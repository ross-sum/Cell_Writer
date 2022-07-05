 -----------------------------------------------------------------------
--                                                                   --
--                       K E Y   S Y M   D E F                       --
--                                                                   --
--                              B o d y                              --
--                                                                   --
--                           $Revision: 1.0 $                        --
--                                                                   --
--  Copyright (C) 2022  Hyper Quantum Pty Ltd.                       --
--  Written by Ross Summerfield.                                     --
--                                                                   --
--  This  package  is  an Ada implementation of part  of  the  X11/  --
--  keysymdef.h file (full path name /usr/include/X11/keysymdef.h).  --
--  which is an include of the X11/keysym.h file.  The X11/keysym.h  --
--  file contains a list of the most common Unicode sets.            --
--  The  X11/keysymdef.h  file contains nearly all of  the  Unicode  --
--  characters (excluding private sets).  Its main use here is  for  --
--  control character keys, which are encoded at key presss  wisely  --
--  to ensue minimal translation on the way through.                 --
--                                                                   --
--  X11/keysymdef.h, (C) The Open Group, has the following to say:   --
--                                                                   --
-- The "X11 Window System Protocol" standard defines in Appendix A the
-- keysym codes. These 29-bit integer values identify characters or
-- functions associated with each key (e.g., via the visible
-- engraving) of a keyboard layout. This file assigns mnemonic macro
-- names for these keysyms.
-- 
-- This file is also compiled (by src/util/makekeys.c in libX11) into
-- hash tables that can be accessed with X11 library functions such as
-- XStringToKeysym() and XKeysymToString().
-- 
-- Where a keysym corresponds one-to-one to an ISO 10646 / Unicode
-- character, this is noted in a comment that provides both the U+xxxx
-- Unicode position, as well as the official Unicode name of the
-- character.
-- 
-- Where the correspondence is either not one-to-one or semantically
-- unclear, the Unicode position and name are enclosed in
-- parentheses. Such legacy keysyms should be considered deprecated
-- and are not recommended for use in future keyboard mappings.
--
-- For any future extension of the keysyms with characters already
-- found in ISO 10646 / Unicode, the following algorithm shall be
-- used. The new keysym code position will simply be the character's
-- Unicode number plus 0x01000000. The keysym values in the range
-- 0x01000100 to 0x0110ffff are reserved to represent Unicode
-- characters in the range U+0100 to U+10FFFF.
-- 
-- While most newer Unicode-based X11 clients do already accept
-- Unicode-mapped keysyms in the range 0x01000100 to 0x0110ffff, it
-- will remain necessary for clients -- in the interest of
-- compatibility with existing servers -- to also understand the
-- existing legacy keysym values in the range 0x0100 to 0x20ff.
-- 
-- Where several mnemonic names are defined for the same keysym in this
-- file, all but the first one listed should be considered deprecated.
-- 
-- Mnemonic names for keysyms are defined in this file with lines
-- that match one of these Perl regular expressions:
-- 
--    /^\#define XK_([a-zA-Z_0-9]+)\s+0x([0-9a-f]+)\s*\/\* U+([0-9A-F]{4,6}) (.*) \*\/\s*$/
--    /^\#define XK_([a-zA-Z_0-9]+)\s+0x([0-9a-f]+)\s*\/\*\(U+([0-9A-F]{4,6}) (.*)\)\*\/\s*$/
--    /^\#define XK_([a-zA-Z_0-9]+)\s+0x([0-9a-f]+)\s*(\/\*\s*(.*)\s*\*\/)?\s*$/
-- 
-- Before adding new keysyms, please do consider the following: In
-- addition to the keysym names defined in this file, the
-- XStringToKeysym() and XKeysymToString() functions will also handle
-- any keysym string of the form "U0020" to "U007E" and "U00A0" to
-- "U10FFFF" for all possible Unicode characters. In other words,
-- every possible Unicode character has already a keysym string
-- defined algorithmically, even if it is not listed here. Therefore,
-- defining an additional keysym macro is only necessary where a
-- non-hexadecimal mnemonic name is needed, or where the new keysym
-- does not represent any existing Unicode character.
-- 
-- When adding new keysyms to this file, do not forget to also update the
-- following as needed:
-- 
--   - the mappings in src/KeyBind.c in the libX11 repo
--     https://gitlab.freedesktop.org/xorg/lib/libx11
-- 
--   - the protocol specification in specs/keysyms.xml in this repo
--     https://gitlab.freedesktop.org/xorg/proto/xorgproto
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

-- with Ada.Unchecked_Conversion;
package body Key_Sym_Def is

   -- subtype key_sym_byte is integer range 16#ff08#..16#ffff#;
   -- type key_sym_list is ( ...);

   -- function To_Key_ID is new Ada.Unchecked_Conversion(key_sym_byte, key_sym_list);
   
   function To_Key_ID (from_key_sym_character : in wide_character) return key_sym_list is
      -- Convert the character position that equates to the numerical
      -- represntation of a key_sym_list into a key_sym_list element.
   begin
      return To_Key_ID(Wide_Character'Pos(from_key_sym_character));
   end To_Key_ID;
   
   -- function From_Key_ID is new Ada.Unchecked_Conversion(key_sym_list,key_sym_byte);
   
   function From_Key_ID(to_key_sym : in key_sym_list) return wide_character is
      -- Convert a key_sym_list element into the character that matches (i.e.
      -- has the same numerical value as) the key_sym_list.
   begin
      return Wide_Character'Val(From_Key_ID(to_key_sym));
   end From_Key_ID;
    
   function To_Mixed_Case(for_data : in string) return string is
       -- Convert the string to upper case first character and all lower case
       -- for the rest of the string.
      working_string : string := for_data;
      char : natural;
   begin
      if working_string'Length > 0 then
         char := working_string'First;
         if working_string(char) in 'a'..'z' then
            working_string(char):= Character'Val(Character'Pos(
                                   working_string(char))+
                                    (Character'Pos('A') - Character'Pos('a')));
         end if;
      end if;
      if working_string'Length > 1 then
         for chr in char+1 .. working_string'Last loop
            if working_string(chr) in 'A'..'Z' then
               working_string(chr) := Character'Val(Character'Pos(
                                      working_string(chr))+
                                      (Character'Pos('a')-Character'Pos('A')));
            end if;
            if working_string(chr-1) = '_' then -- make upper case
               working_string(chr) := Character'Val(Character'Pos(
                                      working_string(chr))+
                                      (Character'Pos('A')-Character'Pos('a')));
            end if;
         end loop;
      end if;
      if working_string = "Backspace" then
         working_string := "BackSpace";
      end if;
      return working_string;
   end To_Mixed_Case;
    
   function The_Key_Name(for_key_id : in key_sym_list) return string is
       -- Return the (mixed case) string representation of the keyboard special
       -- key that the key_sym_list represents.
      the_key : string := key_sym_list'Image(for_key_id);
      key_string : string := the_key(the_key'First+3..the_key'Last);
   begin
      return To_Mixed_Case(key_string);
   end The_Key_Name;

end Key_Sym_Def;
