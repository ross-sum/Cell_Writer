-----------------------------------------------------------------------
--                                                                   --
--                          A V E R A G E S                          --
--                                                                   --
--                              B o d y                              --
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

-- with Vectors;
-- with Samples;           use Samples;
-- with Sample_Comparison; use Sample_Comparison;
-- with Training_Samples;  use Training_Samples;
-- with Stroke_Management;
with Ada.Containers;
with Ada.Numerics.Elementary_Functions;
with Error_Log;
with dStrings;          use dStrings;
with Cell_Writer_Version;
package body Averages is
   use Vectors;
   use Stroke_Management;
   use Comparisons_Arrays;

   -- engine_ave_dist: natural;
   -- num_disqualified : natural := 0;

   procedure Engine_Average(input_sample: in Samples.input_sample_type;
                            input_penalty : in out float;
                            dist_range, angle_range : natural;
                            angle_scale : in out integer) is
      use Strokes_Arrays;
      -- Computes average distance and angle differences between the input
      -- sample and each training sample that has been flagged as a candidate
      -- by the preparation pre-processor engine.
      use Training_Samples;
      the_sample : training_sample;
   begin
      Error_Log.Debug_Data(at_level => 6, 
                           with_details=> "Engine_Average: Start");
      num_disqualified := 0;
      if dist_range /= 0 or angle_range /= 0
      then
         -- Average angle engine needs to be discounted when the input
         -- contains segments too short to produce meaningful angles
         angle_scale := 0;
         for i in input_sample.strokes.First_Index .. 
                             input_sample.strokes.Last_Index loop
            if input_sample.strokes(i).spread >= dot_spread then
               angle_scale := angle_scale + 1;
            end if;
         end loop;
         if natural(input_sample.strokes.Length) > 0 then
            angle_scale := angle_scale * maximum_strokes / 
                           natural(input_sample.strokes.Length);
         -- noting that engine_scale = maximum_strokes, so rather than deal
         -- with yet another global variable pass, and noting that Michael
         -- just equates engine_scale to maximum_strokes, just use that.
         else -- This could be an issue
            Error_Log.Put(the_error => 44,
                       error_intro => "Engine_Average error", 
                       error_message=>"Attempted to divide by zero-length " &
                                      "input sample stroke");
         end if;
      
         -- Run the averaging engine for the sample against every training
         -- sample that has passed prequalification by the prep engine.
         for smpl_no in training_comparisons.First_Index ..
                     training_comparisons.Last_Index loop
            the_sample := Deliver_The_Sample(at_index => 
                                  training_comparisons(smpl_no).sample_number);
            Sample_Average(against_input_sample => input_sample, 
                           the_sample => training_comparisons(smpl_no),
                           for_training_sample => the_sample,
                           dist_range=>dist_range, angle_range=>angle_range);
         end loop;
      else
         Error_Log.Debug_Data(at_level => 9, with_details=> "Engine_Average: distance range and angle range for the engine are 0 at the start, so not processing here.");
      end if;
   end Engine_Average;
   
   function Measure_the_Angle
     (a : in Stroke;
      i : integer;
      b : in Stroke;
      j : integer;
      offset : point) return float is
      -- Measure the lesser angular difference between two segments, namely
      -- between the point at a(i) and the point at b(j).
      -- This function ignores the offset, which must be provided so that the
      -- function is compatible with the template for the function and
      -- therefore can be passed as a parameter.
      result : float;
   begin
      -- Error_Log.Debug_Data(at_level => 8, 
         --                   with_details=> "Measure_the_Angle: Start");
      result := abs (a.angles(i) - b.angles(j));
      -- Make sure the angle is within range (it should be, but just in case)
      while result > 360.0 loop
         result := result - 360.0;
      end loop;
      return result;  -- must be positive because it is really an angle 0..360°
   end Measure_the_Angle;

   procedure Stroke_Average(a : stroke; b : stroke; 
                            pdist : out float;
                            pangle : out angle; ac_to_bc : point;
                            dist_range, angle_range : in natural) is
       -- Compute the average measures for A versus B
       -- NOTE: dist_range is a jump variable spagetti code that Michael
       --       extracted directly from engines[ENGINE_AVGDIST].range in his
       --       code, similarly angle_range is from
       --       engines[ENGINE_AVGANGLE].range.
      use Ada.Containers, Stroke_Management.Points_Arrays;
      a_sampled,
      b_sampled  : stroke;
      null_point : point;
   begin
      Error_Log.Debug_Data(at_level => 8, 
                           with_details=> "Stroke_Average: Start");
      -- Default values for return results
      pdist := 0.0;
      pangle := 0.0;
      if a.points.Length < 1 or b.points.Length < 1 then
         Error_Log.Put(the_error => 45,
                       error_intro => "Stroke_Average error", 
                       error_message=>"Attempted to measure zero-length stroke");
         return;
      end if;
      --  Sample strokes to equal lengths
      Sample_Strokes (a => a, b => b, as => a_sampled, bs => b_sampled);
      
      -- Average the distance between the corresponding points
      if dist_range > 0 then
         pdist:= Measure_Strokes(a => a_sampled,
                                 b => b_sampled,
                                 Func => Measure_Distance'Access,
                                 extra => ac_to_bc,
                                 points=>point_range(a_sampled.points.Length),
                                 elasticity => fine_elasticity);
      end if;
      
      -- We cannot run angle averages if one of the two strokes has no
      -- segments.
      if a.spread < dot_spread
      then
         pangle := 0.0;
      elsif b.spread < dot_spread
      then
         pangle := 180.00;  -- π in °
      else
         --  Average the angle differences between the points
         if angle_range > 0 then
            pangle:= Measure_Strokes(a => a_sampled,
                                     b => b_sampled,
                                     Func => Measure_the_Angle'Access,
                                     extra => null_point,
                                     points=> a_sampled.angles.Last_index,
                                     elasticity => fine_elasticity);
         end if;
      end if;
   end Stroke_Average;

   procedure Sample_Average(the_sample : in out comparison_information;
                            against_input_sample: in Samples.input_sample_type; 
                            for_training_sample : in training_sample;
                            dist_range, angle_range : in natural) is
      -- Take the distance between the input and the sample, enumerating the best
      -- match assignment between input and sample strokes.
      -- TODO scale the measures by stroke distance
      use Ada.Numerics.Elementary_Functions, Ada.Containers;
      the_input   : Samples.input_sample_type renames against_input_sample;
      trg_sample  : training_sample renames for_training_sample;
      rating_max  : constant float := float(Samples.rating_maximum);
      ic_to_sc    : point;       -- centre between input and trg sample centres
      smaller     : sample_type;
      distance    : float := 0.0;
      m_dist      : float := 0.0;
      m_angle     : float := 0.0;  -- note: this is a score that can be >> 360°
   begin
      -- Error_Log.Debug_Data(at_level => 7, 
         --                   with_details=> "Sample_Average: Start");
      -- Ignore disqualified samples
      if the_sample.disqualified then
         num_disqualified := num_disqualified + 1;
         return;
      end if;
      
      -- Adjust for the difference between sample centres
      ic_to_sc := Centre_of_Samples(a => the_input, b => sample_type(trg_sample));
      
      -- Run the averages
      if the_input.strokes.Length < trg_sample.strokes.Length
      then
         smaller := the_input;
      else
         smaller := sample_type(trg_sample);
      end if;
      for stroke_num in  smaller.strokes.First_Index .. 
                             smaller.strokes.Last_Index loop
         declare
            input_stroke  : stroke;
            sample_stroke : stroke;
            weight        : float;
            s_distance    : float := float(maximum_sdistance);
            s_angle       : angle := 180.0;  -- π in °
         begin
            -- Transform strokes, mapping the larger sample onto the
            -- smaller one.  The result is two strokes of the same length
            -- and transformed to give a comparison point.
            if the_input.strokes.Length >= trg_sample.strokes.Length
            then  -- transform input's strokes down to sample's length
               input_stroke := Transform_Stroke(src=> the_input,
                                                tfm=> the_sample.the_transform,
                                                at_stroke  => stroke_num);
               sample_stroke:= trg_sample.strokes(stroke_num);
            else  -- transform sample's strokes down to input's length
               input_stroke := the_input.strokes(stroke_num);
               sample_stroke:= Transform_Stroke(src=> sample_type(trg_sample),
                                                tfm=> the_sample.the_transform,
                                                at_stroke => stroke_num);
            end if;
            if smaller.strokes(stroke_num).spread < dot_spread
            then
               weight := dot_spread;
            else
               weight := smaller.strokes(stroke_num).distance;
            end if;
            -- Compute the distance and angle scores for the average for
            -- this stroke
            Stroke_Average(a => input_stroke, b => sample_stroke, 
                           pdist => s_distance, 
                           pangle => s_angle, 
                           ac_to_bc => ic_to_sc,
                           dist_range=> dist_range, 
                           angle_range=> angle_range);
            m_dist  := m_dist + s_distance * weight;  -- add in dstnce score
            m_angle := m_angle + s_angle * weight;    -- add in angle score
            distance := distance + weight;   -- tally up the total distance
         end;
      end loop;
      
      -- Undo square distortion and account for multiple strokes
      m_dist  := Sqrt(m_dist) / distance;
      m_angle := m_angle / distance;
      --  Check limits
      if m_dist > float(maximum_sdistance) then
         m_dist := float(maximum_sdistance);
      end if;
      if m_angle > 180.0 then
         m_angle := 180.0;  -- here we trim the score back to <= 180°
      end if;
      -- Assign the ratings
      the_sample.ratings(engine_ave_dist) := integer(
                         rating_max - rating_max * m_dist / measure_dist);
      the_sample.ratings(engine_ave_angle):= integer(
                         rating_max - rating_max * m_angle / measure_angle);
      Error_Log.Debug_Data(at_level => 9, with_details=> "Sample_Average: ratings results - Average distance rating = " & Put_Into_String(the_sample.ratings(engine_ave_dist)) & ", average angle rating = " & Put_Into_String(the_sample.ratings(engine_ave_angle)) & ".");
   end Sample_Average;

begin
   Cell_Writer_Version.Register(revision => "$Revision: v1.0.0$",
                                for_module => "Averages");
   Sample_Comparison.
      Register(engine_data  => (name         => Value("Average distance"),
                                func         => Engine_Average'access,
                                e_range      => maximum_range,
                                ignore_zeros => TRUE,
                                scale        => -1,
                                average      => 0,
                                max          => 0 ),
               with_id       => engine_ave_dist);
   Sample_Comparison.
      Register(engine_data  => (name         => Value("Average angle"),
                                func         => NULL, -- actually Engine_Average
                                e_range      => maximum_range,
                                ignore_zeros => TRUE,
                                scale        => 0,
                                average      => 0,
                                max          => 0 ),
               with_id       => engine_ave_angle);
end Averages;
