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
--  General  Public Licence distributed with Cell_Writer.  If  not,  --
--  write  to  the Free Software Foundation,  51  Franklin  Street,  --
--  Fifth Floor, Boston, MA 02110-1301, USA.                         --
--                                                                   --
-----------------------------------------------------------------------
-- with Gtkada.Builder;  use Gtkada.Builder;
-- with Gtk.Button, Gtk.Menu_Item, Gtk.Widget;
-- with dStrings; use dStrings;
-- with GNATCOLL.SQL.Exec;
with Gtk.Widget, Gtk.Image, Gtk.Toggle_Tool_Button, Gtk.Drawing_Area;
with Gtk.Tool_Button;
with Gtk.Grid;
with Gtk.Main, Gtk.Window;
with Gtk.Enums;
with Glib, Glib.Error;
with Gtk.Menu;
with Error_Log;
with String_Conversions;
with Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
with Ada.Characters.Conversions;
with Cell_Writer_Version;
with Help_About, Setup, CSS_Management, Keyboard, Grid_Management,
     Cursor_Management, Keyboard_Emulation;
with Key_Sym_Def;
with Report_Processor;
with Recogniser, Samples;
with Word_Frequency;
with Grid_Event_Handlers; use Grid_Event_Handlers;
with Grid_Training;
with Code_Interpreter;
package body Main_Menu is

   procedure Set_Up_Reports_Menu_and_Buttons (Builder : Gtkada_Builder) is
      use Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
      use Gtk.Button, Gtk.Menu, Gtk.Menu_Item;
      use Report_Processor;
      use String_Conversions;
      parent_menu   : Gtk.Menu.Gtk_Menu;
      report_menu   : Gtk.Menu_Item.Gtk_Menu_Item;
   begin
      parent_menu := gtk_menu(Get_Object(Builder, "menu_reports"));
      for report_num in 1 .. Number_of_Reports loop
         -- Create the report menu item
         report_menu := Gtk_Menu_Item_New_With_Label(Encode
                               (Report_Name(for_report_number => report_num)));
         -- Set_Action_Name(report_menu, "on_report_click");
         Set_Sensitive(report_menu, true);
         Set_Visible(report_menu, true);
         -- Set the report menu item's call-back
         report_menu.On_Activate(Call=>Cell_Writer_Report_Clicked_CB'Access, 
                                 After=>False);
         -- Attach the menu item to the report menu button
         Attach(parent_menu, report_menu, 0, 1, 
                Glib.Guint(report_num - 1), Glib.Guint(report_num));
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
      main_window : Gtk.Window.Gtk_Window;
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
         Error_Log.Put(the_error    => 2, 
                       error_intro  => "Initialise_Main_Menu: file name error",
                       error_message=> "Error in " & 
                                        To_Wide_String(glade_filename) & " : "&
                                        To_Wide_String(Glib.Error.Get_Message 
                                                                 (Error.all)));
         Glib.Error.Error_Free (Error.all);
      end if;
      
      -- Register window destruction
      main_window:= Gtk.Window.Gtk_Window(
                              Get_Object(Gtkada_Builder(Builder),"form_main"));
      -- main_window.On_Destroy(On_Window_Destroy'access, null);
      -- main_window.On_C
      
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
                       Handler_Name => "btn_ins_clicked_cb",
                       Handler      => Btn_Ins_Clicked_CB'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "btn_space_clicked_cb",
                       Handler      => Btn_Space_Clicked_CB'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "btn_sep_clicked_cb",
                       Handler      => Btn_Separator_Clicked_CB'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "btn_period_clicked_cb",
                       Handler      => Btn_Period_Clicked_CB'Access);
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
      Grid_Event_Handlers.Register_Handlers(with_builder => Builder,
                                            DB_Descr     => DB_Descr);
      
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
      -- We need to initialise the recogniser before initialising Setup or the
      -- keyboard so that the training samples are available when Setup tells
      -- Keyboard the language set we are using.  That then provides
      -- information on whether a particular key has been trained or not.
      Recogniser.Initialise_Recogniser(DB_Descr);
      -- Keyboard needs to be initialised before Setup because it gets told
      -- by Setup what language set we are using.
      Keyboard.Initialise_Keyboard(Builder, DB_Descr);
      Setup.Initialise_Setup(Builder, DB_Descr, usage);
      Help_About.Initialise_Help_About(Builder, usage);
      Samples.Initialise_Samples(DB_Descr);
      Code_Interpreter.Initialise_Interpreter(with_builder      => Builder,
                                              with_DB_Descr     => DB_Descr,
                                              reraise_exception => False);
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
         -- And set up the word frequency
         if Word_Frequency.Word_Frequency_Is_Enabled then
            Word_Frequency.Load_Word_Frequency(DB_Descr, 
                                               for_language => new_language);
         end if;
      end;
      --form_main's kill is a kill all:
      -- c code: window.signal_connect("destroy") { Gtk.main_quit }
      -- where window=Gtkada.Builder.Get_Object (Builder, "form_main")
      -- Kevin O'Kane, who inserts his code somewhere before doing a connect,
      -- does the following in c:
      -- g_signal_connect(window, "destroy", G_CALLBACK(gtk_main_quit), NULL);
      -- where window is the main window widget
      Gtk.Main.Main;
      
      -- Clean up memory when done
      Unref (Builder);
   end Initialise_Main_Menu;
   
   procedure Btn_Clear_Clicked_CB 
                (Object : access Gtkada_Builder_Record'Class) is
      use Cursor_Management, Gtk.Widget, Gtk.Grid;
      -- If not training then clear the grid, otherwise delete all training
      -- data for the character or word at the current cell if in training.
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details=>"Btn_Clear_Clicked_CB: Start");
      if Grid_Event_Handlers.Training_Is_Switched_On
      then  -- delete all training data for character at cursor position
         Recogniser.Untrain
              (the_character => Grid_Event_Handlers.The_Current_Cell_Contents);
         Refresh_Current_Cell;  -- make sure it is appropriately highlighted
      else  -- clear the grid
         -- clear the display by queueing up a draw event
         Grid_Event_Handlers.Clear_The_Grid;
         -- and clear the buffer
         Clear_String;
         -- then send the grid cell cursor home
         Grid_Event_Handlers.Cursor_First_Column;
         Grid_Event_Handlers.Cursor_First_Row;
      end if;
   end Btn_Clear_Clicked_CB;

   procedure Btn_Enter_Clicked_CB
            (Object : access Gtkada_Builder_Record'Class) is
     -- Enter generally means transmit the data, including the Enter key
      use Gtk.Toggle_Tool_Button, Cursor_Management;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details=>"Btn_Enter_Clicked_CB: Start");
      if not Get_Active(gtk_toggle_tool_button(
                            Get_Object(Gtkada_Builder(Object),"btn_kbd_keys")))
      then  -- displaying main grid - load the entered characters/words
         Cursor_Management.Add(a_word => Grid_Event_Handlers.Entered_Text);
         Grid_Event_Handlers.Update_Character_Usage;  -- for training sample
      end if; 
      if Cursor_Management.Number_Of_Keystrokes > 0
      then  -- Transmit the data and clear the buffer
         Keyboard_Emulation.Transmit(the_buffer => All_Keystrokes);
         -- Clear the string
         Cursor_Management.Clear_String;
         -- And clear the display
         null;
         -- then send the grid cell cursor to the home position
         Grid_Event_Handlers.Cursor_First_Column;
         Grid_Event_Handlers.Cursor_First_Row;
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
         -- If any text has been entered into the grid, then move this to the
         -- keyboard buffer (will add nothing if there is nothing to add).
         Cursor_Management.Add(a_word => Grid_Event_Handlers.Entered_Text);
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

   exit_process_started : boolean := false;
   procedure Menu_File_Exit_Select_CB  
                (Object : access Gtkada_Builder_Record'Class) is
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Menu_File_Exit_Select_CB: Start");
      if not exit_process_started then  -- do the following once only!
         exit_process_started := true;
         -- Shut down sub-forms and update database where required
         Recogniser.Finalise_Recogniser;
         -- and shut ourselves down
         Gtk.Main.Main_Quit;
      end if;
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
      use Gtk.Toggle_Tool_Button, Gtk.Tool_Button;
      trg_toggled : boolean renames Get_Active(
                   gtk_toggle_tool_button(Get_Object(Object,"btn_training")));
      ins_key : gtk_tool_button:=gtk_tool_button(Get_Object(Object,"btn_ins"));
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Training_Select_CB: Start");
      -- Send the cursor to the grid cell home position first
      Grid_Event_Handlers.Cursor_First_Column;
      Grid_Event_Handlers.Cursor_First_Row;
      -- Now toggle training mode accordingly
      if trg_toggled
      then  -- training button is depressed
         Grid_Event_Handlers.Set_Training_Switch(to => true);
         -- Hide insert key (only has meaning when not training)
         Set_Visible(ins_key, visible => false);
      else  -- training button is not depressed
         Grid_Event_Handlers.Set_Training_Switch(to => false);
         -- Show insert key (only has meaning when not training)
         Set_Visible(ins_key, visible => true);
      end if;
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
      use Gtk.Toggle_Tool_Button;
      use Keyboard_Emulation, Key_Sym_Def;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Btn_Backspace_Clicked_CB: Start");
      if Get_Active(gtk_toggle_tool_button(Get_Object(Object,"btn_grid_edit")))
      then  -- depressed button to use cursor control to edit the line
         Grid_Event_Handlers.Backspace;
      else  -- don't manipulate grid cells, assume data is to be transmitted
         Transmit(key_press => From_Key_ID(to_key_sym => XK_BackSpace));
      end if;
   end Btn_Backspace_Clicked_CB;
   
   procedure Btn_Del_Clicked_CB
                (Object : access Gtkada_Builder_Record'Class) is
      use Gtk.Toggle_Tool_Button;
      use Keyboard_Emulation, Key_Sym_Def;
      in_grid_editing : boolean renames Get_Active(
                   gtk_toggle_tool_button(Get_Object(Object,"btn_grid_edit")));
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Btn_Del_Clicked_CB: Start");
      if Grid_Event_Handlers.Training_Is_Switched_On
      then   -- untrain and refresh the grid cell
         Recogniser.Untrain_Last_Sample
            (for_the_character=>Grid_Event_Handlers.The_Current_Cell_Contents);
         Refresh_Current_Cell;  -- make sure it is appropriately highlighted
      else
         if in_grid_editing
         then  -- depressed button to use cursor control to edit the line
            Grid_Event_Handlers.Delete_Cell_Contents;
         else  -- don't manipulate grid cells, assume data is to be transmitted
            Transmit(key_press => From_Key_ID(to_key_sym => XK_Delete));
         end if;
      end if;
   end Btn_Del_Clicked_CB;

   procedure Btn_Ins_Clicked_CB
                (Object : access Gtkada_Builder_Record'Class) is
      use Gtk.Toggle_Tool_Button;
      use Keyboard_Emulation, Key_Sym_Def;
      in_grid_editing : boolean renames Get_Active(
                   gtk_toggle_tool_button(Get_Object(Object,"btn_grid_edit")));
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Btn_Ins_Clicked_CB: Start");
      if in_grid_editing
      then  -- depressed button to use cursor control to edit the line
         Grid_Event_Handlers.Insert_Cell;
      else  -- don't manipulate grid cells, assume data is to be transmitted
         Transmit(key_press => From_Key_ID(to_key_sym => XK_Insert));
      end if;
   end Btn_Ins_Clicked_CB;
   
   procedure Btn_Space_Clicked_CB
                (Object : access Gtkada_Builder_Record'Class) is
      -- We assume here that if the Grid edit button is depressed, then the
      -- user wants to put a space into the currently selected cell.  If it
      -- isn't depressed, then the user wants to transmit the space to the
      -- active application.
      use Gtk.Toggle_Tool_Button;
      use Keyboard_Emulation;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Btn_Space_Clicked_CB: Start");
      if Get_Active(gtk_toggle_tool_button(Get_Object(Object,"btn_grid_edit")))
      then  -- depressed button to use cursor control to edit the line
         Grid_Event_Handlers.Set_Current_Cell(to => ' ');
      else  -- don't manipulate grid cells, assume data is to be transmitted
         Transmit(key_press => ' ');
      end if;
   end Btn_Space_Clicked_CB;
   
   procedure Btn_Separator_Clicked_CB
                (Object : access Gtkada_Builder_Record'Class) is
     -- We assume here that if training is pressed, then the key can only be
     -- transmitted, but if unpressed, then it always goes to the currently
     -- active grid cell.  We assume that the user never wants to transmit it
     -- to the application when not in training mode.
      use Gtk.Toggle_Tool_Button;
      use Keyboard_Emulation;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Btn_Separator_Clicked_CB: Start");
      if not Grid_Event_Handlers.Training_Is_Switched_On
      then  -- training button is not depressed
         -- Load current cell with the separator (default is quarter space)
         Grid_Event_Handlers.Set_Current_Cell(to => Setup.The_Special_Button);
      else
         Transmit(key_press => Setup.The_Special_Button);
      end if;
   end Btn_Separator_Clicked_CB;
   
   procedure Btn_Period_Clicked_CB
                (Object : access Gtkada_Builder_Record'Class) is
      -- We assume here that if the Grid edit button is depressed, then the
      -- user wants to put a period into the currently selected cell.  If it
      -- isn't depressed, then the user wants to transmit the period to the
      -- active application.
      use Gtk.Toggle_Tool_Button;
      use Keyboard_Emulation;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Btn_Period_Clicked_CB: Start");
      if Get_Active(gtk_toggle_tool_button(Get_Object(Object,"btn_grid_edit")))
      then  -- depressed button to use cursor control to edit the line
         Grid_Event_Handlers.Set_Current_Cell(to => '.');
      else  -- don't manipulate grid cells, assume data is to be transmitted
         Transmit(key_press => '.');
      end if;
   end Btn_Period_Clicked_CB;

   procedure Btn_Up_Clicked_CB
                (Object : access Gtkada_Builder_Record'Class) is
      use Gtk.Toggle_Tool_Button;
      use Keyboard_Emulation, Key_Sym_Def;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Btn_Up_Clicked_CB: Start");
      if Grid_Event_Handlers.Training_Is_Switched_On
      then
         Grid_Training.Grid_Row_Up;
         Grid_Event_Handlers.Display_Training_Data;
      elsif Get_Active(gtk_toggle_tool_button(Get_Object(Object,"btn_grid_edit")))
      then  -- depressed button to use cursor control to edit the line
         Grid_Event_Handlers.Cursor_Up;
      else  -- don't manipulate grid cells, assume data is to be transmitted
         Transmit(key_press => From_Key_ID(to_key_sym => XK_Up));
      end if;
   end Btn_Up_Clicked_CB;
   
   procedure Btn_Down_Clicked_CB
                (Object : access Gtkada_Builder_Record'Class) is
      use Gtk.Toggle_Tool_Button;
      use Keyboard_Emulation, Key_Sym_Def;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Btn_Down_Clicked_CB: Start");
      if Grid_Event_Handlers.Training_Is_Switched_On
      then
         Grid_Training.Grid_Row_Down;
         Grid_Event_Handlers.Display_Training_Data;
      elsif Get_Active(gtk_toggle_tool_button(Get_Object(Object,"btn_grid_edit")))
      then  -- depressed button to use cursor control to edit the line
         Grid_Event_Handlers.Cursor_Down;
      else  -- don't manipulate grid cells, assume data is to be transmitted
         Transmit(key_press => From_Key_ID(to_key_sym => XK_Down));
      end if;
   end Btn_Down_Clicked_CB;
   
   procedure Btn_Left_Clicked_CB
                (Object : access Gtkada_Builder_Record'Class) is
      use Gtk.Toggle_Tool_Button;
      use Keyboard_Emulation, Key_Sym_Def;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Btn_Left_Clicked_CB: Start");
      if Get_Active(gtk_toggle_tool_button(Get_Object(Object,"btn_grid_edit")))
      then  -- depressed button to use cursor control to edit the line
         Grid_Event_Handlers.Cursor_Left;
      else  -- don't manipulate grid cells, assume data is to be transmitted
         Transmit(key_press => From_Key_ID(to_key_sym => XK_Left));
      end if;
   end Btn_Left_Clicked_CB;
   
   procedure Btn_Right_Clicked_CB
                (Object : access Gtkada_Builder_Record'Class) is
      use Gtk.Toggle_Tool_Button;
      use Keyboard_Emulation, Key_Sym_Def;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Btn_Right_Clicked_CB: Start");
      if Get_Active(gtk_toggle_tool_button(Get_Object(Object,"btn_grid_edit")))
      then  -- depressed button to use cursor control to edit the line
         Grid_Event_Handlers.Cursor_Right;
      else  -- don't manipulate grid cells, assume data is to be transmitted
         Transmit(key_press => From_Key_ID(to_key_sym => XK_Right));
      end if;
   end Btn_Right_Clicked_CB;
   
   procedure Btn_Home_Clicked_CB
                (Object : access Gtkada_Builder_Record'Class) is
      use Gtk.Toggle_Tool_Button;
      use Keyboard_Emulation, Key_Sym_Def;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Btn_Home_Clicked_CB: Start");
      if Grid_Event_Handlers.Training_Is_Switched_On
      then
         Grid_Training.Point_At_Grid_Start;
         Grid_Event_Handlers.Display_Training_Data;
      elsif Get_Active(gtk_toggle_tool_button(Get_Object(Object,"btn_grid_edit")))
      then  -- depressed button to use cursor control to edit the line
         Grid_Event_Handlers.Cursor_First_Column;
         Grid_Event_Handlers.Cursor_First_Row;
      else  -- don't manipulate grid cells, assume data is to be transmitted
         Transmit(key_press => From_Key_ID(to_key_sym => XK_Home));
      end if;
   end Btn_Home_Clicked_CB;
   
   procedure Btn_End_Clicked_CB
                (Object : access Gtkada_Builder_Record'Class) is
      use Gtk.Toggle_Tool_Button;
      use Keyboard_Emulation, Key_Sym_Def;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Btn_End_Clicked_CB: Start");
      if Grid_Event_Handlers.Training_Is_Switched_On
      then
         Grid_Training.Point_At_Grid_End;
         Grid_Event_Handlers.Display_Training_Data;
      elsif Get_Active(gtk_toggle_tool_button(Get_Object(Object,"btn_grid_edit")))
      then  -- depressed button to use cursor control to edit the line
         Grid_Event_Handlers.Cursor_Last_Column;
         Grid_Event_Handlers.Cursor_Last_Row;
      else  -- don't manipulate grid cells, assume data is to be transmitted
         Transmit(key_press => From_Key_ID(to_key_sym => XK_End));
      end if;
   end Btn_End_Clicked_CB;
   
   procedure Btn_PageUp_Clicked_CB
                (Object : access Gtkada_Builder_Record'Class) is
      use Gtk.Toggle_Tool_Button;
      use Keyboard_Emulation, Key_Sym_Def;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Btn_PageUp_Clicked_CB: Start");
      if Grid_Event_Handlers.Training_Is_Switched_On
      then
         Grid_Training.Grid_Page_Up;
         Grid_Event_Handlers.Display_Training_Data;
      elsif Get_Active(gtk_toggle_tool_button(Get_Object(Object,"btn_grid_edit")))
      then  -- depressed button to use cursor control to edit the line
         Grid_Event_Handlers.Cursor_First_Row;
      else  -- don't manipulate grid cells, assume data is to be transmitted
         Transmit(key_press => From_Key_ID(to_key_sym => XK_Page_Up));
      end if;
   end Btn_PageUp_Clicked_CB;
   
   procedure Btn_PageDown_Clicked_CB
                (Object : access Gtkada_Builder_Record'Class) is
      use Gtk.Toggle_Tool_Button;
      use Keyboard_Emulation, Key_Sym_Def;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Btn_PageDown_Clicked_CB: Start");
      if Grid_Event_Handlers.Training_Is_Switched_On
      then
         Grid_Training.Grid_Page_Down;
         Grid_Event_Handlers.Display_Training_Data;
      elsif Get_Active(gtk_toggle_tool_button(Get_Object(Object,"btn_grid_edit")))
      then  -- depressed button to use cursor control to edit the line
         Grid_Event_Handlers.Cursor_Last_Row;
      else  -- don't manipulate grid cells, assume data is to be transmitted
         Transmit(key_press => From_Key_ID(to_key_sym => XK_Page_Down));
      end if;
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
      -- And set up the word frequency
      if Word_Frequency.Word_Frequency_Is_Enabled then
         Word_Frequency.Load_Word_Frequency(for_language => new_language);
      end if;
      -- Activate relevant training samples
      Recogniser.Update_Enabled_Samples;
      -- And set up the keyboard to the selected language
      Keyboard.Load_Keyboard(for_language => new_language,
                             at_object => Gtkada_Builder(Object));
   end Combo_Language_Changed_CB;

    -- Window destruction management
   procedure On_Window_Destroy(the_window : access Gtk_Widget_Record'Class;
                               cb : Cb_Gtk_Widget_Void) is
   begin
      Menu_File_Exit_Select_CB(Object=>null);
   end On_Window_Destroy;
   
   procedure On_Window_Close_Request(the_window : access Gtk_Widget_Record'Class) is
   begin
      null; -- On_Window_Destroy(the_window, null);
   end On_Window_Close_Request;

   procedure Cell_Writer_Report_Clicked_CB(label : Glib.UTF8_string) is
     -- Print the specified report (for the defined report Name).
      use Report_Processor;
      use String_Conversions;
      use Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Cell_Writer_Report_Clicked_CB: "&
                                           To_Wide_String(label) & ".");
      Run_The_Report(with_id => Report_ID(for_report_name => Decode(label)));
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