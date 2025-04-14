import os
import csv
import sys

def parse_log_file(filepath):
    data = {
        "benchmark": filepath,
        "result": "",
        "holes": "",
        "solve": "",
        "check": "",
    }

    with open(filepath, 'r') as file:
        for line in file:
            if "solve:" in line:
                data["solve"] = int(line.split("solve:")[1].strip())
            elif "check:" in line:
                data["check"] = int(line.split("check:")[1].strip())
            elif "unknown" in line:
                data["result"] = "unknown"
            elif line.startswith("sat\n"):
                data["result"] = "sat"
            elif line.startswith("correct\n"):
                data["result"] = "unsat"
            elif "incomplete" in line:
                data["holes"] = 1

    return data

def find_log_files(directory):
    log_files = []
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith(".stdout"):
                log_files.append(os.path.join(root, file))
    return log_files

def write_to_csv(log_files, output_csv):
    # Ensure parent directories of the CSV file exist
    os.makedirs(os.path.dirname(output_csv), exist_ok=True)

    fieldnames = ["benchmark", "result", "holes", "solve", "check"]
    
    with open(output_csv, 'w', newline='') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()

        for filepath in log_files:
            data = parse_log_file(filepath)
            writer.writerow(data)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python collect_ethos_stats.py <output directory> <output_csv>")
        sys.exit(1)

    directory = sys.argv[1]
    output_csv = sys.argv[2]

    log_files = find_log_files(directory)
    write_to_csv(log_files, output_csv)

    print(f"Data has been written to {output_csv}")
