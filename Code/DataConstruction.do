clear all
global dir "~/Healthcare"
if "$S_OS" == "Windows" { 
	global dir "C:\Users\Ankur\SkyDrive\Research\Healthcare" 
	* global dir "z:\Healthcare" 
}

set more off

/*
When merging datasets, view census 2010 (e.g.) to be for the midpoint of the 
year ~July 1st 2010. Income data still does 2010 -> 2009, not 100% sure what
the right thing is
 
List of MA county codes

BARNSTABLE 001 
BERKSHIRE 003 
BRISTOL 005 
DUKES 007 
ESSEX 009 
FRANKLIN 011 
HAMPDEN 013 
HAMPSHIRE 015 
MIDDLESEX 017 
NANTUCKET 019 
NORFOLK 021 
PLYMOUTH 023 
SUFFOLK 025 
WORCESTER 027 

List of NAICS 2 codes

11 Agriculture, Forestry, Fishing and Hunting
21 Mining, Quarrying, and Oil and Gas Extraction 
22 Utilities
23 Construction
31-33 Manufacturing
42 Wholesale Trade
44-45 Retail Trade
48-49 Transportation and Warehousing
51 Information
52 Finance and Insurance
53 Real Estate and Rental and Leasing
54 Professional, Scientific and Technical Services
55 Management of Companies and Enterprises
56 Administrative and Support and Waste Management and Remediation Services
61 Educational Services
62 Health Care and Social Assistance
71 Arts, Entertainment, and Recreation
72 Accommodation and Food Services
81 Other Services, except Public Administration
92 Public Administration
99 Unclassified

List of state codes for New England

STATE|STUSAB|STATE_NAME|STATENS
09|CT|Connecticut|01779780
23|ME|Maine|01779787
25|MA|Massachusetts|00606926
33|NH|New Hampshire|01779794
44|RI|Rhode Island|01219835
50|VT|Vermont|01779802

*/

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

program define MapMergedFile

	! rm -fv $dir/Data/infogroup_merged.dta
	! rm -fv $dir/Data/infogroup_merged_MA.dta
	! rm -fv $dir/tmp/infogroup_*_tmp.dta
	! rm -fv $dir/tmp/infogroup_*_tmp.don
	! rm -fv $dir/tmp/DC_*.o*
	! rm -fv $dir/tmp/DC_map_*.log
	! rm -fv $dir/tmp/DataConstruction_map_*.log

	//cleaning up the data
	forvalues fileyear = 1997/2011{	
		! qsub -N DC_`fileyear' -b yes -j yes -wd $dir/tmp stata -b "$dir/Code/DataConstruction_map.do" `fileyear'
		
	}
	
end 

program define BuildStateIncomeData

	clear
	
	!rm -fv $dir/tmp/MedianIncomeState.dta
	import excel "$dir/Data/MedianIncome/h08.xls", cellrange(A62:BI114) 
	ren B income2013
	ren D income2012
	ren F income2011
	ren H income2010
	ren J income2009
	ren L income2008
	ren N income2007
	ren P income2006
	ren R income2005
	ren T income2004
	ren V income2003
	ren X income2002
	ren Z income2001
	ren AB income2000
	ren A state
	cleanstates state, gen(stcode)
	replace stcode = 11 if state == "D.C."
	keep stcode income*
	drop if missing(stcode)
	reshape long income, i(stcode) j(year)
	
	compress
	save $dir/tmp/MedianIncomeState.dta

end

program define BuildIncomeData

	clear
	
	!rm -fv $dir/tmp/MedianIncome_*.dta
	!rm -fv $dir/tmp/Inflation_2000.dta
	!rm -fv $dir/tmp/MedianIncome.dta

	!rm -fv $dir/tmp/MedianIncome_*.csv
	cp $dir/Data/MedianIncome/DEC_00_SF3_P053_with_ann.csv $dir/tmp/MedianIncome_0_1.csv
	cp $dir/Data/MedianIncome/ACS_05_EST_B19013_with_ann.csv $dir/tmp/MedianIncome_5_1.csv
	cp $dir/Data/MedianIncome/ACS_06_EST_B19013_with_ann.csv $dir/tmp/MedianIncome_6_1.csv

	forvalues year=7/9 {
		cp $dir/Data/MedianIncome/ACS_0`year'_1YR_B19013_with_ann.csv $dir/tmp/MedianIncome_`year'_1.csv
		cp $dir/Data/MedianIncome/ACS_0`year'_3YR_B19013_with_ann.csv $dir/tmp/MedianIncome_`year'_3.csv
	}

	forvalues year=10/12 {
		cp $dir/Data/MedianIncome/ACS_`year'_1YR_B19013_with_ann.csv $dir/tmp/MedianIncome_`year'_1.csv
		cp $dir/Data/MedianIncome/ACS_`year'_3YR_B19013_with_ann.csv $dir/tmp/MedianIncome_`year'_3.csv
	}
	
	cp $dir/Data/MedianIncome/ACS_09_5YR_B19013_with_ann.csv $dir/tmp/MedianIncome_9_5.csv
	forvalues year=10/12 {
		cp $dir/Data/MedianIncome/ACS_`year'_5YR_B19013_with_ann.csv $dir/tmp/MedianIncome_`year'_5.csv
	}

	import delimited using "$dir/Data/MedianIncome/Inflation_2000.csv"
	rename value cpi
	save "$dir/tmp/Inflation_2000.dta"
	list
	clear
	
	* census presents income data normalized to the following
	* year's cpi
	forvalues period=1/5 {
		forvalues year=0/14 {
			local current_file "$dir/tmp/MedianIncome_`year'_`period'.csv"
			capture: confirm file `current_file'
			if _rc continue
			import delimited using `current_file'
			rename v2 st_cnty
			rename v4 income
			keep st_cnty income
			quietly: count if real(st_cnty) == . | real(income) == .
			assert r(N) == 2
			drop if real(st_cnty) == . | real(income) == . 
			destring income, replace
			gen state_code = substr(st_cnty,1,2)
			destring state_code, replace
			gen county_code = substr(st_cnty,3,3)
			destring county_code, replace
			gen year = `year' + 2000
			drop st_cnty
			* VERIFY: changing the year is correct for CPI data
			replace year = year + 1
			merge m:1 year using "$dir/tmp/Inflation_2000.dta"
			quietly: count if _merge == 1
			assert r(N) == 0
			drop if _merge == 2
			replace year = year - 1
			replace income = int(round(income / cpi))
			drop _merge cpi
			* gen period = `period'
			save "$dir/tmp/MedianIncome_`year'_`period'.dta"
			clear
		}
	}
	
	clear
	
	gen state_code = .
	gen county_code = . 
	gen year = .
	gen est_income = .
	
	forvalues period=5(-2)1 {
		forvalues year=14(-1)0 {
			capture: confirm file "$dir/tmp/MedianIncome_`year'_`period'.dta"
			if _rc continue
			* load in the new data
			merge 1:1 state_code county_code year using "$dir/tmp/MedianIncome_`year'_`period'.dta"
			* depending on the number of years covered by the estimate, we 
			* create new observations
			gen expandCount = `period' if _merge != 1
			expand expandCount, gen(expanded)
			* change the date of the new observations to the years
			* covered by the estiamte
			bysort state_code county_code year expanded: gen year_add = _n
			replace year = year - year_add if expanded
			drop expandCount expanded year_add
			* want to drop the previous observations since we are loading
			* files in reverse preference order. previous observations
			* will have _merge == 1 while new ones will be 2 or 3
			bysort state_code county_code year: egen max_merge = max(_merge)
			drop if max_merge != _merge
			* then copy over the new income data
			replace est_income = income if income != .
			drop _merge income max_merge
		}	
	}
		
	ren est_income income
	
	gen panel = state_code * 1000 + county_code
	tsset panel year
	tsfill, full
	tsset, clear
	replace state_code = floor(panel / 1000) if state_code == .
	replace county_code = panel - state_code * 1000 if county_code == . 
	bysort panel: ipolate income year, gen(ip_income)
	drop income panel
	rename ip_income income
	replace income = round(income)
		
	rename state_code stcode
	rename county_code cntycd
	
	compress	
	save "$dir/tmp/MedianIncome.dta"

end

/*
stcode          byte    %9.0g                 
cntycd          int     %9.0g                 
year            int     %9.0g                 
population      long    %10.0g    
*/

program define BuildPopulationData

	clear
	!rm -fv $dir/tmp/Population.dta

	import delimited using "$dir/Data/Population/CO-EST00INT-TOT.csv"
	//population of the state
	//drop if county == 0
	ren state stcode
	ren county cntycd
	keep stcode cntycd popestimate*
	reshape long popestimate, i(stcode cntycd) j(year)
	rename popestimate population
	//keep the 2010 data from the next dataset
	drop if year == 2010

	save $dir/tmp/Population.dta
	clear
	
	import delimited using "$dir/Data/Population/CO-EST2013-Alldata.csv"
	//population of the state
	//drop if county == 0
	ren state stcode
	ren county cntycd
	keep stcode cntycd popestimate*
	reshape long popestimate, i(stcode cntycd) j(year)
	rename popestimate population
	
	append using $dir/tmp/Population.dta
	
	save $dir/tmp/Population.dta, replace

end


/* should walk though each data file to doublecheck we are getting the right
variables. Also not sure if I should use 5 or 3 year data since I'm looking at a 
short time window
*/

program define BuildEmploymentData

	clear
	!rm -fv $dir/tmp/Employment.dta
	!rm -fv $dir/tmp/Employment_*.dta
	!rm -fv $dir/tmp/Employment_*.csv
	
	cp $dir/Data/Employment/DEC_00_SF3_DP3_with_ann.csv $dir/tmp/Employment_0_1.csv
	forvalues year=5/6 {
		cp $dir/Data/Employment/ACS_0`year'_EST_DP3_with_ann.csv $dir/tmp/Employment_`year'_1.csv
	}

	forvalues year=7/9 {
		cp $dir/Data/Employment/ACS_0`year'_1YR_DP3_with_ann.csv $dir/tmp/Employment_`year'_1.csv
	}

	forvalues year=10/13 {
		cp $dir/Data/Employment/ACS_`year'_1YR_DP03_with_ann.csv $dir/tmp/Employment_`year'_1.csv
		cp $dir/Data/Employment/ACS_`year'_3YR_DP03_with_ann.csv $dir/tmp/Employment_`year'_3.csv
		cp $dir/Data/Employment/ACS_`year'_5YR_DP03_with_ann.csv $dir/tmp/Employment_`year'_5.csv
	}
	
	forvalues period=1(2)5 {
		forvalues year=0/14 {
			local current_file "$dir/tmp/Employment_`year'_`period'.csv"
			capture: confirm file `current_file'
			if _rc continue
			import delimited using `current_file', rowrange(3)
			rename geoid2 st_cnty
			if `year' >= 0 & `year' < 5 {
				* Number; Employed civilian population 16 years and over - 
				* CLASS OF WORKER - Self-employed workers in own not incorporated business
				rename hc01_vc50 self_employed
				* Number; EMPLOYMENT STATUS - Population 16 years and over
				rename hc01_vc02 population
				* Number; EMPLOYMENT STATUS - Population 16 years and over - 
				* In labor force - Civilian labor force - Employed
				rename hc01_vc05 employed
			}
			if `year' >= 5 & `year' < 7 {
				rename est_vc53 self_employed
				rename est_vc02 population
				rename est_vc05 employed
			}
			if `year' >= 7 & `year' < 10 {
				rename hc01_est_vc55 self_employed
				rename hc01_est_vc02 population
				rename hc01_est_vc05 employed
			}
			if `year' >= 10 & `year' < 13{
				rename hc01_vc69 self_employed
				rename hc01_vc04 population
				rename hc01_vc07 employed		
			}
			if `year' >= 13 {
				rename hc01_vc69 self_employed
				rename hc01_vc03 population
				rename hc01_vc06 employed		
			}
			keep st_cnty self_employed population employed
			
			* some data missing for alaska, colorado and virgina
			destring self_employed, replace force
			destring population, replace force
			destring employed, replace force

			gen state_code = floor(st_cnty / 1000)
			gen county_code = st_cnty - state_code * 1000

			gen year = `year' + 2000
			drop st_cnty
			save "$dir/tmp/Employment_`year'_`period'.dta"
			clear
		}
	}

	* seperate section for the older ACS files not found on the fact finder
	forvalues year=2002/2004 {

		local self_employed_table
		local self_employed_order
		local population_table
		local population_order
		local employed_table
		local employed_order

		local current_file "$dir/Data/Employment/ACS_`year'_050.csv"
		import delimited using `current_file', clear

		if `year' == 2005 | `year' == 2004 {
			local self_employed_table "B24080"
			* code below assumed only self_employed is a list
			local self_employed_order 10, 20
			local population_table "B12006"
			local population_order 1
			local employed_table "B24080"
			local employed_order 1
			ren cest est
			ren clb lb
			ren cub ub
		}
		if `year' == 2004 {
			local population_table "B23001"						
		}
		if `year' == 2002 | `year' == 2003 {
			local self_employed_table "P068"
			* code below assumed only self_employed is a list
			local self_employed_order 11, 22, 32, 43, 54, 64
			local population_table "P064"
			local population_order 1
			local employed_table "P068"
			local employed_order 1
		}
		
		* first free up memory
		drop lb ub
		keep if inlist(tblid, "`self_employed_table'", "`population_table'", "`employed_table'")
		keep if inlist(order, `self_employed_order', `population_order', `employed_order')
		reshape wide est, i(geoid tblid) j(order)
		reshape wide est*, i(geoid) j(tblid) string
		rename est`population_order'`population_table' population
		rename est`employed_order'`employed_table' employed
		keep geoid population employed est*`self_employed_table'
		destring population employed est*`self_employed_table', replace
		egen self_employed = rowtotal(est*`self_employed_table')
		drop est*
		
		gen st_cnty_start = strpos(geoid, "US") + strlen("US")
		gen st_cnty = substr(geoid, st_cnty_start, .)
		drop geoid st_cnty_start
		destring st_cnty, replace
		
		gen state_code = floor(st_cnty / 1000)
		gen county_code = st_cnty - state_code * 1000
		drop st_cnty

		gen year = `year'
		local file_year = `year' - 2000

		save "$dir/tmp/Employment_`file_year'_1.dta"
		clear
	}
	
	clear
	
	gen state_code = .
	gen county_code = . 
	gen year = .
	gen est_self_employed = .
	gen est_population = .
	gen est_employed = .
	
	forvalues period=5(-2)1 {
		forvalues year=14(-1)0 {
			capture: confirm file "$dir/tmp/Employment_`year'_`period'.dta"
			if _rc continue
			* load in the new data
			merge 1:1 state_code county_code year using "$dir/tmp/Employment_`year'_`period'.dta"
			* depending on the number of years covered by the estimate, we 
			* create new observations
			gen expandCount = `period' if _merge != 1
			expand expandCount, gen(expanded)
			* change the date of the new observations to the years
			* covered by the estiamte
			bysort state_code county_code year expanded: gen year_add = _n
			replace year = year - year_add if expanded
			drop expandCount expanded year_add
			* want to drop the previous observations since we are loading
			* files in reverse preference order. previous observations
			* will have _merge == 1 while new ones will be 2 or 3
			bysort state_code county_code year: egen max_merge = max(_merge)
			drop if max_merge != _merge
			* then copy over the new income data
			replace est_self_employed = self_employed if population != .
			replace est_population = population if population != .
			replace est_employed = employed if population != .
			
			drop _merge self_employed population employed max_merge
		}	
	}
	
	ren est_self_employed self_employed
	ren est_population population
	ren est_employed employed
	
	* may not want to generate missing data points here since self employed
	* is my variable of interest
	
	gen panel = state_code * 1000 + county_code
	tsset panel year
	tsfill, full
	tsset, clear
	replace state_code = floor(panel / 1000) if state_code == .
	replace county_code = panel - state_code * 1000 if county_code == . 
	
	bysort panel: ipolate self_employed year, gen(ip_self_employed)
	drop self_employed
	rename ip_self_employed self_employed
	replace self_employed = round(self_employed)

	bysort panel: ipolate population year, gen(ip_population)
	drop population
	rename ip_population population
	replace population = round(population)

	bysort panel: ipolate employed year, gen(ip_employed)
	drop employed
	rename ip_employed employed
	replace employed = round(employed)

	drop panel
	
	rename state_code stcode
	rename county_code cntycd
	
	* data is saved as float rather than integer, not sure why
	compress	
	save "$dir/tmp/Employment.dta"

end


program define BuildPopulationData_old

	clear
	
	!rm -fv $dir/tmp/Population_*.dta
	!rm -fv $dir/tmp/Population.dta
	
	* Note that the population is for the past 12 to 60 months, 
	* e.g. file 2000 applies to the year 1999
	* Not sure about this, switching to using 2000 -> 2000
	!rm -fv $dir/tmp/Population_*.csv
	cp $dir/Data/Population/DEC_00_SF1_P001_with_ann.csv $dir/tmp/Population_0_1.csv
	cp $dir/Data/Population/ACS_05_EST_B01003_with_ann.csv $dir/tmp/Population_5_1.csv
	cp $dir/Data/Population/ACS_06_EST_B01003_with_ann.csv $dir/tmp/Population_6_1.csv

	forvalues year=7/9 {
		cp $dir/Data/Population/ACS_0`year'_1YR_B01003_with_ann.csv $dir/tmp/Population_`year'_1.csv
		cp $dir/Data/Population/ACS_0`year'_3YR_B01003_with_ann.csv $dir/tmp/Population_`year'_3.csv
	}

	forvalues year=10/12 {
		cp $dir/Data/Population/ACS_`year'_1YR_B01003_with_ann.csv $dir/tmp/Population_`year'_1.csv
		cp $dir/Data/Population/ACS_`year'_3YR_B01003_with_ann.csv $dir/tmp/Population_`year'_3.csv
	}
	
	cp $dir/Data/Population/ACS_09_5YR_B01003_with_ann.csv $dir/tmp/Population_9_5.csv
	forvalues year=10/12 {
		cp $dir/Data/Population/ACS_`year'_5YR_B01003_with_ann.csv $dir/tmp/Population_`year'_5.csv
	}

	forvalues period=1(2)5 {
		forvalues year=0/14 {
			local current_file "$dir/tmp/Population_`year'_`period'.csv"
			capture: confirm file `current_file'
			if _rc continue
			import delimited using `current_file'
			rename v2 st_cnty
			rename v4 population
			keep st_cnty population
			quietly: count if real(st_cnty) == . | real(population) == .
			assert r(N) == 2
			drop if real(st_cnty) == . | real(population) == . 
			destring population, replace
			gen state_code = substr(st_cnty,1,2)
			destring state_code, replace
			gen county_code = substr(st_cnty,3,3)
			destring county_code, replace
			gen year = `year' + 2000 //1999
			drop st_cnty
			save "$dir/tmp/Population_`year'_`period'.dta"
			clear
		}
	}
	
	clear
	
	gen state_code = .
	gen county_code = . 
	gen year = .
	gen est_population = .
	
	forvalues period=5(-2)1 {
		forvalues year=14(-1)0 {
			capture: confirm file "$dir/tmp/Population_`year'_`period'.dta"
			if _rc continue
			* load in the new data
			merge 1:1 state_code county_code year using "$dir/tmp/Population_`year'_`period'.dta"
			* depending on the number of years covered by the estimate, we 
			* create new observations
			gen expandCount = `period' if _merge != 1
			expand expandCount, gen(expanded)
			* change the date of the new observations to the years
			* covered by the estiamte
			bysort state_code county_code year expanded: gen year_add = _n
			replace year = year - year_add if expanded
			drop expandCount expanded year_add
			* want to drop the previous observations since we are loading
			* files in reverse preference order. previous observations
			* will have _merge == 1 while new ones will be 2 or 3
			bysort state_code county_code year: egen max_merge = max(_merge)
			drop if max_merge != _merge
			* then copy over the new income data
			replace est_population = population if population != .
			drop _merge population max_merge
		}	
	}
	
	ren est_population population
	
	gen panel = state_code * 1000 + county_code
	tsset panel year
	tsfill, full
	tsset, clear
	replace state_code = floor(panel / 1000) if state_code == .
	replace county_code = panel - state_code * 1000 if county_code == . 
	bysort panel: ipolate population year, gen(ip_population)
	drop population panel
	rename ip_population population
	replace population = round(population)
		
	rename state_code stcode
	rename county_code cntycd
	
	compress	
	save "$dir/tmp/Population.dta"

end


program define GetExpandYear, rclass
	args state county year
	
	assert(`year' < 2015)

	quietly: count if stcode == `state' & cntycd == `county' & year == `year'
	if r(N) == 0 {
		local year = `year' + 1
		GetExpandYear `state' `county' `year'
		local year = r(year)
	}

	return scalar year = `year'
end

program define ReduceMergedFile


	//2007 and to a lesser extent 2008 will be the long poles here
	forvalues fileyear = 1997/2011{
		WaitForFile "$dir/tmp/infogroup_`fileyear'_tmp.don"
		quietly: append using "$dir/tmp/infogroup_`fileyear'_tmp.dta"
	}
	
	display "Converting NAICS code titles to labels (slow)"
	egen tag = tag(pnacode) 
	gsort -tag
	forvalues i=1/`=_N' {
		if !tag[`i'] continue, break
		local _pnacode = pnacode[`i']
		local _pnatitl = pnatitl[`i']
		label define PNACODE `_pnacode' "`_pnatitl'", add
	}
	drop tag pnatitl
	label values pnacode PNACODE

	display "Converting SIC code titles to labels (slow)"
	egen tag = tag(prmsic) 
	gsort -tag
	forvalues i=1/`=_N' {
		if !tag[`i'] continue, break
		local _prmsic = prmsic[`i']
		local _prmsicd = prmsicd[`i']
		label define PRMCODE `_prmsic' "`_prmsicd'", add
	}
	drop tag prmsicd
	label values prmsic PRMCODE

	display "Cleaning newadd"
	replace newadd = newadd + 190000 if newadd < 10000 & newadd > 8400
	replace newadd = newadd + 200000 if newadd < 1200
	replace newadd = . if mod(newadd,100) < 1 | mod(newadd,100) > 12
	
	gen newaddyear = floor(newadd/100)
	//missing values will be too high
	by abi, sort: egen min_nay = min(newaddyear)
	drop year newaddyear
	rename min_nay year
	
	display "Removing duplicates"
	//earliest entries probably best reflect firm's starting location
	//and business
	sort abi fileyear
	by abi: gen tag = _n
	drop if tag != 1
	drop tag fileyear	
	//these should be mostly all entries in 1997 that were never seen again
	//since newadd is missing for only 1997 files
	drop if year == . 
	
	display "Converting NAICS"
	//do I need to worry about changing NAICS code if I only care about 
	//the 2 and 4 digit numbers? 
	ren pnacode naics
	drop if naics == .
	//probably faster to do the integer division
	gen n_string = string(naics, "%12.0g")
	gen naics_2 = real(substr(n_string,1,2))
	gen naics_4 = real(substr(n_string,1,4))
	drop n_string
	
	//http://www.formsend.com/a/38044.pdf	
	gen nonprofit = (naics_4 == 9261) | (naics_4 == 8139) |  (naics_4 == 8134) | (naics_4 == 9241) |  (naics_4 == 6241) |  (naics_4 == 8132) |  (naics_4 == 8139) |  (naics_4 == 9251) |  (naics_4 == 8133) | (naics_4 == 6115) |  (naics_4 == 7121) |  (naics_4 == 6200) | (naics_4 == 9221) |  (naics_4 == 8131) |  (naics_4 == 6100) | (naics_4 == 8133) |  (naics_4 == 8132)	

	display "Saving merged file"
	quietly: save "$dir/Data/infogroup_merged.dta"
	
	quietly: keep if state == "MA"
	quietly: save "$dir/Data/infogroup_merged_MA.dta"

end

/*

save "$dir/Data/merged_MA.dta", replace

use "$dir/Data/cps_00002.dta"

//STATEFIP == 25 for Massachusetts. Dropping other states
keep if statefip == 25

//just have march data
drop month

*/

/*

//create variable for the first year the company is in the records
by abi, sort: egen firstyear = min(fileyear)

//keep only the first year the firm existed
drop if fileyear != firstyear
drop fileyear

//dataset seems to start at 1998 so all firms before that year were recorded as 
//starting in 1998. Drop those.
drop if firstyear < 1999

*/

//create SIC codes
//drop if prmsic == . 
//gen byte SIC_2 = prmsic / 10000
//gen int SIC_3 = prmsic / 1000



program define DataSummary

	quietly: use "$dir/Data/infogroup_merged.dta", clear
	quietly: ds
	foreach var in `r(varlist)' {
		local isString 0
		quietly: ds `var', has (type string)
		capture: if r(varlist) != "" local isString 1
		if `isString'   quietly: count if `var' != ""
		else  		quietly: count if `var' != .
		local notEmpty = r(N)
		quietly: count
		local total = r(N)
		if `total' - `notEmpty' > 0 {		
			if `isString' 	gen `var'_f = `var' != ""
			else 		gen `var'_f = `var' != .
			tab fileyear `var'_f, missing
			quietly: drop `var'_f
		}
	}

end

//worried that if I just dropped non-tagged entries here it would cause problems
//with using the labels on the whole dataset. Need to better understand how
//labels are saved and loaded
program define TestLabelSpeed 

	use "$dir/tmp/infogroup_2011_tmp.dta", clear
//	keep if state == "MA"

	timer on 1

	local count 0
	egen tag = tag(pnacode) 
	forvalues i=1/`=_N' {
		if !tag[`i'] continue
		local _pnacode = pnacode[`i']
		local _pnatitl = pnatitl[`i']
		label define PNACODE `_pnacode' "`_pnatitl'", add
		local count = `count' + 1
	}
	drop tag pnatitl
	label values pnacode PNACODE
	display `count'
	
	timer off 1

//	label drop PNACODE
	use "$dir/tmp/infogroup_2011_tmp.dta", clear	
//	keep if state == "MA"
	
	timer on 2
	
	local count 0
	egen tag = tag(pnacode) 
	gsort -tag

	forvalues i=1/`=_N' {
		if !tag[`i'] continue, break
		local _pnacode = pnacode[`i']
		local _pnatitl = pnatitl[`i']
		label define PNACODE `_pnacode' "`_pnatitl'", add
		local count = `count' + 1
	}
	
	drop tag pnatitl
	label values pnacode PNACODE
	display `count'
	
	timer off 2
	
	timer list

end

* Reference is here
* http://www.federalreserve.gov/newsevents/conferences/lynch-rho-20111109.pdf
program define BuildCapitalStockData

	use $dir/Data/naics5809.dta
	* Not properly using deflator yet

	* Calculating over full business cycle 1999 to 2005
	keep if year >= 1999 & year <= 2005
	
	gen naics_4 = floor(naics / 100)
	bysort naics_4: egen total_emp = total(emp)
	bysort naics_4: egen total_cap = total(cap)
	bysort naics_4: keep if _n == 1
	gen cap_intensity = total_cap / total_emp
	keep naics_4 cap_intensity
	
	save $dir/tmp/Intensity.dta, replace
	
end

program define inner_BuildNonemployerData

	replace naics = "31" if naics == "31-33"
	replace naics = "44" if naics == "44-45"
	replace naics = "48" if naics == "48-49"
	replace naics = substr(naics, 1,4) if strpos(naics, "-a") != 0	
	gen naics_length = length(naics)
	destring naics, replace
	keep if naics_length == 2 | naics_length == 4
	keep if missing(estab_f)
	gen naics_2 = naics if naics_length == 2
	gen naics_4 = naics if naics_length == 4
	rename cty cntycd
	rename st stcode
	* forcing this to be the same interface as the county business dataset
	rename estab small
	keep cntycd stcode naics_2 naics_4 small 
end

program define BuildNonemployerData

	!rm $dir/tmp/nonemployed*.dta

	forvalues i=2/9 {
		clear
		import delimited $dir/Data/NonemployerStatistics/nonemp0`i'co.txt
		inner_BuildNonemployerData
		gen year = 200`i'
		save $dir/tmp/nonemployed200`i'.dta
	}

	forvalues i=0/1 {
		clear
		import delimited $dir/Data/NonemployerStatistics/nonemp0`i'co.txt
		ren county cty
		inner_BuildNonemployerData
		gen year = 200`i'
		save $dir/tmp/nonemployed200`i'.dta
	}

	forvalues i=10/12 {
		clear
		import delimited $dir/Data/NonemployerStatistics/nonemp`i'co.txt
		inner_BuildNonemployerData
		gen year = 20`i'
		save $dir/tmp/nonemployed20`i'.dta
	}

	forvalues i=97/99 {
		clear
		import delimited $dir/Data/NonemployerStatistics/nonemp`i'co.txt
		ren county cty
		inner_BuildNonemployerData
		gen year = 19`i'
		save $dir/tmp/nonemployed19`i'.dta
	}
	
	local naics_update "1997_to_2002_NAICS" "2002_to_2007_NAICS" "2007_to_2012_NAICS"
	
	* first prep the files needed to update NAICS 4 codes
	foreach file in "`naics_update'" {	
		clear
		import delimited $dir/Data/naics/`file'.csv
		* can't do anything about 4 digit naics that get split		
		bysort old: egen max_new = max(new)
		bysort old: egen min_new = min(new)
		drop if max_new != min_new
		drop if new == old
		bysort old new: keep if _n == 1
		keep old new
		save $dir/tmp/`file'.dta, replace
	}
	
	clear	
	forvalues i=1997/2012 {
		append using $dir/tmp/nonemployed`i'.dta
	}
	compress

	* updating to 2012 naics codes
	ren naics_4 old
	merge n:1 old using $dir/tmp/1997_to_2002_NAICS.dta
	drop if _merge == 2
	replace old = new if !missing(new) & year < 2002
	keep cntycd stcode naics_2 old small year
	merge n:1 old using $dir/tmp/2002_to_2007_NAICS.dta
	drop if _merge == 2
	replace old = new if !missing(new) & year < 2007
	keep cntycd stcode naics_2 old small year	
	merge n:1 old using $dir/tmp/2007_to_2012_NAICS.dta
	drop if _merge == 2
	replace old = new if !missing(new) & year < 2012
	keep cntycd stcode naics_2 old small year	
	ren old naics_4

	bysort stcode cntycd naics_4 year: egen total_small = total(small) if missing(naics_2)
	bysort stcode cntycd naics_4 year: drop if _n > 1 & missing(naics_2)
	replace small = total_small if missing(naics_2)
	drop total_small
	
	* now building full panel

	drop if naics_2 == 0
	drop if naics_2 == 99
        drop if naics_4 >= 9900 & naics_4 < 10000
	drop if naics_2 == 62
        * above 6240 consists of things like homeless shelters, not health related
        drop if naics_4 >= 6200 & naics_4 < 6240
	drop if naics_2 == 95
        drop if naics_4 >= 9500 & naics_4 < 9600	

	drop if cntycd == 999 | cntycd == 0
	
	preserve
	
	drop if missing(naics_2)
	drop naics_4
	rename naics_2 naics
	
	* drop NAICS codes that MA doesn't have much of
	bysort stcode cntycd naics: egen t_small = mean(small) if stcode == 25
	bysort stcode naics: egen max_small = max(t_small) if stcode == 25
	bysort naics: egen t_max_small = mean(max_small)	
	drop if t_max_small < 100 | missing(t_max_small)
	drop t_small max_small t_max_small

	/* trying without blanks for now since 4 digit is so slow
	
        levelsof naics, local(naics_codes)
        foreach naics_code in `naics_codes' { 
                quietly: levelsof stcode, local(states) 
                foreach state in `states' {
			display "State: `state'"
                        quietly: levelsof cntycd if stcode == `state', local(counties)
                        foreach county in `counties' {
				display "County: `county'"
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
                                }
                                
                        }
                }       
        }
	
	*/
	
        egen panel =  group(stcode cntycd naics)
        tsset panel year	
	
	/*
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
	bysort panel: ipolate small year, gen(ip_small) epolate
	drop small
	rename ip_small small
	*/
	
	save $dir/tmp/nonemployed.dta, replace
	
	restore

	drop if missing(naics_4)
	drop naics_2
	rename naics_4 naics

	* drop NAICS codes that MA doesn't have much of
	bysort stcode cntycd naics: egen t_small = mean(small) if stcode == 25
	bysort stcode naics: egen max_small = max(t_small) if stcode == 25
	bysort naics: egen t_max_small = mean(max_small)
	drop if t_max_small < 100 | missing(t_max_small)
	drop t_small max_small t_max_small

	/* for now assuming I don't need blanks across all counties due to the
	 *  way i'm doing matching 
		
        levelsof naics, local(naics_codes)
        foreach naics_code in `naics_codes' { 
                quietly: levelsof stcode, local(states) 
                foreach state in `states' {
			display "State: `state'"		
                        quietly: levelsof cntycd if stcode == `state', local(counties)
                        foreach county in `counties' {
				display "County: `county'"
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
                                }
                                
                        }
                }       
        }
	*/

        egen panel =  group(stcode cntycd naics)
        tsset panel year
        
	/*
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
	bysort panel: ipolate small year, gen(ip_small) epolate
	drop small
	rename ip_small small
	*/
	
	save $dir/tmp/nonemployedLong.dta, replace

end

/*

About 60% of employment counts are suppressed. Converting non-supressed to similar
scale from 1 to 12 for consistency purposes. Note there is no 'D' code. More recent
years have additional noise flag to use

                                A       0-19
                                B       20-99
                                C       100-249
                                E       250-499
                                F       500-999
                                G       1,000-2,499
                                H       2,500-4,999
                                I       5,000-9,999
                                J       10,000-24,999
                                K       25,000-49,999
                                L       50,000-99,999
                                M       100,000 or More
*/

program define BuildCountyBusinessLongData

	!rm $dir/tmp/countyBusinessLong*.dta

	forvalues i=0/12 {
		clear
		local filename $dir/Data/CountyBusinessPatterns/cbp`i'co.txt
		if `i' < 10 {
			local filename $dir/Data/CountyBusinessPatterns/cbp0`i'co.txt
		}
		import delimited `filename' 
		keep if fipstate == 25
		* keep if fipstate == 9 | fipstate == 23 | fipstate == 25 | fipstate == 33 | fipstate == 44 | fipstate == 50
				
		keep if (strpos(naics, "-") == 0) & (strpos(naics, "/") == 0)
		destring naics, replace
		ren n1_4 small
		keep naics fips* small
		
		ren fipstate stcode
		ren fipscty cntycd

		gen year = 2000 + `i'
		save $dir/tmp/countyBusinessLong`i'.dta
	}
	
	clear
	forvalues i=0/12 {
		append using $dir/tmp/countyBusinessLong`i'.dta
	}

	compress
	save $dir/tmp/countyBusinessLong.dta
	
end

program define BuildCountyBusinessData

	!rm $dir/tmp/countyBusiness*.dta

	forvalues i=0/12 {
		clear
		local filename $dir/Data/CountyBusinessPatterns/cbp`i'co.txt
		if `i' < 10 {
			local filename $dir/Data/CountyBusinessPatterns/cbp0`i'co.txt
		}
		import delimited `filename' 
		* keep if fipstate == 9 | fipstate == 23 | fipstate == 25 | fipstate == 33 | fipstate == 44 | fipstate == 50
		
		keep if (strpos(naics, "----") == 3) | (strpos(naics, "//") == 5)
		gen naics_2 = substr(naics, 1, 2) if (strpos(naics, "----") == 3) 
		gen naics_4 = substr(naics, 1, 4) if (strpos(naics, "//") == 5)
		drop naics 
		keep n* fips* est emp empflag
		
		gen emp_bucket = 0
		replace emp_bucket = 1 if empflag == "A" | (emp >= 0 & emp < 20)
		replace emp_bucket = 2 if empflag == "B" | (emp >= 20 & emp < 100)
		replace emp_bucket = 3 if empflag == "C" | (emp >= 100 & emp < 250)
		replace emp_bucket = 4 if empflag == "E" | (emp >= 250 & emp < 500)
		replace emp_bucket = 5 if empflag == "F" | (emp >= 500 & emp < 1000)
		replace emp_bucket = 6 if empflag == "G" | (emp >= 1000 & emp < 2500)
		replace emp_bucket = 7 if empflag == "H" | (emp >= 2500 & emp < 5000)
		replace emp_bucket = 8 if empflag == "I" | (emp >= 5000 & emp < 10000)
		replace emp_bucket = 9 if empflag == "J" | (emp >= 10000 & emp < 25000)
		replace emp_bucket = 10 if empflag == "K" | (emp >= 25000 & emp < 50000)
		replace emp_bucket = 11 if empflag == "L" | (emp >= 50000 & emp < 100000)
		replace emp_bucket = 12 if empflag == "M" | (emp >= 100000)
		drop empflag emp
		ren emp_bucket emp
		ren fipstate stcode
		ren fipscty cntycd

		gen year = 2000 + `i'
		save $dir/tmp/countyBusiness`i'.dta
	}
	
	clear
	forvalues i=0/12 {
		append using $dir/tmp/countyBusiness`i'.dta
	}

	keep stcode cntycd n1_4 year naics_2 naics_4
	ren n1_4 small

	destring naics_2, replace
	destring naics_4, replace
	compress		

	* updating to 2012 naics codes
	ren naics_4 old
	merge n:1 old using $dir/tmp/1997_to_2002_NAICS.dta
	drop if _merge == 2
	replace old = new if !missing(new) & year < 2002
	drop new _merge
	merge n:1 old using $dir/tmp/2002_to_2007_NAICS.dta
	drop if _merge == 2
	replace old = new if !missing(new) & year < 2007
	drop new _merge
	merge n:1 old using $dir/tmp/2007_to_2012_NAICS.dta
	drop if _merge == 2
	replace old = new if !missing(new) & year < 2012
	drop new _merge
	ren old naics_4

	bysort stcode cntycd naics_4 year: egen total_small = total(small) if missing(naics_2)
	bysort stcode cntycd naics_4 year: drop if _n > 1 & missing(naics_2)
	replace small = total_small if missing(naics_2)
	drop total_small
	
	preserve

	drop if missing(naics_2)
	drop naics_4
	ren naics_2 naics
	
	* fill out the panel
	egen panel =  group(stcode cntycd naics)
        tsset panel year
	
	/*
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
	bysort panel: ipolate small year, gen(ip_small) epolate
	drop small
	rename ip_small small
	*/

	save $dir/tmp/countyBusiness.dta, replace
	
	restore

	drop if missing(naics_4)
	ren naics_4 naics
	
	* fill out the panel
	egen panel =  group(stcode cntycd naics)
        tsset panel year
	
	/*
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
	bysort panel: ipolate small year, gen(ip_small) epolate
	drop small
	rename ip_small small
	*/

	save $dir/tmp/countyBusinessLong.dta, replace

end

program define BuildAgeData

	!rm $dir/tmp/ageGroup.dta
	
	* first state data
	import delimited $dir/Data/AgeGroup/DEC_00_110H_DP1_with_ann.csv, varnames(1) rowrange(3)
	ren hc02_vc09 percent_20_to_24
	destring percent_20_to_24, replace
	ren hc02_vc80 percent_household_with_children
	destring percent_household_with_children, replace
	rename geoid2 stcode
	destring stcode, replace
	gen cntycd = 0
	destring cntycd, replace
	keep stcode cntycd percent_20_to_24 percent_household_with_children		
	save $dir/tmp/ageGroup.dta
	
	clear
	import delimited $dir/Data/AgeGroup/DEC_00_SF1_DP1_with_ann.csv, varnames(1) rowrange(3)
	ren hc02_vc09 percent_20_to_24
	destring percent_20_to_24, replace
	ren hc02_vc80 percent_household_with_children
	destring percent_household_with_children, replace
	gen stcode = substr(geoid2,1,2)
	destring stcode, replace
	gen cntycd = substr(geoid2,3,3)
	destring cntycd, replace
	keep stcode cntycd percent_20_to_24 percent_household_with_children	

	append using $dir/tmp/ageGroup.dta

	compress
	save $dir/tmp/ageGroup.dta, replace

end

program define BuildInsuranceData

	!rm $dir/tmp/insurance.dta
	import delimited $dir/Data/Insurance/SAHIE2005_tab.TXT
	* consider only counties
	* keep if v3 == 50
	* age range 18 to 64
	keep if v4 == 1
	* all races
	keep if v5 == 0
	* both male and female
	keep if v6 == 0
	* all incomes
	keep if v7 == 0

	* should have about 3000 counties in the US
	count
	assert r(N) > 3000 & r(N) < 3500

	ren v1 stcode
	ren v2 cntycd
	ren v13 percent_uninsured
	* set state equal to county 0
	replace cntycd = 0 if v3 == 40
	
	keep stcode cntycd percent_uninsured
	
	compress
	save $dir/tmp/insurance.dta

end

program define BuildDensityData

	!rm $dir/tmp/density.dta
	import delimited $dir/Data/Density/DEC_00_SF1_GCTPH1.CY07_with_ann.csv, varnames(1) rowrange(3)

	keep if geoid2 == gct_stubtargetgeoid2

	* should have about 3000 counties in the US
	count
	assert r(N) > 3000 & r(N) < 3500

	gen pop_density = hc08
	destring pop_density,replace

	gen stcode = substr(geoid2,1,2)
	destring stcode, replace
	gen cntycd = substr(geoid2,3,3)
	destring cntycd, replace
	keep stcode cntycd pop_density	
	
	compress
	save $dir/tmp/density.dta

end

program define BuildUrbanData

	* doing state first
	! rm $dir/tmp/urban.dta
	import delimited $dir/Data/Density/DEC_00_SF1_H002_with_ann_state.csv, varnames(1) rowrange(3)
	
	destring vd01, replace
	destring vd02, replace
	gen percent_urban = vd02 / vd01
	ren geoid2 stcode
	destring stcode, replace
	gen cntycd = 0
	
	keep percent_urban stcode cntycd
		
	save $dir/tmp/urban.dta
	
	clear
	import delimited $dir/Data/Density/DEC_00_SF1_H002_with_ann.csv, varnames(1) rowrange(3)

	destring vd01, replace
	destring vd02, replace
	gen percent_urban = vd02 / vd01
	
	gen stcode = substr(geoid2,1,2)
	destring stcode, replace
	gen cntycd = substr(geoid2,3,3)
	destring cntycd, replace

	append using $dir/tmp/urban.dta
	compress
	save $dir/tmp/urban.dta, replace

end

// description of micro-data
// http://www2.census.gov/econ/sbo/07/pums/2007_sbo_pums_users_guide.pdf

program define BuildCaptialData

	import delimited $dir/Data/Capital/pums.csv 
	//, varnames(1) rowrange(3)

	* drop states outside of new england
	ren fipst fipstate
	* S4 is rhode island + vermont in PUMS dataset
	keep if fipstate == "09" | fipstate == "23" | fipstate == "25" | fipstate == "33" | fipstate == "44" | fipstate == "50" | fipstate == "S4"
	ren fipstate stcode

	tab scamount scnoneneeded, missing
	* ignore if both are missing
	drop if missing(scamount) & missing(scnoneneeded)
	* also drop if no response to amount but some was needed
	drop if scamount == "0" & scnoneneeded != 1
	* set low capital if scononeneeded is true
	gen byte no_funding = (scnoneneeded == 1)
	* add in firms needing less than $5000 in capital
	* replace no_funding = 1 if scamount == "1"

	preserve	
	
	* only want firms with at least 1 employee since that's our small business
	* dataset
	keep if n07_employer == "E"
	* worried about noise. Although we are looking for 1 to 4 employees, zero's may be 
	* noise from the 1 
	keep if employment_noisy < 5
	
	tab no_funding, missing
	* bysort sector: egen percent_no_funding = mean(no_capital)
	bysort sector: egen sector_weight = total(tabwgt)
	bysort sector: egen s_w_no_funding = total(tabwgt * no_funding)
	gen percent_no_funding = s_w_no_funding / sector_weight
	 	
	by sector: keep if _n == 1
	replace percent_no_funding = percent_no_funding * 100
	keep percent_no_funding sector sector_weight
	ren sector* naics*

	save $dir/tmp/capital.dta, replace	
	
	* next do the non-employer version	
	restore

	keep if n07_employer == "N"
	count if employment_noisy > 0
	assert(r(N) == 0)
	
	tab no_funding, missing
	* bysort sector: egen percent_no_funding = mean(no_capital)
	bysort sector: egen sector_weight = total(tabwgt)
	bysort sector: egen s_w_no_funding = total(tabwgt * no_funding)
	gen percent_no_funding = s_w_no_funding / sector_weight
	 	
	by sector: keep if _n == 1
	replace percent_no_funding = percent_no_funding * 100
	keep percent_no_funding sector sector_weight
	ren sector* naics*

	save $dir/tmp/capitalNonemployer.dta, replace	
	
	* old version that used country wide data of all firms regardless of employee count

	!rm $dir/tmp/capitalOld.dta
	import delimited $dir/Data/Capital/SBO_2007_00CSCB15_with_ann.csv, varnames(1) rowrange(3) clear

	* specifically looking at (extablishments) firms with with 1 to 4 employees 
	* but can't filter on both firm size and naics code
	* keep if empszfiid == 612
	keep if empszfiid == "001"
		
	* all types of firms (female, male owned etc)
	keep if cbgroupid == "0000"
	
	* filter on those that did not need funding
	keep if strtsrceid == "GJ" | strtsrceid == "FX" | strtsrceid == "GD"
	replace strtsrceid = "no_funding" if strtsrceid == "GJ"
	replace strtsrceid = "self_funding" if strtsrceid == "FX"
	replace strtsrceid = "bank_funding" if strtsrceid == "GD"
	
	* the percentage of firms having paid employees falling into this bucket
	ren firmpdemp_pct percent_
		
	ren naicsid naics
	replace naics = "11" if naics == "11(601)"
	replace naics = "31" if naics == "31-33"
	gen duplicate = 2 if naics == "31"
	expand duplicate, gen(tag)
	replace naics = "32" if tag == 1
	drop duplicate tag
	gen duplicate = 2 if naics == "31"
	expand duplicate, gen(tag)
	replace naics = "33" if tag == 1
	drop duplicate tag
	replace naics = "44" if naics == "44-45"
	gen duplicate = 2 if naics == "44"
	expand duplicate, gen(tag)
	replace naics = "45" if tag == 1
	drop duplicate tag
	replace naics = "48" if naics == "48-49(603)"
	gen duplicate = 2 if naics == "48"
	expand duplicate, gen(tag)
	replace naics = "49" if tag == 1
	drop duplicate tag
	replace naics = "52" if naics == "52(604)"
	replace naics = "81" if naics == "81(605)"

	destring naics, replace
	destring percent_, replace
	
	keep naics percent_ strtsrceid
	reshape wide percent_, i(naics) j(strtsrceid) string
	
	//xtile xt_no_funding = percent_no_funding, nquantiles(10)
	
	compress
	save $dir/tmp/capitalOld.dta

	/*
	drop if naics == 99
	graph twoway (scatter percent_no_funding percent_bank_funding, mcolor(blue) ) ///
		(lpoly percent_no_funding percent_bank_funding, lcolor(blue) degree(2))

	graph twoway (scatter percent_no_funding percent_self_funding, mcolor(blue) ) ///
		(lpoly percent_no_funding percent_self_funding, lcolor(blue) degree(1))

	graph twoway (scatter percent_bank_funding percent_self_funding, mcolor(blue) ) ///
		(lpoly percent_bank_funding percent_self_funding, lcolor(blue) degree(1))	
	*/

end

program define MassHealthEnrollment

	* http://www.mass.gov/chia/docs/r/pubs/14/mahealthcare-enroll-trends.pdf
	* Dec 2013 1,192,554

end

program define BuildNonprofitData

	! rm $dir/tmp/nonprofit.dta
	import delimited $dir/Data/Nonprofit/ECN_2012_US_00A1_with_ann.csv, varnames(1) rowrange(3)
	keep naics* optaxid estab
	rename naicsid naics
	destring, replace

	reshape wide estab, i(naics*) j(optaxid) string
	keep if !missing(estabA)
	gen percent_nonprofit = estabY / estabA
	replace percent_nonprofit = 0 if missing(percent_nonprofit)
	drop est*
	
	compress
	save $dir/tmp/nonprofit.dta
end

program define InfogroupToCountyBusiness

	! rm $dir/tmp/infoCountyBusiness.dta
	use $dir/Data/infogroup_merged.dta
	drop city state zip salvol prmsic newadd abi nonprofit


	compress
	save $dir/tmp/infoCountyBusiness.dta
	
	

end

//BuildCountyBusinessData
//BuildNonemployerData
//BuildCaptialData
//BuildCountyBusinessLongData
//InfogroupToCountyBusiness
//BuildNonprofitData
//BuildUrbanData
//BuildStateIncomeData
//BuildDensityData
//BuildInsuranceData
//BuildAgeData
//BuildEmploymentData
//MapMergedFile
//ReduceMergedFile
//DataSummary
//TestLabelSpeed
//BuildCapitalStockData
//BuildPopulationData
//BuildIncomeData
