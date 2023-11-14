INSERT INTO Reports VALUES (1, "Enrolled Words", "wordsstats", 0, "", "");
INSERT INTO Reports VALUES (2, "Usage Statistics", "usestats", 0, "", "");
INSERT INTO Reports VALUES (3, "Performance Statistics", "perfstats", 0 , "", "");
INSERT INTO Reports VALUES (4, "Daily Volume", "dailyvol", 1, "", "");
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
INSERT INTO Queries VALUES (4, 2, "", "CREATE TABLE Temp1 (Patient VARCHAR(80), UDate DATE, Volume INTEGER, PadVol INTEGER, Pads INTEGER);");
INSERT INTO Queries VALUES (4, 3, "Temp1", "SELECT PD.Patient, UR.UDate, SUM(UR.Volume) AS Volume, SUM(UR.PadVolume - (CASE WHEN UR.Leakage < 2 THEN 0 ELSE (SELECT P.Size FROM PadSizes P WHERE P.ID = UR.PadType) - (CASE WHEN UR.Leakage > 2 THEN (SELECT DISTINCT PP.Size FROM PadSizes PP WHERE PP.ID = 1) ELSE 0 END) END)) AS PadVol, COUNT(UR.PadType) AS Pads FROM UrineRecord UR, PatientDetails PD WHERE PD.Identifier = UR.Patient AND UR.UDate < date('now') GROUP BY PD.Patient, UR.UDate;");
INSERT INTO Queries VALUES (4, 4, "", "DROP TABLE Temp2;");
INSERT INTO Queries VALUES (4, 5, "", "CREATE TABLE Temp2 AS SELECT Patient, UDate, Volume * 100.00 / (Volume + PadVol) AS PercentVol, PadVol * 100.00 / (Volume + PadVol ) AS PercentPadVol, Pads AS PadCount FROM Temp1;");
UPDATE Reports SET LaTex="%% LyX 2.3.6 created this file.  For more info, see http://www.lyx.org/.
%% Do not edit unless you really know what you are doing (i.e. you know LaTex).
\documentclass[32pt,a4paper,australian]{bliss_article}
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
\usepackage{fancyhdr}  \pagestyle{fancy}
\lhead{} \chead{}  \rhead{}
\lfoot{: \today}  \cfoot{  \thepage}  \rfoot{  }
\renewcommand\headrulewidth{2pt}
\renewcommand\footrulewidth{0.4pt}

\makeatother

\usepackage{polyglossia}
\setdefaultlanguage[variant=australian]{english}
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
\end{longtable}{\huge\par}
«END QUERY 1»
\end{document}
"
WHERE ID = 1;
UPDATE Reports SET LaTex="%% LyX 2.3.6 created this file.  For more info, see http://www.lyx.org/.
%% Do not edit unless you really know what you are doing.
\documentclass[32pt,a4paper,australian]{bliss_article}
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
%\usepackage{datetime2-bliss-utf8}
\usepackage{fancyhdr}  \pagestyle{fancy}
\lhead{} \chead{ }  \rhead{}
\lfoot{: \today}  \cfoot{  \thepage}  \rfoot{ }
\renewcommand\headrulewidth{2pt}
\renewcommand\footrulewidth{0.4pt}

\makeatother

\usepackage{polyglossia}
\setdefaultlanguage[variant=australian]{english}
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
«END QUERY 1»
\end{longtable}
\end{document}"
WHERE ID = 2;
UPDATE Reports SET LaTex="%% LyX 2.3.6 created this file.  For more info, see http://www.lyx.org/.
%% Do not edit unless you really know what you are doing.
\documentclass[32pt,a4paper,australian]{bliss_article}
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
\usepackage{fancyhdr}  \pagestyle{fancy}
\lhead{} \chead{  }  \rhead{}
\lfoot{: \today}  \cfoot{  \thepage}  \rfoot{   }
\renewcommand\headrulewidth{2pt}
\renewcommand\footrulewidth{0.4pt}

\makeatother

\usepackage{polyglossia}
\setdefaultlanguage[variant=australian]{english}
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
\end{longtable}
\end{document}"
WHERE ID=3;
UPDATE Reports SET R="## Constants ##
## --------- ##
## Set up the source table names
tbltemp1  <- ""Temp1""
tbltemp2  <- ""Temp2""
## Set up the target file names
outputfile    <- ""result1.eps""
graphtitle1   <- ""Ratio of Measured to Pad Volumes for ""
graphtitle2   <- ""%age controlled urine and %age leakage to pad""
bordercolours <- c(""darkblue"")
linecolours   <- c(""green"",""blue"",""red"")
labels        <- c(""% Vol"",""% Pad Vol"",""Pad Count"")
## Get the source table data
library(DBI)
db <- dbConnect(RSQLite::SQLite(), ""«PARAM:4»"")
userids <- dbGetQuery(db, ""SELECT DISTINCT Patient FROM Temp1"")
result  <- dbReadTable(db, tbltemp2)
## Plot the results
postscript(outputfile,horizontal=FALSE,onefile=FALSE,width=14.0,height=7.4,pointsize=10)
plot(x=as.Date(result$UDate,format=""%Y-%m-%d""),y=result$PercentVol, type=""l"", 
     col=linecolours[1], col.axis=bordercolours, xlab=""Date"", ylab=""%"", cex=1.1,
     main=paste(graphtitle1,userids[1],sep=""""), sub=graphtitle2)
lines(x=as.Date(result$UDate,format=""%Y-%m-%d""),y=result$PercentPadVol,
     col=linecolours[2])
par(new = TRUE)
plot(x=as.Date(result$UDate,format=""%Y-%m-%d""),y=result$PadCount, type=""l"", 
     col=linecolours[3],xaxt=""n"",yaxt=""n"",ylab="""",xlab="""",lty = 2,cex=1.1)
axis(side=4)
mtext(""Pads"", side=4, line=3)
legend(""right"", labels, col=linecolours, lty=c(1,2,3))
# text(xy.coords(0.8,1), pos=4, cex=1.1,
#      eval(substitute(expression(R^2 == rsqd), 
#                      list(rsqd = round(summary(fm)$adj.r.squared,4)))) )
dev.off()
## Disconnect from the database
dbDisconnect(db)
## Clean up ##
## -------- ##
rm(result, db, tbltemp1, tbltemp2, userids)
rm(outputfile)
rm(graphtitle1, graphtitle2, bordercolours, linecolours, labels)
# Exit
q()
"
WHERE ID=4;
UPDATE Reports SET LaTex="%% LyX 2.3.2 initially created this file.  For more info, see http://www.lyx.org/.
%% Do not edit unless you really know what you are doing (i.e. you know LaTex).
\documentclass[australian]{article}
\usepackage[T1]{fontenc}
\usepackage[latin9]{inputenc}
\usepackage[landscape,a4paper]{geometry}
\geometry{verbose,tmargin=1.5cm,bmargin=1.2cm,lmargin=1.5cm,rmargin=1.5cm,headheight=0.5cm,headsep=0.5cm,footskip=0.5cm}
\usepackage{graphicx}
\usepackage{setspace}

\makeatletter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% User specified LaTeX commands.
\usepackage{babel}

\makeatother

\usepackage{babel}
\begin{document}
\begin{singlespace}
\noindent \includegraphics[width=270mm,height=180mm]{result1} 
\end{singlespace}
\end{document}
"
WHERE ID=4;
