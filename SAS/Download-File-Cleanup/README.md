# Automated Download-File Cleanup Using SAS

## Project Overview

This project demonstrates a SAS-based file-cleanup workflow designed to prepare designated download directories for subsequent file-conversion processing.

## Key Features

- Enumerates files in configured directories.
- Applies directory-specific cleanup rules.
- Removes designated file types, including BCP, TXT, and CSV files.
- Counts files selected for cleanup.
- Writes a dated execution log containing cleanup counts.
- Includes a holiday-check program before the cleanup logic.

## Technical Skills

- SAS DATA step programming
- SAS macro variables and `CALL SYMPUT`
- Directory handling with `DOPEN` and `DREAD`
- File deletion using `FDELETE`
- PROC SQL aggregation
- Execution logging with `PROC PRINTTO`

## Business Value

Automates recurring directory cleanup and provides a log of file counts to support operational monitoring and preparation for subsequent processing.

## Safety and Validation

File deletion is destructive. The original script targets internal server directories and must not be published with confidential infrastructure details. A public demonstration should use anonymized paths, a dry-run mode, and safeguards to prevent unintended deletion.

The recorded counts should not be treated as confirmation that every deletion succeeded.
