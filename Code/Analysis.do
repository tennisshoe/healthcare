clear all
* need to incrase this for the synth function but perhaps not all the way to the max
set maxvar 32767
set matsize 11000
set more off, perm
set emptycells drop
global dir "~/Healthcare"
if "$S_OS" == "Windows" { 
	global dir "z:\Healthcare" 
}

program define BuildNewEnglandData

	use "$dir/Data/infogroup_merged.dta", clear
	local NEW_ENGLAND state == "MA" | state == "ME" | state == "NH" | state == "VT" | state == "RI" | state == "CT"
	keep if `NEW_ENGLAND'
	drop if year < 2000
	
	merge n:1 stcode cntycd year using "$dir/tmp/MedianIncome.dta"
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge
	
	merge n:1 stcode cntycd year using "$dir/tmp/Population.dta"
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge
	
	save "$dir/tmp/NewEngland.dta", replace

end

program define GraphFull
	args y_variable cutoff treatment_variable treatment_value title
	
	graph twoway (scatter `y_variable' year if `treatment_variable' == "`treatment_value'", mcolor(blue) xline(`cutoff', lcolor(black))) ///
		(lpoly `y_variable' year if year < `cutoff' & `treatment_variable' == "`treatment_value'", lcolor(blue) degree(1)) ///
		(lpoly `y_variable' year if year >= `cutoff' & `treatment_variable' == "`treatment_value'", lcolor(blue) degree(1)) ///
		(scatter `y_variable' year if `treatment_variable' != "`treatment_value'", mcolor(red)) ///
		(lpoly `y_variable' year if year < `cutoff' & `treatment_variable' != "`treatment_value'", lcolor(red) degree(1)) ////
		(lpoly `y_variable' year if year >= `cutoff' & `treatment_variable' != "`treatment_value'", lcolor(red) degree(1)) ///
		, legend(off) subtitle("`title'")
				
end

program define GraphWeighted
	args y_variable cutoff treatment_variable treatment_value weights title

	tempvar mean treated
	gen `treated' = `treatment_variable' == "`treatment_value'"
	bysort year `treated': egen `mean' = wtmean(`y_variable'), weight(`weights')
	
	graph twoway (scatter `mean' year if `treatment_variable' == "`treatment_value'", mcolor(blue) xline(`cutoff', lcolor(black))) ///
		(lpoly `y_variable' year if year < `cutoff' & `treatment_variable' == "`treatment_value'" [aweight=`weights'], lcolor(blue) degree(1)) ///
		(lpoly `y_variable' year if year >= `cutoff' & `treatment_variable' == "`treatment_value'" [aweight=`weights'], lcolor(blue) degree(1)) ///
		(scatter `mean' year if `treatment_variable' != "`treatment_value'", mcolor(red)) ///
		(lpoly `y_variable' year if year < `cutoff' & `treatment_variable' != "`treatment_value'" [aweight=`weights'], lcolor(red) degree(1)) ////
		(lpoly `y_variable' year if year >= `cutoff' & `treatment_variable' != "`treatment_value'" [aweight=`weights'], lcolor(red) degree(1)) ///
		, legend(off) subtitle("`title'")
		
	drop `mean' `treated'
end

program define GraphPaper
	args y_variable cutoff treatment_variable treatment_value title 


	local line = `cutoff' - 0.5

	graph twoway (scatter `y_variable' year if `treatment_variable' == `treatment_value', msymbol(X) mcolor(midblue) xline(`line', lcolor(black))) ///
		(scatter `y_variable' year if `treatment_variable' != `treatment_value', msymbol(+) mcolor(red) xline(`line', lcolor(black))) ///
		(lpoly `y_variable' year if year < `cutoff' & `treatment_variable' == `treatment_value', lcolor(midblue) degree(1)) ///
		(lpoly `y_variable' year if year >= `cutoff' & `treatment_variable' == `treatment_value', lcolor(midblue) degree(1)) ///
		(lpoly `y_variable' year if year < `cutoff' & `treatment_variable' != `treatment_value', lcolor(red) degree(1)) ///
		(lpoly `y_variable' year if year >= `cutoff' & `treatment_variable' != `treatment_value', lcolor(red) degree(1)) ///
		, title(`title') ytitle(Rate of net new firms) yscale(titlegap(3)) ylabel(, labsize(small)) xtitle(Year) xlabel(2001 2004 2008 2012, labsize(small)) legend(order(1 2) label(1 "MA Counties") label(2 "Control Counties") cols(1) size(small)) graphregion(fcolor(dimgray))
	graph2tex, epsfile("$dir/tmp/residuals`title'")	

	exit

	* tostring `treatment_variable', replace	
	
	tempvar treat treat_mean control control_mean blue_mean
	gen `treat' = `y_variable' if `treatment_variable' == `treatment_value'
	gen `control' = `y_variable' if `treatment_variable' != `treatment_value'
	sort year
	by year: egen `treat_mean' = mean(`treat')
	by year: egen `control_mean' = mean(`control')
	by year: gen `blue_mean' = `treat_mean' - `control_mean'	
	
	graph twoway (scatter `blue_mean' year if `treatment_variable' == `treatment_value', mcolor(midblue) xline(`cutoff', lcolor(black))) ///
		(lpoly `blue_mean' year if year < `cutoff' & `treatment_variable' == `treatment_value', lcolor(midblue) degree(1)) ///
		(lpoly `blue_mean' year if year >= `cutoff' & `treatment_variable' == `treatment_value', lcolor(midblue) degree(1)) ///
		, title(`title') ytitle(Residual rate of new firms) yscale(titlegap(3)) ylabel(, labsize(small)) xtitle(Year) xlabel(2001 2004 2008 2012, labsize(small)) legend(order(1 4) label(1 "Treated-Control") cols(1) size(small)) graphregion(fcolor(dimgray))
	graph2tex, epsfile("$dir/tmp/residuals`title'")	
		
	drop `blue_mean' `control_mean' `treat_mean' `treat' `control'

	/* 
		tempvar blue_mean red_mean
	sort year
	by year: egen `blue_mean' = mean(`y_variable') if `treatment_variable' == `treatment_value'
	by year: egen `red_mean' = mean(`y_variable') if `treatment_variable' != `treatment_value'
	
	graph twoway (scatter `blue_mean' year if `treatment_variable' == `treatment_value', mcolor(midblue) xline(`cutoff', lcolor(black))) ///
		(lpoly `y_variable' year if year < `cutoff' & `treatment_variable' == `treatment_value', lcolor(midblue) degree(1)) ///
		(lpoly `y_variable' year if year >= `cutoff' & `treatment_variable' == `treatment_value', lcolor(midblue) degree(1)) ///
		(scatter `red_mean' year if `treatment_variable' != `treatment_value', mcolor(cranberry)) ///
		(lpoly `y_variable' year if year < `cutoff' & `treatment_variable' != `treatment_value', lcolor(cranberry) degree(1)) ////
		(lpoly `y_variable' year if year >= `cutoff' & `treatment_variable' != `treatment_value', lcolor(cranberry) degree(1)) ///
		, title(`title') ytitle(Residual rate of new firms) yscale(titlegap(3)) ylabel(, labsize(small)) xtitle(Year) xlabel(2001 2004 2008 2012, labsize(small)) legend(order(1 4) label(1 "Treated") label(4 "Control") cols(1) size(small)) graphregion(fcolor(dimgray))
	graph2tex, epsfile("$dir/tmp/residuals`title'")	
		
	drop `blue_mean' `red_mean'
	*/

	* capture: destring `treatment_variable', replace
		
end


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

program define IntensityTest

	use "$dir/tmp/NewEngland.dta"
	merge n:1 naics_4 using "$dir/tmp/Intensity.dta"
	drop if _merge == 1
	drop if _merge == 2
	drop _merge

	keep if state == "MA"
	gen new_item = 2
	expand new_item, generate(expand_flag)
	drop new_item
	replace state = "ZZ" if expand_flag
	drop if expand_flag & cap_intensity <= 50
	drop if !expand_flag & cap_intensity > 50
	drop expand_flag
	
	bysort state year: egen new_firms = count(year)	
	bysort state year cntycd: keep if _n == 1
	bysort state year: egen state_pop = total(population)
	bysort state year: keep if _n == 1

	gen rate = new_firms / state_pop
	replace rate = -rate if state != "MA" 
	bysort year: egen diff = total(rate)
	replace rate = -rate if state != "MA" 
	
	GraphGeneric diff 2007 state "MA"

end

program define EmploymentTest

	use "$dir/tmp/Employment.dta"
	keep if stcode == 9 | stcode == 23 | stcode == 25 | stcode == 33 | stcode == 44 | stcode == 50

	keep if population > 500000

	* not 100% correct; missing for example county 19 population for MA in 2005
	replace stcode = 0 if stcode != 25
	bysort stcode year: egen state_se = total(self_employed)	
	bysort stcode year: egen state_pop = total(population)
	bysort stcode year: keep if _n == 1

	* replace stcode = 0 if stcode != 25
	* bysort stcode year: egen region_pop = total(state_pop)
	* bysort stcode year: egen region_se = total(state_se)
	* bysort stcode year: keep if _n == 1
	* drop state_pop state_se
	* rename region_pop state_pop
	* rename region_se state_se	

	gen rate = state_se / state_pop
	replace rate = -rate if stcode != 25 
	bysort year: egen diff = total(rate)
	replace rate = -rate if stcode != 25 
	
	tostring stcode, replace
	
	GraphGeneric rate 2007 stcode "25"
end

/*

http://www.bls.gov/opub/mlr/2005/07/art6full.pdf

*/

program define TagHighTech

	local hightech naics_4 == 3254 | naics_4 == 3341 | naics_4 == 3342 | naics_4 == 3344 |naics_4 == 3345 |naics_4 == 3364 |naics_4 == 5112 |naics_4 == 5161 |naics_4 == 5179 |naics_4 == 5181 |naics_4 == 5182|naics_4 == 5413|naics_4 == 5415|naics_4 == 5417
	gen hightech = 0
	replace hightech = 1 if `hightech'

end

program define SummaryStats_intraMA

	* need to think about how to handle counties with no new firms that year
	use "$dir/tmp/NewEngland.dta", clear
	
	keep if state == "MA"
	gen new_item = 2
	expand new_item, generate(expand_flag)
	drop new_item
	replace state = "ZZ" if expand_flag
	drop if expand_flag & !nonprofit
	drop if !expand_flag & nonprofit
	drop expand_flag
	
	bysort state year: egen new_firms = count(year)	
	bysort state year cntycd: keep if _n == 1
	bysort state year: egen state_pop = total(population)
	bysort state year: keep if _n == 1

	gen rate = new_firms / state_pop
	replace rate = -rate if state != "MA" 
	bysort year: egen diff = total(rate)
	replace rate = -rate if state != "MA" 
	
	GraphGeneric diff 2007 state "MA"

end


program define SummaryStats

	* need to think about how to handle counties with no new firms that year
	use "$dir/tmp/NewEngland.dta", clear
	
	//TagHighTech
	//keep if hightech
		
	bysort state year: egen new_firms = count(year)	
	bysort state year cntycd: keep if _n == 1
	bysort state year: egen state_pop = total(population)
	bysort state year: keep if _n == 1

	replace state = "ZZ" if state != "MA"
	bysort state year: egen region_pop = total(state_pop)
	bysort state year: egen region_firms = total(new_firms)
	bysort state year: keep if _n == 1
	drop state_pop new_firms
	rename region_pop state_pop
	rename region_firms new_firms	

	gen rate = new_firms / state_pop
	replace rate = -rate if state != "MA" 
	bysort year: egen diff = total(rate)
	replace rate = -rate if state != "MA" 

	GraphGeneric rate 2007 state "MA"
end

program define SummaryStats_NaicsLoop_4

        use $dir/tmp/fullPanel.dta
	
        drop if cntycd == 999
        drop if cntycd == 0

        merge n:1 stcode cntycd year using "$dir/tmp/Population.dta"
        count if _merge == 1
        assert(r(N)==0)
        drop if _merge == 2
        drop _merge                                     
        replace population = population / 1000000

	sort panel year 
        gen small_pop = small / population
        gen diff_small_pop = D.small_pop
	
	levelsof naics, local(naics_codes)
	foreach naics_code in `naics_codes' { 

		preserve 
		
		keep if naics == `naics_code'
		count
		if r(N) < 10 {
			restore
			continue
		}
		
		set graphics off
		GraphPaper diff_small_pop 2008 stcode 25 `naics_code'
		set graphics on

		restore
	}

	ReportResults naics
end

program define ReportResults
	args naics_variable


	tempname texhandle
	file open `texhandle' using "$dir/tmp/results.tex", write text replace
	file write `texhandle' ("\documentclass{article}") _n
	file write `texhandle' ("\usepackage{rotating}") _n
	file write `texhandle' ("\usepackage{graphicx}") _n
	file write `texhandle' ("\usepackage{epstopdf}") _n
	file write `texhandle' ("\addtolength{\textwidth}{4cm}") _n
	file write `texhandle' ("\addtolength{\hoffset}{-2cm}") _n
	file write `texhandle' ("\addtolength{\textheight}{3cm}") _n
	file write `texhandle' ("\addtolength{\voffset}{-1.5cm}") _n
	file write `texhandle' ("\begin{document}") _n
	file write `texhandle' ("\setlength{\pdfpagewidth}{8.5in}") _n
	file write `texhandle' ("\setlength{\pdfpageheight}{11in}") _n

	* use "$dir/tmp/fullPanel.dta", clear

	levelsof `naics_variable', local(naics_codes)
	foreach naics_code in `naics_codes' { 

		count if `naics_variable' == `naics_code'
		if r(N) < 10 {
			continue
		}

		file write `texhandle' ("\begin{figure}[htbp]") _n			
		file write `texhandle' ("\includegraphics[width=\linewidth]{residuals`naics_code'.eps}") _n
		file write `texhandle' ("\end{figure}") _n	
		file write `texhandle' ("\clearpage") _n

	}
	
	file write `texhandle' ("\end{document}") _n
	file close `texhandle'	

	local old_dir = c(pwd)
	cd $dir/tmp
	! pdflatex --shell-escape results.tex 
	cd `old_dir'
		
end


program define NonemployedTest

	use $dir/tmp/nonemployed.dta
	
	local NEW_ENGLAND st == 25 | st == 23 | st == 33 | st == 50 | st == 44 | st == 9
	keep if `NEW_ENGLAND'
	
	* first doing total establisments, regardless of NAICS
	sort year st county
	by year st county: egen total_estab = total(estab)
	by year st county: keep if _n == 1
	drop naics estab


	drop if year < 2000
	ren st stcode 
	ren county cntycd
	merge 1:1 stcode cntycd year using "$dir/tmp/Population.dta"
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge
	
	bysort stcode year: egen new_firms = total(total_estab)	
	bysort stcode year cntycd: keep if _n == 1
	bysort stcode year: egen state_pop = total(population)
	bysort stcode year: keep if _n == 1

	replace stcode = 00 if stcode != 25
	bysort stcode year: egen region_pop = total(state_pop)
	bysort stcode year: egen region_firms = total(new_firms)
	bysort stcode year: keep if _n == 1
	drop state_pop new_firms
	rename region_pop state_pop
	rename region_firms new_firms	

	gen rate = new_firms / state_pop
	replace rate = -rate if stcode != 25 
	bysort year: egen diff = total(rate)
	replace rate = -rate if stcode != 25 

	tostring stcode, replace

	GraphGeneric rate 2007 stcode 25		

end

program define NonemployedTest_Loop

	use $dir/tmp/nonemployed.dta
	
	local NEW_ENGLAND st == 25 | st == 23 | st == 33 | st == 50 | st == 44 | st == 9
	keep if `NEW_ENGLAND'

	drop if year < 2000
	ren st stcode 
	ren county cntycd
	merge n:1 stcode cntycd year using "$dir/tmp/Population.dta"
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge

	ren stcode state
	tostring state, replace
	destring naics, replace

	levelsof naics, local(naics_codes)
	foreach naics_code in `naics_codes' { 

		preserve 
		
		keep if naics == `naics_code'
	
		bysort state year: egen new_firms = total(estab)	
		bysort state year cntycd: keep if _n == 1
		bysort state year: egen state_pop = total(population)
		bysort state year: keep if _n == 1

		replace state = "00" if state != "25"
		bysort state year: egen region_pop = total(state_pop)
		bysort state year: egen region_firms = total(new_firms)
		bysort state year: keep if _n == 1
		drop state_pop new_firms
		rename region_pop state_pop
		rename region_firms new_firms	

		gen rate = new_firms / state_pop
		replace rate = -rate if state != "25" 
		bysort year: egen diff = total(rate)
		replace rate = -rate if state != "25" 
		
		local y_variable diff

		set graphics off
		GraphGeneric diff 2007 state "25" `naics_code'
		graph2tex, epsfile("$dir/tmp/`naics_code'")	
		set graphics on 

		restore
	}

	ReportResults naics_2

end

program define CountyBusinessTest

	use $dir/tmp/countyBusiness.dta
	
	* 999 is 'statewide' county
	drop if cntycd == 999
	
	* first doing total establisments, regardless of NAICS
	sort year stcode cntycd
	by year stcode cntycd: egen total_estab = total(n1_4)
	by year stcode cntycd: keep if _n == 1
	drop n*
	
	bysort stcode year: egen new_firms = total(total_estab)	
	replace cntycd = 0
	bysort stcode year: keep if _n == 1
	drop total_estab

	drop if year < 2000
	merge 1:1 stcode cntycd year using "$dir/tmp/Population.dta"
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge

	rename population state_pop

	replace stcode = 00 if stcode != 25
	bysort stcode year: egen region_pop = total(state_pop)
	bysort stcode year: egen region_firms = total(new_firms)
	bysort stcode year: keep if _n == 1
	drop state_pop new_firms
	rename region_pop state_pop
	rename region_firms new_firms	

	gen rate = new_firms / state_pop
	replace rate = -rate if stcode != 25 
	bysort year: egen diff = total(rate)
	replace rate = -rate if stcode != 25 

	tostring stcode, replace

	GraphGeneric rate 2007 stcode 25		

end

program define CountyBusinessNewEngland

	use $dir/tmp/countyBusiness.dta

	* keep if stcode == 9 | stcode == 23 | stcode == 25 | stcode == 33 | stcode == 44 | stcode == 50
	
	* border with Massachusetts
	/*
	gen drop = 1
	replace drop = 0 if stcode == 36 & cntycd == 83	
	replace drop = 0 if stcode == 36 & cntycd == 21
	replace drop = 0 if stcode == 50 & cntycd == 3
	replace drop = 0 if stcode == 50 & cntycd == 25
	replace drop = 0 if stcode == 33 & cntycd == 5
	replace drop = 0 if stcode == 33 & cntycd == 11
	replace drop = 0 if stcode == 33 & cntycd == 15
	replace drop = 0 if stcode == 9 & cntycd == 5
	replace drop = 0 if stcode == 9 & cntycd == 3
	replace drop = 0 if stcode == 9 & cntycd == 13
	replace drop = 0 if stcode == 9 & cntycd == 15
	replace drop = 0 if stcode == 44 & cntycd == 7
	replace drop = 0 if stcode == 44 & cntycd == 1
	replace drop = 0 if stcode == 44 & cntycd == 5
	*/

	* On boarder of Massachussetts
	/*
	replace drop = 0 if stcode == 25 & cntycd == 3
	replace drop = 0 if stcode == 25 & cntycd == 5
	replace drop = 0 if stcode == 25 & cntycd == 9
	replace drop = 0 if stcode == 25 & cntycd == 11
	replace drop = 0 if stcode == 25 & cntycd == 13
	replace drop = 0 if stcode == 25 & cntycd == 17
	replace drop = 0 if stcode == 25 & cntycd == 21
	replace drop = 0 if stcode == 25 & cntycd == 27
	
	drop if drop
	drop drop
	*/
	
	
	* treatment is significant in 23, 31, 56, 61, 62, 81, 99
	
	* keep if naics_2 == 11
	* keep if naics_2 == 21
	* keep if naics_2 == 22
	* keep if naics_2 == 23
	* keep if naics_2 == 31 | naics_2 == 32 | naics_2 == 33
	* keep if naics_2 == 42
	* keep if naics_2 == 44 | naics_2 == 45
	* keep if naics_2 == 48 | naics_2 == 49
	* keep if naics_2 == 51
	* keep if naics_2 == 52
	* keep if naics_2 == 53
	* keep if naics_2 == 54
	* keep if naics_2 == 55
	* keep if naics_2 == 56
	* keep if naics_2 == 61
	* keep if naics_2 == 62
	* keep if naics_2 == 71
	* keep if naics_2 == 72
	* keep if naics_2 == 81
	* keep if naics_2 == 92
	* keep if naics_2 == 99	

	* used pre-2002 for auxillary offices
	* https://ask.census.gov/faq.php?id=5000&faqId=1715
	drop if naics_2 == 95

	gen variable_of_interest = n1_4
	* gen variable_of_interest = n5_9     
	* gen variable_of_interest = n10_19   
	* gen variable_of_interest = n20_49   
	* gen variable_of_interest = n50_99   
	* gen variable_of_interest = n100_249 
	* gen variable_of_interest = n250_499 
	* gen variable_of_interest = n500_999 
	* gen variable_of_interest = n1000    
	* gen variable_of_interest = n1000_1  
	* gen variable_of_interest = n1000_2  
	* gen variable_of_interest = n1000_3  
	* gen variable_of_interest = n1000_4  	
	
	* removing these for now, later need to check that 
	* there wasn't a shift downward in firm size
	drop n*9 n1000* n1_4
	
	* not using these at the moment
	drop emp
	
	* in population data statewide is 0, not 999 as in county business
	* may be better off just dropping 999 since i'm not exactly sure how its
	* calculated
	* replace cntycd = 0 if cntycd == 999
	drop if cntycd == 0

	* using panel function to fill in missing years with zero data
	gen panel =  cntycd * 10000 + stcode * 100 + naics_2
	tsset panel year
	tsfill, full
	sort panel
	by panel: egen stcode_tmp = mean(stcode)
	count if stcode_tmp != stcode & !missing(stcode)
	assert(r(N)==0)
	drop stcode
	rename stcode_tmp stcode
	by panel: egen cntycd_tmp = mean(cntycd)
	count if cntycd_tmp != cntycd & !missing(cntycd)
	assert(r(N)==0)
	drop cntycd
	rename cntycd_tmp cntycd
	by panel: egen naics_2_tmp = mean(naics_2)
	count if naics_2_tmp != naics_2 & !missing(naics_2)
	assert(r(N)==0)
	drop naics_2
	rename naics_2_tmp naics_2
	replace variable_of_interest = 0 if missing(variable_of_interest)
	
	* ERROR: should check if each county state year has all the naics codes
	
	* need n:1 rather than 1:1 since there are multiple naics 2 codes
	merge n:1 stcode cntycd year using "$dir/tmp/Population.dta"
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge

	* bysort stcode cntycd: egen max_pop = max(population)
	* bysort stcode cntycd year: egen total_est = total(est)
	* bysort stcode cntycd: gen est_to_pop = total_est / population	
	* local max_pop 15000
	* list if max_pop < `max_pop' & naics_2 == 11, clean
	* drop if max_pop < `max_pop'
	* drop max_pop
	
	* These counties have abnormally high est_to_pop levels, probably due
	* to tourism
	drop if stcode == 25 & cntycd == 19
	drop if stcode == 25 & cntycd == 7
	* bysort stcode cntycd year: egen total_est = total(est)
	* bysort stcode cntycd: gen est_to_pop = total_est / population
	* hist est_to_pop
	* drop est_to_pop total_est
	
	sort panel year
	
	* getting rate of change in establishments
	gen change_in_establishments = D.variable_of_interest
	gen rate_of_change = change_in_establishments / population

	* treating all other states as new england region
	gen state_dummy = 0
	replace state_dummy = 1 if stcode == 25
	
	* creating year dummies
	tab year, gen(year_dummy)
	
	* dummy for treatment
	gen treatment = 0
	replace treatment = 1 if stcode == 25 & year >= 2007
	
	eststo: regress rate_of_change treatment state_dummy year_dummy*, robust cluster(panel)
	esttab, mtitles  keep(treatment) nonumbers replace compress se
	
	tostring state_dummy, replace
	GraphGeneric rate_of_change 2007 state_dummy "1"
	
	* ERROR: is the rate normally distributed? 
end

program define MatchingState

	use $dir/tmp/nonemployed.dta
	drop if year < 2000
	drop if naics == 0
                
        * get rid of naics codes that don't really exist in MA
	bysort naics stcode: egen t_small = total(small) if year == 2008
	bysort naics stcode: egen tt_small = mean(t_small)
	drop if tt_small < 1000
	drop t_small tt_small

	* focus on matching counties in new england
        * keep if stcode == 9 | stcode == 23 | stcode == 33 | stcode == 44 | stcode == 50 | stcode == 25

	* need n:1 rather than 1:1 since there are multiple naics 2 codes
	merge n:1 stcode cntycd year using "$dir/tmp/Population.dta"
	* ignoring county in Virgina and Florida that don't show up here
	* https://www.census.gov/geo/reference/codes/cou.html
	count if _merge == 1
	* assert(r(N)==0)
	bysort panel: egen error = total(_merge == 1)
	drop if error
	drop error	
	
	drop if _merge == 2
	drop _merge

        sort panel year 
        gen small_pop = small / population * 1000000
        gen diff_small_pop = D.small_pop

	* Covariates used for matching

	* all the covariates are for a single year independant so should be safe to just generate
	* matches for a single year as the 'treatment' group
	
	* income per capita (GDP) 
	rename year year_tmp
	gen year = 2006
	merge n:1 stcode year using "$dir/tmp/MedianIncomeState.dta"
	drop year
	rename year_tmp year
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge
	gen log_income = log(income)
	drop(income)

	* percent aged 20-24 or so since MA has a lot of universities
	* child dependancy ratio
	* this is currently using 2000 year data
	merge n:1 stcode cntycd using "$dir/tmp/ageGroup.dta"
	count if _merge == 1
	* assert(r(N)==0)
	bysort panel: egen error = total(_merge == 1)
	drop if error
	drop error	
	drop if _merge == 2
	drop _merge
	
	* percent with healthcare
	* using 2005 data
	merge n:1 stcode cntycd using "$dir/tmp/insurance.dta"
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge

	* urban population
	* using 2000 year data
	merge n:1 stcode cntycd using "$dir/tmp/urban.dta"
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge

	keep year panel small_pop stcode naics cntycd log_income percent_uninsured percent_20_to_24 diff_small_pop percent_urban

	drop if year == 2000
	
	* set graphics off
	local treatment 2008
	local MA 25
	
	local titles
	
	levelsof naics if stcode == `MA', local(industries) 
	foreach industry of local industries {
	
		* first create synthetic control data by county
		levelsof cntycd if stcode == `MA' & naics == `industry', local(counties)
		foreach county of local counties {

			preserve

			* picking counties with similar predictor values
			local max_sd 1
			sort stcode cntycd
			by stcode cntycd: gen tag = _n == 1
			local predictors log_income percent_20_to_24 percent_urban percent_uninsured		

			foreach predictor of varlist `predictors' {	
				by stcode cntycd: egen st_mean = mean(`predictor')
				su st_mean if tag
				local max_d = `max_sd' * r(sd)
				su st_mean if stcode == `MA' & cntycd == `county'
				drop if st_mean >  r(mean) + `max_d' | st_mean < r(mean) - `max_d'
				su st_mean if tag
				drop st_mean
			}
			drop tag
			
			* should only be one
			levelsof panel if stcode == `MA' & cntycd == `county' & naics == `industry', local(trunit)
			levelsof panel if stcode != `MA' & naics == `industry', local(counit)		
			synth diff_small_pop ///
				diff_small_pop(2001) diff_small_pop(2002) diff_small_pop(2003) diff_small_pop(2004) diff_small_pop(2005) diff_small_pop(2006) diff_small_pop(2007) ///
				log_income percent_20_to_24 percent_urban percent_uninsured ///
				, trunit(`trunit') trperiod(`treatment') counit(`counit') ///
				fig keep("$dir/tmp/synth_`county'_`industry'") replace				
				
			restore
		}					

		* next recreate the control as separate counties
		gen e = 2 if stcode == `MA'
		expand e, gen(d)
		drop e
		replace panel = -panel if d == 1
		replace diff_small_pop = . if d == 1
		replace small = . if d == 1
		replace stcode = 0 if d == 1
		
		gen _Co_Number = panel
		
		levelsof cntycd if stcode == `MA', local(counties)
		foreach county of local counties {
		
			merge n:1 _Co_Number using "$dir/tmp/synth_`county'_`industry'.dta", assert(1 3)
			drop _Y_treated _Y_synthetic _time _merge

			gen w_diff = _W_Weight * diff_small_pop
			bysort year: egen c_diff = total(w_diff)
			replace diff_small_pop = c_diff if d == 1 & stcode == 0 & cntycd == `county' & naics == `industry'
			drop w_diff c_diff _W_Weight

		}
		
		drop d _Co_Number
		
		gen treatment = (year >= `treatment') & (stcode == `MA')
		eststo N_`industry': xtreg diff_small_pop treatment ib2007.year if inlist(stcode, 0,25) & naics == `industry', fe robust	
		drop treatment
		local titles `titles' `industry'

		preserve
		keep if inlist(stcode, 0,25)
		keep if naics == `industry'
		GraphPaper diff_small_pop 2008 stcode 25 `industry'
		restore
		
		drop if stcode == 0
	}
	
	set graphics on



	esttab N_* using "$dir/tmp/naics_DDD", ///
		mtitles(`titles')   ///
		rename(treatment B) ///
		keep(B)  ///
		order(constant B *.year) ///		
		csv nobaselevels nonumbers replace compress ci  b(3) starlevels(* 0.10 ** 0.05 *** 0.01 **** 0.001)

	ReportResults naics	


	exit

	local industry 54
	local MA 25
	GraphPaper diff_small_pop 2008 stcode 25 `industry'

	
	preserve
	keep if naics == 54
	graph twoway (scatter diff_small_pop year if stcode == 25, msymbol(X) mcolor(midblue) xline(2007.5, lcolor(black))) ///
		(scatter diff_small_pop year if stcode == 0, msymbol(+) mcolor(red) xline(2007.5, lcolor(black))) ///
		(lpoly diff_small_pop year if year < 2008 & stcode == 25, lcolor(midblue) degree(1)) ///
		(lpoly diff_small_pop year if year >= 2008 & stcode == 25, lcolor(midblue) degree(1)) ///
		(lpoly diff_small_pop year if year < 2008 & stcode == 0, lcolor(red) degree(1)) ///
		(lpoly diff_small_pop year if year >= 2008 & stcode == 0, lcolor(red) degree(1)) ///
		, title(`title') ytitle(Rate of net new firms) yscale(titlegap(3)) ylabel(, labsize(small)) xtitle(Year) xlabel(2001 2004 2008 2012, labsize(small)) legend(order(1 2) label(1 "MA Counties") label(2 "Synth Counties") cols(1) size(small)) graphregion(fcolor(dimgray))

	restore

end

program define MatchingCounty

	use $dir/tmp/countyBusiness.dta

	* keep if naics_2 == 11
	* keep if naics_2 == 21
	* keep if naics_2 == 22
	* keep if naics_2 == 23
	* keep if naics_2 == 31 | naics_2 == 32 | naics_2 == 33
	* keep if naics_2 == 42
	* keep if naics_2 == 44 | naics_2 == 45
	* keep if naics_2 == 48 | naics_2 == 49
	* keep if naics_2 == 51
	* keep if naics_2 == 52
	* keep if naics_2 == 53
	* keep if naics_2 == 54
	* keep if naics_2 == 55
	* keep if naics_2 == 56
	* keep if naics_2 == 61
	* keep if naics_2 == 62
	* keep if naics_2 == 71
	* keep if naics_2 == 72
	* keep if naics_2 == 81
	* keep if naics_2 == 92
	* keep if naics_2 == 99	

	rename naics_2 naics


	* These counties have abnormally high est_to_pop levels, probably due
	* to tourism
	drop if stcode == 25 & cntycd == 19
	drop if stcode == 25 & cntycd == 7

	* dropping Alaska, has data matching issues later and 
	* arguably irrelevant to study
	drop if stcode == 2

	* ignoring county in Virgina and Florida that don't show up here
	* https://www.census.gov/geo/reference/codes/cou.html
	* and cause merging errors
	drop if (stcode == 51 & cntycd == 560) | (stcode == 12 & cntycd == 25)

	* ignoring Broomsfield, CO; small city that seperated from boulder, CO
	drop if (stcode == 8 & cntycd == 14)

	* used pre-2002 for auxillary offices
	* https://ask.census.gov/faq.php?id=5000&faqId=1715
	drop if naics == 95

	* summing across all naics
	bysort stcode cntycd year: egen variable_of_interest = total(n1_4)
	egen tag = tag(stcode cntycd year)
	keep if tag
	drop naics

	* removing these for now, later need to check that 
	* there wasn't a shift downward in firm size
	drop n*9 n1000* n1_4
	
	* not using these at the moment
	drop emp
	
	* VERIFY: `statewide' establishments, causes extreme teh est_to_pop values
	drop if cntycd == 999
	
	* using panel function to fill in missing years with zero data
	egen panel =  group(cntycd stcode)
	tsset panel year
	tsfill, full
	sort panel
	by panel: egen stcode_tmp = mean(stcode)
	count if stcode_tmp != stcode & !missing(stcode)
	assert(r(N)==0)
	drop stcode
	rename stcode_tmp stcode
	by panel: egen cntycd_tmp = mean(cntycd)
	count if cntycd_tmp != cntycd & !missing(cntycd)
	assert(r(N)==0)
	drop cntycd
	rename cntycd_tmp cntycd
	replace variable_of_interest = 0 if missing(variable_of_interest)
	
	* not necessary but checking we now have a balanced panel
	tsset, clear
	tsset panel year

	* VERIFY: each state county combination has full set of naics_2 observations
	* although may not be necessary

	* creating outcome variable

	* need n:1 rather than 1:1 since there are multiple naics 2 codes
	merge n:1 stcode cntycd year using "$dir/tmp/Population.dta"
	* ignoring county in Virgina and Florida that don't show up here
	* https://www.census.gov/geo/reference/codes/cou.html
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge

	sort panel year	
	* getting rate of change in establishments
	gen change_in_establishments = D.variable_of_interest
	* gen rate_of_change = change_in_establishments / population
	gen rate_of_change = variable_of_interest / population

	* Covariates used for matching

	* all the covariates are for a single year independant so should be safe to just generate
	* matches for a single year as the 'treatment' group
	
	* income per capita (GDP) 
	* note this is actually household income
	rename year year_tmp
	gen year = 2006
	merge n:1 stcode cntycd year using "$dir/tmp/MedianIncome.dta"
	drop year
	rename year_tmp year
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge
	gen log_income = log(income)
	drop(income)

	* percent aged 20-24 or so since MA has a lot of universities
	* child dependancy ratio
	* this is currently using 2000 year data
	merge n:1 stcode cntycd using "$dir/tmp/ageGroup.dta"
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge
	
	* percent with healthcare
	* using 2005 data
	merge n:1 stcode cntycd using "$dir/tmp/insurance.dta"
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge

	* population density
	* using 2000 year data
	merge n:1 stcode cntycd using "$dir/tmp/density.dta"
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge
	
	* price of healthcare ???
	* equivilant of beer consumption per captia ???

	* using every earlier year as a matching variable
	sort stcode cntycd
	foreach year of numlist 2000/2006 {
		by stcode cntycd: egen temp_`year' = mean(rate_of_change) if year == `year'
		by stcode cntycd: egen rate_yr_`year' = mean(temp_`year')
		drop temp_`year'
	}

	* local covariates log_income percent_20_to_24 percent_household_with_children percent_uninsured pop_density rate_yr_*
	
	preserve
	
	* this process tosses out suffolk county (boston)
	keep if year == 2006
	gen treatment_group = (stcode == 25)
	* cem log_income percent_20_to_24 percent_uninsured pop_density rate_yr_2002 rate_yr_2003 rate_yr_2004 rate_yr_2005 rate_yr_2006, treatment(treatment_group)	
	* cem rate_yr_2001 rate_yr_2002 rate_yr_2003 rate_yr_2004 rate_yr_2005 rate_yr_2006, treatment(treatment_group) autocuts("fd")
	cem log_income percent_20_to_24 percent_uninsured pop_density rate_yr_2000 rate_yr_2003 rate_yr_2006, treatment(treatment_group) // autocuts("fd")
	keep stcode cntycd cem_match cem_weights
	save $dir/tmp/cemMatchSet.dta, replace
		
	restore
	
	merge n:1 stcode cntycd using "$dir/tmp/cemMatchSet.dta"
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge

	!rm $dir/tmp/cemMatchSet.dta

	keep if cem_match
	
	* creating dummies
	* VERIFY: trying to caputre effect of Mass policy change so should I 
	* still have state fixed effects? 
	quietly: tab stcode, gen(state_dummy)
	quietly: tab cntycd, gen(county_dummy)
	quietly: tab year, gen(year_dummy)

	local fixed_effects state_dummy* county_dummy* year_dummy*
	
	* dummy for treatment
	gen treatment = 0
	replace treatment = 1 if stcode == 25 & year >= 2007
	
	quietly: eststo: regress rate_of_change treatment `fixed_effects' [iweight=cem_weights]
	esttab, mtitles  keep(treatment) nonumbers replace compress se
	
	tostring stcode, replace
	GraphGeneric rate_of_change 2007 stcode "25"


end

* retail 44/45, managment 55, admin 56 and other 81 seems to have a 95% effect

program define MatchingNaics

	use $dir/tmp/countyBusiness.dta

	* keep if naics_2 == 11
	* keep if naics_2 == 21
	* keep if naics_2 == 22
	* keep if naics_2 == 23
	* keep if naics_2 == 31 | naics_2 == 32 | naics_2 == 33
	* keep if naics_2 == 42
	 keep if naics_2 == 44 | naics_2 == 45
	* keep if naics_2 == 48 | naics_2 == 49
	* keep if naics_2 == 51
	* keep if naics_2 == 52
	* keep if naics_2 == 53
	* keep if naics_2 == 54
	* keep if naics_2 == 55
	* keep if naics_2 == 56
	* keep if naics_2 == 61
	* keep if naics_2 == 62
	* keep if naics_2 == 71
	* keep if naics_2 == 72
	* keep if naics_2 == 81
	* keep if naics_2 == 92
	* keep if naics_2 == 99	

	rename naics_2 naics


	* These counties have abnormally high est_to_pop levels, probably due
	* to tourism
	* for county 19 naics codes are 44 and 23
	drop if stcode == 25 & cntycd == 19
	* for county 7 naics codes are 44 and 23
	drop if stcode == 25 & cntycd == 7

	* dropping Alaska, has data matching issues later and 
	* arguably irrelevant to study
	drop if stcode == 2

	* ignoring county in Virgina and Florida that don't show up here
	* https://www.census.gov/geo/reference/codes/cou.html
	* and cause merging errors
	drop if (stcode == 51 & cntycd == 560) | (stcode == 12 & cntycd == 25)

	* ignoring Broomsfield, CO; small city that seperated from boulder, CO
	drop if (stcode == 8 & cntycd == 14)

	* used pre-2002 for auxillary offices
	* https://ask.census.gov/faq.php?id=5000&faqId=1715
	drop if naics == 95

	* has a lot of varience compared to other naics which are stable in 
	* est / pop over time
	drop if naics == 99
	
	* don't have enough observations in the data for these at a county level
	* when measuring the n1_4 per person
	drop if naics == 21 | naics == 22	

	gen variable_of_interest = n1_4

	* removing these for now, later need to check that 
	* there wasn't a shift downward in firm size
	drop n*9 n1000* n1_4
	
	* not using these at the moment
	drop emp
	
	* VERIFY: `statewide' establishments, causes extreme teh est_to_pop values
	drop if cntycd == 999

	* using panel function to fill in missing years with zero data
	egen panel =  group(cntycd stcode naics)
	tsset panel year
	tsfill, full
	sort panel
	by panel: egen stcode_tmp = mean(stcode)
	count if stcode_tmp != stcode & !missing(stcode)
	assert(r(N)==0)
	drop stcode
	rename stcode_tmp stcode
	by panel: egen cntycd_tmp = mean(cntycd)
	count if cntycd_tmp != cntycd & !missing(cntycd)
	assert(r(N)==0)
	drop cntycd
	rename cntycd_tmp cntycd
	by panel: egen naics_tmp = mean(naics)
	count if naics_tmp != naics & !missing(naics)
	assert(r(N)==0)
	drop naics
	rename naics_tmp naics
	replace variable_of_interest = 0 if missing(variable_of_interest)
	
	* not necessary but checking we now have a balanced panel
	tsset, clear
	tsset panel year

	* VERIFY: each state county combination has full set of naics_2 observations
	* although may not be necessary

	* creating outcome variable

	* need n:1 rather than 1:1 since there are multiple naics 2 codes
	merge n:1 stcode cntycd year using "$dir/tmp/Population.dta"
	* ignoring county in Virgina and Florida that don't show up here
	* https://www.census.gov/geo/reference/codes/cou.html
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge

	sort panel year	
	* getting rate of change in establishments
	* gen change_in_establishments = D.variable_of_interest
	* gen rate_of_change = change_in_establishments / population
	gen rate_of_change = variable_of_interest / population

	* Covariates used for matching

	* all the covariates are for a single year independant so should be safe to just generate
	* matches for a single year as the 'treatment' group
	
	* income per capita (GDP) 
	* note this is actually household income
	rename year year_tmp
	gen year = 2006
	merge n:1 stcode cntycd year using "$dir/tmp/MedianIncome.dta"
	drop year
	rename year_tmp year
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge
	gen log_income = log(income)
	drop(income)

	* percent aged 20-24 or so since MA has a lot of universities
	* child dependancy ratio
	* this is currently using 2000 year data
	merge n:1 stcode cntycd using "$dir/tmp/ageGroup.dta"
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge
	
	* percent with healthcare
	* using 2005 data
	merge n:1 stcode cntycd using "$dir/tmp/insurance.dta"
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge

	* population density
	* using 2000 year data
	merge n:1 stcode cntycd using "$dir/tmp/density.dta"
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge
	
	* price of healthcare ???
	* equivilant of beer consumption per captia ???

	* using every earlier year as a matching variable
	sort stcode cntycd naics
	foreach year of numlist 2000/2006 {
		by stcode cntycd naics: egen temp_`year' = mean(rate_of_change) if year == `year'
		by stcode cntycd naics: egen ln_ry`year' = mean(log(temp_`year'))
		drop temp_`year'
	}
	
	local matching_variables ln_ry2000 ln_ry2003 ln_ry2006 percent_20_to_24 percent_household_with_children pop_density
	
	* removing observations that are to far from Mass counties to prevent 
	* bins that are too wide
	* VERIFY pruning is legitimate
	local max_sd 0.5
	foreach var of varlist `matching_variables'  {
		levelsof naics, local(naics_codes)
		foreach naics_code in `naics_codes' { 
			su `var' if stcode == 25 & year == 2006 & naics == `naics_code'
			local min = r(min)
			local max = r(max)
			local max_deviation = r(sd) * `max_sd'

			count if stcode == 25 & naics == `naics_code'
			local start_count = r(N)
			drop if (`var' < `min' - `max_deviation') | (`var' > `max' + `max_deviation') & naics == `naics_code' & !missing(`var')
			count if stcode == 25 & naics == `naics_code'
			assert r(N) == `start_count'
		}
	}


	* local covariates log_income percent_20_to_24 percent_household_with_children percent_uninsured pop_density rate_yr_*	
	preserve
	
	* this process tosses out suffolk county (boston)
	keep if year == 2006
	gen treatment_group = (stcode == 25)
	* cem log_income percent_20_to_24 percent_uninsured pop_density rate_yr_2002 rate_yr_2003 rate_yr_2004 rate_yr_2005 rate_yr_2006, treatment(treatment_group)	
	/*
	get poor matches probably since rate_of_change isn't normally distributed
	sturges
	--------------------------
	treatment |
	_group    | mean(rate_o~e)
	----------+---------------
		0 |       .0006873
		1 |         .00076
	--------------------------
	fd
	----------+---------------
		0 |       .0001563
		1 |       .0006446
	--------------------------
	scott
	----------+---------------
		0 |       .0002569
		1 |       .0007143
	--------------------------
	ss
	----------+---------------
		0 |       .0004931
		1 |         .00076
	--------------------------
	
	when using log rate we do better
	
	sturges
	----------+---------------
		0 |       .0008906
		1 |       .0007667
	--------------------------
	fd
	--------------------------
		0 |       .0010656
		1 |        .000868
	--------------------------
	scott
	----------+---------------
		0 |       .0010462
		1 |       .0008473
	--------------------------
	ss
	----------+---------------
		0 |       .0008161
		1 |       .0007667
	--------------------------
	gen ln_ry2000 = log(rate_yr_2000)
	gen ln_ry2003 = log(rate_yr_2003)
	gen ln_ry2006 = log(rate_yr_2006)
	foreach algo in "sturges" "fd" "scott" "ss" {
		quietly: cem ln_ry2000 ln_ry2003 ln_ry2006, treatment(treatment_group) autocuts(`algo')
		display "`algo'"
		bysort treatment_group: egen cem_mean = wtmean(rate_of_change), weight(cem_weights)
		table treatment_group, contents(mean cem_mean)
		tab cem_weights if treatment_group == 1 
		drop cem*
	}
	*/

	cem `matching_variables' , treatment(treatment_group) autocuts("sturges")	
	bysort treatment_group: egen cem_mean = wtmean(rate_of_change), weight(cem_weights)
	table treatment_group, contents(mean cem_mean)
	keep stcode cntycd naics cem_match cem_weights
	save $dir/tmp/cemMatchSet.dta, replace
		
	restore
	
	merge n:1 stcode cntycd naics using "$dir/tmp/cemMatchSet.dta"
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge

	!rm $dir/tmp/cemMatchSet.dta

	keep if cem_match
	
	* creating dummies
	* VERIFY: trying to caputre effect of Mass policy change so should I 
	* still have state and county fixed effects? 
	quietly: tab stcode, gen(state_dummy)
	quietly: tab cntycd, gen(county_dummy)
	quietly: tab naics, gen(naics_dummy)
	quietly: tab year, gen(year_dummy)

	local fixed_efects state_dummy* county_dummy* naics_dummy* year_dummy*
	
	* dummy for treatment
	gen treatment = 0
	replace treatment = 1 if stcode == 25 & year >= 2007
	
	quietly: eststo: regress rate_of_change treatment `fixed_efects' [iweight=cem_weights]
	esttab, mtitles  keep(treatment) nonumbers replace compress se
	
	tostring stcode, replace
	GraphWeighted rate_of_change 2007 stcode "25" cem_weights
	destring stcode, replace
	
	
	/*

	* removing observations that are to far from Mass counties to prevent 
	* propensity score overlap violations due to low probabilities 
	* VERIFY pruning is legitimate
	
	local max_sd 1 
	foreach var of varlist `covariates' {
		su `var' if stcode == 25 & year == `matching_year'
		local min = r(min)
		local max = r(max)
		local max_deviation = r(sd) * `max_sd'

		count if stcode == 25
		local start_count = r(N)
		drop if (`var' < `min' - `max_deviation') | (`var' > `max' + `max_deviation')
		count if stcode == 25
		assert r(N) == `start_count'
	}
	


	* VERIFY: ok to increase lower bound of matching estimator
	gen treatment_group = (stcode == 25)
	teffects psmatch (rate_of_change) (treatment_group `covariates' rate_yr_*) if year == `matching_year', osample(violation) generate(nn) pstolerance(1e-6)

	*/
end

/* Currently the main program, along side Nonprofit and SummaryStatistics */

program define StateDiff

	local useNonemployer 0

	if `useNonemployer' {
		use $dir/tmp/nonemployed.dta
		drop if year < 2000
		tsset, clear
		drop panel
		drop if naics == 0
		
		* get rid of naics codes that don't really exist in MA
		bysort naics stcode: egen t_small = total(small) if year == 2008
		bysort naics stcode: egen tt_small = mean(t_small)
		drop if tt_small < 1000
		drop t_small tt_small
		
	} 
	else {
		use $dir/tmp/countyBusiness.dta
		rename naics_2 naics
		drop if missing(naics)
	}

	* NAICS 99 changes too much to be useful
	drop if naics == 99
	* removing the health care sector to comply with theory
	drop if naics == 62
	* don't have capital data on this
	drop if naics == 95

	* dropping construction and retail in Nantucket county as an outlier
	
	drop if stcode == 25 & cntycd == 19 & naics == 23
	drop if stcode == 25 & cntycd == 19 & naics == 44
	drop if stcode == 25 & cntycd == 19

	recast byte stcode 
	keep if stcode == 9 | stcode == 23 | stcode == 33 | stcode == 44 | stcode == 50 | stcode == 25
	label define states 9 "Connecticut" 23 "Maine" 33 "New Hampshire" 44 "Rhode Island" 50 "Vermont" 25 "Massachusetts"
	label variable stcode "State"
	label values stcode states	
	
	if !`useNonemployer' {
	
		* focus on small establishments
		ren n1_4 small
		drop n*9 n1000* est
		drop emp

		* drop state wide establishments, not many of these and gets confusing with 
		* state population data
		drop if cntycd == 999
		
		* there shouldn't be any of these
		drop if cntycd == 0
		
		* creating full panel before merging in population
		* two counties are missing two naics codes entirely
		gen e = 2 if naics == 23 & cntycd == 25 & stcode == 23 & year == 2008
		replace e = 2 if naics == 23 & cntycd == 19 & stcode == 33 & year == 2008
		replace e = 2 if naics == 23 & cntycd == 3 & stcode == 50 & year == 2008
		replace e = 2 if naics == 23 & cntycd == 9 & stcode == 50 & year == 2008
		replace e = 2 if naics == 23 & cntycd == 13 & stcode == 50 & year == 2008
		expand e, gen(d)
		replace naics = 21 if e == 2 & naics == 23 & cntycd == 25 & stcode == 23 & year == 2008 & d == 1
		replace naics = 21 if e == 2 & naics == 23 & cntycd == 19 & stcode == 33 & year == 2008 & d == 1
		replace naics = 21 if e == 2 & naics == 23 & cntycd == 3 & stcode == 50 & year == 2008 & d == 1
		replace naics = 55 if e == 2 & naics == 23 & cntycd == 9 & stcode == 50 & year == 2008 & d == 1
		replace naics = 55 if e == 2 & naics == 23 & cntycd == 13 & stcode == 50 & year == 2008 & d == 1
		replace small = 0 if d == 1
		drop e d
		
		egen panel =  group(stcode cntycd naics)
		tsset panel year
		tsfill, full
		
		bysort panel: egen stcode_tmp = mean(stcode)
		drop stcode
		rename stcode_tmp stcode
		bysort panel: egen cntycd_tmp = mean(cntycd)
		drop cntycd
		rename cntycd_tmp cntycd	
		bysort panel: egen naics_tmp = mean(naics)
		drop naics
		rename naics_tmp naics	
		replace small = 0 if missing(small)

		* verifying we now have a full panel
		tsset, clear
		drop panel
	
	}
		
	merge n:1 stcode cntycd year using "$dir/tmp/Population.dta"
	* ignoring county in Virgina and Florida that don't show up here
	* https://www.census.gov/geo/reference/codes/cou.html
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge					
	* for better readability dividing population by one million
	replace population = population / 1000000

	* saving before we get rid of naics level detail
	* preserve
	
	* sum up all small firms across all naics
	bysort stcode cntycd year: egen small_tmp = sum(small)
	drop small naics
	ren small_tmp small	
	duplicates drop
	
	egen panel = group(stcode cntycd)
	tsset panel year
		
	* getting rate of change in establishments
	sort panel year	
	gen small_pop = small / population
	gen diff_small_pop = D.small_pop
	gen percent_change = diff_small_pop / L.small_pop * 100
		
	* create treatment dummy
	local treatment_start 2008
	local treatment_group 25
	gen treatment = (year >= `treatment_start') & stcode == `treatment_group'
	* adding maine to debug
	* replace treatment = 1 if (year >= `treatment_start') & stcode == 50

	* create weights
	gen weight_tmp = population if year == `treatment_start'
	bysort panel: egen weight = mean(weight_tmp)
	drop weight_tmp
	
	local fixed_effects ib2007.year
	* local fixed_effects i.stcode i.stcode#i.cntycd ib`treatment_start'.year
	* here the state is the family and counties are individuals, so cluster by state
	* eststo DD: xtreg percent_change treatment `fixed_effects', fe robust cluster(stcode)
	eststo DD: xtreg diff_small_pop treatment `fixed_effects' [aw=weight], fe robust

	esttab DD using $dir/tmp/prop1.tex, ///
		mtitles("Model (1)")   ///
		keep("$\beta$")  ///
		rename(treatment "$\beta$") ///
		nobaselevels nonumbers replace compress se r2 scalar("F F-test" "N_g Groups") sfmt(%9.3f %9.0f) b(3) starlevels(* 0.10 ** 0.05 *** 0.01 **** 0.001)	

	* for graph of diff and diff
	gen treatment_group = stcode == `treatment_group'
	* drop year 2008 indicator
	levelsof year, local(years)	
	foreach year of local years {
		if `year' == 2007 | `year' == 2000 continue
		gen iYear`year' = year == `year'
		label variable iYear`year' "`year'"
		gen iTYear`year' = (year == `year') & (stcode == 25)
		label variable iTYear`year' "I*`year'"
	}
	* xtreg percent_change iYear* iTYear*, fe robust cluster(stcode)
	xtreg diff_small_pop iYear* iTYear* [aw=weight], fe robust
		
	GraphPoint iTYear 2007 "StateDiff"
	
	exit
		
	drop iTYear* iYear*
	
	esttab DD using $dir/tmp/state_diff.tex, ///
		mtitles("(1)")   ///
		keep("Massachusetts $\times$ Post 2007")  ///
		rename(treatment "Massachusetts $\times$ Post 2007") ///
		nobaselevels nonumbers replace compress se  b(3) starlevels(* 0.10 ** 0.05 *** 0.01 **** 0.001)
	
	* next do diff-in-diff within MA on industry
	restore	
	
	
	preserve
	
	keep if stcode == 25
	drop stcode
	
	egen panel = group(cntycd naics)
	tsset panel year
	local treatment_start 2008
	
	* getting rate of change in establishments
	sort panel year	
	gen small_pop = small / population
	gen diff_small_pop = D.small_pop
	gen percent_change = diff_small_pop / L.small_pop * 100
	
	/*
	local titles	
	* first asking which industries showed teh largest change in MA
	levelsof naics, local(naic_codes)	
	foreach naic_code of local naic_codes {
		gen treatment = (year >= `treatment_start') & (naics == `naic_code')
		eststo N_`naic_code': xtreg diff_small_pop treatment ib2007.year, fe robust	
		drop treatment
		local titles `titles' `naic_code'
	}
	
	esttab N_* using "$dir/tmp/naics_DD", ///
		mtitles(`titles')   ///
		rename(treatment "B") ///
		keep(B)  ///
		order(constant B *.year) ///		
		csv nobaselevels nonumbers replace compress ci  b(3) starlevels(* 0.10 ** 0.05 *** 0.01 **** 0.001)
	*/

	local titles

	* now using real capital measures
	
	if `useNonemployer' {
		merge n:1 naics using "$dir/tmp/capitalNonemployer.dta"
	}
	else {
		merge n:1 naics using "$dir/tmp/capital.dta"
	}
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge
	
	* set up captial sub-treatment group
	su percent_no_funding, detail
	local upper_cutoff = r(p90)
	gen low_capital = (percent_no_funding >= `upper_cutoff')
	
	* create weights
	/*
	gen weight_tmp = population if year == `treatment_start'
	bysort panel: egen weight = mean(weight_tmp)
	drop weight_tmp
	*/
		
	gen treatment = (year >= `treatment_start') & (low_capital == 1)
	

	local fixed_effects ib2007.year
	eststo C_DD: xtreg diff_small_pop treatment `fixed_effects', fe robust
			
	* eststo DDD: xtreg percent_change ib0.low_capital#ib25.stcode ib0.low_capital#ib2008.year ib25.stcode#ib2008.year treatment [aw=weight], fe robust cluster(cluster)

	/*
	* drop missing
	egen missing_count = rowmiss(percent_change)
	bysort panel: egen has_missing = sum(missing_count)
	drop if (has_missing > 0)
	drop missing_count has_missing
	eststo missing: xtreg percent_change ib0.low_capital#ib25.stcode ib0.low_capital#ib2008.year ib25.stcode#ib2008.year treatment [aw=weight], fe robust cluster(panel)
	*/
	
	drop low_capital treatment

	/*
	local titles
	* we have 18 industries
	local levels 18	
	gen pnf = round(percent_no_funding * 10)
	recast int pnf	
	pctile p = pnf, gen(q) n(`levels')
	levelsof p, local(funding_levels) 
	local quantile 0
	foreach funding_level of local funding_levels {
		display `funding_level'
		gen low_capital = (pnf >= `funding_level')
		count if low_capital
		local low_count = r(N)
		count 
		local total_count = r(N)
		local quantile = `low_count' / `total_count'
		gen treatment = (year >= `treatment_start') & (low_capital == 1)
		quietly: eststo Q_DD_`low_count': xtreg diff_small_pop treatment `fixed_effects', fe robust
		drop low_capital treatment
		local titles `titles' `quantile'
	}
	drop p q
	esttab Q_DD_* using "$dir/tmp/quantiles", ///
		mtitles(`titles')   ///
		rename(treatment "B") ///
		keep(B)  ///
		order(constant B *.year) ///		
		csv nobaselevels nonumbers replace compress ci  b(3) starlevels(* 0.10 ** 0.05 *** 0.01 **** 0.001)
	*/
	
	/*
	* graph of naics diff-diff
	gen low_capital = (percent_no_funding >= `upper_cutoff')
	* drop year 2008 indicator
	levelsof year, local(years)	
	foreach year of local years {
		if `year' == 2007 | `year' == 2000 continue
		gen iYear`year' = year == `year'
		label variable iYear`year' "`year'"
		gen iTYear`year' = (year == `year') & (low_capital==1)
		label variable iTYear`year' "I*`year'"
	}
	* xtreg percent_change iYear* iTYear*, fe robust cluster(stcode)
	xtreg diff_small_pop iYear* iTYear*, fe robust
	esttab . using "$dir/tmp/ddYearChart", ///
		csv nobaselevels nonumbers replace compress ci  b(3) starlevels(* 0.10 ** 0.05 *** 0.01 **** 0.001)

	drop iTYear* iYear*	
	*/

	* now doing triple diff to pull out economic effect
	restore
	
	egen panel = group(stcode cntycd naics)
	tsset panel year
	local treatment_start 2008
	
	* getting rate of change in establishments
	sort panel year	
	gen small_pop = small / population
	gen diff_small_pop = D.small_pop
	gen percent_change = diff_small_pop / L.small_pop * 100
	
	local titles	
	* first asking which industries showed the largest change in MA
	levelsof naics, local(naic_codes)	
	foreach naic_code of local naic_codes {
		gen treatment = (year >= `treatment_start') & (stcode == 25)
		* switching to a DD of industry versus the other states as a control. 
		eststo N_`naic_code': xtreg diff_small_pop treatment ib2007.year if naics == `naic_code', fe robust	
		* eststo N_`naic_code': xtreg diff_small_pop ib23.naics#ib25.stcode ib23.naics#ib2007.year ib25.stcode#ib2007.year treatment, fe robust
		drop treatment
		local titles `titles' `naic_code'
	}	
	
	esttab N_* using "$dir/tmp/naics_DDD", ///
		mtitles(`titles')   ///
		rename(treatment "B") ///
		keep(B)  ///
		order(constant B *.year) ///		
		csv nobaselevels nonumbers replace compress ci  b(3) starlevels(* 0.10 ** 0.05 *** 0.01 **** 0.001)

	local titles
	
	merge n:1 naics using "$dir/tmp/capital.dta"
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge
	
	* set up captial sub-treatment group
	su percent_no_funding, detail
	local upper_cutoff = r(p90)
	gen low_capital = (percent_no_funding >= `upper_cutoff')
	* switching to ~85 percentile
	* replace low_capital = 1 if naics == 22
	
	gen treatment_ddd = (year >= `treatment_start') & (stcode == 25) & (low_capital == 1)
	set matsize 1000
	eststo C_DDD: xtreg diff_small_pop ib23.naics#ib25.stcode ib23.naics#ib2007.year ib25.stcode#ib2007.year treatment_ddd, fe robust // cluster(state)

	* triple diff year fixed effect chart
	levelsof year, local(years)	
	foreach year of local years {
		if `year' == 2007 | `year' == 2000 continue
		gen iYear`year' = year == `year'
		label variable iYear`year' "`year'"
		gen iTYear`year' = (year == `year') & (low_capital==1) & (stcode == 25)
		label variable iTYear`year' "I*`year'"
	}
	* don't think iYear is needed here
	xtreg diff_small_pop ib23.naics#ib25.stcode ib23.naics#ib2007.year ib25.stcode#ib2007.year iTYear*, fe robust
	esttab . using "$dir/tmp/dddYearChart", ///
		keep(iTYear*) ///
		csv nobaselevels nonumbers replace compress ci  b(3) starlevels(* 0.10 ** 0.05 *** 0.01 **** 0.001)
	drop iTYear* iYear*
		
	* testing proposition 2
	gen single_treat = (year == `treatment_start') & (stcode == 25) & (low_capital == 1)
	gen post_treat = (year > `treatment_start') & (stcode == 25) & (low_capital == 1)
	gen single_treat_ddd = single_treat
	gen post_treat_ddd = post_treat

	levelsof year, local(years) 
	foreach year of local years {
		if (`year' == 2000 | `year' == 2007) continue
		if (`year' < 2008) continue
		gen tYear`year' = (year == `year') & (stcode == 25) & (low_capital == 1)
	}

	eststo A_DD: xtreg diff_small_pop ib2007.year single_treat post_treat, fe robust	
	test single_treat=post_treat
	* eststo M_DD: xtreg diff_small_pop ib2007.year tYear*, fe robust	

	eststo A_DDD: xtreg diff_small_pop ib23.naics#ib25.stcode ib23.naics#ib2007.year ib25.stcode#ib2007.year single_treat_ddd post_treat_ddd, fe robust // cluster(state)
	test single_treat_ddd=post_treat_ddd
	* eststo M_DDD: xtreg diff_small_pop ib23.naics#ib25.stcode ib23.naics#ib2007.year ib25.stcode#ib2007.year tYear*, fe robust
	
	drop low_capital treatment

	local titles	
	* we have 18 industries
	local levels 18	
	gen pnf = round(percent_no_funding * 10)
	recast int pnf	
	pctile p = pnf, gen(q) n(`levels')
	levelsof p, local(funding_levels) 
	local quantile 0
	foreach funding_level of local funding_levels {
		display `funding_level'
		gen low_capital = (pnf >= `funding_level')
		count if low_capital
		local low_count = r(N)
		count 
		local total_count = r(N)
		local quantile = `low_count' / `total_count'
		gen treatment = (year >= `treatment_start') & (stcode == 25) & (low_capital == 1)
		quietly: eststo Q_DDD_`low_count': xtreg diff_small_pop ib23.naics#ib25.stcode ib23.naics#ib2007.year ib25.stcode#ib2007.year treatment, fe robust
		drop low_capital treatment
		local titles `titles' `quantile'
	}
	drop p q
	esttab Q_DDD_* using "$dir/tmp/quantiles_ddd", ///
		mtitles(`titles')   ///
		rename(treatment "B") ///
		keep(B)  ///
		order(constant B *.year) ///		
		csv nobaselevels nonumbers replace compress ci  b(3) starlevels(* 0.10 ** 0.05 *** 0.01 **** 0.001)

	* keep("$\beta$" "$\beta_0$" "$\beta_1$")  ///
	* rename(treatment "Low Capital $\times$ Post 2007" treatment_ddd "Massachusetts $\times$ Low Capital $\times$ Post 2007" single_treat "Low Capital $\times$ 2008" post_treat "Low Capital $\times$ Post 2008" single_treat_ddd "Massachusetts $\times$ Low Capital $\times$ 2008" post_treat_ddd "Massachusetts $\times$ Low Capital $\times$ Post 2008") ///
	* rename(treatment "Low Capital $\times$ Post 2007" treatment_ddd "Massachusetts $\times$ Low Capital $\times$ Post 2007" single_treat "Low Capital $\times$ 2008" post_treat "Low Capital $\times$ Post 2008" single_treat_ddd "M $\times$ Low Capital t 2008" post_treat_ddd "M t Low Capital t Post 2008") ///

	esttab C_DD C_DDD A_DD A_DDD  using $dir/tmp/main.tex, ///
		mtitles("(4)" "(5)" "(6)" "(7)")  ///
		drop(*.year *.stcode _cons) ///
		nobaselevels nonumbers replace compress se r2 scalar("F F-test" "N_g Groups") sfmt(%9.3f %9.0f) b(3) starlevels(* 0.10 ** 0.05 *** 0.01 **** 0.001)
	
	/*
	set graphics off
	levelsof naics, local(naic_codes)	
	foreach naic_code of local naic_codes {
		preserve
		keep if naics == `naic_code'
		GraphPaper diff_small_pop 2008 stcode 25 `naic_code'		
		restore
	}
	set graphics on
	ReportResults naics	
	*/


	set graphics off
	levelsof cntycd if stcode == 25, local(naic_codes)	
	foreach naic_code of local naic_codes {
		preserve
		keep if naics == 53 & cntycd == `naic_code'
		GraphPaper diff_small_pop 2008 stcode 25 `naic_code'		
		restore
	}
	set graphics on
	keep if stcode == 25
	ReportResults cntycd	

end

program define Nonprofit

	* splitting out panel creation seperately since its a long process
	use $dir/tmp/fullPanel.dta
	
	merge n:1 naics using $dir/tmp/nonprofit.dta
	* don't expect all naics to exist int he nonprofit data
	keep if _merge == 3
	drop _merge

	gen nonprofit = (!missing(percent_nonprofit) & percent_nonprofit >= .5)
	tab nonprofit
	drop percent_nonprofit naicsdisplaylabel

	merge n:1 stcode cntycd year using "$dir/tmp/Population.dta"
	* ignoring county in Virgina and Florida that don't show up here
	* https://www.census.gov/geo/reference/codes/cou.html
	count if _merge == 1
	* full panel data drops some naics in 62**
	* assert(r(N)==0)
	drop if _merge == 1
	drop if _merge == 2
	drop _merge					
	* for better readability dividing population by one million
	replace population = population / 1000000
	
	* getting rate of change in establishments
	sort panel year	
	gen small_pop = small / population
	gen diff_small_pop = D.small_pop
	gen percent_change = diff_small_pop / L.small_pop * 100
	
	local treatment_start 2008
	local fixed_effects ib2007.year
	gen treatment = (year >= `treatment_start') & (nonprofit == 1) & (stcode == 25)
		
	* first the diff and diff
	eststo NP_DD: xtreg diff_small_pop treatment `fixed_effects' if stcode == 25, fe robust	
	
	set matsize 11000
	display "Matsize changed"
	
	* then the triple diff
	eststo NP_DDD: xtreg diff_small_pop ib2361.naics#ib2007.year ib25.stcode#ib2007.year treatment, fe robust	

	esttab NP_DD NP_DDD using $dir/tmp/nonprofit.tex, ///
		mtitles("Model (2)" "Model (3)")   ///
		keep("$\beta$")  ///
		rename(treatment "$\beta$") ///
		nobaselevels nonumbers replace compress se r2 scalar("F F-test" "N_g Groups") sfmt(%9.3f %9.0f) b(3) starlevels(* 0.10 ** 0.05 *** 0.01 **** 0.001)
	
end

program define fullCountyPanel

	!rm $dir/tmp/fullPanel.dta

	use $dir/tmp/countyBusiness.dta
	rename naics_4 naics
	* should get rid of 2 digit naics codes
	drop if missing(naics)
	drop naics_2

	* get rid of the same naics industies we dropped above
	drop if naics >= 9900 & naics < 10000
	* above 6240 consists of things like homeless shelters, not health related
	drop if naics >= 6200 & naics < 6240
	drop if naics >= 9500 & naics < 9600

	recast byte stcode 
	keep if stcode == 9 | stcode == 23 | stcode == 33 | stcode == 44 | stcode == 50 | stcode == 25
	label define states 9 "Connecticut" 23 "Maine" 33 "New Hampshire" 44 "Rhode Island" 50 "Vermont" 25 "Massachusetts"
	label variable stcode "State"
	label values stcode states	
	
	* focus on small establishments
	ren n1_4 small
	drop n*9 n1000* est
	drop emp

	* drop state wide establishments, not many of these and gets confusing with 
	* state population data
	drop if cntycd == 999
	
	* there shouldn't be any of these
	drop if cntycd == 0

	tab cntycd stcode if year == 2008

	* need to make sure each county in each state has each industry for the 
	* panel fill to work . tsfill, full won't work since some counties won't
	* have any observations of a given industry over the time period. 
	levelsof naics, local(naics_codes)
	* local naics_codes 7225
	foreach naics_code in `naics_codes' { 
		display "Expanding `naics_code'"
		count
		quietly: levelsof stcode, local(states) 
		* local states 25
		foreach state in `states' {
			quietly: levelsof cntycd if stcode == `state', local(counties)
			* local cntycd 19
			foreach county in `counties' {
				* doing this just for one year since tsfill is much more
				* efficient
				* levelsof year, local(years)
				local years 2008
				foreach year in `years' {
					quietly: count if naics == `naics_code' & stcode == `state' & cntycd == `county' & year == `year'
					if r(N) > 0 {
						assert(r(N) == 1)
						continue
					}
					quietly: gen e = 2 if _n == 1
					quietly: expand e, gen(d)
					quietly: replace naics = `naics_code' if d == 1
					quietly: replace stcode = `state' if d == 1
					quietly: replace cntycd = `county' if d == 1
					quietly: replace year = `year' if d == 1					
					quietly: replace small = 0 if d == 1
					quietly: drop e d
					quietly: count if naics == `naics_code' & stcode == `state' & cntycd == `county' & year == `year'
					assert(r(N) == 1)
				}
				
			}
		}	
	}

	* should all be 332
	tab cntycd stcode if year == 2008

	* should now be a fully balanced panel
	egen panel =  group(stcode cntycd naics)
	tsset panel year
	tsfill, full
	
	bysort panel: egen stcode_tmp = mean(stcode)
	drop stcode
	rename stcode_tmp stcode
	bysort panel: egen cntycd_tmp = mean(cntycd)
	drop cntycd
	rename cntycd_tmp cntycd	
	bysort panel: egen naics_tmp = mean(naics)
	drop naics
	rename naics_tmp naics	
	replace small = 0 if missing(small)

	* drop industries with less than 100 establishments across MA
	bysort stcode naics: egen state_small = total(small) if year == 2008
	replace state_small = . if stcode != 25
	bysort naics: egen tmp_state_small = mean(state_small)
	drop state_small
	ren temp_state_small = state_small
	drop if state_small < 100
	drop state_small

	* verifying we now have a full panel
	tsset, clear
	tsset panel year

	save $dir/tmp/fullPanel.dta, replace	

end

program define CapitalImpact

	* ??? are we propertly handling countycd == 0, statewide population data?

	use $dir/tmp/countyBusiness.dta

	* Looking at rest of New England
	* keep if stcode == 9 //stcode == 9 | stcode == 23 | stcode == 33 | stcode == 44 | stcode == 50
	* replace stcode = 25

	keep if stcode == 25
	rename naics_2 naics

	* n4_9 test whether we just reduced the firm size
        *gen variable_of_interest = n5_9
	gen variable_of_interest = n1_4
	
	* removing these for now, later need to check that 
	* there wasn't a shift downward in firm size
	drop n*9 n1000* n1_4
	
	* not using these at the moment
	drop emp
	
	*state wide establishments, not sure what to do with popluation data
	drop if cntycd == 999
	
	* drop nantucket
	* drop if (cntycd == 19 & stcode == 25)
		
	* using panel function to fill in missing years with zero data
	egen panel =  group(cntycd naics)
	tsset panel year
	tsfill, full
	sort panel
	by panel: egen naics_tmp = mean(naics)
	count if naics_tmp != naics & !missing(naics)
	assert(r(N)==0)
	drop naics
	rename naics_tmp naics
	by panel: egen cntycd_tmp = mean(cntycd)
	count if cntycd_tmp != cntycd & !missing(cntycd)
	assert(r(N)==0)
	drop cntycd
	rename cntycd_tmp cntycd
	replace variable_of_interest = 0 if missing(variable_of_interest)
	replace stcode = 25 if missing(stcode)
	
	* not necessary but checking we now have a balanced panel
	tsset, clear
	tsset panel year

	* VERIFY: each state county combination has full set of naics_2 observations
	* although may not be necessary

	* creating outcome variable

	* need n:1 rather than 1:1 since there are multiple naics 2 codes
	merge n:1 stcode cntycd year using "$dir/tmp/Population.dta"
	* ignoring county in Virgina and Florida that don't show up here
	* https://www.census.gov/geo/reference/codes/cou.html
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge
	
	* for better readability dividing population by 1000
	replace population = population / 1000000

	sort panel year	
	* getting rate of change in establishments
	gen change_in_establishments = D.variable_of_interest
	gen rate_of_change = change_in_establishments / population
	gen est_pop = variable_of_interest / population
	* using percentage change 
	* replace rate_of_change = rate_of_change / L.variable_of_interest

	* removing the health care sector to comply with theory
	drop if naics == 62

	* merging in capital measures
	* do not have naics 95 in capital data
	drop if naics == 95
	merge n:1 naics using "$dir/tmp/capital.dta"
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge
	
	/*
	
	* Abnormally unstable count numbers over time for naics 99
	bysort naics year: egen total_est = total(variable_of_interest)
	separate total_est, by(naics) shortlabel
	drop total_est
		
	graph twoway (line total_est* year, lwidth(medium ..)) ///
		, ytitle(Establishments) yscale(titlegap(3)) ylabel(, labsize(small)) xtitle(Year) xlabel(2000(4)2012, labsize(small)) legend(cols(3) size(small)) graphregion(fcolor(dimgray))
	graph2tex, epsfile("$dir/tmp/NAICS_99")
	drop total_est*
	*/
	drop if naics == 99
	
	su percent_no_funding, detail
	local upper_cutoff = r(p90)
	local lower_cutoff = `upper_cutoff'
	capture: drop low_capital
	gen low_capital = (percent_no_funding >= `upper_cutoff')
	replace low_capital = . if low_capital == 0
	replace low_capital = 0 if percent_no_funding < `lower_cutoff'

	* Leads to a 85% cutoff with p90
	* replace low_capital = 1 if naics == 22

	* Verifying we have two sets with different rates of entrepreneurship
	capture: drop total_startups
	bysort low_capital: egen total_startups = total(change_in_establishments) if year < 2008
	table low_capital, contents(mean total_startups)
		
	* DD estimate (looks like fixed effects though)
	* Using reduced form based on the BDM paper 
	* Y_ist = A_s + B_t + cX_ist + betaI_st + e_ist
	
	* individual is a county / naics combination
	* VERIFY: using this as the X_ist variable
	gen i = panel //group(cntycd naics)
	* group is whether or not they are in the low capital set
	* gen s = percent_no_funding
	gen s = low_capital
	* t is year, need to drop 2000 since we don't have a rate_of_change
	drop if year == 2000
	gen t = year
	* indicator for treatment
	* 2007 viewed as pre-treatment accroding to medical liturature
	local treatment_start 2008
	gen treat = (t >= `treatment_start') * s
	
	quietly: tab low_capital, gen(s_dummy)	
	quietly: tab year, gen(t_dummy)	
	quietly: tab i, gen(i_dummy)
	quietly: tab naics, gen(naics_dummy)
	quietly: tab cntycd, gen(cnty_dummy)

	* dropping these to remove perfect collinearity / identification issues
	* VERIFY: Something odd happening with naics dummy; perhaps one is zero for a county?
	drop s_dummy1 t_dummy1 i_dummy1  cnty_dummy1 naics_dummy1 naics_dummy2 i_dummy2
	local fixed_effects s_dummy* t_dummy* i_dummy* //naics_dummy*  cnty_dummy*
	local d_fixed_effects t_dummy* 

	sort panel year
	
	/*
	
	* Should check this for how to make a proper chart
	* http://goodliffe.byu.edu/604/protect/timeseriescausaleffects.pdf
	
	* simcoe's version of chart
	xtreg pages t_dummy* i.nver#wgDum, fe i(series) robust

	
	xtregar variable_of_interest treat, fe 
	
	exit
	
	parmby "xtreg est_pop i.year treat, fe cluster(i)", saving($dir/tmp/tmp.dta, replace) by(year)
	* parmest, saving($dir/tmp/tmp.dta, replace)
	use $dir/tmp/tmp.dta, clear
	keep if parm == "treat"
	twoway scatter (estimate min95 max95) parmseq, c(l l l) msymbol(O i i)  legend(order(1 3) lab(1 "Coefficient") lab(3 "95% CI")) xtitle(" " "Versions Since IPR Disclosure") ytitle("RFC Pages") clpattern(solid dash dash)  cmissing(n n n) xscale(range(-5 6))  

	exit
	
	*/

	* DD estimate (from Wooldrige p. 321)
	* delta_Y_it = eta_i + delta_Z_it + delta_prog_it + delta_u_it	
	gen d_rate_of_change = D.rate_of_change
	gen d_treat = D.treat
	
	gen post_year = year - `treatment_start'
	gen treat_beta = post_year * treat
	gen d_treat_beta = D.treat_beta
	
	gen single_treat = (t == `treatment_start') & (s == 1)
	gen post_treat = (t > `treatment_start') & (s == 1)
	gen d_single_treat = D.single_treat
	gen d_post_treat = D.post_treat
				
	* not sure what to do about fixed effects in this case
	* eststo cochraneOrcutt: prais rate_of_change treat `fixed_effects', cluster(i) corc rhotype(regress)
	/*
	eststo basic: regress rate_of_change treat `fixed_effects'
	eststo d_basic: regress d_rate_of_change d_treat `d_fixed_effects'
	eststo s_basic: regress rate_of_change single_treat post_treat `fixed_effects'
	eststo b_basic: regress rate_of_change treat treat_beta `fixed_effects'
	eststo db_basic: regress d_rate_of_change d_treat d_treat_beta `d_fixed_effects'
	eststo ds_basic: regress d_rate_of_change d_single_treat d_post_treat `d_fixed_effects'
	eststo robust: regress rate_of_change treat `fixed_effects', robust
	eststo d_robust: regress d_rate_of_change d_treat `d_fixed_effects', robust
	eststo s_robust: regress rate_of_change single_treat post_treat `fixed_effects', robust
	eststo b_robust: regress rate_of_change treat treat_beta `fixed_effects', robust
	eststo db_robust: regress d_rate_of_change d_treat d_treat_beta `d_fixed_effects', robust
	eststo ds_robust: regress d_rate_of_change d_single_treat d_post_treat `d_fixed_effects', robust
	*/
	* don't think i want clustered error since each individual only has one structural
	* function over multiple years
	* eststo robust_clust: regress rate_of_change treat `fixed_effects', cluster(i) robust
	* eststo d_robust_clust: regress d_rate_of_change d_treat `d_fixed_effects', cluster(i) robust
	* eststo b_robust_clust: regress rate_of_change treat treat_beta `fixed_effects', cluster(i) robust
	* eststo db_robust_clust: regress d_rate_of_change d_treat d_treat_beta `d_fixed_effects', cluster(i) robust
	* eststo clustered: regress rate_of_change treat `fixed_effects', cluster(i)
	* eststo d_clustered: regress d_rate_of_change d_treat `d_fixed_effects', cluster(i)
	* eststo b_clustered: regress rate_of_change treat treat_beta `fixed_effects', cluster(i)
	* eststo db_clustered: regress d_rate_of_change d_treat d_treat_beta `d_fixed_effects', cluster(i)
	
	* DD estimate (from Wooldrige p. 321)
	* doesn't seem right since we only test whether 2006 -> 2007 makes a 
	* difference
	* delta_Y_it = eta_i + delta_Z_it + delta_prog_it + delta_u_it
	* gen delta_y_it = D.rate_of_change
	* z_it here is null since other charactartists are fixed over t
	* gen delta_treat = D.treat
	* eststo wooldrige: regress delta_y_it delta_treat t_dummy*, cluster(i)
	* eststo gmm: gmm (rate_of_change - {xb:treat `fixed_effects'} - {b0}), instruments(treat `fixed_effects') wmatrix(cluster i) //igmm winit(id) conv_maxiter(5)
	* eststo gmm: ivreg2 rate_of_change treat `fixed_effects', gmm2s cluster(i)

	* testing for autocorrelation to justify newey-west errors
	xtserial rate_of_change treat `fixed_effects'
	
	* xtserial d_rate_of_change d_treat `d_fixed_effects'
	* xtserial d_rate_of_change d_single_treat d_post_treat `d_fixed_effects'
	//xtserial D.rate_of_change D.treat `d_fixed_effects'
	* quietly: eststo neweyWest: newey2 rate_of_change treat `fixed_effects', lag(2) force
	quietly: eststo xtreg: xtreg rate_of_change treat `fixed_effects', fe robust cluster(naics)
	* eststo b_neweyWest: newey2 rate_of_change treat treat_beta `fixed_effects', lag(2)	
	* eststo b_xtreg: xtreg rate_of_change treat treat_beta `fixed_effects', fe robust
	
	quietly: eststo s_neweyWest: newey2 rate_of_change single_treat post_treat `fixed_effects', lag(2) force
	test single_treat=post_treat
	quietly: eststo s_xtreg: xtreg rate_of_change single_treat post_treat `fixed_effects', fe robust cluster(naics)
	test single_treat=post_treat
	
	* eststo d_neweyWest: newey2 d_rate_of_change d_treat `d_fixed_effects', lag(2)
	* eststo db_neweyWest: newey2 d_rate_of_change d_treat d_treat_beta `d_fixed_effects', lag(2)
	* eststo ds_neweyWest: newey2 d_rate_of_change d_single_treat d_post_treat `d_fixed_effects', lag(2)
	* esttab, mtitles  keep(treat delta_treat) nonumbers replace compress se


	* esttab, mtitles  keep(treat d_treat treat_beta d_treat_beta single_treat post_treat d_single_treat d_post_treat) nonumbers replace compress se
	* 
	esttab ///
		, mtitles("Prop 1 NW" "Prop 1 FE" "Prop 2 NW" "Prop 2 FE")   ///
		rename(_cons constant treat treatment single_treat initialTreatment post_treat postTreatment) ///
		keep(constant treatment initialTreatment postTreatment)  ///
		order(constant treatment initialTreatment postTreatment) ///
		nonumbers replace compress se  b(3) starlevels(* 0.10 ** 0.05 *** 0.01 **** 0.001)
		
	esttab using $dir/tmp/results.tex ///
		, mtitles("Prop 1 NW" "Prop 1 FE" "Prop 2 NW" "Prop 2 FE")   ///
		rename(_cons constant treat treatment single_treat initialTreatment post_treat postTreatment) ///
		keep(constant treatment initialTreatment postTreatment)  ///
		order(constant treatment initialTreatment postTreatment) ///
		nonumbers replace compress se  b(3) starlevels(* 0.10 ** 0.05 *** 0.01 **** 0.001)


	* charting impact of taking out fixed effects but leaving the treatment
	quietly: newey2 rate_of_change treat `fixed_effects', lag(2) force
	local treatment_effect = _b[treat]
	predict res, residuals
	gen no_treat = res + `treatment_effect' * treat
	GraphPaper no_treat `treatment_start' s 1
		
	* testing for normality in the residuals seems to fail
	* sktest res
	* swilk res
	* sfrancia is for 5 to 5000 observations according to stata manual
	sfrancia res
	* stem res 
	* dotplot res
	* graph box res  
	* histogram res
	* pnorm res  
	* qnorm res  
	
	* highly centerered around zero with some positive skewness
	* VERIFY: think this means inference will have larger CI than necessary
	su res, detail
	
	* end DD estimate

	exit

	//quietly: tab cntycd, gen(county_dummy)
	quietly: tab naics, gen(naics_dummy)
	* missing data for this year
	//drop if year == 2000
	quietly: tab year, gen(year_dummy)

	local fixed_effects year_dummy* 
	
	* dummy for treatment
	gen treatment = (year >= 2007) & (low_capital == 1)
	
	* interaction term
	gen t_low = treatment * low_capital
	
	keep if year < 2007
	drop if year == 2000
	
	* running no constant since we are modeling the rate as zero after all the 
	* fixed effects are taken care of
	* eststo: regress rate_of_change treatment t_kapital low_capital `fixed_effects'
	eststo: regress rate_of_change //`fixed_effects'
	predict res, r
	plot res year	
	
	egen tmp_y_bar_1_1 = mean(rate_of_change) if year < 2007 & low_capital == 0
	egen y_bar_1_1 = mean(tmp_y_bar_1_1)
	egen tmp_y_bar_2_1 = mean(rate_of_change) if year < 2007 & low_capital == 1
	egen y_bar_2_1 = mean(tmp_y_bar_2_1)
	egen tmp_y_bar_1_2 = mean(rate_of_change) if year >= 2007 & low_capital == 0
	egen y_bar_1_2 = mean(tmp_y_bar_1_2)
	egen tmp_y_bar_2_2 = mean(rate_of_change) if year >= 2007 & low_capital == 1
	egen y_bar_2_2 = mean(tmp_y_bar_2_2)
	drop tmp_y_bar*
	gen delta = (y_bar_1_1 - y_bar_1_2) - (y_bar_2_1 - y_bar_2_2)
	gen delta_alt =  (y_bar_2_2 - y_bar_2_1) - (y_bar_1_2 - y_bar_1_1)

	replace year = 0 if year < 2007
	replace year = 1 if year >= 2007	
	gen t_s = year * low_capital
	regress rate_of_change year low_capital t_s

	
	esttab, mtitles  keep(treatment) nonumbers replace compress se
	eststo clear

	gen t_percent = treatment * percent_no_funding

	eststo: regress est_pop treatment t_percent percent_no_funding `fixed_effects'
	esttab, mtitles  keep(treatment t_percent percent_no_funding) nonumbers replace compress se
	eststo clear

	/*

	* running fixed effect model

	quietly: tab cntycd, gen(county_dummy)
	* this naics has really high percent_no_funding
	* but removing it kills all the effect
	* drop if naics == 99
	quietly: tab naics, gen(naics_dummy)
	* missing data for this year
	drop if year == 2000
	quietly: tab year, gen(year_dummy)

	local fixed_effects county_dummy* naics_dummy* year_dummy*
	
	* dummy for treatment
	gen treatment = 0
	replace treatment = 1 if stcode == 25 & year >= 2007
	
	* interaction term
	gen t_kapital = treatment * percent_no_funding
	
	eststo: regress rate_of_change treatment percent_no_funding t_kapital `fixed_effects'
	esttab, mtitles  keep(treatment percent_no_funding t_kapital) nonumbers replace compress se

	*/

end



program define SummaryStatistics

	use $dir/tmp/countyBusiness.dta
	drop if missing(naics_2)
	drop naics_4
	ren naics_2 naics

	drop if naics == 99 | naics == 95

	* get the total number of industries
        bysort naics: gen nvals = _n == 1 	
	count if nvals
	local naics_count = r(N)
	drop nvals

	* First create a high level table without naics detail
	recast byte stcode 
	keep if stcode == 9 | stcode == 23 | stcode == 33 | stcode == 44 | stcode == 50 | stcode == 25
	label define states 9 "Connecticut" 23 "Maine" 33 "New Hampshire" 44 "Rhode Island" 50 "Vermont" 25 "Massachusetts"
	label variable stcode "State"
	label values stcode states	
		
	* work backwards to get the total number of establishments
	bysort year stcode: egen small = sum(n1_4)
	bysort year stcode: egen est_tmp = sum(est)
	keep year stcode small est_tmp
	ren est_tmp est
	duplicates drop year stcode small est, force

	* want to match with the state population
	gen cntycd = 0	
	merge 1:1 stcode cntycd year using "$dir/tmp/Population.dta"
	* ignoring county in Virgina and Florida that don't show up here
	* https://www.census.gov/geo/reference/codes/cou.html
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge
	
	* Need to treat rest of NE as a single state
	replace stcode = 0 if stcode != 25
	bysort year stcode: egen small_tmp = sum(small)
	bysort year stcode: egen est_tmp = sum(est)
	bysort year stcode: egen population_tmp = sum(population)
	drop small est population
	ren small_tmp small
	ren est_tmp est
	ren population_tmp population
	duplicates drop year stcode small est population, force	

	* creating panel so we can look at the rate of new firm creation
	tsset stcode year

	* calculating everything per million people
	local scale 1000000

	gen ratio = small / est
	gen est_pop = est / (population / `scale')
	gen small_pop = small / (population / `scale')
	gen d_small_pop = D.small_pop
	gen percent_change = d_small_pop / L.small_pop
	gen d_small_pop_i = d_small_pop / `naics_count'

	gen treatment = (year > 2007)

	!rm $dir/tmp/basic_summary.tex
	format population %12.0f
	* matrix m = (0,0,0,0,0,0)
	matrix m = (0,0,0,0)
	* foreach variable of varlist population est small ratio est_pop small_pop d_small_pop{	
	foreach variable of varlist population est small ratio est_pop small_pop percent_change d_small_pop d_small_pop_i{	
		su `variable' if stcode == 25 & !treatment
		local mass_pre = r(mean)
		su `variable' if stcode == 25 & treatment
		local mass_post = r(mean)
		local mass_diff = `mass_post' - `mass_pre'
		su `variable' if stcode != 25 & !treatment
		local ne_pre = r(mean)
		su `variable' if stcode != 25 & treatment
		local ne_post = r(mean)
		local ne_diff = `ne_post' - `ne_pre'
		matrix o = (`mass_pre', `mass_post', `ne_pre', `ne_post')
		* matrix o = (`mass_pre', `mass_post', `mass_diff',`ne_pre', `ne_post', `ne_diff')
		matrix m = m\o
		matrix rownames o = "`variable'"
		local format %12.0fc
		if `variable' == est_pop | `variable' == small_pop | `variable' == ratio | `variable' == d_small_pop local format %12.2f
		if `variable' == percent_change local format %12.4f
		outtable using $dir/tmp/basic_summary, mat(o) append nobox format(`format')
	}
	
	matrix m = m[2...,1...]
	matrix list m	
	
	* now redo this by industry

	use $dir/tmp/countyBusiness.dta, clear
	drop if missing(naics_2)
	drop naics_4
	
	drop if naics == 99 | naics == 95

	recast byte stcode 
	keep if stcode == 9 | stcode == 23 | stcode == 33 | stcode == 44 | stcode == 50 | stcode == 25
	label define states 9 "Connecticut" 23 "Maine" 33 "New Hampshire" 44 "Rhode Island" 50 "Vermont" 25 "Massachusetts"
	label variable stcode "State"
	label values stcode states	
	
	* focus on small establishments
	drop n*9 n1000* est
	drop emp
	
	* work backwards to get the total number of establishments by state by naics
	ren naics_2 naics
	bysort year stcode naics: egen small = sum(n1_4)
	keep year stcode small naics
	duplicates drop year stcode small naics, force
	
	* using panel function to fill in missing years with naics zero data
	egen panel =  group(stcode naics)
	tsset panel year
	tsfill, full
	sort panel
	by panel: egen naics_tmp = mean(naics)
	count if naics_tmp != naics & !missing(naics)
	assert(r(N)==0)
	drop naics
	rename naics_tmp naics
	by panel: egen stcode_tmp = mean(stcode)
	count if stcode_tmp != stcode & !missing(stcode)
	assert(r(N)==0)
	drop stcode
	rename stcode_tmp stcode
	replace small = 0 if missing(small)
	count if missing(stcode)
	assert(r(N)==0)

	tsset, clear
	drop panel
	
	* next match with the state population
	gen cntycd = 0	
	* each naics will have a seperate row
	merge n:1 stcode cntycd year using "$dir/tmp/Population.dta"
	* ignoring county in Virgina and Florida that don't show up here
	* https://www.census.gov/geo/reference/codes/cou.html
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge				
	
	* Need to treat rest of NE as a single state
	replace stcode = 0 if stcode != 25
	bysort year naics stcode: egen small_tmp = sum(small)
	bysort year naics stcode: egen population_tmp = sum(population)
	drop small population
	ren small_tmp small
	ren population_tmp population
	duplicates drop year naics stcode small population, force	

	gen small_pop = small / (population / `scale')
	gen treatment = (year > 2007)	

	* redo the panel with the two regions
	drop cntycd
	egen panel = group(stcode naics)
	tsset panel year	
	gen d_small_pop = D.small_pop
	gen percent_change = d_small_pop / small_pop
	
	label define naics_codes ///
		11 "Agriculture, Forestry, Fishing and Hunting" ///
		21 "Mining, Quarrying, and Oil and Gas Extraction" ///
		22 "Utilities" ///
		23 "Construction" ///
		31 "Manufacturing" ///
		32 "Manufacturing" ///
		33 "Manufacturing" ///
		42 "Wholesale Trade" ///
		44 "Retail Trade" ///
		45 "Retail Trade" ///
		48 "Transportation and Warehousing" ///
		49 "Transportation and Warehousing" ///
		51 "Information" ///
		52 "Finance and Insurance" ///
		53 "Real Estate and Rental and Leasing" ///
		54 "Professional, Scientific and Technical Services" ///
		55 "Management of Companies and Enterprises" ///
		56 "Administrative and Support and Waste Management and Remediation Services" ///
		61 "Educational Services" ///
		62 "Health Care and Social Assistance" ///
		71 "Arts, Entertainment, and Recreation" ///
		72 "Accommodation and Food Services" ///
		81 "Other Services, except Public Administration" ///
		92 "Public Administration" ///
		99 "Unclassified"
	
	recast byte naics
	label variable naics "Naics Industries"
	label values naics naics_codes	
	
	* local variable d_small_pop
	local variable percent_change
	
	!rm $dir/tmp/naics_summary.tex
	* matrix m = (0,0,0,0,0,0)
	matrix m = (0,0,0,0)
	levelsof naics, local(naics_codes)
	foreach naics_code in `naics_codes' { 
		su `variable' if stcode == 25 & !treatment & naics == `naics_code'
		local mass_pre = r(mean)
		su `variable' if stcode == 25 & treatment & naics == `naics_code'
		local mass_post = r(mean)
		local mass_diff = `mass_post' - `mass_pre'
		su `variable' if stcode != 25 & !treatment & naics == `naics_code'
		local ne_pre = r(mean)
		su `variable' if stcode != 25 & treatment & naics == `naics_code'
		local ne_post = r(mean)
		local ne_diff = `ne_post' - `ne_pre'
		* matrix o = (`mass_pre', `mass_post', `mass_diff',`ne_pre', `ne_post', `ne_diff')
		matrix o = (`mass_pre', `mass_post', `ne_pre', `ne_post')
		matrix rownames o = "`naics_code'"
		matrix m = m\o
	}
	
	* do a total row
	mat o = J(rowsof(m),1,1)
	mat o = o'*m
	matrix rownames o = "Total"
	matrix m = m\o	
	
	matrix m = m[2...,1...]
	matrix list m	
	outtable using $dir/tmp/naics_summary, mat(m) replace nobox format(%12.4f)
	
	* county version of across industries
	use $dir/tmp/countyBusiness.dta, clear
	drop if missing(naics_2)
	drop naics_4
	ren naics_2 _naics
	ren n1_4 small
	drop n* est emp
	ren _naics naics

	drop if naics == 99 | naics == 95

	recast byte stcode 
	keep if stcode == 9 | stcode == 23 | stcode == 33 | stcode == 44 | stcode == 50 | stcode == 25
	label define states 9 "Connecticut" 23 "Maine" 33 "New Hampshire" 44 "Rhode Island" 50 "Vermont" 25 "Massachusetts"
	label variable stcode "State"
	label values stcode states	

	* drop state wide counties
	drop if cntycd == 999 | cntycd == 0

	merge n:1 stcode cntycd year using "$dir/tmp/Population.dta"
	* ignoring county in Virgina and Florida that don't show up here
	* https://www.census.gov/geo/reference/codes/cou.html
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge

	* merge across NAICS
	bysort year stcode cntycd: egen small_tmp = sum(small)
	drop small naics
	ren small_tmp small
	duplicates drop year stcode cntycd small population, force	

	* creating panel so we can look at the rate of new firm creation
	egen panel = group(stcode cntycd)
	tsset panel year

	gen small_pop = small / (population / `scale')
	gen d_small_pop = D.small_pop
	gen percent_change = d_small_pop / L.small_pop

	local variable percent_change
	gen treatment = (year > 2007)
	
	!rm $dir/tmp/county_summary.tex
	* matrix m = (0,0,0,0,0,0)
	matrix m = (0,0,0,0,0)
	levelsof stcode, local(states)
	foreach state in `states' { 
		levelsof cntycd if stcode == `state', local(counties)
		foreach county in `counties' { 
			su `variable' if stcode == `state' & cntycd == `county' & !treatment
			local mass_pre = r(mean)
			su `variable' if stcode == `state' & cntycd == `county' & treatment
			local mass_post = r(mean)
			local mass_diff = `mass_post' - `mass_pre'
			matrix o = (`state', `county', `mass_pre', `mass_post', `mass_diff')
			matrix rownames o = "`state' : `county'"
			matrix m = m\o
		}
	}
	
	* do a total row
	mat o = J(rowsof(m),1,1)
	mat o = o'*m
	matrix rownames o = "Total"
	matrix m = m\o	
	
	matrix m = m[2...,1...]
	matrix list m	
	outtable using $dir/tmp/county_summary, mat(m) replace nobox format(%12.4f)
end

program define Kickstarter
	import delimited using "$dir/Data/kickstarter.csv", rowrange(4) varnames(3)
	keep if currentstate == "live"
	replace goal = goal * 0.76 if currency == "AUD"
	replace goal = goal * 0.80 if currency == "CAD"
	replace goal = goal * 0.15 if currency == "DKK"
	replace goal = goal * 1.09 if currency == "EUR"
	replace goal = goal * 1.48 if currency == "GBP"
	replace goal = goal * 0.13 if currency == "NOK"
	replace goal = goal * 0.75 if currency == "NZD"
	replace goal = goal * 0.12 if currency == "SEK"
	keep parentcategory parentcategoryid goal
	ren parentcategory category
	ren parentcategoryid categoryid 
	
	drop if goal > 200000
	
	su goal
	local sigma_hat = r(sd)
	local count = r(N)
	local max = r(max)
	local bw = 2.34 * `sigma_hat' * (`count' ^ (-1/5))
	
	* kdensity goal, k(ep) bw(`bw')	

	kdens goal
	graph2tex, epsfile("$dir/tmp/kickstarter")

	exit

	
	kdens goal, addplot( ///
			kdens goal if categoryid == 1 || ///
			kdens goal if categoryid == 3 || ///
			kdens goal if categoryid == 6 || ///
			kdens goal if categoryid == 7 || ///
			kdens goal if categoryid == 9 || ///
			kdens goal if categoryid == 10 || ///
			kdens goal if categoryid == 11 || ///
			kdens goal if categoryid == 12 || ///
			kdens goal if categoryid == 13 || ///
			kdens goal if categoryid == 14 || ///
			kdens goal if categoryid == 15 || ///
			kdens goal if categoryid == 16 || ///
			kdens goal if categoryid == 17 || ///
			kdens goal if categoryid == 18 || ///
			kdens goal if categoryid == 26 ///
		) ///
	
end

program define TestWeights

	* first run is with just mass versus rest of new england as one state
	use $dir/tmp/countyBusiness.dta
	drop if naics == 99 | naics == 95

	* First create a high level table without naics detail
	recast byte stcode 
	keep if stcode == 9 | stcode == 23 | stcode == 33 | stcode == 44 | stcode == 50 | stcode == 25
	label define states 9 "Connecticut" 23 "Maine" 33 "New Hampshire" 44 "Rhode Island" 50 "Vermont" 25 "Massachusetts"
	label variable stcode "State"
	label values stcode states	
		
	* work backwards to get the total number of small establishments
	bysort year stcode: egen small = sum(n1_4)
	keep year stcode small
	duplicates drop year stcode small, force

	* want to match with the state population
	gen cntycd = 0	
	merge 1:1 stcode cntycd year using "$dir/tmp/Population.dta"
	* ignoring county in Virgina and Florida that don't show up here
	* https://www.census.gov/geo/reference/codes/cou.html
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge
	
	* Need to treat rest of NE as a single state
	replace stcode = 0 if stcode != 25
	bysort year stcode: egen small_tmp = sum(small)
	bysort year stcode: egen population_tmp = sum(population)
	drop small population
	ren small_tmp small
	ren population_tmp population
	duplicates drop year stcode small population, force	

	* creating panel so we can look at the rate of new firm creation
	tsset stcode year

	* calculating everything per million people
	local scale 1000000

	gen small_pop = small / (population / `scale')
	gen d_small_pop = D.small_pop
	gen percent_change = d_small_pop / L.small_pop
	replace percent_change = percent_change * 100

	local treatment_start 2008
	local treatment_group 25
	gen treatment_group =  stcode == `treatment_group'
	gen treatment = (year >= `treatment_start') & (treatment_group)

	gen weight_tmp = population if year == `treatment_start'
	bysort stcode: egen weight = mean(weight_tmp)
	drop weight_tmp

	local fixed_effects ib2008.year ib0.treatment_group
	 eststo: xtreg percent_change treatment `fixed_effects', fe robust cluster(stcode)
	quietly: eststo: xtreg percent_change treatment `fixed_effects' [aw=weight], fe robust cluster(stcode)

	* next do mass versus each state seperately
	use $dir/tmp/countyBusiness.dta, clear
	drop if naics == 99 | naics == 95

	* First create a high level table without naics detail
	recast byte stcode 
	keep if stcode == 9 | stcode == 23 | stcode == 33 | stcode == 44 | stcode == 50 | stcode == 25
	label define states 9 "Connecticut" 23 "Maine" 33 "New Hampshire" 44 "Rhode Island" 50 "Vermont" 25 "Massachusetts"
	label variable stcode "State"
	label values stcode states	
		
	* work backwards to get the total number of establishments
	bysort year stcode: egen small = sum(n1_4)
	keep year stcode small
	duplicates drop year stcode small, force

	* want to match with the state population
	gen cntycd = 0	
	merge 1:1 stcode cntycd year using "$dir/tmp/Population.dta"
	* ignoring county in Virgina and Florida that don't show up here
	* https://www.census.gov/geo/reference/codes/cou.html
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge
	
	* creating panel so we can look at the rate of new firm creation
	tsset stcode year

	* calculating everything per million people
	local scale 1000000

	gen small_pop = small / (population / `scale')
	gen d_small_pop = D.small_pop
	gen percent_change = d_small_pop / L.small_pop
	replace percent_change = percent_change * 100

	local treatment_start 2008
	local treatment_group 25
	gen treatment_group =  stcode == `treatment_group'
	gen treatment = (year >= `treatment_start') & (treatment_group)

	gen weight_tmp = population if year == `treatment_start'
	bysort stcode: egen weight = mean(weight_tmp)
	drop weight_tmp
	
	local fixed_effects ib2008.year ib0.treatment_group
	quietly: eststo: xtreg percent_change treatment `fixed_effects', fe robust cluster(stcode)	
	quietly: eststo: xtreg percent_change treatment `fixed_effects' [aw=weight], fe robust cluster(stcode)	

	esttab, ///
		mtitles("Pool" "AW" "State" "AW" "County" "AW" "Naics" "AW" "N-C" "AW")   ///
		nobaselevels nonumbers replace compress se  b(3) starlevels(* 0.10 ** 0.05 *** 0.01 **** 0.001)

	exit

	* now by county
	use $dir/tmp/countyBusiness.dta, clear
	drop if naics == 99 | naics == 95
	drop if cntycd == 999

	* First create a high level table without naics detail
	recast byte stcode 
	keep if stcode == 9 | stcode == 23 | stcode == 33 | stcode == 44 | stcode == 50 | stcode == 25
	label define states 9 "Connecticut" 23 "Maine" 33 "New Hampshire" 44 "Rhode Island" 50 "Vermont" 25 "Massachusetts"
	label variable stcode "State"
	label values stcode states	
		
	* work backwards to get the total number of establishments
	bysort year stcode cntycd: egen small = sum(n1_4)
	bysort year stcode cntycd: egen est_tmp = sum(est)
	keep year stcode cntycd small est_tmp
	ren est_tmp est
	duplicates drop year stcode cntycd small est, force

	* want to match with the state population
	merge 1:1 stcode cntycd year using "$dir/tmp/Population.dta"
	* ignoring county in Virgina and Florida that don't show up here
	* https://www.census.gov/geo/reference/codes/cou.html
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge
	
	* creating panel so we can look at the rate of new firm creation
	egen panel = group(stcode cntycd)
	tsset panel year

	* calculating everything per million people
	local scale 1000000

	gen ratio = small / est
	gen est_pop = est / (population / `scale')
	gen small_pop = small / (population / `scale')
	gen d_small_pop = D.small_pop
	gen percent_change = d_small_pop / L.small_pop
	replace percent_change = percent_change * 100

	local treatment_start 2008
	local treatment_group 25
	gen treatment = (year >= `treatment_start') & stcode == `treatment_group'

	gen weight_tmp = population if year == `treatment_start'
	bysort stcode: egen weight = mean(weight_tmp)
	drop weight_tmp
	
	local fixed_effects ib25.stcode#i.cntycd ib25.stcode ib2008.year
	* eststo xtreg: xtreg diff_small_pop treatment `fixed_effects', fe robust cluster(naics)
	* eststo xtreg_nan: xtreg diff_small_pop treatment `fixed_effects' if !(stcode == 25 & cntycd == 19), fe robust cluster(naics)
	quietly: eststo: xtreg percent_change treatment `fixed_effects', fe robust cluster(panel)	
	quietly: eststo: xtreg percent_change treatment `fixed_effects' [aw=weight], fe robust cluster(panel)	
	* quietly: eststo: xtreg percent_change treatment `fixed_effects' [pw=weight], fe robust cluster(panel)	
	* quietly: eststo: xtreg percent_change treatment `fixed_effects' [fw=weight], fe robust cluster(stcode)	

	* now by naics
	use $dir/tmp/countyBusiness.dta, clear
	drop if naics == 99 | naics == 95
	drop if cntycd == 999 | cntycd == 0

	recast byte stcode 
	keep if stcode == 9 | stcode == 23 | stcode == 33 | stcode == 44 | stcode == 50 | stcode == 25
	label define states 9 "Connecticut" 23 "Maine" 33 "New Hampshire" 44 "Rhode Island" 50 "Vermont" 25 "Massachusetts"
	label variable stcode "State"
	label values stcode states	
		
	* work backwards to get the total number of establishments
	bysort year stcode naics: egen small = sum(n1_4)
	bysort year stcode naics: egen est_tmp = sum(est)
	keep year stcode naics small est_tmp
	ren est_tmp est
	duplicates drop year stcode naics small est, force

	gen cntycd = 0
	* want to match with the state population
	merge n:1 stcode cntycd year using "$dir/tmp/Population.dta"
	* ignoring county in Virgina and Florida that don't show up here
	* https://www.census.gov/geo/reference/codes/cou.html
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge
	
	* creating panel so we can look at the rate of new firm creation
	egen panel = group(stcode naics)
	tsset panel year

	* calculating everything per million people
	local scale 1000000

	gen ratio = small / est
	gen est_pop = est / (population / `scale')
	gen small_pop = small / (population / `scale')
	gen d_small_pop = D.small_pop
	gen percent_change = d_small_pop / L.small_pop
	replace percent_change = percent_change * 100

	local treatment_start 2008
	local treatment_group 25
	gen treatment = (year >= `treatment_start') & stcode == `treatment_group'

	gen weight_tmp = population if year == `treatment_start'
	bysort stcode: egen weight = mean(weight_tmp)
	drop weight_tmp
	
	local fixed_effects ib25.stcode#i.naics ib25.stcode ib2008.year
	* eststo xtreg: xtreg diff_small_pop treatment `fixed_effects', fe robust cluster(naics)
	* eststo xtreg_nan: xtreg diff_small_pop treatment `fixed_effects' if !(stcode == 25 & cntycd == 19), fe robust cluster(naics)
	quietly: eststo: xtreg percent_change treatment `fixed_effects', fe robust cluster(panel)	
	quietly: eststo: xtreg percent_change treatment `fixed_effects' [aw=weight], fe robust cluster(panel)	
	* quietly: eststo: xtreg percent_change treatment `fixed_effects' [pw=weight], fe robust cluster(panel)	
	* quietly: eststo: xtreg percent_change treatment `fixed_effects' [fw=weight], fe robust cluster(stcode)	
	

	* finally both naics and county codes
	use $dir/tmp/countyBusiness.dta, clear
	ren naics_2 naics
	drop if naics == 99 | naics == 95
	drop if cntycd == 999 | cntycd == 0

	recast byte stcode 
	keep if stcode == 9 | stcode == 23 | stcode == 33 | stcode == 44 | stcode == 50 | stcode == 25
	label define states 9 "Connecticut" 23 "Maine" 33 "New Hampshire" 44 "Rhode Island" 50 "Vermont" 25 "Massachusetts"
	label variable stcode "State"
	label values stcode states	
		
	* work backwards to get the total number of establishments
	bysort year stcode cntycd naics: egen small = sum(n1_4)
	bysort year stcode cntycd naics: egen est_tmp = sum(est)
	keep year stcode cntycd naics small est_tmp
	ren est_tmp est
	duplicates drop year stcode cntycd naics small est, force
	
	* creating panel since not all counties with have all naics
	egen panel = group(stcode cntycd naics)
	tsset panel year
	tsfill, full
	sort panel
	by panel: egen naics_tmp = mean(naics)
	count if naics_tmp != naics & !missing(naics)
	assert(r(N)==0)
	drop naics
	rename naics_tmp naics
	by panel: egen stcode_tmp = mean(stcode)
	count if stcode_tmp != stcode & !missing(stcode)
	assert(r(N)==0)
	drop stcode
	rename stcode_tmp stcode
	by panel: egen cntycd_tmp = mean(cntycd)
	count if cntycd_tmp != cntycd & !missing(cntycd)
	assert(r(N)==0)
	drop cntycd
	rename cntycd_tmp cntycd
	replace small = 0 if missing(small)
	count if missing(stcode)
	assert(r(N)==0)

	* want to match with the state population
	merge n:1 stcode cntycd year using "$dir/tmp/Population.dta"
	* ignoring county in Virgina and Florida that don't show up here
	* https://www.census.gov/geo/reference/codes/cou.html
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge

	* calculating everything per million people
	local scale 1000000

	sort panel year
	gen ratio = small / est
	gen est_pop = est / (population / `scale')
	gen small_pop = small / (population / `scale')
	gen d_small_pop = D.small_pop
	gen percent_change = d_small_pop / L.small_pop
	replace percent_change = percent_change * 100

	local treatment_start 2008
	local treatment_group 25
	gen treatment = (year >= `treatment_start') & stcode == `treatment_group'

	gen weight_tmp = population if year == `treatment_start'
	bysort stcode: egen weight = mean(weight_tmp)
	drop weight_tmp
	
	local fixed_effects ib25.stcode#i.cntycd i.naics ib25.stcode ib2008.year
	* eststo xtreg: xtreg diff_small_pop treatment `fixed_effects', fe robust cluster(naics)
	* eststo xtreg_nan: xtreg diff_small_pop treatment `fixed_effects' if !(stcode == 25 & cntycd == 19), fe robust cluster(naics)
	quietly: eststo: xtreg percent_change treatment `fixed_effects', fe robust cluster(panel)	
	quietly: eststo: xtreg percent_change treatment `fixed_effects' [aw=weight], fe robust cluster(panel)	
	* quietly: eststo: xtreg percent_change treatment `fixed_effects' [pw=weight], fe robust cluster(panel)	
	* quietly: eststo: xtreg percent_change treatment `fixed_effects' [fw=weight], fe robust cluster(stcode)	

	* mtitles("None" "AW" "PW" "FW" "State" "AW" "PW" "FW")   ///

	esttab, ///
		mtitles("None" "AW" "State" "AW" "County" "AW" "Naics" "AW" "N-C" "AW")   ///
		nobaselevels nonumbers replace compress se  b(3) starlevels(* 0.10 ** 0.05 *** 0.01 **** 0.001)

	

end

program define SummaryStatisticsLong

	* First create table of MA as treatment
	* y_ct is new firms per county

	use $dir/tmp/countyBusiness.dta

	recast byte stcode 
	keep if stcode == 9 | stcode == 23 | stcode == 33 | stcode == 44 | stcode == 50 | stcode == 25
	label define states 9 "Connecticut" 23 "Maine" 33 "New Hampshire" 44 "Rhode Island" 50 "Vermont" 25 "Massachusetts"
	label variable stcode "State"
	label values stcode states	
	
	gen treated = stcode == 25

	matrix m = (.,.,.,.,.)
	matrix ma = (.,.,.,.,.)
	matrix ne = (.,.,.,.,.)
	matrix fp = (.,.,.,.,.)
	matrix np = (.,.,.,.,.)
	matrix hc = (.,.,.,.,.)
	matrix lc = (.,.,.,.,.)	
	matrix colnames m = N Mean SD Min Max
	local scale 1000000
	
	* county count
	bysort stcode cntycd: gen nval = _n == 1
	count if nval
	local county_count = r(N)
	matrix o = (`county_count', ., ., ., .)
	matrix m = m\o

	count if nval & stcode == 25
	local ma_county_count = r(N)
	matrix o = (`ma_county_count', ., ., ., .)
	matrix ma = ma\o

	count if nval & stcode != 25
	local ne_county_count = r(N)
	matrix o = (`ne_county_count', ., ., ., .)
	matrix ne = ne\o

	drop nval	
	
	* naics 2 industry count
	drop if naics_2 == 99 | naics_2 == 95 | naics_2 == 62 | naics_2 == 0
	bysort naics_2: gen nval = _n == 1  & !missing(naics_2)
	count if nval
	local naics_2_count = r(N)
	drop nval
	matrix o = (`naics_2_count', ., ., ., .)
	matrix m = m\o
	
	* naics 4 industry count
	preserve
	use $dir/tmp/fullPanel.dta, clear
	
	merge n:1 naics using $dir/tmp/nonprofit.dta
	* don't expect all naics to exist int he nonprofit data
	keep if _merge == 3
	drop _merge					

	gen nonprofit = (!missing(percent_nonprofit) & percent_nonprofit >= .5)
	drop percent_nonprofit naicsdisplaylabel	

	bysort naics: gen nval = _n == 1
	count if nval & !missing(nonprofit)
	local naics_4_count = r(N)
	matrix o = (`naics_4_count', ., ., ., .)
	matrix m = m\o	
	
	count if nval & nonprofit
	local np_naics_4_count = r(N)
	matrix o = (`np_naics_4_count', ., ., ., .)
	matrix np = np\o	

	count if nval & !nonprofit
	local fp_naics_4_count = r(N)
	matrix o = (`fp_naics_4_count', ., ., ., .)
	matrix fp = fp\o	

	drop nval
	
	restore
	* years
	bysort year: gen nval = _n == 1
	count if nval
	local year_count = r(N)
	drop nval
	su year
	matrix o = (`year_count', ., ., r(min), r(max))
	matrix m = m\o	
	
	* new firms t
	preserve 
	drop if missing(naics_2)
	drop naics_4
	bysort year stcode: egen small = sum(n1_4)
	keep year stcode small
	duplicates drop year stcode small, force
	
	gen cntycd = 0
	merge 1:1 stcode cntycd year using "$dir/tmp/Population.dta"
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge

	tsset stcode year
	gen small_pop = small / (population / `scale')
	gen d_small_pop = D.small_pop
		
	su d_small_pop
	matrix o = (r(N), r(mean), r(sd), r(min), r(max))
	matrix m = m\o	

	su d_small_pop if stcode == 25
	matrix o = (r(N), r(mean), r(sd), r(min), r(max))
	matrix ma = ma\o	

	su d_small_pop if stcode != 25
	matrix o = (r(N), r(mean), r(sd), r(min), r(max))
	matrix ne = ne\o		

	* create weights
	gen weight_tmp = population if year == 2008
	bysort stcode: egen weight = mean(weight_tmp)
	drop weight_tmp

	su d_small_pop [aw=weight]
	matrix o = (r(N), r(mean), r(sd), r(min), r(max))
	matrix m = m\o		

	su d_small_pop [aw=weight] if stcode == 25
	matrix o = (r(N), r(mean), r(sd), r(min), r(max))
	matrix ma = ma\o	

	su d_small_pop [aw=weight] if stcode != 25
	matrix o = (r(N), r(mean), r(sd), r(min), r(max))
	matrix ne = ne\o		
	
	restore

	* new firms ct
	preserve 
	drop if missing(naics_2)
	drop naics_4
	bysort year cntycd stcode: egen small = sum(n1_4)
	keep year stcode cntycd small
	duplicates drop year stcode cntycd small, force
	
	drop if cntycd == 999
	merge 1:1 stcode cntycd year using "$dir/tmp/Population.dta"
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge
	
	egen panel = group(stcode cntycd)
	tsset panel year
	gen small_pop = small / (population / `scale')
	gen d_small_pop = D.small_pop

	su d_small_pop
	matrix o = (r(N), r(mean), r(sd), r(min), r(max))
	matrix m = m\o		

	su d_small_pop if stcode == 25
	matrix o = (r(N), r(mean), r(sd), r(min), r(max))
	matrix ma = ma\o	

	su d_small_pop if stcode != 25
	matrix o = (r(N), r(mean), r(sd), r(min), r(max))
	matrix ne = ne\o		

	* create weights
	gen weight_tmp = population if year == 2008
	bysort panel: egen weight = mean(weight_tmp)
	drop weight_tmp

	su d_small_pop [aw=weight]
	matrix o = (r(N), r(mean), r(sd), r(min), r(max))
	matrix m = m\o		

	su d_small_pop [aw=weight] if stcode == 25
	matrix o = (r(N), r(mean), r(sd), r(min), r(max))
	matrix ma = ma\o	

	su d_small_pop [aw=weight] if stcode != 25
	matrix o = (r(N), r(mean), r(sd), r(min), r(max))
	matrix ne = ne\o		
	
	restore
	
	* new firms cit_2
	preserve 
	drop if missing(naics_2)
	drop naics_4
	ren naics_2 naics
	ren n1_4 small
	
	drop if cntycd == 999
	merge n:1 stcode cntycd year using "$dir/tmp/Population.dta"
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge

	levelsof naics, local(naics_codes)
	foreach naics_code in `naics_codes' { 
		levelsof stcode, local(states) 
		foreach state in `states' {
			levelsof cntycd if stcode == `state', local(counties)
			foreach county in `counties' {
				local year 2008
				count if naics == `naics_code' & stcode == `state' & cntycd == `county' & year == `year'
				if r(N) > 0 {
					continue
				}
				quietly: gen e = 2 if _n == 1
				quietly: expand e, gen(d)
				quietly: replace naics = `naics_code' if d == 1
				quietly: replace stcode = `state' if d == 1
				quietly: replace cntycd = `county' if d == 1
				quietly: replace year = `year' if d == 1					
				quietly: replace small = 0 if d == 1
				quietly: drop e d
			}
		}	
	}	
	
	egen panel = group(stcode cntycd naics)
	tsset panel year
	sort panel
	by panel: egen naics_tmp = mean(naics)
	count if naics_tmp != naics & !missing(naics)
	drop naics
	rename naics_tmp naics
	by panel: egen stcode_tmp = mean(stcode)
	count if stcode_tmp != stcode & !missing(stcode)
	assert(r(N)==0)
	drop stcode
	rename stcode_tmp stcode
	by panel: egen cntycd_tmp = mean(cntycd)
	count if cntycd_tmp != cntycd & !missing(cntycd)
	assert(r(N)==0)
	drop cntycd
	rename cntycd_tmp cntycd
	replace small = 0 if missing(small)
	count if missing(stcode)
	assert(r(N)==0)

	gen small_pop = small / (population / `scale')
	sort panel year
	gen d_small_pop = D.small_pop
	su d_small_pop
	matrix o = (r(N), r(mean), r(sd), r(min), r(max))
	matrix m = m\o		

	* create weights
	gen weight_tmp = population if year == 2008
	bysort panel: egen weight = mean(weight_tmp)
	drop weight_tmp

	su d_small_pop [aw=weight]
	matrix o = (r(N), r(mean), r(sd), r(min), r(max))
	matrix m = m\o		

	merge n:1 naics using "$dir/tmp/capital.dta"
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge
	
	su percent_no_funding, detail
	gen low_capital = (percent_no_funding >= r(p90))

	su d_small_pop if low_capital
	matrix o = (r(N), r(mean), r(sd), r(min), r(max))
	matrix lc = lc\o		

	su d_small_pop if !low_capital
	matrix o = (r(N), r(mean), r(sd), r(min), r(max))
	matrix hc = hc\o		

	su d_small_pop [aw=weight] if low_capital
	matrix o = (r(N), r(mean), r(sd), r(min), r(max))
	matrix lc = lc\o		

	su d_small_pop [aw=weight] if !low_capital
	matrix o = (r(N), r(mean), r(sd), r(min), r(max))
	matrix hc = hc\o		
	
	restore

	* new firms cit_4
	
	preserve
	
	use $dir/tmp/fullPanel.dta, clear

	merge n:1 stcode cntycd year using "$dir/tmp/Population.dta"
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge

	merge n:1 naics using $dir/tmp/nonprofit.dta
	keep if _merge == 3
	
	gen small_pop = small / (population / `scale')
	sort panel year
	gen d_small_pop = D.small_pop
	su d_small_pop
	matrix o = (r(N), r(mean), r(sd), r(min), r(max))
	matrix m = m\o		

	* create weights
	gen weight_tmp = population if year == 2008
	bysort panel: egen weight = mean(weight_tmp)
	drop weight_tmp

	su d_small_pop [aw=weight]
	matrix o = (r(N), r(mean), r(sd), r(min), r(max))
	matrix m = m\o
			
	
	gen nonprofit = (!missing(percent_nonprofit) & percent_nonprofit >= .5)
	drop percent_nonprofit naicsdisplaylabel	

	su d_small_pop if nonprofit
	matrix o = (r(N), r(mean), r(sd), r(min), r(max))
	matrix np = np\o		

	su d_small_pop if !nonprofit
	matrix o = (r(N), r(mean), r(sd), r(min), r(max))
	matrix fp = fp\o		

	su d_small_pop [aw=weight] if nonprofit
	matrix o = (r(N), r(mean), r(sd), r(min), r(max))
	matrix np = np\o		

	su d_small_pop [aw=weight] if !nonprofit
	matrix o = (r(N), r(mean), r(sd), r(min), r(max))
	matrix fp = fp\o		
		
	restore
	
	* capital measures
	
	preserve
	
	drop if missing(naics_2)
	bysort naics_2: keep if _n==1
	ren naics_2 naics
	merge 1:1 naics using "$dir/tmp/capital.dta"
	drop if _merge == 2
	su percent_no_funding
	matrix o = (r(N), r(mean), r(sd), r(min), r(max))
	matrix m = m\o

	su percent_no_funding, detail
	gen low_capital = (percent_no_funding >= r(p90))

	su percent_no_funding if low_capital
	matrix o = (r(N), r(mean), r(sd), r(min), r(max))
	matrix lc = lc\o

	su percent_no_funding if !low_capital
	matrix o = (r(N), r(mean), r(sd), r(min), r(max))
	matrix hc = hc\o
	
	restore
	
	matrix m = m[2...,1...]			
	matrix rownames m = Counties Naics_2_Industries Naics_4_Industries Year New_State New_S_Weight New_County New_C_Weighted New_C_Industry2 New_C_I2_Weight New_C_Industry4 New_C_I4_Weight No_Funding
	matrix rownames ma = MA_Treatment Counties New_State New_S_Weight New_County New_C_Weighted
	matrix rownames ne = NE_Control Counties New_State New_S_Weight New_County New_C_Weighted 
	matrix rownames np = NP_Treatment Naics_4_Industries New_C_Industry4 New_C_I4_Weight
	matrix rownames fp = FP_Treatment Naics_4_Industries New_C_Industry4 New_C_I4_Weight
	matrix rownames lc = LC_Treatment New_C_Industry2 New_C_I2_Weight No_Funding
	matrix rownames hc = HC_Treatment New_C_Industry2 New_C_I2_Weight No_Funding
	matrix m = m\ma
	matrix m = m\ne
	matrix m = m\np
	matrix m = m\fp
	matrix m = m\lc
	matrix m = m\hc
	matlist m, format(%9.2fc)

	outtable using $dir/tmp/long_summary, mat(m) replace nobox format(%9.0fc %9.2fc %9.2fc %9.2fc %9.2fc)
	
end

program define BuildInfogroupClean

	! rm $dir/tmp/infogroup_all.dta
	! rm $dir/tmp/infogroup_naics2.dta
	! rm $dir/tmp/infogroup_naics4.dta
	
	use $dir/Data/infogroup_merged.dta
	drop city state zip salvol prmsic newadd abi nonprofit naics
	* keep if inlist(stcode, 25,23,33,50,44,9)
	keep if year > 1999
	recast int naics_2 naics_4

	drop if naics_4 >= 9900 & naics_4 < 10000
	* above 6240 consists of things like homeless shelters, not health related
	drop if naics_4 >= 6200 & naics_4 < 6240
	drop if naics_4 >= 9200 & naics_4 < 9300
	drop if naics_4 >= 9500 & naics_4 < 9600

	drop if cntycd == 999
	drop if cntycd == 0

	merge n:1 stcode cntycd year using "$dir/tmp/Population.dta"
	* ignoring county in Virgina and Florida that don't show up here
	* https://www.census.gov/geo/reference/codes/cou.html
	count if _merge == 1 & stcode == 25
	assert(r(N)==0)
	keep if _merge == 3
	drop _merge					
	* for better readability dividing population by one million
	replace population = population / 1000000

	preserve
	gen firm = 1
	bysort stcode cntycd year: egen newFirms = sum(firm)
	bysort stcode cntycd year: keep if _n == 1
	drop naics_4 naics_2 firm 
	
	egen panel = group(stcode cntycd)
	tsset panel year
	gen i = 1
	bysort panel: egen obs = sum(i)	if stcode == 25
	su obs
	assert(r(mean) == r(max))
	drop obs
	bysort panel: egen obs = sum(i)
	su obs
	drop if obs != r(max)
	drop obs
	drop i
	
	save $dir/tmp/infogroup_all.dta	
	restore

	preserve
	gen firm = 1
	replace naics_2 = 31 if inlist(naics_2, 32, 33)
	replace naics_2 = 44 if inlist(naics_2, 45)
	replace naics_2 = 48 if inlist(naics_2, 49)
	bysort naics_2 stcode cntycd year: egen newFirms = sum(firm)
	bysort naics_2 stcode cntycd year: keep if _n == 1
	drop naics_4 firm	

	/* 
	Don't believe this is needed
	
	quietly: levelsof naics_2, local(naics_codes)
	foreach naics_code in `naics_codes' { 
		display "Expanding `naics_code'"
		quietly: levelsof stcode, local(states) 
		foreach state in `states' {
			quietly: levelsof cntycd if stcode == `state', local(counties)
			foreach county in `counties' {
				local year 2008
				quietly: count if naics == `naics_code' & stcode == `state' & cntycd == `county' & year == `year'
				if r(N) > 0 {
					assert(r(N) == 1)
					continue
				}
				quietly: gen e = 2 if _n == 1
				quietly: expand e, gen(d)
				quietly: replace naics = `naics_code' if d == 1
				quietly: replace stcode = `state' if d == 1
				quietly: replace cntycd = `county' if d == 1
				quietly: replace year = `year' if d == 1					
				quietly: replace newFirms = 0 if d == 1
				quietly: drop e d
				quietly: count if naics == `naics_code' & stcode == `state' & cntycd == `county' & year == `year'
				assert(r(N) == 1)				
			}
		}	
	}
	*/

	egen panel = group(stcode cntycd naics_2)
	tsset panel year
	tsfill, full
	sort panel
	by panel: egen stcode_tmp = mean(stcode)
	count if stcode_tmp != stcode & !missing(stcode)
	assert(r(N)==0)
	drop stcode
	rename stcode_tmp stcode
	by panel: egen cntycd_tmp = mean(cntycd)
	count if cntycd_tmp != cntycd & !missing(cntycd)
	assert(r(N)==0)
	drop cntycd
	rename cntycd_tmp cntycd
	by panel: egen naics_2_tmp = mean(naics_2)
	count if naics_2_tmp != naics_2 & !missing(naics_2)
	assert(r(N)==0)
	drop naics_2
	rename naics_2_tmp naics_2	
	replace newFirms = 0 if missing(newFirms)
	gen i = 1
	bysort panel: egen obs = sum(i)	
	drop i
	su obs
	assert(r(mean) == r(min))

	ren naics_2 naics	
	merge n:1 naics using "$dir/tmp/capital.dta"
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge
	ren naics naics_2
	
	su percent_no_funding, detail
	gen low_capital = (percent_no_funding >= r(p90))
	drop percent*

	save $dir/tmp/infogroup_naics2.dta
	restore
	
	preserve
	gen firm = 1
	bysort naics_4 stcode cntycd year: egen newFirms = sum(firm)
	bysort naics_4 stcode cntycd year: keep if _n == 1
	drop naics_2 firm	

	/*
	Don't belive this is needed anymore
	
	quietly: levelsof naics_4, local(naics_codes)
	foreach naics_code in `naics_codes' { 
		display "Expanding `naics_code'"
		quietly: levelsof stcode, local(states) 
		foreach state in `states' {
			quietly: levelsof cntycd if stcode == `state', local(counties)
			foreach county in `counties' {
				local year 2008
				quietly: count if naics == `naics_code' & stcode == `state' & cntycd == `county' & year == `year'
				if r(N) > 0 {
					assert(r(N) == 1)
					continue
				}
				quietly: gen e = 2 if _n == 1
				quietly: expand e, gen(d)
				quietly: replace naics = `naics_code' if d == 1
				quietly: replace stcode = `state' if d == 1
				quietly: replace cntycd = `county' if d == 1
				quietly: replace year = `year' if d == 1					
				quietly: replace newFirms = 0 if d == 1
				quietly: drop e d
				quietly: count if naics == `naics_code' & stcode == `state' & cntycd == `county' & year == `year'
				assert(r(N) == 1)				
			}
		}	
	}
	*/
	
	egen panel = group(stcode cntycd naics_4)
	tsset panel year
	tsfill, full
	sort panel
	by panel: egen stcode_tmp = mean(stcode)
	count if stcode_tmp != stcode & !missing(stcode)
	assert(r(N)==0)
	drop stcode
	rename stcode_tmp stcode
	by panel: egen cntycd_tmp = mean(cntycd)
	count if cntycd_tmp != cntycd & !missing(cntycd)
	assert(r(N)==0)
	drop cntycd
	rename cntycd_tmp cntycd
	by panel: egen naics_4_tmp = mean(naics_4)
	count if naics_4_tmp != naics_4 & !missing(naics_4)
	assert(r(N)==0)
	drop naics_4
	rename naics_4_tmp naics_4	
	replace newFirms = 0 if missing(newFirms)
	gen i = 1
	bysort panel: egen obs = sum(i)	
	drop i
	su obs
	assert(r(mean) == r(min))

	save $dir/tmp/infogroup_naics4.dta
	restore
	
end

program define InfogroupVersion

	set matsize 11000

	local treatment_start 2008
	local treatment_group 25

	use $dir/tmp/infogroup_all.dta, clear
	fvset base 2007 year
	
	gen treatment = (year >= `treatment_start') & stcode == `treatment_group'

	* create weights
	gen weight_tmp = population if year == `treatment_start'
	bysort panel: egen weight = mean(weight_tmp)
	drop weight_tmp
	
	eststo DD: xtreg newFirms treatment i.year [aw=weight], fe robust

	use $dir/tmp/infogroup_naics2.dta, clear
	fvset base 2007 year
	ren naics_2 naics

	gen treatment = (year >= `treatment_start') & stcode == `treatment_group'
	
	eststo clear

	* create weights
	gen weight_tmp = population if year == `treatment_start'
	bysort panel: egen weight = mean(weight_tmp)
	drop weight_tmp
	
	keep if year >= 2003
	gen bYear = (year >= 2008)
	fvset base 0 bYear

	eststo N11: xtreg newFirms treatment i.bYear if naics == 11, fe robust cluster(panel)
	matlist e(V)
	display e(rank)
	eststo N11: xtreg newFirms treatment i.bYear if naics == 11, fe robust cluster(stcode)
	matlist e(V)
	display e(rank)

	exit

	quietly: levelsof naics, local(naics_codes)
	foreach naics_code in `naics_codes' { 
		eststo N`naics_code': xtreg newFirms treatment i.year if naics == `naics_code', fe robust
		eststo NW`naics_code': xtreg newFirms treatment i.year if naics == `naics_code' [aw=weight], fe robust
		exit
	}
	
	display `naics_codes'
	
	esttab using $dir/tmp/N2.csv, ///
		mtitles(`naics_codes') ///
		keep(treatment) ///
		nobaselevels nonumbers replace compress se r2 scalar("F F-test" "N_g Groups") sfmt(%9.3f %9.0f) b(3) starlevels(* 0.10 ** 0.05 *** 0.01 **** 0.001)
	
	exit

	gen treatment = (stcode == `treatment_group') & (year >= `treatment_start') & (low_capital == 1)
	eststo C_DD: xtreg newFirms treatment i.year if stcode == `treatment_group', fe robust	
	eststo C_DDD: xtreg newFirms ib23.naics#ib25.stcode ib23.naics#ib2007.year ib25.stcode#ib2007.year treatment, fe robust

	* testing proposition 2
	gen single_treat = (year == `treatment_start') & (stcode == `treatment_group') & (low_capital == 1)
	gen post_treat = (year > `treatment_start') & (stcode == `treatment_group') & (low_capital == 1)

	eststo A_DD: xtreg newFirms ib2007.year single_treat post_treat if stcode == `treatment_group', fe robust	
	test single_treat=post_treat
	eststo A_DDD: xtreg newFirms ib23.naics#ib25.stcode ib23.naics#ib2007.year ib25.stcode#ib2007.year single_treat post_treat, fe robust
	test single_treat=post_treat

	* nonprofits	
	use $dir/tmp/infogroup_naics4.dta, clear
	fvset base 2007 year
	ren naics_4 naics
	
	merge n:1 naics using $dir/tmp/nonprofit.dta
	* don't expect all naics to exist int he nonprofit data
	keep if _merge == 3
	drop _merge

	gen nonprofit = (!missing(percent_nonprofit) & percent_nonprofit >= .5)
	tab nonprofit
	drop percent_nonprofit naicsdisplaylabel
	
	gen treatment = (year >= `treatment_start') & (nonprofit == 1) & (stcode == `treatment_group')
		
	eststo NP_DD: xtreg newFirms treatment i.year if stcode == `treatment_group', fe robust		
	eststo NP_DDD: xtreg newFirms ib2361.naics#ib2007.year ib25.stcode#ib2007.year treatment, fe robust

	esttab DD NP_DD NP_DDD C_DD C_DDD A_DD A_DDD, ///
		mtitles("(1)" "(2)" "(3)" "(4)" "(5)" "(6)" "(7)")  ///
		drop(*.year *.stcode _cons)		
		nobaselevels nonumbers replace compress se r2 scalar("F F-test" "N_g Groups") sfmt(%9.3f %9.0f) b(3) starlevels(* 0.10 ** 0.05 *** 0.01 **** 0.001)
		
end

program define IndustryFrequency

	use $dir/tmp/countyBusinessLong.dta, clear
	
	keep if stcode == 25
	drop stcode
	
	gen naics_2 = floor(naics/10000)
	
	* this is the average number of entreprises per naics in each county across all years
	bysort naics cntycd: egen mean_small = mean(small) 
	drop small
	
	* we only need one of these, this should get of other years
	bysort naics cntycd: keep if _n == 1
	drop year
	
	* suming across all the counties to get the state totals
	bysort naics: egen small = sum(mean_small)
	drop mean_small
	
	* only need on of the county observations at this point
	bysort naics: keep if _n == 1
	drop cntycd

	gsort - small
	list naics_2 naics small if naics_2 == 61, clean

	list in 1/10, clean
	
	exit


	use $dir/tmp/countyBusinessLong.dta, clear
	
	keep if stcode == 25
	drop stcode

	* suming across all the counties to get the state totals
	bysort naics year: egen sum_small = sum(small)
	drop small
	
	* only need on of the county observations at this point
	bysort naics year: keep if _n == 1
	drop cntycd
	
	plot sum_small year if naics == 611610

	gen naics_2 = floor(naics/10000)
	bysort naics_2 year: egen small_2 = sum(sum_small)
	drop sum_small
	bysort naics_2 year: keep if _n == 1
	drop naics
	
	plot small_2 year if naics_2 == 61
	
	
	


	exit

	use $dir/tmp/fullPanel.dta, clear

	keep if stcode == 25	
	bysort naics cntycd: egen mean_small = mean(small) 
	keep if year == 2008
	drop stcode year small
	
	gen byte naics_2 = floor(naics / 100)
	
	gsort - mean_small
	tab naics if naics_2 == 61
	list if naics_2 == 61
	

end

program define PaperOutput
	
	*** Chart establishment creation versus net establishments
	foreach version of numlist 1 2 {
		if `version' == 1 {
			local filename $dir/Data/Firms/bds_f_agesz_release.csv
			local title "Entry versus Net Change with 1-4 employees (US)"
			local graphfile "$dir/tmp/est_net_US"
		}
		else {
			local filename $dir/Data/Firms/bds_f_agesz_st_release.csv
			local title "Firms vs Establishments with 1-4 employees (MA)"
			local graphfile "$dir/tmp/est_net_MA"
		}
			
		import delimited `filename', varnames(1) clear
		capture: keep if state == 25
		capture: drop state
		drop job* *_rate net_* *emp	
		replace fsize = regexr(fsize, "[^_]*\) ", "")
		replace fage = regexr(fage, "[^_]*\) ", "")
		* keep if inlist(fage, "0", "1")
		keep if fsize == "1 to 4"
		bysort year: egen total_estabs = total(estabs)
		bysort year: egen total_entry = total(estabs_entry)
		keep if fage == "0"
		tsset year
		gen diff_small_est = D.total_estabs
		
		graph twoway ///
			(scatter total_entry year, msymbol(+)) ///
			(scatter diff_small_est year, msymbol(X)) ///
			, title(`title') ytitle(Count) xtitle(Year) legend(order(1 2 3) label(1 "New Entry") label(2 "Change in Establishments"))
		graph2tex, epsfile(`graphfile')	

	}
	
	*** Chart firm totals versus establishment totals
	foreach version of numlist 1 2 {
		if `version' == 1 {
			local filename $dir/Data/Firms/bds_f_agesz_release.csv
			local title "Firms vs Establishments with 1-4 employees (US)"
			local graphfile "$dir/tmp/firm_est_US"
		}
		else {
			local filename $dir/Data/Firms/bds_f_agesz_st_release.csv
			local title "Firms vs Establishments with 1-4 employees (MA)"
			local graphfile "$dir/tmp/firm_est_MA"
		}
		
		import delimited `filename', varnames(1) clear
		* should fail for US
		capture: keep if state == 25
		replace fsize = regexr(fsize, "[^_]*\) ", "")
		keep if fsize == "1 to 4"
		ren year2 year
		bysort year: egen total_firms = total(firms)
		bysort year: egen total_estabs = total(estabs)
		bysort year: keep if _n == 1

		graph twoway ///
			(scatter total_firms year, msymbol(+)) ///
			(scatter total_estabs year, msymbol(X)) ///
			, title(`title') ytitle(Count) xtitle(Year) legend(order(1 2) label(1 "Firms") label(2 "Establishments"))
		graph2tex, epsfile(`graphfile')	

	}

	*** Construction example chart
	use $dir/tmp/nonemployed.dta, clear
	drop if inlist(naics, 62, 95, 99)
	drop if year < 2000
	ren small ne_est	
	keep ne_est stcode cntycd naics year	
	keep if naics == 23
	keep if stcode == 25
	bysort year: egen total_ne = total(ne_est)
	bysort year: keep if _n == 1	
	
	graph twoway ///
		(scatter total_ne year, msymbol(+)) ///
		, title("Construction in MA") ytitle(Nonemployers) xtitle(Year) ///
		  xlabel(2000(4)2012) ylabel(50000(5000)65000)
	graph2tex, epsfile($dir/tmp/construction)

	*** Building dataset used for state level table

	use $dir/tmp/nonemployed.dta, clear
	drop if naics == 62
	drop if year < 2000
	tsset, clear
	bysort stcode cntycd year: egen ne_est = total(small)
	by stcode cntycd year: keep if _n == 1
	keep ne_est stcode cntycd year	
	save $dir/tmp/ne_tmp.dta, replace
	
	use $dir/tmp/countyBusiness.dta, clear
	drop if naics == 62
	bysort stcode cntycd year: egen emp_est = total(small)
	by stcode cntycd year: keep if _n == 1
	* no equivilant state wide data exists in other datasets
	drop if cntycd == 999
	keep emp_est stcode cntycd year
	save $dir/tmp/emp_tmp.dta, replace

	use "$dir/tmp/Employment.dta", clear
	keep stcode cntycd year self_employed
	drop if year == 2013
	merge 1:1 stcode cntycd year using $dir/tmp/ne_tmp.dta
	count if _merge != 3 & stcode == 25
	assert(r(N)==0)
	keep if _merge == 3
	drop _merge
	merge 1:1 stcode cntycd year using $dir/tmp/emp_tmp.dta
	count if _merge != 3 & stcode == 25
	assert(r(N)==0)
	keep if _merge == 3
	drop _merge
	
	bysort stcode year: egen total_ne = total(ne_est)
	bysort stcode year: egen total_em = total(emp_est)
	bysort stcode year: egen total_se = total(self_employed)
	bysort stcode year: keep if _n == 1
	replace cntycd = 0
	drop ne_est emp_est self_employed

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
	gen se_pop = total_se / population
	gen em_pop = total_em / population
	gen ne_pop = total_ne / population
	gen diff_se_pop = D.se_pop
	gen diff_em_pop = D.em_pop
	gen diff_ne_pop = D.ne_pop

	* Covariates used for matching the synthetic controls

	* all the covariates are for a single year independant so should be safe to just generate
	* matches for a single year as the 'treatment' group
	
	* income per capita (GDP) 
	rename year year_tmp
	gen year = 2006
	merge n:1 stcode year using "$dir/tmp/MedianIncomeState.dta"
	drop year
	rename year_tmp year
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge
	gen log_income = log(income)
	drop(income)

	* percent aged 20-24 or so since MA has a lot of universities
	* child dependancy ratio
	* this is currently using 2000 year data
	merge n:1 stcode cntycd using "$dir/tmp/ageGroup.dta"
	count if _merge == 1
	* assert(r(N)==0)
	bysort panel: egen error = total(_merge == 1)
	drop if error
	drop error	
	drop if _merge == 2
	drop _merge
	
	* percent with healthcare
	* using 2005 data
	merge n:1 stcode cntycd using "$dir/tmp/insurance.dta"
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge

	* urban population
	* using 2000 year data
	merge n:1 stcode cntycd using "$dir/tmp/urban.dta"
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge
		
	drop cntycd geo* vd*
	keep if inlist(stcode, 9, 23, 25, 33, 44, 50)

	file open BASIC_SUMMARY using $dir/tmp/basic_summary.tex, write replace
	file write BASIC_SUMMARY "\begin{tabular}{lrr} \hline \hline" _n
	file write BASIC_SUMMARY "& Massachusetts  & Other New England  \\  \hline" _n

	su population if stcode == 25 & year == 2007
	local ma = r(sum) * 1000000
	su population if stcode != 25 & year == 2007
	local ne = r(sum) * 1000000
	file write BASIC_SUMMARY "Population &" %12.0fc (`ma') " & " %12.0fc (`ne') " \\" _n
	su percent_urban if stcode == 25
	local ma = r(mean) * 100
	su percent_urban if stcode != 25
	local ne = r(mean) * 100
	file write BASIC_SUMMARY "Percent Urban & " %12.2f (`ma') "\% & " %12.2f (`ne') "\% \\" _n
	su percent_uninsured if stcode == 25
	local ma = r(mean)
	su percent_uninsured if stcode != 25
	local ne = r(mean)
	file write BASIC_SUMMARY "Percent Uninsured & " %12.2f (`ma') "\% & " %12.2f (`ne') "\% \\" _n
	su percent_20_to_24 if stcode == 25
	local ma = r(mean)
	su percent_20_to_24 if stcode != 25
	local ne = r(mean)
	file write BASIC_SUMMARY "Percent Aged 20 to 24 & " %12.2f (`ma') "\% & " %12.2f (`ne') "\% \\" _n
	su percent_household if stcode == 25
	local ma = r(mean)
	su percent_household if stcode != 25
	local ne = r(mean)
	file write BASIC_SUMMARY "Percent of Households with Children & " %12.2f (`ma') "\% & " %12.2f (`ne') "\% \\" _n

	file write BASIC_SUMMARY "\hline \textbf{Self-Employment} & & \\" _n
	su total_se if stcode == 25 & year == 2007
	local ma = r(sum)
	su total_se if stcode != 25 & year == 2007
	local ne = r(sum)
	file write BASIC_SUMMARY "Number & " %12.0fc (`ma') " & " %12.0fc (`ne') "\\" _n
	su se_pop if stcode == 25
	local ma = r(mean)
	su se_pop if stcode != 25
	local ne = r(mean)
	file write BASIC_SUMMARY "Per Million People & " %12.0fc (`ma') " & " %12.0fc (`ne') "\\" _n
	su diff_se_pop if stcode == 25
	local ma = r(mean)
	su diff_se_pop if stcode != 25
	local ne = r(mean)
	file write BASIC_SUMMARY "Yearly Change per Million People & " %12.0fc (`ma') " & " %12.0fc (`ne') "\\" _n

	file write BASIC_SUMMARY "\hline \textbf{Non-Employers} & & \\" _n
	su total_ne if stcode == 25 & year == 2007
	local ma = r(sum)
	su total_ne if stcode != 25 & year == 2007
	local ne = r(sum)
	file write BASIC_SUMMARY "Number & " %12.0fc (`ma') " & " %12.0fc (`ne') "\\" _n
	su ne_pop if stcode == 25
	local ma = r(mean)
	su ne_pop if stcode != 25
	local ne = r(mean)
	file write BASIC_SUMMARY "Per Million People & " %12.0fc (`ma') " & " %12.0fc (`ne') "\\" _n
	su diff_ne_pop if stcode == 25
	local ma = r(mean)
	su diff_ne_pop if stcode != 25
	local ne = r(mean)
	file write BASIC_SUMMARY "Yearly Change per Million People & " %12.0fc (`ma') " & " %12.0fc (`ne') "\\" _n

	file write BASIC_SUMMARY "\hline \textbf{Establishments with 1-4 Workers} & & \\" _n
	su total_em if stcode == 25 & year == 2007
	local ma = r(sum)
	su total_em if stcode != 25 & year == 2007
	local ne = r(sum)
	file write BASIC_SUMMARY "Number & " %12.0fc (`ma') " & " %12.0fc (`ne') "\\" _n
	su em_pop if stcode == 25
	local ma = r(mean)
	su em_pop if stcode != 25
	local ne = r(mean)
	file write BASIC_SUMMARY "Per Million People & " %12.0fc (`ma') " & " %12.0fc (`ne') "\\" _n
	su diff_em_pop if stcode == 25
	local ma = r(mean)
	su diff_em_pop if stcode != 25
	local ne = r(mean)
	file write BASIC_SUMMARY "Yearly Change per Million People & " %12.0fc (`ma') " & " %12.0fc (`ne') "\\" _n

	file write BASIC_SUMMARY " \hline \hline \end{tabular}" _n
	file close BASIC_SUMMARY

	*** Now running proposition 1, have state but no industries
	
	use $dir/tmp/nonemployed.dta, clear
	drop if naics == 62
	drop if year < 2000
	tsset, clear
	bysort stcode cntycd year: egen ne_est = total(small)
	by stcode cntycd year: keep if _n == 1
	keep ne_est stcode cntycd year	
	save $dir/tmp/ne_tmp.dta, replace
	
	use $dir/tmp/countyBusiness.dta, clear
	drop if naics == 62
	bysort stcode cntycd year: egen emp_est = total(small)
	by stcode cntycd year: keep if _n == 1
	* no equivilant state wide data exists in other datasets
	drop if cntycd == 999
	keep emp_est stcode cntycd year
	save $dir/tmp/emp_tmp.dta, replace

	use "$dir/tmp/Employment.dta", clear
	keep stcode cntycd year self_employed
	drop if year == 2013
	merge 1:1 stcode cntycd year using $dir/tmp/ne_tmp.dta
	count if _merge != 3 & stcode == 25
	assert(r(N)==0)
	keep if _merge == 3
	drop _merge
	merge 1:1 stcode cntycd year using $dir/tmp/emp_tmp.dta
	count if _merge != 3 & stcode == 25
	assert(r(N)==0)
	keep if _merge == 3
	drop _merge
	
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
	gen em_pop = emp_est / population
	gen ne_pop = ne_est / population
	gen diff_se_pop = D.se_pop
	gen diff_em_pop = D.em_pop
	gen diff_ne_pop = D.ne_pop

	drop if year == 2000
	* drop if year <= 2001
	local base_year 2007

	gen treatment = stcode == 25 & year > `base_year'

	eststo DD_SE: xtreg diff_se_pop treatment ib`base_year'.year i.panel if inlist(stcode, 9, 23, 25, 33, 44, 50), fe robust
	estadd local co "New England" 
	estadd local cl "County"
	eststo DD_NE: xtreg diff_ne_pop treatment ib`base_year'.year i.panel if inlist(stcode, 9, 23, 25, 33, 44, 50), fe robust
	estadd local co "New England" 
	estadd local cl "County"
	eststo DD_EM: xtreg diff_em_pop treatment ib`base_year'.year i.panel if inlist(stcode, 9, 23, 25, 33, 44, 50), fe robust
	estadd local co "New England" 
	estadd local cl "County"

	esttab _all using $dir/tmp/prop1.tex, ///
		mtitles("Self-Employed" "Non-Employers" "Small Establishments")   ///
		keep("Massachusetts $\times$ Post 2007")  ///
		rename(treatment "Massachusetts $\times$ Post `base_year'") ///
		nobaselevels nonumbers replace compress se r2 scalar("F F-test" "N_g Groups" "cl Cluster" "co Control") ///
		indicate("Year FE = *.year" "County FE = *.panel") ///
		sfmt(%9.3f %9.0f) b(3) starlevels(* 0.10 ** 0.05 *** 0.01) ///
		addnotes("Fixed effect model with American Community Survey providing self-employment data, Nonemployer " ///
		 "Statistics providing establishment without employee data and County Business Patterns providing " ///
		 "(small) establishment with 1 to 4 employee data. Establishments with 2 digit NAICS industries of " ///
		 "95, 99 and 62 dropped. Establishments marked as state wide dropped. New England considered " ///
		 "to be Connecticut, Maine, New Hampshire, Rhode Island, Vermont and Massachusetts.")
	
	exit
	
	* now doing the same with state cluster as a comparison	
	eststo DD_SE: xtreg diff_se_pop treatment ib`base_year'.year i.panel if inlist(stcode, 9, 23, 25, 33, 44, 50), fe robust cluster(stcode)
	estadd local co "New England" 
	estadd local cl "State"
	eststo DD_NE: xtreg diff_ne_pop treatment ib`base_year'.year i.panel if inlist(stcode, 9, 23, 25, 33, 44, 50), fe robust cluster(stcode)
	estadd local co "New England" 
	estadd local cl "State"
	eststo DD_EM: xtreg diff_em_pop treatment ib`base_year'.year i.panel if inlist(stcode, 9, 23, 25, 33, 44, 50), fe robust cluster(stcode)
	estadd local co "New England" 
	estadd local cl "State"

	esttab _all using $dir/tmp/prop1_state.tex, ///
		mtitles("Self-Employed" "Non-Employers" "Small Establishments")   ///
		keep("Massachusetts $\times$ Post 2007")  ///
		rename(treatment "Massachusetts $\times$ Post `base_year'") ///
		nobaselevels nonumbers replace compress se r2 scalar("F F-test" "N_g Groups" "cl Cluster" "co Control") ///
		indicate("Year FE = *.year" "County FE = *.panel") ///
		sfmt(%9.3f %9.0f) b(3) starlevels(* 0.10 ** 0.05 *** 0.01) 

	drop treatment


	levelsof year, local(years)
	foreach year of local years {
		if `year' == `base_year' | `year' == 2000 continue
		gen iTYear`year' = (year == `year') & (stcode == 25)
	}
	xtreg diff_se_pop ib`base_year'.year iTYear* if inlist(stcode, 9, 23, 25, 33, 44, 50), fe robust	
	GraphPoint iTYear `base_year' "Self-Employed in Massachusetts versus New England" "_se_all_basic"
	xtreg diff_ne_pop ib`base_year'.year iTYear* if inlist(stcode, 9, 23, 25, 33, 44, 50), fe robust	
	GraphPoint iTYear `base_year' "Non-Employeers in Massachusetts versus New England" "_ne_all_basic"
	xtreg diff_em_pop ib`base_year'.year iTYear* if inlist(stcode, 9, 23, 25, 33, 44, 50), fe robust	
	GraphPoint iTYear `base_year' "Small establishments in Massachusetts versus New England" "_em_all_basic"	
	drop iTYear*
	
	eststo clear

	* Covariates used for matching the synthetic controls

	* all the covariates are for a single year independant so should be safe to just generate
	* matches for a single year as the 'treatment' group
	
	* income per capita (GDP) 
	rename year year_tmp
	gen year = 2006
	merge n:1 stcode year using "$dir/tmp/MedianIncomeState.dta"
	drop year
	rename year_tmp year
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge
	gen log_income = log(income)
	drop(income)

	* percent aged 20-24 or so since MA has a lot of universities
	* child dependancy ratio
	* this is currently using 2000 year data
	merge n:1 stcode cntycd using "$dir/tmp/ageGroup.dta"
	count if _merge == 1
	* assert(r(N)==0)
	bysort panel: egen error = total(_merge == 1)
	drop if error
	drop error	
	drop if _merge == 2
	drop _merge
	
	* percent with healthcare
	* using 2005 data
	merge n:1 stcode cntycd using "$dir/tmp/insurance.dta"
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge

	* urban population
	* using 2000 year data
	merge n:1 stcode cntycd using "$dir/tmp/urban.dta"
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge
	drop geo* vd*

	drop if year == 2000
	* drop if year <= 2001
	
	* set graphics off
	local treatment 2008
	local MA 25
	
	bysort stcode cntycd: egen c = count(year)
	su c
	local max_periods = r(max)	
	drop c
			
	foreach y_variable of varlist diff_se_pop diff_ne_pop diff_em_pop {
		
		local titles

		local title "Small_Establishments"
		local graphfile "_em_synth"
		if "`y_variable'" == "diff_ne_pop" {
			local title "Non-Employers"
			local graphfile "_ne_synth"
		}
		if "`y_variable'" == "diff_se_pop" {
			local title "Self-Employed"
			local graphfile "_se_synth"
		}
	
		levelsof cntycd if stcode == `MA' & !missing(`y_variable'), local(counties)
		foreach county of local counties {

			* also skip if county did not have data for all years
			count if stcode == `MA' & cntycd == `county' & !missing(`y_variable')
			if r(N) != `max_periods' {
				continue
			}

			preserve

			* picking counties with similar predictor values
			local max_sd 1
			sort stcode cntycd
			by stcode cntycd: gen tag = _n == 1
			local predictors log_income percent_20_to_24 percent_urban percent_uninsured		

			foreach predictor of varlist `predictors' {
				* for the percentage predictors, do I model as a uniform and use p(1-p) as variance?
				by stcode cntycd: egen st_mean = mean(`predictor')
				su st_mean if tag
				local max_d = `max_sd' * r(sd)
				su st_mean if stcode == `MA' & cntycd == `county'
				drop if st_mean >  r(mean) + `max_d' | st_mean < r(mean) - `max_d'
				su st_mean if tag
				drop st_mean
			}
			drop tag
				
			* drop counties that are missing our y_variable in some years
			by stcode cntycd: egen t_variable = count(`y_variable') 
			drop if t_variable < `max_periods' & stcode != `MA'			
			drop t_variable
			
			local filename "$dir/tmp/synth_`county'_all_`y_variable'"
			* should only be one
			levelsof panel if stcode == `MA' & cntycd == `county', local(trunit)
			levelsof panel if stcode != `MA', local(counit)	

			levelsof year if panel == `trunit', local(year_matches)
			local year_var
			foreach year_match of local year_matches {
				local year_var `year_var' `y_variable'(`year_match')
			}

			synth `y_variable' `year_var' ///
				log_income percent_20_to_24 percent_urban percent_uninsured ///
				, trunit(`trunit') trperiod(`treatment') counit(`counit') ///
				keep(`filename') replace	
			
			* sometimes we have fewer controls than years which causes merge to 
			* fail later because there are multiple missing _Co_Number values
			* due to the way synth saves its output
			use `filename', clear			
			drop if missing(_Co)
			save `filename', replace
									
			restore
		}

		* next recreate the control as separate counties
		gen e = 2 if stcode == `MA'
		expand e, gen(d)
		drop e
		su panel
		replace panel = panel + r(max) + 1 if d == 1
		replace `y_variable' = . if d == 1
		replace stcode = 0 if d == 1
		
		gen _Co_Number = panel
		
		levelsof cntycd if stcode == `MA' & !missing(`y_variable'), local(counties)
		foreach county of local counties {

			count if stcode == `MA' & cntycd == `county' & !missing(`y_variable')
			if r(N) == `max_periods' {							
				display "Merging County:`county'"
				merge n:1 _Co_Number using "$dir/tmp/synth_`county'_all_`y_variable'.dta", assert(1 3)
				drop _Y_treated _Y_synthetic _time _merge

				gen w_diff = _W_Weight * `y_variable'
				bysort year: egen c_diff = total(w_diff)
				replace `y_variable' = c_diff if d == 1 & stcode == 0 & cntycd == `county'
				drop w_diff c_diff _W_Weight
			}
			else {
				replace `y_variable' = . if stcode == `MA' & cntycd == `county'
			}
		}
		
		drop d _Co_Number
		
		gen treatment = stcode == 25 & year > `base_year'
		capture noisily: eststo s_`y_variable': xtreg `y_variable' treatment ib2007.year i.panel if inlist(stcode, 0,25), fe robust
		if !inlist(_rc,0,2000,2001){
			exit _rc
		}
		if _rc == 2001 {
			display "Main: not enough observations with `y_variable'"
		}
		if _rc == 2000 {
			display "Main: No observations with `y_variable'"
		}
		if _rc == 0 {
			estadd local co "Synthetic" 
			estadd local cl "County"
		}
		drop treatment

		preserve
		levelsof year, local(years)	
		foreach year of local years {
			if `year' == 2007 | `year' == 2000 continue
			gen iTYear`year' = (year == `year') & (stcode == 25)
		}
		keep if inlist(stcode, 0,25)
		capture noisily: xtreg `y_variable' ib2007.year iTYear*, fe robust
		if !inlist(_rc,0,2000,2001){
			exit _rc
		}
		if _rc == 2000 {
			display "Graph: No observations with `y_variable'"
		}
		if _rc == 2001 {
			display "Graph: Not enough observations with `y_variable'"
		}
		if _rc == 0 {
			GraphPoint iTYear 2007 `title' `graphfile'
		}
		restore		
		drop if stcode == 0		
			
	}

	esttab _all using $dir/tmp/prop1_synth.tex, ///
		mtitles("Self-Employed" "Non-Employers" "Small Establishments")   ///
		keep("Massachusetts $\times$ Post 2007")  ///
		rename(treatment "Massachusetts $\times$ Post `base_year'") ///
		nobaselevels nonumbers replace compress se r2 scalar("F F-test" "N_g Groups" "cl Cluster" "co Control") ///
		indicate("Year FE = *.year" "County FE = *.panel") ///
		sfmt(%9.3f %9.0f) b(3) starlevels(* 0.10 ** 0.05 *** 0.01) ///
		addnotes("Fixed effect model with synthetic controls. US counties outside one standard deviation for any " ///
			"obvservable excluded from control pool.")

	exit

	*** For all industries and counties, generate the synthetic control files
	foreach y_variable in diff_em_pop  { // diff_ne_pop

		if "`y_variable'" == "diff_ne_pop" {

			use $dir/tmp/nonemployedLong.dta, clear
			* get rid of the same naics industies we dropped above
			drop if naics >= 9900 & naics < 10000
			* above 6240 consists of things like homeless shelters, not health related
			drop if naics >= 6200 & naics < 6240
			drop if naics >= 9500 & naics < 9600
			drop if year < 2000
			ren small ne_est	
			keep ne_est stcode cntycd naics year	
		
			* dropping naics that MA counties do not have much of
			* bysort stcode cntycd naics: egen t_est = total(ne_est)
			* drop if t_est < 1000 & stcode == 25
			* drop t_est	

		}
		
		if "`y_variable'" == "diff_em_pop" {

			use $dir/tmp/countyBusinessLong.dta, clear
			drop if naics >= 9900 & naics < 10000
			drop if naics >= 6200 & naics < 6240
			drop if naics >= 9500 & naics < 9600
			ren small emp_est
			drop if cntycd == 999
			keep emp_est stcode cntycd naics year
			
			* bysort stcode cntycd naics: egen t_est = total(emp_est)
			* drop if t_est < 1000 & stcode == 25
			* drop t_est	
		
		}
		
		* drop naics that counties do not have for all years
		bysort stcode cntycd naics: egen year_count = count(year)
		drop if year_count != 13
		drop year_count
		
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

		if "`y_variable'" == "diff_ne_pop" {
			gen ne_pop = ne_est / population
			gen diff_ne_pop = D.ne_pop
		}
		if "`y_variable'" == "diff_em_pop" {
			gen em_pop = emp_est / population
			gen diff_em_pop = D.em_pop
		}
		
		rename year year_tmp
		gen year = 2006
		merge n:1 stcode year using "$dir/tmp/MedianIncomeState.dta"
		drop year
		rename year_tmp year
		count if _merge == 1
		assert(r(N)==0)
		drop if _merge == 2
		drop _merge
		gen log_income = log(income)
		drop(income)

		* percent aged 20-24 or so since MA has a lot of universities
		* child dependancy ratio
		* this is currently using 2000 year data
		merge n:1 stcode cntycd using "$dir/tmp/ageGroup.dta"
		count if _merge == 1
		* assert(r(N)==0)
		bysort panel: egen error = total(_merge == 1)
		drop if error
		drop error	
		drop if _merge == 2
		drop _merge
		
		* percent with healthcare
		* using 2005 data
		merge n:1 stcode cntycd using "$dir/tmp/insurance.dta"
		count if _merge == 1
		assert(r(N)==0)
		drop if _merge == 2
		drop _merge

		* urban population
		* using 2000 year data
		merge n:1 stcode cntycd using "$dir/tmp/urban.dta"
		count if _merge == 1
		assert(r(N)==0)
		drop if _merge == 2
		drop _merge

		keep naics year panel `y_variable' stcode cntycd log_income percent_uninsured percent_20_to_24 percent_urban
		compress
		
		save $dir/tmp/synth_`y_variable'.dta, replace

		save $dir/tmp/tmp_`y_variable'.dta		
		
		drop if year == 2000
	
		* set graphics off
		local treatment 2008
		local MA 25
				
		levelsof naics if stcode == `MA' & !missing(`y_variable'), local(industries)
		foreach industry of local industries {

			levelsof cntycd if stcode == `MA' & naics == `industry' & !missing(`y_variable'), local(counties)
			foreach county of local counties {
			
				preserve

				* picking counties with similar predictor values
				local max_sd 1
				sort stcode cntycd
				by stcode cntycd: gen tag = _n == 1
				local predictors log_income percent_20_to_24 percent_urban percent_uninsured		

				foreach predictor of varlist `predictors' {
					by stcode cntycd: egen st_mean = mean(`predictor')
					su st_mean if tag
					local max_d = `max_sd' * r(sd)
					su st_mean if stcode == `MA' & cntycd == `county'
					drop if st_mean >  r(mean) + `max_d' | st_mean < r(mean) - `max_d'
					drop st_mean
				}
				drop tag
				
				* drop counties that are missing our y_variable in some years
				by stcode cntycd: egen t_variable = count(`y_variable') if naics == `industry'
				su t_variable
				drop if t_variable < r(max) & stcode != `MA'			
				drop t_variable
				
				* should only be one
				levelsof panel if stcode == `MA' & cntycd == `county' & naics == `industry', local(trunit)
				* should have at least 2
				count if stcode != `MA' & naics == `industry' & year == 2007
				if(r(N) > 1) {				
					levelsof panel if stcode != `MA' & naics == `industry', local(counit)		
					synth `y_variable' ///
						`y_variable'(2001) `y_variable'(2002) `y_variable'(2003) `y_variable'(2004) `y_variable'(2005) `y_variable'(2006) `y_variable'(2007) ///
						log_income percent_20_to_24 percent_urban percent_uninsured ///
						, trunit(`trunit') trperiod(`treatment') counit(`counit') ///
						keep("$dir/tmp/synth_`county'_`industry'_`y_variable'") replace	
					
					* sometimes we have fewer controls than years which causes merge to 
					* fail later because there are multiple missing _Co_Number values
					* due to the way synth saves its output
					use $dir/tmp/synth_`county'_`industry'_`y_variable', clear			
					drop if missing(_Co)
					save $dir/tmp/synth_`county'_`industry'_`y_variable', replace
				}
										
				restore
			}
		}

	}

	*** Now printing out the basic regressions to make sure things look ok

	* set graphics off
	local treatment 2008
	local MA 25
	local maxEstimatesPerTable 5
			
	foreach y_variable in diff_em_pop  { //  diff_ne_pop

		tempname texhandle
		local texfile "$dir/tmp/synth_results_`y_variable'.tex"
		file open `texhandle' using `texfile', write text replace
		file write `texhandle' ("\documentclass{article}") _n
		file write `texhandle' ("\usepackage{rotating}") _n
		file write `texhandle' ("\usepackage{graphicx}") _n
		file write `texhandle' ("\usepackage{epstopdf}") _n
		file write `texhandle' ("\usepackage{float}") _n
		file write `texhandle' ("\addtolength{\textwidth}{4cm}") _n
		file write `texhandle' ("\addtolength{\hoffset}{-2cm}") _n
		file write `texhandle' ("\addtolength{\textheight}{3cm}") _n
		file write `texhandle' ("\addtolength{\voffset}{-1.5cm}") _n
		file write `texhandle' ("\begin{document}") _n
		file write `texhandle' ("\setlength{\pdfpagewidth}{8.5in}") _n
		file write `texhandle' ("\setlength{\pdfpageheight}{11in}") _n
	
		use $dir/tmp/synth_`y_variable'.dta, clear
	
		gen `y_variable'Beta = .
	
		local titles
		local tableCount 1
		
		local title "1-4 Worker"
		local graphTitle "1_4_Establishment_Synth"
		local capitalFile "$dir/tmp/capital.dta"
		if "`y_variable'" == "diff_ne_pop" {
			local title "0 Worker"
			local graphTitle "0_Establishment_Synth"
			local capitalFile "$dir/tmp/capitalNonemployer.dta"
		}
	
		levelsof naics if stcode == `MA' & !missing(`y_variable'), local(industries)
		foreach industry of local industries {

			gen e = 2 if stcode == `MA'
			expand e, gen(d)
			drop e
			replace panel = -panel if d == 1
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
			
			drop d _Co_Number
						
			gen treatment = stcode == 25 & year >= `treatment'
			
			capture noisily: eststo s_`y_variable'_`industry': xtreg `y_variable' treatment ib2007.year if inlist(stcode, 0,25) & naics == `industry', fe robust
			if !inlist(_rc,0,2000,2001){
				exit _rc
			}
			if _rc == 2001 {
				display "Main: not enough observations with `y_variable' in industry `industry'"
			}
			if _rc == 2000 {
				display "Main: No observations with `y_variable' in industry `industry'"
			}
			if _rc == 0 {
				local titles `titles' "`industry'"
				replace `y_variable'Beta = _b[treatment] if naics == `industry'
				estadd local w "None" 
				estadd local c "County"
			}
			
			drop treatment

			preserve
			levelsof year, local(years)	
			foreach year of local years {
				if `year' == 2007 | `year' == 2000 continue
				gen iTYear`year' = (year == `year') & (stcode == 25)
			}
			keep if inlist(stcode, 0,25)
			keep if naics == `industry'
			capture noisily: xtreg `y_variable' ib2007.year iTYear*, fe robust
			if !inlist(_rc,0,2000,2001){
				exit _rc
			}
			if _rc == 2000 {
				display "Graph: No observations with `y_variable' in industry `industry'"
			}
			if _rc == 2001 {
				display "Graph: Not enough observations with `y_variable' in industry `industry'"
			}
			if _rc == 0 {
				GraphPoint iTYear 2007 "`graphTitle'_`industry'" "`y_variable'_`industry'"
				file write `texhandle' ("\begin{figure}[H]") _n			
				file write `texhandle' ("\includegraphics[width=\linewidth]{graphpoint`y_variable'_`industry'}") _n
				file write `texhandle' ("\end{figure}") _n	
			}
			restore		
			drop if stcode == 0
			
			* want to keep the number of estimates per table capped at 5
			if $eststo_counter + 0 >= `maxEstimatesPerTable' {
				esttab _all using $dir/tmp/`y_variable'_naics_4_synth`tableCount'.tex, ///
					mtitles(`titles')   ///
					keep("Massachusetts $\times$ Post 2007")  ///
					rename(treatment "Massachusetts $\times$ Post 2007") ///
					nobaselevels nonumbers replace compress se r2 scalar("F F-test" "N_g Groups" "w Weight" "c Cluster") ///
					indicate("Year FE = *.year") ///
					sfmt(%9.3f %9.0f) b(3) starlevels(* 0.10 ** 0.05 *** 0.01 **** 0.001)					
				eststo clear

				file write `texhandle' ("\begin{table}[H]") _n	
				file write `texhandle' ("\centering") _n	
				file write `texhandle' ("\input{`y_variable'_naics_4_synth`tableCount'.tex}") _n		
				file write `texhandle' ("\end{table}") _n			
				file write `texhandle' ("\pagebreak") _n			

				local tableCount = `tableCount' + 1
				local titles					
			}						
		}


		if $eststo_counter + 0 > 0 {
			esttab _all using $dir/tmp/`y_variable'_naics_4_synth`tableCount'.tex, ///
				mtitles(`titles')   ///
				keep("Massachusetts $\times$ Post 2007")  ///
				rename(treatment "Massachusetts $\times$ Post 2007") ///
				nobaselevels nonumbers replace compress se r2 scalar("F F-test" "N_g Groups" "w Weight" "c Cluster") ///
				indicate("Year FE = *.year") ///
				sfmt(%9.3f %9.0f) b(3) starlevels(* 0.10 ** 0.05 *** 0.01 **** 0.001)	
			eststo clear
			
			file write `texhandle' ("\begin{table}[H]") _n	
			file write `texhandle' ("\centering") _n	
			file write `texhandle' ("\input{`y_variable'_naics_4_synth`tableCount'.tex}") _n		
			file write `texhandle' ("\end{table}") _n			

		}
				
		
		save $dir/tmp/`y_variable'_beta.dta, replace
		
		preserve
		keep `y_variable'Beta naics
		bysort `y_variable'Beta naics: keep if _n == 1
		replace naics = floor(naics/100)
		replace naics = 31 if inlist(naics, 32, 33)
		replace naics = 44 if inlist(naics, 45)
		replace naics = 48 if inlist(naics, 49)		
		merge n:1 naics using `capitalFile'
		keep if _merge == 3
		drop _merge
		graph twoway ///
			(scatter `y_variable'Beta percent_no_funding, msymbol(+)) ///
			(lfit `y_variable'Beta percent_no_funding, lcolor(midblue)) ///
			, title(`title') ytitle(Coefficient) xtitle(Percent No Capital) legend(order(1 2) label(1 "Point Estimate") label(2 "Linear Trend"))
		! rm $dir/tmp/`y_variable'_capital_naics_4.*
		graph2tex, epsfile($dir/tmp/`y_variable'_capital_naics_4)	
		file write `texhandle' ("\begin{figure}[H]") _n			
		file write `texhandle' ("\includegraphics[width=\linewidth]{`y_variable'_capital_naics_4}") _n
		file write `texhandle' ("\end{figure}") _n			
		restore
		
		file write `texhandle' ("\end{document}") _n
		file close `texhandle'	
		local old_dir = c(pwd)
		cd $dir/tmp
		! pdflatex --shell-escape `texfile' 
		cd `old_dir'

	}	
		
	*** Nonprofit industries with synthetic controls

	* set graphics off
	local MA 25
			
	eststo clear
	foreach y_variable in diff_ne_pop diff_em_pop {
	
		use $dir/tmp/synth_`y_variable'.dta, clear
		merge n:1 naics using $dir/tmp/nonprofit.dta
		* don't expect all naics to exist int he nonprofit data
		keep if _merge == 3
		drop _merge
		* shouldn't be necessary
		drop if missing(percent_nonprofit)
		gen nonprofit = percent_nonprofit >= .5
		tab naics nonprofit
		drop percent_nonprofit naicsdisplaylabel

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
		
		drop if year <= 2000
		keep if inlist(stcode, 0, 25)
		gen treatment_dd = (year >= 2008) & (nonprofit == 1)
		gen treatment_ddd = treatment_dd & stcode == 25
		egen county = group(stcode cntycd)
		set emptycells drop
		
		* leaving out non-time varying fixed effects since they get dropped
		* anyway but slow regression down dramatically
		gen year_dd = year
		eststo NP_DD_`y_variable': xtreg `y_variable' treatment_dd ib2007.year ib1.county if stcode == 25, fe robust	
		eststo NP_DDD_`y_variable': xtreg `y_variable' treatment_ddd i.naics#ib2007.year i.county#ib2007.year i.naics#i.county, fe robust

	}

	esttab NP_DD_diff_ne_pop NP_DDD_diff_ne_pop NP_DD_diff_em_pop NP_DDD_diff_em_pop using $dir/tmp/nonprofit.tex, ///
		varwidth(0) mtitles("(2) Non-Emp" "(3) Non-Emp" "(2) Small Est" "(3) Small Est")   ///
		varlabels(treatment_dd "Non-profit $\times$ Post 2007" ///
			treatment_ddd "Mass $\times$ Non-profit $\times$ Post 2007") ///
		keep(treatment_dd treatment_ddd)  ///
		indicate("County $\times$ Year FE = *.county#2008*" ///
			"Industry $\times$ Year FE = *.naics#2008*" ///
			"Industry $\times$ County FE = *.naics#1.county" ///
			"Year FE = 2008.year") ///
		nonumbers replace compress se r2 scalar("F F-test" "N_g Groups") sfmt(%9.3f %9.0f) b(3) starlevels(* 0.10 ** 0.05 *** 0.01 **** 0.001) ///
		addnotes("Model (2) is diff-in-diff of non-profits versus for profit firms." ///
			"Model (3) is triple diff with synthetic controls." ///
			"Non-Emp are establishments with zero employees." ///
			"Small Est are establishments with one to four employees.") 
		
	exit
			
	*** capital table with synthetic controls

	* set graphics off
	local MA 25
			
	foreach y_variable in diff_ne_pop { // diff_em_pop
	
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

		esttab _all using $dir/tmp/main_`y_variable'.tex, ///
			varwidth(0) mtitles("(4)" "(5)" "(6)" "(7)")   ///
			varlabels(treatment_dd "Low Capital $\times$ Post 2007" ///
				treatment_ddd "Mass $\times$ Low Capital $\times$ Post 2007" ///
				single_treat_dd "Low Capital $\times$ 2008" ///
				post_treat_dd "Low Capital $\times$ Post 2008" ///
				single_treat_ddd "Mass $\times$ Low Capital $\times$ 2008" ///
				post_treat_ddd "Mass $\times$ Low Capital $\times$ Post 2008") ///
			keep(treatment_dd treatment_ddd single_treat_dd post_treat_dd single_treat_ddd post_treat_ddd)  ///
			indicate("County $\times$ Year FE = *.county#200*" ///
				"Industry $\times$ Year FE = *.naics#200*" ///
				"Industry $\times$ County FE = *.naics#?.county" ///
				"Industry FE = *.naics" ///
				"County FE = ?.county" ///
				"Year FE = 200?.year") ///
			nonumbers replace compress se r2 scalar("F F-test" "N_g Groups" "p Short=Long") sfmt(%9.3f %9.0f) b(3) starlevels(* 0.10 ** 0.05 *** 0.01 **** 0.001) ///
			addnotes("Fixed effect model on `description'.") 
			
	}	
		
		
	exit	


	local level_count 0
	levelsof percent_no_funding, local(funding_levels) 
	foreach funding_level of local funding_levels {
		display `funding_level'
		if `level_count' > 1 {
			capture noisily: drop low_capital iTYear*
			gen low_capital = (percent_no_funding >= `funding_level')
			levelsof year, local(years)	
			foreach year of local years {
				if `year' == 2007 | `year' == 2000 continue
				gen iTYear`year' = (year == `year') & (stcode == 25) & (low_capital == 1)
			}
			xtreg `y_variable' iTYear* i.naics#ib2007.year i.county#ib2007.year, fe robust
			GraphPoint iTYear 2007 "DDD of Non-employers `funding_level'" "`y_variable'_ddd_synth_`level_count'"
		}
		local level_count = `level_count' + 1
	}	


	levelsof naics, local(industries) 
	foreach industry of local industries {
		levelsof year, local(years)
		foreach year of local years {
			if (`year' != 2007) {
				gen i_n_`industry'_`year' = `year' == year & `industry' == naics
			}
		}		
	}

	levelsof county  if stcode == 25, local(counties) 
	foreach county of local counties {
		levelsof year, local(years)
		foreach year of local years {
			if (`year' != 2007) {
				gen i_c_`county'_`year' = `year' == year & `county' == cntycd
			}
		}		
	}
	


	drop low_capital

	local titles	
	levelsof percent_no_funding, local(funding_levels) 
	foreach funding_level of local funding_levels {
		display `funding_level'
		gen low_capital = (percent_no_funding >= `funding_level')
		count if low_capital
		local low_count = r(N)
		count 
		local total_count = r(N)
		local quantile = `low_count' / `total_count'
		gen treatment = (year >= 2008) & (stcode == 25) & (low_capital == 1)
		quietly: eststo Q_DDD_`low_count': xtreg diff_ne_pop treatment i.naics#ib2007.year i.county#ib2007.year, fe robust
		drop low_capital treatment
		local titles `titles' `quantile'
	}
	esttab Q_DDD_* using "$dir/tmp/quantiles_ddd", ///
		mtitles(`titles')   ///
		rename(treatment "B") ///
		keep(B)  ///
		csv nobaselevels nonumbers replace compress ci  b(3) starlevels(* 0.10 ** 0.05 *** 0.01 **** 0.001)			


	local titles	
	levelsof percent_no_funding, local(funding_levels) 
	foreach funding_level of local funding_levels {
		display `funding_level'
		gen low_capital = (percent_no_funding >= `funding_level')
		count if low_capital
		local low_count = r(N)
		count 
		local total_count = r(N)
		local quantile = `low_count' / `total_count'
		gen treatment = (year == 2008) & (stcode == 25) & (low_capital == 1)
		gen treatment_a = (year > 2008) & (stcode == 25) & (low_capital == 1)
		quietly: eststo Q_DDD_`low_count': xtreg diff_ne_pop treatment treatment_a i.naics#ib2007.year i.county#ib2007.year, fe robust
		drop low_capital treatment treatment_a
		local titles `titles' `quantile'
	}
	esttab Q_DDD_* using "$dir/tmp/quantiles_2", ///
		mtitles(`titles')   ///
		rename(treatment "B" treatment_a "D") ///
		keep(B D)  ///
		csv nobaselevels nonumbers replace compress ci  b(3) starlevels(* 0.10 ** 0.05 *** 0.01 **** 0.001)			

			
	/*
	*** create naics captial table
	import delimited $dir/Data/Capital/SBO_2007_00CSCB15_with_ann.csv, varnames(1) rowrange(3) clear
	keep naicsdisplaylabel naicsid
	ren naicsid naics
	ren naicsdisplaylabel industry
	bysort naics: keep if _n == 1
	replace naics = "11" if strpos(naics,"11") 
	replace naics = "31" if strpos(naics,"31") 
	replace naics = "44" if strpos(naics,"44") 
	replace naics = "48" if strpos(naics,"48") 
	replace naics = "52" if strpos(naics,"52") 
	replace naics = "81" if strpos(naics,"81") 
	destring naics, replace
	drop if inlist(naics, 0, 99)

	merge 1:1 naics using $dir/tmp/capitalOld.dta
	ren percent_no_funding old
	keep if _merge != 2
	keep industry naics old	

	merge 1:1 naics using $dir/tmp/capitalNonemployer.dta
	ren percent_no_funding ne
	keep if _merge != 2
	keep industry naics old ne

	merge 1:1 naics using $dir/tmp/capital.dta
	ren percent_no_funding emp
	keep if _merge != 2	
	keep industry naics old	ne emp

	label variable naics "Naics"
	label variable industry "Description"
	label variable old "Original"
	label variable ne "No Employees"
	label variable emp "1 to 4 Employees"

	format old ne emp %4.1f
	format naics %4.0g
	flist naics industry old ne emp, notrim
	
	*stata doesn't seem like \w\W or \s\S as a wildcard grouping
	replace industry = regexr(industry, "\([^_]*\)", "")
	* can also shorten industry using str25 etc casting
	gsort - old
	gen star_old = (_n < 4)
	gsort - ne
	gen star_ne = (_n < 4)
	gsort - emp
	gen star_emp = (_n < 4)	
	gsort - naics
	gsort - ne
	
	tostring naics old ne emp, usedisplayformat replace force
	replace old = old + "%" if old != "."
	replace ne = ne + "%" if ne != "."
	replace emp = emp + "%" if emp != "."
	replace old = old + "*" if star_old
	replace ne = ne + "*" if star_ne
	replace emp = emp + "*"  if star_emp

	
	texsave naics industry ne emp old using $dir/tmp/capital.tex, ///
		replace varlabels align(cXccc) location("H") frag title("Percent of establishments requiring captial") ///
		footnote("Star on top 3 industries in each version")
	clear
	
	*** Chart firm net change versus new establishment net change
	/*

	Not sure this does anything useful right now since I just have one year of data. 
	Perhaps can look at the relative number of establishments versus firms? 
	
	import delimited $dir/Data/Firms/SBO_2007_00CSA01_with_ann.csv, varnames(2) clear
	keep if gendercode == 1
	keep if ethnicitycode == 1
	keep if racecode == 0
	keep naicscode year numberoffirms*
	replace naicscode = regexr(naicscode, "\([^_]*\)", "")
	replace naicscode = regexr(naicscode, "\-[^_]*", "")
	destring naicscode numberoffirms*, replace
	rename naicscode naics
	
	*** next take a look at infogroup data
	use $dir/tmp/infogroup_all.dta, clear
	bysort year: egen firm_entry = total(newFirms)
	bysort year: keep if _n == 1
	keep year firm_entry
	save $dir/tmp/infogroup_tmp.dta, replace

	local filename $dir/Data/Firms/bds_f_agesz_release.csv
	local title "Census Est Entry versus Infogroup New Firms (US)"
	local graphfile "$dir/tmp/est_info_US"
	
	import delimited `filename', varnames(1) clear
	drop job* *_rate net_* *emp	
	
	bysort year: egen total_entry = total(estabs_entry)
	bysort year: keep if _n == 1
	ren year2 year 
	keep year total_entry
	
	merge 1:1 year using $dir/tmp/infogroup_tmp.dta
	drop if _merge == 1
	drop _merge
	
	graph twoway ///
		(scatter total_entry year, msymbol(+)) ///
		(scatter firm_entry year, msymbol(X)) ///
		, title(`title') ytitle(Count) xtitle(Year) legend(order(1 2) label(1 "Est Entry") label(2 "Infogroup New Firm"))
	graph2tex, epsfile(`graphfile')				
	!rm $dir/tmp/infogroup_tmp.dta
	

	*** now do the state and county diff-diff without any industry data
	
	
	
	* create weights
	gen weight_tmp = population if year == 2008
	bysort panel: egen weight = mean(weight_tmp)
	drop weight_tmp
		
	local fixed_effects ib2007.year
	foreach variable of varlist diff_se_pop diff_em_pop diff_ne_pop {

		local title "Self-Employment Diff-Diff"
		local graphTitle "Self_Employment"
		if "`variable'"	== "diff_em_pop" {
			local title "1-4 Worker Establishment Diff-Diff"
			local graphTitle "1_4_Establishment"
		}
		if "`variable'"	== "diff_ne_pop" {
			local title "0 Worker Establishment Diff-Diff"
			local graphTitle "0_Establishment"
		}

		eststo c_s_w: xtreg `variable' treatment `fixed_effects' [aw=weight], fe robust
		estadd local w "Population" 
		estadd local c "County"
		eststo c_s_w_c: xtreg `variable' treatment `fixed_effects' [aw=weight], fe robust cluster(stcode)
		estadd local w "Population" 
		estadd local c "State"
		eststo c_s: xtreg `variable' treatment `fixed_effects', fe robust
		estadd local w "None" 
		estadd local c "County"
		eststo c_s_c: xtreg `variable' treatment `fixed_effects', fe robust cluster(stcode)
		estadd local w "None" 
		estadd local c "State"

		esttab c_s_w c_s_w_c c_s c_s_c using $dir/tmp/`variable'_county_simple.tex, ///
			mtitles("(1)"  "(2)"  "(3)" "(4)")   ///
			keep("$\beta$")  ///
			rename(treatment "$\beta$") ///
			nobaselevels nonumbers replace compress se r2 scalar("F F-test" "N_g Groups" "w Weight" "c Cluster") ///
			indicate("Year FE = *.year") ///
			sfmt(%9.3f %9.0f) b(3) starlevels(* 0.10 ** 0.05 *** 0.01 **** 0.001)	

		levelsof year, local(years)	
		foreach year of local years {
			if `year' == 2007 | `year' == 2000 continue
			gen iYear`year' = year == `year'
			gen iTYear`year' = (year == `year') & (stcode == 25)
		}
		local t = "`graphTitle'" + "_Weighted"
		xtreg `variable' iYear* iTYear* [aw=weight], fe robust
		GraphPoint iTYear 2007 `t'

		local t = "`graphTitle'" + "_Unweighted"
		xtreg `variable' iYear* iTYear*, fe robust
		GraphPoint iTYear 2007 `t'
		
		drop iYear* iTYear*
	
	}

	*** starting synthetic controls
	
	* need to reload the dataset since earlier we dropped non-new england states
	eststo clear
	use $dir/tmp/all_states_tmp.dta, clear


	keep treatment year panel diff_se_pop diff_em_pop diff_ne_pop stcode cntycd log_income percent_uninsured percent_20_to_24 percent_urban

	drop if year == 2000
	
	* set graphics off
	local treatment 2008
	local MA 25
	
	local titles
	foreach y_variable of varlist diff_se_pop diff_em_pop diff_ne_pop {
	
		local title "Self-Employment"
		local graphTitle "Self_Employment_Synth"
		if "`y_variable'" == "diff_em_pop" {
			local title "1-4 Worker"
			local graphTitle "1_4_Establishment_Synth"
		}
		if "`y_variable'" == "diff_ne_pop" {
			local title "0 Worker"
			local graphTitle "0_Establishment_Synth"
		}
	
		levelsof cntycd if stcode == `MA', local(counties)
		foreach county of local counties {

			preserve

			* picking counties with similar predictor values
			local max_sd 1
			sort stcode cntycd
			by stcode cntycd: gen tag = _n == 1
			local predictors log_income percent_20_to_24 percent_urban percent_uninsured		

			foreach predictor of varlist `predictors' {	
				by stcode cntycd: egen st_mean = mean(`predictor')
				su st_mean if tag
				local max_d = `max_sd' * r(sd)
				su st_mean if stcode == `MA' & cntycd == `county'
				drop if st_mean >  r(mean) + `max_d' | st_mean < r(mean) - `max_d'
				su st_mean if tag
				drop st_mean
			}
			drop tag
			
			* drop counties that are missing our y_variable in some years
			by stcode cntycd: egen t_variable = count(`y_variable')
			su t_variable
			drop if t_variable < r(max) & stcode != `MA'			
			drop t_variable
			
			* should only be one
			levelsof panel if stcode == `MA' & cntycd == `county', local(trunit)
			levelsof panel if stcode != `MA', local(counit)		
			synth `y_variable' ///
				`y_variable'(2001) `y_variable'(2002) `y_variable'(2003) `y_variable'(2004) `y_variable'(2005) `y_variable'(2006) `y_variable'(2007) ///
				log_income percent_20_to_24 percent_urban percent_uninsured ///
				, trunit(`trunit') trperiod(`treatment') counit(`counit') ///
				keep("$dir/tmp/synth_`county'") replace				
				
			restore
		}					

		* next recreate the control as separate counties
		gen e = 2 if stcode == `MA'
		expand e, gen(d)
		drop e
		replace panel = -panel if d == 1
		replace `y_variable' = . if d == 1
		replace stcode = 0 if d == 1
		
		gen _Co_Number = panel
		
		levelsof cntycd if stcode == `MA', local(counties)
		foreach county of local counties {
		
			merge n:1 _Co_Number using "$dir/tmp/synth_`county'.dta", assert(1 3)
			drop _Y_treated _Y_synthetic _time _merge

			gen w_diff = _W_Weight * `y_variable'
			bysort year: egen c_diff = total(w_diff)
			replace `y_variable' = c_diff if d == 1 & stcode == 0 & cntycd == `county'
			drop w_diff c_diff _W_Weight

		}
		
		drop d _Co_Number
		
		local titles `titles' "`title'"
		eststo s_`y_variable': xtreg `y_variable' treatment ib2007.year if inlist(stcode, 0,25), fe robust
		estadd local w "None" 
		estadd local c "County"

		levelsof year, local(years)	
		foreach year of local years {
			if `year' == 2007 | `year' == 2000 continue
			gen iYear`year' = year == `year'
			gen iTYear`year' = (year == `year') & (stcode == 25)
		}
		preserve
		keep if inlist(stcode, 0,25)
		xtreg `y_variable' iYear* iTYear*, fe robust
		GraphPoint iTYear 2007 `graphTitle'
		restore		
		drop iYear* iTYear*					
		drop if stcode == 0
	}

	esttab _all using $dir/tmp/county_synth.tex, ///
		mtitles(`titles')   ///
		keep("$\beta$")  ///
		rename(treatment "$\beta$") ///
		nobaselevels nonumbers replace compress se r2 scalar("F F-test" "N_g Groups" "w Weight" "c Cluster") ///
		indicate("Year FE = *.year") ///
		sfmt(%9.3f %9.0f) b(3) starlevels(* 0.10 ** 0.05 *** 0.01 **** 0.001)	

	*** Now running NAICS 2 synth diff-diff
	eststo clear
	use $dir/tmp/nonemployed.dta, clear
	drop if inlist(naics, 62, 95, 99)
	drop if year < 2000
	ren small ne_est	
	keep ne_est stcode cntycd naics year	
	* dropping naics that MA counties do not have much of
	bysort stcode cntycd naics: egen t_est = total(ne_est)
	drop if t_est < 1000 & stcode == 25
	drop t_est	
	save $dir/tmp/ne_tmp.dta, replace
	
	use $dir/tmp/countyBusiness.dta, clear
	rename naics_2 naics
	drop if missing(naics)
	drop if inlist(naics, 62, 95, 99)
	ren n1_4 emp_est
	drop if cntycd == 999
	keep emp_est stcode cntycd naics year
	bysort stcode cntycd naics: egen t_est = total(emp_est)
	drop if t_est < 1000 & stcode == 25
	drop t_est	

	merge 1:1 stcode cntycd naics year using $dir/tmp/ne_tmp.dta
	* note we have some missing data in MA since for some industries in 
	* some counties there are non-employer but no employers and visa-versa
	drop _merge

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
	tsfill, full	
	bysort panel: egen stcode_tmp = mean(stcode)
	drop stcode
	rename stcode_tmp stcode
	bysort panel: egen naics_tmp = mean(naics)
	drop naics
	rename naics_tmp naics
	bysort panel: egen cntycd_tmp = mean(cntycd)
	drop cntycd
	rename cntycd_tmp cntycd	
	bysort panel: egen t_emp = count(emp_est)
	bysort panel: egen t_ne = count(ne_est)
	replace emp_est = 0 if missing(emp_est) & t_emp > 0
	replace ne_est = 0 if missing(ne_est) & t_ne > 0
	drop t_emp t_ne
	
	sort panel year	
	gen em_pop = emp_est / population
	gen ne_pop = ne_est / population
	gen diff_em_pop = D.em_pop
	gen diff_ne_pop = D.ne_pop

	* gen control = inlist(stcode, 9, 23, 25, 33, 44, 50)
	gen treatment = stcode == 25 & year > 2007

	rename year year_tmp
	gen year = 2006
	merge n:1 stcode year using "$dir/tmp/MedianIncomeState.dta"
	drop year
	rename year_tmp year
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge
	gen log_income = log(income)
	drop(income)

	* percent aged 20-24 or so since MA has a lot of universities
	* child dependancy ratio
	* this is currently using 2000 year data
	merge n:1 stcode cntycd using "$dir/tmp/ageGroup.dta"
	count if _merge == 1
	* assert(r(N)==0)
	bysort panel: egen error = total(_merge == 1)
	drop if error
	drop error	
	drop if _merge == 2
	drop _merge
	
	* percent with healthcare
	* using 2005 data
	merge n:1 stcode cntycd using "$dir/tmp/insurance.dta"
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge

	* urban population
	* using 2000 year data
	merge n:1 stcode cntycd using "$dir/tmp/urban.dta"
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge

	keep treatment naics year panel diff_em_pop diff_ne_pop stcode cntycd log_income percent_uninsured percent_20_to_24 percent_urban

	drop if year == 2000
	
	* set graphics off
	local treatment 2008
	local MA 25
	local maxEstimatesPerTable 5
			
	foreach y_variable of varlist diff_em_pop diff_ne_pop {
	
		gen `y_variable'Beta = .
	
		local titles
		local tableCount 1
		
		local title "1-4 Worker"
		local graphTitle "1_4_Establishment_Synth"
		local capitalFile "$dir/tmp/capital.dta"
		if "`y_variable'" == "diff_ne_pop" {
			local title "0 Worker"
			local graphTitle "0_Establishment_Synth"
			local capitalFile "$dir/tmp/capitalNonemployer.dta"
		}
	
		levelsof naics if stcode == `MA' & !missing(`y_variable'), local(industries)
		foreach industry of local industries {

			levelsof cntycd if stcode == `MA' & naics == `industry' & !missing(`y_variable'), local(counties)
			foreach county of local counties {
			
				preserve

				* picking counties with similar predictor values
				local max_sd 1
				sort stcode cntycd
				by stcode cntycd: gen tag = _n == 1
				local predictors log_income percent_20_to_24 percent_urban percent_uninsured		

				foreach predictor of varlist `predictors' {	
					by stcode cntycd: egen st_mean = mean(`predictor')
					su st_mean if tag
					local max_d = `max_sd' * r(sd)
					su st_mean if stcode == `MA' & cntycd == `county'
					drop if st_mean >  r(mean) + `max_d' | st_mean < r(mean) - `max_d'
					su st_mean if tag
					drop st_mean
				}
				drop tag
				
				* drop counties that are missing our y_variable in some years
				by stcode cntycd: egen t_variable = count(`y_variable') if naics == `industry'
				su t_variable
				drop if t_variable < r(max) & stcode != `MA'			
				drop t_variable
				
				* should only be one
				levelsof panel if stcode == `MA' & cntycd == `county' & naics == `industry', local(trunit)
				levelsof panel if stcode != `MA' & naics == `industry', local(counit)		
				synth `y_variable' ///
					`y_variable'(2001) `y_variable'(2002) `y_variable'(2003) `y_variable'(2004) `y_variable'(2005) `y_variable'(2006) `y_variable'(2007) ///
					log_income percent_20_to_24 percent_urban percent_uninsured ///
					, trunit(`trunit') trperiod(`treatment') counit(`counit') ///
					keep("$dir/tmp/synth_`county'_`industry'_`y_variable'") replace				
					
				restore
			}

			* next recreate the control as separate counties
			gen e = 2 if stcode == `MA'
			expand e, gen(d)
			drop e
			replace panel = -panel if d == 1
			replace `y_variable' = . if d == 1
			replace stcode = 0 if d == 1
			
			gen _Co_Number = panel
			
			levelsof cntycd if stcode == `MA' & naics == `industry' & !missing(`y_variable'), local(counties)
			foreach county of local counties {
			
				display "Merging County:`county' Industry:`industry'"
				merge n:1 _Co_Number using "$dir/tmp/synth_`county'_`industry'_`y_variable'.dta", assert(1 3)
				* merge n:1 _Co_Number using "$dir/tmp/synth_`county'_`industry'.dta", assert(1 3)
				drop _Y_treated _Y_synthetic _time _merge

				gen w_diff = _W_Weight * `y_variable'
				bysort year: egen c_diff = total(w_diff)
				replace `y_variable' = c_diff if d == 1 & stcode == 0 & cntycd == `county' & naics == `industry'
				drop w_diff c_diff _W_Weight

			}
			
			drop d _Co_Number
			
			local titles `titles' "`industry'"
			eststo s_`y_variable'_`industry': xtreg `y_variable' treatment ib2007.year if inlist(stcode, 0,25) & naics == `industry', fe robust
			replace `y_variable'Beta = _b[treatment] if naics == `industry'
			estadd local w "None" 
			estadd local c "County"

			levelsof year, local(years)	
			foreach year of local years {
				if `year' == 2007 | `year' == 2000 continue
				gen iYear`year' = year == `year'
				gen iTYear`year' = (year == `year') & (stcode == 25)
			}
			preserve
			keep if inlist(stcode, 0,25)
			keep if naics == `industry'
			capture: xtreg `y_variable' iYear* iTYear*, fe robust
			if !inlist(_rc,0,2001){
				exit _rc
			}
			if _rc == 2001 {
				display "Not enough observations with `y_variable' in industry`industry'"
			}
			if _rc == 0 {
				GraphPoint iTYear 2007 "`graphTitle'_`industry'"
			}
			restore		
			drop iYear* iTYear*					
			drop if stcode == 0
			
			* want to keep the number of estimates per table capped at 5
			if $eststo_counter >= `maxEstimatesPerTable' {
				esttab _all using $dir/tmp/`y_variable'_naics_2_synth`tableCount'.tex, ///
					mtitles(`titles')   ///
					keep("Massachusetts $\times$ Post 2007")  ///
					rename(treatment "Massachusetts $\times$ Post 2007") ///
					nobaselevels nonumbers replace compress se r2 scalar("F F-test" "N_g Groups" "w Weight" "c Cluster") ///
					indicate("Year FE = *.year") ///
					sfmt(%9.3f %9.0f) b(3) starlevels(* 0.10 ** 0.05 *** 0.01 **** 0.001)					
				eststo clear
				local tableCount = `tableCount' + 1
				local titles
			}			
			
		}


		if $eststo_counter + 0 > 0 {
			esttab _all using $dir/tmp/`y_variable'_naics_2_synth`tableCount'.tex, ///
				mtitles(`titles')   ///
				keep("Massachusetts $\times$ Post 2007")  ///
				rename(treatment "Massachusetts $\times$ Post 2007") ///
				nobaselevels nonumbers replace compress se r2 scalar("F F-test" "N_g Groups" "w Weight" "c Cluster") ///
				indicate("Year FE = *.year") ///
				sfmt(%9.3f %9.0f) b(3) starlevels(* 0.10 ** 0.05 *** 0.01 **** 0.001)	
			eststo clear
		}
				
		preserve
		keep `y_variable'Beta naics
		bysort `y_variable'Beta naics: keep if _n == 1
		merge 1:1 naics using `capitalFile'
		keep if _merge == 3
		drop _merge
		graph twoway ///
			(scatter `y_variable'Beta percent_no_funding, msymbol(+)) ///
			(lfit `y_variable'Beta percent_no_funding, lcolor(midblue)) ///
			, title(`title') ytitle(Coefficient) xtitle(Percent No Capital) legend(order(1 2) label(1 "Point Estimate") label(2 "Linear Trend"))
		graph2tex, epsfile($dir/tmp/`y_variable'_capital_naics_2)			
		restore

	}
	*/

	exit
	
	*** Now running NAICS 4 synth diff-diff
	eststo clear
	use $dir/tmp/nonemployedLong.dta, clear
	* get rid of the same naics industies we dropped above
	drop if naics >= 9900 & naics < 10000
	* above 6240 consists of things like homeless shelters, not health related
	drop if naics >= 6200 & naics < 6240
	drop if naics >= 9500 & naics < 9600
	drop if year < 2000
	ren small ne_est	
	keep ne_est stcode cntycd naics year	
	* dropping naics that MA counties do not have much of
	bysort stcode cntycd naics: egen t_est = total(ne_est)
	drop if t_est < 1000 & stcode == 25
	drop t_est	
	save $dir/tmp/ne_tmp.dta, replace
	
	use $dir/tmp/countyBusinessLong.dta, clear
	drop if naics >= 9900 & naics < 10000
	drop if naics >= 6200 & naics < 6240
	drop if naics >= 9500 & naics < 9600
	ren small emp_est
	drop if cntycd == 999
	keep emp_est stcode cntycd naics year
	bysort stcode cntycd naics: egen t_est = total(emp_est)
	drop if t_est < 1000 & stcode == 25
	drop t_est	

	merge 1:1 stcode cntycd naics year using $dir/tmp/ne_tmp.dta
	* note we have some missing data in MA since for some industries in 
	* some counties there are non-employer but no employers and visa-versa
	drop _merge

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
	
	* full panel generated in data files, not needed here
	/*	
	tsfill, full	
	bysort panel: egen stcode_tmp = mean(stcode)
	drop stcode
	rename stcode_tmp stcode
	bysort panel: egen naics_tmp = mean(naics)
	drop naics
	rename naics_tmp naics
	bysort panel: egen cntycd_tmp = mean(cntycd)
	drop cntycd
	rename cntycd_tmp cntycd	
	bysort panel: egen t_emp = count(emp_est)
	bysort panel: egen t_ne = count(ne_est)
	replace emp_est = 0 if missing(emp_est) & t_emp > 0
	replace ne_est = 0 if missing(ne_est) & t_ne > 0
	drop t_emp t_ne
	*/
	
	sort panel year	
	gen em_pop = emp_est / population
	gen ne_pop = ne_est / population
	gen diff_em_pop = D.em_pop
	gen diff_ne_pop = D.ne_pop

	* gen control = inlist(stcode, 9, 23, 25, 33, 44, 50)
	gen treatment = stcode == 25 & year > 2007

	rename year year_tmp
	gen year = 2006
	merge n:1 stcode year using "$dir/tmp/MedianIncomeState.dta"
	drop year
	rename year_tmp year
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge
	gen log_income = log(income)
	drop(income)

	* percent aged 20-24 or so since MA has a lot of universities
	* child dependancy ratio
	* this is currently using 2000 year data
	merge n:1 stcode cntycd using "$dir/tmp/ageGroup.dta"
	count if _merge == 1
	* assert(r(N)==0)
	bysort panel: egen error = total(_merge == 1)
	drop if error
	drop error	
	drop if _merge == 2
	drop _merge
	
	* percent with healthcare
	* using 2005 data
	merge n:1 stcode cntycd using "$dir/tmp/insurance.dta"
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge

	* urban population
	* using 2000 year data
	merge n:1 stcode cntycd using "$dir/tmp/urban.dta"
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge

	keep treatment naics year panel diff_em_pop diff_ne_pop stcode cntycd log_income percent_uninsured percent_20_to_24 percent_urban
	compress

	drop if year == 2000
	
	* set graphics off
	local treatment 2008
	local MA 25
	local maxEstimatesPerTable 5
			
	foreach y_variable of varlist diff_em_pop { // diff_ne_pop {
	
		gen `y_variable'Beta = .
	
		local titles
		local tableCount 1
		
		local title "1-4 Worker"
		local graphTitle "1_4_Establishment_Synth"
		local capitalFile "$dir/tmp/capital.dta"
		if "`y_variable'" == "diff_ne_pop" {
			local title "0 Worker"
			local graphTitle "0_Establishment_Synth"
			local capitalFile "$dir/tmp/capitalNonemployer.dta"
		}
	
		levelsof naics if stcode == `MA' & !missing(`y_variable'), local(industries)
		foreach industry of local industries {

			levelsof cntycd if stcode == `MA' & naics == `industry' & !missing(`y_variable'), local(counties)
			foreach county of local counties {

				* also skip if county did not have data for all years
				count if stcode == `MA' & cntycd == `county' & naics == `industry' & !missing(`y_variable')
				if r(N) == 12 {				
			
					preserve

					* picking counties with similar predictor values
					local max_sd 1
					sort stcode cntycd
					by stcode cntycd: gen tag = _n == 1
					local predictors log_income percent_20_to_24 percent_urban percent_uninsured		

					foreach predictor of varlist `predictors' {
						* for the percentage predictors, do I model as a uniform and use p(1-p) as variance?
						by stcode cntycd: egen st_mean = mean(`predictor')
						su st_mean if tag
						local max_d = `max_sd' * r(sd)
						su st_mean if stcode == `MA' & cntycd == `county'
						drop if st_mean >  r(mean) + `max_d' | st_mean < r(mean) - `max_d'
						su st_mean if tag
						drop st_mean
					}
					drop tag
					
					* drop counties that are missing our y_variable in some years
					by stcode cntycd: egen t_variable = count(`y_variable') if naics == `industry'
					su t_variable
					drop if t_variable < r(max) & stcode != `MA'			
					drop t_variable
					
					* should only be one
					levelsof panel if stcode == `MA' & cntycd == `county' & naics == `industry', local(trunit)
					levelsof panel if stcode != `MA' & naics == `industry', local(counit)		
					synth `y_variable' ///
						`y_variable'(2001) `y_variable'(2002) `y_variable'(2003) `y_variable'(2004) `y_variable'(2005) `y_variable'(2006) `y_variable'(2007) ///
						log_income percent_20_to_24 percent_urban percent_uninsured ///
						, trunit(`trunit') trperiod(`treatment') counit(`counit') ///
						keep("$dir/tmp/synth_`county'_`industry'_`y_variable'") replace	
					
					* sometimes we have fewer controls than years which causes merge to 
					* fail later because there are multiple missing _Co_Number values
					* due to the way synth saves its output
					use $dir/tmp/synth_`county'_`industry'_`y_variable', clear			
					drop if missing(_Co)
					save $dir/tmp/synth_`county'_`industry'_`y_variable', replace
											
					restore
				}

			}

			* next recreate the control as separate counties
			gen e = 2 if stcode == `MA'
			expand e, gen(d)
			drop e
			replace panel = -panel if d == 1
			replace `y_variable' = . if d == 1
			replace stcode = 0 if d == 1
			
			replace treatment = 0 if stcode == 0
			
			gen _Co_Number = panel
			
			levelsof cntycd if stcode == `MA' & naics == `industry' & !missing(`y_variable'), local(counties)
			foreach county of local counties {

				count if stcode == `MA' & cntycd == `county' & naics == `industry' & !missing(`y_variable')
				if r(N) == 12 {							
					display "Merging County:`county' Industry:`industry'"
					merge n:1 _Co_Number using "$dir/tmp/synth_`county'_`industry'_`y_variable'.dta", assert(1 3)
					* merge n:1 _Co_Number using "$dir/tmp/synth_`county'_`industry'.dta", assert(1 3)
					drop _Y_treated _Y_synthetic _time _merge

					gen w_diff = _W_Weight * `y_variable'
					bysort year: egen c_diff = total(w_diff)
					replace `y_variable' = c_diff if d == 1 & stcode == 0 & cntycd == `county' & naics == `industry'
					drop w_diff c_diff _W_Weight
				}
				else {
					replace `y_variable' = . if stcode == `MA' & cntycd == `county' & naics == `industry'
				}

			}
			
			drop d _Co_Number
			
			capture: eststo s_`y_variable'_`industry': xtreg `y_variable' treatment ib2007.year if inlist(stcode, 0,25) & naics == `industry', fe robust
			if !inlist(_rc,0,2000,2001){
				exit _rc
			}
			if _rc == 2001 {
				display "Main: not enough observations with `y_variable' in industry `industry'"
			}
			if _rc == 2000 {
				display "Main: No observations with `y_variable' in industry `industry'"
			}
			if _rc == 0 {
				local titles `titles' "`industry'"
				replace `y_variable'Beta = _b[treatment] if naics == `industry'
				estadd local w "None" 
				estadd local c "County"
			}

			levelsof year, local(years)	
			foreach year of local years {
				if `year' == 2007 | `year' == 2000 continue
				gen iYear`year' = year == `year'
				gen iTYear`year' = (year == `year') & (stcode == 25)
			}
			preserve
			keep if inlist(stcode, 0,25)
			keep if naics == `industry'
			capture: xtreg `y_variable' iYear* iTYear*, fe robust
			if !inlist(_rc,0,2000,2001){
				exit _rc
			}
			if _rc == 2000 {
				display "Graph: No observations with `y_variable' in industry `industry'"
			}
			if _rc == 2001 {
				display "Graph: Not enough observations with `y_variable' in industry `industry'"
			}
			if _rc == 0 {
				GraphPoint iTYear 2007 "`graphTitle'_`industry'"
			}
			restore		
			drop iYear* iTYear*					
			drop if stcode == 0
			
			* want to keep the number of estimates per table capped at 5
			if $eststo_counter >= `maxEstimatesPerTable' {
				esttab _all using $dir/tmp/`y_variable'_naics_4_synth`tableCount'.tex, ///
					mtitles(`titles')   ///
					keep("Massachusetts $\times$ Post 2007")  ///
					rename(treatment "Massachusetts $\times$ Post 2007") ///
					nobaselevels nonumbers replace compress se r2 scalar("F F-test" "N_g Groups" "w Weight" "c Cluster") ///
					indicate("Year FE = *.year") ///
					sfmt(%9.3f %9.0f) b(3) starlevels(* 0.10 ** 0.05 *** 0.01 **** 0.001)					
				eststo clear
				local tableCount = `tableCount' + 1
				local titles
			}			
			
		}


		if $eststo_counter + 0 > 0 {
			esttab _all using $dir/tmp/`y_variable'_naics_4_synth`tableCount'.tex, ///
				mtitles(`titles')   ///
				keep("Massachusetts $\times$ Post 2007")  ///
				rename(treatment "Massachusetts $\times$ Post 2007") ///
				nobaselevels nonumbers replace compress se r2 scalar("F F-test" "N_g Groups" "w Weight" "c Cluster") ///
				indicate("Year FE = *.year") ///
				sfmt(%9.3f %9.0f) b(3) starlevels(* 0.10 ** 0.05 *** 0.01 **** 0.001)	
			eststo clear
		}
				
		preserve
		keep `y_variable'Beta naics
		bysort `y_variable'Beta naics: keep if _n == 1
		merge 1:1 naics using `capitalFile'
		keep if _merge == 3
		drop _merge
		graph twoway ///
			(scatter `y_variable'Beta percent_no_funding, msymbol(+)) ///
			(lfit `y_variable'Beta percent_no_funding, lcolor(midblue)) ///
			, title(`title') ytitle(Coefficient) xtitle(Percent No Capital) legend(order(1 2) label(1 "Point Estimate") label(2 "Linear Trend"))
		graph2tex, epsfile($dir/tmp/`y_variable'_capital_naics_4)			
		restore

	}
*/	
	
end

program define ReplicateTuzemenBecker

	use "$dir/tmp/Employment.dta", clear
	sort stcode year
	* no state information should exist in the dataset
	drop if cntycd == 0
	by stcode year: egen total_pop = total(population)
	by stcode year: egen total_self = total(self_employed)
	by stcode year: egen total_emp = total(employed)
	by stcode year: keep if _n == 1
	gen self_pop = total_self / total_pop
	gen self_emp = total_self / total_emp
	keep stcode year self_pop self_emp

end

//ReplicateTuzemenBecker
PaperOutput
//StateDiff
//MatchingState
//SummaryStats_NaicsLoop_4
//IndustryFrequency
//InfogroupVersion
//BuildInfogroupClean
//SummaryStatisticsLong
//fullCountyPanel
//Nonprofit
//TestWeights
//Kickstarter
//SummaryStatistics
//CapitalImpact
//MatchingCounty
//MatchingNaics
//CountyBusinessNewEngland
//CountyBusinessTest
//NonemployedTest_Loop
//IntensityTest
//EmploymentTest
//BuildNewEnglandData
//SummaryStats
//SummaryStats_intraMA
