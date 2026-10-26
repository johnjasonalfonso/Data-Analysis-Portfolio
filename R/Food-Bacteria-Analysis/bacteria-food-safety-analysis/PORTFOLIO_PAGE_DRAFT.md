# Project page content for the portfolio website

Use this content in a new page named `bacteria-analysis.html` in your existing `jason-analytics-portfolio` website repository. Keep this page separate from the analysis repository.

## Food Bacteria Counts: Chilled vs. Not-Chilled Samples

### Project overview
Statistical analysis of 96 food samples to explore bacterial count distributions across chilled and not-chilled food products and observed temperature categories.

### Objectives
- Summarize CFU/g distributions by treatment group.
- Assess normality and compare bacterial counts using non-parametric methods.
- Explore differences across observed temperature categories.
- Communicate findings with reproducible R code and visualizations.

### Methods and tools
R, dplyr, ggplot2, descriptive statistics, Shapiro-Wilk tests, Wilcoxon rank-sum test, Kruskal-Wallis tests, and Bonferroni-adjusted pairwise Wilcoxon comparisons.

### Key interpretation
The supplied report describes higher CFU/g values and greater variability in the not-chilled group. The reported Wilcoxon test found a statistically significant difference between treatment groups. Temperature-group differences were also reported. Re-run the included R script and verify all values before publishing a final numeric summary.

### Limitations
The sample may not represent the wider food supply. Temperature groups have uneven sample sizes, and observed associations should not be interpreted as causal. This case study is a statistical analysis, not a food-safety certification or risk assessment.

### Files and reproducibility
The linked GitHub repository contains the data file, R analysis script, summary tables, and figures. The data should only be made public if you have permission to share it.
