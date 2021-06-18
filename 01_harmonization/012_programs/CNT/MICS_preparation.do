*=========================================================================*
* GLOBAL LEARNING ASSESSMENT DATABASE (GLAD)
* Purpose of this file: create folders and datasets for MICS 6, but also a general file to try out code and apply to countries
*=========================================================================*
*-------------------------------------------------------------------------------
*Create directory
*-------------------------------------------------------------------------------
cd ${input}\CNT

*Add country for which the directory should be created
local cnt 
foreach j in `cnt' {
//mkdir "`j'"
mkdir "`j'/`j'_2018_MICS"
mkdir "`j'/`j'_2018_MICS/`j'_2018_MICS_v01_M"
mkdir "`j'/`j'_2018_MICS/`j'_2018_MICS_v01_M\Data" 
mkdir "`j'/`j'_2018_MICS/`j'_2018_MICS_v01_M\Data\Original"
mkdir "`j'/`j'_2018_MICS/`j'_2018_MICS_v01_M\Data\Stata"
mkdir "`j'/`j'_2018_MICS/`j'_2018_MICS_v01_M\Data\Doc"
mkdir "`j'/`j'_2018_MICS/`j'_2018_MICS_v01_M\Data\Doc\Report"
}

*-------------------------------------------------------------------------------
*Load and clean SPSS file
*-------------------------------------------------------------------------------
*import dataset of primary caretake of children 5-17 (fs)
local cnt GMB KIR KGZ MKD
foreach j in `cnt' {
import spss "`j'/`j'_2018_MICS/`j'_2018_MICS_v01_M\Data\Original\fs", clear
save "`j'/`j'_2018_MICS/`j'_2018_MICS_v01_M/Data/Stata/`j'_2018_MICS_v01_M", replace

}

local cnt TKM 
foreach j in `cnt' {
import spss "`j'/`j'_2019_MICS/`j'_2019_MICS_v01_M\Data\Original\fs", clear
save "`j'/`j'_2019_MICS/`j'_2019_MICS_v01_M/Data/Stata/`j'_2019_MICS_v01_M", replace

}


*review missing variables
svyset [pweight= learner_weight], strata(strata1) psu(su1) 
replace score_mics_read = 99 if score_mics_read== .

svy: tab strata1 score*, se
svy: tab score*, se
tab year
//tabout score* strata1 using "\\wbgfscifs01\GEDEDU\GDB\Personal\WB576431\missings.xls", svy percent c(col) append

*-------------------------------------------------------------------------------
*Trying of code which is used for country code
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

*Ghambia / Kiribati / Macedonia (questionnaire in two languages)
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
*Replicate reading scores Ghambia / KGZ
*-------------------------------------------------------------------------------

svyset [pw=fsweight], strata(strata1) psu(su1)
*select children
keep if cb3>=7 & cb3<=14
keep if fl28==1
*reading correctly
gen nr_read_correct= fl20a-fl20b
gen read_correct= 0
replace read_correct= 1 if nr_read_correct>= 0.9*72
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
*Replicate reading scores MKD
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
*Replicate reading scores MKD roma
*-------------------------------------------------------------------------------
//incorrect
svyset [pw=fsweight], strata(stratum) psu(psu)
*select children
keep if cb3>=7 & cb3<=14
keep if fl28==1
*wrong language questionnaire
gen fl8a= 1
replace fl8a= . if fl9==. | fl7==.
replace fl8a= 0 if fl7==1 | fl7==2 | fl9==1 | fl9==2
svy: tab fl8a 
*reading correctly
gen nr_read_correct= fl20a-fl20b
gen read_correct= 0
replace read_correct = 0 if nr_read_correct==.
replace read_correct= 1 if nr_read_correct>= 0.9*69
*correctly answer three literal questions
gen answer_literal = 0
replace answer_literal= 1 if read_correct==1 & (fl22a==1 & fl22b==1 & fl22c==1)
replace answer_literal = 0 if fl22a==. & fl22b==. & fl22c==.
*correctly answer two inferential questions
gen answer_inferential = 0
replace answer_inferential= 1 if read_correct==1 & fl22d==1 & fl22e==1 
replace answer_inferential= 0 if fl22d==. & fl22e==. 
*demonstrate foundational reading skills
gen foundational_read = 0
*replace foundational_read = . if fl22a==. & fl22b==. & fl22c==. & fl22e==. &read_correct==.
replace foundational_read= 1 if read_correct==1 & answer_inferential==1 & answer_literal==1  

foreach var of varlist read_correct answer_* foundational* fl8a{
svy: tab `var',se
}
*-------------------------------------------------------------------------------
*Replicate reading scores Kiribati
*-------------------------------------------------------------------------------
 svyset [pw=fsweight], strata(stratum) psu(psu)
*select children
keep if cb3>=7 & cb3<=14
keep if fl28==1
*wrong language questionnaire

gen fl8a= 0
replace fl8a =1 if (fl7>=3 | fl7==.) & (fl9>=3 | fl9==.)
*replace fl8a= 1 if fl9==. | fl7==.
*replace fl8a= 0 if fl7==1 | fl7==2 | fl9==1 | fl9==2
svy: tab fl8a 
*reading correctly (1)
egen nr_read_correct = rowtotal(fl19w*)  
gen read_correct = 0
replace read_correct = 1 if nr_read_correct <=7
replace read_correct = 0 if fl19w1==.
*reading correctly (2)
gen nr_read_correct2= fl20a-fl20b
gen read_correct2= 0
replace read_correct2 = 0 if nr_read_correct2==.
replace read_correct2= 1 if nr_read_correct2>= 0.9*72 
tab read_correct read_correct2
*correctly answer three literal questions
gen answer_literal = 0
replace answer_literal= 1 if read_correct==1 & (fl22a==1 & fl22b==1 & fl22c==1)
replace answer_literal = 0 if fl22a==. & fl22b==. & fl22c==.
*correctly answer two inferential questions
gen answer_inferential = 0
replace answer_inferential= 1 if read_correct==1 & fl22d==1 & fl22e==1 
replace answer_inferential= 0 if fl22d==. & fl22e==. 
*demonstrate foundational reading skills
gen foundational_read = 0
*replace foundational_read = . if fl22a==. & fl22b==. & fl22c==. & fl22e==. &read_correct==.
replace foundational_read= 1 if read_correct==1 & answer_inferential==1 & answer_literal==1  

foreach var of varlist read_correct answer_* foundational* fl8a{
svy: tab `var',se
}
replace score_mics_read= 99 if score_mics_read==.
svy: tab score_mics_read, se
