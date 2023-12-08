separate (Training_Samples) 
       function Blob_to_Sample(the_blob : Blobs.blob) return training_sample is
   use Blobs.Base_64, Strings_Functions;
   use Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
   -- Because Unchecked_Conversion doesn't seem to grab the entire sample,
   -- the conversion needs to be specific to each thing being converted.
   -- This does the reverse load of the sample from the blob.  The blob is
   -- assumed to be, in fact, a Base_64 encoded string.
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
   function Get_Boolean_From_String(str:text) return boolean is
      truth : constant text := to_text(from_wide=>"TRUE");
   begin
      return Upper_Case(Trim(str)) = truth;
   end Get_Boolean_From_String;
   function Extract_Point(from : text; at_lvl : wide_character := Lvl2) 
   return point is
      point_fields: text_array := Disassemble(from_string=>from,
                                                 separated_by => at_lvl);
   begin
      return Make_Point( 
                    at_x => Get_Float_From_String(Left_Trim(point_fields(1))), 
                    at_y => Get_Float_From_String(Left_Trim(point_fields(2))),
                    at_z => Get_Float_From_String(Left_Trim(point_fields(3))));
      exception
         when No_Number =>
            Error_Log.Put(the_error => 28,
                          error_intro =>  "Extract_Point error", 
                          error_message=> "Invalid point data '" &
                                           To_String(from) & "'.");
            return origin;
   end Extract_Point;
   function Extract_Strokes(from : text) return stroke_array is
      function Extract_Stroke(from : text) return stroke is
         function Extract_Gluable(from : text) return gluable_entries is
            num_fields:positive:=Component_Count(of_the_string=>from,
                                                 separated_by=> Lvl4);
            glu_fields:text_array:=Disassemble(from_string => from,
                                               separated_by=> Lvl4);
            index : natural := 1;
            result : gluable_entries;
         begin
            for item in strokes_list_range'Range loop
               if index <= num_fields
               then
                  if Get_Integer_From_String(Left_Trim(glu_fields(index))) in 
                                                                  point_range
                  then
                     result(item) := 
                         Get_Integer_From_String(Left_Trim(glu_fields(index)));
                  else
                     Error_Log.Put(the_error => 29,
                                   error_intro =>  "Extract_Gluable error", 
                                   error_message=> "oversided gluable at"& 
                         Get_Integer_From_String(Left_Trim(glu_fields(index)))'
                                                             Wide_Image & 
                                                   " for item  "&
                                                   Integer(item)'Wide_Image &
                                                   " (from '" & 
                                                   To_String(glu_fields(index))
                                                   & "').");
                     if Get_Integer_From_String(Left_Trim(glu_fields(index))) >
                                                               point_range'Last
                      then
                        result(item) := point_range'Last;
                     else
                        result(item) := point_range'First;
                     end if;
                  end if;
               else
                  Error_Log.Put(the_error => 30,
                                error_intro =>  "Extract_Gluable error", 
                                error_message=> "insufficient gluables at"& 
                                                index'Wide_Image & ".");
                  result(item) := 0;
               end if;
               index := index + 1;
            end loop;
            return result;
         end Extract_Gluable;
         function Extract_Points(from: text) return points_array is
            array_fields : text_array := Disassemble(from_string => from,
                                                     separated_by=> Lvl4);
            result : points_array;
         begin
            for item in array_fields'range loop
               if Length(array_fields(item)) > 0 then  -- not empty point data
                  Points_Arrays.Append(result,
                                       Extract_Point(from=>array_fields(item),
                                                     at_lvl => Lvl5));
               end if;
            end loop;
            return result;
         end Extract_Points;
         function Extract_Angles(from: text) return angles_array is
            array_fields : text_array := Disassemble(from_string => from,
                                                     separated_by=> Lvl4);
            result : angles_array;
         begin
            for item in array_fields'range loop
               if Length(array_fields(item)) > 0 then  -- not empty angle data
                  Angles_Arrays.Append(result,
                         Get_Float_From_String(Left_Trim(array_fields(item))));
               end if;
            end loop;
            return result;
         end Extract_Angles;
         strk_fields : text_array := Disassemble(from_string => from,
                                                 separated_by=> Lvl3);
         result : stroke;
      begin  -- Extract_Stroke
         result.centre   := Extract_Point(from=> strk_fields(1), at_lvl=>Lvl4);
         result.distance := Get_Float_From_String(Left_Trim(strk_fields(2)));
         result.spread   := Get_Float_From_String(Left_Trim(strk_fields(4)));
         result.processed:= Get_Boolean_From_String(strk_fields(5));
         result.gluable_start := Extract_Gluable(from => strk_fields(6));
         result.gluable_end   := Extract_Gluable(from => strk_fields(7));
         result.min      := Extract_Point(from=> strk_fields(8), at_lvl=>Lvl4);
         result.max      := Extract_Point(from=> strk_fields(9), at_lvl=>Lvl4);
         if Length(strk_fields(10)) > 0 then  -- there are points
            result.points   := Extract_Points(from => strk_fields(10));
         end if;
         if Length(strk_fields(11)) > 0 then  -- there are angles
            result.angles   := Extract_Angles(from => strk_fields(11));
         end if;
         return result;
      end Extract_Stroke;
      array_fields : text_array := Disassemble(from_string => from,
                                               separated_by=> Lvl2);
      result : stroke_array;
   begin  -- Extract_Strokes
      for item in array_fields'range loop
         if Length(array_fields(item)) > 0 then  -- not empty stroke data
            Strokes_Arrays.Append(result,
                                  Extract_Stroke(from=>array_fields(item)));
         end if;
      end loop;
      return result;
   end Extract_Strokes;
   blob_data : text;
   result    : training_sample := new training_sample_record;
begin  -- Blob_to_Sample
   -- First, convert the blob into a gStrings text style string so that
   -- it is easy to parse.  It is actually a UTF-8 string.
   blob_data:= Value_From_Wide(Decode( 
                               Cast_Blob_As_String(the_blob=>the_blob),UTF_8));
   -- Error_Log.Debug_Data(at_level=>8,with_details=>"Blob_to_Sample: data='"&To_String(blob_data)&"'.");
   -- Now do the reverse of encoding it.
   declare
      sample_fields : text_array := Disassemble(from_string => blob_data,
                                                separated_by=> Lvl1);
   begin
      result.ch     := sample_fields(1);
      result.used   := Get_Integer_From_String(Left_Trim(sample_fields(2)));
      result.centre   := Extract_Point(from => sample_fields(3));
      result.distance := Get_Float_From_String(Left_Trim(sample_fields(4)));
      if Length(sample_fields(5)) > 0 then  -- there are strokes
         result.strokes  := Extract_Strokes(from=> sample_fields(5));
      end if;
      if Length(sample_fields(6)) > 0 then  -- there are roughs
         result.roughs   := Extract_Strokes(from=> sample_fields(6));
      end if;
      result.processed     := Get_Boolean_From_String(sample_fields(7));
   end;
   return result;
end Blob_to_Sample;
