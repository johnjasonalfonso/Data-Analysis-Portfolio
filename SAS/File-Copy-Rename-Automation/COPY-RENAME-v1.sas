/*
    Project: Automated File Copying and Renaming Using SAS
    Original program: COPY-RENAME-v1.sas
    Original author: John Jason D. Alfonso

    Purpose:
      Copy files from a source location to a destination directory,
      with an optional rename operation after copying.

    Legacy implementation notes:
      - Uses Windows shell commands invoked from SAS.
      - Review command syntax and test in a safe, non-production directory.
      - Wildcard copying and renaming multiple files may require separate
        handling; this macro's rename logic is best suited to a single file.
      - Ensure source and destination paths are authorized and non-sensitive.
*/

%macro COPYFILE(
    copyfrom, /* Source directory containing the files */
    file,     /* Filename or wildcard pattern to copy */
    copyto,   /* Destination directory */
    newfile   /* Optional new filename after copying */
);

    options noxwait;

    /* Create the destination directory if it does not already exist. */
    x mkdir "&copyto.";

    %put NOTE: COPYING FILE;

    /* Copy the selected file(s) to the destination directory. */
    x copy "&copyfrom.\&file." "&copyto.";

    /* Rename the copied file when a new name is supplied. */
    %if %length(%superq(newfile)) > 0 %then %do;
        x rename "&copyto.\&file." "&newfile.";

        %put NOTE: MACRO COPYFILE DONE;
        %put NOTE: Source file &copyfrom.\&file. copied to &copyto.;
    %end;
    %else %do;
        %put NOTE: MACRO COPYFILE DONE;
        %put NOTE: Source file(s) &copyfrom.\&file. copied to &copyto.;
    %end;

%mend COPYFILE;


/*
    Example call (edit paths and values before use):

    %COPYFILE(
        C:\Example\Source,
        report.csv,
        C:\Example\Destination,
        report_archive.csv
    );

    Test first with non-sensitive sample files. This reconstructed
    example has not been executed in SAS or validated on Windows.
*/
