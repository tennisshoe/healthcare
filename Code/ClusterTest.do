clear all
set obs 1

local group_count = 3
local individual_count = 10
local year_count = 13

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

gen treatment = (inlist(group,1) & year > (`year_count' / 2))
gen treatment_2 = (inlist(group,1,2) & year > (`year_count' / 2))

gen error = rnormal()
egen panel = group(group individual)
tsset panel year

su group
local mean_group = r(mean)
su panel
local mean_panel = r(mean)
su year
local mean_year = r(mean)

gen y = group - `mean_group' + panel - `mean_panel' + year - `mean_year' + error
su y
gen y_treated = y + r(sd) / 2 * treatment
drop error

regress y i.group i.panel i.year treatment, cluster(group)
regress y i.group i.panel i.year treatment_2, cluster(group)

xtreg y i.group i.panel i.year treatment_2, cluster(group) fe

by panel: egen y_bar = mean(y)
egen y_bar_bar = mean(y_bar)
by panel: egen treatment_bar = mean(treatment)
egen treatment_bar_bar = mean(treatment_bar)

by panel: egen treatment_2_bar = mean(treatment_2)
egen treatment_2_bar_bar = mean(treatment_2_bar)

tab year, gen(yr)
levelsof(year), local(years)
foreach year in `years' {
	by panel: egen yr`year'_bar = mean(yr`year')
	egen yr`year'_bar_bar = mean(yr`year'_bar)
	gen yr`year'_fe = yr`year' - yr`year'_bar + yr`year'_bar_bar
}
drop yr1_fe

gen y_fe = y - y_bar + y_bar_bar
gen treatment_fe = treatment - treatment_bar + treatment_bar_bar
regress y_fe yr*_fe treatment_fe, cluster(group)
xtreg y i.year treatment, cluster(group) fe




