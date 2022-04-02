INSERT INTO Languages VALUES ("Latin",1,32,126,"Basic Latin"); --20h - 7Eh
INSERT INTO Languages VALUES ("Latin-1 Supplement",2,128,255,"Latin-1 Supplement");
INSERT INTO Languages VALUES ("Latin Extended-A",3,256,300,"Latin Extended-A");
INSERT INTO Languages VALUES ("Latin Extended-B",4,256,300,"Latin Extended-B");
INSERT INTO Languages VALUES ("Extend",255,57740,57725,"Blissymbolics");--E100 - E18C

INSERT INTO Words VALUES (255,1,"xxxx","Person");

--INSERT INTO ColourChart VALUES (570,"Blonde");
--ALTER TABLE ColourChart ADD COLUMN Image blob;
.load ./fileio.so
--UPDATE ColourChart SET Image=readfile('1.b64') WHERE Value=570;

INSERT INTO Configurations VALUES(1,"cell_writer.glade",'T',"");
INSERT INTO Configurations VALUES(2,"cell_writer.png",'B',"");
UPDATE Configurations SET Details=readfile('../src/cell_writer.glade') WHERE ID=1;
UPDATE Configurations SET Details=readfile('cell_writer.b64') WHERE ID=2;

