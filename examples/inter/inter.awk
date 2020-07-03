#!/usr/bin/env awk -f
NR==FNR {
    vals[$1,$2] = $0
    next
}
{
    for (i=$2; i<=$3; i++) {
        key = ($1 SUBSEP i)
        if (key in vals) {
            print vals[key]
        } else {
            print $1, i, "N", "N", "N"
        }
    }
}
