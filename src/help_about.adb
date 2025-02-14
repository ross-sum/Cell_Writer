-----------------------------------------------------------------------
--                                                                   --
--                        H E L P   A B O U T                        --
--                                                                   --
--                              B o d y                              --
--                                                                   --
--                           $Revision: 1.0 $                        --
--                                                                   --
--  Copyright (C) 2020  Hyper Quantum Pty Ltd.                       --
--  Written by Ross Summerfield.                                     --
--                                                                   --
--  This  package  displays  the help  about  dialogue  box,  which  --
--  contains  details about the application,  specifically  general  --
--  details,  revision details and usage information (i.e.  how  to  --
--  launch cell_writer).                                           --
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
-- with Glib.Object, Gtk.Widget, Gdk.Event;
with Gtk.Window;
with Error_Log;
with Cell_Writer_Version;
with Gtk.Label;
with String_Conversions;
-- with dStrings; use dStrings;
package body Help_About is


   procedure Initialise_Help_About(Builder : in out Gtkada_Builder;
                                   usage : in text) is
      use Gtk.Window, Gtk.Label, String_Conversions;
      the_revision : gtk_label;
      the_version  : constant string:= "Revision " & 
                                       To_String(Cell_Writer_Version.Version);
      revision_list: gtk_label;
      usage_dets   : gtk_label;
      help_about   : gtk_window;
   begin
      -- Initialise: hide the close button in the top right hand corner
      help_about := Gtk_Window(Builder.Get_Object("dialogue_about"));
      -- Set_Deletable(help_about, false);
      -- set close form operation to hide on delete
      help_about.On_Delete_Event(On_Delete_Request'Access);
      -- Gtk.Window.
         -- On_Delete_Event(Gtk_Window(Builder.Get_Object("dialogue_about")),
         --                 Gtk.Window.Hide_On_Delete'access, 
         --                 After => false);
      -- set up: load the Version into label_revision.Label and
      --         label_revision1.Label
      Error_Log.Debug_Data(at_level => 6, 
                           with_details=>"Initialise_Help_About: version = " &
                                         To_Wide_String(the_version));
      the_revision := Gtk_Label(Builder.Get_Object("label_revision"));
      the_revision.Set_Label(the_version);
      the_revision := Gtk_Label(Builder.Get_Object("label_revision1"));
      the_revision.Set_Label(the_version);
      -- set up: load the versions of the packages into label_versions.Label
      --         from Urine_Record_Version.Revision_List (wide_string)
      revision_list := Gtk_Label(Builder.Get_Object("label_versions"));
      revision_list.Set_Label(To_String(Cell_Writer_Version.Revision_List));
      -- set up: load the Usage details into label_usage.Label
      usage_dets := Gtk_Label(Builder.Get_Object("label_usage"));
      usage_dets.Set_Label(Value(of_string => usage));
      -- set up: Register the handlers
      Register_Handler(Builder      => Builder,
                       Handler_Name => "button_close_about_clicked_cb",
                       Handler      => Help_About_Close_CB'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "dialogue_about_delete_event_cb",
                       Handler      => Help_Hide_On_Delete'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "dialogue_about_destroy_cb",
                       Handler      => Help_About_Close_CB'Access);
                       
   end Initialise_Help_About;

   procedure Show_Help_About(Builder : in Gtkada_Builder) is
   begin
      Gtk.Widget.Show_All(Gtk.Widget.Gtk_Widget 
                        (Gtkada.Builder.Get_Object(Builder,"dialogue_about")));
   end Show_Help_about;
  
   procedure Help_About_Close_CB 
                (Object : access Gtkada_Builder_Record'Class) is
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Help_About_Close_CB: Start");
      Gtk.Widget.Hide(Gtk.Widget.Gtk_Widget 
                        (Gtkada.Builder.Get_Object(Gtkada_Builder(Object),"dialogue_about")));
   end Help_About_Close_CB;

   function Help_Hide_On_Delete
      (Object : access Glib.Object.GObject_Record'Class) return Boolean is
      use Gtk.Widget, Glib.Object;
      result : boolean;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Help_Hide_On_Delete: Start");
      result := Gtk.Widget.Hide_On_Delete(Gtk_Widget_Record(Object.all)'Access);
      -- Gtk.Widget.Hide(Gtk.Widget.Gtk_Widget 
         --             (Gtkada.Builder.Get_Object(Gtkada_Builder(Object),"dialogue_about")));
      return result;
      -- return Gtk.Widget.Hide_On_Delete(Gtk_Widget_Record( 
         --               (Gtkada.Builder.Get_Object(Gtkada_Builder(Object),"dialogue_about").all))'Access);
   end Help_Hide_On_Delete;
   
   function On_Delete_Request(Object : access Gtk_Widget_Record'Class;
                                 Event  : Gdk_Event) return boolean is
   begin
      return Gtk.Widget.Hide_on_Delete(Object);
   end On_Delete_Request;
  
begin
   Cell_Writer_Version.Register(revision => "$Revision: v1.0.0$",
                                for_module => "Help_About");
end Help_About;