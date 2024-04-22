********************
Begin code for Q1
*******************;
data heart;
	set echo.vs;
	where vstestcd='HR' and VSBLFL='Y';
	keep usubjid vstestcd vsblfl vsstresn;
run;

proc sql;	
	create table want as 
	select dm.usubjid, vsstresn, 
	case when vsstresn > 60 then '>60'
	when vsstresn > .z and vsstresn <= 60 then '<=60' end as hr_above_60
	from echo.dm as dm
	join heart as h
	on h.usubjid=dm.usubjid;
quit;

title "Percent of subjects with baseline HR above 60";
proc freq data=want;
	tables hr_above_60 / missprint;
run;
title;

********************
Begin code for Q2
********************;
data vs;
	set echo.vs;
	where vstestcd in ('SYSBP','DIABP') and visitnum in (1,5);
run;

proc sort data=vs;
	by usubjid visitnum;
run;

proc transpose data=vs out=vs_T;
	by usubjid visitnum;
	var vsstresn;
	id vstestcd;
run;

data pulse;
	set vs_t;
	pulse_pressure=sysbp-diabp;
run;

proc sort data=pulse;		
	by usubjid ;
run;

proc transpose data=pulse out=pulse_t prefix=visit;
	by usubjid;
	var pulse_pressure;
	id visitnum;
run;

data pulse2;
	set pulse_t;
	chg=visit5-visit1;
	
	keep usubjid chg;
run;

data echomax;
	set echo.dm;
	where armcd="ECHOMAX";
	keep usubjid armcd;
run;

proc sort data=pulse2;
	by usubjid;
run;

proc sort data=echomax;
	by usubjid;
run;

data combine;	
	merge pulse2 echomax(in=a);
	by usubjid;
	if a;
	
	label chg='Change in pulse pressure Week 0 to Week 32';
run;

title "Histogram of Change in Pulse Pressure Week 0 to Week 32";
ods select histogram;
proc univariate data=combine;
	histogram chg / normal;
	inset mean (8.2) std='SD' (8.3);
run;
title;
