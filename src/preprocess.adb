-----------------------------------------------------------------------
--                                                                   --
--                        P R E P R O C E S S                        --
--                                                                   --
--                              B o d y                              --
--                                                                   --
--                           $Revision: 1.0 $                        --
--                                                                   --
--  Copyright (C) 2022  Hyper Quantum Pty Ltd.                       --
--  Written by Ross Summerfield.                                     --
--                                                                   --
--  This package manages the pre-processor for hand writing recognition.  --
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

-- with Vectors;           use Vectors;
-- with Stroke_Management; use Stroke_Management;
-- with Samples;           use Samples;
-- with Sample_Comparison; use Sample_Comparison;
-- with Training_Samples;  use Training_Samples;
with Ada.Containers;
with Ada.Numerics.Elementary_Functions;
with dStrings;          use dStrings;
with Error_Log;
with Generic_Binary_Trees_With_Data;
with Setup;
with Cell_Writer_Version;  
package body Preprocess is
   use Stroke_Management.Points_Arrays, Stroke_Management.Angles_Arrays;
   use Comparisons_Arrays;
   -- prep_examined : natural := 0;

   package Handle_Lists is new  
              Generic_Binary_Trees_With_Data(T => integer, D =>handle_type, 
                                              "<" => LessThan);
       -- Create a list that is (automatically) sorted by sample rating (which
       -- is of type integer ad the handle is of type natural, a subtype of
       -- integer).

   function LessThan(a, b : in integer) return boolean is
      -- For the list of handles dynamic list for the Engine_Prep procedure
   begin
      return a > b;  -- Sort from biggest (higher rating) to smallest
   end LessThan;
    
   procedure Engine_Prep(input_sample: in Samples.input_sample_type;
                         input_penalty : in out float;
                         unused_1, unused_2 : natural;
                         unused_3 : in out integer) is
      -- The engine preparation of the sample (pre-)processor
      use Handle_Lists;
      handles    : Handle_Lists.list;
      the_sample : training_sample;
      prepared   : boolean;
      sample_num : natural := 1;
   begin
      Error_Log.Debug_Data(at_level => 6, with_details=> "Engine_Prep: Start");
      --  Rate every sample in every possible configuration
      prep_examined := 0;
      for smpl_no in training_comparisons.First_Index ..
                     training_comparisons.Last_Index loop
         the_sample := Deliver_The_Sample(at_index => 
                                  training_comparisons(smpl_no).sample_number);
         training_comparisons(smpl_no).disqualified := true;  -- default state
         Prepare(the_sample => training_comparisons(smpl_no), 
                 for_training_sample => the_sample,
                 with_success => prepared,
                 against_input_sample => input_sample,
                 for_input_penalty  => input_penalty);
         if prepared then
             -- Sort sample into the list by rating for this engine_prep_id
            Insert(into => handles, 
                   the_index=>training_comparisons(smpl_no).ratings(engine_prep_id),
                   the_data => (h=>smpl_no));
         end if;
         Next_Sample;
      end loop;
      -- Qualify the best samples (i.e. the first 'prep_samples' samples)
      First(in_the_list => handles);
      while sample_num<=prep_samples and not Is_End(of_the_list=> handles) loop
         training_comparisons(Deliver_Data(from_the_list=>handles).h).
                                                         disqualified := false;
         Next(in_the_list => handles);
         sample_num := sample_num + 1;
      end loop;
      Clear(the_list => handles);
      Error_Log.Debug_Data(at_level => 9, with_details=> "Engine_Prep: End");
   end Engine_Prep;

   function Measure_Partial(as, b : stroke; offset : point; scale_b : float) 
   return float is
      use Ada.Containers;
       -- Trim the stroke b to be the same as the sample stroke a viz Resample
       -- then Measure the two strokes using the Measure_Distance function.
      bs : stroke;
      the_result : float;
      b_length   : point_range;
      min_length : point_range;
   begin
      Error_Log.Debug_Data(at_level => 7, with_details=> "Measure_Partial: Start");
      b_length := point_range(b.distance * scale_b / rough_resolution + 0.5);
      if b_length < 4
      then
         b_length := 4;
      end if;
      if point_range(as.points.Length) >= b_length
      then
         min_length := b_length;
      else
         min_length := point_range(as.points.Length);
      end if;
      bs := ReSample (the_stroke => b, 
                      num_of_points => b_length, with_size => min_length);
      the_result := Measure_Strokes(a => as, b => bs, 
                                    func => Measure_Distance'Access,
                                    extra => offset,
                                    points => min_length,
                                    elasticity => rough_elasticity);
      Free(the_stroke => bs);
      return the_result;
   end Measure_Partial;
    
   procedure Greedy_Map(larger, smaller : in sample_type; 
                        ptform : out transform;
                        offset : in point; 
                        larger_penalty, smaller_penalty : in out float;
                        result : out float) is
       -- Strokes within a character may be drawn backwards relative to the
       -- training sample, in a different order, or connected together.
       -- This function is a corrective process to account for these variations
       -- by ‘mapping’ one sample to another.
       -- This greedy mapping algorithm, which accounts for variability,
       -- augments the elastic mapping to provide the underlying recognition
       -- mechanism.
       -- A mapping is always made from the sample with more strokes to the
       -- sample with less strokes and describes the order of the strokes,
       -- whether any strokes are reversed, and what order to glue together any
       -- strokes in the larger sample so that its strokes are correctly mapped
       -- to those in the smaller sample.
      use Strokes_Arrays, Setup;
      tfm             : transform;
      unmapped_length : strokes_list_range := 
                                     strokes_list_range(larger.strokes.Length);
      glue_more       : boolean;
      measure         : boolean;
      total           : float := 0.0;
   begin
      Error_Log.Debug_Data(at_level => 7, with_details=> "Greedy_Map: Start");
      --  Prepare transform structure
      Clear(the_transform => tfm);
      ptform := tfm;
      tfm.valid := true;
      -- Try paring down the number of larger strokes to match the number of
      -- smaler strokes, so loop through each smaller stroke to see if we can
      For_Each_Smaller_Stroke :
      for i in smaller.strokes.First_Index .. smaller.strokes.Last_Index loop
         declare
            best        : float;
            best_reach  : float := float'Last;
            best_value  : float := float'Last;
            value       : float;
            penalty     : float := float'Last;
            seg_dist    : float := 0.0;
            last_j      : strokes_list_range := 
                                strokes_list_range(larger.strokes.First_Index);
            best_j      : natural := last_j;
            glue_level  : natural := 0;
            the_stroke  : stroke;
            reach       : float;
            scale       : float;
            the_gluable : point_range;
            the_gluable2: point_range;
            skip_rest_of_this_processing_loop : boolean;
         begin
            glue_more := true;
            While_Gluing_More :
            while glue_more loop
               glue_more := false;  -- at the moment this could be true
               best := float'Last;
               For_Each_Larger_Stroke :
               for j in larger.strokes.First_Index .. 
                             larger.strokes.Last_Index loop
                  Clear(the_stroke);
                  if tfm.order(j) = 0 then
                     tfm.in_reverse(j) := false;
                  end if;
                     --  Do not glue on oversize segments
                  if tfm.order(j) = 0 and then not
                     ((seg_dist + larger.strokes(j).distance / 2.0) > 
                                                smaller.strokes(i).distance and
                      (larger.strokes(j).spread > dot_spread or
                       smaller.strokes(i).spread > dot_spread))
                  then  -- not oversized and dealing with empty order(j)
                     tfm.order(j) := (i - smaller.strokes.First_Index) + 1;
                     tfm.glue(j)  := glue_level;
                     
                     measure := true;
                     While_Measuring :
                     while measure loop
                        measure := false;  -- at the moment this could be true
                        reach := 0.0;
                        the_gluable := 0;
                        skip_rest_of_this_processing_loop := false;
                        if glue_level > 0 then
                           -- Can we glue these strokes together?
                           if not tfm.in_reverse(j) then
                              the_gluable := larger.strokes(j).gluable_start(last_j);
                              the_gluable2:= larger.strokes(last_j).gluable_end(j);
                              if the_gluable2 < the_gluable then
                                 the_gluable := the_gluable2;
                              end if;
                              if the_gluable >= maximum_gluable_entries then
                                 if not Setup.Ignore_Stroke_Direction
                                 then  -- no further processing this loop
                                    skip_rest_of_this_processing_loop := true;
                                 else  -- check in reverse
                                    tfm.in_reverse(j) := true;
                                 end if;
                              end if;
                           end if;
                           if (not skip_rest_of_this_processing_loop) and 
                              tfm.in_reverse(j)
                           then  -- do in-reverse checking
                              the_gluable := larger.strokes(j).gluable_end(last_j);
                              the_gluable2:= larger.strokes(last_j).gluable_start(j);
                              if the_gluable2 < the_gluable then
                                 the_gluable := the_gluable2;
                              end if;
                              if the_gluable >= maximum_gluable_entries 
                              then  -- no more calcs this loop
                                 skip_rest_of_this_processing_loop := true;
                              end if;
                           end if;
                           if not skip_rest_of_this_processing_loop 
                           then  -- further processing required
                              --  Get the inter-stroke (reach) distance
                              declare
                                 p1, p2 : point;
                              begin  -- Assume Michael means the following???
                                 if tfm.in_reverse(last_j)
                                 then
                                    p1 := larger.strokes(last_j).
                                         points(larger.strokes(last_j).points.First_Index);
                                 else
                                    p1 := larger.strokes(last_j).
                                          points(larger.strokes(last_j).points.Last_Index);
                                 end if;
                                 if tfm.in_reverse(j)
                                 then
                                    p2 := larger.strokes(j).
                                          points(larger.strokes(j).points.Last_Index);
                                 else
                                    p2 := larger.strokes(j).
                                         points(larger.strokes(j).points.First_Index);
                                 end if;
                                 reach := Magnitude(The_Vector(p1, p2));
                              end;
                           end if;  -- not skip_rest_of_this_processing_loop
                        end if;  -- glue_level > 0
                        if not skip_rest_of_this_processing_loop then
                           -- Transform and measure the distance
                           the_stroke := Transform_Stroke(src => larger, 
                                                          tfm => tfm,
                                                          at_stroke => i);
                           scale := smaller.distance /
                                    (reach + ptform.reach + larger.distance);
                           value := Measure_Partial(as    => smaller.roughs(i),
                                                    b     => the_stroke, 
                                                    offset=> offset, 
                                                    scale_b=> scale);
                           -- Keep track of the best result
                           if value < best and value < value_max then
                              best := value;
                              best_j := j;
                              best_reach := reach;
                              ptform := tfm;
                              -- Penalise glue and reach distance
                              penalty := float(glue_level) * glue_penalty +
                                         float(the_gluable) * gluable_penalty /
                                         float(maximum_gluable_entries);
                           end if;
                           -- Bail if we have a really good match
                           if value < value_min then
                              exit For_Each_Larger_Stroke;
                           end if;
                           -- Glue on with reversed direction
                           if not Ignore_Stroke_Direction and not tfm.in_reverse(j) and
                              larger.strokes(j).spread > dot_spread
                           then
                              tfm.in_reverse(j) := true;
                              measure := true;   -- measure again
                           else
                              tfm.in_reverse(j) := false;
                              tfm.order(j) := 0;
                           end if;
                        end if;  -- not skip_rest_of_this_processing_loop
                     end loop While_Measuring;
                  end if;
               end loop For_Each_Larger_Stroke;
               if best < float'last
               then
                  best_value := best;
                  larger_penalty  := larger_penalty + penalty;
                  smaller_penalty := smaller_penalty + penalty;
                  seg_dist := seg_dist + best_reach +
                              larger.strokes(best_j).distance;
                  ptform.reach := ptform.reach + best_reach;
                  tfm := ptform;
                  -- If we still have strokes and we didn't just add on
                  -- a dot, try gluing them on
                  unmapped_length := unmapped_length - 1;
                  if unmapped_length >= natural(smaller.strokes.Length) - i and
                     larger.strokes(best_j).spread > dot_spread
                  then
                     last_j := best_j;
                     glue_level := glue_level + 1;
                     glue_more := true;
                  end if;
               elsif glue_level = 0
               then  -- Didn't map a target stroke
                  ptform.valid := false;
                  result := float'last;
                  return;
               end if;
            end loop While_Gluing_More;
            total := total + best_value; 
         end;
      end loop For_Each_Smaller_Stroke;
      --  Didn't assign all of the strokes?
      if unmapped_length > 0 then
         ptform.valid := false;
         result := float'last;
      else
         result := total / float(smaller.strokes.Length);
      end if;
      Error_Log.Debug_Data(at_level => 9, with_details=> "Greedy_Map: End");
   end Greedy_Map;
    
   procedure Prepare(the_sample : in out comparison_information; 
                     for_training_sample : in training_sample;
                     with_success : out boolean;
                     against_input_sample : in Samples.input_sample_type;
                     for_input_penalty : in out float) is
       -- 
      use Ada.Numerics.Elementary_Functions, Ada.Containers;
      input_sample : input_sample_type renames against_input_sample;
      trg_sample   : training_sample renames for_training_sample;
      offset       : point;
      distance     : float;
   begin
      Error_Log.Debug_Data(at_level => 7, 
                           with_details=> "Prepare(the_sample): Start");
      with_success := false;  -- Default result (until we get to the end)
      -- Structural disqualification
      if (Setup.Match_Differing_Stroke_Numbers and 
          trg_sample.strokes.Length /= input_sample.strokes.Length) then
         return;
      end if;
      prep_examined := prep_examined + 1;
      the_sample.penalty := 0.0;
      -- Account for displacement
      offset := Centre_of_Samples(a => sample_type(trg_sample), b => input_sample);
      -- Compare each input stroke to every stroke in the sample and
      -- generate the stroke order information which will be used by other
      -- engines.
      declare
         ip_penalty   : float := for_input_penalty;
         smpl_penalty : float := the_sample.penalty;
      begin
         if input_sample.strokes.Length >= trg_sample.strokes.Length
         then
            Greedy_Map(larger=> input_sample, smaller=>sample_type(trg_sample),
                       ptform=> the_sample.the_transform,
                       offset=> offset,
                       larger_penalty => ip_penalty, 
                       smaller_penalty => smpl_penalty,
                       result=> distance);
         else
            offset := -offset;
            Greedy_Map(larger=> sample_type(trg_sample), smaller=>input_sample,
                       ptform=> the_sample.the_transform,
                       offset=> offset,
                       larger_penalty => smpl_penalty, 
                       smaller_penalty => ip_penalty,
                       result=> distance);
         end if;
         -- set the penalty variable for the training sample to that specified.
         the_sample.penalty := smpl_penalty;
         -- set the penalty variable for the input sample to that specified.
         for_input_penalty    := ip_penalty;
      end;         
      if not the_sample.the_transform.valid then
         return;
      end if;
      -- Undo square distortion and check the distance between the input (test)
      -- sample and the training sample that it was compared against is not too
      -- great
      distance := Sqrt(distance);
      if distance <= float(maximum_sdistance)
      then
      -- Penalise vertical displacement
         the_sample.penalty := the_sample.penalty + 
                                 vertical_penalty * (Y(offset) * Y(offset)) /
                                              float(point_scale * point_scale);
         the_sample.ratings(engine_prep_id) := rating_maximum -
                                             integer(float(rating_maximum) * 
                                          distance / float(maximum_sdistance));
         with_success := true;
         Error_Log.Debug_Data(at_level => 9, with_details=> "Prepare(the_sample): End - success = true, rating(engine_prep_id) = " & Put_Into_String(the_sample.ratings(engine_prep_id)) & ".");
      end if;
   end Prepare;
    

begin
   Cell_Writer_Version.Register(revision => "$Revision: v1.0.0$",
                                for_module => "Preprocess");
   Sample_Comparison.
      Register(engine_data  => (name         => Value("Key-point distance"), 
                                func         => Engine_Prep'access,
                                e_range      => maximum_range,
                                ignore_zeros => TRUE,
                                scale        => -1,
                                average      => 0,
                                max          => 0 ),
               with_id       => engine_prep_id,
               must_be_first => true);
end Preprocess;
