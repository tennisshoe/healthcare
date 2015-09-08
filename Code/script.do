clear all
set maxvar 32767
set matsize 11000
set more off, perm
global dir "~/Healthcare"
log using $dir/tmp/script.log, replace
set emptycells drop

program define GraphPoint
	args y_variable base title filename

	tempvar temp_year temp_beta temp_lower temp_upper

	gen int `temp_year' = .
	gen float `temp_beta' = .
	gen float `temp_lower' = .
	gen float `temp_upper' = .

	* first pull data out of return matrix 
	local i 1
	local z 1.96
	levelsof year, local(years)
	foreach year in `years' {
		* need to generalize this
		if `year' == 2000 {
			continue
		}
		replace `temp_year' = `year' if _n == `i'
		if (`year' == `base') {
			replace `temp_beta' = 0 if _n == `i'
			replace `temp_lower' = 0 if _n == `i'
			replace `temp_upper' = 0 if _n == `i'		
		} 
		else {
			replace `temp_beta' = _b[`y_variable'`year'] if _n == `i'
			replace `temp_lower' = `temp_beta' - `z'*_se[`y_variable'`year'] if _n == `i'
			replace `temp_upper' = `temp_beta' + `z'*_se[`y_variable'`year'] if _n == `i'
		}
		local i = `i' + 1	
	}

	local line = `base' + 0.5	
	
	graph twoway ///
		(rarea `temp_upper' `temp_lower' `temp_year', color(gs12) fintensity(inten50) xline(`line', lcolor(black))) ///
		(line `temp_beta' `temp_year', lcolor(midblue) lpattern(dash)) ///
		(scatter `temp_beta' `temp_year', mcolor(midblue)) ///
		, title(`title') ytitle(Residual rate of new firms) yscale(titlegap(3)) ylabel(, labsize(small)) xtitle(Year) xlabel(2001 2004 2008 2012, labsize(small)) legend(order(1 3) label(3 "Treatment X Year Estimate") label(1 "Confidence Interval") cols(1) size(small)) graphregion(fcolor(dimgray))		
	! rm $dir/tmp/graphpoint`filename'.*
	graph2tex, epsfile("$dir/tmp/graphpoint`filename'")	
		
	drop `temp_year' `temp_beta' `temp_lower' `temp_upper'

end

	local MA 25
			
	foreach y_variable in diff_ne_pop diff_em_pop { // 
	
		eststo clear
		use $dir/tmp/synth_`y_variable'.dta, clear

		local capitalFile "$dir/tmp/capital.dta"
		local description "Establishments with one to four employees"
		if "`y_variable'" == "diff_ne_pop" {
			local capitalFile "$dir/tmp/capitalNonemployer.dta"
			local description "Establishments with no employees"
		}

		su panel
		local max_panel = r(max)
	
		levelsof naics if stcode == `MA' & !missing(`y_variable'), local(industries)
		foreach industry of local industries {

			gen e = 2 if stcode == `MA' & naics == `industry'
			expand e, gen(d)
			drop e
			replace panel = panel + `max_panel' + 1 if d == 1
			replace `y_variable' = . if d == 1
			replace stcode = 0 if d == 1
						
			gen _Co_Number = panel
			
			levelsof cntycd if stcode == `MA' & naics == `industry' & !missing(`y_variable'), local(counties)
			foreach county of local counties {
			
				local filename "$dir/tmp/synth_`county'_`industry'_`y_variable'.dta"
				capture: confirm file `filename'
				if _rc {
					display "Dropping County:`county' Industry:`industry'"
					replace `y_variable' = . if stcode == `MA' & cntycd == `county' & naics == `industry'					
				} 
				else {
					display "Merging County:`county' Industry:`industry'"
					merge n:1 _Co_Number using `filename', assert(1 3)
					drop _Y_treated _Y_synthetic _time _merge
					gen w_diff = _W_Weight * `y_variable'
					bysort year: egen c_diff = total(w_diff)
					replace `y_variable' = c_diff if d == 1 & stcode == 0 & cntycd == `county' & naics == `industry'
					drop w_diff c_diff _W_Weight
				}
			}
			
			drop _Co_Number			
			drop d		
		}
		
		keep if inlist(stcode, 0, 25)
		drop if year == 2000

		gen naics_4 = naics
		replace naics = floor(naics/100)
		replace naics = 31 if inlist(naics, 32, 33)
		replace naics = 44 if inlist(naics, 45)
		replace naics = 48 if inlist(naics, 49)		
		merge n:1 naics using `capitalFile'
		keep if _merge == 3
		drop _merge
		drop naics
		ren naics_4 naics

		su percent_no_funding
		gen low_capital = (percent_no_funding >= ((r(min) + r(max)) / 2))
		gen treatment_dd = (year >= 2008) & (low_capital == 1)
		gen treatment_ddd = treatment_dd & (stcode == 25)
		set emptycells drop
		egen county = group(stcode cntycd)

		* leaving out non-time varying fixed effects since they get dropped
		* anyway but slow regression down dramatically
		eststo C_DD: xtreg `y_variable' treatment_dd ib2007.year i.naics i.county if stcode == 25, fe robust	
		eststo C_DDD: xtreg `y_variable' treatment_ddd i.naics#ib2007.year i.county#ib2007.year i.naics#i.county, fe robust	

		levelsof year, local(years)	
		foreach year of local years {
			if `year' == 2007 | `year' == 2000 continue
			gen iTYear`year' = (year == `year') & (stcode == 25) & (low_capital == 1)
		}
		xtreg `y_variable' iTYear* i.naics#ib2007.year i.county#ib2007.year, fe robust
		GraphPoint iTYear 2007 "`description'" "_`y_variable'_ddd_synth"
		drop iTYear*

		gen single_treat_dd = (year >= 2008) & (year <= 2010) & (low_capital == 1)
		gen post_treat_dd = (year > 2010) & (low_capital == 1)
		gen single_treat_ddd = single_treat & stcode == 25
		gen post_treat_ddd = post_treat & stcode == 25
		eststo A_DD: xtreg `y_variable' single_treat_dd post_treat_dd ib2007.year i.county if stcode == 25, fe robust
		test single_treat_dd=post_treat_dd
		estadd scalar r(p)			
		eststo A_DDD: xtreg `y_variable'  single_treat_ddd post_treat_ddd i.naics#ib2007.year i.county#ib2007.year i.naics#i.county, fe robust
		test single_treat_ddd=post_treat_ddd
		estadd scalar r(p)
		
		save $dir/tmp/tmp_`y_variable'.dta, replace all

		esttab _all using $dir/tmp/main_`y_variable'.tex, ///
			varwidth(0) mtitles("(4)" "(5)" "(6)" "(7)")   ///
			varlabels(treatment_dd "Low Capital $\times$ Post 2007" ///
				treatment_ddd "Mass $\times$ Low Capital $\times$ Post 2007" ///
				single_treat_dd "Low Capital $\times$ 2008" ///
				post_treat_dd "Low Capital $\times$ Post 2008" ///
				single_treat_ddd "Mass $\times$ Low Capital $\times$ 2008" ///
				post_treat_ddd "Mass $\times$ Low Capital $\times$ Post 2008") ///
			keep(treatment_dd treatment_ddd single_treat_dd post_treat_dd single_treat_ddd post_treat_ddd)  ///
			nonumbers replace compress se r2 scalar("F F-test" "N_g Groups" "p Short=Long") sfmt(%9.3f %9.0f) b(3) starlevels(* 0.10 ** 0.05 *** 0.01 **** 0.001) ///
			addnotes("Fixed effect model on `description'.") 
			
	}	
