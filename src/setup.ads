-----------------------------------------------------------------------
--                                                                   --
--                             S E T U P                             --
--                                                                   --
--                     S p e c i f i c a t i o n                     --
--                                                                   --
--                           $Revision: 1.0 $                        --
--                                                                   --
--  Copyright (C) 2022  Hyper Quantum Pty Ltd.                       --
--  Written by Ross Summerfield.                                     --
--                                                                   --
--  This  package displays the setup dialogue box,  which  contains  --
--  the configuration controls, specifically the interface  details  --
--  for  dimensions, window control, status icon and  colours,  the  --
--  languages (i.e. Unicode groups) being coded for, options around  --
--  languages,   and  recognition  management,   including   around  --
--  training samples, word content and word context.                 --
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
with Gtkada.Builder;  use Gtkada.Builder;
with Gtk.Combo_Box;
with Glib.Object, Gdk.RGBA;
with dStrings;        use dStrings;
with GNATCOLL.SQL.Exec;
package Setup is
   use GLib;

   procedure Initialise_Setup(Builder : in out Gtkada_Builder;
                              DB_Descr: GNATCOLL.SQL.Exec.Database_Description;
                              usage : in text);
   procedure Show_Setup(Builder : in Gtkada_Builder);
   procedure Combo_Language_Changed(Object:access Gtkada_Builder_Record'Class;
                                    to_language : out positive);
      -- Save the selected language to the database and return the selected
      -- language number.
   procedure Set_Up_Combining(Object:access Gtkada_Builder_Record'Class;
                              for_language : in positive);
      -- Display the top row of combining character buttons, assuming 
      -- the selected language  is set up for such buttons.  These buttons
      -- are used to apply an accent type (i.e. on the top of the character)
      -- combining characters to the character/word currently written.

   function The_Font(Builder : in Gtkada_Builder) return UTF8_string;
      -- The currently selected font for the system
   function Font_Start_Character return wide_character;
      -- The character to start switching from the default font to the
      -- specified font.

   function Button_Colour(Builder: in Gtkada_Builder) return Gdk.RGBA.Gdk_RGBA;
      -- The currently selected keyboard button colour for the system

   function Used_Cell_Colour(Builder: in Gtkada_Builder) 
   return Gdk.RGBA.Gdk_RGBA;
      -- The currently selected used cell colour for the system

   function Text_Colour(Builder : in Gtkada_Builder) 
   return Gdk.RGBA.Gdk_RGBA;
      -- The currently selected text colour for the system

   function Button_Text_Colour(Builder : in Gtkada_Builder) 
   return Gdk.RGBA.Gdk_RGBA;
      -- The currently selected key text colour for the system

private

   default_font_start_chr : constant wide_character := 
                                     wide_character'Val(16#A000#);
   font_start_char        : wide_character := default_font_start_chr;

   procedure Setup_Cancel_CB (Object : access Gtkada_Builder_Record'Class);
   procedure Setup_Close_CB (Object : access Gtkada_Builder_Record'Class);
   procedure Setup_Language_Selected
                            (Object : access Gtkada_Builder_Record'Class);
   function Setup_Hide_On_Delete
            (Object : access Glib.Object.GObject_Record'Class) return Boolean;
   procedure Setup_Show_Help (Object : access Gtkada_Builder_Record'Class);
   procedure Load_Data_From(database : GNATCOLL.SQL.Exec.Database_Connection;
                            Builder  : in Gtkada_Builder);
   procedure Load_Data_To(database : GNATCOLL.SQL.Exec.Database_Connection;
                          Builder  : in Gtkada_Builder);
   procedure Set_To_ID(Builder    : access Gtkada_Builder_Record'Class;
                       combo      : Gtk.Combo_Box.gtk_combo_box;
                       list_store : string; id : natural);

end Setup;