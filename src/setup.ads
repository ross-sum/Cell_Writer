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
with Glib.Object, Gdk.RGBA, Pango.Font;
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

   function The_Font return UTF8_string;
      -- The currently selected font for the system
   function The_Font_Name return UTF8_string;
      -- The currently selected font name for the system
   function Font_Start_Character return wide_character;
      -- The character to start switching from the default font to the
      -- specified font.
   function Font_Size return gDouble;
      -- The currently selected font size for the system.
   function The_Font_Description return Pango.Font.Pango_Font_Description;
      -- The currently selected font in Pango font description format

   function Button_Text_Colour return Gdk.RGBA.Gdk_RGBA;
      -- The currently selected key text colour for the system
   function Button_Colour return Gdk.RGBA.Gdk_RGBA;
      -- The currently selected keyboard button (background) colour for the system
   function Text_Colour return Gdk.RGBA.Gdk_RGBA;
      -- The currently selected text colour for the system
   function Used_Cell_Colour return Gdk.RGBA.Gdk_RGBA;
      -- The currently selected used cell colour for the system
   function Untouched_Cell_Colour return Gdk.RGBA.Gdk_RGBA;
      -- The currently selected untouched cell background colour for the system
   function Highlight_Colour return Gdk.RGBA.Gdk_RGBA;
      -- The currently selected highlight colour for the system
    
   function Grid_Cell_Columns return natural;
      -- The number of columns in the matrix of cells in the writing grid
   function Grid_Cell_Rows return natural;
      -- The number of rows in the matrix of cells in the writing grid
   function Cell_Height return natural;
      -- The height of each cell in the grid (to the nearest whole number)
   function Cell_Width return natural;
      -- The width of  each cell in the grid (to the nearest whole number)
      
   function Is_Right_to_Left return boolean;
      -- Return true if the right to left check box is checked.
   function Match_Differing_Stroke_Numbers return boolean;
      -- Return true if the requirement to match differing stroke numbers (when
      -- recognising a test sample) check box is checked.
   function Ignore_Stroke_Direction return boolean;
      -- Return true if the ignore stroke direction (when recognising a test
      -- sample) check box is checked.
   function Max_Samples_Per_Character return natural;
      -- Return the user's preference of the maximum number of samples that
      -- should be recorded for training for each character or word that is
      -- trained up.
     
   function The_Special_Button return wide_character;
      -- The special character that is emitted when the special button is
      -- pressed on the main form.

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