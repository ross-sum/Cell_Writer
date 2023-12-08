-----------------------------------------------------------------------
--                                                                   --
--                  T R A I N I N G _ S A M P L E S                  --
--                                                                   --
--                              B o d y                              --
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
-- with Ada.Containers.vectors;
-- with GNATCOLL.SQL_BLOB;
-- with Generic_Binary_Trees_With_Data;
-- with dStrings;             use dStrings;
-- with Samples;              use Samples;
-- with Calendar_Extensions;  use Calendar_Extensions;
with Ada.Characters.Wide_Latin_1;
with Ada.Wide_Characters.Handling;
with Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
with Strings_Functions;
with Blobs, Blobs.Base_64;
with Error_Log;
with Stroke_Management;   use Stroke_Management;
with Vectors;             use Vectors;
package body Training_Samples is
   use Sample_Lists, Samples_Arrays;
   
   -- type handle is private;
   -- private
   --    function LessThan(a, b : in text) return boolean;
   --    package Sample_Lists is new 
   --            Generic_Binary_Trees_With_Data(text, sample, LessThan);
   --    type handle is new Sample_Lists.handle;
   -- the_samples : Sample_Lists.list;

   -- (Training) Sample list operations
   
   function LessThan(a, b : in text) return boolean is
   begin
      return a < b;
   end LessThan;

   -- Sample list manipulation
   procedure Delete_All_Samples is
   begin
      Clear(the_list => the_samples);
   end Delete_All_Samples;
   procedure First_Sample is
   begin
      First (in_the_list => the_samples);
   end First_Sample;
   procedure Last_Sample is
   begin
      Last (in_the_list => the_samples);
   end Last_Sample;
   procedure Next_Sample is
   begin
      Next (in_the_list => the_samples);
   end Next_Sample;
   procedure Previous_Sample is
   begin
      Previous (in_the_list => the_samples);
   end Previous_Sample;
   function  Past_Last_Sample return boolean is
   begin
      return Is_End (of_the_list => the_samples);
   end Past_Last_Sample;
   function  There_Are_No_Samples return boolean is
   begin
      return Is_Empty (for_the_list => the_samples);
   end There_Are_No_Samples;
   function  There_Is_A_Sample_With (the_key : in text) return boolean is
   begin
      return The_List_Contains(the_item=> the_key, in_the_list=> the_samples);
   end There_Is_A_Sample_With;
   function  Number_Of_Samples(for_the_key : in text) return natural is
      -- Count the number of samples for this character/word
      the_count : natural := 0;
      the_key   : text;
   begin
      if The_List_Contains(the_item=> for_the_key, in_the_list=> the_samples)
      then
         Find (the_item => for_the_key, in_the_list => the_samples);
         while not Is_End(of_the_list => the_samples) and then
               Deliver(from_the_list => the_samples) = for_the_key loop
            the_count := the_count + 1;
            Next(in_the_list => the_samples);
         end loop;
      end if;
      return the_count;
   end Number_Of_Samples;
   procedure Find (the_item : in text) is
   begin
      Find (the_item => the_item, in_the_list => the_samples);
   end Find;
   function  Deliver_The_Key return text is
   begin
      return Deliver (from_the_list => the_samples);
   end Deliver_The_Key;
   function  Deliver_The_Sample return training_sample is
      nil_result : training_sample;
   begin
      if not Is_End(of_the_list => the_samples)
      then
         return Deliver_Data (from_the_list => the_samples);
      else  -- tried to get no data
         nil_result := new training_sample_record;
         Clear(nil_result.ch);
         return nil_result;
      end if;
   end Deliver_The_Sample;
   function  Deliver_The_Sample(at_index : natural) return training_sample is
   begin
      Go_To(the_index => at_index);
      return Deliver_Data (from_the_list => the_samples);
   end Deliver_The_Sample;
   procedure Insert (the_index : in text; the_data : in training_sample) is
   begin
      Insert(into=> the_samples, the_index=> the_index, the_data=> the_data);
   end Insert;
   procedure Replace (the_index : in text) is
   begin
      Replace (the_index => the_index, for_the_list => the_samples);
   end Replace;
   procedure Replace (the_data : in training_sample) is
      use Ada.Containers;
   begin
      Replace (the_data => the_data, for_the_list => the_samples);
      -- Also load into the array
      if natural(Length(Container=>element_array)) < Count(the_samples)
      then  -- make sure the array is big enough
         Set_Length(Container => element_array, 
                    Length => Count_Type(Count(the_samples)));
      end if;
      element_array(the_data.index) := The_Handle_For_The_Sample;
   end Replace;
   procedure Delete_The_Sample is
   begin
      Delete  (from_the_list => the_samples);
   end Delete_The_Sample;
   function  The_Handle_For_The_Sample return handle is
      our_handle : handle;
   begin
      Get(the_handle    => Sample_Lists.handle(our_handle), 
          from_the_list => the_samples);
      return our_handle;
   end The_Handle_For_The_Sample;
   procedure Go_To(the_handle : in handle) is
   begin
      Go_To(the_handle  => Sample_Lists.handle(the_handle), 
            in_the_list => the_samples);
   end Go_To;
   procedure Go_To(the_index : in natural) is
   begin
      Go_To(the_handle => element_array(the_index));
   end Go_To;
   function Is_Assigned(the_handle : in handle) return boolean is
   begin
      return Is_Assigned(Sample_Lists.handle(the_handle));
   end Is_Assigned;

   procedure Copy(from : in sample_type; to : out training_sample) is
      -- Copy a sample, cloing its strokes, potentially overwriting the
      -- destination, but reformatting it as specifically a training sample
      -- type.
      use Strokes_Arrays;
   begin
      Error_Log.Debug_Data(at_level=>8, with_details=>"Copy: start.");
      to := new training_sample_record;
      to.ch       := from.ch;
      to.centre   := from.centre;
      to.distance := from.distance;
      to.strokes  := from.strokes;
      to.roughs   := from.roughs;
      to.processed:= from.processed;
      to.enabled  := true;
   end Copy;

   function Blob_to_Sample (the_blob : Blobs.blob) return training_sample 
         is separate;
   
   function Extract_The_Sample (from_blob : in GNATCOLL.SQL_BLOB.Blob) 
   return training_sample is
      use GNATCOLL.SQL_BLOB;
       -- Extract a sample from the supplied blob.
       -- The sample is actually stored in the database as a Base 64 encoded
       -- blob.  String conversion (casting) to keep type consistency is
       -- therefore required when going from stored blob to decoded blob.
      the_blob : aliased Blobs.blob := Raw_Blob(from_the_blob=>from_blob);
   begin
      return Blob_to_Sample(the_blob);
   end Extract_The_Sample;

   function Sample_to_Blob (for_the_sample : training_sample) return Blobs.blob
         is separate;

   function Load_The_Sample (from : in training_sample) 
   return GNATCOLL.SQL_BLOB.Blob is
      use GNATCOLL.SQL_BLOB;
       -- Load a sample into a blob.
       -- The sample is actually stored in the database as a Base 64 encoded
       -- blob.  String conversion (casting) to keep type consistency is
       -- therefore required when going from encoded blob to stored blob.
   begin
      return To_Blob(from_raw=>Sample_to_Blob(for_the_sample => from));
   end Load_The_Sample;
   
end Training_Samples;
