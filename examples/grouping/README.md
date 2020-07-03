See [this SO
question](https://stackoverflow.com/questions/62252413/group-by-csv-columns-in-bash)
for context.

### datamash version:

    datamash -t, -s -g1,2,3 sum 4 < data.csv

### awk version:

    awk -f group.awk data.csv

### tawk version:

    tawk -csv -f group.tawk data.csv
