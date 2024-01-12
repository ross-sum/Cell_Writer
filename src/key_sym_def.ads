 -----------------------------------------------------------------------
--                                                                   --
--                       K E Y   S Y M   D E F                       --
--                                                                   --
--                     S p e c i f i c a t i o n                     --
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
--  General  Public Licence distributed with Cell_Writer.  If  not,  --
--  write  to  the Free Software Foundation,  51  Franklin  Street,  --
--  Fifth Floor, Boston, MA 02110-1301, USA.                         --
--                                                                   --
-----------------------------------------------------------------------

with Ada.Unchecked_Conversion;
package Key_Sym_Def is

   subtype key_sym_byte is integer range 16#ff08#..16#ffff#;
    
   type key_sym_list is (
      -- TTY function keys, cleverly chosen to map to ASCII, for convenience of
         --  programming, but could have been arbitrary (at the cost of lookup
         -- tables in client code).
                         XK_BackSpace,   -- Back space, back char
                         XK_Tab,
                         XK_Linefeed,    -- Linefeed, LF
                         XK_Clear,
                         XK_Return,      -- Return, enter
                         XK_Pause,       -- Pause, hold
                         XK_Scroll_Lock,
                         XK_Sys_Req,
                         XK_Escape,
         -- Japanese keyboard support
                         XK_Kanji,       -- Kanji, Kanji convert
                         XK_Muhenkan,    -- Cancel Conversion
                         XK_Henkan_Mode, -- Start/Stop Conversion
         --              XK_Henkan,      -- Alias for Henkan_Mode
                         XK_Romaji,      -- to Romaji
                         XK_Hiragana,    -- to Hiragana
                         XK_Katakana,    -- to Katakana
                         XK_Hiragana_Katakana, -- Hiragana/Katakana toggle
                         XK_Zenkaku,     -- to Zenkaku
                         XK_Hankaku,     -- to Hankaku
                         XK_Zenkaku_Hankaku, -- Zenkaku/Hankaku toggle
                         XK_Touroku,     -- Add to Dictionary
                         XK_Massyo,      -- Delete from Dictionary
                         XK_Kana_Lock,   -- Kana Lock
                         XK_Kana_Shift,  -- Kana Shift
                         XK_Eisu_Shift,  -- Alphanumeric Shift
                         XK_Eisu_toggle, -- Alphanumeric toggle
                         XK_Kanji_Bangou,-- Codeinput
         -- International & multi-key character composition
         --              XK_Codeinput,   -- code duplicates XK_Kanji_Bangou
                         XK_SingleCandidate,
         --              XK_MultipleCandidate, -- duplicates XK_Zen_Koho
         --              XK_PreviousCandidate, -- duplicates XK_Mae_Koho
         -- Japanese keyboard support (continued)
                         XK_Zen_Koho,    -- Multiple/All Candidate(s)
                         XK_Mae_Koho,    -- Previous Candidate
         -- 0xff31 thru 0xff3f are under XK_KOREAN
         -- Cursor control & motion
                         XK_Home,
                         XK_Left,        -- Move left, left arrow
                         XK_Up,          -- Move up, up arrow
                         XK_Right,       -- Move right, right arrow
                         XK_Down,        -- Move down, down arrow
         --              XK_Prior,       -- Prior, previous
                         XK_Page_Up,     -- ADuplicated by XK_Prior
         --              XK_Next,        -- Next
                         XK_Page_Down,   -- Duplicated by XK_Next
                         XK_End,         -- EOL
                         XK_Begin,       -- BOL
         -- Misc functions
                         XK_Select,      -- Select, mark
                         XK_Print,
                         XK_Execute,     -- Execute, run, do
                         XK_Insert,      -- Insert, insert here
                         XK_Undo,
                         XK_Redo,        -- Redo, again
                         XK_Menu,
                         XK_Find,        -- Find, search
                         XK_Cancel,      -- Cancel, stop, abort, exit
                         XK_Help,        -- Help
                         XK_Break,
                         XK_Mode_switch, -- Character set switch
         --              XK_script_switch, -- Alias for mode_switch
                         XK_Num_Lock,
         -- Keypad functions, keypad numbers cleverly chosen to map to ASCII
                         XK_KP_Space,    -- Space
                         XK_KP_Tab,
                         XK_KP_Enter,    -- Enter
                         XK_KP_F1,       -- PF1, KP_A, ...
                         XK_KP_F2,
                         XK_KP_F3,
                         XK_KP_F4,
                         XK_KP_Home,
                         XK_KP_Left,
                         XK_KP_Up,
                         XK_KP_Right,
                         XK_KP_Down,
         --              XK_KP_Prior,    -- duplicates Page up
                         XK_KP_Page_Up,
         --              XK_KP_Next,     -- duplicates Page DOwn
                         XK_KP_Page_Down,
                         XK_KP_End,
                         XK_KP_Begin,
                         XK_KP_Insert,
                         XK_KP_Delete,
                         XK_KP_Multiply,
                         XK_KP_Add,
                         XK_KP_Separator, -- Separator, often comma
                         XK_KP_Subtract,
                         XK_KP_Decimal,
                         XK_KP_Divide,
   
                         XK_KP_0,
                         XK_KP_1,
                         XK_KP_2,
                         XK_KP_3,
                         XK_KP_4,
                         XK_KP_5,
                         XK_KP_6,
                         XK_KP_7,
                         XK_KP_8,
                         XK_KP_9,
                         XK_KP_Equal,    -- Equals
         -- Auxiliary functions; note the duplicate definitions for left and right
         -- function keys;  Sun keyboards and a few other manufacturers have such
         -- function key groups on the left and/or right sides of the keyboard.
         -- We've not found a keyboard with more than 35 function keys total.
         -- Note: Duplicate codes removed from below list.
                         XK_F1,
                         XK_F2,
                         XK_F3,
                         XK_F4,
                         XK_F5,
                         XK_F6,
                         XK_F7,
                         XK_F8,
                         XK_F9,
                         XK_F10,
                         XK_F11,
                         XK_F12,
                         XK_F13,
                         XK_F14,
                         XK_F15,
                         XK_F16,
                         XK_F17,
                         XK_F18,
                         XK_F19,
                         XK_F20,
                         XK_F21,
                         XK_F22,
                         XK_F23,
                         XK_F24,
                         XK_F25,
                         XK_F26,
                         XK_F27,
                         XK_F28,
                         XK_F29,
                         XK_F30,
                         XK_F31,
                         XK_F32,
                         XK_F33,
                         XK_F34,
                         XK_F35,
         -- Modifiers
                         XK_Shift_L,      -- Left shift */
                         XK_Shift_R,      -- Right shift */
                         XK_Control_L,    -- Left control */
                         XK_Control_R,    -- Right control */
                         XK_Caps_Lock,    -- Caps lock */
                         XK_Shift_Lock,   -- Shift lock */
   
                         XK_Meta_L,       -- Left meta */
                         XK_Meta_R,       -- Right meta */
                         XK_Alt_L,        -- Left alt */
                         XK_Alt_R,        -- Right alt */
                         XK_Super_L,      -- Left super */
                         XK_Super_R,      -- Right super */
                         XK_Hyper_L,      -- Left hyper */
                         XK_Hyper_R,      -- Right hyper
                         
                         XK_Delete);     -- Delete, rubout
   for key_sym_list use (
          16#ff08#, 16#ff09#, 16#ff0a#, 16#ff0b#, 16#ff0d#, 16#ff13#, 16#ff14#,
          16#ff15#, 16#ff1b#,
          16#ff21#, 16#ff22#, 16#ff23#, 16#ff24#, 16#ff25#, 16#ff26#, 16#ff27#,
          16#ff28#, 16#ff29#, 16#ff2a#, 16#ff2b#, 16#ff2c#, 16#ff2d#, 16#ff2e#,
          16#ff2f#, 16#ff30#, 16#ff37#, 
          16#ff3c#, -- 16#ff37#, 16#ff3d#, 16#ff3e#,
          16#ff3d#, 16#ff3e#,
          
          16#ff50#, 16#ff51#, 16#ff52#, 16#ff53#, 16#ff54#, 16#ff55#, 16#ff56#,
          16#ff57#, 16#ff58#,
          16#ff60#, 16#ff61#, 16#ff62#, 16#ff63#, 16#ff65#, 16#ff66#, 16#ff67#,
          16#ff68#, 16#ff69#, 16#ff6a#, 16#ff6b#, 16#ff7e#, 16#ff7f#,
          16#ff80#, 16#ff89#, 16#ff8d#, 16#ff91#, 16#ff92#, 16#ff93#, 16#ff94#,
          16#ff95#, 16#ff96#, 16#ff97#, 16#ff98#, 16#ff99#, 16#ff9a#, 16#ff9b#,
          16#ff9c#, 16#ff9d#, 16#ff9e#, 16#ff9f#, 16#ffaa#, 16#ffab#, 16#ffac#,
          16#ffad#, 16#ffae#, 16#ffaf#,
          16#ffb0#, 16#ffb1#, 16#ffb2#, 16#ffb3#, 16#ffb4#, 16#ffb5#, 16#ffb6#,
          16#ffb7#, 16#ffb8#, 16#ffb9#,
          16#ffbd#, 
          16#ffbe#, 16#ffbf#, 16#ffc0#, 16#ffc1#, 16#ffc2#, 16#ffc3#, 16#ffc4#,
          16#ffc5#, 16#ffc6#, 16#ffc7#, 16#ffc8#, 16#ffc9#, 16#ffca#, 16#ffcb#,
          16#ffcc#, 16#ffcd#, 16#ffce#, 16#ffcf#, 16#ffd0#, 16#ffd1#, 16#ffd2#, 
          16#ffd3#, 16#ffd4#, 16#ffd5#, 16#ffd6#, 16#ffd7#, 16#ffd8#, 16#ffd9#, 
          16#ffda#, 16#ffdb#, 16#ffdc#, 16#ffdd#, 16#ffde#, 16#ffdf#, 16#ffe0#, 
          
          16#ffe1#, 16#ffe2#, 16#ffe3#, 16#ffe4#, 16#ffe5#, 16#ffe6#, 16#ffe7#,
          16#ffe8#, 16#ffe9#, 16#ffea#, 16#ffeb#, 16#ffec#, 16#ffed#, 16#ffee#,
                       
          16#ffff#      );

   function To_Key_ID is new Ada.Unchecked_Conversion(key_sym_byte, key_sym_list);
      -- Convert the numerical representation of the key_sym_list into a
      -- key_sym_list element.
   function To_Key_ID (from_key_sym_character : in wide_character) return key_sym_list;
      -- Convert the character position that equates to the numerical
      -- represntation of a key_sym_list into a key_sym_list element.
   function From_Key_ID is new Ada.Unchecked_Conversion(key_sym_list,key_sym_byte);
      -- Convert a key_sym_list element into its numerical representation.
   function From_Key_ID(to_key_sym : in key_sym_list) return wide_character;
      -- Convert a key_sym_list element into the character that matches (i.e.
      -- has the same numerical value as) the key_sym_list.
    
   function To_Mixed_Case(for_data : in string) return string;
       -- Convert the string to upper case first character and all lower case
       -- for the rest of the string.
       
   function The_Key_Name(for_key_id : in key_sym_list) return string;
       -- Return the (mixed case) string representation of the keyboard special
       -- key that the key_sym_list represents.
    
end Key_Sym_Def;
