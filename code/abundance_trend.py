import sqlite3
import pandas as pd

# Database path
db_path = "/Users/esther/Desktop/G4/50%_GC.db"

# Connect to the database
conn = sqlite3.connect(db_path)

# Load all abundance tables into DataFrames
abundance_tables = {}
for round_num in ["C2", "C3", "C4", "C5", "C6"]:
    table_name = f"{round_num}_abundance"
    # Use double quotes around table names in the SQL query
    df = pd.read_sql(f'SELECT * FROM "{table_name}"', conn)
    # Add rank based on reads(%), higher reads get top rank
    df[f"{round_num}_rank"] = df["reads(%)"].rank(method="min", ascending=False).astype(int)
    # Rename columns for merging
    df = df.rename(columns={
        "Number": f"{round_num}_number",
        "reads(%)": f"{round_num}_read(%)"
    })
    abundance_tables[round_num] = df

# Standardize column names and merge
abundance_trend = None
for round_num, df in abundance_tables.items():
    # Keep relevant columns for merging
    df = df[["Seq", f"{round_num}_number", f"{round_num}_read(%)", f"{round_num}_rank"]]
    if abundance_trend is None:
        abundance_trend = df
    else:
        abundance_trend = pd.merge(abundance_trend, df, on="Seq", how="outer")

# Write the combined table back to the database
abundance_trend.to_sql("abundance_trend", conn, if_exists="replace", index=False)

# Close the connection
conn.close()

print("The table 'abundance_trend' with ranks has been created successfully.")
