with GNATCOLL.SQL; use GNATCOLL.SQL;
with GNATCOLL.SQL_BLOB; use  GNATCOLL.SQL_BLOB;
with GNATCOLL.SQL_Date_and_Time; use  GNATCOLL.SQL_Date_and_Time;
pragma Warnings (Off, "no entities of * are referenced");
pragma Warnings (Off, "use clause for package * has no effect");
with GNATCOLL.SQL_Fields; use GNATCOLL.SQL_Fields;
pragma Warnings (On, "no entities of * are referenced");
pragma Warnings (On, "use clause for package * has no effect");
with database_Names; use database_Names;
package database is
   pragma Style_Checks (Off);
   pragma Elaborate_Body;

   type T_Abstract_Combiningchrs
      (Instance : Cst_String_Access;
       Index    : Integer)
   is abstract new SQL_Table (Ta_Combiningchrs, Instance, Index) with
   record
      Language : SQL_Field_Integer (Ta_Combiningchrs, Instance, N_Language, Index);
      --  Language for this CChar

      Buttonnum : SQL_Field_Integer (Ta_Combiningchrs, Instance, N_Buttonnum, Index);
      --  Button number for this chr

      Cchar : SQL_Field_Text (Ta_Combiningchrs, Instance, N_Cchar, Index);
      --  The combining character

      Tooltip : SQL_Field_Text (Ta_Combiningchrs, Instance, N_Tooltip, Index);
      --  Tool Tip for the button

      Display : SQL_Field_Text (Ta_Combiningchrs, Instance, N_Display, Index);
      --  Symbol displayed on button

      Macro : SQL_Field_Integer (Ta_Combiningchrs, Instance, N_Macro, Index);
      --  The macro that applies

   end record;

   type T_Combiningchrs (Instance : Cst_String_Access)
      is new T_Abstract_Combiningchrs (Instance, -1) with null record;
   --  To use named aliases of the table in a query
   --  Use Instance=>null to use the default name.

   type T_Numbered_Combiningchrs (Index : Integer)
      is new T_Abstract_Combiningchrs (null, Index) with null record;
   --  To use aliases in the form name1, name2,...

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

   type T_Abstract_Keydefinitions
      (Instance : Cst_String_Access;
       Index    : Integer)
   is abstract new SQL_Table (Ta_Keydefinitions, Instance, Index) with
   record
      Language : SQL_Field_Integer (Ta_Keydefinitions, Instance, N_Language, Index);
      --  Language for this key def

      Key_Id : SQL_Field_Integer (Ta_Keydefinitions, Instance, N_Key_Id, Index);
      --  Key to apply the def to

      Unshiftdisp : SQL_Field_Text (Ta_Keydefinitions, Instance, N_Unshiftdisp, Index);
      --  Display char - caps off

      Shiftdisp : SQL_Field_Text (Ta_Keydefinitions, Instance, N_Shiftdisp, Index);
      --  Display char - caps lck on

      Uschrspace : SQL_Field_Text (Ta_Keydefinitions, Instance, N_Uschrspace, Index);
      --  Unshifted char - Space pos

      Uschrasky : SQL_Field_Text (Ta_Keydefinitions, Instance, N_Uschrasky, Index);
      --  Unshifted char - Above Sky

      Uschrsky : SQL_Field_Text (Ta_Keydefinitions, Instance, N_Uschrsky, Index);
      --  Unshifted char - Sky posn

      Uschrbsky : SQL_Field_Text (Ta_Keydefinitions, Instance, N_Uschrbsky, Index);
      --  Unshifted char - Below Sky

      Uschrupper : SQL_Field_Text (Ta_Keydefinitions, Instance, N_Uschrupper, Index);
      --  Unshifted char - Upper pos

      Uschrmiddle : SQL_Field_Text (Ta_Keydefinitions, Instance, N_Uschrmiddle, Index);
      --  Unshifted char - Middle

      Uschrlower : SQL_Field_Text (Ta_Keydefinitions, Instance, N_Uschrlower, Index);
      --  Unshifted char - Lower pos

      Uschrground : SQL_Field_Text (Ta_Keydefinitions, Instance, N_Uschrground, Index);
      --  Unshifted char - Ground

      Uschrjbgnd : SQL_Field_Text (Ta_Keydefinitions, Instance, N_Uschrjbgnd, Index);
      --  Unshifted char - Jst B.Gnd

      Uschrbgnd : SQL_Field_Text (Ta_Keydefinitions, Instance, N_Uschrbgnd, Index);
      --  Unshifted char - Below Gnd

      Uschrcore : SQL_Field_Text (Ta_Keydefinitions, Instance, N_Uschrcore, Index);
      --  Unshifted char - Core pos

      Schrspace : SQL_Field_Text (Ta_Keydefinitions, Instance, N_Schrspace, Index);
      --  Shifted char - Space pos'n

      Schrasky : SQL_Field_Text (Ta_Keydefinitions, Instance, N_Schrasky, Index);
      --  Shifted char - Above Sky

      Schrsky : SQL_Field_Text (Ta_Keydefinitions, Instance, N_Schrsky, Index);
      --  Shifted char - Sky positn

      Schrbsky : SQL_Field_Text (Ta_Keydefinitions, Instance, N_Schrbsky, Index);
      --  Shifted char - Below Sky

      Schrupper : SQL_Field_Text (Ta_Keydefinitions, Instance, N_Schrupper, Index);
      --  Shifted char - Upper posn

      Schrmiddle : SQL_Field_Text (Ta_Keydefinitions, Instance, N_Schrmiddle, Index);
      --  Shifted char - Middle posn

      Schrlower : SQL_Field_Text (Ta_Keydefinitions, Instance, N_Schrlower, Index);
      --  Shifted char - Lower posn

      Schrground : SQL_Field_Text (Ta_Keydefinitions, Instance, N_Schrground, Index);
      --  Shifted char - Ground pos

      Schrjbgnd : SQL_Field_Text (Ta_Keydefinitions, Instance, N_Schrjbgnd, Index);
      --  Shifted char - Just B. Gnd

      Schrbgnd : SQL_Field_Text (Ta_Keydefinitions, Instance, N_Schrbgnd, Index);
      --  Shifted char - Below Gnd

      Schrcore : SQL_Field_Text (Ta_Keydefinitions, Instance, N_Schrcore, Index);
      --  Shifted char - Core posn

   end record;

   type T_Keydefinitions (Instance : Cst_String_Access)
      is new T_Abstract_Keydefinitions (Instance, -1) with null record;
   --  To use named aliases of the table in a query
   --  Use Instance=>null to use the default name.

   type T_Numbered_Keydefinitions (Index : Integer)
      is new T_Abstract_Keydefinitions (null, Index) with null record;
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

   type T_Abstract_Macros
      (Instance : Cst_String_Access;
       Index    : Integer)
   is abstract new SQL_Table (Ta_Macros, Instance, Index) with
   record
      Id : SQL_Field_Integer (Ta_Macros, Instance, N_Id, Index);
      --  Unique ID for this macro

      Macro : SQL_Field_Text (Ta_Macros, Instance, N_Macro, Index);
      --  The macro

   end record;

   type T_Macros (Instance : Cst_String_Access)
      is new T_Abstract_Macros (Instance, -1) with null record;
   --  To use named aliases of the table in a query
   --  Use Instance=>null to use the default name.

   type T_Numbered_Macros (Index : Integer)
      is new T_Abstract_Macros (null, Index) with null record;
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

   type T_Abstract_Recogniserstats
      (Instance : Cst_String_Access;
       Index    : Integer)
   is abstract new SQL_Table (Ta_Recogniserstats, Instance, Index) with
   record
      User : SQL_Field_Integer (Ta_Recogniserstats, Instance, N_User, Index);
      --  ID of the user

      Recdate : SQL_Field_tDate (Ta_Recogniserstats, Instance, N_Recdate, Index);
      --  Recognition date

      Rectime : SQL_Field_tTime (Ta_Recogniserstats, Instance, N_Rectime, Index);
      --  Recognition time

      Examined : SQL_Field_Integer (Ta_Recogniserstats, Instance, N_Examined, Index);
      --  Number samples examined

      Disqual : SQL_Field_Integer (Ta_Recogniserstats, Instance, N_Disqual, Index);
      --  Number samples disqualified

      Strength : SQL_Field_Integer (Ta_Recogniserstats, Instance, N_Strength, Index);
      --  Recognition strength (0-100)

      Recduration : SQL_Field_Float (Ta_Recogniserstats, Instance, N_Recduration, Index);
      --  Processing time (seconds)

      Alternatives : SQL_Field_Integer (Ta_Recogniserstats, Instance, N_Alternatives, Index);
      --  Number of alternatives

      Topone : SQL_Field_Text (Ta_Recogniserstats, Instance, N_Topone, Index);
      --  Most likely sample

   end record;

   type T_Recogniserstats (Instance : Cst_String_Access)
      is new T_Abstract_Recogniserstats (Instance, -1) with null record;
   --  To use named aliases of the table in a query
   --  Use Instance=>null to use the default name.

   type T_Numbered_Recogniserstats (Index : Integer)
      is new T_Abstract_Recogniserstats (null, Index) with null record;
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

      Sample : SQL_Field_Blob (Ta_Trainingdata, Instance, N_Sample, Index);
      --  The sample

      Trgdate : SQL_Field_tDate (Ta_Trainingdata, Instance, N_Trgdate, Index);
      --  Date traning sample made

      Trgtime : SQL_Field_tTime (Ta_Trainingdata, Instance, N_Trgtime, Index);
      --  Training sample time made

      Used : SQL_Field_Integer (Ta_Trainingdata, Instance, N_Used, Index);
      --  Count of times sample used

   end record;

   type T_Trainingdata (Instance : Cst_String_Access)
      is new T_Abstract_Trainingdata (Instance, -1) with null record;
   --  To use named aliases of the table in a query
   --  Use Instance=>null to use the default name.

   type T_Numbered_Trainingdata (Index : Integer)
      is new T_Abstract_Trainingdata (null, Index) with null record;
   --  To use aliases in the form name1, name2,...

   type T_Abstract_Trainingdatawords
      (Instance : Cst_String_Access;
       Index    : Integer)
   is abstract new SQL_Table (Ta_Trainingdatawords, Instance, Index) with
   record
      Id : SQL_Field_Integer (Ta_Trainingdatawords, Instance, N_Id, Index);
      --  Offset from Language Start

      Wordid : SQL_Field_Integer (Ta_Trainingdatawords, Instance, N_Wordid, Index);
      --  Word unique id for Language

      Word : SQL_Field_Text (Ta_Trainingdatawords, Instance, N_Word, Index);
      --  UTF-8 word

      Sampleno : SQL_Field_Integer (Ta_Trainingdatawords, Instance, N_Sampleno, Index);
      --  Sample number recorded

      Sample : SQL_Field_Blob (Ta_Trainingdatawords, Instance, N_Sample, Index);
      --  The sample

      Trgdate : SQL_Field_tDate (Ta_Trainingdatawords, Instance, N_Trgdate, Index);
      --  Date traning sample made

      Trgtime : SQL_Field_tTime (Ta_Trainingdatawords, Instance, N_Trgtime, Index);
      --  Training sample time made

      Used : SQL_Field_Integer (Ta_Trainingdatawords, Instance, N_Used, Index);
      --  Count of times sample used

      User : SQL_Field_Text (Ta_Trainingdatawords, Instance, N_User, Index);
      --  System identifier for user

   end record;

   type T_Trainingdatawords (Instance : Cst_String_Access)
      is new T_Abstract_Trainingdatawords (Instance, -1) with null record;
   --  To use named aliases of the table in a query
   --  Use Instance=>null to use the default name.

   type T_Numbered_Trainingdatawords (Index : Integer)
      is new T_Abstract_Trainingdatawords (null, Index) with null record;
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

   type T_Abstract_Wordfrequency
      (Instance : Cst_String_Access;
       Index    : Integer)
   is abstract new SQL_Table (Ta_Wordfrequency, Instance, Index) with
   record
      Language : SQL_Field_Integer (Ta_Wordfrequency, Instance, N_Language, Index);
      --  Language of word/phrase

      Wfword : SQL_Field_Text (Ta_Wordfrequency, Instance, N_Wfword, Index);
      --  the word or phrase

      Wdcount : SQL_Field_Integer (Ta_Wordfrequency, Instance, N_Wdcount, Index);
      --  Count of words

      Description : SQL_Field_Text (Ta_Wordfrequency, Instance, N_Description, Index);
      --  A name or similar

   end record;

   type T_Wordfrequency (Instance : Cst_String_Access)
      is new T_Abstract_Wordfrequency (Instance, -1) with null record;
   --  To use named aliases of the table in a query
   --  Use Instance=>null to use the default name.

   type T_Numbered_Wordfrequency (Index : Integer)
      is new T_Abstract_Wordfrequency (null, Index) with null record;
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

   function FK (Self : T_Combiningchrs'Class; Foreign : T_Languages'Class) return SQL_Criteria;
   function FK (Self : T_Combiningchrs'Class; Foreign : T_Macros'Class) return SQL_Criteria;
   function FK (Self : T_Keydefinitions'Class; Foreign : T_Languages'Class) return SQL_Criteria;
   function FK (Self : T_Learntdata'Class; Foreign : T_Userids'Class) return SQL_Criteria;
   function FK (Self : T_Learntdata'Class; Foreign : T_Languages'Class) return SQL_Criteria;
   function FK (Self : T_Queries'Class; Foreign : T_Reports'Class) return SQL_Criteria;
   function FK (Self : T_Recogniserstats'Class; Foreign : T_Userids'Class) return SQL_Criteria;
   function FK (Self : T_Userids'Class; Foreign : T_Languages'Class) return SQL_Criteria;
   function FK (Self : T_Wordfrequency'Class; Foreign : T_Languages'Class) return SQL_Criteria;
   function FK (Self : T_Words'Class; Foreign : T_Languages'Class) return SQL_Criteria;
   Combiningchrs : T_Combiningchrs (null);
   Configurations : T_Configurations (null);
   Keydefinitions : T_Keydefinitions (null);
   Languages : T_Languages (null);
   Learntdata : T_Learntdata (null);
   Macros : T_Macros (null);
   Queries : T_Queries (null);
   Recogniserstats : T_Recogniserstats (null);
   Reports : T_Reports (null);
   Trainingdata : T_Trainingdata (null);
   Trainingdatawords : T_Trainingdatawords (null);
   Userids : T_Userids (null);
   Wordfrequency : T_Wordfrequency (null);
   Words : T_Words (null);
end database;
