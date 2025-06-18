import pandas as pd
import sqlite3
import os
import glob

# Set base_dir as the parent of the current script location
script_dir = os.path.dirname(os.path.abspath(__file__))
base_dir = os.path.abspath(os.path.join(script_dir, os.pardir))

# Define directories
qgrs_dir = os.path.join(base_dir, "results/qgrs")
g4screener_dir = os.path.join(base_dir, "results/G4H_G4NN")
abundance_dir = os.path.join(base_dir, "data")

# Extract round names from *.fasta.gz in the data folder
rounds = sorted([
    os.path.basename(f).replace(".fasta.gz", "")
    for f in glob.glob(os.path.join(abundance_dir, "*.fasta.gz"))
])

# Create or connect to SQLite database
results_dir = os.path.join(base_dir, "results")
os.makedirs(results_dir, exist_ok=True)
db_path = os.path.join(results_dir, "result.db")
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Utility functions
def load_qgrs(round_num):
    file_path = os.path.join(qgrs_dir, f"{round_num}_results.tsv")
    return pd.read_csv(file_path, sep="\t")

def load_g4screener(round_num):
    file_path = os.path.join(g4screener_dir, f"{round_num}_results.tsv")
    return pd.read_csv(file_path, sep="\t")

def load_abundance(round_num):
    file_path = os.path.join(abundance_dir, f"{round_num}.xls")
    return pd.read_csv(file_path, sep="\t")

# Process and load data into database
for round_num in rounds:
    print(f"Processing data for round: {round_num}")

    # Load and store QGRS data
    qgrs_data = load_qgrs(round_num)
    qgrs_table = f"{round_num}_qgrs"
    qgrs_data.to_sql(qgrs_table, conn, if_exists="replace", index=False)
    print(f"Loaded QGRS data into table: {qgrs_table}")

    # Load and store G4screener data
    g4screener_data = load_g4screener(round_num)
    g4screener_table = f"{round_num}_G4screener"
    g4screener_data.to_sql(g4screener_table, conn, if_exists="replace", index=False)
    print(f"Loaded G4screener data into table: {g4screener_table}")

    # Load and store abundance data
    abundance_data = load_abundance(round_num)
    abundance_table = f"{round_num}_abundance"
    abundance_data.to_sql(abundance_table, conn, if_exists="replace", index=False)
    print(f"Loaded abundance data into table: {abundance_table}")

# Close the connection
conn.close()
print(f"All data loaded into database at: {db_path}")
