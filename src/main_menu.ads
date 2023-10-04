-----------------------------------------------------------------------
--                                                                   --
--                         M A I N   M E N U                         --
--                                                                   --
--                     S p e c i f i c a t i o n                     --
--                                                                   --
--                           $Revision: 1.0 $                        --
--                                                                   --
--  Copyright (C) 2022  Hyper Quantum Pty Ltd.                       --
--  Written by Ross Summerfield.                                     --
--                                                                   --
--  This  package displays the main menu form,  which contains  the  --
--  tabs necessary to enter training data or to write text well  as  --
--  to  display various reports.  It also contains items to  handle  --
--  help operations and for closing the application.                 --
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
--  General  Public Licence distributed with  Cell_Writer.  If not,  --
--  write  to  the Free Software Foundation,  51  Franklin  Street,  --
--  Fifth Floor, Boston, MA 02110-1301, USA.                         --
--                                                                   --
-----------------------------------------------------------------------
with Gtkada.Builder;  use Gtkada.Builder;
with Gtk.Button, Gtk.Menu_Item, Gtk.Widget;
with dStrings;        use dStrings;
with GNATCOLL.SQL.Exec;
package Main_Menu is


   procedure Initialise_Main_Menu(usage : in text;
                           DB_Descr : GNATCOLL.SQL.Exec.Database_Description;
                           with_tex_path : text;
                           with_pdf_path : text;
                           with_R_path   : text;
                           path_to_temp  : string := "/tmp/";
                           glade_filename: string := "cell_writer.glade");
   procedure Btn_Enter_Clicked_CB
                (Object : access Gtkada_Builder_Record'Class);
   procedure Menu_File_Exit_Select_CB  
                (Object : access Gtkada_Builder_Record'Class);

private
   use Gtk.Widget;

    -- Main toolbar buttons
   procedure Menu_Help_About_Select_CB 
                (Object : access Gtkada_Builder_Record'Class);
   procedure Btn_Clear_Clicked_CB  
                (Object : access Gtkada_Builder_Record'Class);
   procedure Training_Select_CB
                (Object : access Gtkada_Builder_Record'Class);
   procedure Setup_Select_CB 
                (Object : access Gtkada_Builder_Record'Class);
   procedure Btn_Keys_Clicked_CB
                (Object : access Gtkada_Builder_Record'Class);
                
    -- Combo box drop down list selection handler
   procedure Combo_Language_Changed_CB
                (Object : access Gtkada_Builder_Record'Class);
    
    -- Navigation toolbars buttons
   procedure Btn_Tab_Clicked_CB
                (Object : access Gtkada_Builder_Record'Class);
   procedure Btn_Backspace_Clicked_CB
                (Object : access Gtkada_Builder_Record'Class);
   procedure Btn_Del_Clicked_CB
                (Object : access Gtkada_Builder_Record'Class);
   procedure Btn_Ins_Clicked_CB
                (Object : access Gtkada_Builder_Record'Class);
   procedure Btn_Space_Clicked_CB
                (Object : access Gtkada_Builder_Record'Class);
   procedure Btn_Separator_Clicked_CB
                (Object : access Gtkada_Builder_Record'Class);
   procedure Btn_Up_Clicked_CB
                (Object : access Gtkada_Builder_Record'Class);
   procedure Btn_Down_Clicked_CB
                (Object : access Gtkada_Builder_Record'Class);
   procedure Btn_Left_Clicked_CB
                (Object : access Gtkada_Builder_Record'Class);
   procedure Btn_Right_Clicked_CB
                (Object : access Gtkada_Builder_Record'Class);
   procedure Btn_Home_Clicked_CB
                (Object : access Gtkada_Builder_Record'Class);
   procedure Btn_End_Clicked_CB
                (Object : access Gtkada_Builder_Record'Class);
   procedure Btn_PageUp_Clicked_CB
                (Object : access Gtkada_Builder_Record'Class);
   procedure Btn_PageDown_Clicked_CB
                (Object : access Gtkada_Builder_Record'Class);
   
    -- Window destruction management
   procedure On_Window_Destroy(the_window : access Gtk_Widget_Record'Class;
                               cb : Cb_Gtk_Widget_Void);
   procedure On_Window_Close_Request(the_window: access Gtk_Widget_Record'Class);
      -- Called when the X in the top right hand corner is clicked
    
    -- Print the specified report (given the report name from the menu item or
    -- button).
   procedure Cell_Writer_Report_Clicked_CB(label : string);
      -- Print the specified report (for the defined report Name).
   procedure Cell_Writer_Report_Clicked_CB
                (Object : access Gtk.Menu_Item.Gtk_Menu_Item_Record'Class);
       -- Get the name of the report menu item and then print the report.
   procedure Cell_Writer_Report_Clicked_CB
                (Object : access Gtk.Button.Gtk_Button_Record'Class);
       -- Get the name of the report button and then print the report.
       
end Main_Menu;