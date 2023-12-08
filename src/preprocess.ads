-----------------------------------------------------------------------
--                                                                   --
--                        P R E P R O C E S S                        --
--                                                                   --
--                     S p e c i f i c a t i o n                     --
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
with Vectors;           use Vectors;
with Stroke_Management; use Stroke_Management;
with Samples;           use Samples;
with Sample_Comparison; use Sample_Comparison;
with Training_Samples;  use Training_Samples;
package Preprocess is

   prep_examined : natural := 0;

   procedure Engine_Prep(input_sample: in Samples.input_sample_type;
                         input_penalty : in out float;
                         unused_1, unused_2 : natural;
                         unused_3 : in out integer);
      -- The  engine preparation (pre-)processor

private

   engine_prep_id : natural;  -- our engine identifier (set by Register)
   -- Maximum and variable versions of the number of samples to prepare for
   -- thorough examination
   prep_max     : constant natural := Samples.max_samples_per_character * 4;
   prep_samples : constant natural := Samples.Maximum_Samples * 4;

   -- Greedy mapping 
   value_max : constant float := 2048.0;
   value_min : constant float := 1024.0;

   -- Penalties (proportion of final score deducted) */
   vertical_penalty : constant float := 16.00;
   gluable_penalty  : constant float :=  0.08;
   glue_penalty     : constant float :=  0.02;

   function Measure_Partial(as, b : stroke; offset : point; scale_b : float) 
   return float;
       -- Trim the stroke b to be the same as the sample stroke a viz Resample
       -- then Measure the two strokes using the Measure_Distance function.
    
   procedure Greedy_Map(larger, smaller : in sample_type;
                        ptform : out Transform;
                        offset : in point; 
                        larger_penalty, smaller_penalty : in out float;
                        result: out float);
       -- Strokes within a character may be drawn backwards relative to the
       -- training sample, in a different order, or connected together.
       -- This function is a corrective process to account for these variations
       -- by ‘mapping’ one sample to another.
       -- This greedy mapping algorithm, which accounts for variability,
       -- augments the elastic mapping to provide the underlying recognition
       -- mechanism.
    
   procedure Prepare(the_sample : in out comparison_information; 
                     for_training_sample : in training_sample;
                     with_success : out boolean;
                     against_input_sample : in Samples.input_sample_type;
                     for_input_penalty : in out float);

   type handle_type is record  -- dynamic list requires a record structure
         h : natural;
      end record;
   -- For the list of handles dynamic list for the Engine_Prep procedure
   function LessThan(a, b : in integer) return boolean;
  
end Preprocess;
