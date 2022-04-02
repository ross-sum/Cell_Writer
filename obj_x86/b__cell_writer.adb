pragma Warnings (Off);
pragma Ada_95;
pragma Source_File_Name (ada_main, Spec_File_Name => "b__cell_writer.ads");
pragma Source_File_Name (ada_main, Body_File_Name => "b__cell_writer.adb");
pragma Suppress (Overflow_Check);

with System.Restrictions;
with Ada.Exceptions;

package body ada_main is

   E077 : Short_Integer; pragma Import (Ada, E077, "system__os_lib_E");
   E010 : Short_Integer; pragma Import (Ada, E010, "ada__exceptions_E");
   E015 : Short_Integer; pragma Import (Ada, E015, "system__soft_links_E");
   E027 : Short_Integer; pragma Import (Ada, E027, "system__exception_table_E");
   E042 : Short_Integer; pragma Import (Ada, E042, "ada__containers_E");
   E072 : Short_Integer; pragma Import (Ada, E072, "ada__io_exceptions_E");
   E057 : Short_Integer; pragma Import (Ada, E057, "ada__strings_E");
   E059 : Short_Integer; pragma Import (Ada, E059, "ada__strings__maps_E");
   E063 : Short_Integer; pragma Import (Ada, E063, "ada__strings__maps__constants_E");
   E047 : Short_Integer; pragma Import (Ada, E047, "interfaces__c_E");
   E029 : Short_Integer; pragma Import (Ada, E029, "system__exceptions_E");
   E083 : Short_Integer; pragma Import (Ada, E083, "system__object_reader_E");
   E052 : Short_Integer; pragma Import (Ada, E052, "system__dwarf_lines_E");
   E023 : Short_Integer; pragma Import (Ada, E023, "system__soft_links__initialize_E");
   E041 : Short_Integer; pragma Import (Ada, E041, "system__traceback__symbolic_E");
   E218 : Short_Integer; pragma Import (Ada, E218, "gnat_E");
   E216 : Short_Integer; pragma Import (Ada, E216, "interfaces__c__strings_E");
   E162 : Short_Integer; pragma Import (Ada, E162, "system__task_info_E");
   E156 : Short_Integer; pragma Import (Ada, E156, "system__task_primitives__operations_E");
   E287 : Short_Integer; pragma Import (Ada, E287, "system__task_primitives__interrupt_operations_E");
   E105 : Short_Integer; pragma Import (Ada, E105, "ada__tags_E");
   E119 : Short_Integer; pragma Import (Ada, E119, "ada__streams_E");
   E127 : Short_Integer; pragma Import (Ada, E127, "system__file_control_block_E");
   E126 : Short_Integer; pragma Import (Ada, E126, "system__finalization_root_E");
   E124 : Short_Integer; pragma Import (Ada, E124, "ada__finalization_E");
   E123 : Short_Integer; pragma Import (Ada, E123, "system__file_io_E");
   E191 : Short_Integer; pragma Import (Ada, E191, "system__storage_pools_E");
   E187 : Short_Integer; pragma Import (Ada, E187, "system__finalization_masters_E");
   E185 : Short_Integer; pragma Import (Ada, E185, "system__storage_pools__subpools_E");
   E183 : Short_Integer; pragma Import (Ada, E183, "ada__strings__wide_maps_E");
   E179 : Short_Integer; pragma Import (Ada, E179, "ada__strings__wide_unbounded_E");
   E008 : Short_Integer; pragma Import (Ada, E008, "ada__calendar_E");
   E006 : Short_Integer; pragma Import (Ada, E006, "ada__calendar__delays_E");
   E147 : Short_Integer; pragma Import (Ada, E147, "ada__real_time_E");
   E117 : Short_Integer; pragma Import (Ada, E117, "ada__wide_text_io_E");
   E248 : Short_Integer; pragma Import (Ada, E248, "system__assertions_E");
   E285 : Short_Integer; pragma Import (Ada, E285, "system__interrupt_management__operations_E");
   E250 : Short_Integer; pragma Import (Ada, E250, "system__pool_global_E");
   E272 : Short_Integer; pragma Import (Ada, E272, "system__pool_size_E");
   E234 : Short_Integer; pragma Import (Ada, E234, "system__tasking__initialization_E");
   E224 : Short_Integer; pragma Import (Ada, E224, "system__tasking__protected_objects_E");
   E230 : Short_Integer; pragma Import (Ada, E230, "system__tasking__protected_objects__entries_E");
   E242 : Short_Integer; pragma Import (Ada, E242, "system__tasking__queuing_E");
   E258 : Short_Integer; pragma Import (Ada, E258, "system__tasking__stages_E");
   E281 : Short_Integer; pragma Import (Ada, E281, "system__interrupts_E");
   E204 : Short_Integer; pragma Import (Ada, E204, "dstrings_E");
   E270 : Short_Integer; pragma Import (Ada, E270, "general_storage_pool_E");
   E268 : Short_Integer; pragma Import (Ada, E268, "dynamic_lists_E");
   E274 : Short_Integer; pragma Import (Ada, E274, "interlocks_E");
   E262 : Short_Integer; pragma Import (Ada, E262, "serial_communications_E");
   E260 : Short_Integer; pragma Import (Ada, E260, "dstrings__serial_comms_E");
   E210 : Short_Integer; pragma Import (Ada, E210, "sockets_E");
   E220 : Short_Integer; pragma Import (Ada, E220, "sockets__types_E");
   E214 : Short_Integer; pragma Import (Ada, E214, "sockets__naming_E");
   E217 : Short_Integer; pragma Import (Ada, E217, "sockets__thin_E");
   E208 : Short_Integer; pragma Import (Ada, E208, "generic_versions_E");
   E177 : Short_Integer; pragma Import (Ada, E177, "cell_writer_version_E");
   E174 : Short_Integer; pragma Import (Ada, E174, "string_functions_E");
   E113 : Short_Integer; pragma Import (Ada, E113, "calendar_extensions_E");
   E266 : Short_Integer; pragma Import (Ada, E266, "error_log_E");
   E278 : Short_Integer; pragma Import (Ada, E278, "host_functions_E");
   E256 : Short_Integer; pragma Import (Ada, E256, "strings_functions_E");
   E254 : Short_Integer; pragma Import (Ada, E254, "dstrings__io_E");
   E276 : Short_Integer; pragma Import (Ada, E276, "generic_command_parameters_E");

   Sec_Default_Sized_Stacks : array (1 .. 1) of aliased System.Secondary_Stack.SS_Stack (System.Parameters.Runtime_Default_Sec_Stack_Size);

   Local_Priority_Specific_Dispatching : constant String := "";
   Local_Interrupt_States : constant String := "";

   Is_Elaborated : Boolean := False;

   procedure finalize_library is
   begin
      E254 := E254 - 1;
      declare
         procedure F1;
         pragma Import (Ada, F1, "dstrings__io__finalize_spec");
      begin
         F1;
      end;
      E278 := E278 - 1;
      declare
         procedure F2;
         pragma Import (Ada, F2, "host_functions__finalize_spec");
      begin
         F2;
      end;
      declare
         procedure F3;
         pragma Import (Ada, F3, "error_log__finalize_body");
      begin
         E266 := E266 - 1;
         F3;
      end;
      declare
         procedure F4;
         pragma Import (Ada, F4, "error_log__finalize_spec");
      begin
         F4;
      end;
      declare
         procedure F5;
         pragma Import (Ada, F5, "cell_writer_version__finalize_spec");
      begin
         E177 := E177 - 1;
         F5;
      end;
      declare
         procedure F6;
         pragma Import (Ada, F6, "sockets__naming__finalize_body");
      begin
         E214 := E214 - 1;
         F6;
      end;
      E210 := E210 - 1;
      declare
         procedure F7;
         pragma Import (Ada, F7, "sockets__naming__finalize_spec");
      begin
         F7;
      end;
      declare
         procedure F8;
         pragma Import (Ada, F8, "sockets__finalize_spec");
      begin
         F8;
      end;
      E260 := E260 - 1;
      declare
         procedure F9;
         pragma Import (Ada, F9, "dstrings__serial_comms__finalize_spec");
      begin
         F9;
      end;
      E262 := E262 - 1;
      declare
         procedure F10;
         pragma Import (Ada, F10, "serial_communications__finalize_spec");
      begin
         F10;
      end;
      E274 := E274 - 1;
      declare
         procedure F11;
         pragma Import (Ada, F11, "interlocks__finalize_spec");
      begin
         F11;
      end;
      E270 := E270 - 1;
      declare
         procedure F12;
         pragma Import (Ada, F12, "general_storage_pool__finalize_spec");
      begin
         F12;
      end;
      E281 := E281 - 1;
      declare
         procedure F13;
         pragma Import (Ada, F13, "system__interrupts__finalize_spec");
      begin
         F13;
      end;
      E230 := E230 - 1;
      declare
         procedure F14;
         pragma Import (Ada, F14, "system__tasking__protected_objects__entries__finalize_spec");
      begin
         F14;
      end;
      E272 := E272 - 1;
      declare
         procedure F15;
         pragma Import (Ada, F15, "system__pool_size__finalize_spec");
      begin
         F15;
      end;
      E250 := E250 - 1;
      declare
         procedure F16;
         pragma Import (Ada, F16, "system__pool_global__finalize_spec");
      begin
         F16;
      end;
      E117 := E117 - 1;
      declare
         procedure F17;
         pragma Import (Ada, F17, "ada__wide_text_io__finalize_spec");
      begin
         F17;
      end;
      E179 := E179 - 1;
      declare
         procedure F18;
         pragma Import (Ada, F18, "ada__strings__wide_unbounded__finalize_spec");
      begin
         F18;
      end;
      E183 := E183 - 1;
      declare
         procedure F19;
         pragma Import (Ada, F19, "ada__strings__wide_maps__finalize_spec");
      begin
         F19;
      end;
      E185 := E185 - 1;
      declare
         procedure F20;
         pragma Import (Ada, F20, "system__storage_pools__subpools__finalize_spec");
      begin
         F20;
      end;
      E187 := E187 - 1;
      declare
         procedure F21;
         pragma Import (Ada, F21, "system__finalization_masters__finalize_spec");
      begin
         F21;
      end;
      declare
         procedure F22;
         pragma Import (Ada, F22, "system__file_io__finalize_body");
      begin
         E123 := E123 - 1;
         F22;
      end;
      declare
         procedure Reraise_Library_Exception_If_Any;
            pragma Import (Ada, Reraise_Library_Exception_If_Any, "__gnat_reraise_library_exception_if_any");
      begin
         Reraise_Library_Exception_If_Any;
      end;
   end finalize_library;

   procedure adafinal is
      procedure s_stalib_adafinal;
      pragma Import (C, s_stalib_adafinal, "system__standard_library__adafinal");

      procedure Runtime_Finalize;
      pragma Import (C, Runtime_Finalize, "__gnat_runtime_finalize");

   begin
      if not Is_Elaborated then
         return;
      end if;
      Is_Elaborated := False;
      Runtime_Finalize;
      s_stalib_adafinal;
   end adafinal;

   type No_Param_Proc is access procedure;
   pragma Favor_Top_Level (No_Param_Proc);

   procedure adainit is
      Main_Priority : Integer;
      pragma Import (C, Main_Priority, "__gl_main_priority");
      Time_Slice_Value : Integer;
      pragma Import (C, Time_Slice_Value, "__gl_time_slice_val");
      WC_Encoding : Character;
      pragma Import (C, WC_Encoding, "__gl_wc_encoding");
      Locking_Policy : Character;
      pragma Import (C, Locking_Policy, "__gl_locking_policy");
      Queuing_Policy : Character;
      pragma Import (C, Queuing_Policy, "__gl_queuing_policy");
      Task_Dispatching_Policy : Character;
      pragma Import (C, Task_Dispatching_Policy, "__gl_task_dispatching_policy");
      Priority_Specific_Dispatching : System.Address;
      pragma Import (C, Priority_Specific_Dispatching, "__gl_priority_specific_dispatching");
      Num_Specific_Dispatching : Integer;
      pragma Import (C, Num_Specific_Dispatching, "__gl_num_specific_dispatching");
      Main_CPU : Integer;
      pragma Import (C, Main_CPU, "__gl_main_cpu");
      Interrupt_States : System.Address;
      pragma Import (C, Interrupt_States, "__gl_interrupt_states");
      Num_Interrupt_States : Integer;
      pragma Import (C, Num_Interrupt_States, "__gl_num_interrupt_states");
      Unreserve_All_Interrupts : Integer;
      pragma Import (C, Unreserve_All_Interrupts, "__gl_unreserve_all_interrupts");
      Detect_Blocking : Integer;
      pragma Import (C, Detect_Blocking, "__gl_detect_blocking");
      Default_Stack_Size : Integer;
      pragma Import (C, Default_Stack_Size, "__gl_default_stack_size");
      Default_Secondary_Stack_Size : System.Parameters.Size_Type;
      pragma Import (C, Default_Secondary_Stack_Size, "__gnat_default_ss_size");
      Leap_Seconds_Support : Integer;
      pragma Import (C, Leap_Seconds_Support, "__gl_leap_seconds_support");
      Bind_Env_Addr : System.Address;
      pragma Import (C, Bind_Env_Addr, "__gl_bind_env_addr");

      procedure Runtime_Initialize (Install_Handler : Integer);
      pragma Import (C, Runtime_Initialize, "__gnat_runtime_initialize");

      Finalize_Library_Objects : No_Param_Proc;
      pragma Import (C, Finalize_Library_Objects, "__gnat_finalize_library_objects");
      Binder_Sec_Stacks_Count : Natural;
      pragma Import (Ada, Binder_Sec_Stacks_Count, "__gnat_binder_ss_count");
      Default_Sized_SS_Pool : System.Address;
      pragma Import (Ada, Default_Sized_SS_Pool, "__gnat_default_ss_pool");

   begin
      if Is_Elaborated then
         return;
      end if;
      Is_Elaborated := True;
      Main_Priority := -1;
      Time_Slice_Value := -1;
      WC_Encoding := 'b';
      Locking_Policy := ' ';
      Queuing_Policy := ' ';
      Task_Dispatching_Policy := ' ';
      System.Restrictions.Run_Time_Restrictions :=
        (Set =>
          (False, False, False, False, False, False, False, False, 
           False, False, False, False, False, False, False, False, 
           False, False, False, False, False, False, False, False, 
           False, False, False, False, False, False, False, False, 
           False, False, False, False, False, False, False, False, 
           False, False, False, False, False, False, False, False, 
           False, False, False, False, False, False, False, False, 
           False, False, False, False, False, False, False, False, 
           False, False, False, False, False, False, False, False, 
           False, False, False, False, False, True, False, False, 
           False, False, False, False, False, False, False, False, 
           False, False, False, False),
         Value => (0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
         Violated =>
          (True, False, True, False, True, True, False, False, 
           True, False, False, True, True, True, True, False, 
           False, False, False, False, True, True, False, True, 
           True, False, True, True, True, True, False, False, 
           False, False, False, True, False, True, True, False, 
           True, True, True, True, False, True, False, True, 
           True, False, True, True, False, False, True, False, 
           True, False, False, True, False, True, True, True, 
           False, False, True, False, True, True, True, False, 
           True, True, False, True, True, True, True, False, 
           False, True, False, False, False, True, True, True, 
           True, False, True, False),
         Count => (0, 0, 0, 6, 9, 10, 3, 0, 5, 0),
         Unknown => (False, False, False, False, False, False, True, False, True, False));
      Priority_Specific_Dispatching :=
        Local_Priority_Specific_Dispatching'Address;
      Num_Specific_Dispatching := 0;
      Main_CPU := -1;
      Interrupt_States := Local_Interrupt_States'Address;
      Num_Interrupt_States := 0;
      Unreserve_All_Interrupts := 0;
      Detect_Blocking := 0;
      Default_Stack_Size := -1;
      Leap_Seconds_Support := 0;

      ada_main'Elab_Body;
      Default_Secondary_Stack_Size := System.Parameters.Runtime_Default_Sec_Stack_Size;
      Binder_Sec_Stacks_Count := 1;
      Default_Sized_SS_Pool := Sec_Default_Sized_Stacks'Address;

      Runtime_Initialize (1);

      Finalize_Library_Objects := finalize_library'access;

      Ada.Exceptions'Elab_Spec;
      System.Soft_Links'Elab_Spec;
      System.Exception_Table'Elab_Body;
      E027 := E027 + 1;
      Ada.Containers'Elab_Spec;
      E042 := E042 + 1;
      Ada.Io_Exceptions'Elab_Spec;
      E072 := E072 + 1;
      Ada.Strings'Elab_Spec;
      E057 := E057 + 1;
      Ada.Strings.Maps'Elab_Spec;
      E059 := E059 + 1;
      Ada.Strings.Maps.Constants'Elab_Spec;
      E063 := E063 + 1;
      Interfaces.C'Elab_Spec;
      E047 := E047 + 1;
      System.Exceptions'Elab_Spec;
      E029 := E029 + 1;
      System.Object_Reader'Elab_Spec;
      E083 := E083 + 1;
      System.Dwarf_Lines'Elab_Spec;
      E052 := E052 + 1;
      System.Os_Lib'Elab_Body;
      E077 := E077 + 1;
      System.Soft_Links.Initialize'Elab_Body;
      E023 := E023 + 1;
      E015 := E015 + 1;
      System.Traceback.Symbolic'Elab_Body;
      E041 := E041 + 1;
      E010 := E010 + 1;
      Gnat'Elab_Spec;
      E218 := E218 + 1;
      Interfaces.C.Strings'Elab_Spec;
      E216 := E216 + 1;
      System.Task_Info'Elab_Spec;
      E162 := E162 + 1;
      System.Task_Primitives.Operations'Elab_Body;
      E156 := E156 + 1;
      System.Task_Primitives.Interrupt_Operations'Elab_Body;
      E287 := E287 + 1;
      Ada.Tags'Elab_Spec;
      Ada.Tags'Elab_Body;
      E105 := E105 + 1;
      Ada.Streams'Elab_Spec;
      E119 := E119 + 1;
      System.File_Control_Block'Elab_Spec;
      E127 := E127 + 1;
      System.Finalization_Root'Elab_Spec;
      E126 := E126 + 1;
      Ada.Finalization'Elab_Spec;
      E124 := E124 + 1;
      System.File_Io'Elab_Body;
      E123 := E123 + 1;
      System.Storage_Pools'Elab_Spec;
      E191 := E191 + 1;
      System.Finalization_Masters'Elab_Spec;
      System.Finalization_Masters'Elab_Body;
      E187 := E187 + 1;
      System.Storage_Pools.Subpools'Elab_Spec;
      E185 := E185 + 1;
      Ada.Strings.Wide_Maps'Elab_Spec;
      E183 := E183 + 1;
      Ada.Strings.Wide_Unbounded'Elab_Spec;
      E179 := E179 + 1;
      Ada.Calendar'Elab_Spec;
      Ada.Calendar'Elab_Body;
      E008 := E008 + 1;
      Ada.Calendar.Delays'Elab_Body;
      E006 := E006 + 1;
      Ada.Real_Time'Elab_Spec;
      Ada.Real_Time'Elab_Body;
      E147 := E147 + 1;
      Ada.Wide_Text_Io'Elab_Spec;
      Ada.Wide_Text_Io'Elab_Body;
      E117 := E117 + 1;
      System.Assertions'Elab_Spec;
      E248 := E248 + 1;
      System.Interrupt_Management.Operations'Elab_Body;
      E285 := E285 + 1;
      System.Pool_Global'Elab_Spec;
      E250 := E250 + 1;
      System.Pool_Size'Elab_Spec;
      E272 := E272 + 1;
      System.Tasking.Initialization'Elab_Body;
      E234 := E234 + 1;
      System.Tasking.Protected_Objects'Elab_Body;
      E224 := E224 + 1;
      System.Tasking.Protected_Objects.Entries'Elab_Spec;
      E230 := E230 + 1;
      System.Tasking.Queuing'Elab_Body;
      E242 := E242 + 1;
      System.Tasking.Stages'Elab_Body;
      E258 := E258 + 1;
      System.Interrupts'Elab_Spec;
      System.Interrupts'Elab_Body;
      E281 := E281 + 1;
      Dstrings'Elab_Spec;
      Dstrings'Elab_Body;
      E204 := E204 + 1;
      General_Storage_Pool'Elab_Spec;
      General_Storage_Pool'Elab_Body;
      E270 := E270 + 1;
      E268 := E268 + 1;
      Interlocks'Elab_Spec;
      Interlocks'Elab_Body;
      E274 := E274 + 1;
      Serial_Communications'Elab_Spec;
      E262 := E262 + 1;
      Dstrings.Serial_Comms'Elab_Spec;
      DSTRINGS.SERIAL_COMMS'ELAB_BODY;
      E260 := E260 + 1;
      Sockets'Elab_Spec;
      Sockets.Types'Elab_Spec;
      E220 := E220 + 1;
      Sockets.Naming'Elab_Spec;
      Sockets.Thin'Elab_Spec;
      E217 := E217 + 1;
      Sockets'Elab_Body;
      E210 := E210 + 1;
      Sockets.Naming'Elab_Body;
      E214 := E214 + 1;
      E208 := E208 + 1;
      Cell_Writer_Version'Elab_Spec;
      E177 := E177 + 1;
      String_Functions'Elab_Body;
      E174 := E174 + 1;
      Calendar_Extensions'Elab_Body;
      E113 := E113 + 1;
      Error_Log'Elab_Spec;
      Error_Log'Elab_Body;
      E266 := E266 + 1;
      Host_Functions'Elab_Spec;
      Host_Functions'Elab_Body;
      E278 := E278 + 1;
      Strings_Functions'Elab_Body;
      E256 := E256 + 1;
      Dstrings.Io'Elab_Spec;
      Dstrings.Io'Elab_Body;
      E254 := E254 + 1;
      E276 := E276 + 1;
   end adainit;

   procedure Ada_Main_Program;
   pragma Import (Ada, Ada_Main_Program, "_ada_cell_writer");

   function main
     (argc : Integer;
      argv : System.Address;
      envp : System.Address)
      return Integer
   is
      procedure Initialize (Addr : System.Address);
      pragma Import (C, Initialize, "__gnat_initialize");

      procedure Finalize;
      pragma Import (C, Finalize, "__gnat_finalize");
      SEH : aliased array (1 .. 2) of Integer;

      Ensure_Reference : aliased System.Address := Ada_Main_Program_Name'Address;
      pragma Volatile (Ensure_Reference);

   begin
      if gnat_argc = 0 then
         gnat_argc := argc;
         gnat_argv := argv;
      end if;
      gnat_envp := envp;

      Initialize (SEH'Address);
      adainit;
      Ada_Main_Program;
      adafinal;
      Finalize;
      return (gnat_exit_status);
   end;

--  BEGIN Object file/option list
   --   /home/public/pro/ada/dynamic-strings/obj_x86/os_constants.o
   --   /home/public/pro/ada/dynamic-strings/obj_x86/dstrings.o
   --   /home/public/pro/ada/cellwriter/obj_x86/general_storage_pool.o
   --   /home/public/pro/ada/cellwriter/obj_x86/dynamic_lists.o
   --   /home/public/pro/ada/cellwriter/obj_x86/host_functions_thin.o
   --   /home/public/pro/ada/cellwriter/obj_x86/interlocks.o
   --   /home/public/pro/ada/dynamic-strings/obj_x86/serial_comms_h.o
   --   /home/public/pro/ada/dynamic-strings/obj_x86/serial_communications.o
   --   /home/public/pro/ada/dynamic-strings/obj_x86/dstrings-serial_comms.o
   --   /home/public/pro/ada/cellwriter/obj_x86/generic_versions.o
   --   /home/public/pro/ada/cellwriter/obj_x86/cell_writer_version.o
   --   /home/public/pro/ada/cellwriter/obj_x86/string_functions.o
   --   /home/public/pro/ada/cellwriter/obj_x86/calendar_extensions.o
   --   /home/public/pro/ada/cellwriter/obj_x86/error_log.o
   --   /home/public/pro/ada/cellwriter/obj_x86/host_functions.o
   --   /home/public/pro/ada/dynamic-strings/obj_x86/strings_functions.o
   --   /home/public/pro/ada/dynamic-strings/obj_x86/dstrings-io.o
   --   /home/public/pro/ada/cellwriter/obj_x86/generic_command_parameters.o
   --   /home/public/pro/ada/cellwriter/obj_x86/cell_writer.o
   --   -L/home/public/pro/ada/cellwriter/obj_x86/
   --   -L/home/public/pro/ada/cellwriter/obj_x86/
   --   -L/usr/lib/i386-linux-gnu/ada/adalib/adasockets/
   --   -L/home/public/pro/ada/dynamic-strings/obj_x86/
   --   -L/usr/lib/gcc/i686-linux-gnu/10/adalib/
   --   -shared
   --   -lgnarl-10
   --   -lgnat-10
   --   -lrt
   --   -lpthread
   --   -ldl
--  END Object file/option list   

end ada_main;
