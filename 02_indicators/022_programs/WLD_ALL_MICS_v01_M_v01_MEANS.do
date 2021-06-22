*****************************************************
*Author: Syedah Aroob Iqbal
******************************************************

/*
This do file:
1) Calculates reading scores for MICS countries:
*/

set trace on
set seed 10051990
set sortseed 10051990

	clear

	save "$output\WLD_All_MICS_v01_M_v01_A_MEAN.txt" , emptyok replace
			
	file open myfile using "$output\WLD_All_MICS_v01_M_v01_A_MEAN.txt", write replace

	file write myfile "countrycode" _tab "year"  _tab "indicator" _tab "value" _tab "se" _tab "n" _n /*header */
			
	file close myfile

*Change the line below to first bring the file master_countrycode_list.dta from rawdata (Please include the details available in the file to be able to run the loop over the countrycodes.	
use "${clone}/01_harmonization/011_rawdata/master_countrycode_list.dta",  clear


/*replace grade_2_3 = 1 if edlevel_current == 1 & (inlist(grade_current,2,3)) & (inlist(countrycode,"BGD","CAF","GHA","GMB","GNB","KGZ","KIR","LSO","MDG") | inlist(countrycode,"MKD","MNG","PAK","PSE","SLE","STP","TKM")
replace grade_2_3 = 1 if edlevel_current == 10 & (inlist(grade_current,2,3)) & inlist(countrycode,"COD")
replace grade_2_3 = 1 if (inlist(grade_current,2,3)) & inlist(countrycode,"NPL")


label define grade_2_3 1 "Grade2_3"
label define grade_2_3 0 "Not_grade2_3", add
label values grade_2_3 grade_2_3
*/
 
*Setting locals:
levelsof countrycode, local(country)

local subject read lit infer

local traitvars total 
gen total = 1 
label define total 1 "total"
label values total total




foreach c of local country {
	display "`c'"
	
	preserve
	
	keep if countrycode == "`c'" 
	display "`c'"
	
	levelsof year, local(yr)
	foreach y of local yr {
	*display "`c'" "`y'"
						
	*--------------------------------------------------------------------------------
	* 3) Separating indicators by trait groups
	*--------------------------------------------------------------------------------
								
		foreach sub of local subject {
			display "`sub'"
			foreach indicator in score scorescaled rscore {
				capture confirm variable `indicator'_mics_`sub'
				display _rc
				if !_rc {

					foreach trait of local traitvars  {
					capture confirm variable `trait'
					if _rc == 0 {
						mdesc `trait'
						if r(percent) != 100 { 
							separate(`indicator'_mics_`sub'), by(`trait') gen(`indicator'`sub'`trait')
		
						
	*-----------------------------------------------------------------------------
	*4) *Calculation of indicators by subgroups of traitvars
	*-----------------------------------------------------------------------------
							levelsof `trait', local(lev)
							foreach lv of local lev {
								local label: label (`trait') `lv'

				
									*Setting survey structure
									if !inlist("`c'","KGZ","SLE","SUR","TUN") {
									
										svyset [pweight= learner_weight], strata(strata1) psu(su1)

										svy: mean `indicator'`sub'`trait'`lv' 
									}
									
	/*								if inlist("`c'","KGZ") {
								

										 mean `indicator'`sub'`trait'`lv' [pweight = fsweight]
									}
									
									if inlist("`c'","SLE","SUR","TUN") {
								

										 svyset  [pweight = fsweight], strata(stratum)
										 svy: mean `indicator'`sub'`trait'`lv' 
									} */
									
									if _rc == 0 {

									
										matrix pv_mean = e(b)
										matrix pv_var  = e(V)
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

