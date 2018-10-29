<#
  .SYNOPSIS
  Converts systeminfo.exe output to powershell object
  .DESCRIPTION
  Levereges a large amount of string parsing to split a few of the specific fields into hashtables and arrays (IPs, HyperV Requirements, etc.)
  .EXAMPLE
  Simply call function and save results to variable for maximum interaction ( $sysinfo=Get-SysInfo ) and then access various child objects as desired ( $sysinfo.networkcards[0].ipaddresses  to returns available IPs from first profile/interface)  
#>

function Get-SysInfo{
    $fields = 'Hostname','OSName','OSVersion','OSManufacturer','OSConfiguration','OSBuildType','RegisteredOwner','RegisteredOrganization','ProductID','InstallDate','SystemBootTime','SystemManufacturer','SystemModel','SystemType','Processors','BIOSVersion','WindowsDirectory','SystemDirectory','BootDevice','SystemLocale','InputLocale','TimeZone','TotalPhysicalMemory','AvailablePhysicalMemory','VirtualMemoryMaxSize','VirtualMemoryAvailable','VirtualMemoryInUse','PageFileLocations','Domain','LogonServer','Hotfix','NetworkCards','HyperVRequirements','HotfixCount'
    $sysinfo=systeminfo.exe /FO csv | select-object -skip 1| ConvertFrom-Csv -header $fields
    $hfcount=''
    foreach($key in $sysinfo.psobject.Properties){
        if ($key.name -match 'Hotfix'){
            $hfcount+=($key.value -replace '[[0-9]*]','' -replace ':','' -replace ',$','' -split "Installed., ")[0].split(" ")[0]
            $key.value=($key.value -replace '[[0-9]*]','' -replace ':','' -replace ',$','' -split "Installed., ")[1] -replace " ",""
            }
        if ($key.name -match 'HotfixCount'){
            $key.value=$hfcount
            }
        if ($key.name -match 'Processors'){
            $key.value=($key.value -split "Installed.,")[1]
            $key.value=[regex]::split($key.value, '\[..\]: ')
            $key.value=$key.value[1..($key.value.Length-1)]
            }
        if ($key.name -match 'NetworkCards'){
            $key.value=($key.value -split "Installed.,")[1]
            $key.value=[regex]::split($key.value, ',\[..\]: ')  -replace ", *","," -replace ": *",":" -replace "[[0-9]*]:","" -replace "\(*\)*","" -replace "IP addresses,","IPAddresses,"
            $niccnt=0
            $adapters = $key.value
            foreach($adapter in $adapters){
                $ints = @{}
                $nicarr=$adapter.split(",")
                $ints.add("Description",$($nicarr[0]))
                $nicarr=$nicarr[1.."$(($nicarr.length)-1)"]
                if ($nicarr -match 'IPAddresses'){
                    foreach($field in $nicarr[0..$($nicarr.Indexof("$($nicarr -match 'IPAddresses')")-1)]){
                        $ints.add($($field.split(':')[0] -replace ' ',''),$($field.split(':')[1]))
                        }
                    $ips=$($nicarr[$($nicarr.IndexOf("$($nicarr -match 'IPAddresses')")+1).."$(($nicarr.length)-1)"])
                    $ints.add($($nicarr[$nicarr.IndexOf("$($nicarr -match 'IPAddresses')")]),$ips)
                    }
                else{
                    foreach($field in $nicarr){
                        $ints.add($($field.split(':')[0] -replace ' ',''),$($field.split(':')[1]))
                        }
                    }
                $key.value[$niccnt]=$ints
                $niccnt+=1
                }
            }
        if ($key.name -match 'HyperVRequirements'){
            $hyperv=@{}
            $key.value=$key.value.split(",")
            foreach($setting in $key.value){
                $kv=$setting -replace " ",""
                $kv=$kv.split(":")
                $hyperv.add($kv[0],$kv[1])
                }
            $key.value=$hyperv
            }
        }
    return $sysinfo
    }
