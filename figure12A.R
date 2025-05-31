library(ggplot2)
library(dplyr)
library(tidyr)

# Input data with check.names = FALSE to preserve column names
df <- data.frame(
  TestID = c("Seq 1", "Seq 6", "Seq 20", "Seq 21", "Seq 22", "Seq 26", "Seq 30", "Seq 35"),
  "2nd Round" = c(0.0047, 0.0007, 0.0037, 0.0029, 0.0015, 0.0027, 0.0022, 0.0020),
  "3rd Round" = c(0.0164, 0.0130, 0.0090, 0.0094, 0.0069, 0.0061, 0.0074, 0.0073),
  "4th Round" = c(0.0628, 0.0481, 0.0268, 0.0348, 0.0256, 0.0171, 0.0203, 0.0199),
  "5th Round" = c(0.2044, 0.1341, 0.0834, 0.0826, 0.0821, 0.0751, 0.0680, 0.0621),
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
