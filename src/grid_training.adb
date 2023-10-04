-----------------------------------------------------------------------
--                                                                   --
--                     G R I D _ T R A I N I N G                     --
--                                                                   --
--                              B o d y                              --
--                                                                   --
--                           $Revision: 1.0 $                        --
--                                                                   --
--  Copyright (C) 2022  Hyper Quantum Pty Ltd.                       --
--  Written by Ross Summerfield.                                     --
--                                                                   --
--  This  package stores the characters and words that are  trained  --
--  on.   It supports the display of those characters and words  by  --
--  maintaining a 'window' over the displayed blocks, such that the  --
--  user can advance forward and backward by a line or a page.       --
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
--  General Public Licence distributed with  Urine_Records. If not,  --
--  write  to  the Free Software Foundation,  51  Franklin  Street,  --
--  Fifth Floor, Boston, MA 02110-1301, USA.                         --
--                                                                   --
-----------------------------------------------------------------------
-- with dStrings;            use dStrings;
-- with Ada.Containers.Vectors;
-- with Glib;                use Glib;
with Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
with Error_Log;
with Cell_Writer_Version;
package body Grid_Training is
   use Character_And_Word_Arrays;

   -- subtype word_positions is integer range -1 .. integer'Last;
   -- no_words : constant word_positions := word_positions'First;
   -- type training_status is (untrained, trained);
   -- type training is record
   --       data       : text;
   --       is_trained : training_status := untrained;
   --    end record;
   -- package Character_And_Word_Arrays is new Ada.Containers.Vectors
   --       (index_type   => natural,
   --        element_type => training);
   -- subtype training_array is Character_And_Word_Arrays.vector;
   -- type character_and_word_pointer_data is record
   --       word_list     : training_array;
   --       row_count     : positive;
   --       col_count     : positive;
   --       word_position : word_positions := no_words;
   --       window_start  : natural := 0;
   --       window_end    : natural := 0;
   --       current_row   : natural := 0;
   --       num_words     : natural := 0;  -- just words, not characters
   --    end record;
   --    training_data : character_and_word_pointer_data;
   
    -- Key management information
   procedure Set_Window_Size(with_rows, and_columns : in positive) is
       -- Record the number of rows and columns.
       -- Set the character and word pointer to the start
       -- and reset the window to the start.
   begin
      training_data.row_count := with_rows;
      training_data.col_count := and_columns;
      Point_At_Grid_Start;  -- point at the start of the character/word list.
   end Set_Window_Size;
    
    -- Set up for the character and word management for training.
   procedure Clear_Out_Training_Data is
     -- Clears out all the characters and words in the characters and
     -- words list.
   begin
      Error_Log.Debug_Data(at_level => 8, 
                           with_details => "Clear_Out_Training_Data: Start");
      Clear(training_data.word_list);
      training_data.word_position := no_words;
      training_data.window_start  := 1;
      training_data.window_end    := 
                           training_data.col_count * training_data.row_count;
      training_data.current_row   := 1;
      training_data.num_words     := 0;
   end Clear_Out_Training_Data;
   
   procedure Load(the_character : wide_character;
                  which_is : training_status := untrained) is
     -- Add the character to the list.
     -- We should insert it in the correct order.  Therefore we search through
     -- the current list and insert it at the correct alphabetical point.
      use Ada.Containers;
      char_as_text : constant text     := to_text(from_wide => the_character);
      trg          : constant training := (char_as_text, which_is);
      loaded : boolean := false;
   begin
      Error_Log.Debug_Data(at_level => 9, 
                           with_details => "Load(the_character): Start" & "charcter='"&the_character&"'.");
      if training_data.word_list.Length = 0
      then  -- at the start of the list
         training_data.word_list.Append(trg);
      else  -- list is at least 1 character long - find out slot in it
         for char_pos in training_data.word_list.First_Index .. 
                         training_data.word_list.Last_Index loop
            if char_as_text < training_data.word_list(char_pos).data
            then  -- the character is smaller (in unicode), insert it here
               training_data.word_list.Insert(char_pos, trg);
               loaded := true;
               exit;  -- the_character is inserted, so done!  
            elsif char_as_text = training_data.word_list(char_pos).data
            then  -- already loaded
               loaded := true;
               exit;  -- the_character is inserted, so done!  
            end if;
         end loop;
         if not loaded
         then -- got to the end so this is bigger than what was loaded so far
            training_data.word_list.Append(trg);  -- load at end
         end if;
      end if;
   end Load;

   procedure Load(the_word : text; which_is : training_status := untrained) is
     -- Add the word to the end of the list.
     -- This assumes that all the characters are loaded first before the
     -- words are loaded.  It also assumes that the words are loaded in
     -- order.
      trg : constant training := (the_word, which_is);
   begin
      Error_Log.Debug_Data(at_level => 9, 
                           with_details => "Load(the_word): Start");
      training_data.word_list.Append(trg);
      training_data.num_words := training_data.num_words + 1; 
   end Load;

   procedure Load(the_word : UTF8_String; 
                  which_is : training_status := untrained) is
     -- Add the word to the end of the list (conversion to text is
     -- done internally).
      use Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
   begin
      Load(the_word => To_Text(Decode(the_word, UTF_8)), which_is=> which_is);
   end Load;
   
   procedure Record_Training_Status(on_char_or_word : text; 
                                    as : training_status) is
       -- Record the fact against the specified character or word that training
       -- has been done.
       -- If the word does not exist in the list, then also add it in.
      use Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
      char_or_word : text renames on_char_or_word;
   begin
      Error_Log.Debug_Data(at_level => 9, 
                           with_details => "Record_Training_Status (" &
                                           To_String(char_or_word)&"): Start");
      -- First, find the character or word in the list then set the status.
      for char_pos in training_data.word_list.First_Index .. 
                      training_data.word_list.Last_Index loop
         if char_or_word = training_data.word_list(char_pos).data
         then  -- we found it, so set the training status
            training_data.word_list(char_pos).is_trained := as;
            return;  -- no need to continue on.
         end if;
      end loop;
      -- if we got here, then we didn't find it, so load it in.
      if Length(char_or_word) > 1
      then  -- loading a word
         Load(the_word => char_or_word, which_is => as);
      else  -- Loading a character
         Load(the_character => Wide_Element(char_or_word,1), which_is => as);
      end if;
   end Record_Training_Status;

   procedure Record_Training_Is_Done(on_char_or_word : text) is
       -- Record the fact against the specified character or word that training
       -- has been done.
       -- If the word does not exist in the list, then also add it in.
   begin
      Record_Training_Status(on_char_or_word, as => trained);
   end Record_Training_Is_Done;

   procedure Record_Training_Is_Not_Done(on_char_or_word : text) is
       -- Change the status of the training to being untrained.  This may occur
       -- if the training is deleted.
   begin
      Record_Training_Status(on_char_or_word, as => untrained);
   end Record_Training_Is_Not_Done;

   procedure Record_Training_Is_Done(on_word : UTF8_String) is
       -- Record the fact against the specified word that training
       -- has been done (conversion to text is done internally).
      use Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
   begin
      Record_Training_Is_Done(on_char_or_word=>To_Text(Decode(on_word,UTF_8)));
   end Record_Training_Is_Done;

   procedure Record_Training_Is_Done(on_character : wide_character) is
       -- Record the fact against the specified character that training
       -- has been done (conversion to text is done internally).
   begin
      Record_Training_Is_Done(on_char_or_word => To_Text(on_character));
   end Record_Training_Is_Done;
     
    -- Index/pointer management of the training character set.
    -- Here we maintain a window over the set of characters and words
    -- that are visible in the cell grid.
   procedure Point_At_Grid_Start is
       -- Move to the start of the list of characters and words.
      use Ada.Containers;
   begin
      Error_Log.Debug_Data(at_level => 8, 
                           with_details => "Point_At_Grid_Start: Start");
      if training_data.word_list.Length > 0
      then  -- point to start
         training_data.word_position := training_data.word_list.First_Index;
      else  -- point to nowhere
         training_data.word_position := no_words;
      end if;
      training_data.window_start := training_data.word_list.First_Index;
      if natural(training_data.word_list.Length) > 
                           training_data.col_count * training_data.row_count
         then  -- more training data loaded than the window size
         training_data.window_end:= 
                           training_data.col_count * training_data.row_count;
      elsif training_data.word_list.Length > 0
      then  -- amount of training data is less than the window size
         training_data.window_end:=natural(training_data.word_list.Last_Index);
      else  -- there is no training data - set to default
         training_data.window_end:= 0;
      end if;
      training_data.current_row  := 1;
   end Point_At_Grid_Start;

   procedure Point_At_Grid_End is
       -- Move to the end of the list of characters and words, with the
       -- first character pointing to the first one in the window.
      use Ada.Containers;
   begin
      Error_Log.Debug_Data(at_level => 8, 
                           with_details => "Point_At_Grid_End: Start");
      if training_data.word_list.Length > 0
      then  -- We have data
         if natural(training_data.word_list.Length) > 
                           training_data.col_count * training_data.row_count
         then  -- more training data loaded than the window size
            training_data.window_start := 
                           natural(training_data.word_list.Last_Index) + 1 -
                           training_data.col_count * training_data.row_count;
            training_data.window_end   := 
                           natural(training_data.word_list.Last_Index);
            training_data.word_position:= training_data.window_start;
            training_data.current_row  := 1;
         else  -- amount of training data is less than the window size
            training_data.window_start := training_data.word_list.First_Index;
            training_data.window_end   := 
                           natural(training_data.word_list.Last_Index);
            training_data.word_position:= training_data.word_list.First_Index;
            training_data.current_row  := 1;
         end if;
      else  -- no training characters loaded yet, so set to defaults
         training_data.word_position:= no_words;
         training_data.window_start := 1;
         training_data.window_end   := 0;
         training_data.current_row  := 1;
      end if;
   end Point_At_Grid_End;

   procedure Grid_Page_Up is
       -- Move the window up one page if there is a window's worth of space
       -- prior, if not then just go to the start.
   begin
      Error_Log.Debug_Data(at_level => 8, 
                           with_details => "Grid_Page_Up: Start");
      if training_data.window_start >= 
               training_data.col_count * training_data.row_count
      then  -- at least one window width's position prior
         training_data.window_start := training_data.window_start -
               training_data.col_count * training_data.row_count;
         training_data.window_end   := training_data.window_start - 1 +
                           training_data.col_count * training_data.row_count;
         training_data.word_position:= training_data.window_start;
         training_data.current_row  := 1;  -- set at top if paging up or down
      else  -- not enough window left before this, go to start
         Point_At_Grid_Start;
      end if;
   end Grid_Page_Up;

   procedure Grid_Page_Down is
       -- Move the window down one page if there is a window's worth of space
       -- left, if not then just go to the end.
   begin
      Error_Log.Debug_Data(at_level => 8, 
                           with_details => "Grid_Page_Down: Start");
      if training_data.window_start + 
               training_data.col_count * training_data.row_count < 
                                    natural(training_data.word_list.Last_Index)
      then  -- at least one window width's position after
         training_data.window_start := training_data.window_start +
               training_data.col_count * training_data.row_count;
         training_data.window_end   := training_data.window_start - 1 +
                           training_data.col_count * training_data.row_count;
         training_data.word_position:= training_data.window_start;
         training_data.current_row  := 1;  -- set at top if paging up or down
      else  -- not enough window left after this, just go to the end
         Point_At_Grid_End;
      end if;
   end Grid_Page_Down;

   procedure Grid_Row_Up is
       -- If not at the first row, move the row pointer up one and move the
       -- character pointer to the start of that row, otherwise move the
       -- window up one row (if not at the start) and then move the character
       -- pointer to the start of the first row.
   begin
      if training_data.current_row  > 1
      then  -- not at first row in the window, so move it up one
         training_data.current_row := training_data.current_row - 1;
         training_data.word_position:= 
               training_data.window_start + 
               (training_data.current_row - 1) * training_data.col_count;
      else  -- at the first row in the window, so move the window if possible
         if training_data.window_start >= 
                                 natural(training_data.word_list.First_Index) +
                                                    training_data.col_count - 1
         then  -- there is room to go up
            training_data.window_start := training_data.window_start - 
                                          training_data.col_count;
            training_data.window_end   := training_data.window_start - 1 +
                           training_data.col_count * training_data.row_count;
            training_data.word_position:= training_data.window_start;
         else  -- not enough room, just go to the start
            Point_At_Grid_Start;
         end if;
      end if;
   end Grid_Row_Up;

   procedure Grid_Row_Down is
       -- If not at the last row, move the row pointer down one row and move
       -- the character pointer to the start of that row, otherwise move the
       -- window down one row (if not at the end) and then move the character
       -- pointer to the start of the last row.
   begin
      if training_data.current_row < training_data.row_count
      then  -- there is room to go down within the window
         training_data.current_row := training_data.current_row + 1;
         training_data.word_position:= 
               training_data.window_start + 
               (training_data.current_row - 1) * training_data.col_count;
      else  -- we are at the last window row, so move window down if possible
         if training_data.window_end + training_data.col_count < 
                                    natural(training_data.word_list.Last_Index)
         then  -- there is room to go
            training_data.window_start := training_data.window_start + 
                                          training_data.col_count;
            training_data.window_end   := training_data.window_start - 1 +
                           training_data.col_count * training_data.row_count;
            training_data.word_position:= training_data.window_end - 
                                                   training_data.col_count + 1;
         else  -- not enough room, just go to the end
            Point_At_Grid_End;
         end if;
      end if;
   end Grid_Row_Down;

   function Is_End_Of_Grid_Row return boolean is
       -- Return true if we have reached the end of the current row or if
       -- we have reached the end of the list of characters and words.
      pos_in_window : constant natural := 
                  training_data.word_position - training_data.window_start + 1;
   begin
      Error_Log.Debug_Data(at_level => 9, 
                           with_details => "Is_End_Of_Grid_Row: Start");
      return pos_in_window rem training_data.col_count = 0;
   end Is_End_Of_Grid_Row;

   function Is_End_Of_Grid_Page return boolean is
       -- Return true if we have reached the end of the current cell page
       -- or if we have reached the end of the list of characters and words.
      pos_in_window : constant natural := 
                  training_data.word_position - training_data.window_start + 1;
   begin
      Error_Log.Debug_Data(at_level => 9, 
                           with_details => "Is_End_Of_Grid_Page: Start");
      return pos_in_window = training_data.col_count * training_data.row_count;
   end Is_End_Of_Grid_Page;

   function The_Char_or_Word return text is
       -- Return the character or word at the current character pointer
       -- position and advance the character pointer.  If there are no
       -- more characters or words left, then return an empty string.
   begin
      Error_Log.Debug_Data(at_level => 9, 
                           with_details => "The_Char_or_Word: Start");
      if training_data.word_position > no_words and 
         training_data.word_position <= 
                                    natural(training_data.word_list.Last_Index)
      then  -- advance word pointer and return the result
         training_data.word_position :=training_data. word_position + 1;
         Error_Log.Debug_Data(at_level => 9, 
                           with_details => "The_Char_or_Word: ("&integer'Wide_Image(training_data.word_position - 1)&")="&Value(training_data.word_list(training_data.word_position - 1).data));
         return training_data.word_list(training_data.word_position - 1).data;
      else
         return Clear;
      end if;
   end The_Char_or_Word;

   function The_Char_or_Word_As_UTF8 return UTF8_String is
       -- Do as per The_Char_or_Word but return the result as a UTF8 string.
      use Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
   begin
      return Encode(To_String(The_Char_or_Word));
   end The_Char_or_Word_As_UTF8;
   
   function Is_Trained(char_or_word : UTF8_String) return boolean is
       -- Has the char[acter]_or_word been trained up?
      use Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
      chr_or_word : constant text := To_Text(Decode(char_or_word));
   begin
      -- First, find the character or word in the list, then return the result.
      for char_pos in training_data.word_list.First_Index .. 
                      training_data.word_list.Last_Index loop
         if chr_or_word = training_data.word_list(char_pos).data
         then  -- we found it, so return the result
            return training_data.word_list(char_pos).is_trained = trained;
         end if;
      end loop;
      -- We didn't find it if we got here, so return default of false.
      return false;
   end Is_Trained;
   
   function Number_of_Words return natural is
       -- Return the total number of words loaded into the training list.
       -- This information is used by the Word_Frequency engine and it assumes
       -- that the words, perhaps contained in phrases, in the word frequency
       -- data are made up of words that are available for training.
   begin
      return training_data.num_words;
   end Number_of_Words;

   function Number_of_Words_Or_Characters return natural is
       -- As per Number_of_Words but for all characters and words loaded.
   begin
      return natural(training_data.word_list.Length);
   end Number_of_Words_Or_Characters;
   
   function Position_Of(char_or_word : text) return natural is
       -- Provide the list's understanding of the character or word position.
      use Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
      position : natural := 0;
   begin
      -- First, find the character or word in the list, then return the result.
      for char_pos in training_data.word_list.First_Index .. 
                      training_data.word_list.Last_Index loop
         position := position + 1;
         if char_or_word = training_data.word_list(char_pos).data
         then  -- we found it, so return the result
            return position;
         end if;
      end loop;
      -- We didn't find it if we got here, so return default of 0.
      return 0;
   end Position_Of;
   
   function Character_or_Word(at_position : in natural) return text is
       -- Return character or word at the specified postion in the list of
       -- characters and words. 
   begin
      return training_data.word_list(training_data.word_list.First_Index + 
                                                          at_position -1).data;
   end Character_or_Word;

begin
   Cell_Writer_Version.Register(revision => "$Revision: v1.0.0$",
                                for_module => "Grid_Training");
end Grid_Training;
