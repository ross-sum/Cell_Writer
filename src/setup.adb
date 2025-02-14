-----------------------------------------------------------------------
--                                                                   --
--                             S E T U P                             --
--                                                                   --
--                              B o d y                              --
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
--  General  Public Licence distributed with Cell_Writer.  If  not,  --
--  write  to  the Free Software Foundation,  51  Franklin  Street,  --
--  Fifth Floor, Boston, MA 02110-1301, USA.                         --
--                                                                   --
-----------------------------------------------------------------------
-- with Gtkada.Builder;  use Gtkada.Builder;
-- with Gtk.Combo_Box;
-- with Glib.Object, Gdk.RGBA, Pango.Font;
-- with dStrings;        use dStrings;
-- with GNATCOLL.SQL;
with Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
with GNATCOLL.SQL.Exec.Tasking, GNATCOLL.SQL_BLOB;
with Database;                   use Database;
with Gtk.Widget;
with Error_Log;
with dStrings;
with Cell_Writer_Version, CSS_Management;
with Glib.Values;
with Gtk.List_Store, Gtk.Tree_Model, Gtk.Tree_Selection;
with Gtk.Label, Gtk.Check_Button, Gtk.Color_Button;
with Gtk.Cell_Renderer_Toggle, Gtk.Tree_view, Gtk.Tree_Row_Reference;
with Gtk.Text_Buffer, Gtk.Text_Iter;
with Gtk.Button, Gtk.Font_Button, Gtk.Spin_Button, Gtk.Tool_Button;
with Gtk.Adjustment;
with String_Conversions;
with Help_About;
with Grid_Management, Keyboard;
with Recogniser, Word_Frequency, Samples;
package body Setup is
   use GNATCOLL.SQL;
   
   the_builder : Gtkada_Builder;
   cDB         : GNATCOLL.SQL.Exec.Database_Connection;
   lingo_select    : constant GNATCOLL.SQL.Exec.Prepared_Statement :=
      GNATCOLL.SQL.Exec.Prepare 
           (SQL_Select (Fields  => Languages.ID & Languages.Name &
                                   Languages.Description & Languages.Selected &
                                   Languages.Start & Languages.EndChar,
                        From    => Languages,
                        Where   => (Languages.ID > 0),
                        Order_By=> Languages.ID),
            On_Server => True,
            Use_Cache => True);
   lingo_list_sel  : constant GNATCOLL.SQL.Exec.Prepared_Statement :=
      GNATCOLL.SQL.Exec.Prepare 
           (SQL_Select (Fields  => Languages.ID & Languages.Name &
                                   Languages.Description & Languages.Selected &
                                   Languages.Start & Languages.EndChar,
                        From    => Languages,
                        Where   => (Languages.ID > 0) AND (Languages.Selected),
                        Order_By=> Languages.ID),
            On_Server => True,
            Use_Cache => True);
   lingo_sel_item  : constant GNATCOLL.SQL.Exec.Prepared_Statement :=
      GNATCOLL.SQL.Exec.Prepare 
           (SQL_Select (Fields  => Languages.ID & Languages.Name &
                                   Languages.Description & Languages.Selected &
                                   Languages.Start & Languages.EndChar,
                        From    => Languages,
                        Where   => (Languages.ID = Integer_Param(1)),
                        Order_By=> Languages.ID),
            On_Server => True,
            Use_Cache => True);
   combine_select  : constant GNATCOLL.SQL.Exec.Prepared_Statement :=
      GNATCOLL.SQL.Exec.Prepare 
           (SQL_Select (Fields  => CombiningChrs.Language & 
                                   CombiningChrs.ButtonNum &
                                   CombiningChrs.CChar & 
                                   CombiningChrs.ToolTip &
                                   CombiningChrs.Display &
                                   CombiningChrs.Macro,
                        From    => CombiningChrs,
                        Where   => (CombiningChrs.Language = Integer_Param(1)),
                        Order_By=> CombiningChrs.ButtonNum),
            On_Server => True,
            Use_Cache => True);
   CW_select       : constant GNATCOLL.SQL.Exec.Prepared_Statement :=
      GNATCOLL.SQL.Exec.Prepare 
           (SQL_Select (Fields  => Configurations.ID & Configurations.Name & 
                                   Configurations.DetFormat & Configurations.Details,
                        From    => Configurations,
                        Where   => (Configurations.ID > 0) AND
                                   ((Configurations.DetFormat = "S") OR -- str
                                    (Configurations.DetFormat = "N") OR -- num
                                    (Configurations.DetFormat = "L") OR -- bool
                                    ((Configurations.DetFormat = "T") AND
                                     (Configurations.ID = 29))),        -- CSS
                        Order_By=> Configurations.ID),
            On_Server => True,
            Use_Cache => True);
   CW_update       : constant GNATCOLL.SQL.Exec.Prepared_Statement :=
      GNATCOLL.SQL.Exec.Prepare 
           (SQL_Update(Table => Configurations,
                       Set   => (Configurations.Details = Text_Param(2)),
                       Where => (Configurations.ID      = Integer_Param(1))),
            On_Server => True,
            Use_Cache => False);
   lang_select     : constant GNATCOLL.SQL.Exec.Prepared_Statement :=
      GNATCOLL.SQL.Exec.Prepare 
           (SQL_Select (Fields  => Configurations.ID & Configurations.Name & 
                                   Configurations.DetFormat & Configurations.Details,
                        From    => Configurations,
                        Where   => (Configurations.Name = "language"),
                        Order_By=> Configurations.ID),
            On_Server => True,
            Use_Cache => True);
   lang_update     : constant GNATCOLL.SQL.Exec.Prepared_Statement :=
      GNATCOLL.SQL.Exec.Prepare 
           (SQL_Update(Table => Languages,
                       Set   => (Languages.Selected = Boolean_Param(2)),
                       Where => (Languages.ID       = Integer_Param(1))),
            On_Server => True,
            Use_Cache => False);
    
   type database_change_state is (unchanged, changed);
   language_list_changed : database_change_state := unchanged;
   
   -- Special character key 
   special_character : wide_character := wide_character'Val(16#202F#);
                                          -- default to non-breaking space

   procedure Initialise_Setup(Builder : in out Gtkada_Builder;
                              DB_Descr: GNATCOLL.SQL.Exec.Database_Description;
                              usage : in text) is
      use Gtk.Label, String_Conversions;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details=> "Initialise_Setup: Start");
      the_builder := Builder;  -- save for later use
      -- Set up: Open the relevant tables from the database
      cDB:=GNATCOLL.SQL.Exec.Tasking.Get_Task_Connection(Description=>DB_Descr);
      -- GNATCOLL.SQL.Exec.Automatic_Transactions(cDB, Active => false);
      -- Register the handlers
      Register_Handler(Builder      => Builder,
                       Handler_Name => "dialogue_setup_close_clicked_cb",
                       Handler      => Setup_Close_CB'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "dialogue_setup_cancel_clicked_cb",
                       Handler      => Setup_Cancel_CB'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "dialogue_setup_delete_event_cb",
                       Handler      => Setup_Hide_On_Delete'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "dialogue_setup_destroy_cb",
                       Handler      => Setup_Close_CB'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "edit_lingo_selected_toggled_cb",
                       Handler      => Setup_Language_Selected'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "help_manual_activate_cb",
                       Handler      => Setup_Show_Help'Access);
      -- Handler for "combo_language_changed_cb" already set up in main_menu.
      -- set up: load the fields from the database
      Load_Data_From(database => cDB, Builder => Builder);
                       
   end Initialise_Setup;
   
   procedure Set_To_ID(Builder       : access Gtkada_Builder_Record'Class;
                          combo      : Gtk.Combo_Box.gtk_combo_box;
                          list_store : string; id : natural) is
      -- Sets the Combo box to the specified identifier based on what
      -- that identifier is in the list store.
      use Gtk.Tree_Selection, Gtk.List_Store, Gtk.Combo_Box;
      iter     : Gtk.Tree_Model.gtk_tree_iter;
      store    : Gtk.List_Store.gtk_list_store;
      col_data : Glib.Values.GValue;
      rec_no   : natural := 0;
   begin
      store := gtk_list_store(Get_Object(Builder, list_store));
      iter := Get_Iter_First(store);
      Get_Value(Tree_Model => store, Iter => iter, 
                   Column => 0, Value => col_data);
      while Integer(Glib.Values.Get_Int(col_data)) /= id loop
         Next(store, iter);
         Get_Value(Tree_Model => store, Iter => iter, 
                      Column => 0, Value => col_data);
         rec_no := rec_no + 1;
      end loop;
      Set_Active(combo, Glib.Gint(rec_no));
   end Set_To_ID;
   
   procedure Load_Data_From(database : GNATCOLL.SQL.Exec.Database_Connection;
                            Builder : in Gtkada_Builder) is
      use GNATCOLL.SQL.Exec, Gdk.RGBA;
      use Gtk.Spin_Button, Gtk.Check_Button, Gtk.Combo_Box, Gtk.Color_Button;
      use Gtk.Font_Button;
      use Gtk.Text_Buffer;
      use Keyboard, String_Conversions, dStrings;
      R_lingo    : Forward_Cursor;
      lang_no     : positive := 1;
      R_config   : Forward_Cursor;
      spin_entry : Gtk.Spin_Button.gtk_spin_button;
      check_box  : Gtk.Check_Button.gtk_check_button;
      combo_box  : Gtk.Combo_Box.gtk_combo_box;
      text_buffer: Gtk.Text_Buffer.gtk_text_buffer;
      colour_btn : Gtk.Color_Button.gtk_color_button;
      the_colour : Gdk.RGBA.Gdk_RGBA;
      grid_UBG   : Gdk.RGBA.Gdk_RGBA := White_RGBA;
      grid_NBG   : Gdk.RGBA.Gdk_RGBA := White_RGBA;
      grid_FG    : Gdk.RGBA.Gdk_RGBA := Black_RGBA;
      succeeded  : boolean;
      font_btn   : Gtk.Font_Button.gtk_font_button;
      lingo_store: Gtk.List_Store.gtk_list_store;
      my_lingo   : Gtk.List_Store.gtk_list_store;
      lingo_iter : Gtk.Tree_Model.gtk_tree_iter;
      my_iter    : Gtk.Tree_Model.gtk_tree_iter;
      grid_rows  : natural := 4;
      grid_cols  : natural := 10;
      cell_horiz : natural := 45;
      cell_vert  : natural := 70;
      use Gtk.List_Store, GLib;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details=> "Load_Data_From: Start");
      -- Set up and load the list of languages
      R_lingo.Fetch (Connection => database, Stmt => lingo_select);
      if Success(database) and then Has_Row(R_lingo) then
         -- set up the list stores
         lingo_store := gtk_list_store(
                     Gtkada.Builder.Get_Object(Builder, "the_languages_table"));
         Clear(lingo_store);  -- empty the sub-table ready for the new data
         my_lingo := gtk_list_store(
                     Gtkada.Builder.Get_Object(Builder, "my_languages_table"));
         Clear(my_lingo);  -- empty the sub-table ready for the new data
         -- Load the display tree
         while Has_Row(R_lingo) loop  -- while not end_of_table
            Append(lingo_store, lingo_iter);
            Set(lingo_store,lingo_iter,0,Glib.Gint(Integer_Value(R_lingo,0)));
            Set(lingo_store,lingo_iter,1,Glib.UTF8_String(Value(R_lingo,1)));
            Set(lingo_store,lingo_iter,2,(Glib.Gint(Integer_Value(R_lingo,3)) /= 0));
            Set(lingo_store,lingo_iter,3,Glib.UTF8_String(Value(R_lingo,2)));
            Set(lingo_store,lingo_iter,4,Glib.Gint(Integer_Value(R_lingo,4)));
            Set(lingo_store,lingo_iter,5,Glib.Gint(Integer_Value(R_lingo,5)));
            if (Glib.Gint(Integer_Value(R_lingo,3)) /= 0) then -- a selected language
               Append(my_lingo, my_iter);  -- load to combo box lingo list
               Set(my_lingo,my_iter,0,Glib.Gint(Integer_Value(R_lingo,0)));
               Set(my_lingo,my_iter,1,Glib.UTF8_String(Value(R_lingo,1)));
               Set(my_lingo,my_iter,2,Glib.Gint(Integer_Value(R_lingo,4)));
               Set(my_lingo,my_iter,3,Glib.Gint(Integer_Value(R_lingo,5)));
            end if;
            Next(R_lingo);  -- next record(Configurations)
         end loop;
      end if;
      -- set up and load the configuration details
      R_config.Fetch (Connection => database, Stmt => CW_select);
      if Success(database) and then Has_Row(R_config) then
         while Has_Row(R_config) loop  -- while not end_of_table
            if Value(R_config,1) = "dimension_cells_horiz" then
               spin_entry := gtk_spin_button(Get_Object(Builder, 
                                               "setup_dimension_cells_horiz"));
               Set_Value(spin_entry, 
                        Glib.GDouble(Float(Integer'Value(Value(R_config,3)))));
               cell_horiz := Integer'Value(Value(R_config,3));
            elsif Value(R_config,1) = "dimension_cells_vert" then
               spin_entry := gtk_spin_button(Get_Object(Builder, 
                                               "setup_dimension_cells_vert"));
               Set_Value(spin_entry, 
                        Glib.GDouble(Float(Integer'Value(Value(R_config,3)))));
               cell_vert  := Integer'Value(Value(R_config,3));
            elsif Value(R_config,1) = "dimension_grid_horiz" then
               spin_entry := gtk_spin_button(Get_Object(Builder, 
                                               "setup_dimension_grid_horiz"));
               Set_Value(spin_entry, 
                        Glib.GDouble(Float(Integer'Value(Value(R_config,3)))));
               grid_cols := Integer'Value(Value(R_config,3));
            elsif Value(R_config,1) = "dimension_grid_vert" then
               spin_entry := gtk_spin_button(Get_Object(Builder, 
                                               "setup_dimension_grid_vert"));
               Set_Value(spin_entry, 
                        Glib.GDouble(Float(Integer'Value(Value(R_config,3)))));
               grid_rows := Integer'Value(Value(R_config,3));
            elsif Value(R_config,1) = "dimensions_keyboard" then
               spin_entry := gtk_spin_button(Get_Object(Builder, 
                                               "setup_dimensions_keyboard"));
               Set_Value(spin_entry, 
                        Glib.GDouble(Float(Integer'Value(Value(R_config,3)))));
            elsif Value(R_config,1) = "show_button_labels" then
               check_box := gtk_check_button(Get_Object(Builder, 
                                        "checkbox_window_show_button_labels"));
               Set_Active(check_box, (Value(R_config,3) /= "0"));
            elsif Value(R_config,1) = "show_onscreen_keyboard" then
               check_box := gtk_check_button(Get_Object(Builder, 
                                    "checkbox_window_show_onscreen_keyboard"));
               Set_Active(check_box, (Value(R_config,3) /= "0"));
            elsif Value(R_config,1) = "enable_extended_input_events" then
               check_box := gtk_check_button(Get_Object(Builder, 
                              "checkbox_window_enable_extended_input_events"));
               Set_Active(check_box, (Value(R_config,3) /= "0"));
            elsif Value(R_config,1) = "menu_left_click" then
               check_box := gtk_check_button(Get_Object(Builder, 
                                           "checkbox_status_menu_left_click"));
               Set_Active(check_box, (Value(R_config,3) /= "0"));
            elsif Value(R_config,1) = "window_docking" then
               combo_box := gtk_combo_box(Get_Object(Builder, 
                                                "combo_setup_window_docking"));
               Set_Active(combo_box, 
                          Glib.Gint(integer'Value(Value(R_config,3))));
            elsif Value(R_config,1) = "cell_writer.css" then
               text_buffer := gtk_text_buffer(Get_Object(Builder, 
                                                "textbuffer_css"));
               Set_Text(text_buffer, Value(R_config,3));
            elsif Value(R_config,1) = "manual" then
               text_buffer := gtk_text_buffer(Get_Object(Builder, 
                                                "textbuffer_manual"));
               Set_Text(text_buffer, Value(R_config,3));
            -- Colours and Font
            elsif Value(R_config,1) = "used_cell_colour" then
               colour_btn := gtk_color_button(Get_Object(Builder, 
                                           "colour_used_cell"));
               Parse(the_colour, Value(R_config,3), succeeded);
               if succeeded then
                  Set_Rgba(colour_btn, the_colour);
                  grid_UBG := the_colour;
               end if;
            elsif Value(R_config,1) = "blank_cell_colour" then
               colour_btn := gtk_color_button(Get_Object(Builder, 
                                           "colour_blank_cell"));
               Parse(the_colour, Value(R_config,3), succeeded);
               if succeeded then
                  Set_Rgba(colour_btn, the_colour);
                  grid_NBG := the_colour;
               end if;
            elsif Value(R_config,1) = "highlight_colour" then
               colour_btn := gtk_color_button(Get_Object(Builder, 
                                           "colour_highlight"));
               Parse(the_colour, Value(R_config,3), succeeded);
               if succeeded then Set_Rgba(colour_btn, the_colour); end if;
            elsif Value(R_config,1) = "text_and_ink_colour" then
               colour_btn := gtk_color_button(Get_Object(Builder, 
                                           "colour_text_and_ink"));
               Parse(the_colour, Value(R_config,3), succeeded);
               if succeeded then
                  Set_Rgba(colour_btn, the_colour);
                  grid_FG := the_colour;
               end if;
            elsif Value(R_config,1) = "key_face_colour" then
               colour_btn := gtk_color_button(Get_Object(Builder, 
                                           "colour_key_face"));
               Parse(the_colour, Value(R_config,3), succeeded);
               if succeeded then Set_Rgba(colour_btn, the_colour); end if;
            elsif Value(R_config,1) = "key_text_colour" then
               colour_btn := gtk_color_button(Get_Object(Builder, 
                                           "colour_key_text"));
               Parse(the_colour, Value(R_config,3), succeeded);
               if succeeded then Set_Rgba(colour_btn, the_colour); end if;
            --    (Font)
            elsif Value(R_config,1) = "font" then
               font_btn := gtk_font_button(Get_Object(Builder, 
                                           "cellwriter_font"));
               Set_Font(font_btn, Value(R_config,3));
            elsif Value(R_Config,1) = "font_start" then
               font_start_char := 
                          wide_character'Val(Integer'Value(Value(R_config,3)));
            -- Language
            elsif Value(R_config,1) = "disable_basic_latin" then
               check_box := gtk_check_button(Get_Object(Builder, 
                                        "checkbox_setup_disable_basic_latin"));
               Set_Active(check_box, (Value(R_config,3) /= "0"));
               Samples.Set_Disable_Basic_Latin_Letters
                                            (to => (Value(R_config,3) /= "0"));
            elsif Value(R_config,1) = "enable_right_to_left" then
               check_box := gtk_check_button(Get_Object(Builder, 
                                       "checkbox_setup_enable_right_to_left"));
               Set_Active(check_box, (Value(R_config,3) /= "0"));
            -- Recognition
            elsif Value(R_config,1) = "train_on_input" then
               check_box := gtk_check_button(Get_Object(Builder, 
                                           "checkbox_setup_train_on_input"));
               Set_Active(check_box, (Value(R_config,3) /= "0"));
            elsif Value(R_config,1) = "samples_per_character" then
               spin_entry := gtk_spin_button(Get_Object(Builder, 
                                               "spin_setup_samples_per_char"));
               Set_Value(spin_entry, 
                        Glib.GDouble(Float(Integer'Value(Value(R_config,3)))));
               Samples.Set_Maximum_Samples(to=> Integer'Value(Value(R_config,3)));
            elsif Value(R_config,1) = "accuracy_margin" then
               spin_entry := gtk_spin_button(Get_Object(Builder, 
                                               "spin_setup_accuracy_margin"));
               Set_Value(spin_entry, 
                        Glib.GDouble(Float(Integer'Value(Value(R_config,3)))));
               Samples.Set_Maximum_Samples(to=> Integer'Value(Value(R_config,3)));
            elsif Value(R_config,1) = "enable_word_context" then
               check_box := gtk_check_button(Get_Object(Builder, 
                                           "checkbox_setup_enable_english_context"));
               Set_Active(check_box, (Value(R_config,3) /= "0"));
            elsif Value(R_config,1) = "ignore_stroke_direction" then
               check_box := gtk_check_button(Get_Object(Builder, 
                                           "checkbox_setup_ignore_stroke_direction"));
               Set_Active(check_box, (Value(R_config,3) /= "0"));
            elsif Value(R_config,1) = "match_diff_stroke_nos" then
               check_box := gtk_check_button(Get_Object(Builder, 
                                           "checkbox_setup_match_diff_stroke_nos"));
               Set_Active(check_box, (Value(R_config,3) /= "0"));
            elsif Value(R_config,1) = "enable_word_frequency" then
               Word_Frequency.Set_Word_Frequency_Enablement
                                            (to => (Value(R_config,3) /= "0"));
               check_box := gtk_check_button(Get_Object(Builder,
                                           "checkbox_word_frequency_enabled"));
               Set_Active(check_box, (Value(R_config,3) /= "0"));
            -- Set the current working language on the main form
            elsif Value(R_config,1) = "language" then
               combo_box:= gtk_combo_box(Get_Object(Builder,"combo_language"));
               Error_Log.Debug_Data(at_level => 7, 
                       with_details => "Load_Data_From: combo_language");
               -- (R_config,3) contains the language index.  That needs to be
               -- turned into the Combo box index.   Set_To_ID does that.
               declare
                  lingo_num : integer := 
                          Integer(Glib.Gint(integer'Value(Value(R_config,3))));
               begin
                  Set_To_ID(Builder,combo_box,"my_languages_table",lingo_num);
                  Set_Up_Combining(Builder, for_language => lingo_num);
                  lang_no := lingo_num;
               end;
            elsif Value(R_config,1) = "current_sample" then
               null;
               -- Samples.Set_Current_Sample(to => Integer'Value(Value(R_config,3)));
            elsif Value(R_config,1) = "engine_ranges" then
               Recogniser.Set_Engine_Ranges(to=>Value(from=>Value(R_config,3)));
            else
               Error_Log.Debug_Data(at_level => 6, 
                                 with_details=> "Load_Data_From: nothing for "&
                                            To_Wide_String(Value(R_config,1)));
            end if;
            Next(R_config);  -- next record(Configurations)
         end loop;
      end if;
      Error_Log.Debug_Data(at_level => 9, 
                                 with_details=> "Load_Data_From: loaded details");
      -- And set the grid up for the right number of rows and columns
      Grid_Management.Resize_Grid (to_rows => grid_rows, to_cols => grid_cols);
      Keyboard.Resize_Grid (to_rows => grid_rows, to_cols => grid_cols);
      Grid_Management.Set_Writing_Colours(for_text             => grid_FG, 
                                          for_blank_background => grid_NBG, 
                                          for_used_background  => grid_UBG);
      Grid_Management.Set_Writing_Size(width=>cell_horiz, height=>cell_vert);
      Keyboard.Load_Keyboard(for_language=> lang_no, at_object=> Builder);
   end Load_Data_From;
      
   procedure Load_Data_To(database : GNATCOLL.SQL.Exec.Database_Connection;
                          Builder : in Gtkada_Builder) is
      use GNATCOLL.SQL.Exec, Gtk.Check_Button, Gtk.Combo_Box, Gtk.Spin_Button;
      use Gtk.Font_Button, Gtk.Color_Button, Gdk.RGBA;
      use Gtk.Text_Buffer;
      use String_Conversions;
      function Get_Combo_ID(Builder : access Gtkada_Builder_Record'Class;
                            combo, 
                            liststore : Glib.UTF8_String) return integer is
         use Gtk.Combo_Box, Gtk.Tree_Selection, Gtk.List_Store, Glib, String_Conversions;
         iter     : Gtk.Tree_Model.gtk_tree_iter;
         store    : Gtk.List_Store.gtk_list_store;
         col_data : Glib.Values.GValue;
      begin
         store := gtk_list_store(Get_Object(Builder, liststore));
         if Get_Active(Gtk_Combo_Box_Record( 
                                  (Get_Object(Builder,combo).all))'Access) >= 0
         then
            iter  := Get_Active_Iter(Gtk_Combo_Box_Record( 
                                      (Get_Object(Builder,combo).all))'Access);
            Get_Value(store, iter, 0, col_data);
            return Integer(Glib.Values.Get_Int(col_data));
         else
            return -1;
         end if;
      end Get_Combo_ID;
   
      R_config   : Forward_Cursor;
      spin_entry : Gtk.Spin_Button.gtk_spin_button;
      check_box  : Gtk.Check_Button.gtk_check_button;
      text_buffer: Gtk.Text_Buffer.gtk_text_buffer;
      tb_start,
      tb_end     : Gtk.Text_Iter.Gtk_Text_Iter;
      colour_btn : Gtk.Color_Button.gtk_color_button;
      the_colour : Gdk.RGBA.Gdk_RGBA;
      grid_UBG   : Gdk.RGBA.Gdk_RGBA := White_RGBA;
      grid_NBG   : Gdk.RGBA.Gdk_RGBA := White_RGBA;
      grid_FG    : Gdk.RGBA.Gdk_RGBA := Black_RGBA;
      font_btn   : Gtk.Font_Button.gtk_font_button;
      c_cw_update: SQL_Parameters (1 .. 2);
      execute_it : boolean;
      result     : Glib.UTF8_String := "0";
      grid_rows  : natural := 4;
      grid_cols  : natural := 12;
      cell_horiz : natural := 45;
      cell_vert  : natural := 70;
      lang_no    : positive := 1;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details=> "Initialise_Setup: Start");
      R_config.Fetch (Connection => database, Stmt => CW_select);
      if Success(database) and then Has_Row(R_config) then
         while Has_Row(R_config) loop  -- while not end_of_table
            execute_it:= false;
            if Value(R_config,1) = "dimension_cells_horiz" then
               spin_entry := gtk_spin_button(Get_Object(Builder, 
                                               "setup_dimension_cells_horiz"));
               c_cw_update:= (1 => +Integer_Value(R_config,0),
                              2 => +Get_Value_As_Int(spin_entry)'Image);
               Error_Log.Debug_Data(at_level =>6, with_details=>"cells horiz="&To_Wide_String(Integer_Value(R_config,0)'Image)&":"&To_Wide_String(Get_Value_As_Int(spin_entry)'Image));
               execute_it := true;
               cell_horiz := Integer'Value(Value(R_config,3));
            elsif Value(R_config,1) = "dimension_cells_vert" then
               spin_entry := gtk_spin_button(Get_Object(Builder, 
                                               "setup_dimension_cells_vert"));
               c_cw_update:= (1 => +Integer_Value(R_config,0),
                              2 => +Get_Value_As_Int(spin_entry)'Image);
               execute_it := true;
               cell_vert  := Integer'Value(Value(R_config,3));
            elsif Value(R_config,1) = "dimension_grid_horiz" then
               spin_entry := gtk_spin_button(Get_Object(Builder, 
                                               "setup_dimension_grid_horiz"));
               c_cw_update:= (1 => +Integer_Value(R_config,0),
                              2 => +Get_Value_As_Int(spin_entry)'Image);
               grid_cols  := Integer(Get_Value_As_Int(spin_entry));
               execute_it := true;
            elsif Value(R_config,1) = "dimension_grid_vert" then
               spin_entry := gtk_spin_button(Get_Object(Builder, 
                                               "setup_dimension_grid_vert"));
               c_cw_update:= (1 => +Integer_Value(R_config,0),
                              2 => +Get_Value_As_Int(spin_entry)'Image);
               grid_rows  := Integer(Get_Value_As_Int(spin_entry));
               execute_it := true;
            elsif Value(R_config,1) = "dimensions_keyboard" then
               spin_entry := gtk_spin_button(Get_Object(Builder, 
                                               "setup_dimensions_keyboard"));
               c_cw_update:= (1 => +Integer_Value(R_config,0),
                              2 => +Get_Value_As_Int(spin_entry)'Image);
               execute_it := true;
            elsif Value(R_config,1) = "show_button_labels" then
               check_box := gtk_check_button(Get_Object(Builder, 
                                        "checkbox_window_show_button_labels"));
               if Get_Active(check_box)
               then result := "1";
               else result := "0";
               end if;
               c_cw_update:= (1 => +Integer_Value(R_config,0), 2 => +result);
               execute_it := true;
            elsif Value(R_config,1) = "show_onscreen_keyboard" then
               check_box := gtk_check_button(Get_Object(Builder, 
                                    "checkbox_window_show_onscreen_keyboard"));
               if Get_Active(check_box)
               then result := "1";
                  Error_Log.Debug_Data(at_level =>6, with_details=>"keyboard=true");
               else result := "0";
                  Error_Log.Debug_Data(at_level =>6, with_details=>"keyboard=false");
               end if;
               c_cw_update:= (1 => +Integer_Value(R_config,0), 2 => +result);
               execute_it := true;
            elsif Value(R_config,1) = "enable_extended_input_events" then
               check_box := gtk_check_button(Get_Object(Builder, 
                              "checkbox_window_enable_extended_input_events"));
               if Get_Active(check_box)
               then result := "1";
               else result := "0";
               end if;
               c_cw_update:= (1 => +Integer_Value(R_config,0), 2 => +result);
               execute_it := true;
            elsif Value(R_config,1) = "menu_left_click" then
               check_box := gtk_check_button(Get_Object(Builder, 
                                           "checkbox_status_menu_left_click"));
               if Get_Active(check_box)
               then result := "1";
               else result := "0";
               end if;
               c_cw_update:= (1 => +Integer_Value(R_config,0), 2 => +result);
               execute_it := true;
            elsif Value(R_config,1) = "window_docking" then
               c_cw_update:= (1 => +Integer_Value(R_config,0), 
                              2 => +Get_Combo_ID(Builder,
                                       combo=>"combo_setup_window_docking", 
                                       liststore=>"liststore_window_docking"));
               execute_it := true;
            elsif Value(R_config,1) = "cell_writer.css" then
               text_buffer := gtk_text_buffer(Get_Object(Builder, 
                                                "textbuffer_css"));
               if Get_Modified(text_buffer)
               then  -- set the iterators to start and end and load
                  Gtk.Text_Buffer.Get_Start_Iter(text_buffer, tb_start);
                  Get_End_Iter(text_buffer, tb_end);
                  c_cw_update:= (1 => +Integer_Value(R_config,0), 
                                 2 => +Get_Text(text_buffer,tb_start,tb_end));
                  execute_it := true;
               end if;
            -- Colours and Font
            elsif Value(R_config,1) = "used_cell_colour" then
               colour_btn := gtk_color_button(Get_Object(Builder, 
                                           "colour_used_cell"));
               Get_Rgba(colour_btn, the_colour);
               c_cw_update:= (1 => +Integer_Value(R_config,0), 
                              2 => +To_String(the_colour));
               execute_it := true;
               grid_UBG := the_colour;
            elsif Value(R_config,1) = "blank_cell_colour" then
               colour_btn := gtk_color_button(Get_Object(Builder, 
                                           "colour_blank_cell"));
               Get_Rgba(colour_btn, the_colour);
               c_cw_update:= (1 => +Integer_Value(R_config,0), 
                              2 => +To_String(the_colour));
               execute_it := true;
               grid_NBG := the_colour;
            elsif Value(R_config,1) = "highlight_colour" then
               colour_btn := gtk_color_button(Get_Object(Builder, 
                                           "colour_highlight"));
               Get_Rgba(colour_btn, the_colour);
               c_cw_update:= (1 => +Integer_Value(R_config,0), 
                              2 => +To_String(the_colour));
               execute_it := true;
               grid_FG := the_colour;
            elsif Value(R_config,1) = "text_and_ink_colour" then
               colour_btn := gtk_color_button(Get_Object(Builder, 
                                           "colour_text_and_ink"));
               Get_Rgba(colour_btn, the_colour);
               c_cw_update:= (1 => +Integer_Value(R_config,0), 
                              2 => +To_String(the_colour));
               execute_it := true;
            elsif Value(R_config,1) = "key_face_colour" then
               colour_btn := gtk_color_button(Get_Object(Builder, 
                                           "colour_key_face"));
               Get_Rgba(colour_btn, the_colour);
               c_cw_update:= (1 => +Integer_Value(R_config,0), 
                              2 => +To_String(the_colour));
               execute_it := true;
            elsif Value(R_config,1) = "key_text_colour" then
               colour_btn := gtk_color_button(Get_Object(Builder, 
                                           "colour_key_text"));
               Get_Rgba(colour_btn, the_colour);
               c_cw_update:= (1 => +Integer_Value(R_config,0), 
                              2 => +To_String(the_colour));
               execute_it := true;
            elsif Value(R_config,1) = "font" then
               font_btn := gtk_font_button(Get_Object(Builder, 
                                           "cellwriter_font"));
               c_cw_update:= (1 => +Integer_Value(R_config,0), 
                              2 => +Get_Font(font_btn));
               execute_it := true;
            -- Language
            elsif Value(R_config,1) = "disable_basic_latin" then
               check_box := gtk_check_button(Get_Object(Builder, 
                                        "checkbox_setup_disable_basic_latin"));
               if Get_Active(check_box)
               then result := "1";
               else result := "0";
               end if;
               c_cw_update:= (1 => +Integer_Value(R_config,0), 2 => +result);
               execute_it := true;
               Samples.Set_Disable_Basic_Latin_Letters(to=>(result /= "0"));
            elsif Value(R_config,1) = "enable_right_to_left" then
               check_box := gtk_check_button(Get_Object(Builder, 
                                       "checkbox_setup_enable_right_to_left"));
               if Get_Active(check_box)
               then result := "1";
               else result := "0";
               end if;
               c_cw_update:= (1 => +Integer_Value(R_config,0), 2 => +result);
               execute_it := true;
            -- Recognition
            elsif Value(R_config,1) = "train_on_input" then
               check_box := gtk_check_button(Get_Object(Builder, 
                                           "checkbox_setup_train_on_input"));
               if Get_Active(check_box)
               then result := "1";
               else result := "0";
               end if;
               c_cw_update:= (1 => +Integer_Value(R_config,0), 2 => +result);
               execute_it := true;
            elsif Value(R_config,1) = "samples_per_character" then
               spin_entry := gtk_spin_button(Get_Object(Builder, 
                                               "spin_setup_samples_per_char"));
               c_cw_update:= (1 => +Integer_Value(R_config,0),
                              2 => +Get_Value_As_Int(spin_entry)'Image);
               Samples.Set_Maximum_Samples
                                   (to=>Integer(Get_Value_As_Int(spin_entry)));
               execute_it := true;
            elsif Value(R_config,1) = "accuracy_margin" then
               spin_entry := gtk_spin_button(Get_Object(Builder, 
                                               "spin_setup_accuracy_margin"));
               c_cw_update:= (1 => +Integer_Value(R_config,0),
                              2 => +Get_Value_As_Int(spin_entry)'Image);
               execute_it := true;   
            elsif Value(R_config,1) = "enable_word_context" then
               check_box := gtk_check_button(Get_Object(Builder, 
                                     "checkbox_setup_enable_english_context"));
               if Get_Active(check_box)
               then result := "1";
               else result := "0";
               end if;
               c_cw_update:= (1 => +Integer_Value(R_config,0), 2 => +result);
               execute_it := true;
            elsif Value(R_config,1) = "ignore_stroke_direction" then
               check_box := gtk_check_button(Get_Object(Builder, 
                                    "checkbox_setup_ignore_stroke_direction"));
               if Get_Active(check_box)
               then result := "1";
               else result := "0";
               end if;
               c_cw_update:= (1 => +Integer_Value(R_config,0), 2 => +result);
               execute_it := true;
            elsif Value(R_config,1) = "match_diff_stroke_nos" then
               check_box := gtk_check_button(Get_Object(Builder, 
                                      "checkbox_setup_match_diff_stroke_nos"));
               if Get_Active(check_box)
               then result := "1";
               else result := "0";
               end if;
               c_cw_update:= (1 => +Integer_Value(R_config,0), 2 => +result);
               execute_it := true;
            elsif Value(R_config,1) = "enable_word_frequency" then
               check_box := gtk_check_button(Get_Object(Builder, 
                                      "checkbox_word_frequency_enabled"));
               if Get_Active(check_box)
               then 
                  result := "1";
                  Word_Frequency.Set_Word_Frequency_Enablement (to => true);
               else 
                  result := "0";
                  Word_Frequency.Set_Word_Frequency_Enablement (to => false);
               end if;
               c_cw_update:= (1 => +Integer_Value(R_config,0), 2 => +result);
               execute_it := true;
            -- Get the current working language from the main form
            elsif Value(R_config,1) = "language" then
               declare
                  combo_id : integer := Get_Combo_ID(Builder,
                                              combo=>"combo_language", 
                                              liststore=>"my_languages_table");
                  combo_box  : Gtk.Combo_Box.gtk_combo_box;
               begin
                  if combo_id > 0 then
                     c_cw_update:= (1=>+Integer_Value(R_config,0), 
                                    2=>+combo_id);
                     Set_Up_Combining(Builder, for_language => combo_id);
                     lang_no := combo_id;
                  else -- set to -1 == error situation because it wasn't active
                     Error_Log.Debug_Data(at_level    =>6, with_details=>
                                       "Load_Data_To: Language indeterminate");
                     Set_Up_Combining(Builder, for_language => 1); -- default=1
                     combo_box:= gtk_combo_box(Get_Object(Builder,
                                                          "combo_language"));
                     Set_To_ID(Builder, combo_box, "my_languages_table", 1);
                  end if;
               end;
            elsif Value(R_config,1) = "current_sample" then
               -- c_cw_update:= (1 => +Integer_Value(R_config,0),
                  --             2 => +Samples.The_Current_Sample_Number'Image);
               -- execute_it := true;
               null;
            elsif Value(R_config,1) = "engine_ranges" then
               c_cw_update:=(1 =>+Integer_Value(R_config,0),
                             2 =>+Value(of_string=>Recogniser.The_Engine_Ranges));
               execute_it := true;
            else
               Error_Log.Debug_Data(at_level    =>6, 
                                    with_details=>"Load_Data_To: nothing for "&
                                            To_Wide_String(Value(R_config,1)));
            end if;
            if execute_it then
               Execute (Connection=>cDB, Stmt=>CW_update, Params=>c_cw_update);
               Commit_Or_Rollback (cDB);
            end if;
            Next(R_config);  -- next record(Configurations)
         end loop;
         -- And set the grid up for the right number of rows and columns
         Grid_Management.Resize_Grid(to_rows=> grid_rows, to_cols=> grid_cols);
         Grid_Management.Set_Writing_Colours(for_text             => grid_FG, 
                                             for_blank_background => grid_NBG, 
                                             for_used_background  => grid_UBG);
         Grid_Management.Set_Writing_Size(width=>cell_horiz, height=>cell_vert);
         Keyboard.Load_Keyboard(for_language => lang_no, at_object => Builder);
      end if;
   end Load_Data_To;

   procedure Show_Setup(Builder : in Gtkada_Builder) is
   begin
      Gtk.Widget.Show_All(Gtk.Widget.Gtk_Widget 
                        (Gtkada.Builder.Get_Object(Builder,"dialogue_setup")));
   end Show_Setup;

   procedure Setup_Cancel_CB (Object : access Gtkada_Builder_Record'Class) is
      use GNATCOLL.SQL.Exec;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Setup_Close_CB: Start");
      -- Undo any language selections
      if language_list_changed = changed then
         Rollback(cDB);
         language_list_changed := unchanged;
      end if;
      -- reset the data
      Load_Data_From(database => cDB, Builder => Gtkada_Builder(Object));
      -- and hide ourselves
      Gtk.Widget.Hide(Gtk.Widget.Gtk_Widget 
         (Gtkada.Builder.Get_Object(Gtkada_Builder(Object),"dialogue_setup")));
   end Setup_Cancel_CB;
        
   procedure Setup_Close_CB (Object : access Gtkada_Builder_Record'Class) is
      use GNATCOLL.SQL.Exec;
      use Gtk.Tree_Selection, Gtk.List_Store, Gtk.Combo_Box;
      R_lingo    : Forward_Cursor;
      my_lingo   : Gtk.List_Store.gtk_list_store;
      my_iter    : Gtk.Tree_Model.gtk_tree_iter;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Setup_Close_CB: Start");
      -- Save any language selections
      if language_list_changed = changed then
         Commit(cDB);
         -- Update the language list
         R_lingo.Fetch (Connection => cDB, Stmt => lingo_list_sel);
         if Success(cDB) and then Has_Row(R_lingo) then
            my_lingo := gtk_list_store(
                              Gtkada.Builder.Get_Object(Gtkada_Builder(Object),
                                       "my_languages_table"));
            Clear(my_lingo);  -- empty the sub-table ready for the new data
            while Has_Row(R_lingo) loop  -- while not end_of_table
               Append(my_lingo, my_iter);  -- load to combo box lingo list
               Set(my_lingo,my_iter,0,Glib.Gint(Integer_Value(R_lingo,0)));
               Set(my_lingo,my_iter,1,Glib.UTF8_String(Value(R_lingo,1)));
               Set(my_lingo,my_iter,2,Glib.Gint(Integer_Value(R_lingo,4)));
               Set(my_lingo,my_iter,3,Glib.Gint(Integer_Value(R_lingo,5)));
               Next(R_lingo);  -- next record(Configurations)
            end loop;
         end if;
         language_list_changed := unchanged;
      end if;
      -- save the data
      Load_Data_To(database => cDB, Builder => Gtkada_Builder(Object));
      -- and hide ourselves
      Gtk.Widget.Hide(Gtk.Widget.Gtk_Widget 
         (Gtkada.Builder.Get_Object(Gtkada_Builder(Object),"dialogue_setup")));
   end Setup_Close_CB;

   function Setup_Hide_On_Delete
           (Object : access Glib.Object.GObject_Record'Class) return Boolean is
      use Gtk.Widget, Glib.Object;
      use GNATCOLL.SQL.Exec;
      result : boolean;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Setup_Hide_On_Delete: Start");
      result := Gtk.Widget.Hide_On_Delete(Gtk_Widget_Record(Object.all)'Access);
      -- Gtk.Widget.Hide(Gtk.Widget.Gtk_Widget 
         --             (Gtkada.Builder.Get_Object(Gtkada_Builder(Object),"dialogue_setup")));
      return result;
      -- return Gtk.Widget.Hide_On_Delete(Gtk_Widget_Record( 
         --               (Gtkada.Builder.Get_Object(Gtkada_Builder(Object),"dialogue_setup").all))'Access);
   end Setup_Hide_On_Delete;
   
   procedure Setup_Language_Selected
                            (Object : access Gtkada_Builder_Record'Class) is
      use Gtkada.Builder, Gtk.Tree_View, Gtk.Tree_Selection, Gtk.List_Store;
      use Gtk.Tree_Model, Gtk.Tree_Row_Reference;
      use Gtk.Cell_Renderer_Toggle, String_Conversions;
      use GNATCOLL.SQL.Exec, Glib;
      model    : Gtk.Tree_Model.Gtk_Tree_Model;
      iter     : Gtk.Tree_Model.gtk_tree_iter;
      store    : Gtk.List_Store.gtk_list_store;
      lingo_sel: Gtk.Tree_Selection.gtk_tree_selection;
      col_data : Glib.Values.GValue;
      row_num  : integer;
      selected : boolean;
      result   : boolean;
      lang_param: SQL_Parameters (1 .. 2);
      lingo_parm: SQL_Parameters (1 .. 1);
      R_lingo   : Forward_Cursor;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Setup_Language_Selected: Start");
      -- Get the hook into the currently selected record
      lingo_sel:= Get_Selection(Gtk_Tree_View_Record( 
                      (Get_Object(Object,"languages_tree_view").all))'Access);
      store := gtk_list_store(Get_Object(Object,"the_languages_table"));
      Get_Selected(lingo_sel, model, iter);
      -- toggle the selected value
      Get_Value(store, iter, 0, col_data);
      row_num  := Integer(Glib.Values.Get_Int(col_data));
      Get_Value(store, iter, 1, col_data);
      Get_Value(store, iter, 2, col_data);
      lingo_parm := (1 => +row_num);
      selected := not Glib.Values.Get_Boolean(col_data); -- convert and toggle
      R_lingo.Fetch (Connection => cDB, Stmt => lingo_sel_item, 
                     Params => lingo_parm); 
      if Success(cDB) and then Has_Row(R_lingo) then
         selected := not (Integer_Value(R_lingo,3) /= 0);
      end if;
      Set(store,iter,2, selected);  -- set to the toggled value
      -- save the toggled state to the database
      lang_param := (1 => +row_num,
                     2 => +selected);
      if language_list_changed = unchanged then
         result := Start_Transaction(cDB);
         language_list_changed := changed;
      end if;
      Error_Log.Debug_Data(at_level => 7, 
                           with_details=> "Setup_Language_Selected: Updating "&
                                          To_Wide_String(row_num'Image)&" to "&
                                          To_Wide_String(selected'Image)&".");
      Execute (Connection=>cDB, Stmt=>lang_update, Params=>lang_param);
   end Setup_Language_Selected;

   procedure Setup_Show_Help (Object : access Gtkada_Builder_Record'Class) is
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Setup_Show_Help: Start");
      -- Firstly hide ourselves
      Gtk.Widget.Hide(Gtk.Widget.Gtk_Widget 
         (Gtkada.Builder.Get_Object(Gtkada_Builder(Object),"dialogue_setup")));
      -- Secondly, show the Help dialogue box
      Help_About.Show_Help_About(Gtkada_Builder(Object));
   end Setup_Show_Help;
  
   procedure Combo_Language_Changed(Object:access Gtkada_Builder_Record'Class;
                                    to_language : out positive)
     -- Save the selected language to the database and return the selected
     -- language number.
   is
      use GNATCOLL.SQL.Exec, Gtkada.Builder, Gtk.Combo_Box;
      use Gtk.Tree_Selection, Gtk.List_Store, Glib, String_Conversions;
      language   : Gtk.Combo_Box.gtk_combo_box;
      conf_update: SQL_Parameters (1 .. 2);
      iter       : Gtk.Tree_Model.gtk_tree_iter;
      store      : Gtk.List_Store.gtk_list_store;
      col_data   : Glib.Values.GValue;
      R_config   : Forward_Cursor;
   begin
      Error_Log.Debug_Data(at_level => 6, 
                           with_details => "Combo_Language_Changed: Start");
      to_language := 1;  -- default in case below tests fail
      language := gtk_combo_box(Get_Object(Gtkada_Builder(Object),
                                           "combo_language"));
      store := gtk_list_store(Get_Object(Gtkada_Builder(Object),
                                           "my_languages_table"));
      if Get_Active(language) >= 0 then
         iter := Get_Active_Iter(language);
         Get_Value(store, iter, 0, col_data);
         -- Get the record ID in the Configurations table that the
         -- selected language is stored in.
         R_config.Fetch (Connection => cDB, Stmt => lang_select);
         if Success(cDB) and then Has_Row(R_config) then
            Error_Log.Debug_Data(at_level => 7, 
                         with_details=> "Combo_Language_Changed: Updating to "&
                           To_Wide_String(Glib.Values.Get_Int(col_data)'Image)&
                           " for parameter no. " &
                           To_Wide_String(Integer_Value(R_config,0)'Image));
            -- Parameters are the Configurations table Record ID and the
            -- Language number (stored in the list store for the selected
            -- language).
            conf_update:= (1 => +Integer_Value(R_config,0), 
                           2 => +(Glib.Values.Get_Int(col_data)'Image));
            Execute (Connection=>cDB, Stmt=>CW_update, Params=>conf_update);
            Commit_Or_Rollback (cDB);
            to_language := integer(Glib.Values.Get_Int(col_data));
         end if;
      end if;
   end Combo_Language_Changed;

   procedure Set_Up_Combining(Object:access Gtkada_Builder_Record'Class;
                              for_language : in positive) is
     -- Display the top row of combining character buttons, assuming 
     -- the selected language  is set up for such buttons.  These buttons
     -- are used to apply an accent type (i.e. on the top of the character)
     -- combining characters to the character/word currently written.
     -- for_language is the language ID in the list of languages.
      use GNATCOLL.SQL.Exec, Gtkada.Builder;
      use Gtk.Label, Gtk.Button, Gtk.Tool_Button;
      use Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
      -- use Gtk.Box, Gtk.Grid;
      function ToString(int : in natural) return string is
         num : natural := int;
         result : string(1..5) := "     ";
         len    : natural := 0;
      begin
         if num = 0
         then
            return "0";
         else
            while num > 0 loop
               len := len + 1;
               result(5-len+1):=character'Val(character'Pos('0') + num rem 10);
               num := (num - (num rem 10)) / 10;
            end loop;
            return result((5-len+1)..5);
         end if;
      end ToString;
      R_combine  : Forward_Cursor;
      lingo_parm : SQL_Parameters (1 .. 1);
      combine_btn: gtk.Button.Gtk_Button;
      combine_lbl: gtk.Label.Gtk_Label;
      combine_chr: wide_string(1..1);
      special_btn: Gtk.Tool_Button.gtk_tool_button;
      special_c_display : text := To_Text("' '");
      special_c_tooltip : text := To_Text("No-break Space");
      the_font   : Pango.Font.Pango_Font_Description :=
                                                    Setup.The_Font_Description;
   begin
      Error_Log.Debug_Data(at_level => 6, 
                           with_details => "Set_Up_Combining: Start (" &
                String_Conversions.To_Wide_String(ToString(for_language))&")");
      Error_Log.Debug_Data(at_level => 7, 
                              with_details=>"Set_Up_Combining: Hide buttons.");
      -- Hide the buttons to start with
      for button_number in 1..10 loop
         combine_btn := gtk_button(Get_Object(Gtkada_Builder(Object),
                                      "btn_combine_"&ToString(button_number)));
         if combine_btn /= null then
            Hide(combine_btn);
         else
            Error_Log.Debug_Data(at_level => 6, 
                                 with_details=>"Set_Up_Combining: no handle.");
         end if;
      end loop;
      special_btn:= Gtk_Tool_Button(Get_Object(Gtkada_Builder(Object),
                                               "btn_sep"));
      if special_btn /= null then
         Hide(special_btn);
      else
         Error_Log.Debug_Data(at_level => 6, 
                              with_details=>"Set_Up_Combining: no handle.");
      end if;
      -- Work out if buttons should be displayed by querying database
      lingo_parm := (1 => +for_language);
      R_combine.Fetch (Connection => cDB, Stmt => combine_select,
                       Params => lingo_parm);
      if Success(cDB) and then Has_Row(R_combine) then
         Error_Log.Debug_Data(at_level => 7, 
                              with_details=>"Set_Up_Combining: Setting up...");
         -- Load the characters to each button
         while Has_Row(R_combine) loop  -- while not end_of_table
            if Integer_Value(R_combine,1) = 0
            then  -- First one is the special button - assign and show it
               special_character := Wide_Element(
                  Value_From_Wide(Decode(UTF_8_String(Value(R_combine,2)),UTF_8)),1);
               special_btn:= Gtk_Tool_Button(Get_Object(Gtkada_Builder(Object),
                                                        "btn_sep"));
               Set_Label(special_btn, Value(R_combine,4));
               Set_Tooltip_Markup(special_btn, Value(R_combine,4));
               Show(special_btn);  -- show the button
            elsif Integer_Value(R_combine,1) > 10
            then  -- out of range of our buttons
               null;   -- ignore as no where to put them
            else  -- Ordinary combining button - label, tool tip and show
               combine_lbl := gtk_label(Get_Object(Gtkada_Builder(Object),
                                     "btn_combine_label_" & 
                                     ToString(Integer_Value(R_combine,1))));
               combine_btn := gtk_button(Get_Object(Gtkada_Builder(Object),
                                      "btn_combine_" & 
                                      ToString(Integer_Value(R_combine,1))));
               -- while we are here, set up the button font
               Modify_Font(combine_btn, the_font);
               Set_Label(combine_lbl, Value(R_combine,4));
               -- set up the tool-tip, coding in the tip and the macro number
               combine_chr(1) := Wide_Element(Value_From_Wide(
                            Decode(UTF_8_String(Value(R_combine,2)),UTF_8)),1);
               Set_Tooltip_Markup(combine_btn, Value(R_combine,3) & " [ " &
                                   Encode(combine_chr) & "] (" & 
                                   ToString(Integer_Value(R_combine,5)) & ')');
               Show(combine_btn);  -- show the button
            end if;
            Next(R_combine);  -- next record(Configurations)
         end loop;
      else
         -- Queue_Resize(gtk_grid(Get_Object(Object, "grid_cells")));
         -- Queue_Resize(gtk_window(Get_Object(Object, "form_main")));
         null;
      end if;
   end Set_Up_Combining;
  
   function The_Font return UTF8_string is
      -- The currently selected font for the system
      use Gtk.Font_Button;
      font_btn   : Gtk.Font_Button.gtk_font_button;
   begin
      font_btn := gtk_font_button(Get_Object(the_builder, "cellwriter_font"));
      return Get_Font(font_btn);
   end The_Font;
  
   function The_Font_Name return UTF8_string is
      -- The currently selected font for the system
      use Gtk.Font_Button, Pango.Font;
      font_btn   : Gtk.Font_Button.gtk_font_button;
   begin
      font_btn := gtk_font_button(Get_Object(the_builder, "cellwriter_font"));
      return Get_Family(Get_Font_Desc(font_btn));
   end The_Font_Name;
   
   function Font_Size return gDouble is
      -- The currently selected font size for the system.
      use Gtk.Font_Button;
      font_btn   : Gtk.Font_Button.gtk_font_button;
   begin
      font_btn := gtk_font_button(Get_Object(the_builder, "cellwriter_font"));
      return gDouble(Get_Font_Size(font_btn));
   end Font_Size;
   
   function The_Font_Description return Pango.Font.Pango_Font_Description is
      -- The currently selected font in Pango font description format
      use Gtk.Font_Button, Pango.Font;
      font_btn   : Gtk.Font_Button.gtk_font_button;
   begin
      font_btn := gtk_font_button(Get_Object(the_builder, "cellwriter_font"));
      return Get_Font_Desc(font_btn);
   end The_Font_Description;
   
   function Font_Start_Character return wide_character is
      -- The character to start switching from the default font to the
      -- specified font.
   begin
      return font_start_char;
   end Font_Start_Character;

   function Button_Colour return Gdk.RGBA.Gdk_RGBA
   is
      -- The currently selected keyboard button colour for the system
      use Gtk.Color_Button, Gdk.RGBA;
      colour_btn : Gtk.Color_Button.gtk_color_button;
      the_colour : Gdk.RGBA.Gdk_RGBA;
   begin
      colour_btn:= gtk_color_button(Get_Object(the_builder,"colour_key_face"));
      Get_Rgba(colour_btn, the_colour);
      return the_colour;
   end Button_Colour;

   function Used_Cell_Colour return Gdk.RGBA.Gdk_RGBA is
      -- The currently selected used cell colour for the system
      use Gtk.Color_Button, Gdk.RGBA;
      colour_btn : Gtk.Color_Button.gtk_color_button;
      the_colour : Gdk.RGBA.Gdk_RGBA;
   begin
      colour_btn:=gtk_color_button(Get_Object(the_builder,"colour_used_cell"));
      Get_Rgba(colour_btn, the_colour);
      return the_colour;
   end Used_Cell_Colour;
   
   function Untouched_Cell_Colour return Gdk.RGBA.Gdk_RGBA is
      -- The currently selected untouched cell background colour for the system
      use Gtk.Color_Button, Gdk.RGBA;
      colour_btn : Gtk.Color_Button.gtk_color_button;
      the_colour : Gdk.RGBA.Gdk_RGBA;
   begin
      colour_btn := gtk_color_button(Get_Object(the_builder,
                                                "colour_blank_cell"));
      Get_Rgba(colour_btn, the_colour);
      return the_colour;
   end Untouched_Cell_Colour;
    
   function Highlight_Colour return Gdk.RGBA.Gdk_RGBA is
      -- The currently selected highlight colour for the system
      use Gtk.Color_Button, Gdk.RGBA;
      colour_btn : Gtk.Color_Button.gtk_color_button;
      the_colour : Gdk.RGBA.Gdk_RGBA;
   begin
      colour_btn:=gtk_color_button(Get_Object(the_builder,"colour_highlight"));
      Get_Rgba(colour_btn, the_colour);
      return the_colour;
   end Highlight_Colour;

   function Text_Colour return Gdk.RGBA.Gdk_RGBA is
      -- The currently selected background colour for the system
      use Gtk.Color_Button, Gdk.RGBA;
      colour_btn : Gtk.Color_Button.gtk_color_button;
      the_colour : Gdk.RGBA.Gdk_RGBA;
   begin
      colour_btn:= gtk_color_button(Get_Object(the_builder,
                                               "colour_text_and_ink"));
      Get_Rgba(colour_btn, the_colour);
      return the_colour;
   end Text_Colour;

   function Button_Text_Colour return Gdk.RGBA.Gdk_RGBA is
      -- The currently selected background colour for the system
      use Gtk.Color_Button, Gdk.RGBA;
      colour_btn : Gtk.Color_Button.gtk_color_button;
      the_colour : Gdk.RGBA.Gdk_RGBA;
   begin
      colour_btn:= gtk_color_button(Get_Object(the_builder,"colour_key_text"));
      Get_Rgba(colour_btn, the_colour);
      return the_colour;
   end Button_Text_Colour;

   function Grid_Cell_Columns return natural is
      use Gtk.Spin_Button;
      spin_entry : Gtk.Spin_Button.gtk_spin_button;
   begin
      spin_entry := gtk_spin_button(Get_Object(the_builder, 
                                               "setup_dimension_grid_horiz"));
      return Integer(Get_Value_As_Int(spin_entry));
   end Grid_Cell_Columns;
      
   function Grid_Cell_Rows return natural is
      use Gtk.Spin_Button;
      spin_entry : Gtk.Spin_Button.gtk_spin_button;
   begin
      spin_entry := gtk_spin_button(Get_Object(the_builder, 
                                               "setup_dimension_grid_vert"));
      return Integer(Get_Value_As_Int(spin_entry));
   end Grid_Cell_Rows;

   function Cell_Height return natural is
      -- The height of each cell in the grid (to the nearest whole number)
      use Gtk.Spin_Button;
      spin_entry : Gtk.Spin_Button.gtk_spin_button;
   begin
      spin_entry := gtk_spin_button(Get_Object(the_builder, 
                                               "setup_dimension_cells_vert"));
      return Integer(Get_Value_As_Int(spin_entry));
   end Cell_Height;
      
   function Cell_Width return natural is
      -- The width of  each cell in the grid (to the nearest whole number)
      use Gtk.Spin_Button;
      spin_entry : Gtk.Spin_Button.gtk_spin_button;
   begin
      spin_entry := gtk_spin_button(Get_Object(the_builder, 
                                               "setup_dimension_cells_horiz"));
      return Integer(Get_Value_As_Int(spin_entry));
   end Cell_Width;
   
   function Is_Right_to_Left return boolean is
      -- Return true if the right to left check box is checked.
      use Gtk.Check_Button;
      check_box  : Gtk.Check_Button.gtk_check_button;
   begin
      check_box := gtk_check_button(Get_Object(the_builder, 
                                       "checkbox_setup_enable_right_to_left"));
      return Get_Active(check_box);
   end Is_Right_to_Left;
   
   function Match_Differing_Stroke_Numbers return boolean is
      -- Return true if the requirement to match differing stroke numbers (when
      -- recognising a test sample) check box is checked.
      use Gtk.Check_Button;
      check_box  : Gtk.Check_Button.gtk_check_button;
   begin
      check_box := gtk_check_button(Get_Object(the_builder, 
                                      "checkbox_setup_match_diff_stroke_nos"));
      return Get_Active(check_box);
   end Match_Differing_Stroke_Numbers;
   
   function Ignore_Stroke_Direction return boolean is
      -- Return true if the ignore stroke direction (when recognising a test
      -- sample) check box is checked.
      use Gtk.Check_Button;
      check_box  : Gtk.Check_Button.gtk_check_button;
   begin
      check_box := gtk_check_button(Get_Object(the_builder, 
                                    "checkbox_setup_ignore_stroke_direction"));
      return Get_Active(check_box);
   end Ignore_Stroke_Direction;
   
   function Max_Samples_Per_Character return natural is
      -- Return the user's preference of the maximum number of samples that
      -- should be recorded for training for each character or word that is
      -- trained up.
      use Gtk.Spin_Button;
      spin_entry : Gtk.Spin_Button.gtk_spin_button;
   begin
      spin_entry := gtk_spin_button(Get_Object(the_builder, 
                                    "spin_setup_samples_per_char"));
      return Integer(Get_Value_As_Int(spin_entry));
   end Max_Samples_Per_Character;

   function Recognition_Accuracy_Margin return sample_rating is
      -- Return the user's preference for the accuracy margin (that is, the
      -- allowed rating gap before a cell's recognised content is highlighted
      -- after recognition.  Such a highlight indicates to the user that they
      -- could right mouse click to show a pop-up list of alternative samples
      -- that could be what the user really meant when they drew their
      -- character or word.
      use Gtk.Spin_Button;
      spin_entry : Gtk.Spin_Button.gtk_spin_button;
   begin
      spin_entry := gtk_spin_button(Get_Object(the_builder, 
                                    "spin_setup_accuracy_margin"));
      return sample_rating(Get_Value(spin_entry)/100.0);
   end Recognition_Accuracy_Margin;
   
   function The_Special_Button return wide_character is
      -- The special character that is emitted when the special button is
      -- pressed on the main form.
   begin
      return special_character;
   end The_Special_Button;
  
begin
   Cell_Writer_Version.Register(revision => "$Revision: v1.0.0$",
                                for_module => "Setup");
end Setup;
