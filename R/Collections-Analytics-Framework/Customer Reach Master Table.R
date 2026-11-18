library(dplyr)
library(gt)

# ==============================================================================
# 1. SETUP & MASTER PIPELINE (COMBINING ALL REQUIREMENTS)
# ==============================================================================
bucket_order <- c("Current", "1-30 DPD", "31-60 DPD", "61-90 DPD", "91-120 DPD", 
                  "121-150 DPD", "151-180 DPD", "181-210 DPD", "211-240 DPD", 
                  "241-270 DPD", "271-300 DPD", "301-330 DPD", "331-360 DPD", 
                  "361+ DPD")

df_master_clean <- df_final_clean %>%
  mutate(
    Granular_DPD       = factor(Bucket_Label, levels = bucket_order),
    Call_Attempts_Num  = coalesce(as.numeric(as.character(Call_Attempts)), 0),
    Work_Lag_Num       = coalesce(as.numeric(as.character(Work_Lag)), 0),
    All_Attempts_Num   = coalesce(as.numeric(as.character(All_Attempts)), 0),
    RPC_Num            = coalesce(as.numeric(as.character(RPC)), 0),
    Total_Payments_Num = coalesce(as.numeric(as.character(Total.Payments)), 0),
    Delinquency_Bal    = coalesce(as.numeric(gsub(",", "", as.character(P.I))), 0)
  )

# ==============================================================================
# 2. MASTER AGGREGATION
# ==============================================================================
df_executive_summary <- df_master_clean %>%
  group_by(Granular_DPD) %>%
  summarise(
    Total_Accounts       = n(),
    
    # Requirement 1: Velocity / Effort
    Avg_Dial_Trimmed     = mean(Call_Attempts_Num, trim = 0.05, na.rm = TRUE),
    Avg_Work_Lag         = mean(Work_Lag_Num, na.rm = TRUE),
    
    # Requirement 4: Contact Efficiency (Dials required per 1 RPC)
    Dials_per_RPC        = sum(Call_Attempts_Num, na.rm = TRUE) / 
                             pmax(sum(RPC_Num == 1, na.rm = TRUE), 1),
    
    # Requirement 2: Contacted Pool Penetration & Conversion
    Contacted_Rate       = (sum(RPC_Num == 1, na.rm = TRUE) / n()) * 100,
    RPC_Pay_Rate         = (sum(RPC_Num == 1 & Total_Payments_Num > 0, na.rm = TRUE) / 
                              pmax(sum(RPC_Num == 1, na.rm = TRUE), 1)) * 100,
    
    # Requirement 3: Non Contacted Pool / Omission
    Never_Dialed_Rate    = (sum(All_Attempts_Num == 0, na.rm = TRUE) / n()) * 100,
    Silent_Pay_Rate      = (sum(All_Attempts_Num == 0 & Total_Payments_Num > 0, na.rm = TRUE) / 
                              pmax(sum(All_Attempts_Num == 0, na.rm = TRUE), 1)) * 100,
    
    # Ultimate Financial Outcome
    Recovery_Rate_Pct    = (sum(Total_Payments_Num, na.rm = TRUE) / 
                              pmax(sum(Delinquency_Bal, na.rm = TRUE), 1)) * 100,
    .groups = "drop"
  )

# ==============================================================================
# 3. RENDER EXECUTIVE GT TABLE
# ==============================================================================
tbl_executive <- df_executive_summary %>%
  gt(id = "master_executive_summary") %>%
  
  cols_label(
    Granular_DPD         = "DPD Bucket",
    Total_Accounts       = "Total Accounts",
    Avg_Dial_Trimmed     = "Avg Dials (Trimmed)",
    Avg_Work_Lag         = "Avg Work Lag",
    Dials_per_RPC        = "Dials per RPC",
    Contacted_Rate       = "RPC Rate (%)",
    RPC_Pay_Rate         = "RPC Pay Rate (%)",
    Never_Dialed_Rate    = "Never Dialed (%)",
    Silent_Pay_Rate      = "Silent Pay Rate (%)",
    Recovery_Rate_Pct    = "Total Recovery Rate (%)"
  ) %>%
  
  fmt_number(columns = Total_Accounts, decimals = 0) %>%
  fmt_number(columns = c(Avg_Dial_Trimmed, Avg_Work_Lag, Dials_per_RPC), decimals = 1) %>%
  fmt_percent(columns = c(Contacted_Rate, RPC_Pay_Rate, Never_Dialed_Rate, Silent_Pay_Rate, Recovery_Rate_Pct), 
              scale_values = FALSE, decimals = 1) %>%
  
  # Spanner Groupings
  tab_spanner(
    label = "Velocity & Effort",
    columns = c(Avg_Dial_Trimmed, Avg_Work_Lag, Dials_per_RPC) # Added Req 4 Efficiency Metric here
  ) %>%
  tab_spanner(
    label = "Contacted Pool",
    columns = c(Contacted_Rate, RPC_Pay_Rate)
  ) %>%
  tab_spanner(
    label = "Non Contacted Pool",
    columns = c(Never_Dialed_Rate, Silent_Pay_Rate)
  ) %>%
  
  tab_header(
    title = md("**Master Portfolio Executive Summary**"),
    subtitle = "Consolidated View: Velocity, Penetration, Omission, and Cash Recovery"
  ) %>%
  opt_row_striping() %>%
  tab_options(
    row.striping.background_color = "#F8F9F9",
    table.background.color = "#FFFFFF",
    heading.border.bottom.color = "grey",
    heading.border.bottom.width = px(2),
    column_labels.border.bottom.color = "grey",
    column_labels.border.bottom.width = px(1)
  ) %>%
  
  tab_style(
    style = cell_text(weight = "bold", color = "#1A252C"),
    locations = cells_body(columns = Recovery_Rate_Pct)
  ) %>%
  tab_style(
    style = cell_borders(sides = "left", color = "#A6ACAF", style = "solid", weight = px(2)),
    locations = list(
      cells_body(columns = Recovery_Rate_Pct),
      cells_column_labels(columns = Recovery_Rate_Pct)
    )
  )

print(tbl_executive)

# ==============================================================================
# 4. EXPORT TO PHASE 1 FOLDER
# ==============================================================================
export_path <- "/Users/jjalfonso/Documents/Work/Adhoc/Collections/Productivity/Phase 1 - Descriptive"

if (!dir.exists(export_path)) {
  dir.create(export_path, recursive = TRUE)
}

gtsave(tbl_executive, filename = file.path(export_path, "Executive_Summary_Matrix.png"), zoom = 2.5)
