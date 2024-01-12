-----------------------------------------------------------------------
--                                                                   --
--                         C E L L   W R I T E R                     --
--                                                                   --
--                                B o d y                            --
--                                                                   --
--                           $Revision: 1.0 $                        --
--                                                                   --
--  Copyright (C) 2020  Hyper Quantum Pty Ltd.                       --
--  Written by Ross Summerfield and Michael Levin.                   --
--                                                                   --
--  This  application is a grid based character  recognition  input  --
--  method.                                                          --
--                                                                   --
--  This application is a fork of the cellwriter program written in  --
--  C  by  Michael Levin <risujin@risujin.org> (main  author  whose  --
--  intellectual  property  exists throughout the product)  and  is  --
--  Copyright (c) 2007.                                              --
--  It is completely based on their edition, but written in Ada and  --
--  also written to accommodate Blissymbolocs.  The main  objective  --
--  of  the  rewrite  is to allow for the output  of  a  string  of  --
--  combining  characters in response to input.   While  Cellwriter  --
--  does handle combining characters, it does not in this way. This  --
--  method  is important to making it highly useful for a  language  --
--  like Blissymbolics.                                              --
--  The  other main change is to use Glade for the  graphical  user  --
--  interface and the use of xdotool for XKB keyboard emulation.     --
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
with DStrings;            use DStrings;
with dStrings.IO;         use dStrings.IO;
with Calendar_Extensions; use Calendar_Extensions;
with String_Conversions;
with Error_Log;
with Host_Functions;
with Generic_Command_Parameters;
with Cell_Writer_Version;
with Main_Menu;
with Database;
with Recogniser;
with GNATCOLL.SQL.Sqlite;   -- or Postgres
with GNATCOLL.SQL.Exec;
with GNATCOLL.SQL, GNATCOLL.SQL.Exec.Tasking, GNATCOLL.SQL_BLOB;
with Ada.Sequential_IO;
with Ada.Directories;
procedure Cell_Writer is

   Already_Running : exception;
   
   default_log_file_name  : constant wide_string := "/var/log/cell_writer.log";
   default_log_file_format: constant wide_string := "";
   default_path_to_temp   : constant wide_string := "/tmp/";
   default_db_path        : constant wide_string := "~/var/lib/cellwriter/";
   default_db_file_name   : constant wide_string := "cell_writer.db";
   default_db_name        : constant wide_string := default_db_path &
                                                    default_db_file_name;
   default_tex_name       : constant wide_string := "/usr/bin/xelatex";
   default_pdf_name       : constant wide_string := "/usr/bin/xpdf";
   default_R_name         : constant wide_string := "/usr/bin/R";
   lock_file_name         : constant string:= "/var/run/lock/cell_writer.lock";

   package Parameters is new Generic_Command_Parameters
      (Cell_Writer_Version.Version,
       "z,temp,string," & default_path_to_temp &
                 ",path to the system writable temporary directory;" &
       "b,db,string," & default_db_name &
                 ",path and file name for the urine records database;" &
       "t,tex,string," & default_tex_name &
                 ", Path to LaTex PDF output generator;" & 
       "p,pdf,string," & default_pdf_name &
                 ", Path to PDF display tool;" &
       "r,R,string," & default_R_name &
                 ", Path to GNU R graph generating tool;" &
       "l,log,string," & default_log_file_name & 
                 ",log file name with optional path;" &
       "f,format,string," & default_log_file_format &
                 ",log file format (e.g. '' or 'WCEM=8' for UTF-8 or " & 
                 "'WECM=8,ctrl' to do UTF-8 and turn control characters into" &
                 "a readable format);" &
       "d,debug,integer,0,debug level (0=none + 9=max);" &
       "x,xid,boolean,FALSE,starts CellWriter in embedded mode. You can set "&
                 "gnome-screensaver to call Cell_Writer with this option to "&
                 "embed Cell_Writer into the unlock password prompt;" &
       "i,interactive,boolean,FALSE, run in interactive (attended) mode;",
       0, false);
   use Parameters;
   
   procedure Load_Configuration_Parameters(
                         for_database : GNATCOLL.SQL.Exec.Database_Description;
                         at_temp_path : string) is
      use GNATCOLL.SQL, Database;
      use GNATCOLL.SQL.Exec, GNATCOLL.SQL_BLOB;
      package Byte_IO is new Ada.Sequential_IO(byte);
      DB       : GNATCOLL.SQL.Exec.Database_Connection;
      Q_config : SQL_Query;
      R_config : Forward_Cursor;
   begin
      DB:=GNATCOLL.SQL.Exec.Tasking.Get_Task_Connection(Description=>for_database);
      Q_config := SQL_Select
         (Fields  => Configurations.ID & Configurations.Name & 
                     Configurations.DetFormat & Configurations.Details,
          From    => Configurations,
          Where   => (Configurations.ID > 0) AND
                     ((Configurations.DetFormat = "B") OR -- blob
                      (Configurations.DetFormat = "T")),  -- text
          Order_By=> Configurations.ID);
      R_config.Fetch (Connection => DB, Query => Q_config);
      if Success(DB) and then Has_Row(R_config) then
         while Has_Row(R_config) loop  -- while not end_of_table
            -- get the configuration data for the Name thing, and write out
            if Value(R_config, 2) = "B" then -- reformatting on the way
               declare
                  use String_Conversions, Byte_IO;
                  output_file : Byte_IO.file_type;
                  the_data    : blob := Blob_Value(R_config, 3);
                  file_name   : constant string := at_temp_path &
                                                   Value(R_config, 1);
               begin
                  if Length(the_data) > 0 then
                     Create(output_file, Out_File, file_name);
                     for byte_number in 1 .. Length(the_data) loop
                        Write(output_file, Element(the_data, byte_number));
                     end loop;
                     Close(output_file);
                  end if;
                  exception
                     when Byte_IO.Status_Error => null;  -- file already exists
               end;
            else  -- just write out
               declare
                  use String_Conversions;
                  output_file: dStrings.IO.file_type;
                  the_data   : Wide_String:= To_Wide_String(Value(R_config,3));
                  file_name  : constant string := at_temp_path &
                                                  Value(R_config, 1);
               begin
                  if the_data'Length > 0 then
                     Create(output_file, Out_File, file_name);
                     Put(output_file, the_data);
                     Close(output_file);
                  end if;
                  exception
                     when dStrings.IO.Status_Error => 
                        null;  -- file already exists
               end;
            end if;
            Next(R_config);  -- next record(Configurations)
         end loop;
      end if;
   end Load_Configuration_Parameters;
   
   procedure Initialise(db_name : string) is
      -- Initialise the configuration database if it does not exist.
      -- By default, put the db in var/lib/ and put any configuration
      -- setup parameters in etc/ beneath the home directory, sourcing the
      -- default files from either /var/lib/ or /var/local/lib and from
      -- either /etc/ or /usr/local/etc/.
      use Ada.Directories, String_Conversions;
      db_full_path_name : text;
   begin
      if (db_name'Length > 0) and then
         (db_name(db_name'First) /= '/') then
         if db_name(db_name'First) = '~' then -- user's home directory
            db_full_path_name:= Host_Functions.Get_Environment_Value(
                                                for_variable => "HOME") &
                                Value(db_name(db_name'First+1..db_name'Last));
         else  -- current directory
            db_full_path_name:= Value(Current_Directory) & "/" & Value(db_name);
         end if;
      else
         db_full_path_name := Value(db_name);
      end if;
      Error_Log.Debug_Data(at_level => 3, 
                        with_details => "DB path=" & Value(db_full_path_name));
      -- check for existence  #######MODIFY TO ALSO CHECK FOR POSTGRESQL######
      if not Exists(Value(db_full_path_name)) then
         -- if the DB doesn't exist, assume nothing does.  So copy it in.
         -- First, create the target directory if necessary
         begin
            -- Note: path needs to be absolute; "~/" doesn't work
            Create_Path(Containing_Directory(Value(db_full_path_name)));
            exception
               when others =>
                  Error_Log.Debug_Data(at_level => 1, 
                                   with_details => "Didn't create a DB path.");
                  null;
         end;
         -- Second check in /var/lib and then in /var/local/lib
         if Exists("/var/lib/" & To_String(default_db_file_name)) then
            -- copy from /var/lib/
            Copy_File(source_name=>"/var/lib/"&To_String(default_db_file_name),
                      target_name=>db_name, form=>"");
         elsif Exists("/var/local/lib/" &To_String(default_db_file_name)) then
            Copy_File(source_name=>"/var/local/lib/"&
                                   To_String(default_db_file_name),
                      target_name=>db_name, form=>"");
         else   -- don't know where to look
            Put_Line("Cannot locate " & default_db_file_name & 
                     " to initialise it.");
            null;  -- do nothing for now, but should error!
         end if;
      end if;
   end Initialise;

   procedure Terminate_Us is
   begin
      Error_Log.Debug_Data(at_level=>1, with_details=>"Terminate_Us: Start");
      Main_Menu.Menu_File_Exit_Select_CB(null);
      Error_Log.Debug_Data(at_level=>1, with_details=>"Terminate_Us: Finish");
   end Terminate_Us;

   lock_file : dStrings.IO.file_type;
   still_running : boolean := true;
   DB_Descr : GNATCOLL.SQL.Exec.Database_Description;
   tex_path : text := Parameter(with_flag => flag_type'('t'));
   pdf_path : text := Parameter(with_flag => flag_type'('p'));
   R_path   : text := Parameter(with_flag => flag_type'('r'));
   temp_path: text := Parameter(with_flag => flag_type'('z'));
      
begin  -- Cell_Writer
   Cell_Writer_Version.Register(revision   => "$Revision: v1.0.1 $",
                                for_module => "Cell_Writer");
   if Parameter(with_flag => flag_type'('i')) then
      Put_Line("Cell Writer");
      Put_Line("Grid-entry handwriting input panel");
      Put_Line("Copyright (C) 2022-23 Hyper Quantum Pty Ltd");
      Put_Line("with the recognition algorithm by Michael Levin (cellwriter)");
      Put_Line("Written by Ross Summerfield");
      New_Line;
      -- Host_Functions.Check_Reservation;
   end if;
   if  Parameters.is_invalid_parameter or
       Parameters.is_help_parameter or
       Parameters.is_version_parameter then
      -- abort Cell_Writer;
      Recogniser.Finalise_Early;
      return;
   end if;
   
   -- Set up the lock file, ensuring we are a single instance running
   declare
      pid : text;
   begin
      if Ada.Directories.Exists(lock_file_name)
      then  -- maybe the app crashed? Otherwise we aren't the only one running
         dStrings.IO.Open(lock_file, in_file, lock_file_name);
         dStrings.IO.Get_Line(lock_file, pid);   
         if Host_Functions.Process_Exists(for_id=>Get_Integer_From_String(pid))
         then  -- already running - we are not alone!
            Close(lock_file);
            raise Already_Running;
         else  -- not running - must be a crashed event
            dStrings.IO.Reset(lock_file, out_file);
         end if;
      else  -- lock file doesn't exist, so create it
         dStrings.IO.Create(lock_file, out_file, lock_file_name);
      end if;
      -- Load the lock file with our PID and enable it to be read
      Put_line(lock_file, Put_Into_String(Host_Functions.Process_ID));
      Flush(lock_file);
      Reset(lock_file, Append_File);
      -- Apply_Exclusive_Lock(to_file => lock_file);
      exception
         when Status_Error => raise Already_Running;
   end;
   
   -- Initialise files if necessary
   Initialise(Value(Parameter(with_flag => flag_type'('b'))));

   if Parameter(with_flag => flag_type'('i')) then
      Put_Line("Setting Log file to '" & 
               Value(Parameter(with_name=>Value("log"))) & "'.");
   end if;
   Error_Log.Set_Log_File_Name(
      Value(Parameter(with_name=>Value("log"))), 
      Value(Parameter(with_name=>Value("format"))));
   Error_Log.Set_Debug_Level
         (to => Parameter(with_flag => flag_type'('d')) );
   Error_Log.Debug_Data(at_level => 1, 
                        with_details => "Cell_Writer: Start processing");
   still_running := false;
   
   -- Set up the database
   declare
      db_full_path_name : text;
      db_name : string := Value(Parameter(with_flag => flag_type'('b')));
      use Ada.Directories, String_Conversions;
   begin
      if db_name(db_name'First) = '~' then -- user's home directory
         db_full_path_name:= Host_Functions.Get_Environment_Value(
                                                for_variable => "HOME") &
                                Value(db_name(db_name'First+1..db_name'Last));
      elsif db_name(db_name'First) = '/' then -- absolute path
         db_full_path_name:= Value(db_name);
      else  -- current directory
         db_full_path_name:= Value(Current_Directory) & "/" & Value(db_name);
      end if;
      Error_Log.Debug_Data(at_level => 3, 
                        with_details => "DB path=" & Value(db_full_path_name));
      DB_Descr := GNATCOLL.SQL.Sqlite.Setup(Value(db_full_path_name));
   end;
   -- Load in the configuration data
   Load_Configuration_Parameters(for_database => DB_Descr, 
                                 at_temp_path => Value(temp_path));
   -- Bring up the main menu
   Main_Menu.Initialise_Main_Menu(Parameters.The_Usage, DB_Descr, 
                                  tex_path, pdf_path, R_path,Value(temp_path));
   -- Free up the database description when done
   GNATCOLL.SQL.Exec.Free (DB_Descr);
   
   -- wait for termination and wait for messages
   while still_running loop
      delay 1.0;  -- wait a second
      still_running:= not Host_Functions.Told_To_Die;
   end loop;
   dStrings.IO.Delete(lock_file);
   Terminate_Us;
   
   Error_Log.Debug_Data(at_level=>1, with_details=>"Cell_Writer: Finish");
                        
   exception  -- invalid parameter
      when Already_Running =>
         Put_Line("Application is already running"); 
      when Name_Error | Use_Error =>
         Usage("Error in configuration file name.");
      when Host_Functions.Naming_Error =>
         Usage("Error in daemonising this application.");
      when Host_Functions.Terminate_Application =>
         if Ada.Directories.Exists(lock_file_name) and then
            Is_Open(lock_file) 
         then
            dStrings.IO.Delete(lock_file);
         end if;
         Terminate_Us;
            -- requested to terminate: shut down tasks
end Cell_Writer;
