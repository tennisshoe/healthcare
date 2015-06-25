clear all
set more off
global dir "~/Healthcare"

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

	tostring `treatment_variable', replace
	
	tempvar blue_mean red_mean
	sort year
	by year: egen `blue_mean' = mean(`y_variable') if `treatment_variable' == "`treatment_value'"
	by year: egen `red_mean' = mean(`y_variable') if `treatment_variable' != "`treatment_value'"
	
	graph twoway (scatter `blue_mean' year if `treatment_variable' == "`treatment_value'", mcolor(midblue) xline(`cutoff', lcolor(black))) ///
		(lpoly `y_variable' year if year < `cutoff' & `treatment_variable' == "`treatment_value'", lcolor(midblue) degree(1)) ///
		(lpoly `y_variable' year if year >= `cutoff' & `treatment_variable' == "`treatment_value'", lcolor(midblue) degree(1)) ///
		(scatter `red_mean' year if `treatment_variable' != "`treatment_value'", mcolor(cranberry)) ///
		(lpoly `y_variable' year if year < `cutoff' & `treatment_variable' != "`treatment_value'", lcolor(cranberry) degree(1)) ////
		(lpoly `y_variable' year if year >= `cutoff' & `treatment_variable' != "`treatment_value'", lcolor(cranberry) degree(1)) ///
		, ytitle(Residual rate of new firms) yscale(titlegap(3)) ylabel(, labsize(small)) xtitle(Year) xlabel(2001 2004 2008 2012, labsize(small)) legend(order(1 4) label(1 "Low Capital Industries") label(4 "High Capital Industries") cols(1) size(small)) graphregion(fcolor(dimgray))
	graph2tex, epsfile("$dir/tmp/residuals")	
		
	drop `blue_mean' `red_mean'

	capture: destring `treatment_variable', replace
		
end


program define GraphGeneric
	args y_variable cutoff treatment_variable treatment_value title 

	tostring `treatment_variable', replace
	
	tempvar blue_mean red_mean
	sort year
	by year: egen `blue_mean' = mean(`y_variable') if `treatment_variable' == "`treatment_value'"
	by year: egen `red_mean' = mean(`y_variable') if `treatment_variable' != "`treatment_value'"
	
	graph twoway (scatter `blue_mean' year if `treatment_variable' == "`treatment_value'", mcolor(blue) xline(`cutoff', lcolor(black))) ///
		(lpoly `y_variable' year if year < `cutoff' & `treatment_variable' == "`treatment_value'", lcolor(blue) degree(1)) ///
		(lpoly `y_variable' year if year >= `cutoff' & `treatment_variable' == "`treatment_value'", lcolor(blue) degree(1)) ///
		(scatter `red_mean' year if `treatment_variable' != "`treatment_value'", mcolor(red)) ///
		(lpoly `y_variable' year if year < `cutoff' & `treatment_variable' != "`treatment_value'", lcolor(red) degree(1)) ////
		(lpoly `y_variable' year if year >= `cutoff' & `treatment_variable' != "`treatment_value'", lcolor(red) degree(1)) ///
		, legend(off) subtitle("`title'")
		
	drop `blue_mean' `red_mean'

	capture: destring `treatment_variable', replace

		
end

program define GraphPlain
	args y_variable cutoff treatment_variable treatment_value title
	
	graph twoway (lpoly `y_variable' year if year < `cutoff' & `treatment_variable' == "`treatment_value'", lcolor(blue) degree(1)) ///
		(lpoly `y_variable' year if year >= `cutoff' & `treatment_variable' == "`treatment_value'", lcolor(blue) degree(1)) ///
		(lpoly `y_variable' year if year < `cutoff' & `treatment_variable' != "`treatment_value'", lcolor(red) degree(1)) ////
		(lpoly `y_variable' year if year >= `cutoff' & `treatment_variable' != "`treatment_value'", lcolor(red) degree(1)), ///
		legend(off) subtitle("`title'")
		
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

program define SummaryStats_NaicsLoop_2

	* need to think about how to handle counties with no new firms that year
	use "$dir/tmp/NewEngland.dta", clear
	
	levelsof naics_2, local(naics_codes)
	foreach naics_code in `naics_codes' { 

		preserve 
		
		keep if naics_2 == `naics_code'
		count
		if r(N) < 100 {
			restore
			continue
		}
	
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
		
		local y_variable diff

		set graphics off
		GraphGeneric diff 2007 state "MA" `naics_code'
		graph2tex, epsfile("$dir/tmp/`naics_code'")	
		set graphics on 

		restore
	}

	ReportResults naics_2
end


program define SummaryStats_NaicsLoop_4

	* need to think about how to handle counties with no new firms that year
	use "$dir/tmp/NewEngland.dta", clear
	
	levelsof naics_4, local(naics_codes)
	foreach naics_code in `naics_codes' { 

		preserve 
		
		keep if naics_4 == `naics_code'
		count
		if r(N) < 100 {
			restore
			continue
		}
	
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
		
		local y_variable diff

		set graphics off
		GraphGeneric diff 2007 state "MA" `naics_code'
		graph2tex, epsfile("$dir/tmp/`naics_code'")	
		set graphics on 

		restore
	}

	ReportResults naics_4

	exit

	graph twoway (scatter `y_variable' year if state == "MA", mcolor(blue)) ///
		(lpoly `y_variable' year if state == "MA", lcolor(blue) degree(1)) ///





	keep if naics_2 == 55


	* bysort stcode year: egen new_firms = count(year)	
	* bysort stcode year: egen state_pop = total(population)
	* bysort stcode year: drop if _n > 1
	* gen rate = new_firms / state_pop



	* bysort stcode cntycd year: egen new_firms = count(year)	
	* bysort stcode cntycd year: egen new_firms = count(nonprofit)	
	* bysort stcode cntycd year: drop if _n > 1
	* gen rate = new_firms / population


	graph twoway (scatter rate year if state == "MA", mcolor(blue)) ///
		(lpoly rate year if state == "MA", lcolor(blue) degree(1) kernel(triangle))
		

	
		
end

program define GraphRD

	local bin_width 1
	local bin_max 2011
	local cutoff 2007
	local bin_min = `cutoff' - (`bin_max' - `cutoff')
	
	egen temp_x = cut(newaddyear) if (newaddyear >= `bin_min' & newaddyear < `bin_max'), at(`bin_min'(`bin_width')`bin_max')
			
	bysort temp_x: egen temp_y = count(newaddyear) 
	replace temp_x = temp_x  + (`bin_width'/2)

	exit

	capture: rdob_mod2 temp_x temp_y 
	local h_opt = r(h_opt)
	if (`h_opt' == .) {
		local h_opt = 10
	}
		
	disp _newline "BW : `h_opt'"
		
	graph twoway (scatter temp_y temp_x & temp_x >= `bin_min' & temp_x < `bin_max') ///
		(lpoly temp_y temp_y if `newaddyear' >= `bin_min' & newaddyear < `cutoff' & experiment_`sch' == 1, lcolor(black) degree(1) kernel(triangle) bwidth(`h_opt')) ///
		(lpoly `outcome' runvar_`sch' if runvar_`sch' >= 0 & runvar_`sch' < `bin_max' & experiment_`sch' == 1, lcolor(black) degree(1) kernel(triangle) bwidth(`h_opt')), ///
		xlab(`xlabel') ylab(`ylabel') xline(0, lpattern(shortdash)) ytitle("") xtitle("") subtitle(`subtitle') legend(off)
	graph rename temp_`sch'			
		
	drop temp_x temp_y temp_i	

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

	use "$dir/tmp/NewEngland.dta", clear

	levelsof `naics_variable', local(naics_codes)
	foreach naics_code in `naics_codes' { 

		count if `naics_variable' == `naics_code'
		if r(N) < 100 {
			continue
		}

		file write `texhandle' ("\begin{figure}[htbp]") _n			
		file write `texhandle' ("\includegraphics[width=\linewidth]{`naics_code'.eps}") _n
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

	use $dir/tmp/countyBusiness.dta

	* 56  61 are positive

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

	* dropping Alaska, has data matching issues later and 
	* arguably irrelevant to study
	drop if stcode == 2

	* used pre-2002 for auxillary offices
	* https://ask.census.gov/faq.php?id=5000&faqId=1715
	drop if naics == 95

	* causes a lot of varience in totals across state
	drop if naics == 99

	* summing across all naics and counties
	bysort stcode year: egen variable_of_interest = total(n1_4)
	egen tag = tag(stcode year)
	keep if tag
	drop naics tag
	
	* represents the full state in covariates
	replace cntycd = 0

	* removing these for now, later need to check that 
	* there wasn't a shift downward in firm size
	drop n*9 n1000* n1_4
	
	* not using these at the moment
	drop emp
	
	* VERIFY: `statewide' establishments, causes extreme teh est_to_pop values
	* drop if cntycd == 999	
	
	* using panel function to fill in missing years with zero data
	/*
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
	*/
	
	
	tsset stcode year

	* creating outcome variable

	* need n:1 rather than 1:1 since there are multiple naics 2 codes
	merge n:1 stcode cntycd year using "$dir/tmp/Population.dta"
	* ignoring county in Virgina and Florida that don't show up here
	* https://www.census.gov/geo/reference/codes/cou.html
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge

	sort stcode year	
	* getting rate of change in establishments
	gen change_in_establishments = D.variable_of_interest
	* gen rate_of_change = change_in_establishments / population
	gen rate_of_change = variable_of_interest / population

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

	* urban population
	* using 2000 year data
	merge n:1 stcode cntycd using "$dir/tmp/urban.dta"
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge
	
	* need to ensure all states have data for each year
	bysort stcode: egen num_years = count(year)
	egen max_years = max(num_years)
	drop if max_years != num_years
	drop max_years num_years	
	
	* price of healthcare ???
	* equivilant of beer consumption per captia ???
	synth rate_of_change log_income percent_uninsured percent_20_to_24 rate_of_change(2000) rate_of_change(2003) rate_of_change(2006), trunit(25) trperiod(2007) xperiod(2001(1)2006) nested fig

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

program define StateDiff

	use $dir/tmp/countyBusiness.dta
	rename naics_2 naics

	* NAICS 99 changes too much to be useful
	drop if naics == 99
	* removing the health care sector to comply with theory
	drop if naics == 62
	* don't have capital data on this
	drop if naics == 95

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

	* using panel function to fill in missing years with zero data
	egen panel =  group(stcode cntycd)
	tsset panel year
	tsfill, full
		
	* getting rate of change in establishments
	sort panel year	
	gen small_pop = small / population
	gen diff_small_pop = D.small_pop
	gen percent_change = diff_small_pop / L.small_pop * 100
		
	* create treatment dummy
	local treatment_start 2008
	local treatment_group 25
	gen treatment = (year >= `treatment_start') & stcode == `treatment_group'

	* create weights
	gen weight_tmp = population if year == `treatment_start'
	bysort panel: egen weight = mean(weight_tmp)
	drop weight_tmp
	
	local fixed_effects ib`treatment_start'.year
	* local fixed_effects i.stcode i.stcode#i.cntycd ib`treatment_start'.year
	* here the state is the family and counties are individuals, so cluster by state
	* eststo DD: xtreg percent_change treatment `fixed_effects', fe robust cluster(stcode)
	eststo DD: xtreg diff_small_pop treatment `fixed_effects' [aw=weight], fe robust cluster(stcode)

	* for graph of diff and diff
	gen treatment_group = stcode == `treatment_group'
	* drop year 2008 indicator
	levelsof year, local(years)	
	foreach year of local years {
		if `year' == 2008 | `year' == 2000 continue
		gen iYear`year' = year == `year'
		label variable iYear`year' "`year'"
		gen iTYear`year' = (year == `year') & (stcode == 25)
		label variable iTYear`year' "I*`year'"
	}
	* xtreg percent_change iYear* iTYear*, fe robust cluster(stcode)
	xtreg diff_small_pop iYear* iTYear* [aw=weight], fe robust cluster(stcode)
	drop iTYear* iYear*
	
	esttab using $dir/tmp/state_diff.tex, ///
		mtitles("Model (1)")   ///
		keep("$\beta$")  ///
		rename(treatment "$\beta$") ///
		nobaselevels nonumbers replace compress se  b(3) starlevels(* 0.10 ** 0.05 *** 0.01 **** 0.001)
	
	eststo clear
	
	exit
	
	* next do triple diff
	restore
	
	egen panel =  group(stcode cntycd naics)
	tsset panel year

	* this is not working well so skipping the panel balancing for now
	/*
	bysort panel: egen naics_tmp = mean(naics)
	count if naics_tmp != naics & !missing(naics)
	assert(r(N)==0)
	drop naics
	rename naics_tmp naics
	
	replace small = 0 if missing(small)

	* verifying we now have a full panel
	tsset clear
	tsset panel year
	tsfill, full
	*/

	* getting rate of change in establishments
	sort panel year	
	gen small_pop = small / population
	gen diff_small_pop = D.small_pop
	gen percent_change = diff_small_pop / L.small_pop * 100
	
	merge n:1 naics using "$dir/tmp/capital.dta"
	count if _merge == 1
	assert(r(N)==0)
	drop if _merge == 2
	drop _merge
	
	* set up captial sub-treatment group
	su percent_no_funding, detail
	local upper_cutoff = r(p5)
	gen low_capital = (percent_no_funding >= `upper_cutoff')

	* create weights
	gen weight_tmp = small if year == `treatment_start'
	bysort stcode: egen weight = mean(weight_tmp)
	drop weight_tmp
	
	* Leads to a 85% cutoff with p90
	* replace low_capital = 1 if naics == 22
	
	gen treatment = (year >= `treatment_start') & (low_capital == 1) & (stcode == 25)
	* triple differences
	* now state#county is the family and naics are individuals, so cluster by state#county
	egen cluster = group(stcode cntycd)
	eststo DDD: xtreg percent_change ib0.low_capital#ib25.stcode ib0.low_capital#ib2008.year ib25.stcode#ib2008.year treatment [aw=weight], fe robust cluster(cluster)

	/*
	* drop missing
	egen missing_count = rowmiss(percent_change)
	bysort panel: egen has_missing = sum(missing_count)
	drop if (has_missing > 0)
	drop missing_count has_missing
	eststo missing: xtreg percent_change ib0.low_capital#ib25.stcode ib0.low_capital#ib2008.year ib25.stcode#ib2008.year treatment [aw=weight], fe robust cluster(panel)
	*/

	esttab, ///
		mtitles("DD" "DDD" "Drop Missing")   ///
		keep(treatment)  ///
		order(constant treatment *.year) ///		
		nobaselevels nonumbers replace compress se  b(3) starlevels(* 0.10 ** 0.05 *** 0.01 **** 0.001)

	esttab using $dir/tmp/state_diff.tex, ///
		mtitles("State Diff" "Capital Diff" "Triple" "Drop Missing")   ///
		keep("$\beta$" *.year)  ///
		rename(treatment "$\beta$") ///
		nobaselevels nonumbers replace compress se  b(3) starlevels(* 0.10 ** 0.05 *** 0.01 **** 0.001)

	eststo clear

	drop low_capital treatment
	pctile p = percent_no_funding [aw=small], gen(q) n(20)
	levelsof q, local(quantiles) 
	foreach quantile of local quantiles {
		local q = 100-`quantile'
		egen c = mean(p) if q == `q'
		egen cutoff = mean(c)
		gen low_capital = (percent_no_funding >= cutoff)
		gen treatment = (year >= `treatment_start') & (low_capital == 1) & (stcode == 25)
		eststo Q`quantile': xtreg percent_change ib0.low_capital#ib25.stcode ib0.low_capital#ib2008.year ib25.stcode#ib2008.year treatment [aw=weight], fe robust cluster(stcode)
		drop c cutoff low_capital treatment
		local titles `titles' `q'
	}
	drop p q

	esttab, ///
		mtitles(`q')   ///
		keep(treatment)  ///
		order(constant treatment *.year) ///		
		nobaselevels nonumbers replace compress se  b(3) starlevels(* 0.10 ** 0.05 *** 0.01 **** 0.001)

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
	replace rate_of_change = rate_of_change / L.variable_of_interest

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
	quietly: eststo neweyWest: newey2 rate_of_change treat `fixed_effects', lag(2) force
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

	drop if naics == 99 | naics == 95

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

	gen treatment = (year > 2007)

	!rm $dir/tmp/basic_summary.tex
	format population %12.0f
	* matrix m = (0,0,0,0,0,0)
	matrix m = (0,0,0,0)
	* foreach variable of varlist population est small ratio est_pop small_pop d_small_pop{	
	foreach variable of varlist population est small ratio est_pop small_pop percent_change{	
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
	
	* drop if goal > 100000
	
	su goal
	local sigma_hat = r(sd)
	local count = r(N)
	local max = r(max)
	local bw = 2.34 * `sigma_hat' * (`count' ^ (-1/5))
	
	* kdensity goal, k(ep) bw(`bw')	

	kdens goal


	
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

//TestWeights
//StateDiff
Kickstarter
//SummaryStatistics
//CapitalImpact
//MatchingState
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
//SummaryStats_NaicsLoop_2
