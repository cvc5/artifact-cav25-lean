import os
import csv
import sys

def parse_log_file(filepath):
    data = {
        "benchmark": filepath,
        "result": "",
        "holes": "",
        "solve": "",
    }

    with open(filepath, 'r') as file:
        for line in file:
            if "prove:" in line:
                data["solve"] = int(line.split("prove:")[1].strip())
            elif "status Theorem for" in line:
                data["result"] = "unsat"
            elif "status GaveUp for" in line:
                data["result"] = "unknown"
            elif "status Timeout for" in line:
                data["result"] = "unknown"

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

    fieldnames = ["benchmark", "result", "holes", "solve"]
    
    with open(output_csv, 'w', newline='') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()

        for filepath in log_files:
            data = parse_log_file(filepath)
            writer.writerow(data)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python collect_duper_stats.py <output directory> <output_csv>")
        sys.exit(1)

    directory = sys.argv[1]
    output_csv = sys.argv[2]

    log_files = find_log_files(directory)
    write_to_csv(log_files, output_csv)

    print(f"Data has been written to {output_csv}")
