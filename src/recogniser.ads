-----------------------------------------------------------------------
--                                                                   --
--                        R E C O G N I S E R                        --
--                                                                   --
--                     S p e c i f i c a t i o n                     --
--                                                                   --
--                           $Revision: 1.0 $                        --
--                                                                   --
--  Copyright (C) 2022  Hyper Quantum Pty Ltd.                       --
--  Written by Ross Summerfield.                                     --
--                                                                   --
--  This  package does the hand writing recognition.                 --
--  It is a translation of the recognizer.c package to Ada that  is  --
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
with GNATCOLL.SQL.Exec;
with Ada.Containers.Vectors;
with dStrings;          use dStrings;
with Vectors;           use Vectors;
with Setup;
with Stroke_Management; use Stroke_Management;
with Samples;           use Samples;
with Sample_Comparison; use Sample_Comparison;
with Training_Samples;  use Training_Samples;
with Preprocess;        use Preprocess;
with Averages;          use Averages;
with Word_Frequency;    use Word_Frequency;
with Generic_Binary_Trees_With_Data;
package Recogniser is

   -- Initialisation and finalisation - to be done at program start and
   -- at program end to set up start condition and to save the operating
   -- environment.
   procedure Initialise_Recogniser
                   (DB_Descr : GNATCOLL.SQL.Exec.Database_Description);
   procedure Finalise_Recogniser;
   
   -- Alternative possible characters or words for a particular
   -- sample being recognised
   subtype sample_rating is Setup.sample_rating;  -- per cent value
   type alternative_details is record
         ch             : text;
         rating         : sample_rating := 0.0;
         sample_number  : natural;
      end record;
   function LessThan(a, b : in sample_rating) return boolean;
   package Alternatives_Arrays is new Generic_Binary_Trees_With_Data
                                (sample_rating, alternative_details, LessThan);
   subtype alternative_array is Alternatives_Arrays.list;
   -- 
   -- training_block : aliased integer;

   procedure Recognise_Sample (input_sample : in sample_type;
                               best_result  : out text;
                               alternatives : out alternative_array;
                               num_alternatives : in integer);
      -- Use the recognition engines to try to recognise the sample.
      -- Then rank and, using the rankings, determine the most likely
      -- character.
      -- We only return num_alternatives alternatives at most, also sorted
      -- from most likely to least likely.

   procedure Train_Sample (cell : in sample_type);
      -- Overwrite a blank or least-recently-used slot in the samples set.
      
   procedure Untrain(the_character : in text);
       -- Delete all samples for a character.
   procedure Untrain_Last_Sample(for_the_character : in text);
       -- Delete the last sample recorded for a character.
   procedure Promote (the_character : in text; at_sample_number : in natural);
      -- Update usage counter for a training sample.  This information is used
      -- when there are already the maximum number of samples and the user
      -- wants to add one more.  The training sample with the lowest usage
      -- counter is replaced with new training sample.

   procedure Set_Engine_Ranges(to : in text);
      -- Get a space/comma delimited list of numbers to load into the
      -- Engine array.
   function The_Engine_Ranges return text;
      -- Provide a comma delimited list of numbers for the Engine array.

   procedure Update_Enabled_Samples;
         -- External_Name => "update_enabled_samples";
      -- Run through the samples list and enable samples in enabled blocks.
      -- These are the training samples that are a part of the blocks of
      -- characters that the user has selected as their character sets.

private

   -- User Identifier (from the system)
   user_logon : text    := Clear & "root";
   user_id    : natural := 0;  -- Note that 0 is default for all users
   
   subtype gluable_entries is Stroke_Management.gluable_entries;

  -- Fine sampling parameters  
   fine_resolution : constant float := Samples.fine_resolution;
   fine_elasticity : constant integer := Samples.fine_elasticity;
  -- Rough sampling parameters
   rough_resolution : constant float := Samples.rough_resolution;
   rough_elasticity : constant integer := Samples.rough_elasticity;
   
   -- Range of the scale value for engines  
   engine_scale : point_range := maximum_strokes;

   function Engine_Rating(for_the_sample : in comparison_information; 
                          at_engine_number : natural) return integer;
      -- Get the processed rating for specified engine (i.e. the processor) 
      -- on a sample.  This rating is processed as a part of the comparison
      -- between the input sample to be recognised (or, if you like, under
      -- test) and the training samples.  The information passed in relates
      -- to the relevant training sample.  Note that an engine can give a
      -- negative rating.

  -- Sample specific operations
   procedure Demote (the_sample : in out training_sample);
      -- Remove the sample from our set if we can.

   procedure Set_Sample_Rating(for_sample : in out comparison_information;
                               with_input_sample : in input_sample_type);
       -- Get the composite processed rating on a sample.
   procedure Insert(new_sample : in out training_sample;
                    overwrite  : in boolean := false); 
       -- Insert a sample into the sample chain, possibly overwriting an older
       -- sample.
   procedure Read_In_Samples
                    (from_database : in GNATCOLL.SQL.Exec.Database_Connection);
       -- Read in samples from the database and load to the list of samples.

   procedure Write_Out(the_sample  : in training_sample;
                       to_database : in GNATCOLL.SQL.Exec.Database_Connection;
                       as_update   : in boolean := false);
       -- Write out the specified sample to the database from the list of
       -- training samples.
   procedure Delete(the_sample  : in training_sample;
                    from_database : in GNATCOLL.SQL.Exec.Database_Connection);
       -- Delete the specified training sample from the database for the
       -- current user.
  
   strength_sum : natural := 0;
   
   -- To maintain throughput speeds, write-back to the database of statistical
   -- information is via a separate task.
   task Performance_Write_Back is
      entry Set_Database(to : in GNATCOLL.SQL.Exec.Database_Description);
      entry Record_Statistics
                       (for_recognition : in GNATCOLL.SQL.Exec.SQL_Parameters);
      entry Update_Usage(for_character : in text; at_sample_number: in natural;
                         to : in natural);
      entry Stop;
   end Performance_Write_Back;

end Recogniser;
