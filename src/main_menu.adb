-----------------------------------------------------------------------
--                                                                   --
--                         M A I N   M E N U                         --
--                                                                   --
--                              B o d y                              --
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
--  General Public Licence distributed with  Urine_Records. If not,  --
--  write  to  the Free Software Foundation,  51  Franklin  Street,  --
--  Fifth Floor, Boston, MA 02110-1301, USA.                         --
--                                                                   --
-----------------------------------------------------------------------
-- with Gtkada.Builder;  use Gtkada.Builder;
with Gtk.Widget, Gtk.Image;
with Gtk.Main;
with Gtk.Enums;
with Glib, Glib.Error;
-- with Gtk.Button, Gtk.Menu_Item;
with Gtk.Menu;
-- with Handlers; use Handlers;
with Error_Log;
-- with dStrings; use dStrings;
with String_Conversions;
with Ada.Characters.Conversions;
with Cell_Writer_Version;
with Help_About, Help_Manual, Error_Dialogue, Check_For_Deletion;
with Report_Processor;
-- with GNATCOLL.SQL.Exec;
package body Main_Menu is

   procedure Set_Up_Reports_Menu_and_Buttons (Builder : Gtkada_Builder) is
      use Gtk.Button, Gtk.Menu, Gtk.Menu_Item;
      use Report_Processor;
      use String_Conversions;
      report_button : Gtk.Button.Gtk_Button;
      parent_menu   : Gtk.Menu.Gtk_Menu;
      report_menu   : Gtk.Menu_Item.Gtk_Menu_Item;
   begin
      parent_menu := gtk_menu(Get_Object(Builder, "menu_repts_child"));
      for report_num in 1 .. Number_of_Reports loop
         if report_num in 1 .. 4 then  -- within range of buttons
            case report_num is
               when 1 => 
                  report_button:=gtk_button(Get_Object(Builder,"btn_1_report"));
               when 2 => 
                  report_button:=gtk_button(Get_Object(Builder,"btn_2_report"));
               when 3 => 
                  report_button:=gtk_button(Get_Object(Builder,"btn_3_report"));
                  null;
               when 4 => 
                  report_button:=gtk_button(Get_Object(Builder,"btn_4_report"));
               when others => null;  -- do nothing
            end case;
            -- Give the button its correct label
            Error_Log.Debug_Data(at_level => 6, 
                      with_details=>"Set_Up_Reports_Menu_and_Buttons: report "&
                 To_Wide_String(Report_Name(for_report_number => report_num)));
            Set_Label(report_button,
                      Report_Name(for_report_number => report_num));
            -- set up the button's call-back
            report_button.On_Clicked(Call => 
                                     Urine_Records_Report_Clicked_CB'Access);
         end if;
         -- Create the report menu item
         Gtk_New_With_Label(report_menu, 
                            Report_Name(for_report_number => report_num));
         Set_Action_Name(report_menu, "on_report_click");
         Attach(parent_menu, report_menu, 0, 1, 
                Glib.Guint(report_num - 1), Glib.Guint(report_num));
         Set_Sensitive(report_menu, true);
         -- Set the report menu item's call-back
         report_menu.On_Activate(Call=>Urine_Records_Report_Clicked_CB'Access, 
                                 After=>False);
      end loop;
   end Set_Up_Reports_Menu_and_Buttons;
    
   procedure Initialise_Main_Menu(usage : in text;
                           DB_Descr : GNATCOLL.SQL.Exec.Database_Description;
                           with_tex_path : text;
                           with_pdf_path : text;
                           with_R_path   : text;
                           path_to_temp  : string := "/tmp/";
                           glade_filename: string := "urine_records.glade") is
      use Glib.Error, Ada.Characters.Conversions;
      type GError_Access is access Glib.Error.GError;
      Builder : Gtkada_Builder;
      Error   : GError_Access; -- access Glib.Error.GError;
      count   : Glib.Guint;
   begin
      -- Set the locale specific data (e.g time and date format)
      -- Gtk.Main.Set_Locale;
      -- Create a Builder and add the XML data
      Gtk.Main.Init;
      Gtk_New (Builder);
      count := Add_From_File (Builder, path_to_temp & glade_filename, Error);
      if Error /= null then
         Error_Log.Put(the_error    => 201, 
                       error_intro  => "Initialise_Main_Menu: file name error",
                       error_message=> "Error in " & 
                                        To_Wide_String(glade_filename) & " : "&
                                        To_Wide_String(Glib.Error.Get_Message 
                                                                 (Error.all)));
         Glib.Error.Error_Free (Error.all);
      end if;
      
      -- Register the handlers
      Register_Handler(Builder      => Builder,
                       Handler_Name => "help_about_select_cb",
                       Handler      => Menu_Help_About_Select_CB'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "help_manual_activate_cb",
                       Handler      => Menu_Manual_Select_CB'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "file_new_activate_cb",
                       Handler      => Menu_File_New_Select_CB'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "file_exit_select_cb",
                       Handler      => Menu_File_Exit_Select_CB'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "form_main_destroy_cb",
                       Handler      => Menu_File_Exit_Select_CB'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "btn_patient_details_clicked_cb",
                       Handler      => Btn_Patient_Details_Clicked_CB'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "btn_catheter_urine_records_clicked_cb",
                       Handler      => Btn_Catheter_Urine_Records_Clicked_CB'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "btn_urine_records_clicked_cb",
                       Handler      => Btn_Urine_Records_Clicked_CB'Access);
      
      -- Point images in Glade file to unloaded area in the temp directory
      declare
         use Gtk.Image;
         no_2_image : Gtk.Image.gtk_image;
         image_name : constant string := "chkbtn_no2_image";
         file_name  : constant string := path_to_temp & "toilet_action.jpeg";
      begin
         no_2_image := gtk_image(Get_Object(Builder, image_name));
         Set(image => no_2_image, Filename=> file_name);
      end;
      
      -- Set up child forms
      Help_About.Initialise_Help_About(Builder, usage);
      Help_Manual.Initialise_Manual(Builder);
      Get_Date_Calendar.Initialise_Calendar(Builder);
      Urine_Colour_Selector.Initialise_Colour_Selector(Builder, DB_Descr,
                                                       path_to_temp);
      Check_For_Deletion.Initialise(Builder);
      Patient_Details.Initialise_Patient_Details(Builder, DB_Descr);
      Urine_Records_Form.Initialise_Urine_Records(Builder, DB_Descr);
      Catheter_Urine_Records_Form.Initialise_Catheter_Urine_Records(Builder, 
                                                                    DB_Descr);
      Error_Dialogue.Initialise_Dialogue(Builder);
      Report_Processor.Initialise(with_DB_descr => DB_Descr,
                                  with_tex_path => with_tex_path,
                                  with_pdf_path => with_pdf_path,
                                  with_R_path   => with_R_path,
                                  path_to_temp  => path_to_temp);
      -- Set up the Reports menu (needs to be done after report processor is
      -- initialised)
      Set_Up_Reports_Menu_and_Buttons(Builder);
      
      -- Initialise
      Do_Connect (Builder);
      
      --  Find our main window, then display it and all of its children. 
      Gtk.Widget.Show_All (Gtk.Widget.Gtk_Widget 
                           (Gtkada.Builder.Get_Object (Builder, "form_main")));
      Gtk.Main.Main;
      
      -- Clean up memory when done
      Unref (Builder);
   end Initialise_Main_Menu;

   procedure Btn_Patient_Details_Clicked_CB 
                (Object : access Gtkada_Builder_Record'Class) is
       
   begin
      Error_Log.Debug_Data(at_level => 5, 
                        with_details=>"Btn_Patient_Details_Clicked_CB: Start");
      Patient_Details.Show_Patient_Details(Gtkada_Builder(Object));
   end Btn_Patient_Details_Clicked_CB;

   procedure Btn_Urine_Records_Clicked_CB
            (Object : access Gtkada_Builder_Record'Class) is
   begin
      Error_Log.Debug_Data(at_level => 5, 
                        with_details=>"Btn_Urine_Records_Clicked_CB: Start");
      Urine_Records_Form.Show_Urine_Records(Gtkada_Builder(Object));
   end Btn_Urine_Records_Clicked_CB;

   procedure Btn_Catheter_Urine_Records_Clicked_CB
            (Object : access Gtkada_Builder_Record'Class) is
   begin
      Error_Log.Debug_Data(at_level => 5, 
                 with_details=>"Btn_Catheter_Urine_Records_Clicked_CB: Start");
      Catheter_Urine_Records_Form.Show_Catheter_Urine_Records
                        (Gtkada_Builder(Object));
   end Btn_Catheter_Urine_Records_Clicked_CB;

   procedure Menu_File_New_Select_CB  
                (Object : access Gtkada_Builder_Record'Class) is
   begin
      Error_Log.Debug_Data(at_level => 5, 
                              with_details=> "Menu_File_New_Select_CB: Start");
      null;
   end Menu_File_New_Select_CB;

   procedure Menu_File_Exit_Select_CB  
                (Object : access Gtkada_Builder_Record'Class) is
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Menu_File_Exit_Select_CB: Start");
      -- Shut down sub-forms where required
      Patient_Details.Finalise;
      Catheter_Urine_Records_Form.Finalise;
      Urine_Records_Form.Finalise;
      -- and shut ourselves down
      Gtk.Main.Main_Quit;
   end Menu_File_Exit_Select_CB;

   procedure Menu_Help_About_Select_CB 
                (Object : access Gtkada_Builder_Record'Class) is
   
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Menu_Help_About_Select_CB: Start");
      Help_About.Show_Help_About(Gtkada_Builder(Object));
   end Menu_Help_About_Select_CB;

   procedure Menu_Manual_Select_CB
                (Object : access Gtkada_Builder_Record'Class) is
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Menu_Manual_Select_CB: Start");
      Help_Manual.Show_Manual(Gtkada_Builder(Object));
   end Menu_Manual_Select_CB;

   procedure Urine_Records_Report_Clicked_CB(label : string) is
     -- Print the specified report (for the defined report Name).
      use Report_Processor;
      use String_Conversions;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Urine_Records_Report_Clicked_CB: "&
                                           To_Wide_String(label) & ".");
      Run_The_Report(with_id => Report_ID(for_report_name => label));
   end Urine_Records_Report_Clicked_CB;

   procedure Urine_Records_Report_Clicked_CB
                (Object : access Gtk.Menu_Item.Gtk_Menu_Item_Record'Class) is
      -- Get the name of the report menu item and then print the report.
      use Gtk.Menu_Item;
   begin
       -- Get the name of the report menu item and then print the report.
      Urine_Records_Report_Clicked_CB(label=>Get_Label(Gtk_Menu_Item(Object)));
   end Urine_Records_Report_Clicked_CB;

   procedure Urine_Records_Report_Clicked_CB
                (Object : access Gtk.Button.Gtk_Button_Record'Class) is
      -- Get the name of the report button and then print the report.
      use Gtk.Button;
   begin
      Urine_Records_Report_Clicked_CB(label=>Get_Label(Gtk_Button(Object)));
   end Urine_Records_Report_Clicked_CB;

begin
   Urine_Record_Version.Register(revision => "$Revision: v1.0.2$",
                                 for_module => "Main_Menu");
end Main_Menu;