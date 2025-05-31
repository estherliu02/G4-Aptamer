# === Load Libraries ===
library(DBI)
library(RSQLite)
library(dplyr)
library(ComplexUpset)
library(ggplot2)

# === Connect to SQLite Database ===
con <- dbConnect(RSQLite::SQLite(), your_data_path)

# === Query Data ===
df <- dbGetQuery(con, "
  SELECT 
    Seq,
    QGRS_score,
    G4H,
    G4NN,
    \"5th_read(%)\" AS Read5
  FROM all_info
")

# === Create Set Membership Columns ===
df <- df %>%
  mutate(
    'G4H > 1' = G4H > 1,
    'G4NN > 0.5' = G4NN > 0.5,
    'QGRS > 50' = QGRS_score > 50
  ) %>%
  filter(!is.na('G4H > 1'), !is.na('G4NN > 0.5'), !is.na('QGRS > 50'))

# === Specify the Sets to Use ===
sets <- c("G4H > 1", "G4NN > 0.5", "QGRS > 50")

# === Arrange Venn Coordinates ===
# Total sequences
total <- nrow(df)

# Arrange all points for plotting
arranged <- arrange_venn(df, sets = sets)

# Count how many points per region
region_sizes <- arranged %>%
  count(region, name = "size") %>%
  mutate(label = paste0("[", size, ", ", sprintf("%.3f", size / total * 100), "%]"))

arranged_labels <- arranged %>%
  group_by(region) %>%
  slice_head(n = 1) %>%
  ungroup() %>%
  left_join(region_sizes, by = "region")


ggplot(arranged) +
  theme_void() +
  coord_fixed(clip = "off") +
  geom_point(aes(x = x, y = y, color = region), size = 2.5) +
  geom_venn_circle(df, sets = sets, size = 1.5) +
  geom_venn_label_set(df, sets = sets, aes(label = region), outwards_adjust = 2.25) +
  geom_label(
    data = arranged_labels,
    aes(x = x, y = y, label = label),
    position = position_nudge(y = 0.2),
    size = 5
  ) +
  scale_color_venn_mix(df, sets = sets, guide = 'none') +
  labs(title = "G4 Venn Diagram: G4H, G4NN, QGRS") +
  theme(plot.title = element_text(hjust = 0.5, size = 14, face = "bold"))

