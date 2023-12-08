-----------------------------------------------------------------------
--                                                                   --
--                          A V E R A G E S                          --
--                                                                   --
--                     S p e c i f i c a t i o n                     --
--                                                                   --
--                           $Revision: 1.0 $                        --
--                                                                   --
--  Copyright (C) 2022  Hyper Quantum Pty Ltd.                       --
--  Written by Ross Summerfield.                                     --
--                                                                   --
--  This package manages the averaging for hand writing recognition.  --
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
with Vectors;
with Samples;           use Samples;
with Sample_Comparison; use Sample_Comparison;
with Training_Samples;  use Training_Samples;
with Stroke_Management;
package Averages is

   engine_ave_dist: natural; -- one of our engine identifiers (set by Register)
   num_disqualified : natural := 0;
 
   procedure Engine_Average(input_sample: in Samples.input_sample_type;
                            input_penalty : in out float;
                            dist_range, angle_range : natural;
                            angle_scale : in out integer);
      -- Computes average distance and angle differences between the input
      -- sample and each training sample that has been flagged as a candidate
      -- by the preparation pre-processor engine.

  private
   use Vectors;
   use Stroke_Management;
  
   engine_ave_angle: natural;  -- our engine identifier (set by Register)
   
   -- Maximum measures
   measure_dist  : constant float := float(Stroke_Management.maximum_sdistance);
   measure_angle : constant Vectors.Angle := 180.0 / 4.0; -- (PI / 4);
   
   function Measure_the_Angle
     (a : in Stroke;
      i : integer;
      b : in Stroke;
      j : integer;
      offset : point) return float;
      --  Measure the lesser angular difference between two segments
  
   procedure Stroke_Average(a : stroke; b : stroke; pdist : out float;
                            pangle : out angle; ac_to_bc : point;
                            dist_range, angle_range : in natural);
      -- Compute the average measures for A vs B
   
   procedure Sample_Average(the_sample : in out comparison_information;
                            against_input_sample: in Samples.input_sample_type;
                            for_training_sample : in training_sample;
                            dist_range, angle_range : in natural);
      -- Take the distance between the input and the sample, enumerating the best
      -- match assignment between input and sample strokes.
      -- TODO scale the measures by stroke distance
  
end Averages;
