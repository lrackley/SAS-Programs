libname bios511 "/home/lrackley0/BIOS 511";
*include the proc format;
proc format;
   value fmtA 
   1-3='At Least Somewhat Difficult' 
   4='A Little Difficult' 
   5='No Difficulty';
run;

*Create macro variable list of allowed qstestcd values;
proc sql noprint;
   select distinct qstestcd into: cdlist separated by ' ' 
     from bios511.adsis 
   where prxmatch('m/^ITEM(0[1-9]|1[0-6])/', strip(qstestcd));
quit;

%put &=cdlist;
/* options minoperator mlogic mprint symbolgen; */

%macro freq(cd=, fmt=) / minoperator ;
   %if not (&cd in (&cdlist)) %then
      %do;
         %put ERROR: Not an acceptable value of cd.;
         %abort;
      %end;
   %else
      %do;
         %*get the corresponding test name;

         data _null_;
            set bios511.adsis(keep=qstestcd qstest);
            where qstestcd="&cd";
            call symputx('test', qstest);
         run;
         
         %*Generate PROC FREQ output but do not print it;
         proc freq data=bios511.adsis noprint;
            tables aval / out=freq_&cd.;
            where qstestcd="&cd";

            %if not (%upcase(&fmt) in (FMTA NONE)) %then
               %do;
                  %put ERROR: Only allowed values are NONE or FMTA.;
                  %abort; %*Print error if incorrect format is used;
               %end;
            %else
               %do;

                  %if &fmt=FMTA %then 
                     %do;
                        format aval &fmt..;%*Format aval with FMTA if specified;
                     %end;
                  %else %if &fmt=NONE %then %*Do not format if no format is specified;
                     %do;
                     %end;
               %end;
         run;

         %*Create text versions of count and percents from PROC FREQ output dataset;
         data freq_&cd._1;
            set freq_&cd.;
            cnt=strip(put(count, 8.));
            pct=strip(put(percent, 5.2));
         run;

         title1 "Frequency Analysis of Survey Item %substr(&cd,5)"  bold height=0.4cm color=black;
         title2 "&test" color=black bold height=0.25cm;

         proc report data=freq_&cd._1 split='*';
            columns aval cnt pct;
            define aval / "* * Analysis Value";
            define cnt / "* Frequency*Count";
            define pct / "Percent of*Total*Frequency";
         run;

      %end;
%mend freq;
options nodate nonumber;
ods pdf file = "/home/lrackley0/BIOS 511/Final/macrotest.pdf" startpage=yes;
%freq(cd=ITEM16, fmt=FMTA) ;
%freq(cd=ITEM02, fmt=NONE) ;
ods pdf close;
