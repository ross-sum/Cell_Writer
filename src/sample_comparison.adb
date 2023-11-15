-----------------------------------------------------------------------
--                                                                   --
--                 S A M P L E   C O M P A R I S O N                 --
--                                                                   --
--                              B o d y                              --
--                                                                   --
--                           $Revision: 1.0 $                        --
--                                                                   --
--  Copyright (C) 2022  Hyper Quantum Pty Ltd.                       --
--  Written by Ross Summerfield.                                     --
--                                                                   --
--  This  package does the comparison of the test sample  that  was  --
--  input  by  the  user  against  the  training  samples.   It  is  --
--  principally  used  by the Recogniser and its components  to  do  --
--  recongition.   This package is mainly the data  types  required  --
--  for recongition along with any supporing management  procedures  --
--  or functions.                                                    --
--  It  is a reinterpretation of a translation of the  recognizer.c  --
--  package  to  Ada  that  is  Copyright (C)  2007  Michael  Levin  --
--  <risujin@gmail.com>                                              --
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
-- with dStrings;            use dStrings;
-- with Stroke_Management;   use Stroke_Management;
-- with Samples;
-- with Ada.Containers.Vectors;
with Error_Log;
with Cell_Writer_Version;
with Training_Samples;    use Training_Samples;
package body Sample_Comparison is
   use Engine_Processor_Array, Comparisons_Arrays, Engines_Arrays;
   
   procedure Clear(the_transform : out transform) is
   begin
      the_transform.valid      := false;
      the_transform.order      := (others => 0);
      the_transform.in_reverse := (others => false);
      the_transform.glue       := (others => 0);
      the_transform.reach      := 0.0;
   end Clear;
-- 
   function Transform_Stroke (src : in Samples.sample_type;
                              tfm : in transform;
                              at_stroke : natural) 
   return Stroke_Management.stroke is
      use Samples;
         -- External_Name => "transform_stroke";
      -- Create a new stroke by applying the transformation to the source.
      src_start  : natural renames src.strokes.First_Index;
      i          : natural renames at_stroke;
      new_stroke : stroke := Stroke_Management.New_Stroke;
      j          : natural := src_start;
      k          : natural := 0;
   begin
      Error_Log.Debug_Data(at_level=>8, with_details=>"Transform_stroke: start.");
      while k < maximum_strokes and j <= src.strokes.Last_Index loop
         j := src_start;
         while j <= src.strokes.Last_Index loop 
            if tfm.order(j - src_start) - 1 = i and tfm.glue(j - src_start) = k
            then
               Glue(the_stroke => src.strokes(j), 
                    to => new_stroke,
                    in_reverse => tfm.in_reverse(j-src_start));
               exit;
            end if;
            j := j + 1;
         end loop;
         k := k + 1;
      end loop;
      Stroke_Management.Process(the_stroke => new_stroke);
      return new_stroke;
      exception
         when Stroke_Management.NO_POINTS_ERROR =>
            -- First, log the error
            Error_Log.Put(the_error => 42,
                          error_intro =>  "Transform_stroke error", 
                          error_message=> "trying to transform empty stroke.");
            -- Then just return the empty and therefore unprocessed new stroke
            return new_stroke;
         when others =>
            Error_Log.Put(the_error => 43,
                          error_intro => "Transform_stroke error", 
                          error_message=>"strange error transforming stroke.");
            -- Then just return the empty and therefore unprocessed new stroke
            return new_stroke;
   end Transform_stroke;

   procedure Clear(the_comparison_information : out comparison_information) is
   begin
      Error_Log.Debug_Data(at_level=>8, 
                    with_details=>"Clear(the_comparison_information): start.");
      Clear(the_comparison_information.ch);
      the_comparison_information.rating := 0;
      Set_Length(the_comparison_information.ratings, engines.Length);
      for engine_no in the_comparison_information.ratings.First_Index .. 
                       the_comparison_information.ratings.Last_Index loop
         the_comparison_information.ratings(engine_no) := 0; 
      end loop;
      the_comparison_information.disqualified := true;  -- default state
      Clear(the_comparison_information.the_transform);
      the_comparison_information.penalty := 0.0;
   end Clear;
   
   procedure Setup_The_Comparison_Array is
      -- Initialise the comparison array such that there is an entry for each
      -- training sample and the entry's index matches that for the training
      -- sample's entry.  It should be noted that the training sample list is
      -- an instantiation of a generic binary tree with data (so it's a sorted
      -- list).  Here, we are loading it into an array.  To enable matching,
      -- here we index the comparison data for each character/word and we pass
      -- back to the training data the index matching it.
      the_sample      : training_sample;
      comparison_data : comparison_information;
      last_character  : text := Clear;
      index           : natural := 0;
   begin
      Comparisons_Arrays.Clear(training_comparisons);
      First_Sample;
      while not Past_Last_Sample loop
         the_sample := Deliver_The_Sample;
         if the_sample.enabled
         then  -- we don't do recognition for disabled samples
            Clear(comparison_data);
            comparison_data.ch := the_sample.ch;
         -- work out our index number for this training sample
            if Is_Empty(training_comparisons)
            then
               comparison_data.sample_number := 1;
            else
               comparison_data.sample_number := 
                               training_comparisons.Last_Index + 1;
            end if;
            Comparisons_Arrays.Append(training_comparisons, comparison_data);
            the_sample.index := comparison_data.sample_number;
            Replace (the_data => the_sample);
         end if;
         Next_Sample;
      end loop;
   end Setup_The_Comparison_Array;

   procedure Register(engine_data : in engine_management;
                      with_id     : out natural;
                      must_be_first : boolean := false) is
      -- This procedure loads the engine data into the array.  It is called by
      -- each engine's main package body at initialisation (i.e. at the same
      -- place the version details are registered).
   begin
      if must_be_first
      then  -- insert at the beginning (this would only be the pre-processor).
         Engines_Arrays.Prepend(engines, engine_data);
      else  -- insert at the end of the list.
         Engines_Arrays.Append(engines, engine_data);
      end if;
      with_id := Engines_Arrays.Last_Index(engines);
   end Register;

begin
   Cell_Writer_Version.Register(revision => "$Revision: v1.0.0$",
                                for_module => "Sample_Comparison");
end Sample_Comparison;
