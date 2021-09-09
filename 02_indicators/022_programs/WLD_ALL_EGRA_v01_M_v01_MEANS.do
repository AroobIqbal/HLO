*****************************************************
*Author: Syedah Aroob Iqbal & Katharina Ziegler
******************************************************

/*
This do file:
1) Calculates reading scores for EGRA countries:
*/

*set trace on
set seed 10051990
set sortseed 10051990

	clear

	save "$output\WLD_All_EGRA_v01_M_v01_A_MEAN.txt" , emptyok replace
			
	file open myfile using "$output\WLD_All_EGRA_v01_M_v01_A_MEAN.txt", write replace

	file write myfile "countrycode" _tab "year"  _tab "indicator" _tab "value" _tab "se" _tab "n" _n /*header */
			
	file close myfile

*Change the line below to first bring the file master_countrycode_list.dta from rawdata (Please include the details available in the file to be able to run the loop over the countrycodes.	
use "${clone}/01_harmonization/011_rawdata/master_countrycode_list.dta",  clear
keep if assessment== "EGRA" & region=="WLD"
 
*Setting locals:
levelsof countrycode, local(country)

local subject read
local traitvars total 


foreach c of local country {
	display "`c'"
	
	preserve
	
	keep if countrycode == "`c'" 
	display "`c'"
	
	levelsof year, local(yr)
	foreach y of local yr {
	display "`c'" "`y'"
	use "${clone}/01_harmonization/013_outputs/`c'/`c'_`y'_EGRA/`c'_`y'_EGRA_v01_M_wrk_A_GLAD_ALL", replace
	*--------------------------------------------------------------------------------
	* 3) Separating indicators by trait groups
	*--------------------------------------------------------------------------------
								
		foreach sub of local subject {
			display "`sub'"
			foreach indicator in score {
				capture confirm variable `indicator'_egra_`sub'
				display _rc
			
				if !_rc {
				
					foreach trait of local traitvars  {
					capture confirm variable `trait'
					display _rc
					if _rc == 0 {
						mdesc `trait'
						return list
						if r(percent) != 100 { 
							separate(`indicator'_egra_`sub'), by(`trait') gen(`indicator'`sub'`trait')
	*-----------------------------------------------------------------------------
	*4) *Calculation of indicators by subgroups of traitvars
	*-----------------------------------------------------------------------------
							levelsof `trait', local(lev)
							foreach lv of local lev {
								local label: label (`trait') `lv'
				
									*Setting survey structure
									if inlist("`c'","AFG", "AGO", "ATG", "BGD", "DMA")  {
										svyset [pweight= learner_weight]
										svy: mean `indicator'`sub'`trait'`lv' 
									}
									if inlist("`c'","GRD","HND", "JAM", "KHM", "KNA", "LAO", "LCA")  {
									
										svyset [pweight= learner_weight]
										svy: mean `indicator'`sub'`trait'`lv' 
									}
									if inlist("`c'","MKD","MWI","SDN", "SEN", "TON", "TUV", "VCT", "VUT", "WSM")  {
									
										svyset [pweight= learner_weight]
										svy: mean `indicator'`sub'`trait'`lv' 
									}
									if inlist("`c'", "GHA"){
										svyset su1 [pweight= learner_weight], strata(strata1) || su2, strata(strata2)  singleunit(scaled) vce(linearized)
										svy: mean `indicator'`sub'`trait'`lv' 
									}
									if inlist("`c'",  "SLE"){
										svyset su1 [pweight= learner_weight], strata(strata1) || su2, strata(strata2)  singleunit(scaled) 
										svy: mean `indicator'`sub'`trait'`lv' 
									}
									if inlist("`c'", "GUY"){
										svyset su1 [pweight = learner_weight], fpc(fpc1) strata(strata1) || su2, fpc(fpc2) || su3,  strata(strata3) singleunit(scaled) vce(linearized)
										svy: mean `indicator'`sub'`trait'`lv' 
									}
									if inlist("`c'", "IND", "TZA"){
										svyset su1 [pweight = learner_weight], fpc(fpc1) strata(strata1) || su2, fpc(fpc2) strata(strata2) || su4, fpc(fpc4) strata(strata4) singleunit(scaled) vce(linearized)
										svy: mean `indicator'`sub'`trait'`lv' 
									}
									if inlist("`c'", "IRQ" ){
										svyset su1 [pweight = learner_weight], fpc(fpc1) strata(strata1) || su2, fpc(fpc2) strata(strata2) || su3, fpc(fpc3) singleunit(scaled) vce(linearized)
										svy: mean `indicator'`sub'`trait'`lv' 
									}
									if inlist("`c'", "PHL", "SLV" ){
										svyset su1 [pweight = learner_weight], fpc(fpc1) strata(strata1) || su2, fpc(fpc2) strata(strata2) || su3, fpc(fpc3) strata(strata3) singleunit(scaled) vce(linearized)
										svy: mean `indicator'`sub'`trait'`lv' 
									}
									if inlist("`c'", "PHL", "YEM", "ZMB" ){
										svyset su1 [pweight = learner_weight], fpc(fpc1) strata(strata1) || su2, fpc(fpc2) || su3, fpc(fpc3) strata(strata3) singleunit(scaled) vce(linearized)
										svy: mean `indicator'`sub'`trait'`lv' 
									}
									if inlist("`c'", "JOR" ){
										svyset su1 [pweight = learner_weight],  strata(strata1) || su2, fpc(fpc2) strata(strata2) || su3, fpc(fpc3) singleunit(scaled) vce(linearized)
										svy: mean `indicator'`sub'`trait'`lv' 
									}
									if inlist("`c'", "KEN", "NPL", "EGY", "NIC"){
										svyset su1 [pweight = learner_weight], strata(strata1) fpc(fpc1) || su2, strata(strata2) fpc(fpc2)  singleunit(scaled) vce(linearized)
										svy: mean `indicator'`sub'`trait'`lv' 
									}
									if inlist("`c'", "KGZ", "TJK"){
										svyset su1 [pweight = learner_weight], strata(strata1) vce(linearized)
										svy: mean `indicator'`sub'`trait'`lv' 
									}
									if inlist("`c'", "KIR"){
										svyset su1 [pweight = learner_weight], fpc(fpc1) singleunit(scaled) vce(linearized)
										svy: mean `indicator'`sub'`trait'`lv' 
									}
									if inlist("`c'", "MAR"){
										svyset su1 [pweight = learner_weight], fpc(fpc1) || su2, strata(strata2) fpc(fpc2) singleunit(scaled)  vce(linearized)
										svy: mean `indicator'`sub'`trait'`lv' 
									}
									if inlist("`c'", "RWA"){
										svyset [pweight = learner_weight]
										svy: mean `indicator'`sub'`trait'`lv' 
									}
									if inlist("`c'", "PAK"){
										svyset [pweight = learner_weight]
										svy: mean `indicator'`sub'`trait'`lv' 
									}
									if inlist("`c'", "SLB"){
										svyset su1 [pweight = learner_weight], strata(strata1) || su2 || su3
 										svy: mean `indicator'`sub'`trait'`lv' 
									}
									if inlist("`c'", "TLS"){
										svyset su1 [pweight = learner_weight] || su2 , strata(strata2) singleunit(scaled)
										svy: mean `indicator'`sub'`trait'`lv' 
									}
									if inlist("`c'", "UGA"){
										svyset su1 [pweight = learner_weight], fpc(fpc1) strata(strata1) || su2, fpc(fpc2)  || su3, fpc(fpc3) strata(strata3) singleunit(scaled) vce(linearized)
										svy: mean `indicator'`sub'`trait'`lv' 
									}
									if inlist("`c'", "BDI") & inlist("`y'", "2011"){
										svyset su1 [pweight= learner_weight], fpc(fpc1) strata(strata1) vce(linearized) 

										svy: mean `indicator'`sub'`trait'`lv' 
									}
									if inlist("`c'", "BDI") & inlist("`y'", "2012"){
										svyset [pweight= learner_weight]
										svy: mean `indicator'`sub'`trait'`lv'
									}
									if inlist("`c'", "COD") & inlist("`y'", "2010"){
										svyset [pweight= learner_weight]
										svy: mean `indicator'`sub'`trait'`lv' 

									}
									if inlist("`c'", "COD") & inlist("`y'", "2012"){
										svyset su1 [pweight= learner_weight], strata(strata1) fpc(fpc1) || su2, strata(strata2) fpc(fpc2) singleunit(scaled) vce(linearized)
										svy: mean `indicator'`sub'`trait'`lv' 

									}
									if inlist("`c'", "COD") & inlist("`y'", "2015"){
										svyset su1 [pweight= learner_weight], strata(strata1) fpc(fpc1) || su2, strata(strata2) fpc(fpc2) || su3, strata(strata3) fpc(fpc3) singleunit(scaled) vce(linearized)
										svy: mean `indicator'`sub'`trait'`lv'
									}
									if inlist("`c'", "ETH") & inlist("`y'", "2010"){
										svyset su1 [pweight= learner_weight], strata(strata1) fpc(fpc1) || su2, strata(strata2) fpc(fpc2) || su3, strata(strata3) fpc(fpc3) singleunit(scaled) vce(linearized)
										svy: mean `indicator'`sub'`trait'`lv' 
									}
									if inlist("`c'", "ETH") & inlist("`y'", "2018"){
										svyset su1 [pweight= learner_weight], strata(strata1) || su2, strata(strata2)  singleunit(scaled) 
										svy: mean `indicator'`sub'`trait'`lv'
									}
									if inlist("`c'", "GMB") & inlist("`y'", "2011"){
										svyset su1 [pweight = learner_weight], fpc(fpc1) strata(strata1)  || su2, fpc(fpc2) strata(strata2) singleunit(scaled) vce(linearized)
										svy: mean `indicator'`sub'`trait'`lv' 
									}
									if inlist("`c'", "HTI") & inlist("`y'", "2012"){
										svyset su1 [pw=learner_weight], strata(strata1) fpc(fpc1) ||su2, strata(strata2) fpc(fpc2) vce(linearized) singleunit(scaled)
										svy: mean `indicator'`sub'`trait'`lv' 
									}
									if inlist("`c'", "HTI") & inlist("`y'", "2013"){
										svyset su1 [pweight= learner_weight], strata(strata1) fpc(fpc1) || su2, strata(strata2) fpc(fpc2) || su3, strata(strata3) fpc(fpc3) singleunit(centered) vce(linearized)
										svy: mean `indicator'`sub'`trait'`lv' 
									}
									if inlist("`c'", "HTI") & inlist("`y'", "2015", "2016"){
										svyset [pweight = learner_weight]
										svy: mean `indicator'`sub'`trait'`lv'
									}
									if inlist("`c'", "MLI") & inlist("`y'", "2009"){
										svyset su1 [pweight = learner_weight], fpc(fpc1) || su2, fpc(fpc2) strata(strata2) || su3, fpc(fpc3) strata(strata3) singleunit(scaled) vce(linearized)
										svy: mean `indicator'`sub'`trait'`lv' 
									} 
									if inlist("`c'", "MLI") & inlist("`y'", "2015"){
										svyset su1 [pweight = learner_weight], fpc(fpc1) strata(strata1) || su2, fpc(fpc2) strata(strata2) singleunit(scaled) vce(linearized)
										svy: mean `indicator'`sub'`trait'`lv'
									} 
									if inlist("`c'", "MMR") & inlist("`y'", "2014"){
										svyset su1 [pweight = learner_weight], fpc(fpc1) strata(strata1) || su2, fpc(fpc2) singleunit(scaled) vce(linearized)
										svy: mean `indicator'`sub'`trait'`lv' 
									}
									if inlist("`c'", "MMR") & inlist("`y'", "2015"){
										svyset su1 [pweight = learner_weight],  strata(strata1) singleunit(scaled) vce(linearized)
										svy: mean `indicator'`sub'`trait'`lv'
									}
									if inlist("`c'", "NGA") & inlist("`y'", "2010"){
										svyset su1 [pw=learner_weight], fpc(fpc1) strata(strata1) || su2, fpc(fpc2) || su3, fpc(fpc3) strata(strata3) vce(linearized) singleunit(scaled)
										svy: mean `indicator'`sub'`trait'`lv' 
									}
									if inlist("`c'", "NGA") & inlist("`y'", "2014"){
										svyset su1 [pw=learner_weight], fpc(fpc1) strata(strata1) || su2, fpc(fpc2) strata(strata2) vce(linearized) singleunit(scaled)
										svy: mean `indicator'`sub'`trait'`lv'
									}
									if inlist("`c'", "PNG") & inlist("`y'", "2011"){
										svyset su1 [pweight = learner_weight], strata(strata1) || su2,  strata(strata2) singleunit(scaled) 
										svy: mean `indicator'`sub'`trait'`lv' 
									}
									if inlist("`c'", "PNG") & inlist("`y'", "2012","2013"){
										svyset [pweight = learner_weight]
										svy: mean `indicator'`sub'`trait'`lv'
									}
									display _rc
									if _rc == 0 {
									
										matrix pv_mean = e(b)
										matrix pv_var  = e(V)
										
										matrix list pv_var
										
										local  m_`indicator'`sub'`label'  = pv_mean[1,1]
										local  se_`indicator'`sub'`label' = sqrt(pv_var[1,1])
										local  n_`indicator'`sub'`label'  = e(N)
													
										file open myfile   using	 "$output\WLD_All_EGRA_v01_M_v01_A_MEAN.txt", write append			

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
		
insheet using "$output\WLD_All_EGRA_v01_M_v01_A_MEAN.txt", clear names
gen test = "EGRA"
*cf _all using "$output\WLD_All_EGRA_v01_M_v01_A_MEAN.dta", verbose
save "$output\WLD_All_EGRA_v01_M_v01_A_MEAN.dta", replace

use "$output\WLD_All_EGRA_v01_M_v01_A_MEAN.dta", replace
export excel using "$output\WLD_All_EGRA_v01_M_v01_A_MEAN", replace

