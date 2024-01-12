# Cell Writer
$Date: Sat Apr 2 21:02:14 2022 +1000$

## Description

Cell Writer is a grid-entry natural handwriting recognition input panel.   As
you write characters into the cells, your writing is instantly recognised at
the character level.  When you press 'Send' on the panel, the input you entered
is sent to the currently focused application as if typed on the keyboard.

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

The reports use GNU R, LaTex (TexLive edition), RSQLite and a PDF display
tool (by default, on Linux, it is xPDF).

## Installation

* It may be wise to install the Blissymbolics package first.
* Ensure Gnat is installed:
    `apt-get install gnat`
* Ada sockets is required by the Hyper Quantum Ada tools; install viz:
    `apt-get install libadasockets12-dev libadasockets10`
* Install xDoTool viz: 
    `apt-get install xdotool`
* Install GnatColl, with the last 3 packages being the runtime librearies, viz:
    `apt-get install libgnatcoll-sql5-dev libgnatcoll-sqlite21-dev libgnatcoll-sql3 libgnatcoll-sqlite20 libgnatcoll21`
  Install TexLive, which should load additional required TexLive packages, viz:
    `apt-get install texlive texlive-fonts-extra texlive-fonts-recommended`
* Install R and RSQLite viz:
    `apt-get install r-base  r-cran-rsqlite`
  Install xPDF viz:
    `apt-get install xpdf`
* Install the ToBase64 application, which is a sub-package to the Urine Records 
  repository.  Download the Urine Records repository, then do the following:
    `make tobase64s'
  Then pop the executable (in one of the obj_* direcotories) into a location
  where it can be found by the Cell Writer installation script.
* Compile and load the Ada software, viz from the top level Cell Writer directory:
    `make ; sudo make install`

## Usage

The full instructions for using Cell Writer are contained in the on-line manual,
which is available from within the application under Help (click on the Help|
About button, (?) to bring up the About dialogue box, then select the Manual tab).

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

## Support

For help, email me at ross<at>hyperquantum<dot>com<dot>au.  Otherwise, 
issue tracking is through GitHub.

If you wish to contribute, see Contributing and Roadmap sections below.

## Contributing

Contributions are welcome.  The following needs to be done.

We need to get the Blissymbolics language recognised by the Unicode Consortium. 
This may require a few of us writing a few books and probably requires a lot of 
lobbying.  Prior to that, we all need to agree on the character set.  That may 
take a bit of work.  Please see the Blissymbolics repository for more 
information.

There is a bit of coding work to do.  As Michael Levin points out, his 
recognition engine is not good for large character sets.  Its accuracy decreases 
and it slows right down as the number of enrolled symbols increases.  I plan to 
investigate the use of i-vector or x-vector.

The roadmap section below outlines a lot of work other than changing out the 
recognition engine that needs to be done.  Help would be welcomed there.

To help, contact me, Ross Summerfield, ross <at> hyperquantum <dot> com <dot> au.
Collaboration is envisaged to be through Github.

## Authors and acknowledgment

Clearly, a lot of thanks goes to Michael Levin.  It was his initial cellwriter
C program that inspired me to do something.  The alternatives were to alter
his code or do a complete rewrite.  Michael's code did not really lend itself
to the sort of internal modification envisaged.  But it was an important source
of information and his user interface layout approach is excellent.

I would also like to thank the late Dr Charles K. Bliss.  It was an article about 
him and Blissymbolics in a Readers Digest magazine that I read when I was really 
young that got me interested in the symbol set.  That inspired me to look for a 
practical way to input Blissymbolics symbols into a computer.

##Licence

Cell_Writer is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public Licence as published by the Free Software 
Foundation; either version 2, or (at your option) any later version.  Cell_Writer 
is distributed in hope that it will be useful, but WITHOUT ANY WARRANTY; without 
even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public Licence for more details.  You should have received 
a copy of the GNU General Public Licence distributed with  Cell_Writer. If not, 
write to the Free Software Foundation, 51 Franklin Street, Fifth Floor, Boston, 
MA 02110-1301, USA.

## Project status

As detailed in the Manual, the current project status is in its early days.  It 
needs a bit of work right now.

Outstanding features required of the application and other work required are as 
follows:
* A complete rewrite of the recognition engine is required.  This should speed 
up the recognition and make it less susceptible to the number of characters or 
words that it is trained to recognise.  Right now, it slows down considerably 
as you approach 100 words.  For Blissymbolics, the average user would have as 
many as 500 words trained and an advanced user would have maybe 2000 words 
trained.
* Display/hide navigation keys with swipe left (left button down) over the key 
area and swipe right over the edge.
* Check the Blissymbolics words against documentation by Dr Charles K Bliss (the 
designer of Blissymbolics) to confirm correctness.  Then check against BCI's 
outlines.  Because Dr Bliss designed the symbols and as he has noted in  his 
documentation that he wishes to avoid symbol shape drift over time, the approach 
taken here has been to assume his documentation takes precedence.  (But if you 
disagree, you can edit the symbol set yourself - it is in the database that 
comes with this application.)
* Compare the word table against BCI words and add in any that are missing.
* Error repair including for cell redraw (error number 20), for changing the 
fonts, for closing the main form by clicking the X (in the top right hand 
corner) on the Grid Entry's application bar, and for the race hazard with 
report generation.
* Allow editing and update of the CSS in the Setup dialogue box and make the 
changes take effect straight away.  See Gtk.Text_Buffer for the hooks for 
editing (e.g. cut, copy, paste, selection and iterators).
* Get the cursor to operate and display correctly in the data entry display 
area of the on-screen keyboard.  It doesn't display and it sometimes does not 
work.
* Modify Cell writer so that all components of the system, including hints, 
about text and help, use the selected language in the selected font.
* Provide a configuration key that allows memory of the Number Lock ('NL' key) 
status.
* Get window docking to work.
* Add or replace training samples from characters where recognition was 
previously unclear, that is, where there were many possible alternatives and 
that with the highest score was not selected.  In particular:
   - Add training samples when sample counts is less than the user setting (and 
     certainly when less than the maximum number permitted).
      + Decide based on deviation Decide based on deviation from average for 
        each training sample for that character or word.
   - Replace unmatched or rarely matched samples when the training sample count 
     has reached or exceeded maximum.
* Provide a PostgreSQL option for the main database.
* Display the Manual using a mark-up to highlight headings and the like.  At the 
moment it does not do that, rather it just displays plain text (with the 
mark-up/mark-down displayed as plain text).
* Code linting and automated testing is required.

