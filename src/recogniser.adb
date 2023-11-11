-----------------------------------------------------------------------
--                                                                   --
--                        R E C O G N I S E R                        --
--                                                                   --
--                              B o d y                              --
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
-- with GNATCOLL.SQL.Exec;
-- with Ada.Containers.Vectors;
-- with dStrings;          use dStrings;
-- with Vectors;           use Vectors;
-- with dStrings;          use dStrings;
-- with Vectors;           use Vectors;
-- with Stroke_Management; use Stroke_Management;
-- with Samples;           use Samples;
-- with Sample_Comparison; use Sample_Comparison;
-- with Training_Samples;  use Training_Samples;
-- with Preprocess;        use Preprocess;
-- with Averages;          use Averages;
-- with Word_Frequency;    use Word_Frequency;
-- with Generic_Binary_Trees_With_Data;
-- with Setup;
with Ada.Wide_Characters.Handling, Ada.Characters.Conversions;
with Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
with Ada.Calendar;
with GNATCOLL.SQL.Exec.Tasking, GNATCOLL.SQL_BLOB;
with GNATCOLL.SQL_Date_and_Time;
with Error_Log;
with Host_Functions;
with Calendar_Extensions;  use Calendar_Extensions;
with Database;             use Database;
with Grid_Training;
with Cell_Writer_Version;
package body Recogniser is
   use GNATCOLL.SQL, GNATCOLL.SQL_BLOB, GNATCOLL.SQL_Date_and_Time;
   use Setup;

   cDB : GNATCOLL.SQL.Exec.Database_Connection;
   CW_select            : constant GNATCOLL.SQL.Exec.Prepared_Statement :=
      GNATCOLL.SQL.Exec.Prepare 
           (SQL_Select (Fields  => Configurations.ID & Configurations.Name & 
                                   Configurations.DetFormat & Configurations.Details,
                        From    => Configurations,
                        Where   => (Configurations.ID > 0) AND
                                   ((Configurations.DetFormat = "S") OR -- str
                                    (Configurations.DetFormat = "N") OR -- num
                                    (Configurations.DetFormat = "L")),  -- bool
                        Order_By=> Configurations.ID),
            On_Server => True,
            Use_Cache => True);
   CW_update            : constant GNATCOLL.SQL.Exec.Prepared_Statement :=
      GNATCOLL.SQL.Exec.Prepare 
           (SQL_Update(Table => Configurations,
                       Set   => (Configurations.Details = Text_Param(2)),
                       Where => (Configurations.ID      = Integer_Param(1))),
            On_Server => True,
            Use_Cache => False);
   User_ID_Num          : constant GNATCOLL.SQL.Exec.Prepared_Statement :=
      GNATCOLL.SQL.Exec.Prepare 
           (SQL_Select (Fields  => UserIDs.UID,
                        From    => UserIDs,
                        Where   => (UserIDs.Logon = Text_Param(1))),
            On_Server => True,
            Use_Cache => True);
   User_ID_Exists       : constant GNATCOLL.SQL.Exec.Prepared_Statement :=
      GNATCOLL.SQL.Exec.Prepare 
           (SQL_Select (Fields  => UserIDs.UID,
                        From    => UserIDs,
                        Where   => (UserIDs.UID = Integer_Param(1))),
            On_Server => True,
            Use_Cache => True);
   Max_User_Num         : constant GNATCOLL.SQL.Exec.Prepared_Statement :=
      GNATCOLL.SQL.Exec.Prepare 
           -- ("SELECT Max (UserIDs.UID) FROM UserIDs",
           (SQL_Select (Fields  => UserIDs.UID,  -- Should be Max ()
                        From    => UserIDs),
            On_Server => True,
            Use_Cache => True);
   User_Insert          : constant GNATCOLL.SQL.Exec.Prepared_Statement :=
      GNATCOLL.SQL.Exec.Prepare 
           (SQL_Insert (-- Table  => UserIDs,
                        Values => (UserIDs.UID = Integer_Param(1)) &
                                  (UserIDs.Logon = Text_Param(2)) &
                                  (UserIDs.Language = 1)),
            On_Server => True,
            Use_Cache => True);
   lingo_sel_enabled    : constant GNATCOLL.SQL.Exec.Prepared_Statement :=
      GNATCOLL.SQL.Exec.Prepare 
           (SQL_Select (Fields  => Languages.ID & 
                                   Languages.Start & Languages.EndChar & 
                                   Languages.Selected,
                        From    => Languages,
                        Where   => (Languages.Start <= Integer_Param(1) AND
                                   (Languages.EndChar >= Integer_Param(1))),
                        Order_By=> Languages.ID),
            On_Server => True,
            Use_Cache => True);
   word_sel_enabled    : constant GNATCOLL.SQL.Exec.Prepared_Statement :=
      GNATCOLL.SQL.Exec.Prepare 
           (SQL_Select (Fields  => Languages.ID & 
                                   Words.ID & Words.Word & 
                                   Languages.Selected,
                        From    => Languages & Words,
                        Where   => (Words.Word = Text_Param(1)),
                        Order_By=> Languages.ID),
            On_Server => True,
            Use_Cache => True);
   word_id              : constant GNATCOLL.SQL.Exec.Prepared_Statement :=
      GNATCOLL.SQL.Exec.Prepare 
           (SQL_Select (Fields  => Words.Language & 
                                   Words.ID & Words.word,
                        From    => Words,
                        Where   => (Words.word = Text_Param(1)),
                        Order_By=> (Words.Language)),
            On_Server => True,
            Use_Cache => True);
   learnt_data_entry    : constant GNATCOLL.SQL.Exec.Prepared_Statement :=
      GNATCOLL.SQL.Exec.Prepare 
           (SQL_Select (Fields  => LearntData.User & 
                                   LearntData.Language & LearntData.ID,
                        From    => LearntData,
                        Where   => (LearntData.User = Integer_Param(1)) AND
                                   (LearntData.Language = Integer_Param(2)) AND
                                   (LearntData.ID = Integer_Param(3)),
                        Order_By=> (LearntData.User & LearntData.Language)),
            On_Server => True,
            Use_Cache => True);   
   learnt_data_insert   : constant GNATCOLL.SQL.Exec.Prepared_Statement :=
      GNATCOLL.SQL.Exec.Prepare 
           (SQL_Insert (-- Table  => LearntData,
                        Values => (LearntData.User = Integer_Param(1)) & 
                                  (LearntData.Language = Integer_Param(2)) &
                                  (LearntData.ID = Integer_Param(3))),
            On_Server => True,
            Use_Cache => True);
   training_data_letters: constant GNATCOLL.SQL.Exec.Prepared_Statement :=
      GNATCOLL.SQL.Exec.Prepare 
           (SQL_Select (Fields  => TrainingData.ID & 
                                   Languages.Start & 
                                   TrainingData.SampleNo & TrainingData.Sample&
                                   TrainingData.TrgDate & TrainingData.TrgTime,
                        From    => TrainingData & Languages & UserIDs,
                        Where   => ((UserIDs.Logon = Text_Param(1)) OR
                                    (UserIDs.Logon = "")) AND
                                   (TrainingData.User = UserIDs.UID) AND
                                   (TrainingData.Language = Languages.ID) AND
                                   (TrainingData.ID <= Languages.EndChar),
                        Order_By=> TrainingData.ID),
            On_Server => True,
            Use_Cache => True);
   training_data_words  : constant GNATCOLL.SQL.Exec.Prepared_Statement :=
      GNATCOLL.SQL.Exec.Prepare 
           (SQL_Select (Fields  => TrainingDataWords.ID & 
                                   TrainingDataWords.WordID & 
                                   TrainingDataWords.Word &
                                   TrainingDataWords.SampleNo & 
                                   TrainingDataWords.Sample &
                                   TrainingDataWords.TrgDate & 
                                   TrainingDataWords.TrgTime,
                        From    => TrainingDataWords,
                        Where   => (TrainingDataWords.User = Text_Param(1)) OR
                                   (TrainingDataWords.User = ""),
                        Order_By=> TrainingDataWords.ID),
            On_Server => True,
            Use_Cache => True);
   Trg_Delete           : constant GNATCOLL.SQL.Exec.Prepared_Statement :=
      GNATCOLL.SQL.Exec.Prepare 
           (SQL_Delete (From    => TrainingData,
                        Where   => (TrainingData.User = Integer_Param(1)) AND
                                   (TrainingData.Language = Integer_Param(2)) AND
                                   (TrainingData.ID = Integer_Param(3)) AND
                                   (TrainingData.SampleNo = Integer_Param(4))),
            On_Server => True,
            Use_Cache => True);
   Trg_SampleNo         : constant GNATCOLL.SQL.Exec.Prepared_Statement :=
      GNATCOLL.SQL.Exec.Prepare 
           (SQL_Select (Fields  => TrainingData.SampleNo &  -- should be Max ()
                                   TrainingData.User & 
                                   TrainingData.Language & 
                                   TrainingData.ID,
                        From    => TrainingData,
                        Where   => (TrainingData.User = Integer_Param(1)) AND 
                                   (TrainingData.Language = Integer_Param(2)) AND
                                   (TrainingData.ID = Integer_Param(3)),
                        Order_By =>TrainingData.User & 
                                   TrainingData.Language & TrainingData.ID),
            On_Server => True,
            Use_Cache => True);
   Trg_Insert           : constant GNATCOLL.SQL.Exec.Prepared_Statement :=
      GNATCOLL.SQL.Exec.Prepare 
           (SQL_Insert (-- Table  => TrainingData,
                        Values => (TrainingData.User = Integer_Param(1)) & 
                                  (TrainingData.Language = Integer_Param(2)) &
                                  (TrainingData.ID = Integer_Param(3)) &
                                  (TrainingData.SampleNo = Integer_Param(4)) & 
                                  (TrainingData.Sample = Blob_Param(5)) &
                                  (TrainingData.TrgDate = tDate_Param(6)) & 
                                  (TrainingData.TrgTime = tTime_Param(7))),
            On_Server => True,
            Use_Cache => True);
   Trg_Update          : constant GNATCOLL.SQL.Exec.Prepared_Statement :=
      GNATCOLL.SQL.Exec.Prepare 
           (SQL_Update (Table => TrainingData,
                        Set   => (TrainingData.Sample = Blob_Param(5)),
                        Where => (TrainingData.User = Integer_Param(1)) AND
                                 (TrainingData.Language = Integer_Param(2)) AND
                                 (TrainingData.ID = Integer_Param(3)) AND
                                 (TrainingData.SampleNo = Integer_Param(4))),
            On_Server => True,
            Use_Cache => True);

   function LessThan(a, b : in sample_rating) return boolean is
      -- For the list of alternatives dynamic list for the recognise procedure
   begin
      return a > b;  -- Sort from biggest (higher rating) to smallest
   end LessThan;

   procedure Initialise_Recogniser
                   (DB_Descr : GNATCOLL.SQL.Exec.Database_Description) is
      use GNATCOLL.SQL.Exec, GNATCOLL.SQL_BLOB;
      R_user      : Forward_Cursor;
      user_parm   : SQL_Parameters (1 .. 1);
      userdb_parm : SQL_Parameters (1 .. 2);
      user_id     : natural := 0;  -- Note that 0 is default for all users
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details=> "Initialise_Recogniser: Start");
      -- Set up: Open the relevant tables from the database
      cDB:=GNATCOLL.SQL.Exec.Tasking.Get_Task_Connection(Description=>DB_Descr);
      -- And set up the word frequency
      if Word_Frequency_Is_Enabled then
         Load_Word_Frequency(DB_Descr);
      end if;
      -- And get the user identifier for the current logged-on user from
      -- the system.
      if Host_Functions.Current_User'Length > 0 then
         user_logon := Value_From_Wide(Host_Functions.Current_User);
      end if;
      -- Check that the user is in the database
      user_parm := (1 => +(Value(user_logon)));
      R_user.Fetch (Connection => cDB, Stmt => User_ID_Num,
                    Params => user_parm);
      if Success(cDB) and then Has_Row(R_user) then
         user_id := Integer_Value(R_user,0);
      else -- user does not exist - create an entry
         -- Check first for the system's understanding of user ID
         user_id := Host_Functions.Current_User_ID;
         user_parm := (1 => +user_id);
         R_user.Fetch (connection => cDB, Stmt =>User_ID_Exists);
         if Success(cDB) and then Has_Row(R_user) then
            -- exists - need to create one.
            -- Get the maximum user number (we will use that + 1)
            R_user.Fetch (Connection => cDB, Stmt => Max_User_Num);
            if Success(cDB) and then Has_Row(R_user) then
               while Has_Row(R_user) loop  -- while not end_of_table
                  if Integer_Value(R_user,0) > user_id then
                     user_id := Integer_Value(R_user,0);
                  end if;
                  Next(R_user);
               end loop;
            end if;
            user_id := user_id + 1;
         end if;
         -- Create the new entry
         userdb_parm := (1 => +user_id,
                         2 => +Value(user_logon));
         Execute (Connection=>cDB, Stmt=>User_Insert, Params=>userdb_parm);
         Commit_Or_Rollback (cDB);
      end if;
      -- And, knowing who we are, load in the samples for this user
      Read_In_Samples(from_database => cDB);
   end Initialise_Recogniser;

   procedure Finalise_Recogniser is
      use GNATCOLL.SQL.Exec;
      R_config   : Forward_Cursor;
      execute_it : boolean;
      c_cw_update: SQL_Parameters (1 .. 2);
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details=> "Finalise_Recogniser: Start");
      R_config.Fetch (Connection => cDB, Stmt => CW_select);
      if Success(cDB) and then Has_Row(R_config) then
         while Has_Row(R_config) loop  -- while not end_of_table
            execute_it:= false;
            if Value(R_config,1) = "current_sample" then
               null;
            elsif Value(R_config,1) = "engine_ranges" then
               c_cw_update:=(1 =>+Integer_Value(R_config,0),
                             2 =>+Value(of_string=>Recogniser.The_Engine_Ranges));
               execute_it := true;
            else
               Null;  -- nothing to do here if not found
            end if;
            if execute_it then
               Execute (Connection=>cDB, Stmt=>CW_update, Params=>c_cw_update);
               Commit_Or_Rollback (cDB);
            end if;
            Next(R_config);  -- next record(Configurations)
         end loop;
      end if;
   end Finalise_Recogniser;
          
   procedure Set_Engine_Ranges(to : in text) is
      -- Get a space/comma delimited list of numbers to load into the
      -- Engine array.
      -- This information is provided as a part of initialisation process
      -- where the information is restored from the database at setup time.
      the_list : text := to;
      the_num  : natural;
   begin
      Error_Log.Debug_Data(at_level => 6, 
                           with_details=> "Set_Engine_Ranges: Start");
      for eng_num in engines.First_Index .. engines.Last_Index loop
         if Length(the_list) > 0 then
            the_num := Get_Integer_From_String(the_list);
            Delete_Number_From_String(the_list);
            if Length(the_list) > 1 then  -- not the last entry
               Delete(the_list, 1, 1);  -- delete the separator
            end if;
            engines(eng_num).e_range := the_num;
         end if;
      end loop;
   end Set_Engine_Ranges;
    
   function The_Engine_Ranges return text is
      -- Provide a comma delimited list of numbers for the Engine array.
      -- This returned information is stored in the database when the
      -- application is shut down, ready for restoration (by Set_Engine_Ranges)
      -- when the application starts up as a part of its setup routine.
      the_list : text;
   begin
      Clear(the_list);
      for eng_num in engines.First_Index .. engines.Last_Index loop
         the_List:= the_list & Put_Into_String(item=>engines(eng_num).e_range);
         if eng_num /= engines.Last_Index then
            the_list := the_list & ',';
         end if;
      end loop;
      return the_list;
   end The_Engine_Ranges;

   function Engine_Rating(for_the_sample : in comparison_information; 
                          at_engine_number : natural) return integer is
      -- Get the processed rating for specified engine (i.e. the processor) 
      -- on a sample.  This rating is processed as a part of the comparison
      -- between the input sample to be recognised (or, if you like, under
      -- test) and the training samples.  The information passed in relates
      -- to the relevant training sample.  Note that an engine can give a
      -- negative rating.
      value : integer;
      j : natural renames at_engine_number;
   begin
      -- Error_Log.Debug_Data(at_level=>8, with_details=> "Engine_Rating: Start");
   
      if engines(j).e_range = 0 or engines(j).max < 1
      then
         return 0;
      else
         value := (for_the_sample.ratings(j) - engines(j).average) *
                                           engines(j).e_range / engines(j).max;
         if engines(j).scale >= 0
         then
            value := value * engines(j).scale / engine_scale;
         end if;
         return value;
      end if;
   end Engine_Rating;

   procedure Set_Sample_Rating(for_sample : in out comparison_information;
                               with_input_sample : in input_sample_type) is
       -- Get the composite processed rating on a sample.
      input_sample : input_sample_type renames with_input_sample;
      rating : integer := 0;
      trg_sample : training_sample;
   begin
      -- Error_Log.Debug_Data(at_level => 7, 
         --                   with_details=> "Set_Sample_Rating: Start");
      trg_sample := Deliver_The_Sample(at_index=>for_sample.sample_number);
      if for_sample.disqualified or 
         Is_Disqualified (the_sample => sample_type(trg_sample),
                          against_input_sample => input_sample) /= false or
         (not trg_sample.enabled) or
         for_sample.penalty >= 1.0
      then
         for_sample.rating := rating_minimum;
      else
         for engine_id in engines.First_Index .. engines.Last_Index loop
            rating := rating + Engine_Rating(for_the_sample => for_sample, 
                                             at_engine_number => engine_id);
         end loop;
         rating := integer(float(rating) * (1.0 - for_sample.penalty));
         if rating > rating_maximum then
            rating := rating_maximum;
         elsif rating < rating_minimum then
            rating := rating_minimum;
         end if;
         for_sample.rating := rating;
      end if;
   end Set_Sample_Rating;

   -- Recognition and training

   procedure Recognise_Sample (input_sample : in sample_type;
                               best_result  : out text;
                               alternatives : out alternative_array;
                               num_alternatives : in integer) is
      -- Use the recognition engines to try to recognise the sample.
      -- Then rank and, using the rankings, determine the most likely
      -- character.
      -- We only return num_alternatives alternatives at most, also sorted
      -- from most likely to least likely.
      -- use Ada.Containers; 
      use Comparisons_Arrays, Engines_Arrays;
      use Alternatives_Arrays;  use Ada.Containers;
      function To_Wide(value : in float) return wide_string is
      begin
         return To_String(Put_Into_String(float'rounding(value*1000.0)*0.001,3));
      end To_Wide;
      function To_Wide(value : in integer) return wide_string is
      begin
         return To_String(Put_Into_String(value));
      end To_Wide;
      the_time     : Time := Clock;
      e_range      : natural := 0;
      rated        : natural;
      value        : natural;
      strength     : natural := 0;
      input_penalty: float := 0.0;
      the_sample   : comparison_information;
      alternative_num     : natural := 0;
      highest_rating      : sample_rating;
      next_highest_rating : sample_rating;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details=> "Recognise_Sample: Start");
      -- Set up the array of data for each training sample to be used in
      -- comparison.  Clear ratings against the training samples and otherwise
      -- get ready to find the matching sample.
      Setup_The_Comparison_Array;
      Clear(the_list => alternatives);
   
      -- Run engines
      Error_Log.Debug_Data(at_level => 9, with_details=> "Recognise_Sample: run the engines");
      for cntr in engines.First_Index .. engines.Last_Index loop
         rated := 0;
         if engines(cntr).func /= NULL then
            -- Run the engine
            engines(cntr).func.all (input_sample, 
                                    input_penalty,
                                    engines(cntr).e_range, 
                                    engines(engine_ave_dist).e_range,
                                    engines(cntr).scale);
         end if;
         -- Compute average and maximum value
         Error_Log.Debug_Data(at_level => 9, with_details=> "Recognise_Sample: Computing average and maximum value");
         engines(cntr).max := 0;
         engines(cntr).average := 0;
         for sample_number in training_comparisons.First_Index .. 
                              training_comparisons.Last_Index loop
            the_sample := training_comparisons(sample_number);
            -- work out the maximum rating value across the samples
            -- and start calculation of the average
            value := 0; 
         -- if the_sample.ch /= null_char then
            if the_sample.ratings(cntr) > value then
               value := the_sample.ratings(cntr);  -- new max rating
            end if;
            if not (value = 0 and engines(cntr).ignore_zeros) then
               if value > engines(cntr).max then
                  engines(cntr).max := value;  -- assign new max rating
               end if;
               engines(cntr).average := engines(cntr).average + value;
               rated := rated + 1;
            end if;
         end loop;
         if rated > 0 then
            -- finish average calculation (i.e. Sum(values)/Count(values)):
            engines(cntr).average := engines(cntr).average / rated;
            if engines(cntr).max > 0 then
               e_range := e_range + engines(cntr).e_range;
            end if;
            if engines(cntr).max = engines(cntr).average
            then
               engines(cntr).average := 0;  -- WHY???
            else
               engines(cntr).max := engines(cntr).max - engines(cntr).average;
            end if;
         end if;
      end loop;
      if e_range = 0 then  -- Didn't find a match!
         -- log the elapsed time so far and clear the character
         Error_Log.Debug_Data(at_level =>4, 
                           with_details=>"Recognised -- No ratings, t=" &
                                         To_Wide(float(Clock - the_time)) &
                                          " secs");
         best_result := null_char;
         return;
      end if;
      
      -- Rank the top samples
      for sample_no in training_comparisons.First_Index ..
                       training_comparisons.Last_Index loop
         the_sample := training_comparisons(sample_no);
         Set_Sample_Rating(for_sample => the_sample,
                           with_input_sample => input_sample);
         if the_sample.rating >= 1 then
            declare
               alternative : alternative_details;
            begin
               alternative.ch := the_sample.ch;
               -- set the rating, normalising it to be within 0% .. 100%
               alternative.rating:= sample_rating(
                                      float(the_sample.rating)/float(e_range));
               -- Load in the sample index number, that is the sample look-up
               -- number that links the comparison and the training data (which
               -- is different to the sample number for the specific character)
               alternative.sample_number := the_sample.sample_number;
               Error_Log.Debug_Data(at_level => 9, with_details=> "Recognise_Sample: adding alternative '" & alternative.ch & "' at number " & Put_Into_String(Count(of_items_in_the_list => alternatives)+1) & " with rating " & Put_Into_String(integer(alternative.rating * 100.0)) & "%.");
               Insert(into => alternatives, 
                   the_index => alternative.rating,
                   the_data =>  alternative);
               Error_Log.Debug_Data(at_level => 9, with_details=> "Recognise_Sample: added alternative '" & alternative.ch & "'.");
            end;
         end if;
      end loop;
      
      --  Trim excess alternatives to be no more than num_alternatives
      First(in_the_list => alternatives);
      while not Is_End(of_the_list => alternatives) loop
         alternative_num := alternative_num + 1;
            -- Delete out excess alternatives beyond num_alternatives
         if alternative_num > num_alternatives
         then  -- delete from the end (it doesn't matter where to delete from)
            Error_Log.Debug_Data(at_level => 9, with_details=> "Recognise_Sample: deleting alternative '" & Deliver_Data(alternatives).ch & "' at number " & Put_Into_String(alternative_num) & " with rating " & Put_Into_String(integer(Deliver_Data(alternatives).rating * 100.0)) & "%.");
            Delete(from_the_list => alternatives);
         else
            Error_Log.Debug_Data(at_level => 9, with_details=> "Recognise_Sample: keeping alternative '" & Deliver_Data(alternatives).ch & "' at number " & Put_Into_String(alternative_num) & " with rating " & Put_Into_String(integer(Deliver_Data(alternatives).rating * 100.0)) & "%.");
         end if;
         Next(in_the_list => alternatives);
      end loop;
      
      -- Keep track of strength stat
      if Count(of_items_in_the_list => alternatives) > 0 then
         if Count(of_items_in_the_list => alternatives) > 1
         then  -- more than one item, find the strength of the first item
            Error_Log.Debug_Data(at_level => 9, with_details=> "Recognise_Sample: number of alternatives is " & Put_Into_String(Count(of_items_in_the_list => alternatives)) & ".");
            First(in_the_list => alternatives);
            highest_rating := Deliver_Data(from_the_list=>alternatives).rating;
            Error_Log.Debug_Data(at_level => 9, with_details=> "Recognise_Sample: highest_rating = " & Put_Into_String(integer(highest_rating * 100.0)) & "%.");
            -- The following code to get next_highest_rating is to get around a
            -- strange error that randomly and very infrequently popped up
            for alternate in 2..Count(of_items_in_the_list=>alternatives) loop
               Next(in_the_list => alternatives);
               if Is_End  (of_the_list=>alternatives)
               then  -- there is a list error - try next
                  Next(in_the_list => alternatives);
               else  -- no problems - quit loop now
                  exit;
               end if;
            end loop;
            if not Is_End  (of_the_list=>alternatives)
            then  -- all's well
               next_highest_rating := Deliver_Data(from_the_list=>alternatives).rating;
            else  -- error condition - assign 0!
               next_highest_rating := 0.0;
            end if;
            Error_Log.Debug_Data(at_level => 9, with_details=> "Recognise_Sample: next_highest_rating = " & Put_Into_String(integer(next_highest_rating * 100.0)) & "%.");
            strength := integer((highest_rating-next_highest_rating)*100.0);
         else  -- just one item, so it is 100% strong
            strength := 100;
         end if;
         strength_sum := strength_sum + strength;
      end if;
      
      -- Debugging: print some statistics to the log
      if prep_examined - num_disqualified /= 0
      then
         Error_Log.Debug_Data(at_level => 4, 
                   with_details=>"Recognised -- " & To_Wide(num_disqualified) &
                                  "/" & To_Wide(prep_examined) & "(" &
                              To_Wide(num_disqualified * 100 / prep_examined) &
                                  "%) disqualified, " & 
                                  To_Wide(float(Clock - the_time)) & " secs ("&
                                  To_Wide(float(Clock - the_time)/
                                       float(prep_examined - num_disqualified))
                                        & " s/symbol), " & To_Wide(strength) & 
                                        "% strong");
      else
         Error_Log.Debug_Data(at_level =>4, 
                   with_details=>"Recognised -- " & To_Wide(num_disqualified) &
                                  "/" & To_Wide(prep_examined) & "(" &
                              To_Wide(num_disqualified * 100 / prep_examined) &
                                  "%) disqualified, " & 
                                  To_Wide(float(Clock - the_time)) & " secs ("&
                                  "-1 s/symbol), " & To_Wide(strength) & 
                                        "% strong");
      end if;
      -- Debugging: Print out the top candidate scores in detail
      declare
         use dStrings;
         len : natural;
         msg : text;
         trg_sample  : training_sample;
         cmpr_sample : comparison_information;
         alternative : alternative_details;
      begin
         First(in_the_list => alternatives);
         while not Is_End(of_the_list => alternatives) loop
            -- Bail when alternatives are blank (nothing to do there - they
            -- have no data in them and have been declared unused)
            -- exit when alternatives(item).ch = null_char;
            Clear(msg);
            alternative := Deliver_Data(from_the_list => alternatives);
            trg_sample  := 
                   Deliver_The_Sample(at_index => alternative.sample_number);
            cmpr_sample := training_comparisons(alternative.sample_number);
            if input_sample.strokes.Length >= trg_sample.strokes.Length
            then
               len := natural(input_sample.strokes.Length);
            else
               len := natural(trg_sample.strokes.Length);
            end if;
            msg := msg & "| '" & alternative.ch & "' (";
            for cntr in engines.First_Index .. engines.Last_Index loop
               msg := msg & 
                      To_Wide(Engine_Rating(for_the_sample=>cmpr_sample,
                                            at_engine_number=>cntr)) & " [" &
                      To_Wide(cmpr_sample.ratings(cntr)) & "]";
               if cntr < engines.Last_Index then
                  msg := msg & ", ";
               end if;
            end loop;
            msg := msg & ") " & To_Wide(cmpr_sample.rating) & " [";
            for cntr in strokes_list_range'First .. 
                        strokes_list_range'First + len - 1 loop
               msg := msg & To_Wide(cmpr_sample.the_transform.order(cntr)-1);
            end loop;
            for cntr in strokes_list_range'First .. 
                        strokes_list_range'First + len - 1 loop
               if cmpr_sample.the_transform.in_reverse(cntr)
               then
                  msg := msg & 'R';
               else
                  msg := msg & '-';
               end if;
            end loop;
            for cntr in strokes_list_range'First .. 
                        strokes_list_range'First + len - 1 loop
               msg := msg & To_Wide(cmpr_sample.the_transform.glue(cntr));
            end loop;
            msg := msg & "] ";
            Error_Log.Debug_Data(at_level => 5, with_details => msg);
            Next(in_the_list => alternatives);
         end loop;
      end;
      
      -- Load the resultant recognition to the input sample
      if Count(of_items_in_the_list => alternatives) > 0
      then  -- some kind of match was found
         First(in_the_list => alternatives);
         best_result := Deliver_Data(from_the_list => alternatives).ch;
      else  -- no match was found
         best_result := null_char;
      end if;
   end Recognise_Sample;

   procedure Insert(new_sample : in out training_sample;
                    overwrite  : in boolean := false) is
       -- Insert a sample into the sample chain, possibly overwriting an older
       -- sample for this character/word.
       -- Then insert (or update) the database with this sample.
      the_sample : training_sample;
   begin
      Error_Log.Debug_Data(at_level=>8,with_details=>"Insert(sample): start.");
      if overwrite
      then  -- the sample contains the sample number to overwrite at
         -- Delete the old sample from the in-memory list
         Find (the_item => new_sample.ch);
         while not Past_Last_Sample loop
            the_sample := Deliver_The_Sample;
            if the_sample.ch = new_sample.ch
            then
               if the_sample.sample_number = new_sample.sample_number
               then  -- got it - replace it and write out to the database
                  -- update the in-memory edition of the sample
                  Replace (the_data => new_sample);
                  -- and update in the database
                  Write_Out(the_sample => new_sample, to_database => cDB,
                            as_update => true);
                  exit;  -- job done here
               end if;
            else  -- overshot the mark - didn't find the install place - add it
               Insert(the_index => new_sample.ch, the_data => new_sample);
               Write_Out(the_sample => new_sample, to_database => cDB);
               -- and report the error
               Error_Log.Put(the_error => 31,
                             error_intro =>  "Insert(new_sample) error", 
                             error_message => "Attempted update but it " &
                                              " doesn't exist for sample '" & 
                                              new_sample.ch & "'.");
               exit;  -- done as past the character
            end if;
            Next_Sample;
         end loop;
      else  -- create a new entry in the list of samples and the database
         Insert(the_index => new_sample.ch, the_data => new_sample);
         Error_Log.Debug_Data(at_level=>9,with_details=>"Insert(sample): inserting.");
         -- And insert into the database
         Write_Out(the_sample => new_sample, to_database => cDB);
      end if;
      Error_Log.Debug_Data(at_level=>9,with_details=>"Insert(sample): end.");
   end Insert;

   procedure Train_Sample (cell : in sample_type) is  --; trusted : boolean) is
      -- Add the sample into the list of training samples, overwriting an old
      -- one if there are already enough samples.
      use Ada.Containers;
      new_sample : training_sample;
      usage      : natural;
   begin
      Error_Log.Debug_Data(at_level=>7, with_details=>"Train_Sample: start.");
      -- Do not allow zero-length samples
      if cell.strokes.Length < 1 then
         Error_Log.Put(the_error => 32,
                       error_intro =>  "Train_Sample error", 
                       error_message => "Attempted to train zero length " &
                                        "sample for '"& cell.ch & "'.");
         return;
      end if;
      Error_Log.Debug_Data(at_level=>9, with_details=>"Train_Sample: about to copy.");
      copy(from => cell, to => new_sample);
      -- Record when we made the sample
      new_sample.training_date := UTC_Clock;
      new_sample.training_time := Seconds(UTC_Clock);
      new_sample.sample_number := Number_Of_Samples(for_the_key => cell.ch) + 1;
      if new_sample.sample_number > Setup.Max_Samples_Per_Character
      then  -- need to work out how to select the one to replace and put that code in here.
         -- Get the least used sample
         Find (the_item => cell.ch);
         usage := Deliver_The_Sample.used;  -- starting positions
         new_sample.sample_number := Deliver_The_Sample.sample_number;
         while not Past_Last_Sample loop
            if Deliver_The_Sample.used < usage
            then  -- this is better than previous;
               usage := Deliver_The_Sample.used;  -- load new best
               new_sample.sample_number := Deliver_The_Sample.sample_number;
            end if;
            Next_Sample;
            exit when Deliver_The_Key /= cell.ch;
         end loop;
         -- assign that sample's number
         Error_Log.Debug_Data(at_level=>9, with_details=>"Train_Sample: overwriting old with new sample.");
         Insert(new_sample, overwrite => true);
      else  -- inserting a new sample
      -- new_sample.enabled := true;
         Error_Log.Debug_Data(at_level=>9, with_details=>"Train_Sample: inserting new sample.");
         Insert(new_sample, overwrite => false);
      end if;
   end Train_Sample;

   procedure Update_Enabled_Samples is
         -- External_Name => "update_enabled_samples";
      -- Run through the samples list and enable samples in enabled blocks
      -- (and disable those not).
      -- These are the training samples that are a part of the blocks of
      -- characters that the user has selected as their character sets.
      -- Also need to check back for any words
      use GNATCOLL.SQL.Exec;
      use Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
      the_sample : training_sample;
      R_lingo    : Forward_Cursor;
      lingo_parm : SQL_Parameters (1 .. 1);
   begin
      Error_Log.Debug_Data(at_level => 6, 
                           with_details=> "Update_Enabled_Samples: Start");
      First_Sample;
      while not Past_Last_Sample loop
         the_sample := Deliver_The_Sample;
         the_sample.enabled := false;  -- default is not enabled
         if Length(the_sample.ch) = 1 and then
            the_sample.ch /= null_char then -- null char = no character
            -- Just check to see if the character is within one of the
            -- Unicode blocks that the user has said is enabled
            -- We assume that if the first character for a word is within the
            -- block, then the word should be, otherwise it shouldn't.
            lingo_parm:= (1=> 
                         +(wide_character'Pos(Wide_Element(the_sample.ch,1))));
            R_lingo.Fetch (Connection => cDB, Stmt => lingo_sel_enabled, 
                           Params => lingo_parm);
            if Success(cDB) and then Has_Row(R_lingo) then
               the_sample.enabled := (Value(R_lingo, 3) /= "0");
            end if;
         elsif Length(the_sample.ch) > 1
         then  -- it is a word
            lingo_parm:= (1=> +To_UTF8_String(item => the_sample.ch));
            R_lingo.Fetch (Connection => cDB, Stmt => word_sel_enabled,
                           Params => lingo_parm);
            if Success(cDB) and then Has_Row(R_lingo) then
               the_sample.enabled := (Value(R_lingo, 3) /= "0");
            end if;
         end if;
         -- Save the newly discovered enabled status back
         Replace (the_data => the_sample);
         Next_Sample;
      end loop;
   end Update_Enabled_Samples;

   procedure Promote(the_character : in text; at_sample_number : in natural) is
      -- Update usage counter for a sample, both in memory and in the
      -- database.  This is called whenever a sample is confirmed as
      -- having been used.
      -- The 'at_sample_number' is actually the index into the in-memory list
      -- of samples (there is uniquely one for each sample (character:sample
      -- number combination), so it is different to the 'sample_number' that is
      -- only unique to a particular character/word). The 'the_character' is
      -- the relevant character and is used as a cross check that the index
      -- 'at_sample_number' is pointing to the right sample.
      the_sample : training_sample;
   begin
      -- Find (the_item => the_character);
      the_sample := Deliver_The_Sample(at_index => at_sample_number);
      if the_sample.ch = the_character and then 
         the_sample.used < natural'Last - 100
      then  -- no point in generating an error if it has been used that often
         -- Increment_Current_Sample;
         the_sample.used := the_sample.used + 1;
         -- Update the database with this updated sample
         Write_Out(the_sample => the_sample, to_database => cDB,
                   as_update => true);
         -- And update the training sample in memory
         Replace (the_data => the_sample);
      elsif the_sample.ch /= the_character
      then  -- this is an error condition
         Error_Log.Put(the_error => 33,
                       error_intro =>  "Promote error", 
                       error_message => "Attempted to promote a non-existent "&
                                        "sample, '"& the_character & 
                                        "' at sample number " & 
                                        Put_Into_String(at_sample_number) & ".");
      end if;
   end Promote;

   procedure Demote (the_sample : in out training_sample) is
      -- Remove the sample from our set if we can.
   begin
      if Number_Of_Samples(for_the_key => the_sample.ch) > 1
      then  -- delete it from the database and in memory
         -- Delete the in-memory edition
         Find (the_item => the_sample.ch);
         Delete_The_Sample;
         -- And delete the database edition
         Delete(the_sample => the_sample, from_database => cDB);
         Clear (the_sample => sample_type(the_sample));
      else
         Error_Log.Put(the_error => 34,
                       error_intro =>  "Demote error", 
                       error_message => "Attempted to delete a non-existent " &
                                        "sample, '"& the_sample.ch & "'.");
      end if;
   end Demote;

   procedure Untrain(the_character : in text) is
       -- Delete all samples for a character.
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details=> "Untrain: Start");
      while There_Is_A_Sample_With (the_key=> the_character) loop
         Find (the_item => the_character);
         if not Past_Last_Sample and then
              Deliver_The_Key = the_character then
            -- Delete from the database
            Delete(the_sample => Deliver_The_Sample, from_database => cDB);
            -- And delete from the in-memory store
            Delete_The_Sample;
         end if;
      end loop;
      Grid_Training.Record_Training_Is_Not_Done(on_char_or_word=>the_character);
   end Untrain;

   procedure Untrain_Last_Sample(for_the_character : in text) is
       -- Delete the last sample recorded for a character.
       -- This is essentially an "undo" operation.
      num_samples : natural := 0;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details=> "Untrain_Last_Sample: Start");
      -- Get the last training number for this character
      if There_Is_A_Sample_With (the_key=> for_the_character)
      then
         num_samples := Number_Of_Samples(for_the_key=>for_the_character);
      -- Now find it and delete it
         Find (the_item => for_the_character);
         for sample_num in 1 .. num_samples - 1 loop
            if not Past_Last_Sample then  -- just in case :-)
               Next_Sample;
            end if;
         end loop;
         -- we should now be at that last sample number
         if not Past_Last_Sample and then
            Deliver_The_Key = for_the_character then
            -- Delete this particular training sample from the database
            Delete(the_sample => Deliver_The_Sample, from_database => cDB);
            -- And undo the training for it in memory
            Delete_The_Sample;
            if not There_Is_A_Sample_With (the_key=> for_the_character)
            then  -- we deleted the last training sample for this character
               Grid_Training.Record_Training_Is_Not_Done
                                          (on_char_or_word=>for_the_character);
            end if;
         end if;
      end if;
   end Untrain_Last_Sample;
   
   -- Database operations
   procedure Read_In_Samples
                  (from_database : in GNATCOLL.SQL.Exec.Database_Connection) is
       -- Read in samples from the database and load to the list of training
       -- samples.
      use GNATCOLL.SQL.Exec, GNATCOLL.SQL_BLOB;
      use Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
      use Grid_Training;  -- where we store the fact that it is trained
      -- use Training_Samples;  -- where we store the training samples
      R_train    : Forward_Cursor;
      the_sample : training_sample;
      the_ch     : text;
      user_parm : SQL_Parameters (1 .. 1);
   begin
      Error_Log.Debug_Data(at_level => 6, 
                           with_details=> "Read_In_Samples: Start");
      -- Start off with an empty list of training samples
      Delete_All_Samples;
      -- Get the data from the database: First, get characters
      user_parm := (1 => +(Value(user_logon)));
      -- This comes from the TrainingData table, where the ID is an offset
      -- from the Language number as a start position.
      R_train.Fetch (Connection => from_database, Stmt => training_data_letters,
                     Params => user_parm);
      if Success(from_database) and then Has_Row(R_train) then
         while Has_Row(R_train) loop  -- while not end_of_table
            -- Extract the character which, as noted above, is offset from
            -- the language number start position, so obtained by adding the
            -- two numbers together to result in the character value.
            the_ch := Clear & wide_character'Val(Integer_Value(R_train,0) + 
                                                 Integer_Value(R_train,1));
            -- Extract the sample data from the blob
            the_sample:= Extract_The_Sample(from_blob=> Blob_Value(R_train,3));
            -- And get the date and time of training for this sample
            the_sample.training_date := Time(tDate_Value(R_train,4));
            the_sample.training_time := Seconds(Time(tTime_Value(R_train,5)));
            the_sample.sample_number := Integer_Value(R_train,2);
            -- Check that we got the right sample
            if Length(the_sample.ch) = 1 and then the_sample.ch = the_ch
            then  -- got the right sample
              -- Load the sample data into the list of samples
               Insert(the_index => the_ch, the_data => the_sample);
            else  -- got the wrong sample (pretty serious issue here!)
               Error_Log.Put(the_error => 35,
                             error_intro => "Read_In_Samples error", 
                              error_message => "unmatched character for '"&
                                  Value(the_sample.ch) & "' against index '" &
                                  Value(the_ch) & "'.");
            end if;
            Next(R_train);
         end loop;
      else  -- We could have a database problem! (or there really is no data)
         Error_Log.Put(the_error => 36,
                       error_intro => "Read_In_Samples possible error", 
                       error_message =>"no character training samples found.");
      end if;
      -- Get the data from the database: Second words/combining character sets
      -- This actually comes via a database View, TrainingDataWords, which
      -- calculates the word ID as the sum of the Language start and ID, and
      -- melds in the actual word.
      R_train.Fetch (Connection => from_database, Stmt => training_data_words,
                     Params => user_parm);
      if Success(from_database) and then Has_Row(R_train) then
         while Has_Row(R_train) loop  -- while not end_of_table
            -- Extract the word (Note: database stores string in UTF8 format)
            the_ch := 
                 Value_From_Wide(Decode(UTF_8_String(Value(R_train,2)),UTF_8));
            -- Extract the sample data from the blob
            the_sample:= Extract_The_Sample(from_blob =>Blob_Value(R_train,4));
            -- And get the date and time of training for this sample
            the_sample.training_date := Time(tDate_Value(R_train,5));
            the_sample.training_time := Seconds(Time(tTime_Value(R_train,6)));
            the_sample.sample_number := Integer_Value(R_train,3);
            -- Check that we got the right sample
            if the_sample.ch = the_ch
            then  -- got the right sample
               -- Load the sample data into the list of samples
               Insert(the_index => the_ch, the_data => the_sample);
            else  -- got the wrong sample (pretty serious issue here!)
               Error_Log.Put(the_error => 37,
                             error_intro => "Read_In_Samples error", 
                              error_message => "unmatched word for '" &
                                               Value(the_sample.ch) & 
                                               "' against index '" &
                                               Value(the_ch) & "'.");
            end if;
            Next(R_train);
         end loop;
      else  -- This might be an issue or there might be no data
         Error_Log.Debug_Data(at_level => 2, 
                              with_details=> "Read_In_Samples: " & 
                                             "no words trained on yet.");
      end if;
      -- Finally, if there is data, set the enabled flag appropriately
      if not There_Are_No_Samples then
         Update_Enabled_Samples;
      end if;
      Error_Log.Debug_Data(at_level => 9, 
                           with_details=> "Read_In_Samples: Finish");
   end Read_In_Samples;

   procedure Write_Out(the_sample  : in training_sample;
                       to_database : in GNATCOLL.SQL.Exec.Database_Connection;
                       as_update   : in boolean := false) is
       -- Write out samples to the database from the list of training samples.
      use GNATCOLL.SQL.Exec, GNATCOLL.SQL_BLOB;
      use Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
      user_parm  : SQL_Parameters (1 .. 1);
      lang_parm  : SQL_Parameters (1 .. 1);
      learnt_parm: SQL_Parameters (1 .. 3);
      train_parm : SQL_Parameters (1 .. 7);
      R_user     : Forward_Cursor;
      R_lang     : Forward_Cursor;
      user_id    : natural := 0;  -- Note that 0 is default for all users
      language_id: natural := 1;  -- the training data table language
      char_id    : natural := 0;  -- the training data table id
      block_start: natural;
      block_end  : natural;
      -- sample_no  : natural := 0;
      train_time : Calendar_Extensions.Time;
   begin
      Error_Log.Debug_Data(at_level => 6, 
                           with_details=> "Write_Out(the_sample): Start");
      -- Get the logged on user's numerical identifer as the database
      -- understands it
      user_parm := (1 => +(Value(user_logon)));
      R_user.Fetch (Connection => to_database, Stmt => User_ID_Num,
                    Params => user_parm);
      if Success(to_database) and then Has_Row(R_user) then
         user_id := Integer_Value(R_user,0);
      end if;
      -- Work out the block for the character set based on first character
      lang_parm := (1 => +Wide_Character'Pos(Wide_Element(the_sample.ch, 1)));
      R_lang.Fetch (Connection => to_database, Stmt => lingo_sel_enabled,
                          Params => lang_parm);
      if Success(to_database) and then Has_Row(R_lang) then
         language_id := Integer_Value(R_lang, 0);
         block_start := Integer_Value(R_Lang, 1);
         block_end   := Integer_Value(R_Lang, 2);
      else  -- We have a problem!
         Error_Log.Put(the_error => 38,
                       error_intro =>  "Write_Out(the_sample) error", 
                       error_message => "Didn't find block for character '" &
                                        Wide_Element(the_sample.ch, 1) & "'.");
      end if;
      -- Is this a word sample or a character for the sample
      if Length(the_sample.ch) = 1
      then  -- a character sample
         -- the offset is for the single character
         char_id := Wide_Character'Pos(Wide_Element(the_sample.ch, 1)) - 
                    block_start;
      else  -- a word sample -- first character is the block offset
         -- the word gives the offset from the block. Note that the
         -- database stores text in UTF8 format, so need to convert.
         lang_parm := (1 => +To_UTF8_String(item => the_sample.ch));
         R_lang.Fetch (Connection => to_database, Stmt => word_id,
                          Params => lang_parm);
         if Success(to_database) and then Has_Row(R_lang) then
            char_id := block_end + Integer_Value(R_lang, 1);
         else  -- we have a problem!
            Error_Log.Put(the_error => 39,
                          error_intro => "Write_Out(the_sample) error", 
                          error_message=>"Didn't find word '" & the_sample.ch &
                                         "'.");
            char_id := block_end + 100;  -- for now
         end if;
      end if;
      -- Before loading the sample, check there is an entry for the
      -- LearntData table for this character/word.
      learnt_parm := ( 1 => +user_id,
                       2 => +language_id,
                       3 => +char_id);
      R_lang.Fetch (Connection => to_database, Stmt => learnt_data_entry,
                     Params => learnt_parm);
      if not Success(to_database) or else not Has_Row(R_lang)
      then  -- No LeartData, so set it up
         Execute (Connection=>to_database, Stmt=>learnt_data_insert, 
                  Params=>learnt_parm);
         Commit_Or_Rollback (to_database);
      end if;
      train_time  := Time_Of(Year_Number'First,Month_Number'First,
                             Day_Number'First, the_sample.training_time);
      -- Now load the sample
      train_parm  := ( 1 => +user_id,
                       2 => +language_id,
                       3 => +char_id,
                       4 => +the_sample.sample_number, -- +sample_no,
                       5 => +Load_The_Sample (from=> the_sample),
                       6 => +tDate(the_sample.training_date),
                       7 => +tTime(train_time));
      if as_update
      then  -- update query
         Execute (Connection => to_database, Stmt => Trg_Update, 
                  Params     => train_parm);
      else  -- insert query
         Execute (Connection => to_database, Stmt => Trg_Insert, 
                  Params     => train_parm);
      end if;
      Commit_Or_Rollback (to_database);
   end Write_Out;

   procedure Delete(the_sample   : in training_sample;
                    from_database: in GNATCOLL.SQL.Exec.Database_Connection) is
       -- Delete the specified training sample from the database for the
       -- current user.
      use GNATCOLL.SQL.Exec, GNATCOLL.SQL_BLOB;
      use Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
      -- the_ch     : text;
      user_parm  : SQL_Parameters (1 .. 1);
      lang_parm  : SQL_Parameters (1 .. 1);
      train_parm : SQL_Parameters (1 .. 4);
      R_user     : Forward_Cursor;
      R_lang     : Forward_Cursor;
      user_id    : natural := 0;  -- Note that 0 is default for all users
      language_id: natural := 1;  -- the training data table language
      char_id    : natural := 0;  -- the training data table id
      block_start: natural;
      block_end  : natural;
   begin
      Error_Log.Debug_Data(at_level => 6, 
                           with_details=> "Delete(the_sample): Start");
      -- Get the logged on user's numerical identifer as the database
      -- understands it
      user_parm := (1 => +(Value(user_logon)));
      R_user.Fetch (Connection => from_database, Stmt => User_ID_Num,
                    Params => user_parm);
      if Success(from_database) and then Has_Row(R_user) then
         user_id := Integer_Value(R_user,0);
      end if;
      -- the_ch := the_sample.ch;
      -- Work out the block for the character set based on first character
      lang_parm := (1 => +Wide_Character'Pos(Wide_Element(the_sample.ch, 1)));
      R_lang.Fetch (Connection => from_database, Stmt => lingo_sel_enabled,
                          Params => lang_parm);
      if Success(from_database) and then Has_Row(R_lang) then
         language_id := Integer_Value(R_lang, 0);
         block_start := Integer_Value(R_Lang, 1);
         block_end   := Integer_Value(R_Lang, 2);
         Error_Log.Debug_Data(at_level => 9, with_details=> "Delete(the_sample): on sample '"&the_sample.ch&"', got the language (id="&Put_Into_String(language_id)&", block start="&Put_Into_String(block_start)&", block end="&Put_Into_String(block_end)&").");
      else  -- We have a problem!
         Error_Log.Put(the_error => 40,
                       error_intro   => "Delete(the_sample) error", 
                       error_message => "Didn't find block for character '" &
                                        Wide_Element(the_sample.ch, 1) & "'.");
      end if;
      -- Is this a word sample or a character for the sample
      if Length(the_sample.ch) = 1
      then  -- a character sample
         -- the offset is for the single character
         char_id := Wide_Character'Pos(Wide_Element(the_sample.ch, 1)) - 
                    block_start;
      else  -- a word sample -- first character is the block offset
         -- the word gives the offset from the block. Note that the
         -- database stores text in UTF8 format, so need to convert.
         lang_parm := (1 => +To_UTF8_String(item => the_sample.ch));
         R_lang.Fetch (Connection => from_database, Stmt => word_id,
                          Params => lang_parm);
         if Success(from_database) and then Has_Row(R_lang) then
            char_id := block_end + Integer_Value(R_lang, 1);
         else  -- we have a problem!
            Error_Log.Put(the_error => 41,
                          error_intro => "Delete(the_sample) error", 
                          error_message=>"Didn't find word '" & the_sample.ch &
                                         "'.");
            char_id := block_end + 100;  -- for now
         end if;
      end if;
      Error_Log.Debug_Data(at_level => 9, with_details=> "Delete(the_sample): user id="&integer'Wide_Image(user_id)&", language id="&integer'Wide_Image(language_id)&", char id="&integer'Wide_Image(char_id)&").");
      -- Now delete the sample
      train_parm := ( 1 => +user_id,
                      2 => +language_id,
                      3 => +char_id,
                      4 => +the_sample.sample_number);
      Error_Log.Debug_Data(at_level => 9, with_details=> "Delete(the_sample): updating sample for '"&the_sample.ch&"' at sample_no="&Put_Into_String(the_sample.sample_number)&".");
      Execute (Connection=>from_database,Stmt=>Trg_Delete, Params=>train_parm);
      Commit_Or_Rollback (from_database);
   end Delete;

begin
   Cell_Writer_Version.Register(revision => "$Revision: v1.0.0$",
                                for_module => "Recogniser");
end Recogniser;
