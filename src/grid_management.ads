-----------------------------------------------------------------------
--                                                                   --
--                   G R I D   M A N A G E M E N T                   --
--                                                                   --
--                     S p e c i f i c a t i o n                     --
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
with Gtkada.Builder;  use Gtkada.Builder;
with Gdk.RGBA;
with GNATCOLL.SQL.Exec;
package Grid_Management is

   type cell_flag_types is (cell_unset, cell_show_ink, cell_dirty, 
                            cell_verified, cell_shifted);

   procedure Initialise_Grid(Builder : in out Gtkada_Builder;
                             DB_Descr: GNATCOLL.SQL.Exec.Database_Description);
   procedure Resize_Grid (to_rows, to_cols : natural);
     -- Resize the grid of writing cells such that it becomes <to_rows> deep
     -- by <to_cols> wide.
      -- Rows and columns passed in are one (1) based, but the grid is zero (0)
      -- based.
   procedure Set_Writing_Size(height, width : natural);
      -- Set up the writing cell size to that specified.
   procedure Set_Writing_Colours(for_text, for_blank_background, 
                                 for_used_background : Gdk.RGBA.Gdk_RGBA);
      -- Set up the writing cell colours and make sure that the writing area is
      -- at the front.

end Grid_Management;
