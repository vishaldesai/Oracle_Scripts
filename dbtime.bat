@ECHO off
SET DBUser=%1
SET DBPass=%2
SET DBTNS=%3

sqlplus -s "%DBUser%/%DBPass%@%DBTNS%" @C:\Users\U267399\Desktop\Tools\scripts\dbtimemonitor.sql %1 %2

cd C:\Users\U267399\Desktop\Tools\dominicgiles\dbtimemonitorOct012012\dbtimemonitor\bin\
dbtimemonitor.bat

cd C:\Users\U267399\Desktop\Tools\scripts