-----------------------------------------------------------------------
--                                                                   --
--                  C O D E   I N T E R P R E T E R                  --
--                                                                   --
--                              B o d y                              --
--                                                                   --
--                           $Revision: 1.0 $                        --
--                                                                   --
--  Copyright (C) 2023  Hyper Quantum Pty Ltd.                       --
--  Written by Ross Summerfield.                                     --
--                                                                   --
--  This package is a code interpreter for the combining  character  --
--  instruction  set.   The combining  character  instruction  sets  --
--  operate on a single cell. If that cell contains several Unicode  --
--  characters,  then  it  operates on all of  them.  If  the  cell  --
--  contains  one character,  which for instance would be the  case  --
--  for the Latin character set, then it operates on just that one.  --
--                                                                   --
--  The algorithm for the Execute operation is as follows:           --
--  The main procedure (Execute) executes the following blocks, with --
--  components executed by sub-procedures as appropriate:            --
-- 1. Initialise registers                                           --
--     1 Set H to passed in parameter (see above)                    --
--     2 Set S to the current cell's contents as represented by the  --
--       cell's hint text                                            --
--     3 Set registers A to E to 0                                   --
--     4 Set F to ' ' (16#0020#)                                     --
--     5 Set G to ""                                                 --
--     6 Define an array of the current character block's space      --
--       characters, defining each character's width                 --
-- 2. Load and parse (clean out comments, simplify spaces)           --
--    instruction set blob into an array of text, breaking at ;      --
-- 3. Execute the instructions by recursively passing in the block   --
--    of code to execute (at the top level, this is the code between --
--    the PROCEDURE command and its matching END, noting that the    --
--    procedure name is for readability only and is ignored, except  --
--    to match against the END statement); for each instruction in   --
--    the instruction array passed in:                               --
--     • Extract the first literal from the command line:            --
--     • if a register followed by an assignment, parse each element --
--        of the operation to the right of the assignment (:=)       --
--        operator                                                   --
--     • If an operator command (INSERT, REPLACE, DELETE), execute   --
--       the specific command on the specified register              --
--     • If EXIT, then providing in a FOR loop, exit the recursion   --
--       level out to beyond that FOR loop level; if none is         --
--       encountered, then raise the exception.                      --
--     • If a block command (IF, FOR), determine the end of the      --
--       block, calculate the block control (i.e. of the IF or the   --
--       FOR), then recursion down, passing down an array containing --
--       the commands in the block and the block controls.           --
--     • For sub-commands (LIST, FIND, CHAR, ABS), perform the       --
--        operation and return its value, for mathematical           --
--       operators, perform the operation on the left (if not a      --
--       unary operator) and right components and return its value,  --
--       recursing where  brackets require.                          --
-- 4. Load the S register contents back into the currently selected  --
--    cell's hint and initiate a redraw for that cell.               --
--                                                                   --
--  Version History:                                                 --
--  $Log$
--                                                                   --
--  Cell_Writer  is free software; you can redistribute  it  and/or  --
--  modify  it under terms of the GNU  General  Public  Licence  as  --
--  published by the Free Software Foundation; either version 2, or  --
--  (at your option) any later version.  Cell_Writer is distributed  --
--  in  hope  that  it will be useful, but  WITHOUT  ANY  WARRANTY;  --
--  without even the implied warranty of MERCHANTABILITY or FITNESS  --
--  FOR  A PARTICULAR PURPOSE.  See the GNU General Public  Licence  --
--  for  more details.  You should have received a copy of the  GNU  --
--  General  Public Licence distributed with Cell_Writer.  If  not,  --
--  write  to  the Free Software Foundation,  51  Franklin  Street,  --
--  Fifth Floor, Boston, MA 02110-1301, USA.                         --
--                                                                   --
-----------------------------------------------------------------------
-- with GNATCOLL.SQL.Exec;
-- with Gtkada.Builder;    use Gtkada.Builder;
-- with Gtk.Drawing_Area;  use Gtk.Drawing_Area;
-- with dStrings;          use dStrings;
-- with Generic_Binary_Trees_With_Data;
with Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
with Ada.Characters.Wide_Latin_1, Ada.Wide_Characters.Handling;
with GNATCOLL.SQL.Exec.Tasking;  --, GNATCOLL.SQL_BLOB;
with Gtkada.Builder;    use Gtkada.Builder;
with Gtk.Drawing_Area;  use Gtk.Drawing_Area;
with dStrings;          use dStrings;
with Strings_Functions;
with String_Conversions;
with Error_Log;
with Database;          use Database;
with Error_Log_Display; use Error_Log_Display;
with Macro_Interpreter; use Macro_Interpreter;
with Cursor_Management;
with Cell_Writer_Version;
package body Code_Interpreter is
   use GNATCOLL.SQL; --, GNATCOLL.SQL_BLOB;

   the_builder : Gtkada.Builder.Gtkada_Builder;
   
   macros_select        : constant GNATCOLL.SQL.Exec.Prepared_Statement :=
      GNATCOLL.SQL.Exec.Prepare 
           (SQL_Select (Fields  => Macros.ID & Macros.Macro,
                        From    => Macros,
                        Order_By=> Macros.ID),
            On_Server => True,
            Use_Cache => True);

   procedure Initialise_Interpreter(with_builder : in out Gtkada_Builder;
                        with_DB_Descr : GNATCOLL.SQL.Exec.Database_Description;
                             reraise_exception : boolean := false) is
      -- Load the macros into memory and otherwise set up the interpreter ready
      -- for operation.  That includes stripping out comments from the macros
      -- and simplifying spaces.  That also includes getting a handle to the
      -- pop-up, which will be utilised by Error_Log for displaying any error
      -- that raises the BAD_MACRO_CODE exception.  If reraise_exception is set
      -- to true, then the exception will be reraised after the pop-up is
      -- displayed.
      use GNATCOLL.SQL.Exec;  
      use Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
      rDB         : GNATCOLL.SQL.Exec.Database_Connection;
      R_macros    : Forward_Cursor;
      this_macro  : text;
   begin
      -- First, save a reference to the builder
      the_builder := with_Builder;
      -- Set up the Error logging for a pop-up in the event of the exception
      -- being raised
      Error_Log_Display.Initialise_Error_Log_Display(Builder=> with_builder);
      -- Set the preference for re-raising the macro exception (or not)
      Set_Re_raise_Exception_Preference(to => reraise_exception);
      -- Load in the macros
      Clear_All_Macros;  -- just to be sure
      --   next, stash away the main database pointer
      rDB := GNATCOLL.SQL.Exec.Tasking.Get_Task_Connection
                                                  (Description=>with_DB_descr);
      --   and run the query to load the data
      R_macros.Fetch (Connection => rDB, Stmt => macros_select);
      if Success(rDB) and then Has_Row(R_macros) then
         while Has_Row(R_macros) loop  -- while not end_of_table
            Error_Log.Debug_Data(at_level => 9, with_details => "Initialise_Interpreter: at macro number " & Put_Into_String(Integer_Value(R_macros,0)) & ".");
            this_macro := 
                Value_From_Wide(Decode(UTF_8_String(Value(R_macros,1)),UTF_8));
            Load(the_macro=>this_macro, at_number=>Integer_Value(R_macros,0));
            Next(R_macros);
         end loop;
      end if;
   end Initialise_Interpreter;

   procedure Execute (the_cell : in out gtk_drawing_area;
                      the_macro_Number : in natural;
                      passed_in_parameter : in text) is
      -- This main macro execution procedure the following parameters:
      --     1 The pointer to the currently selected cell;
      --     2 A pointer to the blob containing the instructions, as pointed to
      --       by the combining character button;
      --     3 The 'passed-in parameter', taken from the combining character
      --       button: if specified in the brackets after the procedure and its
      --       optional name, then extracted from the procedure call, if the
      --       brackets are provided but have no contents, extracted from the
      --       button's tool tip help text, otherwise set to 16#0000# (NULL).
      use Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
   begin  -- Execute (the main execute procedure)
      Error_Log.Debug_Data(at_level => 6, 
                           with_details => "Execute: Start" & ".  Macro number = " & Put_Into_String(the_macro_Number) & " and passed in parameter is '" & passed_in_parameter & "' with a character position of (" & Put_Into_String(Integer(wide_character'Pos(Wide_Element(passed_in_parameter,1)))) & ").");
      -- First, load or otherwise initialise the registers;
      Set(the_register => H, to => passed_in_parameter);
      Set(the_register => S, 
          to => Value_From_Wide(Decode(Get_Tooltip_Text(the_cell))));
      -- Now execute the macro
      Execute (the_macro_Number);
      -- Finally, load the S register back
      Set_Tooltip_Text(the_cell, 
                       Encode(to_string(The_Value(of_the_register=>S)))); 
      Error_Log.Debug_Data(at_level => 7, 
                           with_details => "Execute: Finished" & ".  Loaded S register '" & Value_From_Wide(Decode(Get_Tooltip_Text(the_cell))) & "' back into tool tip.");
   end Execute;
   
begin
   Cell_Writer_Version.Register(revision => "$Revision: v1.0.2$",
                                for_module => "Code_Interpreter");
end Code_Interpreter;
