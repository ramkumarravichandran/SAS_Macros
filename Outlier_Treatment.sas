/************************************************************************************************************
						Outlier Treatment
			
Macro Objective: The macro will treat an outlier value of a variable by flooring and/or capping 
		 the outliers on a percentile of variable given by user
Prepared By:	 Rajat Mathur [Rajat.Mathur@DiamondConsultants.com]
Date of Creation: Jan 15th 2009
Edited By:
Edited On:	
Changes Made:

How to Use Macro:1. Include this file - "C:\xxx\Outlier_Treatment.txt";
		 2. Call the macro by putting appropriate inputs for each parameter
		 
		 %outl_teatment(data_in=<input_dataset>,data_out=<output_dataset>,
		 varlist=<variable list>,floor_on=<flooring percentile>,cap_on=<capping percentile>);
		 
		 where:
		 	data_in  = name of input data set. eg. libname.dataset
			data_out = name of output data set. eg. libname2.dataset2
			varlist  = list of all NUMERIC variables on which you wish to perform imputation
			floor_on = Enter the perentile on which you wish to floor your outliers. 
				   eg. if you wish to floor it onfirst percentile then enter 1
			cap_on  =  Enter the perentile on which you wish to cap your outliers. 
				   eg. if you wish to floor it on 99th percentile then enter 99

Caveat: Length of VARIABLE NAMES should not be more than 30 characters

Algo for Macro:
1. Create a _temp_ data set that has required perctile needed for outlier for all variables.
2. Create global macro variable (for each variable) that contains required value by which that variable shall be imputed
3. If a variable is missing then impute that variable with help of variables macro global variable

*************************************************************************************************************/


**********   		0. Start of SAS Macro                                      **************************;

%macro outl_teatment(data_in=,data_out=,varlist=,floor_on=,cap_on=);

*******************   1. Create a _temp_ data set that has required ***************************************;
*******************   perctile needed for outlier for all variables.   ************************************;

		proc univariate data=&data_in;
		var &varlist;
		output out=_temp_ pctlpts=&floor_on &cap_on pctlpre=&varlist;
		run;


*******************   2. Create global macro variable (for each variable) that 		*******************;
*******************	contains required value capped and floor values			 ******************;
	
		%local cnt this_var;
		%let this_var= %scan (&varlist, 1, %str(" "));
		%let cnt=1;
		
		%do %while( &this_var ne );
			data _null_;
			set _temp_;
				call symput ('Low',&this_var.&floor_on);
				call symput ('High',&this_var.&cap_on);
			run;
		
		%let &this_var.L=&Low;
		%let &this_var.H=&High;

		%let cnt = %eval(&cnt+1);
		%let this_var = %scan(&varlist ,&cnt , %str(" "));
		%end;


data &data_out;
set &data_in;
run;

%local cnt this_var;
%let cnt=1;

%let this_var= %scan (&varlist, &cnt, %str(" "));

*****************	3. If a variable beyond capped or floor value then perform  *************************;
*****************	outlier treatment with help of variables macro global variable **********************;

	data &data_out;
	set &data_out;
	%do %while (&this_var ne );
			
		if (&this_var > &&&this_var.H) then &this_var = (&&&this_var.H );
		else if (&this_var < &&&this_var.L and &this_var ne .) then &this_var = (&&&this_var.L );
	
		%let cnt=%eval(&cnt+1);
		%let this_var= %scan (&varlist, &cnt, %str(" "));
		
	%end;
	run;

%mend outl_teatment;

********************* 			End of SAS macro	**********************************************;




