*****************************************************
*Author: Syedah Aroob Iqbal & Katharina Ziegler
******************************************************

/*
This do file:
1) Calculates reading scores for MICS countries:
*/

*set trace on
set seed 10051990
set sortseed 10051990

	clear

	save "$output\WLD_All_MICS_v01_M_v01_A_MEAN.txt" , emptyok replace
			
	file open myfile using "$output\WLD_All_MICS_v01_M_v01_A_MEAN.txt", write replace

	file write myfile "countrycode" _tab "year"  _tab "indicator" _tab "value" _tab "se" _tab "n" _n /*header */
			
	file close myfile

*Change the line below to first bring the file master_countrycode_list.dta from rawdata (Please include the details available in the file to be able to run the loop over the countrycodes.	
use "${clone}/01_harmonization/011_rawdata/master_countrycode_list.dta",  clear
keep if assessment== "MICS"
 
*Setting locals:
levelsof countrycode, local(country)

local subject read read_literal read_inferential math math_foundational
local traitvars total 


foreach c of local country {
	display "`c'"
	
	preserve
	
	keep if countrycode == "`c'" 
	display "`c'"
	
	levelsof year, local(yr)
	foreach y of local yr {
	*display "`c'" "`y'"
	use "${clone}/01_harmonization/013_outputs/`c'/`c'_`y'_MICS/`c'_`y'_MICS_v01_M_wrk_A_GLAD_ALL", replace
	*--------------------------------------------------------------------------------
	* 3) Separating indicators by trait groups
	*--------------------------------------------------------------------------------
								
		foreach sub of local subject {
			display "`sub'"
			foreach indicator in score {
				capture confirm variable `indicator'_mics_`sub'
				display _rc
			
				if !_rc {
				
					foreach trait of local traitvars  {
					capture confirm variable `trait'
					display _rc
					if _rc == 0 {
						mdesc `trait'
						return list
						if r(percent) != 100 { 
							separate(`indicator'_mics_`sub'), by(`trait') gen(`indicator'`sub'`trait')
	*-----------------------------------------------------------------------------
	*4) *Calculation of indicators by subgroups of traitvars
	*-----------------------------------------------------------------------------
							levelsof `trait', local(lev)
							foreach lv of local lev {
								local label: label (`trait') `lv'
				
									*Setting survey structure
									if inlist("`c'","XXX") {
									
										svyset [pweight= learner_weight], strata(strata1) psu(su1) singleunit(scaled)
										svy: mean `indicator'`sub'`trait'`lv' 
									}
									
									else  if !inlist("`c'","XXX"){
										svyset [pweight= learner_weight], strata(strata1) psu(su1) singleunit(scaled)
										svy: mean `indicator'`sub'`trait'`lv' 
										return list
										matrix list e(V)
									}
									display _rc
									if _rc == 0 {
									
										matrix pv_mean = e(b)
										matrix pv_var  = e(V)
										
										matrix list pv_var
										
										local  m_`indicator'`sub'`label'  = pv_mean[1,1]
										local  se_`indicator'`sub'`label' = sqrt(pv_var[1,1])
										local  n_`indicator'`sub'`label'  = e(N)
													
										file open myfile   using	 "$output\WLD_All_MICS_v01_M_v01_A_MEAN.txt", write append			

										file write myfile "`c'" _tab "`y'" _tab "`indicator'`sub'`label'" _tab "`m_`indicator'`sub'`label''" _tab "`se_`indicator'`sub'`label''" _tab  "`n_`indicator'`sub'`label''"  _n

										file close myfile
									
									}
								}
							}
						}
					}
				}
			}
		}
	}
	restore
}
		
insheet using "$output\WLD_All_MICS_v01_M_v01_A_MEAN.txt", clear names
gen test = "MICS"
*cf _all using "$output\WLD_All_MICS_v01_M_v01_A_MEAN.dta", verbose
save "$output\WLD_All_MICS_v01_M_v01_A_MEAN.dta", replace

use "$output\WLD_All_MICS_v01_M_v01_A_MEAN.dta", replace
export excel using "$output\WLD_All_MICS_v01_M_v01_A_MEAN", replace

