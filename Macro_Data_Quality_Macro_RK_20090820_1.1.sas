/*Contact: ram.nit05@gmail.com*/

options compress=yes obs=max;

%macro dqr(data_in=,num_excel=,char_excel=);

proc contents data=&data_in varnum out=tmx1(keep=NAME label type length);
run;

proc sort data=tmx1;by name;run;

proc sql;
	select count(*) into :nrows from tmx1;
	%let nrows = %left(&nrows);
	select name into :name1 - :name&nrows from  tmx1;
quit;

%do i=1 %to &nrows;
	proc sql;
		create table tmx2 as
		select "&&name&i                             " as Name ,
		count(&&name&i) as Nobs,
		count(distinct(&&name&i)) as NUnique
		from &data_in;
	quit;
	
	%if &i=1 %then %do;
		data tmx_append;
			set tmx2;
		run;
	%end;
	%else %do;
		data tmx_append;
			set tmx_append tmx2;
			name=strip(name);
		run;
	%end;
%end;

data t_merge;
	merge tmx1(in=a) tmx_append(in=b);
	by name;
run;

data t_char t_num t_date;
	set t_merge;
	if 	type ne 1 /* or NUnique le 10*/ then output t_char;
	else if type eq 1 and Nunique le 10 
	else if type ne 1  and format = compress("DATE") then output t_date;
	else if type eq 1 and format ne compress("DATE") then output t_num;
	else output nut_cases;
run;

/*Numerical Variables*/
proc sql;
	select count(*) into :nrows2 from t_num;
	%let nrows2 = %left(&nrows2);
	select name into :nname1 - :nname&nrows2 from  t_num;
quit;

%do k=1 %to &nrows2;
proc summary data=&data_in(keep=&&nname&k) n nmiss mean min p1 p5 p10 p25 p50 p75 p90 p95 p99 max noprint;
	var  &&nname&k;
	output out=smry(drop=_TYPE_ _FREQ_)
/*	n(&&nname&k)=nobs*/
	nmiss(&&nname&k)=nmiss 
	mean (&&nname&k)=Mean
	min (&&nname&k)=Min
	p1 (&&nname&k) =t_p1 
	p5 (&&nname&k) =t_p5 
	p10 (&&nname&k)=t_p10
	p25 (&&nname&k)=t_p25
	p50 (&&nname&k)=t_p50
	p75 (&&nname&k)=t_p75
	p90 (&&nname&k)=t_p90
	p95 (&&nname&k)=t_p95
	p99 (&&nname&k)=t_p99
	max (&&nname&k)=t_max;
run;

data smry;
	NAME 
	TYPE 
	LABEL 
	Nobs
	NUnique 
	nmiss 
	pct_missing
	Mean 
	Min 
	t_p1
	t_p5
	t_p10
	t_p25
	t_p50
	t_p75
	t_p90
	t_p95
	t_p99
	t_max ;

	merge t_num(obs=&k firstobs=&k) smry;
	format NAME $32.
			TYPE 1.
			LABEL $200.
			nobs 12.
			NUnique 12.
			nmiss 12.
			pct_missing 12.
			Mean 
			Min 
			t_p1
			t_p5
			t_p10
			t_p25
			t_p50
			t_p75
			t_p90
			t_p95
			t_p99
			t_max 24.;
	pct_missing = (nmiss/nobs)*100;
run;
 
run;

	%if &k=1 %then %do;
		data summary_num;
			set smry;
		run;
	%end;
	%else %do;
		data summary_num;
			set summary_num smry;
		run;
	%end;
%end;



/*Character variable */

proc sql;	
	select count(*) into :nrows3 from t_char/*(where = (type ne 1))*/;
	%let nrows3 = %left(&nrows3);
	select name into :cname1 - :cname&nrows3 from  t_char/*(where = (type ne 1))*/;
quit; 

/*To get the list of character variables subsetted for further study */

data temp_char;
	set &data_in.(keep = _char_);
run;

%let c_list=;
%do k=1 %to &nrows3;
	%let gsf=&c_list;
	%let c_list=&gsf &&cname&k;
	data temp_char;
		set temp_char;
		&&cname&k = compress(upcase(&&cname&k));
	run;
%end;

%do k=1 %to &nrows3;
	proc sql;
		create table t_char_nmiss_&k. as
			select "&&cname&k                             " as Name ,
			sum(case when compress(upcase(&&cname&k)) in ("","-99","-999",,"-9999",,"NULL","NA",".","-","?") then 1 else 0 end) as nmiss
		from ;
	quit;

	%if &k. = 1 %then %do;
		data t_char_nmiss;
			set t_char_nmiss_1;
		run;
	%end;
		%else %do;
			data t_char_nmiss;
				set t_char_nmiss t_char_nmiss_&i.;
			run; 
		%end;
%end;
/*Merging Row by Row the t_char */
proc sort data = t_char; by name;run;
proc sort data = t_char_nmiss; by name;run;

data summary_char;
	merge t_char(in = a) t_char_miss(in = b);
	by name;
	merge_ind = compress(a||b);
run;
proc freq;tables merge_ind ;run; 

proc sql;
select nunique into :nuni-:nuni&nrows3. from t_char ;

quit;
ods html file= "&char_excel";

%do k=1 %to &nrows3;
	proc sql;
			select &&cname&k. as Name,
			count(*) as counts 
		from &data_in.(keep=&c_list.) 
		group by &&cname&k. 
		order by counts desc;
	quit;
%end;

ods html close;

/*Date Variables*/


data t_date;set t_date;run;

proc sql;	
	select count(*) into :nrows4 from t_date;
	%let nrows4 = %left(&nrows4);
	select name into :dname1 - :dname&nrows4 from  t_date;
quit; 

/*Merging all the date, character and numerical distribution tables to get a single report*/
data &libname..Report_one;
	set summary_num summary_char summary_date ;
run;
*PROC EXPORT DATA= summary_out
            OUTFILE= "&num_excel" 
            DBMS=CSV REPLACE;
/*     SHEET="dqr"; */
*RUN;
%mend;
