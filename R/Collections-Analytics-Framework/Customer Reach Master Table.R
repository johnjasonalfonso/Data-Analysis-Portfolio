
# ==============================================================================
# COLLECTIONS ANALYTICS FRAMEWORK
# Customer Reach
# North Star - Recovery Rate
# ==============================================================================

# ==============================================================================
# 0. LOAD REQUIRED PACKAGES
# ==============================================================================

library(dplyr)
library(gt)
library(corrplot)
library(Hmisc)
library(readr)
library(purrr)
library(lubridate)
library(stringr)
library(readxl)
library(writexl)
library(ggplot2)

# ==============================================================================
# 1. IMPORT AND COMBINE MONTHLY DATA
# ==============================================================================

file_path <- "/Users/jjalfonso/Documents/Work/Adhoc/Collections/Productivity"

month_labels <- c(
  "Jun 2025", "Jul 2025", "Aug 2025", "Sep 2025", "Oct 2025",
  "Nov 2025", "Dec 2025", "Jan 2026", "Feb 2026", "Mar 2026"
)

filenames <- file.path(
  file_path,
  paste0("Contact Rate - ", month_labels, " EOM.xlsx")
)

read_and_prep <- function(file_path) {
  if (file.exists(file_path)) {
    read_excel(file_path) %>%
      rename_all(~ make.names(.)) %>%
      mutate(across(everything(), as.character))
  } else {
    NULL
  }
}

# Combine monthly files in chronological order
df_master <- filenames %>%
  set_names(month_labels) %>%
  map_df(read_and_prep, .id = "Report_Month") %>%
  mutate(Report_Month = factor(Report_Month, levels = month_labels))

# ==============================================================================
# 2. CLEAN DATA TYPES AND STANDARDIZE FIELDS
# ==============================================================================

df_master <- df_master %>%
  mutate(
    across(
      c(Total.Payments, PTP.Amount, All_Attempts, Kept.PTP),
      as.numeric
    ),
    across(
      matches("Date|Dt|_Dt"),
      function(x) {
        num_x <- suppressWarnings(as.numeric(x))
        date_x <- as.Date(num_x, origin = "1899-12-30")

        if (all(is.na(date_x)) && !all(is.na(x))) {
          date_x <- as.Date(
            parse_date_time(x, orders = c("ymd", "mdy", "dmy"))
          )
        }

        return(date_x)
      }
    )
  )

# ==============================================================================
# 3. DEDUPLICATION AND FEATURE ENGINEERING
# ==============================================================================

df_master <- df_master %>%
  mutate(
    Loan.No = as.character(trimws(Loan.No))
  ) %>%

  # Standardize operational counts
  mutate(
    Total_Payments_Num = coalesce(
      as.numeric(as.character(Total.Payments)), 0
    ),
    All_Attempts_Num = coalesce(
      as.numeric(as.character(All_Attempts)), 0
    ),
    Call_Attempts_Num = coalesce(
      as.numeric(as.character(Call_Attempts)), 0
    ),
    SMS_Attempts_Num = coalesce(
      as.numeric(as.character(SMS_Attempts)), 0
    ),
    Email_Attempts_Num = coalesce(
      as.numeric(as.character(Email_Attempts)), 0
    ),
    PTP.Amount_Num = coalesce(
      as.numeric(gsub(",", "", as.character(PTP.Amount))), 0
    ),
    Kept.PTP_Num = coalesce(
      as.numeric(as.character(Kept.PTP)), 0
    )
  ) %>%

  # Retain one record per loan per reporting month,
  # prioritizing the record with the highest call attempt count
  group_by(Loan.No, Report_Month) %>%
  arrange(desc(All_Attempts_Num)) %>%
  slice(1) %>%
  ungroup() %>%

  # Create DPD classifications and operational measures
  mutate(
    Bucket_Label = case_when(
      DPD.Bucket == "M0" ~ "Current",
      DPD.Bucket == "M1" ~ "1-30 DPD",
      DPD.Bucket == "M2" ~ "31-60 DPD",
      DPD.Bucket == "M3" ~ "61-90 DPD",
      DPD.Bucket == "M4" ~ "91-120 DPD",
      DPD.Bucket == "M5" ~ "121-150 DPD",
      DPD.Bucket == "M6" ~ "151-180 DPD",
      DPD.Bucket == "M7" ~ "181-210 DPD",
      DPD.Bucket == "M8" ~ "211-240 DPD",
      DPD.Bucket == "M9" ~ "241-270 DPD",
      DPD.Bucket %in% c("M10", "xM10") ~ "271-300 DPD",
      DPD.Bucket %in% c("M11", "xM11") ~ "301-330 DPD",
      DPD.Bucket %in% c("M12", "xM12") ~ "331-360 DPD",
      DPD.Bucket %in% c("M12+", "xM12+") ~ "361+ DPD",
      TRUE ~ "Other/Unknown"
    ),

    Bucket_Label = factor(
      Bucket_Label,
      levels = c(
        "Current", "1-30 DPD", "31-60 DPD", "61-90 DPD",
        "91-120 DPD", "121-150 DPD", "151-180 DPD",
        "181-210 DPD", "211-240 DPD", "241-270 DPD",
        "271-300 DPD", "301-330 DPD", "331-360 DPD",
        "361+ DPD"
      )
    ),

    # Payment indicators
    Paid_Flag = ifelse(Total_Payments_Num > 0, 1, 0),
    Recovery_Mns = Total_Payments_Num / 1e6,

    # Date fields
    Date_First_Worked = as.Date(
      parse_date_time(First.Worked.Date, orders = c("mdy", "ymd", "dmy"))
    ),
    Date_Endo = as.Date(
      parse_date_time(Endo.Date, orders = c("mdy", "ymd", "dmy"))
    ),
    Date_First_PTP = as.Date(
      parse_date_time(First.PTP.Date, orders = c("mdy", "ymd", "dmy"))
    ),
    Date_PTP = as.Date(
      parse_date_time(PTP.Date, orders = c("mdy", "ymd", "dmy"))
    ),
    Date_Calling = as.Date(
      parse_date_time(Calling.Date, orders = c("mdy", "ymd", "dmy"))
    ),
    Date_First_RPC = as.Date(
      parse_date_time(First.RPC.Date, orders = c("mdy", "ymd", "dmy"))
    ),

    # Collection activity measures
    Work_Lag = as.numeric(
      difftime(Date_First_Worked, Date_Endo, units = "days")
    ),
    Nego_TAT = as.numeric(
      difftime(Date_First_PTP, Date_First_Worked, units = "days")
    ),
    PTP_Lifetime_Lag = as.numeric(
      difftime(Date_PTP, Date_First_PTP, units = "days")
    ),

    Fulfillment_Ratio = pmin(
      Total_Payments_Num / pmax(PTP.Amount_Num, 1), 1
    ),
    Is_Fulfilled = ifelse(Fulfillment_Ratio >= 0.9, 1, 0),
    Integrity_Ratio = Kept.PTP_Num / pmax(All_Attempts_Num, 1),

    # Calling calendar measures
    Day_Num = wday(Date_Calling),
    Call_Weekday = weekdays(Date_Calling),
    Call_Weekday = factor(
      Call_Weekday,
      levels = c(
        "Monday", "Tuesday", "Wednesday", "Thursday",
        "Friday", "Saturday", "Sunday"
      )
    ),
    Is_Weekend = ifelse(
      Call_Weekday %in% c("Saturday", "Sunday"),
      "Weekend", "Weekday"
    ),

    # Call attempt intensity bands
    Attempt_Band_1 = factor(
      case_when(
        All_Attempts_Num == 0 ~ "0",
        All_Attempts_Num >= 1 & All_Attempts_Num <= 25 ~ "1-25",
        All_Attempts_Num >= 26 & All_Attempts_Num <= 100 ~ "26-100",
        All_Attempts_Num >= 101 & All_Attempts_Num <= 200 ~ "101-200",
        All_Attempts_Num >= 201 & All_Attempts_Num <= 350 ~ "201-350",
        All_Attempts_Num > 350 ~ ">350"
      ),
      levels = c("0", "1-25", "26-100", "101-200", "201-350", ">350")
    )
  )

# ==============================================================================
# 4. MASTER PORTFOLIO EXECUTIVE SUMMARY
# ==============================================================================

bucket_order <- c(
  "Current", "1-30 DPD", "31-60 DPD", "61-90 DPD",
  "91-120 DPD", "121-150 DPD", "151-180 DPD",
  "181-210 DPD", "211-240 DPD", "241-270 DPD",
  "271-300 DPD", "301-330 DPD", "331-360 DPD",
  "361+ DPD"
)

# Use the prepared dataset from the previous steps
df_master_clean <- df_master %>%
  mutate(
    Granular_DPD = factor(Bucket_Label, levels = bucket_order),
    RPC_Num = coalesce(as.numeric(as.character(RPC)), 0),
    Delinquency_Bal = coalesce(
      as.numeric(gsub(",", "", as.character(P.I))), 0
    )
  )

# ==============================================================================
# 5. MASTER AGGREGATION
# ==============================================================================

df_executive_summary <- df_master_clean %>%
  group_by(Granular_DPD) %>%
  summarise(
    Total_Accounts = n(),

    # Velocity and collection effort
    Avg_Dial_Trimmed = mean(
      Call_Attempts_Num, trim = 0.05, na.rm = TRUE
    ),
    Avg_Work_Lag = mean(
      Work_Lag, na.rm = TRUE
    ),

    # Contact efficiency
    Dials_per_RPC = sum(
      Call_Attempts_Num, na.rm = TRUE
    ) / pmax(sum(RPC_Num == 1, na.rm = TRUE), 1),

    # Contacted pool
    Contacted_Rate = (
      sum(RPC_Num == 1, na.rm = TRUE) / n()
    ) * 100,

    RPC_Pay_Rate = (
      sum(
        RPC_Num == 1 & Total_Payments_Num > 0,
        na.rm = TRUE
      ) / pmax(sum(RPC_Num == 1, na.rm = TRUE), 1)
    ) * 100,

    # Non-contacted pool
    Never_Dialed_Rate = (
      sum(All_Attempts_Num == 0, na.rm = TRUE) / n()
    ) * 100,

    Silent_Pay_Rate = (
      sum(
        All_Attempts_Num == 0 & Total_Payments_Num > 0,
        na.rm = TRUE
      ) / pmax(sum(All_Attempts_Num == 0, na.rm = TRUE), 1)
    ) * 100,

    # Financial recovery
    Recovery_Rate_Pct = (
      sum(Total_Payments_Num, na.rm = TRUE) /
        pmax(sum(Delinquency_Bal, na.rm = TRUE), 1)
    ) * 100,

    .groups = "drop"
  )

# ==============================================================================
# 6. RENDER EXECUTIVE GT TABLE
# ==============================================================================

tbl_executive <- df_executive_summary %>%
  gt(id = "master_executive_summary") %>%

  cols_label(
    Granular_DPD = "DPD Bucket",
    Total_Accounts = "Total Accounts",
    Avg_Dial_Trimmed = "Avg Dials (Trimmed)",
    Avg_Work_Lag = "Avg Work Lag",
    Dials_per_RPC = "Dials per RPC",
    Contacted_Rate = "RPC Rate (%)",
    RPC_Pay_Rate = "RPC Pay Rate (%)",
    Never_Dialed_Rate = "Never Dialed (%)",
    Silent_Pay_Rate = "Silent Pay Rate (%)",
    Recovery_Rate_Pct = "Total Recovery Rate (%)"
  ) %>%

  fmt_number(columns = Total_Accounts, decimals = 0) %>%
  fmt_number(
    columns = c(Avg_Dial_Trimmed, Avg_Work_Lag, Dials_per_RPC),
    decimals = 1
  ) %>%
  fmt_percent(
    columns = c(
      Contacted_Rate, RPC_Pay_Rate,
      Never_Dialed_Rate, Silent_Pay_Rate,
      Recovery_Rate_Pct
    ),
    scale_values = FALSE,
    decimals = 1
  ) %>%

  # Column groupings
  tab_spanner(
    label = "Velocity & Effort",
    columns = c(Avg_Dial_Trimmed, Avg_Work_Lag, Dials_per_RPC)
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
    style = cell_borders(
      sides = "left",
      color = "#A6ACAF",
      style = "solid",
      weight = px(2)
    ),
    locations = list(
      cells_body(columns = Recovery_Rate_Pct),
      cells_column_labels(columns = Recovery_Rate_Pct)
    )
  )

print(tbl_executive)

# ==============================================================================
# 7. EXPORT EXECUTIVE SUMMARY
# ==============================================================================

export_path <- file.path(getwd(), "results")

if (!dir.exists(export_path)) {
  dir.create(export_path, recursive = TRUE)
}

gtsave(
  tbl_executive,
  filename = file.path(export_path, "Executive_Summary_Matrix.png"),
  zoom = 2.5
)

# ==============================================================================
# END OF COLLECTIONS ANALYTICS FRAMEWORK
# ==============================================================================
