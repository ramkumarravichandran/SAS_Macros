/*Contact: ram.nit05@gmail.com*/
/*Macro helps choose the best transformation from one of 8 (Square, log, etc.) based on R2 values*/
%MACRO transform(basedata, depvar, groups, destination);

PROC CONTENTS DATA = &basedata OUT = varlabel NOPRINT;
RUN;

DATA varlabel;
SET  varlabel;

IF UPCASE(name) = UPCASE("&depvar") OR type NE 1 THEN 
 DELETE;

IF label = '' THEN
 label = name;

RUN;

DATA _NULL_;
SET varlabel;

CALL SYMPUT('indepvar' || LEFT(PUT(_N_, 4.)), TRIM(name));

RUN;

PROC SQL NOPRINT;
SELECT COUNT(*)
INTO :indepvarnum
FROM varlabel
;
QUIT;

%DO i = 1 %TO &indepvarnum;

/* DM LOG 'CLEAR' CONTINUE;*/
/* DM OUTPUT 'CLEAR' CONTINUE;*/

 PROC RANK DATA = &basedata OUT = xtemp GROUPS = &groups;
 VAR &&indepvar&i. ;
 RANKS rank;
 RUN;

 PROC SQL;
 CREATE TABLE regdata AS
 SELECT rank,
 LOG(AVG(&depvar) / (1 - AVG(&depvar))) AS logodds,
 AVG(&&indepvar&i.) AS variable,
 AVG(1 / &&indepvar&i.) AS inverse,
 AVG(1 / SQRT(&&indepvar&i.)) AS rootinverse,
 AVG(SQRT(&&indepvar&i.)) AS root,
 AVG(&&indepvar&i. * &&indepvar&i.) AS square,
 AVG(LOG(&&indepvar&i.)) AS log
 FROM xtemp
 GROUP BY rank
 ;
 QUIT;

 ODS OUTPUT FITSTATISTICS = rsq_1;

 PROC REG DATA = regdata;
 MODEL logodds = variable
 /VIF COLLIN;
 RUN;
 QUIT;

 ODS OUTPUT FITSTATISTICS = rsq_2;

 PROC REG DATA = regdata;
 MODEL logodds = inverse
 /VIF COLLIN;
 RUN;
 QUIT;

 ODS OUTPUT FITSTATISTICS = rsq_3;

 PROC REG DATA = regdata;
 MODEL logodds = rootinverse
 /VIF COLLIN;
 RUN;
 QUIT;

 ODS OUTPUT FITSTATISTICS = rsq_4;

 PROC REG DATA = regdata;
 MODEL logodds = root
 /VIF COLLIN;
 RUN;
 QUIT;

 ODS OUTPUT FITSTATISTICS = rsq_5;

 PROC REG DATA = regdata;
 MODEL logodds = square
 /VIF COLLIN;
 RUN;
 QUIT;

 ODS OUTPUT FITSTATISTICS = rsq_6;

 PROC REG DATA = regdata;
 MODEL logodds = log
 /VIF COLLIN;
 RUN;
 QUIT;

 %IF &i = 1 %THEN
 %DO;
  PROC SQL;
  CREATE TABLE transform AS
  SELECT
   "&&indepvar&i." AS varname LENGTH = 35,
   a.nvalue2 AS variable,
   b.nvalue2 AS inverse,
   c.nvalue2 AS rootinverse,
   d.nvalue2 AS root,
   e.nvalue2 AS square,
   f.nvalue2 AS log
  FROM rsq_1 a, rsq_2 b, rsq_3 c, rsq_4 d, rsq_5 e, rsq_6 f
  WHERE UPCASE(a.label2) = "R-SQUARE"
  AND   UPCASE(b.label2) = "R-SQUARE"
  AND   UPCASE(c.label2) = "R-SQUARE"
  AND   UPCASE(d.label2) = "R-SQUARE"
  AND   UPCASE(e.label2) = "R-SQUARE"
  AND   UPCASE(f.label2) = "R-SQUARE"
  ;
  QUIT;
 %END;
 %ELSE
 %DO;
  PROC SQL;
  INSERT INTO transform
  SELECT
   "&&indepvar&i." AS varname,
   a.nvalue2 AS variable,
   b.nvalue2 AS inverse,
   c.nvalue2 AS rootinverse,
   d.nvalue2 AS root,
   e.nvalue2 AS square,
   f.nvalue2 AS log
  FROM rsq_1 a, rsq_2 b, rsq_3 c, rsq_4 d, rsq_5 e, rsq_6 f
  WHERE UPCASE(a.label2) = "R-SQUARE"
  AND   UPCASE(b.label2) = "R-SQUARE"
  AND   UPCASE(c.label2) = "R-SQUARE"
  AND   UPCASE(d.label2) = "R-SQUARE"
  AND   UPCASE(e.label2) = "R-SQUARE"
  AND   UPCASE(f.label2) = "R-SQUARE"
  ;
  QUIT;
 %END;

 PROC SQL;
 DROP TABLE xtemp, regdata, rsq_1, rsq_2, rsq_3, rsq_4, rsq_5, rsq_6;
 QUIT;

/* DM LOG 'CLEAR' CONTINUE;*/
/* DM ODSRESULTS 'CLEAR' CONTINUE;*/

%END;

DATA transform;
SET  transform;

FORMAT max_at $15.;

max = MAX(of variable, inverse, rootinverse, root, square, log);

IF variable = max THEN
 max_at = "Variable";

IF inverse = max THEN
 max_at = "Inverse";

IF rootinverse = max THEN
 max_at = "Root Inverse";

IF root = max THEN
 max_at = "Root";

IF square = max THEN
 max_at = "Square";

IF log = max THEN
 max_at = "Log";

RUN;

FILENAME outfile "&destination./transform.csv";

DATA _NULL_;
SET  transform;
FILE outfile DLM = ',' DSD DROPOVER LRECL = 32767;

IF _N_ = 1 THEN
 PUT
  "Varname,"
  "Variable,"
  "Inverse,"
  "Root Inverse,"
  "Root,"
  "Square,"
  "Log,"
  "Max,"
  "Max At"
  ;

PUT
 varname $
 variable
 inverse
 rootinverse
 root
 square
 log
 max
 max_at
;
;

RUN;

%MEND;

