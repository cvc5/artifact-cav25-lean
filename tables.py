import pandas as pd
import glob
import os
import argparse

def load_and_process_table_data(file_pattern, benchmark_filter=None):
    """
    Load and process CSV files matching the file pattern.
    Generate a summary table for `unsat` results with required columns.
    Optionally filter benchmarks by a name prefix.
    """
    table_data = []
    total = None  # To store the total benchmarks (same for all checkers)

    for file in glob.glob(file_pattern):
        df = pd.read_csv(file)
        checker_name = file.split('/')[-1].split('.')[0]  # Use file name as checker ID

        # Apply benchmark filtering if specified
        if benchmark_filter:
            df = df[df['benchmark'].str.contains(benchmark_filter)]

        # Identify `unsat` results based on the given conditions
        if 'check' in df.columns:
            df['is_unsat'] = (
                (df['result'] == 'unsat') | (df['holes'] == 1) |
                (df['result'].isna() & df['solve'].notna() & df['check'].isna())
            )
            checked = df[(df['is_unsat']) & (df['check'].notna())].shape[0]
            checked_no_holes = df[(df['is_unsat']) & (df['check'].notna()) & (df['holes'].isna())].shape[0]
        elif 'kernel' in df.columns:
            df['is_unsat'] = df['load'].notna()
            checked = df[(df['is_unsat']) & (df['kernel'].notna())].shape[0]
            checked_no_holes = df[(df['is_unsat']) & (df['kernel'].notna()) & (df['holes'].isna())].shape[0]
        else:
            df['is_unsat'] = df['solve'].notna()
            checked = df[(df['is_unsat']) & (df['solve'].notna())].shape[0]
            checked_no_holes = df[(df['is_unsat']) & (df['solve'].notna()) & (df['holes'].isna())].shape[0]

        solved = df['is_unsat'].sum()

        if total is None:
            total = df.shape[0]

        table_data.append({
            "Solver+Checker": checker_name,
            "Solved": solved,
            "Checked": checked,
            "Checked (no holes)": checked_no_holes
        })

    return pd.DataFrame(table_data), total

def save_table_to_latex(table, total, output_file):
    """
    Save the generated table to a LaTeX file.
    Include the total benchmarks in the caption or as a footnote.
    """
    # Ensure parent directories of the TEX file exist
    os.makedirs(os.path.dirname(output_file), exist_ok=True)

    with open(output_file, 'w') as f:
        latex_table = table.to_latex(index=False, escape=False)
        latex_table += f"\n\\hline\nTotal Benchmarks: {total}\n"
        f.write(latex_table)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate a summary table for `unsat` results.")
    parser.add_argument("data_dir", type=str, help="Path to the directory containing data files.")
    parser.add_argument("output_file", type=str, help="Path to the output LaTeX file.")
    parser.add_argument("--benchmark_filter", type=str, default=None, help="Prefix to filter benchmarks within the data (e.g., QF_ for quantifier-free benchmarks).")
    args = parser.parse_args()

    # Load and process the data
    file_pattern = os.path.join(args.data_dir, "*.csv")
    table_data, total = load_and_process_table_data(file_pattern, args.benchmark_filter)

    # Save the table to a LaTeX file
    save_table_to_latex(table_data, total, args.output_file)
