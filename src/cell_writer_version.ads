with Generic_Versions;
package Cell_Writer_Version is

   package Cell_Writer_Versions is new Generic_Versions
   ("1.0.0", "Cell_Writer");

   function Version return wide_string 
   renames Cell_Writer_Versions.Version;
   function Application_Title return wide_string
   renames Cell_Writer_Versions.Application_Title;
   function Application_Name return wide_string
   renames Cell_Writer_Versions.Application_Name;
   function Computer_Name return wide_string
   renames Cell_Writer_Versions.Computer_Name;
   procedure Register(revision, for_module : in wide_string)
   renames Cell_Writer_Versions.Register;
   function Revision_List return wide_string
   renames Cell_Writer_Versions.Revision_List;

end Cell_Writer_Version;