-----------------------------------------------------------------------
--                                                                   --
--               G R I D _ E V E N T _ H A N D L E R S               --
--                                                                   --
--                     S p e c i f i c a t i o n                     --
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
--  area  are assembled into a GTK Grid, which is made up  of  grid  --
--  cells.   Each  cell  contains a GTK Drawing  Area.   The  event  --
--  signals here take the input and formulate that into an array of  --
--  points.   The event signals here also do the drawing itself  as  --
--  the user draws the character or word.                            --
--  This  package additionally tracks the currently selected  cell,  --
--  which  is  essentially the cursor position.  That  position  is  --
--  used to highlight the border of that currently selected cell.    --
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
with System;
with GNATCOLL.SQL.Exec;
with Gtkada.Builder;   use Gtkada.Builder;
with Glib.Object;      use Glib.Object;
with Gtk.Drawing_Area; use Gtk.Drawing_Area;
with Gtk.Button;
with Gdk.Event, Cairo, Gtk.Widget, Gtk.Menu, Gtk.Menu_Item;
with Gdk.RGBA;
with dStrings;         use dStrings;
with Recogniser;
package Grid_Event_Handlers is
    
   procedure Register_Handlers(with_builder : in out Gtkada_Builder;
                            DB_Descr : GNATCOLL.SQL.Exec.Database_Description);
      -- Register all the signal event handlers for each cell drawing area in
      -- the grid and for each combining character button, as well as set the
      -- count for the number of rows and the number of columns.
   procedure Set_Training_Switch(to : boolean);
      -- Set the status of the training switch.  Also set up the grid
      -- ready for training if the switch is depressed.  If the switch
      -- is released, then ensure training data is saved and clear the
      -- training data out of the grid.
   function  Training_Is_Switched_On return boolean;

   procedure Display_Training_Data;
      -- Display the training data into the grid from the current point in
      -- the list of characters or words to be trained up on for the 'page'
      -- worth of grid positions.
   
    -- Draw event Callbacks
   procedure Register_Events(for_writing_area : gtk_drawing_area);
      -- Register the call-back events for the specified grid cell.

   function Entered_Text return Text;
      -- return the complete set of characters, words and spaces entered
      -- and clear the diplay.
       
   function Cell_Widget_Word return text;
      -- Return the current word or phrase and the current cell's position in
      -- that word/phrase.  This actually splits the currently written-in
      -- components of the cells into two parts, separated by a null character.
      -- That allows for the insertion of a character in a word (or, in the
      -- case of a language like Blissymbolics, potentially the insertion of a
      -- word in a phrase).

   procedure Update_Character_Usage;
       -- Update the usage for the last character or word entered (if any).
       -- This procedure will not do an update if there was only one word
       -- entered or if there was no previous word entered.
       
   procedure Clear_The_Grid;
      -- Clear all cells in the grid of data.
   procedure Delete_Cell_Contents;
      -- Delete the currently selected cell of its contents.
   procedure Backspace;
      -- Delete the contents of the cell prior to the currently selected cell.
   procedure Insert_Cell;
      -- Insert a blank cell at the currently selected cell position before
      -- all cells to the right.  If there is text at the very last cell in
      -- the grid, then  add a new row to the cell writer grid.
   procedure Refresh_Current_Cell;
      -- Refresh the display of the current cell.  This would be important to
      -- do if one or more training samples were deleted when in training
      -- mode.  In that case, it would update the cell's highlighting.
      -- This procedure is essentially an alias for Redraw_Cell_At_The_Cursor.
       
   procedure Set_Current_Cell(to : in wide_character);
      -- Load the currently selected cell (see cursor management below) with
      -- the specified character.
   function The_Current_Cell_Contents return text;
      -- Return the character or word in the currently selected cell.
    
    -- Grid cursor management
   procedure Cursor_Up;
   procedure Cursor_Down;
   procedure Cursor_Left;
   procedure Cursor_Right;
   procedure Cursor_First_Row;
   procedure Cursor_Last_Row;
   procedure Cursor_First_Column;
   procedure Cursor_Last_Column;
   -- The grid event handlers package, as a part of its initialisation, works
   -- out the number of rows and columns.  However, it does not track that
   -- thereafter - that function is left to the Grid_Management package.
   procedure Set_Grid_Size(with_rows, with_columns : in natural);
      -- Set the number of columns and number of rows in the grid
   function  Grid_Column_Count return natural;
      -- Get the grid's understanding of the number of columns
   function  Grid_Row_Count return natural;
      -- Get the grid's understanding of the number of rows
       
private
   use Gdk.Event, Cairo, Gtk.Widget,  Gtk.Button;

    -- Combining Character event management, both to register the event and to
    -- manage the on-click event
   procedure Register_Event(for_button : gtk_button);
      -- Register the call-back event for the specified combining character
      -- button.  Essentially, assign it the Combining_Clicked_CB to the
      -- requested button.
   procedure Combining_Clicked_CB(for_button: access GTK_Button_Record'Class);
      -- Respond to the on clicked event when the combining character button
      -- is clicked.  This response is to set into motion the combining
      -- character macro event, wherein the macro inserts the specified
      -- combining character to the currently selected cell's text.

   function Show_Cell_Popup (writing_area : access Gtk_Widget_Record'Class;
                             event : Gdk_Event_Button) return boolean;
      -- Pop up the pop-up menu containing the list of alternative characters
      -- or words that may have been written, but were not the first choice
      -- (but maybe should have been).
   procedure Cell_Writer_Popup_Clicked_CB
                (Object : access Gtk.Menu_Item.Gtk_Menu_Item_Record'Class);
      -- Get the name of the popup menu item and then action it.
      -- This event is called when the user selects an item from the pop-up
      -- menu (that was poped up in by the Cell_Popup_Click_CB event).
   procedure Menu_Detacher(attach_widget : System.Address; 
                           menu : System.Address);
    pragma Convention (C, Menu_Detacher);
      -- Detacher call-back required when attaching the pop-up to an object.
      -- This call-back clears the pop-up menu of all of its menu items.

   function Draw_Press_CB    (writing_area : access Gtk_Widget_Record'Class;
                              event : Gdk_Event_Button) return boolean;
      -- This is for starting a new stroke, possibly for a new sample.  If the 
      -- current cell is empty, it is a new sample.  If the current cell is the
      -- same, then it is a new stroke.
   function Draw_Release_CB  (writing_area : access Gtk_Widget_Record'Class;
                              event : Gdk_Event_Button) return boolean;
      -- End a stroke, so this process at least saves the point where the mouse
      -- button was released.  It may or may not be the last stroke for the
      -- sample, so we just save the stroke; we do not close the sample.
   function Draw_Strokes_CB  (writing_area : access Gtk_Widget_Record'Class;
                              Cr : Cairo.Cairo_Context) return boolean;
      -- Draw strokes within the specified current cell.  If the cell is the
      -- same as the current cell (i.e. no cell change, then draw the sample.
      -- If there is no sample for this cell, and then if the tool tip has a
      -- character or word contained within, then draw that.  Otherwise draw
      -- nothing.
   function Motion_Notify_CB (writing_area : access Gtk_Widget_Record'Class;
                              event : Gdk_Event_Motion) return boolean;
      -- Called whenever the mouse moves inside the window, but never if it
      -- leaves the window.  It also seems to only work when the button is
      -- pressed.
   function Leave_Notify_CB  (writing_area : access Gtk_Widget_Record'Class;
                              event : Gdk_Event_Crossing) return boolean;
      -- When the mouse pointer leaves the cell, this is called.  At this point,
      -- we want to close out the cell drawing, either by recording the
      -- training sample or by recognising drawn symbol(s).
   procedure Close_Out_Sample(for_cell : in wide_string);
      -- When the cell has been detected as changed, this procedure is called to
      -- effect the change by either saving the training sample (if in training)
      -- or by finding a match for the sample.  Then the necessary pointer data
      -- is reset to indicat that the change has been effected.
   procedure Check_For_Skipped_Cell;
      -- When starting drawing at a new cell, check that the previous cell
      -- (which may be to the left(right) or in the line above) has a character
      -- (or two) assigned.  If not, then assign that cell the space character.
  
  -- Track the cursor position in the grid.  The grid is a matrix, so the
  -- cursor is located by an 'x' and a 'y' coordinate of the row and column.
   type position_type is record
         row : natural := 0;  -- 0 means no row, as row starts at 1
         col : natural := 0;  -- 0 means no column, as column starts at 1
      end record;
   cursor_position : position_type;
    
   grid_size       : position_type;  -- number of rows and columns
  
   procedure Set_Cursor_Position(to : in position_type);
   procedure Set_Cursor_Row(to : in natural);
   procedure Set_Cursor_Column(to : in natural);
   function  Get_Cursor_Position return position_type;
   function  Cursor_Row return Natural;
   function  Cursor_Column return Natural;
   function  Is_Cursor_At(the_row, and_the_column : in natural) return boolean;

   procedure Set(cell_at : position_type; to : in text);
      -- Load the specified cell with the specified character.
   function The_Cell_Contents(at_cell : position_type) return text;
      -- Return the character or word in the specified cell.
   function Previous_Position(from_cell : position_type) return position_type;
      -- Return the cell position that is, in the case of left to right, to
      -- the left (or from the right-most cell of the previous line) or, in
      -- the case oof right to left, the right (or from the left-most cell of
      -- the previous line).  If at the first cell, just return (0,0) to
       -- indicate that we are already at the beginning.
   function Next_Position(from_cell : position_type) return position_type;
      -- Return the cell position that is, in the case of left to right, to
      -- the right (or from the left-most cell of the previous line) or, in
      -- the case oof right to left, the left (or from the right-most cell of
      -- the previous line).  If at the last cell, just return (0,0) to
      -- indicate that we are already at the end.
   
   function Get_Writing_Area(at_position : in position_type) 
   return Gtk.Drawing_Area.gtk_drawing_area;
      -- Return a handle to the drawing area widget that is the specified
      -- writing cell, that is, at the speicified cell position.
   procedure Redraw_Cell(at_position : in position_type);
      -- Force a redraw of the cell at the specified cell position so that it
      -- correctly paints the border either highlighted or unhighlighted.
   procedure Redraw_Cell_At_The_Cursor;
      -- Force a redraw of the cell at the current cursor position
      -- so that it paints the highlight.
   procedure Refresh_Current_Cell renames Redraw_Cell_At_The_Cursor;

    -- To manage the pop-up menu, the protected type is used.  This effectively
    -- cleanly stores the values of the alternatives and also the current
    -- character selection in the menu.
   protected Alternative_Mgt is
       -- alternative management
      procedure Set(the_alternatives : in Recogniser.alternative_array);
      procedure Current(menu_item : in text);
      procedure Set_Allowed_Rating_Gap(to : in Recogniser.sample_rating);
      function The_Character return text;
      function The_Sample_Number return natural;
      function Character_Requires_Highlight return boolean;
          -- Indicate whether there is more than one character for this cell
          -- and the gap is insignificant (default is < 5%)
      function Multiple_Choices_of_Character return boolean;
          -- Indicate whether there is more than one character for this cell
      procedure Clean_Up;
          -- Clean out all the data so that any future calls indicate that there
          -- are no alternatives
    private
      selected_popup_entry : text;
          -- selected_popup_entry is used solely to preseve the last used value
          -- between calls by Close_Out_Sample or by pressing the btn_enter (to
          -- transmit currently entered text to the receiving application).
          -- This information is used so that the correct training sample's
          -- usage count can be incremented.  When the text is finally entered,
          -- then the correct row number out of this list is retrieved and the
          -- related training sample's 'used' field is updated.
      alternatives_list : Recogniser.alternative_array;
          -- the alternatives_list is used solely to preseve its contents
          -- between calls by Close_Out_Sample.
          -- This information is used so that the correct training sample's
          -- usage count can be incremented.  When the text is finally entered,
          -- then the correct row number out of this list is retrieved and the
          -- related training sample's 'used' field is updated.
      ch : text;
      sample_num : natural := 0;
      allowed_gap: Recogniser.sample_rating := 0.05; -- %
      current_gap: Recogniser.sample_rating := 1.00; -- %
   end Alternative_Mgt;

end Grid_Event_Handlers;
