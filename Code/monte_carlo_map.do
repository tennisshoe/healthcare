local i = `1'
set maxvar 32767
set matsize 11000
set more off, perm
set emptycells drop
global dir "~/Healthcare"
if "$S_OS" == "Windows" { 
	global dir "z:\Healthcare" 
}

program define custom_bootstrap, rclass

	preserve
	bsample, strata(state)
	regress y treatment i.county_fe#industry i.year#county_fe i.year#industry
	return scalar beta = _b[treatment]	
	restore

end

log close _all
log using "$dir/tmp/mc_map_`i'.log", append

use $dir/tmp/mc_`i'

tempname sim
postfile `sim' OLS robust newey bootstrap using $dir/tmp/mc_results`i', replace 

xtreg y treatment i.year#county_fe i.year#industry, fe
test treatment
scalar OLS = (r(p) < 0.05)
xtreg y treatment i.year#county_fe i.year#industry, fe robust
test treatment
scalar robust = (r(p) < 0.05)
* xtreg y treatment i.year#county_fe i.year#industry, fe cluster(state)
* test treatment
* scalar cluster = (r(p) < 0.05)
egen i_CI = group(county_fe industry)
egen i_YC = group(year county_fe)
egen i_YI = group(year industry)
* xtregar y treatment i.i_YC i.i_YI, fe
* test treatment
* scalar ar = (r(p) < 0.05)
xi: newey2 y treatment i.i_CI i.i_YC i.i_YI, lag(3)
test treatment
scalar newey = (r(p) < 0.05)
drop i_*
regress y treatment i.county_fe#industry i.year#county_fe i.year#industry
scalar observed = _b[treatment]
local N = e(N)
simulate beta=r(beta), reps(100): custom_bootstrap
bstat, stat(observed) n(`N')
test beta
scalar bootstrap = (r(p) < 0.05)
post `sim' (OLS) (robust) (newey) (bootstrap)

postclose `sim'

tempname filehandle
file open `filehandle' using "$dir/tmp/mc_`i'.don", write binary
file write `filehandle' %8z (0)
file close `filehandle'
