import pandas as pd
import matplotlib.pyplot as plt
import argparse
import os

def load_csv(file):
    """Load CSV and determine its format."""
    df = pd.read_csv(file)

    # Drop first 5 components of the path in the benchmark
    df['benchmark'] = df['benchmark'].apply(lambda x: '/'.join(x.split('/')[8:]) if '/' in x else x)

    if 'check' in df.columns:
        df['total_check_time'] = df['check']
    elif 'kernel' in df.columns:
        df['total_check_time'] = df[['load', 'reconstruct', 'kernel']].sum(axis=1, skipna=False)
    else:
        raise ValueError(f"Invalid CSV format for {file}")
    return df[['benchmark', 'total_check_time']].sort_values(by='benchmark')

def plot_scatter(csv1, csv2, output_file):
    """Generate scatter plot comparing total checking times."""
    df1 = load_csv(csv1)
    df2 = load_csv(csv2)
    
    # Merge on benchmark
    merged = pd.merge(df1, df2, on='benchmark', suffixes=('_1', '_2'))
    
    # Filter out rows where either solver timed out
    merged = merged.dropna(subset=['total_check_time_1', 'total_check_time_2'])
    
    # Determine axis limits
    min_val = min(merged['total_check_time_1'].min(), merged['total_check_time_2'].min())
    max_val = max(merged['total_check_time_1'].max(), merged['total_check_time_2'].max())
    
    # Scatter plot
    plt.figure(figsize=(6, 6))
    plt.scatter(merged['total_check_time_1'], merged['total_check_time_2'], alpha=0.7)
    plt.plot([min_val, max_val], [min_val, max_val], 'r--', label='y = x')
    
    plt.xscale('log')
    plt.yscale('log')
    plt.xlim(min_val, max_val)
    plt.ylim(min_val, max_val)
    
    plt.xlabel("Lean-SMT Checking Time (ms)")
    plt.ylabel("Ethos Checking Time (ms)")
    plt.title("Lean-SMT vs. Ethos Checking Times")
    plt.legend()
    plt.grid(True, linestyle='--', alpha=0.6)

    # Ensure parent directories of the PDF file exist
    os.makedirs(os.path.dirname(output_file), exist_ok=True)

    # Save as PDF
    plt.savefig(output_file)
    plt.close()

def main():
    parser = argparse.ArgumentParser(description="Generate scatter plot from two CSV files.")
    parser.add_argument("csv1", type=str, help="Path to first CSV file")
    parser.add_argument("csv2", type=str, help="Path to second CSV file")
    parser.add_argument("output", type=str, help="Path to output PDF file")
    args = parser.parse_args()
    
    plot_scatter(args.csv1, args.csv2, args.output)

if __name__ == "__main__":
    main()
