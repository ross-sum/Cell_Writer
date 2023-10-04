-----------------------------------------------------------------------
--                                                                   --
--                            S T R O K E                            --
--                                                                   --
--                     S p e c i f i c a t i o n                     --
--                                                                   --
--                           $Revision: 1.0 $                        --
--                                                                   --
--  Copyright (C) 2022-23  Hyper Quantum Pty Ltd.                    --
--  Written by Ross Summerfield.                                     --
--                                                                   --
--  This  package manages the strokes for hand writing recognition.  --
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
-- with dStrings;
-- with Vectors;  use Vectors;
with Error_Log;
with Ada.Characters.Conversions;
with Cell_Writer_Version;
package body Stroke_Management is
   use dStrings;
    
   -- Define the points and angles for setting up an open-ended array
   -- of points (and of angles).
   -- package Points_Arrays is new Ada.Containers.Vectors
   --       (index_type   => natural,
   --        element_type => point);
   -- package Angles_Arrays is new Ada.Containers.Vectors
   --       (index_type   => natural,
   --        element_type => angle);
   -- subtype points_array is Points_Arrays.vector;
   -- subtype angles_array is Angles_Arrays.vector;
    -- 
   -- type Stroke is record
         -- centre        : point;
         -- distance      : float;
         -- length        : point_range;
         -- size          : point_range;
         -- spread        : float;
         -- processed     : boolean;
         -- gluable_start : gluable_entries := (others => 0);
         -- gluable_end   : gluable_entries := (others => 0);
         -- min           : point;
         -- max           : point;
         -- points        : points_array;
         -- angles        : angles_array;
      -- end record;
      
  -- Generalised measure function  
   -- type MeasureFunc is access function
   --      (arg1 : access stroke;
   --       arg2 : integer;
   --       arg3 : access stroke;
   --       arg4 : integer;
   --       arg5 : stroke) return float;

   procedure Reverse_Copy_Points(from: in stroke; to: in out stroke;
                                 append : in boolean := false) is
     -- reverse copy the points and angles from one stroke to another.
      use Points_Arrays, Angles_Arrays;
      source_points : points_array := from.points;
      source_angles : angles_array renames from.angles;
      dest_points   : points_array renames to.points;
      dest_angles   : angles_array renames to.angles;
      the_angle     : angle;
   begin
      Error_Log.Debug_Data(at_level=>8,with_details=>"Reverse_Copy_Points: start.");
      if not append then  -- empty the destination
         Points_Arrays.Clear(dest_points);
         Angles_Arrays.Clear(dest_angles);
      end if;
      for item in source_angles.First_Index .. source_angles.Last_Index loop
         -- Get the angle for pointing in the opposite direction
         if item < source_angles.Last_Index
         then  -- there is an angle to the point after this
            the_angle := source_angles(source_angles.Last_Index - item - 1);
            if the_angle > 180.0
            then  -- looking for the_angle + 180, trimmed to be within 0..360
               the_angle := the_angle - 180.0;
            else  -- set to the_angle + 180
               the_angle := the_angle + 180.0;
            end if;
         else  -- there isn't an angle to the point after this
            the_angle := 0.0;
         end if;
         -- Get the reverse point's reverse angle and set it
         Angles_Arrays.Append(dest_angles, the_angle);
      end loop;
      -- Reverse the source points array and append it to the destination
      Points_Arrays.Reverse_Elements(source_points);
      Points_Arrays.Append(dest_points, source_points);
      Error_Log.Debug_Data(at_level=>8,with_details=>"Reverse_Copy_Points: end.");
   end Reverse_Copy_Points;

     -- Stroke allocation  
   function New_Stroke return Stroke is
      -- External_Name => "stroke_new";
      -- Initialise the stroke, setting the size (by default set to 
      -- points_granualarity).
      result : stroke;
   begin
      Error_Log.Debug_Data(at_level=> 8, with_details=> "New_Stroke: start.");
      Clear(the_stroke => result);
      return result;
   end New_Stroke;

   function Clone(the_stroke: in Stroke; in_reverse: boolean) return stroke is
         -- External_Name => "stroke_clone";
      use Ada.Containers;
      temp : stroke := the_stroke;
   begin
      Error_Log.Debug_Data(at_level=>8, 
                           with_details=>"Clone(the_stroke): start.");
      if (not Points_Arrays.Is_Empty(the_stroke.points)) and in_reverse then
         Reverse_Copy_Points(from => the_stroke, to => temp);  
      end if;
      return temp;
   end Clone;

   procedure Free(the_stroke : in out Stroke) is  -- ./recognize.h:58
         -- External_Name => "stroke_free";
   begin
      Error_Log.Debug_Data(at_level=>8, with_details=>"Free(stroke): start.");
      -- This procedure would apply if the_stroke were an access type
      null;
   end Free;

   procedure Clear(the_stroke : in out Stroke) is
         -- External_Name => "clear_stroke";
      -- the_size : point_range := the_stroke.size;
   begin
      Error_Log.Debug_Data(at_level=>8, 
                           with_details=>"Clear(the_stroke): start.");
      -- the_stroke.size := the_size;
      the_stroke.distance := 0.0;
      the_stroke.spread := 0.0;
      Initialise(the_stroke.centre);
      Initialise(the_stroke.max);
      Initialise(the_stroke.min);
      the_stroke.processed := false;
      Points_Arrays.Clear(the_stroke.points);
      Angles_Arrays.Clear(the_stroke.angles);
   end Clear;

  -- Stroke manipulation  
   procedure Process(the_stroke : in out stroke) is
      use Ada.Containers;
     -- Generate cached parameters of a stroke.
     -- This includes setting up the bounding box (i.e. 'the spread') for the
     -- stroke, described in the 2 diagonal corners by Min and Max, setting up
     -- the angles for each stroke point, the stroke centre and the stroke
     -- distance (which, of course, is the sum of the magnitudes, i.e. total
     -- stroke length).
     -- As a first step in proccessing, the stroke is smoothed and simplified, 
      i       : point_range;
      distnce : float := 0.0;
      first_pt: natural; 
   begin
      Error_Log.Debug_Data(at_level=>8,with_details=>"Process(stroke): start.");
      if the_stroke.processed then
         -- Error_Log.Debug_Data(at_level=>9,
            --                with_details=>"Process(stroke):already processed.");
         return;
      end if;
      the_stroke.processed := true;
      
      -- Smooth out the points on the stroke and then remove redundant points.
      Smooth(the_stroke);
      Simplify(the_stroke);
      
      -- Check that there is some data to process
      if Points_Arrays.Is_Empty(the_stroke.points)
      then
         raise NO_POINTS_ERROR;
      else
         first_pt := the_stroke.points.First_Index;
      end if;   
      
      -- Dot strokes
      if the_stroke.points.Length = 1
      then
         the_stroke.centre := the_stroke.points(first_pt);
         the_stroke.spread := 0.0;
         return;
      end if;
      
      -- Min and Max describe the 2 corners of the bounding box for the stroke
      the_stroke.min := the_stroke.points(first_pt);
      the_stroke.max := the_stroke.min;
      for point_num in the_stroke.points.First_Index .. 
                     the_stroke.points.Last_Index - 1 loop
         declare
            weight : float;
         begin
            -- Check that the angle array entry exists; create if not
            while natural(the_stroke.angles.Length)<(point_num-first_pt+1) loop
               the_stroke.angles.Append(0.0);
            end loop;
            i := point_num - first_pt + the_stroke.angles.First_Index;
            -- Angle (now goes from point i to i+1)
            the_stroke.angles(i):= Direction(
                       The_Vector(for_start=> the_stroke.points(point_num), 
                                  and_end  => the_stroke.points(point_num+1)));
            -- Point contribution to spread
            if X(the_stroke.points(point_num+1)) < X(the_stroke.min) then
               Set_X(for_point => the_stroke.min, 
                     to        => X(the_stroke.points(point_num+1)));
            end if;
            if Y(the_stroke.points(point_num+1)) < Y(the_stroke.min) then
               Set_Y(for_point => the_stroke.min, 
                     to        => Y(the_stroke.points(point_num+1)));
            end if;
            if X(the_stroke.points(point_num+1)) > X(the_stroke.max) then
               Set_X(for_point => the_stroke.max, 
                     to        => X(the_stroke.points(point_num+1)));
            end if;
            if Y(the_stroke.points(point_num+1)) > Y(the_stroke.max) then
               Set_Y(for_point => the_stroke.max, 
                     to        => Y(the_stroke.points(point_num+1)));
            end if;
            -- Segment contribution to centre
            weight := Magnitude(
                       The_Vector(for_start=>the_stroke.points(point_num), 
                                  and_end  =>the_stroke.points(point_num+1)));
            distnce := distnce + weight;
            the_stroke.centre := the_stroke.centre + 
                                 (the_stroke.points(point_num)+
                                  the_stroke.points(point_num+1))*
                                        (weight / 2.0);
         end;
      end loop;
      if distnce /= 0.0
      then
         the_stroke.centre := the_stroke.centre * (1.0 / distnce);
      else
         Error_Log.Put(the_error => 21,
                       error_intro => "Process(stroke) error", 
                       error_message=>"Dividing by zero distance.");
      end if;
      -- Note: M. Levin's C code would have incremented i on loop exit.
      i := the_stroke.angles.Last_Index;
      -- Check that the angle array last entry exists; create if not
      if natural(the_stroke.angles.Length) < natural(the_stroke.points.Length)
      then  -- doesn't exist, so create and set
         i := i + 1;
         the_stroke.angles.Append(the_stroke.angles(i - 1));
      else -- exists, so just set
         the_stroke.angles(i) := the_stroke.angles(i - 1);
      end if;
      the_stroke.distance  := distnce;
      
      -- Stroke spread (maximum of X or Y between max and min (/= distance))
      the_stroke.spread := X(the_stroke.max) - X(the_stroke.min);
      if Y(the_stroke.max) - Y(the_stroke.min) > the_stroke.spread then
         the_stroke.spread := Y(the_stroke.max) - Y(the_stroke.min);
      end if;
   end Process;

   procedure Add (a_point : point; to_the_stroke : in out stroke) is
         -- External_Name => "draw_stroke";
     -- Add a point in scaled coordinates to a stroke.  The points are supplied
     -- to this Add procedure in already 'scaled', that is, normalised format.
     -- In this format, the origin of the points is moved from bottom left hand
     -- edge to the centre of the cell and the height and width are scaled
     -- against the full 'point_scale' using the cell height, noting that the
     -- cell height is (or should be) always bigger than the cell width.
     -- This procedure does some basic checks to ensure there are not too many
     -- points per stroke and that the points fit within the range of the cell.
     -- It may be possible that a point or two falls outside the bounding box
     -- of the cell and they are clipped to be at the cell edge.
      use Ada.Containers;
      new_point  : point := a_point;
      the_stroke : stroke renames to_the_stroke;
   begin
      Error_Log.Debug_Data(at_level=>8, with_details=>"Add (a_point): start.");
      -- Create a new stroke if necessary
      if Points_Arrays.Is_Empty(the_stroke.points) then
         the_stroke := New_Stroke;
      end if;
      -- If we run out of room, resample the stroke to fit
      if point_range(the_stroke.points.Length) >= maximum_points then
         the_stroke := ReSample(the_stroke, 
                          num_of_points => maximum_points - points_granularity,
                          with_size => maximum_points);
      end if;
      -- Enforce range limits on the point
      if X(new_point) <= float(-point_scale / 2)
      then
         Set_X(for_point => new_point, to => float(-point_scale / 2 + 1));
      elsif X(new_point) >= float(point_scale / 2)
      then
         Set_X(for_point => new_point, to => float(point_scale / 2 - 1));
      end if;
      if Y(new_point) <= float(-point_scale / 2)
      then
         Set_Y(for_point => new_point, to => float(-point_scale / 2 + 1));
      elsif Y(new_point) >= float(point_scale / 2)
      then
         Set_Y(for_point => new_point, to => float(point_scale / 2 - 1));
      end if;
      
      -- Append the point and an empty angle for the end
      Points_Arrays.Append(the_stroke.points, new_point);
      Angles_Arrays.Append(the_stroke.angles, 0.0);
   end Add;

   procedure Smooth(the_stroke : in out Stroke) is
         -- External_Name => "smooth_stroke";
      -- Smooth stroke points by moving each point halfway toward the line
      -- between its two neighbours.  This is the first step in preprocessing.
      -- While modern pen digitisers are very accurate, some distortion is still
      -- produced. In particular, the “staircase effect” that results from
      -- snapping the pointer position to the nearest pixel or hardware grid
      -- unit can complicate segment angle measurements.
      -- This first stage of preprocessing uses a simple smoothing algorithm
      -- to remove this kind of distortion. Each point in a stroke is moved
      -- halfway toward the straight line formed by connecting that point’s
      -- two immediate neighbours. This removes digitiser distortion without
      -- significantly altering the intended stroke. For every point b and
      -- its immediate neighbours a and c the smoothed point b' is
      -- computed by:
      -- b' = (a+b)/2 + (((b-a).(c-a))(c-a))/(2||c-a||**2)
      function Point_Projection(a, b : in point) return point is
         dist  : float;
         mag   : float;
         vec_a : vector := The_Vector(for_start => origin, and_end => a);
         vec_b : vector := The_Vector(for_start => origin, and_end => b);
      begin
         dist := Dot_Product(vec_a, vec_b);
         mag  := Magnitude(vec_b);
         mag := mag * mag;  -- we actually want the square of magnitude
         return b * dist / mag;
      end Point_Projection;
      last_point : point;
      a, b, c  : point;
   begin
      Error_Log.Debug_Data(at_level=>8,with_details=>"Smooth(stroke): start.");
      -- grab the first point
      last_point := the_stroke.points(the_stroke.points.First_Index);
      -- we start off at the second point, having already got the first one
      for point_no in the_stroke.points.First_Index + 1 .. 
                  the_stroke.points.Last_Index - 1 loop
         -- If the last point is the same as the next point, then no smoothing
         -- is required; smoothing only required if not the same
         if last_point = the_stroke.points(point_no + 1)
         then
            last_point := the_stroke.points(point_no);
         else  -- last point (and this point?) and next point are different
            -- b' = (a+b)/2 + (((b-a).(c-a))(c-a))/(2||c-a||**2)
            a  := last_point;                      -- a = last point
            b  := the_stroke.points(point_no);     -- b = this point
            c  := the_stroke.points(point_no + 1); -- c = next point
            last_point := the_stroke.points(point_no);
            the_stroke.points(point_no) := 
                      b + (a + Point_Projection(b - a, c - a) - b) * 0.5 + 0.5;
            -- annul that 0.5 in the (unused) z plane (just to avoid trouble)
            Set_Z(for_point => the_stroke.points(point_no), to => 0.0);
         end if;
      end loop;
   end Smooth;

   procedure Simplify(the_stroke : in out Stroke) is
         -- External_Name => "simplify_stroke";
      -- Remove excess points between neighbours, the second part of initial 
      -- pre-processing (done in conjunction with Smooth).
      -- Additionally, input is simplified by removing any redundant points
      -- that are not a significant distance away from the straight line
      -- formed by their neighbours.
      use Points_Arrays, Angles_Arrays;
      point_no: natural;
      len_vector, width_vector : Vectors.vector;
      mag     : float;
      dp      : float;
      dist    : float;
      offset  : natural := 0;
   begin
      Error_Log.Debug_Data(at_level=>8,with_details=>"Simplify(stroke): start.");
      -- Work out the offset between points and angles (should be 0)
      if not (Is_Empty(the_stroke.points)) or Is_Empty(the_stroke.angles) then
         offset := the_stroke.angles.First_Index-the_stroke.points.First_index;
      end if;
      point_no := the_stroke.points.First_Index + 1;
      while point_no < the_stroke.points.Last_Index loop
         -- Vector length (i.e. len_vector) is a unit vector from the point at
         -- 'point_no - 1' to the point at 'point_no + 1'
         Initialise(the_vector => len_vector,
                    at_start   => the_stroke.points(point_no - 1), 
                    at_end     => the_stroke.points(point_no + 1));
         Normalise(the_vector => len_vector, against_vector => len_vector, 
                   mag => mag);
         -- Vector width is a vector from the point at 'point_no - 1' to our
         -- point at 'point_no'
         Initialise(the_vector => width_vector,
                    at_start   => the_stroke.points(point_no - 1), 
                    at_end     => the_stroke.points(point_no));
         -- Do not touch mid points that are not in between their neighbours
         -- get the dot product:
         dp := len_vector * width_vector;
         if not (dp < 0.0 or dp > mag)
         then  -- not touching those mid points
            -- Remove any points that are less than some threshold away
            -- from their neighbour points
            -- Distance is the absolute value of the magnitude of the
            -- cross product.
            -- --dist := Cross_Product_Mag(len_vector, width_vector);
            dist := Magnitude(len_vector * width_vector);
            if dist < simplify_threshold
            then  -- (dist in the range +/- simp._thresh.) delete this point
               the_stroke.points.Delete(point_no);
               if natural(the_stroke.angles.Length) >= point_no then
                  the_stroke.angles.Delete(point_no + offset);
               end if;
               -- (and, as we've deleted a point, the point_no now points to the
               --  next one, so we don't move point_no on by one)
            else  -- move onto the next point
               point_no := point_no + 1;
            end if;
         else  -- touching those mid points, so move onto the next point
            point_no := point_no + 1;
         end if;
      end loop;
      Error_Log.Debug_Data(at_level=>9,with_details=>"Simplify(stroke): end.");
   end Simplify;

   function ReSample (the_stroke    : stroke;
                      num_of_points : point_range;
                      with_size     : point_range) return stroke is
         -- External_Name => "sample_stroke";
      -- Recreate the stroke by sampling at regular distance intervals.
      -- ReSampled strokes always have angle data.
      -- In recreating the stroke, ensure that the stroke is of the specified
      -- number of points at a regular spacing, as guided by 'with_size'.
      -- (In actual fact, the number of points is the lesser of 'num_of_points'
      -- and 'with_size', after each has had some range (.i.e. sanity) checks
      -- applied to their values.)
      --
      -- This function may extend out or shorten the length of the points
      --  array.  It then does a redistribution of points.
      -- As a side note, in this program, the points array is dynamically
      -- extensible as we make it a standard package linked list (by using the
      -- Ada.Containers.Vectors).
      use Ada.Containers;
      the_points : point_range:= num_of_points;-- total number of sample points
      the_size   : point_range:= with_size;    -- stroke size
      len        : point_range;   -- number of points in the resultant stroke
      dist_i,                     -- distance between current and next point
                                  -- for the resultant stroke.  This is evenly
                                  -- spread (i.e. inter-point distance is
                                  -- constant).
      dist_j,                     -- distance between current and next point
                                  -- for 'the_stroke' and varies as, if the
                                  -- resultant stroke has less points, may
                                  -- skip a point or two.
      dist_per_pt: float;         -- average distance per point (using points)
      i,                          -- target result point number for insertion
      j          : point_range:=1;-- source the_stroke point number to insert
      o          : point_range;   -- Offset between points and angles arrays
      result     : stroke;
   begin
      Error_Log.Debug_Data(at_level=>8, with_details=>"ReSample: start.");
      -- do some basic error checking
      if Points_Arrays.Is_Empty(the_stroke.points)
      then  -- stroke not yet initialised or loaded with any points
         Error_Log.Put(the_error => 22,
                       error_intro => "ReSample error", 
                       error_message=>"Attempted to sample an invalid stroke");
         Clear(result);
         return result;
      end if;
      -- Check ranges
      if the_size > maximum_points then
         Error_Log.Put(the_error => 23,
                   error_intro =>  "ReSample warning", 
                   error_message=> "Stroke sized to maximum length possible.");
         the_size := maximum_points;
      end if;
      if the_points > maximum_points then
         Error_Log.Put(the_error => 24,
                 error_intro =>  "ReSample warning", 
                 error_message=> "Stroke sampled to maximum length possible.");
         the_points := maximum_points;
      end if;
      if the_size < 1 then
         the_size := 1;
      end if;
      if the_points < 1 then
         the_points := 1;
      end if;
      
      -- Allocate memory and copy cached data to the result
      Clear(result);
      Points_Arrays.Clear(result.points);
      Angles_Arrays.Clear(result.angles);
      -- result.size := the_size;
      -- Len is the lesser of size and points (- 1) and the number of points
      -- will be at the lesser of size and points (i.e. len + 1).
      if the_size < the_points
      then
         len := the_size - 1;
      else
         len := the_points - 1;
      end if;
      result.spread := the_stroke.spread;  -- these will remain the same
      result.centre := the_stroke.centre;
      
      -- Error_Log.Debug_Data(at_level=>8, with_details=>"ReSample: checking for special case.");
      -- Special case for (re)sampling a single point
      if the_stroke.points.Length = 1 or the_points = 1
      then  -- load in source the_stroke's first point and angle
         for item in 0 .. len loop
            Points_Arrays.Append(result.points, 
                             the_stroke.points(the_stroke.points.First_Index));
            Angles_Arrays.Append(result.angles,
                             the_stroke.angles(the_stroke.angles.First_Index));
         end loop;
         result.distance := 0.0;
         -- Error_Log.Debug_Data(at_level=>8, with_details=>"ReSample: single point.");
         return result;
      end if;
      
      -- For all other cases, where we are sampling multiple points...
      dist_per_pt := the_stroke.distance / float(the_points - 1);
      result.distance := the_stroke.distance;  -- this won't change
      j := the_stroke.points.First_Index;
      dist_j := Magnitude(for_vector => 
                              The_Vector(for_start => the_stroke.points(j), 
                                         and_end => the_stroke.points(j + 1)));
      dist_i := dist_per_pt;
      -- initialise the result with the first point (and angle)
      Points_Arrays.Append(result.points, the_stroke.points(j));
      Angles_Arrays.Append(result.angles, 
                           the_stroke.angles(the_stroke.angles.First_Index));
      -- Now we have an angle, calculate the difference (i.e. offset) between
      -- the points and the angles arrays (should, in fact, be 0)
      o := the_stroke.angles.First_Index - the_stroke.points.First_Index;
      -- Error_Log.Debug_Data(at_level=>8, with_details=>"ReSample: checking each point.");
      Each_Result_Point :
      for point_cntr in 1 .. len - 1 loop
         -- Preserve loop counter to know how many times we actually looped,
         -- pointing to the relevant stroke point that we are copying from.
         -- This will be used for adding in the remaining points required.
         i := point_cntr;
         -- Advance our position
         Dist_i_Calculation :  -- advance j to the next point (if required)
         while dist_i >= dist_j loop
            if j >= the_stroke.points.Last_Index - 1
            then  -- exhausted all source the_stroke points already
               exit Each_Result_Point;
            end if;
            dist_i := dist_i - dist_j;
            j := j + 1;
            dist_j := Magnitude(for_vector => 
                              The_Vector(for_start => the_stroke.points(j), 
                                         and_end => the_stroke.points(j + 1)));
         end loop Dist_i_Calculation;
         -- Error_Log.Debug_Data(at_level=>8, with_details=>"ReSample: advanced position.");
         -- Interpolate points and load to the result (at element 'i')
         Points_Arrays.Append(result.points, the_stroke.points(j) +
                              ((the_stroke.points(j+1)-the_stroke.points(j)) *
                                                               dist_i/dist_j));
         Angles_Arrays.Append(result.angles, the_stroke.angles(j+o));
         -- and crank out Result's dist_i by the inter-point distance
         dist_i := dist_i + dist_per_pt;
      end loop Each_Result_Point;
      -- Error_Log.Debug_Data(at_level=>8, with_details=>"ReSample: finishing up.");
      
      -- fill in the last few points (if any, but at least the last one) in the
      -- result with the point after the one we stopped at above
   <<Finish_Up>>
      -- Error_Log.Debug_Data(at_level=>8, with_details=>"ReSample: <<Finish_Up>>: i = " & Put_Into_String(i) & ", j = " & Put_Into_String(j) & ", o =  " & Put_Into_String(o) & ", len = " & Put_Into_String(len) & ".");
      for point_cntr in i .. len loop
         Points_Arrays.Append(result.points, the_stroke.points(j+1));
         Angles_Arrays.Append(result.angles, the_stroke.angles(j+o+1));
      end loop;
      -- Error_Log.Debug_Data(at_level=>8, with_details=>"ReSample: finished.");
      
      return result;
   end ReSample;

   procedure Sample_Strokes (a, b : in stroke;
                             as, bs : out stroke) is
      -- Sample multiple strokes to equal lengths.
      -- That is, take the two strokes, 'a' and 'b', and put them into the two
      -- sampled strokes, 'as' and 'ab', which are both of the same length.
      -- This is done by getting the maximum of the 'distances', which is
      -- actually the stroke's end to end lengths, then working out how many
      -- points (and therefore the (equal) spacing between the points), and
      -- then resampling each to yield the two results.
      dist : float;
      points : point_range;
   begin
      Error_Log.Debug_Data(at_level=>8, with_details=>"Sample_Strokes: start.");
      -- Find the sample length
      dist := a.distance;
      if b.distance > dist then
         dist := b.distance;
      end if;
      points := 1 + point_range(dist / fine_resolution);
      if points = maximum_points then
         points := maximum_points;
      end if;
      
      as := ReSample(a, num_of_points => points, with_size => points);
      bs := ReSample(b, num_of_points => points, with_size => points);
   end Sample_Strokes;

   procedure Glue (the_stroke : in Stroke;          -- b*
                   to         : in out stroke;      -- pa** / a*
                   in_reverse : boolean) is
      -- Glue 'the_stroke' onto the end of 'to' preserving processed properties
      -- that may exist in 'to' (but put 'the_stroke' properties in if 'to' has
      -- no points), simply adjusting the centre and distance.
      -- If in_reverse is specified as true, then do the gluing of 'the_stroke'
      -- from the far end (i.e. last points) rather than the near end (i.e.
      -- starting from the first point).
      use Ada.Containers;
      from_centre    : point := the_stroke.centre * the_stroke.distance;
      start          : point;
      glue_segment   : vector;
      glue_centre    : point;
      glue_mag       : float;
      dest_start_len : natural := 0;  -- used when calculating joint's angle
   begin
      Error_Log.Debug_Data(at_level=>8, with_details=>"Glue: start.");
      -- If there is no stroke to glue to, just copy
      if Points_Arrays.Is_Empty(to.points)
      then  -- there is no other stroke yet, so just do a copy
         to := Clone(the_stroke, in_reverse);
      else  -- a stroke exists to glue on
         dest_start_len := to.points.Last_Index;  -- save for later use
         -- Gluing two strokes creates a new segment between them
         begin  -- set up a block to trap an exception should there be an error
            if in_reverse
            then
               start := the_stroke.points(the_stroke.points.Last_Index);
            else
               start := the_stroke.points(the_stroke.points.First_Index);
            end if;
            exception
               when Constraint_Error => -- the_stroke is also of zero length
                  Error_Log.Put(the_error => 25,
                                error_intro => "Glue error", 
                                error_message=>"Gluing on zero length stroke.");
                  start := origin;
         end;
         Initialise (the_vector => glue_segment, 
                     at_start   => to.points(to.points.Last_Index), 
                     at_end     => start);
         glue_centre := (start + to.points(to.points.Last_Index))/2.0;
         glue_mag := Magnitude(glue_segment);
         -- Compute the new spread
         if X(the_stroke.min) < X(to.min) then
            Set_X(for_point => to.min, to => X(the_stroke.min));
         end if;
         if X(the_stroke.max) > X(to.max) then
            Set_X(for_point => to.max, to => X(the_stroke.max));
         end if;
         if Y(the_stroke.min) < Y(to.min) then
            Set_Y(for_point => to.min, to => Y(the_stroke.min));
         end if;
         if Y(the_stroke.max) > Y(to.max) then
            Set_Y(for_point => to.max, to => Y(the_stroke.max));
         end if;
         to.spread := X(to.max) - X(to.min);
         if Y(to.max) - Y(to.min) > to.spread then
            to.spread := Y(to.max) - Y(to.min);
         end if;
         -- Compute the new centre point
         to.centre := to.centre * to.distance;
         glue_centre := glue_centre * glue_mag;
         to.centre := to.centre + (the_stroke.centre * the_stroke.distance) + 
                      glue_centre;
         to.centre := to.centre / (to.distance +the_stroke.distance +glue_mag);
         -- Copy the points
         if not in_reverse or the_stroke.points.Length < 2
         then  -- either doing a straight copy or (when length = 1 or 0 points)
               -- the stroke length is same in either forward or reverse
            Points_Arrays.Append(to.points, the_stroke.points);
            Angles_Arrays.Append(to.angles, the_stroke.angles);
         else  -- do a reverse copy of the points
            Reverse_Copy_Points(from => the_stroke, to => to, append => true);
         end if;
         -- Adjust the angle at the join point
         to.angles(dest_start_len) := Direction(glue_segment);
         -- and adjust the distance to the new value
         to.distance := to.distance + glue_mag + the_stroke.distance;
      end if;
      Error_Log.Debug_Data(at_level=>8, with_details=>"Glue: end.");
   end Glue;

   procedure Dump(the_stroke : in Stroke) is
        -- External_Name => "dump_stroke";
      use Points_Arrays;
   begin
      -- print statistics
      Error_Log.Debug_Data(at_level => 1, with_details => "Stroke data --");
      Error_Log.Debug_Data(at_level => 1, 
                           with_details=> "Distance: " & 
                                       Put_Into_String(the_stroke.distance,2));
      Error_Log.Debug_Data(at_level => 1, 
                           with_details=> "  Centre: (" & 
                                  Put_Into_String(X(the_stroke.centre),2)&","&
                                  Put_Into_String(Y(the_stroke.centre),2)&")");
      Error_Log.Debug_Data(at_level => 1, 
                           with_details=> "  Spread: " & 
                                        Put_Into_String(the_stroke.spread,2));
      Error_Log.Debug_Data(at_level => 1, 
                           with_details=> Put_Into_String(the_stroke.spread,2)& 
                                          " points --");
      -- print point data
      for item in the_stroke.points.Iterate loop
         Error_Log.Debug_Data(at_level => 1,
                           with_details=> "  "&Put_Into_String(To_Index(item))&
                                          ": (" &
                                Put_Into_String(X(the_stroke.points(item)),2)&
                                          "," &
                                Put_Into_String(Y(the_stroke.points(item)),2));
      end loop;
   end Dump;

   function Measure_Distance
     (a : in Stroke;
      i : integer;
      b : in Stroke;
      j : integer;
      offset : point) return float is
      -- Measure the square of the offset Euclidean distance between two points
      point_a : point := a.points(i) + offset;
      point_b : point renames b.points(j);
      result   : float;
   begin
      -- We are doing the operation of (b-a) with the offset is applied to
      -- a's points[i], and Magnitude does a - b.
      result:= Magnitude(The_Vector(for_start => point_a, and_end => point_b));
      -- As this actually requires the square of the distance, 
      -- calculate the square of the result.
      return result * result;
      exception
         when Constraint_Error =>
             -- index i or index j is out of range
            Error_Log.Put(the_error => 26,
                          error_intro =>  "Measure_Distance error", 
                          error_message=> "Either a.points(i) or b.points(j)" &
                                          " is out of range.");
            raise;  -- re-raise it (for now)
   end Measure_Distance;

   function Measure_Strokes
     (a : in Stroke;
      b : in Stroke;
      Func : MeasureFunc;
      extra : point;
      points : point_range;
      elasticity : integer) return float is
      -- Find optimal match between A points and B points for lowest distance
      -- via dynamic programming
      subtype array_range is natural range 0 .. ((points+1) * (points+1) + 1);
      type table_array is array (array_range'range) of float;
      table : table_array;
      the_points : point_range := points;
      j_to  : natural;
      j     : natural;
      value : float;
   begin
      Error_Log.Debug_Data(at_level=>8, with_details=>"Measure_Strokes: start.");
      -- We could be touching the table array prior to a cell initialisation.
      -- Zero it out just in case, so this is operating from a known value.
      -- (Note: Michael didn't do this.)
      for item in array_range loop
         table(item) := 0.0;
      end loop;
      -- Coordinates are counted from 1 because of buffer areas
      the_points := the_points + 1;
      -- Fill out the buffer row
      j_to := elasticity + 2;
      if the_points < j_to then  -- restrict range of j_to to <= the points
         j_to := the_points;
      end if;
      for item in 1 .. j_to - 1 loop
         table(item) := float'Last;
      end loop;
      
      -- The first table entry is given
      table(the_points + 1) := 2.0 * Func(a, 0, b, 0, extra);
      
      -- 
      for i in 1 .. the_points - 1 loop
         -- Starting position
         if i - elasticity < 1
         then
            j := 1;
         else
            j := i - elasticity;
         end if;
         -- Buffer column entry
         table(i * the_points + j - 1) := float'Last;
         -- Start from the 2nd cell on the first row (j += i == 1) wtf!
         if i = 1 then j := j + 1; end if;
         -- End limit
         j_to := i + elasticity + 1;
         if j_to > the_points then
            j_to := the_points;
         end if;
         --  Start with up-left
         value := table((i - 1) * the_points + j - 1);
         
         -- Dynamically program the row segment
         while j < j_to loop
            declare
               low_value : float;
               measure   : float;
            begin
               measure   := Func(a, i - 1, b, j - 1, extra);
               low_value := value + measure * 2.0;
               -- Check if left is lower
               value := table(i * the_points + j - 1);
               if value + measure < low_value then
                  low_value := value + measure;
               end if;
               -- Check if up is lower
               value := table((i - 1) * the_points + j);
               if value + measure < low_value then
                  low_value := value + measure;
               end if;
               table(i * the_points + j) := low_value;
            end;
            j := j + 1;
         end loop;
         --  End of the row buffer
         table(i * the_points + j_to) := float'Last;
      end loop;
      
      -- Return final lowest progression
      return table(the_points * the_points - 1) / float((the_points - 1) * 2);
      exception
         when Constraint_Error =>
             -- index i or index j is out of range
            Error_Log.Put(the_error => 27,
                          error_intro =>  "Measure_Strokes error", 
                          error_message=> "Likely a Measure_Distance error. " &
                                          "Either a.points(i) or b.points(j)" &
                                          " is out of range.");
            return 0.0;  -- send back zero result (for now)
   end Measure_Strokes;

begin
   Cell_Writer_Version.Register(revision => "$Revision: v1.0.0$",
                                for_module => "Stroke_Management");
end Stroke_Management;
