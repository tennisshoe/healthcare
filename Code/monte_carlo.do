clear all

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

input byte dataset
0
end

program define generateData

	keep if _n == 1
	gen dummy = 0
	keep dummy

	local state_count = 6
	gen state_count = `state_count'
	expand state_count
	gen state = _n
	drop state_count

	local county_count = 11
	gen county_count = `county_count'
	expand county_count
	bysort state: gen county = _n
	drop county_count

	local year_count = 13
	gen year_count = `year_count'
	expand year_count
	bysort state county: gen year = _n + 1999
	drop year_count

	gen treatment = (state == 1 & year > 2007)

	gen county_error = rnormal()
	bysort state year: gen state_error = rnormal() if _n == 1
	bysort state year: egen state_error_tmp = mean(state_error)
	drop state_error
	rename state_error_tmp state_error

	egen panel = group(state county)
	tsset panel year
	local rho 0.95
	gen county_residual = county_error if year == 2000
	gen state_residual = state_error if year == 2000
	foreach year of numlist 2001/2012 {
		replace county_residual = (1-`rho') * county_error + `rho' * L.county_residual if year == `year'
		replace state_residual = (1-`rho') * state_error + `rho' * L.state_residual if year == `year'
	}

	gen y = state + county + year + 0 * treatment + county_residual + state_residual
	drop dummy

end

local number_trials 100

tempname sim

timer on 1

postfile `sim' OLS robust cluster using results, replace 
forvalues i = 1/`number_trials' {
	quietly {
		generateData
		xtreg y treatment ib2007.year, fe
		test treatment
		scalar OLS = (r(p) < 0.05)
		xtreg y treatment ib2007.year, fe robust
		test treatment
		scalar robust = (r(p) < 0.05)
		xtreg y treatment ib2007.year, fe cluster(state)
		test treatment
		scalar cluster = (r(p) < 0.05)
		post `sim' (OLS) (robust) (cluster)
	}
}

postclose `sim'
use results, clear
summarize

timer off 1

timer list


