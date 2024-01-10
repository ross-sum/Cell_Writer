-----------------------------------------------------------------------
--                                                                   --
--                          K E Y B O A R D                          --
--                                                                   --
--                              B o d y                              --
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
-- with dStrings;        use dStrings;
-- with Gtkada.Builder;  use Gtkada.Builder;
-- with GNATCOLL.SQL;
with GNATCOLL.SQL.Exec.Tasking, GNATCOLL.SQL_BLOB;
with Database;                   use Database;
with Error_Log, String_Conversions;
with Cell_Writer_Version;
with Help_About, Setup, Main_Menu, Cursor_Management, CSS_Management;
with Keyboard_Emulation;
with Grid_Training, Training_Samples;
with Glib.Values, Gdk.RGBA;
with Gtk.Widget, Gtk.Toggle_Tool_Button, Gtk.Toggle_Button;
with Gtk.Radio_Button, Gtk.Button, Gtk.Label, Gtk.GEntry, Gtk.Combo_Box;
with Gtk.Button_Box;
with Gtk.Tree_Model, Gtk.Tree_Selection, Gtk.List_Store;
-- with Gtk.Tree_Row_Reference;
with Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
with Pango.Font; --Pango.Attributes;
package body Keyboard is
   use GNATCOLL.SQL;

   kDB : GNATCOLL.SQL.Exec.Database_Connection;
   
   kb_layout_select : constant GNATCOLL.SQL.Exec.Prepared_Statement :=
      GNATCOLL.SQL.Exec.Prepare 
           (SQL_Select (Fields  => KeyDefinitions.Language & 
                                   KeyDefinitions.Key_ID & 
                                   KeyDefinitions.UnShiftDisp &
                                   KeyDefinitions.ShiftDisp &
                                   KeyDefinitions.USChrSpace & 
                                   KeyDefinitions.USChrASky &
                                   KeyDefinitions.USChrSky & 
                                   KeyDefinitions.USChrBSky &
                                   KeyDefinitions.USChrUpper &
                                   KeyDefinitions.USChrMiddle &
                                   KeyDefinitions.USChrLower &
                                   KeyDefinitions.USChrGround &
                                   KeyDefinitions.USChrJBGnd &
                                   KeyDefinitions.USChrBGnd &
                                   KeyDefinitions.USChrCore &
                                   KeyDefinitions.SChrSpace & 
                                   KeyDefinitions.SChrASky &
                                   KeyDefinitions.SChrSky & 
                                   KeyDefinitions.SChrBSky &
                                   KeyDefinitions.SChrUpper &
                                   KeyDefinitions.SChrMiddle &
                                   KeyDefinitions.SChrLower &
                                   KeyDefinitions.SChrGround &
                                   KeyDefinitions.SChrJBGnd &
                                   KeyDefinitions.SChrBGnd &
                                   KeyDefinitions.SChrCore,
                        From    => KeyDefinitions,
                        Where   => (KeyDefinitions.Language = Integer_Param(1)),
                        Order_By=> KeyDefinitions.Key_ID),
            On_Server => True,
            Use_Cache => True);
   kb_words_list : constant GNATCOLL.SQL.Exec.Prepared_Statement :=
      GNATCOLL.SQL.Exec.Prepare 
           (SQL_Select (Fields  => Words.Word & 
                                   Words.ID &
                                   Words.Description,
                        From    => Words,
                        Where   => (Words.Language = Integer_Param(1)),
                        Order_By=> Words.Word),
            On_Server => True,
            Use_Cache => True);
   chars_list : constant GNATCOLL.SQL.Exec.Prepared_Statement :=
      GNATCOLL.SQL.Exec.Prepare 
           (SQL_Select (Fields  => Languages.ID &
                                   Languages.Start &
                                   Languages.EndChar,
                        From    => Languages,
                        Where   => (Languages.ID = Integer_Param(1)),
                        Order_By=> Languages.Start),
            On_Server => True,
            Use_Cache => True);

   bliss_space_start : wide_character := Wide_Character'Val(16#E100#);
   bliss_space_end   : wide_character := Wide_Character'Val(16#E10F#);
   
   procedure Initialise_Keyboard(Builder : in out Gtkada_Builder;
                             DB_Descr: GNATCOLL.SQL.Exec.Database_Description) is
      use Cursor_Management;
   begin
      Error_Log.Debug_Data(at_level => 4, 
                           with_details=> "Initialise_Keyboard: Start");
      -- Set up: Open the relevant tables from the database
      kDB:=GNATCOLL.SQL.Exec.Tasking.Get_Task_Connection(Description=>DB_Descr);
      -- Register the handlers
      -- First, the tool bar
      Register_Handler(Builder      => Builder,
                       Handler_Name => "btn_kbd_setup_clicked_cb",
                       Handler      => Setup_Select_CB'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "kbd_help_about_select_cb",
                       Handler      => Keyboard_Show_Help'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "btn_kbd_keys_toggled_cb",
                       Handler      => Btn_Keys_UnClicked'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "btn_kbd_unicode_toggled_cb",
                       Handler      => Btn_Unicode_Clicked'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "btn_kbd_send_clicked_cb",
                       Handler      => Btn_Send_Characters'Access);
      -- Other buttons
      Register_Handler(Builder      => Builder,
                       Handler_Name => "btn_use_selected_word_clicked_cb",
                       Handler      => Btn_Word_Selected'Access);
      -- The shift level
      Register_Handler(Builder      => Builder,
                       Handler_Name => "shift_lvl_space_toggled_cb",
                       Handler      => Shift_Lvl_space'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "shift_lvl_asky_toggled_cb",
                       Handler      => Shift_Lvl_asky'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "shift_lvl_sky_toggled_cb",
                       Handler      => Shift_Lvl_sky'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "shift_lvl_bsky_toggled_cb",
                       Handler      => Shift_Lvl_bsky'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "shift_lvl_upper_toggled_cb",
                       Handler      => Shift_Lvl_upper'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "shift_lvl_mid_toggled_cb",
                       Handler      => Shift_Lvl_mid'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "shift_lvl_lower_toggled_cb",
                       Handler      => Shift_Lvl_lower'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "shift_lvl_gnd_toggled_cb",
                       Handler      => Shift_Lvl_gnd'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "shift_lvl_jbgnd_toggled_cb",
                       Handler      => Shift_Lvl_jbgnd'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "shift_lvl_bgnd_toggled_cb",
                       Handler      => Shift_Lvl_bgnd'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "shift_lvl_core_toggled_cb",
                       Handler      => Shift_Lvl_core'Access);
      -- The modifier (caps lock, shift, control, alt) buttons
      Register_Handler(Builder      => Builder,
                       Handler_Name => "toggle_caps_lock",
                       Handler      => Toggle_Caps'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "toggle_num_lock",
                       Handler      => Toggle_Num_Lock'Access);
      -- The keyboard
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_04_clicked_cb",
                       Handler      => Key_Clicked_CB_04'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_05_clicked_cb",
                       Handler      => Key_Clicked_CB_05'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_06_clicked_cb",
                       Handler      => Key_Clicked_CB_06'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_07_clicked_cb",
                       Handler      => Key_Clicked_CB_07'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_08_clicked_cb",
                       Handler      => Key_Clicked_CB_08'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_09_clicked_cb",
                       Handler      => Key_Clicked_CB_09'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_0A_clicked_cb",
                       Handler      => Key_Clicked_CB_0A'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_0B_clicked_cb",
                       Handler      => Key_Clicked_CB_0B'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_0C_clicked_cb",
                       Handler      => Key_Clicked_CB_0C'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_0D_clicked_cb",
                       Handler      => Key_Clicked_CB_0D'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_0E_clicked_cb",
                       Handler      => Key_Clicked_CB_0E'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_0F_clicked_cb",
                       Handler      => Key_Clicked_CB_0F'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_10_clicked_cb",
                       Handler      => Key_Clicked_CB_10'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_11_clicked_cb",
                       Handler      => Key_Clicked_CB_11'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_12_clicked_cb",
                       Handler      => Key_Clicked_CB_12'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_13_clicked_cb",
                       Handler      => Key_Clicked_CB_13'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_14_clicked_cb",
                       Handler      => Key_Clicked_CB_14'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_15_clicked_cb",
                       Handler      => Key_Clicked_CB_15'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_16_clicked_cb",
                       Handler      => Key_Clicked_CB_16'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_17_clicked_cb",
                       Handler      => Key_Clicked_CB_17'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_18_clicked_cb",
                       Handler      => Key_Clicked_CB_18'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_19_clicked_cb",
                       Handler      => Key_Clicked_CB_19'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_1A_clicked_cb",
                       Handler      => Key_Clicked_CB_1A'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_1B_clicked_cb",
                       Handler      => Key_Clicked_CB_1B'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_1C_clicked_cb",
                       Handler      => Key_Clicked_CB_1C'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_1D_clicked_cb",
                       Handler      => Key_Clicked_CB_1D'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_1E_clicked_cb",
                       Handler      => Key_Clicked_CB_1E'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_1F_clicked_cb",
                       Handler      => Key_Clicked_CB_1F'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_20_clicked_cb",
                       Handler      => Key_Clicked_CB_20'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_21_clicked_cb",
                       Handler      => Key_Clicked_CB_21'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_22_clicked_cb",
                       Handler      => Key_Clicked_CB_22'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_23_clicked_cb",
                       Handler      => Key_Clicked_CB_23'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_24_clicked_cb",
                       Handler      => Key_Clicked_CB_24'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_25_clicked_cb",
                       Handler      => Key_Clicked_CB_25'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_26_clicked_cb",
                       Handler      => Key_Clicked_CB_26'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_27_clicked_cb",
                       Handler      => Key_Clicked_CB_27'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_28_clicked_cb",
                       Handler      => Key_Clicked_CB_28'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_29_clicked_cb",
                       Handler      => Key_Clicked_CB_29'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_2A_clicked_cb",
                       Handler      => Key_Clicked_CB_2A'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_2B_clicked_cb",
                       Handler      => Key_Clicked_CB_2B'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_2C_clicked_cb",
                       Handler      => Key_Clicked_CB_2C'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_2D_clicked_cb",
                       Handler      => Key_Clicked_CB_2D'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_2E_clicked_cb",
                       Handler      => Key_Clicked_CB_2E'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_2F_clicked_cb",
                       Handler      => Key_Clicked_CB_2F'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_30_clicked_cb",
                       Handler      => Key_Clicked_CB_30'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_31_clicked_cb",
                       Handler      => Key_Clicked_CB_31'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_33_clicked_cb",
                       Handler      => Key_Clicked_CB_33'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_34_clicked_cb",
                       Handler      => Key_Clicked_CB_34'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_35_clicked_cb",
                       Handler      => Key_Clicked_CB_35'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_36_clicked_cb",
                       Handler      => Key_Clicked_CB_36'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_37_clicked_cb",
                       Handler      => Key_Clicked_CB_37'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_38_clicked_cb",
                       Handler      => Key_Clicked_CB_38'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_3A_clicked_cb",
                       Handler      => Key_Clicked_CB_3A'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_3B_clicked_cb",
                       Handler      => Key_Clicked_CB_3B'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_3C_clicked_cb",
                       Handler      => Key_Clicked_CB_3C'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_3D_clicked_cb",
                       Handler      => Key_Clicked_CB_3D'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_3E_clicked_cb",
                       Handler      => Key_Clicked_CB_3E'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_3F_clicked_cb",
                       Handler      => Key_Clicked_CB_3F'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_40_clicked_cb",
                       Handler      => Key_Clicked_CB_40'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_41_clicked_cb",
                       Handler      => Key_Clicked_CB_41'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_42_clicked_cb",
                       Handler      => Key_Clicked_CB_42'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_43_clicked_cb",
                       Handler      => Key_Clicked_CB_43'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_44_clicked_cb",
                       Handler      => Key_Clicked_CB_44'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_45_clicked_cb",
                       Handler      => Key_Clicked_CB_45'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_46_clicked_cb",
                       Handler      => Key_Clicked_CB_46'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_47_clicked_cb",
                       Handler      => Key_Clicked_CB_47'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_48_clicked_cb",
                       Handler      => Key_Clicked_CB_48'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_49_clicked_cb",
                       Handler      => Key_Clicked_CB_49'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_4A_clicked_cb",
                       Handler      => Key_Clicked_CB_4A'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_4B_clicked_cb",
                       Handler      => Key_Clicked_CB_4B'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_4C_clicked_cb",
                       Handler      => Key_Clicked_CB_4C'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_4D_clicked_cb",
                       Handler      => Key_Clicked_CB_4D'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_4E_clicked_cb",
                       Handler      => Key_Clicked_CB_4E'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_4F_clicked_cb",
                       Handler      => Key_Clicked_CB_4F'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_50_clicked_cb",
                       Handler      => Key_Clicked_CB_50'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_51_clicked_cb",
                       Handler      => Key_Clicked_CB_51'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_52_clicked_cb",
                       Handler      => Key_Clicked_CB_52'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_76_clicked_cb",
                       Handler      => Key_Clicked_CB_76'Access);
     -- The keypad
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_54_clicked_cb",
                       Handler      => Key_Clicked_CB_54'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_55_clicked_cb",
                       Handler      => Key_Clicked_CB_55'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_56_clicked_cb",
                       Handler      => Key_Clicked_CB_56'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_57_clicked_cb",
                       Handler      => Key_Clicked_CB_57'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_58_clicked_cb",
                       Handler      => Key_Clicked_CB_58'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_59_clicked_cb",
                       Handler      => Key_Clicked_CB_59'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_5A_clicked_cb",
                       Handler      => Key_Clicked_CB_5A'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_5B_clicked_cb",
                       Handler      => Key_Clicked_CB_5B'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_5C_clicked_cb",
                       Handler      => Key_Clicked_CB_5C'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_5D_clicked_cb",
                       Handler      => Key_Clicked_CB_5D'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_5E_clicked_cb",
                       Handler      => Key_Clicked_CB_5E'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_5F_clicked_cb",
                       Handler      => Key_Clicked_CB_5F'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_60_clicked_cb",
                       Handler      => Key_Clicked_CB_60'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_61_clicked_cb",
                       Handler      => Key_Clicked_CB_61'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_62_clicked_cb",
                       Handler      => Key_Clicked_CB_62'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_63_clicked_cb",
                       Handler      => Key_Clicked_CB_63'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_67_clicked_cb",
                       Handler      => Key_Clicked_CB_67'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_B1_clicked_cb",
                       Handler      => Key_Clicked_CB_B1'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_BB_clicked_cb",
                       Handler      => Key_Clicked_CB_BB'Access);
      -- The space size
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_F0_clicked_cb",
                       Handler      => Key_Clicked_CB_F0'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_F1_clicked_cb",
                       Handler      => Key_Clicked_CB_F1'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_F2_clicked_cb",
                       Handler      => Key_Clicked_CB_F2'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_F3_clicked_cb",
                       Handler      => Key_Clicked_CB_F3'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_F4_clicked_cb",
                       Handler      => Key_Clicked_CB_F4'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "key_F5_clicked_cb",
                       Handler      => Key_Clicked_CB_F5'Access);
      -- Any other configuration
      Set_Unprintable_Range(from => start_reserved_char, 
                            to   => end_reserved_char);
      Set_Combining_to_Unprintable;
   end Initialise_Keyboard;

   procedure Resize_Grid (to_rows, to_cols : natural) is
      -- Store the new rows and columns to match the grid size
   begin
      Grid_Training.Set_Window_Size(with_rows=>to_rows, and_columns=>to_cols);
   end Resize_Grid;

   function Key_As_String(key : in key_id_types) return string is
      the_key : string := key_id_types'Image(key);
      -- This raw conversion produces an upper case represenation.
      -- We need a lower case representation to match correctly
      posn : natural := the_key'First;
   begin
      while the_key(posn) /= '_' loop  -- "_' = end of alpha
         if the_key(posn) in 'A' .. 'Z' then
            -- convert to lower case
            the_key(posn) := Character'Val(Character'Pos(the_key(posn)) + 
                                    (Character'Pos('a') - Character'Pos('A')));
         end if;
         posn := posn + 1;
      end loop;
      return the_key;
   end Key_As_String;
   
   function Text_To_UTF8(for_text : in text)return Glib.UTF8_String is
         -- Convert the UTF-8 string stored in the database to a dStrings.text
         -- (i.e. Ada.Strings.Wide_Unbounded) string.
      use Ada.Strings.UTF_Encoding;
      use Ada.Strings.UTF_Encoding.Wide_Strings;
   begin
      return Encode(To_String(from => for_text), UTF_8);
   end  Text_To_UTF8;
   
   function UTF8_To_Text(for_word : Glib.UTF8_String) return Text is
         -- Convert the UTF-8 string to a dStrings.text
         -- (i.e. Ada.Strings.Wide_Unbounded) string.
      use Ada.Strings.UTF_Encoding;
      use Ada.Strings.UTF_Encoding.Wide_Strings;
   begin
      return To_Text(Decode(for_word, UTF_8));
   end  UTF8_To_Text;

   procedure Show_Keyboard(Builder : in Gtkada_Builder) is
      use Gtk.Toggle_Tool_Button, Gtk.GEntry, Cursor_Management;
      the_label   : Gtk.GEntry.gtk_entry;
   begin
      Error_Log.Debug_Data(at_level => 3, 
                           with_details => "Show_Keyboard: Start");
      -- Toggle the keyboard button to be depressed
      Set_Active(gtk_toggle_tool_button(Get_Object(Builder,"btn_kbd_keys")),
                 Is_Active => True);
      -- Set up the display string with any characters or words already loaded.
      -- These would have come from the grid cells, for instance.
      the_label:= gtk_entry(Get_Object(Builder, "key_strokes_entered"));
      Set_Text(the_label, Text_To_UTF8(Visible_Keystrokes));
      -- And show the keyaboard
      Gtk.Widget.Show_All(Gtk.Widget.Gtk_Widget 
                        (Gtkada.Builder.Get_Object(Builder,"form_keyboard")));
      -- Hiding and showing things doesn't work while a form is not visible,
      -- so the following procedure, which sets up the correct visibility of
      -- keys, is run after making the keyboard visible.
      Toggle_Caps(Object => Builder);
   end Show_Keyboard;

    -- The tool bar buttons and other buttons
   procedure Keyboard_Show_Help(Object : access Gtkada_Builder_Record'Class) is
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Setup_Show_Help: Start");
      -- Show the Help dialogue box
      Help_About.Show_Help_About(Gtkada_Builder(Object));
   end Keyboard_Show_Help;

   procedure Btn_Keys_UnClicked
            (Object : access Gtkada_Builder_Record'Class) is
      use Gtk.Toggle_Tool_Button;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Btn_Keys_UnClicked: Start");
      if not Get_Active(gtk_toggle_tool_button(
                            Get_Object(Gtkada_Builder(Object),"btn_kbd_keys")))
      then
      -- Show the main menu
         Gtk.Widget.Show_All(Gtk.Widget.Gtk_Widget 
                        (Gtkada.Builder.Get_Object(Object,"form_main")));
      -- Show/hide the combining character buttons (must be done after unhiding
      -- the main window).
         declare
            new_language : positive;
         begin
            Setup.Combo_Language_Changed(Object, to_language => new_language);
         -- Display or hide the top row of combining accents based on language
            Setup.Set_Up_Combining(Object, for_language => new_language);
         end;
      -- and then hide ourselves
         Gtk.Widget.Hide(Gtk.Widget.Gtk_Widget 
            (Gtkada.Builder.Get_Object(Gtkada_Builder(Object),"form_keyboard")));
      end if;
   end Btn_Keys_UnClicked;

   procedure Btn_Unicode_Clicked(Object: access Gtkada_Builder_Record'Class) is
      use Gtk.Toggle_Tool_Button;
      use Keyboard_Emulation;
      the_button : Gtk.Toggle_Tool_Button.Gtk_Toggle_Tool_Button;
   begin
      -- Get the Unicode button on the main grid to mimic this state
      if Get_Active(Gtk_Toggle_Tool_Button(
           Gtkada.Builder.Get_Object(Gtkada_Builder(Object),"btn_unicode"))) /=
         Get_Active(Gtk_Toggle_Tool_Button(
                         Get_Object(Gtkada_Builder(Object),"btn_kbd_unicode")))
      then -- toggle it (and  this will toggle the normal/ujicode state)
         the_button := Gtk_Toggle_Tool_Button(
                             Get_Object(Gtkada_Builder(Object),"btn_unicode"));
         Set_Active(the_button, is_active => (not Get_Active(the_button)));
      end if;
   end Btn_Unicode_Clicked;

   procedure Setup_Select_CB  
                (Object : access Gtkada_Builder_Record'Class) is
   begin
      Error_Log.Debug_Data(at_level => 5, 
                              with_details=> "Keybd: Setup_Select_CB: Start");
      Setup.Show_Setup(Gtkada_Builder(Object));
   end Setup_Select_CB;
   
   procedure Btn_Word_Selected (Object : access Gtkada_Builder_Record'Class) is
     -- When the Word Selected "Apply" button is clicked, add the word
     -- curently selected in the drop-down list to the output stream and update
     -- the display of the output stream.
      use Gtk.Combo_Box, Gtk.Tree_Selection, Gtk.List_Store, Glib, Glib.Values;
      use Gtk.GEntry;
      use Cursor_Management;
      the_combo : Gtk.Combo_Box.gtk_combo_box;
      iter      : Gtk.Tree_Model.gtk_tree_iter;
      store     : Gtk.List_Store.gtk_list_store;
      col_data  : Glib.Values.GValue;
      the_label : Gtk.GEntry.gtk_entry;
      the_display : text;
   begin  -- Btn_Word_Selected
      Error_Log.Debug_Data(at_level => 5, 
                           with_details=> "Btn_Word_Selected: Start");
      the_combo := gtk_combo_box(Get_Object(Object, "combo_select_word"));
      if Get_Active(the_combo) >= 0 then
         store:= gtk_list_store(Get_Object(Gtkada_Builder(Object),"word_list"));
         iter := Get_Active_Iter(the_combo);
         Get_Value(store, iter, 0, col_data);
         Add(a_word => UTF8_To_Text(Glib.Values.Get_String(col_data)));
         -- display the result and act on it if ncessary
         the_label:= gtk_entry(Get_Object(Object, "key_strokes_entered"));
         Set_Text(the_label, Text_To_UTF8(Visible_Keystrokes));
      end if;
   end Btn_Word_Selected;

    -- The shift level radio buttons
   procedure Shift_Level_Toggled(to_level  : in shift_level_types;
                                 for_button: in string;
                                 on_object : access Gtkada_Builder_Record'Class)
   is
      -- Change the shift level to that selected.
      -- The event and therefore this procedure gets called whenever a radio
      -- button is depressed and whenever it is released.  We are only interested
      -- in the point when a radio button is depressed.
      use Gtk.Toggle_Button;
   begin
      if Get_Active(gtk_toggle_button(
                            Get_Object(Gtkada_Builder(on_object),for_button)))
      then  -- only do this for a depression, not a release
         shift_level := to_level;
         Toggle_Caps(Object => on_object);
      end if;
   end Shift_Level_Toggled;
    
   procedure Shift_Lvl_space   (Object : access Gtkada_Builder_Record'Class) is
   begin
      Shift_Level_Toggled(to_level => space, for_button=> "shift_lvl_space", 
                          on_object => Object);
   end Shift_Lvl_space;
   
   procedure Shift_Lvl_asky    (Object : access Gtkada_Builder_Record'Class) is
   begin
      Shift_Level_Toggled(to_level => above_sky, for_button=> "shift_lvl_asky", 
                          on_object => Object);
   end Shift_Lvl_asky;

   procedure Shift_Lvl_sky     (Object : access Gtkada_Builder_Record'Class) is
   begin
      Shift_Level_Toggled(to_level => sky, for_button=> "shift_lvl_sky", 
                          on_object => Object);
   end Shift_Lvl_sky;
   
   procedure Shift_Lvl_bsky    (Object : access Gtkada_Builder_Record'Class) is
   begin
      Shift_Level_Toggled(to_level => below_sky, for_button=> "shift_lvl_bsky", 
                          on_object => Object);
   end Shift_Lvl_bsky;
   
   procedure Shift_Lvl_upper   (Object : access Gtkada_Builder_Record'Class) is
   begin
      Shift_Level_Toggled(to_level => upper, for_button=> "shift_lvl_upper", 
                          on_object => Object);
   end Shift_Lvl_upper;
   
   procedure Shift_Lvl_mid     (Object : access Gtkada_Builder_Record'Class) is
   begin
      Shift_Level_Toggled(to_level => middle, for_button=> "shift_lvl_mid", 
                          on_object => Object);
   end Shift_Lvl_mid;
   
   procedure Shift_Lvl_lower   (Object : access Gtkada_Builder_Record'Class) is
   begin
      Shift_Level_Toggled(to_level => lower, for_button=> "shift_lvl_lower", 
                          on_object => Object);
   end Shift_Lvl_lower;
   
   procedure Shift_Lvl_gnd     (Object : access Gtkada_Builder_Record'Class) is
   begin
      Shift_Level_Toggled(to_level => ground, for_button=> "shift_lvl_gnd", 
                          on_object => Object);
   end Shift_Lvl_gnd;
   
   procedure Shift_Lvl_jbgnd   (Object : access Gtkada_Builder_Record'Class) is
   begin
      Shift_Level_Toggled(to_level => just_below_ground, 
                          for_button=> "shift_lvl_jbgnd", 
                          on_object => Object);
   end Shift_Lvl_jbgnd;
   
   procedure Shift_Lvl_bgnd    (Object : access Gtkada_Builder_Record'Class) is
   begin
      Shift_Level_Toggled(to_level => below_ground,
                          for_button=> "shift_lvl_bgnd", 
                          on_object => Object);
   end Shift_Lvl_bgnd;
   
   procedure Shift_Lvl_core    (Object : access Gtkada_Builder_Record'Class) is
   begin
      Shift_Level_Toggled(to_level => core, for_button=> "shift_lvl_core", 
                          on_object => Object);
   end Shift_Lvl_core;
    
   -- The modifier (caps lock, shft, control, alt) buttons
   procedure Toggle_Caps       (Object : access Gtkada_Builder_Record'Class) is
       -- Display the keys in either the capitals state or the lower csse state
       -- depending on the status of the shift and caps lock keys.
      use Gtk.Toggle_Button, Gtk.Button, Gtk.Label, String_Conversions;
      the_key    : key_id_types;
      key_lbl    : Gtk.Label.gtk_label;
      key_btn    : Gtk.Button.gtk_button;
      left_shift : constant string := Key_As_String(key_E1);
      right_shift: constant string := Key_As_String(key_E5);
      caps_lock  : constant string := Key_As_String(key_39);
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details=> "Toggle_Caps: Start");
      the_key :=  First_In(the_set => keyboard_keys);
      loop
         key_btn := gtk_button(Get_Object(Object, Key_As_String(the_key)));
         key_lbl := gtk_label(Get_Object(Object,'l' & Key_As_String(the_key)));
         if Get_Active(gtk_toggle_button(Get_Object(Object, caps_lock)))
           xor (Get_Active(gtk_toggle_button(Get_Object(Object,left_shift)))
             or Get_Active(gtk_toggle_button(Get_Object(Object,right_shift))))
         then  -- Shift/Caps Lock is depressed (active) - display upper case
            if the_key < space_keys then
               Set_Label(key_btn,Text_To_UTF8(key_characters(the_key).shifted_display));
               Set_Visible(key_btn, not (
                  key_characters(the_key).shifted_result(shift_level) = ' ' or
                  key_characters(the_key).shifted_result(shift_level) = null_char));
            else
               Set_Label(key_lbl,Text_To_UTF8(key_characters(the_key).shifted_display));
               Set_Visible(key_lbl, not (
                  key_characters(the_key).shifted_result(shift_level) = ' ' or
                  key_characters(the_key).shifted_result(shift_level) = null_char));
            end if;
         else  -- Shift/Caps Lock is not depressed - display lower case
            if the_key < space_keys then
               Set_Label(key_btn,Text_To_UTF8(key_characters(the_key).unshifted_display));
               Set_Visible(key_btn, not (
                  key_characters(the_key).unshifted_result(shift_level) = ' ' or
                  key_characters(the_key).unshifted_result(shift_level) = null_char));
            else
               Set_Label(key_lbl,Text_To_UTF8(key_characters(the_key).unshifted_display));
               Set_Visible(key_lbl, not (
                  key_characters(the_key).unshifted_result(shift_level) = ' ' or
                  key_characters(the_key).unshifted_result(shift_level) = null_char));
            end if;
         end if;
         exit when the_key >= Last_In(the_set => keyboard_keys);
         the_key := Next_In(the_set => keyboard_keys, from => the_key);
      end loop;
   end Toggle_Caps;
   
   procedure Toggle_Num_Lock   (Object : access Gtkada_Builder_Record'Class) is
       -- Display the number pad keys in either numbers or movement arrows
       -- depending on the status of the num lock key.
      use Gtk.Toggle_Button, Gtk.Button, Pango.Font, Setup;
      num_lock   : constant string := Key_As_String(key_53);
      the_key    : key_id_types;
      key_btn    : Gtk.Button.gtk_button;
      num_lock_on: boolean;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details=> "Toggle_Num_Lock: Start");
      num_lock_on:= Get_Active(gtk_toggle_button(Get_Object(Object,num_lock)));
      the_key := First_In(the_set => keypad_keys);
      loop
         key_btn := gtk_button(Get_Object(Object,Key_As_String(the_key)));
         if num_lock_on
         then  -- Num Lock is depressed (active) - display and use numbers
            Set_Label(key_btn, 
                      Text_To_UTF8(key_characters(the_key).shifted_display));
         else  -- Num Lock is not depressed (not active) - display cursor keys
            Set_Label(key_btn, 
                      Text_To_UTF8(key_characters(the_key).unshifted_display));
         end if;
         exit when the_key >= Last_In(the_set => keypad_keys);
         the_key := Next_In(the_set => keypad_keys, from => the_key);
      end loop;
   end Toggle_Num_Lock;

   procedure Btn_Send_Characters(Object: access Gtkada_Builder_Record'Class) is
      -- Send the all of the currently loaded string to the curently active
      -- application
      use Gtk.GEntry, Cursor_Management;
      the_label   : Gtk.GEntry.gtk_entry;
   begin
      Main_Menu.Btn_Enter_Clicked_CB(Object);
      the_label:= gtk_entry(Get_Object(Object, "key_strokes_entered"));
      Set_Text(the_label, "");
      Clear_String;  -- should already be cleared, but just in case...
   end Btn_Send_Characters;
   
    -- The keyboard buttons
   procedure Process_Key_Clicked(for_key : in wide_character;
                               at_object:access Gtkada_Builder_Record'Class) is
       -- Code convert, if necessary, then transmit the key character to the
       -- buffer or the target application.
      use Gtk.GEntry, Gtk.Toggle_Tool_Button, Cursor_Management;
      use String_Conversions;
      the_label   : Gtk.GEntry.gtk_entry;
   begin
      Error_Log.Debug_Data(at_level => 6, 
                           with_details=> "Process_Key_Clicked: Start: '" &
                                          for_key & "'");
      the_label:= gtk_entry(Get_Object(at_object, "key_strokes_entered"));
      -- Load in the new character if displayable
      if Get_Active(gtk_toggle_tool_button(Get_Object(at_object,"btn_kbd_edit")))
      then  -- depressed button to use cursor control to edit the line
         -- The following should be a case statement but Ada thinks that
         -- the comparison points, e.g. insert_char, delete_char, are not
         -- constants (tried pragmas inline and elaborate with no success),
         -- so a series of if then else is used.
         if for_key = insert_char then -- toggle the insert/overwrite mode
            Set_Overwrite_Mode(the_label,not Get_Overwrite_Mode(the_label));
         elsif for_key = delete_char then -- delete character under cursor
            Delete_Character;
         elsif for_key = bs_key then -- delete character to the left of the cursor
            Back_Space;
         elsif for_key = left_arrow then -- move cursor 1 space left if possible
            Cursor_Left;
         elsif for_key = right_arrow then -- move cursor 1 space right if possible
            Cursor_Right;
         elsif for_key = home_char then -- move cursor to the start of the line
            Cursor_Home;
         elsif for_key = end_char then -- move cursor to the end of the line
            Cursor_End;
         else  -- Treat normally
            if for_key = kpad_000
               then
               Add(a_character => key_characters(key_62).shifted_result(middle));
               Add(a_character => key_characters(key_62).shifted_result(middle));
               Add(a_character => key_characters(key_62).shifted_result(middle));
            elsif for_key = kpad_00
               then
               Add(a_character => key_characters(key_62).shifted_result(middle));
               Add(a_character => key_characters(key_62).shifted_result(middle));
            else
               Add(a_character => for_key);
            end if;
         end if;
      else  -- don't do line editing, assume data is to be transmitted
         if for_key = kpad_000
         then
            Add(a_character => key_characters(key_62).shifted_result(middle));
            Add(a_character => key_characters(key_62).shifted_result(middle));
            Add(a_character => key_characters(key_62).shifted_result(middle));
         elsif for_key = kpad_00
         then
            Add(a_character => key_characters(key_62).shifted_result(middle));
            Add(a_character => key_characters(key_62).shifted_result(middle));
         else
            Add(a_character => for_key);
         end if;
      end if;
      Set_Position(the_label, Glib.Gint(Cursor_Position));
      -- display the result and act on it if ncessary
      if for_key = enter_key
      then  -- Carriage return - clear display and act on it
         Btn_Send_Characters(at_object);
      else  -- display the result (printable characters only)
         Set_Text(the_label, Text_To_UTF8(Visible_Keystrokes));
      end if;
   end Process_Key_Clicked;
    
   procedure Key_Clicked(for_key_id : in key_id_types;
                         at_object: access Gtkada_Builder_Record'Class;
                         at_level : in shift_level_types := middle) is
       -- Based on the control, alt and shift levels, determine the character
       -- clicked and then operate on the result.
      use Gtk.Toggle_Button, String_Conversions;
      use Keyboard_Emulation;
      the_result : wide_character := ' ';
      left_shift : constant string := Key_As_String(key_E1);
      right_shift: constant string := Key_As_String(key_E5);
      caps_lock  : constant string := Key_As_String(key_39);
      left_ctrl  : constant string := Key_As_String(key_E0);
      right_ctrl : constant string := Key_As_String(key_E4);
      left_alt   : constant string := Key_As_String(key_E2);
      right_alt  : constant string := Key_As_String(key_E6);
      super_key  : constant string := Key_As_String(key_E3);  -- aka Windows key
      num_lock   : constant string := Key_As_String(key_53);
      shft_state : boolean := 
           Get_Active(gtk_toggle_button(Get_Object(at_object, right_shift)))
           or Get_Active(gtk_toggle_button(Get_Object(at_object, left_shift)));
      ctrl_state : boolean :=
           Get_Active(gtk_toggle_button(Get_Object(at_object, left_ctrl)))
           or Get_Active(gtk_toggle_button(Get_Object(at_object, right_ctrl)));
      alt_state  : boolean := 
           Get_Active(gtk_toggle_button(Get_Object(at_object, left_alt)))
           or Get_Active(gtk_toggle_button(Get_Object(at_object, right_alt)));
      supr_state : boolean := 
           Get_Active(gtk_toggle_button(Get_Object(at_object, super_key)));
   begin
      Error_Log.Debug_Data(at_level => 7, 
                           with_details=> "Key_Clicked: Start: '" &
                                To_Wide_String(Key_As_String(for_key_id))&"'");
      if ctrl_state or alt_state or supr_state
      then  -- A control or alt or super character so treat specially
         -- First, dump the buffer
         Btn_Send_Characters(at_object);
         -- Then transmit the character with the modifier
         declare
            key_pressed : wide_character := 
                         key_characters(for_key_id).unshifted_result(at_level);
         begin
            if ctrl_state and not (alt_state or supr_state or shft_state)
            then
               Keyboard_Emulation.Transmit(the_key => key_pressed,
                                           with_modifier => ctrl);
            elsif alt_state and not (ctrl_state or supr_state or shft_state)
            then
               Keyboard_Emulation.Transmit(the_key => key_pressed,
                                           with_modifier => alt);
            elsif alt_state and ctrl_state and not (supr_state or shft_state)
            then
               Keyboard_Emulation.Transmit(the_key => key_pressed,
                                           with_modifier => ctrl_alt);
            elsif ctrl_state and shft_state and not (alt_state or supr_state)
            then
               Keyboard_Emulation.Transmit(the_key => key_pressed,
                                           with_modifier => shift_ctrl);
            elsif alt_state and shft_state and not (ctrl_state or supr_state)
            then
               Keyboard_Emulation.Transmit(the_key => key_pressed,
                                           with_modifier => shift_alt);
            elsif alt_state and ctrl_state and shft_state and not supr_state
            then
               Keyboard_Emulation.Transmit(the_key => key_pressed,
                                           with_modifier => shift_ctrl_alt);
            elsif supr_state
            then
               null;
            else
               null;
            end if;
         end;
      elsif for_key_id < keypad_keys and then for_key_id /= key_B1
      then
         if Get_Active(gtk_toggle_button(Get_Object(at_object, num_lock)))
         then  -- Num Lock is on
            the_result:=key_characters(for_key_id).shifted_result(at_level);
         else  -- Num Lock is off
            the_result:=key_characters(for_key_id).unshifted_result(at_level);
         end if;
      elsif shft_state
      then -- a shift
         if Get_Active(gtk_toggle_button(Get_Object(at_object,caps_lock)))
         then  -- invert the shift (i.e. unshifted)
            the_result:=key_characters(for_key_id).unshifted_result(at_level);
         else  -- shifted character
            the_result:=key_characters(for_key_id).shifted_result(at_level);
         end if;
      else  -- not shifted
         if Get_Active(gtk_toggle_button(Get_Object(at_object, caps_lock)))
         then  -- treat as shifted character
            the_result:=key_characters(for_key_id).shifted_result(at_level);
         else  -- unshfted character
            the_result:=key_characters(for_key_id).unshifted_result(at_level);
         end if;
      end if;
      -- operate on the result
      Process_Key_Clicked(for_key => the_result, at_object=>at_object);
      -- and reset the super, shift, control and alt keys to not depressed
      Set_Active(gtk_toggle_button(Get_Object(at_object,left_shift)),Is_Active=>false);
      Set_Active(gtk_toggle_button(Get_Object(at_object,right_shift)),Is_Active=>false);
      Set_Active(gtk_toggle_button(Get_Object(at_object,left_ctrl)),Is_Active=>false);
      Set_Active(gtk_toggle_button(Get_Object(at_object,right_ctrl)),Is_Active=>false);
      Set_Active(gtk_toggle_button(Get_Object(at_object,left_alt)),Is_Active=>false);
      Set_Active(gtk_toggle_button(Get_Object(at_object,right_alt)),Is_Active=>false);
      Set_Active(gtk_toggle_button(Get_Object(at_object,super_key)),Is_Active=>false);
   end Key_Clicked;

   procedure Key_Clicked_CB_04 (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id=>key_04,at_object=>Object,at_level=>shift_level);
   end Key_Clicked_CB_04;
   
   procedure Key_Clicked_CB_05 (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id=>key_05,at_object=>Object,at_level=>shift_level);
   end Key_Clicked_CB_05;
   
   procedure Key_Clicked_CB_06 (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id=>key_06,at_object=>Object,at_level=>shift_level);
   end Key_Clicked_CB_06;
   
   procedure Key_Clicked_CB_07 (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id=>key_07,at_object=>Object,at_level=>shift_level);
   end Key_Clicked_CB_07;
   
   procedure Key_Clicked_CB_08 (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id=>key_08,at_object=>Object,at_level=>shift_level);
   end Key_Clicked_CB_08;
   
   procedure Key_Clicked_CB_09 (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id=>key_09,at_object=>Object,at_level=>shift_level);
   end Key_Clicked_CB_09;
   
   procedure Key_Clicked_CB_0A (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id=>key_0A,at_object=>Object,at_level=>shift_level);
   end Key_Clicked_CB_0A;
   
   procedure Key_Clicked_CB_0B (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id=>key_0B,at_object=>Object,at_level=>shift_level);
   end Key_Clicked_CB_0B;
   
   procedure Key_Clicked_CB_0C (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id=>key_0C,at_object=>Object,at_level=>shift_level);
   end Key_Clicked_CB_0C;
   
   procedure Key_Clicked_CB_0D (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id=>key_0D,at_object=>Object,at_level=>shift_level);
   end Key_Clicked_CB_0D;
   
   procedure Key_Clicked_CB_0E (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id=>key_0E,at_object=>Object,at_level=>shift_level);
   end Key_Clicked_CB_0E;
   
   procedure Key_Clicked_CB_0F (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id=>key_0F,at_object=>Object,at_level=>shift_level);
   end Key_Clicked_CB_0F;
   
   procedure Key_Clicked_CB_10 (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id=>key_10,at_object=>Object,at_level=>shift_level);
   end Key_Clicked_CB_10;
   
   procedure Key_Clicked_CB_11 (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id=>key_11,at_object=>Object,at_level=>shift_level);
   end Key_Clicked_CB_11;
   
   procedure Key_Clicked_CB_12 (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id=>key_12,at_object=>Object,at_level=>shift_level);
   end Key_Clicked_CB_12;
   
   procedure Key_Clicked_CB_13 (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id=>key_13,at_object=>Object,at_level=>shift_level);
   end Key_Clicked_CB_13;
   
   procedure Key_Clicked_CB_14 (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id=>key_14,at_object=>Object,at_level=>shift_level);
   end Key_Clicked_CB_14;
   
   procedure Key_Clicked_CB_15 (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id=>key_15,at_object=>Object,at_level=>shift_level);
   end Key_Clicked_CB_15;
   
   procedure Key_Clicked_CB_16 (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id=>key_16,at_object=>Object,at_level=>shift_level);
   end Key_Clicked_CB_16;
   
   procedure Key_Clicked_CB_17 (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id=>key_17,at_object=>Object,at_level=>shift_level);
   end Key_Clicked_CB_17;
   
   procedure Key_Clicked_CB_18 (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id=>key_18,at_object=>Object,at_level=>shift_level);
   end Key_Clicked_CB_18;
   
   procedure Key_Clicked_CB_19 (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id=>key_19,at_object=>Object,at_level=>shift_level);
   end Key_Clicked_CB_19;
   
   procedure Key_Clicked_CB_1A (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id=>key_1A,at_object=>Object,at_level=>shift_level);
   end Key_Clicked_CB_1A;
   
   procedure Key_Clicked_CB_1B (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id=>key_1B,at_object=>Object,at_level=>shift_level);
   end Key_Clicked_CB_1B;
   
   procedure Key_Clicked_CB_1C (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id=>key_1C,at_object=>Object,at_level=>shift_level);
   end Key_Clicked_CB_1C;
   
   procedure Key_Clicked_CB_1D (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id=>key_1D,at_object=>Object,at_level=>shift_level);
   end Key_Clicked_CB_1D;
   
   procedure Key_Clicked_CB_1E (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id=>key_1E,at_object=>Object,at_level=>shift_level);
   end Key_Clicked_CB_1E;
   
   procedure Key_Clicked_CB_1F (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id=>key_1F,at_object=>Object,at_level=>shift_level);
   end Key_Clicked_CB_1F;
   
   procedure Key_Clicked_CB_20 (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id=>key_20,at_object=>Object,at_level=>shift_level);
   end Key_Clicked_CB_20;
   
   procedure Key_Clicked_CB_21 (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id=>key_21,at_object=>Object,at_level=>shift_level);
   end Key_Clicked_CB_21;
   
   procedure Key_Clicked_CB_22 (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id=>key_22,at_object=>Object,at_level=>shift_level);
   end Key_Clicked_CB_22;
   
   procedure Key_Clicked_CB_23 (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id=>key_23,at_object=>Object,at_level=>shift_level);
   end Key_Clicked_CB_23;
   
   procedure Key_Clicked_CB_24 (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id=>key_24, at_object=>Object,at_level=>shift_level);
   end Key_Clicked_CB_24;
   
   procedure Key_Clicked_CB_25 (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id=>key_25, at_object=>Object,at_level=>shift_level);
   end Key_Clicked_CB_25;
   
   procedure Key_Clicked_CB_26 (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id=>key_26, at_object=>Object,at_level=>shift_level);
   end Key_Clicked_CB_26;
   
   procedure Key_Clicked_CB_27 (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id=>key_27, at_object=>Object,at_level=>shift_level);
   end Key_Clicked_CB_27;
   
   procedure Key_Clicked_CB_2D (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id=>key_2D, at_object=>Object,at_level=>shift_level);
   end Key_Clicked_CB_2D;
   
   procedure Key_Clicked_CB_2E (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id=>key_2E, at_object=>Object,at_level=>shift_level);
   end Key_Clicked_CB_2E;
   
   procedure Key_Clicked_CB_2F (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id=>key_2F, at_object=>Object,at_level=>shift_level);
   end Key_Clicked_CB_2F;
   
   procedure Key_Clicked_CB_30 (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id=>key_30, at_object=>Object,at_level=>shift_level);
   end Key_Clicked_CB_30;
   
   procedure Key_Clicked_CB_31 (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id=>key_31, at_object=>Object,at_level=>shift_level);
   end Key_Clicked_CB_31;
   
   procedure Key_Clicked_CB_33 (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id=>key_33, at_object=>Object,at_level=>shift_level);
   end Key_Clicked_CB_33;
   
   procedure Key_Clicked_CB_34 (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id=>key_34, at_object=>Object,at_level=>shift_level);
   end Key_Clicked_CB_34;
   
   procedure Key_Clicked_CB_35 (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id=>key_35, at_object=>Object,at_level=>shift_level);
   end Key_Clicked_CB_35;
   
   procedure Key_Clicked_CB_36 (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id=>key_36, at_object=>Object,at_level=>shift_level);
   end Key_Clicked_CB_36;
   
   procedure Key_Clicked_CB_37 (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id=>key_37, at_object=>Object,at_level=>shift_level);
   end Key_Clicked_CB_37;
   
   procedure Key_Clicked_CB_38 (Object : access Gtkada_Builder_Record'Class) is
   begin
      Key_Clicked(for_key_id => key_38, at_object => Object);
   end Key_Clicked_CB_38;
   
    -- The fixed return keys (Function keys, space bar key(s), tab, backspace,
    -- menu, enter/return, escape and navigation keys)
   procedure Fixed_Key_Clicked(for_key_id : in key_id_types;
                               at_object:access Gtkada_Builder_Record'Class) is
   begin
      Process_Key_Clicked
              (for_key => key_characters(for_key_id).unshifted_result(middle),
               at_object => at_object);
   end Fixed_Key_Clicked;
   
   procedure Key_Clicked_CB_3A (Object : access Gtkada_Builder_Record'Class) is
   begin  -- F1
      Fixed_Key_Clicked(for_key_id => key_3A, at_object=>Object);
   end Key_Clicked_CB_3A;
   
   procedure Key_Clicked_CB_3B (Object : access Gtkada_Builder_Record'Class) is
   begin  -- F2
      Fixed_Key_Clicked(for_key_id => key_3B, at_object=>Object);
   end Key_Clicked_CB_3B;
   
   procedure Key_Clicked_CB_3C (Object : access Gtkada_Builder_Record'Class) is
   begin  -- F3
      Fixed_Key_Clicked(for_key_id => key_3C, at_object=>Object);
   end Key_Clicked_CB_3C;
   
   procedure Key_Clicked_CB_3D (Object : access Gtkada_Builder_Record'Class) is
   begin  -- F4
      Fixed_Key_Clicked(for_key_id => key_3D, at_object=>Object);
   end Key_Clicked_CB_3D;
   
   procedure Key_Clicked_CB_3E (Object : access Gtkada_Builder_Record'Class) is
   begin  -- F5
      Fixed_Key_Clicked(for_key_id => key_3E, at_object=>Object);
   end Key_Clicked_CB_3E;
   
   procedure Key_Clicked_CB_3F (Object : access Gtkada_Builder_Record'Class) is
   begin  -- F6
      Fixed_Key_Clicked(for_key_id => key_3F, at_object=>Object);
   end Key_Clicked_CB_3F;
    
   procedure Key_Clicked_CB_40 (Object : access Gtkada_Builder_Record'Class) is
   begin  -- F7
      Fixed_Key_Clicked(for_key_id => key_40, at_object=>Object);
   end Key_Clicked_CB_40;
    
   procedure Key_Clicked_CB_41 (Object : access Gtkada_Builder_Record'Class) is
   begin  -- F8
      Fixed_Key_Clicked(for_key_id => key_41, at_object=>Object);
   end Key_Clicked_CB_41;
    
   procedure Key_Clicked_CB_42 (Object : access Gtkada_Builder_Record'Class) is
   begin  -- F9
      Fixed_Key_Clicked(for_key_id => key_42, at_object=>Object);
   end Key_Clicked_CB_42;
    
   procedure Key_Clicked_CB_43 (Object : access Gtkada_Builder_Record'Class) is
   begin  -- F10
      Fixed_Key_Clicked(for_key_id => key_43, at_object=>Object);
   end Key_Clicked_CB_43;
    
   procedure Key_Clicked_CB_44 (Object : access Gtkada_Builder_Record'Class) is
   begin  -- F11
      Fixed_Key_Clicked(for_key_id => key_44, at_object=>Object);
   end Key_Clicked_CB_44;
    
   procedure Key_Clicked_CB_45 (Object : access Gtkada_Builder_Record'Class) is
   begin  -- F12
      Fixed_Key_Clicked(for_key_id => key_45, at_object=>Object);
   end Key_Clicked_CB_45;
   
   procedure Key_Clicked_CB_28 (Object : access Gtkada_Builder_Record'Class) is
      use Cursor_Management;
   begin  -- Enter/Return
      Fixed_Key_Clicked(for_key_id => key_28, at_object=>Object);
      Clear_String;
   end Key_Clicked_CB_28;
     
   procedure Key_Clicked_CB_29 (Object : access Gtkada_Builder_Record'Class) is
   begin  -- Esc
      Fixed_Key_Clicked(for_key_id => key_29, at_object=>Object);
   end Key_Clicked_CB_29;
   
   procedure Key_Clicked_CB_2A (Object : access Gtkada_Builder_Record'Class) is
   begin  -- Backspace
      Fixed_Key_Clicked(for_key_id => key_2A, at_object=>Object);
   end Key_Clicked_CB_2A;
   
   procedure Key_Clicked_CB_2B (Object : access Gtkada_Builder_Record'Class) is
   begin  -- Tab
      Fixed_Key_Clicked(for_key_id => key_2B, at_object=>Object);
   end Key_Clicked_CB_2B;
     
   procedure Key_Clicked_CB_2C (Object : access Gtkada_Builder_Record'Class) is
   begin  -- Space Bar
      Fixed_Key_Clicked(for_key_id => key_2C, at_object=>Object);
   end Key_Clicked_CB_2C;
   
   procedure Key_Clicked_CB_76 (Object : access Gtkada_Builder_Record'Class) is
   begin  -- Menu
      Fixed_Key_Clicked(for_key_id => key_76, at_object=>Object);
   end Key_Clicked_CB_76;
    
   procedure Key_Clicked_CB_46 (Object : access Gtkada_Builder_Record'Class) is
   begin  -- Print Screen
      Fixed_Key_Clicked(for_key_id => key_46, at_object=>Object);
   end Key_Clicked_CB_46;
    
   procedure Key_Clicked_CB_47 (Object : access Gtkada_Builder_Record'Class) is
   begin  -- Scroll Lock
      Fixed_Key_Clicked(for_key_id => key_47, at_object=>Object);
   end Key_Clicked_CB_47;
    
   procedure Key_Clicked_CB_48 (Object : access Gtkada_Builder_Record'Class) is
   begin  -- Break
      Fixed_Key_Clicked(for_key_id => key_48, at_object=>Object);
   end Key_Clicked_CB_48;
    
   procedure Key_Clicked_CB_49 (Object : access Gtkada_Builder_Record'Class) is
   begin  -- Insert
      Fixed_Key_Clicked(for_key_id => key_49, at_object=>Object);
   end Key_Clicked_CB_49;
    
   procedure Key_Clicked_CB_4A (Object : access Gtkada_Builder_Record'Class) is
   begin  -- Home
      Fixed_Key_Clicked(for_key_id => key_4A, at_object=>Object);
   end Key_Clicked_CB_4A;
    
   procedure Key_Clicked_CB_4B (Object : access Gtkada_Builder_Record'Class) is
   begin  -- Page Up
      Fixed_Key_Clicked(for_key_id => key_4B, at_object=>Object);
   end Key_Clicked_CB_4B;
    
   procedure Key_Clicked_CB_4C (Object : access Gtkada_Builder_Record'Class) is
   begin  -- Delete
      Fixed_Key_Clicked(for_key_id => key_4C, at_object=>Object);
   end Key_Clicked_CB_4C;
    
   procedure Key_Clicked_CB_4D (Object : access Gtkada_Builder_Record'Class) is
   begin  -- End
      Fixed_Key_Clicked(for_key_id => key_4D, at_object=>Object);
   end Key_Clicked_CB_4D;
    
   procedure Key_Clicked_CB_4E (Object : access Gtkada_Builder_Record'Class) is
   begin  -- Page Down
      Fixed_Key_Clicked(for_key_id => key_4E, at_object=>Object);
   end Key_Clicked_CB_4E;
    
   procedure Key_Clicked_CB_4F (Object : access Gtkada_Builder_Record'Class) is
   begin  -- Arrow Right
      Fixed_Key_Clicked(for_key_id => key_4F, at_object=>Object);
   end Key_Clicked_CB_4F;
    
   procedure Key_Clicked_CB_50 (Object : access Gtkada_Builder_Record'Class) is
   begin  -- Arrow Left
      Fixed_Key_Clicked(for_key_id => key_50, at_object=>Object);
   end Key_Clicked_CB_50;
    
   procedure Key_Clicked_CB_51 (Object : access Gtkada_Builder_Record'Class) is
   begin  -- Arrow Down
      Fixed_Key_Clicked(for_key_id => key_51, at_object=>Object);
   end Key_Clicked_CB_51;
    
   procedure Key_Clicked_CB_52 (Object : access Gtkada_Builder_Record'Class) is
   begin  -- Arrow Up
      Fixed_Key_Clicked(for_key_id => key_52, at_object=>Object);
   end Key_Clicked_CB_52;
   
    -- The keypad buttons
   procedure Key_Clicked_CB_54 (Object : access Gtkada_Builder_Record'Class) is
   begin  -- /
      Fixed_Key_Clicked(for_key_id => key_54, at_object=>Object);
   end Key_Clicked_CB_54;
    
   procedure Key_Clicked_CB_55 (Object : access Gtkada_Builder_Record'Class) is
   begin  -- *
      Fixed_Key_Clicked(for_key_id => key_55, at_object=>Object);
   end Key_Clicked_CB_55;
    
   procedure Key_Clicked_CB_56 (Object : access Gtkada_Builder_Record'Class) is
   begin  -- -
      Fixed_Key_Clicked(for_key_id => key_56, at_object=>Object);
   end Key_Clicked_CB_56;
    
   procedure Key_Clicked_CB_5F (Object : access Gtkada_Builder_Record'Class) is
   begin  -- 7 / Home
      Key_Clicked(for_key_id => key_5F, at_object => Object);
   end Key_Clicked_CB_5F;
    
   procedure Key_Clicked_CB_60 (Object : access Gtkada_Builder_Record'Class) is
   begin  -- 8 / Arrow Up
      Key_Clicked(for_key_id => key_60, at_object => Object);
   end Key_Clicked_CB_60;
    
   procedure Key_Clicked_CB_61 (Object : access Gtkada_Builder_Record'Class) is
   begin  -- 9 / Page Up
      Key_Clicked(for_key_id => key_61, at_object => Object);
   end Key_Clicked_CB_61;
    
   procedure Key_Clicked_CB_57 (Object : access Gtkada_Builder_Record'Class) is
   begin  -- +
      Fixed_Key_Clicked(for_key_id => key_57, at_object=>Object);
   end Key_Clicked_CB_57;
    
   procedure Key_Clicked_CB_5C (Object : access Gtkada_Builder_Record'Class) is
   begin  -- 4 / Arrow Left
      Key_Clicked(for_key_id => key_5C, at_object => Object);
   end Key_Clicked_CB_5C;
    
   procedure Key_Clicked_CB_5D (Object : access Gtkada_Builder_Record'Class) is
   begin  -- 5
      Fixed_Key_Clicked(for_key_id => key_5D, at_object=>Object);
   end Key_Clicked_CB_5D;
    
   procedure Key_Clicked_CB_5E (Object : access Gtkada_Builder_Record'Class) is
   begin  -- 6 / Arrow Right
      Key_Clicked(for_key_id => key_5E, at_object => Object);
   end Key_Clicked_CB_5E;
    
   procedure Key_Clicked_CB_BB (Object : access Gtkada_Builder_Record'Class) is
   begin  -- Back Space ("<-")
      Fixed_Key_Clicked(for_key_id => key_2A, 
                        at_object  => Object); -- It doesn't matter which BkSpc
   end Key_Clicked_CB_BB;
    
   procedure Key_Clicked_CB_59 (Object : access Gtkada_Builder_Record'Class) is
   begin  -- 1 / End
      Key_Clicked(for_key_id => key_59, at_object => Object);
   end Key_Clicked_CB_59;
    
   procedure Key_Clicked_CB_5A (Object : access Gtkada_Builder_Record'Class) is
   begin  -- 2 / Arrow Down
      Key_Clicked(for_key_id => key_5A, at_object => Object);
   end Key_Clicked_CB_5A;
    
   procedure Key_Clicked_CB_5B (Object : access Gtkada_Builder_Record'Class) is
   begin  -- 3v / Page Down
      Key_Clicked(for_key_id => key_5B, at_object => Object);
   end Key_Clicked_CB_5B;
    
   procedure Key_Clicked_CB_67 (Object : access Gtkada_Builder_Record'Class) is
   begin  -- =
      Fixed_Key_Clicked(for_key_id => key_67, at_object=>Object);
   end Key_Clicked_CB_67;
    
   procedure Key_Clicked_CB_62 (Object : access Gtkada_Builder_Record'Class) is
   begin  -- 0 / Ins
      Key_Clicked(for_key_id => key_62, at_object => Object);
   end Key_Clicked_CB_62;
    
   procedure Key_Clicked_CB_B1 (Object : access Gtkada_Builder_Record'Class) is
   begin  -- 000/00
      -- Because this is a special case, where the key is either 000 or 00 and
      -- we should just pump out the characters accordingly, depending on
      -- whether shifted or not (and also, control characters are used to mimic
      -- them), we call Key_Clicked rather than Fixed_Key_Clicked to process
      -- the shift state.  As all shift states are set for this particular key
      -- (by default, at least), calling Key_Clicked is okay.
      Key_Clicked(for_key_id => key_B1, at_object=>Object);
   end Key_Clicked_CB_B1;
    
   procedure Key_Clicked_CB_63 (Object : access Gtkada_Builder_Record'Class) is
   begin  -- . / Del
      Key_Clicked(for_key_id => key_63, at_object => Object);
   end Key_Clicked_CB_63;
    
   procedure Key_Clicked_CB_58 (Object : access Gtkada_Builder_Record'Class) is
      use Cursor_Management;
   begin  -- Enter
      Fixed_Key_Clicked(for_key_id => key_28, 
                        at_object => Object);  -- It doesn't matter which Enter
      Clear_String;
   end Key_Clicked_CB_58;
    
    -- The space size buttons
   procedure Key_Clicked_CB_F0 (Object : access Gtkada_Builder_Record'Class) is
   begin  -- full space
      Fixed_Key_Clicked(for_key_id => key_F0, at_object=>Object);
   end Key_Clicked_CB_F0;

   procedure Key_Clicked_CB_F1 (Object : access Gtkada_Builder_Record'Class) is
   begin  -- half space
      Fixed_Key_Clicked(for_key_id => key_F1, at_object=>Object);
   end Key_Clicked_CB_F1;

   procedure Key_Clicked_CB_F2 (Object : access Gtkada_Builder_Record'Class) is
   begin  -- quarter space
      Fixed_Key_Clicked(for_key_id => key_F2, at_object=>Object);
   end Key_Clicked_CB_F2;

   procedure Key_Clicked_CB_F3 (Object : access Gtkada_Builder_Record'Class) is
   begin  -- eighth space
      Fixed_Key_Clicked(for_key_id => key_F3, at_object=>Object);
   end Key_Clicked_CB_F3;

   procedure Key_Clicked_CB_F4 (Object : access Gtkada_Builder_Record'Class) is
   begin  -- 5/48 space
      Fixed_Key_Clicked(for_key_id => key_F4, at_object=>Object);
   end Key_Clicked_CB_F4;

   procedure Key_Clicked_CB_F5 (Object : access Gtkada_Builder_Record'Class) is
   begin  -- 1/48 space
      Fixed_Key_Clicked(for_key_id => key_F5, at_object=>Object);
   end Key_Clicked_CB_F5;

      -- Keyboard management functions
   procedure Load_Keyboard(for_language : in positive;
                           at_object: Gtkada_Builder) is
      -- Loads the keyboard key display characters and definitions from the
      --  database
      use GNATCOLL.SQL.Exec, Gtk.Button, Gtk.Radio_Button, Gtk.Toggle_Button;
      use Gtk.GEntry, Gtk.Label, Pango.Font, Setup, String_Conversions;
      function To_Char(for_cursor : in Forward_Cursor; at_id : in Field_Index)
      return wide_character is
         -- Convert the character stored in the database, which is stored in
         -- UTF-8 format, to a Wide Character (i.e. 16 bit) format.
         use Ada.Strings.UTF_Encoding;
         use Ada.Strings.UTF_Encoding.Wide_Strings;
         the_result : Glib.UTF8_String := Value(for_cursor, at_id);
      begin
         if the_result'Length > 0 then
            return Decode(the_result, UTF_8)(1);
         else  -- Nothing speccified - return the null character
            return null_char;
         end if;
      end To_Char;
      function Field_To_Text(for_cursor : Forward_Cursor; at_id : Field_Index)
      return Text is
         -- Convert the UTF-8 string stored in the database to a dStrings.text
         -- (i.e. Ada.Strings.Wide_Unbounded) string.
         use Ada.Strings.UTF_Encoding;
         use Ada.Strings.UTF_Encoding.Wide_Strings;
         the_result : Glib.UTF8_String := Value(for_cursor, at_id);
      begin
         return To_Text(Decode(the_result, UTF_8));
      end  Field_To_Text;
      
      left_shift : constant string := Key_As_String(key_E1);
      right_shift: constant string := Key_As_String(key_E5);
      caps_lock  : constant string := Key_As_String(key_39);
      left_ctrl  : constant string := Key_As_String(key_E0);
      right_ctrl : constant string := Key_As_String(key_E4);
      left_alt   : constant string := Key_As_String(key_E2);
      right_alt  : constant string := Key_As_String(key_E6);
      super_key  : constant string := Key_As_String(key_E3); -- aka Windows key
      shift_mid  : constant string := "shift_lvl_mid";
      R_keyboard : Forward_Cursor;
      lingo_parm : SQL_Parameters (1 .. 1);
      key_entry  : Gtk.GEntry.gtk_entry;
      btn_colour : Gdk.RGBA.Gdk_RGBA := Setup.Button_Colour;
      btn_txt_col: Gdk.RGBA.Gdk_RGBA := Setup.Button_Text_Colour;
      txt_colour : Gdk.RGBA.Gdk_RGBA := Setup.Text_Colour;
   begin  -- Load_Keyboard
      Error_Log.Debug_Data(at_level => 5, 
                           with_details=> "Load_Keyboard: Start Lingo.");
      -- Reset the list of characters and words in Grid_Training
      Grid_Training.Clear_Out_Training_Data;
      -- Reset the shift, control, alt, etc, state of the keyboard
      Set_Active(gtk_toggle_button(Get_Object(at_object,left_shift)),Is_Active=>false);
      Set_Active(gtk_toggle_button(Get_Object(at_object,right_shift)),Is_Active=>false);
      Set_Active(gtk_toggle_button(Get_Object(at_object,left_ctrl)),Is_Active=>false);
      Set_Active(gtk_toggle_button(Get_Object(at_object,right_ctrl)),Is_Active=>false);
      Set_Active(gtk_toggle_button(Get_Object(at_object,left_alt)),Is_Active=>false);
      Set_Active(gtk_toggle_button(Get_Object(at_object,right_alt)),Is_Active=>false);
      Set_Active(gtk_toggle_button(Get_Object(at_object,super_key)),Is_Active=>false);
      Set_Active(gtk_toggle_button(Get_Object(at_object,caps_lock)),Is_Active=>false);
      Set_Active(gtk_radio_button(Get_Object(at_object,shift_mid)),Is_Active=>true);
      -- Set up and load the keyboard key details
      lingo_parm := (1 => +for_language);
      R_keyboard.Fetch (Connection => kDB, Stmt => kb_layout_select,
                        Params => lingo_parm);
      if Success(kDB) and then not Has_Row(R_keyboard) then
         Error_Log.Debug_Data(at_level => 6, 
                    with_details=> "Load_Keyboard: No keyboard for language.");
         lingo_parm := (1 => +1);
         R_keyboard.Fetch (Connection => kDB, Stmt => kb_layout_select,
                           Params => lingo_parm);
      end if;
      if Success(kDB) and then Has_Row(R_keyboard) then
         -- First clear out the keys for the main part of the keyboard
         declare
            pure_keyboard : keypad_set := keyboard_keys - space_keys;
            the_key  : key_id_types := First_In(the_set => pure_keyboard);
            key_disp : Gtk.Label.gtk_label;
         begin
            loop
               Clear(key_characters(the_key).unshifted_display);
               key_characters(the_key).unshifted_result(middle) := null_char;
               Clear(key_characters(the_key).shifted_display);
               key_characters(the_key).shifted_result(middle) := null_char;
               key_disp := gtk_label(Get_Object(at_object,'l' & 
                                                      Key_As_String(the_key)));
               Set_Label(key_disp, " ");
               exit when the_key >= Last_In(the_set => pure_keyboard);
               the_key := Next_In(the_set => pure_keyboard, from => the_key);
            end loop;
         end;
         -- Now load the new key definitions
         while Has_Row(R_keyboard) loop  -- while not end_of_table
            -- Load the relevant entry in the keyboard key data array
            declare
               key : key_id_types := To_Key_ID(Integer_Value(R_keyboard,1));
               char : key_character_display renames key_characters(key);
            begin
               Clear(char.unshifted_display); -- clear out
               char.unshifted_display := Field_To_Text(R_keyboard,2);
               Clear(char.shifted_display); -- clear out
               char.shifted_display   := Field_To_Text(R_keyboard,3);
               char.unshifted_result(space)         := To_Char(R_keyboard, 4);
               char.unshifted_result(above_sky)     := To_Char(R_keyboard, 5);
               char.unshifted_result(sky)           := To_Char(R_keyboard, 6);
               char.unshifted_result(below_sky)     := To_Char(R_keyboard, 7);
               char.unshifted_result(upper)         := To_Char(R_keyboard, 8);
               char.unshifted_result(middle)        := To_Char(R_keyboard, 9);
               char.unshifted_result(lower)         := To_Char(R_keyboard,10);
               char.unshifted_result(ground)        := To_Char(R_keyboard,11);
               char.unshifted_result(just_below_ground):=To_Char(R_keyboard,12);
               char.unshifted_result(below_ground)  := To_Char(R_keyboard,13);
               char.unshifted_result(core)          := To_Char(R_keyboard,14);
               char.shifted_result(space)           := To_Char(R_keyboard,15);
               char.shifted_result(above_sky)       := To_Char(R_keyboard,16);
               char.shifted_result(sky)             := To_Char(R_keyboard,17);
               char.shifted_result(below_sky)       := To_Char(R_keyboard,18);
               char.shifted_result(upper)           := To_Char(R_keyboard,19);
               char.shifted_result(middle)          := To_Char(R_keyboard,20);
               char.shifted_result(lower)           := To_Char(R_keyboard,21);
               char.shifted_result(ground)          := To_Char(R_keyboard,22);
               char.shifted_result(just_below_ground):=To_Char(R_keyboard,23);
               char.shifted_result(below_ground)    := To_Char(R_keyboard,24);
               char.shifted_result(core)            := To_Char(R_keyboard,25);
            end;
            Next(R_keyboard);  -- next record(KeyDefinitions)
         end loop;
         -- load key definitions
         declare
            the_key    : key_id_types := First_In(the_set => Full);
            key_disp   : Gtk.Label.gtk_label;
            key_button : Gtk.Button.gtk_button;
            the_toggle : Gtk.Toggle_Button.gtk_toggle_button;
            char : key_character_display;
         begin
            loop
               char := key_characters(the_key);
               -- Set up the colour for the buttons themselves (but not
               -- specifically the label by setting the background colour of
               -- the button grids.
               if (the_key < toggle_keys)
               then  -- Toggle
                  the_toggle:= gtk_toggle_button(
                                 Get_Object(at_object,Key_As_String(the_key)));
                  CSS_Management.Load(the_button => the_toggle, 
                                      with_colour => btn_colour,
                                      and_text_colour => btn_txt_col);
               else  -- Must be a button
                  key_button:=gtk_button(Get_Object(at_object,
                                                    Key_As_String(the_key)));
                  CSS_Management.Load(the_button => key_button, 
                                      with_colour => btn_colour,
                                      and_text_colour => btn_txt_col);
               end if;
               -- Load the key with the lower case character
               case the_key is
                  when key_28 .. key_2C | key_76 =>
                     Set_Label(key_button, Text_To_UTF8(char.unshifted_display));
                  when space_key_range =>
                     Set_Label(key_button, Text_To_UTF8(char.unshifted_display));
                     if Length(char.unshifted_display) > 1 and then
                        Wide_Element(char.unshifted_display,2) > 
                                                     Setup.Font_Start_Character
                     then  -- represented probably using Blissymbolics
                        Modify_Font(key_button, From_String(Setup.The_Font));
                     else  -- reset the font
                        Modify_Font(key_button, null);
                     end if;
                  when key_39 | key_53 | toggle_key_pt_range =>
                     Set_Label(the_toggle,Text_To_UTF8(char.unshifted_display));
                     null;  -- Otherwise ignore these as it shouldn't be defined
                  when cursor_key_range =>
                    -- cursor movement buttons
                     Modify_Font(key_button, null);
                     -- end if;
                     Set_Label(key_button, Text_To_UTF8(char.unshifted_display));
                  when keypad_key_pt_range | key_67 | key_B1 | key_BB =>
                    -- numeric keypad buttons
                     key_disp:= gtk_label(Get_Object(at_object,"l" & 
                                                     Key_As_String(the_key)));
                     if Length(char.unshifted_display) > 1 and then
                        Wide_Element(char.unshifted_display,2) > 
                                                     Setup.Font_Start_Character
                     then  -- represented probably using Blissymbolics
                        Modify_Font(key_disp, From_String(Setup.The_Font));
                     else  -- reset the font
                        Modify_Font(key_disp, null);
                     end if;
                     Set_Label(key_disp, Text_To_UTF8(char.unshifted_display));
                     -- and set the colour for the button itself
                     Override_Background_Color(key_disp, 0, btn_colour);
                     Override_Color(key_disp, 0, btn_txt_col);
                  when others =>
                     -- enter the value into the custom content, after setting
                     -- the font
                     key_disp:= gtk_label(Get_Object(at_object,"l" & 
                                                     Key_As_String(the_key)));
                     -- Set the font (exctracting the font from Setup.The_Font)
                     if ((Length(char.unshifted_display) > 1 and then
                          Wide_Element(char.unshifted_display,2) > 
                                                Setup.Font_Start_Character) or
                         (Length(char.unshifted_display) = 1 and then
                          Wide_Element(char.unshifted_display,1) > 
                                                Setup.Font_Start_Character)) or
                        ((Length(char.shifted_display) > 1 and then
                          Wide_Element(char.shifted_display,2) > 
                                                Setup.Font_Start_Character) or
                         (Length(char.shifted_display) = 1 and then
                          Wide_Element(char.shifted_display,1) > 
                                                Setup.Font_Start_Character))
                     then  -- represented probably using Blissymbolics
                        Modify_Font(key_disp, From_String(Setup.The_Font));
                     else  -- reset the font
                        Modify_Font(key_disp, null);
                     end if;
                     Set_Label(key_disp, Text_To_UTF8(char.unshifted_display));
                     Override_Background_Color(key_disp, 0, btn_colour);
                     Override_Color(key_disp, 0, btn_txt_col);
               end case;
               exit when the_key >= Last_In(the_set => Full);
               the_key := Next_In(the_set => Full, from => the_key);
            end loop;
         end;
         key_entry:= gtk_entry(Get_Object(at_object, "key_strokes_entered"));
         Modify_Font(key_entry, From_String(Setup.The_Font));
         Override_Background_Color(key_entry, 0, Setup.Used_Cell_Colour);
         Override_Color(key_entry, 0, Setup.Text_Colour);
         -- While we are here, load the character into the training list
         Load_Characters_List (for_language => for_language);
         -- And load the words into the drop-down list (and the training list)
         Load_Words_List(for_language => for_language, at_object => at_object);
      end if;
   end Load_Keyboard;

   procedure Load_Words_List(for_language : in positive;
                             at_object: Gtkada_Builder) is
       -- Load the list of words that pertain to the specified language.  This
       -- procedure is called by Load_Keyboard.
      use Gtk.Combo_Box, Pango.Font;
      use GNATCOLL.SQL.Exec;
      -- use String_Conversions;
      use Gtk.List_Store, GLib;
      use Grid_Training, Training_Samples;
      combo_box  : Gtk.Combo_Box.gtk_combo_box;
      R_words    : Forward_Cursor;
      words_list : Gtk.List_Store.gtk_list_store;
      words_iter : Gtk.Tree_Model.gtk_tree_iter;
      lingo_parm : SQL_Parameters (1 .. 1);
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details=> "Load_Words_List: Start");
      combo_box:= gtk_combo_box(Get_Object(at_object,"combo_select_word"));
      Modify_Font(combo_box, From_String(Setup.The_Font));
      -- Set up and load the list of words
      lingo_parm := (1 => +for_language);
      R_words.Fetch (Connection => kDB, Stmt => kb_words_list, 
                     Params => lingo_parm);
      if Success(kDB) and then Has_Row(R_words) then
         -- set up the list store of words
         words_list := gtk_list_store(Get_Object(at_object, "word_list"));
         Clear(words_list);  -- empty the table ready for the new data
         -- Load the display tree
         while Has_Row(R_words) loop  -- while not end_of_table
            Append(words_list, words_iter);
            Gtk.List_Store.Set(words_list, words_iter, 0,
                               Glib.UTF8_String(Value(R_words,0)));  -- word
            Gtk.List_Store.Set(words_list, words_iter, 1,
                               Glib.Gint(Integer_Value(R_words,1))); -- ID
            Gtk.List_Store.Set(words_list, words_iter, 2,
                               Glib.UTF8_String(Value(R_words,2)));  -- Descr.
            -- and while we are here, load the word into the training
            -- character and word list
            Load(the_word => Glib.UTF8_String(Value(R_words,0)));
            -- and then record whether training is done on it
            if There_Is_A_Sample_With (the_key => UTF8_To_Text(for_word=>
                                           Glib.UTF8_String(Value(R_words,0))))
            then  -- training has been done on it
               Record_Training_Is_Done(on_word => 
                                           Glib.UTF8_String(Value(R_words,0)));
            end if;
            Next(R_words);  -- next record(Configurations)
         end loop;
      end if;
      null;
   end Load_Words_List;
   
   procedure Load_Characters_List (for_language : in positive) is
       -- Load the list of characters for this specified language into
       -- the grid training data.  This is essentially done here as a
       -- by-product of loading the keyboard, also done here because
       -- the load process needs to be done at the same time as the
       -- keyboard is loaded.
       -- This procedure is called by Load_Keyboard.
      use GNATCOLL.SQL.Exec;
      use Grid_Training, Training_Samples;
      R_chars    : Forward_Cursor;
      lingo_parm : SQL_Parameters (1 .. 1);
      starting   : natural := 0;
      ending     : natural := 0;
      the_char   : wide_character;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details=> "Load_Characters_List: Start");
      lingo_parm := (1 => +for_language);
      R_chars.Fetch (Connection => kDB, Stmt => chars_list, 
                     Params => lingo_parm);
      if Success(kDB) and then Has_Row(R_chars) then
         -- set up the training list of characters
         starting := Integer_Value(R_chars,1);
         ending   := Integer_Value(R_chars,2);
         for char_id in starting .. ending loop
            the_char := wide_character'Val(char_id);
            if not (the_char in bliss_space_start .. bliss_space_end)
            then  -- This is a trainable character
            -- Load it
               Load(the_character => the_char);
            -- and record whether training is done on it
               if There_Is_A_Sample_With (the_key => To_Text(the_char))
               then  -- training has been done on it
                  Record_Training_Is_Done(on_character => the_char);
               end if;
            end if;
         end loop;
      else  -- Bit of a problem here!
         Error_Log.Put(the_error => 10,
                       error_intro =>  "Load_Characters_List error", 
                       error_message=> "Didn'd find language number"& 
                                       Integer'Wide_Image(for_language) & ".");
      end if;
   end Load_Characters_List;
                             
begin
   Cell_Writer_Version.Register(revision => "$Revision: v1.0.1$",
                                for_module => "Keyboard");
end Keyboard;
