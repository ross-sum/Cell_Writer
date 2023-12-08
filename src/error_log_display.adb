 -----------------------------------------------------------------------
--                                                                   --
--                 E R R O R   L O G   D I S P L A Y                 --
--                                                                   --
--                              B o d y                              --
--                                                                   --
--                           $Revision: 1.0 $                        --
--                                                                   --
--  Copyright (C) 2023  Hyper Quantum Pty Ltd.                       --
--  Written by Ross Summerfield.                                     --
--                                                                   --
--  This  package  displays  the  error  log  dialogue  box,  which  --
--  contains details about an error that has been raised.            --
--  It  is linked in with the Error_Log package and  just  displays  --
--  errors.  It does not display debug messages.                     --
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
-- with Glib.Object, Gtk.Widget, Gdk.Event;
-- with Gtkada.Builder;  use Gtkada.Builder;
with Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
with Gtk.Window;
with Gtk.Label;
with Error_Log;
with Cell_Writer_Version;
package body Error_Log_Display is

   the_builder : Gtkada.Builder.Gtkada_Builder;

   procedure Initialise_Error_Log_Display(Builder : in out Gtkada_Builder) is
      use Gtk.Window;
      error_log_display : gtk_window; -- Gtk_Message_Dialog;
   begin
      the_builder := Builder;
      -- Initialise: get the pointer to the Error Log dialogue box window
      error_log_display := Gtk_Window
                                (Builder.Get_Object("dialogue_error_message"));
      -- The objective of the following command and the handlers below is to
      -- just hide the dialogue box when the Close button is clicked, rather
      -- than to do the default of destroying the dialogue box.  That way, we
      -- can reuse it for other errors after the first error.
      -- Set close form operation to hide on delete
      error_log_display.On_Delete_Event(On_Delete_Request'Access);
      -- Set up the call-back for errors popping out of Error_Log
      Error_Log.Set_Error_Display_Call_Back(to => Display_Error'Access);
      Error_Log.Set_Error_Message_Terminator
                      (to => "Please see your system administrator or email " &
                             "the log to the developer along with an " &
                             "explanation of what you were doing just before " &
                             "the error");
      -- set up: Register the handlers
      Register_Handler(Builder      => Builder,
                       Handler_Name => "dialogue_error_message_close_cb",
                       Handler      => Error_Log_Display_Close_CB'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "dialogue_error_delete_event_cb",
                       Handler      => Error_Log_Hide_On_Delete'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "dialogue_error_destroy_cb",
                       Handler      => Error_Log_Display_Close_CB'Access);
   end Initialise_Error_Log_Display;
   
   procedure Initialise_Error_Terminator(to : in wide_string) is
      -- Set the terminator message to that specified.  This message is a
      -- general message that tells the user what to do about the error.
   begin
      Error_Log.Set_Error_Message_Terminator(to);
   end Initialise_Error_Terminator;

   procedure Display_Error (with_message : wide_string) is
      -- This is the call-back that the Error_Log package calls when an
      -- error is recorded.
      use Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
      use Gtk.Window, Gtk.Label;
      error_log_display : gtk_label;
      error_log_window  : gtk_window;
   begin
      error_log_display := 
         Gtk_Label(Get_Object(the_builder, "label_error_log_display_message"));
      error_log_window  := 
                 Gtk_Window(Get_Object(the_builder, "dialogue_error_message"));
      -- Load the error message
      Set_Markup (error_log_display, Encode(with_message));
      -- Display the dialogue box
      Gtk.Widget.Show_All(Gtk.Widget.Gtk_Widget(error_log_window));
      null;
   end Display_Error;

   procedure Error_Log_Display_Close_CB 
                             (Object : access Gtkada_Builder_Record'Class) is
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Error_Log_Display_Close_CB: Start");
      Gtk.Widget.Hide(Gtk.Widget.Gtk_Widget 
                        (Gtkada.Builder.Get_Object(Gtkada_Builder(Object),
                                                   "dialogue_error_message")));
   end Error_Log_Display_Close_CB;
   
   function Error_Log_Hide_On_Delete
           (Object : access Glib.Object.GObject_Record'Class) return Boolean is
      use Gtk.Widget, Glib.Object;
      result : boolean;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Error_Log_Hide_On_Delete: Start");
      result := Gtk.Widget.Hide_On_Delete(Gtk_Widget_Record(Object.all)'Access);
      return result;
   end Error_Log_Hide_On_Delete;
   
   function On_Delete_Request(Object : access Gtk_Widget_Record'Class;
                              Event  : Gdk_Event) return boolean is
   begin
      return Gtk.Widget.Hide_on_Delete(Object);
   end On_Delete_Request;

begin
   Cell_Writer_Version.Register(revision => "$Revision: v1.0.0$",
                                for_module => "Error_Log_Display");
end Error_Log_Display;
