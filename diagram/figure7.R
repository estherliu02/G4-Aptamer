library(DBI)
library(RSQLite)
library(ggplot2)
library(patchwork)
library(dplyr)
library(tidyr)
library(scales)

# Connect to database
con <- dbConnect(RSQLite::SQLite(), your_data_path)

# Query to get top 10% rows based on any round percentage
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
df[is.na(df)] <- 0

# Reshape and bin
df_long <- df %>%
  pivot_longer(cols = starts_with("Round"), names_to = "Round", values_to = "RoundPercent") %>%
  filter(RoundPercent > 0)

breaks <- pretty(df_long$RoundPercent, n = 30)
bin_labels <- head(breaks, -1) + diff(breaks) / 2

df_long <- df_long %>%
  mutate(
    Bin = cut(RoundPercent, breaks = breaks, include.lowest = TRUE),
    BinMid = bin_labels[as.integer(Bin)]
  )

hist_data <- df_long %>%
  count(Round, BinMid)

# Scatterplot styling
scatter_theme <- theme_minimal(base_size = 13)

# Add position flags
df <- df %>%
  mutate(
    pos23 = ifelse(Round3 >= Round2, "Above", "Below"),
    pos34 = ifelse(Round4 >= Round3, "Above", "Below"),
    pos45 = ifelse(Round5 >= Round4, "Above", "Below"),
    pos25 = ifelse(Round5 >= Round2, "Above", "Below")
  )

# Scatterplots
s1 <- ggplot(df, aes(x = Round2, y = Round3, color = pos23)) +
  geom_point(alpha = 0.5) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed") +
  scale_color_manual(values = c("Above" = "#1f77b4", "Below" = "#ff7f0e")) +
  labs(title = "Round 2 vs Round 3", x = "Round 2 (%)", y = "Round 3 (%)") +
  scatter_theme + guides(color = "none")

s2 <- ggplot(df, aes(x = Round3, y = Round4, color = pos34)) +
  geom_point(alpha = 0.5) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed") +
  scale_color_manual(values = c("Above" = "#1f77b4", "Below" = "#ff7f0e")) +
  labs(title = "Round 3 vs Round 4", x = "Round 3 (%)", y = "Round 4 (%)") +
  scatter_theme + guides(color = "none")

s3 <- ggplot(df, aes(x = Round4, y = Round5, color = pos45)) +
  geom_point(alpha = 0.5) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed") +
  scale_color_manual(values = c("Above" = "#1f77b4", "Below" = "#ff7f0e")) +
  labs(title = "Round 4 vs Round 5", x = "Round 4 (%)", y = "Round 5 (%)") +
  scatter_theme + guides(color = "none")

s4 <- ggplot(df, aes(x = Round2, y = Round5, color = pos25)) +
  geom_point(alpha = 0.5) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed") +
  scale_color_manual(values = c("Above" = "#1f77b4", "Below" = "#ff7f0e")) +
  labs(title = "Round 2 vs Round 5", x = "Round 2 (%)", y = "Round 5 (%)") +
  scatter_theme + guides(color = "none")

# Barplot setup
get_above_below_counts <- function(df, xcol, ycol) {
  df %>%
    mutate(position = ifelse(.data[[ycol]] >= .data[[xcol]], "Above", "Below")) %>%
    count(position) %>%
    mutate(comparison = paste("Round", gsub("Round", "", xcol), "vs Round", gsub("Round", "", ycol)))
}

count1 <- get_above_below_counts(df, "Round2", "Round3")
count2 <- get_above_below_counts(df, "Round3", "Round4")
count3 <- get_above_below_counts(df, "Round4", "Round5")
count4 <- get_above_below_counts(df, "Round2", "Round5")

bar_data <- bind_rows(count1, count2, count3, count4) %>%
  mutate(comparison = factor(comparison, levels = c(
    "Round 2 vs Round 3", "Round 3 vs Round 4", "Round 4 vs Round 5", "Round 2 vs Round 5"
  )))

bar_data_percent <- bar_data %>%
  group_by(comparison) %>%
  mutate(Percent = n / sum(n))

barplot <- ggplot(bar_data_percent, aes(x = comparison, y = n, fill = position)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.7), width = 0.6) +
  geom_text(
    aes(label = paste0(round(Percent * 100, 1), "%")),
    position = position_dodge(width = 0.7),
    vjust = -0.4,
    size = 4.2
  ) +
  geom_vline(xintercept = 3.5, linetype = "dashed", color = "black") +
  scale_fill_manual(values = c("Above" = "#1f77b4", "Below" = "#ff7f0e")) +
  labs(
    x = "Comparison",
    y = "Count"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.margin = margin(t = 30, r = 10, b = 10, l = 10)
  ) +
  coord_cartesian(clip = "off")  # ✅ CRUCIAL LINE



# Combine 4 scatterplots above barplot, with tags A–E
final_combined_plot <- (
  (s1 | s2 | s3 | s4) / barplot
) +
  plot_layout(heights = c(1, 0.7)) +
  plot_annotation(
    title = "Comparative Enrichment of Sequences Across Rounds",
    tag_levels = "A",
    theme = theme(
      plot.title = element_text(size = 16, face = "bold", hjust = 0.5, margin = margin(b = 10)),
      plot.tag = element_text(size = 14, face = "bold")
    )
  )


# Show plot
final_combined_plot



