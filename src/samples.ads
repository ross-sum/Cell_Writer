-----------------------------------------------------------------------
--                                                                   --
--                           S A M P L E S                           --
--                                                                   --
--                     S p e c i f i c a t i o n                     --
--                                                                   --
--                           $Revision: 1.0 $                        --
--                                                                   --
--  Copyright (C) 2022  Hyper Quantum Pty Ltd.                       --
--  Written by Ross Summerfield.                                     --
--                                                                   --
--  This package holds the stroke structural detail that is used in  --
--  hand writing recognition.                                        --
--  It  is  a  translation  from stroke  definition  parts  of  the  --
--  recognizer.c package to Ada that is Copyright (C) 2007  Michael  --
--  Levin <risujin@gmail.com>                                        --
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
with Strings_Functions;
with Vectors;             use Vectors;
with GNATCOLL.SQL.Exec;
with GNATCOLL.SQL_BLOB;
with Ada.Characters.Wide_Latin_1;
with Ada.Containers.Vectors;
with Stroke_Management;   use Stroke_Management;
with Calendar_Extensions; use Calendar_Extensions;
package Samples is

   procedure Initialise_Samples
                   (DB_Descr : GNATCOLL.SQL.Exec.Database_Description);

  -- Fine sampling parameters  
   fine_resolution : constant float := 8.0;
   fine_elasticity : constant integer := 2;
  -- Rough sampling parameters
   rough_resolution : constant float := 24.0;
   rough_elasticity : constant integer := 0;

  -- Highest range a rating can have  
   rating_maximum : constant integer := 32767;
   rating_minimum : constant integer := -32767;
            
   null_char : constant text := Clear & Ada.Characters.Wide_Latin_1.NUL;

   package Strokes_Arrays is new Ada.Containers.Vectors
         (index_type   => natural,
          element_type => stroke);
   subtype stroke_array    is Strokes_Arrays.vector;
   type sample_type_record is tagged record
         ch            : text := null_char;
         processed     : boolean := false;
         centre        : point;
         distance      : float;
         strokes       : stroke_array;
         roughs        : stroke_array;
      end record;
   type sample_type is access all sample_type_record'Class;
   subtype input_sample_type_record is sample_type_record;
   subtype input_sample_type is sample_type;

   function Is_Disqualified (the_sample, against_input_sample : in sample_type) 
   return boolean;
      -- Check disqualification conditions for a sample during recognition.
      -- The preprocessor engine must run before any calls to this or
      -- disqualification will not work.

  -- Processing  
   procedure Clear (the_sample : in out sample_type);
      -- Free stroke data associated with a sample and reset its parameters.
   procedure Process(the_sample : in out sample_type);
      -- Generate cached properties of a sample.  These properties are used
      -- when doing comparisons between input sample being recognised and
      -- training samples.  It is applied to both training samples (and then
      -- stored in the database of training samples) and the sample being
      -- recognised.
  
  -- Maximum number of samples we can have per character  
   max_samples_per_character : constant natural := 16;
        -- External_Name => "SAMPLES_MAX"
   subtype samples_range is natural range 0 .. max_samples_per_character;
   procedure Set_Maximum_Samples(to : in samples_range);
      -- Load in the user's preference for the maximum number of training
      -- samples per character.
   function Maximum_Samples return samples_range;
      -- Get the user's preference for the maximum number of training samples.
   function Centre_of_Samples(a, b : in sample_type) return point;
       -- Adjust for the difference between two sample centres

   procedure Set_Disable_Basic_Latin_Letters(to : in boolean);
      -- If you have trained both the Basic Latin block and a block with
      -- characters to Latin letters (for instance, Crillic), you can disable
      -- the Basic Latin letters in order to use only numbers and symbols from
      -- Basic Latin.

   private

   max_num_samples : samples_range := 5;
   current_sample : samples_range := 1;
  
  -- Maximum distance between glue points
   glue_distance : constant point_range := maximum_points / 6;

   procedure Process_Gluable(for_sample : in out sample_type; 
                             at_stroke_number : strokes_list_range);
       -- Calculate the lowest distance between the start or end of one
       -- stroke and any other point on each other stroke in the sample.
       -- This is essentially a major component of the mapping of one
       -- sample onto another.
   
   no_latin_alpha : boolean := false;
   g_unichar_isgraph : boolean := false;  -- FIX ME! --
   function Is_Disabled(the_character : in text) return boolean;
       -- Returns TRUE if a character is not renderable or is explicity
       -- disabled by a setting (not counting disabled Unicode blocks)

end Samples;
