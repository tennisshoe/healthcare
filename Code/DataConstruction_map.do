local fileyear `1'
global dir "~/Healthcare"

log close _all
log using "$dir/tmp/DC_map_`fileyear'.log", append

display "Loading `fileyear'"
use "$dir/Data/infogroup/infogroup_`fileyear'.dta"

display "Dropping unnecessary variables"
//dropping unnecessary firm data 
//latt and long might be useful at some point. Note that it 
//is renamed lon1itude and latitude in 2011
drop frstnm lastnm prottl ttlcd gendcd trdate addr dlvpbc crcode popcod phone adsiz adsiz2 yelcod calsts fax offsiz empsdt slsvdt hdbrch acrflg prof yearet sitnum bknum frncod actcod sicflg iscode subnum empsiz zip4 sicd ssic1-ssic4 pubprv psalvl pactsl pempsz pactem

//not all years have these
capture noisily: drop latt  
capture noisily: drop lon1 
capture noisily: drop matchcd 
capture noisily: drop mesflg 
capture noisily: drop adtflg 
capture noisily: drop endrec
capture noisily: drop confil
capture noisily: drop recentdate
capture noisily: drop pid
capture noisily: drop co2srt
capture noisily: drop flgbyt
capture noisily: drop egcode
capture noisily: drop keycod
capture noisily: drop genfld
capture noisily: drop contcd
capture noisily: drop sid
capture noisily: drop ttladd
capture noisily: drop secondary_*
capture noisily: drop mail_score__mailing
capture noisily: drop lon1itude
capture noisily: drop latitude
capture noisily: drop mailscore
capture noisily: drop frncod*
capture noisily: drop actcod2
capture noisily: drop sic
capture noisily: drop snacode
capture noisily: drop snatitl
capture noisily: drop aid

//drop if prmsic == .

//should also consider dropping aid and ttladd since 2011 lacks
//those variables

//this should help reduce file size of the merged set
display "Converting strings to numbers"
foreach var in abi ultnum year newadd stcode sic indfrm cntycd zip zip4 snacode prmsic pnacode ssic1 ssic2 ssic3 ssic4 subnum pactem pactsl aid {
	capture noisily: confirm variable `var'
	if _rc continue

	quietly: ds `var', has (type string)
	local var_return 0
	capture: if (r(varlist) != "") local var_return 1
	if `var_return' {
		quietly: if "`var'" == "abi" replace `var' = subinstr(`var',"'","",.)
		quietly: if "`var'" == "ultnum" replace `var' = "0" if `var' == ""
		if "`var'" == "abi" | "`var'" == "ultnum" | "`var'" == "year" {
			display "Dropping bad `var''s"
			drop if real(`var')==.
			count
		}
		quietly: destring `var', replace
	}
}

*drop all individuals (indfrm == 1)
//tostring indfrm,replace
display "Dropping individuals"
drop if indfrm == 1
count
drop indfrm

*drop all very short firm names and blanks
display "Dropping short names"
drop if length(coname) < 3
count

drop coname

*only keep the parent companies 
//don't think this works well for 1997   
//		gen is_main_branch = ultnum == "0" | abi == ultnum | ultnum == "000000000" |ultnum == "00000000" |ultnum == "00000000"
//		tab is_main_branch
//		keep if is_main_branch
//		drop is_main_branch ultnum

//not sure why hdbrch was not used here. seems like it does the 
//same thing
display "Dropping branches"
keep if ultnum == 0 | abi == ultnum 
count
drop ultnum

//dealing with year, some files have it as a string, others as a byte
//want to end this as an int	

display "Fixing types"
		
quietly: ds year, has (type byte)
capture: if r(varlist) != "" replace year = year + 1900

//many of these are empty the first year in the first year
foreach var in ttladd pempsz psalvl {
	capture noisily: confirm variable `var'
	if _rc continue

	quietly: ds `var', has (type byte)
	capture: if r(varlist) != "" tostring `var', replace
}

//no longer using pubprv
/*
quietly: ds pubprv, has (type string)
capture: if r(varlist) != "" destring pubprv, replace
quietly: replace pubprv = 0 if pubprv == .
*/
/*  
//don't have the match name code
*add the match_name
cd "~/MEP/code.main"
display "Making match name"
do ../do/tomname.do coname
*/
display "Saving"
*put fileyear and save
gen fileyear = `fileyear'
save "$dir/tmp/infogroup_`fileyear'_tmp.dta"

tempname filehandle		
file open `filehandle' using "$dir/tmp/infogroup_`fileyear'_tmp.don", write binary
file write `filehandle' %8z (0)
file close `filehandle'

