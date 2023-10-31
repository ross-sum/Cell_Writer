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
with Cursor_Management;
with Cell_Writer_Version;
package body Code_Interpreter is
   use GNATCOLL.SQL; --, GNATCOLL.SQL_BLOB;

   -- BAD_MACRO_CODE : exception;
      -- A handler at the top level main macro execution procedure logs and
      -- then displays the error in a pop-up whin this exception is raised.
   tab     : constant wide_character := Ada.Characters.Wide_Latin_1.HT;
   LF      : constant wide_character := Ada.Characters.Wide_Latin_1.LF;
   CR      : constant wide_character := Ada.Characters.Wide_Latin_1.CR;
   SP      : constant wide_character := ' ';
   
   the_builder : Gtkada.Builder.Gtkada_Builder;
   
   macros_select        : constant GNATCOLL.SQL.Exec.Prepared_Statement :=
      GNATCOLL.SQL.Exec.Prepare 
           (SQL_Select (Fields  => Macros.ID & Macros.Macro,
                        From    => Macros,
                        Order_By=> Macros.ID),
            On_Server => True,
            Use_Cache => True);

   function LessThan(a, b : in natural) return boolean is
   begin
      return a < b;
   end LessThan;

   procedure Initialise(the_registers : out register_array) is
      -- set the discrimanent for each position to match the position
   begin
      for reg in all_register_names loop
         the_registers(reg) := new register_type(reg);
      end loop;
   end Initialise;
   
   function AtM(macros : macro_list; m : in natural) return code_block is
      -- AtM(acro): Deliver macro number m from the macro_list macros.
      use Macro_Lists;
      our_macros : macro_list;
      R: code_block;
   begin
      Assign(the_list => macros, to => our_macros);
      First(in_the_list => our_macros);
      Find_The_Macro:
         while not Is_End(of_the_list => our_macros) loop
         if Deliver(from_the_list => our_macros) = m 
         then  -- found it
            R := Deliver_Data(from_the_list => our_macros);
            exit Find_The_Macro;
         else  -- keep looking
            Next(in_the_list => our_macros);
         end if;
      end loop Find_The_Macro;
      return R;
   end AtM;

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
      -- use GNATCOLL.SQL;
      use GNATCOLL.SQL.Exec;  
      use Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
      -- use String_Conversions;
      use Macro_Lists;
      rDB         : GNATCOLL.SQL.Exec.Database_Connection;
      R_macros    : Forward_Cursor;
      this_macro  : text;
      macro_code  : code_block;
   begin
      -- First, save a reference to the builder
      the_builder := with_Builder;
      -- Record exception handling preference
      reraise_bad_macro_code_exception := reraise_exception;
      -- Set up the Error logging for a pop-up in the event of the exception
      -- being raised
      Error_Log_Display.Initialise_Error_Log_Display(Builder=> with_builder);
      -- Load in the macros
      Clear(the_list => the_macros);  -- just to be sure
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
            -- this_macro := Value(Value(R_macros,1));
            -- Do a preliminary parse on the macros
            Strip_Comments_And_Simplify_Spaces(this_macro);
            Load_Macro(into => macro_code, from => this_macro);
            -- Save away the macro
            Insert(into      => the_macros,
                   the_index => Integer_Value(R_macros,0),
                   the_data  => macro_code);
            Next(R_macros);
         end loop;
      end if;
      exception
         when BAD_MACRO_CODE =>  -- display the error and stop loading macros.
            Error_Log.Put(the_error => 46,
                          error_intro =>  "Code_Interpreter Initialise_Interpreter error", 
                          error_message=> "Bad code in Macro found during initialisation");
   end Initialise_Interpreter;
      
   procedure Execute (the_macro_code : in code_block;
                      on_registers : in out register_array;
                      loop_exit_triggered : in out boolean) is
      -- This main macro execution procedure the following parameters:
      --     1 The pointer to the currently selected cell;
      --     2 A pointer to the blob containing the instructions, as pointed to
      --       by the combining character button;
      --     3 The 'passed-in parameter', taken from the combining character
      --       button: if specified in the brackets after the procedure and its
      --       optional name, then extracted from the procedure call, if the
      --       brackets are provided but have no contents, extracted from the
      --       button's tool tip help text, otherwise set to 16#0000# (NULL).
      -- This Execute procedure is built to be recursive, and is called by a
      -- shell Execute procedure that simply sets up the data and, after this
      -- Execute operation has run its course, saves the result back to the
      -- currently active cell.
      registers    : register_array renames on_registers;
      the_macro    : code_block := the_macro_code;
      exiting_loop : boolean renames loop_exit_triggered;
      procedure Execute(the_equation : in out equation_access; at_level : in natural) is
        -- Calculate the result of the equation for the current register values
         procedure Clear_Results(for_equation : in out equation_access) is
           -- 'Clear' (reset) the results fields for each part of the equation
           -- back to their initial values, which are specified in the x_const
           -- field.  This is not done for funct, as it is always assumed to be
           -- zero at start of calculations.
            the_equation : equation_access := for_equation;
         begin
            while the_equation /= null loop
               case the_equation.eq is
                  when mathematical=>the_equation.m_result:=the_equation.m_const;
                  when logical   => the_equation.l_result:=the_equation.l_const;
                  when textual   => the_equation.t_result:=the_equation.t_const;
                  when bracketed => null; -- gets done on recursion
                  when funct     => 
                     the_equation.f_result := 0.0; -- 0 at start!
                     Clear(the_equation.ft_result);
                  when comparison=> the_equation.c_result:=the_equation.c_const;
                  when none      => null;  -- equation's no-op operation
               end case;
               the_equation := the_equation.equation;
            end loop;
         end Clear_Results;
         function Get_Param(from_equation: in equation_access) return long_float
         is
         -- Get the parameter from the specified (sub)equation
            the_equation : equation_access := from_equation;
            the_reg  : all_register_names;
            param    : long_float;
            char_pos : natural := 0;
         begin
            if the_equation = null
            then
               Error_Log.Debug_Data(at_level => 8, with_details => "Get_Param(from_equation): processing equation that is null.");
               return 0.0;
            else
               Error_Log.Debug_Data(at_level => 8, with_details => "Get_Param(from_equation): processing equation " & the_equation.eq'Wide_Image & ".");
               Execute(the_equation, at_level + 1);
               Error_Log.Debug_Data(at_level => 8, with_details => "Get_Param(from_equation): Executed equation " & the_equation.eq'Wide_Image & " with register '" & register_ids(the_equation.register) & "' with operator '" & all_maths_operators(the_equation.operator) & "' with a previous eqution in existence = " & Boolean'Wide_Image(the_equation.last_equ /= null) & ".");
               -- In case a register is specified, work out if a character
               -- position is specified
               the_reg := the_equation.register;
               if the_reg /= const and then the_equation.reg_parm /= null
               then
                  char_pos := integer(the_equation.reg_parm.m_result);
               end if;
               case the_equation.eq is
                  when mathematical =>
                     if char_pos = 0
                     then
                        char_pos := 1;
                     end if;
                     Error_Log.Debug_Data(at_level => 8, with_details => "Get_Param(from_equation): Type is mathematical with m_result = " & Put_Into_String(the_equation.m_result,3) & " and with register '" & register_ids(the_equation.register) & "' and char pos " & Put_Into_String(char_pos) & ".");
                     if the_reg /= const
                     then
                        case the_reg is
                           when G | H | S =>  -- this has a length
                              param := Long_Float(wide_character'Pos(
                                         Wide_Element(
                                          registers(the_reg).reg_t,char_pos)));
                              Error_Log.Debug_Data(at_level => 9, with_details => "Get_Param: set param (= Wide_Element(registers(" & register_ids(the_reg) & ").reg_t)," & Put_Into_String(char_pos) & ") = '" & Put_Into_String(param) & "'.");
                           when A .. E =>  -- assume not a character
                              if the_equation.operator in numeric_operator and 
                                 the_equation.reg_parm = null
                              then
                                 param := the_equation.m_result;
                              else
                                 param := registers(the_reg).reg_f;
                              end if;
                           when F =>  -- this is a distinct possibility
                              param := Long_Float(wide_character'Pos(
                                                    registers(the_reg).reg_c));
                           when Y => -- an error condition or want boolean
                              if registers(the_reg).reg_b
                              then
                                 param := 1.0;
                              else
                                 param := 0.0;
                              end if;
                           when const =>  null;  -- not actually included   
                        end case;
                     else  -- not a register
                        param := the_equation.m_result;
                     end if;
                  when funct =>
                     param := the_equation.f_result;
                  when others =>
                     Error_Log.Debug_Data(at_level => 8, with_details => "Get_Param(from_equation): Type is others (" & the_equation.eq'Wide_Image & ") with m_result = " & Put_Into_String(the_equation.m_result,3) & " and with register '" & register_ids(the_equation.register) & "' and char pos " & Put_Into_String(char_pos) & ".");
                     case the_equation.register is
                        when A .. E =>  -- get that register
                           param:=registers(the_equation.register).reg_f;
                        when F =>  -- get the character register
                           param := long_float(wide_character'Pos(
                                      registers(the_equation.register).reg_c));
                        when G | H | S =>
                           if char_pos > 0
                           then
                              param := Long_Float(wide_character'Pos(
                                         Wide_Element(
                                          registers(the_reg).reg_t,char_pos)));
                           else
                              param := 0.0;
                           end if;
                        when others =>
                           param := 0.0;
                     end case;
               end case;
               Error_Log.Debug_Data(at_level => 8, with_details => "Get_Param(from_equation): param = " & Put_Into_String(param,2) & ".");
               return param;
            end if;
         end Get_Param;
         function Char(start : integer; size: long_float) return wide_character
         is
            use Ada.Wide_Characters.Handling;
            result   : wide_character := ' ';
            start_ch : constant wide_character := wide_character'Val(start);
         begin
            if Cursor_Management.Combining_Check_On(the_character=>start_ch)
            then  -- a combining character
               result := wide_character'Val(16#0000#);  -- null character
            else  -- search the list
               for item in reverse char_sizes'range loop
                  if char_sizes(item).the_char <= start_ch
                  then  -- got it, so find the next matching size
                     for chr in item .. char_sizes'Last loop
                        if char_sizes(chr).size <= size
                        then  -- found it, so set the result and finish up
                           result := char_sizes(chr).the_char;
                           exit;
                        end if;
                     end loop;
                     exit;  -- found the start char, so stop here
                  end if;
               end loop;
            end if;
            Error_Log.Debug_Data(at_level => 9, with_details => "Char: set result for start character '" & start_ch & "' (" & Put_into_String(start) & ") and size = " & Put_Into_String(size, 3) &" to '" & result & "' (" & Put_Into_String(integer(wide_character'Pos(result))) & ").");
            return result;
         end Char;
         function Abs_Value(of_number : in long_float) return long_float is
         begin
            Error_Log.Debug_Data(at_level => 9, with_details => "Abs: set result Abs(" & Put_Into_String(of_number,3) & ") = " & Put_Into_String(Abs(of_number),3) & ".");
            return Abs(of_number);
         end Abs_Value;
         function Find(value : wide_character; 
                       in_the_register : string_register := S) return natural is
            reg    : string_register renames in_the_register;
            result : natural := 0;
         begin
            for char_pos in 1 .. Length(registers(reg).reg_t) loop
               if Wide_Element(registers(reg).reg_t, char_pos) = value
               then  -- found it
                  result := char_pos;
                  Error_Log.Debug_Data(at_level => 9, with_details => "Find: set result Find(" & value & ") = " & Put_Into_String(result) & ".");
                  exit;  -- finish looking
               end if;
            end loop;
            Error_Log.Debug_Data(at_level => 9, with_details => "Find: set result Find(" & value & ") = " & Put_Into_String(result) & " (found nothing if 0).");
            return result;
         end Find;
         function Width(value : wide_character) return long_float is
            result : long_float := 0.0;
         begin
            if not Cursor_Management.Combining_Check_On(the_character => value)
            then  -- not a combining character (otherwise width = 0
               result := 1.0;  -- size if not otherwise specified
               for item in char_sizes'range loop
                  if char_sizes(item).the_char = value
                  then  -- got it, so return matching size
                     result := char_sizes(item).size;
                     exit;  -- found the start char, so stop here
                  end if;
               end loop;
            end if;
            return result;
         end Width;
         function In_Range(the_ch, start_ch, end_ch: wide_character) 
         return boolean is
         begin
            return the_ch >= start_ch and the_ch <= end_ch;
         end In_Range;
         function Str_Length(of_the_reg : in all_register_names) 
         return natural is
            result : natural := 0;
         begin
            case of_the_reg is
               when G | H | S =>  -- this has a length
                  result := Length(registers(of_the_reg).reg_t); 
                  Error_Log.Debug_Data(at_level => 9, with_details => "Str_Length: set result (= Length(registers(" & register_ids(of_the_reg) & ").reg_t)) = " & Put_Into_String(result) & ".");
               when A .. E =>  -- this doesn't have a length
                  result := 0;
               when F =>  -- this has a length of 1
                  result := 1;
               when others => null;
                  Error_Log.Debug_Data(at_level => 9, with_details => "Str_Length: set result (= Length(registers(" & register_ids(of_the_reg) & ").reg_t)) = " & Put_Into_String(result) & ".");
            end case;
            return result;
         end Str_Length;
         function Size_of(the_reg: in all_register_names) return natural is
            result : natural := 0;
         begin
            case the_reg is
               when A .. E    => result := Long_Float'Size;
               when G | H | S => result := registers(the_reg).reg_t'Size;
               when F         => result := wide_character'Size;
               when Y         => result := boolean'Size;
               when const     => null;  -- nothing, so no size
            end case;
            return result;
         end Size_of;
         function The_First(for_the_reg: in all_register_names) 
         return long_float is
            result : long_float := 0.0;
         begin
            case for_the_reg is
               when G | H | S =>  -- this has a first character
                  result := long_float(wide_character'Pos(
                               Wide_Element(registers(for_the_reg).reg_t, 1)));
               when A .. E =>  -- this doesn't have a first
                  result := long_float(float'First);
               when F =>  -- this has a range of 0 .. WC'Last
                  result := 0.0;
               when others => null;
            end case;
            return result;
         end The_First;
         function The_Last(for_the_reg: in all_register_names) 
         return long_float is
            result : long_float := 0.0;
         begin
            case for_the_reg is
               when G | H | S =>  -- this has a first character
                  result := long_float(wide_character'Pos(
                               Wide_Element(registers(for_the_reg).reg_t, 
                                       Length(registers(for_the_reg).reg_t))));
               when A .. E =>  -- this doesn't have a first
                  result := long_float(float'Last);
               when F =>  -- this has a range of 0 .. WC'Last
                  result:= long_float(wide_character'Pos(wide_character'Last));
               when others => null;
            end case;
            return result;
         end The_Last;
         function The_IN_Value(for_register : in all_register_names; 
                               with_register_parameter : in natural;
                               at_range_condition : equation_access) 
         return boolean is
            equation : equation_access renames at_range_condition;
            param1,
            param2   : long_float;
            char_pos : natural := with_register_parameter;
            result   : boolean := false;
            lhs      : wide_character;
         begin
            Error_Log.Debug_Data(at_level => 9, with_details => "The_IN_Value: for_register '" & register_ids(for_register) & "' with_register_parameter " & Put_Into_String(char_pos) & " and range condition '" & at_range_condition.eq'Wide_Image & "'.");
            -- First, get the L.H.S. (the register)
            if char_pos = 0 then  -- there is no characer position specified
               char_pos := 1;  -- worst case scenario
            end if;
            case for_register is
               when G | H | S =>  -- this has a length
                  Error_Log.Debug_Data(at_level => 9, with_details => "The_IN_Value: registers (" & register_ids(for_register) & ").reg_t = '" & registers(for_register).reg_t & "'.");
                  lhs := Wide_Element(registers(for_register).reg_t,char_pos); 
                  Error_Log.Debug_Data(at_level => 9, with_details => "The_IN_Value: set lhs (= Wide_Element(registers(" & register_ids(for_register) & ").reg_t)," & Put_Into_String(char_pos) & ") = '" & lhs & "'.");
               when A .. E =>  -- assume a character in integer representation
                  lhs := wide_character'Val(
                                       integer(registers(for_register).reg_f));
               when F =>  -- this is a distinct possibility
                  lhs := registers(for_register).reg_c;
               when Y => -- an error condition in this program
                  lhs := null_ch;-- should raise exception
               when const =>  -- error condition in macro   
                  Error_Log.Debug_Data(at_level => 9, 
                                   with_details=>"Execute: raising exception "&
                                                 "on instruction = 'EQUATION" &
                                                 "' for no register defined.");
                  raise BAD_MACRO_CODE;
            end case;
            -- Now get the two parameters that define the R.H.S.
            param1 := Get_Param(from_equation => equation.f_param1);
            param2 := Get_Param(from_equation => equation.f_param2);
            -- Now calculate the answer
            result:= In_Range(the_ch=>lhs,
                                 start_ch=>wide_character'Val(integer(param1)),
                                 end_ch=>wide_character'Val(integer(param2)));
            Error_Log.Debug_Data(at_level => 9, with_details => "The_IN_Value: set result comparing to registers(" & register_ids(for_register) & ").reg_t) = " & result'Wide_Image & ".");
            return result;
            exception
               when Ada.Strings.Index_Error =>  -- access attempt beyond string
                  Error_Log.Debug_Data(at_level => 9, 
                                with_details => "Execute: raising exception " &
                                                "on executing an equation (" &
                                                "The_IN_Value)for attempt to "& 
                                                "access beyond the length of "& 
                                                "a string register.");
                  raise BAD_MACRO_CODE;
         end The_IN_Value;
         function Compare(the_value, against : in long_float; 
                          using_operator:comparison_operator) return boolean is
            result : boolean := false;
         begin
            case using_operator is
               when greater_equal   => result := the_value >= against;
               when greater         => result := the_value >  against;
               when less_equal      => result := the_value <= against;
               when less            => result := the_value <  against;
               when equals          => result := the_value =  against;
               when range_condition => result := false;
            end case;
            Error_Log.Debug_Data(at_level => 8, with_details => "Compare(the_value " & Put_Into_String(the_value,3) & ", against " & Put_Into_String(against,3) & "): using operator '" & all_maths_operators(using_operator) & "' = " & result'Wide_Image & ".");
            return result;
         end Compare;
         function Combine(the_value, with_value : in long_float;
                          using_operator:numeric_operator) return long_float is
            result : long_float := 0.0;
         begin
            case using_operator is
               when multiply => result := the_value * with_value;
               when divide   => 
                  if with_value = 0.0
                  then  -- divide by zero - not possible to calculate
                     result := long_float'Last;  -- crude indication of div 0
                  else  -- outcome is calculable
                     result := the_value / with_value;
                  end if;
               when plus     => result := the_value + with_value;
               when minus    => result := the_value - with_value;
               when others   => result := the_value + with_value;
            end case;
            Error_Log.Debug_Data(at_level => 8, with_details => "Combine(the_value " & Put_Into_String(the_value,3) & ", with_value " & Put_Into_String(with_value,3) & "): using operator '" & all_maths_operators(using_operator) & "' = " & Put_Into_String(result,3) & ".");
            return result;
         end Combine;
         function Combine(the_value: in boolean; with_value: in boolean:=false;
                          using_operator : logical_operator) return boolean is
            result : boolean := false;
         begin
            case using_operator is
               when logical_and => result := the_value and with_value;
               when logical_or  => result := the_value or  with_value;
               when logical_not => result := not the_value;
               when others      => result := the_value or  with_value;
            end case;
            Error_Log.Debug_Data(at_level => 8, with_details => "Combine(the_value " & the_value'Wide_Image & ", with_value " & with_value'Wide_Image & "): using operator '" & all_maths_operators(using_operator) & "' = " & result'Wide_Image & ".");
            return result;
         end Combine;
         function Combine(the_value, with_value: in text;
                          using_operator : string_operator) return text is
            result : text;
         begin
            case using_operator is
               when concat => result := the_value & with_value;
               when others => result := the_value & with_value;
            end case;
            Error_Log.Debug_Data(at_level => 8, with_details => "Combine(the_value '" & the_value & "', with_value '" & with_value & "'): using operator '" & all_maths_operators(using_operator) & "' = '" & result & "'.");
            return result;
         end Combine;
         equation          : equation_access := the_equation;
         reverse_start     : equation_access := null;
         register          : all_register_names;
         register_position : natural := 0;
         param1,
         param2            : long_float;
         logres            : boolean;
         txtres,
         txtres2           : text;
      begin  -- Execute (the_equation)
         -- First, Clear the results storage points for the equation
         Clear_Results(for_equation => equation);
         -- Get the initial target register
         register := equation.register;
         Error_Log.Debug_Data(at_level => 7, with_details => "Execute(the_equation): Start." & " At level " & Put_Into_String(at_level) & ", register = '" & register'Wide_Image & "' and is of type " & equation.eq'Wide_Image & ".");
         -- Get/calculate any parameters for the register (only applies to S+G)
         if register = S or register = G
         then
            null;
         end if;
         -- Now process the equation bits, going forward (forward pass)
         while equation /= null loop
            if equation.register in A..E then Error_Log.Debug_Data(at_level => 8, with_details => "Execute(the_equation): processing equation " & equation.eq'Wide_Image & ". Register = '" & register_ids(equation.register)  & "' (" & Put_Into_String(registers(equation.register).reg_f) & ") with operator '" & all_maths_operators(equation.operator) & "'."); 
            else Error_Log.Debug_Data(at_level => 8, with_details => "Execute(the_equation): processing equation " & equation.eq'Wide_Image & ". Register = '" & register_ids(equation.register)  & "' with operator '" & all_maths_operators(equation.operator) & "'."); end if;
            -- Get any parameters for the register
            if equation.register /= const and equation.reg_parm /= null
            then  -- parameter specified - calculate it's value
               Execute(equation.reg_parm, at_level + 1);
            end if;
            case equation.eq is
               when mathematical =>
                  case equation.operator is
                     when numeric_operator =>
                        Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): processing mathematical equation with '" & all_maths_operators(equation.operator) & "' and equation.m_result = " & Put_Into_String(equation.m_result,3) & ".");
                        if equation.m_result = 0.0 then
                           case equation.register is
                              when F => param1:=long_float(wide_character'Pos(
                                           registers(equation.register).reg_c));
                              when A .. E => param1:=
                                           registers(equation.register).reg_f;
                              when others => param1 := 0.0;
                           end case;
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): processing mathematical equation with operator '" & all_maths_operators(equation.operator) & "'. Register = '" & register_ids(equation.register) & "' and parameter " & Put_Into_String(param1,2) & ".");
                           if equation.last_equ /= null and then
                              equation.last_equ.m_result = 0.0
                           then
                              equation.m_result := param1;
                           else
                              equation.m_result := param1;
                           end if;
                        end if;
                     when ellipses =>
                        Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): processing mathematical equation with 'ellipses'.");
                        null;
                     when range_condition =>
                        Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): processing mathematical equation with 'ellipses'.");
                        null;
                     when none =>
                        Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): processing mathematical equation with operator 'none'. Register = '" & register_ids(equation.register) & "'.");
                        if equation.register /= const and
                           equation.m_result = 0.0 then
                           case equation.register is
                              when F => param1:=long_float(wide_character'Pos(
                                           registers(equation.register).reg_c));
                              when A .. E => param1:=
                                           registers(equation.register).reg_f;
                              when others => param1 := 0.0;
                           end case;
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): processing mathematical equation with operator 'none'. Register = '" & register_ids(equation.register) & "' and parameter " & Put_Into_String(param1,2) & ".");
                           equation.m_result := equation.m_result + param1;
                        else
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): processing mathematical equation with operator 'none'. Register = '" & register_ids(equation.register) & "' and equation.m_result = " & Put_Into_String(equation.m_result,2) & ".");
                        end if;
                     when assign =>
                        Execute(equation.equation, at_level + 1);
                        reverse_start := equation;
                        exit;  -- quit the loop;
                     when others =>
                        Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): processing mathematical equation with 'others' (" & all_maths_operators(equation.operator) & ").");
                        null;
                  end case;
                  null;
               when logical =>
                  case equation.operator is
                     when logical_operator =>
                        Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): processing logical equation with '" & all_maths_operators(equation.operator) & "'.");
                        if equation.l_result = false then
                           case equation.register is
                              when F => logres:=(wide_character'Pos(
                                       registers(equation.register).reg_c)/=0);
                              when A .. E => logres:=(Integer(
                                       registers(equation.register).reg_f)/=0);
                              when Y => logres := 
                                            registers(equation.register).reg_b;
                              when others => logres := false;
                           end case;
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): processing mathematical equation with operator '" & all_maths_operators(equation.operator) & "'. Register = '" & register_ids(equation.register) & "' and parameter " & logres'Wide_Image & ".");
                           if equation.last_equ /= null
                           then
                              equation.last_equ.l_result := logres;
                           else
                              equation.l_result := logres;
                           end if;
                        end if;
                        null;
                     when ellipses =>
                        Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): processing logical equation with 'ellipses'.");
                        null;
                     when range_condition =>  -- (IN) This will be a function
                        Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): processing logical equation with operator 'range_condition' (IN).");
                        if equation.equation /= null and then 
                           equation.equation.eq = funct
                        then
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): processing logical equation 'range_condition' (IN) with child at 'funct' and register '" & register_ids(equation.register) & "'.");
                           if equation.reg_parm /= null
                           then
                              register_position := integer(equation.reg_parm.m_result);
                           else
                              register_position := 0;
                           end if;
                           equation.l_result := 
                              The_IN_Value(for_register => equation.register, 
                                           with_register_parameter => register_position,
                                           at_range_condition => equation.equation);
                        end if;
                     when none =>  -- a value, check children for type
                        Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): processing logical equation with operator 'none'.");
                        if equation.equation /= null and then 
                           equation.equation.eq = funct
                        then
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): processing logical equation with child at 'funct'.");
                        elsif equation.register /= const and
                           equation.l_result = false then
                           case equation.register is
                              when F => logres:=(wide_character'Pos(
                                       registers(equation.register).reg_c)/=0);
                              when A .. E => logres:=(Integer(
                                       registers(equation.register).reg_f)/=0);
                              when Y => logres := 
                                            registers(equation.register).reg_b;
                              when others => logres := false;
                           end case;
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): processing mathematical equation with operator '" & all_maths_operators(equation.operator) & "'. Register = '" & register_ids(equation.register) & "' and parameter " & logres'Wide_Image & ".");
                           equation.l_result := equation.l_result or logres;
                        end if;
                     when assign =>
                        Execute(equation.equation, at_level + 1);
                        reverse_start := equation;
                        exit;  -- quit the loop;
                     when others =>
                        Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): processing logical equation with operator 'others'(" & all_maths_operators(equation.operator) & ").");
                        if equation.equation /= null and then 
                           equation.equation.eq = funct
                        then
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): processing logical equation with child at 'funct'.");
                           null;
                        end if;
                        null;
                  end case;
                  null;
               when textual =>
                  Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): processing textual equation based on operator.");
                  case equation.operator is
                     when concat =>
                        Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): processing textual equation with '" & all_maths_operators(equation.operator) & "' and equation.t_result = '" & equation.t_result & "'.");
                        if Length(equation.t_result) = 0 then
                           case equation.register is
                              when F => txtres:=To_Text(
                                           registers(equation.register).reg_c);
                              when G | H | S =>
                                 if equation.reg_parm /= null
                                 then
                                    txtres:=To_Text(Wide_Element(
                                         registers(equation.register).reg_t,
                                         integer(equation.reg_parm.m_result)));
                                 else
                                    txtres:=registers(equation.register).reg_t;
                                 end if;
                              when A .. E    => txtres:=Put_Into_String(
                                           registers(equation.register).reg_f);
                              when others => Clear(txtres);
                           end case;
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): processing textual equation with operator '" & all_maths_operators(equation.operator) & "'. Register = '" & register_ids(equation.register) & "' and parameter '" & txtres & "'.");
                           if equation.last_equ /= null and then  ---*** elsif
                              equation.last_equ.eq = funct
                           then  -- we would need to add it in at the head
                              null;
                              equation.t_result := txtres;
                           else
                              equation.t_result := txtres;
                           end if;
                        end if;
                     when none =>  -- a value, check children for type
                        Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): processing textual equation with operator 'none'. Register = '" & register_ids(equation.register) & "'.");
                        if equation.register /= const and
                           Length(equation.t_result) = 0 then
                           case equation.register is
                              when F => txtres:=To_Text(
                                           registers(equation.register).reg_c);
                              when G | H | S =>
                                 if equation.reg_parm /= null
                                 then
                                    txtres:=To_Text(Wide_Element(
                                         registers(equation.register).reg_t,
                                         integer(equation.reg_parm.m_result)));
                                 else
                                    txtres:=registers(equation.register).reg_t;
                                 end if;
                              when A .. E    => txtres:=Put_Into_String(
                                           registers(equation.register).reg_f);
                              when others => Clear(txtres);
                           end case;
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): processing textual equation with operator 'none'. Register = '" & register_ids(equation.register) & "' and parameter '" & txtres & "'.");
                           if equation.last_equ /= null and then  ---*** elsif
                              equation.last_equ.eq = funct
                           then  -- we would need to add it in at the head
                              null;
                              equation.t_result := txtres;
                           else
                              equation.t_result := txtres;
                           end if;
                        end if;
                     when assign =>
                        Execute(equation.equation, at_level + 1);
                        reverse_start := equation;
                        exit;  -- quit the loop;
                     when others =>
                        Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): processing textual equation with 'others' operator (" & equation.operator'Wide_Image & ").");
                        null;
                  end case;
                  Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): processing textual equation - finished processing of 'based on operator'.");
                  null;
               when bracketed =>
                  -- Execute the equation
                  Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): executing bracketed equation where equation.b_equation = " & equation.b_equation.eq'Wide_Image & ".");
                  Execute(equation.b_equation, at_level + 1);
                  -- Reach in to extract the result
                  case equation.b_equation.eq is
                     when mathematical =>
                        equation.b_result := equation.b_equation.m_result;
                     when funct =>
                        equation.b_result := equation.b_equation.f_result;
                     when bracketed =>
                        equation.b_result := equation.b_equation.b_result;
                     when logical =>
                        if equation.b_equation.l_result
                        then equation.b_result := 1.0;
                        else equation.b_result := 0.0;
                        end if;
                     when textual =>
                        if Length(equation.b_equation.t_result) = 1
                        then 
                           equation.b_result := 
                              long_float(wide_character'Pos(
                                Wide_Element(equation.b_equation.t_result,1)));
                        -- Else do nothing at this stage
                        end if;
                     when others =>
                        null;  -- Do nothing at this stage
                  end case;
                  Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): executed bracketed equation of type " & equation.b_equation.eq'Wide_Image & " with result  of " & Put_Into_String(equation.b_result,2) & ".");
               when funct =>
                  Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): processing equation - Starting processing Funct.");
                  -- calculate the parameter(s)
                  param1 := Get_Param(from_equation => equation.f_param1);
                  param2 := Get_Param(from_equation => equation.f_param2);
                  Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): processing funct equation with parameters " & Put_Into_String(param1,2) & " and " & Put_Into_String(param2,2) & " for function '" & equation.f_type'Wide_Image & "'" & ".");
                  -- Execute the function, storing the result in f_result.
                  case equation.f_type is
                     when cCHAR =>
                        equation.f_result := long_float(wide_character'Pos(
                           Char(start=>integer(param1),size=>param2)));
                        equation.ft_result := To_Text(
                               wide_character'Val(integer(equation.f_result)));
                        Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): processing cCHAR with parameters = " & Put_Into_String(integer(param1)) & " and " & Put_Into_String(param2,3) & " with result = '" & wide_character'Val(integer(equation.f_result)) & "'"); 
                        if equation.last_equ /= null and then
                           equation.last_equ.eq = mathematical and then
                           equation.last_equ.operator = none
                        then
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): processed cCHAR and set equation.last_equ.m_result := equation.f_result = '" & wide_character'Val(integer(equation.f_result)) & "' (IS THIS USED?)"); 
                           equation.last_equ.m_result := equation.f_result;
                        elsif  equation.last_equ /= null and then
                           equation.last_equ.eq = textual and then
                           equation.last_equ.operator = none
                        then
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): processed cCHAR and set equation.last_equ.t_result := To_Text(equation.f_result) = '" & wide_character'Val(integer(equation.f_result)) & "' (IS THIS USED?)"); 
                           equation.last_equ.t_result := equation.ft_result;
                        end if;
                     when cABS =>
                        Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): processing cABS with parameter = '" & Put_Into_String(param1, 3) & "'"); 
                        equation.f_result := Abs_Value(of_number => param1);
                        if equation.last_equ /= null and then
                           equation.last_equ.eq = mathematical and then
                           equation.last_equ.operator = none then
                           equation.last_equ.f_result := equation.f_result;
                        end if;
                     when cFIND =>
                        Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): processing cFIND with parameter = '" & wide_character'Val(integer(param1)) & "'"); 
                        equation.f_result := Long_Float(
                           Find(value => wide_character'Val(integer(param1))));
                        if equation.last_equ /= null and then
                           equation.last_equ.eq = mathematical and then
                           equation.last_equ.operator = none then
                           equation.last_equ.f_result := equation.f_result;
                        end if;
                     when cWIDTH =>
                        Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): processing cWIDTH"); 
                        equation.f_result := 
                            Width(value=> wide_character'Val(integer(param1)));
                        if equation.last_equ /= null and then
                           equation.last_equ.eq = mathematical and then
                           equation.last_equ.operator = none
                        then
                           equation.last_equ.f_result := equation.f_result;
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): processed cWIDTH and put result (" & Put_Into_String(equation.f_result) & ") into equation.last_equ.f_result.");
                        else
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): processed cWIDTH but result (" & Put_Into_String(equation.f_result,3) & ") only exists in equation.f_result.");
                        end if;
                     when cIN => null;  -- do nothing here - already done
                        Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Not reprocessing cIN");
                     when cLength =>
                        if equation.register /= const
                        then
                           equation.f_result := Long_Float(
                                  Str_Length(of_the_reg => equation.register));
                        elsif equation.last_equ /= null and then
                              equation.last_equ.register /= const
                         then
                           equation.f_result := Long_Float(
                                  Str_Length(of_the_reg=>
                                                  equation.last_equ.register));
                        else  -- error condition - need a register
                           Error_Log.Debug_Data(at_level => 9, 
                                with_details => "Execute: raising exception " &
                                                "on instruction = 'EQUATION" &
                                                "' for no register defined.");
                           raise BAD_MACRO_CODE;
                        end if;
                     when cSize =>
                        if equation.register /= const
                        then
                           equation.f_result := Long_Float(
                                        Size_Of(the_reg => equation.register));
                        elsif equation.last_equ /= null and then
                              equation.last_equ.register /= const
                         then
                           equation.f_result := Long_Float(
                                 Size_Of(the_reg=>equation.last_equ.register));
                        else  -- error condition - need a register
                           Error_Log.Debug_Data(at_level => 9, 
                                with_details => "Execute: raising exception " &
                                                "on instruction = 'EQUATION" &
                                                "' for no register defined.");
                           raise BAD_MACRO_CODE;
                        end if;
                     when cFirst =>
                        if equation.register /= const
                        then
                           equation.f_result := 
                                  The_First(for_the_reg => equation.register);
                        elsif equation.last_equ /= null and then
                              equation.last_equ.register /= const
                         then
                           equation.f_result := 
                                  The_First(for_the_reg=>
                                                  equation.last_equ.register);
                        else  -- error condition - need a register
                           Error_Log.Debug_Data(at_level => 9, 
                                with_details => "Execute: raising exception " &
                                                "on instruction = 'EQUATION" &
                                                "' for no register defined.");
                           raise BAD_MACRO_CODE;
                        end if;
                     when cLast =>
                        if equation.register /= const
                        then
                           equation.f_result := 
                                  The_Last(for_the_reg => equation.register);
                        elsif equation.last_equ /= null and then
                              equation.last_equ.register /= const
                         then
                           equation.f_result := 
                                  The_Last(for_the_reg=>
                                                  equation.last_equ.register);
                        else  -- error condition - need a register
                           Error_Log.Debug_Data(at_level => 9, 
                                with_details => "Execute: raising exception " &
                                                "on instruction = 'EQUATION" &
                                                "' for no register defined.");
                           raise BAD_MACRO_CODE;
                        end if;
                  end case;
               when comparison =>
                  -- Execute the equations
                  Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): executing comparison equation where equation.c_lhs = " & equation.c_lhs.eq'Wide_Image & "."); 
                  Execute(equation.c_lhs, at_level + 1);
                  Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): executing comparison equation where equation.r_lhs = " & equation.c_rhs.eq'Wide_Image & ".");
                  Execute(equation.c_rhs, at_level + 1);
               when others =>
                  Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): processing equation - at When Others => null.");
                  null;
            end case;
            null;
            if equation.equation = null  -- no more to go
            then  -- stash the end point at so we can get to it in reverse
               reverse_start := equation;
               Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): processing equation (forward pass) - set reverse_start to " & reverse_start.eq'Wide_Image & ".");
            else
               if equation.equation.last_equ /= null then Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Forward processing: moving to next equation part, with its last_equ = '" & equation.equation.last_equ.eq'Wide_Image & "'.");
               else Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Forward processing: moving to next equation part, with its last_equ = 'NULL'."); end if;
            end if;
            equation := equation.equation;
            Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Forward processing: moved to next equation part.");
         end loop;
         -- Now process the equation going backwards (reverse pass) in order to
         -- deposit the result at the beginning
         Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Starting reverse processing.");
         equation := reverse_start;
         while equation /= null loop
            if equation.register in A..E then Error_Log.Debug_Data(at_level => 8, with_details => "Execute(the_equation): Reverse processing equation " & equation.eq'Wide_Image & " with register '" & register_ids(equation.register) & "' (" & Put_Into_String(registers(equation.register).reg_f) & ") and operator '" & all_maths_operators(equation.operator) & "' with num_type " & equation.num_type'Wide_Image & "."); 
            else Error_Log.Debug_Data(at_level => 8, with_details => "Execute(the_equation): Reverse processing equation " & equation.eq'Wide_Image & " with register '" & register_ids(equation.register) & "' and operator '" & all_maths_operators(equation.operator) & "' with num_type " & equation.num_type'Wide_Image & "."); end if;
            case equation.eq is
               when mathematical =>
                  if equation.last_equ /= null
                  then -- not at the top
                     if equation.last_equ.operator in numeric_operator
                     then
                        case equation.last_equ.eq is
                           when mathematical =>
                              Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing equation of 'mathematical' with '" & all_maths_operators(equation.last_equ.operator) & "'{equation.last_equ.m_result=" & Put_Into_String(equation.last_equ.m_result,3) & ",equation.m_result=" & Put_Into_String(equation.m_result,3) & "}.");
                              equation.last_equ.m_result := 
                                 Combine(the_value=>equation.last_equ.m_result,
                                         with_value=>equation.m_result,
                                   using_operator=>equation.last_equ.operator);
                           when bracketed    =>
                              Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing equation of 'mathematical' with '" & all_maths_operators(equation.last_equ.operator) & "'{equation.last_equ.b_result=" & Put_Into_String(equation.last_equ.b_result,3) & ",equation.m_result=" & Put_Into_String(equation.m_result,3) & "}.");
                              equation.last_equ.b_result := 
                                 Combine(the_value=>equation.last_equ.b_result,
                                         with_value=>equation.m_result,
                                   using_operator=>equation.last_equ.operator);
                           when funct        =>
                              Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing equation of 'mathematical' with '" & all_maths_operators(equation.last_equ.operator) & "'{equation.last_equ.f_result=" & Put_Into_String(equation.last_equ.f_result,3) & ",equation.m_result=" & Put_Into_String(equation.m_result,3) & "}.");
                              equation.last_equ.f_result := 
                                 Combine(the_value=>equation.last_equ.f_result,
                                         with_value=>equation.m_result,
                                   using_operator=>equation.last_equ.operator);
                           when others => null;  -- should never occur
                        end case;
                     else
                        Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing MATHEMATICAL at equation.last_equ = null.");
                     end if;
                  else  -- got to the top, if a register is specified, then
                        -- load the answer into it
                     Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing equation and got to the top of 'mathematical' with register '" & register_Ids(equation.register) & "' and operator '" & all_maths_operators(equation.operator) & "' and current value of equation.m_result = '" & Put_Into_String(equation.m_result,3) & "'.");
                     if equation.operator = assign -- a common event for top
                     then  -- reach in to grab the result
                        case equation.equation.eq is
                           when mathematical =>
                              equation.m_result := equation.equation.m_result;
                           when bracketed =>
                              equation.m_result := equation.equation.b_result;
                           when funct =>
                              equation.m_result := equation.equation.f_result;
                           when others => null;  -- Should never occur
                        end case;
                     end if;
                     if equation.register in A..E then
                        if equation.last_equ = null and 
                           equation.num_type /= null_type
                        then
                           registers(equation.register).reg_f:= equation.m_result;
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing mathematical equation at assign and set register " & register_ids(equation.register) & " to " & Put_Into_String(registers(equation.register).reg_f,2) & " with equation.num_type = " & equation.num_type'Wide_Image & ".");
                        end if;
                        Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing mathematical equation at register " & register_ids(equation.register) & " with equation.num_type = " & equation.num_type'Wide_Image & " - with m_result of " & Put_Into_String(equation.m_result, 3) & ".");
                     end if;
                  end if;
               when logical =>
                  Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing equation of 'logical'.");
                  if equation.last_equ /= null
                  then -- not at the top
                     Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing equation.last_equ.operator (" & all_maths_operators(equation.last_equ.operator) & ") for equation of 'logical'.");
                     if equation.last_equ.operator in logical_operator
                     then
                        equation.last_equ.l_result := 
                                 Combine(the_value => equation.l_result,
                                        with_value=>equation.last_equ.l_result,
                                   using_operator=>equation.last_equ.operator);
                        if equation.register in A .. E
                           then  -- get the register contents
                           equation.last_equ.l_result := 
                                 Combine(the_value => equation.l_result,
                                   with_value=>
                                     (registers(equation.register).reg_f/=0.0),
                                   using_operator=>equation.last_equ.operator);
                           -- else the value is already in the l_result location
                        end if;
                     end if;
                  else  -- got to the top, if a register is specified, then
                        -- load the answer into it
                     Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing equation and got to the top of 'logical' with register '" & register_Ids(equation.register) & "' and operator '" & all_maths_operators(equation.operator) & "' and current value of equation.m_result = '" & equation.l_result'Wide_Image & "'.");
                     if equation.operator = assign -- a common event for top
                     then  -- reach in to grab the result
                        case equation.equation.eq is
                           when mathematical => equation.l_result := 
                                           (equation.equation.m_result /= 0.0);
                           when bracketed =>    equation.l_result := 
                                           (equation.equation.b_result /= 0.0);
                           when funct =>        equation.l_result := 
                                           (equation.equation.f_result /= 0.0);
                           when logical =>
                              equation.l_result := equation.equation.l_result;
                           when others => null;  -- Should never occur
                        end case;
                     end if;
                     if equation.register in A..E and then
                        (equation.last_equ = null and 
                         equation.num_type /= null_type)
                     then
                        if equation.l_result
                        then
                           registers(equation.register).reg_f:= 1.0;
                        else
                           registers(equation.register).reg_f:= 0.0;
                        end if;
                     elsif (equation.register in S .. H) and then 
                           (equation.equation.eq = mathematical and
                            (equation.equation.num_type = integer_type or
                             equation.equation.num_type = null_type))
                     then  -- previous would be specifying a character position
                        Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing equation of 'logical' and got a character position of " & register_ids(equation.register) & "(" & Put_Into_String(integer(equation.equation.m_result)) & ")='" & Wide_Element(registers(equation.register).reg_t,integer(equation.equation.m_result)) & "'.");
                        equation.l_pos := 
                             Wide_Element(registers(equation.register).reg_t,
                                          integer(equation.equation.m_result));
                     end if;
                  end if;
               when textual =>
                  if equation.last_equ /= null
                  then -- not at the top
                     if equation.operator in string_operator
                     then
                        Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing '" & all_maths_operators(equation.operator) & "' for equation of 'TEXTUAL' with equation.t_result = '" & equation.t_result & "' and equation.last_equ.operator = " & all_maths_operators(equation.last_equ.operator) & ".");
                        if equation.last_equ.eq = textual and then
                        Length(equation.t_result) > 0 
                        then
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing '" & all_maths_operators(equation.operator) & "' for equation of 'TEXTUAL' with equation.last_equ.t_result= '" & equation.last_equ.t_result & "', equation.t_result = '" & equation.t_result & "' and equation.last_equ.operator = " & all_maths_operators(equation.last_equ.operator) & ".");
                           equation.last_equ.t_result := 
                                 Combine(the_value=> equation.t_result,
                                        with_value=>equation.last_equ.t_result,
                                   using_operator=>equation.operator);     
                        elsif equation.last_equ.eq = funct and then
                        Length(equation.t_result) > 0 
                        then  -- trace back and concat to first textual found
                           txtres := equation.t_result;
                           reverse_start := equation.last_equ;
                           while reverse_start /= null and then 
                                 reverse_start.eq = funct loop
                              Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing '" & all_maths_operators(equation.operator) & "' for equation of 'TEXTUAL' with equation last f_result= " & Put_Into_String(integer(reverse_start.f_result)) & ", text result = '" & txtres & "' and equation last operator = " & all_maths_operators(reverse_start.operator) & ".");
                              txtres := Combine(the_value=> To_Text(
                                               Wide_Character'Val(integer(
                                                    reverse_start.f_result))),
                                            with_value=> txtres,
                                            using_operator=>equation.operator);
                              if reverse_start.last_equ = null
                              then  -- advance equation to this point
                                 equation := reverse_start;
                              end if;
                              reverse_start := reverse_start.last_equ;
                           end loop;
                           if reverse_start /= null and then
                              reverse_start.eq = textual
                           then
                              Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing '" & all_maths_operators(equation.operator) & "' for equation of 'TEXTUAL' loading result of '" & txtres & "' into '" & reverse_start.t_result & "'.");
                              reverse_start.t_result:= reverse_start.t_result &
                                                       txtres;
                           elsif reverse_start = null and then
                                 equation.eq = funct  -- which it should!
                           then  -- We are at the top and this is the answer
                              Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing '" & all_maths_operators(equation.operator) & "' for equation of 'TEXTUAL' loading result of '" & txtres & "' into '" & equation.ft_result & "'.");
                              equation.ft_result := txtres;
                           else  -- At the end and didn't assign
                              if reverse_start /= null then txtres2 := To_Text(reverse_start.eq'Wide_Image); 
                              else txtres2 := To_Text("NULL"); end if;
                              Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing '" & all_maths_operators(equation.operator) & "' for equation of 'TEXTUAL' and first position being of  type '" & txtres2 & "' loading result of '" & txtres & "' into NOWHERE!");
                              Error_Log.Debug_Data(at_level => 9, 
                                 with_details => "Execute: raising exception" &
                                             " on instruction = 'EQUATION' " &
                                              "for a format error in textual "&
                                              "concatenation with unassigned "&
                                              "result '" & txtres & "'.");
                              raise BAD_MACRO_CODE;
                           end if;
                        end if;
                     elsif equation.operator = none
                     then
                        Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing this operator '" & all_maths_operators(equation.operator) & "' for equation of 'textual'.");
                        if equation.last_equ.eq = textual and
                              equation.last_equ.operator in string_operator
                        then
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing last operator '" & all_maths_operators(equation.last_equ.operator) & "' for equation of 'textual'.");
                           equation.last_equ.t_result := 
                                 Combine(the_value=>equation.t_result,
                                        with_value=>equation.last_equ.t_result,
                                   using_operator=>equation.last_equ.operator);
                        elsif equation.last_equ.eq = bracketed and
                              equation.last_equ.operator in string_operator and
                              (equation.last_equ.last_equ /= null and then
                               equation.last_equ.last_equ.eq = textual)
                           then
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing last BRACKETED with last operator '" & all_maths_operators(equation.last_equ.operator) & "' for equation of 'textual'.");
                           equation.last_equ.last_equ.t_result := 
                                 Combine(the_value => equation.t_result, 
                                         with_value=>
                                           equation.last_equ.last_equ.t_result,
                                         using_operator=>
                                                   equation.last_equ.operator);
                        else
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing at 'none' for equation of 'textual' with equation.last_equ.eq = " & equation.last_equ.eq'Wide_Image & " and equation.last_equ.operator = '" & all_maths_operators(equation.last_equ.operator) & "'.");
                        end if;
                     else
                        Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing TEXTUAL at equation.last_equ = null.");
                     end if;
                  else  -- got to the top, if a register is specified, then
                        -- load the answer into it
                     Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing equation and got to the top of 'textual' with register '" & register_Ids(equation.register) & "' and operator '" & all_maths_operators(equation.operator) & "' and current value of equation.t_result = '" & equation.t_result & "'.");
                     if equation.operator = assign -- a common event for top
                     then  -- reach in to grab the result
                        case equation.equation.eq is
                           when mathematical => 
                              equation.t_result:= Put_Into_String
                                                (equation.equation.m_result,3);
                           when bracketed => 
                              equation.t_result:= Put_Into_String
                                                (equation.equation.b_result,3);
                           when funct => 
                              equation.t_result:= Put_Into_String
                                                (equation.equation.f_result,3);
                           when textual => 
                              equation.t_result:= equation.equation.t_result;
                           when logical =>
                              equation.t_result:= To_Text(equation.equation.l_result'Wide_Image);
                           when others => null;  -- Should never occur
                        end case;
                     end if;
                     if equation.register in G .. S then
                        if equation.last_equ = null and 
                           equation.num_type /= null_type
                        then
                           registers(equation.register).reg_t:= equation.t_result;
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing textual equation and SET register " & register_ids(equation.register) & " to '" & registers(equation.register).reg_t & "' with equation.num_type = " & equation.num_type'Wide_Image & ".");
                        end if;
                     elsif equation.register = F
                           then  -- get the register contents
                        Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing loading previous point's t_result with register = " & register_ids(equation.register) &  ", setting it to previous value of '" & equation.last_equ.t_result & "' & '" & registers(equation.register).reg_c & "'.");
                        if equation.last_equ = null and 
                           equation.num_type /= null_type
                        then
                           registers(equation.register).reg_c:= 
                                             Wide_Element(equation.t_result,1);
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing textual equation and set register " & register_ids(equation.register) & " to " & registers(equation.register).reg_c & "' with equation.num_type = " & equation.num_type'Wide_Image & ".");
                        end if;
                     end if;
                  end if;
               when Funct =>
                  Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing with register = Funct (" & Put_Into_String(equation.f_result,2) & ").");
                  if equation.f_type = cIN
                  then  -- already processed - do nothing
                     null;
                  elsif equation.last_equ /= null
                  then  -- stash the result there
                     case equation.last_equ.eq is
                        when mathematical =>
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing Funct and loading " & Put_Into_String(equation.f_result, 2) & " into equation.last_equ.m_result (which had " & Put_Into_String(equation.last_equ.m_result, 2) & ").");
                           if equation.last_equ.operator in numeric_operator
                           then  -- calculate the result as specified
                              equation.last_equ.m_result :=
                                 Combine(the_value=>equation.last_equ.m_result,
                                         with_value=>equation.f_result,
                                   using_operator=>equation.last_equ.operator);
                           else  -- just assign the result
                              equation.last_equ.m_result := equation.f_result;
                           end if;
                        when bracketed =>
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing Funct and loading " & Put_Into_String(equation.f_result, 2) & " into equation.last_equ.b_result (which had " & Put_Into_String(equation.last_equ.b_result, 2) & ").");
                           if equation.last_equ.operator in numeric_operator
                           then  -- calculate the result as specified
                              equation.last_equ.b_result :=
                                 Combine(the_value=>equation.last_equ.b_result,
                                         with_value=>equation.f_result,
                                   using_operator=>equation.last_equ.operator);
                           else  -- just assign the result
                              equation.last_equ.b_result := equation.f_result;
                           end if;
                        when funct =>
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing Funct and loading " & Put_Into_String(equation.f_result, 2) & " into equation.last_equ.f_result (which had " & Put_Into_String(equation.last_equ.f_result, 2) & ").");
                           if equation.last_equ.operator in numeric_operator
                           then  -- calculate the result as specified
                              equation.last_equ.f_result :=
                                 Combine(the_value=>equation.last_equ.f_result,
                                         with_value=>equation.f_result,
                                   using_operator=>equation.last_equ.operator);
                           elsif equation.last_equ.operator in logical_operator
                           then  -- calculate the result as specified
                              equation.last_equ.f_result := 
                                 long_float(boolean'Pos(
                                   Combine(the_value=>
                                               equation.last_equ.f_result/=0.0,
                                           with_value=>
                                               equation.f_result /= 0.0,
                                           using_operator=>
                                               equation.last_equ.operator)));
                           elsif equation.last_equ.operator in string_operator
                           then  -- calculate the result as specified
                              equation.last_equ.ft_result :=
                                 Combine(the_value=>equation.last_equ.ft_result,
                                         with_value=>equation.ft_result,
                                   using_operator=>equation.last_equ.operator);
                           elsif equation.operator in numeric_operator
                           then  -- calculate the result as specified
                              equation.last_equ.f_result :=
                                 Combine(the_value=>equation.last_equ.f_result,
                                         with_value=>equation.f_result,
                                   using_operator=>equation.operator);
                           else  -- just assign the result
                              equation.last_equ.f_result := equation.f_result;
                           end if;
                        when logical =>
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing Funct and loading " & Put_Into_String(equation.f_result, 1) & " into equation.last_equ.l_result (which had " & equation.last_equ.l_result'wide_Image & ").");
                           equation.last_equ.l_result :=
                                                    (equation.f_result /= 0.0);
                        when textual =>
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing Funct and loading the character for " & Put_Into_String(equation.f_result, 1) & " into equation.last_equ.t_result (which had '" & equation.last_equ.t_result & "').");
                           equation.last_equ.t_result := 
                              equation.last_equ.t_result & To_Text(
                               Wide_Character'Val(integer(equation.f_result)));
                        when others =>
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing Funct and not loading " & Put_Into_String(equation.f_result, 2) & " as equation.last_equ.eq type = " & equation.last_equ.eq'Wide_Image & ".");
                           null;
                     end case;
                  else  -- last_equ = null - at the top, stash result locally
                     -- If a register is specified, load it there
                     Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing equation and got to the top of 'funct' with register '" & register_Ids(equation.register) & "' and operator '" & all_maths_operators(equation.operator) & "' and current value of equation.f_result = '" & Put_Into_String(equation.f_result,3) & "'.");
                     if equation.operator = assign -- a common event for top
                     then  -- reach in to grab the result
                        case equation.equation.eq is
                           when mathematical =>
                              equation.f_result := equation.equation.m_result;
                           when bracketed =>
                              equation.f_result := equation.equation.b_result;
                           when funct =>
                              equation.f_result := equation.equation.f_result;
                              equation.ft_result := equation.equation.ft_result;
                           when others => null;  -- Should never occur
                        end case;
                     end if;
                     if equation.last_equ = null and 
                        equation.num_type /= null_type and
                        equation.operator = assign
                     then  -- We can load the value to a register
                        Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing of Funct got to the top with register = '" & register_ids(equation.register) & "'.");
                        case equation.register is
                           when A .. E =>
                              Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing of Funct LOADING register " & register_ids(equation.register) & " which has " & Put_Into_String(registers(equation.register).reg_f,3) & " with " & Put_Into_String(equation.f_result,3) & ".");
                              registers(equation.register).reg_f:= 
                                                             equation.f_result;
                           when F =>
                              Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing of Funct LOADING register " & register_ids(equation.register) & " which has '" & registers(equation.register).reg_c & "' with '" & wide_character'Val(integer(equation.f_result)) & "'.");
                              registers(equation.register).reg_c:= 
                                 wide_character'Val(integer(equation.f_result));
                           when string_register =>
                              Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing of Funct LOADING register " & register_ids(equation.register) & " which has '" & registers(equation.register).reg_t & "' with '" & equation.ft_result & "'.");
                              registers(equation.register).reg_t:= 
                                                            equation.ft_result;
                           when Y =>
                              Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing of Funct LOADING register " & register_ids(equation.register) & " which has " & registers(equation.register).reg_b'Wide_Image & " with " & boolean'Wide_Image(equation.f_result /= 0.0) & ".");
                              registers(equation.register).reg_b:= 
                                                      equation.f_result /= 0.0;
                           when others =>
                              Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing of Funct got to the top with register = others (" & register_ids(equation.register) & ") and didn't load a register.");
                              null;
                        end case;
                     end if;
                  end if;
               when bracketed =>
                  Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing on bracketed with operator '" & all_maths_operators(equation.operator) & "' and register '" & register_ids(equation.register) & "' and equation.b_result = " & Put_Into_String(equation.b_result,3) & ".");
                  if equation.last_equ /= null
                  then  -- Reach in to extract the result
                     Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing with operation type equation.last_equ.eq = '" & equation.last_equ.eq'Wide_Image & "' on bracketed, bracketed equation of type '" & equation.b_equation.eq'Wide_Image & "' and equation.last_equ.operator '" & all_maths_operators(equation.last_equ.operator) & "'.");
                     case equation.last_equ.eq is
                        when mathematical => 
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing with equation.last_equ.eq operation type " & equation.last_equ.eq'Wide_Image & " and equation.b_equation.eq operation type " & equation.b_equation.eq'Wide_Image & " and has equation.b_equation.m_result = " & Put_Into_String(equation.b_result) & ".");
                           if equation.last_equ.operator in numeric_operator
                           then  -- not near the top, calculate it
                              equation.last_equ.m_result := 
                                 Combine(the_value=>equation.last_equ.m_result,
                                         with_value=>equation.b_result,
                                   using_operator=>equation.last_equ.operator);
                           else  -- near the top, so just load it into the top
                              equation.last_equ.m_result := equation.b_result;
                           end if;           
                        when logical =>
                           if equation.b_equation.l_pos = null_ch
                           then
                              equation.last_equ.l_result := equation.b_equation.l_result;
                           else
                              equation.last_equ.l_pos :=  equation.b_equation.l_pos;
                           end if;
                        when textual =>
                           equation.last_equ.t_result := equation.b_equation.t_result;
                        when funct =>
                           case equation.last_equ.eq is
                              when mathematical =>
                                 equation.last_equ.m_result:= equation.b_equation.f_result;
                              when bracketed =>
                                 equation.last_equ.b_result:= equation.b_equation.f_result;
                              when others =>
                                 null;
                           end case;
                        when bracketed =>
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing with equation.last_equ.eq operation type " & equation.last_equ.eq'Wide_Image & " and equation.b_equation.eq operation type " & equation.b_equation.eq'Wide_Image & ".");
                           if equation.last_equ.operator in numeric_operator
                           then
                              Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing '" & all_maths_operators(equation.operator) & "' for equation of 'bracketed' with equation.last_equ.b_result= " & Put_Into_String(equation.last_equ.b_result,3) & ", equation.b_result = " & Put_Into_String(equation.b_result,3) & " and equation.last_equ.operator = '" & all_maths_operators(equation.last_equ.operator) & "'.");
                              equation.last_equ.b_result := 
                                 Combine(the_value=>equation.last_equ.b_result,
                                         with_value=>equation.b_result,
                                   using_operator=>equation.last_equ.operator);
                           end if;
                           null;
                        when others =>
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing with equation.last_equ.eq operation type Others " & equation.last_equ.eq'Wide_Image & " and equation.b_equation.eq operation type " & equation.b_equation.eq'Wide_Image & " [doing nothing with this].");
                           null;
                     end case;
                  else  -- got to the top, if a register is specified, then
                        -- load the answer into it
                     Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing equation and got to the top of 'bracketed' with register '" & register_Ids(equation.register) & "' and operator '" & all_maths_operators(equation.operator) & "' and current value of equation.b_result = '" & Put_Into_String(equation.b_result,3) & "'.");
                     if equation.operator = assign -- a common event for top
                     then  -- reach in to grab the result
                        case equation.equation.eq is
                           when mathematical =>
                              equation.b_result := equation.equation.m_result;
                           when bracketed =>
                              equation.b_result := equation.equation.b_result;
                           when funct =>
                              equation.b_result := equation.equation.f_result;
                           when logical =>
                              if equation.equation.l_result
                              then equation.b_result := 1.0;
                              else equation.b_result := 0.0;
                              end if;
                           when others => null;  -- Should never occur
                        end case;
                     end if;
                     if equation.register in A..E then
                        if equation.last_equ = null and 
                           equation.num_type /= null_type
                        then  -- NB: this situation should never occur
                           registers(equation.register).reg_f:=equation.b_result;
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing bracketed equation and set register " & register_ids(equation.register) & " to " & Put_Into_String(registers(equation.register).reg_f,2) & " with equation.num_type = " & equation.num_type'Wide_Image & ".");
                        else
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing with equation.last_equ.eq = NULL and equation.b_equation.eq operation type " & equation.b_equation.eq'Wide_Image & ".");
                        end if;
                     else
                        Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing with equation.last_equ.eq = NULL and equation.b_equation.eq operation type " & equation.b_equation.eq'Wide_Image & " and b_result of " & Put_Into_String(equation.b_result,3) & ".");
                     end if;
                  end if;
               when comparison =>
                  Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing with register = comparison operator '" & all_maths_operators(equation.operator) & "' and register '" & register_ids(equation.register) & "'.");
                  if equation.last_equ /= null
                  then  -- Reach in to extract the result
                     Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing with operation on equation.last_equ of type '" & equation.last_equ.eq'Wide_Image & "' on comparison.");
                  end if;
                  if equation.c_lhs /= null
                  then  -- Reach in to extract the result
                     Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing with operation on equation.c_lhs of type '" & equation.c_lhs.eq'Wide_Image & "' on comparison.");
                     case equation.c_lhs.eq is
                        when mathematical =>
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing when mathematical for equation of 'comparison' with equation.c_lhs.m_result = " & Put_Into_String(equation.c_lhs.m_result,3) & ".");
                           param1 := equation.c_lhs.m_result;
                        when bracketed =>
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing when bracketed for equation of 'comparison'.");
                           if equation.c_lhs.b_equation.eq = mathematical
                           then
                              Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing when mathematical for equation of 'comparison' with equation.c_lhs.b_equation.m_result = " & Put_Into_String(equation.c_lhs.b_equation.m_result,3) & ".");
                              param1 := equation.c_lhs.b_equation.m_result;
                           elsif equation.c_lhs.b_equation.eq = funct
                           then
                              Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing when funct for equation of 'comparison' with equation.c_lhs.b_equation.f_result = " & Put_Into_String(equation.c_lhs.b_equation.f_result,3) & ".");
                              param1 := equation.c_lhs.b_equation.f_result;
                           else  -- not correctly specified - assume 0
                              param1 := 0.0;
                           end if;
                        when logical =>
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing when GREATER for equation of 'comparison'.");
                           if equation.c_lhs.l_result
                           then param1 := 1.0;
                           else param1 := 0.0;
                           end if;
                        when funct =>
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing when funct for equation of 'comparison'.");
                           param2 := equation.c_lhs.f_result;
                        when none =>
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing when none for equation of 'comparison'.");
                           param1 := 0.0;
                        when others =>
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing when others for equation of 'comparison'.");
                           param1 := 0.0;
                     end case;
                  else
                     param1 := 0.0;
                  end if;
                  if equation.c_rhs /= null
                  then  -- Reach in to extract the result
                     Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing with operation on equation.c_rhs of type '" & equation.c_rhs.eq'Wide_Image & "' on comparison.");
                     case equation.c_rhs.eq is
                        when mathematical =>
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing when mathematical for equation of 'comparison'.");
                           param2 := equation.c_rhs.m_result;
                        when bracketed =>
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing when bracketed for equation of 'comparison'.");
                           if equation.c_rhs.b_equation.eq = mathematical
                           then
                              Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing when mathematical for equation of 'comparison' with equation.c_rhs.b_equation.m_result = " & Put_Into_String(equation.c_rhs.b_equation.m_result,3) & ".");
                              param2 := equation.c_rhs.b_equation.m_result;
                           elsif equation.c_rhs.b_equation.eq = funct
                           then
                              Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing when funct for equation of 'comparison' with equation.c_rhs.b_equation.f_result = " & Put_Into_String(equation.c_rhs.b_equation.f_result,3) & ".");
                              param2 := equation.c_rhs.b_equation.f_result;
                           else  -- not correctly specified - assume 0
                              Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing when others for equation of 'comparison' with equation.c_rhs.b_equation.eq = " & equation.c_rhs.b_equation.eq'Wide_Image & ".");
                              param2 := 0.0;
                           end if;
                        when logical =>
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing when logical for equation of 'comparison'.");
                           if equation.c_rhs.l_result
                           then param2 := 1.0;
                           else param2 := 0.0;
                           end if;
                        when funct =>
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing when funct for equation of 'comparison'.");
                           param2 := equation.c_rhs.f_result;
                        when none =>
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing when none for equation of 'comparison'.");
                           param2 := 0.0;
                        when others =>
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing when others for equation of 'comparison'.");
                           param2 := 0.0;
                     end case;
                  else
                     param1 := 0.0;
                  end if;
                  equation.c_result := 
                               Compare(the_value => param1, against => param2, 
                                       using_operator => equation.operator);
               when others =>
                  Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing with register = others (" & register_ids(equation.register) & ").");
                  null;
            end case;
            equation := equation.last_equ;
            Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Reverse processing and moved to previous equation part.");
         end loop;
         null;
         Error_Log.Debug_Data(at_level => 9, with_details => "Execute(the_equation): Finished execute at level " & Put_Into_string(at_level) & ".");
      end Execute;
      proc_name  : text;
      proc_param : text;
   begin  -- Execute (the_macro) [main recursive execute procedure]
      Error_Log.Debug_Data(at_level => 6, 
                           with_details => "Execute(the_macro): Start.");
      -- Work through the macro instruction set
      Macro_Processing:
      while the_macro /= null loop
         Error_Log.Debug_Data(at_level => 7, with_details => "Execute: processing command " & the_macro.cmd'Wide_Image & ".");
         case the_macro.cmd is
            when cPROCEDURE =>
               -- load up the parameter into ???
               proc_param := the_macro.parameter;
               proc_name  := the_macro.proc_name;
               if the_macro.proc_body = null
               then  -- no procedure body
                  Error_Log.Debug_Data(at_level => 9, with_details => "Execute: no procedure body.");
               end if;
               if the_macro.next_command = null
               then
                  Error_Log.Debug_Data(at_level => 9, with_details => "Execute: no procedure next_command.");
               end if;
               -- and execute into the code block
               Execute (the_macro.proc_body, on_registers => registers,
                        loop_exit_triggered => exiting_loop);
               Error_Log.Debug_Data(at_level => 9, with_details => "Execute: Got Procedure with procedure '" & proc_name & "' parameter '" & proc_param & "'.");
               the_macro := the_macro.next_command;
            when cEQUATION =>  -- execute the code block
               Error_Log.Debug_Data(at_level => 9, with_details => "Execute: Got Execute(equation).");
               if not exiting_loop then  -- (don't execute if bailing)
                  Execute(the_equation => the_macro.equation, at_level => 0);
               end if;
               the_macro := the_macro.next_command;
            when cIF =>
               Error_Log.Debug_Data(at_level => 9, with_details => "Execute: Got IF(condtion).");
               -- work out the result of the IF equation
               Execute(the_equation => the_macro.condition, at_level => 0);
               Error_Log.Debug_Data(at_level => 9, with_details => "Execute: Got Condition for IF.");
               -- execute then or else part based on result
               if (the_macro.condition.eq = logical and then 
                                the_macro.condition.l_result) or else
                  (the_macro.condition.eq = comparison and then 
                                the_macro.condition.c_result)
               then  -- execute THEN part
                  Error_Log.Debug_Data(at_level => 9, with_details => "Execute: IF: executing THEN part.");
                  -- First, make sure the ELSIF (if any) doesn't execute
                  if the_macro.else_part /= null and then
                     the_macro.else_part.cmd = cELSIF
                  then  -- note to it that we have executed the THEN part
                     the_macro.else_part.eif_executed := true;
                  elsif the_macro.else_part /= null and  then
                        the_macro.else_part.cmd = cELSE
                  then
                     the_macro.if_executed := true;
                  end if;
                  -- Now execute the THEN part
                  Execute (the_macro.then_part, on_registers => registers,
                           loop_exit_triggered => exiting_loop);
                  Error_Log.Debug_Data(at_level => 9, with_details => "Execute: IF: executed THEN part.  Currently the_macro.cmd = " & all_reserved_words(the_macro.cmd) & " and the_macro.next_command.cmd = " & all_reserved_words(the_macro.next_command.cmd) &  ".");
               elsif the_macro.else_part /= null
               then  -- execute ELSE part
                  Error_Log.Debug_Data(at_level => 9, with_details => "Execute: IF: executing ELSE part.");
                  Execute (the_macro.else_part, on_registers => registers,
                           loop_exit_triggered => exiting_loop);
                  -- If the ELSE part was an ELSIf, then check on the ELSIF's
                  -- ELSIF Executed (eif_executed) flag to make sure it has
                  -- been reset.
                  if the_macro.else_part.cmd = cELSIF and then
                     the_macro.else_part.eif_executed
                  then  -- reset it
                     Error_Log.Debug_Data(at_level => 9, with_details => "Execute: IF condition resetting ELSIF's eif_executed flag.");
                     declare
                        macro : code_block := the_macro.else_part;
                     begin
                        macro.eif_executed := false;
                        macro := macro.eelse_part;
                        while macro /= null and then
                              macro.cmd = cELSIF and then
                              macro.eif_executed loop
                           -- check down a level again
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute: IF condition resetting ELSIF's ELSIF's eif_executed flag.");
                           macro.eif_executed := false;
                           macro := macro.eelse_part;
                        end loop;
                     end;
                  end if;
               else  -- IF condition failed and no ELSE part
                  Error_Log.Debug_Data(at_level => 9, with_details => "Execute: IF condition failed and no ELSE part, setting the_macro to next_command.");
               end if;
               the_macro := the_macro.next_command;  -- moving on
            when cELSIF =>
               Error_Log.Debug_Data(at_level => 9, with_details => "Execute: Got ELSIF(condtion).  Prior command is '" & all_reserved_words(the_macro.last_command.cmd) & "'.");
               -- First, work out where we have come to here from.  If from the
               -- IF statement, then proceed, otherwise, would have come from
               -- the END IF or a previous ELSIF.
               if the_macro.eif_executed
               then  --  just passing through, so return back
                  Error_Log.Debug_Data(at_level => 9, with_details => "Execute: Exiting cELSIF with the_macro.cmd = '" & all_reserved_words(the_macro.cmd) & "' and with the_macro.last_command.cmd = '" & all_reserved_words(the_macro.last_command.cmd) & "'."); 
                  the_macro.eif_executed := false;
                  the_macro := the_macro.parent_if;  -- point to parent/prior
                  Error_Log.Debug_Data(at_level => 9, with_details => "Execute: Exiting cELSIF with the_macro.parent_if.cmd = '" & all_reserved_words(the_macro.cmd) & "' and with the_macro.parent_if.last_command.cmd = '" & all_reserved_words(the_macro.last_command.cmd) & "' and the_macro.parent_if.next_command.cmd = '" & all_reserved_words(the_macro.next_command.cmd) & "'."); 
                  exit Macro_Processing;  -- actually return to the IF block
               else  -- actually at the ELSIF part
                  -- work out the result of the ELSIF equation
                  Execute(the_equation => the_macro.econdition, at_level => 0);
                  Error_Log.Debug_Data(at_level => 7, with_details => "Execute: Got Condition for ELSIF.");
                  -- execute then or else part based on result
                  if (the_macro.econdition.eq = logical and then 
                                the_macro.econdition.l_result) or else
                     (the_macro.econdition.eq = comparison and then 
                                the_macro.econdition.c_result)
                  then  -- execute THEN part
                     Error_Log.Debug_Data(at_level => 9, with_details => "Execute: ELSIF: executing THEN part.");
                     the_macro.eif_executed := true;
                     Execute (the_macro.ethen_part, on_registers => registers,
                              loop_exit_triggered => exiting_loop);
                     Error_Log.Debug_Data(at_level => 9, with_details => "Execute: ELSIF: executed THEN part.  Currently the_macro.cmd = " & all_reserved_words(the_macro.cmd) & ".");
                  elsif the_macro.eelse_part /= null
                  then  -- execute ELSE part
                     Error_Log.Debug_Data(at_level => 9, with_details => "Execute: ELSIF: executing ELSE part.");
                     Execute (the_macro.eelse_part, on_registers => registers,
                              loop_exit_triggered => exiting_loop);
                  end if;
               end if;
               the_macro:= the_macro.next_command; -- go to next statement
            when cELSE =>
               Error_Log.Debug_Data(at_level => 9, with_details => "Execute: Got ELSE.  Prior command is '" & all_reserved_words(the_macro.last_command.cmd) & "'.");
               -- First, work out where we have come to here from.  If from the
               -- IF or ELSIF's else statement, then proceed, otherwise, would
               -- have come from END IF of either the IF or a previous ELSIF.
               if the_macro.else_parent.cmd = cELSIF and then
                  the_macro.else_parent.eif_executed
               then  --  just passing through, so return back
                  Error_Log.Debug_Data(at_level => 9, with_details => "Execute: ELSE Setting the macro to the parent with the_macro.cmd = '" & all_reserved_words(the_macro.cmd) & "' and with the_macro.else_parent.cmd = '" & all_reserved_words(the_macro.else_parent.cmd) & "', then not executing ELSE part."); 
                  the_macro := the_macro.else_parent;  -- point to parent/prior
               elsif the_macro.else_parent.cmd = cIF and then
                     the_macro.else_parent.if_executed
               then  -- also passing through, so return back
                  Error_Log.Debug_Data(at_level => 9, with_details => "Execute: ELSE Skipping execution as THEN already executed, with the_macro.cmd = '" & all_reserved_words(the_macro.cmd) & "' and with the_macro.else_parent.cmd = '" & all_reserved_words(the_macro.else_parent.cmd) & "', then not executing ELSE part."); 
                  the_macro.else_parent.if_executed := false;  -- reset first
                  -- the_macro := the_macro.else_parent;  -- point to parent/prior
               else  -- actually at the ELSE part
                  -- execute the ELSE equation
                  Execute (the_macro.else_block, on_registers => registers,
                           loop_exit_triggered => exiting_loop);
                  Error_Log.Debug_Data(at_level => 9, with_details => "Execute: ELSE: executed ELSE part.  Currently the_macro.cmd = " & all_reserved_words(the_macro.cmd) & ".");
                  -- Pop to parent IF for exit of the if block
                  Error_Log.Debug_Data(at_level => 9, with_details => "Execute: Executed ELSE.  Prior command was '" & all_reserved_words(the_macro.last_command.cmd) & "' and current command is '" & all_reserved_words(the_macro.cmd) & "'.");
                  if the_macro.next_command /= null and the_macro.next_command.cmd = cEND then Error_Log.Debug_Data(at_level => 9, with_details => "Execute: Executed ELSE.  Next command is '" & all_reserved_words(the_macro.next_command.cmd) & "' with end_type '" & all_reserved_words(the_macro.next_command.end_type) & "'and next command parent is '" & all_reserved_words(the_macro.next_command.parent_block.cmd) & "' and it's next command is '" & all_reserved_words(the_macro.next_command.parent_block.next_command.cmd) & "'."); end if;
               end if;
               the_macro:= the_macro.next_command; -- go to next statement
            when cFOR =>
               Error_Log.Debug_Data(at_level => 9, with_details => "Execute: Got FOR(start .. end).");
               declare
                  the_start,
                  the_end   : integer := 0;
               begin
                  -- Work out the start and end parameters of the FOR loop
                  Execute(the_equation => the_macro.f_start, at_level => 0);
                  if the_macro.f_start.eq = mathematical
                  then
                     the_start := integer(the_macro.f_start.m_result);
                  elsif the_macro.f_start.eq = funct
                  then
                     the_start:= integer(the_macro.f_start.f_result);
                  elsif the_macro.f_start.eq = bracketed
                  then
                     the_start:= integer(the_macro.f_start.b_result);
                  end if;
                  Error_Log.Debug_Data(at_level => 9, with_details => "Execute: Got Start Condition (" & Put_Into_String(the_start) & ") for FOR.");
                  Execute(the_equation => the_macro.f_end, at_level => 0);
                  if the_macro.f_end.eq = mathematical
                  then
                     the_end := integer(the_macro.f_end.m_result);
                  elsif  the_macro.f_end.eq = funct
                  then
                     the_end := integer(the_macro.f_end.f_result);
                  elsif  the_macro.f_end.eq = bracketed
                  then
                     the_end := integer(the_macro.f_end.b_result);
                  end if;
                  Error_Log.Debug_Data(at_level => 9, with_details => "Execute: Got End Condition (" & Put_Into_String(the_end) & ") for FOR.");
                  -- Now run the FOR loop
                  if the_macro.direction = forward
                  then
                     for item in the_start .. the_end loop
                        Error_Log.Debug_Data(at_level => 9, with_details => "Execute: FOR Loop (fwd): register ('" & register_ids(the_macro.for_reg) & "') = item (" & Put_Into_String(item) & ") start (" & Put_Into_String(the_start) & ") .. end (" & Put_Into_String(the_end) & ").");
                        case the_macro.for_reg is
                           when G | H | S =>
                              registers(the_macro.for_reg).reg_t := 
                                             To_Text(Wide_Character'Val(item)); 
                           when A .. E =>
                              registers(the_macro.for_reg).reg_f := Long_Float(item);
                           when F =>
                              registers(the_macro.for_reg).reg_c := 
                                                      Wide_Character'Val(item);
                           when others => null;
                        end case;
                        Error_Log.Debug_Data(at_level => 9, with_details => "Execute: FOR Loop in forward direction : macro.cmd = " & the_macro.cmd'Wide_Image & ", register " & register_ids(the_macro.for_reg) & " = " & Put_Into_String(item) & ".");
                        Execute (the_macro.for_block, on_registers => registers,
                                 loop_exit_triggered => exiting_loop);
                        if the_macro.last_command /= null and the_macro.next_command /= null then
                           if the_macro.last_command.cmd = cEND then
                              Error_Log.Debug_Data(at_level => 9, with_details => "Execute: FOR Loop in forward direction : stepped into macro.cmd = " & all_reserved_words(the_macro.cmd) & ". which has its next_command = " & all_reserved_words(the_macro.next_command.cmd) & " and its last_command = '" & all_reserved_words(the_macro.last_command.cmd) & "' (" & all_reserved_words(the_macro.last_command.end_type) & ")" & ".");
                           else
                              Error_Log.Debug_Data(at_level => 9, with_details => "Execute: FOR Loop in forward direction : stepped into macro.cmd = " & all_reserved_words(the_macro.cmd) & ". which has its next_command = '" & all_reserved_words(the_macro.next_command.cmd) & "' and its last_command = '" & all_reserved_words(the_macro.last_command.cmd) & "'.");
                           end if;
                        elsif the_macro.next_command /= null then
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute: FOR Loop in forward direction : stepped into macro.cmd = " & all_reserved_words(the_macro.cmd) & ". which has its next_command = '" & all_reserved_words(the_macro.next_command.cmd) & "'.");
                        else
                           Error_Log.Debug_Data(at_level => 9, with_details => "Execute: FOR Loop in forward direction : stepped into macro.cmd = " & all_reserved_words(the_macro.cmd) & ".");
                        end if;
                        if loop_exit_triggered then  -- EXIT has been triggered
                           loop_exit_triggered := false;  -- reset it
                           exit;  -- and quit the loop
                        end if;
                     end loop;
                  else
                     for item in reverse the_start .. the_end loop
                        Error_Log.Debug_Data(at_level => 9, with_details => "Execute: FOR Loop (rev): register ('" & register_ids(the_macro.for_reg) & "') = item (" & Put_Into_String(item) & ") start (" & Put_Into_String(the_start) & ") .. end (" & Put_Into_String(the_end) & ").");
                        case the_macro.for_reg is
                           when G | H | S =>
                              registers(the_macro.for_reg).reg_t := 
                                             To_Text(Wide_Character'Val(item)); 
                           when A .. E =>
                              registers(the_macro.for_reg).reg_f := Long_Float(item);
                           when F =>
                              registers(the_macro.for_reg).reg_c := 
                                                      Wide_Character'Val(item);
                           when others => null;
                        end case;
                        Error_Log.Debug_Data(at_level => 9, with_details => "Execute: FOR Loop in reverse direction : macro.cmd = " & the_macro.cmd'Wide_Image & ", register " & register_ids(the_macro.for_reg) & " = " & Put_Into_String(item) & ".");
                        Execute (the_macro.for_block, on_registers => registers,
                                 loop_exit_triggered => exiting_loop);
                        if loop_exit_triggered then  -- EXIT has been triggered
                           loop_exit_triggered := false;  -- reset it
                           exit;  -- and quit the loop
                        end if;
                     end loop;
                  end if;
               end;
               if the_macro.next_command /= null and then
                  the_macro.next_command.cmd = cEND
               then
                  the_macro := the_macro.next_command.next_command;
                  Error_Log.Debug_Data(at_level => 9, with_details => "Execute: FOR Loop : exiting and heading to END LOOP's next_command.");
               else  -- really an error condition
                  the_macro := the_macro.next_command;
                  Error_Log.Debug_Data(at_level => 9, with_details => "Execute: FOR Loop : exiting and heading to the next_command (which is ?).");
               end if;
            when cLOOP =>
               Error_Log.Debug_Data(at_level => 9, with_details => "Execute: Got LOOP.");
               loop
                  Error_Log.Debug_Data(at_level => 9, with_details => "Execute: LOOP Loop  : macro.cmd = " & the_macro.cmd'Wide_Image & ".");
                  Execute (the_macro.loop_block, on_registers => registers,
                                 loop_exit_triggered => exiting_loop);
                  if loop_exit_triggered then  -- EXIT has been triggered
                     loop_exit_triggered := false;  -- reset it
                     exit;  -- and quit the loop
                  end if;
               end loop;
               if the_macro.next_command /= null and then
                  the_macro.next_command.cmd = cEND
               then
                  the_macro := the_macro.next_command.next_command;
                  Error_Log.Debug_Data(at_level => 9, with_details => "Execute: LOOP Loop : exiting and heading to END LOOP's next_command.");
               else  -- really an error condition
                  the_macro := the_macro.next_command;
                  Error_Log.Debug_Data(at_level => 9, with_details => "Execute: LOOP Loop : exiting and heading to the next_command (which is ?).");
               end if;
            when cEXIT =>
               if loop_exit_triggered
               then  -- a previous exit has been triggered, just exit
                  the_macro := the_macro.next_command;
               elsif the_macro.exit_conditn /= null
               then  -- see if the condition is met
                  Execute(the_equation => the_macro.exit_conditn, at_level=>0);
                  Error_Log.Debug_Data(at_level => 9, with_details => "Execute: EXIT - executed exit_conditn."); 
                  if (the_macro.exit_conditn.eq = logical and then 
                                the_macro.exit_conditn.l_result) or else
                  (the_macro.exit_conditn.eq = comparison and then 
                                the_macro.exit_conditn.c_result)
                  then  -- condition met, so execute EXIT part
                     loop_exit_triggered := true;
                     Error_Log.Debug_Data(at_level => 9, with_details => "Execute: EXIT - set exit_is_set and the_macro.exit_parent = '" & all_reserved_words(the_macro.exit_parent.cmd) & "' as exit condition is met."); 
                     the_macro := the_macro.exit_parent;
                  else  -- condition not met, so do nothing other than continue
                     Error_Log.Debug_Data(at_level => 9, with_details => "Execute: EXIT - executed exit_conditn with result = exit condition is NOT met."); 
                     the_macro := the_macro.next_command;
                  end if;
               else  -- this is an unconditional exit
                  loop_exit_triggered := true;
                  Error_Log.Debug_Data(at_level => 9, with_details => "Execute: EXIT - set exit_is_set and the_macro.exit_parent = '" & all_reserved_words(the_macro.exit_parent.cmd) & "'.");
                  the_macro := the_macro.exit_parent;
               end if;
            when cEND =>
               -- Return (i.e. pop back up) the macro to the calling parent
               -- (Procedure/if/For) by exiting this loop and then returning
               Error_Log.Debug_Data(at_level => 9, with_details => "Execute: END - the_macro (" & all_reserved_words(the_macro.cmd) & ") is exiting the loop and therefore exiting Execute(the_macro)."); 
               exit Macro_Processing;
            when cINSERT =>
               declare
                  reg_pos   : natural := 0;
                  the_value : wide_character := null_ch;
                  the_str   : wide_string(1..1);
               begin
                  -- Get the register position to operate on
                  Execute(the_equation => the_macro.i_pos, at_level => 0);
                  if the_macro.i_pos.eq = mathematical
                  then
                     reg_pos := integer(the_macro.i_pos.m_result);
                  elsif the_macro.i_pos.eq = funct
                  then
                     reg_pos := integer(the_macro.i_pos.f_result);
                  end if;
                  -- Get the value to insert
                  case the_macro.i_val is
                     when const =>
                        Execute(the_equation => the_macro.i_data, at_level=>0);
                        if the_macro.i_data.eq = mathematical
                        then
                           the_value := wide_character'Val(integer(
                                           the_macro.i_data.m_result));
                        elsif the_macro.i_data.eq = funct
                        then
                           the_value := wide_character'Val(integer(
                                           the_macro.i_data.f_result));
                        elsif the_macro.i_data.eq = textual
                        then
                           the_value := Wide_Element(
                                           the_macro.i_data.t_result,1);
                        end if;
                     when A .. E =>
                        the_value := wide_character'Val(integer(
                                        registers(the_macro.i_val).reg_f));
                     when G | H | S => 
                        the_value := Wide_Element(
                                        registers(the_macro.i_val).reg_t, 1);
                     when F =>
                        the_value := registers(the_macro.i_val).reg_c;
                     when others => -- error condition
                        Error_Log.Debug_Data(at_level => 9, 
                                with_details => "Execute: raising exception " &
                                                "on instruction = 'EQUATION" &
                                                "' for bad INSERT format.");
                        raise BAD_MACRO_CODE;
                  end case;
                  -- Effect the Insert operation
                  the_str(1) := the_value;
                  Error_Log.Debug_Data(at_level => 9, with_details => "Execute: INSERT - inserting '" & the_str & "' into Register '" & register_IDs(the_macro.i_reg) & "' ('" & registers(the_macro.i_reg).reg_t & "') at position " & Put_Into_String(reg_pos) & ".");
                  if reg_pos = (Length(registers(the_macro.i_reg).reg_t) + 1)
                  then
                     Append(the_str, to => registers(the_macro.i_reg).reg_t);
                  else
                     Insert(registers(the_macro.i_reg).reg_t, reg_pos,the_str);
                  end if;
                  exception
                     when others =>
                        Error_Log.Debug_Data(at_level => 9, 
                             with_details => "Execute: raising exception on " &
                                             "instruction = 'EQUATION' for " &
                                              "a format error in INSERT.");
                        raise BAD_MACRO_CODE;
               end;
               the_macro := the_macro.next_command;
            when cREPLACE =>
               declare
                  reg_pos   : natural := 0;
                  the_value : text; --  := null_ch;
                  pre, post : text;
               begin
                  -- Get the register position to operate on
                  Execute(the_equation => the_macro.r_pos, at_level => 0);
                  if the_macro.r_pos.eq = mathematical
                  then
                     reg_pos := integer(the_macro.r_pos.m_result);
                  elsif the_macro.r_pos.eq = funct
                  then
                     reg_pos := integer(the_macro.r_pos.f_result);
                  end if;
                  -- Get the value to replace
                  case the_macro.r_val is
                     when const =>
                        Execute(the_equation => the_macro.r_data, at_level=>0);
                        if the_macro.r_data.eq = mathematical
                        then  -- assume a character
                           the_value := To_Text(wide_character'Val(integer(
                                                  the_macro.r_data.m_result)));
                        elsif the_macro.r_data.eq = funct
                        then  -- extract the string from the function
                           if Length(the_macro.r_data.ft_result) = 0
                           then
                              the_value:= To_Text(wide_character'Val(integer(
                                                  the_macro.r_data.f_result)));
                           else
                              the_value := the_macro.r_data.ft_result;
                           end if;
                        elsif the_macro.r_data.eq = textual
                        then  -- already in the right format
                           the_value := the_macro.r_data.t_result;
                        end if;
                     when A .. E =>
                        the_value := To_Text(wide_character'Val(integer(
                                           registers(the_macro.r_val).reg_f)));
                     when G | H | S => 
                        the_value := registers(the_macro.r_val).reg_t;
                     when F =>
                        the_value := To_Text(registers(the_macro.r_val).reg_c);
                     when others => -- error condition
                        Error_Log.Debug_Data(at_level => 9, 
                                with_details => "Execute: raising exception " &
                                                "on instruction = 'EQUATION" &
                                                "' for bad REPLACE format.");
                        raise BAD_MACRO_CODE;
                  end case;
                  -- Effect the Replace operation
                  Error_Log.Debug_Data(at_level => 9, with_details => "Execute: REPLACE - replacing '" & the_value & "' into Register '" & register_IDs(the_macro.r_reg) & "' ('" & registers(the_macro.r_reg).reg_t & "') at position " & Put_Into_String(reg_pos) & ".");
                  if reg_pos > 1 then
                     pre := Sub_String(registers(the_macro.r_reg).reg_t, 1, 
                                       reg_pos - 1);
                  end if;
                  post := Sub_String(registers(the_macro.r_reg).reg_t, 
                                     reg_pos + 1, 
                                     Length(registers(the_macro.r_reg).reg_t)
                                                                    - reg_pos);
                  registers(the_macro.r_reg).reg_t := pre & the_value & post;
                  exception
                     when others =>
                        Error_Log.Debug_Data(at_level => 9, 
                             with_details => "Execute: raising exception on " &
                                             "instruction = 'EQUATION' for " &
                                             "a format error in REPLACE.");
                        raise BAD_MACRO_CODE;
               end;
               the_macro := the_macro.next_command;
            when cDELETE =>
               declare
                  reg_pos   : natural := 0;
               begin
                  -- Get the register position to operate on
                  Execute(the_equation => the_macro.d_position, at_level => 0);
                  if the_macro.d_position.eq = mathematical
                  then
                     reg_pos := integer(the_macro.d_position.m_result);
                  elsif the_macro.d_position.eq = funct
                  then
                     reg_pos := integer(the_macro.d_position.f_result);
                  end if;
                  -- Effect the Delete operation
                  Error_Log.Debug_Data(at_level => 9, with_details => "Execute: DELETE - deleting '" & Wide_Element(registers(the_macro.d_reg).reg_t, reg_pos) & "' from the Register '" & register_IDs(the_macro.d_reg) & "' ('" & registers(the_macro.d_reg).reg_t & "') at position " & Put_Into_String(reg_pos) & ".");
                  Delete(registers(the_macro.d_reg).reg_t, reg_pos, 1);
                  Error_Log.Debug_Data(at_level => 9, with_details => "Execute: DELETE - deleted from the Register '" & register_IDs(the_macro.d_reg) & "' ('" & registers(the_macro.d_reg).reg_t & "') at position " & Put_Into_String(reg_pos) & ".");
                  exception
                     when others =>
                        Error_Log.Debug_Data(at_level => 9, 
                             with_details => "Execute: raising exception on " &
                                             "instruction = 'EQUATION' for " &
                                             "a format error in DELETE.");
                        raise BAD_MACRO_CODE;
               end;
               the_macro := the_macro.next_command;
            when cERROR_LOG =>
               if the_macro.e_reg /= const
               then
                  case the_macro.e_reg is
                     when G | H | S =>
                        Error_Log.Debug_Data(at_level=>1, 
                                   with_details=>registers(the_macro.e_reg).reg_t);
                     when A .. E =>
                        Error_Log.Debug_Data(at_level=>1, 
                           with_details=>
                                Put_Into_String(registers(the_macro.e_reg).reg_f));
                     when F =>
                        Error_Log.Debug_Data(at_level=>1, 
                           with_details=>To_Text(registers(the_macro.e_reg).reg_c));
                     when others => null;
                  end case;
               elsif the_macro.e_val = Value("registers")
               then
                  Error_Log.Debug_Data(at_level=>1, 
                             with_details=>"Execute: H='"&registers(H).reg_t &
                               "',S='" & registers(S).reg_t & 
                               "',A=" & Put_Into_String(registers(A).reg_f,2) &
                               ",B=" & Put_Into_String(registers(B).reg_f,2) & 
                               ",C=" & Put_Into_String(registers(C).reg_f,2) & 
                               ",D=" &  Put_Into_String(registers(D).reg_f,2) & 
                               ",E=" & Put_Into_String(registers(E).reg_f,2) & 
                               ",F='" & registers(F).reg_c & 
                               "',G='" & registers(G).reg_t & "'.");
               else
                  Error_Log.Debug_Data(at_level=>1, with_details=>the_macro.e_val);
               end if;
               the_macro := the_macro.next_command;
            when cNull =>  -- Do nothing, just go to the next command
               the_macro := the_macro.next_command;
            when others =>
               the_macro := the_macro.next_command;
         end case;
         if the_macro /= null then
            Error_Log.Debug_Data(at_level => 9, with_details => "Execute: Next Cmd=" & the_macro.cmd'Wide_Image & ", H='" & registers(H).reg_t & "',S='" & registers(S).reg_t & "',A=" & Put_Into_String(registers(A).reg_f,2) & ",B=" & Put_Into_String(registers(B).reg_f,2) & ",C=" & Put_Into_String(registers(C).reg_f,2) & ",D=" &  Put_Into_String(registers(D).reg_f,2) & ",E=" & Put_Into_String(registers(E).reg_f,2) & ",F='" & registers(F).reg_c & "',G='" & registers(G).reg_t & "',Y=" & registers(Y).reg_b'Wide_Image & ".");
         else
            Error_Log.Debug_Data(at_level => 9, with_details => "Execute: No further commands, H='" & registers(H).reg_t & "',S='" & registers(S).reg_t & "',A=" & Put_Into_String(registers(A).reg_f,2) & ",B=" & Put_Into_String(registers(B).reg_f,2) & ",C=" & Put_Into_String(registers(C).reg_f,2) & ",D=" &  Put_Into_String(registers(D).reg_f,2) & ",E=" & Put_Into_String(registers(E).reg_f,2) & ",F='" & registers(F).reg_c & "',G='" & registers(G).reg_t & "',X=" & "',Y=" & registers(Y).reg_b'Wide_Image & ".");
         end if;
      end loop Macro_Processing;
      if the_macro /= null then
         Error_Log.Debug_Data(at_level => 9, with_details => "Execute: Exiting Execute with Next Cmd=" & the_macro.cmd'Wide_Image & ".");
      else
         Error_Log.Debug_Data(at_level => 9, with_details => "Execute: Exiting Execute with No further commands.");
      end if;
      exception
         when BAD_MACRO_CODE =>  -- display the error and stop macro execution
            Error_Log.Put(the_error => 47,
                          error_intro =>  "Code_Interpreter Execute error", 
                          error_message=> "Bad code in Macro found during execution");
   end Execute;

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
      macro      : code_block := AtM(the_macros,the_macro_number);
      registers  : register_array;
      exiting_loop: boolean := false;
   begin  -- Execute (the main execute procedure)
      Error_Log.Debug_Data(at_level => 6, 
                           with_details => "Execute: Start" & ".  Macro number = " & Put_Into_String(the_macro_Number) & " and passed in parameter is '" & passed_in_parameter & "' with a character position of (" & Put_Into_String(Integer(wide_character'Pos(Wide_Element(passed_in_parameter,1)))) & ").");
      -- First, load or otherwise initialise the registers;
      Initialise(the_registers => registers);
      registers(H).reg_t:= passed_in_parameter;
      registers(S).reg_t:= Value_From_Wide(Decode(Get_Tooltip_Text(the_cell)));
      -- Now execute the macro
      Execute (the_macro_code => macro, on_registers => registers,
               loop_exit_triggered => exiting_loop);
      -- Finally, load the S register back
      Set_Tooltip_Text(the_cell, Encode(to_string(registers(S).reg_t))); 
      Error_Log.Debug_Data(at_level => 7, 
                           with_details => "Execute: Finished" & ".  Loaded S register '" & registers(S).reg_t & "' back into tool tip.");
   end Execute;


   procedure Strip_Comments_And_Simplify_Spaces(for_macro : in out text) is
      -- Strip out all comments, indicated by '--' and terminated by an end of
      -- line character, then go through and, knowing that commands are
      -- separated by the ';' character, replace all multiple spaces type
      -- characters, including end of line and tab characters, with a single
      -- space character (or no character on either side of a ';' character).
      use Ada.Wide_Characters.Handling;
      result : text := for_macro;  -- temporary store
      char_pos : positive := 1;
   begin
      -- First, remove all comments
      while char_pos <= Length(result) loop
         if Length(result) >= char_pos + 1 and then 
            (Wide_Element(result, char_pos) = '-' 
             and Wide_Element(result, char_pos  + 1) = '-')
         then  -- a comment - delete until end of line
            while Length(result) >= char_pos and then
                  (Wide_Element(result, char_pos) /= CR and 
                   Wide_Element(result, char_pos) /= LF) loop
               Delete(result, char_pos, 1);
            end loop;
         end if;
         char_pos := char_pos + 1;
      end loop;
      -- Second, simplify space characters
      char_pos := 1;
      while char_pos <= Length(result) loop
         if Is_Line_Terminator(Wide_Element(result, char_pos)) or
            Wide_Element(result, char_pos) = Tab or
            Wide_Element(result, char_pos) = SP
         then  -- found a space type character - reduce them
            while Length(result) >= char_pos + 1 and then
                  (Is_Line_Terminator(Wide_Element(result, char_pos + 1)) or
                   Wide_Element(result, char_pos + 1) = Tab or
                   Wide_Element(result, char_pos + 1) = SP)
            loop
               Delete(result, char_pos, 1);
            end loop;
            -- now ensure that the separator is, in fact, a space character
            -- (except when it is the last character in the whole macro)
            if Length(result) > char_pos then
               Amend(object => result, by => SP, position => char_pos);
            end if;
         end if;
         -- Make adjustments for the 'old' format of multiply and divide,
         -- substituting both / and * for the new format if encountered
         if Wide_Element(result, char_pos) = '*' and
            (Length(result) = char_pos or else
             Wide_Element(result, char_pos + 1) /= '*')
         then -- it is an old format multiply
            Amend(object => result, by => multiply_ch, position => char_pos);
         elsif Wide_Element(result, char_pos) = '/'
         then  -- it is old format for divide
            Amend(object => result, by => divide_ch, position => char_pos);
         end if;
         char_pos := char_pos + 1;
      end loop;
      -- Trim out any leading space character
      if Locate(' ',result) = 1 then
         Delete( result, 1, 1);
      end if;
      -- Finally, simplify around the command terminator (;}
      char_pos := 1;
      while char_pos <= Length(result) loop
         if Length(result) >= char_pos + 1 and then
            ((Wide_Element(result, char_pos) = SP and
              Wide_Element(result, char_pos + 1) = ';') or
             (Wide_Element(result, char_pos + 1) = SP and
              Wide_Element(result, char_pos) = ';'))
         then  -- remove the surplus space
            Delete(result, char_pos, 1);
            Amend(object => result, by => ';', position => char_pos);
         elsif Length(result) >= char_pos + 1 and then
            (Wide_Element(result, char_pos) = ';' and
             Wide_Element(result, char_pos + 1) = ';')
         then  -- this is an error condition
            raise BAD_MACRO_CODE;   
         end if;
         char_pos := char_pos + 1;
      end loop;
      for_macro := result;
      
   end Strip_Comments_And_Simplify_Spaces;

   procedure Load_Macro(into : out code_block; from : in text) is
      -- Work through the code block, loading in the instructions from the macro
      -- text.  Parameters such as character positions in a string register are
      -- treated as equations.  The equations are essentially a linked list of
      -- operations.  These are connected back to each instruction as required.
      -- If an error is encountered, then raise the BAD_MACRO_CODE exception.
      use Command_Stack;
      the_stack : Command_Stack.stack;
      
      function Reserved_Word_From_Text(for_word     : in text;
                                       or_parameter : in text) 
      return reserved_words is
      begin
         for item in reserved_words'Range loop
            if Length(all_reserved_words(item)) > 0 and then
               Pos(all_reserved_words(item), for_word) = 1
            then  -- found it (but it may be more than the reserved word)
               return item;
            end if;
         end loop;
         -- If we got here, then not a reserved word, could be an equation
         if Length(or_parameter) > 0 and  then 
            Pos(all_maths_operators(assign), or_parameter) > 0
         then  -- it's an equation
            return cEQUATION;
         else  -- If we got here, then not an equation - return null
            return cNull;
         end if;
      end Reserved_Word_From_Text;
      function Reserved_Word_To_Command(for_word     : in text;
                                        or_parameter : in text) 
      return command_set is
         the_reserved_word : reserved_words :=
                               Reserved_Word_From_Text(for_word, or_parameter);
      begin
         if the_reserved_word in command_set'First .. command_set'Last
         then 
            return the_reserved_word;
         else
            return cNull;
         end if;
      end Reserved_Word_To_Command;
      function To_Register(for_character : in wide_character) 
      return all_register_names is
      begin
         for item in all_register_names'Range loop
            if for_character = register_ids(item)
            then  -- found it
               return item;
            end if;
         end loop;
         -- If we got here, not a register name
         return const;
      end To_Register;
      function The_Operator(in_string : in text) return mathematical_operator is
         -- Get the operator from the string, noting that the operator must be
         -- at the start of the string, 'in_string'.
      begin
         for item in mathematical_operator'Range loop
            if Length(in_string) <= 3 and then
               all_maths_operators(item) = in_string
            then
               return item;  -- Found it
            elsif Length(in_string) >= 3 and then
               all_maths_operators(item) = Sub_String(in_string, 1, 3)
            then
               return item;  -- Found it within the string
            elsif Length(in_string) >= 2 and then
               all_maths_operators(item) = Sub_String(in_string, 1, 2)
            then
               return item;
            elsif Length(in_string) >= 1 and then
               all_maths_operators(item) = Sub_String(in_string, 1, 1)
            then
               return item;
            end if;
         end loop;
         --  If we got here, then there wasn't one
         return none;
      end The_Operator;
      function Operator_Position(in_string : in text;
                                 for_operator : mathematical_operator := none)
      return natural is
        -- Find the position of the operator in the 'in_string', but skip over
        -- any bracket sets such that operators within up-coming brackets are
        -- not the operator found.
        -- If for_operator is specified (i.e. not 'none'),  then look
        -- specifically for that operator
         result : natural := 0;
         operator : mathematical_operator;
         bracket_count : natural := 0;
      begin
         for posn in 1 .. Length(in_string) loop
            -- Work out if there is an operator or if this is a unary component
            if Wide_Element(in_string, posn) = '('
            then  -- starting a bracket, set up for skip to the end
               bracket_count := bracket_count + 1;
            elsif Wide_Element(in_string, posn) = ')'
            then  -- finishing a bracket set, skipping to end of this set
               bracket_count := bracket_count - 1;
            elsif bracket_count = 0
            then  -- not within a pair of brackets, so check for operator
               operator := 
                       The_Operator(in_string=>Sub_String(in_string, posn, 3));
               if operator = none then
                  operator:= 
                         The_Operator(in_string=>Sub_String(in_string,posn,2));
                  if operator = none then
                     operator := 
                           The_Operator(To_Text(Wide_Element(in_string,posn)));
                  end if;
               end if;
               if operator /= none
               then  -- check it is actually an operator and not part of a word
                  declare
                     operator_len : constant natural :=
                                     Length(all_maths_operators(operator));
                  begin -- check logical operators and the range condition 'IN'
                     if Length(in_string) > posn + operator_len and then
                        ((operator in logical_operator) or 
                         (operator = range_condition)) and then
                        (Wide_Element(in_string, posn+operator_len) /= ' ' and
                         Wide_Element(in_string, posn+operator_len) /= '(')
                     then  -- not a space or ( following, so not an operator
                        -- Error_Log.Debug_Data(at_level => 9, with_details => "Operator_Position: resetting the operator '" & all_maths_operators(operator) & "' to 'none' for string '" & in_string & "'.");
                        operator := none;
                     -- else
                        -- Error_Log.Debug_Data(at_level => 9, with_details => "Operator_Position: resetting the operator '" & all_maths_operators(operator) & "' is okay for string '" & in_string & "'.");
                     end if;
                  end;
               end if;
               if for_operator /= none and then operator /= for_operator then
                  operator := none;  -- not the operator we are looking for
               end if;
               if operator /=  none
               then   -- a multi-part component 
                  result := posn;
                  exit;  -- found one, so done
               end if;
            -- else, do nothing: just wait for bracket to close
            end if;
         end loop;
         return result;
         exception
            when Constraint_Error =>  -- unmatched close brackets
               Error_Log.Debug_Data(at_level => 9, 
                             with_details => "Load_Macro: raising exception " &
                                             "on instruction = 'EQUATION" &
                                             "' for unmatched brackets in '" &
                                             in_string & "'.");
               raise BAD_MACRO_CODE;
      end Operator_Position;
      use Strings_Functions;
      procedure Extract(bracketed_parameter : out text; from : in out text) is
         bracket_count : natural := 0;
         char_pos : natural := 1;
      begin
         Clear(bracketed_parameter);  -- to be sure, to be sure
         -- extract the parameter
         while char_pos <= Length(from) loop
            if Wide_Element(from, char_pos) = '('
            then
               bracket_count := bracket_count + 1;
               if bracket_count > 1
               then  -- not first one, add it in
                  bracketed_parameter := bracketed_parameter & 
                                         Wide_Element(from, char_pos);
               end if;
               Delete(from, 1, 1);  -- '('
            elsif Wide_Element(from, char_pos) = ')'
            then
               bracket_count := bracket_count - 1;
               if bracket_count = 0 then  -- last bracket so done
                  Delete(from, 1, 1);  -- ')'
                  exit;
               else  -- add it in
                  bracketed_parameter := bracketed_parameter & 
                                         Wide_Element(from, char_pos);
                  Delete(from, 1, 1);  -- and delte it out
               end if;
            elsif bracket_count > 0
            then  -- add the character in
               bracketed_parameter := bracketed_parameter & 
                                      Wide_Element(from, char_pos);
               Delete(from, 1, 1);  -- and delte it out
            else-- just move to start of brackets
               char_pos := char_pos + 1;
            end if;
         end loop;    
      end Extract;
      function Build_Equation(using_parameter: in text;
                              into_register : in all_register_names := const; 
                              of_type : in equation_format := mathematical;
                              treat_assignment_as_done : boolean := false)
      return equation_access is
        -- Build up the equation as a linked list of operations.
        -- Take care of brackets first before before proceeding with operators
        -- as they take precedence.  That within the brackets is treated as a
        -- sub-equation.
         parameter : text := Trim(using_parameter);
         lhs       : text;
         param     : text;
         the_reg   : all_register_names := const;
         operator  : mathematical_operator;
         result    : equation_access := null;
         the_eqn   : equation_access := null;
         eq_format : equation_format;
         br_format : equation_format;  -- bracket format (for brackets sub-eqn)
         passed_eq : boolean := treat_assignment_as_done;
                     -- have we passed the assignment (equals) operation?
      begin
         Error_Log.Debug_Data(at_level => 9, with_details => "Build_Equation: loading '" & using_parameter & "' into register '" & register_ids(into_register) & "', of type '" & of_type'Wide_Image & "'.");
         -- work through each component of the operators
         loop
            if Operator_Position(in_string => parameter) > 0
            then  -- strip out the left hand side
               lhs := Trim(Sub_String(parameter, 1, 
                                 Operator_Position(in_string => parameter)-1));
               Delete(parameter, 1, Operator_Position(in_string=>parameter)-1);
               operator := The_Operator(in_string=> parameter);
               Delete(parameter, 1, Length(all_maths_operators(operator)));
            else  -- this is the equation component
               lhs := parameter;
               Clear(parameter);
               operator := none;
            end if;
            parameter := Trim(parameter);
            Error_Log.Debug_Data(at_level => 9, with_details => "Build_Equation: L.H.S. = '" & lhs & "', parameter (R.H.S) = '" & parameter & "' and operator = '" & all_maths_operators(operator) & "'.");
            -- Sort out the operation type on this equation
            case operator is
               when assign              => eq_format := of_type;
               when numeric_operator    => eq_format := mathematical;
               when logical_operator    => eq_format := logical;
               when concat              => eq_format := textual;
               when comparison_operator => 
                  if Length(lhs) = 0 or operator = range_condition or 
                     the_eqn /= null
                  then  -- definitely logical
                     eq_format := logical;
                  else  -- cmmparison
                     eq_format := comparison;
                     passed_eq := true;  -- to be sure, to be sure!
                  end if;
               when none                =>
                  if Length(parameter) = 0 and
                     (Length(lhs) > 0 and then 
                      (Wide_Element(lhs,1) in '0'..'9' or
                                                    Wide_Element(lhs,1) = '.'))
                  then  -- definitely numerical
                     eq_format := mathematical;
                  else  -- use the specified format
                     eq_format := of_type;
                  end if;
               when others              => eq_format := of_type;
            end case;
            -- In the case of the operator being 'IN' and Length(lhs) = 0, it
            -- is not the operator, rather it is the function
            if operator = range_condition and Length(lhs) = 0
            then  -- add back in the 'IN'
               parameter := all_reserved_words(cIN) & ' ' & parameter;
            end if;
            -- Generate our special case equation formats
            if Length(lhs) > 0 and operator in comparison_operator and
                  operator /= range_condition and the_eqn = null
            then  -- make sure there is no change
               null;
            elsif Reserved_Word_From_Text(for_word=>lhs,or_parameter=>Clear) in
                                                     function_set'Range
            then
               eq_format := funct;
            elsif Reserved_Word_From_Text(for_word => parameter,
                                          or_parameter => Clear) = cIN
            then
               eq_format := funct;
            elsif Length(lhs) >= 3 and then Locate(''', within => lhs) = 1
            then  -- quoted character, so mathematical
               eq_format := mathematical;
            elsif Length(lhs) > 2 and then
                 (Wide_Element(lhs,1)='(' and Wide_Element(lhs,Length(lhs))=')')
            then  -- Bracketed () sub-equation
               br_format := eq_format;
               eq_format := bracketed;
            end if;
            -- Create our equation entry in the list for the current processing
            if the_eqn = null
            then  -- nothing specified yet
               the_eqn := new equation_type(eq_format);
               Error_Log.Debug_Data(at_level => 9, with_details => "Build_Equation: created new the_eqn.eq format = '" & eq_format'Wide_Image & "' and operator = '" & all_maths_operators(operator) & "' and R.H.S. = '" & parameter & "'.");
            else  -- part way through an equation creation
               the_eqn.equation := new equation_type(eq_format);
               the_eqn.equation.last_equ := the_eqn;
               the_eqn := the_eqn.equation;
               Error_Log.Debug_Data(at_level => 9, with_details => "Build_Equation: created the_eqn.equation with the_eqn.equation.eq format = '" & eq_format'Wide_Image & "' and operator = '" & all_maths_operators(operator) & "' and R.H.S. = '" & parameter & "', with its parent being '" & the_eqn.last_equ.eq'Wide_Image & "'.");
            end if;
            the_eqn.operator := operator;
            Error_Log.Debug_Data(at_level => 9, with_details => "Build_Equation: the_eqn.eq format = '" & eq_format'Wide_Image & "' and operator = '" & all_maths_operators(operator) & "' and R.H.S. = '" & parameter & "'.");
            -- Work out if the L.H.S. is a register
            if (Length(lhs) = 1 or else 
                (Length(lhs) > 1 and then Wide_Element(lhs,2)='(') or else
                (Length(lhs) > 1 and then Wide_Element(lhs,2)=''')) and then
               To_Register(for_character => Wide_Element(lhs,1)) /= const
            then  -- It's a register specification
               the_reg := To_Register(for_character => Wide_Element(lhs,1));
               the_eqn.register := the_reg;
               if passed_eq then
                  the_eqn.num_type := null_type;
               end if;
               if (Length(lhs) > 1 and then Wide_Element(lhs,2)='(')
               then  -- extract the position parameter
                  Delete(lhs, 1, 1);  -- 'R' (where R is the register)
                  Extract(bracketed_parameter => param, from => lhs);
                  the_eqn.reg_parm := Build_Equation(using_parameter=>param,
                                                    into_register => const, 
                                                    of_type => mathematical,
                                               treat_assignment_as_done=>true);
                  the_eqn.reg_parm.num_type := null_type;
                  Error_Log.Debug_Data(at_level => 9, with_details => "Build_Equation: Loaded bracketed parameter L.H.S. of register " & register_ids(the_eqn.register) & " of type " & the_eqn.eq'Wide_Image & " for parameter '" & param & "' as a sub-equation (against a register of const and of_type " & the_eqn.reg_parm.eq'Wide_Image & " with operator '" & all_maths_operators(the_eqn.operator) & "'.");
               elsif (Length(lhs) >1 and then Wide_Element(lhs,2)=''') and then
                     (Pos(all_attributes(cLength), Upper_Case(lhs)) = 2 or
                      Pos(all_attributes(cSize), Upper_Case(lhs)) = 2 or
                      Pos(all_attributes(cFirst), Upper_Case(lhs)) = 2 or
                      Pos(all_attributes(cLast), Upper_Case(lhs)) = 2)
               then -- register length attrubute
                  -- re-declare the_eqn as a param type, overwriting old data
                  if the_eqn.last_equ = null
                  then  -- simply recast as there is no prior equation part
                     the_eqn := new equation_type(funct);  -- replace
                  else  -- there's a prior equation part - tack onto that
                     the_eqn := the_eqn.last_equ;  -- tack back one step first
                     the_eqn.equation := new equation_type(funct);  -- replace
                     the_eqn.equation.last_equ := the_eqn;
                     the_eqn := the_eqn.equation;
                  end if;
                  the_eqn.operator := operator;
                  the_eqn.register := the_reg;
                  if passed_eq then
                     the_eqn.num_type := null_type;
                  end if;
                  -- and assign the function
                  if Pos(all_attributes(cLength), Upper_Case(lhs)) = 2
                  then
                     the_eqn.f_type:= cLength;
                  elsif Pos(all_attributes(cSize), Upper_Case(lhs)) = 2
                  then
                     the_eqn.f_type:= cSize;
                  elsif Pos(all_attributes(cFirst), Upper_Case(lhs)) = 2
                  then
                     the_eqn.f_type:= cFirst;
                  elsif Pos(all_attributes(cLast), Upper_Case(lhs)) = 2
                  then
                     the_eqn.f_type:= cLast;
                  end if;
                  Error_Log.Debug_Data(at_level => 9, with_details => "Build_Equation: Attribute function of register " & register_ids(the_eqn.register) & all_attributes(the_eqn.f_type) & " with operator '" & all_maths_operators(the_eqn.operator) & "'.");
               else
                  Error_Log.Debug_Data(at_level => 9, with_details => "Build_Equation: register " & register_ids(the_eqn.register) & " specified with operator '" & all_maths_operators(the_eqn.operator) & "' of type '" & eq_format'Wide_Image & "'.");
               end if;
               -- Check if this is really the IN function
               if operator = range_condition
               then  -- actually the IN function - set it up
                  parameter := all_reserved_words(cIN) & ' ' & parameter;
                  the_eqn.equation:= Build_Equation(using_parameter=>parameter,
                                                   into_register => const, 
                                                   of_type => logical,
                                               treat_assignment_as_done=>true);
                  -- Because we are cecking a register, reach in to link it
                  the_eqn.equation.last_equ := the_eqn;
                  Clear(parameter);  -- as it is now used up
                  Error_Log.Debug_Data(at_level => 9, with_details => "Build_Equation: built sub-equation for range condition '" & all_maths_operators(operator) & "' with  register = " & register_ids(the_eqn.register) & " and R.H.S = '" & parameter & "' and is of type '" & eq_format'Wide_Image & "'.");
               elsif operator in comparison_operator and
                  operator /= range_condition and the_eqn.last_equ = null
               then  -- comparison operation with L.H.S. being a register
                  -- Assign 2 parts to a logical result
                  the_eqn.register := into_register;
                  -- L.H.S. is a register
                  the_eqn.c_lhs := new equation_type(mathematical);
                  the_eqn.c_lhs.register := the_reg;
                  the_eqn.num_type := null_type;
                  -- R.H.S is whatever the R.H.S. parameter is
                  the_eqn.c_rhs:=Build_Equation(using_parameter=>parameter,
                                               into_register => const, 
                                               of_type => mathematical,
                                               treat_assignment_as_done=>true);
                  Clear(parameter);  -- since we loaded it
                  Error_Log.Debug_Data(at_level => 9, with_details => "Build_Equation: built '" & all_maths_operators(the_eqn.operator) & "' between  L.H.S. register = " & register_ids(the_eqn.c_lhs.register) & " and R.H.S = '" & parameter & "' and is of type '" & eq_format'Wide_Image & "'.");
               end if;
            elsif Length(lhs) = 0 and operator = assign
            then  -- at the start, so assign to the specified register
               the_eqn.register := into_register;
               Error_Log.Debug_Data(at_level => 9, with_details => "Build_Equation: Building a sub-equation upon the operator '" & all_maths_operators(the_eqn.operator) & "' whith  register = " & register_ids(the_eqn.register) & " and L.H.S. = '" & lhs  & "' and R.H.S = '" & parameter & "' and is of type '" & eq_format'Wide_Image & "'.");
               the_eqn.equation := Build_Equation(using_parameter=>parameter,
                                                into_register => const, 
                                                of_type => of_type,
                                               treat_assignment_as_done=>true);
               -- Because we are loading a register, reach in to link it
               passed_eq := true;  -- now seen the equate (assign) operation
               Clear(parameter);  -- since we loaded it
            elsif Length(lhs) > 0 and operator in comparison_operator and
                  operator /= range_condition and the_eqn.last_equ = null
            then  -- at the start, so assign 2 parts to a logical result
               the_eqn.register := into_register;
               the_eqn.c_lhs := Build_Equation(using_parameter=>lhs,
                                                into_register => const, 
                                                of_type => mathematical,
                                               treat_assignment_as_done=>true);
               the_eqn.c_rhs := Build_Equation(using_parameter=>parameter,
                                                into_register => const, 
                                                of_type => mathematical,
                                               treat_assignment_as_done=>true);
               Clear(parameter);  -- since we loaded it
            elsif Reserved_Word_From_Text(for_word=>lhs,or_parameter=>Clear)
                        in function_set'Range
            then  -- these are functions to be dealt with
               the_eqn.register := into_register;
               if passed_eq then
                  the_eqn.num_type := null_type;
               end if;
               the_eqn.operator := operator;
               the_eqn.f_type:= Reserved_Word_From_Text(for_word=>lhs,
                                                       or_parameter=>Clear);
               Error_Log.Debug_Data(at_level => 9, with_details => "Build_Equation: Function (" & all_reserved_words(the_eqn.f_type) & ") of register '" & register_ids(the_eqn.register) & "' with operator '" & all_maths_operators(the_eqn.operator) & "'.");
               -- Delete out the reserved word
               Delete(lhs, 1, Length(all_reserved_words(the_eqn.f_type)));
               -- Get the parameters (comma separated) within the function's
               -- brackets
               Extract(bracketed_parameter => param, from => lhs);
               declare
                  param_list : text_array := Disassemble(from_string => param, 
                                                         separated_by=> ',');
               begin
                  the_eqn.f_param1 := 
                                 Build_Equation(using_parameter=>param_list(1),
                                                into_register => const, 
                                                of_type => mathematical,
                                               treat_assignment_as_done=>true);
                  if param_list'Last > 1 then  -- there's a second parameter
                     the_eqn.f_param2 := 
                                 Build_Equation(using_parameter=>param_list(2),
                                                into_register => const, 
                                                of_type => mathematical,
                                               treat_assignment_as_done=>true);
                  end if;
               end;
            elsif Reserved_Word_From_Text(for_word => parameter,
                                          or_parameter => Clear) = cIN
            then  -- these are functions to be dealt with
               the_eqn.register := into_register;
               the_eqn.operator := operator;
               the_eqn.f_type:= cIN;
               Error_Log.Debug_Data(at_level => 9, with_details => "Build_Equation: Function (" & all_reserved_words(the_eqn.f_type) & ") of register '" & register_ids(the_eqn.register) & "' with operator '" & all_maths_operators(the_eqn.operator) & "'.");
               -- Delete out the reserved word
               Delete(parameter, 1, 
                      Length(all_reserved_words(the_eqn.f_type))+1);
                  -- strip out any outside brackets
               if Wide_Element(parameter, 1) = '(' and 
                     Wide_Element(parameter, Length(parameter)) = ')'
                  then  -- strip out the brackets (not required here now)
                  Delete(parameter, Length(parameter), 1);  -- ')'
                  Delete(parameter, 1, 1);                  -- '('
               end if;
               Error_Log.Debug_Data(at_level => 9, with_details => "Build_Equation: Function (" & all_reserved_words(the_eqn.f_type) & ") with parameter '" & parameter & "'.");
               lhs := Trim(Sub_String(parameter, 1, 
                                 Operator_Position(in_string => parameter)-1));
               Delete(parameter, 1, Operator_Position(in_string=>parameter)-1);
               operator := The_Operator(in_string=> parameter);
               Delete(parameter, 1, Length(all_maths_operators(operator)));
               the_eqn.f_param1:= Build_Equation(using_parameter=>lhs,
                                                    into_register => const, 
                                                    of_type => mathematical,
                                               treat_assignment_as_done=>true);
               the_eqn.f_param2:= Build_Equation(using_parameter=>parameter,
                                                    into_register => const, 
                                                    of_type => mathematical,
                                               treat_assignment_as_done=>true);
               Clear(parameter);
               if operator /= ellipses then -- error: wrong operator
                  Error_Log.Debug_Data(at_level => 9, 
                             with_details => "Load_Macro: raising exception " &
                                             "on instruction = 'EQUATION" &
                                             "' for incorrect operator (" &
                                             all_maths_operators(operator) &
                                             ") for function 'IN'.");
                  raise BAD_MACRO_CODE;
               end if;
            elsif Length(lhs) >= 3 and then Locate(''', within => lhs) = 1-- and then 
                  -- Wide_Element(lhs, 3) = '''
            then  -- it is a quoted character - assume mathematical
               the_eqn.operator := operator;
               the_eqn.num_type := character_type;
               the_eqn.m_const := 
                           long_float(Wide_Character'Pos(Wide_Element(lhs,2)));
               Error_Log.Debug_Data(at_level => 9, with_details => "Build_Equation: quoted character (" & lhs & ") into nummerical representation (" & Put_Into_String(integer(the_eqn.m_const)) & ") of character.");
            elsif Wide_Element(lhs,1)='(' and Wide_Element(lhs,Length(lhs))=')'
            then  -- Bracketed () sub-equation
               Extract(bracketed_parameter => param, from => lhs);
               the_eqn.register := into_register;
               the_eqn.operator := operator;
               if not passed_eq then
                  the_eqn.num_type := integer_type;
               end if;
               Error_Log.Debug_Data(at_level => 9, with_details => "Build_Equation: going into bracketed (" & param & " with format " & eq_format'Wide_Image & ") into no register(i.e. const) of type eq_format (" & br_format'Wide_Image & ").");
               the_eqn.b_equation := Build_Equation(using_parameter=>param,
                                                   into_register => const, 
                                                   of_type => br_format,
                                               treat_assignment_as_done=>true);
               if the_eqn.b_equation.num_type = float_type then
                  the_eqn.b_equation.num_type := integer_type;
               end if;
               Error_Log.Debug_Data(at_level => 9, with_details => "Build_Equation: Built bracketed (" & the_eqn.b_equation.eq'Wide_Image & ") into register(" & register_ids(the_eqn.b_equation.register) & ") with operator " & all_maths_operators(the_eqn.b_equation.operator) & " of num type (" & the_eqn.b_equation.num_type'Wide_Image & "). Our (bracketed level) operator = '" & all_maths_operators(the_eqn.operator) & "'.");
            else  -- processing the line
               -- work out what the L.H.S. is (register or number or value)
               -- and assign to the the_eqn
               Error_Log.Debug_Data(at_level => 9, with_details => "Build_Equation: ELSE equation of register '" & register_ids(the_eqn.register) & "' of for eq_format = '" & eq_format'Wide_Image & ".");
               case eq_format is 
                  when textual =>
                     the_eqn.t_const := lhs;
                     if operator = concat then
                        the_eqn.equation := 
                                  Build_Equation(using_parameter=>parameter,
                                                into_register => into_register,
                                                of_type => eq_format,
                                               treat_assignment_as_done=>true);
                        the_eqn.equation.last_equ := the_eqn;
                        Clear(parameter);
                     end if;
                  when mathematical =>
                     -- Implement order of precedence, then initiate operations
                     if the_eqn.register = const
                     then  -- it isn't a register, so it's a number
                        the_eqn.m_const := Get_Long_Float_From_String(lhs);
                        Error_Log.Debug_Data(at_level => 9, with_details => "Build_Equation: Converted string '" & lhs & "' into " & Put_Into_String(the_eqn.m_const,3) & " .");
                     end if;
                     if Length(parameter) > 0
                     then  -- more of the equation to go
                        Error_Log.Debug_Data(at_level => 9, with_details => "Build_Equation: Getting the equation for = '" & parameter & "' for register '" & register_ids(into_register) & "' of type '" & eq_format'Wide_Image & "'.");
                        the_eqn.equation := 
                                  Build_Equation(using_parameter=>parameter,
                                                into_register => into_register, 
                                                of_type => eq_format,
                                               treat_assignment_as_done=>true);
                        the_eqn.equation.last_equ := the_eqn;
                        Clear(parameter);
                     end if;
                  when logical =>
                     if the_eqn.register = const
                     then  -- it isn't a register, so it's a value
                        the_eqn.l_const := (Upper_Case(lhs) /= Value("FALSE"));
                        Error_Log.Debug_Data(at_level => 9, with_details => "Build_Equation: the_eqn.l_const = '" & the_eqn.l_const'Wide_Image & " .");
                     end if;
                     if Length(parameter) > 0
                     then  -- more of the equation to go
                        Error_Log.Debug_Data(at_level => 9, with_details => "Build_Equation: Getting the equation for = '" & parameter & "' for register '" & register_ids(into_register) & "' of type '" & eq_format'Wide_Image & "'.");
                        the_eqn.equation := 
                                  Build_Equation(using_parameter=>parameter,
                                                into_register => into_register, 
                                                of_type => eq_format,
                                               treat_assignment_as_done=>true);
                        the_eqn.equation.last_equ := the_eqn;
                        Clear(parameter);
                     end if;
                  when others =>
                     Error_Log.Debug_Data(at_level => 9, with_details => "Build_Equation: Got eq_format = Others for parameter '" & parameter & "' for register '" & register_ids(into_register) & "' of_type = '" & of_type'Wide_Image & "'.");
                     null;
               end case;
            end if;
            -- Set up the result to be at the head of the linked list.  We do
            -- this at the end of the loop in caes the_eqn gets recast.
            if result = null
            then  -- this is the head of the equation linked list
               result := the_eqn;  -- result set to head of the linked list
            end if;
            exit when Length(parameter) = 0;
         end loop;
         -- if there is any parameter left, operate on it
         return  result;
         exception
            when No_Number =>  -- number expected but not found (bad format)
               Error_Log.Debug_Data(at_level => 9, 
                             with_details => "Load_Macro: raising exception " &
                                             "on instruction = 'EQUATION" &
                                             "' for mal-formed parameters ('" &
                                             lhs & "', '" & parameter & "').");
               raise BAD_MACRO_CODE;
      end Build_Equation;
      function  Set_Order_Of_Precedence(for_parameter: in text; 
                                        at_command : command_set := cNull) 
      return text is
        -- Inserts brackets to define the order of precedence
         function The_Text_Is(a_number : in text) return boolean is
         begin
            if Length(a_number) = 0 then  -- it's nothing, not even a number
               return false;
            else
               for posn in 1 .. Length(a_number)loop
                  if not (Wide_Element(a_number, posn) in '0' .. '9') and
                    Wide_Element(a_number, posn) /= '.'
                  then  -- not a number
                     return false;
                  end if;
               end loop;
               return true;
            end if;
         end The_Text_Is;
         function Bracket(for_the_operator  : in mathematical_operator;
                         for_parameter : in text) return text is
           -- Bracket either side of the operator but note that there might be
           -- more than one of them.  So the left side of the operator is in
           -- brackets, as is the right side, but the operator is not.
            operator     : mathematical_operator renames for_the_operator;
            result       : text := for_parameter;
            lhs, rhs     : text;
            the_position : natural;
            operator_len : constant natural := 
                                Length(all_maths_operators(operator));
         begin
            rhs := for_parameter;  -- starting situation
            the_position := Operator_Position(in_string => rhs, 
                                             for_operator => operator);
            if the_position > 0 and then (operator_len > 1 or else
               (operator_len = 1 and
               The_Operator(in_string=>Sub_String(rhs,the_position-1,2))=none))
            then  -- there is a legitimate operator, so brackets are required
               lhs := Trim(Sub_String(rhs, 1, the_position - 1));-- extract lhs
               if not (Wide_Element(lhs, 1) = '(' and 
                      Wide_Element(lhs, Length(lhs)) = ')') and
                    not The_Text_Is(a_number => lhs)
               then  -- not already bracketed
                  if not (operator = range_condition and then
                          ((Length(lhs) = 1 or 
                            (Length(lhs) > 1 and Wide_Element(lhs,2) = '('))
                           and then 
                            To_Register(Wide_Element(lhs,1)) in register_name))
                  then -- L.H.S. is not a register specification
                     lhs := '(' & lhs & ')';
                  end if;
               end if;
               rhs := Trim(Sub_String(rhs, the_position + operator_len, 
                                     Length(rhs)-operator_len-the_position+1));
               Error_Log.Debug_Data(at_level => 9, with_details => "Bracket: L.H.S. = '" & lhs & "' and R.H.S = '" & rhs & "' with operator of '" & all_maths_operators(operator) & "'.");
               the_position := Operator_Position(in_string => rhs, 
                                                for_operator => operator);
               if the_position > 0
               then
                  rhs := Trim(Bracket(for_the_operator, for_parameter => rhs));
               else
                  if not (Wide_Element(rhs, 1) = '(' and 
                         Wide_Element(rhs, Length(rhs)) = ')') and
                    not The_Text_Is(a_number => rhs)
                  then  -- not already bracketed
                     rhs := '(' & rhs & ')';
                  end if;
               end if;
               result:=lhs & ' ' &  all_maths_operators(operator) & ' ' &  rhs;
            end if;
            return result;
         end Bracket;
         function Bracket_Arithmetic(for_parameter : in text) return text is
           -- Bracket around the operator but note that there might be
           -- more than one of them.  So the bracket includes the item to the
           -- left and the item to the right and  the operator.
           -- Here, the operator is specifically multiply and divide.
            result          : text;
            lhs             : text;
            word            : text;
            current_char    : wide_character := ' ';
            last_char       : wide_character;
            opening_bracket : boolean := false;
            closing_bracket : boolean := false;
            closed_bracket  : boolean := false;
            closed_position : natural := 0;
            started_matching: boolean := false;
            find_bracket    : natural := 0;
            in_brackets     : natural := 0;  -- brackets count in macro source
            in_function     : natural := 0;
            function_bracket: natural := 0;
         begin
            Clear(result);
            Clear(lhs);
            Clear(word);
            for char_pos in 1 .. Length(for_parameter) loop
               last_char := current_char;
               current_char := Wide_Element(for_parameter, char_pos);
               word := word & current_char;
               if current_char = '('
               then  -- increment the bracket counter
                  in_brackets := in_brackets + 1;
                  if in_function > 0
                  then
                     function_bracket := function_bracket + 1;
                  end if;
               elsif current_char = ')'
               then  -- decrement the current counter
                  in_brackets := in_brackets - 1;
                  if in_function > 0
                  then
                     function_bracket := function_bracket - 1;
                     if function_bracket = 0
                     then  -- decrement function counter
                        Error_Log.Debug_Data(at_level => 9, with_details => "Bracket_Arithmetic: Finishing on in_function for result = '" & result & "' and lhs = '" & lhs & "' at '" & current_char & "'.");
                        in_function := in_function - 1;
                        result := result & lhs;
                        Clear(lhs);
                     end if;
                  end if;
               elsif current_char = ' '
               then  -- reset the word
                  Clear(word);
               elsif Reserved_Word_From_Text(for_word => word, 
                                           or_parameter=>Clear) in 
                                        function_set'First .. function_set'Last
               then  -- Just loaded a reserved word into result
                  -- count it like a bracket
                  Error_Log.Debug_Data(at_level => 9, with_details => "Bracket_Arithmetic: Starting on in_function for result = '" & result & "' and lhs = '" & lhs & "' at '" & current_char & "'.");
                  in_function := in_function + 1;
                  function_bracket := 0;
                  Clear(word);
               end if;
               if not opening_bracket
               then  -- not potentially needing to open a bracket
                  result := result & current_char;
               else  -- may need to open a bracket
                  lhs := lhs & current_char;
               end if;
               if not (opening_bracket or closing_bracket) and current_char=' '
                  and in_brackets = 0  -- don't do this if brackets supplied
                  and in_function = 0  -- and also not if in a function
               then  -- At a space character, so start tracking
                  opening_bracket := true;
                  if Length(lhs) = 0 and Locate(' ', within=>result) = char_pos
                  then  -- we appear to be at the start
                     lhs := result;
                     Clear(result);
                  else  -- process as per normal for restarting tracking
                     Clear(lhs);
                  end if;
                  Error_Log.Debug_Data(at_level => 9, with_details => "Bracket_Arithmetic: opening and closing bracket were false, on result '" & result & "' and lhs = '" & lhs & "' at '" & current_char & "', set opening_bracket = true and cleared lhs.");
               elsif opening_bracket and 
                     (current_char = '+' or current_char = '-')
               then  -- At an operator, so restart tracking
                  result := result & lhs;
                  Clear(lhs);
                  closed_bracket := false;  -- in case it was set
               elsif opening_bracket and in_function = 0 and
                     (current_char = multiply_ch or current_char = divide_ch)
               then  -- got to either multiply or divide
                  Error_Log.Debug_Data(at_level => 9, with_details => "Bracket_Arithmetic: opening_bracket was true, setting result (" & result & ") to '" & result & '(' & lhs & "' at '" & current_char & "' and setting closing_bracket = true and opening_bracket = false and clearing lhs (" & lhs & ").");
                  if (Length(result) > 0 and then
                      (Wide_Element(result, Length(result)) = ')' or
                       (Length(result) > 1 and then
                        (Wide_Element(result, Length(result)) = ' ' and
                         Wide_Element(result, Length(result)-1) = ')')))) or
                     (Length(lhs) > 0 and then
                      (Wide_Element(lhs, Length(lhs)) = ')' or
                       (Length(lhs) > 1 and then Wide_Element(lhs, 1) = ')')))
                  then  -- there's a close bracket prior to multiply or divide
                     result := result & lhs;
                     Error_Log.Debug_Data(at_level => 9, with_details => "Bracket_Arithmetic: there's a close bracket prior to multiply or divide, on result '" & result & "' and lhs = '" & lhs & "' at '" & current_char & "'.");
                     started_matching := false;
                     find_bracket := 0;
                     for res_pos in reverse 1 .. Length(result) loop
                        if Wide_Element(result, res_pos) = ')'
                        then
                           find_bracket := find_bracket + 1;
                           started_matching := true;
                        elsif Wide_Element(result, res_pos) = '('
                        then
                           find_bracket := find_bracket - 1;
                        end if;
                        Error_Log.Debug_Data(at_level => 9, with_details => "Bracket_Arithmetic: there's a close bracket prior to multiply or divide, res_pos = " & Put_Into_String(res_pos) & " and find_bracket = = " & Put_Into_String(find_bracket) & " with started_matching being " & started_matching'Wide_Image & ".");
                        if started_matching and find_bracket = 0
                        then  -- may be at position ot insert the open bracket
                           if res_pos = 1 or else
                              Wide_Element(result, res_pos) = ' ' or else
                              (res_pos > 1 and then not
                               (Wide_Element(result, res_pos - 1) in 'A'..'Z'))
                           then  -- now at position to insert the open bracket
                              if res_pos > 1
                              then
                                 result:=Sub_String(result,1,res_pos-1) & '(' &
                                         Sub_String(result, res_pos, 
                                                    Length(result)-res_pos+1);
                              else  -- insert at the beginning
                                 result := '(' & result;
                              end if;
                              exit;  -- done our job now
                           end if;
                        end if;
                     end loop;
                  else  -- no brackets prior, okay to open brackets
                     if Length(lhs)>1 and Wide_Element(lhs,1) = ' '
                     then  -- put bracket after the space character
                        result := result & " (" & Left_Trim(lhs);
                     else  -- no problem, just insert the bracket
                        result := result & '(' & lhs;
                     end if;
                  end if;
                  closing_bracket := true;
                  opening_bracket := false;
                  closed_bracket  := false;
                  Clear(lhs);
               elsif in_brackets = 0 and in_function = 0 and
                     not (opening_bracket or closing_bracket) and 
                     (current_char = multiply_ch or current_char = divide_ch)
               then  -- got to either multiply or divide near start of string?
                  if closed_bracket
                  then  -- still multiplying and dividing
                     closing_bracket := true;  -- reset it back to on
                     Delete(result, closed_position, 1); -- whip out old ')'
                     closed_bracket := false;  -- reset our status
                  else  -- actually near start of string
                     result := '(' & result;
                     Error_Log.Debug_Data(at_level => 9, with_details => "Bracket_Arithmetic: opening and closing bracket were false, set result to '" & result & "' at '" & Wide_Element(for_parameter, char_pos-1) & Wide_Element(for_parameter, char_pos) & "' and set closing_bracket = true.");
                     closing_bracket := true;
                  end if;
               elsif (closing_bracket and in_brackets = 0 and in_function = 0)
                     and then (current_char = ' ' and not
                            (last_char = multiply_ch or last_char = divide_ch))
               then  -- found the other side of the operator's operation
                  Error_Log.Debug_Data(at_level => 9, with_details => "Bracket_Arithmetic: bracketing closing bracket on result '" & result & "' at '" & Wide_Element(for_parameter, char_pos-1) & Wide_Element(for_parameter, char_pos) & "'.");
                  closing_bracket := false;
                  Delete(result, Length(result), 1);  -- whip out the space
                  closed_position := Length(result) + 1;
                  result := result & ") ";
                  closed_bracket := true;
               elsif (closing_bracket and in_brackets = 0 and in_function = 0)
                     and then (current_char = '+' or current_char = '-')
               then  -- found the other side of the operator's operation
                  closing_bracket := false;
                  Delete(result, Length(result), 1);  -- whip out the operator
                  Error_Log.Debug_Data(at_level => 9, with_details => "Bracket_Arithmetic: closing_bracket = true and +/-, setting result (" & result & current_char & ") to '" & result & ")" & current_char & "' at '" & current_char & "'.");
                  result:= result & ")" & current_char;
                  closed_bracket := false;
               end if;
            end loop;
            if Length(lhs) > 0 then
               result := result & lhs;
            end if;
            if closing_bracket  -- a check on whether bracket closed
            then  -- got to the end of the string, put the bracket in
               result := result & ')';
            end if;
            return result;
         end Bracket_Arithmetic;
         procedure Remove_Extraneous_Brackets(on : in out text; 
                                              at_command:command_set:=cNull) is
            -- If the bracket is on the outside, then strip it off
            in_bracket : natural := 0;
         begin
            if Wide_Element(on, 1) = '(' and Wide_Element(on, Length(on)) = ')'
               and at_command /= cDELETE
            then  -- check that these are matching brackets, strip if so
               in_bracket := 1;
               for posn in 2 .. Length(on) loop
                  -- count the brackets
                  if Wide_Element(on, posn) = '('
                  then
                     in_bracket := in_bracket + 1;
                  elsif Wide_Element(on, posn) = ')'
                  then
                     in_bracket := in_bracket - 1;
                  end if;
                  -- work out if the brackets are on the outside
                  if in_bracket = 0 and posn < Length(on)
                  then  -- they are not on the outside
                     exit;
                  elsif in_bracket = 0 and posn = Length(on)
                  then  -- these brackets are on the outside
                     Delete(on, 1, 1);  -- strip out starting bracket
                     Delete(on, Length(on), 1);  -- strip out last bracket
                  end if;
               end loop;
            end if;
         end Remove_Extraneous_Brackets;
         parameter : text := for_parameter;
         lhs       : text;
         rhs       : text;
         assignment : text := all_maths_operators(assign);
         assign_len : constant natural := Length(assignment);
         -- operator  : comparison_operator;
         result    : text := for_parameter;
      begin  -- Set_Order_Of_Precedence
         -- first, remove the assignment operator (if any) from the situation
         if Length(result) >= assign_len and then
               Sub_String(result, 1, assign_len) = assignment
         then  -- strip out the assignment operator temporarily
            Delete(result, 1, assign_len);
            if Length(result) > 0 and then Wide_Element(result, 1) = ' '
            then  -- move the space character across too
               assignment := assignment & ' ';
               Delete(result, 1, 1);
            end if;
         else
            Clear(assignment);
         end if;
         -- Logical AND, OR take top level precedence
         result:= Bracket(for_the_operator=>logical_and,for_parameter=>result);
         result:= Bracket(for_the_operator=>logical_or, for_parameter=>result);
         Error_Log.Debug_Data(at_level => 9, with_details => "Set_Order_Of_Precedence: bracketing logical operators results in '" & result & "'.");
         -- Logical NOT also takes top level precedence and is a unary operator
         null;
         -- Comparison is the next level of precedence
         for item in comparison_operator loop
            result := Bracket(for_the_operator=> item, for_parameter=> result);
         end loop;
         -- Multiplication and division are the next level of precedence
         result := Bracket_Arithmetic(for_parameter=>result);
         Remove_Extraneous_Brackets(on => result, at_command => at_command);
         -- Now add the assignment operator (if any) back in)
         result := assignment & result;
         Error_Log.Debug_Data(at_level => 9, with_details => "Set_Order_Of_Precedence: bracketing multiply and divide operators results in '" & result & "'.");
         return result;
      end Set_Order_Of_Precedence;
      procedure Link(the_block : in out code_block; to : in link_to_positions;
                     for_current : in out code_block) is
         -- Chain from the current (soon to be previous) block into the_block
         -- via the current block's specified linking point
      begin
         case to is
            when proc_body    => for_current.proc_body    := the_block;
            when then_part    => for_current.then_part    := the_block;
            when else_part    => for_current.else_part    := the_block; 
            when else_parent  => for_current.else_parent  := the_block; 
            when else_block   => for_current.else_block   := the_block; 
            when ethen_part   => for_current.ethen_part   := the_block; 
            when parent_if    => for_current.parent_if    := the_block; 
            when eelse_part   => for_current.eelse_part   := the_block;
            when for_block    => for_current.for_block    := the_block; 
            when loop_block   => for_current.loop_block   := the_block; 
            when exit_point   => for_current.exit_point   := the_block;
            when next_command => for_current.next_command := the_block;
         end case;
      end Link;
      macro : text := from;  -- a working copy of the macro in simplified form
      char_pos    : positive := 1;
      the_block   : code_block;
      -----------------------------------------------------
      procedure Print(the_equation : in equation_access) is
         function Print(our_equation : in equation_access;
                        is_first : in boolean := false) return text is
            current : equation_access := our_equation;
            the_first : boolean := is_first;
            eqn : text;
         begin
            Clear(eqn);
            while current /= null loop
               if not the_first and then current.register /= const
               then
                  if Length(eqn) > 0 then Append(wide_tail=>' ', to=>eqn); end if;
                  eqn := eqn & register_ids(current.register);
                  if current.reg_parm /= null then
                     eqn := eqn & '(' & Print(current.reg_parm) & ')';
                  end if;
               end if;
               the_first := false;
               eqn := eqn & " '" & all_maths_operators(current.operator) & "' {";
               case current.eq is
                  when mathematical => eqn := eqn & "M[" & Put_Into_String(current.m_const,3) & ']';
                  when logical => eqn := eqn & "L[" & current.l_const'Wide_Image & ']';
                  when textual => eqn := eqn & "T[" & current.t_const & ']';
                  when bracketed => eqn := eqn & '(' & Print(our_equation => current.b_equation) & ')'; 
                  when funct => 
                     eqn := eqn & all_reserved_words(current.f_type) & '(' &
                            Print(current.f_param1) & ',' & Print(current.f_param2) & ')';
                  when comparison => 
                     eqn := eqn & "C[" & current.c_const'Wide_Image & "] (" & 
                            Print(current.c_lhs) & ',' & Print(current.c_rhs) & ')';
                  when none => null;
               end case;
               eqn := eqn & '}';
               current := current.equation;
            end loop;
            return eqn;
         end Print;
         reg : text;
         eqn : text;
      begin
         if the_equation.register /= const
         then
            reg := To_Text(register_ids(the_equation.register));
            if the_equation.reg_parm /= null then
               reg := reg & '(' & Print(the_equation.reg_parm) & ')';
            end if;
         else
            Clear(reg);
         end if;
         eqn := Print(the_equation, true);
         Error_Log.Debug_Data(at_level => 9, with_details => "Equation: Register " & reg & eqn & "'.");
      end Print;
      -----------------------------------------------------
   begin  ---*** Load_Macro ***---
      Error_Log.Debug_Data(at_level => 6, 
                           with_details => "Load_Macro: Start" & ".  Macro text is '" & from & "'.");
      -- Ensure that this is a new macro being loaded
      into := null;
      -- First, make splitting up easier by inserting a command terminator
      -- after IS, LOOP (if none already, i.e. if after FOR), THEN
      -- Start with IS
      while Pos(SP&all_reserved_words(cIS)&SP, macro, starting_at=>char_pos)>0
      loop
         char_pos := Pos(SP&all_reserved_words(cIS)&SP, macro, starting_at => char_pos) + 4;
         Insert(macro, char_pos, ";");
         char_pos := char_pos + 1;
      end loop;
      -- Now do THEN, but place it after 'THEN'
      char_pos := 1;
      while Pos(all_reserved_words(cTHEN),macro,starting_at=>char_pos) > 0 loop
         char_pos:= Pos(all_reserved_words(cTHEN),macro,starting_at=>char_pos);
         Insert(macro, char_pos + 4, ";");
         char_pos := char_pos + 5;
      end loop;
      -- Now do ELSE, but place it after 'ELSE'
      char_pos := 1;
      while Pos(all_reserved_words(cELSE),macro,starting_at=>char_pos) > 0 loop
         char_pos:= Pos(all_reserved_words(cELSE),macro,starting_at=>char_pos);
         Insert(macro, char_pos + 4, ";");
         char_pos := char_pos + 5;
      end loop;
      -- Now do LOOP (after FOR, i.e. don't do END LOOP)
      char_pos := 1;
      while Pos(all_reserved_words(cLOOP),macro,starting_at=>char_pos) > 0 loop
         char_pos:= Pos(all_reserved_words(cLOOP),macro,starting_at=>char_pos);
         if Sub_String(macro, char_pos - 4, 3) /= all_reserved_words(cEND) then
            Insert(macro, char_pos + 5, ";");
         end if;
         char_pos := char_pos + 6;
      end loop;
      -- Now split the macro into individual commands
      declare
         use Ada.Wide_Characters.Handling;
         current_block: code_block := null;
         link_to      : link_to_positions := next_command;
         instructions : text_array := Disassemble(from_string => macro, 
                                                  separated_by=> ';');
         instruction  : text;
         command      : text;
         parameters   : text;
         fleft,fright : text;  -- for FOR loop parameters split
         parent_data  : stack_data;
      begin
         for num in instructions'Range loop
         -- Get the macro command and operate on it
            instruction := Trim(instructions(num));
            if Length(instruction) > 0 and then 
               not Is_Line_Terminator(Wide_Element(instruction, 1))
            then  -- an instruction to process (not a blank line)
               if Locate(fragment=>' ', within=>instruction) > 0
               then  -- there are parts to this instruction
                  command:=Sub_String(from=>instruction, starting_at=>1, 
                                    for_characters=>Locate(' ',instruction)-1);
               else  -- this insruction is just a command
                  command:=instruction;
               end if;
               if command /= instruction
               then  -- suck out the parameters
                  parameters:= Left_Trim(
                                Sub_String(from => instruction, 
                                           starting_at => Length(command)+1,
                                           for_characters=>Length(instruction)-
                                                             Length(command)));
               else
                  Clear(parameters);
               end if;
               Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: at instruction number " & Put_Into_String(num) & ", instruction = '" & instruction & "', command = '" & command & "' and parameters = '" & parameters & "'.");
               -- load the command in the appropriate place
               case Reserved_Word_To_Command(for_word=>command, 
                                             or_parameter=> parameters) is
                  when cPROCEDURE =>
                        -- Set up the code block for the procedure
                     the_block := new cmd_block(cPROCEDURE);
                     the_block.last_command := current_block;
                     -- the_block := new_block;
                     if into = null then -- at start of the tree
                        Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: At start of tree so setting into at the_block (i.e. the start).");
                        into := the_block;  -- pointer assignment
                     end if;
                        -- Remove the ' IS' from the parameters
                     if Pos(all_reserved_words(cIS), parameters) > 0
                     then  -- remove it
                        Delete(parameters, 
                               Pos(all_reserved_words(cIS), parameters) - 1, 
                               Length(parameters) -
                                    Pos(all_reserved_words(cIS),parameters)+1);
                     else  -- bad syntax
                        Error_Log.Debug_Data(at_level => 9, 
                             with_details => "Load_Macro: raising exception " &
                                             "on instruction = '" & command &
                                             "' for mal-formed parameters (" &
                                             parameters & ").");
                        raise BAD_MACRO_CODE;
                     end if;
                     -- Get the procedure name if any
                     if Locate('(',parameters) > 0 
                     then  -- possible name with parameters
                        if Locate('(',parameters) > 2 then -- there's a name
                           the_block.proc_name:=Trim(Sub_String(parameters, 1,
                                                     Locate('(',parameters)-1));
                        end if;
                        -- get the parameter
                        Delete(parameters, 1, Locate('(',parameters));
                        if Locate('}',parameters) > 1
                        then  -- there is a parameter
                           the_block.parameter := Sub_String(parameters, 1, 
                                                     Locate('(',parameters)-1);
                        else
                           Clear(the_block.parameter);
                        end if;
                     elsif Length(parameters) > 0 then
                        the_block.proc_name := Trim(parameters);
                     end if;
                     -- Push ourselves onto the stack
                     Push(the_item=> (cPROCEDURE,the_block), onto=> the_stack);
                     -- Now point us to our sub-code block
                     current_block := the_block;
                     link_to := proc_body;
                     Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: processed PROCEDURE.");
                  when cEQUATION =>
                     Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: processing EQUATION.");
                     the_block := new cmd_block(cEQUATION);
                     Link(the_block, to=>link_to, for_current=>current_block);
                     the_block.last_command := current_block;
                     if current_block /= null then Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: EQUATION - last_command = '" & all_reserved_words(current_block.cmd) & "' for this block and linked to this via " & link_to'Wide_Image & "."); end if;
                     if current_block.cmd = cPROCEDURE
                     then
                        if current_block.proc_body = null
                        then 
                           current_block.proc_body := the_block;
                           Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: processing EQUATION, but previous cPROCEDURE is UNLINKED!!!");
                        else
                           Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: processing EQUATION and previous cPROCEDURE is linked.");
                        end if;
                     end if;
                     declare
                        the_reg : constant all_register_names := 
                           To_Register(for_character=>Wide_Element(command,1));
                        the_param : constant text := 
                                           Set_Order_Of_Precedence(parameters);
                     begin
                        the_block.equation :=
                           Build_Equation(using_parameter => the_param,
                                          into_register => the_reg,
                                           of_type => register_types(the_reg));
                     end;
                     -- Point the block at the next instruction location
                     current_block := the_block;
                     link_to := next_command;
                  when cINSERT => -- INSERT S({position}) WITH "{string}"|reg
                     Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: processing INSERT.");
                     -- Set the block data up to point to the INSERT command
                     the_block := new cmd_block(cINSERT);
                     Link(the_block, to=>link_to, for_current=>current_block);
                     the_block.last_command := current_block;
                     if current_block /= null then Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: INSERT - last_command = '" & all_reserved_words(current_block.cmd) & "' for this block and linked to this via " & link_to'Wide_Image & "."); end if;
                     -- Extract the (usually) S (string) register position from
                     -- the parameters
                     the_block.i_reg := To_Register(for_character =>
                                                  Wide_Element(parameters, 1));
                     Delete(parameters, 1, 2);  -- 'S(' or 'G('
                     the_block.i_pos := Build_Equation
                                   (using_parameter=>Sub_String(parameters,1,
                                                     Locate(')',parameters)-1),
                                               treat_assignment_as_done=>true);
                     Delete (parameters, 1, Locate(')',parameters)-1);
                     Delete(parameters, 1, 7);  -- ') WITH '
                     -- Determine the target from the parameters (register or
                     -- constant)
                     if Wide_Element(parameters, 1) = '"'
                     then  -- a string, so set it
                        Delete(parameters, 1, 1);  -- '"'
                        Delete(parameters, Length(parameters), 1);  -- '"'
                        the_block.i_data := new equation_type(textual);
                        the_block.i_data.t_const := parameters;
                        the_block.i_data.operator := none;
                        the_block.i_data.num_type := character_type;
                     elsif Length(parameters) = 1
                     then  -- a register
                        the_block.i_val := To_Register(for_character =>
                                                  Wide_Element(parameters, 1));
                     else  -- an equation
                        the_block.i_data := Build_Equation
                                                 (using_parameter=>parameters,
                                                  of_type => textual,
                                               treat_assignment_as_done=>true);
                     end if;
                     -- Point the block at the next instruction location
                     current_block := the_block;
                     link_to := next_command;
                  when cREPLACE => -- REPLACE S({position}) WITH "{string}"|reg
                     Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: processing REPLACE.");
                     -- Set the block data up to point to the REPLACE command
                     the_block := new cmd_block(cREPLACE);
                     Link(the_block, to=>link_to, for_current=>current_block);
                     the_block.last_command := current_block;
                     if current_block /= null then Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: REPLACE - last_command = '" & all_reserved_words(current_block.cmd) & "' for this block and linked to this via " & link_to'Wide_Image & "."); end if;
                     -- Extract the (usually) S (string) register position from
                     -- the parameters
                     the_block.r_reg := To_Register(for_character =>
                                                  Wide_Element(parameters, 1));
                     Delete(parameters, 1, 2);  -- 'S(' or 'G('
                     the_block.r_pos := Build_Equation
                                   (using_parameter=>Sub_String(parameters,1,
                                                     Locate(')',parameters)-1),
                                    -- into_register => the_block.r_reg,
                                               treat_assignment_as_done=>true);
                     Delete (parameters, 1, Locate(')',parameters)-1);
                     Delete(parameters, 1, 7);  -- ') WITH '
                     -- Determine the target from the parameters (register or
                     -- constant)
                     if Wide_Element(parameters, 1) = '"'
                     then  -- a string, so set it
                        Delete(parameters, 1, 1);  -- '"'
                        Delete(parameters, Length(parameters), 1);  -- '"'
                        the_block.r_data := new equation_type(textual);
                        the_block.r_data.t_const := parameters;
                        the_block.r_data.operator := none;
                        the_block.r_data.num_type := character_type;
                     elsif Length(parameters) = 1
                     then  -- a register
                        the_block.r_val := To_Register(for_character =>
                                                  Wide_Element(parameters, 1));
                     else  -- an equation
                        the_block.r_data := Build_Equation
                                                 (using_parameter=>parameters,
                                                  of_type => textual,
                                               treat_assignment_as_done=>true);
                     end if;
                     -- Point the block at the next instruction location
                     current_block := the_block;
                     link_to := next_command;
                  when cDELETE =>
                     Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: processing DELETE.");
                     -- Set the block data up to point to the DELETE command
                     the_block := new cmd_block(cDELETE);
                     Link(the_block, to=>link_to, for_current=>current_block);
                     the_block.last_command := current_block;
                     if current_block /= null then Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: DELETE - last_command = '" & all_reserved_words(current_block.cmd) & "' for this block and linked to this via " & link_to'Wide_Image & "."); end if;
                     if Wide_Element(parameters,1) = '(' and 
                        Wide_Element(parameters, Length(parameters)) =')'
                     then  -- strip them
                        parameters := 
                               Sub_String(parameters, 2, Length(parameters)-2);
                     end if;
                     Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: processing DELETE: parameters are '" & parameters & "'.");
                     if (Wide_Element(parameters,2) = ' ' or 
                         Wide_Element(parameters,2) = ',') and then
                        To_Register(for_character =>
                                           Wide_Element(parameters,1)) /= const
                     then  -- There is a register specified for char to delete
                        the_block.d_reg := To_Register(for_character =>
                                                  Wide_Element(parameters, 1));
                        Delete(parameters, 1, 1);  -- delete 'S' or 'G'
                        if Wide_Element(parameters, 1) = ',' then
                           Delete(parameters, 1, 1);  -- delete that too
                        end if;
                        parameters := Left_Trim(parameters);
                     end if;
                     if the_block.d_reg in G .. S
                     then  -- There is a specification of char to delete
                        the_block.d_position := Build_Equation
                                              (using_parameter=>parameters,
                                    -- into_register => the_block.d_reg,
                                               treat_assignment_as_done=>true);
                     else  -- mal-formed delete parameter or register
                        Error_Log.Debug_Data(at_level => 9, 
                                with_details => "Load_Macro: raising " &
                                                "exception on instruction = '"&
                                                command &
                                                "' - bad parameter format '" & 
                                                parameters & "' in register '"&
                                                register_ids(the_block.d_reg) &
                                                "'.");
                        raise BAD_MACRO_CODE;
                     end if;
                     -- Point the block at the next instruction location
                     current_block := the_block;
                     link_to := next_command;
                  when cERROR_LOG =>
                     Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: processing ERROR_LOG.");
                     -- Set the block data up to point to the ERROR_LOG command
                     the_block := new cmd_block(cERROR_LOG);
                     Link(the_block, to=>link_to, for_current=>current_block);
                     the_block.last_command := current_block;
                     if current_block /= null then Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: ERROR_LOG - last_command = '" & all_reserved_words(current_block.cmd) & "' for this block and linked to this via " & link_to'Wide_Image & "."); end if;
                     -- First, strip out any brackets
                     if Length(parameters) > 2 and then
                        (Wide_Element(parameters, 1) = '(' and
                         Wide_Element(parameters, Length(parameters)) = ')')
                     then
                        Delete(parameters, 1, 1);                   -- '('
                        Delete(parameters, Length(parameters), 1);  -- ')'
                     end if;
                     -- Set up the error  log based on the parameter, which may
                     -- be either a string literal or a register whose contents
                     -- are to be logged.
                     if Length(parameters) > 0
                     then
                        if Length(parameters) > 2 and then
                           Wide_Element(parameters, 1) = '"'
                        then  -- a string to be logged?
                           if Wide_Element(parameters, Length(parameters))= '"'
                           then
                              the_block.e_val := Sub_String(from => parameters,
                                                            starting_at => 2,
                                                            for_characters =>
                                                         Length(parameters)-2);
                           else
                              Error_Log.Debug_Data(at_level => 9, 
                                 with_details => "Load_Macro: raising " &
                                                "exception on instruction = '"&
                                                command &
                                                "' - bad log string.");
                              raise BAD_MACRO_CODE;
                           end if;
                        else  -- a register to be logged
                           the_block.e_reg := 
                                       To_Register(Wide_Element(parameters,1));
                           if the_block.e_reg = const then -- error
                              Error_Log.Debug_Data(at_level => 9, 
                                 with_details => "Load_Macro: raising "&
                                              "exception on instruction = '" &
                                              command &
                                              "' - bad register specification"&
                                              " as '"& parameters & "'.");
                              raise BAD_MACRO_CODE;
                           end if;
                        end if;
                     else  -- error condition - nothing to log specified
                        Error_Log.Debug_Data(at_level => 9, 
                              with_details => "Load_Macro: raising exception "&
                                              "on instruction = '" & command &
                                              "' - nothing specified to log.");
                        raise BAD_MACRO_CODE;
                     end if;
                     -- Point the block at the next instruction location
                     current_block := the_block;
                     link_to := next_command;
                  when cIF =>
                     Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: processing IF.");
                     -- Set the block data up to point to the IF command
                     the_block := new cmd_block(cIF);
                     Link(the_block, to=>link_to, for_current=>current_block);
                     the_block.last_command := current_block;
                     if current_block /= null then Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: IF - last_command = '" & all_reserved_words(current_block.cmd) & "' for this block and linked to this via " & link_to'Wide_Image & "."); end if;
                     -- Determine and set up the condition from the parameters
                     the_block.condition := 
                        Build_Equation(using_parameter => 
                           Set_Order_Of_Precedence(for_parameter => 
                                  Sub_String(parameters, 1, 
                                             Pos(Value("THEN"),parameters)-1)),
                                       into_register => const,
                                       of_type => logical,
                                       treat_assignment_as_done=>true);
                     -- Push ourselves onto the stack
                     Push(the_item=> (cIF,the_block), onto=> the_stack);
                     -- Now point us to our sub-code block for THEN part
                     current_block := the_block;
                     link_to := then_part;
                  when cELSIF =>
                     Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: processing ELSIF.");
                     -- Set the block data up to point to the ELSIF command
                     the_block := new cmd_block(cELSIF);
                     Link(the_block, to=>link_to, for_current=>current_block);
                     the_block.last_command := current_block;
                     if current_block /= null then Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: ELSIF - last_command = '" & all_reserved_words(current_block.cmd) & "' for this block and linked to this via " & link_to'Wide_Image & "."); end if;
                     -- Get the parent block pointer from the stack and point
                     -- the parent_if at that, so we know where to return
                     -- to in the event that the condition fails and we need to
                     -- find the ELSE part.  The parent is the previous IF or
                     -- ELSIF statement.
                     Pop(the_item => parent_data, off_of => the_stack);
                     the_block.parent_if := parent_data.parent;
                     -- If the parent's ELSE part is not set, then set it to
                     -- this ELSIF
                     if parent_data.parent.cmd = cIF and then
                        parent_data.parent.else_part = null
                     then  -- As parent is IF, set it's else part to this ELSIF
                        parent_data.parent.else_part := the_block;
                        Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: ELSIF - set parent_if to '" & all_reserved_words(parent_data.parent.cmd) & "' (being the parent_data.parent) and parent_data.parent.else_part to this ELSIF block.");
                     elsif parent_data.parent.cmd = cELSIF and then
                           parent_data.parent.eelse_part = null
                     then  -- As previous is ELSIF, point it to this ELSIF
                        parent_data.parent.eelse_part := the_block;
                        Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: ELSIF - set parent_if to '" & all_reserved_words(parent_data.parent.cmd) & "' (being the parent_data.parent) and parent_data.parent.eelse_part to this ELSIF block.");
                     else  -- Not an if statement! Push it back on the stack
                        Push(the_item => parent_data, onto => the_stack);
                        if parent_data.parent /= null then Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: ELSIF - set parent_if to '" & all_reserved_words(parent_data.parent.cmd) & "' (being the parent_data.parent) but that parent did not get its else or eelse part set."); end if;
                     end if;
                     -- Determine and set up the condition from the parameters
                     the_block.econdition := 
                        Build_Equation(using_parameter => 
                           Set_Order_Of_Precedence(for_parameter => 
                                  Sub_String(parameters, 1, 
                                             Pos(Value("THEN"),parameters)-1)),
                                       into_register => const,
                                       of_type => logical);
                     -- Push our If statement back onto the stack
                     Push(the_item=> (cELSIF,the_block), onto=> the_stack);
                     -- Now point us to our sub-code block for ELSIF part
                     current_block := the_block;
                     link_to := ethen_part;
                  when cELSE =>
                     Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: processing ELSE.");
                     -- Set the block data up to point to the ELSE command
                     the_block := new cmd_block(cELSE);
                     Link(the_block, to=>link_to, for_current=>current_block);
                     the_block.last_command := current_block;
                     if current_block /= null then Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: ELSE - last_command = '" & all_reserved_words(current_block.cmd) & "' for this block and linked to this via " & link_to'Wide_Image & "."); end if;
                     -- Get the parent block pointer from the stack and point
                     -- the next_command at that, so we know where to return
                     -- to.  The parent is the previous IF or ELSIF statement.
                     Pop(the_item => parent_data, off_of => the_stack);
                     the_block.else_parent := parent_data.parent;
                     -- If the parent's ELSE part is not set, then set it to
                     -- this ELSIF
                     if parent_data.parent.cmd = cIF and then
                        parent_data.parent.else_part = null
                     then  -- As parent is IF, set it's else part to this ELSE
                        parent_data.parent.else_part := the_block;
                        Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: ELSE - set parent_if to '" & all_reserved_words(parent_data.parent.cmd) & "' (being the parent_data.parent) and parent_data.parent.else_part to this ELSE block.");
                     elsif parent_data.parent.cmd = cELSIF and then
                        parent_data.parent.eelse_part = null
                     then  -- As previous is ELSIF, point it to this ELSE
                        parent_data.parent.eelse_part := the_block;
                        Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: ELSE - set else_parent to '" & all_reserved_words(parent_data.parent.cmd) & "' (being the parent_data.parent) and parent_data.parent.eelse_part to this ELSE block.");
                     else  -- Not an if statement! Push it back on the stack
                        Push(the_item => parent_data, onto => the_stack);
                        if parent_data.parent /= null then Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: ELSE - set parent_if to '" & all_reserved_words(parent_data.parent.cmd) & "' (being the parent_data.parent) but that parent did not get its else or eelse part set."); end if;
                     end if;
                     -- Push ourselves onto the stack
                     Push(the_item=> (cELSE,the_block), onto=> the_stack);
                     -- Now point us to our sub-code block for ELSE part
                     current_block := the_block;
                     link_to := else_block;
                  when cFOR =>
                     Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: processing FOR.");
                     -- Set the block data up to point to the FOR command
                     the_block := new cmd_block(cFOR);
                     Link(the_block, to=>link_to, for_current=>current_block);
                     the_block.last_command := current_block;
                     if current_block /= null then Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: FOR - last_command = '" & all_reserved_words(current_block.cmd) & "' for this block and linked to this via " & link_to'Wide_Image & "."); end if;
                     -- Extract the loop conditions from the paramenters
                     the_block.for_reg := To_Register(for_character =>
                                                   Wide_Element(parameters,1));
                     Delete(parameters, 1, 2);  -- register + space
                     if Pos(Value("IN REVERSE"), Upper_Case(parameters)) = 1
                     then
                        the_block.direction := in_reverse;
                        Delete(parameters, 1, 11);  -- 'IN REVERSE '
                     else
                        Delete(parameters, 1, 3);   -- 'IN '
                     end if;
                     -- Extract the start and finish points
                     Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: ellipses (" & all_maths_operators(ellipses) & ") in '" & parameters & "' at position " & Put_Into_String(Pos(all_maths_operators(ellipses),parameters)) & ".");
                     fleft := Trim(Sub_String(parameters, 1, 
                                             Pos(all_maths_operators(ellipses),
                                              parameters)-1));
                     fright:= Trim(Sub_String(parameters, 
                                             Pos(all_maths_operators(ellipses),
                                              parameters)+3,
                                              Length(parameters)-4));
                     the_block.f_start:=Build_Equation(using_parameter=>fleft);
                     Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: the_block.f_start:=Build_Equation on fleft (" & fleft & ").");
                     the_block.f_end:= Build_Equation(using_parameter=>
                                                  Sub_String(fright, 1, 
                                                             Pos(Value("LOOP"),
                                                                  fright)-2));
                     Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: the_block.f_end:=Build_Equation on fright (" & Sub_String(fright, 1, Pos(Value("LOOP"), fright)-2) & ").");
                     if the_block.f_end = null then
                        Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: the_block.f_end - got not equation back!");
                     end if;
                     -- Push ourselves onto the stack
                     Push(the_item=> (cFOR,the_block), onto=> the_stack);
                     -- Now point us to our sub-code block for FOR part
                     current_block := the_block;
                     link_to := for_block;
                  when cLOOP =>
                     Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: processing LOOP.");
                     -- Set the block data up to point to the LOOP command
                     the_block := new cmd_block(cLOOP);
                     Link(the_block, to=>link_to, for_current=>current_block);
                     the_block.last_command := current_block;
                     if current_block /= null then Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: LOOP - last_command = '" & all_reserved_words(current_block.cmd) & "' for this block and linked to this via " & link_to'Wide_Image & "."); end if;
                     -- Extract the start and finish points
                     -- Push ourselves onto the stack
                     Push(the_item=> (cLOOP,the_block), onto=> the_stack);
                     -- Now point us to our sub-code block for LOOP part
                     current_block := the_block;
                     link_to := loop_block;
                  when cEXIT =>  -- Exit a For loop or just a LOOP
                     Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: processing EXIT.");
                     -- Find the parent FOR loop in the stack (which may be a
                     -- few IF statements up)
                     declare
                        for_stack : Command_Stack.stack;
                     begin
                        -- First, get to the for loop, saving steps for retrace
                        Clear(the_stack => for_stack);
                        loop
                           Pop(the_item => parent_data, off_of => the_stack);
                           Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: processing EXIT - popped item " & parent_data.command'Wide_Image & ".");
                           Push(the_item => parent_data, onto => for_stack);
                           exit when parent_data.command = cFOR or
                                     parent_data.command = cLOOP or
                                     Depth(of_the_stack=> the_stack) = 0;
                        end loop;
                        -- Get back to the point of adjustment data
                        Pop(the_item => parent_data, off_of => for_stack);
                        -- Second, load the point to exit to
                        the_block := new cmd_block(cEXIT);
                        -- Third, work out if there is a condition
                        if Length(parameters) > 0 and then
                           Pos(Value("WHEN"), Upper_Case(parameters)) = 1
                        then  -- there's a condition - load it in
                           Delete(parameters, 1, 5);  -- 'WHEN '
                           the_block.exit_conditn := 
                                   Build_Equation(using_parameter=>parameters,
                                                  into_register => const,
                                                  of_type => logical,
                                               treat_assignment_as_done=>true);
                           Clear(parameters);
                        end if;
                        -- Now, link it all up
                        Link(the_block,to=>link_to,for_current=>current_block);
                        the_block.last_command := current_block;
                        if current_block /= null then Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: EXIT - last_command = '" & all_reserved_words(current_block.cmd) & "' for this block and linked to this via " & link_to'Wide_Image & "."); end if;
                        the_block.exit_point:= parent_data.parent;  -- the FOR
                        Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: processing EXIT - assigned exit_point to parent_data.parent.");
                        -- Just in case, ensure the exit_parent is assigned to something
                        if Depth(of_the_stack=> for_stack) = 0  -- at end?  ---***
                           then  -- this is our parent - save so we pop to it
                           the_block.exit_parent := parent_data.parent;  ---***
                           Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: processing EXIT - initial assignment of exit_parent to parent_data.parent.");
                        end if;  ---***
                        -- And restore the stack
                        Push(the_item=> parent_data, onto=> the_stack);
                        Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: processing EXIT - assigned exit_point to parent_data.parent with stack depth to process in reverse of " & Put_Into_String(Depth(of_the_stack=> for_stack)) & ".");
                        while Depth(of_the_stack=> for_stack) > 0 loop
                           Pop(the_item => parent_data, off_of => for_stack);
                           Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: processing EXIT - pushing item " & parent_data.command'Wide_Image & ".");
                           Push(the_item=> parent_data, onto=> the_stack);
                           if Depth(of_the_stack=> for_stack) = 0  -- at end?
                           then  -- this is our parent - save so we pop to it
                              the_block.exit_parent := parent_data.parent;
                              Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: processing EXIT - final assignment of exit_parent to parent_data.parent.");
                           end if;
                        end loop;
                        Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: processing EXIT - processed stack restoration.");
                        Clear(the_stack => for_stack);
                        Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: processing EXIT - cleared out for_stack.");
                     end;
                     -- Finally, point the_block at the next statement
                     Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: processing EXIT - Setting current_block to the_block.");
                     current_block := the_block;
                     Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: processing EXIT - assigning next_command to link_to.");
                     link_to := next_command;
                     null;
                     Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: now processed EXIT.");
                  when cEND =>
                     Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: processing END with command '" & command & "' and parameters '" & parameters & "'.");
                     -- Get the parent block pointer from the stack and point
                     -- the next_command at that, adjusting as necessary other
                     -- relevant pointers.
                     Pop(the_item => parent_data, off_of => the_stack);
                     case parent_data.command is
                        when cIF | cELSIF | cELSE =>-- parameter should be 'IF'
                           Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: processing END IF (" & all_reserved_words(parent_data.parent.cmd) & ") with current_block.cmd = '" & all_reserved_words(current_block.cmd) & "' (" & current_block.cmd'Wide_Image & ") and link_to = '" & link_to'Wide_Image & "'.");
                           -- Chain through from the previous command to this,
                           -- and from this to the next command (adjusting the
                           -- IF block components along the way).
                           the_block := new cmd_block(cEND);
                           the_block.end_type := cIF;
                           Link(the_block, to=>link_to, for_current=>current_block);
                           the_block.last_command := current_block;
                           if current_block /= null then Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: END (IF) - last_command = '" & all_reserved_words(current_block.cmd) & "' for this block and linked to this via " & link_to'Wide_Image & "."); end if;
                           -- Check the parameter is correct
                           if Upper_Case(parameters) /= all_reserved_words(cIF)
                           then  -- no match so raise an error
                              Error_Log.Debug_Data(at_level => 9, 
                                 with_details => "Load_Macro: raising "& 
                                              "exception on instruction = '" & 
                                              command & " " & parameters & 
                                              "' - unmatching END type " & 
                                              "(should be END IF).");
                              raise BAD_MACRO_CODE;
                           end if;
                           -- Point this END (IF) at the last parent IF/ELSIF/
                           -- ELSE clause
                           the_block.parent_block := parent_data.parent;
                           -- Chase back each previous IF/ELSIF/ELSE command
                           -- and set their next_command to this END block
                           while parent_data.parent.cmd /= cIF loop
                              -- Point the ELSIF / ELSE at this END (IF) block
                              parent_data.parent.next_command := the_block;
                              Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: END (IF) - set parent_data.parent '" & all_reserved_words(parent_data.parent.cmd) & "' next_command to this block.");
                              -- Now go back to the prior IF/ELSIF/ELSE block
                              if parent_data.parent.cmd = cELSE
                              then  -- go to ELSE's parent
                                 parent_data.parent := 
                                                parent_data.parent.else_parent;
                              elsif parent_data.parent.cmd = cELSIF
                              then  -- go  to ELSIF's parent
                                 parent_data.parent := 
                                                  parent_data.parent.parent_if;
                              end if;
                           end loop;
                           -- parent_data should point to IF now
                           if parent_data.parent.cmd = cIF then
                              -- Point the IF at this END (IF) block for now
                              parent_data.parent.next_command := the_block;
                              Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: END (IF) - set parent_data.parent '" & all_reserved_words(parent_data.parent.cmd) & "' next_command to this block, with this block's parent being '" & all_reserved_words(the_block.parent_block.cmd) & "'.");
                           end if;
                           -- Point to the next block
                           current_block := the_block;
                           link_to := next_command;
                        when cFOR =>               -- parameter should be 'FOR'
                           Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: processing END LOOP (" & all_reserved_words(parent_data.parent.cmd) & ") with current_block.cmd = '" & all_reserved_words(current_block.cmd) & "' and link_to = '" & link_to'Wide_Image & "'.");
                           -- Point the previous block to this end block, make
                           -- sure this end block points to the parent and the 
                           -- parent to the next command so that the parent can
                           -- either continue to loop or terminate the loop
                           the_block := new cmd_block(cEND);
                           the_block.end_type := cFOR;
                           Link(the_block, to=>link_to, for_current=>current_block);
                           the_block.parent_block := parent_data.parent;
                           the_block.last_command := current_block;
                           if current_block /= null then Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: END (FOR) - last_command = '" & all_reserved_words(current_block.cmd) & "' for this block and linked to this via " & link_to'Wide_Image & "."); end if;
                           parent_data.parent.next_command := the_block;
                           -- and point to the next block
                           current_block := the_block;
                           link_to := next_command;
                           if Upper_Case(parameters)/=all_reserved_words(cLOOP)
                           then  -- no match so raise an error
                              Error_Log.Debug_Data(at_level => 9, 
                                 with_details => "Load_Macro: raising "& 
                                              "exception on instruction = '" & 
                                              command & " " & parameters & 
                                              "' - unmatching END type " & 
                                              "(should be END LOOP).");
                              raise BAD_MACRO_CODE;
                           end if;
                           Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: processed END LOOP with previous (" & all_reserved_words(the_block.last_command.cmd) & ") with current_block.cmd NOW = '" & all_reserved_words(current_block.cmd) & "' and link_to = '" & link_to'Wide_Image & "' with this block's parent being '" & all_reserved_words(the_block.parent_block.cmd) & "'.");
                        when cLOOP =>             -- parameter should be 'LOOP'
                           Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: processing END LOOP (" & all_reserved_words(parent_data.parent.cmd) & ") with current_block.cmd = '" & all_reserved_words(current_block.cmd) & "' and link_to = '" & link_to'Wide_Image & "'.");
                           -- Point the previous block to this end block, make
                           -- sure this end block points to the parent and the 
                           -- parent to the next command so that the parent can
                           -- either continue to loop or terminate the loop
                           the_block := new cmd_block(cEND);
                           the_block.end_type := cLOOP;
                           Link(the_block, to=>link_to, for_current=>current_block);
                           the_block.parent_block := parent_data.parent;
                           the_block.last_command := current_block;
                           if current_block /= null then Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: END (LOOP) - last_command = '" & all_reserved_words(current_block.cmd) & "' for this block and linked to this via " & link_to'Wide_Image & "."); end if;
                           parent_data.parent.next_command := the_block;
                           -- and point to the next block
                           current_block := the_block;
                           link_to := next_command;
                           if Upper_Case(parameters)/=all_reserved_words(cLOOP)
                           then  -- no match so raise an error
                              Error_Log.Debug_Data(at_level => 9, 
                                 with_details => "Load_Macro: raising "& 
                                              "exception on instruction = '" & 
                                              command & " " & parameters & 
                                              "' - unmatching END type " & 
                                              "(should be END LOOP).");
                              raise BAD_MACRO_CODE;
                           end if;
                           Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: processed END LOOP with previous (" & all_reserved_words(the_block.last_command.cmd) & ") with current_block.cmd NOW = '" & all_reserved_words(current_block.cmd) & "' and link_to = '" & link_to'Wide_Image & "' with this block's parent being '" & all_reserved_words(the_block.parent_block.cmd) & "'.");
                        when cPROCEDURE =>--  this should be the last statement
                           if (Length(parent_data.parent.proc_name)> 0 and then
                               Trim(Upper_Case(parent_data.parent.proc_name))/=
                                                        Upper_Case(parameters))
                               or else (Length(parent_data.parent.proc_name)= 0
                                        and Length(parameters) > 0)
                           then  -- no match so raise an error
                              Error_Log.Debug_Data(at_level => 9, 
                                 with_details => "Load_Macro: raising "& 
                                              "exception on instruction = '" & 
                                              command & " " & parameters & 
                                              "' - unmatching END type " & 
                                              "(should be END " & Trim(
                                              parent_data.parent.proc_name) & 
                                              ").");
                              raise BAD_MACRO_CODE;
                           end if;
                           the_block := new cmd_block(cEND);
                           the_block.end_type := cPROCEDURE;
                           Link(the_block, to=>link_to, for_current=>current_block);
                           the_block.parent_block := parent_data.parent;
                           the_block.last_command := current_block;
                           -- link the procedure back to here for now (it
                           -- should point to the command after this END)
                           parent_data.parent.next_command := the_block;
                           if current_block /= null then Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: END (PROCEDURE) - last_command = '" & all_reserved_words(current_block.cmd) & "' for this block and linked to this via " & link_to'Wide_Image & " with this block's parent being '" & all_reserved_words(the_block.parent_block.cmd) & "'."); end if;
                           current_block := the_block;
                           link_to := next_command;
                        when others =>     -- actually an error condition
                           Error_Log.Debug_Data(at_level => 9, 
                              with_details => "Load_Macro: raising exception "&
                                              "on instruction = '" & command &
                                              "' - incorrect END placement.");
                           raise BAD_MACRO_CODE;
                     end case;
                     null;
                  when cNull =>  -- No operation (null) command
                     the_block := new cmd_block(cNull);
                     Link(the_block, to=>link_to, for_current=>current_block);
                     the_block.last_command := current_block;
                     if current_block /= null then Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: END (NULL) - last_command = '" & all_reserved_words(current_block.cmd) & "' for this block and linked to this via " & link_to'Wide_Image & "."); end if;
                     current_block := the_block;
                     link_to := next_command;
                  when others => 
                     Error_Log.Debug_Data(at_level => 9, 
                             with_details => "Load_Macro: raising exception " & 
                                             "on instruction = '" & command &
                                             "'.");
                     raise BAD_MACRO_CODE;
               end case;
            else
               if num /= instructions'Last
               then -- not last CR character
                  Error_Log.Debug_Data(at_level => 9, 
                             with_details => "Load_Macro: raising exception " & 
                                             "on instruction = '" &instruction&
                                             "'.");
                  raise BAD_MACRO_CODE;
               end if;
            end if;
         end loop;
         -- Working backwards, fix up the links for cEXIT, cIF, cFOR and cLOOP
         while current_block /= null loop
            Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: backwards: current_block is " & current_block.cmd'Wide_Image & ".");
            if current_block.cmd = cEXIT
            then  -- should point to next_command, but was probably blank prior
               current_block.exit_parent :=
                                        current_block.exit_parent.next_command;
               Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: backwards: current_block is " & current_block.cmd'Wide_Image & " with exit_parent = '" & all_reserved_words(current_block.exit_parent.cmd) & "'.");
            elsif current_block.cmd = cIF or current_block.cmd = cFOR
            then  -- should point to block after END, but it didn't exist then
               current_block.next_command := 
                                       current_block.next_command.next_command;
               Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: backwards: current_block is " & current_block.cmd'Wide_Image & " with next_command = '" & all_reserved_words(current_block.next_command.cmd) & "'.");
            elsif current_block.cmd = cIF or current_block.cmd = cLOOP
            then  -- should point to block after END, but it didn't exist then
               current_block.next_command := 
                                       current_block.next_command.next_command;
               Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: backwards: current_block is " & current_block.cmd'Wide_Image & " with next_command = '" & all_reserved_words(current_block.next_command.cmd) & "'.");
            elsif current_block.cmd = cPROCEDURE
            then  -- should point to the next statement, if any (may be NULL)
               current_block.next_command := 
                                       current_block.next_command.next_command;
               Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: backwards: current_block is " & current_block.cmd'Wide_Image & ".");
               if current_block.next_command /= null then Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: backwards: The current_block '" & current_block.cmd'Wide_Image & "' next_command now points to '" & all_reserved_words(current_block.next_command.cmd) & "'."); 
               else Error_Log.Debug_Data(at_level => 9, with_details => "Load_Macro: backwards: The current_block '" & current_block.cmd'Wide_Image & "' next_command now points to 'NULL'."); end if;
            elsif current_block.cmd = cEQUATION then Print(the_equation => current_block.equation);
            end if;
            current_block := current_block.last_command;
         end loop;
      end;
   end Load_Macro;
   
begin
   Cell_Writer_Version.Register(revision => "$Revision: v1.0.2$",
                                for_module => "Code_Interpreter");
end Code_Interpreter;
