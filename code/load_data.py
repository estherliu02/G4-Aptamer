import pandas as pd
import sqlite3
import os

# Paths and filenames
base_dir = "/Users/esther/Desktop/G4"
qgrs_dir = os.path.join(base_dir, "results/qgrs/50%_GC")
rnafold_dir = os.path.join(base_dir, "results/rnafold/50%_GC")
g4screener_dir = os.path.join(base_dir, "results/G4H_G4NN/50%_GC")
abundance_dir = os.path.join(base_dir, "NGS_30%_20%_library/50%_GC")
rounds = ["C2", "C3", "C4", "C5", "C6"]
#rounds = ["C7", "C8", "C9", "C10", "C11"]
#rounds = ["C12", "C13", "C14", "C15", "C16"]

# Create or connect to SQLite database
db_path = os.path.join(base_dir, "50%_GC.db")
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Utility functions
def load_qgrs(round_num):
    file_path = os.path.join(qgrs_dir, f"{round_num}_results.tsv")
    return pd.read_csv(file_path, sep="\t")

def load_rnafold(round_num):
    file_path = os.path.join(rnafold_dir, f"{round_num}_combined_RNAfold.out")
    data = []
    with open(file_path, "r") as f:
        seq_id = None
        seq = None
        for line in f:
            line = line.strip()
            if line.startswith(">"):
                seq_id = line.strip(">")
            elif seq_id and not seq:
                seq = line
            elif seq:
                try:
                    structure, dg = line.rsplit(" ", 1)
                    dg = float(dg.strip("()"))
                    data.append((seq_id, seq, structure, dg))
                except ValueError:
                    print(f"Skipping malformed line: {line}")
                finally:
                    seq_id = None
                    seq = None
    return pd.DataFrame(data, columns=["Seq_ID", "Sequence", "Structure", "RNAfold_dG"])

def load_g4screener(round_num):
    file_path = os.path.join(g4screener_dir, f"{round_num}_combined_results.tsv")
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

    # Load and store RNAfold data
    rnafold_data = load_rnafold(round_num)
    rnafold_table = f"{round_num}_RNAfold"
    rnafold_data.to_sql(rnafold_table, conn, if_exists="replace", index=False)
    print(f"Loaded RNAfold data into table: {rnafold_table}")

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
