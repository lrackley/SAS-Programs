*********************************************************************
*  TITLE :      lb.sas                                  
*                                                                   
*  DESCRIPTION: Produce LB dataset       
*                                                                   
*-------------------------------------------------------------------
*  JOB NAME:    lb.sas                                         
*  LANGUAGE:    SAS 9.4                                 
*                                                                   
*  NAME:        Lauren Rackley                              
*  DATE:        31MAR2024                                 
*-------------------------------------------------------------------;
libname bios511 "/home/lrackley0/BIOS 511";

*Create formats to derive new variables;
proc format;
   value $ lbtestcdf
   'Albumin'='ALB'
   'Hematocrit'='HCT'
   'Calcium'='CA'
   ;
   
   invalue visitf
   'Screening'=-1
   'Week 0'=1
   'Week 16'=3
   'Week 32'=5
   ;
run;

data lb1;
   length studyid $10 usubjid $30 lbtestcd $8 lbtest $40 lbcat lbreasnd visit $50
   lbstresu $20 lbstat $10 lbdtc $20;
   set bios511.rawlab;
   studyid='ECHO';
   usubjid=catx('-',studyid,site,subject);
   lbtest=labtest;
   
   *Derive lbtestcd;
   lbtestcd = put(lbtest,lbtestcdf.);
   *Derive lbcat;
   lbcat=upcase(labcat);
   
   lbstresn=value;
   lbstresu=unit;
   if nd ne '' then lbstat='NOT DONE';
   lbreasnd = nd;
   
   *Visit variables;
   visit = visdesc;
   if visit ne '' then visitnum=input(visit,visitf.);
   
   *Assign lbdtc;
   if labdate ne '' then lbdtc=put(labdate,is8601da.);
run;

/* proc freq data = lb1; */
/*    tables lbtestcd*labtest lbtest*labtest lbcat*labcat lbstat*nd visitnum*visit visit* */
/*    visdesc lbdtc*labdate/ list missing; */
/* run; */

*Bring in variables from dm;
data dm;
   set bios511.dm;
   keep usubjid sex rfxstdtc;
run;

proc sql;
   create table lb2 as 
   select lb1.*,dm.sex,dm.rfxstdtc
      from lb1 as lb1
      left join dm as dm
      on dm.usubjid=lb1.usubjid;
quit;

%macro refrange(hi=,lo=);
   if lbstresn < &lo. then lbnrind='L';
   else if &lo. <= lbstresn <= &hi. then lbnrind='N';
   else if lbstresn > &hi. then lbnrind='H';
%mend;

data lb3;
   length lbnrind $5;
   set lb2;
   if missing(lbstresn)=0 then do;
      if lbtestcd='CA' then do;
         %refrange(hi=2.7,lo=2.1);
      end;
      if lbtestcd='ALB' then do;
         %refrange(hi=55,lo=35);
      end;
      if lbtestcd='HCT' then do;
         if sex='F' then do;
            %refrange(hi=0.445,lo=0.349);
         end;
         if sex='M' then do;
            %refrange(hi=0.500,lo=0.388);
         end;
      end;
   end;
run;

*Check lbnrind;
/* proc means data = lb3 n nmiss min max; */
/*    class lbnrind lbtestcd sex; */
/*    var lbstresn; */
/* run; */

*Deriving baseline flag;
*getting them in order of last visit per subject and lab test;
proc sort data = lb3;
   by usubjid lbcat lbtestcd descending lbdtc;
run;

data lb4 chk(keep=usubjid lbcat lbtestcd visit lbdtc lbstresn lbblfl rfxstdtc);
   length lbblfl $1;
   set lb3;
   retain flag;
   by usubjid lbcat lbtestcd descending lbdtc;
   if first.lbtestcd then do;
      flag=0;
   end; 
   if flag=0 and lbdtc <= rfxstdtc and lbstresn ne . then do;
      lbblfl='Y';
      flag=1;
   end;
run;

*Derive lbseq;
proc sort data = lb4;
   by usubjid lbcat lbtestcd lbtest visit;
run;

*Output final dataset;
data sdtm_lb;
   attrib STUDYID  label='Study Identifier'                         ;   
   attrib USUBJID  label='Unique Subject Identifier'                ; 
   attrib LBSEQ    label='Sequence Number'                          ;   
   attrib LBTESTCD label='Lab Test or Examination Short Name'       ; 
   attrib LBTEST   label='Lab Test or Examination Name'             ;       
   attrib LBCAT    label='Category for Lab Test'                    ;     
   attrib LBSTRESN label='Numeric Result/Finding in Standard Units' ; 
   attrib LBSTRESU label='Standard Units'                           ; 
   attrib LBNRIND  label='Reference Range Indicator'                ; 
   attrib LBSTAT   label='Completion Status'                        ;     
   attrib LBREASND label='Reason Test Not Done'                     ; 
   attrib LBBLFL   label='Baseline Flag'                            ;     
   attrib VISITNUM label='Visit Number'                             ; 
   attrib VISIT    label='Visit Name'                               ;     
   attrib LBDTC    label='Date/Time of Specimen Collection'         ;
   keep studyid usubjid lbseq lbtestcd lbtest lbcat lbstresn lbstresu lbnrind 
   lbstat lbreasnd lbblfl visitnum visit lbdtc;
   set lb4;
   by usubjid lbcat lbtestcd lbtest visit;
   if first.usubjid then lbseq=0; /*Derive lbseq*/
   lbseq+1;
proc contents;
run;

proc print data=sdtm_lb label noobs;
   where usubjid in ('ECHO-011-001','ECHO-011-006');
run;

proc compare base = sdtm_lb compare = lb_solution;
run;
   
   