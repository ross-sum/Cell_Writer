-----------------------------------------------------------------------
--                                                                   --
--                     G R I D _ T R A I N I N G                     --
--                                                                   --
--                     S p e c i f i c a t i o n                     --
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
--  General  Public Licence distributed with Cell_Writer.  If  not,  --
--  write  to  the Free Software Foundation,  51  Franklin  Street,  --
--  Fifth Floor, Boston, MA 02110-1301, USA.                         --
--                                                                   --
-----------------------------------------------------------------------
with dStrings;            use dStrings;
with Ada.Containers.Vectors;
with Glib;                use Glib;
package Grid_Training is

    -- Define the training statuses
   type training_status is (untrained, trained);
   for training_status use (0, 1);
    
    -- Key management information
   procedure Set_Window_Size(with_rows, and_columns : in positive);
       -- Record the number of rows and columns.
       -- Set the character and word pointer to the start
       -- and reset the window to the start.
    
    -- Set up for the character and word management for training.
   procedure Clear_Out_Training_Data;
       -- Clears out all the characters and words in the characters and
       -- words list.
   procedure Load(the_character : wide_character;
                  which_is : training_status := untrained);
       -- Add the character to the list.  Note if the character has
       -- training samples already.
   procedure Load(the_word : text; which_is : training_status := untrained);
       -- Add the word to the end of the list.  Note if the word has
       -- training samples already.
   procedure Load(the_word : UTF8_String; which_is:training_status:=untrained);
       -- Add the word to the end of the list (conversion to text is
       -- done internally).
   procedure Record_Training_Is_Done(on_char_or_word : text);
       -- Record the fact against the specified character or word that training
       -- has been done.
       -- If the word does not exist in the list, then also add it in.
   procedure Record_Training_Is_Done(on_word : UTF8_String);
       -- Record the fact against the specified word that training
       -- has been done (conversion to text is done internally).
   procedure Record_Training_Is_Done(on_character : wide_character);
       -- Record the fact against the specified character that training
       -- has been done (conversion to text is done internally).
   procedure Record_Training_Is_Not_Done(on_char_or_word : text);
       -- Change the status of the training to being untrained.  This may occur
       -- if the training is deleted.

    -- Index/pointer management of the training character set.
    -- Here we maintain a window over the set of characters and words
    -- that are visible in the cell grid.  The window is defined here
    -- as the array/grid of cell columns by cell rows.
    -- Whenever we page up or page down, the row pointer points to the
    -- first row.  Whenever we page up or page down or move a row up or
    -- row down, the character pointer points to the top of the page or
    -- the start of the row respectively.
   procedure Point_At_Grid_Start;
       -- Move to the start of the list of characters and words.
   procedure Point_At_Grid_End;
       -- Move to the end of the list of characters and words, with the
       -- first character pointing to the first one in the window.
   procedure Grid_Page_Up;
       -- Move the window up one page if there is a window's worth of space
       -- prior, if not then just go to the start.
   procedure Grid_Page_Down;
       -- Move the window down one page if there is a window's worth of space
       -- left, if not then just go to the end.
   procedure Grid_Row_Up;
       -- If not at the first row, move the row pointer up one and move the
       -- character pointer to the start of that row, otherwise move the
       -- window up one row (if not at the start) and then move the character
       -- pointer to the start of the first row.
   procedure Grid_Row_Down;
       -- If not at the last row, move the row pointer down one row and move
       -- the character pointer to the start of that row, otherwise move the
       -- window down one row (if not at the end) and then move the character
       -- pointer to the start of the last row.
   function Is_End_Of_Grid_Row return boolean;
       -- Return true if we have reached the end of the current row or if
       -- we have reached the end of the list of characters and words.
   function Is_End_Of_Grid_Page return boolean;
       -- Return true if we have reached the end of the current cell page
       -- or if we have reached the end of the list of characters and words.
   function The_Char_or_Word return text;
       -- Return the character or word at the current character pointer
       -- position and advance the character pointer.  If there are no
       -- more characters or words left, then return an empty string.
   function The_Char_or_Word_As_UTF8 return UTF8_String;
       -- Do as per The_Char_or_Word but return the result as a UTF8 string.
   function Is_Trained(char_or_word : UTF8_String) return boolean;
       -- Has the char[acter]_or_word been trained up?
   function Number_of_Words return natural;
       -- Return the total number of words loaded into the training list.
       -- This information is used by the Word_Frequency engine and it assumes
       -- that the words, perhaps contained in phrases, in the word frequency
       -- data are made up of words that are available for training.
   function Number_of_Words_Or_Characters return natural;
       -- As per Number_of_Words but for all characters and words loaded.
   function Position_Of(char_or_word : text) return natural;
       -- Provide the list's understanding of the character or word position.
   function Character_or_Word(at_position : in natural) return text;
       -- Return character or word at the specified postion in the list of
       -- characters and words. 
    
private

   subtype word_positions is integer range -1 .. integer'Last;
   no_words : constant word_positions := word_positions'First;
   
   type training is record
         data       : text;
         is_trained : training_status := untrained;
      end record;
   package Character_And_Word_Arrays is new Ada.Containers.Vectors
         (index_type   => natural,
          element_type => training);
   subtype training_array is Character_And_Word_Arrays.vector;
   
   type character_and_word_pointer_data is record
         word_list     : training_array;
         row_count     : positive;
         col_count     : positive;
         word_position : word_positions := no_words;
         window_start  : natural := 0;
         window_end    : natural := 0;
         current_row   : natural := 0;
         num_words     : natural := 0;  -- just words, not characters
      end record;

   procedure Record_Training_Status(on_char_or_word : text; 
                                    as : training_status);
       -- Record the fact against the specified character or word that training
       -- has been done.
       -- If the word does not exist in the list, then also add it in.
      
   training_data : character_and_word_pointer_data;
    
end Grid_Training;
