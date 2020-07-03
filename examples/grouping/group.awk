BEGIN { SUBSEP = FS = OFS = "," }
{ groups[$1,$2,$3] += $4 }
END {
    PROCINFO["sorted_in"] = "@ind_str_asc"
    for (g in groups)
        print g, groups[g]
}
