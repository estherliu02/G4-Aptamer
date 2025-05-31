library(ggplot2)
library(dplyr)
library(tidyr)

# Input data with check.names = FALSE to preserve column names
df <- data.frame(
  TestID = c("Seq 1844", "Seq 2019", "Seq 2354", "Seq 2501", "Seq 2875", "Seq 11324", "Seq 11420", "Seq 11421", "Seq 11596", "Seq 11598"),
  "2nd Round" = c(0.0005, 0.0005, 0.0003, 0.0002, 0.0012, 0.0002, 0.0003, 0.0005, 0.0002, 0.0003),
  "3rd Round" = c(0.0016, 0.0023, 0.0024, 0.0011, 0.0019, 0.0015, 0.0011, 0.0009, 0.0010, 0.0004),
  "4th Round" = c(0.0027, 0.0027, 0.0026, 0.0019, 0.0019, 0.0015, 0.0021, 0.0010, 0.0011, 0.0009),
  "5th Round" = c(0.0073, 0.0064, 0.0039, 0.0027, 0.0020, 0.0020, 0.0023, 0.0016, 0.0015, 0.0015),
  check.names = FALSE
)

# Convert to long format and preserve ordering
df_long <- df %>%
  mutate(TestID = factor(TestID, levels = TestID)) %>%
  pivot_longer(cols = -TestID, names_to = "Round", values_to = "Percentage") %>%
  mutate(Round = factor(Round, levels = c("2nd Round", "3rd Round", "4th Round", "5th Round")))

# Plot
ggplot(df_long, aes(x = Round, y = Percentage, group = TestID, color = TestID)) +
  geom_line(size = 1.2) +
  geom_text(
    data = df_long %>% filter(Round == "5th Round"),
    aes(label = TestID),
    hjust = -0.1, size = 5, show.legend = FALSE
  ) +
  theme_minimal() +
  theme(
    axis.title = element_text(size = 16, face = "bold"),
    axis.text = element_text(size = 14),
    legend.title = element_text(size = 15, face = "bold"),
    legend.text = element_text(size = 13),
    axis.text.x = element_text(angle = 0, hjust = 1)
  ) +
  labs(
    x = "Selection Round",
    y = "Read Percentage",
    color = "TestID"
  )
