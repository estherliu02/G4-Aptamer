import sqlite3
import pandas as pd
import os
import glob

# Set base_dir as the parent directory of the current script
script_dir = os.path.dirname(os.path.abspath(__file__))
base_dir = os.path.abspath(os.path.join(script_dir, os.pardir))

# Detect round names from data files like C2.fasta.gz
data_dir = os.path.join(base_dir, "data")
rounds = sorted([
    os.path.basename(f).replace(".fasta.gz", "")
    for f in glob.glob(os.path.join(data_dir, "*.fasta.gz"))
])

# Database path
db_path = os.path.join(base_dir, "results", "result.db")

# Connect to the database
conn = sqlite3.connect(db_path)

# Load all abundance tables into DataFrames
abundance_tables = {}
for round_num in rounds:
    table_name = f"{round_num}_abundance"
    df = pd.read_sql(f'SELECT * FROM "{table_name}"', conn)
    df[f"{round_num}_rank"] = df["reads(%)"].rank(method="min", ascending=False).astype(int)
    df = df.rename(columns={
        "Number": f"{round_num}_number",
        "reads(%)": f"{round_num}_read(%)"
    })
    abundance_tables[round_num] = df

# Merge across rounds on "Seq"
abundance_trend = None
for round_num, df in abundance_tables.items():
    df = df[["Seq", f"{round_num}_number", f"{round_num}_read(%)", f"{round_num}_rank"]]
    if abundance_trend is None:
        abundance_trend = df
    else:
        abundance_trend = pd.merge(abundance_trend, df, on="Seq", how="outer")

# Save the result
abundance_trend.to_sql("abundance_trend", conn, if_exists="replace", index=False)

# Close DB connection
conn.close()

print("The table 'abundance_trend' with ranks has been created successfully.")
