# Collections Analytics Framework

## Project Overview

This project uses R to analyze collections performance, customer contactability, collection effort, and payment behavior across different Days Past Due (DPD) buckets.

The objective was to develop a structured framework that gives the Customer Strategy team a clearer view of how collections activities translate into customer engagement and financial recovery. The analysis covers historical collections data from **June 2025 to March 2026**.

The framework also produces an executive summary that brings key collection metrics together, helping identify performance gaps, understand collection effectiveness, and highlight areas for further investigation.

## Objectives

- Measure collection effort and productivity across DPD buckets.
- Assess customer contactability and the effectiveness of collection attempts.
- Identify accounts that have not received collection attempts.
- Compare payment behavior between contacted and non-contacted accounts.
- Evaluate recovery performance against outstanding delinquency balances.
- Identify opportunities to improve collection efficiency and resource allocation.

## Analytical Approach

### 1. Data Preparation and Integration

Developed an R workflow to consolidate monthly collections reports covering June 2025 to March 2026.

The preparation process includes:

- Importing and combining monthly Excel files.
- Standardizing column names and data types.
- Cleaning numeric fields, dates, and collection activity variables.
- Standardizing DPD bucket classifications.
- Creating derived variables for collection attempts, payments, work lag, and payment behavior.
- Removing duplicate loan records within each reporting month, retaining the record with the highest number of collection attempts.

### 2. Customer Reach and Contactability

Evaluated how effectively the collections team reaches customers using measures such as:

- RPC Rate
- Never Dialed Rate
- Average Work Lag
- Dials per RPC

These metrics help assess customer reach, collection coverage, and the effort required to establish contact.

### 3. Collection Effort and Payment Behavior

Analyzed collection activity and payment outcomes using:

- Average Dials, using a 5% trimmed mean to reduce the influence of extreme values.
- RPC Rate
- RPC Pay Rate
- Silent Pay Rate

The analysis distinguishes between accounts successfully contacted and accounts that made payments without recorded collection attempts.

### 4. Recovery Performance

Measured financial recovery by comparing total payments against outstanding delinquency balances.

Recovery performance was reviewed across DPD buckets to understand how payment outcomes vary as accounts progress through delinquency stages.

### 5. Executive Summary and Visualization

Developed an executive summary using R and the `gt` package, consolidating the key metrics into four reporting areas:

- **Velocity & Effort** – collection activity and productivity
- **Contacted Pool** – contact rates and payment behavior among contacted accounts
- **Non-Contacted Pool** – accounts without collection attempts and their payment behavior
- **Financial Recovery** – payments relative to outstanding delinquency balances

The summary is exported as a high-resolution image for reporting and presentation purposes.

## Key Metrics

| Category | Metrics |
|---|---|
| Collection Effort | Average Dials, Average Work Lag, Dials per RPC |
| Contactability | RPC Rate, Never Dialed Rate |
| Payment Behavior | RPC Pay Rate, Silent Pay Rate |
| Financial Recovery | Total Recovery Rate |

## Key Findings and Business Implications

The analysis highlighted differences in collection productivity and recovery performance across delinquency stages.

Key observations included:

- Wednesday recorded the highest collection activity.
- Thursday showed the highest collection efficiency, at approximately ₱115.80 per dial.
- Recovery rates declined to approximately 7.2% once accounts exceeded 30 DPD.

These findings supported recommendations to prioritize early-stage collections and explore automated outreach for accounts beyond 30 DPD. The intent was to improve recovery efficiency and collection coverage without necessarily increasing headcount.

The findings were presented to the Head of Customer Strategy and received positive feedback.

## Further Areas for Investigation

The framework also identified opportunities for deeper analysis:

- Customer segmentation by DPD, first-time and repeat borrowers, risk deciles, loan counts, and ticket sizes.
- Contact success by number of collection attempts.
- Effectiveness of SMS versus call-based outreach.
- Collection outcomes by contact timing.
- Collection effort spent on accounts that remain unreachable.

These are potential extensions of the analysis and should not be interpreted as completed findings.

## Tools and Technologies

- **R** – data preparation, statistical analysis, and visualization
- **dplyr** – data transformation and aggregation
- **ggplot2** – data visualization
- **gt** – executive summary reporting
- **readxl** – Excel data import

## Business Value

The framework provides a more structured view of collections performance, helping the team understand where collection effort is being spent, how effectively customers are reached, and how recovery varies across delinquency stages.

By bringing operational and financial measures into one executive summary, the analysis supports more informed discussions around collection prioritization, process improvements, and opportunities to improve recovery efficiency.
