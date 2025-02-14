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
--       cell's hint text.                                           --
-- 2. Load and parse the instruction set blob using the              --
--    Macro_Interpreter library package.                             --
-- 3. Call the Macro_Interpreter's Execute to execute instructions.  --
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
with Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
with Ada.Characters.Wide_Latin_1, Ada.Wide_Characters.Handling;
with GNATCOLL.SQL.Exec.Tasking, GNATCOLL.SQL_BLOB;
with Gtkada.Builder;    use Gtkada.Builder;
with Gtk.Drawing_Area;  use Gtk.Drawing_Area;
with dStrings;          use dStrings;
with Error_Log;
with Database;          use Database;
with Error_Log_Display; use Error_Log_Display;
with Macro_Interpreter; use Macro_Interpreter;
with Cursor_Management;
with Cell_Writer_Version;
package body Code_Interpreter is
   use GNATCOLL.SQL;

   the_builder : Gtkada.Builder.Gtkada_Builder;
   
   macros_select        : constant GNATCOLL.SQL.Exec.Prepared_Statement :=
      GNATCOLL.SQL.Exec.Prepare 
           (SQL_Select (Fields  => Macros.ID & Macros.Macro,
                        From    => Macros,
                        Order_By=> Macros.ID),
            On_Server => True,
            Use_Cache => True);
   error_dets_select    : constant GNATCOLL.SQL.Exec.Prepared_Statement :=
      GNATCOLL.SQL.Exec.Prepare 
           (SQL_Select (Fields  => Configurations.ID & Configurations.Details,
                        From    => Configurations,
                        Where   => (Configurations.Name = Text_Param(1)), --AND
                                   -- (Configurations.DetFormat = "N"),
                        Order_By=> Configurations.ID),
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
      use GNATCOLL.SQL.Exec, GNATCOLL.SQL_BLOB;  
      use Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
      rDB         : GNATCOLL.SQL.Exec.Database_Connection;
      R_err_dets  : Forward_Cursor;
      error_param : SQL_Parameters (1 .. 1);
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
      --   set up the error message terminator (for in case of a macro error)
      error_param := (1 => +(Value(To_Text("error_terminator"))));
      R_err_dets.Fetch(Connection => rDB, Stmt => error_dets_select,
                       Params => error_param);
      if Success(rDB) and then Has_Row(R_err_dets) then
         Initialise_Error_Terminator(to => 
                                Decode(UTF_8_String(Value(R_err_dets,1)),UTF_8));
      end if;
      --   and the logging level number for macro error causes
      error_param := (1 => +(Value(To_Text("macro_err_no"))));
      R_err_dets.Fetch(Connection => rDB, Stmt => error_dets_select,
                       Params => error_param);
      if Success(rDB) and then Has_Row(R_err_dets) then
         Set_Log_Level(to => Integer_Value(R_err_dets,1));
      end if;
      --   and then run the query to load the data
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
      Error_Log.Debug_Data(at_level => 9, with_details => "Execute: Executing Macro number = " & Put_Into_String(the_macro_Number) & " with Register S = '" & As_Text(The_Value(of_the_register=>S)) & "' and REgister H = '" & As_Text(The_Value(of_the_register=>H)) & "'.");
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
