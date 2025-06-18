# G4 Aptamer Analysis Pipeline

This pipeline processes G-quadruplex (G4) aptamer candidates using G4RNA Screener, QGRS Mapper, and abundance ranking, storing all outputs in a unified SQLite database.

---

## 📁 Repository Structure

```
project-root/
├── code/
│   ├── combine_fasta.sh      # Combines .fasta.gz files into plain FASTA
│   ├── remove_dup.sh         # Removes duplicate sequences
│   ├── run_G4H_G4NN.sh       # Executes G4RNA Screener on each sequence file
│   ├── run_qgrs.sh           # Runs QGRS Mapper on FASTA files
│   ├── create_db.py          # Builds SQLite DB from results
│   ├── abundance_trend.py    # Ranks sequences across rounds
│   └── all_info.py           # Merges all results into one table
│
├── data/                     # Input .fasta.gz and .xls files (one per round)
│
├── results/
│   ├── unique_sequences/     # Deduplicated FASTA files
│   ├── G4H_G4NN/             # Output from G4RNA Screener
│   ├── qgrs/                 # Output from QGRS Mapper
│   └── result.db             # Final SQLite database
│
└── library/                  # External tools and environments
    ├── g4rna_screener/       # Cloned repo for G4RNA Screener
    └── g4rna_env/            # Python 2 virtual environment for screener
```
---

## 🧰 Setup Instructions

### 1. Locate Code Folder

```bash
cd code
```

### 2. Clone G4RNA Screener

```bash
git clone https://github.com/scottgroup/g4rna_screener.git ../library/g4rna_screener
```

> 💬 G4RNA Screener uses **Python 2**

### 3. Set up Python 2 Virtual Environment

```bash
pip3 install virtualenv
virtualenv -p python2 ../library/g4rna_env
source ../library/g4rna_env/bin/activate
```

### 4. Install Dependencies

```bash
pip2 install numpy pandas scipy regex
deactivate
pip install http://biopython.org/DIST/biopython-1.76.tar.gz
```

---

## ▶️ Pipeline Execution

### Step 1: Combine FASTA Files

```bash
chmod +x combine_fasta.sh
./combine_fasta.sh
```

### Step 2: Remove Duplicates

```bash
chmod +x remove_dup.sh
./remove_dup.sh
```

### Step 3: Run G4RNA Screener

```bash
chmod +x run_G4H_G4NN.sh
./run_G4H_G4NN.sh
```

> ⏱ Takes ~753 seconds for 906,366 sequences

### Step 4: Run QGRS Mapper

```bash
./run_qgrs.sh
```

> ⏱ Takes ~3748 seconds for 906,366 sequences

---

## 🧪 SQLite Integration

### Step 5: Create Database

```bash
python create_db.py
```

- Loads QGRS, G4 screener, and abundance `.xls` into `results/result.db`.

### Step 6: Build Abundance Trend Table

```bash
python abundance_trend.py
```

- Ranks sequences across all rounds based on abundance.

### Step 7: Merge All Info

```bash
python all_info.py
```

- Combines QGRS, G4 scores, and abundance into final `all_info` table.

---

## 📦 Output Summary

- ✅ SQLite DB: `results/result.db`
  - Tables: `*_qgrs`, `*_G4screener`, `*_abundance`, `abundance_trend`, `all_info`

---

## 💡 Notes

- All scripts must be run from `code/`
