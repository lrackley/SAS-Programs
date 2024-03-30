%LET job=RPTD;
%LET onyen=lrackley;
%LET outdir=/home/lrackley0/BIOS669;

proc printto log="&outdir/Logs/&job._&onyen..log" new; 
run;

*********************************************************************
*  Assignment:    RPTD                                   
*                                                                    
*  Description:   Produce METS Table 8.1
*
*  Name:          Lauren Rackley
*
*  Date:          April 7, 2021                               
*------------------------------------------------------------------- 
*  Job name:      RPTD_lrackley.sas   
*
*  Purpose:       Produce a table with proc report
* 
*  Language:      SAS, VERSION 9.4  
*
*  Input:         mets.omra_669, mets.dr_669
*
*  Output:        rtf output
*                                                                    
********************************************************************;
OPTIONS NODATE MPRINT MERGENOBY=WARN VARINITCHK=WARN NOFULLSTIMER;
ODS _ALL_ CLOSE;
/* FOOTNOTE "Job &job._&onyen run on &sysdate at &systime"; */

%LET job=RPTD;
%LET onyen=lrackley;
%LET outdir=/home/lrackley0/BIOS669;
libname mets "/home/lrackley0/my_shared_file_links/kathyroggenkamp/METS";

ods pdf file="&outdir/PDFs/&job._&onyen..pdf" style=journal;
options nodate nonumber orientation=landscape;
footnote;

*Copied code from LUTA model answer;
proc sql noprint;
    create table possible2 as 
        select distinct bid, scan(omra1,1,' -') as WtLiabMed
            from mets.omra_669
            where omra4='06' and omra5a='Y'
            ;
quit;

/* #2 */
/* make look-up table:  Med as code, Class as value to assign */
data medclass;
    length Med $15 Class $4;
    input med class ;
cards;
CLOZAPINE HIGH
ZYPREXA HIGH
RISPERIDONE HIGH
SEROQUEL HIGH
INVEGA HIGH
CLOZARIL HIGH
OLANZAPINE HIGH
RISPERDAL HIGH
ZIPREXA HIGH
LARI HIGH
QUETIAPINE HIGH
RISPERDONE HIGH
RISPERIDAL HIGH
RISPERIDOL HIGH
SERAQUEL HIGH
ABILIFY LOW
GEODON LOW
ARIPIPRAZOLE LOW
HALOPERIDOL LOW
PROLIXIN LOW
ZIPRASIDONE LOW
GEODONE LOW
HALDOL LOW
PERPHENAZINE LOW
FLUPHENAZINE LOW
THIOTRIXENE LOW
TRILAFON LOW
TRILOFAN LOW
;

title 'Check med class assignments after #2';
proc freq data=medclass;
    tables class*med/list;
run;
title;



* #3 - table look-up using merge;
proc sort data=possible2 out=possbymed;
    by wtliabmed;
run;
proc sort data=medclass out=tablebymed(rename=(med=wtliabmed));
    by med;
run;
data classify_merge(keep=bid wtliabmed class_merge);
    merge possbymed(in=inmain) tablebymed;
    by wtliabmed;
    if inmain;
    rename class=class_merge;
/*     highlow=upcase(class)='HIGH' or missing(class); */
run;

proc sort data=classify_merge;
    by bid wtliabmed;
run;

proc sort data=mets.dr_669(keep=bid) out=dr_669;
	by bid;
run;

data temp;
	merge classify_merge dr_669(in=a);
	by bid;
	if a;
run;


/* This was a fake dataset to test if the flag was being derived correctly */
/* data temp; */
/* infile datalines missover; */
/* input bid :$3. class_merge :$4.; */
/* datalines; */
/* 001 HIGH */
/* 001 LOW */
/* 002  */
/* 003 HIGH */
/* 004 LOW */
/* 005  */
/* 005  */
/* ; */
/* run; */

/* proc sort data=temp; */
/* 	by bid; */
/* run; */

/* if you want to use a boolean variable, this is a way that I found works */
/* data want; */
/*   set temp (in=firstpass) temp (in=secondpass); */
/*   by bid; */
/*   retain missingflag highflag; */
/*   if first.bid then do; */
/*   	missingflag=0; */
/*   	highflag=0; */
/*   end; */
/*   if firstpass and class_merge='HIGH' then highflag=1; */
/*   if firstpass and missing(class_merge)=0 then missingflag=1; */
/*   if last.bid then output; */
/* run; */

/* yet another way to get the flag for if all records are missing */
/* proc sql; */
/* create table want as */
/* select *,n(class_merge) = 0 as missingflag */
/*  from temp */
/*   group by bid; */
/* quit; */

/* proc sql; */
/* 	create table want2 as select distinct bid, min(missingflag) as missFL, */
/* 	max(highflag) as highFL */
/* 		from want */
/* 		group by bid; */
/* quit; */
/*  */
/*  */
/* data want3; */
/* 	set want2; */
/* 	highflag=missFL=0 or highFL=1; */
/* run; */
/*  */
/* proc sql; */
/* 	create table want4 as select dr.trt,w.* */
/* 		from want3 as w */
/* 		left join mets.dr_669 dr */
/* 		on w.bid=dr.bid; */
/* quit; */
/*  */
/* proc freq data=want4; */
/* 	tables highflag*trt; */
/* quit; */
/*  */
/* proc sql; */
/* 	create table temp2 as select distinct bid, max(highFL) as highFL */
/* 		from temp1 */
/* 		group by bid; */
/* quit; */
/*  */
/* proc freq data=temp2; */
/* 	tables highFL; */
/* run; */
/*  */
/* proc sql; */
/* 	create table temp3 as select d.trt, t.* */
/* 		from temp2 as t */
/* 		left join */
/* 		mets.dr_669 as d */
/* 		on d.bid=t.bid; */
/* quit; */
/*  */
/* data analysisset; */
/* 	set temp3; */
/* 	output; */
/* 	trt='Z'; */
/* 	output; */
/* run; */
/*  */
/* proc freq data=analysisset; */
/* 	tables highFL*trt; */
/* quit; */

/*  */
/* get counts of high and low meds by bid */
proc sql;
	create table temp2 as select bid,sum(class_merge='HIGH') as highcount, sum(class_merge='LOW') as lowcount
		from temp
		group by bid;
quit;

data temp3;
	set temp2;
	*case 1 - no information or no meds - gets classified as high;
	if lowcount=0 and highcount=0 then highind=1;
	
	*case 2 - person had any highs - classified as high;
	else if highcount ge 1 then highind=1;
	
	*case 3 - person has no highs but 1 or more lows - classified as LOW;
	else if highcount=0 and lowcount ge 1 then highind=0;
run;

title "Check derivation of highind: 1=HIGH, 0=LOW";
proc freq data=temp3;
	tables highcount*lowcount*highind/list missing;
run;
title;

*bring treatment back in to the dataset;
proc sql;
	create table report as select t.*,m.trt
		from temp3 t
		left join 
		mets.dr_669 as m
		on m.bid=t.bid;
quit;

/* double the dataset to get overall column */
data report2;
	set report;
	output;
	trt='Z';
	output;
run;

****highind statistics programming;
proc freq data=report2 noprint;
	tables trt*highind/missing outpct out=highind1;
run;

***format highind N(%) as desired;
data highind2;
	set highind1;
	where ^missing(highind);
	length value $ 25;
	value = put(count,4.) || ' ('||strip(put(pct_row,5.1))||')';
run;

*sort by highind before transposing;
proc sort data=highind2;
	by highind;
run;

*transpose highind summary statistics;
proc transpose data=highind2 out=highind3(drop=_name_)
 prefix=col;
 	by highind;
 	var value;
 	id trt;
 run;

*assign value of text variable for first column in report; 
data highind4;
 	set highind3;
 	length text1 $ 500;
 	if highind=1 then do; 
 	text1='Participants on higher weight liability antipsychotic meds';
 	ord=1;
 		end;
 	else if highind=0 then do;
 	text1='Participants on lower weight liability antipsychotic meds';
 	ord=2;
 		end;
 run;
 
 *get chi square for active vs. placebo;
 proc freq data=report2 noprint;
 	where ^missing(highind) and trt ^='Z';
 	tables highind*trt/chisq;
 	output out=pvalue pchi;
 run;

*make the value of text1 the same as value of text1 in first row of the table for merge;
data pvalue2;
	set pvalue;
	length text1 $ 500;
	text1='Participants on higher weight liability antipsychotic meds';
	pvalue=put(p_pchi,6.4);
	ord=1;
run;

/* combine p-value in first row with the report dataset */
proc sql noprint;
	create table forreport as select p.pvalue, h.*
		from highind4 as h
		left join
		pvalue2 as p
		on p.text1=h.text1 and p.ord=h.ord;
/* get macro variables for column headers */
	select count(*) into :metN trimmed
		from report2 where trt='A';
		
	select count(*) into :PlaN trimmed
		from report2
		where trt='B';
	
	select count(*) into :totN trimmed
		from report2
		where trt='Z';
	
quit;

%put &=metN &=plaN &=totN;

ods pdf close;

ods rtf file="&outdir/RTFs/&job._&onyen..rtf" style=journal bodytitle;
*Create the final report and send to RTF;
title "Table 8.1: METS Weight Liability by Treatment Group";
footnote1 j=l "*Chi-square statistic comparing metformin and placebo groups";

footnote3 j=l "Participants taking both higher and lower weight liability meds are included in 
the higher group";
footnote4 j=l "Created by &job._&onyen..sas on &sysdate at &systime";
proc report data=forreport nowd split='^';
	columns text1 colZ colA colB pvalue;
	define text1/ "" style=[cellwidth=1.5in];
	define colZ / "Total^N(%)^n = &totN" center;
	define colA / "Metformin^N(%)^n = &metN" center ;
	define colB / "Placebo^N(%)^n = &plaN" center;
	define pvalue/"^^P-value*" center;
run;

title;
footnote;

ods pdf close;
ods rtf close;
ods listing;

proc printto;
run;



