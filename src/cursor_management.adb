 -----------------------------------------------------------------------
--                                                                   --
--                 C U R S O R   M A N A G E M E N T                 --
--                                                                   --
--                              B o d y                              --
--                                                                   --
--                           $Revision: 1.0 $                        --
--                                                                   --
--  Copyright (C) 2022  Hyper Quantum Pty Ltd.                       --
--  Written by Ross Summerfield.                                     --
--                                                                   --
--  This package manages the cursor for the keyboard display cache.  --
--  This  display  cache is also used by the main  form  under  the  --
--  covers  for  data control.  Management is  essentially  keeping  --
--  track of where the cursor is and allowing crude editing (delete  --
--  and backspace).                                                  --
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

-- with Set_of;
-- with dStrings;        use dStrings;
with Error_Log;
with Cell_Writer_Version;
with String_Conversions;
package body Cursor_Management is

   -- The Display string buffer, containing the typed text
   -- disp_str : text;
   -- Cursor details
   -- type cursor_details is private;
    --   private
    --    type cursor_details is record
    --      visible_cursor : natural := 0;  -- the position of the visible cursor
    --      absolute_pos   : natural := 0;
    --      unprintable_start : wide_character;
    --      unprintable_end   : wide_character;
    --    end record;
   --     the_cursor : cursor_details;
   
   -- Unprintable character details:
   -- note that it is assumed that all characters less than ' ' (16#20@) are
   -- not printable in addition to the range set by this procedure.
   procedure Set_Unprintable_Range(from, to : wide_character) is
   begin
      the_cursor.unprintable_start := from;
      the_cursor.unprintable_end   := to;
      the_cursor.combining_characters := the_cursor.combining_characters +
                                         Make_Set(from, to);
   end Set_Unprintable_Range;

   procedure Set_Combining_to_Unprintable is
   -- Add in the list of combining characters to the set of unprintable
   -- characters
   begin
      null;
      the_cursor.combining_characters := the_cursor.combining_characters +
                                 Combining_Characters.The_Combining_Characters;
   end Set_Combining_to_Unprintable;
      
   function The_Character(is_printable : in wide_character) return boolean is
   begin
      return is_printable >= wide_character'Val(16#20#) and
         not (is_printable >= the_cursor.unprintable_start and 
              is_printable <= the_cursor.unprintable_end);
         -- not (is_printable < the_cursor.combining_characters);
   end The_Character;

   function Combining_Check_On(the_character:in wide_character) return boolean
   is
      -- Returns true if the specified character is combining.
   begin
      return the_character < the_cursor.combining_characters;
   end Combining_Check_On;

      -- Cursor control
   procedure Add(a_character : in wide_character) is
      use String_Conversions;
   begin
      if Length(disp_str) = 0 or the_cursor.absolute_pos = Length(disp_str)
      then
         Append(wide_tail => a_character, to => disp_str);
      else 
         disp_str := Sub_String(from => disp_str, starting_at => 1, 
                             for_characters => the_cursor.absolute_pos) &
                     a_character &
                     Sub_String(from => disp_str, 
                                starting_at => the_cursor.absolute_pos + 1, 
                                for_characters => Length(disp_str) - 
                                                  the_cursor.absolute_pos);
      end if;
      the_cursor.absolute_pos := the_cursor.absolute_pos + 1;
      if The_Character(is_printable => a_character)
      then
         the_cursor.visible_cursor := the_cursor.visible_cursor + 1;
      end if;
   end Add;

   procedure Add(a_word : in text) is
      use String_Conversions;
   begin
      if Length(disp_str) = 0
      then
         disp_str := a_word;
      elsif the_cursor.absolute_pos = 0 and Length(a_word) > 1
      then  -- inserting at the start of the display string
         disp_str := a_word & disp_str;
      elsif the_cursor.absolute_pos = Length(disp_str)
      then  -- appending to the end of the display string
         Append(tail => a_word, to => disp_str);
      else  -- inseting somewhere within the display string
         Error_Log.Debug_Data(at_level => 7, 
                              with_details=> "Add(a_word): adding in a bit.");
         disp_str := Sub_String(from => disp_str, starting_at => 1, 
                             for_characters => the_cursor.absolute_pos) &
                     a_word &
                     Sub_String(from => disp_str, 
                                starting_at => the_cursor.absolute_pos + 1, 
                                for_characters => Length(disp_str) - 
                                                  the_cursor.absolute_pos);
      end if;
      -- The absolute cursor position is the total string length, that is,
      -- the original display string length + a_word's length.
      the_cursor.absolute_pos := the_cursor.absolute_pos + Length(a_word);
      -- Calculate the visible cursor position
      the_cursor.visible_cursor := 0;
      for chr_num in 1..the_cursor.absolute_pos loop
         if The_Character(is_printable => Wide_Element(disp_str,chr_num)) then
            the_cursor.visible_cursor := the_cursor.visible_cursor + 1;
         end if;
      end loop;
   end Add;
   
   procedure Cursor_Left is
   begin
      if the_cursor.absolute_pos > 0 then
         if The_Character(is_printable => 
                                Wide_Element(disp_str,the_cursor.absolute_pos))
            and then the_cursor.visible_cursor > 0
         then -- on a visible character, so can move visible character cursor
            the_cursor.visible_cursor := the_cursor.visible_cursor - 1;
         end if;
         the_cursor.absolute_pos := the_cursor.absolute_pos - 1;
      end if;
   end Cursor_Left;
   
   procedure Cursor_Right is
   begin
      if the_cursor.absolute_pos < Length(disp_str) then
         -- can advance the cursor(s) to the right in the keyed-in string
         the_cursor.absolute_pos := the_cursor.absolute_pos + 1;
         if The_Character(is_printable => 
                                Wide_Element(disp_str,the_cursor.absolute_pos))
         then  -- moving to a visible characer, so advance visible cursor
            the_cursor.visible_cursor := the_cursor.visible_cursor + 1;
         end if;
      end if;
   end Cursor_Right;

   procedure Cursor_Home is
   begin
      the_cursor.absolute_pos   := 0;
      the_cursor.visible_cursor := 0;
   end Cursor_Home;
   
   procedure Cursor_End is
   begin
      the_cursor.absolute_pos := Length(disp_str);
      the_cursor.visible_cursor := 0;
      for chr_num in 1..Length(disp_str) loop
         if The_Character(is_printable => Wide_Element(disp_str,chr_num)) then
            the_cursor.visible_cursor := the_cursor.visible_cursor + 1;
         end if;
      end loop;
   end Cursor_End;
   
   Procedure Back_Space is
      use String_Conversions;
   begin
      if the_cursor.absolute_pos = 0
      then  -- can't delete character to left of start of line
         return;
      end if;
      Error_Log.Debug_Data(at_level => 7, 
                           with_details=> "Back_Space: back spacing.");
      if The_Character(is_printable => 
                              Wide_Element(disp_str,the_cursor.absolute_pos))
      then
         the_cursor.visible_cursor := the_cursor.visible_cursor - 1;
      end if;
      Delete(disp_str, the_cursor.absolute_pos, 1);
      the_cursor.absolute_pos := the_cursor.absolute_pos - 1;
   end Back_Space;
   
   Procedure Delete_Character is
      use String_Conversions;
   begin
      if the_cursor.absolute_pos >= Length(disp_str)  -- at (past) end
      or Length(disp_str) = 0                         -- no more to delete
      then  -- at end (delete doesn't work at end, it deletes CR/LF)
         return;
      end if;
      Error_Log.Debug_Data(at_level => 7, 
                           with_details=> "Delete_Character: deleting...");
      -- The cursor position only changes if the current cursor position is at
      -- the end of the display string (i.e. end of the line).  And then, the
      -- vsible cursor position changes only if that last character is visible.
      if the_cursor.absolute_pos = Length(disp_str) then
         -- the cursor position is at the end of the line
         if The_Character(is_printable => 
                              Wide_Element(disp_str,the_cursor.absolute_pos+1))
         then  -- the last character at the end of the line is visible
            the_cursor.visible_cursor := the_cursor.visible_cursor - 1;
         end if;
         Delete(disp_str, the_cursor.absolute_pos+1, 1);
         the_cursor.absolute_pos := the_cursor.absolute_pos - 1;
      else  -- not at the end of hte line, just delete the character
         Delete(disp_str, the_cursor.absolute_pos+1, 1);
      end if;
   end Delete_Character;

   procedure Clear_String is
      -- Clear the display string and reset the curser details
   begin
      Clear(disp_str);
      the_cursor.absolute_pos   := 0;
      the_cursor.visible_cursor := 0;
   end Clear_String;

   function All_Keystrokes return text is
   begin
      return disp_str;
   end All_Keystrokes;
   
   function Visible_Keystrokes return text is
      the_display : text;
   begin
      for chr_num in 1..Length(disp_str) loop
         if The_Character(is_printable => Wide_Element(disp_str,chr_num))
         then
            append(wide_tail=>Wide_Element(disp_str,chr_num), to=>the_display);
         end if;
      end loop;
      return the_display;
   end Visible_Keystrokes;

   function Cursor_Position return natural is
      -- Yield up the visible cursor position (i.e. not including invisible
      -- characters).
      -- The cursor posiion starts from 1 at the left, when there is no
      -- character entered in the display string at all.  Internally, it is
      -- zero based, so we add 1 here.
   begin
      return the_cursor.visible_cursor + 1;
   end Cursor_Position;

   function Number_Of_Keystrokes return natural is
     -- The total number of keystrokes, including for hidden keys such as
     -- cursor movement keys.
   begin
      return Length(disp_str);
   end Number_Of_Keystrokes;

begin
   Cell_Writer_Version.Register(revision => "$Revision: v1.0.2$",
                                for_module => "Cursor_Management");
end Cursor_Management;
