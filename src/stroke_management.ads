-----------------------------------------------------------------------
--                                                                   --
--                            S T R O K E                            --
--                                                                   --
--                     S p e c i f i c a t i o n                     --
--                                                                   --
--                           $Revision: 1.0 $                        --
--                                                                   --
--  Copyright (C) 2022  Hyper Quantum Pty Ltd.                       --
--  Written by Ross Summerfield.                                     --
--                                                                   --
--  This  package manages the strokes for hand writing recognition.  --
--  It  is  a translation of the stroke.c package to  Ada  that  is  --
--  Copyright (C) 2007 Michael Levin <risujin@gmail.com>             --
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
with dStrings; -- use dStrings;
with Vectors;  use Vectors;
with Ada.Containers.Vectors;
package Stroke_Management is
   
   -- Key Error Exceptions
   NO_POINTS_ERROR  : exception;
   NO_STROKES_ERROR : exception;
   
   -- Stroke data
   subtype point_range is integer range -255 .. 512;        -- M. LEVIN: 256;
   subtype positive_point_range  is point_range range 1 .. point_range'Last;

   -- Maximum number of points a stroke can have
   maximum_points : constant point_range := point_range'Last;
   -- Scale of the point coordinates
   point_scale : constant point_range := point_range'Last;
         -- External_Name => "SCALE"
   maximum_sdistance : constant integer := 362; -- sqrt(2) * point_scale
         --  External_Name => "MAX_DIST"
  
  -- Minimum stroke spread distance for angle measurements 
   dot_spread : constant float := float(point_scale) / 10.0;
         -- External_Name => "DOT_SPREAD"

   -- Maximum number of strokes a sample can have */
   maximum_strokes : constant point_range := 32;
         -- External_Name => "STROKES_MAX"
         -- Also: #define ENGINE_SCALE STROKES_MAX
   subtype strokes_list_range is point_range range 0 .. maximum_strokes;
   
   -- Largest value the gluable matrix entries can take
   maximum_gluable_entries : constant point_range := 255;
       -- External_Name => "GLUABLE_MAX"
   type gluable_entries is array (strokes_list_range'Range) of point_range;

   -- Define the points and angles for setting up an open-ended array
   -- of points (and of angles).
   package Points_Arrays is new Ada.Containers.Vectors
         (index_type   => natural,
          element_type => point);
   package Angles_Arrays is new Ada.Containers.Vectors
         (index_type   => natural,
          element_type => angle);
   subtype points_array is Points_Arrays.vector;
   subtype angles_array is Angles_Arrays.vector;

   type Stroke is record
         centre        : point;
         distance      : float;
         spread        : float;
         processed     : boolean;
         gluable_start : gluable_entries := (others => 0);
         gluable_end   : gluable_entries := (others => 0);
         min           : point;
         max           : point;
         points        : points_array;
         angles        : angles_array;
      end record;

     -- Stroke allocation  
   function New_Stroke return Stroke;  -- ./recognize.h:56
      -- External_Name => "stroke_new";
      -- Initialise the stroke, setting the size (by default set to 
      -- points_granualarity).

   function Clone(the_stroke : in stroke; in_reverse : boolean) return stroke;
         -- External_Name => "stroke_clone";

   procedure Free(the_stroke : in out Stroke);  -- ./recognize.h:58
         -- External_Name => "stroke_free";

   procedure Clear(the_stroke : in out Stroke);  -- ./recognize.h:59
         -- External_Name => "clear_stroke";

  -- Stroke manipulation  
   procedure Process(the_stroke : in out Stroke);  -- ./recognize.h:62
         -- External_Name => "process_stroke";
     -- Generate cached parameters of a stroke

   procedure Add (a_point : point; to_the_stroke : in out stroke);
     -- Add a point in scaled coordinates to a stroke

   procedure Smooth(the_stroke : in out Stroke);  -- ./recognize.h:64
         -- External_Name => "smooth_stroke";
     -- Smooth stroke points by moving each point halfway toward the line
     -- between its two neighbours

   procedure Simplify(the_stroke : in out Stroke);  -- ./recognize.h:65
         -- External_Name => "simplify_stroke";

   function ReSample (the_stroke    : stroke;
                      num_of_points : point_range;
                      with_size     : point_range) return stroke;  -- ./recognize.h:66
         -- External_Name => "sample_stroke";
      -- Recreate the stroke by sampling at regular distance intervals.
      -- Sampled strokes always have angle data.
      -- In recreating the stroke, ensure that the stroke is of the specified
      -- number of points at a regular spacing, as guided by 'with_size'.
      -- (In actual fact, the number of points is the lesser of 'num_of_points'
      -- and 'with_size', after each has had some range (.i.e. sanity) checks
      -- applied to their values.)

   procedure Sample_Strokes (a, b : in stroke;
                             as, bs : out stroke);  -- ./recognize.h:67
         -- External_Name => "sample_strokes";
      -- Sample multiple strokes to equal lengths

   procedure Glue (the_stroke : in Stroke;
                   to : in out stroke;
                   in_reverse : boolean);  -- ./recognize.h:68
         -- External_Name => "glue_stroke";
      -- Glue 'the_stroke' onto the end of 'to' preserving processed properties

   procedure Dump(the_stroke : in Stroke);  -- ./recognize.h:69
        -- External_Name => "dump_stroke";
  
  -- Generalised measure function  
   type MeasureFunc is access function
        (arg1 : stroke;
         arg2 : integer;
         arg3 : stroke;
         arg4 : integer;
         arg5 : point) return float;
      -- with Convention => C;  -- ./recognize.h:109

   function Measure_Distance
     (a : in Stroke;
      i : integer;
      b : in Stroke;
      j : integer;
      offset : point) return float;  -- ./recognize.h:118
         -- External_Name => "measure_distance";
      -- Measure the (square of) offset Euclidean distance between two points

   function Measure_Strokes
     (a : in Stroke;
      b : in Stroke;
      Func : MeasureFunc;
      extra : point;
      points : point_range;
      elasticity : integer) return float;  -- ./recognize.h:120
         -- External_Name => "measure_strokes";
      -- Find optimal match between A points and B points for lowest distance
      -- via dynamic programming

private 

   points_granularity : constant point_range := 64;
     --Granularity of stroke point array in points
     
   -- Fine sampling parameters
   fine_resolution : constant float := 8.0;

   -- Distance from the line formed by the two neighbors of a point, which, if
   -- not exceeded, will cause the point to be culled during simplification
   simplify_threshold : constant float := 0.1;  -- M. LEVIN: 0.5;
     
   procedure Reverse_Copy_Points(from: in stroke; to: in out stroke;
                                 append : in boolean := false);
     -- reverse copy the points and angles from one stroke to another.
     
end Stroke_Management;
