library(shiny)
library(dplyr)
library(tidyr)
library(ggplot2)
library(scales)
library(bslib)
library(readxl) 
library(gt) # Added for the ranking table

# ==============================================================================
# 1. IMPORT & GLOBAL DATA TRANSFORMATION 
# ==============================================================================
df_attrition <- read_excel("Documents/Work/Adhoc/AI Impact/attrition.xlsx")

df_attrition_long <- df_attrition %>%
  select(COMPANY_CODE, COMPANY_NAME, INDUSTRY_NAME, starts_with("ATTR_RATE_")) %>%
  mutate(
    INDUSTRY_NAME = coalesce(INDUSTRY_NAME, "Unmapped"),
    Company_Label = paste0(COMPANY_NAME, " [", INDUSTRY_NAME, "]")
  ) %>%
  pivot_longer(
    cols = starts_with("ATTR_RATE_"),
    names_to = "YearMonth_Raw",
    values_to = "Attrition_Rate"
  ) %>%
  mutate(
    # Convert decimal output from SQL into a true percentage whole number
    Attrition_Rate = Attrition_Rate * 100, 
    YearMonth = gsub("ATTR_RATE_", "", YearMonth_Raw),
    Report_Date = as.Date(paste0(YearMonth, "01"), format = "%Y%m%d")
  ) %>%
  filter(!is.na(Attrition_Rate))

industry_choices <- sort(unique(df_attrition_long$INDUSTRY_NAME))
company_choices <- sort(unique(df_attrition_long$COMPANY_NAME))

# ==============================================================================
# 2. UI (USER INTERFACE)
# ==============================================================================
ui <- page_sidebar(
  title = "Company Attrition Analytics (Aug 2025 - Jul 2026)",
  theme = bs_theme(version = 5, primary = "#3D2D68"),
  
  sidebar = sidebar(
    title = "Controls",
    selectInput(
      inputId = "industry_filter",
      label = "Filter by Industry:",
      choices = c("All Industries", industry_choices),
      selected = "All Industries"
    ),
    selectInput(
      inputId = "company_filter",
      label = "Filter by Company:",
      choices = c("All Companies", company_choices),
      selected = "All Companies"
    ),
    hr(),
    helpText("Use the dropdowns to isolate specific segments. The peak month, trend charts, and rankings will recalculate dynamically based on your selection.")
  ),
  
  # Main display area with the new Industry Rankings tab added
  navset_card_tab(
    nav_panel("Peak Attrition Month", plotOutput("peak_plot", height = "600px")),
    nav_panel("Industry Rankings", gt_output("ranking_table")),
    nav_panel("Macro Trends", plotOutput("trend_plot", height = "600px")),
    nav_panel("Company Heatmap", plotOutput("heatmap_plot", height = "800px"))
  )
)

# ==============================================================================
# 3. SERVER LOGIC
# ==============================================================================
server <- function(input, output, session) {
  
  # Reactive dataset based on filters
  filtered_data <- reactive({
    data <- df_attrition_long
    
    if (input$industry_filter != "All Industries") {
      data <- data %>% filter(INDUSTRY_NAME == input$industry_filter)
    }
    
    if (input$company_filter != "All Companies") {
      data <- data %>% filter(COMPANY_NAME == input$company_filter)
    }
    
    return(data)
  })
  
  # --- PLOT 1: DYNAMIC PEAK ATTRITION ---
  output$peak_plot <- renderPlot({
    req(nrow(filtered_data()) > 0) 
    
    df_peak <- filtered_data() %>%
      group_by(Report_Date) %>%
      summarise(Avg_Attrition = mean(Attrition_Rate, na.rm = TRUE), .groups = "drop")
    
    max_month <- df_peak$Report_Date[which.max(df_peak$Avg_Attrition)]
    
    ggplot(df_peak, aes(x = Report_Date, y = Avg_Attrition)) +
      geom_col(aes(fill = Report_Date == max_month), width = 20) +
      scale_fill_manual(values = c("TRUE" = "#3D2D68", "FALSE" = "#E0E0E0"), guide = "none") +
      scale_x_date(date_breaks = "1 month", date_labels = "%b %Y") +
      scale_y_continuous(labels = function(x) paste0(x, "%")) + 
      theme_minimal() +
      labs(
        title = "Average Attrition Over Time",
        subtitle = "Highlighting the peak attrition month for the selected data slice",
        x = "Reporting Month",
        y = "Average Attrition Rate"
      ) +
      theme(
        axis.text.x = element_text(angle = 45, hjust = 1, size = 12),
        axis.text.y = element_text(size = 12),
        axis.title = element_text(size = 14, face = "bold"),
        panel.grid.major.x = element_blank(),
        plot.title = element_text(face = "bold", size = 18)
      )
  })
  
  # --- TABLE: INDUSTRY RANKINGS ---
  output$ranking_table <- render_gt({
    req(nrow(filtered_data()) > 0)
    
    # Aggregate and immediately sort in descending order
    df_rank <- filtered_data() %>%
      group_by(INDUSTRY_NAME) %>%
      summarise(
        Total_Companies = n_distinct(COMPANY_NAME),
        Avg_Attrition = mean(Attrition_Rate, na.rm = TRUE), 
        .groups = "drop"
      ) %>%
      arrange(desc(Avg_Attrition))
    
    df_rank %>%
      gt() %>%
      cols_label(
        INDUSTRY_NAME = "Industry",
        Total_Companies = "Company Count",
        Avg_Attrition = "Avg Attrition Rate (%)"
      ) %>%
      fmt_number(columns = Total_Companies, decimals = 0) %>%
      fmt_number(columns = Avg_Attrition, decimals = 2) %>%
      # Applies a color scale to make the highest rates instantly visible
      data_color(
        columns = Avg_Attrition,
        colors = scales::col_numeric(
          palette = c("#F0F0FA", "#3D2D68"),
          domain = NULL
        )
      ) %>%
      tab_header(
        title = md("**Industry Attrition Leaderboard**"),
        subtitle = "Ranked from highest to lowest average attrition rate"
      ) %>%
      opt_row_striping() %>%
      tab_options(
        row.striping.background_color = "#F8F9F9", 
        column_labels.font.weight = "bold", 
        table.width = pct(100)
      )
  })

  # --- PLOT 2: TREND LINES ---
  output$trend_plot <- renderPlot({
    req(nrow(filtered_data()) > 0)
    
    df_trend <- filtered_data() %>%
      group_by(Report_Date, INDUSTRY_NAME) %>%
      summarise(Avg_Attrition = mean(Attrition_Rate, na.rm = TRUE), .groups = "drop")
    
    ggplot(df_trend, aes(x = Report_Date, y = Avg_Attrition, color = INDUSTRY_NAME)) +
      geom_line(size = 1.2) +
      geom_point(size = 4) +
      scale_color_viridis_d(option = "plasma") + 
      scale_x_date(date_breaks = "1 month", date_labels = "%b %Y") +
      scale_y_continuous(labels = function(x) paste0(x, "%")) +
      theme_minimal() +
      labs(
        title = "Attrition Trends by Industry",
        x = "Reporting Month",
        y = "Average Attrition Rate"
      ) +
      theme(
        legend.position = "bottom",
        legend.title = element_blank(),
        legend.text = element_text(size = 12),
        axis.text.x = element_text(angle = 45, hjust = 1, size = 12),
        axis.title = element_text(size = 14, face = "bold"),
        plot.title = element_text(face = "bold", size = 18)
      )
  })
  
  # --- PLOT 3: COMPANY HEATMAP ---
  output$heatmap_plot <- renderPlot({
    req(nrow(filtered_data()) > 0)
    
    ggplot(filtered_data(), aes(x = Report_Date, y = reorder(Company_Label, Attrition_Rate), fill = Attrition_Rate)) +
      geom_tile(color = "white") +
      scale_fill_gradient(
        low = "#F0F0FA", 
        high = "#3D2D68", 
        name = "Attrition Rate",
        labels = function(x) paste0(x, "%")
      ) +
      scale_x_date(date_breaks = "1 month", date_labels = "%b '%y") +
      theme_minimal() +
      labs(
        title = "Company-Level Attrition Heatmap",
        subtitle = "Darker bands indicate acute attrition spikes",
        x = "Month",
        y = "Company [Industry]"
      ) +
      theme(
        axis.text.y = element_text(size = 9),
        axis.text.x = element_text(angle = 45, hjust = 1, size = 12),
        axis.title = element_text(size = 14, face = "bold"),
        panel.grid = element_blank(),
        plot.title = element_text(face = "bold", size = 18)
      )
  })
}

# ==============================================================================
# 4. RUN APP
# ==============================================================================
shinyApp(ui = ui, server = server)
