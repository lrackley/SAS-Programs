*********************************************************************
*  Protocol:      CDISCPILOT01                                    
*                                                                    
*  Description:   t-dm.sas
*
*  Name:          Lauren Rackley
*
*  Date:          30MAR2024                                
*
*  Purpose:       Create demographic table
* 
*  Language:      SAS 9.4
*
*  Input:         ADSL
*
*  Output:        t-dm.rtf                                                               
********************************************************************;
*Assigning libraries;
libname adam '/home/lrackley0/CDISC Pilot/ADaM';

*Filter on intent-to-treat population;
data adsl;
   set adam.adsl;
   where ITTFL = 'Y';
   *deriving new age variable;
   agegr2 = put(age,agef.);
run;

*****************
Getting header N
*****************;
proc sql noprint;
   create table header as 
   select count(*) as n, trt01pn
      from adsl
      where ittfl = 'Y'
      group by trt01pn;
      
   select n into: n1 -
      from header;
quit;

%put &=n1 &=n2 &=n3;

*Assinging formats to be used in table writing;
proc format;
   value agef
   low - <65 = '<65'
   65-80 = '65-80'
   80<- high = '>80'
   other = ' '
   ;
   
   value $ catf
   'n'='n'
   'mean_sd'='Mean (SD)'
   'med'='Median'
   'min_max'='Min - Max'
   ;
   
   invalue rowf
   'n'=1
   'Mean (SD)'=2
   'Median'=3
   'Min - Max'=4
   ;
   
   invalue agegrf
   '<65'=1
   '65-80'=2
   '>80'=3
   ;
   
   invalue racef
   'WHITE'=1
   'BLACK OR AFRICAN AMERICAN'=2
   'AMERICAN INDIAN OR ALASKA NATIVE'=3
   ;
run;

*Calling the macro for each cont variable;
%desc(var=age,lbl=Age,grp=1);
%desc(var=heightbl,lbl=%str(Baseline Height (cm)),grp=4);
%desc(var=weightbl,lbl=%str(Baseline Weight (kg)),grp=5);
%desc(var=bmibl,lbl=%str(Baseline BMI (kg/m^2)),grp=6);
%desc(var=mmsetot,lbl=%str(MMSE Total),grp=7);

*Call macro for each categorical variable in table;
%freqmac(var=agegr2,fmt=agegrf,grp=2,lbl=%str(Pooled Age Group 1));
%freqmac(var=race,fmt=racef,grp=3,lbl=%str(Race));

*Stack up all the stat datasets and assign page numbers;
data final;
   length rowlabel col0 col54 col81 $200;
   set ds1-ds7;
   if grp in (1:5) then pg=1;
   else pg=2;
run;

proc sort data=final;
   by pg grp roword;
run;

*Writing the report;
options nodate nonumber orientation=landscape;
ods escapechar='~';
ods tagsets.rtf file = '/home/lrackley0/CDISC Pilot/Tables/t-dm.rtf';

title height=10pt j=l "~S={fontweight=light fontstyle=roman}Protocol: CDISCPILOT01"
 j=c "~S={fontweight=light fontstyle=roman}Population: Intent-to-Treat"
 j=r "~S={fontweight=light fontstyle=roman}PAGE X of Y";
title3 height=12pt "~S={fontstyle=roman}Summary of Demographic and Baseline Characteristics";
footnote3 height=9pt j=l "~S={fontweight=bold fontstyle=roman}Source:
~S={fontweight=light fontstyle=roman}d:\t-dm-sgf.rtf"
 j=r "~S={fontsize=9pt fontweight=bold fontstyle=roman}Date:
~S={fontweight=light fontstyle=roman}&sysdate9.";
proc report data = final split='*' nocenter missing
style(header)={backgroundcolor=_undef_ just=l}
style(report)={rules=groups frame=hsides
 cellspacing=0 cellpadding=0 outputwidth=100%};
   columns pg grp rowlabel roword cat col0 col54 col81;
   *Order variables;
   define pg / order order = internal noprint;
   define grp / order order = internal noprint;
   define rowlabel /order order=internal noprint;
   define roword / order order=internal noprint;
   
   *Reported columns;
   define cat /display '' style(column)={cellwidth=2in paddingleft=0.1in};
   define col0 / "Placebo*(N=&n1)" display style(column)={cellwidth=1.25in just=c} style(header)={just=c};
   define col54 /"Xanomeline Low Dose*(N=&n2)" display style(column)={cellwidth=1.25in just=c} style(header)={just=c};
   define col81 / "Xanomeline High Dose*(N=&n3)" display style(column)={cellwidth=1.25in just=c} style(header)={just=c};
   
   *Labels over statistics;
   compute before rowlabel /style(lines)={just=l};
      line rowlabel $50.;
   endcomp;
   
   *Paging;
   break after pg/page;

   
   *skip line between groups;
   compute after grp;
      line '';
   endcomp;
run;
ods tagsets.rtf close;

   