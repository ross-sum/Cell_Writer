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
--  This application is a grid based character recognition input method.  --
--                                                                   --
--  This application is a fork of the cellwriter program written in  --
--  C  by  Michael Levin <risujin@risujin.org> (main  author  whose  --
--  intellectual property exists throughout the product) and .  --
--  It is completely based on their edition, but written in Ada and  --
--  also written to accommodate Blissymbolocs.  The main  objective  --
--  of  the  rewrite  is to allow for the output  of  a  string  of  --
--  combining  characters in response to input.   While  Cellwriter  --
--  does handle combining characters, it does not in this way. This  --
--  method  is important to making it highly useful for a  language  --
--  like Blissymbolics.                                              --
--  The  other main change is to use Glade for the  graphical  user  --
--  interface.                                                       --
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
with Error_Log;
with Host_Functions;
with Generic_Command_Parameters;
with Cell_Writer_Version;
with Main_Menu;
with Database;
with GNATCOLL.SQL.Sqlite;   -- or Postgres
with GNATCOLL.SQL.Exec;
with GNATCOLL.SQL, GNATCOLL.SQL.Exec.Tasking, GNATCOLL.SQL_BLOB;
with Ada.Sequential_IO;
procedure Cell_Writer is

   default_log_file_name : constant wide_string := 
                           "/var/log/cell_writer.log";

   package Parameters is new Generic_Command_Parameters
      (Cell_Writer_Version.Version,
       "z,temp,string," & default_path_to_temp &
                 ",path to the system writable temporary directory;" &
       "b,db,string," & default_db_name &
                 ",path and file name for the urine records database;" &
       "l,log,string," & default_log_file_name & 
                 ",log file name with optional path;" &
       "d,debug,integer,0,debug level (0=none + 9=max);" &
       "x,xid,boolean,FALSE,starts  CellWriter in embedded mode. You can set "&
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
          Where   => Configurations.ID > 0,
          Order_By=> Configurations.ID);
      R_config.Fetch (Connection => DB, Query => Q_config);
      if Success(DB) and then Has_Row(R_config) then
         while Has_Row(R_config) loop  -- while not end_of_table
            -- get the configuration data for the Name thing, and write out
            if Value(R_config, 2) = "B" then -- reformatting on the way
               declare
                  use string_conversions, Byte_IO;
                  output_file : file_type;
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
                     when Status_Error => null;  -- file already exists
               end;
            else  -- just write out
               declare
                  use string_conversions, Ada.Text_IO;
                  output_file : Ada.Text_IO.file_type;
                  the_data    : String := Value(R_config, 3);
                  file_name   : constant string := at_temp_path &
                                                   Value(R_config, 1);
               begin
                  if the_data'Length > 0 then
                     Create(output_file, Out_File, file_name);
                     Put(output_file, the_data);
                     Close(output_file);
                  end if;
                  exception
                     when Ada.Text_IO.Status_Error => 
                        null;  -- file already exists
               end;
            end if;
            Next(R_config);  -- next record(Configurations)
         end loop;
      end if;
   end Load_Configuration_Parameters;
   
   procedure Initialise is
     -- Initialise the configuration database if it does not exist.
     -- By default, put the db in var/lib/ and put any configuration
     -- setup parameters in etc/ beneath the home directory, sourcing the
     -- default files from either /var/lib/ or /var/local/lib and from
     -- either /etc/ or /usr/local/etc/.
   begin
   -- check for existence
   -- if the DB doesn't exist, assume nothing does.  So copy it in.
      null;
   end Initialise;

   procedure Terminate_Us is
   begin
      Error_Log.Debug_Data(at_level=>1, with_details=>"Terminate_Us: Start");
      Error_Log.Debug_Data(at_level=>1, with_details=>"Terminate_Us: Finish");
   end Terminate_Us;

   still_running : boolean := true;
   DB_Descr : GNATCOLL.SQL.Exec.Database_Description;
   temp_path: text := Parameter(with_flag => flag_type'('z'));
      
begin  -- Cell_Writer
   Cell_Writer_Version.Register(revision   => "$Revision: 1.0 $",
                                for_module => "Cell_Writer");
   if Parameter(with_flag => flag_type'('i')) then
      Put_Line("Cell Writer");
      Put_Line("Grid-entry handwriting input panel");
      Put_Line("Copyright (C) 2022 Hyper Quantum Pty Ltd, Michael Levin");
      Put_Line("Written by Ross Summerfield and Michael Levin");
      New_Line;
      -- Host_Functions.Check_Reservation;
   end if;
   if  Parameters.is_invalid_parameter or
   Parameters.is_help_parameter or
   Parameters.is_version_parameter then
      -- abort Cell_Writer;
      return;
   end if;
   
   -- Initialise files if necessary
   Initialise;

   if Parameter(with_flag => flag_type'('i')) then
      Put_Line("Setting Log file to '" & 
               Value(Parameter(with_name=>Value("log"))) & "'.");
   end if;
   Error_Log.Set_Log_File_Name(
      Value(Parameter(with_name=>Value("log"))));
   Error_Log.Set_Debug_Level
         (to => Parameter(with_flag => flag_type'('d')) );
   Error_Log.Debug_Data(at_level => 1, 
                        with_details => "Cell_Writer: Start processing");
   if not Parameter(with_flag => flag_type'('i')) then
      if Host_Functions.Daemonise = 0 then
         -- we are the child - continue on
         Error_Log.Debug_Data(at_level => 2, 
                              with_details => "Cell_Writer: Daemonised");
         declare -- log the SIGTERM reservation for the daemon
            attached, installed : boolean;
         begin
            Host_Functions.Check_Reservation(attached, installed);
            if attached then
               Error_Log.Debug_Data(at_level=>3, with_details=> "attached");
            else
               Error_Log.Debug_Data(at_level=>3, with_details=> "unattached");
            end if;
            if installed then
               Error_Log.Debug_Data(at_level=>3, with_details=> "installed");
            else
               Error_Log.Debug_Data(at_level=>3, with_details=> "uninstalled");
            end if;
         end;
         null;
      else  -- we are the parent or there was an error
         Error_Log.Debug_Data(at_level => 2, 
                      with_details => "Cell_Writer: Daemon parent exiting");
         return;  -- exit gracefully
      end if;
   else  -- interactive, set up and run as per normal
      null;  
   end if;
   
   -- Set up the database
   DB_Descr := GNATCOLL.SQL.Sqlite.Setup
                            (Value(Parameter(with_flag => flag_type'('x'))));
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
   Terminate_Us;
   
   Error_Log.Debug_Data(at_level=>1, with_details=>"Cell_Writer: Finish");
                        
   exception  -- invalid parameter
      when Name_Error | Use_Error =>
         Usage("Error in configuration file name.");
      -- when dStr_IO.Serial_Error =>
         -- Error_Log.Put(the_error => 1, error_intro => "I/O Device Error", 
            --  error_message => "Error with setting up or operating the device");
      when Host_Functions.Naming_Error =>
         Usage("Error in daemonising this application.");
      when Host_Functions.Terminate_Application =>
         Terminate_Us;
            -- requested to terminate: shut down tasks
end Cell_Writer;
