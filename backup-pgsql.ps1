<#Общие переменные, такие как
backupfolder - папка, в которой будут хранится бэкапы
pathToLogfile - путь к лог файлу, в который будет записываться информация о выполнении бэкапов (в том числе и ошибки)
date - переменная для хранения даты выполнения бэкапа
bases - массив с именами баз, которые нужно бэкапить
limitPgDump - сколько дней хранить бэкапы pg_dump (в переменной дата "отсечки")
limitPgBasebackup - сколько дней хранить бэкапы pg_basebackup (в переменной дата "отсечки")
#>
$backupfolder = 'C:\Bases1s\backup';
$pathToLogfile = 'C:\Bases1s\backup\backup.log';
$date = Get-Date -Format yyyy_MM_dd_HH_mm;
$bases = New-Object System.Collections.ArrayList;
$limitPgDump = (Get-Date).AddDays(-14);
$limitPgBasebackup = (Get-Date).AddDays(-7);
$bases.Add('unf_crm');

#очищаем файлы логов, чтобы не захламлять диск (очищаются прервого числа каждого месяца)
$dayOfMonth = Get-Date -Format %d;

if ($dayOfMonth -eq 1) 
{ 
	echo '' > $pathToLogfile;
} 

#папка из которой берутся исполняемые файлы PostgreSQL
$pathPostgres = "C:\Program Files\PostgreSQL\10.3-3.1C\bin";

#Если папка не существует - нужно ее создать
if(!(Test-Path $backupfolder)) {
	New-Item -Path $backupfolder -ItemType Directory;
}

#Пробегаемся по массиву с базами данных и выполняем бэкап pg_dump
foreach($base in $bases) {
    $path = $backupfolder + '\pg_dump\1s8_' + $base + '_' + $date + '.dump';
	echo "$(Get-Date) - pg_dump - $base - begin $path" >> $pathToLogfile;
    Start-Process "$pathPostgres\pg_dump.exe" -ArgumentList "-Fc", "-U postgres", "-h 127.0.0.1", "-f $path", $base -Wait -NoNewWindow >> $pathToLogfile -RedirectStandardError $pathToLogfile;
	echo "$(Get-Date) - pg_dump - $base - end $path" >> $pathToLogfile;
}

Start-Sleep -s 15;

#Удаляем бэкапы pg_dump старше 14 дней
Get-ChildItem -Path "$backupfolder\pg_dump" -Recurse -Force | Where-Object { $_.CreationTime -lt $limitPgDump } | Remove-Item -Force;

#Начинаем бэкапить с помощью pg_basebackup
echo "$(Get-Date) - pg_basebackup - cluster - begin" >> $pathToLogfile;

#Папку не создаем т.к. ключ -D по умолчанию создает папку
$backupfolderBasebackup = "$backupfolder\pg_basebackup\$date";

#Запускаем pg_basebackup со сжатием в gz (параметр z)
Start-Process "$pathPostgres\pg_basebackup.exe" -ArgumentList "-D $backupfolderBasebackup", "-Ft", "-z", "-U postgres", "-h 127.0.0.1", "-P" -Wait -NoNewWindow >> $pathToLogfile -RedirectStandardError $pathToLogfile;
echo "$(Get-Date) - pg_basebackup - cluster - end" >> $pathToLogfile;

#Удаляем старые бэкапы pg_basebackup и удаляем пустые папки
Get-ChildItem "$backupfolder\pg_basebackup" -Recurse | ? { -not $_.PSIsContainer -and $_.CreationTime -lt $limitPgBasebackup } | Remove-Item;
Get-ChildItem -Path "$backupfolder\pg_basebackup" -Recurse -Force | Where-Object { $_.PSIsContainer -and (Get-ChildItem -Path $_.FullName -Recurse -Force | Where-Object { !$_.PSIsContainer }) -eq $null } | Remove-Item -Force -Recurse