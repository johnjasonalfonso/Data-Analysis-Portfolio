# Food bacteria count analysis: chilled vs. not-chilled samples
# Run from the project root in RStudio.
# Data file paths are relative to this project.

required_packages <- c("readr", "dplyr", "ggplot2", "moments", "rstatix", "readxl")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages) > 0) {
  install.packages(missing_packages)
}

library(readr)
library(dplyr)
library(ggplot2)
library(moments)
library(rstatix)

dir.create("results/tables", recursive = TRUE, showWarnings = FALSE)
dir.create("results/figures", recursive = TRUE, showWarnings = FALSE)

data_path <- "data/bacteria_data.csv"
dataset <- read_csv(data_path, show_col_types = FALSE)

required_columns <- c("Food", "Temperature", "Group", "CFUG")
if (!all(required_columns %in% names(dataset))) {
  stop("Dataset must contain: ", paste(required_columns, collapse = ", "))
}

bacteria_data <- dataset %>%
  mutate(
    Group = factor(Group, levels = c("Chilled", "Not-Chilled")),
    # Keep 0 CFU/g observations defined for visualization.
    log10_CFU_plus1 = log10(CFUG + 1),
    Temp_grp = if_else(Temperature <= 4, "0-4", as.character(Temperature)),
    Temp_grp = factor(Temp_grp, levels = c("0-4", "5", "7", "8.5", "12", "30", "32", "37"))
  )

# Descriptive statistics by treatment group
summary_by_group <- bacteria_data %>%
  group_by(Group) %>%
  summarise(
    n = sum(!is.na(CFUG)),
    mean = mean(CFUG, na.rm = TRUE),
    sd = sd(CFUG, na.rm = TRUE),
    median = median(CFUG, na.rm = TRUE),
    IQR = IQR(CFUG, na.rm = TRUE),
    minimum = min(CFUG, na.rm = TRUE),
    maximum = max(CFUG, na.rm = TRUE),
    skewness = moments::skewness(CFUG, na.rm = TRUE),
    kurtosis = moments::kurtosis(CFUG, na.rm = TRUE),
    .groups = "drop"
  )
write_csv(summary_by_group, "results/tables/summary_by_group.csv")

summary_by_temperature <- bacteria_data %>%
  group_by(Group, Temp_grp, .drop = TRUE) %>%
  summarise(
    n = sum(!is.na(CFUG)),
    mean = mean(CFUG, na.rm = TRUE),
    sd = sd(CFUG, na.rm = TRUE),
    median = median(CFUG, na.rm = TRUE),
    IQR = IQR(CFUG, na.rm = TRUE),
    minimum = min(CFUG, na.rm = TRUE),
    maximum = max(CFUG, na.rm = TRUE),
    skewness = moments::skewness(CFUG, na.rm = TRUE),
    kurtosis = moments::kurtosis(CFUG, na.rm = TRUE),
    .groups = "drop"
  )
write_csv(summary_by_temperature, "results/tables/summary_by_temperature.csv")

# Figures
p_group <- ggplot(bacteria_data, aes(x = Group, y = log10_CFU_plus1, fill = Group)) +
  geom_boxplot(alpha = 0.8, outlier.alpha = 0.65) +
  labs(
    title = "Bacterial counts by treatment group",
    subtitle = "Visualization uses log10(CFU/g + 1); raw CFU/g is retained for statistical tests",
    x = "Treatment group", y = "log10(CFU/g + 1)"
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none")
ggsave("results/figures/boxplot_by_group.png", p_group, width = 8, height = 5, dpi = 300)

p_temp <- ggplot(bacteria_data, aes(x = Temp_grp, y = log10_CFU_plus1, fill = Temp_grp)) +
  geom_boxplot(alpha = 0.8, outlier.alpha = 0.65) +
  facet_wrap(~ Group, scales = "free_x") +
  labs(
    title = "Bacterial counts across observed temperature categories",
    subtitle = "Visualization uses log10(CFU/g + 1)",
    x = "Temperature category (°C)", y = "log10(CFU/g + 1)"
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none")
ggsave("results/figures/boxplot_by_temperature.png", p_temp, width = 10, height = 5.5, dpi = 300)

# Shapiro-Wilk tests (R requires 3 to 5000 non-missing observations)
normality_results <- bacteria_data %>%
  group_by(Group) %>%
  summarise(
    n = sum(!is.na(CFUG)),
    W = unname(shapiro.test(CFUG)$statistic),
    p_value = shapiro.test(CFUG)$p.value,
    .groups = "drop"
  )
write_csv(normality_results, "results/tables/shapiro_wilk.csv")

# Two-sided Wilcoxon rank-sum test. Use a two-sided test unless a directional
# hypothesis was specified in advance and is justified by the study protocol.
wilcox_result <- wilcox.test(CFUG ~ Group, data = bacteria_data, exact = FALSE, conf.int = TRUE)
wilcox_table <- tibble(
  test = "Wilcoxon rank-sum: CFU/g by treatment group",
  statistic = unname(wilcox_result$statistic),
  p_value = wilcox_result$p.value,
  conf_low = if (!is.null(wilcox_result$conf.int)) unname(wilcox_result$conf.int[1]) else NA_real_,
  conf_high = if (!is.null(wilcox_result$conf.int)) unname(wilcox_result$conf.int[2]) else NA_real_
)
write_csv(wilcox_table, "results/tables/wilcoxon_treatment.csv")

# Kruskal-Wallis and post-hoc comparisons within each treatment group.
kw_results <- list()
pairwise_results <- list()

for (g in levels(droplevels(bacteria_data$Group))) {
  dat_g <- bacteria_data %>% filter(Group == g) %>% droplevels()
  if (nlevels(dat_g$Temp_grp) >= 2) {
    kw <- kruskal.test(CFUG ~ Temp_grp, data = dat_g)
    kw_results[[g]] <- tibble(
      Group = g,
      statistic = unname(kw$statistic),
      df = unname(kw$parameter),
      p_value = kw$p.value
    )
    pw <- pairwise.wilcox.test(
      dat_g$CFUG, dat_g$Temp_grp,
      p.adjust.method = "bonferroni",
      exact = FALSE
    )
    pw_df <- as.data.frame(as.table(pw$p.value), stringsAsFactors = FALSE)
    names(pw_df) <- c("temperature_1", "temperature_2", "adjusted_p_value")
    pw_df <- pw_df %>%
      filter(!is.na(adjusted_p_value)) %>%
      mutate(Group = g, .before = 1)
    pairwise_results[[g]] <- pw_df
  }
}
if (length(kw_results)) write_csv(bind_rows(kw_results), "results/tables/kruskal_wallis_by_group.csv")
if (length(pairwise_results)) write_csv(bind_rows(pairwise_results), "results/tables/pairwise_wilcoxon_bonferroni.csv")

message("Analysis complete. Review results/tables and results/figures before publishing.")
