library(DBI)
library(RSQLite)
library(ggplot2)
library(patchwork)

# Connect to SQLite database
con <- dbConnect(RSQLite::SQLite(), "/Users/esther/Desktop/G4/30%_library.db")

# Query data
query <- "
WITH Ranked AS (
    SELECT Seq, \"5th_read(%)\" AS abundance,
           QGRS_score,
           G4H,
           G4NN,
           ROW_NUMBER() OVER (ORDER BY \"5th_read(%)\" DESC) AS row_num,
           COUNT(*) OVER () AS total_rows
    FROM all_info
)
SELECT 
    G4NN, G4H, QGRS_score
FROM Ranked;
"

df <- dbGetQuery(con, query)
colnames(df) <- c("G4NN", "G4H", "QGRS")

# Helper function to create paired plots
paired_plot <- function(metric) {
  hist_plot <- ggplot(df, aes_string(x = metric)) +
    geom_histogram(bins = 30, fill = "red", alpha = 0.6) +
    theme_minimal() +
    labs(title = paste(metric, "- Histogram"), x = metric, y = "Count")
  
  box_plot <- ggplot(df, aes_string(y = metric)) +
    geom_boxplot(fill = "red", alpha = 0.6) +
    theme_minimal() +
    labs(title = paste(metric, "- Boxplot"), y = metric, x = "")
  
  # Side by side with custom width ratio
  hist_plot + box_plot + plot_layout(widths = c(2, 1))
}

# Generate plots
g4nn_plot <- paired_plot("G4NN")
g4h_plot  <- paired_plot("G4H")
qgrs_plot <- paired_plot("QGRS")

# Combine with panel labels
final_plot <- g4nn_plot / g4h_plot / qgrs_plot +
  plot_annotation(
    title = "Histograms and Boxplots of G4NN, G4H, and QGRS",
    subtitle = "Each metric with its histogram and boxplot side by side",
    tag_levels = 'A'  # Add automatic panel tags A, B, C, ...
  )

# Display
print(final_plot)
