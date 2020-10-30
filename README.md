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
* `-quotechar C` Use the given character instead of double quote for
  quoted CSV fields.
* `-quoteall` Always quote every CSV field when printing.

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
  execute the script.
* `rline [-field N] re script` If the regular expression `re` matches
  the line, (Or the specified field), execute the script.

### These are available everywhere
* `print [arg ...]` Print out all its arguments joined by `$OFS`, or
  `$F(0)` if called with no arguments.
* `csv_join arglist [delim] [quotechar] [quotemode]` Return the list
  joined into a CSV-formatted string.
* `csv_split string [delim] [quotechar]` Split a CSV-formatted string
  into a list.

### Changes to existing commands

* `continue` stops processing the current line and goes to the next. Like `next` in awk.
* `break` stops processing the current file and goes on to the next.

Variables
---------

Most of these are lifted straight from `awk` names.

* `F` An array holding the columns of the line. `$F(0)` is the whole
  line. Setting a new element above `NF` fills in the missing interval
  with empty strings. Setting `F(0)` rebuilds the rest of the array
  based on splitting the new value.
* `NF` The number of fields in the current line. Modifying this adjusts `F`.
* `NR` The current line number.
* `FNR` The line number of the current file.
* `FILENAME` The name of the current file, `-` for standard input.
* `INFILE` The file handle of the current file. Only set in
  `BEGINFILE`, `line` and `rline` blocks.
* `FS` If set, a single character, or regular expression that is used
  to indicate field delimiters. If a a single space, or not set, any
  amount of whitespace is used, and leading and trailing whitespace is
  first stripped. If an empty string, splits every character into its
  own field. Can only be a single character in CSV mode.
* `OFS` Used to separate fields in `F(0)` when other elements of `F`
  are written to or `NF` is changed. Also used to seperate arguments
  of `print`. Can only be a single character in CSV mode.
* `CSV` 1 if in CSV mode, 0 if in normal mode. (Read-only)
* `CSVQUOTECHAR` when in CSV mode, the character used to quote
  fields. Set by the `-quotechar` option. Defaults to a double quote.
* `CSVQUOTE` Set to `always` to always quote CSV fields (Turned on by
  the `-quoteall` argument), or `auto` to only quote when
  needed. Attempting to set other values raises an error. Defaults to
  auto.

CSV Mode
--------

If invoked with the `-csv` option, the output field separator (`OFS`)
is set to comma instead of a space, and `print` joins its arguments
with CSV escaping.

When reading fields, the default field separator (`FS`) if not
explicitly set is a comma, and only single-character separators are
supported. Lines are split by a CSV-aware parser - so commas in quoted
fields don't count, unlike if just setting `FS` to a comma in normal
mode. The `CSVQUOTECHAR` variable controls the character used to quote
fields (Defaults to double quote, set by the `-quotechar` option.)

Also, the `print` command CSV-escapes its arguments, and `gets` reads
a full CSV record, which may be multiple lines.
