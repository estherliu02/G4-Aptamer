
library(DBI)
library(RSQLite)
library(dplyr)
library(UpSetR)

# Connect to SQLite
con <- dbConnect(RSQLite::SQLite(), your_data_path)

# SQL query with NA handling
query <- "
SELECT Seq,
       COALESCE(\"2nd_read(%)\", 0) AS Read2,
       COALESCE(\"3rd_read(%)\", 0) AS Read3,
       COALESCE(\"4th_read(%)\", 0) AS Read4,
       COALESCE(\"5th_read(%)\", 0) AS Read5,
       COALESCE(QGRS_score, 0) AS QGRS,
       COALESCE(G4H, 0) AS G4H,
       COALESCE(G4NN, 0) AS G4NN
FROM all_info;
"
df <- dbGetQuery(con, query)
total <- nrow(df)
top_n <- ceiling(0.10 * total)

# Create flags
df <- df %>%
  mutate(
    G4H = G4H > 1,
    G4NN = G4NN > 0.5,
    Top10 = rank(-Read2, ties.method = "min") <= top_n |
      rank(-Read3, ties.method = "min") <= top_n |
      rank(-Read4, ties.method = "min") <= top_n |
      rank(-Read5, ties.method = "min") <= top_n,
    QGRS = QGRS > 50,
    Trend = Read2 <= Read3 & Read3 <= Read4 & Read4 <= Read5
  )

# Count the 10 requested intersections
counts <- list(
  #"G4H" = sum(df$G4H & !df$G4NN & !df$QGRS & !df$Top10 & !df$Trend),
  #"G4NN" = sum(!df$G4H & df$G4NN & !df$QGRS & !df$Top10 & !df$Trend),
  #"QGRS" = sum(!df$G4H & !df$G4NN & df$QGRS & !df$Top10 & !df$Trend),
  #"Top10%" = sum(!df$G4H & !df$G4NN & !df$QGRS & df$Top10 & !df$Trend),
  #"Trend" = sum(!df$G4H & !df$G4NN & !df$QGRS & !df$Top10 & df$Trend),
  
  #"G4H&G4NN" = sum(df$G4H & df$G4NN & !df$QGRS & !df$Top10 & !df$Trend),
  #"G4NN&QGRS" = sum(!df$G4H & df$G4NN & df$QGRS & !df$Top10 & !df$Trend),
  #"G4H&QGRS" = sum(df$G4H & !df$G4NN & df$QGRS & !df$Top10 & !df$Trend),
  
  "Top10%&Trend" = sum(!df$G4H & !df$G4NN & !df$QGRS & df$Top10 & df$Trend),
  
  "G4H&G4NN&QGRS" = sum(df$G4H & df$G4NN & df$QGRS & !df$Top10 & !df$Trend),
  "G4H&G4NN&QGRS&Top10%" = sum(df$G4H & df$G4NN & df$QGRS & df$Top10 & !df$Trend),
  "G4H&G4NN&QGRS&Trend" = sum(df$G4H & df$G4NN & df$QGRS & !df$Top10 & df$Trend),
  "G4H&G4NN&QGRS&Top10%&Trend" = sum(df$G4H & df$G4NN & df$QGRS & df$Top10 & df$Trend),
  
  "Top10%&Trend&QGRS" = sum(!df$G4H & !df$G4NN & df$QGRS & df$Top10 & df$Trend),
  "Top10%&Trend&G4NN" = sum(!df$G4H & df$G4NN & !df$QGRS & df$Top10 & df$Trend),
  "Top10%&Trend&G4H" = sum(df$G4H & !df$G4NN & !df$QGRS & df$Top10 & df$Trend),
  "Top10%&Trend&G4H&G4NN" = sum(df$G4H & df$G4NN & !df$QGRS & df$Top10 & df$Trend)
)

# Convert to UpSetR expression format
input_expr <- fromExpression(counts)

# Plot
upset(
  input_expr,
  sets = c("G4H", "G4NN", "QGRS", "Top10%", "Trend"),
  keep.order = FALSE,
  sets.bar.color = "#5DA5DA",
  main.bar.color = "#FAA43A",
  text.scale = 1.3,
  mainbar.y.label = "Intersection Size",
  sets.x.label = "Set Size",
  order.by = "freq",
  set_size.show = TRUE,
  set_size.scale_max = 60000
)