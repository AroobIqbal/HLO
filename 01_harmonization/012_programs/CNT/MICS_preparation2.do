* Purpose of this file: File is to try out code, and give some explanations of hwo MICS can be cleaned well 
*=========================================================================* 
/* 
left: 
2017:  TGO 
 
reading unavailable:  
 
Explanation of do file: 
This is a do file which provides useful code to clean and structure MICS 6 datasets. 
Note the Excel file which also provides an overview of datasets. 
*/ 
*------------------------------------------------------------------------------- 
*Create directory for MICS 
*------------------------------------------------------------------------------- 
cd ${input}\CNT 
 
*Add country for which the directory should be created 
local cnt GNB 
foreach j in `cnt' { 
mkdir "`j'" 
mkdir "`j'/`j'_2019_MICS" 
mkdir "`j'/`j'_2019_MICS/`j'_2019_MICS_v01_M" 
mkdir "`j'/`j'_2019_MICS/`j'_2019_MICS_v01_M\Data"  
mkdir "`j'/`j'_2019_MICS/`j'_2019_MICS_v01_M\Data\Original" 
mkdir "`j'/`j'_2019_MICS/`j'_2019_MICS_v01_M\Data\Stata" 
mkdir "`j'/`j'_2019_MICS/`j'_2019_MICS_v01_M\Doc" 
mkdir "`j'/`j'_2019_MICS/`j'_2019_MICS_v01_M\Doc\Report" 
mkdir "`j'/`j'_2019_MICS/`j'_2019_MICS_v01_M\Doc\Technical" 
} 
 
*------------------------------------------------------------------------------- 
*Load SPSS file and make a STATA file 
*------------------------------------------------------------------------------- 
//cnt needs to be replaced by the appropriate dataset 
 
*import dataset of primary caretake of children 5-17 (fs) 
//2018 
local cnt CRI GEO IRQ LSO MDG MNG MNE SUR TUN COD 
foreach j in `cnt' { 
import spss "`j'/`j'_2018_MICS/`j'_2018_MICS_v01_M\Data\Original\fs", clear 
save "`j'/`j'_2018_MICS/`j'_2018_MICS_v01_M/Data/Stata/`j'_2018_MICS_v01_M", replace 
} 
//2019 
local cnt GUY XXK PSE BGD TCD CUB NPL STP SRB THA TON ZWE DZW GNB CAF 
foreach j in `cnt' { 
import spss "`j'/`j'_2019_MICS/`j'_2019_MICS_v01_M\Data\Original\fs", clear 
save "`j'/`j'_2019_MICS/`j'_2019_MICS_v01_M/Data/Stata/`j'_2019_MICS_v01_M", replace 
} 
//2017 
local cnt GHA PAK LAO SLE TGO 
foreach j in `cnt' { 
import spss "`j'/`j'_2017_MICS/`j'_2017_MICS_v01_M\Data\Original\fs", clear 
save "`j'/`j'_2017_MICS/`j'_2017_MICS_v01_M/Data/Stata/`j'_2017_MICS_v01_M", replace 
} 
*------------------------------------------------------------------------------- 
*Review dataset 
*------------------------------------------------------------------------------- 
/* 
Useful Steps to clean  and review: 
-check if reading score is available (fl*) 
-review survey years (if survey was e.g. conducted 2017-2018 and decide if the majority of interviews was conducted in 2017 or 2018) 
-review grades and adjust (it is uuseful to also check the education system) 
-check that psu= hh1 , stratum==hh7 
-if psu is unavailable use hh1, and if stratum is unavailable use hh6/7 to generate stratum 
*/ 
* review years 
tab fs7y 
 
*review and adjust grades 
//in some countries, grades start at 1 again in secondary schools, so it is necessary to review the grades and adjust accordingly 
tab cb5b cb5a 
tab cb5a schage 
tab cb5b schage 
 
//example of adjusting grades 
replace idgrade = idgrade + 9 if cb5a== 3 
replace idgrade = idgrade + 12 if cb5a== 4 | cb5a== 5 | cb5a== 6 
label define grade 13 "tertiary" 14 "tertiary" 15 "tertiary" 16 "tertiary" 17 "tertiary" 18 "tertiary" 
label var idgrade grade 
replace idgrade = . if  cb5b>90 
	 
tab cb5a idgrade 
tab idgrade schage 
order cb5a cb5b idgrade schage 
 
*review missing variables 
svyset [pweight= learner_weight], strata(strata1) psu(su1)  
replace score_mics_read = 99 if score_mics_read== . 
 
svy: tab score_mics_read, se details 
tab year 
 
*review and generate psu and strata1 
egen stratum2 = group(hh6 hh7) 
 
*------------------------------------------------------------------------------- 
*Trying of code which is used for countries 
*------------------------------------------------------------------------------- 
*create reading score 
foreach i in FL22A FL22B FL22C FL22D FL22E{ 
gen score_`i' = `i' 
replace score_`i' = 0 if `i'>=2 
replace score_`i' = . if `i'==. 
} 
egen read_comp_score =rowtotal(score_FL22A score_FL22B score_FL22C score_FL22D score_FL22E) 
replace read_comp_score = . if score_FL22A==. & score_FL22B==. & score_FL22C==. & score_FL22D==. & score_FL22E==. 
gen read_comp_score_pct= read_comp_score/5 
gen score_mics_read = read_comp_score_pct  
 
*create highest grade attended 
gen grade = cb5b 
replace grade = grade + 9 if cb5a== 3 
replace grade = grade + 9 if cb5a== 4 
*------------------------------------------------------------------------------- 
*review when variables are missing through following questionnaire 
*------------------------------------------------------------------------------- 
gen age_group = . 
replace age_group= 1 if cb3==5 |cb3==6 
replace age_group = 2 if cb3>6 & cb3<15 
replace age_group = 3 if cb3==15 | cb3==16 | cb3==17 
gen young = 0 
replace young = 1 if cb3== 7 | cb3==8 | cb3==9 
 
gen read_practice = 0 
replace read_practice= 1 if fl14==1 & fl15== 1 & fl17==1  
replace read_practice =1 if fl14==1 & fl17== 1 
replace read_practice= . if fl10!=1  
replace read_practice= . if  young!=1 & cb7==1 
 
egen nr_read_correct = rowtotal(fl19w*)   
gen read_correct = 0 
replace read_correct = 1 if nr_read_correct <=7 
replace read_correct = . if fl19w1==.  
svy: tab read_correct  
 
gen fl8a= 1 
replace fl8a= . if  fl7==. 
replace fl8a= 0 if fl7==1 | fl7==2 | fl9==1 | fl9==2 
 
*Gambia / Kiribati / Macedonia (questionnaire in two languages) 
gen test_language =0 
replace test_language =1 if fl7==1 | fl7==2 
replace test_language=. if fl7==. 
 
*Turkmenistan (questionnaire in two languages) 
gen test_language =0 
replace test_language =1 if fl7==1 | fl7==3 
replace test_language=. if fl7==. 
 
gen attempted_first=1 
replace attempted_first =999 if fl19w1==. & fl19wa1==. 
svy: tab attempted_first 
 
*Kyrgyz (quest in four languages) 
gen test_language =0 
replace test_language =1 if fl7==1 | fl7==2 | fl7==3 | fl7 ==4 
replace test_language=. if fl7==. 
 
foreach var of varlist fl28 age_group fl1 fl3 fl7 cb7 fl9 fl10 read_practice fl21 fl22a fl8a fl19w1 read_correct flintro fl14 fl15 fl17 test_language cb4 { 
	replace `var' = 999 if `var' ==.  
} 
 
svyset [pw=fsweight], strata(strata1) psu(su1) 
foreach var of varlist age_group fl1 fl3  cb7 cb4 test_language fl9 fl10 read_practice fl19w1 fl22a { 
svy: tab `var', se  
} 
*------------------------------------------------------------------------------- 
*Replace missings  
*------------------------------------------------------------------------------- 
*easy way 
replace score_mics_read = 999 if score_mics_read ==.  
svy: tab score_mics_read, se  
 
 
replace score_mics_read = 0 if score_mics_read== . 
replace score_mics_read =.z if fl10 == . | fl10 ==2 
replace score_mics_read = 999 if score_mics_read ==.  
replace score_mics_read = 99 if score_mics_read ==.z  
svy: tab score_mics_read, se  
mdesc schooling  
 
*complicated way 
	*age group 
	replace score_mics_read= .z if cb3>6 & cb3<15 
	*consent 
	replace score_mics_read =.z if fl1==2 | fl3 ==2 | fl10 ==2 
	*language reasons 
	gen wrong_language == 0  
	replace wrong_language ==1 if fl10 ==. & fl3!= . | fl3==2 
	replace mics_score_read == .z if wrong_language ==1 
	*failing the reading practice 
	gen young = 0 
	replace young = 1 if cb3== 7 | cb3==8 | cb3==9 
	 
	gen read_practice = 0 
	replace read_practice= 1 if fl14==1 & fl15== 1 & fl17==1  
	replace read_practice =1 if fl14==1 & fl17== 1 
	replace read_practice= . if fl10!=1  
	replace read_practice= . if  young!=1 & cb7==1 
	//check cb7 again what it is 
	replace score_mics_read = 0 if read_practice ==0 
*------------------------------------------------------------------------------- 
*Replicate reading scores Gambia  
*------------------------------------------------------------------------------- 
svyset su1 [pw=fsweight], strata(strata1)  
svy: tab foundational*, se 
order psu hh1 
svyset hh1 [pw=fsweight], strata(strata1)  
svy: tab foundational*, se 
svyset [pw=fsweight], strata(strata1)  psu(hh1) 
svy: tab foundational*, se 
*select children 
keep if cb3>=7 & cb3<=14 
keep if fl28==1 
*reading correctly 
gen nr_read_correct= fl20a-fl20b 
gen read_correct= 0 
replace read_correct= 1 if nr_read_correct>= 0.9*72 
replace read_correct = . if nr_read_correct==. 
svy: tab read_correct 
*correctly answer three literal questions 
gen answer_literal = 0 
replace answer_literal= 1 if  (fl22a==1 & fl22b==1 & fl22c==1) 
replace answer_literal = 0 if fl22a==. | fl22b==. | fl22c==. 
svy: tab answer_literal  
*correctly answer two inferential questions 
gen answer_inferential = 0 
replace answer_inferential= 1 if fl22d==1 & fl22e==1  
replace answer_inferential= 0 if fl22d==. | fl22e==.  
*demonstrate foundational reading skills 
gen foundational_read = 0 
replace foundational_read= 1 if read_correct==1 & answer_inferential==1 & answer_literal==1   
 
foreach var of varlist read_correct answer_* foundational* { 
svy: tab `var',se 
} 
 
*------------------------------------------------------------------------------- 
*Replicate reading scores KGZ 
*------------------------------------------------------------------------------- 
 
svyset [pw=fsweight], strata(strata1) psu(su1) 
*select children 
keep if cb3>=7 & cb3<=14 
keep if fl28==1 
*reading correctly 
//replace fl20a=72 if fl19w60==2 & fl19w59!=2  
gen nr_read_correct= fl20a-fl20b 
gen read_correct= 0 
replace read_correct= 1 if nr_read_correct>= 72*0.9  
replace read_correct = . if nr_read_correct==. 
 
//order fs12 fs13 read_correct* nr_read* fl20a fl20b fl19w59 fl19w60 fl19w72 
svy: tab read_correct 
*correctly answer three literal questions 
gen answer_literal = 0 
replace answer_literal= 1 if  (fl22a==1 & fl22b==1 & fl22c==1) 
replace answer_literal = 0 if fl22a==. | fl22b==. | fl22c==. 
svy: tab answer_literal  
*correctly answer two inferential questions 
gen answer_inferential = 0 
replace answer_inferential= 1 if fl22d==1 & fl22e==1  
replace answer_inferential= 0 if fl22d==. | fl22e==.  
*demonstrate foundational reading skills 
gen foundational_read = 0 
replace foundational_read= 1 if read_correct==1 & answer_inferential==1 & answer_literal==1   
 
foreach var of varlist read_correct answer_* foundational* { 
svy: tab `var',se 
} 
*------------------------------------------------------------------------------- 
*Replicate reading scores Kiribati 
*------------------------------------------------------------------------------- 
 
svyset [pw=fsweight], strata(stratum) psu(psu) 
*select children 
keep if cb3>=7 & cb3<=14 
keep if fl28==1 
*reading correctly 
gen nr_read_correct= fl20a-fl20b 
gen read_correct= 0 
replace read_correct= 1 if nr_read_correct>= 0.9*78 
replace read_correct = 0 if nr_read_correct==. 
svy: tab read_correct  
*correctly answer three literal questions 
gen answer_literal = 0 
replace answer_literal= 1 if  (fl22a==1 & fl22b==1 & fl22c==1) 
replace answer_literal = 0 if fl22a==. | fl22b==. | fl22c==. 
svy: tab answer_literal  
*correctly answer two inferential questions 
gen answer_inferential = 0 
replace answer_inferential= 1 if fl22d==1 & fl22e==1  
replace answer_inferential= 0 if fl22d==. | fl22e==.  
*demonstrate foundational reading skills 
gen foundational_read = 0 
replace foundational_read= 1 if read_correct==1 & answer_inferential==1 & answer_literal==1   
 
foreach var of varlist read_correct answer_* foundational* { 
svy: tab `var',se 
} 
*------------------------------------------------------------------------------- 
*Replicate reading scores MKD /MKD roma 
*------------------------------------------------------------------------------- 
 
svyset [pw=fsweight], strata(stratum) psu(psu) 
*select children 
keep if cb3>=7 & cb3<=14 
keep if fl28==1 
*reading correctly 
gen nr_read_correct= fl20a-fl20b 
gen read_correct= 0 
 
replace read_correct= 1 if nr_read_correct>= 62 & fs13==2 
replace read_correct= 1 if nr_read_correct>= 69 & fs13==3 
replace read_correct = 0 if nr_read_correct==. 
svy: tab read_correct  
 
//order fs12 fs13 read_correct nr_read* fl20a fl20b fl19w69 fl19wa77 
*correctly answer three literal questions 
gen answer_literal = 0 
replace answer_literal= 1 if  (fl22a==1 & fl22b==1 & fl22c==1) 
replace answer_literal = 0 if fl22a==. | fl22b==. | fl22c==. 
svy: tab answer_literal  
*correctly answer two inferential questions 
gen answer_inferential = 0 
replace answer_inferential= 1 if fl22d==1 & fl22e==1  
replace answer_inferential= 0 if fl22d==. | fl22e==.  
*demonstrate foundational reading skills 
gen foundational_read = 0 
replace foundational_read= 1 if read_correct==1 & answer_inferential==1 & answer_literal==1   
 
foreach var of varlist read_correct answer_* foundational* { 
svy: tab `var',se 
} 
*------------------------------------------------------------------------------- 
*Replicate reading scores TKM 
*------------------------------------------------------------------------------- 
 
svyset [pw=fsweight], strata(stratum) psu(psu) 
*select children 
keep if cb3>=7 & cb3<=14 
keep if fl28==1 
*reading correctly 
gen nr_read_correct= fl20a-fl20b 
gen read_correct= 0 
 
replace read_correct= 1 if nr_read_correct>= 69*0.9 & fs13==3 
replace read_correct= 1 if nr_read_correct>= 60*0.9 & fs13==2 
replace read_correct = 0 if nr_read_correct==. 
svy: tab read_correct  
 
//order fs12 fs13 read_correct nr_read* fl20a fl20b fl19w69 fl19wa77 
*correctly answer three literal questions 
gen answer_literal = 0 
replace answer_literal= 1 if  (fl22a==1 & fl22b==1 & fl22c==1) 
replace answer_literal = 0 if fl22a==. | fl22b==. | fl22c==. 
svy: tab answer_literal  
*correctly answer two inferential questions 
gen answer_inferential = 0 
replace answer_inferential= 1 if fl22d==1 & fl22e==1  
replace answer_inferential= 0 if fl22d==. | fl22e==.  
*demonstrate foundational reading skills 
gen foundational_read = 0 
replace foundational_read= 1 if read_correct==1 & answer_inferential==1 & answer_literal==1   
 
foreach var of varlist read_correct answer_* foundational* { 
svy: tab `var',se 
} 
