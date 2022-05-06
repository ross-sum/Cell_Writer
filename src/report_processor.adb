-----------------------------------------------------------------------
--                                                                   --
--                  R E P O R T   P R O C E S S O R                  --
--                                                                   --
--                              B o d y                              --
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
-- with GNATCOLL.SQL.Exec;
-- with dStrings;                  use dStrings;
with GNATCOLL.SQL.Exec.Tasking;
with GNATCOLL.SQL.Sqlite;   -- or Postgres
with GNATCOLL.SQL_Impl;
with GNATCOLL.SQL;               use GNATCOLL.SQL;
with Database;                   use Database;
with Error_Log;
with Cell_Writer_Version;
with dStrings.IO;
with Strings_Functions;
with String_Conversions;
with Ada.Characters.Latin_1;
with Host_Functions;
package body Report_Processor is
   use GNATCOLL.SQL.Exec;
   
   -- Exceptions raised by the various error conditions
   -- Query_Error : exception;
   -- Graph_Error : exception;
   -- LaTex_Error : exception;

   line_feed_char : constant wide_character := 
                  wide_character'Val(character'Pos(Ada.Characters.Latin_1.LF));
   rDB : GNATCOLL.SQL.Exec.Database_Connection;
   tDB : GNATCOLL.SQL.Exec.Database_Connection;
   R_reports : GNATCOLL.SQL.Exec.Direct_Cursor;
   temp_path : text;
   tex_path  : text;
   pdf_path  : text;
   R_path    : text;

   -- Set up all the prepared queries
   reports_select : constant GNATCOLL.SQL.Exec.Prepared_Statement :=
      GNATCOLL.SQL.Exec.Prepare 
           (SQL_Select(Fields  => Reports.ID & Reports.Name & 
                                  Reports.Filename & Reports.HasGraph &
                                  Reports.R & Reports.LaTex,
                       From    => Reports,
                       Order_By=> Reports.ID),
            On_Server => True,
            Use_Cache => True);
   queries_select : constant GNATCOLL.SQL.Exec.Prepared_Statement :=
      GNATCOLL.SQL.Exec.Prepare 
           (SQL_Select(Fields  => Queries.Q_Number & Queries.TargetTbl & 
                                  Queries.SQL,
                       From    => Queries,
                       Where   => Queries.ID = Integer_Param(1),
                       Order_By=> Queries.Q_Number),
            On_Server => True,
            Use_Cache => True);
   
   procedure Initialise(with_DB_descr: GNATCOLL.SQL.Exec.Database_Description;
                        path_to_temp : string := "/tmp/";
                        with_tex_path: text := Value("pdflatex");
                        with_pdf_path: text := Value("xpdf");
                        with_R_path  : text := Value("R"))
   is
       -- Initialise, saving away the database that will be operated on
       -- by the SQL queries.  It is also the location where the SQL queries
       -- are kept, in the Queries table, pointed to by the Reports table.
       -- Additionally, initialise sets up the temporary database where the
       -- results of the queries are stored and, if necessary, further
       -- manipulated.
   begin
      -- First, stash away the main database pointer
      rDB := GNATCOLL.SQL.Exec.Tasking.Get_Task_Connection
                                                  (Description=>with_DB_descr);
      -- and run the query to load the data
      R_reports.Fetch (Connection => rDB, Stmt => reports_select);
      -- Then set up the temporary database (called, e.g., /tmp/temp.db)
      tDB := GNATCOLL.SQL.Exec.Build_Connection
                 (Self => GNATCOLL.SQL.Sqlite.Setup(path_to_temp & "temp.db"));
      -- Save away the path to the temporary files for location of the
      -- .eps files, the .tex file and the .pdf file.
      temp_path := Value(from => path_to_temp);
      -- And save away the path to the applications called for report
      -- generation and display.
      tex_path  := with_tex_path;
      pdf_path  := with_pdf_path;
      R_path    := with_R_path;
   end Initialise;
       
   function Number_of_Reports return natural is
       -- Return the total number of reports.
   begin
      return R_reports.Rows_Count;
   end Number_of_Reports;
       
   function Report_FileName(for_report_number : in natural) return string is
       -- For the number (starting at 1, going up to Number_of_Reports), return
       -- the filename of the report.  for_report_number is sequential in the
       -- list of reports and may not be the same as the report's numerical ID
       -- (but should be).
   begin
      if R_reports.Current = for_report_number then
         null;  -- nothing to do here
      elsif R_reports.Current > for_report_number then
         R_reports.First;
         for row_num in 2 .. for_report_number loop
            if Has_Row(R_reports) then
               R_reports.Next;
            end if;
         end loop;
      elsif R_reports.Current < for_report_number then
        -- current row less than report number, so go to it
         for row_num in R_reports.Current + 1 .. for_report_number loop
            if Has_Row(R_reports) then
               R_reports.Next;
            end if;
         end loop;
      end if;
      if R_reports.Current = for_report_number then -- got there
         return Value(R_reports, 2);
      else  -- went past the end of data
         return "";
      end if;
   end Report_FileName;
       
   function Report_Name(for_report_number : in natural) return string is
       -- For the number (starting at 1, going up to Number_of_Reports), return
       -- the title of the report.  for_report_number is sequential in the list
       -- of reports and may not be the same as the report's numerical ID (but
       -- should be).  The title is what is in the Reports menu or on the
       -- report button for the report.
   begin
      if R_reports.Current = for_report_number then
         null;  -- nothing to do here
      elsif R_reports.Current > for_report_number then
         R_reports.First;
         for row_num in 2 .. for_report_number loop
            if Has_Row(R_reports) then
               R_reports.Next;
            end if;
         end loop;
      elsif R_reports.Current < for_report_number then
        -- current row less than report number, so go to it
         for row_num in R_reports.Current + 1 .. for_report_number loop
            if Has_Row(R_reports) then
               R_reports.Next;
            end if;
         end loop;
      end if;
      if R_reports.Current = for_report_number then -- got there
         return Value(R_reports, 1);
      else  -- went past the end of data
         return "";
      end if;
   end Report_Name;
       
   function Report_ID(for_report_number : in natural) return natural is
       -- Translate the report number into the report ID (i.e. into with_id).
   begin
      if R_reports.Current = for_report_number then
         null;  -- nothing to do here
      elsif R_reports.Current > for_report_number then
         R_reports.First;
         for row_num in 2 .. for_report_number loop
            if Has_Row(R_reports) then
               R_reports.Next;
            end if;
         end loop;
      elsif R_reports.Current < for_report_number then
        -- current row less than report number, so go to it
         for row_num in R_reports.Current + 1 .. for_report_number loop
            if Has_Row(R_reports) then
               R_reports.Next;
            end if;
         end loop;
      end if;
      if R_reports.Current = for_report_number then -- got there
         return Integer_Value(R_reports, 0);
      else  -- went past the end of data
         return 0;
      end if;
   end Report_ID;
        
   function Report_ID(for_report_name : in string) return natural is
       -- Translate the report name into the report ID (i.e. into with_id).
      use String_Conversions;
   begin
      if Value(R_reports, 1) = for_report_name then
         null;  -- nothing to do here
      else
         R_reports.First;
         for row_num in 1 .. R_reports.Rows_Count loop
            if Has_Row(R_reports) then
               if Value(R_reports, 1) = for_report_name then
                  exit;
               else
                  R_reports.Next;
               end if;
            end if;
         end loop;
      end if;
      if Value(R_reports, 1) = for_report_name then -- got there
         Error_Log.Debug_Data(at_level => 6, 
                              with_details => "Report_ID: "&
                                    To_Wide_String(Value(R_reports, 1)) & ".");
         return Integer_Value(R_reports, 0);
      else  -- went past the end of data
         Error_Log.Debug_Data(at_level => 4, 
                              with_details => "Report_ID: Not found!");
         return 0;
      end if;
   end Report_ID;
   
   function Go_to_Row(with_report_id : in natural) return natural is
      -- Go to the correct row in the R_reports table for the specified
      -- ID (if not already there)
      -- Then return the report row number.
      report_number : natural := 0;
   begin
      if not (Has_Row(R_reports) and then 
             Integer_Value(R_reports,0) = with_report_id)
      then  -- not currently on the correct report row - go and find it
         R_reports.First;
         while Has_Row(R_reports) 
         and then Integer_Value(R_reports, 0) /= with_report_id loop
            R_reports.Next;
            report_number := report_number + 1;
         end loop;
         if Has_Row(R_reports) 
         and then Integer_Value(R_reports, 0)=with_report_id then  -- got there
            report_number := report_number + 1;
         else
            report_number := 0;  -- default value for when we never got there
         end if;
         return report_number;
      else
         return R_reports.Current;
      end if;
   end Go_to_Row;
      
   procedure Run_The_Report(with_id : in natural) is
       -- Run the specified report number, executing the queries pointed to by
       -- the report number in their numerical sequence, then, if required,
       -- generating any diagrams or graphs, then generating the LaTex and
       -- finally producing a PDF using pdf2latex.
       -- Using nesting, the reports may have groups (and groups within groups)
       -- as group headers and footers to contain detailed data.
      report_number : natural := 0;
   begin
      Error_Log.Debug_Data(at_level=>5, with_details=>"Run_The_Report: Start");
      -- Go to the desired row in the Reports table
      report_number := Go_to_Row(with_report_id => with_id);
      -- First, run the queries for the specified report number
      Run_Queries(for_report_id => with_id);
      -- If there are graphs, generate them
      if Report_ID(for_report_number => report_number) > 0 and then
            Boolean_Value(R_reports, 3) then
         Generate_Graphs(for_report_id => with_id);
      end if;
      -- Compose the Report
      Generate_LaTex(for_report_id => with_id);
      Display_Report(for_report_id => with_id);
   end Run_The_Report;
    
-- private
   procedure Run_Queries(for_report_id : in natural) is
       -- In the specified sequence, run the report queries.
      use String_Conversions;
      Q_reports  : GNATCOLL.SQL.Exec.Forward_Cursor;
      the_query  : GNATCOLL.SQL.Exec.Forward_Cursor;
      num_fields : natural;
      the_insert : Text;
   begin
      Error_Log.Debug_Data(at_level=> 5, with_details=> "Run_Queries: Start ("& 
                                     To_Wide_String(for_report_id'Image) &")");
      -- Get the queries for this report Identifier
      Q_reports.Fetch (Connection => rDB, Stmt => queries_select, 
                       Params => (1 => +for_report_id));
      while Has_Row(Q_reports) loop  -- execute each of the queries
         Error_Log.Debug_Data(at_level=> 6, with_details=> "Run_Queries: HasRow");
         if Value(Q_reports, 1)'Length > 0 then -- a target table specified
            Error_Log.Debug_Data(at_level=> 6, with_details=> "Run_Queries: "&
                                    To_Wide_String(Value(Q_reports, 1)) & ".");
            -- execute the query on the (main) database
            Fetch(Result => the_query, Connection => rDB,
                  Query  => Value(Q_reports, 2));
            -- build the insert query statement to insert into temp database
            num_fields := Natural(the_query.Field_Count);
            the_insert := "INSERT INTO " & Value(from => Value(Q_reports, 1)) &
                          " VALUES (";
            for field_num in 1 .. num_fields loop
               the_insert := the_insert & '?';
               if field_num < num_fields then  -- more parameters to come
                  the_insert := the_insert & ',';
               end if;
            end loop;
            the_insert := the_insert & ");";
            -- set up the parameter array
            declare
               the_params : SQL_Parameters(1..num_fields);
            begin
               Error_Log.Debug_Data(at_level=> 6, with_details=> "Run_Queries: Insert Query built '" &
                        Value(the_insert) & "'.");
            -- then, for each row, insert into the temporary database
               while Has_Row(the_query) loop
               -- first, load the parameter array
                  for field_num in 1 .. num_fields loop
                     if not Is_Null(the_query, Field_Index(field_num-1)) then
                        Error_Log.Debug_Data(at_level=> 6, with_details=> "Run_Queries: Parameter " &
                           To_Wide_String(Value(the_query, Field_Index(field_num-1))) & ".");
                        the_params(field_num) := +Value(the_query, 
                                                     Field_Index(field_num-1));
                     else
                        the_params(field_num) := Null_Parameter;
                     end if;
                  end loop;
               -- then execute the query to save the record in the temp DB
                  Error_Log.Debug_Data(at_level=> 6, with_details=> "Run_Queries: Loading " &
                        Value(the_insert) & "...");
                  Execute(Connection => tDB, Query => Value(the_insert), 
                          Params => the_params);
                  the_query.Next;
               end loop;
               Commit_Or_Rollback(Connection => tDB);
               if not Success(tDB) then  -- rolled back
                  Error_Log.Debug_Data(at_level=> 2, 
                                    with_details=> "Run_Queries: Rolled Back "&
                                          To_Wide_String(Value(Q_reports, 2)) &
                                           ".");
                  raise Query_Error;
               end if;
            end;
         else  -- no target table specified, so operates on temporary database
            Error_Log.Debug_Data(at_level=> 6, with_details=> "Run_Queries: Execute");
            Execute(Connection => tDB, Query => Value(Q_reports, 2));
            Commit_Or_Rollback(Connection => tDB);
            if not Success(tDB) then  -- rolled back
               Error_Log.Debug_Data(at_level=> 2, 
                                    with_details=> "Run_Queries: Rolled Back "&
                                          To_Wide_String(Value(Q_reports, 2)) &
                                           ".");
               -- raise Query_Error;
            end if;
         end if;
         Q_reports.Next;
      end loop;
   end Run_Queries;

   procedure Generate_Graphs(for_report_id : in natural) is
       -- Following the loaded up instructions, generate graphs using R.
       -- It requires the RSQLite package for GNU R to be installed.
      use dStrings.IO, Strings_Functions;
      use Host_Functions, String_Conversions;
      function Substitute_Parameters(for_line : in text;
                                     using_params : SQL_Parameters) 
      return text is
         -- Substitute in parameters, when something else, return that number.
         the_line : text;
      begin
         if Pos(pattern=>Value("«PARAM:"), source => for_line) > 0 then
            -- Parameter(s) specified, substitute in the parameter(s)
            the_line := for_line;
            -- substitute in any parameters into «PARAM:<num>»
            while Pos(Value("«PARAM:"), the_line) > 0 loop
               declare
                  field_pos : positive := Pos(Value("«PARAM:"),the_line);
                  end_pos   : positive := Pos(Value("»"),the_line);
                  field_str : text := for_line;
                  param_num : positive;
                  the_param : text;
               begin
                  Delete(field_str, 1, field_pos + 7);
                  -- extract the field number
                  param_num := Get_Integer_From_String(field_str);
                  -- extract the parameter
                  if using_params(param_num) = Null_Parameter then
                     Clear(the_param);
                  else
                     the_param := 
                           Value(from=>using_params(param_num).Image(tDB.all));
                  end if;
                        -- pop in the parameter
                  if end_pos + 1 >= Length(the_line) then
                     the_line := Sub_String(the_line, 1, field_pos - 1) &
                                       the_param;
                  else
                     the_line := Sub_String(the_line, 1, field_pos - 1) &
                                       the_param &
                                       Sub_String(the_line, end_pos + 2, 
                                               Length(the_line) - end_pos - 1);
                  end if;
               end;
            end loop;
            return the_line;
         else
            return for_line;
         end if;
      end Substitute_Parameters;
      procedure Process_R(for_R        : text_array;
                          using_params : SQL_Parameters;
                          to_file      : file_type) is
         line_num     : positive := 1;
      begin
         while line_num <= for_R'Last loop
            Error_Log.Debug_Data(at_level=>6, with_details=>"Process_R: " &
                                                   Value(for_R(line_num)));
            Put_Line(to_file, 
                     Substitute_Parameters(for_R(line_num), using_params));
            line_num := line_num + 1;
         end loop;
      end Process_R;
      report_number : natural := 0;
      the_file      : file_type;
      R_params      : SQL_Parameters (1..4):=(1=>+Value(of_string=>temp_path),
                                              2=>+(Value(R_reports,2) & ".R"),
                                              3=>+Value(of_string=>R_path),
                                              4=>+Value(of_string=>temp_path &
                                                                   "temp.db"));
   begin  -- Generate_Graphs
      Error_Log.Debug_Data(at_level=>5, with_details=>"Generate_Graphs: Start");
      -- Go to the desired row in the Reports table
      report_number := Go_to_Row(with_report_id => for_report_id);
      -- If the target file exists, delete it
      declare
         old_file : file_type;
      begin
         Open(old_file, in_file, Value(temp_path) & Value(R_reports,2) & ".R");
         Delete(old_file);
         exception
            when others => null;  -- target doesn't exist, no issue
      end;
      -- Create the target file
      Create(file => the_file, 
             name => Value(temp_path) & Value(R_reports, 2) & ".R",
             form => "WCEM=8");
      -- Set up the R file, passing in key parameters
      Process_R(for_R => Disassemble(from_string => 
                                               Value(from=>Value(R_reports,4)),
                                     separated_by=> line_feed_char),
                using_params => R_params,
                to_file => the_file);
      -- Then Shut the target file
      Close(the_file);
      -- Then Execute R
      Host_Functions.
         Execute(app_name => To_String(R_path), 
                 args     => "--file=" & Value(temp_path) & 
                                To_Wide_String(Value(R_reports, 2)) & ".R",
                 envs     => "");
      exception
         when others =>
            Close(the_file);
            raise;  -- reraise the exception
   end Generate_Graphs;

   procedure Generate_LaTex(for_report_id : in natural) is
       -- In accordance with instructions and folding in any generated graphs,
       -- output the LaTex that describes the report.
      use GNATCOLL.SQL.Exec;  use String_Conversions;
      use dStrings.IO, Strings_Functions;
      type line_type is (query, end_query, latex);
      procedure Process_Latex(for_LaTex          : text_array;
                              starting_with_line : in out positive;
                              using_params       : SQL_Parameters;
                              at_query_number    : natural := 0;
                              to_file            : file_type) is
         function The_Line_Type(for_line : in text) return line_type is
         begin
            if Pos(pattern=>Value("«QUERY"), source => for_line) > 0 then
               return query;
            elsif Pos(pattern=>Value("«END QUERY"), source=>for_line) > 0 then
               return end_query;
            else
               return latex;
            end if;
         end The_Line_Type;
         procedure Process_Query(
                          q_latex: in out GNATCOLL.SQL.Exec.Forward_Cursor;
                          line_num : in out positive;
                          q_number : in natural) is
            sub_line_num : positive;
         begin
            Error_Log.Debug_Data(at_level=>5, with_details=>"Process_Query: start");
                     -- Advance the line number to after the query
            line_num := line_num + 1;  -- this is where the query
                                                -- will start operating from
                     -- For each row in the result set, load parameters
                     -- and recurse in
            while Has_Row(q_latex) loop
               declare
                  sub_params : SQL_Parameters(1..Natural(q_latex.Field_Count));
               begin
                  -- load parameters
                  for field_num in 1 .. Natural(q_latex.Field_Count) loop
                     if not Is_Null(q_latex, Field_Index(field_num-1)) then
                        sub_params(field_num) := 
                                     +Value(q_latex, Field_Index(field_num-1));
                     else
                        sub_params(field_num) := Null_Parameter;
                     end if;
                  end loop;
                  -- reset the line number for chid
                  sub_line_num := line_num;
                  -- call the child
                  Process_Latex(for_LaTex, sub_line_num, sub_params,
                                         q_number, to_file); 
               end;
               q_latex.Next;
            end loop;
            line_num := sub_line_num;  -- advance to end
         end Process_Query;
         function Escape_The_Character(character_to_escape : in wide_character;
                                       in_text : text) return text is
            result : text;
            escape_character : constant wide_character := '\';
         begin
            for char_pos in 1 .. Length (in_text) loop
               if Wide_Element(of_string => in_text, at_position => char_pos) =
                  character_to_escape then
                  result := result & escape_character;
               end if;
               result := result & 
                   Wide_Element(of_string => in_text, at_position => char_pos);
            end loop;
            return result;
         end Escape_The_Character;
         line_num     : positive renames starting_with_line;
         q_number     : natural;
         the_query    : text;
         the_line     : text;
         query_length : natural;
      begin  -- Process_Latex
         Error_Log.Debug_Data(at_level=>5, with_details=>"Process_Latex: start");
         while line_num <= for_LaTex'Last loop
            Error_Log.Debug_Data(at_level=>6, with_details=>"Process_Latex: " &
                                                   Value(for_LaTex(line_num)));
            case The_Line_Type(Trim(for_LaTex(line_num))) is
               when query => 
                  -- Get the query number (should be 1 more than current)
                  the_query := Trim(for_LaTex(line_num));
                  Delete(the_query, 1, 7); -- Delete "«QUERY "
                  q_number := Get_Integer_From_String(the_query);
                  if q_number /= at_query_number + 1
                  then  -- Query numbering wrong for some reason
                     raise LaTex_Error;
                  end if;
                  Delete_Number_From_String(the_query);
                  Delete(the_query, 1, 1);  -- delete trailing ":" after number
                  -- Build the full query
                  query_length := Pos(Value("»"), the_query, 1);
                  -- delete from end (all after chevron is treated as comments)
                  Delete(the_query, query_length, 
                         Length(the_query) - query_length + 1);
                  if Pos(Value(from=>"?"), the_query) > 0
                  then  -- parameters have been specified, so process with them
                     declare
                        num_params : constant natural := 
                                    Component_Count(of_the_string => the_query,
                                                    separated_by => '?');
                     -- param_order: array (1..num_params) of natural;
                        the_params : SQL_Parameters(1..num_params) :=
                                     using_params(1..num_params);
                        q_latex    : GNATCOLL.SQL.Exec.Forward_Cursor;
                     begin  -- Run the query
                        Error_Log.Debug_Data(at_level=>6, 
                             with_details=>"Process_Latex: executing query with parameters '"&
                                                 Value(of_string=> the_query) & "'.");
                        Fetch(Result => q_latex, Connection => tDB,
                           Query  => Value(the_query), 
                           Params => the_params);
                        Process_Query(q_latex, line_num, q_number);
                     end;
                  else -- parameterless query
                     declare
                        q_latex    : GNATCOLL.SQL.Exec.Forward_Cursor;
                     begin
                        Error_Log.Debug_Data(at_level=>6, 
                             with_details=>"Process_Latex: executing query without parameters '"&
                                                 Value(of_string=> the_query) & "'.");
                        Fetch(Result => q_latex, Connection => tDB,
                           Query  => Value(the_query));
                        Process_Query(q_latex, line_num, q_number);
                     end;
                  end if;
               when end_query => 
                  -- check if it is our query number (trouble if not?)
                  the_query := Trim(for_LaTex(line_num));
                  Delete(the_query, 1, 11); -- Delete "«END QUERY "
                  if Get_Integer_From_String(the_query) /= at_query_number
                  then  -- not, so trouble
                     raise LaTex_Error;
                  else
                     -- pop out of this recursion
                     exit;
                  end if;
               when latex => 
                  the_line := for_LaTex(line_num);
                  -- substitute in any fields or parameters into «FIELD:<num>»
                  while Pos(Value("«FIELD:"), the_line) > 0 loop
                     declare
                        use GNATCOLL.SQL_Impl;
                        field_pos : positive := Pos(Value("«FIELD:"),the_line);
                        end_pos   : positive := Pos(Value("»"),the_line);
                        field_str : text := the_line;
                        param_num : positive;
                        the_param : text;
                     begin
                        Delete(field_str, 1, field_pos + 7);
                        -- extract the field number
                        param_num := Get_Integer_From_String(field_str);
                        -- extract the parameter
                        if using_params(param_num) = Null_Parameter then
                           Clear(the_param);
                        else
                           the_param:= Escape_The_Character('&',
                              Value(from=>using_params(param_num).Image(tDB.all)));
                        end if;
                        -- pop in the parameter
                        if end_pos + 1 >= Length(the_line) then
                           the_line := Sub_String(the_line, 1, field_pos - 1) &
                                       the_param;
                        else
                           the_line := Sub_String(the_line, 1, field_pos - 1) &
                                       the_param &
                                       Sub_String(the_line, end_pos + 2, 
                                               Length(the_line) - end_pos - 1);
                        end if;
                     end;
                  end loop;
                  -- write out to file
                  Put_Line(to_file, the_line);
            end case;
            line_num := line_num + 1;
         end loop;
      end Process_Latex;
      report_number : natural := 0;
      the_file      : file_type;
      start_line    : positive := 1;
   begin -- Generate_LaTex
      Error_Log.Debug_Data(at_level=>5, with_details=>"Generate_LaTex: Start");
      -- Go to the desired row in the Reports table
      report_number := Go_to_Row(with_report_id => for_report_id);
      -- If the target file exists, delete it
      declare
         old_file : file_type;
      begin
         Open(old_file, in_file, Value(temp_path)&Value(R_reports, 2)&".tex");
         Delete(old_file);
         exception
            when others => null;  -- target doesn't exist, no issue
      end;
      -- Create the target file
      Create(file => the_file, 
             name => Value(temp_path) & Value(R_reports, 2) & ".tex",
             form => "WCEM=8");
      -- Start the generation, passing in the LaTex as an array of lines taken
      -- from the LaTex (number 5) field
      Process_Latex(for_LaTex => Disassemble(from_string => 
                                               Value(from=>Value(R_reports,5)),
                                             separated_by=> line_feed_char),
                    starting_with_line => start_line,
                    using_params => No_Parameters,
                    to_file => the_file);
      -- Then Shut the target file
      Close(the_file);
      exception
         when others =>
            Close(the_file);
            raise;  -- reraise the exception
   end Generate_LaTex;
       
   procedure Display_Report(for_report_id : in natural) is
       -- Execute pdflatex on the generated LaTex, then display the generated
       -- PDF using a PDF viewer.  It is from that PDF viewer that the report
       -- can be printed by the user.
      use Host_Functions, String_Conversions;
   begin
      Error_Log.Debug_Data(at_level=>5, with_details=>"Display_Report: Start");
      -- Generate .pdf with pdflatex (or whatever app name is in tex_path)
      Host_Functions.
         Execute(app_name => To_String(tex_path), 
                 args     => "-output-directory=" & Value(temp_path) & " " &
                             Value(temp_path) & 
                                To_Wide_String(Value(R_reports, 2)) & ".tex ",
                 envs     => "");
      -- Give it some time
      delay 2.0; -- wait a couple of seconds
      -- Display the output ready for printing
      Host_Functions.
         Execute(app_name => To_String(pdf_path), 
                 args     => Value(temp_path) & 
                                To_Wide_String(Value(R_reports, 2)) & ".pdf",
                 envs     => "");
   end Display_Report;
   
begin
   Cell_Writer_Version.Register(revision => "$Revision: v1.0.0$",
                                 for_module => "Report_Processor");
end Report_Processor;