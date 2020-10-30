See [this SO
question](https://stackoverflow.com/questions/64606304/delete-entries-from-csv-from-second-csv-file)
for context.

### awk version

    awk -F, 'NR == FNR {mail[$0]=1; next} !($11 in mail)' second.csv first.csv

### tawk version

    tawk -csv 'line {$NR == $FNR} { dict set mail $F(0) 1; continue }
               line {![dict exists $mail $F(11)]} { print }' second.csv first.csv
