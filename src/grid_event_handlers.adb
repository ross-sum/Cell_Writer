-----------------------------------------------------------------------
--                                                                   --
--               G R I D _ E V E N T _ H A N D L E R S               --
--                                                                   --
--                              B o d y                              --
--                                                                   --
--                           $Revision: 1.0 $                        --
--                                                                   --
--  Copyright (C) 2022  Hyper Quantum Pty Ltd.                       --
--  Written by Ross Summerfield.                                     --
--                                                                   --
--  This  package handles the drawing events for the cells  in  the  --
--  grid.  These cells are made up of a drawing area, to which  the  --
--  signals are applied, and a text area, in which the character or  --
--  word, as understood, is printed.  The drawing area and the text  --
--  area  are assembled into a GTK Stack and those GTK  Stacks  are  --
--  assembled into the grid.  The event signals here take the input  --
--  and formulate that into an array of points.  The event  signals  --
--  here also do the drawing itself as the user draws the character  --
--  or word.                                                         --
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
-- with Gtkada.Builder;   use Gtkada.Builder;
-- with Glib.Object;      use Glib.Object;
-- with Gtk.Drawing_Area; use Gtk.Drawing_Area;
-- with Gdk.Event, Cairo, Gtk.Widget, Gtk.Menu, Gtk.Menu_Item;
-- with Gdk.RGBA;
-- with dStrings;         use dStrings;
-- with Recogniser;
with GNATCOLL.SQL.Exec.Tasking;
with Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
with Ada.Strings.Wide_Unbounded;
with Ada.Characters.Wide_Latin_1;
with Ada.Containers;
with Error_Log;
with Gdk.Types, Gtk.Enums, Gtk.Grid;
with Pango.Font;
with Glib;                use Glib;
with Vectors;             use vectors;
with String_Conversions;
with Cell_Writer_Version;
-- with Setup;
with Samples;             use Samples;
with Stroke_Management;   use Stroke_Management;
with Grid_Training;       use Grid_Training;
with Code_Interpreter;
package body Grid_Event_Handlers is
   use GNATCOLL.SQL;

   tab     : constant wide_character := Ada.Characters.Wide_Latin_1.HT;
   percent : constant wide_character := '%';
   
   -- Define the border colour to go around the perimeter of each grid cell
   border_colour  : Gdk.RGBA.Gdk_RGBA := Gdk.RGBA.Black_RGBA;
    
   the_builder    : Gtkada_Builder;
   width_offset   : gDouble := 4.0;   -- for placing text in training mode
   height_offset  : gDouble := -5.0;  -- for placing text in training mode
   modifier       : gDouble := 13.0;  -- multiplier for positioning text
   blank_cell_name: constant wide_string := "draw_0_00";
   current_cell   : wide_string(1..9) := blank_cell_name;
   current_sample : Samples.sample_type;
   in_training    : boolean := false;
   the_DB         : GNATCOLL.SQL.Exec.Database_Connection;

   function As_Number(from: in wide_string) return natural is
         -- Convert the string to a number
      result : natural := 0;
   begin
      for chr in from'First .. from'Last loop
         result := result * 10 + 
                   (wide_character'Pos(from(chr)) - wide_character'Pos('0'));
      end loop;
      return result;
   end As_Number;
    
   procedure Register_Handlers(with_builder : in out Gtkada_Builder;
                          DB_Descr : GNATCOLL.SQL.Exec.Database_Description) is
      -- Register all the signal event handlers for each cell drawing area in
      -- the grid and for each combining character button, as well as set the
      -- count for the number of rows and the number of columns.
      use Gtk.Grid, Glib, Gtk.Widget;
      use Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
      use String_Conversions;
      the_grid     : Gtk.Grid.Gtk_Grid;
      writing_area : Gtk.Drawing_Area.gtk_drawing_area;
      children     : Gtk.Widget.Widget_List.Glist;
      our_cell     : wide_string(1..9);
      the_button   : Gtk.Button.gtk_button;
      our_button   : wide_string := "btn_combine_";
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Register_Handlers: Start");
      the_builder := with_builder;
      the_DB:=GNATCOLL.SQL.Exec.Tasking.Get_Task_Connection(Description=>DB_Descr);
      -- Starting from the grid, work through with each child cell
      the_grid := Gtk.Grid.gtk_grid(Get_Object(with_builder, "grid_cells"));
      children := Get_Children(the_grid);
      for item in 0 .. Gtk.Widget.Widget_List.Length(children) - 1 loop
         writing_area := 
              Gtk_Drawing_Area(Gtk.Widget.Widget_List.Nth_Data(children,item));
         -- Now attach each of the handlers to the writing area
         if writing_area /= null 
         then  -- register the handlers and update the row and column count
            Register_Events(for_writing_area => writing_area);
            our_cell := To_Wide_String(Get_Name(writing_area));
            if As_Number(our_cell(6..6)) > grid_size.row then
               grid_size.row := As_Number(our_cell(6..6));
            end if;
            if As_Number(our_cell(8..9)) > grid_size.col then
               grid_size.col := As_Number(our_cell(8..9));
            end if;
         else
            Error_Log.Put(the_error => 13,
                          error_intro   =>  "Register_Handlers error", 
                          error_message => "Didn'd find 'draw at position"&
                                               Guint'Wide_Image(item) & "'.");
         end if;
      end loop;
      for btn_num in 1 .. 10 loop
         if btn_num < 10
         then
            the_button := Gtk_Button(Get_Object(the_builder,
                                     Encode(our_button & 
                                          Integer'Wide_Image(btn_num)(2..2))));
         else
            the_button := Gtk_Button(Get_Object(the_builder,
                                     Encode(our_button & 
                                          Integer'Wide_Image(btn_num)(2..3))));
         
         end if;
         Register_Event(for_button => the_button);
      end loop;
      -- Finally, initialise the the cursor to be the first cell
      Set_Cursor_Position(to => (1,1));
      Error_Log.Debug_Data(at_level => 9, with_details => "Register_Handlers: rows =" & Integer'Wide_Image(grid_size.row) & ", cols =" & Integer'Wide_Image(grid_size.col));
   end Register_Handlers;
   
    -- Draw event Callbacks
   procedure Register_Events(for_writing_area : gtk_drawing_area) is
      writing_area : gtk_drawing_area renames for_writing_area;
   begin
      writing_area.Set_Events(Button_Motion_Mask or Button_Press_Mask or
                              Button_Release_Mask or Leave_Notify_Mask);
      writing_area.On_Button_Press_Event(Draw_Press_CB'access);
      writing_area.On_Button_Release_Event(Draw_Release_CB'access);
      writing_area.On_Draw(Draw_Strokes_CB'access);
      writing_area.On_Motion_Notify_Event(Motion_Notify_CB'access);
      writing_area.On_Leave_Notify_Event(Leave_Notify_CB'access);
      if not Get_Visible(writing_area) then
         Set_Visible(writing_area, visible => true);
      end if;
   end Register_Events;

   procedure Register_Event(for_button : gtk_button) is
      -- Register the call-back event for the specified combining character
      -- button.
      use Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
      the_button : gtk_button renames for_button;
   begin
      -- set up the on-clicked event
      the_button.On_Clicked(Call=>Combining_Clicked_CB'access, After=>false);
   end Register_Event;

   procedure Combining_Clicked_CB(for_button: access GTK_Button_Record'Class)
   is
      -- Respond to the on clicked event when the combining character button
      -- is clicked.  This response is to set into motion the combining
      -- character macro event, wherein the macro inserts the specified
      -- combining character to the currently selected cell's text.
      use Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
      use Code_Interpreter;
      the_button    : Gtk.Button.gtk_button := Gtk_Button(for_button);
      tooltip       : text;
      macro_num     : natural;
      writing_area  : Gtk.Drawing_Area.gtk_drawing_area;
      combining_chr : text;
   begin
      Error_Log.Debug_Data(at_level => 6, 
                           with_details => "Combining_Clicked_CB: Start");
      tooltip := Value_From_Wide(Decode(Get_Tooltip_Text(the_button)));
      macro_num:= Get_Integer_From_String
                                (Sub_String(tooltip, Locate('(',tooltip)+1,2));
      writing_area := Get_Writing_Area(at_position => Get_Cursor_Position);
      combining_chr:= Sub_String(tooltip, Locate(wide_fragment=>"[",
                                                 within=>tooltip)+2, 1);
      Execute (the_cell => writing_area,
               the_macro_Number => macro_num,
               passed_in_parameter => combining_chr);
      Gtk.Widget.Queue_Draw(Gtk_Widget_Record(writing_area.all)'Access);
   end Combining_Clicked_CB;

   procedure Display_Training_Data is
      -- Display the training data into the grid from the current point in
      -- the list of characters or words to be trained up on for the 'page'
      -- worth of grid positions.
      use Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
      writing_area  : Gtk.Drawing_Area.gtk_drawing_area;
   begin
      for row in 1 .. Grid_Row_Count loop
         for col in 1 .. Grid_Column_Count loop
            writing_area := Get_Writing_Area(at_position => (row, col));
            if writing_area /= null
               then
                  -- Store the character or word in the tool tip
               Set_Tooltip_Text(writing_area, The_Char_or_Word_As_UTF8);
               Set_Has_Tooltip(writing_area, true);
                  -- And display the character or word by queuing a redraw
               Gtk.Widget.Queue_Draw(Gtk_Widget_Record(writing_area.all)'Access);
            else
               Error_Log.Put(the_error => 14,
                             error_intro =>  "Display_Training_Data error", 
                             error_message=> "Didn'd find cell.");
            end if;
         end loop;
      end loop;
   end Display_Training_Data;
    
   procedure Set_Training_Switch(to : boolean) is
      -- Set the status of the training switch.  Also set up the grid
      -- ready for training if the switch is depressed.  If the switch
      -- is released, then ensure training data is saved and clear the
      -- training data out of the grid.
      use Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
      use Gtk.Widget, Gtk.Grid;
      grid_cells    : Gtk.Grid.gtk_grid;
   begin
      Error_Log.Debug_Data(at_level => 6, 
                           with_details => "Set_Training_Switch: Start");
      -- First, check if sample is closed up
      if current_cell /= blank_cell_name
         then  -- not yet closed up, so do so before changing training switch
         Close_Out_Sample(for_cell => current_cell);
      end if;
      -- Record switch status
      in_training := to;
      -- Act on switch status
      if in_training
      then  -- Set up the grid ready for training
         -- get the character set, working out the segment of the character set
         -- and paint the character set segment
         Point_At_Grid_Start;
         Display_Training_Data;
      else  -- not in training - save out training data and clear out the grid
         -- Recogniser.Write_Out_Samples (to_database => the_DB);
         -- Clear the text cells
         Clear_The_Grid;
         -- Clear the drawing cells
         grid_cells := Gtk_Grid(Get_Object(the_builder, "grid_cells"));
         Gtk.Widget.Queue_Draw(Gtk_Widget(grid_cells));
      end if;
   end Set_Training_Switch;
   
   function  Training_Is_Switched_On return boolean is
   begin
      return in_training;
   end Training_Is_Switched_On;
   
   function Draw_Press_CB    (writing_area : access Gtk_Widget_Record'Class;
                              event : Gdk_Event_Button) return boolean is
      -- We are starting a new stroke, possibly for a new sample.  If the 
      -- current cell is empty, it is a new sample.  If the current cell is the
      -- same, then it is a new stroke.
      -- The point gets scaled by a scale factor, with an offset such that
      -- the origin of the cell is moved from the top left hand corner
      -- to the centre of the cell.
      use String_Conversions;
      use Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
      use Gdk.Types;
      scale_factor : constant float := float(point_scale) / 
                                       float(Setup.Cell_Height);
      x_offset     : constant float := float(Setup.Cell_Width) / 2.0;
      y_offset     : constant float := float(Setup.Cell_Height) / 2.0;
      scaled_point : point;
      our_cell     : wide_string(1..9); 
   begin
      -- Identify our name
      our_cell := To_Wide_String(Get_Name(gtk_drawing_area(writing_area)));
      Error_Log.Debug_Data(at_level => 7, 
                           with_details => "Draw_Press_CB: Start for '" & 
                                           our_cell & "'.");
      if (Button3_Mask and event.state) = Button3_Mask
      then  -- Ignore any processing here
         null;   -- Ignore the right mouse button click on release
      elsif our_cell /= current_cell
      then  -- changed cells, so close up sample, then initialise everything
         -- Check if sample is closed up for the previous cell
         if current_cell /= blank_cell_name
         then  -- not yet closed up, so do so
            Close_Out_Sample(for_cell => current_cell);
         end if;
         -- Clear current_sample ready for the new sample data (current_sample
         -- is our sample 'scratch pad' where we store the strokes as we go and
         -- finally either recognise it or, if training, load it into the
         -- training database).
         Samples.Clear(current_sample);
         -- and give it a new stroke to start with
         Strokes_Arrays.Append(current_sample.strokes, New_Stroke);
         -- then remember that we have changed the current cell to our_cell
         current_cell := our_cell;
         -- and set the cursor to here
         Set_Cursor_Row(to => As_Number(our_cell(6..6))); 
         Set_Cursor_Column(to => As_Number(our_cell(8..9)));
         -- then check the previous cell
         Check_For_Skipped_Cell;
      else  -- new stroke for this sample
         -- Finish up on the previous stroke
         Process(the_stroke => 
                    current_sample.strokes(current_sample.strokes.Last_Index));
         -- then start the new stroke for this sample
         Strokes_Arrays.Append(current_sample.strokes, New_Stroke);
      end if;
      -- Record the point where the pen is right now
      -- first, work out the offset and scale for the point
      scaled_point := Make_Point(at_x=>(float(event.X)-x_offset)*scale_factor,
                                 at_y=>(y_offset-float(event.Y))*scale_factor);
      -- then load the point into the current_sample
      Add(a_point => scaled_point,
          to_the_stroke =>
                    current_sample.strokes(current_sample.strokes.Last_Index));
      return true;     -- indicate that there is no more processing to do
   end Draw_Press_CB;

   function Draw_Release_CB  (writing_area : access Gtk_Widget_Record'Class;
                              event : Gdk_Event_Button) return boolean is
      -- We are ending a stroke, so we at least save the point where the mouse
      -- button was released.  It may or may not be the last stroke for the
      -- sample, so we just save the stroke; we do not close the sample.
      -- The point gets scaled by a scale factor, with an offset such that
      -- the origin of the cell is moved from the top left hand corner
      -- to the centre of the cell.
      -- A possible event is that the user will skid from the current cell into
      -- another cell (or right out of the Cell Writer) and that will result in
      -- the commencement of a new stroke, but of course the process for
      -- setting up a new stroke hasn't been initiated by other related events
      -- yet.  So, to ignore, just ignore any situation with the current cell
      -- having no strokes or points.
      use String_Conversions;
      use Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
      use Gdk.Types;
      scale_factor : constant float := float(point_scale) / 
                                       float(Setup.Cell_Height);
      x_offset     : constant float := float(Setup.Cell_Width)/2.0;
      y_offset     : constant float := float(Setup.Cell_Height)/2.0;
      x_pos        : float := float(event.X);
      y_pos        : float := float(event.Y);
      our_cell     : wide_string(1..9); 
      drawing_area : Gtk.Drawing_Area.gtk_drawing_area;
      new_point    : point;
   begin
      -- Identify our name
      our_cell := To_Wide_String(Get_Name(gtk_drawing_area(writing_area)));
      drawing_area := Gtk_Drawing_Area(writing_area);
      Error_Log.Debug_Data(at_level => 7, 
                           with_details => "Draw_Release_CB: Start for '" & 
                                           our_cell & "'." & " Event.state = '" & event.state'Wide_Image & "'." & " Event position=(" & Put_Into_String(float(event.X),1) & "," & Put_Into_String(float(event.Y),1) & ").");
      -- Save this point for the stroke as its last point
      new_point := Make_Point(at_x=> (x_pos-x_offset)*scale_factor,
                              at_y=> (y_offset-y_pos)*scale_factor);
      Error_Log.Debug_Data(at_level => 9, with_details => "Draw_Release_CB: point is at (" & Put_Into_String(X(new_point),1) & "," & Put_Into_String(Y(new_point),1) & "), built from X=" & Put_Into_String(x_pos,2) & " and Y=" & Put_Into_String(y_pos,2) & ".");
      if (Button3_Mask and event.state) = Button3_Mask
      then  -- Execute the popup call-back, which may display a pop-up menu
         Error_Log.Debug_Data(at_level => 9, with_details => "Draw_Release_CB: Button3_Mask event state.");
         return Show_Cell_Popup (writing_area, event);
      elsif (Button1_Mask and event.state) = Button1_Mask and then
         not Strokes_Arrays.Is_Empty(current_sample.strokes) and then
               not Points_Arrays.Is_Empty(current_sample.strokes(0).points) and
         then current_sample.strokes(current_sample.strokes.Last_Index).
                    points(current_sample.strokes(current_sample.strokes.
                                    Last_Index).points.Last_Index) /= new_point
      then  -- this is actually a new point and not the same as last time
         Error_Log.Debug_Data(at_level => 9, with_details => "Draw_Release_CB: Button1_Mask event state and a new point.");
         -- Load the current_sample up with the current pen location
         Add(a_point => new_point,
             to_the_stroke =>
                    current_sample.strokes(current_sample.strokes.Last_Index));
         -- Queue up the drawing event to draw the stroke(s) for this cell
         Gtk.Widget.Queue_Draw(Gtk_Widget_Record(drawing_area.all)'Access);
      end if;
      return true;     -- indicate that there is no more processing to do
      exception
         when Constraint_Error => -- probably range check failed
            Error_Log.Put(the_error => 15,
                          error_intro =>  "Draw_Release_CB error", 
                          error_message=> "Range Check, probably no strokes.");
            return false;
   end Draw_Release_CB;
   
   function Draw_Strokes_CB  (writing_area : access Gtk_Widget_Record'Class;
                              Cr : Cairo.Cairo_Context) return boolean is
      -- Draw strokes within the specified current cell.  If the cell is the
      -- same as the current cell (i.e. no cell change, then draw the sample.
      -- If there is no sample for this cell, and then if the tool tip has a
      -- character or word contained within, then draw that.  Otherwise draw
      -- nothing.
      -- The point gets the scale factor removed, then the offset is extracted
      -- out such that the origin of the cell is moved from the centre of the
      -- cell back to the top left hand corner to the centre of the cell.
      use Ada.Containers;
      use String_Conversions;
      scale_factor : constant float := float(point_scale) / 
                                       float(Setup.Cell_Height);
      x_offset     : constant float := float(Setup.Cell_Width)/2.0;
      y_offset     : constant float := float(Setup.Cell_Height)/2.0;
      orientation  : constant point := Make_Point(at_x => 1.0, at_y => -1.0);
      offset_point : constant point:=Make_Point(at_x=>x_offset,at_y=>y_offset);
      our_cell     : wide_string(1..9) := 
                      To_Wide_String(Get_Name(gtk_drawing_area(writing_area)));
      writing_colour  : Gdk.RGBA.Gdk_RGBA:=Setup.Text_Colour;
      bg_used_colour  : Gdk.RGBA.Gdk_RGBA:=Setup.Used_Cell_Colour;
      bg_unused_colour: Gdk.RGBA.Gdk_RGBA:=Setup.Untouched_Cell_Colour;
      highlight_colour: Gdk.RGBA.Gdk_RGBA:=Setup.Highlight_Colour;
      height          : gDouble;
      width           : gDouble;
      thickness       : gDouble;
      adjustment      : gDouble;
      this_is_the_current_cell : boolean := false;
   begin
      -- Error_Log.Debug_Data(at_level => 9, 
         --                   with_details => "Draw_Strokes_CB: Start for '" & 
         --                                   our_cell & "'.");
      -- First, draw the border to this grid cell
      width := gDouble(Gtk.Widget.Get_Allocated_Width(writing_area));
      height:= gDouble(Gtk.Widget.Get_Allocated_Height(writing_area));
      --   Test if this is the current cell.
      if Is_Cursor_At(the_row        => As_Number(our_cell(6..6)), 
                      and_the_column => As_Number(our_cell(8..9)))
      then  --   it is: set the cursor colour to the highlight colour
         thickness := 2.0;  -- the pen width
         Cairo.Set_Source_Rgba(Cr,highlight_colour.Red,highlight_colour.Green,
                                 highlight_colour.Blue,highlight_colour.Alpha);
         this_is_the_current_cell := true;
      else  -- it isn't: set the cursor colour to border_colour
         thickness := 1.0;  -- the pen width
         Cairo.Set_Source_Rgba(Cr, border_colour.Red, border_colour.Green, 
                                   border_colour.Blue, border_colour.Alpha);
         this_is_the_current_cell := false;
      end if;
      cairo.Set_Line_Width(Cr, thickness);  -- set the pen width
      --   draw the lines around the border
      Cairo.Move_To(cr, 0.0, 0.0);
      Cairo.Line_To(cr, width, 0.0);
      Cairo.Line_To(cr, width, height);
      Cairo.Line_To(cr, 0.0, height);
      Cairo.Line_To(cr, 0.0, 0.0);
      --   and paint it
      Cairo.Stroke(cr);
      -- And then colour the background to this grid cell
      if (our_cell = current_cell and then current_sample.strokes.Length >0) or
         (not in_training and Get_Tooltip_Text(writing_area)'Length > 0) or
         (in_training and 
                    Is_Trained(char_or_word => Get_Tooltip_Text(writing_area)))
      then  -- Set the colour to that of a used/written in area
         Cairo.Set_Source_Rgba(Cr, bg_used_colour.Red, bg_used_colour.Green, 
                                   bg_used_colour.Blue, bg_used_colour.Alpha);
      else  -- set the colour to that of an unused/unwritten to area
         Cairo.Set_Source_Rgba(Cr,bg_unused_colour.Red,bg_unused_colour.Green,
                                 bg_unused_colour.Blue,bg_unused_colour.Alpha);
      end if;
      --   mark out the border of the background
      Cairo.Move_To(cr, thickness,       thickness);
      Cairo.Line_To(cr, width-thickness, thickness);
      Cairo.Line_To(cr, width-thickness, height-thickness);
      Cairo.Line_To(cr, thickness,       height-thickness);
      Cairo.Line_To(cr, thickness,       thickness);
      --   and paint the background
      Cairo.Fill(cr);
      
      -- If it is for this cell or else there is nothing in this cell, then
      -- return, otherwise print the strokes
      if our_cell = current_cell and then current_sample.strokes.Length > 0
      then  -- draw the sample
         -- For each point in each stroke for this cell: For each stroke
         for s in current_sample.strokes.First_Index .. 
                     current_sample.strokes.Last_Index loop
               -- : for each point within the stroke
            if natural(current_sample.strokes.Length)-1 < s or else 
                  current_sample.strokes(s).points.Length < 2
            then   -- Safety valve - nothing to process here yet
               exit;
            end if;
            for p in current_sample.strokes(s).points.First_Index ..
                     current_sample.strokes(s).points.Last_Index-1 loop
               declare
                  use GLib;
                  from_point : constant point := 
                                   (current_sample.strokes(s).points(p)/
                                        scale_factor)*orientation+offset_point;
                  to_point   : constant point := 
                                   (current_sample.strokes(s).points(p+1)/
                                        scale_factor)*orientation+offset_point;
               begin
                  if p = current_sample.strokes(s).points.First_Index
                  then  -- first point for stroke, do initial setup.
                     -- Set the cursor colour to writing_colour
                     Cairo.Set_Source_Rgba(Cr, writing_colour.Red, 
                                               writing_colour.Green, 
                                               writing_colour.Blue,
                                               writing_colour.Alpha);
                     -- Set the cursor at the start of the line segment
                     Cairo.Move_To(cr, Gdouble(X(from_point)),
                                       Gdouble(Y(from_point)));
                  end if;
                  -- Draw the line segment from start point to next point
                  Cairo.Line_To(cr, Gdouble(X(to_point)),Gdouble(Y(to_point)));
                  if p = current_sample.strokes(s).points.Last_Index-1
                  then  -- last point drawn for the stroke, finalise.
                     Cairo.Stroke(cr);  -- draw the line (i.e. do line, not fill)
                  end if;
               end;
            end loop;
         end loop;
         return false;  -- we are done - no more screen processing to do
      else  -- if in training, then writing, else cell is blank
         if Get_Tooltip_Text(writing_area)'Length > 0
         then   -- in training and not drawing, or it's written, 
            --     so write in the character
            if this_is_the_current_cell and then 
               Alternative_Mgt.Character_Requires_Highlight
            then  -- there's a pop-up menu worth looking at
               Cairo.Set_Source_Rgba(Cr, highlight_colour.Red, 
                                         highlight_colour.Green, 
                                         highlight_colour.Blue,
                                         highlight_colour.Alpha);
            else  -- no pop-up menu worth looking at
               Cairo.Set_Source_Rgba(Cr, writing_colour.Red, 
                                         writing_colour.Green, 
                                         writing_colour.Blue,
                                         writing_colour.Alpha);
            end if;
            Cairo.Select_Font_Face (cr, Setup.The_Font_Name,
                                        Cairo_Font_Slant_Normal,
                                        Cairo_Font_Weight_Normal);
            Cairo.Set_Font_Size (cr, Setup.Font_Size);
            -- Display the text, with a width offset that is proportional to
            -- the non-combining characters involved
            adjustment := width  / 2.0 - width_offset * (modifier + gDouble(
                          Get_Tooltip_Text(writing_area)'Length))/(modifier+1.0);
            if adjustment < width_offset then
               adjustment := width_offset;
            end if;
            Cairo.Move_To (cr, adjustment, height / 2.0 - height_offset);
            Cairo.Show_Text(cr, Get_Tooltip_Text(writing_area));
            -- And write it out
            Cairo.Fill(cr);
         -- else
         --    don't do anything, just leave the cell cleared
         end if;
         return false;  -- nothing further to do
      end if;
   end Draw_Strokes_CB;
   
   function Motion_Notify_CB (writing_area : access Gtk_Widget_Record'Class;
                              event : Gdk_Event_Motion) return boolean is
      -- If the cell changes, then this is the end of recording the current
      -- sample, in which case, process the sample (or save it out if it is a
      -- training sample).  Otherwise, this is the next point for the current
      -- sample.
      -- The point gets scaled by a scale factor, with an offset such that
      -- the origin of the cell is moved from the top left hand corner
      -- to the centre of the cell.
      use String_Conversions, Ada.Strings.UTF_Encoding.Wide_Strings;
      use Gdk.Types;
      scale_factor : constant float := float(point_scale) / 
                                 float(Setup.Cell_Height);
      x_offset     : constant float:=float(Setup.Cell_Width)/2.0;
      y_offset     : constant float:=float(Setup.Cell_Height)/2.0;
      our_cell     : wide_string(1..9);
      new_point    : point;
   begin
      -- Identify our name
      our_cell := To_Wide_String(Get_Name(gtk_drawing_area(writing_area)));
      if (Button3_Mask and event.state) = Button3_Mask
      then  -- Ignore any processing here
         null;   -- Ignore the right mouse button click on release
      elsif our_cell /= current_cell and current_cell /= blank_cell_name
      then  -- changed cells, so close up sample and process
         Close_Out_Sample(for_cell => current_cell);
      else  -- still in the same cell, so we may need to record the point
         if (Button1_Mask and event.state) = Button1_Mask then
            -- Do a bit of health checking
            if natural(current_sample.strokes.Length) = 0
            then  -- shouldn't be here
               raise NO_POINTS_ERROR;
            end if;
            -- Load the current_stroke up with the current pen location
            -- new_point:= Make_Point(at_x=>float(event.X), at_y=>float(event.Y));
            new_point:=Make_Point(at_x=> (float(event.X)-x_offset)*scale_factor,
                              at_y=> (y_offset-float(event.Y))*scale_factor);
            if current_sample.strokes(current_sample.strokes.Last_Index).points
                    (current_sample.strokes(current_sample.strokes.Last_Index).
                                                points.Last_Index) /= new_point
            then  -- this is actually a new point
               -- record the point
               Add(a_point => new_point,
                   to_the_stroke =>
                    current_sample.strokes(current_sample.strokes.Last_Index));
               -- and queue the drawing event to draw all the strokes in the cell
               Gtk.Widget.Queue_Draw(writing_area);
            end if;
         end if;
      end if;
      null;
      return true;
      exception
         when NO_POINTS_ERROR | NO_STROKES_ERROR =>
            null;  -- no big issue, just exit as nothing to be done
            return true;
   end Motion_Notify_CB;

   function Leave_Notify_CB  (writing_area : access Gtk_Widget_Record'Class;
                              event : Gdk_Event_Crossing) return boolean is
      -- When the mouse pointer leaves the cell, this is called.  At this point,
      -- we want to close out the cell drawing, either by recording the
      -- training sample or by recognising drawn symbol(s).
      use String_Conversions;
      our_cell : wide_string(1..9) := 
                      To_Wide_String(Get_Name(gtk_drawing_area(writing_area)));
   begin
      if event.Mode = Crossing_Normal and then current_cell /= blank_cell_name
       then
         Close_Out_Sample(for_cell => our_cell);
      end if;
      return true;
   end Leave_Notify_CB;

   function Show_Cell_Popup (writing_area : access Gtk_Widget_Record'Class;
                             event : Gdk_Event_Button) return boolean is
      -- Pop up the pop-up menu containing the list of alternative characters
      -- or words that may have been written, but were not the first choice
      -- (but maybe should have been).
      use Gtk.Menu;
      the_menu  : Gtk.Menu.gtk_menu;
      drawing_area : Gtk.Drawing_Area.gtk_drawing_area;
   begin
      Error_Log.Debug_Data(at_level => 8, 
                           with_details => "Show_Cell_Popup: Start");
      -- First check that the menu is attached to this cell.
      drawing_area := gtk_drawing_area(writing_area);
      the_menu := Gtk_Menu(Get_Object(the_builder, "menu_alternatives"));
      if Get_Attach_Widget(the_menu) = Gtk_Widget(writing_area)
      then  -- This is the correct widget
         -- If so, call the pop-up
         Popup(the_menu, null, null, null, event.button, event.time);
         -- Replace later with Popup_At_Widget(the_menu, drawing_area, 0?, 0?, null);
      end if;
      return true;
   end Show_Cell_Popup;
    
   procedure Cell_Writer_Popup_Clicked_CB
                (Object : access Gtk.Menu_Item.Gtk_Menu_Item_Record'Class) is
      -- Get the name of the popup menu item and then action it.
      use Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
      use Gtk.Menu_Item;
      the_entry : text;
   begin
      Error_Log.Debug_Data(at_level => 8, 
                           with_details => "Cell_Writer_Popup_Clicked_CB: Start");
      -- Get the pop-up menu entry
      the_entry := To_Text(Decode(Get_Label(Gtk_Menu_Item(Object))));
      Alternative_Mgt.Current(menu_item => the_entry);
      -- Load the pop-up menu entry into the currently active cell
      Set(cell_at => Get_Cursor_Position, to => Alternative_Mgt.The_Character);
      -- Clear out (reset) current_sample in case it was tampered with, which
      -- can occur as a consequence of the right mouse click operation
      Clear (the_sample => current_sample);
      -- and also reset the current cell's identity to none.
      current_cell := blank_cell_name;
   end Cell_Writer_Popup_Clicked_CB;

   procedure Menu_Detacher(attach_widget : System.Address; 
                           menu : System.Address) is
      -- Detacher call-back required when attaching the pop-up to an object.
      -- This call-back clears the pop-up menu of all of its menu items.
      use Gtk.Menu, Gtk.Menu_Item;
      use Gtk.Widget.Widget_List;
      the_menu  : Gtk.Menu.gtk_menu;
      menu_items: Gtk.Widget.Widget_List.Glist;
   begin
      Error_Log.Debug_Data(at_level=>7, with_details=>"Menu_Detacher: Start");
      -- Translate the system addresse for the menu into our object
      the_menu := gtk_menu(Gtk.Widget.Convert(menu));
      -- Find and delete the children in the menu
      menu_items := Get_Children(the_menu);
      for menu_item in 0 .. Gtk.Widget.Widget_List.Length(menu_items) - 1 loop
         Remove(the_menu, Gtk_Menu_Item(Nth_Data(menu_items,menu_item)));
      end loop;
   end Menu_Detacher;
   
   procedure Update_Character_Usage is
       -- Update the usage for the last character or word entered (if any).
       -- This procedure will not do an update if there was only one word
       -- entered or if there was no previous word entered.
      use Recogniser;
      the_char    : text;
   begin
      Error_Log.Debug_Data(at_level => 8, 
                           with_details => "Update_Character_Usage: Start");
      if Alternative_Mgt.Multiple_Choices_of_Character
      then  -- valid entries for this time around
         Promote(the_character => Alternative_Mgt.The_Character,
                 at_sample_number => Alternative_Mgt.The_Sample_Number);
      end if;
      Alternative_Mgt.Clean_Up;
   end Update_Character_Usage;
       
   procedure Close_Out_Sample(for_cell : in wide_string) is
      -- When the cell has been detected as changed, this procedure is called to
      -- effect the change by either saving the training sample (if in training)
      -- or by finding a match for the sample.  Then the necessary pointer data
      -- is reset to indicat that the change has been effected.
      use Ada.Containers, String_Conversions, Gtk.Widget;
      use Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
      use Recogniser, Recogniser.Alternatives_Arrays, Setup;
      procedure Set_Up_Popup_Menu(for_alternatives: in out alternative_array) is
         use Gtk.Menu, Gtk.Menu_Item;
         the_menu       : Gtk.Menu.Gtk_Menu;
         alt_menu_item  : Gtk.Menu_Item.Gtk_Menu_Item;
         current_cell   : Gtk.Drawing_Area.gtk_drawing_area;
         alternative    : Recogniser.alternative_details;
         alt_num        : natural := 0;
         alt_menu_entry : text;
         the_font     : Pango.Font.Pango_Font_Description :=
                                                    Setup.The_Font_Description;
      begin
         Error_Log.Debug_Data(at_level => 8, 
                              with_details => "Set_Up_Popup_Menu: Start");
         -- First, save the alternatives array for future use
         Alternative_Mgt.Set(the_alternatives => for_alternatives);
         -- get a pointer to the menu
         the_menu := Gtk_Menu(Get_Object(the_builder, "menu_alternatives"));
         -- attach the menu to the current cell, setting up a right mouse click
         current_cell := Get_Writing_Area(at_position => Get_Cursor_Position);
         Modify_Font(the_menu, the_font);
         Set_Title(the_menu, "Pop-up");
         Attach_to_Widget(the_menu, attach_widget => current_cell, 
                          detacher => Menu_Detacher'access);
         -- and load the menu
         First(in_the_list => for_alternatives);
         while not Is_End(of_the_list => for_alternatives) loop
            alternative := Deliver_Data(from_the_list => for_alternatives);
            alt_num := alt_num + 1;
            -- Create the menu item for the character/word alternative
            alt_menu_entry := alternative.ch & tab & 
                          Put_Into_String(integer(alternative.rating * 100.0))&
                              percent;
            alt_menu_item := Gtk_Menu_Item_New_With_Label
                                           (Encode(To_String(alt_menu_entry)));
            Modify_Font(alt_menu_item, the_font);
            Set_ToolTip_Text(alt_menu_item, Encode(To_String(alternative.ch)));
            Set_Sensitive(alt_menu_item, true);
            Set_Visible(alt_menu_item, true);
            -- Set the alternatives menu item's call-back
            alt_menu_item.On_Activate(Call=>Cell_Writer_Popup_Clicked_CB'Access,
                                      After=>False);
            -- Attach the menu item to the pop-up menu
            Attach(menu => the_menu, child => alt_menu_item, 
                   left_attach =>0, right_attach => 1, -- at column 0->column 1 
                   top_attach =>Glib.Guint(alt_num - 1),  -- from bounding row 
                   bottom_attach =>Glib.Guint(alt_num));  -- to bounding row
            -- If this is the first one, then it is the currently chosen one
            if alt_num = 1 then  -- store that as current
               -- selected_popup_entry := alt_menu_entry;
               Alternative_Mgt.Current(menu_item => alt_menu_entry);
            end if;
            Next(in_the_list => for_alternatives);
         end loop;
         -- and finally make it visible
         Set_Visible(the_menu, true);
      end Set_Up_Popup_Menu;
      -- Close_Out_Sample:
      use Gtk.Menu;
      the_cell  : gtk_drawing_area := 
                    gtk_drawing_area(Get_Object(the_builder,Encode(for_cell)));
      the_char  : text;
      identities: alternative_array;
      the_menu  : Gtk.Menu.Gtk_Menu;
   begin   -- Close_Out_Sample
      Error_Log.Debug_Data(at_level => 7, 
                           with_details => "Close_Out_Sample: Start for '" & 
                                           for_cell & "'.");
      -- check that the usage counter for any previous sample has been updated
      Update_Character_Usage;
      -- clear the menu menu_alternatives of existing content
      the_menu := Gtk_Menu(Get_Object(the_builder, "menu_alternatives"));
      if Get_Attach_Widget(the_menu) /= null
      then  -- attached to something at the moment
         Detach(the_menu);  -- Clean up by detaching.
      end if;
      Set_Visible(the_menu, false);  -- and hiding
      -- Finish up on the very last stroke by smoothing, simplifying and
      -- otherwise processing it
      Process(the_stroke => 
                    current_sample.strokes(current_sample.strokes.Last_Index));
      -- Do initial sample processing to provide base data from its strokes
      Process(the_sample => current_sample);
      -- Process sample, depending on whether a training sample or a sample
      -- for recognition
      if in_training and then
            not Strokes_Arrays.Is_Empty(current_sample.strokes) and then
               not Points_Arrays.Is_Empty(current_sample.strokes(0).points)
      then  -- Load the training sample
         -- Do the load
         current_sample.ch := To_Text(Decode(Get_ToolTip_Text(the_cell)));
         Train_Sample (cell => current_sample);
         -- And return to displaying the character
         Record_Training_Is_Done(on_char_or_word => current_sample.ch);
         Gtk.Widget.Queue_Draw(Gtk_Widget_Record(the_cell.all)'Access);
      elsif not Strokes_Arrays.Is_Empty(current_sample.strokes) and then
               not Points_Arrays.Is_Empty(current_sample.strokes(0).points)
      then  -- process the sample
            -- Try to recognise the sample
         Error_Log.Debug_Data(at_level => 9, with_details => "Close_Out_Sample: recognising '" & for_cell & "'.");
         Recognise_Sample (input_sample => current_sample,
                           best_result => the_char,
                           alternatives => identities,
                           num_alternatives => 4);  -- ***** IS THIS RIGHT???*****
         --  Display the most likely result, allowing selections if more
         -- than one.
         if the_char = null_char
         then  -- didn't find a match
            Set_ToolTip_Text(the_cell, "");
         else  -- possible match found
            -- Display and record the match
            Set_ToolTip_Text(the_cell, Encode(To_String(the_char)));
         end if;
         if Count(of_items_in_the_list => identities) > 1
         then  -- several candidate characters/words, set up menu and attach
            Set_Up_Popup_Menu(for_alternatives => identities);
         elsif Count(of_items_in_the_list => identities) = 1
         then  -- just one candidate, so safe to update the usage count
            First(in_the_list => identities);
            Promote(the_character => the_char, 
                    at_sample_number => 
                        Deliver_Data(from_the_list=>identities).sample_number);
         end if;
      -- else moved out of cell, but there is no data entered in this cell
      end if;
      -- then queue a redraw to display the recognised character (if any)
      Gtk.Widget.Queue_Draw(Gtk_Widget_Record(the_cell.all)'Access);
      -- Clear out (reset) current_sample ready for reuse
      Error_Log.Debug_Data(at_level => 9, with_details => "Close_Out_Sample: clearing data '" & for_cell & "'.");
      Clear (the_sample => current_sample);
      -- If there is a cell change, then we want to make sure that the next
      -- operation is a cell change type operation even if the user comes back
      -- and operates on the same cell, just in case they mean to redo the
      -- current cell's contents.
      current_cell := blank_cell_name;
   end Close_Out_Sample;

   procedure Check_For_Skipped_Cell is
      -- When starting drawing at a new cell, check that the previous cell
      -- (which may be to the left(right) ro in the line above) has a character
      -- (or two) assigned.  If not, then assign that cell the space character.
      use Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
      current_cell  : position_type;
      previous_cell : position_type;
      writing_area  : Gtk.Drawing_Area.gtk_drawing_area;
   begin
      current_cell := Get_Cursor_Position;
      previous_cell := current_cell;  -- to start with
      -- Work out the previous cell based on whether writing left to right or
      -- right to left.
      if Setup.Is_Right_to_Left
      then  -- right to left, so it is the one to the right (or prev. row)
         if current_cell.col < Grid_Column_Count
         then
            previous_cell.col := current_cell.col + 1;
         else  -- previous is the last cell on the previous row (if any)
            previous_cell.row := current_cell.row - 1;
            previous_cell.col := Grid_Column_Count;
         end if;
      else  -- left to right, so it is the one to the left (or prev. row)
         if current_cell.col > 1
         then
            previous_cell.col := current_cell.col - 1;
         else  -- previous is the last cell on the previous row (if any)
            previous_cell.row := current_cell.row - 1;
            previous_cell.col := 1;
         end if;
      end if;
      if previous_cell.col > 0 and previous_cell.row > 0
      then  -- were not at the very start - check the cell
         writing_area := Get_Writing_Area(at_position => previous_cell);
         if writing_area /= null
         then  -- work out if the previous cell has a char or word in it
            if Get_Tooltip_Text(writing_area)'Length = 0 then  -- it's blank
               Set_Tooltip_Text(writing_area, " ");  -- load a space in
               Set_Has_Tooltip(writing_area, true);  -- and display it
               Gtk.Widget.Queue_Draw(Gtk_Widget_Record(writing_area.all)'Access);
            end if;
         end if;
      end if;
      exception
         when Constraint_Error =>  -- must have not started yet
            null;  -- just ignore it
   end Check_For_Skipped_Cell;

   function Entered_Text return Text is
       -- Return the complete set of characters, words and spaces entered
       -- and clear the diplay.
       -- The written characters/words are stored in the tool tip for each cell.
       -- We assume here that the user has written from left to right (unless
       -- right to left is set) and from top to bottom.
      use Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
      writing_area  : Gtk.Drawing_Area.gtk_drawing_area;
      the_result    : text;
      col_start,
      col_end       : natural;
      col           : natural;
      in_reverse    : boolean := false;
   begin
      Clear(the_result);
      -- Work out whether the characters/words are right to left or not
      if Setup.Is_Right_to_Left
      then
         col_start  := Grid_Column_Count;
         col_end    := 0;  -- make sure while loop covers down to 1
         in_reverse := true;
      else
         col_start  := 1;  -- + make sure while loop covers all columns
         col_end    := Grid_Column_Count + 1;
      end if;
      for row in 1 .. Grid_Row_Count loop
         col := col_start;
         while col /= col_end loop
            writing_area := Get_Writing_Area(at_position => (row, col));
            if writing_area /= null
            then
               -- Extract the character or word from the tool tip
               append(wide_tail => Decode(Get_Tooltip_Text(writing_area)),
                      to => the_result);
               -- Clear the tool tip
               Set_Tooltip_Text(writing_area, "");
               Set_Has_Tooltip(writing_area, false);
               -- And clear the display by queuing a redraw
               Gtk.Widget.Queue_Draw(Gtk_Widget_Record(writing_area.all)'Access);
            end if;
            if in_reverse
            then col := col - 1;
            else col := col + 1;
            end if;
         end loop;
      end loop;
      return the_result;
   end Entered_Text;
   
   function Cell_Widget_Word return text is
      -- Return the current word or phrase and the current cell's position in
      -- that word/phrase.  This actually splits the currently written-in
      -- components of the cells into two parts, separated by a null character.
      -- That allows for the insertion of a character in a word (or, in the
      -- case of a language like Blissymbolics, potentially the insertion of a
      -- word in a phrase).
      use Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
      txt_cell          : wide_string(1..9) := "draw_0_00";
      writing_area      : Gtk.Drawing_Area.gtk_drawing_area;
      col_start,
      col_end           : natural;
      col               : natural;
      in_reverse        : boolean := false;
      cursor_pos        : natural:= 0;
      first_part        : text;
      last_part         : text;
      past_current_cell : boolean := false;
   begin
      Clear(first_part);
      Clear(last_part);
      -- Work out whether the characters/words are right to left or not
      if Setup.Is_Right_to_Left
      then
         col_start  := Grid_Column_Count;
         col_end    := 0;  -- make sure while loop covers down to 1
         in_reverse := true;
      else
         col_start  := 1;  -- + make sure while loop covers all columns
         col_end    := Grid_Column_Count + 1;
      end if;
      for row in 1 .. Grid_Row_Count loop
         col := col_start;
         while col /= col_end loop
            cursor_pos := cursor_pos + 1;
            if col <= 9
               then
               txt_cell(8) := '0';
               txt_cell(9..9) := Integer'Wide_Image(col)(2..2);
            else
               txt_cell(8..9) := Integer'Wide_Image(col)(2..3);
            end if;
            txt_cell(6..6) := Integer'Wide_Image(row)(2..2);
            writing_area := Gtk_Drawing_Area(Get_Object(the_builder,
                                                           Encode(txt_cell)));
            if writing_area /= null
            then
               -- Extract the character or word from the tool tip
               if col = Cursor_Column and row = Cursor_Row
               then -- this is the current cell - it shouldn't be used
                  null;
                  past_current_cell := true;
               elsif past_current_cell
               then
                  append(wide_tail => Decode(Get_Tooltip_Text(writing_area)),
                         to => last_part);
               else
                  append(wide_tail => Decode(Get_Tooltip_Text(writing_area)),
                         to => first_part);
               end if;
            else
               Error_Log.Put(the_error => 16,
                             error_intro =>  "Entered_Text error", 
                             error_message=> "Didn'd find '"& txt_cell & "'.");
            end if;
            if in_reverse
            then col := col - 1;
            else col := col + 1;
            end if;
         end loop;
      end loop;
      if Length(first_part) = 0
      then  -- cursor is at the end or not assigned, just return last part
         return last_part;
      elsif Length(last_part) = 0
      then  -- cursor is at the beginning or not assigned, return first part
         return first_part;
      else  --split the line with a null and return that
         return first_part &
                wide_character'Val(16#00#) &
                last_part;
      end if;
   end Cell_Widget_Word;

   procedure Clear_The_Grid is
       -- Clear all cells in the grid of data.
      use Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
      txt_cell      : wide_string(1..9) := "draw_0_00";
      writing_area  : Gtk.Drawing_Area.gtk_drawing_area;
   begin
      for row in 1 .. Grid_Row_Count loop
         for col in 1 .. Grid_Column_Count loop
            if col <= 9
               then
               txt_cell(8) := '0';
               txt_cell(9..9) := Integer'Wide_Image(col)(2..2);
            else
               txt_cell(8..9) := Integer'Wide_Image(col)(2..3);
            end if;
            txt_cell(6..6) := Integer'Wide_Image(row)(2..2);
            writing_area := Gtk_Drawing_Area(Get_Object(the_builder,
                                                           Encode(txt_cell)));
            if writing_area /= null
            then
               -- Clear the tool tip
               Set_Tooltip_Text(writing_area, "");
               Set_Has_Tooltip(writing_area, false);
               -- And clear the display by queuing a redraw
               Gtk.Widget.Queue_Draw(Gtk_Widget_Record(writing_area.all)'Access);
            else
               Error_Log.Put(the_error => 17,
                             error_intro =>  "Clear_The_Grid error", 
                             error_message=> "Didn'd find '"& txt_cell & "'.");
            end if;
         end loop;
      end loop;
   end Clear_The_Grid;


   function Previous_Position(from_cell: position_type) return position_type is
       -- Return the cell position that is, in the case of left to right, to
       -- the left (or from the right-most cell of the previous line) or, in
       -- the case oof right to left, the right (or from the left-most cell of
       -- the previous line).  If at the first cell, just return (0,0) to
       -- indicate that we are already at the beginning.
      result : position_type := (0, 0);
   begin
      if Setup.Is_Right_to_Left
      then  -- Right to left writing
         if from_cell.col = grid_size.col
         then  -- at the start of the line
            result.col := 1;  -- go to the end of the previous line
            result.row := from_cell.row - 1;
         else  -- go one cell back (i.e. to the right)
            result.col := from_cell.col + 1;
            result.row := from_cell.row;
         end if;
      else  -- Left to right writing
         if from_cell.col = 1
         then  -- at the start of the line
            result.col := grid_size.col;  -- go to the end of the previous line
            result.row := from_cell.row - 1;
         else  -- go one cell back (i.e. to the left)
            result.col := from_cell.col - 1;
            result.row := from_cell.row;
         end if;
      end if;
      if result.row = 0
      then  -- at the start of cells already - set to 0 (to return (0,0))
         result.col := 0;
      end if;
      return result;
   end Previous_Position;

   function Next_Position(from_cell : position_type) return position_type is
       -- Return the cell position that is, in the case of left to right, to
       -- the right (or from the left-most cell of the previous line) or, in
       -- the case oof right to left, the left (or from the right-most cell of
       -- the previous line).  If at the last cell, just return (0,0) to
       -- indicate that we are already at the end.
      result : position_type := (0, 0);
   begin
      if Setup.Is_Right_to_Left
      then  -- Right to left writing
         if from_cell.col = 1
         then  -- at the end of the line
            result.col := grid_size.col;  -- go to the start of the next line
            result.row := from_cell.row + 1;
         else  -- go one cell forward (i.e. to the left)
            result.col := from_cell.col - 1;
            result.row := from_cell.row;
         end if;
      else  -- Left to right writing
         if from_cell.col = grid_size.col
         then  -- at the start of the line
            result.col := 1;  -- go to the start of the next line
            result.row := from_cell.row + 1;
         else  -- go one cell forward (i.e. to the right)
            result.col := from_cell.col + 1;
            result.row := from_cell.row;
         end if;
      end if;
      if result.row > grid_size.row
      then  -- at the end of cells already - set to 0 (to return (0,0))
         result.row := 0;
         result.col := 0;
      end if;
      return result;
   end Next_Position;

   procedure Set(cell_at : position_type; to : in text) is
       -- Load the specified cell with the specified character.
      use Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
      the_character : constant wide_string := To_String(to);
      writing_area  : Gtk.Drawing_Area.gtk_drawing_area;
   begin
      -- Write up the label for the specified cell name
      writing_area := Get_Writing_Area(at_position => cell_at);
      if writing_area /= null
      then  -- load in the character to the cell
         Set_Tooltip_Text(writing_area, Encode(the_character));
         if Length(to) > 0
         then
            Set_Has_Tooltip(writing_area, true);
         else
            Set_Has_Tooltip(writing_area, false);
         end if;
         -- And update the display by queuing a redraw for this cell
         Gtk.Widget.Queue_Draw(Gtk_Widget_Record(writing_area.all)'Access);
      end if;
   end Set;

   function The_Cell_Contents(at_cell : position_type) return text is
       -- Return the character or word in the specified cell.
      use Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
      writing_area  : Gtk.Drawing_Area.gtk_drawing_area;
   begin
      writing_area := Get_Writing_Area(at_position => at_cell);
      if writing_area /= null
      then  -- got it - return the character or word in the cell
         if Get_Tooltip_Text(writing_area)'Length > 0
         then
            return To_Text(Decode(Get_Tooltip_Text(writing_area)));
         else
            return Clear;
         end if;
      else  -- didn't find the label (this is actually a fault condition)
         -- Error_Log.Put(the_error => 18,
            --            error_intro =>  "The_Cell_Contents error", 
            --            error_message=> "Didn'd find '" & txt_cell& "'.");
         return Clear;
      end if;    
   end The_Cell_Contents;
   
   procedure Set_Current_Cell(to : in wide_character) is
       -- Load the currently selected cell (see cursor management below) with
       -- the specified character.
   begin
      Set(cell_at => Get_Cursor_Position, to => To_Text(from_wide => to));
   end Set_Current_Cell;

   function The_Current_Cell_Contents return text is
       -- Return the character or word in the currently selected cell.
   begin
      return The_Cell_Contents(at_cell => Get_Cursor_Position);
   end The_Current_Cell_Contents;

   procedure Delete_Cell_Contents is
       -- Delete the currently selected cell of its contents.
       -- Basically, move all columns to the right/left (depending on whether
       -- right-to-left is enabled).
      current_position : position_type := Get_Cursor_Position;
      unpositioned     : constant position_type := (0,0);
      cell_text        : text;
   begin
      -- Work through each cell from the current position through to the end, 
      -- assigning the current cell the contents of the next cell.  At the
      -- end, clear it.
      while current_position /=  unpositioned loop
         cell_text := The_Cell_Contents(at_cell =>
                                 Next_Position(from_cell => current_position));
         Set(cell_at => current_position, to => cell_text);
         current_position := Next_Position(from_cell => current_position);
      end loop;
      -- Now we are at the end, clear the very last cell's contents
      current_position.row := grid_size.row;
      if Setup.Is_Right_to_Left
      then  -- Right to left writing -- last cell is at column 1
         current_position.col := 1;
      else  -- Left to right writing -- last cell is at last column
         current_position.col := grid_size.col;
      end if;
      Set(cell_at => current_position, to => Clear);
   end Delete_Cell_Contents;
    
   procedure Backspace is
       -- Delete the contents of the cell prior to the currently selected cell.
      unpositioned : constant position_type := (0,0);
   begin
      -- First, move the cursor to the prior cell
      if Previous_Position(from_cell => Get_Cursor_Position) /= unpositioned
      then  -- not at the very first cell
         Set_Cursor_Position(to => Previous_Position
                                           (from_cell => Get_Cursor_Position));
         Delete_Cell_Contents;
      -- else
      --    ignore the attempt to go before the first cell
      end if;
   end Backspace;

   procedure Insert_Cell is
       -- Insert a blank cell at the currently selected cell position before
       -- all cells to the right.  If there is text at the very last cell in
       -- the grid, then  add a new row to the cell writer grid.
      procedure Add_A_Row is
          -- Add a row to the cell writer grid.  Also increment this package's
          -- understanding of the number of rows.
         use Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
         use Gtk.Grid, Gtk.Enums, Gtk.Widget;
         use String_Conversions;
         txt_cell     : wide_string(1..9) := "draw_0_00";
         writing_area : Gtk.Drawing_Area.gtk_drawing_area;
         the_grid     : Gtk.Grid.Gtk_Grid :=
                      Gtk.Grid.gtk_grid(Get_Object(the_builder, "grid_cells"));
         cell_width   : constant natural := Setup.Cell_Width;
         cell_height  : constant natural := Setup.Cell_Height;
         blank_background_colour : constant Gdk.RGBA.Gdk_RGBA := 
                                                   Setup.Untouched_Cell_Colour;
      begin
         grid_size.row := grid_size.row + 1;
         txt_cell(6..6) := Integer'Wide_Image(grid_size.row)(2..2);
         -- insert the contents at the bottom, which should grow out the row
         if the_grid = null then
            Error_Log.Put(the_error => 19,
                          error_intro =>  "Insert_Cell (Add_A_Row) error", 
                          error_message=> "Failed to assign grid from " & 
                                          "'grid_cells'");
         end if;
         for col in 1..grid_size.col loop
            Gtk_New(writing_area);
            if col <= 9
            then
               txt_cell(8) := '0';
               txt_cell(9..9) := Integer'Wide_Image(col)(2..2);
            else
               txt_cell(8..9) := Integer'Wide_Image(col)(2..3);
            end if;
            Set_Name(writing_area, Encode(txt_cell));
            Error_Log.Debug_Data(at_level => 9, with_details => "Insert_Cell - Add_A_Row: adding cell '" & txt_cell & "' as cell name '"& To_Wide_String(Get_Name(writing_area)) & "'.");
            -- Set the size and colour
            Set_Size_Request(writing_area,Gint(cell_width), Gint(cell_height));
            Override_Background_Color(writing_area,0, blank_background_colour);
            -- Override_Color(the_cell, 0, pen_colour);
            -- Set up the signal events to the writing_area
            Register_Events(for_writing_area => writing_area);
            -- And attach the cell into the grid
            Attach(the_grid, writing_area,
                             Glib.Gint(col-1), Glib.Gint(grid_size.row-1));
            Set_Visible(writing_area, True);  -- by default it is not visible
            Expose_Object(the_builder, -- expose name to the builder for future
                          name => Encode(txt_cell),  -- searches of this object
                          object => GObject(writing_area));
         end loop;
      end Add_A_Row;
      current_position : position_type := grid_size;
      cell_text        : text;
   begin  -- Insert_Cell
      -- First, check as to whether the last cell has any contents.
      if Length(The_Cell_Contents(at_cell => grid_size)) > 0
      then  -- there are contents at the last cell, so add a new row
         Add_A_Row;
         current_position := grid_size;  -- reaffirm after adding the row.
      end if;
      Error_Log.Debug_Data(at_level => 9, with_details => "Insert_Cell: start row="&Put_Into_String(current_position.row)&", last row="&Put_Into_String(grid_size.row)&", start col="&Put_Into_String(current_position.col)&", last col="&Put_Into_String(grid_size.col)&".");
      -- We start from the end and work to the current position, shifting all
      -- cell contents forward (to the right in left-to-right or to the left in
      -- right-to-left writing).
      while current_position /= Get_Cursor_Position loop
         cell_text := The_Cell_Contents(at_cell =>
                             Previous_Position(from_cell => current_position));
         Set(cell_at => current_position, to => cell_text);
         current_position := Previous_Position(from_cell => current_position);
      end loop;
      -- now blank out the cell at the current position
      Set(cell_at => current_position, to => Clear);
   end Insert_Cell;

   function Get_Writing_Area(at_position : in position_type) 
   return Gtk.Drawing_Area.gtk_drawing_area is
       -- Return a handle to the drawing area widget that is the specified
       -- writing cell, that is, at the speicified cell position.
      use Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
      txt_cell      : wide_string(1..9) := "draw_0_00";
      writing_area  : Gtk.Drawing_Area.gtk_drawing_area;
   begin
      if at_position.col <= 9
      then
         txt_cell(8) := '0';
         txt_cell(9..9) := Integer'Wide_Image(at_position.col)(2..2);
      else
         txt_cell(8..9) := Integer'Wide_Image(at_position.col)(2..3);
      end if;
      txt_cell(6..6) := Integer'Wide_Image(at_position.row)(2..2);
      writing_area := Gtk_Drawing_Area(Get_Object(the_builder,
                                                  Encode(txt_cell)));
      if writing_area = null
      then  -- log the fact and then pass back the null pointer
         Error_Log.Put(the_error => 20,
                       error_intro =>  "Redraw_Cell error", 
                       error_message=> "Didn'd find '" & txt_cell & "'.");
      end if;
      return writing_area;
   end Get_Writing_Area;
   
   procedure Redraw_Cell(at_position : in position_type) is
     -- Force a redraw of the cell at the specified cell position so that it
     -- correctly paints the border either highlighted or unhighlighted.
      -- use Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
      -- txt_cell      : wide_string(1..9) := "draw_0_00";
      writing_area  : Gtk.Drawing_Area.gtk_drawing_area;
   begin
      writing_area := Get_Writing_Area(at_position);
      if writing_area /= null
      then  -- Force the redraw of the cell by queuing a redraw
         Gtk.Widget.Queue_Draw(Gtk_Widget_Record(writing_area.all)'Access);
      end if;
   end Redraw_Cell;

   procedure Redraw_Cell_At_The_Cursor is
      -- Force a redraw of the cell at the current cursor position
      -- so that it paints the highlight.
   begin
      Redraw_Cell(at_position => Get_Cursor_Position);
   end Redraw_Cell_At_The_Cursor;

  -- Track the cursor position in the grid.  The grid is a matrix, so the
  -- cursor is located by an 'x' and a 'y' coordinate of the row and column.
   -- type position_type is record
   --       row : natural := 0;  -- 0 means no row, as row starts at 1
   --       col : natural := 0;  -- 0 means no column, as column starts at 1
   --    end record;
   -- cursor_position : position_type;

   procedure Set_Cursor_Position(to : in position_type) is
      old_position : constant position_type := Get_Cursor_Position;
   begin
      cursor_position := to;
      Redraw_Cell_At_The_Cursor;
      if old_position /= (0, 0) then
         Redraw_Cell(at_position => old_position);
      end if;
   end Set_Cursor_Position;

   procedure Set_Cursor_Row(to : in natural) is
      old_position : constant position_type := Get_Cursor_Position;
   begin
      cursor_position.row := to;
      Redraw_Cell_At_The_Cursor;
      Redraw_Cell(at_position => old_position);
   end Set_Cursor_Row;
   
   procedure Set_Cursor_Column(to : in natural) is
      old_position : constant position_type := Get_Cursor_Position;
   begin
      cursor_position.col := to;
      Redraw_Cell_At_The_Cursor;
      Redraw_Cell(at_position => old_position);
   end Set_Cursor_Column;

   function  Get_Cursor_Position return position_type is
   begin
      return cursor_position;
   end Get_Cursor_Position;

   function  Cursor_Row return natural is
   begin
      return cursor_position.row;
   end Cursor_Row;

   function  Cursor_Column return natural is
   begin
      return cursor_position.col;
   end Cursor_Column;

   function  Is_Cursor_At(the_row, and_the_column : in natural) return boolean
   is
   begin
      return Cursor_Row = the_row and Cursor_Column = and_the_column;
   end Is_Cursor_At;

   procedure Cursor_Up is
   begin
      if Cursor_Row > 1 then
         Set_Cursor_Row(to => Cursor_Row - 1);
      end if;
   end Cursor_Up;
   
   procedure Cursor_Down is
   begin
      if Cursor_Row < grid_size.row then
         Set_Cursor_Row(to => Cursor_Row + 1);
      end if;
   end Cursor_Down;
   
   procedure Cursor_Left is
   begin
      if Cursor_Column > 1 then
         Set_Cursor_Column(to => Cursor_Column - 1);
      end if;
   end Cursor_Left;
   
   procedure Cursor_Right is
   begin
      if Cursor_Column < grid_size.col then
         Set_Cursor_Column(to => Cursor_Column + 1);
      end if;
   end Cursor_Right;
   
   procedure Cursor_First_Row is
   begin
      Set_Cursor_Row(to => 1);
   end Cursor_First_Row;
   
   procedure Cursor_Last_Row is
   begin
      Set_Cursor_Row(to => grid_size.row);
   end Cursor_Last_Row;
   
   procedure Cursor_First_Column is
   begin
      Set_Cursor_Column(to => 1);
   end Cursor_First_Column;
   
   procedure Cursor_Last_Column is
   begin
      Set_Cursor_Column(to => grid_size.col);
   end Cursor_Last_Column;

   procedure Set_Grid_Size(with_rows, with_columns : in natural) is
   -- Set the number of columns and number of rows in the grid
   begin
      grid_size.row := with_rows;
      grid_size.col := with_columns;
   end Set_Grid_Size;
   
   function  Grid_Column_Count return natural is
   -- Get the grid's understanding of the number of columns
   begin
      return grid_size.col;
   end Grid_Column_Count;
   
   function  Grid_Row_Count return natural is
   -- Get the grid's understanding of the number of rows
   begin
      return grid_size.row;
   end Grid_Row_Count;


    -- To manage the pop-up menu, the protected type is used.  This effectively
    -- cleanly stores the values of the alternatives and also the current
    -- character selection in the menu.
   protected body Alternative_Mgt is
       -- alternative management
      procedure Set(the_alternatives : in Recogniser.alternative_array) is
         use Recogniser, Recogniser.Alternatives_Arrays, Setup;
         alt_num : natural := 0;
         first_rating : Setup.sample_rating;
      begin
         alternatives_list := the_alternatives;
         -- work out the current actual gap
         current_gap := 1.00;  -- default starting point
         First(in_the_list => alternatives_list);
         while not Is_End(of_the_list => alternatives_list) loop
            alt_num := alt_num + 1;
            if alt_num = 1
            then  -- the gap is the difference between the first sample ...
               first_rating := 
                         Deliver_Data(from_the_list=>alternatives_list).rating;
            elsif alt_num = 2
            then  -- ... and the second sample
               current_gap := first_rating -
                         Deliver_Data(from_the_list=>alternatives_list).rating;
            end if;
            exit when alt_num >= 2;
         end loop;
      end Set;
      procedure Set_Allowed_Rating_Gap(to : in Setup.sample_rating) is
      begin
         allowed_gap := to;
      end Set_Allowed_Rating_Gap;
      procedure Current(menu_item : in text) is
         use Recogniser, Recogniser.Alternatives_Arrays, Setup;
         rating_text : text;
         rating      : Setup.sample_rating;
         alternative : Recogniser.alternative_details;
      begin
         selected_popup_entry := menu_item;
         -- Break up the pop-up entry data into its components
         ch := Sub_String(from => menu_item, starting_at => 1,
                          for_characters => Pos(To_Text(tab),menu_item)-1);
         rating_text := Sub_String(from => menu_item,
                                   starting_at => Length(ch)+2,
                                   for_characters => 
                                           Length(menu_item) - Length(ch) - 1);
         -- check for ending '%'
         if Wide_Element(rating_text, Length(rating_text)) = percent
         then  -- delete it
            Delete(rating_text, Length(rating_text), 1);
         end if;
         rating := Setup.sample_rating(float(
                       Get_Integer_From_String(rating_text)) / 100.0);
         -- locate the appropriate entry in the list
         First(in_the_list => alternatives_list);
         while not Is_End(of_the_list => alternatives_list) loop
            alternative := Deliver_Data(from_the_list => alternatives_list);
            if alternative.ch = ch and alternative.rating = rating
            then  -- assume this is the one
               sample_num := alternative.sample_number;
               exit;
            end if;
            Next(in_the_list => alternatives_list);
         end loop;
      end Current;
      function The_Character return text is
      begin
         return ch;
      end The_Character;
      function The_Sample_Number return natural is
      begin
         return sample_num;
      end The_Sample_Number;
      function Character_Requires_Highlight return boolean is
          -- Indicate whether there is more than one character for this cell
          -- and the gap is insignificant (default is < 5%)
         use Recogniser, Recogniser.Alternatives_Arrays, Setup;
      begin
         return Length(selected_popup_entry) > 0 and then 
                Count(of_items_in_the_list => alternatives_list) > 1 and then
                current_gap >= Setup.Recognition_Accuracy_Margin;
      end Character_Requires_Highlight;
      function Multiple_Choices_of_Character return boolean is
         -- Indicate whether there is more than one character for this cell
         use Recogniser, Recogniser.Alternatives_Arrays;
      begin
         return Length(selected_popup_entry) > 0 and then 
                Count(of_items_in_the_list => alternatives_list) > 1;
      end Multiple_Choices_of_Character;
      procedure Clean_Up is
         -- Clean out all the data so that any future calls indicate that there
         -- are no alternatives
         use Recogniser, Recogniser.Alternatives_Arrays;
      begin
         Clear(ch);
         Clear(selected_popup_entry);
         Clear(the_list => alternatives_list);
         sample_num := 0;
         current_gap := 1.00; -- %
         allowed_gap := Setup.Recognition_Accuracy_Margin;
      end Clean_Up;
    -- private
      -- selected_popup_entry : text;
          -- selected_popup_entry is used solely to preseve the last used value
          -- between calls by Close_Out_Sample or by pressing the btn_enter (to
          -- transmit currently entered text to the receiving application).
          -- This information is used so that the correct training sample's
          -- usage count can be incremented.  When the text is finally entered,
          -- then the correct row number out of this list is retrieved and the
          -- related training sample's 'used' field is updated.
      -- alternatives_list : Recogniser.alternative_array;
          -- the alternatives_list is used solely to preseve its contents
          -- between calls by Close_Out_Sample.
          -- This information is used so that the correct training sample's
          -- usage count can be incremented.  When the text is finally entered,
          -- then the correct row number out of this list is retrieved and the
          -- related training sample's 'used' field is updated.
      -- ch : text;
      -- sample_num : natural := 0;
      -- allowed_gap: Recogniser.sample_rating := 0.05; -- %
      -- current_gap: Recogniser.sample_rating := 1.00; -- %
   end Alternative_Mgt;

begin
   Cell_Writer_Version.Register(revision => "$Revision: v1.0.2$",
                                 for_module => "Grid_Event_Handlers");
end Grid_Event_Handlers;
