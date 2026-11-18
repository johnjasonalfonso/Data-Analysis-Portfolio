# SQL Analytics Projects

This folder contains SQL-based analytics projects focused on portfolio performance monitoring, company-level segmentation, credit maturity analysis, and automated business reporting.

Projects leverage Snowflake SQL to integrate multiple data sources, develop business-relevant KPIs, automate recurring reporting, and translate loan-level data into actionable insights for portfolio monitoring and customer strategy decision-making.

## Projects

### 1. Company-Level Maturity, KPI Monitoring & Portfolio Segmentation

- Developed a monthly company-level KPI monitoring framework using Snowflake SQL.
- Integrated loan-level data, salary dip metrics, and company attrition views using optimized CTEs and date matching.
- Established KPIs covering portfolio volume, employee penetration, income stability, affordability, conversion efficiency, delinquency, and company retention.
- Collaborated with business heads to define and align KPI requirements.
- **Business Impact:** Adopted by UnionDigital Bank's Customer Strategy Head for monthly company performance and portfolio monitoring.

### 2. Daily Bookings & Conversion Reporting Automation

- Developed Snowflake SQL queries to consolidate daily bookings, loan amounts, and lead volumes for bookings and conversion performance monitoring.
- Applied CTEs and window functions to calculate cumulative lead baselines and map lead volumes to booking activity dates.
- Integrated booking records with loan details, including offered terms, booked terms, and interest rates.
- Implemented deduplication and conditional logic to prevent duplicate loan records and repeated lead baseline counts.
- Simplified SQL scripts so team members could execute queries without manually modifying the code.
- Integrated SQL outputs into an Amazon QuickSight dashboard for daily performance monitoring.
- **Business Impact:** Automated previously manual Excel-based bookings and conversion reporting, saving 2+ man-hours daily in report preparation for a 10-person team. Dashboard development and implementation were completed in less than 3 days.

## Technical Skills

- Snowflake SQL
- Common Table Expressions (CTEs)
- Window Functions
- Data Integration & Aggregation
- KPI Development
- Portfolio Segmentation
- Data Validation & Deduplication
- Reporting Automation
- Business Intelligence & Analytics
