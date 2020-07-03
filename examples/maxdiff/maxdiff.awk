#!/usr/bin/env awk -f
$1 > -1000 && $2 > -1000 {
    d = $1 - $2
    if (FNR in diffs) {
        if (diffs[FNR] < d)
            diffs[FNR] = d
    } else {
        diffs[FNR] = d
    }
}
END {
    for (n = 1; n <= FNR; n++) {
        if (n in diffs)
            print diffs[n]
        else 
            print -99999
    }
}
