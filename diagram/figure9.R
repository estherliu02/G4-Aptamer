library(DBI)
library(RSQLite)
library(dplyr)
library(ggplot2)
library(scales)

# Connect to SQLite
db_path <- file.path("..", "results", "result.db")
con <- dbConnect(RSQLite::SQLite(), db_path)

# Read data
query <- "
SELECT Seq,
       COALESCE(\"2nd_read(%)\", 0) AS Read2,
       COALESCE(\"3rd_read(%)\", 0) AS Read3,
       COALESCE(\"4th_read(%)\", 0) AS Read4,
       COALESCE(\"5th_read(%)\", 0) AS Read5
FROM all_info;
"
df <- dbGetQuery(con, query)

# Store total top-10% counts
top_counts_summary <- data.frame()

# Function to get counts and percentages
get_counts <- function(df, round_col, round_name) {
  df_nonzero <- df %>% filter(.data[[round_col]] > 0)
  top_n <- ceiling(nrow(df_nonzero) * 0.1)
  
  df_top <- df_nonzero %>%
    arrange(desc(.data[[round_col]])) %>%
    slice_head(n = top_n) %>%
    mutate(Trend = Read2 <= Read3 & Read3 <= Read4 & Read4 <= Read5)
  
  counts <- df_top %>%
    count(Trend) %>%
    mutate(
      Round = round_name,
      Category = ifelse(Trend, "Increasing Trend", "Not Increasing"),
      Total = top_n,
      Percent = n / top_n
    ) %>%
    select(Round, Category, n, Percent, Total)
  
  top_counts_summary <<- bind_rows(top_counts_summary, data.frame(Round = round_name, TopN = top_n))
  
  return(counts)
}

# Build results
result <- bind_rows(
  get_counts(df, "Read2", "Round 2"),
  get_counts(df, "Read3", "Round 3"),
  get_counts(df, "Read4", "Round 4"),
  get_counts(df, "Read5", "Round 5")
)

# Generate subtitle
subtitle_text <- paste0(
  "Top 10% Non-Zero Counts — ",
  paste0(top_counts_summary$Round, ": ", top_counts_summary$TopN, collapse = " | ")
)

# Plot
ggplot(result, aes(x = Round, y = n, fill = Category)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.9)) +
  geom_text(
    aes(label = paste0(round(Percent * 100, 1), "%")),
    position = position_dodge(width = 0.9),
    vjust = -0.5,
    size = 4
  ) +
  labs(
    title = "Top 10% Sequences in Each Round: Trend Analysis",
    subtitle = subtitle_text,
    x = "Round",
    y = "Sequence Count",
    fill = "Trend Type"
  ) +
  theme_minimal(base_size = 14) +
  ylim(0, max(result$n) * 1.15)
