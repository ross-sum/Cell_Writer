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
--  General  Public Licence distributed with Cell_Writer.  If  not,  --
--  write  to  the Free Software Foundation,  51  Franklin  Street,  --
--  Fifth Floor, Boston, MA 02110-1301, USA.                         --
--                                                                   --
-----------------------------------------------------------------------

with dStrings;        use dStrings;
with GLib;
package Keyboard_Emulation is

   type transmission_methods is (normal, as_unicode);
   procedure Set_Transmission_Method(to : in transmission_methods);
   function Current_Transmission_Method_Is return transmission_methods;
    
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
      -- Note that, as it is a character being sent with a modifier, it is
      -- always sent as a normal character!  (This won't work for LyX if you
      -- meant to send a non-ASCII character with a modifier.)
      
private

   transmission_method : transmission_methods := normal;

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

end Keyboard_Emulation;
