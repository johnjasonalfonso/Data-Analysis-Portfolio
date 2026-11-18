# Collections Analytics Framework

## Project Overview

Developed a Collections Analytics Framework using R to better understand collection performance, customer contactability, collection effort, and recovery rates across different Days Past Due (DPD) buckets.

The project brought together key collections measures to help identify how effectively customers were being reached, where collection efforts were concentrated, which accounts were receiving little or no attention, and where opportunities existed to improve recovery.

## Project Objectives

- Evaluate collection effort and productivity across different stages of delinquency.
- Understand how effectively collection teams reach customers.
- Identify accounts receiving limited or no collection attempts.
- Examine payment behavior among contacted and non-contacted customers.
- Assess recovery performance and identify opportunities to improve collection strategies.
- Explore differences in customer contactability across portfolio segments.

## Approach

### 1. Data Preparation

- Used R to clean, organize, and prepare historical collections data from June 2025 to March 2026.
- Standardized delinquency buckets to support consistent performance comparisons.
- Prepared collection activity, work lag, contact attempts, RPC, payment, and outstanding balance information.
- Addressed missing values and data inconsistencies before calculating the metrics.

### 2. Customer Reach & Contactability

Examined how effectively collection teams reached customers and where contact efforts could be improved.

- **Average Attempts Before First RPC:** Examined the effort required to successfully reach customers.
- **Contact Rate:** Assessed customer reach across delinquency buckets.
- **Never Dialed Rate:** Identified accounts with no recorded call attempts.
- **Work Lag:** Examined the time between account assignment and the first collection attempt.
- **Dials per RPC:** Measured the number of call attempts required for each successful Right Party Contact.

### 3. Collection Effort & Payment Behavior

Evaluated whether collection activities translated into successful customer contact and payments.

- **Average Dials:** Calculated average call attempts per account using a 5% trimmed mean.
- **RPC Rate:** Percentage of accounts successfully reached through Right Party Contact.
- **RPC Pay Rate:** Percentage of contacted accounts with recorded payments.
- **Silent Pay Rate:** Percentage of accounts that made payments without any recorded collection calls.

### 4. Recovery Performance

- Compared total payments against outstanding delinquency balances to calculate recovery rates.
- Reviewed recovery performance across DPD buckets to identify differences between early-stage and later-stage collections.
- Examined the relationship between collection effort, customer contactability, and payment outcomes.

### 5. Reporting & Visualization

- Consolidated the results into an executive summary covering collection effort, customer contactability, payment behavior, and financial recovery.
- Used R and the `gt` package to create a formatted executive summary table by DPD bucket.
- Organized the metrics into four reporting categories:
  - Velocity & Effort
  - Contacted Pool
  - Non-Contacted Pool
  - Financial Recovery
- Exported the executive summary as a high-resolution image for reporting and presentation.

## Additional Analysis Areas

The broader framework also identified opportunities for further investigation:

- **Customer Segmentation:** Compare contactability across DPD, FTB/RB, deciles, loan counts, and ticket sizes.
- **Contact Success by Attempt:** Examine how contact success changes with increasing call attempts and identify diminishing returns.
- **Channel Effectiveness:** Explore customer responses to SMS versus calls.
- **Contact Timing:** Identify when different customer segments are most responsive.
- **Collection Effort Efficiency:** Examine collection effort spent on accounts that remain unreachable or require repeated attempts.

## Key Metrics

| Area | Measures |
|---|---|
| Collection Effort | Average Dials, Average Work Lag, Dials per RPC |
| Customer Contactability | RPC Rate, Never Dialed Rate |
| Payment Behavior | RPC Pay Rate, Silent Pay Rate |
| Financial Recovery | Total Recovery Rate |

## Tools Used

- R
- dplyr – Data preparation and analysis
- gt – Executive reporting and table visualization

## Business Value

Provided a clearer view of collection performance across delinquency stages, helping identify gaps in customer contact, areas where collection efforts could be better focused, and opportunities to improve recovery efficiency without necessarily increasing collection resources.

The findings supported recommendations to prioritize early-stage collections and explore automated outreach for accounts beyond 30 DPD.
