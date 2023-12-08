-----------------------------------------------------------------------
--                                                                   --
--                    W O R D _ F R E Q U E N C Y                    --
--                                                                   --
--                              B o d y                              --
--                                                                   --
--                           $Revision: 1.0 $                        --
--                                                                   --
--  Copyright (C) 2022  Hyper Quantum Pty Ltd.                       --
--  Written by Ross Summerfield.                                     --
--                                                                   --
--  This   package  manages  the  word  frequency  and   associated  --
--  statistical  processing  for hand  writing  recognition.   This  --
--  information is used to improve accuracy of recognition.          --
--  It  is a translation of the wordfreq.c package to Ada  that  is  --
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

-- with DStrings;            use DStrings;
-- with Generic_Binary_Trees_With_Data;
-- with Samples;             use Samples;
with GNATCOLL.SQL.Exec.Tasking;
with Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
with Generic_Binary_Trees_With_Data.Locate;
with Error_Log;
with Cell_Writer_Version;
with Database;                   use Database;
with Training_Samples, Grid_Training;
with Grid_Event_Handlers;
package body Word_Frequency is
   use GNATCOLL.SQL;
   use Word_Freq_Arrays;
   use Sample_Comparison, Sample_Comparison.Comparisons_Arrays;

   -- type word_frequency_info is record
   --       word  : text;
   --       count : natural := 0;
   --    end record;
   -- package Word_Freq_Arrays is new Generic_Binary_Trees_With_Data
   --       (T   => text,
   --        D   => word_frequency_info,
   --        "<" => dStrings."<",
   --        storage_size => (524288 * 4));
   -- subtype word_frequency_array is Word_Freq_Arrays.list;
   -- word_frequencies : word_frequency_array;

   package Search_Pre_Words is new Word_Freq_Arrays.Locate(PreComparison);
   package Search_Post_Words is new Word_Freq_Arrays.Locate(PostComparison);
   
   function PreComparison(comparitor, contains: text) return Boolean is
   begin
      return Locate(fragment=> Lower_Case(contains), 
                    within=> Lower_Case(comparitor)) = 1;
   end PreComparison;
   function PostComparison(comparitor, contains: text) return Boolean is
   begin
      return Locate(fragment=> Lower_Case(contains), 
                    within=> Lower_Case(comparitor)) > 1;
   end PostComparison;

   cDB : GNATCOLL.SQL.Exec.Database_Connection;
   word_freq_select : constant GNATCOLL.SQL.Exec.Prepared_Statement :=
      GNATCOLL.SQL.Exec.Prepare 
           (SQL_Select (Fields  => WordFrequency.WFWord & 
                                   WordFrequency.WdCount,
                        From    => WordFrequency,
                        Where   => (WordFrequency.Language = Integer_Param(1)),
                        Order_By=> WordFrequency.WFWord),
            On_Server => True,
            Use_Cache => True);
   word_freq_find : constant GNATCOLL.SQL.Exec.Prepared_Statement :=
      GNATCOLL.SQL.Exec.Prepare 
           ("SELECT WordFrequency.WFWord,WordFrequency.WdCount " &
            "FROM WordFrequency " &
            "WHERE WordFrequency.WFWord LIKE '?'" &
            "  AND WordFrequency.Language = ? " &
            "ORDER BY WordFrequency.WFWord",
            On_Server => True,
            Use_Cache => True);

   function Word_Frequency_Is_Enabled return boolean is
       -- Return true if our current understanding of the enablement of the
       -- word frequency engine is true.  Default initial value is 'true'.
   begin
      return wordfreq_enable;
   end Word_Frequency_Is_Enabled;
   
   procedure Set_Word_Frequency_Enablement(to : in boolean) is
   begin
      wordfreq_enable := to;
   end Set_Word_Frequency_Enablement;

   procedure Load_Word_Frequency
                   (DB_Descr : GNATCOLL.SQL.Exec.Database_Description;
                    for_language : in natural) is
      -- Clear out the old word frequency file that is loaded.  Then read
      -- in the word frequency file from the database. The file format 
      -- is: word (called WFWord in the database), count (called WdCount in
      -- the database).
      use GNATCOLL.SQL.Exec;
      use Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
      R_wd_freq    : Forward_Cursor;
      wd_freq_data : word_frequency_info;
      lingo_parm   : SQL_Parameters (1 .. 1);
   begin
      Error_Log.Debug_Data(at_level => 6, 
                           with_details=> "Load_Word_Frequency: Start");
      -- Set up: Open the relevant tables from the database
      the_DB_description := DB_Descr;
      cDB:=GNATCOLL.SQL.Exec.Tasking.Get_Task_Connection(Description=>DB_Descr);
      if language_number /= for_language
      then  -- Only do this if there has been a change in language
         language_number := for_language;
         -- Clear out the list ready to load
         Clear(the_list => word_frequencies);
         -- Fetch the data and load it
         lingo_parm:= (1=> +language_number);
         R_wd_freq.Fetch (Connection => cDB, Stmt => word_freq_select, 
                          Params => lingo_parm);
         if Success(cDB) and then Has_Row(R_wd_freq) then
            while Has_Row(R_wd_freq) loop  -- while not end_of_table
               wd_freq_data.word  := Value_From_Wide(
                               Decode(UTF_8_String(Value(R_wd_freq,0)),UTF_8));
               wd_freq_data.count := Integer_Value(R_wd_freq, 1);
               Insert(into => word_frequencies, 
                      the_index=> wd_freq_data.word, the_data => wd_freq_data);
               Next(R_wd_freq);
            end loop;
         end if;
      end if;
   end Load_Word_Frequency;

   procedure Load_Word_Frequency(for_language : in natural) is
   begin
      Load_Word_Frequency(the_DB_description, for_language);
   end Load_Word_Frequency;
   
   procedure Engine_Word_Frequency(input_sample: in Samples.input_sample_type;
                                   input_penalty : in out float;
                                   var1, var2 : natural;
                                   var3 : in out integer) is
     -- This engine calculates the probability that the character or word at
     -- the current cell position is a particular character or word, working
     -- through the list of training samples and rating them.  In doing so,
     -- it does not use the input_sample at all.  It simply weights each
     -- training sample based upon previous and post (current cursor position)
     -- actually entered characters or words.
      -- use Search_Pre_Words;
      use Training_Samples, Grid_Training;
      type chars_ratings is array
                (1..(Grid_Training.Number_of_Words_Or_Characters + 
                     (wide_character'Pos(wide_character'Last) -
                      wide_character'Pos(wide_character'First)+1))) of natural;
      subtype digits_range is wide_character range '0' .. '9';
      
      chars    : chars_ratings := (others => 0);
   
      procedure Store(the_Char_or_Word : in text; with_rating : in natural) is
         -- Store the rating in the score array for application against samples
         the_char : text renames the_Char_or_Word;
      begin
         if the_char /= null_char then -- found it, pop it in
            if Position_Of(char_or_word=>the_char) > 0
            then  -- it is in the current list
               chars(Position_Of(char_or_word=>the_char)) := 
                      chars(Position_Of(char_or_word=>the_char)) + with_rating;
            elsif Length(the_char) = 1  --(looking globally)
            then  -- single character located other than in current set
               chars(Number_of_Words_Or_Characters +
                        wide_character'Pos(Wide_Element(the_char, 1))) :=
                            chars(Number_of_Words_Or_Characters +
                               wide_character'Pos(Wide_Element(the_char, 1)))+
                                                                   with_rating;
            else  -- didn't really find it?
               null;         
            end if;
         end if;
      end Store;
   
      pre      : text;
      post     : text;
      full_word: text;
      split    : natural;
      the_char : text := null_char;
      -- the_sample: sample;
   begin
      Error_Log.Debug_Data(at_level => 6, 
                           with_details=> "Engine_Word_Frequency: Start");
      if not wordfreq_enable then
         return;
      end if;
      -- Extract the pre and post bits of the cell grid text currently entered.
      -- The pre and post bits are split by a null character.
      pre  := Lower_Case(Grid_Event_Handlers.Cell_Widget_Word);
      if Locate(fragment=>null_char, within=>pre) > 0
      then  -- found the split point, so extract post and trim pre
         split := Locate(fragment=>null_char, within=>pre);
         post := Sub_String(from=>pre, starting_at=>split+1, 
                            for_characters=>Length(pre)-split);
         Delete(pre, start=>split, size=>Length(pre)-split+1);
      else  -- no post component - all pre
         Clear(post);
      end if;
      -- Strip out all words prior and afterwards
      while Length(pre) > 0 and then
            locate(fragment => ' ',  within => pre) > 0 loop
         Delete(pre, 1, locate(fragment => ' ',  within => pre));
      end loop;
      if Length(post) > 0 and then locate(fragment => ' ',  within => post) > 0
      then
         Delete(post, locate(fragment => ' ',  within => post), 
                Length(post) - locate(fragment => ' ',  within => post) + 1);
      end if;
      -- A quick sanity check on the entered text so far
      if Length(pre) = 0 and Length(post) = 0 then
         return;  -- no characters entered yet (beyond current cursor point).
      end if;
      -- Numbers follow numbers
      if Length(pre) > 0 and then
         Wide_Element(pre, Length(pre)) in digits_range'Range
      then  -- probably it's a number
         for digit in digits_range'Range loop
            if Position_Of(char_or_word=>To_Text(digit)) > 0 then
               -- exists in our data set, so give it a rating
               chars(Position_Of(char_or_word=>To_Text(digit))) := 1;
            end if;
         end loop;
      else  --  Not a digit: Search the database for matches
         if Length(pre) > 0
         then  -- Look for first half of word
            full_word := Search_Pre_Words.
                                 The_Full_Key(for_partial_key => pre,
                                              in_the_list => word_frequencies);
            -- Move our pointers there
            if Length(full_word) > 0 then
               Find (the_item => full_word, in_the_list => word_frequencies);
            end if;
            -- There may be several matches, so we work through them all
            While_Word_Matches:
            while (Length(full_word) > 0 and
                   (not Is_End (of_the_list => word_frequencies))) and then 
                  Locate(fragment=>pre, within=>Lower_Case(full_word)) = 1 loop
               if Length(post) = 0 or else (Length(post) > 0 and then
                  locate(fragment=> post, within=> Lower_Case(full_word)) > 
                                                                 Length(pre)+1)
               then  -- we have a match!
                  if Length(post) > 0
                  then
                     the_char := Sub_String(from => full_word, 
                        starting_at => Length(pre)+1,
                        for_characters => 
                         locate(fragment=>post,within=>Lower_Case(full_word))
                                                            - Length(pre) - 1);
                  else  -- THE FOLLOWING WON'T WORK FOR WORDS IN A SINGLE CELL - ISSUE IS for_characters WOULD BE > 1!
                     the_char := Sub_String(from => full_word, 
                                            starting_at => Length(pre)+1,
                                            for_characters => 1);
                  end if;
                  Lower_Case(the_char);
                  Store(the_Char_or_Word => the_char, 
                        with_rating=> Deliver_Data 
                                      (from_the_list=>word_frequencies).count);
               end if;
               -- get the next word from the list
               Next(in_the_list => word_frequencies);
               if not Is_End (of_the_list => word_frequencies) then
                  full_word := Deliver(from_the_list => word_frequencies);
               end if;
            end loop While_Word_Matches;
         elsif Length(post) > 0
         then  -- we are inserting a character before a partial word, maybe
            full_word := Search_Post_Words.
                                 The_Full_Key(for_partial_key => post,
                                              in_the_list => word_frequencies);
            if Length(full_word) > 0 then
               Find (the_item => full_word, in_the_list => word_frequencies);
            end if;
            -- THERE IS A BUG HERE.  THERE NEEDS TO BE A FIND_NEXT FUNCTION
            -- IN GENERIC_BINARY_TREES_WITH_DATA THAT INTERACTS WITH LOCATE!!!
            While_Post_Matches:
            while (Length(full_word) > 0 and
                   (not Is_End (of_the_list => word_frequencies))) and then 
                  Locate(fragment=>post,within=>Lower_Case(full_word)) > 1 loop
               the_char := 
                  Sub_String(from => full_word, starting_at => 1,
                     for_characters => 
                       Locate(fragment=>post,within=>Lower_Case(full_word))-1);
               Upper_Case(the_char);  -- since Length(pre) = 0, so 1st char(s)
               Store(the_Char_or_Word => the_char, 
                     with_rating=> Deliver_Data 
                                      (from_the_list=>word_frequencies).count);
               -- get the next word from the list
               Next(in_the_list => word_frequencies);
               if not Is_End (of_the_list => word_frequencies) then
                  full_word := Deliver(from_the_list => word_frequencies);
               end if;
            end loop While_Post_Matches;
         -- else Length(pre) and Length(post) = 0
         end if;
      end if;  -- looking for digits first, then more generally
      -- Apply table: Apply characters table
      for smpl_no in training_comparisons.First_Index ..
                     training_comparisons.Last_Index loop
         if Position_Of(char_or_word=>training_comparisons(smpl_no).ch) > 0
         then  -- it is in the current list (look locally)
            training_comparisons(smpl_no).ratings(engine_word_freq) := 
                                 chars(Position_Of(char_or_word=>
                                            training_comparisons(smpl_no).ch));
         elsif Length(training_comparisons(smpl_no).ch) = 1
            then  -- single character located other than in current set
            training_comparisons(smpl_no).ratings(engine_word_freq) :=  --(looking globally)
                     chars(Number_of_Words_Or_Characters +
                           wide_character'Pos(Wide_Element(
                                        training_comparisons(smpl_no).ch, 1)));
         else  -- didn't really find it?
            null;         
         end if;
      end loop;
   end Engine_Word_Frequency;

begin
   Cell_Writer_Version.Register(revision => "$Revision: v1.0.0$",
                                for_module => "Word_Frequency");
   Sample_Comparison.
      Register(engine_data  => (name         => Value("Word context"),
                                func         => Engine_Word_Frequency'access,
                                e_range      => maximum_range / 3,
                                ignore_zeros => FALSE,
                                scale        => -1,
                                average      => 0,
                                max          => 0),
               with_id       => engine_word_freq);
end Word_Frequency;
