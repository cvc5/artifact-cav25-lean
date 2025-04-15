import os
import csv
import sys

def parse_log_file(filepath):
    data = {
        "benchmark": filepath,
        "result": "",
        "holes": "",
        "solve": "",
        "check": ""
    }

    try:
        with open(filepath, "r") as f:
            for line in f:
                if "goal." not in line:
                    continue
                if "error:" in line or "timeout" in line:
                    # If there's an error or timeout, skip extracting times
                    data["solve"] = ""
                    data["check"] = ""
                else:
                    # Extract ATP time (solve time)
                    if "+" in line:
                        atp_start = line.find("+") + 1
                        atp_end = line.find(")", atp_start)
                        if atp_start != -1 and atp_end != -1 and atp_start < atp_end:
                            atp_time = int(line[atp_start:atp_end])
                        else:
                            atp_time = None

                        if atp_time is not None:
                            data["solve"] = str(int(atp_time))

                    # Extract preplay time (check time)
                    if "some smt" in line:
                        preplay_start = line.rfind("(") + 1
                        preplay_end = line.find(")", preplay_start)

                        if preplay_start != -1 and preplay_end != -1 and preplay_start < preplay_end:
                            preplay_time = int(line[preplay_start:preplay_end])
                        else:
                            preplay_time = None

                        if preplay_time is not None:
                            data["check"] = str(int(preplay_time))
                            data["result"] = "unsat"
    except FileNotFoundError:
        return data

    return data

def find_log_files(directory):
    log_files = []
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith(".stdout"):
                file = os.path.join(os.path.splitext(file)[0], "mirabelle/mirabelle.log")
                log_files.append(os.path.join(root, file))
    return log_files

def write_to_csv(log_files, output_csv):
    # Ensure parent directories of the CSV file exist
    os.makedirs(os.path.dirname(output_csv), exist_ok=True)

    fieldnames=["benchmark", "result", "holes", "solve", "check"]

    # Write data to CSV
    with open(output_csv, 'w', newline='') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()

        for filepath in log_files:
            data = parse_log_file(filepath)
            writer.writerow(data)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python collect_sledgehammer_stats.py <output directory> <output_csv>")
        sys.exit(1)

    directory = sys.argv[1]
    output_csv = sys.argv[2]

    log_files = find_log_files(directory)
    write_to_csv(log_files, output_csv)

    print(f"Data has been written to {output_csv}")
