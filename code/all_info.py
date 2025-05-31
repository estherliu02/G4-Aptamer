import sqlite3
import pandas as pd

# Database path
db_path = "/Users/esther/Desktop/G4/50%_GC.db"

# Connect to the database
conn = sqlite3.connect(db_path)

# Step 1: Load abundance trend data
abundance_trend = pd.read_sql("SELECT * FROM abundance_trend", conn)

# Step 2: Initialize a combined DataFrame for all rounds
all_info = pd.DataFrame()

# Step 3: Loop through each round and join data
for round_num in ["C2", "C3", "C4", "C5", "C6"]:
    # Load QGRS, RNAfold, and G4Screener data for the current round
    qgrs_table = f'"{round_num}_qgrs"'
    rnafold_table = f'"{round_num}_RNAfold"'
    g4screener_table = f'"{round_num}_G4screener"'

    qgrs_data = pd.read_sql(f"SELECT input_sequence as Seq, GS FROM {qgrs_table}", conn)
    rnafold_data = pd.read_sql(f"SELECT Seq_ID, RNAfold_dG FROM {rnafold_table}", conn)
    g4screener_data = pd.read_sql(f"SELECT Sequence as Seq, description as Seq_ID, G4H, G4NN FROM {g4screener_table}", conn)

    # Filter abundance data for the current round
    abundance_cols = [f"{round_num}_read(%)"]
    round_abundance = abundance_trend[["Seq"] + abundance_cols].dropna()
    round = round_abundance.drop(columns=abundance_cols)
    # Join RNAfold and G4screener on Seq_ID
    rnafold_and_g4screener = g4screener_data.merge(rnafold_data, on="Seq_ID", how="inner")

    # Drop Seq_ID after merging RNAfold and G4screener
    rnafold_and_g4screener.drop(columns=["Seq_ID"], inplace=True)

    # Merge data sources
    round_data = round.merge(abundance_trend[["Seq", "C2_read(%)", "C3_read(%)", "C4_read(%)", "C5_read(%)", "C6_read(%)"]], on="Seq", how="inner")
    round_data = round_data.merge(qgrs_data, on="Seq", how="inner")
    round_data = round_data.merge(rnafold_and_g4screener, on="Seq", how="inner")

    # Add a column to flag missing scores
    round_data["Missing_Scores"] = round_data[["GS", "RNAfold_dG", "G4H", "G4NN"]].isnull().any(axis=1)

    # Append to the all_info DataFrame
    all_info = pd.concat([all_info, round_data], ignore_index=True)

all_info.drop_duplicates(inplace=True)

# Step 4: Rename and reorder columns
all_info.rename(columns={"GS": "QGRS_score"}, inplace=True)

# Define the desired column order
abundance_columns = [col for col in all_info.columns if col.endswith("_read(%)")]
new_column_order = ["Seq"] + abundance_columns + ["QGRS_score", "RNAfold_dG", "G4H", "G4NN"]

# Reorder the columns
all_info = all_info[new_column_order]

# Sort the table
all_info = all_info.sort_values(
    by=["C6_read(%)", "C5_read(%)", "C4_read(%)", "C3_read(%)", "C2_read(%)"],
    ascending=[False, False, False, False, False]
)

# Step 5: Write the combined table back to the database
all_info.to_sql("all_info", conn, if_exists="replace", index=False)

# Close the connection
conn.close()

print("The table 'all_info' has been created successfully.")
