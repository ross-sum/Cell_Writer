-----------------------------------------------------------------------
--                                                                   --
--                   G R I D   M A N A G E M E N T                   --
--                                                                   --
--                              B o d y                              --
--                                                                   --
--                         $Revision: 1.0 $                          --
--                                                                   --
--  Copyright (C) 2022  Hyper Quantum Pty Ltd.                       --
--  Written by Ross Summerfield.                                     --
--                                                                   --
--  This  package manages the writing grid.  It controls  its  size  --
--  and  handles  drawing input for it.  It does  not  contain  the  --
--  actual  algoritms for interpretation, but it does receive  hand  --
--  writing input for interpretation.                                --
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
with Error_Log;
with Cell_Writer_Version;
with Gtk.Widget, Gtk.Grid, Gtk.Enums, Gtk.Drawing_Area, Gtk.Stack;
with Gtk.Label, Glib.Object;
-- with , Gdk.RGBA;
-- with dStrings;        use dStrings;
with String_Conversions;
-- with GNATCOLL.SQL.Exec;
with GNATCOLL.SQL.Exec.Tasking, GNATCOLL.SQL_BLOB;
package body Grid_Management is

   cDB : GNATCOLL.SQL.Exec.Database_Connection;
   the_grid : Gtk.Grid.Gtk_Grid;
   -- row count  We will cheat here.  the Gtk.Grid element should know its row
   -- count and column count.
   row_count,
   column_count : natural :=0;
   -- Note: the grid row and colummn indexes ae zero based.
   cell_width   : natural := 45;
   cell_height  : natural := 70;
   blank_background_colour : Gdk.RGBA.Gdk_RGBA := Gdk.RGBA.White_RGBA;
   used_background_colour  : Gdk.RGBA.Gdk_RGBA := Gdk.RGBA.White_RGBA;
   pen_colour              : Gdk.RGBA.Gdk_RGBA := Gdk.RGBA.Black_RGBA;

   function ToString(int : in natural) return string is
      num : natural := int;
      result : string(1..5) := "     ";
      len    : natural := 0;
   begin
      while num > 0 loop
         len := len + 1;
         result(5-len+1):= character'Val(character'Pos('0') + num rem 10);
         num := (num - (num rem 10)) / 10;
      end loop;
      return result((5-len+1)..5);
   end ToString;

   procedure Initialise_Grid(Builder : in out Gtkada_Builder;
                             DB_Descr: GNATCOLL.SQL.Exec.Database_Description)
   is
      use Gtk.Grid;
      the_colour: Gdk.RGBA.Gdk_RGBA;
      result    : boolean;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details=> "Initialise_Grid: Start");
      -- Set up: Open the relevant tables from the database
      cDB:=GNATCOLL.SQL.Exec.Tasking.Get_Task_Connection(Description=>DB_Descr);
      null;
      -- Set up: assign the grid to the grid variable
      the_grid := Gtk.Grid.gtk_grid(Get_Object(Builder, "grid_cells"));
      -- Set up: set the colour of the grid so you can see the drawing area
      Gdk.RGBA.Parse(the_colour, "rgb(128,128,128)", result);
      if result then
         Override_Background_Color(the_grid, 0, the_colour);
      else
         Override_Background_Color(the_grid, 0, Gdk.RGBA.Black_RGBA);
      end if;
      -- Ugly hack as unable to determine how to read the row+column count
      row_count := 5;
      column_count := 10;
   end Initialise_Grid;
    
   procedure Resize_Grid (to_rows, to_cols : natural) is
      use Glib, Gtk.Grid, Gtk.Enums, Gtk.Widget;
      use Gtk.Drawing_Area, Gtk.Label, Gtk.Stack;
      use String_Conversions;
     -- Resize the grid of writing cells such that it becomes <to_rows> deep
     -- by <to_cols> wide.
      -- Rows and columns passed in are one (1) based, but the grid is zero (0)
      -- based.
      the_cell       : Gtk.Stack.gtk_stack;
      writing_area   : Gtk.Drawing_Area.gtk_drawing_area;
      cell_contents  : Gtk.Label.gtk_label;
      -- at_num         : Glib.Gint;
   begin
      Error_Log.Debug_Data(at_level => 5, with_details=> "Resize_Grid: Start");
      -- Delete excess rows
      while to_rows < row_count loop
         Error_Log.Debug_Data(at_level     => 8, 
                              with_details => "Resize_Grid: delete a row");
         -- delete the row
         Remove_Row(the_grid, Glib.Gint(row_count-1));
         row_count := row_count - 1;
      end loop;
      -- Delete excess columns
      while to_cols < column_count loop
         Error_Log.Debug_Data(at_level     => 8, 
                              with_details => "Resize_Grid: delete a column");
         -- delete the column
         Remove_Column(the_grid, Glib.Gint(column_count-1));
         column_count := column_count - 1;
      end loop;
      -- Append additional rows
      while row_count < to_rows loop
         Error_Log.Debug_Data(at_level     => 8, 
                              with_details => "Resize_Grid: add a row");
         -- insert the row at the bottom of the grid
         row_count := row_count + 1;
         -- insert the contents at the bottom, which should grow out the fow
         for col in 1..column_count loop
            Gtk_New(the_cell);
            Gtk_New(writing_area);
            Gtk_New(cell_contents);
            if col < 10 then
               Set_Name(the_cell, "stack_" & ToString(row_count) &
                                  "_0" & ToString(col));
               Set_Name(writing_area, "draw_" & ToString(row_count) &
                                      "_0" &ToString(col));
               Add_Named(the_cell, writing_area, "draw_" & 
                         ToString(col) & "_0" & ToString(row_count));
               Set_Name(cell_contents, "char" & ToString(row_count) &
                                       "_0" & ToString(col));
               Add_Named(the_cell, cell_contents, "char" & 
                         ToString(row_count) & "_0" & ToString(col));
            else
               Set_Name(the_cell, "stack_" & ToString(row_count) &
                                  "_" & ToString(col));
               Set_Name(writing_area, "char_" & ToString(row_count) &
                                      "_" & ToString(col));
               Add_Named(the_cell, writing_area, "draw_" & 
                         ToString(row_count) & "_" & ToString(col));
               Set_Name(cell_contents, "char_" & ToString(row_count) &
                                       "_" & ToString(col));
               Add_Named(the_cell, cell_contents, "char" & 
                         ToString(row_count) & "_" & ToString(col));
            end if;
            Set_Size_Request(the_cell, Gint(cell_width), Gint(cell_height));
            Override_Background_Color(the_cell, 0, blank_background_colour);
            Override_Color(the_cell, 0, pen_colour);
            Attach(the_grid, the_cell,Glib.Gint(col-1),Glib.Gint(row_count-1));
            Set_Visible(the_cell, True);  -- by default it is not visible
         end loop;
      end loop;
      -- Append additional columns
      while column_count < to_cols loop
         Error_Log.Debug_Data(at_level     => 8, 
                              with_details => "Resize_Grid: add a column");
         -- insert the column at the right of the grid
         column_count := column_count + 1;
         -- insert the cell contents to the right, which should grow the column
         for row in 1..row_count loop
            Gtk_New(the_cell);
            Gtk_New(writing_area);
            Gtk_New(cell_contents);
            if column_count < 10 then
               Set_Name(the_cell, "stack_" & ToString(row) &
                                      "_0" & ToString(column_count));
               Set_Name(writing_area, "draw_" & ToString(row) &
                                      "_0" & ToString(column_count));
               Add_Named(the_cell, writing_area, "draw_" & 
                         ToString(row) & "_0" & ToString(column_count));
               Set_Name(cell_contents, "char" & ToString(row) &
                                       "_0" & ToString(column_count));
               Add_Named(the_cell, cell_contents, "char" & 
                         ToString(row) & "_0" & ToString(column_count));
            else
               Set_Name(the_cell, "stack_" & ToString(row) &
                                      "_" & ToString(column_count));
               Set_Name(writing_area, "draw_" & ToString(row) &
                                      "_" & ToString(column_count));
               Add_Named(the_cell, writing_area, "draw_" & 
                         ToString(row) & "_0" & ToString(column_count));
               Set_Name(cell_contents, "char" & ToString(row) &
                                       "_0" & ToString(column_count));
               Add_Named(the_cell, cell_contents, "char" & 
                         ToString(row) & "_0" & ToString(column_count));
            end if;
            Set_Size_Request(the_cell, Gint(cell_width), Gint(cell_height));
            Override_Background_Color(the_cell, 0, blank_background_colour);
            Override_Color(the_cell, 0, pen_colour);
            Attach(the_grid, the_cell, Glib.Gint(column_count-1), 
                                       Glib.Gint(row-1));
            Set_Visible(the_cell, True);  -- by default it is not visible
         end loop;
      end loop;
      Error_Log.Debug_Data(at_level => 7, with_details=> "Resize_Grid: End");
   end Resize_Grid;

   procedure Set_Writing_Colours(for_text, for_blank_background, 
                                 for_used_background : Gdk.RGBA.Gdk_RGBA) is
      -- Set up the writing cell colours and make sure that the writing area is
      -- at the front.
      use Glib, Gtk.Grid, Gtk.Enums, Gtk.Drawing_Area, Gtk.Stack;
      use String_Conversions;
      the_cell       : Gtk.Stack.gtk_stack;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details=> "Set_Writing_Colours: Start");
      blank_background_colour := for_blank_background;
      used_background_colour  := for_used_background;
      pen_colour              := for_text;
      for col in 0 .. column_count-1 loop
         for row in 0 .. row_count-1 loop
            the_cell := Gtk_Stack(Get_Child_At(the_grid, Gint(col),Gint(row)));
            if the_cell /= null then
               Override_Background_Color(the_cell, 0, 
                                         blank_background_colour);
               Override_Color(the_cell, 0, pen_colour);
               -- suck the drawing area to the front, (in front of the text)
               if col < 9 then
                  Set_Visible_Child_Name(the_cell, "draw_" & ToString(row+1) &
                                         "_0" & ToString(col+1));
               else
                  Set_Visible_Child_Name(the_cell, "draw_" & ToString(row+1) &
                                         "_" & ToString(col+1));
               end if;
            else
               Error_Log.Debug_Data(at_level => 6, 
                      with_details=> "Set_Writing_Colours: did not find cell");
            end if;
         end loop;
      end loop;
   end Set_Writing_Colours;

   procedure Set_Writing_Size(height, width : natural) is
      -- Set up the writing size and apply the font.
      use Glib, Gtk.Grid, Gtk.Enums, Gtk.Drawing_Area, Gtk.Stack, Gtk.Widget;
      the_cell    : Gtk.Stack.gtk_stack;
      requisition : Gtk_Requisition;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details=> "Set_Writing_Size: Start");
      cell_width  := width;
      cell_height := height;
      for col in 0 .. column_count-1 loop
         for row in 0 .. row_count-1 loop
            the_cell := Gtk_Stack(Get_Child_At(the_grid, Gint(col),Gint(row)));
            if the_cell /= null then
               Set_Size_Request(the_cell, Gint(cell_width), Gint(cell_height));
               Size_Request(the_cell, requisition);  -- Force a cell redraw to resize
            else
               Error_Log.Debug_Data(at_level => 6, 
                         with_details=> "Set_Writing_Size: did not find cell");
            end if;
         end loop;
      end loop;
   end Set_Writing_Size;

begin
   Cell_Writer_Version.Register(revision => "$Revision: v1.0.0$",
                                for_module => "Grid_Management");
end Grid_Management;
