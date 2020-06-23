#!/usr/bin/env bash

set +o noclobber
trap "rm -f data.txt data.csv test.tawk out*.txt" EXIT

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
   line { incr total $F(2) }
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


echo "Done."
echo "$pass tests passed, $fail tests failed."
if [[ $fail -ne 0 ]]; then
    exit 1
fi
