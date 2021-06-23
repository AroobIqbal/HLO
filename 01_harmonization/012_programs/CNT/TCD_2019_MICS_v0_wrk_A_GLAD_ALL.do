*=========================================================================*
* GLOBAL LEARNING ASSESSMENT DATABASE (GLAD)
* Project information at: https://github.com/worldbank/GLAD
*
* Metadata to be stored as 'char' in the resulting dataset (do NOT use ";" here)
local region      = "TCD"   /* LAC, SSA, WLD or CNT such as KHM RWA */
local year        = "2019"  /* 2019 */
local assessment  = "MICS" /* PIRLS, PISA, EGRA, etc */
local master      = "v01_M" /* usually v01_M, unless the master (eduraw) was updated*/
local adaptation  = "wrk_A_GLAD" /* no need to change here */
local module      = "ALL"  /* for now, we are only generating ALL and ALL-BASE in GLAD */
local ttl_info    = "Joao Pedro de Azevedo [eduanalytics@worldbank.org]" /* no need to change here */
local dofile_info = "last modified by Katharina Ziegler, 17.5.2021"  /* change date*/
*
* Steps:
* 0) Program setup (identical for all assessments)
* 1) Open all rawdata, lower case vars, save in temp_dir
* 2) Combine all rawdata into a single file (merge and append)
* 3) Standardize variable names across all assessments
* 4) ESCS and other calculations
* 5) Bring WB countrycode & harmonization thresholds, and save dtas
*=========================================================================*

  *---------------------------------------------------------------------------
  * 0) Program setup (identical for all assessments)
  *---------------------------------------------------------------------------

  // Parameters ***NEVER COMMIT CHANGES TO THOSE LINES!***
  //  - whether takes rawdata from datalibweb (==1) or from indir (!=1), global in 01_run.do
  local from_datalibweb = $from_datalibweb
  //  - whether checks first if file exists and attempts to skip this do file
  local overwrite_files = $overwrite_files
  //  - optional shortcut in datalibweb
  local shortcut = "$shortcut"
  //  - setting random seed at the beginning of each do for reproducibility
  set seed $master_seed

  // Set up folders in clone and define locals to be used in this do-file
  glad_local_folder_setup , r("`region'") y("`year'") as("`assessment'") ma("`master'") ad("`adaptation'")
  local temp_dir     "`r(temp_dir)'"
  local output_dir   "`r(output_dir)'"
  local surveyid     "`r(surveyid)'"
  local output_file  "`surveyid'_`adaptation'_`module'"

  // If user does not have access to datalibweb, point to raw microdata location
  if `from_datalibweb' == 0 {
    local input_dir	= "${input}/CNT/`region'/`region'_`year'_`assessment'/`surveyid'/Data/Stata"
  }

  // Confirm if the final GLAD file already exists in the local clone
  cap confirm file "`output_dir'/`output_file'.dta"
  display _rc
  *display `output_dir'
  // If the file does not exist or overwrite_files local is set to one, run the do
  *if (_rc == 601) | (`overwrite_files') {

    /* Filter the master country list to only this assessment-year - Not necessary for country-level EGRAs
    use "${clone}/01_harmonization/011_rawdata/master_countrycode_list.dta", clear
    keep if (assessment == "`assessment'") & (year == `year')
    // Most assessments use the numeric idcntry_raw but a few (ie: PASEC 1996) have instead idcntry_raw_str
    if use_idcntry_raw_str[1] == 1 {
      drop   idcntry_raw
      rename idcntry_raw_str idcntry_raw
    }
    keep idcntry_raw national_level countrycode
    save "`temp_dir'/countrycode_list.dta", replace
	*/

    // Tokenized elements from the header to be passed as metadata
    local glad_description  "This dataset is part of the Global Learning Assessment Database (GLAD). It contains microdata from `assessment' `year'. Each observation corresponds to one learner (student or pupil), and the variables have been harmonized."
    local metadata          "region `region'; year `year'; assessment `assessment'; master `master'; adaptation `adaptation'; module `module'; ttl_info `ttl_info'; dofile_info `dofile_info'; description `glad_description'"

    *---------------------------------------------------------------------------
    * 1) Open all rawdata, lower case vars, save in temp_dir
    *---------------------------------------------------------------------------

    /* NOTE: Some assessments will loop over `prefix'`cnt' (such as PIRLS, TIMSS),
       then create a temp file with all prefixs of a cnt merged.
       but other asssessments only need to loop over prefix (such as LLECE).
       See the two examples below and change according to your needs */



       // Temporary copies of the 4 rawdatasets needed for each country (new section) * 1 dataset 
         if `from_datalibweb'==1 {
           noi edukit_datalibweb, d(country(`region') year(`year') type(EDURAW) surveyid(`surveyid') filename(2013.dta) `shortcut')
         }
         else {
           use "`input_dir'/`region'_`year'_MICS_v01_M", clear
         }
         rename *, lower
         compress
         save "`temp_dir'/`region'_`year'_MICS_v01_M", replace
		
		

    noi disp as res "{phang}Step 1 completed (`output_file'){p_end}"


    *---------------------------------------------------------------------------
    * 2) Combine all rawdata into a single file (merge and append)
    *---------------------------------------------------------------------------

    /* NOTE: the merge / append of all rawdata saved in temp in above step
       will vary slightly by assessment.
       See the two examples continued and change according to your needs */
	   
	   *Just one file
    noi disp as res "{phang}Step 2 completed (`output_file'){p_end}"


    *---------------------------------------------------------------------------
    * 3) Standardize variable names across all assessments
    *---------------------------------------------------------------------------
    // For each variable class, we create a local with the variables in that class
    //     so that the final step of saving the GLAD dta  knows which vars to save

    // Every manipulation of variable must be enclosed by the ddi tags
    // Use clonevar instead of rename (preferable over generate)
    // The labels should be the same.
    // The generation of variables was commented out and should be replaced as needed

    // ID Vars:
    local idvars "idcntry_raw year idlearner"

    *<_idcntry_raw_>
    gen idcntry_raw = "`region'"
    label var idcntry_raw "Country ID, as coded in rawdata"
    *</_idcntry_raw_>
	
	*<_year_>
	clonevar year = fs7y
	label var year "Year"
	*</_year_>


    /*<_idschool_> - Information not available
	gen idschool = school_code
    label var idschool "School ID"
    *</_idschool_>*/
	
    /*<_idclass_> - Information not available 
    label var idclass "Class ID"
    *</_idclass_>*/

    *<_idlearner_> - No ID avaialable
	gen idlearner = _n
    label var idlearner "Learner ID"
    *</_idlearner_>
	
    /* Drop any value labels of idvars, to be okay to append multiple surveys
    foreach var of local idvars {
      label values `var' .
    }*/


    // VALUE Vars: 	  /* CHANGE HERE FOR YOUR ASSESSMENT!!! PIRLS EXAMPLE */
    local valuevars	"score_mics* "

    *<_score_assessment_reading> 
	foreach i in fl22a fl22b fl22c fl22d fl22e{ 
	gen score_`i' = `i' 
	replace score_`i' = 0 if `i'>=2 
	replace score_`i' = . if `i'==. 
	} 
	egen read_comp_score =rowtotal(score_fl22a score_fl22b score_fl22c score_fl22d score_fl22e) 
	replace read_comp_score = . if score_fl22a==. & score_fl22b==. & score_fl22c==. & score_fl22d==. & score_fl22e==. 
	gen read_comp_score_pct= read_comp_score/5 
 
	 clonevar score_mics_read = read_comp_score_pct  
     label var score_mics_read "Percentage of correct reading comprehension questions for `assessment' (out of 5)" 
    *</_score_assessment_reading> 
 
	*</_score_assessment_math> 
		foreach i of var fl24* fl25* fl27* { 
	gen score_`i' = `i' 
	replace score_`i' = 0 if `i'>=2 
	replace score_`i' = . if `i'==. 
	} 
	egen math_comp_score =rowtotal(score_fl24a score_fl24b score_fl24c score_fl24d score_fl24e score_fl25a score_fl25b score_fl25c score_fl25d score_fl25e score_fl27a score_fl27b score_fl27c score_fl27d score_fl27e) 
	replace math_comp_score = . if score_fl24a ==. & score_fl24b ==. &score_fl24c ==. & score_fl24d ==. & score_fl24e ==. & score_fl25a ==. & score_fl25b ==. & score_fl25c ==. & score_fl25d ==. & score_fl25e ==. & score_fl27a ==. & score_fl27b ==. & score_fl27c ==. & score_fl27d ==. & score_fl27e==.  
	gen math_comp_score_pct= math_comp_score/15 
	 
	 clonevar score_mics_math = math_comp_score_pct  
     label var score_mics_math "Percentage of correct math comprehension questions for `assessment' (out of 15)" 
	*</_score_assessment_math> 
	 
	*<clean score_assessment_subject> 
	replace score_mics_read = 0 if score_mics_read== .			 
	replace score_mics_read =.z if fl10 == . | fl10 ==2	 
	label define score_mics_read .z "Not applicable" 
	label val score_mics_read score_mics_read 
	 
	replace score_mics_math = 0 if score_mics_math== .			 
	replace score_mics_math =.z if fl10 == . | fl10 ==2	 
	label define score_mics_math .z "Not applicable" 
	label val score_mics_math score_mics_math 
	//replacing children who drop out because of age, consent or language reasons as ".z" and missing children who failed the reading practice or did not finish reading the story as 0 
	*<clean score_assessment_subject>* 
	
	*<official_score_assessment_reading>  
	 gen score_mics_read_literal = 0
	 replace score_mics_read_literal= 1 if  (fl22a==1 & fl22b==1 & fl22c==1) 
	 replace score_mics_read_literal=. if cb3<7 & cb3>14 
	 replace score_mics_read_literal=. if fl28!=1 
	 
	 gen score_mics_read_inferential = 0 
	 replace score_mics_read_inferential= 1 if fl22d==1 & fl22e==1 
	 replace score_mics_read_inferential=. if cb3<7 & cb3>14  
	 replace score_mics_read_inferential=. if fl28!=1  
 	 *<official_score_assessment_reading>  
	
	*<official_score_assessment_math>  
	 gen score_mics_math_foundational = 0
	 replace score_mics_math_foundational= 1 if fl23a==1 & fl23b==1 & fl23c==1 & fl23d==1 & fl23e==1 & fl23f==1 & fl24a==1 & fl24b==1 & fl24c==1 & fl24d==1 & fl24e==1 & fl25a==1 & fl25b==1 & fl25c==1 & fl25d==1 & fl25e==1 & fl27a==1 & fl27b==1 & fl27c==1 & fl27d==1 & fl27e==1 
	 replace score_mics_math_foundational=. if cb3<7 & cb3>14 
	 replace score_mics_math_foundational=. if fl28!=1 
 	 *<official_score_assessment_math>

    // TRAIT Vars:
     local traitvars	"idgrade male age urban school total"
	
	*<_total_> 
	gen total = 1 
	label define total 1 "total"
	label values total total
	*<_total_> 
	
	*<_idgrade_> 
	gen idgrade = cb5b
	replace idgrade = idgrade + 6 if cb5a== 21 | cb5a== 20
	replace idgrade = idgrade + 10 if cb5a== 40 | cb5a== 41 | cb5a== 31 | cb5a== 30
	replace idgrade = . if schage ==5 & idgrade==13
	replace idgrade = . if schage ==4 & idgrade==10
	replace idgrade = . if schage ==5 & idgrade==8
	label var idgrade "Grade"
    *</_idgrade_>


    *<_age_> 
    clonevar age = cb3	
	replace age=. if age>18
    label var age "Learner age at time of assessment"
    *</_age_>*

    *<_urban_> 
    gen byte urban = hh6
	replace urban= 0 if urban==2
	label define urban 1 "urban" 0 "rural"
	label values urban urban
    label var urban "School is located in urban/rural area"
    *</_urban_>

    *<_urban_o_>
    *decode acbg05a, g(urban_o)
    *label var urban_o "Original variable of urban: population size of the school area"
    *</_urban_o_>*/

    *<_male_>
    gen byte male = 1 if hl4 == 1
	replace male = 0 if hl4 == 2
	label define male 1 "male" 0 "female"
    label var male "Learner gender is male/female"
	label values male male
    *</_male_>
	
	*<_school_> 
	clonevar school = cb7
	replace school = 0 if school ==2
	replace school = 0 if cb4==2
	label define school 1 "yes" 0 "no"
	label val school school
    label var school "Learner attended school at time of assessment"
    *</_school_>

    // SAMPLE Vars:		 	  /* CHANGE HERE FOR YOUR ASSESSMENT!!! PIRLS EXAMPLE */
    local samplevars "learner_weight su1 strata1"
	

	
	*<_Nationally_representative_> 
	gen national_level = 1
	*</_Nationally_representative_>
	
	*<_Nationally_representative_> 
	gen nationally_representative = 1
	*</_Nationally_representative_>

	
	*<_Regionally_representative_> 
	gen regionally_representative = 1
	*<_Regionally_representative_>

	/*From SPSS file:
		/PLANVARS ANALYSISWEIGHT=fsweight
		/DESIGN STRATA = strat CLUSTER=HH1  				//hh1=psu
		/ESTIMATOR TYPE=WR									// "WR estimation does not include a correction for sampling from a finite population"
	Translate to STATA: 
		svyset [pweight= fsweight], strata(hh6) psu(psu) 	*/	

    *<_learner_weight_>
    clonevar learner_weight  = fsweight
    label var learner_weight "Total learner weight"
    *</_learner_weight_>
	
    *<_psu_>
    clonevar su1  = psu
    label var su1 "Primary sampling unit"
    *</_learner_weight_>
	
	*<_strata1_> 
	clonevar strata1 = stratum
    label var strata1 "Strata 1"
    *</_learner_weight_>
	
	*<_fpc1_>
   * label var fpc1 "fpc 1"
    *</_learner_weight_>*/

	*<_su2_>
 *	clonevar su2 = stage2
 *   label var su2 "Sampling unit 2"
    *</_learner_weight_>
	
	*<_strata2_>
 *   label var strata2 "Strata 2"
    *</_learner_weight_>

	*<_fpc2_>
  *  label var fpc2 "fpc 2"
    *</_learner_weight_>*/
	
	*<_su3_>
 *	clonevar su3 = stage3
 *  label var su3 "Sampling unit 2"
    *</_learner_weight_>
	
	*<_strata3_>
 *  label var strata3 "Strata 3"
    *</_learner_weight_>

	*<_fpc3_>
 *  label var fpc3 "fpc 3"
    *</_learner_weight_>*/


    /*<_jkzone_>
    label var jkzone "Jackknife zone"
    *</_jkzone_>

    *<_jkrep_>
    label var jkrep "Jackknife replicate code"
    *</_jkrep_>*/

	svyset [pweight= learner_weight], strata(strata1) psu(su1) 
	
    noi disp as res "{phang}Step 3 completed (`output_file'){p_end}"

    *---------------------------------------------------------------------------
    * 4) ESCS and other calculations
    *---------------------------------------------------------------------------

    // Placeholder for other operations that we may want to include (kept in ALL-BASE)
    *<_escs_>
	*ESCS variables avaialble
	*Develop code for ESCS
    * code for ESCS
    * label for ESCS
    *</_escs_>

    noi disp as res "{phang}Step 4 completed (`output_file'){p_end}"


    *---------------------------------------------------------------------------
    * 5) Bring WB countrycode & harmonization thresholds, and save dtas
    *---------------------------------------------------------------------------

    // Brings World Bank countrycode from ccc_list - No need to merge as country level data
	clonevar countrycode = idcntry_raw
    // NOTE: the *assert* is intentional, please do not remove it.
    // if you run into an assert error, edit the 011_rawdata/master_countrycode_list.csv
    *merge m:1 idcntry_raw using "`temp_dir'/countrycode_list.dta", keep(match) assert(match using) nogen

    // Surveyid is needed to merge harmonization proficiency thresholds
    gen str surveyid = "`region'_`year'_`assessment'"
    label var surveyid "Survey ID (Region_Year_Assessment)"

    // New variable class: keyvars (not IDs, but rather key to describe the dataset)
    local keyvars "surveyid countrycode national_level"

    /* Harmonization of proficiency on-the-fly, based on thresholds as CPI
    glad_hpro_as_cpi
    local thresholdvars "`r(thresholdvars)'"
    local resultvars    "`r(resultvars)'"*/

    // Update valuevars to include newly created harmonized vars (from the ado)
    local valuevars : list valuevars | resultvars
	
	*<_language_test_> 
	gen language_test = fs13
	*<_language_test_>

	
				// Additional metadata: EGRA characteristics
	*	char _dta[nationally_representative]    "1"
	*	char _dta[regionally_representative]    "0"


    // This function compresses the dataset, adds metadata passed in the arguments as chars, save GLAD_BASE.dta
    // which contains all variables, then keep only specified vars and saves GLAD.dta, and delete files in temp_dir
    edukit_save,  filename("`output_file'") path("`output_dir'") dir2delete("`temp_dir'")              ///
                idvars("`idvars'") varc("key `keyvars'; value `valuevars'; trait `traitvars'; sample `samplevars'") ///
                metadata("`metadata'") collection("GLAD")
				
*Results close but not exactly matching yet
 /* }

  else {
    noi disp as txt "Skipped creation of `output_file'.dta (already found in clone)"
    // Still loads it, to generate documentation
    use "`output_dir'/`output_file'.dta", clear
  }
}
