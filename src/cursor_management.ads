 -----------------------------------------------------------------------
--                                                                   --
--                 C U R S O R   M A N A G E M E N T                 --
--                                                                   --
--                     S p e c i f i c a t i o n                     --
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
--  Typically,  this  package is used to manage  the  contents  and  --
--  cursor  position  for a Gtk_Entry (in Gtk.GEntry)  widget.   It  --
--  allows  full  cursor movement and also  supports  deleting  and  --
--  inserting  characters or  strings  anywhere  in  the   curently  --
--  composed display string.                                         --
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

with Set_of;
with dStrings;        use dStrings;
with Combining_Characters;
package Cursor_Management is

   -- The Display string buffer, containing the typed text
   disp_str : text;

   -- Cursor details
   type cursor_details is private;
   
   -- Unprintable character details:
   -- note that it is assumed that all characters less than ' ' (16#20@) are
   -- not printable.
   procedure Set_Unprintable_Range(from, to : wide_character);
   procedure Set_Combining_to_Unprintable;
   function Combining_Check_On(the_character:in wide_character) return boolean;
      -- Returns true if the specified character is combining.
      
    -- Cursor control
   procedure Add(a_character : in wide_character);
   procedure Add(a_word : in text);
   procedure Cursor_Left;
   procedure Cursor_Right;
   procedure Cursor_Home;
   procedure Cursor_End;
   procedure Back_Space;
   procedure Delete_Character;
   procedure Clear_String;
      -- Clear the display string and reset the curser details
   function All_Keystrokes return text;
   function Visible_Keystrokes return text;
   function Cursor_Position return natural;
      -- Yield up the visible cursor position (i.e. not including invisible
      -- characters).
      -- The cursor posiion starts from 1 at the left, when there is no
      -- character entered in the display string at all.
   function Number_Of_Keystrokes return natural;
     -- The total number of keystrokes, including for hidden keys such as
     -- cursor movement keys.
    
private
   use Combining_Characters, Combining_Characters.Combining_Sets;
      -- There is a standard list of combining characters.  To handle all
      -- combining characters, which are not 'printable' (i.e. they do not
      -- consume a character space), this all needs to be set up as a set.
      -- The Combining_Characters package does this.
      
   type cursor_details is record
         visible_cursor : natural := 0;  -- the position of the visible cursor
         absolute_pos   : natural := 0;
         unprintable_start : wide_character;
         unprintable_end   : wide_character;
         combining_characters : combining_character_set := Empty;
      end record;
      
   the_cursor : cursor_details;
   
   function The_Character(is_printable : in wide_character) return boolean;
   
end Cursor_Management;
