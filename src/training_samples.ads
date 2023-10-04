-----------------------------------------------------------------------
--                                                                   --
--                  T R A I N I N G _ S A M P L E S                  --
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
with Ada.Containers.vectors;
with GNATCOLL.SQL_BLOB;
with Generic_Binary_Trees_With_Data;
with dStrings;             use dStrings;
with Samples;              use Samples;
with Calendar_Extensions;  use Calendar_Extensions;
package Training_Samples is

   type training_sample_record is new Samples.sample_type_record with record
         index         : natural := 0;  -- for aligning with comparison data
         sample_number : natural := 0;  -- 0 == unassigned
         used          : natural := 0;  -- number of times this trg sample used
         training_date : time;
         training_time : day_duration;
         enabled       : boolean := false;  -- only really used once loaded
      end record;
   type training_sample is access all training_sample_record'Class;
   
   -- Sample list manipulation
   type handle is private;
   procedure Delete_All_Samples;
   procedure First_Sample;
   procedure Last_Sample;
   procedure Next_Sample;
   procedure Previous_Sample;
   function  Past_Last_Sample return boolean;  -- no more samples in the list
   function  There_Are_No_Samples return boolean;
   function  There_Is_A_Sample_With (the_key : in text) return boolean;
   function  Number_Of_Samples(for_the_key : in text) return natural;
      -- Count the number of samples for this character/word
   procedure Find (the_item : in text);
   function  Deliver_The_Key return text;
   function  Deliver_The_Sample return training_sample;
   function  Deliver_The_Sample(at_index : natural) return training_sample;
   procedure Insert (the_index : in text; the_data : in training_sample);
   procedure Replace (the_index : in text);
   procedure Replace (the_data : in training_sample);
   procedure Delete_The_Sample;
   function  The_Handle_For_The_Sample return handle;
   procedure Go_To(the_handle : in handle);
   procedure Go_To(the_index : in natural);
   function Is_Assigned(the_handle : in handle) return boolean;

   procedure Copy(from : in sample_type; to : out training_sample);
      -- Copy a sample, cloing its strokes, potentially overwriting the
      -- destination, but reformatting it as specifically a training sample
      -- type.
      
   -- Database interaction functions to convert between blob and sample
   function Extract_The_Sample(from_blob : in GNATCOLL.SQL_BLOB.Blob) 
   return training_sample;
         -- External_Name => "sample_read"
       -- Extract a sample from the supplied blob
   function Load_The_Sample (from : in training_sample) 
   return GNATCOLL.SQL_BLOB.Blob;
         -- External_Name => "sample_read"
       -- Load a sample into a blob.
       -- Using unchecked conversion, pack the sample into the blob field and
       --  load it into the SQL blob for return.

private
   
   function LessThan(a, b : in text) return boolean;
   package Sample_Lists is new 
              Generic_Binary_Trees_With_Data(text, training_sample, LessThan);
   type handle is new Sample_Lists.handle;

   the_samples : Sample_Lists.list;

    -- The following is used for matching handles to identifiers
   package Samples_Arrays is new Ada.Containers.Vectors
         (index_type   => natural,
          element_type => handle);
   subtype sample_array is Samples_Arrays.vector;
   element_array : sample_array;

end Training_Samples;