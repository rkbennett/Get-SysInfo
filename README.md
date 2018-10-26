# Get-SysInfo
Powershell function for converting systeminfo output into a powershell object

This function allows object interaction of data derived from systeminfo.exe output.

This function may also be modified to read pre-existing systeminfo output files if they were output as csv by changing 
"$sysinfo=systeminfo.exe /FO csv" to "$sysinfo=Get-Content /path/to/systeminfo_file.csv" on the 3rd line of the function
