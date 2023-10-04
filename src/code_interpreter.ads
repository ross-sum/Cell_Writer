-----------------------------------------------------------------------
--                                                                   --
--                  C O D E   I N T E R P R E T E R                  --
--                                                                   --
--                     S p e c i f i c a t i o n                     --
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
--
--  Instruction Syntax
-- 
-- The command set may take a parameter, which is passed in as a constant.
-- The syntax for defining this is below.  It is loaded into register H.  
-- It is sourced from the database for the key to which it applies. 
-- 
-- Each full command is separated by a semicolon (;).
-- White space is at least one of the space (' ' - 16#0020#), tab (16#0008#),
-- carriage return (16#000D#) and line feed (16#000A#) characters. It is used 
--to separate sub- components of a command. 
-- Comments commence with a double dash (--) character pair and terminate with
-- end of line (line feed - 16#000A#) character, and are ignored. 
-- 
-- Data Sources 
-- 
--     • 5 registers, A - E for numbers
--     • 1 character register,  F
--     • 1 string register,  G
--       • where each character is addressable as G(x), where x is some integer
--         or a numeric register containing an integer
--       • The parameter Length (as in G'Length) returns the string length 
--     • 1 character register,  H, which contains a parameter passed to the
--       command set and cannot be altered by the command set
--     • The Cell, represented by the register S
--       • The parameter Length (as in S'Length) returns the cell's string
--         length
--     • Constants (as a decimal number)
--     • Width of each 'space' character
--       • 'space' characters specified in a character set in the database
--       • the set of 'space' characters under operation are bounded by two
--         ASCII space (16#0020#) characters
--       • For the purposes of this language, these 'space' characters are non-
--         combining characters that occupy the current cell
--     • Position of each 'space' character. 
-- 
-- Command Set
-- 
-- PROCEDURE
-- The PROCEDURE command is used to initiate the combining character command set.
-- Format is:
--   PROCEDURE <<name>> ({value}) IS
--   PROCEDURE <<name>> () IS
--   PROCEDURE IS
-- Where:
--   <<name>> is an optional procedure name;
--   {value}  is a Unicode character to be passed in and is loaded into register
--            H.
-- If the {value} is not specified but the brackets () are, then the value in
-- the H register is taken from the key tool tip help text of the launching
-- combining character button.
-- If no brackets are specified, then the H register is left empty.
-- 
-- END
-- The END command on its own terminates combining character command set and is
-- terminated with a semicolon. 
-- Format is:
--   END
--   END <<name>>
-- Where:
--   <<name>> is an optional name, but if supplied, must match the procedure
--            name (which must also then be supplied).
-- 
-- IF - THEN - ELSE
-- A conditional set of operations. 
-- Format is:
--   IF {condition} THEN {operation}
--   ELSIF {condition} THEN {operation}
--   ELSE {operation} END IF
-- Where:
--   {condition} is some comparison of two data sources;
--   {operation} is a set of instructions using the command set. Each operation
--               (i.e. command) is separated by a semicolon (;) as noted above. 
-- The ELSIF component together with its operation is optional.  There may be
-- as many ELSIF components as is required.
-- The ELSE component together with its operation is optional.
-- 
-- INSERT
-- Insert just before the specified 'space' character the specified string.  To
-- insert at the end, specify the last character plus 1.
-- If there is no 'space' character but there are other non-combining
-- characters, then they or it is used. For the vast majority of character
-- sets, and definitely for the Latin character set, just one character is used
-- within a cell, meaning that the instruction set operates on the (only)
-- character in the current cell (see note at the beginning about characters
-- and cells).
-- After the insertion, the character position is advanced to character just
-- past the inserted string and the character count (i.e. column count) is
-- updated to add in the inserted string's length. 
-- Format is:
--   INSERT S({position}) WITH "{string}"
--   INSERT S({position}) WITH {register}
-- Where:
--   {position} is the 1 based position from the start of the 'space' sequence
--              of the desired 'space' character to be inserted before;
--   {string}   is the string of characters that are to insert before the
--              specified 'space' character - it could be calculated from a
--              string formula;
--   {register} is one of either F (character) or G (string) to be inserted.
-- 
-- REPLACE
-- Replace the specified 'space' character with the specified string. 
-- 
-- After the replacement, the character position is advanced to character just
-- past the inserted string and the character count (i.e. column count) is
-- updated to add in the inserted string's length less 1 for the replaced
-- character.
-- Format is:
--   REPLACE S({position}) WITH "{string}"
--   REPLACE S({position}) WITH {register}
-- Where:
--   {position} is the 1 based position from the start of the 'space' sequence
--              of the desired 'space' character to be replaced;
--   {string}   is the string of characters that are to replace the specified
--              'space' character -  it could be calculated from a string
--              formula;
--   {register} is one of either F or G to replace.
-- 
-- DELETE
-- Delete the specified character in the cell.  This operation does not visibly
-- affect position counters that might be in operation,  for instance in a For
-- loop that is working through a string of characters in a cell.  That is
-- achieved by leaving the character position where it is and adjusting the
-- string length. 
-- Format is:
--   DELETE ({position})
--   DELETE ({register})
--   DELETE {register} ({position})
--   DELETE {register} ({register})
-- Where:
--   {position} is the 1 based position from the start of the character
--              sequence in the cell of the desired character to be deleted;
--   {register} is one of the numeric registers specifying the character
--              position to be deleted or, in the case of the last two formats
--              the first occurrence specifies the register to delete from.
-- 
-- FOR - LOOP
-- For each item in a list, perform a specified series of operations.
-- Format is:
--   FOR {register} IN {value} .. {value} LOOP {commands} END LOOP
--   FOR {register} IN REVERSE {value} .. {value} LOOP {commands} END LOOP
--   FOR {register} IN {register} LOOP {commands} END LOOP
--   FOR {register} IN REVERSE {register} LOOP {commands} END LOOP
-- Where:
--   {register} is a numeric register,  A - E, and the initial value in this
--              register is lost for the counter register (i.e. the first
--              instance specified in the command) if counting up (i.e. REVERSE
--              is not specified) or if the range is specified rather than an
--              end value register. Otherwise,  the register specifies the
--              starting value.  The second register specifies the end number.
--              These numbers must be integers;
--   {value}    specifies the start and end count ranges and must be integers;
--   {commands} is a set of instructions using the command set. Each operation
--              (i.e. command) is separated by a semicolon (;) as noted above.
-- 
-- EXIT
--   Exit a For loop. 
-- Format is:
--   EXIT
-- 
-- LIST
-- This is a 'function' that lists out the sequential characters or numbers
-- between two specified limits. It is used in a for loop (e.g.
-- FOR A IN 1 .. 3) and in a test in an if statement (e.g. IF A IN 1 .. 3).
-- Format is:
--   IN '{start}' .. '{end}'
-- Where:
--   {start} is the starting character or number;
--   {end}   is the ending character or number. 
-- 
-- FIND
-- This is a function that finds the specified combining accent or other
-- character position, returning the position number.  If there are multiple
-- instances of the specified character, then it returns the position of the
-- first instance.   If none are found then it returns 0.
-- It, of course, operates on the S register.
-- Format is:
--   FIND ('{c}')
--   FIND ({register})
-- Where:
--   {c}        is a character to search on;
--   {register} is any register other than the G register, but if any of
--               registers A - E, then the number must be an integer and is
--               translated into its Unicode character value.
-- 
-- WIDTH
-- Provide the width of the specified character, usually a 'space' character. 
-- Format is:
--   WIDTH ('{c}')
--   WIDTH ({register})
-- Where:
--   {c}        is a character to search on;
--   {register} is any register other than the G (and S) register, but if any
--              of registers A - E, then the number must be an integer and is
--              translated into its Unicode character value.
-- 
-- CHAR
-- Provide the character that is the nearest first match for a given character
-- width, given a character starting position.
-- Format is:
--   CHAR ({start}, {size})
-- Where:
--   {start} is the starting character, either as a quoted constant (e.g. ' ')
--           or as a register (e.g. F). If it is a numeric register (i.e.
--           between A and E), then the number must be an integer and is
--           translated into its Unicode character value;
--   {size}  is the character size (see WIDTH above) and may either be a
--           (floating point) constant or a register. 
-- 
-- ERROR LOG
-- Provide a method of logging a message or a register.  The log is sent to the
-- application’s standard logging channel with a log level of 1.
-- Format is:
--   ERROR_LOG ("{string}") or
--   ERROR_LOG ({register})
-- Where:
--   {string}   is text string and is surrounded by double quotes (");
--   {register} is a register (e.g. F). If it is a numeric register (i.e.
--              between A and E), then the number will be logged in human
--              readable (i.e. textual) format.
-- 
-- Mathematical Operators
--   :=  : make the left hand side (a register) equal to the right hand side
--         equation. 
--   +   : add two registers or a register and a constant together. 
--   -   : subtract one register or constant from another register or constant.
--         It can also be a unary operator where it negates the register or
--         constant to the right of it.
--   ×   : multiply the item to its left (register or constant) by the item
--         (register or constant) to the right. Multiplication and division
--         have precedence over addition and subtraction. 
--   ÷   : divide the item (register or constant) on the left of the symbol by
--         the item (register or constant) to the right. 
--   &   : concatenate the register (either F or G) or double quote (")
--         enclosed constant to the operator's left with the register (either F
--         or G) or double quote enclosed constant to the operator's right. The
--         result must either go into register G (e.g. G := "constant" & F) or
--         must be the component of a comparison operation.
--   AND : boolean AND of the register or prior test with another register or
--         subsequent test; if a register, then a content of 0 is treated as
--         FALSE and anything else as TRUE.
--   OR  : boolean OR of the register or prior test with another register or
--         subsequent test; if a register, then a content of 0 is treated as
--         FALSE and anything else as TRUE.
--   NOT : boolean NOT of the register or subsequent test; if a register, then
--         a content of 0 is treated as FALSE and anything else as TRUE.
-- 
-- Comparison Operators 
--   =  : test that the value (if an equation, then the calculated value) on
--        the left of the comparator is equal to that on the right, returning
--        TRUE if so.
--   >  : test that the value (if an equation, then the calculated value) on
--        the left of the comparator is greater than that on the right,
--        returning TRUE if so.
--   >= : test that the value (if an equation, then the calculated value) on
--        the left of the comparator is greater than or equal to that on the
--        right, returning TRUE if so.
--   <  : test that the value (if an equation, then the calculated value) on
--        the left of the comparator is less than that on the right, returning
--        TRUE if so.
--   <= : test that the value (if an equation, then the calculated value) on
--        the left of the comparator is less than or equal to that on the
--        right, returning TRUE if so.
-- 
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
with GNATCOLL.SQL.Exec;
with Gtkada.Builder;    use Gtkada.Builder;
with Gtk.Drawing_Area;  use Gtk.Drawing_Area;
with dStrings;          use dStrings;
with Generic_Binary_Trees_With_Data;
with Generic_Stack;
package Code_Interpreter is

   BAD_MACRO_CODE : exception;
      -- A handler at the top level main macro execution procedure logs and
      -- then displays the error in a pop-up whin this exception is raised.

   procedure Initialise_Interpreter(with_builder : in out Gtkada_Builder;
                        with_DB_Descr : GNATCOLL.SQL.Exec.Database_Description;
                             reraise_exception : boolean := false);
      -- Load the macros into memory and otherwise set up the interpreter ready
      -- for operation.  That includes stripping out comments from the macros
      -- and simplifying spaces.  That also includes getting a handle to the
      -- pop-up, which will be utilised by Error_Log for displaying any error
      -- that raises the BAD_MACRO_CODE exception.  If reraise_exception is set
      -- to true, then the exception will be reraised after the pop-up is
      -- displayed.
      
   procedure Execute (the_cell : in out gtk_drawing_area;
                      the_macro_Number : in natural;
                      passed_in_parameter : in text);
      -- This main macro execution procedure the following parameters:
      --     1 The pointer to the currently selected cell;
      --     2 A pointer to the blob containing the instructions, as pointed to
      --       by the combining character button;
      --     3 The 'passed-in parameter', taken from the combining character
      --       button: if specified in the brackets after the procedure and its
      --       optional name, then extracted from the procedure call, if the
      --       brackets are provided but have no contents, extracted from the
      --       button's tool tip help text, otherwise set to 16#0000# (NULL).

private

   reraise_bad_macro_code_exception : boolean;
   
   multiply_ch: constant wide_character := wide_character'Val(16#00D7#); -- '×'
   divide_ch  : constant wide_character := wide_character'Val(16#00F7#); -- '÷'
   null_ch    : constant wide_character := wide_character'Val(16#0000#);
    
   type reserved_words_and_attributes is
           (cNull, cEQUATION, cPROCEDURE, cEND, cIF, cINSERT, cREPLACE, 
            cDELETE, cFOR, cEXIT, cELSE, cELSIF, cERROR_LOG, 
            cIS, cLOOP, cTHEN, cREVERSE, cWITH, cCHAR, cFIND, cWIDTH, cIN, 
            cLength, cSize, cFirst, cLast);
   subtype reserved_words is reserved_words_and_attributes range cNull..cIN;
   subtype command_set is reserved_words range cNull .. cERROR_LOG;
   subtype function_set is reserved_words_and_attributes range cCHAR .. cLast;
   type reserved_word_list is array (reserved_words) of text;
   all_reserved_words : constant reserved_word_list := 
      (Value("NULL"), Value(""), Value("PROCEDURE"), Value("END"), Value("IF"),
       Value("INSERT"), Value("REPLACE"), Value("DELETE"), Value("FOR"), 
       Value("EXIT"), Value("ELSE"), Value("ELSIF"), Value("ERROR_LOG"), 
       Value("IS"), Value("LOOP"), Value("THEN"), Value("REVERSE"), 
       Value("WITH"), 
       Value("CHAR"), Value("FIND"), Value("WIDTH"), Value("IN"));
   subtype register_attributes is 
                            reserved_words_and_attributes range cLength..cLast;
   type attributes_list is array (register_attributes) of text;
   all_attributes : constant attributes_list :=
      (Value("'LENGTH"), Value("'SIZE"), Value("'FIRST"), Value("'LAST"));
   type mathematical_operator is (none, assign, plus, minus, multiply,
                                  divide, concat, logical_and, logical_or, 
                                  logical_not, ellipses, 
                                  greater_equal, greater, less_equal, 
                                  less, equals, range_condition);
   type mathematical_operator_list is array (mathematical_operator) of text;
   all_maths_operators : constant mathematical_operator_list :=
      (Clear, Value(":="), Value("+"), Value("-"), to_text(multiply_ch), 
       to_text(divide_ch), Value("&"), Value("AND"), Value("OR"), Value("NOT"), 
       Value(".."), Value(">="), Value(">"), Value("<="), Value("<"), 
       Value("="), Value("IN"));
   subtype numeric_operator    is mathematical_operator range plus .. divide;
   subtype logical_operator    is mathematical_operator range 
                                              logical_and .. logical_not;
   subtype comparison_operator is mathematical_operator range 
                                              greater_equal .. range_condition;
   type all_register_names is (const, H, S, A, B, C, D, E, F, G, Y);
   register_ids : constant array (all_register_names'Range) of wide_character:=
        (' ', 'H', 'S', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'Y');
   subtype register_name is all_register_names range H .. G;
   type for_loop_directions is (forward, in_reverse);
   
   type cmd_block(cmd : command_set := cNull);
   type code_block is access all cmd_block;
   
   type number_type is (character_type, integer_type, float_type, null_type);
   type equation_format is (none, mathematical, logical, textual, funct, 
                            bracketed, comparison);
   type equation_type(eq : equation_format := mathematical);
   type equation_access is access all equation_type;
   register_types:constant array (all_register_names'Range) of equation_format:=
        (none, textual, textual, mathematical, mathematical, mathematical,
         mathematical, mathematical, textual, textual, logical);
   type equation_type(eq : equation_format := mathematical) is record
         register : all_register_names := const;
         reg_parm : equation_access := null;  -- sub-component of reg., if any
         operator : mathematical_operator;
         equation : equation_access := null;  -- forward pointer
         last_equ : equation_access := null;  -- backwards pointer
         num_type : number_type := float_type;
         case eq is
            when mathematical => 
               m_const  : long_float := 0.0;
               m_result : long_float := 0.0;
            when logical      =>  
               l_const  : boolean    := false;
               l_result : boolean    := false;
               l_pos    : wide_character := null_ch;
            when textual      =>  
               t_const  : text;
               t_result : text;
            when bracketed    =>
               b_equation : equation_access := null;
            when funct        =>
               f_type   : function_set;
               f_param1 : equation_access;
               f_param2 : equation_access;
               f_result : long_float := 0.0;
            when comparison   =>  
               c_const  : boolean    := false;
               c_result : boolean    := false;
               c_lhs    : equation_access := null;
               c_rhs    : equation_access := null;
            when none =>
               null;
         end case; 
      end record;
    
   type link_to_positions is (proc_body, then_part, else_part, else_parent, 
                              else_block, ethen_part, parent_if, eelse_part,
                              for_block, exit_point, next_command);
   type cmd_block(cmd : command_set := cNull) is record
         next_command : code_block;
         last_command : code_block;
         case cmd is
            when cNull =>
               null;
            when cEQUATION =>
               equation : equation_access;
            when cPROCEDURE =>
               proc_name   : text;
               parameter   : text;
               proc_body   : code_block;
            when cEND =>
               end_type    : command_set;  -- IF/FOR/PROCEDURE
               parent_block: code_block;
               exit_is_set : boolean := false;
            when cIF =>
               condition   : equation_access;  -- : expression(boolean);
               then_part   : code_block;  -- The THEN Block of code
               else_part   : code_block;  -- points to next ELSIF/ELSE block
               -- next_command points to END (IF)
            when cELSE =>  -- this pops back to the cIF block's end
               else_parent : code_block;  -- prior ELSIF/IF command (path back)
               else_block  : code_block;  -- The ELSE Block of code
               -- next_command points to END (IF)
            when cELSIF =>  -- this chains off next_command from cIF
               econdition  : equation_access;
               ethen_part  : code_block;  -- The ELSIF Block of code
               parent_if   : code_block;  -- prior ELSIF/IF command (path back)
               eelse_part  : code_block;  -- next elsif or else or end block
               -- next_command points to END (IF)
            when cINSERT =>
               i_reg : register_name := S;
               i_pos : equation_access;
               i_val : all_register_names := const;
               i_data: equation_access;  -- equation_type;
            when cREPLACE =>
               r_reg : register_name := S;
               r_pos : equation_access;
               r_val : all_register_names := const;
               r_data: equation_access;  -- equation_type;
            when cDELETE =>
               d_reg       : register_name := S;
               d_position  : equation_access;
            when cFOR =>
               for_reg     : register_name;
               f_start     : equation_access;
               f_end       : equation_access;
               direction   : for_loop_directions := forward;
               for_block   : code_block;
               exit_for    : boolean := false;  -- Set by the cEXIT command
               -- f_pointer   : integer;  -- current point in FOR loop
            when cEXIT =>
               exit_point  : code_block;  -- FOR statement that this applies to
               exit_parent : code_block;  -- prior IF/ELSIF/ELSE/FOR command
            when cERROR_LOG =>
               e_reg : all_register_names := const;
               e_val : text;
         end case;
      end record;
    
   function LessThan(a, b : in natural) return boolean;
   package Macro_Lists is new 
        Generic_Binary_Trees_With_Data(T=>natural,D=>code_block,"<"=>LessThan);
   subtype macro_list is Macro_Lists.list;
   function AtM(macros : macro_list; m : in natural) return code_block;
      -- AtM(acro): Deliver macro number m from the macro_list macros.
   the_macros : macro_list;
   
   type register_type(reg : all_register_names);
   type register_access is access register_type;
   type register_type(reg : all_register_names) is record
         case reg is
            when A .. E =>
               reg_f : long_float := 0.0;
            when G | H | S =>
               reg_t : text := Clear;
            when F => 
               reg_c : wide_character := null_ch;
            when Y =>
               reg_b : boolean := false;
            when const =>
               null;
         end case;
      end record;
   type register_array is array (all_register_names) of register_access;
   procedure Initialise(the_registers : out register_array);
      -- set the discrimanent for each position to match the position
  
   procedure Strip_Comments_And_Simplify_Spaces(for_macro : in out text);
      -- Strip out all comments, indicated by '--' and terminated by an end of
      -- line character, then go through and, knowing that commands are
      -- separated by the ';' character, replace all multiple spaces type
      -- characters, including end of line and tab characters, with a single
      -- space character (or no character on either side of a ';' character).
   
   procedure Load_Macro(into : out code_block; from : in text);
      -- Load the textual macro into a command block structure, effectively
      -- doing a first pass structural check on the macro.  If there is any
      -- issue, then the BAD_MACRO_CODE exception is raised.
   
   -- The command stack is used to track (through pushing and popping) where
   -- the second pass code interpreter (which is executed as the last pass of
   -- Initialise_Interpreter) is up to in terms of procedures, if/then/elsif/
   -- else statements, for loops and bracket sets in bracketed equations.
   type stack_data is record
         command : command_set;  -- quick access to the relevant command
         parent  : code_block;   -- the parent to which this command applies
      end record;
   empty_stack : constant stack_data := (cNull, null);
      
   package Command_Stack is new Generic_Stack(T => stack_data, 
                                              empty_item => empty_stack);
   
   -- The CHAR command is essentially about getting the size of a character.
   -- It returns the first character after that specified with a close matching
   -- size.  As this data is not really readily avialable from the font
   -- information, so we keep a table of values for key items.  Here, the space
   -- (' ') character is assumed to have a width of 1, just as are all non-
   -- combining characters that are not Blissymbolics characters, along with
   -- the full-width Blissymbolic full space character.  The other Blissymbolic
   -- space characters are given a size accordingly.
   type char_size is record
         the_char : wide_character;
         size     : long_float := 1.0;
      end record;
   type char_size_array is array (positive range <>) of char_size;
   char_sizes : constant char_size_array :=
                         ((' ',1.0),
                          (wide_character'Val(16#E100#),1.0),  -- bliss_space
                          (wide_character'Val(16#E101#),0.5),  -- bliss_hspace
                          (wide_character'Val(16#E102#),0.25), -- 1/4 space
                          (wide_character'Val(16#E103#),0.125),-- 1/8 space
                          (wide_character'Val(16#E104#),5.0/48.0),
                          (wide_character'Val(16#E105#),1.0/48.0),
                          (wide_character'Val(16#E106#),0.0),
                          (wide_character'Val(16#E18C#),0.0),
                          (wide_character'Val(16#E18D#),1.0));

   procedure Execute (the_macro : in out code_block;
                      on_registers : in out register_array);
      -- This main macro execution procedure the following parameters:
      --     1 The pointer to the currently selected cell;
      --     2 A pointer to the blob containing the instructions, as pointed to
      --       by the combining character button;
      --     3 The 'passed-in parameter', taken from the combining character
      --       button: if specified in the brackets after the procedure and its
      --       optional name, then extracted from the procedure call, if the
      --       brackets are provided but have no contents, extracted from the
      --       button's tool tip help text, otherwise set to 16#0000# (NULL).
      -- This Execute procedure is built to be recursive, and is called by the
      -- abive (public) shell Execute procedure that simply sets up the data
      -- and, after this Execute operation has run its course, saves the result
      -- back to the currently active cell.
   
end Code_Interpreter;
