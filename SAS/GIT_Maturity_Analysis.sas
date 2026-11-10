/*--------------------------------------------------------------------
  GIT MATURITY SURVEY ANALYSIS
  Author: Jason Alfonso
  Source: GIT_Maturity(1).xlsx | Sheet1

  Outputs:
    1. Spearman rank-correlation matrix for experience, frequency,
       usage and GIT practice scores
    2. Distribution of the five GIT practice scores
    3. Respondent-by-practice maturity heatmap
    4. Kruskal-Wallis tests (PROC NPAR1WAY) by years of Git experience
    5. Friedman repeated-measures test across the five practices

  Update the XLSX path below if the workbook is stored elsewhere.
--------------------------------------------------------------------*/

options nodate nonumber; 

/* 1. IMPORT THE EXCEL RESPONSES */
%let infile = C:\YourFolder\GIT_Maturity(1).xlsx;

proc import datafile="&infile."
    out=work.git_raw
    dbms=xlsx
    replace;
    sheet="Sheet1";
    getnames=yes;
    datarow=2;
    guessingrows=max;
run;

/* 2. CLEAN AND RECODE VARIABLES
   Years_GIT_Num: 1=Less than 1 year, 2=1-2 years, 3=3-5 years
   Frequency_Ordinal_Num: 1=Rarely, 2=Weekly, 3=Daily
*/
data work.git_clean;
    set work.git_raw;

    length Years_GIT_Num Frequency_Ordinal_Num 8;

    select (strip(upcase(Years_GIT)));
        when ('LESS THAN 1 YEAR') Years_GIT_Num=1;
        when ('1-2 YEARS')        Years_GIT_Num=2;
        when ('3-5 YEARS')        Years_GIT_Num=3;
        otherwise .;
    end;

    select (strip(upcase(Frequency_Tools)));
        when ('RARELY') Frequency_Ordinal_Num=1;
        when ('WEEKLY') Frequency_Ordinal_Num=2;
        when ('DAILY')  Frequency_Ordinal_Num=3;
        otherwise .;
    end;

    /* Keep only complete respondent records for the five practice scores. */
    if nmiss(of GIT_Usage
                Repository_Management_Recovery_Archiving
                Commit_Practices
                Branching_Strategy
                Code_Review_Merge_Conflict)=0;
run;

proc format;
    value gitexp
        1='Less than 1 year'
        2='1-2 years'
        3='3-5 years';
    value gitfreq
        1='Rarely'
        2='Weekly'
        3='Daily';
run;

/* Quick check of imported sample size and score distributions. */
proc contents data=work.git_clean varnum; run;
proc means data=work.git_clean n mean median std min max;
    var Years_ING Years_GIT_Num Frequency_Ordinal_Num GIT_Usage
        Repository_Management_Recovery_Archiving Commit_Practices
        Branching_Strategy Code_Review_Merge_Conflict;
run;

/* 3. RESHAPE THE FIVE PRACTICE SCORES TO LONG FORMAT */
data work.git_long;
    set work.git_clean;
    length Practice $55;

    Practice='Branching_Strategy';
    Score=Branching_Strategy;
    output;

    Practice='Code_Review_Merge_Conflict';
    Score=Code_Review_Merge_Conflict;
    output;

    Practice='Commit_Practices';
    Score=Commit_Practices;
    output;

    Practice='GIT_Usage';
    Score=GIT_Usage;
    output;

    Practice='Repository_Management_Recovery_Archiving';
    Score=Repository_Management_Recovery_Archiving;
    output;

    keep Name Practice Score;
run;

/* Retain a stable respondent order for the heatmap. */
data work.respondent_order;
    set work.git_clean(keep=Name);
    Respondent_Order=_n_;
run;

proc sql;
    create table work.git_heatlong as
    select a.*, b.Respondent_Order
    from work.git_long as a
    left join work.respondent_order as b
      on a.Name=b.Name;
quit;

/* 4. SPEARMAN CORRELATIONS
   OUTS= saves the Spearman correlation matrix for plotting. */
proc corr data=work.git_clean spearman nosimple outs=work.spearman_out;
    var Years_ING Years_GIT_Num Frequency_Ordinal_Num GIT_Usage
        Repository_Management_Recovery_Archiving Commit_Practices
        Branching_Strategy Code_Review_Merge_Conflict;
run;

/* Convert the OUTS= correlation matrix to a plotting dataset.
   The upper triangle (including the diagonal) is displayed. */
data work.spearman_long;
    set work.spearman_out(where=(_TYPE_='CORR'));
    length Row_Variable Col_Variable $55;
    array corrvars {*} Years_ING Years_GIT_Num Frequency_Ordinal_Num
        GIT_Usage Repository_Management_Recovery_Archiving
        Commit_Practices Branching_Strategy Code_Review_Merge_Conflict;
    array varnames[8] $55 _temporary_
        ('Years_ING' 'Years_GIT_Num' 'Frequency_Ordinal_Num' 'GIT_Usage'
         'Repository_Management_Recovery_Archiving' 'Commit_Practices'
         'Branching_Strategy' 'Code_Review_Merge_Conflict');

    Row_Variable=_NAME_;
    do j=1 to dim(corrvars);
        Col_Variable=varnames[j];
        Corr=corrvars[j];
        /* Keep only upper triangle based on the declared variable order. */
        do i=1 to dim(varnames);
            if varnames[i]=Row_Variable then Row_Order=i;
        end;
        Col_Order=j;
        if Col_Order >= Row_Order and not missing(Corr) then output;
    end;
    keep Row_Variable Col_Variable Row_Order Col_Order Corr;
run;

proc sort data=work.spearman_long;
    by Row_Order Col_Order;
run;

title "GIT Maturity Responses Spearman Correlations";
proc sgplot data=work.spearman_long noautolegend;
    heatmapparm x=Col_Variable y=Row_Variable colorresponse=Corr /
        colormodel=(red white lime) name='corr';
    text x=Col_Variable y=Row_Variable text=Corr /
        textattrs=(size=8) textformat=5.2;
    gradlegend 'corr' / title='Spearman r';
    xaxis display=(nolabel) discreteorder=data fitpolicy=rotate
          valueattrs=(size=8);
    yaxis display=(nolabel) discreteorder=data reverse
          valueattrs=(size=8);
run;
title;

/* 5. DISTRIBUTION OF GIT PRACTICE SCORES */
proc format;
    value likert
        1='1' 2='2' 3='3' 4='4';
run;

title "Distribution of GIT Practice Scores";
proc sgpanel data=work.git_long;
    panelby Practice / columns=2 novarname;
    vbar Score / stat=freq;
    colaxis label='Likert Score' values=(1 to 4 by 1);
    rowaxis label='Frequency' integer;
    format Score likert.;
run;
title;

/* 6. INDIVIDUAL RESPONDENT MATURITY HEATMAP */
proc sort data=work.git_heatlong;
    by descending Respondent_Order Practice;
run;

title "Individual GIT Maturity Ratings Responses";
proc sgplot data=work.git_heatlong;
    heatmapparm x=Practice y=Name colorresponse=Score /
        colormodel=(red lightsalmon lightgreen green) name='score';
    text x=Practice y=Name text=Score / textattrs=(size=8);
    gradlegend 'score' / title='Score' integer;
    xaxis label='Maturity Metric' discreteorder=data
          fitpolicy=rotate valueattrs=(size=8);
    yaxis label='Respondent' discreteorder=data valueattrs=(size=8);
run;
title;

/* 7. PROC NPAR1WAY: DIFFERENCES BY YEARS OF GIT EXPERIENCE
   This treats experience bands as independent groups. With three bands,
   the Wilcoxon-score analysis includes the Kruskal-Wallis test.
   The null hypothesis for each score is that its distribution is the same
   across the experience groups.
*/
 title "Nonparametric Comparison of GIT Scores by Years of Git Experience";
proc npar1way data=work.git_clean wilcoxon;
    class Years_GIT_Num;
    var GIT_Usage
        Repository_Management_Recovery_Archiving
        Commit_Practices
        Branching_Strategy
        Code_Review_Merge_Conflict;
    format Years_GIT_Num gitexp.;
run;
title;

/* 8. FRIEDMAN TEST: COMPARE THE FIVE PRACTICES WITHIN RESPONDENTS
   The same 11 respondents rated all five practices. Therefore, these are
   related/repeated measurements, not independent samples. This section
   calculates the Friedman chi-square statistic using within-respondent
   average ranks (ties are handled with average ranks and a tie correction).
*/
proc sort data=work.git_long out=work.git_long_sorted;
    by Name;
run;

proc rank data=work.git_long_sorted out=work.git_ranked ties=mean;
    by Name;
    var Score;
    ranks Score_Rank;
run;

proc sql;
    create table work.practice_rank_sums as
    select Practice,
           sum(Score_Rank) as Rank_Sum,
           count(*) as N
    from work.git_ranked
    group by Practice;

    /* For tie correction: for each respondent and score, count tied ranks. */
    create table work.tie_groups as
    select Name, Score, count(*) as Tie_N
    from work.git_long
    group by Name, Score;

    create table work.friedman_ties as
    select sum(Tie_N**3 - Tie_N) as Tie_Total
    from work.tie_groups
    where Tie_N > 1;

    create table work.friedman_summary as
    select sum(a.Rank_Sum**2) as Rank_Squares,
           max(a.N) as N,
           count(*) as K,
           b.Tie_Total
    from work.practice_rank_sums as a, work.friedman_ties as b;
quit;

data work.friedman_result;
    set work.friedman_summary;
    /* Standard Friedman statistic */
    Friedman_ChiSq=(12/(N*K*(K+1)))*Rank_Squares - 3*N*(K+1);
    /* Tie correction summed over respondents */
    Tie_Correction=1 - (Tie_Total/(N*(K**3-K)));
    if Tie_Correction > 0 then Friedman_ChiSq_Corrected=Friedman_ChiSq/Tie_Correction;
    DF=K-1;
    P_Value=1-probchi(Friedman_ChiSq_Corrected,DF);
    label Friedman_ChiSq_Corrected='Tie-corrected Friedman Chi-Square'
          P_Value='Asymptotic p-value';
run;

title "Friedman Test Across the Five GIT Practices";
proc print data=work.friedman_result label noobs;
    var N K Friedman_ChiSq_Corrected DF P_Value;
    format P_Value pvalue6.4 Friedman_ChiSq_Corrected 8.3;
run;
title;

/* Optional: inspect mean/median ranks to see which practices rank higher. */
proc means data=work.git_ranked mean median std;
    class Practice;
    var Score Score_Rank;
    title "Descriptive Statistics and Average Ranks by GIT Practice";
run;
title;

/* END OF PROGRAM */
