DROP VIEW TrainingDataWords;
DROP TABLE TrainingData;
CREATE TABLE TrainingData (
  User Integer NOT NULL,
  Language Integer NOT NULL,
  ID Integer NOT NULL,
  SampleNo Integer NOT NULL,
  Sample TEXT NOT NULL,
  TrgDate DATE,
  TrgTime TIME,
  PRIMARY KEY (User,Language,ID,SampleNo),
  FOREIGN KEY (User,Language,ID) REFERENCES LearntData (User,Language,ID));
PRAGMA foreign_keys = ON;
CREATE VIEW TrainingDataWords (ID, WordID, Word, SampleNo, Sample, TrgDate, TrgTime, User) AS
SELECT TrainingData.ID, (TrainingData.ID - Languages.EndChar) AS WordID, Words.word AS Word, TrainingData.SampleNo, TrainingData.Sample, TrainingData.TrgDate, TrainingData.TrgTime, UserIDs.Logon AS User
FROM TrainingData, Languages, UserIDs, Words
WHERE (TrainingData.User = UserIDs.UID)
  AND (Words.Language = TrainingData.Language)
  AND (Words.ID = (TrainingData.ID - Languages.EndChar))
  AND (TrainingData.Language = Languages.ID)
  AND (TrainingData.ID > Languages.EndChar)
ORDER BY User, TrainingData.ID, WordID, SampleNo;
INSERT INTO Languages VALUES ("Latin",1,32,126,"Basic Latin",1); --20h - 7Eh
INSERT INTO Languages VALUES ("Latin-1 Supplement",2,160,255,"Latin-1 Supplement",0);
INSERT INTO Languages VALUES ("Latin Extended-A",3,256,383,"Latin Extended-A",0);
INSERT INTO Languages VALUES ("Latin Extended-B",4,384,591,"Latin Extended-B",0);
INSERT INTO Languages VALUES ("IPA Extensions",5,592,687,"IPA Extensions",0);
INSERT INTO Languages VALUES ("Spacing Modifiers",6,688,767,"Spacing Modifier Letters",0);
INSERT INTO Languages VALUES ("Combining Diacritical",7,788,879,"Combining Diacritical Marks",0);
INSERT INTO Languages VALUES ("Greek",8,880,1023,"Greek and Coptic",0);
INSERT INTO Languages VALUES ("Cyrillic",9,1024,1279,"Cyrillic",0);
INSERT INTO Languages VALUES ("Cyrillic Supplement",10,1280,1327,"Cyrillic Supplement",0);
INSERT INTO Languages VALUES ("Armenian",11,1329,1423,"Armenian",0);
INSERT INTO Languages VALUES ("Hebrew",12,1425,1524,"Hebrew",0);
INSERT INTO Languages VALUES ("Arabic",13,1548,1790,"Arabic",0); -- 060C - 06FE
INSERT INTO Languages VALUES ("Syriac",14,1792,1866,"Syriac",0); -- 0700 - 074A
INSERT INTO Languages VALUES ("Thaana",15,1920,1968,"Thaana",0); -- 0780 - 07B0
INSERT INTO Languages VALUES ("Nko",16,1984,2047,"Nko",0);
INSERT INTO Languages VALUES ("Samaritan",17,2048,2111,"Samaritan",0);
INSERT INTO Languages VALUES ("Mandaic",18,2112,2143,"Mandaic",0);
INSERT INTO Languages VALUES ("Syriac Supplement",19,2144,2159,"Syriac Supplement",0);
INSERT INTO Languages VALUES ("Arabic Extended-A",20,2208,2303,"Arabic Extended-A",0);
INSERT INTO Languages VALUES ("Devanagan",21,2304,2431,"Devanagan",0);
INSERT INTO Languages VALUES ("Bengali",22,2432,2559,"Bengali",0);
INSERT INTO Languages VALUES ("Gurmukhi",23,2560,2687,"Gurmukhi",0);
INSERT INTO Languages VALUES ("Gujarati",24,2688,2815,"Gujarati",0);
INSERT INTO Languages VALUES ("Oriya",25,2816,2943,"Oriya",0);
INSERT INTO Languages VALUES ("Tamil",26,2944,3071,"Tamil",0);
INSERT INTO Languages VALUES ("Telugu",27,3072,3199,"Telugu",0);
INSERT INTO Languages VALUES ("Kannada",28,3200,3327,"Kannada",0);
INSERT INTO Languages VALUES ("Malayalam",29,3328,3455,"Malayalam",0);
INSERT INTO Languages VALUES ("Sinhala",30,3456,3583,"Sinhala",0);
INSERT INTO Languages VALUES ("Thai",31,3584,3711,"Thai",0);
INSERT INTO Languages VALUES ("Lao",32,3712,3839,"Lao",0);
INSERT INTO Languages VALUES ("Tibetan",33,3840,4095,"Tibetan",0);
INSERT INTO Languages VALUES ("Myanmar",34,4096,4255,"Myanmar",0);
INSERT INTO Languages VALUES ("Georgian",35,4256,4351,"Georgian",0);
INSERT INTO Languages VALUES ("Hangul Jamo, Coseong",36,4352,4447,"Hangul Jamo, Coseong",0);
INSERT INTO Languages VALUES ("Hangul Jamo, Jungseong",37,4448,4519,"Hangul Jamo, Jungseong",0);
INSERT INTO Languages VALUES ("Hangul Jamo, Jongseong",38,4520,4607,"Hangul Jamo, Jongseong",0);
INSERT INTO Languages VALUES ("Ethiopic",39,4608,4991,"Ethiopic",0);
INSERT INTO Languages VALUES ("Ethiopic Supplement",40,4992,5023,"Ethiopic Supplement",0);
INSERT INTO Languages VALUES ("Cherokee",41,5024,5119,"Cherokee",0);
INSERT INTO Languages VALUES ("Unified Canadian Aboriginal Syllabics",42,5120,5759,"Unified Canadian Aboriginal Syllabics",0);
INSERT INTO Languages VALUES ("Ogham",43,5760,5791,"Ogham",0);
INSERT INTO Languages VALUES ("Runic",44,5792,5887,"Runic",0);
INSERT INTO Languages VALUES ("Tagalog",45,5888,5919,"Tagalog",0);
INSERT INTO Languages VALUES ("Hanunoo",46,5920,5951,"Hanunoo",0);
INSERT INTO Languages VALUES ("Buhid",47,5952,5983,"Buhid",0);
INSERT INTO Languages VALUES ("Tagbanwa",48,5984,6015,"Tagbanwa",0);
INSERT INTO Languages VALUES ("Khmer",49,6016,6143,"Khmer",0);
INSERT INTO Languages VALUES ("Mongolian",50,6144,6319,"Mongolian",0);
INSERT INTO Languages VALUES ("Unified Canadian Aboriginal Syllabics Extended",51,6272,6399,"Unified Canadian Aboriginal Syllabics Extended",0);
INSERT INTO Languages VALUES ("Limbu",52,6400,6479,"Limbu",0);
INSERT INTO Languages VALUES ("Tai Le",53,6480,6527,"Tai Le",0);
INSERT INTO Languages VALUES ("New Tai Lue",54,6528,6623,"New Tai Lue",0);
INSERT INTO Languages VALUES ("Khmer Symbols",55,6624,6655,"Khmer Symbols",0);
INSERT INTO Languages VALUES ("Buginese",56,6656,6687,"Buginese",0);
INSERT INTO Languages VALUES ("Tiai Tham",57,6688,6831,"Tiai Tham",0);
INSERT INTO Languages VALUES ("Combining Diacritical Marks Extended",58,6832,6911,"Combining Diacritical Marks Extended",0);
INSERT INTO Languages VALUES ("Balinese",59,6912,7103,"Balinese",0);
INSERT INTO Languages VALUES ("Sudanese",60,6272,7103,"Sudanese",0);
INSERT INTO Languages VALUES ("Batak",61,7104,7167,"Batak",0);
INSERT INTO Languages VALUES ("Lebcha",62,7168,7247,"Lebcha",0);
INSERT INTO Languages VALUES ("Ol Chiki",63,7248,7295,"Ol Chiki",0);
INSERT INTO Languages VALUES ("Cyrillic Extended-C",64,7296,7311,"Cyrillic Extended-C",0);
INSERT INTO Languages VALUES ("Georgian Extended",65,7312,7359,"Georgian Extended",0);
INSERT INTO Languages VALUES ("Sudanese Supplement",66,7360,7375,"Sudanese Supplement",0);
INSERT INTO Languages VALUES ("Vedic Extensions",67,7376,7423,"Vedic Extensions",0);
INSERT INTO Languages VALUES ("Phonetic Extensions",68,7424,7551,"Phonetic Extensions",0);
INSERT INTO Languages VALUES ("Phonetic Extensions Supplement",69,7552,7615,"Phonetic Extensions Supplement",0);
INSERT INTO Languages VALUES ("Combining Diacritical Marks Supplement",70,7616,7679,"Combining Diacritical Marks Supplement",0);
INSERT INTO Languages VALUES ("Latin Extended Additional",71,7680,7935,"Latin Extended Additional",0);
INSERT INTO Languages VALUES ("Greek Extended",72,7936,8191,"Greek Extended",0);
INSERT INTO Languages VALUES ("General Punctuation",73,8192,8303,"General Punctuation",0);
INSERT INTO Languages VALUES ("Superscripts and Subscripts",74,8304,8351,"Superscripts and Subscripts",0);
INSERT INTO Languages VALUES ("Currency Symbols",75,8352,8399,"Currency Symbols",0);
INSERT INTO Languages VALUES ("Combining Diacritical Marks for Symbols",76,8400,8447,"Combining Diacritical Marks for Symbols",0);
INSERT INTO Languages VALUES ("Letterlike Symbols",77,8448,8527,"Letterlike Symbols",0);
INSERT INTO Languages VALUES ("Number Forms",78,8528,8591,"Number Forms",0);
INSERT INTO Languages VALUES ("Arrows",79,8592,8703,"Arrows",0);
INSERT INTO Languages VALUES ("Mathematical Operators",80,8704,8959,"Mathematical Operators",0);
INSERT INTO Languages VALUES ("Miscellaneous Technical",81,8960,9215,"Miscellaneous Technical",0);
INSERT INTO Languages VALUES ("Control Pictures",82,9216,9279,"Control Pictures",0);
INSERT INTO Languages VALUES ("Optical Character Recognition",83,9280,9311,"Optical Character Recognition",0);
INSERT INTO Languages VALUES ("Enclosed Alphanumerics",84,9312,9471,"Enclosed Alphanumerics",0);
INSERT INTO Languages VALUES ("Box Drawing",85,9472,9599,"Box Drawing",0);
INSERT INTO Languages VALUES ("Block Elements",86,9600,9631,"Block Elements",0);
INSERT INTO Languages VALUES ("Geometric Shapes",87,9632,9727,"Geometric Shapes",0);
INSERT INTO Languages VALUES ("Miscellaneous Symbols",88,9728,9983,"Miscellaneous Symbols",0);
INSERT INTO Languages VALUES ("Dingbats",89,9984,10175,"Dingbats",0);
INSERT INTO Languages VALUES ("Miscellaneous Mathematical Symbols-A",90,10176,10223,"Miscellaneous Mathematical Symbols-A",0);
INSERT INTO Languages VALUES ("Supplemental Arrows-A",91,10224,10239,"Supplemental Arrows-A",0);
INSERT INTO Languages VALUES ("Braille Patterns",92,10240,10495,"Braille Patterns",0);
INSERT INTO Languages VALUES ("Supplemental Arrows-B",93,10496,10623,"Supplemental Arrows-B",0);
INSERT INTO Languages VALUES ("Miscellaneous Mathematical Symbols-B",94,10624,10751,"Miscellaneous Mathematical Symbols-B",0);
INSERT INTO Languages VALUES ("Supplemental Mathematical Operators",95,10752,11007,"Supplemental Mathematical Operators",0);
INSERT INTO Languages VALUES ("Miscellaneous Symbols and Arrows",96,11008,11263,"Miscellaneous Symbols and Arrows",0);
INSERT INTO Languages VALUES ("Glagolitic",97,11264,11359,"Glagolitic",0);
INSERT INTO Languages VALUES ("Latin Extended-C",98,11360,11391,"Latin Extended-C",0);
INSERT INTO Languages VALUES ("Coptic",99,11392,11519,"Coptic",0);
INSERT INTO Languages VALUES ("Georgian Supplement",100,11520,11567,"Georgian Supplement",0);
INSERT INTO Languages VALUES ("Tifinagh",101,11568,11647,"Tifinagh",0);
INSERT INTO Languages VALUES ("Ethiopic Extended",102,11648,11743,"Ethiopic Extended",0);
INSERT INTO Languages VALUES ("Cyrillic Extended-A",103,11744,11775,"Cyrillic Extended-A",0);
INSERT INTO Languages VALUES ("Supplemental Punctuation",104,11776,11903,"Supplemental Punctuation",0);
INSERT INTO Languages VALUES ("CJK Radicals Supplement",105,11904,12031,"CJK Radicals Supplement",0);
INSERT INTO Languages VALUES ("Kangxi Radicals",106,12032,12255,"Kangxi Radicals",0);
INSERT INTO Languages VALUES ("Ideographic Description Characters",107,12272,12287,"Ideographic Description Characters",0);
INSERT INTO Languages VALUES ("CJK Phonetics and Symbols",108,12288,13311,"CJK Phonetics and Symbols",0);
INSERT INTO Languages VALUES ("CJK Unified Ideographs Extension A",109,13312,19903,"CJK Unified Ideographs Extension A",0);
INSERT INTO Languages VALUES ("Yijing Hexagram",110,19904,19967,"Yijing Hexagram",0);
INSERT INTO Languages VALUES ("CJK Unified Ideographs",111,19968,40956,"CJK Unified Ideographs",0);
INSERT INTO Languages VALUES ("Yi Syllables",112,40960,42127,"Yi Syllables",0);
INSERT INTO Languages VALUES ("Yi Radicals",113,42128,42191,"Yi Radicals",0);
INSERT INTO Languages VALUES ("Lisu",114,42192,42239,"Lisu",0);
INSERT INTO Languages VALUES ("Vai",115,42240,42559,"Vai",0);
INSERT INTO Languages VALUES ("Cyrillic Extended-B",116,42560,42751,"Cyrillic Extended-B",0);
INSERT INTO Languages VALUES ("Bamum",117,42656,42751,"Bamum",0);
INSERT INTO Languages VALUES ("Modifier Tone Letters",118,42752,42783,"Modifier Tone Letters",0);
INSERT INTO Languages VALUES ("Latin Extended-D",119,42784,43007,"Latin Extended-D",0);
INSERT INTO Languages VALUES ("Syloti Nagri",120,43008,43135,"Syloti Nagri",0);
INSERT INTO Languages VALUES ("Common Indic Number Forms",121,43056,43071,"Common Indic Number Forms",0);
INSERT INTO Languages VALUES ("Phags-pa",122,43072,43135,"Phags-pa",0);
INSERT INTO Languages VALUES ("Saurashtra",123,43136,43231,"Saurashtra",0);
INSERT INTO Languages VALUES ("Devanagari Extended",124,43232,43263,"Devanagari Extended",0);
INSERT INTO Languages VALUES ("Kayah Li",125,43264,43311,"Kayah Li",0);
INSERT INTO Languages VALUES ("Rejang",126,43312,43359,"Rejang",0);
INSERT INTO Languages VALUES ("Hangul Jamo Extended-A",127,43360,43391,"Hangul Jamo Extended-A",0);
INSERT INTO Languages VALUES ("Javanese",128,43392,43487,"Javanese",0);
INSERT INTO Languages VALUES ("Myanmar Extended-B",129,43488,43519,"Myanmar Extended-B",0);
INSERT INTO Languages VALUES ("Tai Viet",130,43648,43743,"Tai Viet",0);
INSERT INTO Languages VALUES ("Meetei Mayek Extensions",131,43744,43775,"Meetei Mayek Extensions",0);
INSERT INTO Languages VALUES ("Ethiopic Extended-A",132,43776,43823,"Ethiopic Extended-A",0);
INSERT INTO Languages VALUES ("Latin Extended-E",133,43824,43887,"Latin Extended-E",0);
INSERT INTO Languages VALUES ("Cherokee Supplement",134,43888,43967,"Cherokee Supplement",0);
INSERT INTO Languages VALUES ("Meetei Mayek",135,43968,44031,"Meetei Mayek",0);
INSERT INTO Languages VALUES ("Hangul Syllables",136,44032,55203,"Hangul Syllables",0);
INSERT INTO Languages VALUES ("Hangul Jamo Extended-B",137,55216,55295,"Hangul Jamo Extended-B",0);
INSERT INTO Languages VALUES ("High Surrogates",138,55296,56191,"High Surrogates",0);
INSERT INTO Languages VALUES ("High Private Use Surrogates",139,56192,56319,"High Private Use Surrogates",0);
INSERT INTO Languages VALUES ("Low Surrogates",140,56320,57343,"Low Surrogates",0);
INSERT INTO Languages VALUES ("Private Use A",141,57344,57599,"Private Use A",0);
INSERT INTO Languages VALUES ("Blissymbolics",142,57600,57740,"Blissymbolics",1);
INSERT INTO Languages VALUES ("Private Use B",143,57741,63743,"Private Use B",0);
INSERT INTO Languages VALUES ("CJK Compatibility Ideographs",144,63744,64255,"CJK Compatibility Ideographs",0);
INSERT INTO Languages VALUES ("Alphabetic Presentation Forms",145,64256,64335,"Alphabetic Presentation Forms",0);
INSERT INTO Languages VALUES ("Latin Ligatures",146,64256,64262,"Latin Ligatures",0);
INSERT INTO Languages VALUES ("Armenian Ligatures",147,64275,64279,"Armenian Ligatures",0);
INSERT INTO Languages VALUES ("Hebrew Ligatures/Pointed Letters",148,64285,64335,"Hebrew Ligatures/Pointed Letters",0);
INSERT INTO Languages VALUES ("Arabic Presentation Forms-A",149,64336,65023,"Arabic Presentation Forms-A",0);

INSERT INTO Macros VALUES (0," ");  -- does nothing
INSERT INTO Macros VALUES (1,"x");
INSERT INTO Macros VALUES (2,"x");
UPDATE Macros SET Macro=readfile('../src/macro_0.txt') WHERE ID=0;
UPDATE Macros SET Macro=readfile('../src/macro_1.txt') WHERE ID=1;
UPDATE Macros SET Macro=readfile('../src/macro_2.txt') WHERE ID=2;

INSERT INTO CombiningChrs VALUES (1,0," ","No-break Space","' '", 0);
INSERT INTO CombiningChrs VALUES (1,1,"̀","Grave"," ̀", 1);
INSERT INTO CombiningChrs VALUES (1,2,"́","Acute"," ́", 1);
INSERT INTO CombiningChrs VALUES (1,3,"̂","Circumflex"," ̂", 1);
INSERT INTO CombiningChrs VALUES (1,4,"̃","Tilde"," ̃", 1);
INSERT INTO CombiningChrs VALUES (1,5,"̄","Macron"," ̄", 1);
INSERT INTO CombiningChrs VALUES (1,6,"̆","Breve"," ̆", 1);
INSERT INTO CombiningChrs VALUES (1,7,"̇","Dot"," ̇", 1);
INSERT INTO CombiningChrs VALUES (1,8,"̈","Diaeresis"," ̈", 1);
INSERT INTO CombiningChrs VALUES (1,9,"̉","Hook"," ̉", 1);
INSERT INTO CombiningChrs VALUES (1,10,"̌","Caron"," ̌", 1);
INSERT INTO CombiningChrs VALUES (142,0,"","Quarter Space","|¼|", 0);
INSERT INTO CombiningChrs VALUES (142,1,"","Bliss Thing","", 2);
INSERT INTO CombiningChrs VALUES (142,2,"","Bliss Action","", 2);
INSERT INTO CombiningChrs VALUES (142,3,"","Bliss Evaluation","", 2);
INSERT INTO CombiningChrs VALUES (142,4,"","Bliss Location","", 2);
INSERT INTO CombiningChrs VALUES (142,5,"","Bliss Passive","", 2);
INSERT INTO CombiningChrs VALUES (142,6,"","Bliss Active","", 2);
INSERT INTO CombiningChrs VALUES (142,7,"","Bliss Past Tense","", 2);
INSERT INTO CombiningChrs VALUES (142,8,"","Bliss Future Tense","", 2);
INSERT INTO CombiningChrs VALUES (142,9,"","Bliss Multiple","", 2);
INSERT INTO CombiningChrs VALUES (142,10,"","Bliss Unknown","", 2);

INSERT INTO KeyDefinitions VALUES (1, 04, "a", "A", " "," "," "," "," ","a"," "," "," "," "," "," "," "," "," "," ","A"," "," "," "," "," ");
INSERT INTO KeyDefinitions VALUES (1, 05, "b", "B", " "," "," "," "," ","b"," "," "," "," "," "," "," "," "," "," ","B"," "," "," "," "," ");
INSERT INTO KeyDefinitions VALUES (1, 06, "c", "C", " "," "," "," "," ","c"," "," "," "," "," "," "," "," "," "," ","C"," "," "," "," "," ");
INSERT INTO KeyDefinitions VALUES (1, 07, "d", "D", " "," "," "," "," ","d"," "," "," "," "," "," "," "," "," "," ","D"," "," "," "," "," ");
INSERT INTO KeyDefinitions VALUES (1, 08, "e", "E", " "," "," "," "," ","e"," "," "," "," "," "," "," "," "," "," ","E"," "," "," "," "," ");
INSERT INTO KeyDefinitions VALUES (1, 09, "f", "F", " "," "," "," "," ","f"," "," "," "," "," "," "," "," "," "," ","F"," "," "," "," "," ");
INSERT INTO KeyDefinitions VALUES (1, 10, "g", "G", " "," "," "," "," ","g"," "," "," "," "," "," "," "," "," "," ","G"," "," "," "," "," ");
INSERT INTO KeyDefinitions VALUES (1, 11, "h", "H", " "," "," "," "," ","h"," "," "," "," "," "," "," "," "," "," ","H"," "," "," "," "," ");
INSERT INTO KeyDefinitions VALUES (1, 12, "i", "I", " "," "," "," "," ","i"," "," "," "," "," "," "," "," "," "," ","I"," "," "," "," "," ");
INSERT INTO KeyDefinitions VALUES (1, 13, "j", "J", " "," "," "," "," ","j"," "," "," "," "," "," "," "," "," "," ","J"," "," "," "," "," ");
INSERT INTO KeyDefinitions VALUES (1, 14, "k", "K", " "," "," "," "," ","k"," "," "," "," "," "," "," "," "," "," ","K"," "," "," "," "," ");
INSERT INTO KeyDefinitions VALUES (1, 15, "l", "L", " "," "," "," "," ","l"," "," "," "," "," "," "," "," "," "," ","L"," "," "," "," "," ");
INSERT INTO KeyDefinitions VALUES (1, 16, "m", "M", " "," "," "," "," ","m"," "," "," "," "," "," "," "," "," "," ","M"," "," "," "," "," ");
INSERT INTO KeyDefinitions VALUES (1, 17, "n", "N", " "," "," "," "," ","n"," "," "," "," "," "," "," "," "," "," ","N"," "," "," "," "," ");
INSERT INTO KeyDefinitions VALUES (1, 18, "o", "O", " "," "," "," "," ","o"," "," "," "," "," "," "," "," "," "," ","O"," "," "," "," "," ");
INSERT INTO KeyDefinitions VALUES (1, 19, "p", "P", " "," "," "," "," ","p"," "," "," "," "," "," "," "," "," "," ","P"," "," "," "," "," ");
INSERT INTO KeyDefinitions VALUES (1, 20, "q", "Q", " "," "," "," "," ","q"," "," "," "," "," "," "," "," "," "," ","Q"," "," "," "," "," ");
INSERT INTO KeyDefinitions VALUES (1, 21, "r", "R", " "," "," "," "," ","r"," "," "," "," "," "," "," "," "," "," ","R"," "," "," "," "," ");
INSERT INTO KeyDefinitions VALUES (1, 22, "s", "S", " "," "," "," "," ","s"," "," "," "," "," "," "," "," "," "," ","S"," "," "," "," "," ");
INSERT INTO KeyDefinitions VALUES (1, 23, "t", "T", " "," "," "," "," ","t"," "," "," "," "," "," "," "," "," "," ","T"," "," "," "," "," ");
INSERT INTO KeyDefinitions VALUES (1, 24, "u", "U", " "," "," "," "," ","u"," "," "," "," "," "," "," "," "," "," ","U"," "," "," "," "," ");
INSERT INTO KeyDefinitions VALUES (1, 25, "v", "V", " "," "," "," "," ","v"," "," "," "," "," "," "," "," "," "," ","V"," "," "," "," "," ");
INSERT INTO KeyDefinitions VALUES (1, 26, "w", "W", " "," "," "," "," ","w"," "," "," "," "," "," "," "," "," "," ","W"," "," "," "," "," ");
INSERT INTO KeyDefinitions VALUES (1, 27, "x", "X", " "," "," "," "," ","x"," "," "," "," "," "," "," "," "," "," ","X"," "," "," "," "," ");
INSERT INTO KeyDefinitions VALUES (1, 28, "y", "Y", " "," "," "," "," ","y"," "," "," "," "," "," "," "," "," "," ","Y"," "," "," "," "," ");
INSERT INTO KeyDefinitions VALUES (1, 29, "z", "Z", " "," "," "," "," ","z"," "," "," "," "," "," "," "," "," "," ","Z"," "," "," "," "," ");
INSERT INTO KeyDefinitions VALUES (1, 47, "[", "{", " "," "," "," "," ","["," "," "," "," "," "," "," "," "," "," ","{"," "," "," "," "," ");
INSERT INTO KeyDefinitions VALUES (1, 48, "]", "}", " "," "," "," "," ","]"," "," "," "," "," "," "," "," "," "," ","}"," "," "," "," "," ");
INSERT INTO KeyDefinitions VALUES (1, 49, "\", "|", " "," "," "," "," ","\"," "," "," "," "," "," "," "," "," "," ","|"," "," "," "," "," ");
INSERT INTO KeyDefinitions VALUES (1, 51, ";", ":", " "," "," "," "," ",";"," "," "," "," "," "," "," "," "," "," ",":"," "," "," "," "," ");
INSERT INTO KeyDefinitions VALUES (1, 52, "'", '"', " "," "," "," "," ","'"," "," "," "," "," "," "," "," "," "," ",'"'," "," "," "," "," ");
INSERT INTO KeyDefinitions VALUES (1, 54, ",", "<", " "," "," "," "," ",","," "," "," "," "," "," "," "," "," "," ","<"," "," "," "," "," ");
INSERT INTO KeyDefinitions VALUES (1, 55, ".", ">", " "," "," "," "," ","."," "," "," "," "," "," "," "," "," "," ",">"," "," "," "," "," ");
INSERT INTO KeyDefinitions VALUES (1, 56, "/", "?", " "," "," "," "," ","/"," "," "," "," "," "," "," "," "," "," ","?"," "," "," "," "," ");
INSERT INTO KeyDefinitions VALUES (1, 53, "`", "~", " "," "," "," "," ","`"," "," "," "," "," "," "," "," "," "," ","~"," "," "," "," "," ");
INSERT INTO KeyDefinitions VALUES (1, 30, "1", "!", " "," "," "," "," ","1"," "," "," "," "," "," "," "," "," "," ","!"," "," "," "," "," ");
INSERT INTO KeyDefinitions VALUES (1, 31, "2", "@", " "," "," "," "," ","2"," "," "," "," "," "," "," "," "," "," ","@"," "," "," "," "," ");
INSERT INTO KeyDefinitions VALUES (1, 32, "3", "#", " "," "," "," "," ","3"," "," "," "," "," "," "," "," "," "," ","#"," "," "," "," "," ");
INSERT INTO KeyDefinitions VALUES (1, 33, "4", "$", " "," "," "," "," ","4"," "," "," "," "," "," "," "," "," "," ","$"," "," "," "," "," ");
INSERT INTO KeyDefinitions VALUES (1, 34, "5", "%", " "," "," "," "," ","5"," "," "," "," "," "," "," "," "," "," ","%"," "," "," "," "," ");
INSERT INTO KeyDefinitions VALUES (1, 35, "6", "^", " "," "," "," "," ","6"," "," "," "," "," "," "," "," "," "," ","^"," "," "," "," "," ");
INSERT INTO KeyDefinitions VALUES (1, 36, "7", "&", " "," "," "," "," ","7"," "," "," "," "," "," "," "," "," "," ","&"," "," "," "," "," ");
INSERT INTO KeyDefinitions VALUES (1, 37, "8", "*", " "," "," "," "," ","8"," "," "," "," "," "," "," "," "," "," ","*"," "," "," "," "," ");
INSERT INTO KeyDefinitions VALUES (1, 38, "9", "(", " "," "," "," "," ","9"," "," "," "," "," "," "," "," "," "," ","("," "," "," "," "," ");
INSERT INTO KeyDefinitions VALUES (1, 39, "0", ")", " "," "," "," "," ","0"," "," "," "," "," "," "," "," "," "," ",")"," "," "," "," "," ");
INSERT INTO KeyDefinitions VALUES (1, 45, "-", "_", " "," "," "," "," ","-"," "," "," "," "," "," "," "," "," "," ","_"," "," "," "," "," ");
INSERT INTO KeyDefinitions VALUES (1, 46, "=", "+", " "," "," "," "," ","="," "," "," "," "," "," "," "," "," "," ","+"," "," "," "," "," ");
-- INSERT INTO KeyDefinitions VALUES (1, 41, "Esc", "Esc", " "," "," "," "," ",char(27)," "," "," "," "," "," "," "," "," "," ",char(27)," "," "," "," "," ");
-- INSERT INTO KeyDefinitions VALUES (1, 40, "Enter", "Enter", " "," "," "," "," ",char(13)," "," "," "," "," "," "," "," "," "," ",char(13)," "," "," "," "," ");
-- INSERT INTO KeyDefinitions VALUES (1, 42, "BkSp", "BkSp", " "," "," "," "," ",char(8)," "," "," "," "," "," "," "," "," "," ",char(8)," "," "," "," "," ");
-- INSERT INTO KeyDefinitions VALUES (1, 43, "Tab", "Tab", " "," "," "," "," ",char(9)," "," "," "," "," "," "," "," "," "," ",char(9)," "," "," "," "," ");
-- INSERT INTO KeyDefinitions VALUES (1, 44, " ", " ", " "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," ");
-- INSERT INTO KeyDefinitions VALUES (1, 84, "/", "/", " "," "," "," "," ","/"," "," "," "," "," "," "," "," "," "," ","/"," "," "," "," "," ");
-- INSERT INTO KeyDefinitions VALUES (1, 85, "*", "*", " "," "," "," "," ","*"," "," "," "," "," "," "," "," "," "," ","*"," "," "," "," "," ");
-- INSERT INTO KeyDefinitions VALUES (1, 86, "-", "-", " "," "," "," "," ","-"," "," "," "," "," "," "," "," "," "," ","-"," "," "," "," "," ");
-- INSERT INTO KeyDefinitions VALUES (1, 95, "Hm", "7", " "," "," "," "," ",char(2)," "," "," "," "," "," "," "," "," "," ","7"," "," "," "," "," ");
-- INSERT INTO KeyDefinitions VALUES (1, 96, "↑", "8", " "," "," "," "," ",char(19)," "," "," "," "," "," "," "," "," "," ","8"," "," "," "," "," ");
-- INSERT INTO KeyDefinitions VALUES (1, 97, "PU", "9", " "," "," "," "," ",char(11)," "," "," "," "," "," "," "," "," "," ","9"," "," "," "," "," ");
-- INSERT INTO KeyDefinitions VALUES (1, 87, "+", "+", " "," "," "," "," ","+"," "," "," "," "," "," "," "," "," "," ","+"," "," "," "," "," ");
-- INSERT INTO KeyDefinitions VALUES (1, 92, "←", "4", " "," "," "," "," ",char(17)," "," "," "," "," "," "," "," "," "," ","4"," "," "," "," "," ");
-- INSERT INTO KeyDefinitions VALUES (1, 93, "5", "5", " "," "," "," "," ","5"," "," "," "," "," "," "," "," "," "," ","5"," "," "," "," "," ");
-- INSERT INTO KeyDefinitions VALUES (1, 94, "→", "6", " "," "," "," "," ",char(18)," "," "," "," "," "," "," "," "," "," ","6"," "," "," "," "," ");
-- INSERT INTO KeyDefinitions VALUES (1, 187, "<-", "⇐", " "," "," "," "," ",char(08)," "," "," "," "," "," "," "," "," "," ",char(08)," "," "," "," "," ");
-- INSERT INTO KeyDefinitions VALUES (1, 89, "End", "1", " "," "," "," "," ",char(3)," "," "," "," "," "," "," "," "," "," ","1"," "," "," "," "," ");
-- INSERT INTO KeyDefinitions VALUES (1, 90, "↓", "2", " "," "," "," "," ",char(20)," "," "," "," "," "," "," "," "," "," ","2"," "," "," "," "," ");
-- INSERT INTO KeyDefinitions VALUES (1, 91, "PD", "3", " "," "," "," "," ",char(12)," "," "," "," "," "," "," "," "," "," ","3"," "," "," "," "," ");
-- INSERT INTO KeyDefinitions VALUES (1, 103, "=", "=", " "," "," "," "," ","="," "," "," "," "," "," "," "," "," "," ","="," "," "," "," "," ");
-- INSERT INTO KeyDefinitions VALUES (1, 98, "Ins", "0", " "," "," "," "," ",char(15)," "," "," "," "," "," "," "," "," "," ","0"," "," "," "," "," ");
-- INSERT INTO KeyDefinitions VALUES (1, 177, "000", "000", " "," "," "," "," ",char(14)," "," "," "," "," "," "," "," "," "," ",char(14)," "," "," "," "," ");
-- INSERT INTO KeyDefinitions VALUES (1, 99, "Del", ".", " "," "," "," "," ",char(127)," "," "," "," "," "," "," "," "," "," ","."," "," "," "," "," ");
-- INSERT INTO KeyDefinitions VALUES (1, 88, "Ent", "↲", " "," "," "," "," ",char(13)," "," "," "," "," "," "," "," "," "," ",char(13)," "," "," "," "," ");
-- We treat Home = 16#02#, End = 16#03#, Page Up = 16#0B#, Page Down = 16#0C#, Ins = 16#0F#, Del = 16#7F#, 000=16#0E#
--       Arrow Left = 16#11#, Arrow Right = 16#12#, Arrow Up = 16#13#, Arrow Down = 16#14#.
-- These then get converted on the way out to the correct scan codes.

-- The first 4 are small semi-circles, then vertical/horzontal lines, then last 4 larger semi-circles
-- Lingo, ID, Unshift Disp, Caps Disp, Space, ASky,Sky,BSky,Upper,Middle,Lower,Ground,JstBelowGnd,BelowGnd,Core,
INSERT INTO KeyDefinitions VALUES (142, 013, "", "", "","","","","","","","","","","", "","","","","","","","","","","");
INSERT INTO KeyDefinitions VALUES (142, 014, "", "", "","","","","","","","","","","", "","","","","","","","","","","");
INSERT INTO KeyDefinitions VALUES (142, 015, "", "", "","","","","","","","","","","", "","","","","","","","","","","");
INSERT INTO KeyDefinitions VALUES (142, 051, "", "", "","","","","","","","","","","", "","","","","","","","","","","");
INSERT INTO KeyDefinitions VALUES (142, 010, "", "", "","","","","","","","","","","", "","","","","","","","","","","");
INSERT INTO KeyDefinitions VALUES (142, 011, "", "", "","","","","","","","","","","", "","","","","","","","","","","");
INSERT INTO KeyDefinitions VALUES (142, 004, "", "", "","","","","","","","","","","", "","","","","","","","","","","");
INSERT INTO KeyDefinitions VALUES (142, 022, "", "", "","","","","","","","","","","", "","","","","","","","","","","");
INSERT INTO KeyDefinitions VALUES (142, 007, "", "", "","","","","","","","","","","", "","","","","","","","","","","");
INSERT INTO KeyDefinitions VALUES (142, 008, "e", "", "","","","","","","","","","","", "","","","","","","","","","","");
INSERT INTO KeyDefinitions VALUES (142, 009, "", "", "","","","","","","","","","","", "","","","","","","","","","","");
INSERT INTO KeyDefinitions VALUES (142, 012, "", "", "","","","","","","","","","","", "","","","","","","","","","","");
INSERT INTO KeyDefinitions VALUES (142, 018, "", "", "","","","","","","","","","","", "","","","","","","","","","","");
INSERT INTO KeyDefinitions VALUES (142, 019, "", "", "","","","","","","","","","","", "","","","","","","","","","","");
INSERT INTO KeyDefinitions VALUES (142, 024, "º", "", "","","","","","","","","","","", "","","","","","","","","","","");
INSERT INTO KeyDefinitions VALUES (142, 023, "", "", "","","","","","","","","","","", "","","","","","","","","","","");
INSERT INTO KeyDefinitions VALUES (142, 028, "", "", "","","","","","","","","","","", "","","","","","","","","","","");
INSERT INTO KeyDefinitions VALUES (142, 029, "a", "A", "","","","","","","","","","","", "","","","","","","","","","","");
INSERT INTO KeyDefinitions VALUES (142, 027, "", "", "","","","","","","","","","","", "","","","","","","","","","","");
INSERT INTO KeyDefinitions VALUES (142, 025, "f", "", "","","","","","","","","","","", "","","","","","","","","","","");
INSERT INTO KeyDefinitions VALUES (142, 054, "□", "<", "","","","","","","","","","","", "","","","","","","","","","","");
INSERT INTO KeyDefinitions VALUES (142, 055, ".", ">", "","","","","","","","","","","", "","","","","","","","","","","");
INSERT INTO KeyDefinitions VALUES (142, 030, "1", "!", "","","","","","","1","","","","", "","","","","","","!","","","","");
INSERT INTO KeyDefinitions VALUES (142, 031, "2", "□", "","","","","","","2","","","","", "","","","","","","","","","","");
INSERT INTO KeyDefinitions VALUES (142, 032, "3", "^", "","","","","","","3","","","","", "","","","","","","","","","","");
INSERT INTO KeyDefinitions VALUES (142, 033, "4", "꙾", "","","","","","","4","","","","", "","","","","","","","","","","");
INSERT INTO KeyDefinitions VALUES (142, 034, "5", "%", "","","","","","","5","","","","", "","","","","","","%","","","","");
INSERT INTO KeyDefinitions VALUES (142, 035, "6", "˙", "","","","","","","6","","","","", "","","","","","","","","","","");
INSERT INTO KeyDefinitions VALUES (142, 036, "7", "?", "","","","","","","7","","","","", "","","","","","","?","","","","");
INSERT INTO KeyDefinitions VALUES (142, 037, "8", "ⷯ", "","","","","","","8","","","","", "","","","","","","","","","","");
INSERT INTO KeyDefinitions VALUES (142, 038, "9", "(", "","","","","","","9","","","","", "","","","","","","","","","","");
INSERT INTO KeyDefinitions VALUES (142, 039, "0", ")", "","","","","","","0","","","","", "","","","","","","","","","","");
INSERT INTO KeyDefinitions VALUES (142, 240, "|  1  |", "|  1  |", "","","","","","","","","","","","","","","","","","","","","","");
INSERT INTO KeyDefinitions VALUES (142, 241, "| ½ |", "| ½ |", "","","","","","","","","","","","","","","","","","","","","","");
INSERT INTO KeyDefinitions VALUES (142, 242, "|¼|", "|¼|", "","","","","","","","","","","","","","","","","","","","","","");
INSERT INTO KeyDefinitions VALUES (142, 243, "|⅛|", "|⅛|", "","","","","","","","","","","","","","","","","","","","","","");
INSERT INTO KeyDefinitions VALUES (142, 244, "| |", "| |", "","","","","","","","","","","","","","","","","","","","","","");
INSERT INTO KeyDefinitions VALUES (142, 245, "||", "||", "","","","","","","","","","","","","","","","","","","","","","");

--INSERT INTO ColourChart VALUES (570,"Blonde");
--ALTER TABLE ColourChart ADD COLUMN Image blob;
-- If necessary, (re)compile fileio.so from the src/ directory viz:
-- gcc -fPIC -shared -I. fileio.c -o ../system/fileio.so
.load ./fileio
--UPDATE ColourChart SET Image=readfile('1.b64') WHERE Value=570;

INSERT INTO Configurations VALUES(1,"cell_writer.glade",'T',"");
INSERT INTO Configurations VALUES(2,"cell_writer.xpm",'B',"");
UPDATE Configurations SET Details=readfile('../src/cell_writer.glade') WHERE ID=1;
UPDATE Configurations SET Details=readfile('cell_writer.b64') WHERE ID=2;
INSERT INTO Configurations VALUES(3,"dimension_cells_horiz",'N',"45");
INSERT INTO Configurations VALUES(4,"dimension_cells_vert",'N',"70");
INSERT INTO Configurations VALUES(5,"dimension_grid_horiz",'N',"10");
INSERT INTO Configurations VALUES(6,"dimension_grid_vert",'N',"5");
INSERT INTO Configurations VALUES(7,"dimensions_keyboard",'N',"640");
INSERT INTO Configurations VALUES(8,"show_button_labels",'L',"0");
INSERT INTO Configurations VALUES(9,"show_onscreen_keyboard",'L',"0");
INSERT INTO Configurations VALUES(10,"enable_extended_input_events",'L',"0");
INSERT INTO Configurations VALUES(11,"menu_left_click",'L',"0");
INSERT INTO Configurations VALUES(12,"window_docking",'N',"1");
INSERT INTO Configurations VALUES(13,"language",'N',"1");
INSERT INTO Configurations VALUES(14,"train_on_input",'L',"0");
INSERT INTO Configurations VALUES(15,"samples_per_character",'N',"5");
INSERT INTO Configurations VALUES(16,"enable_word_context",'L',"0");
INSERT INTO Configurations VALUES(17,"ignore_stroke_direction",'L',"0");
INSERT INTO Configurations VALUES(18,"match_diff_stroke_nos",'L',"0");
INSERT INTO Configurations VALUES(30,"enable_word_frequency",'L',"1");
INSERT INTO Configurations VALUES(19,"used_cell_colour",'S',"rgb(255,255,255)");
INSERT INTO Configurations VALUES(20,"blank_cell_colour",'S',"rgb(153,193,241)");
INSERT INTO Configurations VALUES(21,"highlight_colour",'S',"rgb(205,0,0)");
INSERT INTO Configurations VALUES(22,"text_and_ink_colour",'S',"rgb(0,0,0)");
INSERT INTO Configurations VALUES(23,"key_face_colour",'S',"rgb(128,128,128)");
INSERT INTO Configurations VALUES(24,"key_text_colour",'S',"rgb(255,255,255)");
INSERT INTO Configurations VALUES(25,"font",'S',"Sans 12");
INSERT INTO Configurations VALUES(26,"font_start",'N',"40960");
INSERT INTO Configurations VALUES(27,"disable_basic_latin",'L',"0");
INSERT INTO Configurations VALUES(28,"enable_right_to_left",'L',"0");
INSERT INTO Configurations VALUES(29,"cell_writer.css",'T',"");
UPDATE Configurations SET Details=readfile('cell_writer.css') WHERE ID=29;
INSERT INTO Configurations VALUES(31,"engine_ranges",'S',"100 100 100 100");

INSERT INTO UserIDs VALUES (0, "", "", 1);
