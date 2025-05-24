import pandas as pd
import matplotlib.pyplot as plt
import glob
import os
import argparse

def load_and_process_data(file_pattern, benchmark_filter=None):
    """
    Load and process CSV files matching the file pattern.
    Calculate total time (sum of relevant columns) for unsat results.
    Optionally filter benchmarks within the data by a name prefix.
    """
    data_frames = []
    for file in glob.glob(file_pattern):
        df = pd.read_csv(file)

        # Fill missing values with 0
        df = df.fillna(0)

        # Determine schema and calculate time accordingly
        if 'check' in df.columns:
            df['time'] = df['solve'] + df['check']
        elif 'kernel' in df.columns:
            df['time'] = df['solve'] + df['reconstruct'] + df['kernel']
        else:
            df['time'] = df['solve']

        # Filter and sum times where result == 'unsat'
        filtered = df[df['result'] == 'unsat']
        if benchmark_filter:
            filtered = filtered[filtered['benchmark'].str.contains(benchmark_filter)]

        aggregated = filtered.groupby('benchmark')['time'].sum().reset_index()
        aggregated['checker'] = file.split('/')[-1].split('.')[0]  # Use file name as checker ID
        data_frames.append(aggregated)
    return pd.concat(data_frames, ignore_index=True)

def generate_plot(data, output_file):
    """
    Generate cumulative solve time vs. rules proved plot for multiple checkers.
    Save the plot as a PDF to the specified output file.
    """
    plt.figure(figsize=(5, 3))

    for checker, group in data.groupby('checker'):
        group = group.sort_values('time').reset_index()
        group['cumulative_time'] = group['time'].cumsum() / 1000  # Convert ms to seconds
        plt.step(group.index + 1, group['cumulative_time'], label=checker, where='post')

    plt.title("Cumulative solving + checking time")
    plt.xlabel("Number of benchmarks")
    plt.ylabel("Time (s)")
    plt.yscale('log')  # Set y-axis to logarithmic scale
    plt.legend(title="solver+checker")
    plt.grid(True, linestyle='--', alpha=0.7)
    plt.tight_layout()

    # Ensure parent directories of the PDF file exist
    os.makedirs(os.path.dirname(output_file), exist_ok=True)

    # Save the plot as a PDF
    plt.savefig(output_file)
    plt.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate cumulative solve time plots.")
    parser.add_argument("data_dir", type=str, help="Path to the directory containing data files.")
    parser.add_argument("output_file", type=str, help="Path to the output PDF file.")
    parser.add_argument("--benchmark_filter", type=str, default=None, help="Prefix to filter benchmarks within the data (e.g., QF_ for quantifier-free benchmarks).")
    args = parser.parse_args()

    # Load and process the data
    file_pattern = os.path.join(args.data_dir, "*.csv")
    processed_data = load_and_process_data(file_pattern, args.benchmark_filter)

    # Generate the plot
    generate_plot(processed_data, args.output_file)
