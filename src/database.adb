package body database is
   pragma Style_Checks (Off);

   function FK (Self : T_Combiningchrs'Class; Foreign : T_Languages'Class) return SQL_Criteria is
   begin
      return Self.Language = Foreign.Id;
   end FK;

   function FK (Self : T_Keydefinitions'Class; Foreign : T_Languages'Class) return SQL_Criteria is
   begin
      return Self.Language = Foreign.Id;
   end FK;

   function FK (Self : T_Learntdata'Class; Foreign : T_Userids'Class) return SQL_Criteria is
   begin
      return Self.User = Foreign.Uid;
   end FK;

   function FK (Self : T_Learntdata'Class; Foreign : T_Languages'Class) return SQL_Criteria is
   begin
      return Self.Language = Foreign.Id;
   end FK;

   function FK (Self : T_Queries'Class; Foreign : T_Reports'Class) return SQL_Criteria is
   begin
      return Self.Id = Foreign.Id;
   end FK;

   function FK (Self : T_Userids'Class; Foreign : T_Languages'Class) return SQL_Criteria is
   begin
      return Self.Language = Foreign.Id;
   end FK;

   function FK (Self : T_Words'Class; Foreign : T_Languages'Class) return SQL_Criteria is
   begin
      return Self.Language = Foreign.Id;
   end FK;
end database;
