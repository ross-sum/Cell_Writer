# Cell Writer
$Date: Sat Apr 2 21:02:14 2022 +1000$



## Building

Cell Writer uses the following packages:
1. GTKAda - this is for the user interface.  In fact, it uses Glade.
2. AdaSockets - this is used by some of the library packages, so is
   not directly required, but is needed for compilation.
3. GnatColl, GnatColl_SQL and GnatColl_SQLite - for database access to
   the symbol template data and other matters related to the use of
   Cell Writer.
4. Dynamic-Strings - this is a super-set of the unbounded wide strings
   package (and pre-dates it in its origin).  it is expected to be at
   the same directory level as the top level of Cell writer, but in
   its own ../dynamic-strings/ directory.
5. Hyper Quantum's Tools library - various tools are used from this
   library and they are expeced  to also be at the same directory
   level as the top level of Cell writer, namely in its own
   ../tools/ directory.
6. Jordan Sissel's xdoTool 
   (see https://github.com/jordansissel/xdotool/tree/master)


## Installation

Install xDoTool viz 'apt-get install xdotool'.
Compile and load the Ada software.


## Execution

The main issue to consider during execution of Cell Writer is the location of
the log file.  If the system administrator has not made /var/log/cell_writer.log
world writable (or, at least, writable by users who will be using Cell Writer),
then you must specify your own log file.  Otherwise, you can just use the default
and not specify it on the command line.  The other factor to consider is the level
of logging required.  When the application is stable, this can be left blank (i.e.,
only log errors), but otherwise you may choose something more vigorous.  A log
level is a number between 1 (almost no logging) and 9 (log everything).
When logging, the --format option determines whether to use UTF-8 formatting or
not.  If just using Cell Writer for a language like English (or, perhaps, most
European languages), then this need not be specified.  If using it for a language
like Blissymbolics, then it should be specified, but in that case, you must view
the log file with an editor that can view in the language specified.

Execute via something like:
cell_writer --log /tmp/cellwriter.log --format WCEM=8,ctrl --debug 5


