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
with Gtk.Widget, Gtk.Image, Gtk.Toggle_Tool_Button;
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
with Help_About, Setup, CSS_Management, Keyboard, Grid_Management,
     Cursor_Management, Keyboard_Emulation;
with Key_Sym_Def;
with Report_Processor;
-- with GNATCOLL.SQL.Exec;
package body Main_Menu is

   procedure Set_Up_Reports_Menu_and_Buttons (Builder : Gtkada_Builder) is
      use Gtk.Button, Gtk.Menu, Gtk.Menu_Item;
      use Report_Processor;
      use String_Conversions;
      parent_menu   : Gtk.Menu.Gtk_Menu;
      report_menu   : Gtk.Menu_Item.Gtk_Menu_Item;
   begin
      parent_menu := gtk_menu(Get_Object(Builder, "menu_reports"));
      for report_num in 1 .. Number_of_Reports loop
         -- Create the report menu item
         Gtk_New_With_Label(report_menu, 
                            Report_Name(for_report_number => report_num));
         Set_Action_Name(report_menu, "on_report_click");
         -- Attach(parent_menu, report_menu, 0, 1, 
            --     Glib.Guint(report_num - 1), Glib.Guint(report_num));
         Set_Sensitive(report_menu, true);
         -- Set the report menu item's call-back
         report_menu.On_Activate(Call=>Cell_Writer_Report_Clicked_CB'Access, 
                                 After=>False);
      end loop;
   end Set_Up_Reports_Menu_and_Buttons;
    
   procedure Initialise_Main_Menu(usage : in text;
                           DB_Descr : GNATCOLL.SQL.Exec.Database_Description;
                           with_tex_path : text;
                           with_pdf_path : text;
                           with_R_path   : text;
                           path_to_temp  : string := "/tmp/";
                           glade_filename: string := "cell_writer.glade") is
      use Glib.Error, Ada.Characters.Conversions;
      -- type GError_Access is access Glib.Error.GError;
      Builder : Gtkada_Builder;
      Error   : Glib.Error.GError_Access := null;
      count   : Glib.Guint;
   begin
      -- Set the locale specific data (e.g time and date format)
      -- Gtk.Main.Set_Locale;
      -- Create a Builder and add the XML data
      Gtk.Main.Init;
      -- Connect to the style sheet
      CSS_Management.Set_Up_CSS(for_file => path_to_temp & "cell_writer,css");
      -- Set up the Builder whti the Glade file
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
                       Handler_Name => "btn_train_clicked_cb",
                       Handler      => Training_Select_CB'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "btn_setup_clicked_cb",
                       Handler      => Setup_Select_CB'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "file_exit_select_cb",
                       Handler      => Menu_File_Exit_Select_CB'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "form_main_destroy_cb",
                       Handler      => Menu_File_Exit_Select_CB'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "btn_clear_clicked_cb",
                       Handler      => Btn_Clear_Clicked_CB'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "btn_keys_clicked_cb",
                       Handler      => Btn_Keys_Clicked_CB'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "btn_enter_clicked_cb",
                       Handler      => Btn_Enter_Clicked_CB'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "btn_tab_clicked_cb",
                       Handler      => Btn_Tab_Clicked_CB'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "btn_backspace_clicked_cb",
                       Handler      => Btn_Backspace_Clicked_CB'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "btn_del_clicked_cb",
                       Handler      => Btn_Del_Clicked_CB'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "btn_space_clicked_cb",
                       Handler      => Btn_Space_Clicked_CB'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "btn_up_clicked_cb",
                       Handler      => Btn_Up_Clicked_CB'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "btn_down_clicked_cb",
                       Handler      => Btn_Down_Clicked_CB'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "btn_left_clicked_cb",
                       Handler      => Btn_Left_Clicked_CB'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "btn_right_clicked_cb",
                       Handler      => Btn_Right_Clicked_CB'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "btn_home_clicked_cb",
                       Handler      => Btn_Home_Clicked_CB'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "btn_end_clicked_cb",
                       Handler      => Btn_End_Clicked_CB'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "btn_pageup_clicked_cb",
                       Handler      => Btn_PageUp_Clicked_CB'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "btn_pagedown_clicked_cb",
                       Handler      => Btn_PageDown_Clicked_CB'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "combo_language_changed_cb",
                       Handler      => Combo_Language_Changed_CB'Access);
      -- Drawing Event handlers
      Register_Handler(Builder      => Builder,
                       Handler_Name => "draw_1_01_button_press_event_cb",
                       Handler      => Btn_Draw_Press_Event_CB'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "draw_1_01_draw_cb",
                       Handler      => Draw_CB'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "draw_1_01_motion_notify_event_cb",
                       Handler      => Motion_Notify_CB'Access);
      
      -- Point images in Glade file to unloaded area in the temp directory
      declare
         use Gtk.Image;
         no_2_image : Gtk.Image.gtk_image;
         image_name : constant string := "chkbtn_no2_image";
         file_name  : constant string := path_to_temp & "toilet_action.jpeg";
      begin
         no_2_image := gtk_image(Get_Object(Builder, image_name));
         --Set(image => no_2_image, Filename=> file_name);
      end;
      
      -- Set up child forms
      Grid_Management.Initialise_Grid(Builder, DB_Descr);
      Keyboard.Initialise_Keyboard(Builder, DB_Descr);
      Setup.Initialise_Setup(Builder, DB_Descr, usage);
      Help_About.Initialise_Help_About(Builder, usage);
      -- Get_Date_Calendar.Initialise_Calendar(Builder);
      -- Urine_Colour_Selector.Initialise_Colour_Selector(Builder, DB_Descr,
         --                                               path_to_temp);
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
      -- Show/hide the combining character buttons (must be done after unhiding
      -- the main window).
      declare
         new_language : positive;
      begin
         Setup.Combo_Language_Changed(Builder, to_language => new_language);
         -- Display or hide the top row of combining accents based on language
         Setup.Set_Up_Combining(Builder, for_language => new_language);
      end;
      --form_main's kill is a kill all:
      -- c code: window.signal_connect("destroy") { Gtk.main_quit }
      -- where window=Gtkada.Builder.Get_Object (Builder, "form_main")
      Gtk.Main.Main;
      
      -- Clean up memory when done
      Unref (Builder);
   end Initialise_Main_Menu;
   
   procedure Btn_Clear_Clicked_CB 
                (Object : access Gtkada_Builder_Record'Class) is
      use Cursor_Management;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                        with_details=>"Btn_Clear_Clicked_CB: Start");
      -- clear the display
      null;
      -- and clear the buffer
      Clear_String;
   end Btn_Clear_Clicked_CB;

   procedure Btn_Enter_Clicked_CB
            (Object : access Gtkada_Builder_Record'Class) is
     -- Enter generally means transmit the data, including the Enter key
      use Cursor_Management;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                        with_details=>"Btn_Enter_Clicked_CB: Start");
      if Cursor_Management.Number_Of_Keystrokes > 0
      then  -- Transmit the data and clear the buffer
         Keyboard_Emulation.Transmit(the_buffer => All_Keystrokes);
         -- Clear the string
         Cursor_Management.Clear_String;
         -- And clear the display
         null;
      else  -- Transmit the Enter key
         Keyboard_Emulation.Transmit(key_press=> Keyboard.enter_key);
      end if;   
   end Btn_Enter_Clicked_CB;

   procedure Btn_Keys_Clicked_CB
            (Object : access Gtkada_Builder_Record'Class) is
      use Gtk.Toggle_Tool_Button;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                 with_details=>"Btn_Keys_Clicked_CB: Start");
      if Get_Active(Gtk_Toggle_Tool_Button(
                Gtkada.Builder.Get_Object(Gtkada_Builder(Object),"btn_keys")))
      then
      -- Hide ourself
         Gtk.Widget.Hide(Gtk.Widget.Gtk_Widget 
              (Gtkada.Builder.Get_Object(Gtkada_Builder(Object),"form_main")));
      -- Toggle the btn_keys button in preparation for showing
      -- ourselves again
         Set_Active(Gtk_Toggle_Tool_Button(
                Gtkada.Builder.Get_Object(Gtkada_Builder(Object),"btn_keys")),
                    Is_Active => False);
      -- And show the Keyboard
         Keyboard.Show_Keyboard (Gtkada_Builder(Object));
      end if;
   end Btn_Keys_Clicked_CB;

   procedure Setup_Select_CB  
                (Object : access Gtkada_Builder_Record'Class) is
   begin
      Error_Log.Debug_Data(at_level => 5, 
                              with_details=> "Setup_Select_CB: Start");
      Setup.Show_Setup(Gtkada_Builder(Object));
   end Setup_Select_CB;

   procedure Menu_File_Exit_Select_CB  
                (Object : access Gtkada_Builder_Record'Class) is
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Menu_File_Exit_Select_CB: Start");
      -- Shut down sub-forms where required
      --Urine_Records_Form.Finalise;
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

   procedure Training_Select_CB
                (Object : access Gtkada_Builder_Record'Class) is
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Training_Select_CB: Start");
      -- Help_Manual.Show_Manual(Gtkada_Builder(Object));
   end Training_Select_CB;

   procedure Btn_Tab_Clicked_CB
                (Object : access Gtkada_Builder_Record'Class) is
      use Keyboard_Emulation, Key_Sym_Def;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Btn_Tab_Clicked_CB: Start");
      Transmit(key_press => From_Key_ID(to_key_sym => XK_Tab));
   end Btn_Tab_Clicked_CB;
   
   procedure Btn_Backspace_Clicked_CB
                (Object : access Gtkada_Builder_Record'Class) is
      use Keyboard_Emulation, Key_Sym_Def;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Btn_Backspace_Clicked_CB: Start");
      Transmit(key_press => From_Key_ID(to_key_sym => XK_BackSpace));
   end Btn_Backspace_Clicked_CB;
   
   procedure Btn_Del_Clicked_CB
                (Object : access Gtkada_Builder_Record'Class) is
      use Keyboard_Emulation, Key_Sym_Def;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Btn_Del_Clicked_CB: Start");
      Transmit(key_press => From_Key_ID(to_key_sym => XK_Delete));
   end Btn_Del_Clicked_CB;
   
   procedure Btn_Space_Clicked_CB
                (Object : access Gtkada_Builder_Record'Class) is
      use Keyboard_Emulation;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Btn_Space_Clicked_CB: Start");
      Transmit(key_press => ' ');
   end Btn_Space_Clicked_CB;
   
   procedure Btn_Up_Clicked_CB
                (Object : access Gtkada_Builder_Record'Class) is
      use Keyboard_Emulation, Key_Sym_Def;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Btn_Up_Clicked_CB: Start");
      Transmit(key_press => From_Key_ID(to_key_sym => XK_Up));
   end Btn_Up_Clicked_CB;
   
   procedure Btn_Down_Clicked_CB
                (Object : access Gtkada_Builder_Record'Class) is
      use Keyboard_Emulation, Key_Sym_Def;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Btn_Down_Clicked_CB: Start");
      Transmit(key_press => From_Key_ID(to_key_sym => XK_Down));
   end Btn_Down_Clicked_CB;
   
   procedure Btn_Left_Clicked_CB
                (Object : access Gtkada_Builder_Record'Class) is
      use Keyboard_Emulation, Key_Sym_Def;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Btn_Left_Clicked_CB: Start");
      Transmit(key_press => From_Key_ID(to_key_sym => XK_Left));
   end Btn_Left_Clicked_CB;
   
   procedure Btn_Right_Clicked_CB
                (Object : access Gtkada_Builder_Record'Class) is
      use Keyboard_Emulation, Key_Sym_Def;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Btn_Right_Clicked_CB: Start");
      Transmit(key_press => From_Key_ID(to_key_sym => XK_Right));
   end Btn_Right_Clicked_CB;
   
   procedure Btn_Home_Clicked_CB
                (Object : access Gtkada_Builder_Record'Class) is
      use Keyboard_Emulation, Key_Sym_Def;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Btn_Home_Clicked_CB: Start");
      Transmit(key_press => From_Key_ID(to_key_sym => XK_Home));
   end Btn_Home_Clicked_CB;
   
   procedure Btn_End_Clicked_CB
                (Object : access Gtkada_Builder_Record'Class) is
      use Keyboard_Emulation, Key_Sym_Def;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Btn_End_Clicked_CB: Start");
      Transmit(key_press => From_Key_ID(to_key_sym => XK_End));
   end Btn_End_Clicked_CB;
   
   procedure Btn_PageUp_Clicked_CB
                (Object : access Gtkada_Builder_Record'Class) is
      use Keyboard_Emulation, Key_Sym_Def;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Btn_PageUp_Clicked_CB: Start");
      Transmit(key_press => From_Key_ID(to_key_sym => XK_Page_Up));
   end Btn_PageUp_Clicked_CB;
   
   procedure Btn_PageDown_Clicked_CB
                (Object : access Gtkada_Builder_Record'Class) is
      use Keyboard_Emulation, Key_Sym_Def;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Btn_PageDown_Clicked_CB: Start");
      Transmit(key_press => From_Key_ID(to_key_sym => XK_Page_Down));
   end Btn_PageDown_Clicked_CB;

   procedure Combo_Language_Changed_CB
                (Object : access Gtkada_Builder_Record'Class) is
      new_language : positive;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Combo_Language_Changed_CB: Start");
      Setup.Combo_Language_Changed(Object, to_language => new_language);
      -- Display or hide the top row of combining accents based on language
      Setup.Set_Up_Combining(Object, for_language => new_language);
      -- And set up the keyboard to the selected language
      Keyboard.Load_Keyboard(for_language => new_language,
                             at_object => Gtkada_Builder(Object));
   end Combo_Language_Changed_CB;

   function Btn_Draw_Press_Event_CB
                (Object : access Gtkada_Builder_Record'Class) return Boolean is
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Btn_Draw_Press_Event_CB: Start");
      null;
      return true;
   end Btn_Draw_Press_Event_CB;
   
   function Draw_CB
                (Object : access Gtkada_Builder_Record'Class) return Boolean is
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Draw_CB: Start");
      null;
      return true;
   end Draw_CB;
   
   function Motion_Notify_CB
                (Object : access Gtkada_Builder_Record'Class) return Boolean is
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Motion_Notify_CB: Start");
      null;
      return true;
   end Motion_Notify_CB;

   procedure Cell_Writer_Report_Clicked_CB(label : string) is
     -- Print the specified report (for the defined report Name).
      use Report_Processor;
      use String_Conversions;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Cell_Writer_Report_Clicked_CB: "&
                                           To_Wide_String(label) & ".");
      Run_The_Report(with_id => Report_ID(for_report_name => label));
   end Cell_Writer_Report_Clicked_CB;

   procedure Cell_Writer_Report_Clicked_CB
                (Object : access Gtk.Menu_Item.Gtk_Menu_Item_Record'Class) is
      -- Get the name of the report menu item and then print the report.
      use Gtk.Menu_Item;
   begin
       -- Get the name of the report menu item and then print the report.
      Cell_Writer_Report_Clicked_CB(label=>Get_Label(Gtk_Menu_Item(Object)));
   end Cell_Writer_Report_Clicked_CB;

   procedure Cell_Writer_Report_Clicked_CB
                (Object : access Gtk.Button.Gtk_Button_Record'Class) is
      -- Get the name of the report button and then print the report.
      use Gtk.Button;
   begin
      Cell_Writer_Report_Clicked_CB(label=>Get_Label(Gtk_Button(Object)));
   end Cell_Writer_Report_Clicked_CB;

begin
   Cell_Writer_Version.Register(revision => "$Revision: v1.0.2$",
                                 for_module => "Main_Menu");
end Main_Menu;