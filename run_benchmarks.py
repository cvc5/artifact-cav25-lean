import argparse
import multiprocessing
import os
import psutil
import subprocess
import sys
import time
import threading
from functools import partial
from pathlib import Path

# Define how to invoke each solver
SOLVER_COMMANDS = {
    "duper": lambda path: ["/home/user/artifact/duper.sh", path],
    "cvc5+leansmt": lambda path: ["/home/user/artifact/cvc5+leansmt.sh", path],
    "cvc5+ethos": lambda path: ["/home/user/artifact/cvc5+ethos.sh", path],
    "verit+sledgehammer": None,  # We'll handle this one specially
    "verit+smtcoq": lambda path: ["/home/user/artifact/verit+smtcoq.sh", path],
}

BENCHMARK_ROOT = Path("/home/user/artifact/benchmarks")

def kill_process_tree(pid):
    try:
        parent = psutil.Process(pid)
        children = parent.children(recursive=True)
        for child in children:
            child.kill()
        parent.kill()
    except psutil.NoSuchProcess:
        pass

def monitor_memory(pid, memout_mb, flag):
    """Monitor memory usage of the process tree."""
    try:
        proc = psutil.Process(pid)
        while not flag["done"]:
            mem = proc.memory_info().rss  # Memory in bytes
            for child in proc.children(recursive=True):
                try:
                    mem += child.memory_info().rss
                except psutil.NoSuchProcess:
                    continue
            if mem > memout_mb * 1024 * 1024:
                flag["memout"] = True
                kill_process_tree(pid)
                return
            time.sleep(5)
    except psutil.NoSuchProcess:
        pass

def run_with_limits(cmd, timeout, memout_mb):
    try:
        proc = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            preexec_fn=os.setsid  # new process group
        )
        flag = {"done": False, "memout": False}
        monitor_thread = threading.Thread(target=monitor_memory, args=(proc.pid, memout_mb, flag))
        monitor_thread.start()

        try:
            stdout, stderr = proc.communicate(timeout=timeout)
            flag["done"] = True
            monitor_thread.join()
            if flag["memout"]:
                return "MEMOUT", stdout, stderr
            return proc.returncode, stdout, stderr
        except subprocess.TimeoutExpired:
            flag["done"] = True
            kill_process_tree(proc.pid)
            monitor_thread.join()
            return "TIMEOUT", "", ""
    except Exception as e:
        return "ERROR", "", str(e)

def save_output(solver, benchmark_path, stdout, stderr, out_dir):
    try:
        # Compute relative benchmark path
        rel_path = Path(benchmark_path).relative_to(BENCHMARK_ROOT)
        out_dir = Path(out_dir) / solver / rel_path.parent
        out_dir.mkdir(parents=True, exist_ok=True)

        # Save stdout and stderr
        with open(out_dir / (rel_path.name + ".stdout"), 'w') as f_out:
            f_out.write(stdout)
        with open(out_dir / (rel_path.name + ".stderr"), 'w') as f_err:
            f_err.write(stderr)
    except Exception as e:
        print(f"Failed to save output for {benchmark_path}: {e}", file=sys.stderr)

def run_single_benchmark(solver_name, timeout, memout_mb, out_dir, benchmark_path):
    if solver_name not in SOLVER_COMMANDS:
        return (benchmark_path, "INVALID_SOLVER", f"Solver {solver_name} is not recognized.")

    # Only pass the out_dir argument to verit+sledgehammer
    if solver_name == "verit+sledgehammer":
        cmd = ["/home/user/artifact/verit+sledgehammer.sh", out_dir, benchmark_path]
    else:
        cmd = SOLVER_COMMANDS[solver_name](benchmark_path)

    code, out, err = run_with_limits(cmd, timeout, memout_mb)
    save_output(solver_name, benchmark_path, out, err, out_dir)
    return (benchmark_path, code)

def read_benchmarks(file_path):
    try:
        with open(file_path, 'r') as f:
            return [line.strip() for line in f if line.strip()]
    except FileNotFoundError:
        print(f"Error: File '{file_path}' not found.")
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description="Run solver on a set of benchmarks with parallelism and resource limits.")
    parser.add_argument("input_file", help="Path to file containing full benchmark paths")
    parser.add_argument("solver", choices=SOLVER_COMMANDS.keys(), help="Solver to use")
    parser.add_argument("--jobs", "-j", type=int, default=1, help="Number of benchmarks to run in parallel")
    parser.add_argument("--timeout", "-t", type=int, default=60, help="Timeout (in seconds) per benchmark")
    parser.add_argument("--memout", "-m", type=int, default=1024, help="Memory limit (in MB) per benchmark")
    parser.add_argument("--output_dir", "-o", type=str, default="/home/user/artifact/output",
                        help="Root directory for solver output")

    args = parser.parse_args()
    benchmark_paths = read_benchmarks(args.input_file)

    with multiprocessing.Pool(args.jobs) as pool:
        run_func = partial(run_single_benchmark, args.solver, args.timeout, args.memout, args.output_dir)
        results = pool.map(run_func, benchmark_paths)

    print(f"\nSummary for solver: {args.solver}")
    for path, code in results:
        print(f"{path} -> {code}")

if __name__ == "__main__":
    main()
