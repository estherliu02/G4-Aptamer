import sqlite3
import pandas as pd
import os
import glob

# Set base_dir as the parent directory of the script location
script_dir = os.path.dirname(os.path.abspath(__file__))
base_dir = os.path.abspath(os.path.join(script_dir, os.pardir))

# Paths
data_dir = os.path.join(base_dir, "data")
db_path = os.path.join(base_dir, "results", "result.db")

# Detect round names from .fasta.gz files
rounds = sorted([
    os.path.basename(f).replace(".fasta.gz", "")
    for f in glob.glob(os.path.join(data_dir, "*.fasta.gz"))
])

# Connect to the database
conn = sqlite3.connect(db_path)

# Step 1: Load abundance trend data
abundance_trend = pd.read_sql("SELECT * FROM abundance_trend", conn)

# Step 2: Initialize a combined DataFrame
all_info = pd.DataFrame()

# Step 3: Loop through rounds and merge QGRS and G4screener
for round_num in rounds:
    print(f"Processing round: {round_num}")
    
    # Table names
    qgrs_table = f'"{round_num}_qgrs"'
    g4screener_table = f'"{round_num}_G4screener"'

    # Load data
    qgrs_data = pd.read_sql(f"SELECT input_sequence AS Seq, GS FROM {qgrs_table}", conn)
    g4screener_data = pd.read_sql(f"SELECT Sequence AS Seq, G4H, G4NN FROM {g4screener_table}", conn)

    # Abundance (remove current round's read(%) column before merge to avoid duplicates)
    abundance_cols = [f"{round_num}_read(%)"]
    round_abundance = abundance_trend[["Seq"] + abundance_cols].dropna()
    round = round_abundance.drop(columns=abundance_cols)

    # Merge all relevant info
    round_data = round.merge(abundance_trend, on="Seq", how="inner")
    round_data = round_data.merge(qgrs_data, on="Seq", how="left")
    round_data = round_data.merge(g4screener_data, on="Seq", how="inner")

    # Flag missing scores
    round_data["Missing_Scores"] = round_data[["GS", "G4H", "G4NN"]].isnull().any(axis=1)

    # Append
    all_info = pd.concat([all_info, round_data], ignore_index=True)

# Final cleanup
all_info.drop_duplicates(inplace=True)
all_info.rename(columns={"GS": "QGRS_score"}, inplace=True)

# Column ordering
abundance_columns = [col for col in all_info.columns if col.endswith("_read(%)")]
new_column_order = ["Seq"] + sorted(abundance_columns, reverse=True) + ["QGRS_score", "G4H", "G4NN"]
all_info = all_info[new_column_order]

# Sort by most recent round first
all_info = all_info.sort_values(by=sorted(abundance_columns, reverse=True), ascending=False)

# Save to DB
all_info.to_sql("all_info", conn, if_exists="replace", index=False)
conn.close()

print("The table 'all_info' has been created successfully.")
