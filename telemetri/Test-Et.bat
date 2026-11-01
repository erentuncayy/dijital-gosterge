@echo off
REM Telemetri calisiyor mu? Tarayicida veriyi acar.
start "" "http://localhost:8765/"
echo Tarayicida {"cpu":...} gibi bir veri gorunuyorsa telemetri calisiyor.
echo "Siteye ulasilamiyor" gorunurse once Baslat.bat dosyasini calistir.
echo Sorun devam ederse ayni klasordeki telemetri-log.txt dosyasini gonder.
pause
