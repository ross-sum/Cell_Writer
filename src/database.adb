package body database is
   pragma Style_Checks (Off);

   function FK (Self : T_Catheterurinerecord'Class; Foreign : T_Colourchart'Class) return SQL_Criteria is
   begin
      return Self.Colour = Foreign.Value;
   end FK;

   function FK (Self : T_Catheterurinerecord'Class; Foreign : T_Floaties'Class) return SQL_Criteria is
   begin
      return Self.Floaties = Foreign.Value;
   end FK;

   function FK (Self : T_Catheterurinerecord'Class; Foreign : T_Catheterleakage'Class) return SQL_Criteria is
   begin
      return Self.Leakage = Foreign.Value;
   end FK;

   function FK (Self : T_Keyevents'Class; Foreign : T_Patientdetails'Class) return SQL_Criteria is
   begin
      return Self.Patient = Foreign.Identifier;
   end FK;

   function FK (Self : T_Queries'Class; Foreign : T_Reports'Class) return SQL_Criteria is
   begin
      return Self.Id = Foreign.Id;
   end FK;

   function FK (Self : T_Urinerecord'Class; Foreign : T_Holdstates'Class) return SQL_Criteria is
   begin
      return Self.Hold = Foreign.Id;
   end FK;

   function FK (Self : T_Urinerecord'Class; Foreign : T_Leakage'Class) return SQL_Criteria is
   begin
      return Self.Leakage = Foreign.Value;
   end FK;

   function FK (Self : T_Urinerecord'Class; Foreign : T_Padsizes'Class) return SQL_Criteria is
   begin
      return Self.Padtype = Foreign.Id;
   end FK;

   function FK (Self : T_Urinerecord'Class; Foreign : T_Spasms'Class) return SQL_Criteria is
   begin
      return Self.Spasm = Foreign.Spasm;
   end FK;

   function FK (Self : T_Urinerecords'Class; Foreign : T_Patientdetails'Class) return SQL_Criteria is
   begin
      return Self.Patient = Foreign.Identifier;
   end FK;
end database;
