import sys
import sqlite3
import pandas as pd
import matplotlib.pyplot as plt
import os
# Database path
db_path = "/Users/esther/Desktop/G4/20%_library.db"

def generate_trend(sequence):
    # Connect to the SQLite database
    conn = sqlite3.connect(db_path)

    # Query the abundance_trend table for the specified sequence
    query = f"""
        SELECT Seq,
               "2nd_read(%)" AS "2nd",
               "3rd_read(%)" AS "3rd",
               "4th_read(%)" AS "4th",
               "5th_read(%)" AS "5th"
        FROM abundance_trend
        WHERE Seq = ?
    """
    trend_data = pd.read_sql(query, conn, params=[sequence])

    # Close the connection
    conn.close()

    # Check if the sequence exists in the table
    if trend_data.empty:
        print(f"No data found for sequence: {sequence}")
        return

    # Prepare data for plotting
    rounds = ["2nd", "3rd", "4th", "5th"]
    read_percentages = trend_data.iloc[0, 1:].fillna(0).values  # Exclude the Sequence column and replace nulls with 0

    # Plot the data
    plt.figure(figsize=(8, 5))
    plt.plot(rounds, read_percentages, marker="o", linestyle="-", label=f"Sequence: {sequence}")
    plt.title(f"Read Percentage Over Rounds for {sequence}")
    plt.xlabel("Round")
    plt.ylabel("Read Percentage (%)")
    plt.xticks(rounds)
    plt.ylim(0, max(read_percentages) * 1.2)  # Adjust y-axis for better visibility
    plt.grid()
    plt.legend()
    plt.tight_layout()

    os.makedirs("abundance_trend", exist_ok=True)
    output_path = f"abundance_trend/{sequence}_read_trend.png"
    plt.savefig(output_path)
    plt.show()
    plt.close()
    print(f"Trend graph saved to {output_path}")

# Main script
if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python generate_trend.py <Sequence>")
        sys.exit(1)

    sequence = sys.argv[1]
    generate_trend(sequence)
