-----------------------------------------------------------------------
--                                                                   --
--                    W O R D _ F R E Q U E N C Y                    --
--                                                                   --
--                     S p e c i f i c a t i o n                     --
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
with GNATCOLL.SQL.Exec;
with DStrings;            use DStrings;
with Generic_Binary_Trees_With_Data;
with Samples;             use Samples;
with Sample_Comparison;
package Word_Frequency is

   function Word_Frequency_Is_Enabled return boolean;
       -- Return true if our current understanding of the enablement of the
       -- word frequency engine is true.  Default initial value is 'true'.
   procedure Set_Word_Frequency_Enablement(to : in boolean);
       
   procedure Load_Word_Frequency
                   (DB_Descr : GNATCOLL.SQL.Exec.Database_Description);
      -- Read in the word frequency file from the database. The file format 
      -- is: word (called WFWord in the database), count (called WdCount in
      -- the database).

   procedure Engine_Word_Frequency(input_sample: in Samples.input_sample_type;
                                   input_penalty : in out float;
                                   var1, var2 : natural;
                                   var3 : in out integer);
     -- This engine calculates the probability that the character or word at
     -- the current cell position is a particular character or word, working
     -- through the list of training samples and rating them.  In doing so,
     -- it does not use the input_sample at all.  It simply weights each
     -- training sample based upon previous and post (current cursor position
     -- actually entered characters or words.

private

   engine_word_freq : natural;  -- our engine identifier (set by Register)
   
   wordfreq_enable : boolean := true;

   type word_frequency_info is record
         word  : text;
         count : natural := 0;
      end record;

   package Word_Freq_Arrays is new Generic_Binary_Trees_With_Data
         (T   => text,
          D   => word_frequency_info,
           "<" => dStrings."<",
           storage_size => (524288 * 4));
   subtype word_frequency_array is Word_Freq_Arrays.list;
   
   word_frequencies : word_frequency_array;

   function PreComparison(comparitor, contains: text) return Boolean;
   function PostComparison(comparitor, contains: text) return Boolean;

end Word_Frequency;
