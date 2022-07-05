-----------------------------------------------------------------------
--                                                                   --
--                  R E P O R T   P R O C E S S O R                  --
--                                                                   --
--                     S p e c i f i c a t i o n                     --
--                                                                   --
--                           $Revision: 1.0 $                        --
--                                                                   --
--  Copyright (C) 2020  Hyper Quantum Pty Ltd.                       --
--  Written by Ross Summerfield.                                     --
--                                                                   --
--  This  package  processes queries ready for a report.   It  then  --
--  takes  the  output of those queries (in temporary tables  in  a  --
--  temporary  database) and produces a report.  The report may  be  --
--  either  tabular  or graphical.  The output is LaTex,  which  is  --
--  then processed by pdflatex, which produces a PDF file ready for  --
--  printing.                                                        --
--                                                                   --
--  Version History:                                                 --
--  $Log$
--                                                                   --
--  Urine_Records is free software; you can redistribute it  and/or  --
--  modify  it under terms of the GNU  General  Public  Licence  as  --
--  published by the Free Software Foundation; either version 2, or  --
--  (at   your  option)  any  later  version.    Urine_Records   is  --
--  distributed  in  hope that it will be useful, but  WITHOUT  ANY  --
--  WARRANTY; without even the implied warranty of  MERCHANTABILITY  --
--  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public  --
--  Licence for  more details.  You should have received a copy  of  --
--  the GNU General Public Licence distributed with  Urine_Records.  --
--  If  not,  write to the Free Software  Foundation,  51  Franklin  --
--  Street, Fifth Floor, Boston, MA 02110-1301, USA.                 --
--                                                                   --
-----------------------------------------------------------------------
with GNATCOLL.SQL.Exec;
with dStrings;                  use dStrings;
package Report_Processor is

   -- Exceptions raised by the various error conditions
   Query_Error : exception;
   Graph_Error : exception;
   LaTex_Error : exception;

   procedure Initialise(with_DB_descr: GNATCOLL.SQL.Exec.Database_Description;
                        path_to_temp : string := "/tmp/";
                        with_tex_path: text := Value("pdflatex");
                        with_pdf_path: text := Value("xpdf");
                        with_R_path  : text := Value("R"));
       -- Initialise, saving away the database that will be operated on
       -- by the SQL queries.  It is also the location where the SQL queries
       -- are kept, in the Queries table, pointed to by the Reports table.
       -- Additionally, initialise sets up the temporary database where the
       -- results of the queries are stored and, if necessary, further
       -- manipulated.
    
   procedure Run_The_Report(with_id : in natural);
       -- Run the specified report number, executing the queries pointed to by
       -- the report number in their numerical sequence, then, if required,
       -- generating any diagrams or graphs, then generating the LaTex and
       -- finally producing a PDF using pdf2latex.
       -- Using nesting, the reports may have groups (and groups within groups)
       -- as group headers and footers to contain detailed data.
       -- All data used in the report is taken from a temporary database,
       -- temp.db, which is stored in the temporary directory (/tmp/ on unix).
       -- This database is in SQLite (version 3) format, so this module is
       -- compiled with the GNATCOLL.SQL.Sqlite package.
       -- Full details on the syntax or format is with the sub-component
       -- declarations in the private section below.
       
   function Number_of_Reports return natural;
       -- Return the total number of reports.
       
   function Report_FileName(for_report_number : in natural) return string;
       -- For the number (starting at 1, going up to Number_of_Reports), return
       -- the filename of the report.  for_report_number is sequential in the
       -- list of reports and may not be the same as the report's numerical ID
       -- (but should be).
       
   function Report_Name(for_report_number : in natural) return string;
       -- For the number (starting at 1, going up to Number_of_Reports), return
       -- the name of the report.  for_report_number is sequential in the list
       -- of reports and may not be the same as the report's numerical ID (but
       -- should be).  The name is what is in the Reports menu or on the
       -- report button for the report.
       
   function Report_ID(for_report_number : in natural) return natural;
       -- Translate the report number into the report ID (i.e. into with_id).

   function Report_ID(for_report_name : in string) return natural;
       -- Translate the report name into the report ID (i.e. into with_id).
    
private
   procedure Run_Queries(for_report_id : in natural);
       -- In the specified sequence, run the report queries.
       -- If the TargetTbl field contains a value (that is, is not blank),
       -- then the data is drawn (in all cases) from the main database
       -- and the result of the query is dumped into the temp.db.
       -- If the TargetTbl field is blank or null, then the query operates
       -- entirely on the temporary database, temp.db.
       
   procedure Generate_Graphs(for_report_id : in natural);
       -- Following the loaded up instructions, generate graphs using R.
       -- It requires the RSQLite package for GNU R to be installed.
       -- 
       -- The outputted encapsulated postscript graph files, stored in the
       -- specified temporary directory, need to have their names synchronised
       -- with the matching LaTex and need to have the .eps extension, for
       -- example, "result1.eps", which should be similarly referenced in the
       -- LaTex file.
       -- The texlive-font-utils package and its dependent ps2eps package is
       -- required to generate the graph.
       
   procedure Generate_LaTex(for_report_id : in natural);
       -- In accordance with instructions and folding in any generated graphs,
       -- output the LaTex that describes the report.
       -- The LaTex, stored in the LaTex field of the Reports table, is
       -- processed line by line.  Lines starting with a chevron and the
       -- word Query and a number («QUERY <num>:) and terminated by the closing
       -- chevron (»)are treated specially.  The query encapsulated in between
       -- is executed on the temporary database and then, for each row returned
       -- in the result set, the following rows, up to the closing chevron
       -- encapsulated «END QUERY <num>» statement, are processed recursively.
       -- These two statements need to be on their own line.
       -- Substitution of parameters into the query from the parent query is via
       -- the "?" statement as is standard for SQLite, but you need to make sure
       -- that the number of "?" is no more than the number of parameters
       -- available.  The parameter number follows the "?", for instance
       -- to push in parameter 2, it would be "?2".
       -- Fields are referenced by column number (starting from 0) as per the
       -- format «FIELD:<num>», with the (text converted) result substituted
       -- in as the LaTex is written out to its temporary <Filename.tex> file.
       -- Encapsulated postscript files are referenced directly by the name
       -- used in the LaTeX file.  This is typically done by referencing in the
       -- epstopdf package (viz \usepackage{epstopdf}), then if the
       -- encapsulated postscript file is called result1.eps, running the
       -- command, \includegraphics[width=1\linewidth]{result1}.
       
   procedure Display_Report(for_report_id : in natural);
       -- Execute pdflatex on the generated LaTex, then display the generated
       -- PDF using a PDF viewer.  It is from that PDF viewer that the report
       -- can be printed by the user.

end Report_Processor;