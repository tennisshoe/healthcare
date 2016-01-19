
local bincount 4

cem log_income (#`bincount') percent_20_to_24 (#`bincount')  percent_urban (#`bincount')  percent_uninsured (#`bincount')  yr2001 (#`bincount')  yr2002 (#`bincount')  yr2003 (#`bincount')  yr2004 (#`bincount')  yr2005 (#`bincount')  yr2006 (#`bincount')  yr2007 (#`bincount') , treatment(treated) showbreaks

local outbincount 4
cem yr2001 (#`outbincount')  yr2002 (#`outbincount')  yr2003 (#`outbincount')  yr2004 (#`outbincount')  yr2005 (#`outbincount')  yr2006 (#`outbincount')  yr2007 (#`outbincount') , treatment(treated) noimb

sort panel year
levelsof year, local(years)
foreach year of local years {
	if `year' > `base_year' continue
	by panel: gen yr`year' = `y_variable'[`year'-2000]
}

local outbincount 3
local bincount 6
local inbincount 3
cem log_income (#`inbincount') percent_20_to_24 (#`bincount')  percent_urban (#`bincount')   yr2001 (#`bincount')  yr2002 (#`outbincount')  yr2003 (#`outbincount')  yr2004 (#`outbincount')  yr2005 (#`outbincount')  yr2006 (#`outbincount')  yr2007 (#`outbincount') , treatment(treated)

imb log_income percent_20_to_24 percent_urban yr2001 yr2002 yr2003 yr2004 yr2005 yr2006 yr2007, treatment(treated) useweights

xtreg `y_variable' treatment ib2007.year [pw=cem_weights], fe robust

preserve
	levelsof year, local(years)
	foreach year of local years {
		if `year' == `base_year' | `year' == 2000 continue
		gen iTYear`year' = (year == `year') & (stcode == 25)
	}
	xtreg `y_variable' ib`base_year'.year iTYear* [pw=cem_weights], fe robust
	matrix beta = e(b)'
	matrix beta = beta[13..23,1]
	GraphPoint iTYear `base_year' "Self-Employed in Massachusetts versus Synthetic" "_`y_variable'_synthetic"
restore


cem log_income (#10) percent_20_to_24 (#10)  percent_urban (#10)  percent_uninsured (#10), treatment(treated)
