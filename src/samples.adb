-----------------------------------------------------------------------
--                                                                   --
--                           S A M P L E S                           --
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
-- with dStrings;          use dStrings;
-- with Strings_Functions;
-- with Vectors;           use Vectors;
-- with GNATCOLL.SQL.Exec;
-- with GNATCOLL.SQL_BLOB;
-- with Ada.Characters.Wide_Latin_1;
-- with Ada.Containers.Vectors;
-- with Stroke_Management; use Stroke_Management;
-- with Calendar_Extensions; use Calendar_Extensions;
with GNATCOLL.SQL.Exec.Tasking;
with Ada.Wide_Characters.Handling;
with Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
with Blobs, Blobs.Base_64;
with Error_Log;
with Cell_Writer_Version; with Setup;
with Database;                   use Database;
package body Samples is
   use GNATCOLL.SQL;

   cDB : GNATCOLL.SQL.Exec.Database_Connection;
   lingo_sel_enabled    : constant GNATCOLL.SQL.Exec.Prepared_Statement :=
      GNATCOLL.SQL.Exec.Prepare 
           (SQL_Select (Fields  => Languages.ID & 
                                   Languages.Start & Languages.EndChar & 
                                   Languages.Selected,
                        From    => Languages,
                        Where   => (Languages.Start <= Integer_Param(1)) AND
                                   (Languages.EndChar >= Integer_Param(1)),
                        Order_By=> Languages.ID),
            On_Server => True,
            Use_Cache => True);
   
   procedure Initialise_Samples
                   (DB_Descr : GNATCOLL.SQL.Exec.Database_Description) is
      -- use GNATCOLL.SQL.Exec;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details=> "Initialise_Samples: Start");
      -- Set up: Open the relevant tables from the database
      cDB:=GNATCOLL.SQL.Exec.Tasking.Get_Task_Connection(Description=>DB_Descr);
   end Initialise_Samples;

   procedure Set_Disable_Basic_Latin_Letters(to : in boolean) is
      -- If you have trained both the Basic Latin block and a block with
      -- characters to Latin letters (for instance, Crillic), you can disable
      -- the Basic Latin letters in order to use only numbers and symbols from
      -- Basic Latin.
   begin
      no_latin_alpha := to;
   end Set_Disable_Basic_Latin_Letters;
     
   -- Sample variable operations
   
   procedure Set_Maximum_Samples(to : in samples_range) is
      -- Load in the user's preference for the maximum number of samples
      -- per character
   begin
      max_num_samples := to;
      if max_num_samples < 1 then
         max_num_samples := 1;
      end if;
   end Set_Maximum_Samples;

   function Maximum_Samples return samples_range is
      -- Get the user's preference for hte maximum number of samples.
   begin
      return max_num_samples;
   end Maximum_Samples;

   -- Sample operations and processing
   
   function Centre_of_Samples(a, b : in sample_type) return point is
       --Adjust for the difference between two sample centres
   begin
      return b.centre - a.centre;
   end Centre_of_Samples;

   function Is_Disabled(the_character : in text) return boolean is
       -- Returns TRUE if a character is not renderable or is explicity
       -- disabled by a setting (not counting disabled Unicode blocks)
       -- We assume here that, in a word, we are only interested in the
       -- first leter of that word.
      use GNATCOLL.SQL.Exec, Ada.Wide_Characters.Handling;
      R_lingo    : Forward_Cursor;
      lingo_parm : SQL_Parameters (1 .. 1);
   begin
      -- First, work out which characters are in the first block by getting the
      -- block number that the_character is in
      lingo_parm := (1 => +(wide_character'Pos(Wide_Element(the_character, 1))));
      R_lingo.Fetch (Connection => cDB, Stmt => lingo_sel_enabled, 
                     Params => lingo_parm);
      if Success(cDB) and then Has_Row(R_lingo) then
         -- We now know which block the character is in
         if no_latin_alpha
         then  -- confirm it's Latin1 and it is an alpha  
             -- check the character is or isn't in the first set (that's the
             -- Latin 1 set) and that it is alpha-numeric, but not numeric
            return (Integer_Value(R_lingo, 0) = 1) and then
                   (Is_Alphanumeric(Wide_Element(the_character, 1)) and 
                    not Is_Digit(Wide_Element(the_character, 1)));
         else  -- If it isn't Latin 1, make sure it isn't a control character
            return Is_Control(Wide_Element(the_character, 1));
         end if;
      else  -- didn't find it so assume it is not disabled
         return false;
      end if;
   end Is_Disabled;

   function Is_Disqualified (the_sample, against_input_sample : in sample_type) 
   return boolean is
      -- Check disqualification conditions for a sample during recognition.
      -- The preprocessor engine must run before any calls to this or
      -- disqualification will not work.
         -- External_Name => "sample_disqualified";
      use Ada.Containers;
      input_strokes : stroke_array renames against_input_sample.strokes;
   begin
      if (Setup.Match_Differing_Stroke_Numbers and 
          (the_sample.strokes.Length /= input_strokes.Length))
      then
         return true;
      elsif Is_Disabled(the_sample.ch)
      then
         return true;
      else
         return false;
      end if;
   end Is_Disqualified;

  -- Processing  
   procedure Clear (the_sample : in out sample_type) is
      -- Free stroke data associated with a sample and reset its parameters.
      use Strokes_Arrays;
   begin
      Error_Log.Debug_Data(at_level=>8, with_details=>"Clear(sample): start.");
      -- First, make sure the sample is defined
      if the_sample = null then
         the_sample := new Samples.sample_type_record;
      end if;
      -- Now ensure the sample contains no data or is set to default data
      if not Is_Empty(the_sample.strokes) then
         for item in the_sample.strokes.First_Index .. 
                  the_sample.strokes.Last_Index loop
            Clear(the_stroke => the_sample.strokes(item));
         end loop;
         Strokes_Arrays.Clear(the_sample.strokes);
      end if;
      if not Is_Empty(the_sample.roughs) then
         for item in the_sample.roughs.First_Index .. 
                  the_sample.roughs.Last_Index loop
            Clear(the_stroke => the_sample.roughs(item));
         end loop;
         Strokes_Arrays.Clear(the_sample.roughs);
      end if;
      -- Clear the sample itself:
      the_sample.ch        := null_char;
      the_sample.processed := false;
      the_sample.centre    := origin;
      --   nothing else to do here.
   end Clear;

   procedure Process_Gluable(for_sample : in out sample_type; 
                             at_stroke_number : strokes_list_range) is
       -- Calculate the lowest distance between the start or end of one
       -- stroke and any other point on each other stroke in the sample.
       -- This is essentially a major component of the mapping of one
       -- sample onto another, working out whether it is possible to
       -- glue any two strokes together.
      type passes is (first_pass, last_pass);
      a_point : point;
      sample_stroke : Stroke_Management.stroke 
                      renames for_sample.strokes(at_stroke_number);
   begin
      Error_Log.Debug_Data(at_level=>9,with_details=>"Process_Gluable:start.");
      -- Dots cannot be glued
      sample_stroke.gluable_start := (others => -1);
      sample_stroke.gluable_end   := (others => -1);
      if sample_stroke.spread < dot_spread then 
         Error_Log.Debug_Data(at_level=>9,with_details=>"Process_Gluable: a dot: sample_stroke spread=" & Put_Into_String(sample_stroke.spread,3) & ", which is < dot_spread=" & Put_Into_String(dot_spread,2) & ".");
         return;
      end if;
      
      -- We scan through for the gluable start and then again through for
      -- the gluable end (i.e. we do 2 scans)
      for scan_number in first_pass .. last_pass loop
         case scan_number is
            when first_pass =>  -- Doing sample start point (gluable start)
               a_point:=sample_stroke.points(sample_stroke.points.First_Index);
            when last_pass =>  -- doing sample end point (gluable end)
               a_point:=sample_stroke.points(sample_stroke.points.Last_Index);
         end case;
         for stroke_number in for_sample.strokes.First_Index .. 
                              for_sample.strokes.Last_Index loop
            declare
               current_stroke : Stroke_Management.stroke 
                                renames for_sample.strokes(stroke_number);
               dist       : float;
               min        : float := float(glue_distance);
               gluable    : point_range;
               first_point: point_range 
                            renames current_stroke.points.First_index;
            begin 
               -- Note: we don't glue onto ourselves, and we don't glue onto
               --       other strokes which have < dot_spread spreading,
               --       so do the check for all other strokes than those
               if not (stroke_number = at_stroke_number or
                       current_stroke.spread < dot_spread) then
                  -- Check the distance to the first point
                  dist := Magnitude(for_vector => 
                      The_Vector(for_start => a_point, 
                                 and_end=>current_stroke.points(first_point)));
                  if dist < min then
                     min := dist;
                  end if;
                  
                  -- Find the lowest distance from the glue point to any other
                  -- point on the other stroke
                  for point_no in current_stroke.points.First_Index .. 
                                  current_stroke.points.Last_Index -1 loop
                     declare
                        len_vector, width_vector : vector;
                        dist, mag, dot           : float;
                     begin
                        -- Vector length (i.e. len_vector) is a unit vector 
                        -- from the point at point_no to point_no + 1
                        Initialise(len_vector,
                                   at_start=>current_stroke.points(point_no),
                                   at_end  =>current_stroke.points(point_no+1));
                        Normalise(len_vector, len_vector, mag);
                        -- Vector width is a vector from the point at 'point_no'
                        -- to our point, 'a_point'
                        Initialise(width_vector, 
                                   at_start => current_stroke.points(point_no),
                                   at_end => a_point);
                        -- For points that are not in between a segment, get
                        -- the distance from the points themselves, otherwise
                        -- get the distance from the segment line
                        dot := len_vector * width_vector;  -- dot product
                        if dot < 0.0 or dot > mag
                        then
                           dist := Magnitude(The_Vector(
                                  for_start=>current_stroke.points(point_no+1),
                                  and_end=>a_point));
                        else  -- magnitude of the cross product
                           dist := Magnitude(width_vector * len_vector);
                        end if;
                        if dist < min then
                           min := dist;
                        end if;
                     end;
                  end loop;
                  gluable:= point_range(float'Truncation (min)) * 
                            point_range(maximum_gluable_entries)/glue_distance;
                  case scan_number is
                     when first_pass =>
                        sample_stroke.gluable_start(stroke_number) := gluable;
                     when last_pass => 
                        sample_stroke.gluable_end  (stroke_number) := gluable;
                  end case;
               end if;
            end;
         end loop;
      end loop;
   end Process_Gluable;
   
  -- Properties  
  
   procedure Process(the_sample : in out sample_type) is
      -- Generate cached properties of a sample.  These properties are used
      -- when doing comparisons between input sample being recognised and
      -- training samples.  It is applied to both training samples (and then
      -- stored in the database of training samples) and the sample being
      -- recognised.
      distance : float := 0.0;
   begin
      Error_Log.Debug_Data(at_level=>8,with_details=>"Process(sample):start.");
      -- Compute properties for each stroke
      Initialise(the_sample.centre);  -- to default of (0, 0, 0)
      Error_Log.Debug_Data(at_level=>9,with_details=>"Process(sample):initialised centre.");
      for stroke_number in the_sample.strokes.First_Index .. 
                           the_sample.strokes.Last_Index loop
         declare
            the_stroke : Stroke_Management.stroke 
                                     renames the_sample.strokes(stroke_number);
            stroke_no_1: constant natural := the_sample.strokes.First_Index;
            weight     : float;
            points     : point_range;
         begin
            -- Add the stroke centre to the centre vector, weighted by length
            if the_stroke.spread < dot_spread
            then
               weight := float(dot_spread);
            else
               weight := the_stroke.distance;
            end if;
            the_sample.centre:= the_sample.centre + the_stroke.centre * weight;
            distance := distance + weight;
            
            -- Get gluing distances
            Process_Gluable(for_sample => the_sample, 
                            at_stroke_number => stroke_number);
            
            -- Create a rough-sampled version
            -- first calculate points as a fraction of distance
            Error_Log.Debug_Data(at_level=>9,with_details=>"Process(sample): calculating points. the_stroke.distance =" & Put_Into_String(the_stroke.distance,3) & ", rough_resolution =" & Put_Into_String(rough_resolution,3) & ".");
            points:= point_range(the_stroke.distance / rough_resolution + 0.5);
            if points < 4
            then  -- minimum points in roughs needs to be 4
               points := 4;
            end if;
            Error_Log.Debug_Data(at_level=>9,with_details=>"Process(sample): at stroke number " & stroke_number'Wide_Image & ", points for roughs =" & points'Wide_Image & ".");
            -- then make sure that the roughs array is big enough
            while natural(the_sample.roughs.Length) < (stroke_number - stroke_no_1 + 1) loop
               the_sample.roughs.Append(New_Stroke);
            end loop;
            -- now the roughs for this stroke
            the_sample.roughs(stroke_number) := 
                        Stroke_Management.ReSample(the_stroke, points, points);
         end;
      end loop;
      the_sample.centre := the_sample.centre / distance;
      the_sample.distance := distance;
   end Process;

begin
   Cell_Writer_Version.Register(revision => "$Revision: v1.0.0$",
                                for_module => "Samples");
end Samples;
