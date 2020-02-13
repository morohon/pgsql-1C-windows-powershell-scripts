$pathPostgres = "C:\Program Files\PostgreSQL\10.3-3.1C\bin";

Start-Process "$pathPostgres\vacuumdb.exe" -ArgumentList  "--all", "--full", "--analyze", "-U postgres", "-h 127.0.0.1" -Wait -NoNewWindow;
