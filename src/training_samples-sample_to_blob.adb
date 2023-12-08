--    -- type Transform_array is array (strokes_list_range'Range) of natural;
--    -- type In_Reverse_array is array (strokes_list_range'Range) of boolean;
--    -- type Transform is record
--          -- valid : boolean;                  -- ./recognize.h:143
--          -- order : aliased Transform_array;  -- ./recognize.h:143
--          -- in_reverse : aliased In_Reverse_array;  -- ./recognize.h:143
--          -- glue : aliased Transform_array;  -- ./recognize.h:144
--          -- reach : aliased float;  -- ./recognize.h:145
--       -- end record;
   -- type processor_ratings_type is array (engine_processor_types'Range) of natural;
   -- package Strokes_Arrays is new Ada.Containers.Vectors
   --       (index_type   => natural,
   --        element_type => stroke);
   -- subtype stroke_array    is Strokes_Arrays.vector;
   -- type sample_type is record
         -- ch            : text := null_char;  -- ./recognize.h:150
         -- used          : aliased natural := 0;  -- ./recognize.h:149
         -- processed     : aliased boolean := false;  -- ./recognize.h:153
         -- centre        : aliased point;  -- ./recognize.h:155
         -- distance      : aliased float;  -- ./recognize.h:156
         -- strokes       : stroke_array;  -- ./recognize.h:157
         -- roughs        : stroke_array;  -- ./recognize.h:157
      -- end record;

separate (Training_Samples) 
         function Sample_to_Blob (for_the_sample : training_sample) 
         return Blobs.blob is
   use Blobs.Base_64;
   use Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
   -- Because Unchecked_Conversion doesn't seem to grab the entire sample,
   -- the conversion needs to be specific to each thing being converted.
   -- This takes a sample and converts it into a blob.  The blob is
   -- assumed to be, in fact, a Base_64 encoded string.  Its length will
   -- be quite variable.  To Manage that, we will use a dString text type
   -- and then translate that back into the blob.
   -- Uncommon control characters are used to break the data up into layers,
   -- starting from the top at Lvl1 and going down a level as the data dives
   -- into lower level arrays and sub-records.
   Lvl1 : constant wide_character := Ada.Characters.Wide_Latin_1.ETB;
      -- used to separate top level record items
   Lvl2 : constant wide_character := Ada.Characters.Wide_Latin_1.SO;
      -- used to separate next level down, which are arrays except for
      -- transform, which is a sub-record
   Lvl3 : constant wide_character := Ada.Characters.Wide_Latin_1.SI;
      -- used to separate next level down again, often arrays
   Lvl4 : constant wide_character := Ada.Characters.Wide_Latin_1.FF;
      -- used to separate next level down again, often records
   Lvl5 : constant wide_character := Ada.Characters.Wide_Latin_1.VT;
      -- used to separate next level down again, specifically point data
   function Convert_To_Blob(the_point : point; 
                            at_lvl: wide_character := Lvl2) return text is
      result : text;
   begin
      result :=
         Put_Into_String(X(the_point)) & at_lvl &
         Put_Into_String(Y(the_point)) & at_lvl &
         Put_Into_String(Z(the_point));
      return result;
   end Convert_To_Blob;
   function Stroke_To_Blob(the_stroke : stroke) return text is
      result : text;  zero : constant natural := 0;
   begin
      result := Convert_To_Blob(the_point=> the_stroke.centre, at_lvl=> Lvl4)&
                Lvl3 & Put_Into_String(the_stroke.distance)&
                Lvl3 & Put_Into_String(zero)& --the_stroke.size)&
                Lvl3 & Put_Into_String(the_stroke.spread)&
                Lvl3&Value_From_Wide(boolean'Wide_Image(the_stroke.processed))&
                Lvl3;
      -- Gluable Start
      for item in strokes_list_range'Range loop
         result := result &  Put_Into_String(the_stroke.gluable_start(item));
         if item < strokes_list_range'Last then
            result := result & Lvl4;
         end if;
      end loop;
      result := result & Lvl3;
      -- Gluable End
      for item in strokes_list_range'Range loop
         result := result & Put_Into_String(the_stroke.gluable_end(item));
         if item < strokes_list_range'Last then
            result := result & Lvl4;
         end if;
      end loop;
      result := result & Lvl3 &
                Convert_To_Blob(the_point=>the_stroke.min,at_lvl=>Lvl4)& Lvl3 &
                Convert_To_Blob(the_point=>the_stroke.max,at_lvl=>Lvl4)& Lvl3;
      -- Points
      for item in the_stroke.points.First_index ..
               the_stroke.points.Last_Index loop
         result := result & Convert_To_Blob(the_stroke.points(item), 
                                            at_lvl => Lvl5) & Lvl4;
      end loop;
      result := result & Lvl3;
      -- Angles
      for item in the_stroke.angles.First_index ..
                  the_stroke.angles.Last_Index loop
         result := result & Put_Into_String(the_stroke.angles(item)) & Lvl4;
      end loop;
      return result;
   end Stroke_To_Blob;
   
   blob_data : text;
begin  -- Sample_to_Blob
   Clear(blob_data);
   -- Translate the top level data into a string, using the ETB as a separator.
   blob_data := for_the_sample.ch & Lvl1 &
                Put_Into_String(for_the_sample.used) & Lvl1 &
         Convert_To_Blob(for_the_sample.centre) & Lvl1 &
         Put_Into_String(for_the_sample.distance) & Lvl1;
   -- Strokes Array (of strokes)
   for item in for_the_sample.strokes.First_index ..
               for_the_sample.strokes.Last_Index loop
      blob_data := blob_data&Stroke_To_Blob(for_the_sample.strokes(item))&Lvl2;
   end loop;
   -- Roughs Array (of strokes)
   blob_data := blob_data & Lvl1;
   for item in for_the_sample.roughs.First_index ..
               for_the_sample.roughs.Last_Index loop
      blob_data:= blob_data & Stroke_To_Blob(for_the_sample.roughs(item))&Lvl2;
   end loop;
   blob_data := blob_data & Lvl1 & 
         Value_From_Wide(boolean'Wide_Image(for_the_sample.processed)) & Lvl1;
   -- Error_Log.Debug_Data(at_level=>8,with_details=>"Sample_to_Blob:data='"&To_String(blob_data)&"'.");
   return Cast_String_As_Blob(the_string => 
                                    Encode(Value(of_string=>blob_data),UTF_8));
end Sample_to_Blob;
