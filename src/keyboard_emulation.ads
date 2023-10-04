 -----------------------------------------------------------------------
--                                                                   --
--                K E Y B O A R D _ E M U L A T I O N                --
--                                                                   --
--                     S p e c i f i c a t i o n                     --
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

with dStrings;        use dStrings;
with GLib;
package Keyboard_Emulation is

   procedure Transmit(key_press : in wide_character);
      -- Transmit to the active application the specified key_press character.
    
   procedure Transmit(the_buffer : in text);
      -- Transmit to the active application all the key characters stored in
      -- the buffer.  If there is nothing in the display string buffer then
      -- nothing is sent.  The buffer is not cleared of all key strokes by this
      -- operation.

   type key_modifiers is (shift, ctrl, alt, ctrl_alt, shift_ctrl, shift_alt, 
                          shift_ctrl_alt, Alt_L, Alt_R);
   procedure Transmit(the_key : in wide_character; 
                      with_modifier : key_modifiers);
      -- Transmit to the active application the specified 'the_key; character
      -- with the relevant modifier applied.
      
private

   procedure Transmit_Sequence(of_characters : in Glib.UTF8_String);
      -- Transmit the specified sequence of character to the active application.
   function To_UTF8(from : in wide_character) return Glib.UTF8_String;
      -- Turn the character 'from' into a UTF8 string, converting any cursor
      -- management keys (such as Tab, Home, PgUp,...).
   function Text_To_UTF8(for_text : in text)return Glib.UTF8_String;
         -- Convert the UTF-8 string stored in the database to a dStrings.text
         -- (i.e. Ada.Strings.Wide_Unbounded) string.
   
   -- The following is used to transmit the key event to the active application
   type key_event_type is record
         key_code : wide_character;
         shift    : boolean;
         key_sim  : natural;
      end record;
   current_event : key_event_type;
   
   null_char     : constant wide_character := wide_character'Val(16#00#);
   
   -- Bad keycodes: Despite having no KeySym entries, certain KeyCodes will
   -- generate special KeySyms even if their KeySym entries have been overwritten.
   -- For instance, KeyCode 204 attempts to eject the CD-ROM even if there is no
   -- CD-ROM device present! KeyCode 229 will launch GNOME file search even if
   -- there is no search button on the physical keyboard. There is no programatic
   -- way around this but to keep a list of commonly used "bad" KeyCodes.

   type key_statuses is (
          KEY_TAKEN,       -- Has KeySyms, cannot be overwritten
          KEY_BAD,         -- Manually marked as unusable 
          KEY_USABLE,      -- Has no KeySyms, can be overwritten
          KEY_ALLOCATED,   -- Normally usable, but currently allocated
          multiple_allocations
          -- Values greater than key_allocated represent multiple allocations
        );
   for key_statuses use (0, 1, 2, 3, 4);
   subtype ascii_keys is wide_character range 
                              wide_character'first .. wide_character'Val(255);
   -- usable : array(ascii_keys) of key_statuses;
   -- pressed: array(ascii_keys) of boolean;
   -- key_min, key_max, key_offset, key_codes : natural;
--    
   -- type KeySym is new integer;  -- defined in <X11/X.h> and used in <X11/keysym.h>
   -- keysyms : KeySym := 0;
   -- function Usable(the_char : in wide_character) return key_statuses;
--       
   -- procedure Allocate(the_key_event : in out key_event_type; 
   --                    with_key_sim  : natural);
   -- procedure New_Event(for_key_event : in out key_event_type; 
   --                     with_keysym   : natural);
   -- procedure Free(the_key_event : key_event_type);
   -- procedure Press(the_key_event : key_event_type);
   -- procedure Press_Force(the_key_event : key_event_type);
   -- procedure Release(the_key_event : key_event_type);
   -- procedure Release_Force(the_key_event : key_event_type);
   -- procedure Send(the_character : wide_character);

end Keyboard_Emulation;
