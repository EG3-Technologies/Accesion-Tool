@ECHO OFF

curl  https://www.python.org/ftp/python/3.9.2/python-3.9.2.exe -o python.exe
#Cannot Curl Ghostscript for some reason

ECHO Installing Python
python #/quiet
ECHO Install Done

gs9533w32 #/S
ECHO Installing GS
ECHO Install Done

ECHO %ERRORLEVEL%
ECHO Installing python dependencies
py -m pip install PySide2
py -m pip install qrcode
py -m pip install treepoem

ECHO Dependencies Installed
