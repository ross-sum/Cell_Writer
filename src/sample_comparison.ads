-----------------------------------------------------------------------
--                                                                   --
--                 S A M P L E   C O M P A R I S O N                 --
--                                                                   --
--                     S p e c i f i c a t i o n                     --
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
with dStrings;            use dStrings;
with Stroke_Management;   use Stroke_Management;
with Samples;
with Ada.Containers.Vectors;
package Sample_Comparison is

   --        Samples and characters
   -- The following is the list of engine  processor types.
   -- Should there be additional engines applied, they will need
   -- to be added into this list.
   package Engine_Processor_Array is new Ada.Containers.Vectors
         (index_type   => natural,
          element_type => integer);
   subtype processor_ratings_type is Engine_Processor_Array.vector;

   type Transform_array is array (strokes_list_range'Range) of natural;
   type In_Reverse_array is array (strokes_list_range'Range) of boolean;
   type Transform is record
         valid : boolean := false;
         order : aliased Transform_array;
         in_reverse : aliased In_Reverse_array;
         glue : aliased Transform_array;
         reach : aliased float := 0.0;
      end record;
   procedure Clear(the_transform : out transform);

   function Transform_Stroke(src : in Samples.sample_type;
                             tfm : in transform;
                             at_stroke : natural)
   return Stroke_Management.stroke;  -- ./recognize.h:183
      -- Create a new stroke by applying the transformation to the source.
      
   type comparison_information is record
         ch            : text := Samples.null_char;
         sample_number : natural :=0;  -- the index for related training sample
         rating        : integer;
         ratings       : processor_ratings_type;
         disqualified  : boolean;
         the_transform : Transform;
         penalty       : float := 0.0;
      end record;
   package Comparisons_Arrays is new Ada.Containers.Vectors
         (index_type   => natural,
          element_type => comparison_information);
   subtype comparison_array is Comparisons_Arrays.vector;
   training_comparisons : comparison_array;
   
   procedure Setup_The_Comparison_Array;
      -- Initialise the comparison array such that there is an entry for each
      -- training sample and the entry's index matches that for the training
      -- sample's entry.

   --        Recognition engines
   -- 
   maximum_range : constant natural := 100;
      -- Largest allowed engine weight
   type engine_processor is 
          access procedure (input_sample: in Samples.input_sample_type;
                            input_penalty : in out float;
                            var1, var2 : natural;
                            var3 : in out integer);
   -- Template for the engine processor for an engine

   type engine_management is record
         name         : text;
         func         : engine_processor;
         e_range      : aliased natural;
         ignore_zeros : boolean;
         scale        : aliased integer;
         average      : aliased integer;
         max          : aliased integer;
      end record;
   package Engines_Arrays is new Ada.Containers.Vectors
         (index_type   => natural,
          element_type => engine_management);
   subtype engine_array is Engines_Arrays.vector;
   engines : engine_array;
   
   procedure Register(engine_data : in engine_management;
                      with_id     : out natural;
                      must_be_first : boolean := false);
      -- This procedure loads the engine data into the array.  It is called by
      -- each engine's main package body at initialisation (i.e. at the same
      -- place the version details are registered).
      
private

   procedure Clear(the_comparison_information : out comparison_information);

end Sample_Comparison;
