INSERT INTO Reports VALUES (1, "Enrolled Words", "wordsstats", 0, "", "");
INSERT INTO Reports VALUES (2, "Usage Statistics", "usestats", 0, "", "");
INSERT INTO Reports VALUES (3, "Performance Statistics", "perfstats", 0 , "", "");
INSERT INTO Reports VALUES (4, "Top 20 Words", "usagegraph", 1, "", "");
INSERT INTO Queries VALUES (1, 1, "", "DROP TABLE Temp1;");
INSERT INTO Queries VALUES (1, 2, "", "CREATE TABLE Temp1 (User VARCHAR(100), Word VARCHAR(100), SampleCount INTEGER);");
INSERT INTO Queries VALUES (1, 3, "Temp1", "SELECT T.User, T.Word, COUNT(T.SampleNo) AS SampleCount FROM TrainingDataWords T GROUP BY T.User, T.ID, T.WordID;");
INSERT INTO Queries VALUES (2, 1, "", "DROP TABLE Temp1;");
INSERT INTO Queries VALUES (2, 2, "", "CREATE TABLE Temp1 (User INTEGER, Name VARCHAR(100), Logon VARCHAR(100), Language INTEGER, ID INTEGER, SampleNo INTEGER, TheChar VARCHAR(1), Word VARCHAR(100), Used INTEGER);");
INSERT INTO Queries VALUES (2, 3, "Temp1", "SELECT T.User, U.Name, U.Logon, T.Language, T.ID, T.SampleNo, IIF(T.ID<=L.EndChar,char(T.ID+L.Start),NULL) AS TheChar, W.word, T.Used FROM UserIDs U, Languages L, TrainingData T LEFT JOIN Words W ON (T.Language = W.Language AND W.ID = (T.ID - L.EndChar)) WHERE (T.Used > 0) AND (U.UID = T.User) AND (L.ID = T.Language) ORDER BY U.Logon ASC, T.Used DESC;");
INSERT INTO Queries VALUES (3, 1, "", "DROP TABLE Temp1;");
INSERT INTO Queries VALUES (3, 2, "", "CREATE TABLE Temp1 (CharWord VARCHAR(100), Avg_Durn NUMERIC, Avg_Disqual NUMERIC, Avg_Alts NUMERIC);");
INSERT INTO Queries VALUES (3, 3, "Temp1", "SELECT S.TopOne AS CharWord, avg(S.RecDuration) AS Avg_Durn, avg(S.Disqual * 100 / S.Examined) AS Avg_Disqual, avg(S.Alternatives) AS Avg_Alts FROM RecogniserStats S WHERE S.Strength > 0 GROUP BY S.TopOne ORDER BY CharWord;");
INSERT INTO Queries VALUES (4, 1, "", "DROP TABLE Temp1;");
INSERT INTO Queries VALUES (4, 2, "", "CREATE TABLE Temp1 (User INTEGER, Name VARCHAR(100), Logon VARCHAR(100), Language INTEGER, ID INTEGER, SampleNo INTEGER, TheChar VARCHAR(100), Used INTEGER);");
INSERT INTO Queries VALUES (4, 3, "Temp1", "SELECT T.User, U.Name, U.Logon, T.Language, T.ID, T.SampleNo, ifnull(iif(T.ID<=L.EndChar,char(T.ID+L.Start),NULL),W.Word) AS TheChar, T.Used FROM UserIDs U, Languages L, TrainingData T LEFT JOIN Words W ON (T.Language = W.Language AND W.ID = (T.ID - L.EndChar)) WHERE (T.Used > 0) AND (U.UID = T.User) AND (L.ID = T.Language) ORDER BY U.Logon ASC, T.Used DESC;");
INSERT INTO Queries VALUES (4, 4, "", "DROP TABLE Temp2;");
INSERT INTO Queries VALUES (4, 5, "", "CREATE TABLE Temp2 AS SELECT Logon, Language, TheChar, SampleNo, Used FROM Temp1 GROUP BY Logon, TheChar, SampleNo ORDER BY Used DESC LIMIT 20;");
INSERT INTO Queries VALUES (4, 6, "", "DROP TABLE Temp3;");
INSERT INTO Queries VALUES (4, 7, "", "CREATE TABLE Temp3 AS SELECT DISTINCT T1.Logon, (sum(T1.Used) - (SELECT sum(T2.Used) FROM Temp2 T2 WHERE T2.Logon = T1.Logon)) AS TotalUsed FROM Temp1 T1;");
INSERT INTO Queries VALUES (4, 8, "", "INSERT INTO Temp2 SELECT Logon, 0, NULL, 0, TotalUsed FROM Temp3;");
UPDATE Reports SET LaTex="%% LyX 2.3.6 created this file.  For more info, see http://www.lyx.org/.
%% Do not edit unless you really know what you are doing (i.e. you know LaTex).
\documentclass[32pt,a4paper,blissymbolics]{bliss_article}
\usepackage[main=blissymbolics]{babel}
\usepackage{fontspec}
\setmainfont[Mapping=tex-text]{Blissymbolics}
\setsansfont[Mapping=tex-text]{Blissymbolics}
\setmonofont{Blissymbolics}
\usepackage{longtable}

\makeatletter

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% LyX specific LaTeX commands.
\pdfpageheight\paperheight
\pdfpagewidth\paperwidth

%% Because html converters don't know tabularnewline
\providecommand{\tabularnewline}{\\}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% User specified LaTeX commands.
\usepackage[useregional,showdow]{datetime2}
\DTMusemodule{blissymbolics}{blissymbolics}
\selectlanguage{blissymbolics}
\usepackage{fancyhdr}  \pagestyle{fancy}
\setlength{\footskip}{37.4pt}
\lhead{} \chead{}  \rhead{}
\lfoot{: \DTMnow}  \cfoot{  \thepage}  \rfoot{  }
\renewcommand\headrulewidth{2pt}
\renewcommand\footrulewidth{0.4pt}

\makeatother

\begin{document}
{\huge{}}%
\begin{longtable}[l]{|c|c|c|}
\hline 
\textbf{\large{} } & \textbf{\large{} } & \textbf{\large{}1  }\tabularnewline
\hline 
\endfirsthead
\hline 
\textbf{\large{} } & \textbf{\large{} } & \textbf{\large{}1  }\tabularnewline
\hline 
\endhead
\hline 
«QUERY 1:SELECT DISTINCT User FROM Temp1 ORDER BY User; »
«FIELD:1» & & \tabularnewline
«QUERY 2:SELECT DISTINCT User, Word, SampleCount FROM Temp1 WHERE User=?1 ORDER BY User; »
 & «FIELD:2» & «FIELD:3» \tabularnewline
«END QUERY 2»
\hline 
«QUERY 2:SELECT DISTINCT User, count(Word), sum(SampleCount) FROM Temp1 WHERE User=?1 ORDER BY User; »
\textbf{\large{} } & \textbf{\large{}«FIELD:2»} & \textbf{\large{}«FIELD:3»}\tabularnewline
\hline 
«END QUERY 2»
\end{longtable}{\huge\par}
«END QUERY 1»
\end{document}
"
WHERE ID = 1;
UPDATE Reports SET LaTex="%% LyX 2.3.6 created this file.  For more info, see http://www.lyx.org/.
%% Do not edit unless you really know what you are doing.
\documentclass[32pt,a4paper,blissymbolics]{bliss_article}
\usepackage[main=blissymbolics]{babel}
\usepackage{fontspec}
\setmainfont[Mapping=tex-text]{Blissymbolics}
\setsansfont[Mapping=tex-text]{Blissymbolics}
\setmonofont{Blissymbolics}
\usepackage{longtable}

\makeatletter

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% LyX specific LaTeX commands.
\pdfpageheight\paperheight
\pdfpagewidth\paperwidth

%% Because html converters don't know tabularnewline
\providecommand{\tabularnewline}{\\}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% User specified LaTeX commands.
\usepackage[useregional,showdow]{datetime2}
\DTMusemodule{blissymbolics}{blissymbolics}
\selectlanguage{blissymbolics}
\usepackage{fancyhdr}  \pagestyle{fancy}
\setlength{\footskip}{37.4pt}
\lhead{} \chead{ }  \rhead{}
\lfoot{: \DTMnow}  \cfoot{  \thepage}  \rfoot{ }
\renewcommand\headrulewidth{2pt}
\renewcommand\footrulewidth{0.4pt}

\makeatother

\begin{document}
\begin{longtable}[c]{|l|l|l|}
\hline 
\textbf{\large{} } & \textbf{\large{} } & \textbf{\large{}  }\tabularnewline
\hline 
\endhead
\hline 
«QUERY 1:SELECT DISTINCT Logon FROM Temp1 ORDER BY Logon; »
«FIELD:1» & & \tabularnewline
«QUERY 2:SELECT DISTINCT Logon, IFNULL(Word, TheChar) Word, Used FROM Temp1 WHERE Logon=?1 ORDER BY Logon ASC, Used DESC; »
 & «FIELD:2» & «FIELD:3» \tabularnewline
«END QUERY 2»
\hline 
«QUERY 2:SELECT DISTINCT Logon, sum(Used) FROM Temp1 WHERE Logon=?1 ORDER BY User; »
\textbf{\large{} } & & \textbf{\large{}«FIELD:2»}\tabularnewline
\hline 
«END QUERY 2»
«END QUERY 1»
\end{longtable}
\end{document}"
WHERE ID = 2;
UPDATE Reports SET LaTex="%% LyX 2.3.6 created this file.  For more info, see http://www.lyx.org/.
%% Do not edit unless you really know what you are doing.
\documentclass[32pt,a4paper,blissymbolics]{bliss_article}
\usepackage[main=blissymbolics]{babel}
\usepackage{fontspec}
\setmainfont[Mapping=tex-text]{Blissymbolics}
\setsansfont[Mapping=tex-text]{Blissymbolics}
\setmonofont{Blissymbolics}
\usepackage{longtable}

\makeatletter

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% LyX specific LaTeX commands.
\pdfpageheight\paperheight
\pdfpagewidth\paperwidth

%% Because html converters don't know tabularnewline
\providecommand{\tabularnewline}{\\}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% User specified LaTeX commands.
\usepackage[useregional,showdow]{datetime2}
\DTMusemodule{blissymbolics}{blissymbolics}
\selectlanguage{blissymbolics}
\usepackage{fancyhdr}  \pagestyle{fancy}
\setlength{\footskip}{37.4pt}
\lhead{} \chead{  }  \rhead{}
\lfoot{: \DTMnow}  \cfoot{  \thepage}  \rfoot{   }
\renewcommand\headrulewidth{2pt}
\renewcommand\footrulewidth{0.4pt}

\makeatother

\begin{document}
\begin{longtable}[c]{|c|c|c|c|}
\hline 
\textbf{\large{} } & \textbf{\large{} } & \textbf{\large{}  } & \textbf{\large{}  }\tabularnewline
\hline 
\endhead
\hline 
«QUERY 1:SELECT DISTINCT CharWord, round(Avg_Durn,3), round(Avg_Disqual,1), cast(round(Avg_Alts) as INTEGER) FROM Temp1 ORDER BY CharWord;»
«FIELD:1» & «FIELD:2» & «FIELD:3» & «FIELD:4» \tabularnewline
«END QUERY 1»
\hline 
«QUERY 1:SELECT round(avg(Avg_Durn),3), round(avg(Avg_Disqual),1) FROM Temp1; »
\textbf{\large{} } & \textbf{\large{}«FIELD:1»} & \textbf{\large{}«FIELD:2»} & \tabularnewline
\hline 
«END QUERY 1»
\end{longtable}
\end{document}"
WHERE ID=3;
UPDATE Reports SET R="## Fonts ##
## ----- ##
## The following should be put into a script and run
## as the input parameter to the program Rscript as root
## after the Blissymbolics-Courier.ttf font is installed
## into the /usr/share/fonts/truetype/lyx/ directory.
## You would run the following for extrafont, but it
## doesn't work for printing.
# install.packages(""extrafont"")
# library(extrafont)
# font_import()
## You might need to run that last command manually in R
## since it requires you to answer ""y"" to a request to
## proceed.
## Best is to run the following R command as root:
# install.packages(""showtext"")
## For extrafont, you do:
# library(extrafont)
# loadfonts(device=""all"", quiet=TRUE)
## For showtext, you do:
library(showtext)
font_add(""Blissymbolics"", ""/usr/local/share/texmf/fonts/truetype/Blissymbolics-Courier.ttf"")
showtext_auto()
## Constants ##
## --------- ##
## Set up the source table names
tbltemp1  <- ""Temp1""
tbltemp2  <- ""Temp2""
tbltemp3  <- ""Temp3""
## Set up the target file names
outputfile    <- ""result1.eps""
graphtitle1   <- ""   ""
graphtitle2   <- ""   ""
bordercolours <- c(""darkblue"")
linecolours   <- c(""green"",""blue"",""red"")
label        <- c("""")
## Get the source table data
library(DBI)
db <- dbConnect(RSQLite::SQLite(), ""«PARAM:4»"")
userids  <- dbGetQuery(db, ""SELECT DISTINCT Logon FROM Temp1"")
result  <- dbGetQuery(db, ""SELECT DISTINCT Logon, TheChar, SampleNo, Used FROM Temp2"")
remaining <- dbReadTable(db, tbltemp3)
## Plot the results

postscript(outputfile,horizontal=FALSE,onefile=FALSE,width=7.4,height=10.0,pointsize=20)
pie(result$Used, labels = result$TheChar, edges = 200, radius = 0.8,
    clockwise = FALSE, 
    density = NULL, angle = 45, col = NULL, border = bordercolours,
    lty = NULL, main = graphtitle1, family=""Blissymbolics"")
dev.off()
## Disconnect from the database
dbDisconnect(db)
## Clean up ##
## -------- ##
rm(result, db, tbltemp1, tbltemp2, tbltemp3, userids, remaining)
rm(outputfile)
rm(graphtitle1, graphtitle2, bordercolours, linecolours, label)
# Exit
q()
"
WHERE ID=4;
UPDATE Reports SET LaTex="%% LyX 2.3.2 initially created this file.  For more info, see http://www.lyx.org/.
%% Do not edit unless you really know what you are doing (i.e. you know LaTex).
\documentclass[32pt,a4paper,blissymbolics]{bliss_article}
\usepackage[main=blissymbolics]{babel}
\usepackage{fontspec}
\setmainfont[Mapping=tex-text]{Blissymbolics}
\setsansfont[Mapping=tex-text]{Blissymbolics}
\setmonofont{Blissymbolics}
\usepackage[portrait,a4paper]{geometry}
\geometry{verbose,tmargin=1.8cm,bmargin=1.8cm,lmargin=1.5cm,rmargin=1.5cm,headheight=0.5cm,headsep=0.5cm,footskip=0.5cm}
\usepackage{graphicx}
\usepackage{setspace}

\makeatletter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% User specified LaTeX commands.
\selectlanguage{blissymbolics}
\usepackage[useregional,showdow]{datetime2}
\DTMusemodule{blissymbolics}{blissymbolics}
\selectlanguage{blissymbolics}
\usepackage{fancyhdr}  \pagestyle{fancy}
\setlength{\footskip}{37.4pt}
\setlength{\headheight}{37.0pt}
\addtolength{\topmargin}{-22.77364pt}
\lhead{} \chead{ }  \rhead{}
\lfoot{: \DTMnow}  \cfoot{  \thepage}  \rfoot{ }
\renewcommand\headrulewidth{2pt}
\renewcommand\footrulewidth{0.4pt}

\makeatother

\begin{document}
\begin{singlespace}
\noindent \includegraphics[width=180mm,height=230mm]{result1} 
\end{singlespace}
\end{document}
"
WHERE ID=4;
