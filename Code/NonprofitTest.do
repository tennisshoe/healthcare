clear all
local year_count 3
local state_count 6
local county_count 1
local naics_count 10
local obs = `year_count'*`state_count'*`county_count'*`naics_count'
set obs `obs'
gen year = 2000
replace year = year + mod(_n,`year_count')
bysort year: gen state = mod(_n,`state_count')
bysort year state: gen county = mod(_n,`county_count')
bysort year state county: gen naics = mod(_n,`naics_count')

local treatment_effect 50
egen panel = group(state county naics)

* homogeneous treatment
su year
local post_year = r(mean)
gen treatment = (year >= `post_year') * (state == 0)
local treatment_effect 50
gen change = state + county + naics + year + `treatment_effect' * treatment + rnormal(0,1)

gen i_year = year == 2000
xtset panel year
xtreg change i.year treatment, fe robust  allbaselevels
exit
drop treatment change

* hetrogeneous treatment

gen nonprofit_percentage = runiform()
bysort naics: replace nonprofit_percentage = nonprofit_percentage[1]

gen treatment = nonprofit_percentage * (year > 2007) * (state == 0)
gen change = state + county + naics + year + `treatment_effect' * treatment + rnormal()

regress change i.state i.county i.naics i.year treatment if state == 0, robust

xtset panel year
xtreg change i.year treatment if state == 0, fe robust


xtreg change i.state#i.year i.county#i.year i.naics#i.year treatment, fe robust



