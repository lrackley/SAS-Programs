/*****************************************************************************************************************
 
SAS file name: desc.sas
__________________________________________________________________________________________________________________
 
Purpose: Creates rows of descriptive stats for tables
Author: Lauren Rackley
Creation Date: 30MAR2024
*****************************************************************************************************************/

*Writing a macro for continuous variables;
%macro desc(var=,lbl=,grp=);
proc means data = adsl nway n stddev min max median noprint;
   class trt01pn / missing;
   var &var.;
   output out=&var.stats n=_n stddev = _sd min = _min max = _max median = _med mean = _mean;
run;

data &var.stats2;
   length n mean_sd min_max med $14;
   set &var.stats;
   n=strip(put(_n,8.));   
   mean_sd = strip(put(_mean,8.2))||''||'('||strip(put(_sd,8.2))||')';
   min_max = strip(put(_min,8.))||' - '||strip(put(_max,8.));
   med = strip(put(_med,8.1));
run;

proc transpose data = &var.stats2 out = &var.stats2_t prefix = col;
   id trt01pn;
   var n mean_sd med min_max;
run;

data ds&grp.;
   length cat $200;
   set &var.stats2_t;
   cat = put(_name_,$catf.);
   rowlabel = "&lbl";
   roword = input(cat,rowf.);
   grp = &grp.;
run;
%mend desc;
