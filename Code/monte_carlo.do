clear all
set maxvar 32767
set matsize 11000
set more off, perm
set emptycells drop
global dir "~/Healthcare"
if "$S_OS" == "Windows" { 
	global dir "z:\Healthcare" 
}

log close _all
log using "$dir/tmp/mc_main_2_100_1000.log", append

* NE has 6 states with an average of 11 counties
* MA has 16 counties

* serial autocorrlation with one lag is 0.96 for se_pop and -0.34 for diff_se_pop
/* se_pop with 4 lagged variables
------------------------------------------------------------------------------
       resid |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
       resid |
         L1. |   .5058299   .0440747    11.48   0.000     .4192477    .5924121
         L2. |   .2009714   .0515696     3.90   0.000      .099666    .3022768
         L3. |     .24527   .0584769     4.19   0.000     .1303955    .3601444
         L4. |   .0075292   .0520105     0.14   0.885    -.0946424    .1097008

diff_se_pop with 3 lagged variables

------------------------------------------------------------------------------
       resid |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
       resid |
         L1. |  -.4190254   .0423302    -9.90   0.000    -.5021591   -.3358918
         L2. |  -.2022236   .0494301    -4.09   0.000    -.2993011   -.1051462
         L3. |      .0379   .0512482     0.74   0.460     -.062748     .138548
*/

* data generating process of 
* y_sct = alpha_s + gamma_c + delta_t + beta * treatment + error_st + error_sct
* with error_st = rho * error_s(t-1) + u_st and u_st ~ N(0,1)
* error_sct defined similarly

program define generateData

	local group_count = 6
	local individual_count = 11
	local year_count = 13

	if "`1'" != "" {
		local group_count = `1'
	}
	if "`2'" != "" {
		local individual_count = `2'
	}
	if "`3'" != "" {
		local year_count = `3'
	}
	
	clear
	set obs 1	

	gen group_count = `group_count'
	expand group_count
	gen group = _n
	drop group_count

	gen individual_count = `individual_count'
	expand individual_count
	bysort group: gen individual = _n
	drop individual_count

	gen year_count = `year_count'
	expand year_count
	bysort group individual: gen year = _n
	drop year_count

	gen treatment = (group == 1 & year > (`year_count' / 2))

	gen error = .
	levelsof group, local(groups)
	foreach group in `groups' {
		local res_matrix = 1 + floor(runiform() * state_count)
		replace error = RES`res_matrix'[1 + floor(runiform() * rowsof(RES`res_matrix')),1] if group == `group'
	}
	
	egen panel = group(group individual)
	tsset panel year
	su year
	local min_year = r(min)
	gen rho_tmp = RHO[1 + floor(runiform() * rowsof(RHO)),1] if year == `min_year'
	bysort panel: egen rho = mean(rho_tmp)
	drop rho_tmp
	levelsof year, local(years)
	foreach year in `years' {
		if (`year' == `min_year') {
			gen residual = error if year == `year'
		} 
		else {
			replace residual = rho * L.residual + (1-rho) * error if year == `year'
		}
	}
	drop if year == `min_year'

	su group
	local mean_group = r(mean)
	su panel
	local mean_panel = r(mean)
	su year
	local mean_year = r(mean)
	
	* not using state residual since my parameter process only outputs a single residual
	gen y = group - `mean_group' + panel - `mean_panel' + year - `mean_year' + residual	
	su y
	gen y_treated = y + r(sd) / 2 * treatment
	drop error residual rho
	
end

program define generateDataIndustry

	local group_count = 6
	local individual_count = 11
	local year_count = 13

	if "`1'" != "" {
		local group_count = `1'
	}
	if "`2'" != "" {
		local individual_count = `2'
	}
	if "`3'" != "" {
		local year_count = `3'
	}

	clear
	set obs 1
	
	gen group_count = `group_count'
	expand group_count
	gen group = _n
	drop group_count

	gen individual_count = `individual_count'
	expand individual_count
	bysort group: gen individual = _n
	drop individual_count

	gen year_count = `year_count'
	expand year_count
	bysort group individual: gen year = _n
	drop year_count

	gen treatment = (state == 1 & year > (`year_count' / 2))
	
	su industry
	local industry_cutoff = r(mean)
	gen treatment_ddd = (state == 1 & industry >= `industry_cutoff' & year > 2007)	
	
	gen error_ics = .
	levelsof state, local(states)
	foreach state in `states' {
		local res_matrix = 1 + floor(runiform() * 6)
		replace error_ics = RES`res_matrix'[1 + floor(runiform() * rowsof(RES`res_matrix')),1] if state == `state'
	}
	
	egen panel = group(state county industry)
	tsset panel year
	gen rho_tmp = RHO[1 + floor(runiform() * rowsof(RHO)),1] if year == 2008
	bysort panel: egen rho = mean(rho_tmp)
	drop rho_tmp
	gen residual = error_ics if year == 2000
	foreach year of numlist 2001/2012 {
		replace residual = rho * L.residual + error_ics if year == `year'
	}

	su state
	local mean_state = r(mean)
	su county
	local mean_county = r(mean)
	su industry
	local mean_industry = r(mean)
	su year
	local mean_year = r(mean)
	
	* not using state residual since my parameter process only outputs a single residual
	gen y = state - `mean_state' + county - `mean_county' + year - `mean_year' + industry - `mean_industry' +residual
	
	drop error_ics residual rho
	drop if year == 2000
	
	egen county_fe = group(state county)

end

program define generateDataDDD

	local state_count = 2
	local county_count = 14
	local industry_count 52
	local year_count = 13

	clear
	set obs 1

	gen state_count = `state_count'
	expand state_count
	gen state = _n
	drop state_count

	gen county_count = `county_count'
	expand county_count
	bysort state: gen county = _n
	drop county_count

	gen industry_count = `industry_count'
	expand industry_count
	bysort state county: gen industry = _n
	drop industry_count

	gen year_count = `year_count'
	expand year_count
	bysort state county industry: gen year = _n + 1999
	drop year_count

	su industry
	local industry_cutoff = r(mean)
	gen treatment = (state == 1 & industry >= `industry_cutoff' & year > 2007)
	
	* gen county_error = rnormal()
	gen county_error = RES[1 + floor(runiform() * rowsof(RES)),1]
	* bysort state year: gen state_error = rnormal() if _n == 1
	bysort state year: gen state_error = RES[1 + floor(runiform() * rowsof(RES)),1] if _n == 1	
	bysort state year: egen state_error_tmp = mean(state_error)
	drop state_error
	rename state_error_tmp state_error

	bysort industry year: gen industry_error = RES[1 + floor(runiform() * rowsof(RES)),1] if _n == 1	
	bysort industry year: egen industry_error_tmp = mean(industry_error)
	drop industry_error
	rename industry_error_tmp industry_error

	gen rho = .
	replace rho = RHO_TREAT[1 + floor(runiform() * rowsof(RHO_TREAT)),1] if state == 1
	replace rho = RHO_CONTROL[1 + floor(runiform() * rowsof(RHO_CONTROL)),1] if state != 1
	* replace rho = RHO[1 + floor(runiform() * rowsof(RHO)),1]
	
	egen panel = group(state county industry)
	tsset panel year
	gen county_residual = county_error if year == 2000
	gen state_residual = state_error if year == 2000
	gen industry_residual = industry_error if year == 2000
	foreach year of numlist 2001/2012 {
		replace county_residual = (1-rho) * county_error + rho * L.county_residual if year == `year'
		replace state_residual = (1-rho) * state_error + rho * L.state_residual if year == `year'
		replace industry_residual = (1-rho) * industry_error + rho * L.industry_residual if year == `year'
	}

	su state
	local mean_state = r(mean)
	su county
	local mean_county = r(mean)
	su industry
	local mean_industry = r(mean)
	su year
	local mean_year = r(mean)
	
	gen y = state - `mean_state' + county - `mean_county' + year - `mean_year' + industry - `mean_industry' + 0 * treatment + county_residual + state_residual + industry_residual
	drop *_error *_residual rho
	drop if year == 2000
	
	egen county_fe = group(state county)

end

program define ggn_boostrap, rclass

	preserve
	tempvar t dup expand_count individual_duplicates individual_bootstrap group_bootstrap n N
	
	local treatment_count 0
	local control_count 0
	while `treatment_count' == 0 | `control_count' == 0 {
		restore, preserve
		bsample, idcluster(`group_bootstrap') cluster(group)
		count if group == 1
		local treatment_count = r(N)
		count if group != 1
		local control_count = r(N)
	}	
	
	* now randomizing within each state
	replace group = `group_bootstrap'
	drop `group_bootstrap'
	gen `individual_duplicates' = .
	sort group year
	su year
	local min_year = r(min)
	by group year: gen `N' = _N if year == `min_year'
	by group year: gen `individual_bootstrap' = 1 + floor(runiform() * `N') if year == `min_year'
	levelsof individual, local(individuals)
	foreach individual in `individuals' {
		by group year: egen `t' = total(`individual_bootstrap' == `individual') if year == `min_year'
		by group year: replace `individual_duplicates' = `t' if individual == `individual' & year == `min_year'
		drop `t'
	}
	drop `individual_bootstrap' `N'
	
	bysort group individual: egen `expand_count' = mean(`individual_duplicates' + 1)
	expand `expand_count', generate(`dup')
	drop if `dup' == 0
	drop `dup' `individual_duplicates' `expand_count'	
	drop individual
	sort group year panel 
	by group year: gen individual = _n	
	drop panel
	egen panel = group(group individual)
	
	regress y_treat i.group i.panel i.year treatment
	return scalar treatment = _b[treatment]
	regress y i.group i.panel i.year treatment
	return scalar no_treatment = _b[treatment]
	
	restore
end

program define generateParameters

	scalar drop _all
	matrix drop _all
	use "$dir/tmp/Employment.dta", clear
	keep stcode cntycd year self_employed
	drop if year == 2013
	
	merge n:1 stcode cntycd year using "$dir/tmp/Population.dta"
	* ignoring counties in Virgina and Florida that don't show up here
	* https://www.census.gov/geo/reference/codes/cou.html
	count if _merge == 1 & stcode == 25
	assert(r(N)==0)
	keep if _merge == 3
	drop _merge					
	* for better readability dividing population by one million
	replace population = population / 1000000

	keep if inlist(stcode, 9, 23, 25, 33, 44, 50)
	scalar state_count = 6

	egen state = group(stcode)
	drop stcode
	
	egen panel =  group(state cntycd)
	tsset panel year
	
	sort panel year	
	gen se_pop = self_employed / population
	gen diff_se_pop = D.se_pop
	
	levelsof panel, local(panels)
	foreach panel in `panels' {
		regress diff_se_pop L.diff_se_pop if panel == `panel'
		local rho = _b[L.diff_se_pop]
		predict res if panel == `panel', rstand
		replace res = res / (1-`rho')
		mkmat res, nomissing
		drop res
		
		su state if panel == `panel'
		local state = r(mean)
		capture: matrix list RES`state'			
		if _rc == 111 {
			matrix RES`state' = res
		}
		else {
			matrix RES`state' = RES`state'\res
		}
		matrix drop res

		capture: matrix list RHO			
		if _rc == 111 {
			matrix RHO = (`rho')
		}
		else {
			matrix RHO = RHO\(`rho')			
		}
	}
	
	clear

end

program define generateParametersOld

	use "$dir/tmp/Employment.dta", clear
	keep stcode cntycd year self_employed
	drop if year == 2013
	
	merge n:1 stcode cntycd year using "$dir/tmp/Population.dta"
	* ignoring counties in Virgina and Florida that don't show up here
	* https://www.census.gov/geo/reference/codes/cou.html
	count if _merge == 1 & stcode == 25
	assert(r(N)==0)
	keep if _merge == 3
	drop _merge					
	* for better readability dividing population by one million
	replace population = population / 1000000
	
	egen panel =  group(stcode cntycd)
	tsset panel year
	
	sort panel year	
	gen se_pop = self_employed / population
	gen diff_se_pop = D.se_pop

	drop if year == 2000
	local base_year 2007
	gen treatment = stcode == 25 & year > `base_year'
	
	keep if inlist(stcode, 9, 23, 25, 33, 44, 50)
	scalar state_count 6
	
	bysort panel: egen rvals = count(panel)
	su rvals
	local col_count = r(mean)
	drop rvals
	bysort panel: gen nvals = _n == 1
	count if nvals & stcode == 25
	matrix RHO_TREAT = J(r(N),`col_count',0)
	count if nvals & stcode != 25
	matrix RHO_CONTROL = J(r(N),`col_count',0)
	count if nvals
	matrix RHO = J(r(N),`col_count',0)
	drop nvals
	
	levelsof panel, local(panels)
	local iTreat 1
	local iControl 1
	local i 1
	foreach panel in `panels' {
		quietly: {
			regress diff_se_pop L.diff_se_pop if panel == `panel'
			local rho = _b[L.diff_se_pop]
			predict res if panel == `panel', rstand
			mkmat res, nomissing
			* matrix list res
			drop res
			count if panel == `panel' & stcode == 25
			if(r(N) > 0) {
				matrix RHO_TREAT[`iTreat',1] = `rho'
				matrix RHO_TREAT[`iTreat',2] = res'
				local iTreat = `iTreat' + 1
			}
			else {
				matrix RHO_CONTROL[`iControl',1] = `rho'
				matrix RHO_CONTROL[`iControl',2] = res'
				local iControl = `iControl' + 1
			}
			matrix RHO[`i',1] = `rho'
			matrix RHO[`i',2] = res'
			local i = `i' + 1
		}
	}
	
	* prais diff_se_pop
	levelsof stcode, local(states)
	local i 1
	foreach state in `states' {
		regress diff_se_pop L.diff_se_pop if stcode == `state'
		predict res if stcode == `state', rstand 
		mkmat res, matrix(RES`i') nomissing
		local i = `i' + 1
		drop res
	}
	clear

end

program define generateParametersIndustry

	use $dir/tmp/nonemployedLong.dta, clear
	drop if naics >= 9900 & naics < 10000
	drop if naics >= 6200 & naics < 6240
	drop if naics >= 9500 & naics < 9600
	drop if year < 2000
	drop if year > 2012
	ren small ne_est
	keep ne_est stcode cntycd naics year	

	keep if inlist(stcode, 9, 23, 25, 33, 44, 50)
	
	merge n:1 stcode cntycd year using "$dir/tmp/Population.dta"
	* ignoring counties in Virgina and Florida that don't show up here
	* https://www.census.gov/geo/reference/codes/cou.html
	count if _merge == 1 & stcode == 25
	assert(r(N)==0)
	keep if _merge == 3
	drop _merge					
	* for better readability dividing population by one million
	replace population = population / 1000000
	
	egen panel =  group(stcode cntycd naics)
	tsset panel year
	
	sort panel year
	gen ne_pop = ne_est / population
	gen diff_ne_pop = D.ne_pop

	drop if year == 2000
	
	bysort panel: egen years = count(diff_ne_pop)
	bysort panel: gen nvals = _n == 1
	local min_years 5
	count if nvals & years >= `min_years'
	matrix RHO = J(r(N),1,0)
	drop nvals
	
	levelsof panel if years >= `min_years', local(panels)
	local i 1
	foreach panel in `panels' {
		quietly: {
			regress diff_ne_pop L.diff_ne_pop if panel == `panel'
			local rho = _b[L.diff_ne_pop]
			matrix RHO[`i',1] = `rho'
			local i = `i' + 1
		}
	}
	
	levelsof stcode, local(states)
	local i 1
	foreach state in `states' {
		sort panel year
		regress diff_ne_pop L.diff_ne_pop if stcode == `state'
		predict res if stcode == `state', rstand 
		sort res
		replace res = . if _n > 11000
		mkmat res, matrix(RES`i') nomissing
		local i = `i' + 1
		drop res
	}
	clear

end


program define generateParametersDDD


	use $dir/tmp/nonemployed.dta, clear
	drop if naics == 62
	drop if year < 2000

	merge n:1 stcode cntycd year using "$dir/tmp/Population.dta"
	* ignoring counties in Virgina and Florida that don't show up here
	* https://www.census.gov/geo/reference/codes/cou.html
	count if _merge == 1 & stcode == 25
	assert(r(N)==0)
	keep if _merge == 3
	drop _merge					
	* for better readability dividing population by one million
	replace population = population / 1000000
	
	tsset panel year
	
	sort panel year	
	gen ne_pop = small / population
	gen diff_ne_pop = D.ne_pop

	drop if year == 2000
	local base_year 2007
	gen treatment = stcode == 25 & year > `base_year'
	
	keep if inlist(stcode, 9, 23, 25, 33, 44, 50)
	
	regress diff_ne_pop L.diff_ne_pop
	
	bysort panel: gen nvals = _n == 1
	count if nvals & stcode == 25
	matrix RHO_TREAT = J(r(N),1,0)
	count if nvals & stcode != 25
	matrix RHO_CONTROL = J(r(N),1,0)
	count if nvals
	matrix RHO = J(r(N),1,0)
	drop nvals
	
	levelsof panel, local(panels)
	local iTreat 1
	local iControl 1
	local i 1
	foreach panel in `panels' {
		quietly capture: {
			regress diff_ne_pop L.diff_ne_pop if panel == `panel'
			count if panel == `panel' & stcode == 25
			if(r(N) > 0) {
				matrix RHO_TREAT[`iTreat',1] = _b[L.diff_ne_pop]
				local iTreat = `iTreat' + 1
			}
			else {
				matrix RHO_CONTROL[`iControl',1] = _b[L.diff_ne_pop]
				local iControl = `iControl' + 1
			}
			matrix RHO[`i', 1] = _b[L.diff_ne_pop]
			local i = `i' + 1
		}
	}
	
	regress diff_ne_pop L.diff_ne_pop
	predict res, rstand
	sort res
	replace res = . if _n > 11000
	mkmat res, matrix(RES) nomissing
	clear

end

program define runSimulation

	generateParameters
	local number_trials 100
	if ("`1'" != "") {
		local number_trials = `1'
	}

	tempname sim

	postfile `sim' OLS robust cluster ar newey bootstrap OLS_t robust_t cluster_t ar_t newey_t bootstrap_t using $dir/tmp/mc_output, replace 
	forvalues i = 1/`number_trials' {
		* quietly {
			generateData 2 100 13
			* generateData 5 10 13

			xtreg y treatment i.year, fe
			test treatment
			scalar OLS = (r(p) < 0.05)
			xtreg y_treat treatment i.year, fe
			test treatment
			scalar OLS_t = (r(p) < 0.05)
		
			xtreg y treatment i.year, fe robust
			test treatment
			scalar robust = (r(p) < 0.05)
			xtreg y_treat treatment i.year, fe robust
			test treatment
			scalar robust_t = (r(p) < 0.05)

			xtreg y treatment i.year, fe cluster(group)
			test treatment
			scalar cluster = (r(p) < 0.05)
			xtreg y_treat treatment i.year, fe cluster(group)
			test treatment
			scalar cluster_t = (r(p) < 0.05)
			
			xi: xtregar y treatment i.year, fe
			test treatment
			scalar ar = (r(p) < 0.05)
			xi: xtregar y_treat treatment i.year, fe
			test treatment
			scalar ar_t = (r(p) < 0.05)
			
			
			xi: newey2 y i.group i.panel i.year treatment, lag(3)
			test treatment
			scalar newey = (r(p) < 0.05)
			xi: newey2 y_treat i.group i.panel i.year treatment, lag(3)
			test treatment
			scalar newey_t = (r(p) < 0.05)
			
			regress y i.group i.panel i.year treatment
			scalar observed = _b[treatment]
			local N = e(N)
			regress y_treat i.group i.panel i.year treatment
			scalar observed_t = _b[treatment]
			simulate beta=r(no_treatment) beta_t=r(treatment), reps(100): ggn_boostrap
			bstat, stat([observed, observed_t]) n(`N')
			test beta
			scalar bootstrap = (r(p) < 0.05)
			test beta_t
			scalar bootstrap_t = (r(p) < 0.05)			
			
			post `sim' (OLS) (robust) (cluster) (ar) (newey) (bootstrap) (OLS_t) (robust_t) (cluster_t) (ar_t) (newey_t) (bootstrap_t)
		* }
	}

	postclose `sim'
	use $dir/tmp/mc_output, clear
	summarize

end

program define runSimulationIndustry

	generateParametersIndustry
	local number_trials 100
	if ("`1'" != "") {
		local number_trials = `1'
	}

	tempname sim

	postfile `sim' OLS robust cluster ar newey bootstrap using $dir/tmp/mc_outputI, replace 
	forvalues i = 1/`number_trials' {
		* quietly {
			* MA has 14 counties and 112 4 digit naics on average
			generateData 2 14 112 13
			xtreg y treatment ib2007.year, fe
			test treatment
			scalar OLS = (r(p) < 0.05)
			xtreg y treatment ib2007.year, fe robust
			test treatment
			scalar robust = (r(p) < 0.05)
			xtreg y treatment ib2007.year, fe cluster(state)
			test treatment
			scalar cluster = (r(p) < 0.05)
			xi: xtregar y treatment i.year, fe
			test treatment
			scalar ar = (r(p) < 0.05)
			xi: newey2 y i.state i.county_fe i.industry i.year treatment, lag(3)
			test treatment
			scalar newey = (r(p) < 0.05)
			regress y i.state i.county_fe i.industry ib2007.year treatment
			scalar observed = _b[treatment]
			local N = e(N)
			simulate beta=r(beta), reps(100): ggn_boostrap
			bstat, stat(observed) n(`N')
			test beta
			scalar bootstrap = (r(p) < 0.05)
			post `sim' (OLS) (robust) (cluster) (ar) (newey) (bootstrap)
		* }
	}

	postclose `sim'
	use $dir/tmp/mc_outputI, clear
	summarize

end

program define WaitForFile

	local filename `1'

	//wait for file
	display "Waiting for `filename'" _continue
	capture: confirm file "`filename'"
	while _rc {
		//if _rc != 601 display _rc _continue
		display "." _continue
		sleep 1000
		capture: confirm file "`filename'"
	}
	
	tempname filehandle
/*	capture: file open `filehandle' using "`filename'", read write binary

	//we should know the file has been fully written if we can get write access
	//but this doesn't seem to work
	while _rc {
		display _rc _continue
		display "," _continue
		sleep 1000
		capture: file open `filehandle' using "`filename'", read write binary
	}
	
	file close `filehandle'	
*/
	file open `filehandle' using "`filename'", read binary
	//check if written; should really have EOF marker
	file seek `filehandle' eof 
	while r(loc) == 0 {
		display "*" _continue
		sleep 1000
		file seek `filehandle' eof 
	}	
	file close `filehandle'	
	
	display "DONE"

end

program define runSimulationDDD

	generateParametersDDD
	local number_trials 100
	!rm $dir/tmp/mc_*

	tempname sim

	forvalues i = 1/`number_trials' {
		generateDataDDD
		save $dir/tmp/mc_`i', replace
		! qsub -N mc_`i' -b yes -j yes -wd $dir/tmp stata -b "$dir/Code/monte_carlo_map.do" `i'
	}

	/*	
	forvalues i = 1/`number_trials'{
		WaitForFile "$dir/tmp/mc_results`i'.don"
		capture noisily: append using "$dir/tmp/mc_results`i'.dta"
	}
	summarize
	*/

end

program define generateTestData

	clear
	set obs 500
	* y = state fixed effect + error ~ N(0,1)
	gen error = rnormal()
	gen state = mod(_n, 10)
	su state
	local state_mean = r(mean)
	gen y = state - `state_mean' + error
	gen treatment = state > `state_mean'

end

program define runTest

	local number_trials 1000
	tempname sim

	postfile `sim' OLS robust using $dir/tmp/mc_output, replace 
	forvalues i = 1/`number_trials' {
		quietly {
			generateTestData
			regress y state treatment
			test treatment
			scalar OLS = (r(p) < 0.05)
			regress y state treatment, robust
			test treatment
			scalar robust = (r(p) < 0.05)
			post `sim' (OLS) (robust)
		}
	}

	postclose `sim'
	use $dir/tmp/mc_output, clear
	summarize

end

runSimulation 1000
