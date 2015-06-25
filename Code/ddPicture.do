clear all
global dir "~/Healthcare"

use $dir/Data/ietfIPDisclosurePanel.dta, clear

** Examine the Panel
xtset series vnum
* summarize
* tab vnum nver
* tab ipDisc discFlag
 

** Pooled Cross Section & FE Models 
regress pages ipDisc discFlag i.nver wgDum, cluster(series)
xtreg pages ipDisc i.nver, fe i(series) robust 


** Make the "Magical" DD Picture
gen toDisc = (vnum - discVer) * discFlag
replace toDisc = . if (toDisc<-6 | toDisc > 5) 
replace toDisc = -1 if !discFlag
replace toDisc = toDisc + 6
tab toDisc

* Statistical Version
xtreg pages ib(freq).toDisc i.nver#wgDum, fe i(series) robust
xtreg pages ib(first).toDisc i.nver#wgDum, fe i(series) robust
* testparm 0.toDisc 1.toDisc 2.toDisc 3.toDisc 4.toDisc

* Graphical Version
* parmest also produces the same results but parmby has an ordered sequence which is useful
parmby "xtreg pages ib(freq).toDisc i.nver#wgDum, fe i(series)", saving($dir/tmp/tmp.dta, replace)

* preserve 
use $dir/tmp/tmp.dta, clear
keep if parmseq<=12
gen treatAge = parmseq-6

	* set scheme s2mono
	twoway scatter (estimate min95 max95) treatAge, c(l l l) msymbol(O i i)  legend(order(1 3) lab(1 "Coefficient") lab(3 "95% CI")) xtitle(" " "Versions Since IPR Disclosure") ytitle("RFC Pages") clpattern(solid dash dash)  cmissing(n n n) xscale(range(-5 6))  
	exit
	graph export discPagesV1.pdf, replace

	twoway (scatter estimate treatAge, c(l) msymbol(O) clpattern(solid) cmissing(n)) (rcap min95 max95 treatAge, bstyle(ci2)), legend(lab(1 "Coefficient") lab(2 "95% CI")) xtitle(" " "Versions Since IPR Disclosure") ytitle("RFC Pages") 
	graph export discPagesV2.pdf, replace

* restore

exit


**** Other Ideas to Explore ****

** Change in Specification
gen logPages = ln(pages)
xtreg logPages ipDisc i.nver wgDum, fe i(series) robust 
xtpoisson pages ipDisc i.nver wgDum, fe i(series) robust 
xtreg pages ipDisc i.nver#wgDum, fe i(series) robust


** Matching at Baseline
cem pages authcnt wgStart if vnum == 1, treatment(discFlag)
by series: egen base_weight = max(cem_wieght*(nver==1))
xtreg pages ipDisc wgDum i.nver [pweight=1/base_weight], fe i(series) robust


** Treatment Heterogeneity
xtreg pages ipDisc i.nver if wgStart, fe i(series) robust
xtreg pages ipDisc i.nver if !wgStart, fe i(series) robust
xtreg pages ipDisc ipDiscFree wgDum i.nver, fe i(series) 
