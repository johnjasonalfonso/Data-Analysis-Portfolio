/*
    Project: Automated Download-File Cleanup Using SAS
    Program: DELETE-DLFiles-v1.sas
    Author: John Jason D. Alfonso

    Purpose:
      Demonstration template for identifying and cleaning selected file types
      from configured directories, counting discovered/selected files, and
      writing a dated run log.

    IMPORTANT:
      - This public portfolio version uses example paths only.
      - It has NOT been executed or validated in SAS.
      - File deletion is destructive. Review every path and file filter first.
      - Run in DRY_RUN mode and inspect the log before enabling deletion.
      - The original program included a separate holiday-check dependency.
        Add a reviewed, authorized holiday-check program if required.
*/

options compress=yes nosymbolgen nosource;

/* Configure these example paths before use. */
%let dry_run = 1;  /* 1 = list intended deletions only; 0 = perform deletions */

%let asccend_path = C:\Example\ASCCEND-DL;
%let phoenix_path = C:\Example\PHOENIX-DL;
%let ccts_path    = C:\Example\BCAD_CCS;
%let log_path     = C:\Example\Logs;

/*
  Optional dependency:
  The original program included a holiday-check SAS program before cleanup.
  This portfolio template intentionally does not include an internal path
  or assume that dependency is available.
*/


/* Helper macro: enumerate files in a directory into a SAS data set. */
%macro list_directory(path=, out=);
    data &out;
        length item $512 fullpath $1024;
        rc = filename("dirref", "&path");
        did = dopen("dirref");

        if did > 0 then do;
            num = dnum(did);
            do i = 1 to num;
                item = dread(did, i);
                fullpath = catx('\', "&path", item);
                output;
            end;
            rc = dclose(did);
        end;
        else do;
            put "WARNING: Unable to open directory &path";
        end;

        rc = filename("dirref");
        keep item fullpath;
    run;
%mend list_directory;


/* ASCCEND-DL: identify all entries for review. */
%list_directory(path=&asccend_path, out=asccend_entries);

data asccend_cleanup;
    set asccend_entries;
    length file_type $12;
    file_type = "ALL_ENTRIES";
run;


/* PHOENIX-DL: select BCP files only. */
%list_directory(path=&phoenix_path, out=phoenix_entries);

data phoenix_cleanup;
    set phoenix_entries;
    if lowcase(scan(item, -1, '.')) = 'bcp';
run;


/* BCAD_CCS: select TXT and CSV files. */
%list_directory(path=&ccts_path, out=ccts_entries);

data ccts_txt_cleanup;
    set ccts_entries;
    if lowcase(scan(item, -1, '.')) = 'txt';
run;

data ccts_csv_cleanup;
    set ccts_entries;
    if lowcase(scan(item, -1, '.')) = 'csv';
run;


/* Count candidate entries before any deletion is attempted. */
proc sql noprint;
    select count(*) into :asccend_count trimmed from asccend_cleanup;
    select count(*) into :phoenix_count trimmed from phoenix_cleanup;
    select count(*) into :ccts_txt_count trimmed from ccts_txt_cleanup;
    select count(*) into :ccts_csv_count trimmed from ccts_csv_cleanup;
quit;

%put NOTE: ASCCEND-DL candidate entries: &asccend_count;
%put NOTE: PHOENIX-DL BCP candidates: &phoenix_count;
%put NOTE: BCAD_CCS TXT candidates: &ccts_txt_count;
%put NOTE: BCAD_CCS CSV candidates: &ccts_csv_count;


/*
  DRY-RUN / DELETE PHASE

  In dry-run mode, the program only writes the candidate paths to the log.
  Set dry_run=0 only after verifying the paths and file lists.
*/
%macro process_candidates(data=, label=);
    data _null_;
        set &data;
        length action $20;
        %if &dry_run = 1 %then %do;
            action = "DRY RUN - NOT DELETED";
            put action ": " fullpath;
        %end;
        %else %do;
            rc = filename("target", fullpath);
            delete_rc = fdelete("target");
            if delete_rc = 0 then
                put "DELETE REQUEST SUCCEEDED: " fullpath;
            else
                put "WARNING: DELETE FAILED (return code=" delete_rc +(-1) "): " fullpath;
            rc = filename("target");
        %end;
    run;
%mend process_candidates;

%process_candidates(data=asccend_cleanup, label=ASCCEND-DL);
%process_candidates(data=phoenix_cleanup, label=PHOENIX-DL);
%process_candidates(data=ccts_txt_cleanup, label=BCAD_CCS TXT);
%process_candidates(data=ccts_csv_cleanup, label=BCAD_CCS CSV);


/* Summary output. This reports candidates, not guaranteed successful deletions. */
data _null_;
    put "DOWNLOAD-FILE CLEANUP SUMMARY";
    put "ASCCEND-DL entries selected: &asccend_count";
    put "PHOENIX-DL BCP files selected: &phoenix_count";
    put "BCAD_CCS TXT files selected: &ccts_txt_count";
    put "BCAD_CCS CSV files selected: &ccts_csv_count";
    %if &dry_run = 1 %then %do;
        put "MODE: DRY RUN - no files were deleted";
    %end;
    %else %do;
        put "MODE: DELETE - inspect individual return codes above";
    %end;
run;

/*
  Portfolio notes:
    - Counts represent candidate entries selected by the filters.
    - A successful FDELETE return code is logged for individual files.
    - This is a demonstration template, not a drop-in replacement for the
      original operational job.
    - Test in an isolated directory with sample files before use.
*/
