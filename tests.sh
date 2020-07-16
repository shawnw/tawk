#!/usr/bin/env bash

set +o noclobber
trap "rm -f data*.txt data*.csv test.tawk out*.txt" EXIT

echo "Running tawk tests..."

declare -a letters=(a b c d)
paste <(printf "%s\n" "${letters[@]}") <(seq 1 ${#letters[@]}) > data.txt
sed 's/\t/,/g' data.txt > data.csv

cat <<'EOF' >test.tawk
line { incr total $F(2) }
END { puts $total }
EOF

declare -i pass=0 fail=0

# Read from file
if output=$(./tawk '
   line {
        incr total $F(2)
   }
   END { puts $total }' data.txt) && [[ $output -eq 10 ]]; then
    echo "Test 1: Pass"
    pass+=1
else
    echo "Test 1: Fail"
    fail+=1
fi

# Read from standard input, script in file
if output=$(./tawk -f test.tawk < data.txt) && [[ $output -eq 10 ]]; then
    echo "Test 2: Pass"
    pass+=1
else
    echo "Test 2: Fail"
    fail+=1
fi

if output=$(./tawk '
   line {$F(2) % 2 == 0} { incr total $F(2) }
   END { puts $total }' data.txt) && [[ $output -eq 6 ]]; then
    echo "Test 3: Pass"
    pass+=1
else
    echo "Test 3: Fail"
    fail+=1
fi

# Setting OFS in script
if ./tawk '
   BEGIN { set OFS , }
   line { set F(1) $F(1); puts $F(0) }' data.txt > out.txt  \
        && cmp out.txt data.csv; then
    echo "Test 4: Pass"
    pass+=1
else
    echo "Test 4: Fail"
    fail+=1
fi

# Set variable on command line
if ./tawk '
   line { set F(1) $F(1); puts $F(0) }' "OFS=," data.txt > out.txt \
        && cmp out.txt data.csv; then
    echo "Test 5: Pass"
    pass+=1
else
    echo "Test 5: Fail"
    fail+=1
fi

# Set variable on command line, read from standard input
if ./tawk '
   line { set F(1) $F(1); puts $F(0) }' "OFS=," < data.txt > out.txt \
        && cmp out.txt data.csv; then
    echo "Test 6: Pass"
    pass+=1
else
    echo "Test 6: Fail"
    fail+=1
fi

# Set FS on command line
if ./tawk 'line { puts [string toupper $F(1)] }' "FS=," data.csv > out.txt \
        && cmp out.txt <(printf "%s\n" "${letters[@]^^}"); then
    echo "Test 7: Pass"
    pass+=1
else
    echo "Test 7: Fail"
    fail+=1
fi

# Test BEGINFILE
if ./tawk 'BEGINFILE { puts $FILENAME }' data.txt data.csv > out.txt \
        && cmp out.txt <(printf "%s\n" data.txt data.csv); then
    echo "Test 8: Pass"
    pass+=1
else
    echo "Test 8: Fail"
    fail+=1
fi

# Test ENDFILE
if ./tawk 'ENDFILE { incr x; puts $x; puts $FILENAME }' data.txt data.csv > out.txt \
        && cmp out.txt <(printf "%s\n" 1 data.txt 2 data.csv); then
    echo "Test 9: Pass"
    pass+=1
else
    echo "Test 9: Fail"
    fail+=1
fi

# Missing script
if ! output=$(./tawk 2>&1) && [[ $output == "Error: Missing script argument." ]]; then
    echo "Test 10: Pass"
    pass+=1
else
    echo "Test 10: Fail"
    fail+=1
fi

# Set FS via command line option
if ./tawk -F , 'line { puts $F(1) }' data.csv > out.txt \
        && cmp out.txt <(printf "%s\n" "${letters[@]}"); then
    echo "Test 11: Pass"
    pass+=1
else
    echo "Test 11: Fail"
    fail+=1
fi

# Safe mode with no error
if ./tawk -safe -F , 'line { puts $F(1) }' data.csv > out.txt \
        && cmp out.txt <(printf "%s\n" "${letters[@]}"); then
    echo "Test 12: Pass"
    pass+=1
else
    echo "Test 12: Fail"
    fail+=1
fi

# Safe mode with error
cat <<'EOF' >test.tawk
BEGIN {
      set FS ,
      set f [open "out.txt" w]
}
line { puts $f $F(1) }
END { close $f }
EOF
if ! output=$(./tawk -safe -f test.tawk data.csv 2>&1) \
        && [[ $output == Error* ]]; then
    echo "Test 13: Pass"
    pass+=1
else
    echo "Test 13: Fail"
    fail+=1
fi

if ./tawk -f test.tawk data.csv && cmp out.txt <(printf "%s\n" "${letters[@]}"); then
    echo "Test 14: Pass"
    pass+=1
else
    echo "Test 14: Fail"
    fail+=1
fi

# Timeout without error
if ./tawk -timeout 10 'line { puts $F(2) }' data.txt > /dev/null; then
    echo "Test 15: Pass"
    pass+=1
else
    echo "Test 15: Fail"
    fail+=1
fi

# Timeout with error
if ! ./tawk -timeout 2 'line {$NR == 2} { after 3000 }' data.txt > /dev/null 2>&1; then
    echo "Test 16: Pass"
    pass+=1
else
    echo "Test 16: Fail"
    fail+=1
fi

# Fields with spaces
cat <<EOF >data2.csv
red fox,1
brown dog,2
grey cat,3
EOF
if ./tawk -F , 'line { puts "[string toupper $F(1)]" }' data2.csv > /dev/null; then
    echo "Test 17: Pass"
    pass+=1
else
    echo "Test 17: Fail"
    fail+=1
fi

# Test print
cat <<EOF >out2.txt
1,red fox
2,brown dog
3,grey cat
EOF
if ./tawk -F , 'line { print $F(2) $F(1) }' OFS=, data2.csv > out.txt \
        && cmp out.txt out2.txt; then
    echo "Test 18: Pass"
    pass+=1
else
    echo "Test 18: Fail"
    fail+=1
fi

# Test csv_join
if ./tawk -F , 'line { puts [csv_join [list $F(2) $F(1)]] }' data2.csv > out.txt \
        && cmp out.txt out2.txt; then
    echo "Test 19: Pass"
    pass+=1
else
    echo "Test 19: Fail"
    fail+=1
fi

# Test multi-line CSV records
cat <<EOF > data3.csv
1,2,"
6",7
3,4,5,8
EOF
if output=$(./tawk -csv 'line { incr sum $F(3) }
   END { puts $sum }' data3.csv) \
        && [[ $output -eq 11 ]]; then
    echo "Test 20: Pass"
    pass+=1
else
    echo "Test 20: Fail"
    fail+=1
fi

# Test setting a read-only variable
if ! ./tawk 'BEGIN { set CSV 1 }' data2.csv > /dev/null 2>&1; then
    echo "Test 21: Pass"
    pass+=1
else
    echo "Test 21: Fail"
    fail+=1
fi

# Test csv mode print
if ./tawk -csv 'line { print $F(2) $F(1) }' data2.csv > out.txt \
        && cmp out.txt out2.txt; then
    echo "Test 22: Pass"
    pass+=1
else
    echo "Test 22: Fail"
    fail+=1
fi

# Test continue, which should skip the rest of the current line
if output=$(./tawk -F , '
   line {
        if {$NR > 1} { continue }
        set total $F(2)
   }
   line { incr total $F(2) }
   END { puts $total }' data2.csv) && [[ $output -eq 2 ]]; then
    echo "Test 23: Pass"
    pass+=1
else
    echo "Test 23: Fail $output"
    fail+=1
fi

# Test break, which should skip the remainder of the current file
if output=$(./tawk -csv '
   BEGIN { set total 0 }
   line {
        if {$NR == 1} { break }
        incr total $F(2)
   }
   line { incr total $F(2) }
   END { puts $total }' data2.csv data2.csv) && [[ $output -eq 12 ]]; then
    echo "Test 24: Pass"
    pass+=1
else
    echo "Test 24: Fail"
    fail+=1
fi

# Test error, which should abort the script
if ! output=$(./tawk '
   BEGIN { error Test }
   line { puts Fail }' data2.csv 2>&1) \
   && [[ $output == "Error: Test" ]]; then
    echo "Test 25: Pass"
    pass+=1
else
    echo "Test 25: Fail"
    fail+=1
fi

# Test regular expressions
if output=$(./tawk '
   rline {[bc]} { incr sum $F(2) }
   END { puts $sum }' data.txt) && [[ $output -eq 5 ]]; then
    echo "Test 26: Pass"
    pass+=1
else
    echo "Test 26: Fail"
    fail+=1
fi

if output=$(./tawk '
   rline -field 1 {[bc]} { incr sum $F(2) }
   END { puts $sum }' data.txt) && [[ $output -eq 5 ]]; then
    echo "Test 27: Pass"
    pass+=1
else
    echo "Test 27: Fail"
    fail+=1
fi

if output=$(./tawk '
   BEGIN { set sum 0 }
   rline -field 2 {[bc]} { incr sum $F(2) }
   END { puts $sum }' data.txt) && [[ $output -eq 0 ]]; then
    echo "Test 28: Pass"
    pass+=1
else
    echo "Test 28: Fail"
    fail+=1
fi

# Test invalid field numbers for rline
if ! ./tawk 'rline -field foo {[ab]} { puts $::F(0) }' data.txt 2>/dev/null; then
    echo "Test 29: Pass"
    pass+=1
else
    echo "Test 29: Fail"
    fail+=1
fi

if ! ./tawk 'rline -field -1 {[ab]} { puts $F(0) }' data.txt 2>/dev/null; then
    echo "Test 30: Pass"
    pass+=1
else
    echo "Test 30: Fail"
    fail+=1
fi

# Out of range positive fields are an empty string.
if output=$(./tawk 'rline -field 40 {[ab]} { puts $F(0) }' data.txt) \
   && [[ $output = "" ]]; then
    echo "Test 31: Pass"
    pass+=1
else
    echo "Test 31: Fail"
    fail+=1
fi

if output=$(./tawk 'rline -field 40 {^$} { puts $F(0) }' data.txt) \
   && [[ $output != "" ]]; then
    echo "Test 32: Pass"
    pass+=1
else
    echo "Test 32: Fail"
    fail+=1
fi

if output=$(./tawk 'BEGINFILE { gets $INFILE }
   line { incr sum $F(2) }
   END { puts $sum }' data.txt) \
         && [[ $output -eq 9 ]]; then
    echo "Test 33: Pass"
    pass+=1
else
    echo "Test 33: Fail"
    fail+=1
fi

# Test null FS
if output=$(./tawk -F '' 'line { puts $NF }' <<<"abcd" ) \
        && [[ $output -eq 4 ]]; then
    echo "Test 34: Pass"
    pass+=1
else
    echo "Test 34: Fail"
    fail+=1
fi

# Test setting F(0)
if output=$(./tawk '
   line { set FS "|"
          set F(0) "1|2|3"
          puts $F(1)
   }' <<<"a b c") && [[ $output -eq 1 ]]; then
    echo "Test 35: Pass"
    pass+=1
else
    echo "Test 35: Fail"
    fail+=1
fi

if output=$(./tawk '
   line { set FS "|"
          set F(0) "1|2|3|4"
          puts $NF
   }' <<<"a b c" ) && [[ $output -eq 4 ]]; then
    echo "Test 36: Pass"
    pass+=1
else
    echo "Test 36: Fail"
    fail+=1
fi

# Test setting NF
# shrinking
if output=$(./tawk '
   line { set NF 2
          print
   }' <<<"a b c") && [[ $output = "a b" ]]; then
    echo "Test 37: Pass"
    pass+=1
else
    echo "Test 37: Fail"
    fail+=1
fi

# growing
if output=$(./tawk '
   BEGIN { set OFS , }
   line { set NF 5
          print
   }' <<<"a b c" ) && [[ $output = "a,b,c,," ]]; then
    echo "Test 38: Pass"
    pass+=1
else
    echo "Test 38: Fail"
    fail+=1
fi

# Setting NF to 0
if output=$(./tawk '
   BEGIN { set OFS , }
   line { set NF 0
          print
   }' <<<"a b c" ) && [[ -z $output ]]; then
    echo "Test 39: Pass"
    pass+=1
else
    echo "Test 39: Fail"
    fail+=1
fi


# Test setting a higher than existing F(x)
if output=$(./tawk '
   BEGIN { set OFS , }
   line { set F(5) e
          print
   }' <<<"a b c" ) && [[ $output = "a,b,c,,e" ]]; then
    echo "Test 40: Pass"
    pass+=1
else
    echo "Test 40: Fail"
    fail+=1
fi


if output=$(./tawk '
   line { set F(5) e
          puts $NF
   }' <<<"a b c" ) && [[ $output -eq 5 ]]; then
    echo "Test 41: Pass"
    pass+=1
else
    echo "Test 41: Fail"
    fail+=1
fi

# Test an empty input line
if output=$(./tawk 'line { puts $NF }' <<<"") \
         && [[ $output -eq 0 ]]; then
    echo "Test 42: Pass"
    pass+=1
else
    echo "Test 42: Fail"
    fail+=1
fi

echo "Done."
echo "$pass tests passed, $fail tests failed."
if [[ $fail -ne 0 ]]; then
    exit 1
fi
