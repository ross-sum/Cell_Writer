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
--  General  Public Licence distributed with Cell_Writer.  If  not,  --
--  write  to  the Free Software Foundation,  51  Franklin  Street,  --
--  Fifth Floor, Boston, MA 02110-1301, USA.                         --
--                                                                   --
-----------------------------------------------------------------------
-- with Gtkada.Builder;  use Gtkada.Builder;
-- with Gdk.RGBA;
-- with GNATCOLL.SQL.Exec;
with Error_Log;
with Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
with Gtk.Widget, Gtk.Grid, Gtk.Enums, Gtk.Drawing_Area; --, Gtk.Menu;
with Pango.Font, Glib.Object, Glib.Values, Gdk.Color;
with dStrings;        use dStrings;
with String_Conversions;
with GNATCOLL.SQL.Exec.Tasking, GNATCOLL.SQL_BLOB;
with Cell_Writer_Version;
with Grid_Event_Handlers;
With Setup;
package body Grid_Management is

   cDB : GNATCOLL.SQL.Exec.Database_Connection;
   the_builder : Gtkada_Builder;
   the_grid : Gtk.Grid.Gtk_Grid;
   -- row count  We will cheat here.  the Gtk.Grid element should know its row
   -- count and column count.
   row_count,
   column_count : natural := 0;
   -- Note: the grid row and colummn indexes ae zero based.
   cell_width   : natural := 45;
   cell_height  : natural := 70;
   blank_background_colour : Gdk.RGBA.Gdk_RGBA := Gdk.RGBA.White_RGBA;
   used_background_colour  : Gdk.RGBA.Gdk_RGBA := Gdk.RGBA.White_RGBA;
   pen_colour              : Gdk.RGBA.Gdk_RGBA := Gdk.RGBA.Black_RGBA;
   
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
      the_builder := Builder;
      -- Set up: assign the grid to the grid variable
      the_grid := Gtk.Grid.gtk_grid(Get_Object(Builder, "grid_cells"));
      -- Set up: set the colour of the grid so you can see the drawing area
      Gdk.RGBA.Parse(the_colour, "rgb(128,128,128)", result);
      if result then
         Override_Background_Color(the_grid, 0, the_colour);
      else
         Override_Background_Color(the_grid, 0, Gdk.RGBA.Black_RGBA);
      end if;
      -- Get the initial values of row and column from the Grid_Event_Handlers
      row_count := Grid_Event_Handlers.Grid_Row_Count;
      column_count := Grid_Event_Handlers.Grid_Column_Count;
   end Initialise_Grid;
    
   procedure Resize_Grid (to_rows, to_cols : natural) is
     -- Resize the grid of writing cells such that it becomes <to_rows> deep
     -- by <to_cols> wide.
      -- Rows and columns passed in are one (1) based, but the grid is zero (0)
      -- based.
      use Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
      use Glib, Gtk.Grid, Gtk.Enums, Gtk.Widget;
      use Gtk.Drawing_Area, Glib.Object;
      use String_Conversions;
      use Grid_Event_Handlers;
      txt_cell       : wide_string(1..9) := "draw_0_00";
      writing_area   : Gtk.Drawing_Area.gtk_drawing_area;
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
         txt_cell(6..6) := Integer'Wide_Image(row_count)(2..2);
         -- insert the contents at the bottom, which should grow out the row
         for col in 1..column_count loop
            Gtk_New(writing_area);
            if col <= 9
            then
               txt_cell(8) := '0';
               txt_cell(9..9) := Integer'Wide_Image(col)(2..2);
            else
               txt_cell(8..9) := Integer'Wide_Image(col)(2..3);
            end if;
            Set_Name(writing_area, Encode(txt_cell));
            -- Set the size and colour
            Set_Size_Request(writing_area,Gint(cell_width), Gint(cell_height));
            Override_Background_Color(writing_area, 0, blank_background_colour);
            -- Override_Color(the_cell, 0, pen_colour);
            -- Set up the signal events to the writing_area
            Register_Events(for_writing_area => writing_area);
            -- And attach the cell into the grid
            Attach(the_grid, writing_area,
                             Glib.Gint(col-1), Glib.Gint(row_count-1));
            Set_Visible(writing_area, True);  -- by default it is not visible
            Expose_Object(the_builder, -- expose name to the builder for future
                          name => Encode(txt_cell),  -- searches of this object
                          object => GObject(writing_area));
         end loop;
      end loop;
      -- Append additional columns
      while column_count < to_cols loop
         Error_Log.Debug_Data(at_level     => 8, 
                              with_details => "Resize_Grid: add a column");
         -- insert the column at the right of the grid
         column_count := column_count + 1;
         if column_count <= 9
         then
            txt_cell(8) := '0';
            txt_cell(9..9) := Integer'Wide_Image(column_count)(2..2);
         else
            txt_cell(8..9) := Integer'Wide_Image(column_count)(2..3);
         end if;
         -- insert the cell contents to the right, which should grow the column
         for row in 1..row_count loop
            -- Gtk_New(the_cell);
            Gtk_New(writing_area);
            -- Gtk_New(cell_contents);
            txt_cell(6..6) := Integer'Wide_Image(row)(2..2);
            Set_Name(writing_area, Encode(txt_cell));
            -- Set the size and colour
            Set_Size_Request(writing_area, Gint(cell_width), Gint(cell_height));
            Override_Background_Color(writing_area, 0, blank_background_colour);
            -- Override_Color(the_cell, 0, pen_colour);
            -- Set up the signal events to the writing_area
            Register_Events(for_writing_area => writing_area);
            -- And attach the cell into the grid
            Attach(the_grid, writing_area, Glib.Gint(column_count-1), 
                                           Glib.Gint(row-1));
            Set_Visible(writing_area, True);  -- by default it is not visible
         end loop;
      end loop;
      -- Now store the new size in the grid event handlers for its use
      Set_Grid_Size(with_rows => to_rows, with_columns => to_cols);
      Error_Log.Debug_Data(at_level => 7, with_details=> "Resize_Grid: End");
   end Resize_Grid;

   procedure Set_Writing_Colours(for_text, for_blank_background, 
                                 for_used_background : Gdk.RGBA.Gdk_RGBA) is
      -- Set up the writing cell colours.
      use Glib, Gtk.Grid, Gtk.Enums, Gtk.Drawing_Area;
      -- use Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
      use String_Conversions;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details=> "Set_Writing_Colours: Start");
      blank_background_colour := for_blank_background;
      used_background_colour  := for_used_background;
      pen_colour              := for_text;
   end Set_Writing_Colours;

   procedure Set_Writing_Size(height, width : natural) is
      -- Set up the writing cell size to that specified and attach the font
      -- to the writing area.
      use Glib, Gtk.Grid, Gtk.Enums, Gtk.Drawing_Area, Gtk.Widget; --, Gtk.Menu;
      writing_area : Gtk.Drawing_Area.gtk_drawing_area;
      -- the_menu     : Gtk.Menu.Gtk_Menu;
      requisition  : Gtk_Requisition;
      the_font     : Pango.Font.Pango_Font_Description :=
                                         Pango.Font.Pango_Font_Description_New;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details=> "Set_Writing_Size: Start");
      Pango.Font.Set_Family(the_font, Setup.The_Font);
      cell_width  := width;
      cell_height := height;
      for col in 0 .. column_count-1 loop
         for row in 0 .. row_count-1 loop
            writing_area:= gtk_drawing_area(Get_Child_At(the_grid, 
                                                         Gint(col),Gint(row)));
            if writing_area /= null then
               -- Set up the size
               Set_Size_Request(writing_area, Gint(cell_width), 
                                              Gint(cell_height));
               -- Set up the font
               Override_Font(writing_area, the_font);
               -- Force a cell redraw to resize
               Size_Request(writing_area, requisition);
            else
               Error_Log.Debug_Data(at_level => 6, 
                         with_details=> "Set_Writing_Size: did not find cell");
            end if;
         end loop;
      end loop;
   --    -- And set it for the pop-up menu
      -- the_menu := Gtk_Menu(Get_Object(the_builder, "menu_alternatives"));
      -- Override_Font(the_menu, the_font);
   end Set_Writing_Size;

begin
   Cell_Writer_Version.Register(revision => "$Revision: v1.0.0$",
                                for_module => "Grid_Management");
end Grid_Management;
