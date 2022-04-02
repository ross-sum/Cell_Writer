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

   type T_Urinerecords
      (Table_Name : Cst_String_Access;
       Instance   : Cst_String_Access;
       Index      : Integer)
   is abstract new SQL_Table (Table_Name, Instance, Index) with
   record
      Patient : SQL_Field_Integer (Table_Name, Instance, N_Patient, Index);
      --  Patient's ID

      Udate : SQL_Field_tDate (Table_Name, Instance, N_Udate, Index);
      --  Urine voiding date

      Utime : SQL_Field_tTime (Table_Name, Instance, N_Utime, Index);
      --  Urine voiding time of day

      Volume : SQL_Field_Integer (Table_Name, Instance, N_Volume, Index);
      --  Volume (ml) voided

   end record;

   type T_Abstract_Catheterleakage
      (Instance : Cst_String_Access;
       Index    : Integer)
   is abstract new SQL_Table (Ta_Catheterleakage, Instance, Index) with
   record
      Leakage : SQL_Field_Text (Ta_Catheterleakage, Instance, N_Leakage, Index);
      --  Leakage Name for look-up

      Value : SQL_Field_Integer (Ta_Catheterleakage, Instance, N_Value, Index);
      --  Leakage unique identifier

      Description : SQL_Field_Text (Ta_Catheterleakage, Instance, N_Description, Index);
      --  Details about this amount

   end record;

   type T_Catheterleakage (Instance : Cst_String_Access)
      is new T_Abstract_Catheterleakage (Instance, -1) with null record;
   --  To use named aliases of the table in a query
   --  Use Instance=>null to use the default name.

   type T_Numbered_Catheterleakage (Index : Integer)
      is new T_Abstract_Catheterleakage (null, Index) with null record;
   --  To use aliases in the form name1, name2,...

   type T_Abstract_Catheterurinerecord
      (Instance : Cst_String_Access;
       Index    : Integer)
   is abstract new T_Urinerecords (Ta_Catheterurinerecord, Instance, Index) with
   record
      Colour : SQL_Field_Integer (Ta_Catheterurinerecord, Instance, N_Colour, Index);
      --  Urine colour (blood to clear)

      Floaties : SQL_Field_Integer (Ta_Catheterurinerecord, Instance, N_Floaties, Index);
      --  Any floaties observed in bag

      Leakage : SQL_Field_Integer (Ta_Catheterurinerecord, Instance, N_Leakage, Index);
      --  Leakage past catheter

   end record;

   type T_Catheterurinerecord (Instance : Cst_String_Access)
      is new T_Abstract_Catheterurinerecord (Instance, -1) with null record;
   --  To use named aliases of the table in a query
   --  Use Instance=>null to use the default name.

   type T_Numbered_Catheterurinerecord (Index : Integer)
      is new T_Abstract_Catheterurinerecord (null, Index) with null record;
   --  To use aliases in the form name1, name2,...

   type T_Abstract_Colourchart
      (Instance : Cst_String_Access;
       Index    : Integer)
   is abstract new SQL_Table (Ta_Colourchart, Instance, Index) with
   record
      Value : SQL_Field_Integer (Ta_Colourchart, Instance, N_Value, Index);
      --  Colour wavelength

      Colour : SQL_Field_Text (Ta_Colourchart, Instance, N_Colour, Index);
      --  Colour's common name
Image : SQL_Field_Blob (Ta_Colourchart, Instance, N_Image, Index);

   end record;

   type T_Colourchart (Instance : Cst_String_Access)
      is new T_Abstract_Colourchart (Instance, -1) with null record;
   --  To use named aliases of the table in a query
   --  Use Instance=>null to use the default name.

   type T_Numbered_Colourchart (Index : Integer)
      is new T_Abstract_Colourchart (null, Index) with null record;
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
      --  Detls fmt: T=Text,B=Base64

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

   type T_Abstract_Floaties
      (Instance : Cst_String_Access;
       Index    : Integer)
   is abstract new SQL_Table (Ta_Floaties, Instance, Index) with
   record
      Floatie : SQL_Field_Text (Ta_Floaties, Instance, N_Floatie, Index);
      --  Floatie Name for look-up

      Value : SQL_Field_Integer (Ta_Floaties, Instance, N_Value, Index);
      --  Floatie unique identifier

      Description : SQL_Field_Text (Ta_Floaties, Instance, N_Description, Index);
      --  Details about this floatie

   end record;

   type T_Floaties (Instance : Cst_String_Access)
      is new T_Abstract_Floaties (Instance, -1) with null record;
   --  To use named aliases of the table in a query
   --  Use Instance=>null to use the default name.

   type T_Numbered_Floaties (Index : Integer)
      is new T_Abstract_Floaties (null, Index) with null record;
   --  To use aliases in the form name1, name2,...

   type T_Abstract_Holdstates
      (Instance : Cst_String_Access;
       Index    : Integer)
   is abstract new SQL_Table (Ta_Holdstates, Instance, Index) with
   record
      Id : SQL_Field_Integer (Ta_Holdstates, Instance, N_Id, Index);
      --  hold state unique identifier

      Description : SQL_Field_Text (Ta_Holdstates, Instance, N_Description, Index);
      --  Details about this hold state

   end record;

   type T_Holdstates (Instance : Cst_String_Access)
      is new T_Abstract_Holdstates (Instance, -1) with null record;
   --  To use named aliases of the table in a query
   --  Use Instance=>null to use the default name.

   type T_Numbered_Holdstates (Index : Integer)
      is new T_Abstract_Holdstates (null, Index) with null record;
   --  To use aliases in the form name1, name2,...

   type T_Abstract_Keyevents
      (Instance : Cst_String_Access;
       Index    : Integer)
   is abstract new SQL_Table (Ta_Keyevents, Instance, Index) with
   record
      Patient : SQL_Field_Integer (Ta_Keyevents, Instance, N_Patient, Index);
      --  Patient's ID

      Eventdate : SQL_Field_tDate (Ta_Keyevents, Instance, N_Eventdate, Index);
      --  Date of the key event

      Event : SQL_Field_Text (Ta_Keyevents, Instance, N_Event, Index);
      --  Event title

      Details : SQL_Field_Text (Ta_Keyevents, Instance, N_Details, Index);
      --  Detailed description

   end record;

   type T_Keyevents (Instance : Cst_String_Access)
      is new T_Abstract_Keyevents (Instance, -1) with null record;
   --  To use named aliases of the table in a query
   --  Use Instance=>null to use the default name.

   type T_Numbered_Keyevents (Index : Integer)
      is new T_Abstract_Keyevents (null, Index) with null record;
   --  To use aliases in the form name1, name2,...

   type T_Abstract_Leakage
      (Instance : Cst_String_Access;
       Index    : Integer)
   is abstract new SQL_Table (Ta_Leakage, Instance, Index) with
   record
      Leakage : SQL_Field_Text (Ta_Leakage, Instance, N_Leakage, Index);
      --  Leakage Name for look-up

      Value : SQL_Field_Integer (Ta_Leakage, Instance, N_Value, Index);
      --  Leakage unique identifier

      Description : SQL_Field_Text (Ta_Leakage, Instance, N_Description, Index);
      --  Details about this amount

   end record;

   type T_Leakage (Instance : Cst_String_Access)
      is new T_Abstract_Leakage (Instance, -1) with null record;
   --  To use named aliases of the table in a query
   --  Use Instance=>null to use the default name.

   type T_Numbered_Leakage (Index : Integer)
      is new T_Abstract_Leakage (null, Index) with null record;
   --  To use aliases in the form name1, name2,...

   type T_Abstract_Padsizes
      (Instance : Cst_String_Access;
       Index    : Integer)
   is abstract new SQL_Table (Ta_Padsizes, Instance, Index) with
   record
      Id : SQL_Field_Integer (Ta_Padsizes, Instance, N_Id, Index);
      --  Pad size unique identifier

      Brand : SQL_Field_Text (Ta_Padsizes, Instance, N_Brand, Index);
      --  Pad's Brand name

      Size : SQL_Field_Integer (Ta_Padsizes, Instance, N_Size, Index);
      --  Pad weight in grams

      Description : SQL_Field_Text (Ta_Padsizes, Instance, N_Description, Index);
      --  Details about this pad

      Qtyperpack : SQL_Field_Integer (Ta_Padsizes, Instance, N_Qtyperpack, Index);
      --  Number of pads in a packet

      Priceperpack : SQL_Field_Money (Ta_Padsizes, Instance, N_Priceperpack, Index);
      --  Cost price of a packet

   end record;

   type T_Padsizes (Instance : Cst_String_Access)
      is new T_Abstract_Padsizes (Instance, -1) with null record;
   --  To use named aliases of the table in a query
   --  Use Instance=>null to use the default name.

   type T_Numbered_Padsizes (Index : Integer)
      is new T_Abstract_Padsizes (null, Index) with null record;
   --  To use aliases in the form name1, name2,...

   type T_Abstract_Patientdetails
      (Instance : Cst_String_Access;
       Index    : Integer)
   is abstract new SQL_Table (Ta_Patientdetails, Instance, Index) with
   record
      Identifier : SQL_Field_Integer (Ta_Patientdetails, Instance, N_Identifier, Index);
      --  patient's unique identifier

      Patient : SQL_Field_Text (Ta_Patientdetails, Instance, N_Patient, Index);
      --  Patient's name

      Addressline1 : SQL_Field_Text (Ta_Patientdetails, Instance, N_Addressline1, Index);
      --  Patient's street address pt 1

      Addressline2 : SQL_Field_Text (Ta_Patientdetails, Instance, N_Addressline2, Index);
      --  Patient's street address pt 2

      Town : SQL_Field_Text (Ta_Patientdetails, Instance, N_Town, Index);
      --  Patient's address town/city

      State : SQL_Field_Text (Ta_Patientdetails, Instance, N_State, Index);
      --  Address state/province

      Country : SQL_Field_Text (Ta_Patientdetails, Instance, N_Country, Index);
      --  Patient's address country

      Referraldate : SQL_Field_tDate (Ta_Patientdetails, Instance, N_Referraldate, Index);
      --  Date referred to specialist

   end record;

   type T_Patientdetails (Instance : Cst_String_Access)
      is new T_Abstract_Patientdetails (Instance, -1) with null record;
   --  To use named aliases of the table in a query
   --  Use Instance=>null to use the default name.

   type T_Numbered_Patientdetails (Index : Integer)
      is new T_Abstract_Patientdetails (null, Index) with null record;
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

   type T_Abstract_Spasms
      (Instance : Cst_String_Access;
       Index    : Integer)
   is abstract new SQL_Table (Ta_Spasms, Instance, Index) with
   record
      Spasm : SQL_Field_Integer (Ta_Spasms, Instance, N_Spasm, Index);
      --  spasm unique identifier

      Description : SQL_Field_Text (Ta_Spasms, Instance, N_Description, Index);
      --  Details about this intensity

   end record;

   type T_Spasms (Instance : Cst_String_Access)
      is new T_Abstract_Spasms (Instance, -1) with null record;
   --  To use named aliases of the table in a query
   --  Use Instance=>null to use the default name.

   type T_Numbered_Spasms (Index : Integer)
      is new T_Abstract_Spasms (null, Index) with null record;
   --  To use aliases in the form name1, name2,...

   type T_Abstract_Urinerecord
      (Instance : Cst_String_Access;
       Index    : Integer)
   is abstract new T_Urinerecords (Ta_Urinerecord, Instance, Index) with
   record
      Padvolume : SQL_Field_Integer (Ta_Urinerecord, Instance, N_Padvolume, Index);
      --  weight (g) of pad + its urine

      Hold : SQL_Field_Integer (Ta_Urinerecord, Instance, N_Hold, Index);
      --  hold ability mid-stream

      Leakage : SQL_Field_Integer (Ta_Urinerecord, Instance, N_Leakage, Index);
      --  none,some, pad change, etc.

      Padtype : SQL_Field_Integer (Ta_Urinerecord, Instance, N_Padtype, Index);
      --  Pad brand and clean weight

      No2 : SQL_Field_Boolean (Ta_Urinerecord, Instance, N_No2, Index);
      --  Passed stools at this time?

      Urges : SQL_Field_Integer (Ta_Urinerecord, Instance, N_Urges, Index);
      --  Number of urges experienced

      Spasm : SQL_Field_Integer (Ta_Urinerecord, Instance, N_Spasm, Index);
      --  Any spasm endured intensity

      Spasmcount : SQL_Field_Integer (Ta_Urinerecord, Instance, N_Spasmcount, Index);
      --  Number of spasms experienced

      Notes : SQL_Field_Text (Ta_Urinerecord, Instance, N_Notes, Index);
      --  Any points to note about it

   end record;

   type T_Urinerecord (Instance : Cst_String_Access)
      is new T_Abstract_Urinerecord (Instance, -1) with null record;
   --  To use named aliases of the table in a query
   --  Use Instance=>null to use the default name.

   type T_Numbered_Urinerecord (Index : Integer)
      is new T_Abstract_Urinerecord (null, Index) with null record;
   --  To use aliases in the form name1, name2,...

   function FK (Self : T_Catheterurinerecord'Class; Foreign : T_Colourchart'Class) return SQL_Criteria;
   function FK (Self : T_Catheterurinerecord'Class; Foreign : T_Floaties'Class) return SQL_Criteria;
   function FK (Self : T_Catheterurinerecord'Class; Foreign : T_Catheterleakage'Class) return SQL_Criteria;
   function FK (Self : T_Keyevents'Class; Foreign : T_Patientdetails'Class) return SQL_Criteria;
   function FK (Self : T_Queries'Class; Foreign : T_Reports'Class) return SQL_Criteria;
   function FK (Self : T_Urinerecord'Class; Foreign : T_Holdstates'Class) return SQL_Criteria;
   function FK (Self : T_Urinerecord'Class; Foreign : T_Leakage'Class) return SQL_Criteria;
   function FK (Self : T_Urinerecord'Class; Foreign : T_Padsizes'Class) return SQL_Criteria;
   function FK (Self : T_Urinerecord'Class; Foreign : T_Spasms'Class) return SQL_Criteria;
   function FK (Self : T_Urinerecords'Class; Foreign : T_Patientdetails'Class) return SQL_Criteria;
   Catheterleakage : T_Catheterleakage (null);
   Catheterurinerecord : T_Catheterurinerecord (null);
   Colourchart : T_Colourchart (null);
   Configurations : T_Configurations (null);
   Floaties : T_Floaties (null);
   Holdstates : T_Holdstates (null);
   Keyevents : T_Keyevents (null);
   Leakage : T_Leakage (null);
   Padsizes : T_Padsizes (null);
   Patientdetails : T_Patientdetails (null);
   Queries : T_Queries (null);
   Reports : T_Reports (null);
   Spasms : T_Spasms (null);
   Urinerecord : T_Urinerecord (null);
end database;
