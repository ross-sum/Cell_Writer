-----------------------------------------------------------------------
--                                                                   --
--                          K E Y B O A R D                          --
--                                                                   --
--                     S p e c i f i c a t i o n                     --
--                                                                   --
--                           $Revision: 1.0 $                        --
--                                                                   --
--  Copyright (C) 2022  Hyper Quantum Pty Ltd.                       --
--  Written by Ross Summerfield.                                     --
--                                                                   --
--  This  package displays the keyboard, which allows the  user  to  --
--  select  a  character by cliking on it.  For  Blissymbolics,  it  --
--  contains  a shift level radio button to enable further  refined  --
--  selection.   This means that the key is obvious and you do  not  --
--  have to try to interpret the likely location.                    --
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
--  General Public Licence distributed with  Urine_Records. If not,  --
--  write  to  the Free Software Foundation,  51  Franklin  Street,  --
--  Fifth Floor, Boston, MA 02110-1301, USA.                         --
--                                                                   --
-----------------------------------------------------------------------
with dStrings;        use dStrings;
with GLib;            use GLib;
with Gtkada.Builder;  use Gtkada.Builder;
with GNATCOLL.SQL.Exec;
with Set_of;
with Key_Sym_Def;     use Key_Sym_Def;
with Ada.Unchecked_Conversion;
package Keyboard is

   -- Some notable keys that are used generally across the application
   enter_key : constant Wide_Character := From_Key_ID(XK_Return);   -- 16#0D#
   esc_key   : constant Wide_Character := From_Key_ID(XK_Escape);   -- 16#1B#
   tab_key   : constant Wide_Character := From_Key_ID(XK_Tab);       --16#09#
   bs_key    : constant Wide_Character := From_Key_ID(XK_BackSpace); --16#08#
   null_char : constant wide_character := wide_character'Val(16#00#);
   
   -- To simplify internal communications, complex keys like the function keys
   -- and the more complex of cursor movement keys are assigned a small unused
   -- block of unicode characters in the unicode tree.  These are set in the
   -- stanadard XWindow keysy  list.
   -- These characters are converted at final load time.
   start_reserved_char : constant Wide_Character := 
                                     From_Key_ID(key_sym_list'First);
   end_reserved_char   : constant Wide_Character :=
                                     From_Key_ID(key_sym_list'Last);

   -- Shift levels are the "shift key" position to stick the character entered.
   -- It is primarily applicable to the Blissymbolics language.
   type shift_level_types is (space, above_sky, sky, below_sky, upper, middle,
                              lower, ground, just_below_ground, below_ground,
                              core);
   
   subtype key_id_byte is integer range 16#04#..16#F5#;
   -- The Key IDs are those identifiers that are returned by a USB keyboard
   -- These IDs are used to work out what characters to display, depending on
   -- the language chosen, and also what key character to return in response to
   -- a key press.
   type key_id_types is (key_04, key_05, key_06, key_07, key_08, key_09, key_0A,
                         key_0B, key_0C, key_0D, key_0E, key_0F, key_10, key_11,
                         key_12, key_13, key_14, key_15, key_16, key_17, key_18,
                         key_19, key_1A, key_1B, key_1C, key_1D, key_1E, key_1F,
                         key_20, key_21, key_22, key_23, key_24, key_25, key_26,
                         key_27, key_28, key_29, key_2A, key_2B, key_2C, key_2D,
                         key_2E, key_2F, key_30, key_31, key_33, key_34, key_35,
                         key_36, key_37, key_38, key_39, key_3A, key_3B, key_3C,
                         key_3D, key_3E, key_3F, key_40, key_41, key_42, key_43,
                         key_44, key_45, key_46, key_47, key_48, key_49, key_4A,
                         key_4B, key_4C, key_4D, key_4E, key_4F, key_50, key_51,
                         key_52, key_53, key_54, key_55, key_56, key_57, key_58,
                         key_59, key_5A, key_5B, key_5C, key_5D, key_5E, key_5F,
                         key_60, key_61, key_62, key_63, key_67, key_76, key_B1,
                         key_BB, key_E0, key_E1, key_E2, key_E3, key_E4, key_E5,
                         key_E6, key_F0, key_F1, key_F2, key_F3, key_F4, key_F5);
   for key_id_types use (16#04#, 16#05#, 16#06#, 16#07#, 16#08#, 16#09#, 16#0A#,
                         16#0B#, 16#0C#, 16#0D#, 16#0E#, 16#0F#, 16#10#, 16#11#,
                         16#12#, 16#13#, 16#14#, 16#15#, 16#16#, 16#17#, 16#18#,
                         16#19#, 16#1A#, 16#1B#, 16#1C#, 16#1D#, 16#1E#, 16#1F#,
                         16#20#, 16#21#, 16#22#, 16#23#, 16#24#, 16#25#, 16#26#,
                         16#27#, 16#28#, 16#29#, 16#2A#, 16#2B#, 16#2C#, 16#2D#,
                         16#2E#, 16#2F#, 16#30#, 16#31#, 16#33#, 16#34#, 16#35#,
                         16#36#, 16#37#, 16#38#, 16#39#, 16#3A#, 16#3B#, 16#3C#,
                         16#3D#, 16#3E#, 16#3F#, 16#40#, 16#41#, 16#42#, 16#43#,
                         16#44#, 16#45#, 16#46#, 16#47#, 16#48#, 16#49#, 16#4A#,
                         16#4B#, 16#4C#, 16#4D#, 16#4E#, 16#4F#, 16#50#, 16#51#,
                         16#52#, 16#53#, 16#54#, 16#55#, 16#56#, 16#57#, 16#58#,
                         16#59#, 16#5A#, 16#5B#, 16#5C#, 16#5D#, 16#5E#, 16#5F#,
                         16#60#, 16#61#, 16#62#, 16#63#, 16#67#, 16#76#, 16#B1#,
                         16#BB#, 16#E0#, 16#E1#, 16#E2#, 16#E3#, 16#E4#, 16#E5#,
                         16#E6#, 16#F0#, 16#F1#, 16#F2#, 16#F3#, 16#F4#, 16#F5#);

   -- Because we have made a one-to-one mapping between the enumerated type for
   -- each key on the keyboard and the underlying number for the key code (as
   -- defined in the USB code for the key), conversion is not by the 'Val/'Pos
   -- attribute but rather by a straight (unchecked) conversion.
   function To_Key_ID is new Ada.Unchecked_Conversion(key_id_byte, key_id_types);
   function From_Key_ID is new Ada.Unchecked_Conversion(key_id_types,key_id_byte);

   -- Because the numeric key pad is not a contiguous list of key identifiers,
   -- the Set_Of package is used to contain the set of key identifiers that are
   -- components of the numeric keypad.
   type key_list is array (positive range <>) of key_id_types;
   package Key_Sets is new Set_Of(Element => key_id_types,
                                  Index   => positive,
                                  List    => key_list);
   use Key_Sets;
   subtype keypad_set  is Key_Sets.Set;
   -- Keypad to the right of the keyboard (not including the separate cursor
   -- keys).
   keypad_keys : keypad_set := Make_Set(key_54, key_63) + Make_Set(key_67) + 
                               Make_Set(key_B1) + Make_Set(key_BB);
      -- that is, the set is key_54..key_63, key_67, key_B1, key_BB.
   subtype keypad_key_pt_range is key_id_types range key_54 .. key_63;
   -- The cursor keys, on the other hand, are a contiguous block, so can be
   -- treated as a simple sub-type of key_id_types.
   cursor_keys : keypad_set := Make_Set(key_46, key_52);
   subtype cursor_key_range is key_id_types range key_46 .. key_52;
   -- The keys that have a fixed value are not contiguous.  These are the
   -- Enter/Return, Esc, Tab, Backspace, space bar Caps Lock, Left and right
   -- shifts, left and right control and alt keys, and the Super (windows) key.
   static_keys : keypad_set := Make_Set(key_28, key_2C) + Make_Set(key_76);
   toggle_keys : keypad_set := Make_Set(key_39) + Make_Set(key_53) + 
                               Make_Set(key_E0, key_E6);
   subtype toggle_key_pt_range is key_id_types range key_E0 .. key_E6;
   function_keys : keypad_set := Make_Set(key_3A, key_45);
   subtype function_key_range is key_id_types range key_3A .. key_45;
   space_keys  : keypad_set := Make_Set(key_F0, key_F5);
   subtype space_key_range is key_id_types range key_F0 .. key_F5;
   
   -- The keys that are used for the different character sets are all the
   -- other keys
   keyboard_keys : keypad_set := ((((Full - keypad_keys) - cursor_keys) - 
                                     static_keys) - toggle_keys)-function_keys;
   
   -- Define the characters to both display and to return when a key is pressed
   type character_results is array (shift_level_types'Range) of wide_character;
   type key_character_display is record
         unshifted_display   : text;
         unshifted_result    : character_results;
         shifted_display     : text;
         shifted_result      : character_results;
      end record;
   type key_character_types is array (key_id_types'Range) of key_character_display;

   procedure Initialise_Keyboard(Builder : in out Gtkada_Builder;
                             DB_Descr: GNATCOLL.SQL.Exec.Database_Description);
   procedure Resize_Grid (to_rows, to_cols : natural);
      -- Store the new rows and columns to match the grid size
   procedure Show_Keyboard(Builder : in Gtkada_Builder);
   procedure Load_Keyboard(for_language : in positive;
                           at_object: Gtkada_Builder);
       -- Loads the keyboard key display characters and definitions from the
       --  database

private
    -- control variables
   shift_level    : shift_level_types := middle;
   
   -- to make character mapping easier, the following characters are converted
   -- back to their numerical values, since they are actually offsets.
   start_reserved_pos : constant natural := 
                                 wide_character'Pos(start_reserved_char);
   end_reserved_pos   : constant natural := 
                                 wide_character'Pos(end_reserved_char);

   -- Noting that a number of characters will be represented by characters
   -- from the X11/keysymdef.h (reproduced into the key_sym_def library), 
   -- define these characters here
   insert_char   : constant wide_character := From_Key_ID(XK_Insert);
   delete_char   : constant wide_character := From_Key_ID(XK_Delete);
   -- backsp_char   : constant wide_character := wide_character'Val(16#08#);
   left_arrow    : constant wide_character := From_Key_ID(XK_Left);
   right_arrow   : constant wide_character := From_Key_ID(XK_Right);
   up_arrow      : constant wide_character := From_Key_ID(XK_Up);
   down_arrow    : constant wide_character := From_Key_ID(XK_Down);
   home_char     : constant wide_character := From_Key_ID(XK_Home);
   end_char      : constant wide_character := From_Key_ID(XK_End);
   page_up       : constant wide_character := From_Key_ID(XK_Page_Up);
   page_down     : constant wide_character := From_Key_ID(XK_Page_Down);
   -- special temporary codes for "000" and "00"
   kpad_000      : constant wide_character := wide_character'Val(16#0E#);
   kpad_00       : constant wide_character := wide_character'Val(16#0F#);
   
   -- The "pictures" (actually Unicode characters that represent the key) to
   -- display on the key.
   lf_arrow_chr : constant text := to_text(wide_character'Val(16#2190#));
   rt_arrow_chr : constant text := to_text(wide_character'Val(16#2192#));
   up_arrow_chr : constant text := to_text(wide_character'Val(16#2191#));
   dn_arrow_chr : constant text := to_text(wide_character'Val(16#2193#));
   bkspc_chr    : constant text := to_text(wide_character'Val(16#21D0#));
   enter_chr    : constant text := to_text(wide_character'Val(16#21B2#));
   -- Default parameters (that is, key responses to key presses) for the keypad
   -- and cursor keys, and also the function keys.  These keys likely never 
   -- change irrespective of the language in use (although symbols might).
   key_nil_uadef:character_results:= (others => null_char);
   key_nil_def: key_character_display := (Clear, key_nil_uadef, Clear, key_nil_uadef);
   key_39_def : key_character_display := (Value("CapsLk"), key_nil_uadef, Value("CapsLk"), key_nil_uadef);
   key_E1_def : key_character_display := (Value("Shift"), key_nil_uadef, Value("Shift"), key_nil_uadef);
   key_E5_def : key_character_display := (Value("Shift"), key_nil_uadef, Value("Shift"), key_nil_uadef);
   key_E0_def : key_character_display := (Value("Ctrl"), key_nil_uadef, Value("Ctrl"), key_nil_uadef);
   key_E4_def : key_character_display := (Value("Ctrl"), key_nil_uadef, Value("Ctrl"), key_nil_uadef);
   key_E2_def : key_character_display := (Value("Alt"), key_nil_uadef, Value("Alt"), key_nil_uadef);
   key_E6_def : key_character_display := (Value("Alt"), key_nil_uadef, Value("Alt"), key_nil_uadef);
   key_E3_def : key_character_display := (Value("Su"), key_nil_uadef, Value("Su"), key_nil_uadef);
   key_28_uadef:character_results := (others => enter_key);
   key_28_def : key_character_display := (Value("Enter"), key_28_uadef, Value("Enter"), key_28_uadef);
   key_29_uadef:character_results := (others => esc_key);
   key_29_def : key_character_display := (Value("Esc"), key_29_uadef, Value("Esc"), key_29_uadef);
   key_2A_uadef:character_results := (others => bs_key);
   key_2A_def : key_character_display := (Value("BkSp"), key_2A_uadef, Value("BkSp"), key_2A_uadef);
   key_2B_uadef:character_results := (others => tab_key);
   key_2B_def : key_character_display := (Value("Tab"), key_2B_uadef, Value("Tab"), key_2B_uadef);
   key_2C_uadef:character_results := (others => ' ');  -- Space bar
   key_2C_def : key_character_display := (Value(" "), key_2C_uadef, Value(" "), key_2C_uadef);
   key_3A_udef: character_results := ((middle) => From_Key_ID(XK_F1),
                                      others => null_char);
   key_3A_sdef: character_results := ((middle) => From_Key_ID(XK_F21),
                                      others => null_char);
   key_3A_def : key_character_display := (Value("F1"), key_3A_udef, Value("F1"), key_3A_sdef);
   key_3B_udef: character_results := ((middle) => From_Key_ID(XK_F2), 
                                      others => null_char);
   key_3B_sdef: character_results := ((middle) => From_Key_ID(XK_F22),
                                      others => null_char);
   key_3B_def : key_character_display := (Value("F2"), key_3B_udef, Value("F2"), key_3B_sdef);
   key_3C_udef: character_results := ((middle) => From_Key_ID(XK_F3),
                                      others => null_char);
   key_3C_sdef: character_results := ((middle) => From_Key_ID(XK_F23),
                                      others => null_char);
   key_3C_def : key_character_display := (Value("F3"), key_3C_udef, Value("F3"), key_3C_sdef);
   key_3D_udef: character_results := ((middle) => From_Key_ID(XK_F4),
                                      others => null_char);
   key_3D_sdef: character_results := ((middle) => From_Key_ID(XK_F24),
                                      others => null_char);
   key_3D_def : key_character_display := (Value("F4"), key_3D_udef, Value("F4"), key_3D_sdef);
   key_3E_udef: character_results := ((middle) => From_Key_ID(XK_F5),
                                      others => null_char);
   key_3E_sdef: character_results := ((middle) => From_Key_ID(XK_F25),
                                      others => null_char);
   key_3E_def : key_character_display := (Value("F5"), key_3E_udef, Value("F5"), key_3E_sdef);
   key_3F_udef: character_results := ((middle) => From_Key_ID(XK_F6),
                                      others => null_char);
   key_3F_sdef: character_results := ((middle) => From_Key_ID(XK_F26),
                                      others => null_char);
   key_3F_def : key_character_display := (Value("F6"), key_3F_udef, Value("F6"), key_3F_sdef);
   key_40_udef: character_results := ((middle) => From_Key_ID(XK_F7),
                                      others => null_char);
   key_40_sdef: character_results := ((middle) => From_Key_ID(XK_F27),
                                      others => null_char);
   key_40_def : key_character_display := (Value("F7"), key_40_udef, Value("F7"), key_40_sdef);
   key_41_udef: character_results := ((middle) => From_Key_ID(XK_F8),
                                      others => null_char);
   key_41_sdef: character_results := ((middle) => From_Key_ID(XK_F28),
                                      others => null_char);
   key_41_def : key_character_display := (Value("F8"), key_41_udef, Value("F8"), key_41_sdef);
   key_42_udef: character_results := ((middle) => From_Key_ID(XK_F9),
                                      others => null_char);
   key_42_sdef: character_results := ((middle) => From_Key_ID(XK_F29),
                                      others => null_char);
   key_42_def : key_character_display := (Value("F9"), key_42_udef, Value("F9"), key_42_sdef);
   key_43_udef: character_results := ((middle) => From_Key_ID(XK_F10),
                                      others => null_char);
   key_43_sdef: character_results := ((middle) => From_Key_ID(XK_F30),
                                      others => null_char);
   key_43_def : key_character_display := (Value("F10"), key_43_udef, Value("F10"), key_43_sdef);
   key_44_udef: character_results := ((middle) => From_Key_ID(XK_F11),
                                      others => null_char);
   key_44_sdef: character_results := ((middle) => From_Key_ID(XK_F31),
                                      others => null_char);
   key_44_def : key_character_display := (Value("F11"), key_44_udef, Value("F11"), key_44_sdef);
   key_45_udef: character_results := ((middle) => From_Key_ID(XK_F12),
                                      others => null_char);
   key_45_sdef: character_results := ((middle) => From_Key_ID(XK_F32),
                                      others => null_char);
   key_45_def : key_character_display := (Value("F12"), key_45_udef, Value("F12"), key_45_sdef);
   key_46_udef: character_results := ((middle) => From_Key_ID(XK_Print),
                                      others => null_char);
   key_46_sdef: character_results := ((middle) => From_Key_ID(XK_Print),
                                      others => null_char);
   key_46_def : key_character_display := (Value("PSc"), key_46_udef, Value("PSc"), key_46_sdef);
   key_47_udef: character_results := ((middle) => From_Key_ID(XK_Scroll_Lock),
                                      others => null_char);
   key_47_sdef: character_results := ((middle) => From_Key_ID(XK_Scroll_Lock),
                                      others => null_char);
   key_47_def : key_character_display := (Value("SLk"), key_47_udef, Value("SLk"), key_47_sdef);
   key_48_udef: character_results := ((middle) => From_Key_ID(XK_Break),
                                      others => null_char);
   key_48_sdef: character_results := ((middle) => From_Key_ID(XK_Break),
                                      others => null_char);
   key_48_def : key_character_display := (Value("Brk"), key_48_udef, Value("Brk"), key_48_sdef);
   key_76_uadef: character_results := (others => From_Key_ID(XK_Menu));
   key_76_def : key_character_display := (Value("Mn"), key_76_uadef, Value("Mn"), key_76_uadef);
   key_53_def : key_character_display := (Value("NL"), key_nil_uadef, Value("NL"), key_nil_uadef);
   key_49_uadef:character_results := (others => insert_char); -- navigation key
   key_49_def : key_character_display := (Value("Ins"), key_49_uadef, Value("Ins"), key_49_uadef);
   key_4A_uadef:character_results := (others => home_char);   -- navigation key
   key_4A_def : key_character_display := (Value("Hm"), key_4A_uadef, Value("Hm"), key_4A_uadef);
   key_4B_uadef:character_results := (others => page_up);     -- navigation key
   key_4B_def : key_character_display := (Value("PU"), key_4B_uadef, Value("PU"), key_4B_uadef);
   key_4C_uadef:character_results := (others => delete_char); -- navigation key
   key_4C_def : key_character_display := (Value("Del"), key_4C_uadef, Value("Del"), key_4C_uadef);
   key_4D_uadef:character_results := (others => end_char);    -- navigation key
   key_4D_def : key_character_display := (Value("End"), key_4D_uadef, Value("End"), key_4D_uadef);
   key_4E_uadef:character_results := (others => page_down);  -- navigation key
   key_4E_def : key_character_display := (Value("PD"), key_4E_uadef, Value("PD"), key_4E_uadef);
   key_4F_uadef:character_results := (others => right_arrow); -- navigation key
   key_4F_def : key_character_display := (rt_arrow_chr, key_4F_uadef, rt_arrow_chr, key_4F_uadef);
   key_50_uadef:character_results := (others => left_arrow);  -- navigation key
   key_50_def : key_character_display := (lf_arrow_chr, key_50_uadef, lf_arrow_chr, key_50_uadef);
   key_51_uadef:character_results := (others => down_arrow);  -- navigation key
   key_51_def : key_character_display := (dn_arrow_chr, key_51_uadef, dn_arrow_chr, key_51_uadef);
   key_52_uadef:character_results := (others => up_arrow);    -- navigation key
   key_52_def : key_character_display := (up_arrow_chr, key_52_uadef, up_arrow_chr, key_52_uadef);
   key_54_uadef:character_results := (others => '/');  -- keypad '/'
   key_54_def : key_character_display := (Value("/"), key_54_uadef, Value("/"), key_54_uadef);
   key_55_uadef:character_results := (others => '*');  -- keypad '*'
   key_55_def : key_character_display := (Value("*"), key_55_uadef, Value("*"), key_55_uadef);
   key_56_uadef:character_results := (others => '-');  -- keypad '-'
   key_56_def : key_character_display := (Value("-"), key_56_uadef, Value("-"), key_56_uadef);
   key_5F_udef: character_results := ((middle) => home_char, others => null_char);
   key_5F_sdef: character_results := ((middle) => '7', others => null_char);
   key_5F_def : key_character_display := (Value("Hm"), key_5F_udef, Value("7"), key_5F_sdef);
   key_60_udef: character_results := ((middle) => up_arrow, others => null_char);
   key_60_sdef: character_results := ((middle) => '8', others => null_char);
   key_60_def : key_character_display := (up_arrow_chr, key_60_udef, Value("8"), key_60_sdef);
   key_61_udef: character_results := ((middle) => page_up, others => null_char);
   key_61_sdef: character_results := ((middle) => '9', others => null_char);
   key_61_def : key_character_display := (Value("PU"), key_61_udef, Value("9"), key_61_sdef);
   key_57_uadef:character_results := (others => '+');  -- keypad '+'
   key_57_def : key_character_display := (Value("+"), key_57_uadef, Value("+"), key_57_uadef);
   key_5C_udef: character_results := ((middle) => left_arrow, others => null_char);
   key_5C_sdef: character_results := ((middle) => '4', others => null_char);
   key_5C_def : key_character_display := (lf_arrow_chr, key_5C_udef, Value("4"), key_5C_sdef);
   key_5D_udef: character_results := ((middle) => '5', others => null_char);
   key_5D_sdef: character_results := ((middle) => '5', others => null_char);
   key_5D_def : key_character_display := (Value("5"), key_5D_udef, Value("5"), key_5D_sdef);
   key_5E_udef: character_results := ((middle) => right_arrow, others => null_char);
   key_5E_sdef: character_results := ((middle) => '6', others => null_char);
   key_5E_def : key_character_display := (rt_arrow_chr, key_5E_udef, Value("6"), key_5E_sdef);
   key_BB_uadef:character_results := (others => bs_key);  -- keypad '<-'
   key_BB_def : key_character_display := (Value("<-"), key_BB_uadef, bkspc_chr, key_BB_uadef);
   key_59_udef: character_results := ((middle) => end_char, others => null_char);
   key_59_sdef: character_results := ((middle) => '1', others => null_char);
   key_59_def : key_character_display := (Value("End"), key_59_udef, Value("1"), key_59_sdef);
   key_5A_udef: character_results := ((middle) => down_arrow, others => null_char);
   key_5A_sdef: character_results := ((middle) => '2', others => null_char);
   key_5A_def : key_character_display := (dn_arrow_chr, key_5A_udef, Value("2"), key_5A_sdef);
   key_5B_udef: character_results := ((middle) => page_down, others => null_char);
   key_5B_sdef: character_results := ((middle) => '3', others => null_char);
   key_5B_def : key_character_display := (Value("PD"), key_5B_udef, Value("3"), key_5B_sdef);
   key_67_uadef:character_results := (others => '=');  -- keypad '='
   key_67_def : key_character_display := (Value("="), key_67_uadef, Value("="), key_67_uadef);
   key_62_udef: character_results := ((middle) => insert_char, others => null_char);
   key_62_sdef: character_results := ((middle) => '0', others => null_char);
   key_62_def : key_character_display := (Value("Ins"), key_62_udef, Value("0"), key_62_sdef);
   key_B1_udef:character_results := (others => kpad_000);  -- keypad '000'
   key_B1_sdef:character_results := (others => kpad_00);  -- keypad '000'
   key_B1_def : key_character_display := (Value("000"), key_B1_udef, Value("00"), key_B1_sdef);
   key_63_udef: character_results := ((middle) => delete_char, others => null_char);
   key_63_sdef: character_results := ((middle) => '.', others => null_char);
   key_63_def : key_character_display := (Value("Del"), key_63_udef, Value("."), key_63_sdef);
   key_58_uadef:character_results := (others => enter_key);  -- keypad '<-'
   key_58_def : key_character_display := (Value("Ent"), key_58_uadef, enter_chr, key_58_uadef);
   key_F0_uadef:character_results := (others => wide_character'Val(16#E100#));  -- full space
   key_F0_def : key_character_display := (Value("|____|"), key_F0_uadef, Value("|____|"), key_F0_uadef);
   key_F1_uadef:character_results := (others => wide_character'Val(16#E101#));  -- half space
   key_F1_def : key_character_display := (Value("|__|"), key_F1_uadef, Value("|__|"), key_F1_uadef);
   key_F2_uadef:character_results := (others => wide_character'Val(16#E102#));  -- quarter space
   key_F2_def : key_character_display := (Value("|_|"), key_F2_uadef, Value("|_|"), key_F2_uadef);
   key_F3_uadef:character_results := (others => wide_character'Val(16#E103#));  -- eighth space
   key_F3_def : key_character_display := (Value("|.|"), key_F3_uadef, Value("|.|"), key_F3_uadef);
   key_F4_uadef:character_results := (others => wide_character'Val(16#E104#));  -- five-forty eighth space
   key_F4_def : key_character_display := (Value("| |"), key_F4_uadef, Value("| |"), key_F4_uadef);
   key_F5_uadef:character_results := (others => wide_character'Val(16#E105#));  -- one-forty eighth space
   key_F5_def : key_character_display := (Value("||"), key_F5_uadef, Value("||"), key_F5_uadef);
   key_characters : key_character_types := (key_28 => key_28_def,
                                            key_29 => key_29_def,
                                            key_2A => key_2A_def,
                                            key_2B => key_2B_def,
                                            key_2C => key_2C_def,
                                            key_39 => key_39_def,
                                            key_3A => key_3A_def,
                                            key_3B => key_3B_def,
                                            key_3C => key_3C_def,
                                            key_3D => key_3D_def,
                                            key_3E => key_3E_def,
                                            key_3F => key_3F_def,
                                            key_40 => key_40_def,
                                            key_41 => key_41_def,
                                            key_42 => key_42_def,
                                            key_43 => key_43_def,
                                            key_44 => key_44_def,
                                            key_45 => key_45_def,
                                            key_46 => key_46_def,
                                            key_47 => key_47_def,
                                            key_48 => key_48_def,
                                            key_49 => key_49_def,
                                            key_4A => key_4A_def,
                                            key_4B => key_4B_def,
                                            key_4C => key_4C_def,
                                            key_4D => key_4D_def,
                                            key_4E => key_4E_def,
                                            key_4F => key_4F_def,
                                            key_50 => key_50_def,
                                            key_51 => key_51_def,
                                            key_52 => key_52_def,
                                            key_53 => key_53_def,
                                            key_54 => key_54_def,
                                            key_55 => key_55_def,
                                            key_56 => key_56_def,
                                            key_57 => key_57_def,
                                            key_58 => key_58_def,
                                            key_59 => key_59_def,
                                            key_5A => key_5A_def,
                                            key_5B => key_5B_def,
                                            key_5C => key_5C_def,
                                            key_5D => key_5D_def,
                                            key_5E => key_5E_def,
                                            key_5F => key_5F_def,
                                            key_60 => key_60_def,
                                            key_61 => key_61_def,
                                            key_62 => key_62_def,
                                            key_63 => key_63_def,
                                            key_67 => key_67_def,
                                            key_76 => key_76_def,
                                            key_B1 => key_B1_def,
                                            key_BB => key_BB_def,
                                            key_E0 => key_E0_def,
                                            key_E1 => key_E1_def,
                                            key_E2 => key_E2_def,
                                            key_E3 => key_E3_def,
                                            key_E4 => key_E4_def,
                                            key_E5 => key_E5_def,
                                            key_E6 => key_E6_def,
                                            key_F0 => key_F0_def,
                                            key_F1 => key_F1_def,
                                            key_F2 => key_F2_def,
                                            key_F3 => key_F3_def,
                                            key_F4 => key_F4_def,
                                            key_F5 => key_F5_def,                                            
                                            others => key_nil_def);
   
    -- The tool bar buttons and other buttons
   procedure Setup_Select_CB     (Object : access Gtkada_Builder_Record'Class);
   procedure Keyboard_Show_Help  (Object : access Gtkada_Builder_Record'Class);
   procedure Btn_Keys_UnClicked  (Object : access Gtkada_Builder_Record'Class);
   procedure Btn_Send_Characters (Object : access Gtkada_Builder_Record'Class);
   procedure Btn_Word_Selected   (Object : access Gtkada_Builder_Record'Class);
       -- When the Word Selected "Apply" button is clicked, add the word
       -- curently selected in the drop-down list to the output stream and update
       -- the display of the output stream.
   function Key_As_String(key : in key_id_types) return string;
   function Text_To_UTF8(for_text : in text)return Glib.UTF8_String;

    -- The modifier (caps lock, shift, control, alt) buttons
   procedure Toggle_Caps       (Object : access Gtkada_Builder_Record'Class);
       -- Display the keys in either the capitals state or the lower csse state
       -- depending on the status of the shift and caps lock keys.
   
    -- The shift level radio buttons
   procedure Shift_Level_Toggled(to_level : in shift_level_types;
                                 for_button: in string;
                               on_object : access Gtkada_Builder_Record'Class);
       -- Change the shift level to that selected.
   procedure Shift_Lvl_space   (Object : access Gtkada_Builder_Record'Class);
   procedure Shift_Lvl_asky    (Object : access Gtkada_Builder_Record'Class);
   procedure Shift_Lvl_sky     (Object : access Gtkada_Builder_Record'Class);
   procedure Shift_Lvl_bsky    (Object : access Gtkada_Builder_Record'Class);
   procedure Shift_Lvl_upper   (Object : access Gtkada_Builder_Record'Class);
   procedure Shift_Lvl_mid     (Object : access Gtkada_Builder_Record'Class);
   procedure Shift_Lvl_lower   (Object : access Gtkada_Builder_Record'Class);
   procedure Shift_Lvl_gnd     (Object : access Gtkada_Builder_Record'Class);
   procedure Shift_Lvl_jbgnd   (Object : access Gtkada_Builder_Record'Class);
   procedure Shift_Lvl_bgnd    (Object : access Gtkada_Builder_Record'Class);
   procedure Shift_Lvl_core    (Object : access Gtkada_Builder_Record'Class);
   
   procedure Toggle_Num_Lock   (Object : access Gtkada_Builder_Record'Class);
       -- Display the number pad keys in either numbers or movement arrows
       -- depending on the status of the num lock key.
    
    -- The fixed return keys (Function keys, space bar key(s), tab, backspace,
    -- menu, enter/return, escape, navigation keys and key pad keys)
   procedure Key_Clicked_CB_3A (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_3B (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_3C (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_3D (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_3E (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_3F (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_40 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_41 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_42 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_43 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_44 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_45 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_28 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_29 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_2A (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_2B (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_2C (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_76 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_46 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_47 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_48 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_49 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_4A (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_4B (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_4C (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_4D (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_4E (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_4F (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_50 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_51 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_52 (Object : access Gtkada_Builder_Record'Class);
    
    -- The keyboard buttons
   procedure Process_Key_Clicked(for_key  : in wide_character;
                                 at_object:access Gtkada_Builder_Record'Class);
       -- Code convert, if necessary, then transmit the key character to the
       -- buffer or the target application.
   procedure Key_Clicked(for_key_id : in key_id_types;
                         at_object: access Gtkada_Builder_Record'Class;
                         at_level : in shift_level_types := middle);
       -- Based on the control, alt and shift levels, determine the character
       -- clicked and then operate on the result.
   procedure Key_Clicked_CB_04 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_05 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_06 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_07 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_08 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_09 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_0A (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_0B (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_0C (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_0D (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_0E (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_0F (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_10 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_11 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_12 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_13 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_14 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_15 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_16 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_17 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_18 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_19 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_1A (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_1B (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_1C (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_1D (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_1E (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_1F (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_20 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_21 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_22 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_23 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_24 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_25 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_26 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_27 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_2D (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_2E (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_2F (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_30 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_31 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_33 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_34 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_35 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_36 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_37 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_38 (Object : access Gtkada_Builder_Record'Class);
    
    -- The keypad buttons
   procedure Key_Clicked_CB_54 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_55 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_56 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_5F (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_60 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_61 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_57 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_5C (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_5D (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_5E (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_BB (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_59 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_5A (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_5B (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_67 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_62 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_B1 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_63 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_58 (Object : access Gtkada_Builder_Record'Class);
    
    -- The space size buttons
   procedure Key_Clicked_CB_F0 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_F1 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_F2 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_F3 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_F4 (Object : access Gtkada_Builder_Record'Class);
   procedure Key_Clicked_CB_F5 (Object : access Gtkada_Builder_Record'Class);

   procedure Load_Words_List(for_language : in positive;
                             at_object: Gtkada_Builder);
       -- Load the list of words that pertain to the specified language.  This
       -- procedure is called by Load_Keyboard.
   procedure Load_Characters_List (for_language : in positive);
       -- Load the list of characters for this specified language into
       -- the grid training data.  This is essentially done here as a
       -- by-product of loading the keyboard, also done here because
       -- the load process needs to be done at the same time as the
       -- keyboard is loaded.
       -- This procedure is called by Load_Keyboard.

end Keyboard;
