tawk - awk but in tcl
=====================

`awk` is a great tool for working with columnar data a line at a time,
but the langauge itself is a bit limited. Usually when it's not quite
powerful enough, I turn to `perl`. But... choice is good. Enter
`tawk`, which uses `tcl` as the scripting language. It's designed to
be very familiar to anyone coming from an `awk` background.

Running `tawk`
==============

Much like `awk`:

    tawk [OPTIONS] ['script'] [var=value | filename] ...

Reads from standard input if no filenames are given on command line.

Installing
----------

Dependencies are tcl 8.6, and tcllib. Copy the `tawk` script to
`/usr/local/bin` or wherever - it's a single, self-contained script.

Options
-------

* `-F regexp` Sets the field seperator (`FS`).
* `-f filename` Read the script from the given file instead of it
  being the first non-option command line argument.
* `-safe` Run the script in a safe tcl interpreter. Meant for untrusted code.
* `-timeout N` Exit with an error if a script takes more than `N`
  seconds to complete.
* `-csv` Turn on CSV line parsing. Prefer this over setting `FS` to a comma.

The language
============

Commands
--------

`tawk` adds the following commands on top of basic `tcl`:

### These are available as top-level commands.

* `BEGIN script` Executed at the beginning of processing, before any data.
* `END script` Executed at the end, after processing all data.
* `BEGINFILE script` Executed at the beginning of each file.
* `ENDFILE script` Executed at the end of reading each file.
* `line script` Executed for every line read.
* `line test script` If `test` returns true when evaluated by `expr`,
  executes the script.
* `rline re script` If the regular expression `re` matches the line,
  executes the script.

### These are available everywhere
* `print [arg ...]` Print out all its arguments joined by `$OFS`, or
  `$F(0)` if called with no arguments.
* `csv_join arglist [delim]` Return the list joined into a CSV-formatted string.
* `csv_split string [delim]` Split a CSV-formatted string into a list.

### Changes to existing commands

* `continue` stops processing the current line and goes to the next. Like `next` in awk.
* `break` stops processing the current file and goes on to the next.

Variables
---------

Most of these are lifted straight from `awk` names.

* `F` An array holding the columns of the line. `$F(0)` is the whole line.
* `NF` The number of fields in the current line. Modifying this adjusts `F`.
* `NR` The current line number.
* `FNR` The line number of the current file.
* `FILENAME` The name of the current file, `-` for standard input.
* `FS` If set, a single character, or regular expression that is used
  to indicate field delimiters. If an empty string or not set, any
  amount of whitespace is used.
* `OFS` Used to separate fields in `F(0)` when other elements of `F`
  are written to or `NF` is changed.
* `CSV` 1 if in CSV mode, 0 if in normal mode.

CSV Mode
--------

If invoked with the `-csv` option, the default field separator (`FS`)
and output field separator (`OFS`) are set to comma instead of
whitespace, and lines are split by a CSV parser - so commas in quoted
fields don't count, unlike if just setting `FS` to a comma. Also, the
`print` command CSV-escapes its arguments, and `gets` reads a full CSV
record, which may be multiple lines.
