 -----------------------------------------------------------------------
--                                                                   --
--                K E Y B O A R D _ E M U L A T I O N                --
--                                                                   --
--                              B o d y                              --
--                                                                   --
--                           $Revision: 1.0 $                        --
--                                                                   --
--  Copyright (C) 2022  Hyper Quantum Pty Ltd.                       --
--  Written by Ross Summerfield.                                     --
--                                                                   --
--  This  package  emulates  the  keyboard  operation,  essentially  --
--  acting  as  a  virtual  keyboard  for  the  currentlhy   active  --
--  application, providing it with the keystrokes that the user has  --
--  entered (eithe by the on-screen keyboard or by the hand-written  --
--  keystrokes).                                                     --
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

-- with dStrings;           use dStrings;
with Error_Log;
with Key_Sym_Def;           use Key_Sym_Def;
with xdo;                   use xdo;
with Interfaces.C.Strings;  use Interfaces.C.Strings;
with Cell_Writer_Version;
-- with GLib;
with Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
with Ada.Strings.UTF_Encoding.Conversions;
with String_Conversions;
package body Keyboard_Emulation is
   
   cell_writer_window : xdo_t_access := xdo_new(display => New_String("" & ASCII.NUL));
   
   -- type transmission_methods is (normal, as_unicode);
   procedure Set_Transmission_Method(to : in transmission_methods) is
   begin
      transmission_method := to;
   end Set_Transmission_Method;
   
   function Current_Transmission_Method_Is return transmission_methods is
   begin
      return transmission_method;
   end Current_Transmission_Method_Is;

   function Text_To_UTF8(for_text : in text)return Glib.UTF8_String is
         -- Convert the UTF-8 string stored in the database to a dStrings.text
         -- (i.e. Ada.Strings.Wide_Unbounded) string.
      use Ada.Strings.UTF_Encoding;
      use Ada.Strings.UTF_Encoding.Wide_Strings;
   begin
      return Encode(To_String(from => for_text), UTF_8);
   end  Text_To_UTF8;
   
   function To_UTF8(from : in wide_character) return Glib.UTF8_String is
      -- Turn the character 'from' into a UTF8 string, converting any cursor
      -- management keys (such as Tab, Home, PgUp,...).
      use Ada.Strings.UTF_Encoding.Conversions;
      key_string : wide_string := (1=> from);
      utf8_key : Glib.UTF8_String := Convert(key_string);
   begin
      if from in From_Key_ID(key_sym_list'First)..From_Key_ID(key_sym_list'Last)
      then  -- control character - transmit as a control character
         declare
            use String_Conversions;
            the_key : key_sym_list := To_Key_ID(from);
            key_string: Glib.UTF8_String:=The_Key_Name(for_key_id=>the_key);
         begin
            return key_string;
         end;
      else  -- ordinary character - transmit it
         return utf8_key;
      end if;
   end To_UTF8;

   function Convert_To_Unicode_Number_Sequence(the_char : wide_character)
    return Glib.UTF8_String is
      use Ada.Strings.UTF_Encoding;
      use Ada.Strings.UTF_Encoding.Wide_Strings;
      function Integer_To_Hexadecimal(char: in wide_character) 
      return Wide_String is
         hex_characters : constant Wide_String := "0123456789ABCDEF";
         hexadecimal : Wide_String(1..4) := "0000";
         remainder : natural := wide_character'Pos(char);
      begin
        -- Convert the integer to hexadecimal
         for i in reverse 1 .. 4 loop
            if remainder /= 0 then  -- only bother if not already 0
               hexadecimal(i) := hex_characters(remainder mod 16 + 1);
               remainder := remainder / 16;
            end if;
         end loop;
         -- return result
         return hexadecimal;
      end Integer_To_Hexadecimal;
   begin  -- convert to hexadecimal string and cast as UTF8
      return Encode(Integer_to_Hexadecimal(the_char), UTF_8);
   end Convert_To_Unicode_Number_Sequence;
    
   procedure Transmit(key_press : in wide_character) is
      -- Transmit to the active application the specified key_press character.
      use Interfaces.C, GLib;
      app_window : xdo_t_access := xdo_new(display=>New_String("" & ASCII.NUL));
      app_win_access : xdo_t_const_access := app_window.all'access;
   begin
      Error_Log.Debug_Data(at_level => 9, 
                           with_details=>"Transmit: Start '"& key_press & "'");
      if key_press in 
                From_Key_ID(key_sym_list'First)..From_Key_ID(key_sym_list'Last)
      then  -- a function key or the like (e.g. F1 or Home)
         Transmit_Sequence(of_characters => To_UTF8(from=>key_press));
      elsif transmission_method = as_unicode
      then  -- carefully encode and send
         Transmit_Sequence(of_characters => "shift+control+u");
         declare
            key_string : Glib.UTF8_String := 
                       Convert_To_Unicode_Number_Sequence(the_char=>key_press);
            C_char     : chars_ptr := New_String(key_string & ASCII.NUL);
         begin
            if Xdo_Enter_Text_Window (xdo        => app_win_access,
                                      the_window => CURRENTWINDOW,
                                      string     => C_char,
                                      c_delay    => 12000) = 0
            then
               null;
            end if;
            xdo_free (xdo=> app_window);
         end;
         Transmit_Sequence(of_characters => "Return");
      else  -- ordinary key press key in normal mode, so send it out the door
         declare
            key_string : Glib.UTF8_String := Text_To_UTF8(to_text(key_press));
            C_char     : chars_ptr := New_String(key_string & ASCII.NUL);
         begin
            if Xdo_Enter_Text_Window (xdo        => app_win_access,
                                      the_window => CURRENTWINDOW,
                                      string     => C_char,
                                      c_delay    => 12000) = 0
            then
               null;
            end if;
            xdo_free (xdo=> app_window);
         end;
      end if;
   end Transmit;
    
   procedure Transmit(the_buffer : in text) is
      -- Transmit to the active application all the key characters stored in
      -- the buffer.  If there is nothing in the display string buffer then
      -- nothing is sent.  The buffer is not cleared of all key strokes by this
      -- operation.
      use Interfaces.C;
   begin
      Error_Log.Debug_Data(at_level => 6, 
                           with_details => "Transmit: Start '" & Value(the_buffer) & "'");
      if Length(the_buffer) > 0 then
         for char_num in 1 .. Length(the_buffer) loop
            if Wide_Element(the_buffer, char_num) in 
                From_Key_ID(key_sym_list'First)..From_Key_ID(key_sym_list'Last)
            then  -- control character - transmit as a control character
               declare
                  use String_Conversions;
                  the_key : key_sym_list := To_Key_ID(
                                           Wide_Element(the_buffer, char_num));
                  key_string: Glib.UTF8_String:=The_Key_Name(for_key_id=>the_key);
               begin
                  Transmit_Sequence(of_characters => key_string);
               end;
            else  -- ordinary character - transmit it
               Transmit(key_press => Wide_Element(the_buffer, char_num));
            end if;
         end loop;
      end if;
   end Transmit;

   -- type key_modifiers is (shift, ctrl, alt, ctrl_alt, shift_ctrl, shift_alt, 
   --                        shift_ctrl_alt, Alt_L, Alt_R);
   procedure Transmit(the_key : in wide_character; 
                      with_modifier : key_modifiers) is
      -- Transmit to the active application the specified 'the_key; character
      -- with the relevant modifier applied.
      key_as_utf8 : Glib.UTF8_String :=  To_UTF8(from => the_key);
   begin
      case with_modifier is
         when shift=> Transmit_Sequence(of_characters=>"shift+"&key_as_utf8);
         when ctrl => Transmit_Sequence(of_characters=>"control+"&key_as_utf8);
         when alt    => Transmit_Sequence(of_characters => "alt+"&key_as_utf8);
         when ctrl_alt   => Transmit_Sequence(of_characters => "control+alt+" &
                                                             key_as_utf8);
         when shift_ctrl => Transmit_Sequence(of_characters=> "shift+control+"&
                                                             key_as_utf8);
         when shift_alt  => Transmit_Sequence(of_characters=> "shift+alt+" &
                                                             key_as_utf8);
         when shift_ctrl_alt => 
            Transmit_Sequence(of_characters=>"shift+control+alt+"&key_as_utf8);
         when alt_L=> Transmit_Sequence(of_characters => "Alt_L+"&key_as_utf8);
         when alt_R=> Transmit_Sequence(of_characters => "Alt_R+"&key_as_utf8);
         when others =>
            null;
      end case;
   end Transmit;

   procedure Transmit_Sequence(of_characters : in Glib.UTF8_String) is
      -- Transmit the specified sequence of character to the active application.
      use Interfaces.C;
      app_window : xdo_t_access:= xdo_new(display=>New_String("" & ASCII.NUL));
      app_win_access : xdo_t_const_access := app_window.all'access;
      C_char     : chars_ptr := New_String(of_characters & ASCII.NUL);
   begin
      if Xdo_Send_KeySequence_Window(xdo         => app_win_access,
                                     the_window  => CURRENTWINDOW,
                                     keysequence => C_char,
                                     c_delay     => 12000) = 0
      then
         null;
      end if;
      xdo_free (xdo=> app_window);
   end Transmit_Sequence;

begin
   Cell_Writer_Version.Register(revision => "$Revision: v1.1.0$",
                                for_module => "Keyboard_Emulation");
end Keyboard_Emulation;
