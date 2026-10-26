/*
    Project: Automated File Archiving and Extraction Using SAS
    Original program: AutoZipFile-v1.sas
    Original author: John Jason D. Alfonso
    Original date: March 30, 2015

    Purpose:
      - Archive selected files into a RAR archive.
      - Optionally password-protect the archive.
      - Optionally delete source files after archiving.
      - Extract files from an archive to a destination directory.

    Legacy implementation notes:
      - Uses Windows command execution and assumes WinRAR is installed.
      - Review and test commands in a safe test directory before use.
      - Do not use on production or sensitive files without appropriate
        validation, permissions, and safeguards.
*/

/* Add selected files to an archive. Subfolders are not recursively added. */
%macro zip(
    Path,       /* Directory containing source files */
    CopyTo,     /* Directory where the archive will be stored */
    ArchName,   /* Archive name, without .rar extension */
    FileName,   /* File pattern/name; * selects all files in Path */
    df,         /* Nonzero: delete source files after archiving; 0: retain */
    pass,       /* Nonzero: password-protect archive; 0: no password */
    password    /* Password value when pass is nonzero */
);

    options noxwait noxsync;

    %if &pass ne 0 and &df ne 0 %then %do;
        %put NOTE: File archiving requested with deletion and password protection.;
        x "start winrar a -ep1 -df -p&password &CopyTo.\&ArchName..rar &Path.\&FileName";
    %end;
    %else %if &pass = 0 and &df ne 0 %then %do;
        %put NOTE: File archiving requested with deletion and no password protection.;
        x "start winrar a -ep1 -df &CopyTo.\&ArchName..rar &Path.\&FileName";
    %end;
    %else %if &pass ne 0 and &df = 0 %then %do;
        %put NOTE: File archiving requested with password protection; source files retained.;
        x "start winrar a -ep1 -p&password &CopyTo.\&ArchName..rar &Path.\&FileName";
    %end;
    %else %do;
        %put NOTE: File archiving requested without deletion or password protection.;
        x "start winrar a -ep1 &CopyTo.\&ArchName..rar &Path.\&FileName";
    %end;

%mend zip;


/* Extract selected files from a RAR archive to a destination directory. */
%macro unzip(
    Path,       /* Directory containing the archive */
    CopyTo,     /* Destination directory for extracted files */
    ArchName,   /* Archive name, including .rar if desired */
    FileName    /* File pattern/name to extract */
);

    options noxwait noxsync;

    x "start winrar x -ep &Path.\&ArchName &FileName &CopyTo.";

%mend unzip;


/*
    Example calls (edit paths and values before use):

    %zip(
        Path=C:\Example\Source,
        CopyTo=C:\Example\Archive,
        ArchName=sample_archive,
        FileName=*,
        df=0,
        pass=0,
        password=
    );

    %unzip(
        Path=C:\Example\Archive,
        CopyTo=C:\Example\Extracted,
        ArchName=sample_archive.rar,
        FileName=*
    );

    Do not run the example calls without replacing the paths and testing
    the command behavior in a safe, non-production directory.
*/
