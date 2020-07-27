/************************************************************************************************************
						Misisng Value Imputation
			
Macro Objective: The macro will impute the missing values of variables either by any of
		 its percentile value or by its mean or any user given value.
Prepared By:	 Rajat Mathur [Rajat.Mathur@DiamondConsultants.com]
Date of Creation: Jan 15th 2009
Edited By:
Edited On:	
Changes Made:

How to Use Macro:1. Include this file - "C:\xxx\MVI.txt";
		 2. Call the macro by putting appropriate inputs for each parameter
		 
		 %MVI(data_in=<input_dataset>,data_out=<output_dataset>,
		 varlist=<variable list>,imputing_option=<1 or 2 or 3>,imputing_value=<as required>);
		 
		 where:
		 	data_in  = name of input data set. eg. libname.dataset
			data_out = name of output data set. eg. libname2.dataset2
			varlist  = list of all NUMERIC variables on which you wish to perform imputation
			imputing_option = This paramenter can only take either 1 or 2 or 3. 
					  1 for Mean 2 for Percentile 3 for User Defined Value
			imputing_value  = Applicable only when imputing option is for Percentile or User Defined
					  For percentile - enter  value of percentile. eg. for 50th percentile enter 50
					  For User Defined - enter the value by which you wish to do the imputation
					  eg. if you wish to impute variables with zero then enter 0.

Caveat: Length of VARIABLE NAMES should not be more than 26 characters


Algo for Macro:
1. Create a _temp_ data set that has mean or required perctile needed for imputation for all variables.
2. Create global macro variable (for each variable) that contains required value by which that variable shall be imputed
3. If a variable is missing then impute that variable with help of variables macro global variable

*************************************************************************************************************/


**********   		0. Start of SAS Macro                                      **************************;

%macro MVI(data_in=,data_out=,varlist=,imputing_option=,imputing_value=);


*******************   1. Create a _temp_ data set that has mean or required **********************************;
*******************   perctile needed for imputation for all variables.   ************************************;

%if (&imputing_option eq 1) %then %do;
	proc summary data=&data_in nway missing;
	var &varlist;
	output out=_temp_(drop=_freq_ _type_) mean=/autoname;
	run;
%end;
%if (&imputing_option eq 2) %then %do;
	proc univariate data=&data_in;
	var &varlist;
	output out=_temp_ pctlpts=&imputing_value pctlpre=&varlist;
	run;
%end;

*******************   2. Create global macro variable (for each variable) that 		*******************;
*******************	contains required value by which that variable shall be imputed  ******************;
	
		%local cnt this_var;
		%let this_var= %scan (&varlist, 1, %str(" "));
		%let cnt=1;
		
		%do %while( &this_var ne );
			
			%if (&imputing_option eq 1) %then %do;					
				data _null_;
				set _temp_;
					call symput ('x',&this_var._mean);
				run;
			%end;
			
			%if (&imputing_option eq 2) %then %do;			
				data _null_;
				set _temp_;
					call symput ('x',&this_var.&imputing_value);
				run;
			%end;
			
			%if (&imputing_option eq 3) %then %do;			
				%let x=&imputing_value;
			%end;		
			
			%let &this_var.x=&x;
			%let cnt = %eval(&cnt+1);
			%let this_var = %scan(&varlist ,&cnt , %str(" "));
		%end;
		
*****************	3. If a variable is missing then impute that variable *************************;
*****************	with help of variables macro global variable 		***********************;

data &data_out;
set &data_in;
run;

%local cnt this_var;
%let cnt=1;

%let this_var= %scan (&varlist, &cnt, %str(" "));
	
	data &data_out;
	set &data_out;
	%do %while (&this_var ne );
		if (&this_var eq .) then &this_var = &&&this_var.x;
	%let cnt=%eval(&cnt+1);
	%let this_var= %scan (&varlist, &cnt, %str(" "));
		
	%end;
	run;

%mend MVI;

********************* End of SAS macro**************************************************************;
