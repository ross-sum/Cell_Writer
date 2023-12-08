-----------------------------------------------------------------------
--                                                                   --
--                 E R R O R   L O G   D I S P L A Y                 --
--                                                                   --
--                     S p e c i f i c a t i o n                     --
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
with Glib.Object, Gtk.Widget, Gdk.Event;
with Gtkada.Builder;  use Gtkada.Builder;
package Error_Log_Display is

   procedure Initialise_Error_Log_Display(Builder : in out Gtkada_Builder);
      -- Set up the error log dialogue box so that it behaves properly and
      -- also set up the call-back with the Error_Log package to utilise
      -- this dialogue box to display errors.
   
   procedure Initialise_Error_Terminator(to : in wide_string);
      -- Set the terminator message to that specified.  This message is a
      -- general message that tells the user what to do about the error.
   
   procedure Display_Error (with_message : wide_string);
      -- This is the call-back that the Error_Log package calls when an
      -- error is recorded.

private
   use Gtk.Widget, Gdk.Event;

    -- Call-backs for closing or managing correctly the closing of the Error
    -- Log Display dialogue box
   procedure Error_Log_Display_Close_CB 
                             (Object : access Gtkada_Builder_Record'Class);
   function Error_Log_Hide_On_Delete
             (Object : access Glib.Object.GObject_Record'Class) return Boolean;
   function On_Delete_Request(Object : access Gtk_Widget_Record'Class;
                              Event  : Gdk_Event) return boolean;

end Error_Log_Display;
