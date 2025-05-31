library(DBI)
library(RSQLite)
library(ggplot2)
library(patchwork)
library(dplyr)
library(tidyr)
library(scales)


# Connect to database
con <- dbConnect(RSQLite::SQLite(), your_data_path)

# Query to get top 10% rows based on any read percentage
query <- "
WITH Ranked AS (
    SELECT Seq,
           COALESCE(\"2nd_read(%)\", 0) AS Round2,
           COALESCE(\"3rd_read(%)\", 0) AS Round3,
           COALESCE(\"4th_read(%)\", 0) AS Round4,
           COALESCE(\"5th_read(%)\", 0) AS Round5,
           ROW_NUMBER() OVER (ORDER BY COALESCE(\"2nd_read(%)\", 0) DESC) AS row_num2,
           ROW_NUMBER() OVER (ORDER BY COALESCE(\"3rd_read(%)\", 0) DESC) AS row_num3,
           ROW_NUMBER() OVER (ORDER BY COALESCE(\"4th_read(%)\", 0) DESC) AS row_num4,
           ROW_NUMBER() OVER (ORDER BY COALESCE(\"5th_read(%)\", 0) DESC) AS row_num5
    FROM all_info
)
SELECT DISTINCT Round2, Round3, Round4, Round5
FROM Ranked
WHERE 
      row_num2 <= 30000
   OR row_num3 <= 30000
   OR row_num4 <= 30000
   OR row_num5 <= 30000;
"



df <- dbGetQuery(con, query)

# Treat NA as 0
df[is.na(df)] <- 0

# Reshape and clean
df_long <- df %>%
  pivot_longer(cols = starts_with("Round"), names_to = "Round", values_to = "ReadPercent") %>%
  filter(ReadPercent > 0)

# Smart binning
breaks <- pretty(df_long$ReadPercent, n = 30)

# Compute bin midpoints for cleaner x-axis labels
bin_labels <- head(breaks, -1) + diff(breaks) / 2

# Cut and assign numeric bin labels
df_long <- df_long %>%
  mutate(
    Bin = cut(ReadPercent, breaks = breaks, include.lowest = TRUE),
    BinMid = bin_labels[as.integer(Bin)]
  )

# Count per Round and BinMid
hist_data <- df_long %>%
  count(Round, BinMid)

# Create grouped bar chart
histogram_combined <- ggplot(hist_data, aes(x = BinMid, y = n, fill = Round)) +
  geom_bar(stat = "identity", position = "dodge") +
  scale_y_log10(
    breaks = c(10, 50, 100, 500, 1000, 5000, 10000, 50000, 100000),
    labels = comma_format()
  ) +
  labs(
    x = "Read Percentage",
    y = "Count (log scale)"
  ) +
  theme_minimal(base_size = 16)

histogram_combined
