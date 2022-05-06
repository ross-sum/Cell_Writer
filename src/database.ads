with GNATCOLL.SQL; use GNATCOLL.SQL;
with GNATCOLL.SQL_BLOB; use  GNATCOLL.SQL_BLOB;
pragma Warnings (Off, "no entities of * are referenced");
pragma Warnings (Off, "use clause for package * has no effect");
with GNATCOLL.SQL_Fields; use GNATCOLL.SQL_Fields;
pragma Warnings (On, "no entities of * are referenced");
pragma Warnings (On, "use clause for package * has no effect");
with database_Names; use database_Names;
package database is
   pragma Style_Checks (Off);
   pragma Elaborate_Body;

   type T_Abstract_Configurations
      (Instance : Cst_String_Access;
       Index    : Integer)
   is abstract new SQL_Table (Ta_Configurations, Instance, Index) with
   record
      Id : SQL_Field_Integer (Ta_Configurations, Instance, N_Id, Index);
      --  Index into config items

      Name : SQL_Field_Text (Ta_Configurations, Instance, N_Name, Index);
      --  Could be a file name, etc.

      Detformat : SQL_Field_Text (Ta_Configurations, Instance, N_Detformat, Index);
      --  Details fmt: T=Text,B=Base64

      Details : SQL_Field_Text (Ta_Configurations, Instance, N_Details, Index);
      --  (actually a blob)

   end record;

   type T_Configurations (Instance : Cst_String_Access)
      is new T_Abstract_Configurations (Instance, -1) with null record;
   --  To use named aliases of the table in a query
   --  Use Instance=>null to use the default name.

   type T_Numbered_Configurations (Index : Integer)
      is new T_Abstract_Configurations (null, Index) with null record;
   --  To use aliases in the form name1, name2,...

   type T_Abstract_Languages
      (Instance : Cst_String_Access;
       Index    : Integer)
   is abstract new SQL_Table (Ta_Languages, Instance, Index) with
   record
      Name : SQL_Field_Text (Ta_Languages, Instance, N_Name, Index);
      --  Language Name for look-up

      Id : SQL_Field_Integer (Ta_Languages, Instance, N_Id, Index);
      --  Language unique identifier

      Start : SQL_Field_Integer (Ta_Languages, Instance, N_Start, Index);
      --  Character set start

      Endchar : SQL_Field_Integer (Ta_Languages, Instance, N_Endchar, Index);
      --  Character set end

      Description : SQL_Field_Text (Ta_Languages, Instance, N_Description, Index);
      --  Details about this lingo

      Selected : SQL_Field_Boolean (Ta_Languages, Instance, N_Selected, Index);
      --  Is this a char set used?

   end record;

   type T_Languages (Instance : Cst_String_Access)
      is new T_Abstract_Languages (Instance, -1) with null record;
   --  To use named aliases of the table in a query
   --  Use Instance=>null to use the default name.

   type T_Numbered_Languages (Index : Integer)
      is new T_Abstract_Languages (null, Index) with null record;
   --  To use aliases in the form name1, name2,...

   type T_Abstract_Learntdata
      (Instance : Cst_String_Access;
       Index    : Integer)
   is abstract new SQL_Table (Ta_Learntdata, Instance, Index) with
   record
      User : SQL_Field_Integer (Ta_Learntdata, Instance, N_User, Index);
      --  ID of the user

      Language : SQL_Field_Integer (Ta_Learntdata, Instance, N_Language, Index);
      --  Language identifier

      Id : SQL_Field_Integer (Ta_Learntdata, Instance, N_Id, Index);
      --  Offset from Language Start

      Description : SQL_Field_Text (Ta_Learntdata, Instance, N_Description, Index);
      --  Important details

   end record;

   type T_Learntdata (Instance : Cst_String_Access)
      is new T_Abstract_Learntdata (Instance, -1) with null record;
   --  To use named aliases of the table in a query
   --  Use Instance=>null to use the default name.

   type T_Numbered_Learntdata (Index : Integer)
      is new T_Abstract_Learntdata (null, Index) with null record;
   --  To use aliases in the form name1, name2,...

   type T_Abstract_Queries
      (Instance : Cst_String_Access;
       Index    : Integer)
   is abstract new SQL_Table (Ta_Queries, Instance, Index) with
   record
      Id : SQL_Field_Integer (Ta_Queries, Instance, N_Id, Index);
      --  This query's report

      Q_Number : SQL_Field_Integer (Ta_Queries, Instance, N_Q_Number, Index);
      --  Query number in report

      Targettbl : SQL_Field_Text (Ta_Queries, Instance, N_Targettbl, Index);
      --  Target table name (if any)

      Sql : SQL_Field_Text (Ta_Queries, Instance, N_Sql, Index);
      --  SQL to run

   end record;

   type T_Queries (Instance : Cst_String_Access)
      is new T_Abstract_Queries (Instance, -1) with null record;
   --  To use named aliases of the table in a query
   --  Use Instance=>null to use the default name.

   type T_Numbered_Queries (Index : Integer)
      is new T_Abstract_Queries (null, Index) with null record;
   --  To use aliases in the form name1, name2,...

   type T_Abstract_Reports
      (Instance : Cst_String_Access;
       Index    : Integer)
   is abstract new SQL_Table (Ta_Reports, Instance, Index) with
   record
      Id : SQL_Field_Integer (Ta_Reports, Instance, N_Id, Index);
      --  Report ID/number

      Name : SQL_Field_Text (Ta_Reports, Instance, N_Name, Index);
      --  Report Name/Heading

      Filename : SQL_Field_Text (Ta_Reports, Instance, N_Filename, Index);
      --  file name for report files

      Hasgraph : SQL_Field_Boolean (Ta_Reports, Instance, N_Hasgraph, Index);
      --  Does it have graph(s)?

      R : SQL_Field_Text (Ta_Reports, Instance, N_R, Index);
      --  Graph instructions (in R)

      Latex : SQL_Field_Text (Ta_Reports, Instance, N_Latex, Index);
      --  Report construction 'howto'

   end record;

   type T_Reports (Instance : Cst_String_Access)
      is new T_Abstract_Reports (Instance, -1) with null record;
   --  To use named aliases of the table in a query
   --  Use Instance=>null to use the default name.

   type T_Numbered_Reports (Index : Integer)
      is new T_Abstract_Reports (null, Index) with null record;
   --  To use aliases in the form name1, name2,...

   type T_Abstract_Trainingdata
      (Instance : Cst_String_Access;
       Index    : Integer)
   is abstract new SQL_Table (Ta_Trainingdata, Instance, Index) with
   record
      User : SQL_Field_Integer (Ta_Trainingdata, Instance, N_User, Index);
      --  ID of the user

      Language : SQL_Field_Integer (Ta_Trainingdata, Instance, N_Language, Index);
      --  Language identifier

      Id : SQL_Field_Integer (Ta_Trainingdata, Instance, N_Id, Index);
      --  Offset from Language Start

      Sampleno : SQL_Field_Integer (Ta_Trainingdata, Instance, N_Sampleno, Index);
      --  Sample number recorded

      Sample : SQL_Field_Text (Ta_Trainingdata, Instance, N_Sample, Index);
      --  The sample

   end record;

   type T_Trainingdata (Instance : Cst_String_Access)
      is new T_Abstract_Trainingdata (Instance, -1) with null record;
   --  To use named aliases of the table in a query
   --  Use Instance=>null to use the default name.

   type T_Numbered_Trainingdata (Index : Integer)
      is new T_Abstract_Trainingdata (null, Index) with null record;
   --  To use aliases in the form name1, name2,...

   type T_Abstract_Userids
      (Instance : Cst_String_Access;
       Index    : Integer)
   is abstract new SQL_Table (Ta_Userids, Instance, Index) with
   record
      Uid : SQL_Field_Integer (Ta_Userids, Instance, N_Uid, Index);
      --  User unique identifier

      Logon : SQL_Field_Text (Ta_Userids, Instance, N_Logon, Index);
      --  System identifier for user

      Name : SQL_Field_Text (Ta_Userids, Instance, N_Name, Index);
      --  The user's name

      Language : SQL_Field_Integer (Ta_Userids, Instance, N_Language, Index);
      --  The language preferred

   end record;

   type T_Userids (Instance : Cst_String_Access)
      is new T_Abstract_Userids (Instance, -1) with null record;
   --  To use named aliases of the table in a query
   --  Use Instance=>null to use the default name.

   type T_Numbered_Userids (Index : Integer)
      is new T_Abstract_Userids (null, Index) with null record;
   --  To use aliases in the form name1, name2,...

   type T_Abstract_Words
      (Instance : Cst_String_Access;
       Index    : Integer)
   is abstract new SQL_Table (Ta_Words, Instance, Index) with
   record
      Language : SQL_Field_Integer (Ta_Words, Instance, N_Language, Index);
      --  Language of the word

      Id : SQL_Field_Integer (Ta_Words, Instance, N_Id, Index);
      --  Word Unique identifier

      Word : SQL_Field_Text (Ta_Words, Instance, N_Word, Index);
      --  UTF-8 word

      Description : SQL_Field_Text (Ta_Words, Instance, N_Description, Index);
      --  A name or similar

   end record;

   type T_Words (Instance : Cst_String_Access)
      is new T_Abstract_Words (Instance, -1) with null record;
   --  To use named aliases of the table in a query
   --  Use Instance=>null to use the default name.

   type T_Numbered_Words (Index : Integer)
      is new T_Abstract_Words (null, Index) with null record;
   --  To use aliases in the form name1, name2,...

   function FK (Self : T_Learntdata'Class; Foreign : T_Userids'Class) return SQL_Criteria;
   function FK (Self : T_Learntdata'Class; Foreign : T_Languages'Class) return SQL_Criteria;
   function FK (Self : T_Queries'Class; Foreign : T_Reports'Class) return SQL_Criteria;
   function FK (Self : T_Userids'Class; Foreign : T_Languages'Class) return SQL_Criteria;
   function FK (Self : T_Words'Class; Foreign : T_Languages'Class) return SQL_Criteria;
   Configurations : T_Configurations (null);
   Languages : T_Languages (null);
   Learntdata : T_Learntdata (null);
   Queries : T_Queries (null);
   Reports : T_Reports (null);
   Trainingdata : T_Trainingdata (null);
   Userids : T_Userids (null);
   Words : T_Words (null);
end database;
