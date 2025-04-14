import os
import csv
from pathlib import Path

def parse_log_file(log_file):
    """
    Parse a single mirabelle.log file to extract benchmark, ATP time, and preplay time.
    Convert all times to milliseconds.
    """
    data = []

    benchmark_path = str(log_file.parent)

    with open(log_file, "r") as f:
        for line in f:
            if "goal." not in line:
                continue

            fields = {
                "benchmark": benchmark_path,
                "result": "",
                "holes": "",
                "solve": "",
                "check": ""
            }

            if "error:" in line or "timeout" in line:
                # If there's an error or timeout, skip extracting times
                fields["solve"] = ""
                fields["check"] = ""
            else:
                # Extract ATP time (solve time)
                if ", ATP" in line:
                    atp_start = line.find(", ATP") + 5
                    atp_end_ms = line.find("ms", atp_start)
                    atp_end_s = line.find("s", atp_start)
                    if atp_end_ms != -1 and (atp_end_s == -1 or atp_end_ms < atp_end_s):
                        atp_time = float(line[atp_start:atp_end_ms])
                    elif atp_end_s != -1:
                        atp_time = float(line[atp_start:atp_end_s]) * 1000
                    else:
                        atp_time = None

                    if atp_time is not None:
                        fields["solve"] = str(int(atp_time))

                # Extract preplay time (check time)
                if "Try this:" in line:
                    preplay_start = line.rfind("(") + 1
                    preplay_end_ms = line.find("ms", preplay_start)
                    preplay_end_s = line.find("s", preplay_start)

                    if preplay_end_ms != -1 and preplay_end_ms > preplay_start:
                        preplay_time = float(line[preplay_start:preplay_end_ms])
                    elif preplay_end_s != -1:
                        preplay_time = float(line[preplay_start:preplay_end_s]) * 1000
                    else:
                        preplay_time = None

                    if preplay_time is not None:
                        fields["check"] = str(int(preplay_time))
                        fields["result"] = "unsat"

            data.append(fields)

    return data

def extract_data_to_csv(data_dir, output_csv):
    """
    Extract data from all mirabelle.log files in the directory and write to CSV.
    """
    all_data = []

    for dirpath, _, filenames in os.walk(data_dir):
        for filename in filenames:
            if filename == "mirabelle.log":
                log_file = Path(dirpath) / filename
                all_data.extend(parse_log_file(log_file))

    # Write data to CSV
    with open(output_csv, "w", newline="") as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=["benchmark", "result", "holes", "solve", "check"])
        writer.writeheader()
        writer.writerows(all_data)

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Extract ATP and preplay times from mirabelle.log files.")
    parser.add_argument("data_dir", type=str, help="Path to the directory containing mirabelle.log files.")
    parser.add_argument("output_csv", type=str, help="Path to the output CSV file.")
    args = parser.parse_args()

    extract_data_to_csv(args.data_dir, args.output_csv)

    print("Extraction complete. Data saved to", args.output_csv)
