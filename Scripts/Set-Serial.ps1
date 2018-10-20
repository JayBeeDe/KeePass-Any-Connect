Param(
  [int]$speed,
  [string]$username
)

function preventSoftFailure([int]$multipleOpeningTimeout,[string]$soft,[string]$subSoft){
  if ($multipleOpeningTimeout -ne $null){
    if ($multipleOpeningTimeout -gt 0){
      try{
        if ($subSoft -ne $null){
          $res=(Get-Process -Name $subSoft -ErrorAction Stop | Select Name, StartTime | sort StartTime -Descending)[0].StartTime
        }else{
          $res=(Get-Process -Name $soft -ErrorAction Stop | Select Name, StartTime | sort StartTime -Descending)[0].StartTime
        }
        if ($res -ne $null){
          if ($res -gt 0){
            $res=$($res).AddSeconds($multipleOpeningTimeout)
            if ($(Get-Date) -le $res){
              write-host "Waiting time $res sec to prevent $soft crash"
              while ($(Get-Date) -le $res){
                sleep 1
              }
            }
          }
        }
      }catch{}
    }
  }
}

$scriptPath=$(split-path -parent $MyInvocation.MyCommand.Definition)
[xml]$XmlDocument=Get-Content -Path "$($scriptPath)\Config.xml"
$debugMode=$($XmlDocument | Select-Xml -XPath "/Settings/General/debugMode" | ForEach-Object { $_.Node.value })

$soft=$XmlDocument | Select-Xml -XPath "/Settings/Proto/Serial/app" | ForEach-Object { $_.Node.value }
$softPath="$($scriptPath)\$($XmlDocument | Select-Xml -XPath "/Settings/App/$($soft)/path" | ForEach-Object { $_.Node.value })"
$multipleOpeningTimeout="$($XmlDocument | Select-Xml -XPath "/Settings/App/$($soft)/multipleOpeningTimeout" | ForEach-Object { $_.Node.value })"
$subSoft="$($XmlDocument | Select-Xml -XPath "/Settings/App/$($soft)/subApp" | ForEach-Object { $_.Node.value })"

if(-Not($speed -gt 1000)){
    $speed=$($XmlDocument | Select-Xml -XPath "/Settings/Proto/Serial/defaultSpeed" | ForEach-Object { $_.Node.value })
}
if($soft -eq "SuperPutty"){
    $specArg=""
}else{
    $specArg=""
}
$puttyProfile=$($XmlDocument | Select-Xml -XPath "/Settings/Proto/Serial/profile" | ForEach-Object { $_.Node.value })
if($puttyProfile -eq $null){
    $specArg2=""
}else{
    $specArg2="-load $(($config | Where-Object {$_.Proto -eq "Serial"}).puttyProfile)"
}

preventSoftFailure $multipleOpeningTimeout $subSoft $soft

$ports=Get-WMIObject Win32_pnpentity | Where-Object{$_.PNPClass -match ".*Ports.*"} | select Name
$ports | foreach{
    $port=$_.Name -replace "^.*\(COM",""
    $port=$port -replace "\).*$",""
    if($port -eq $null -or $port -eq ""){
        #[System.Windows.Forms.MessageBox]::Show("No Serial Interface has been found on your device!","Serial Error","ok",16)
    }else{
        $port=$port.ToInt32($Null)
        Write-Host "The COM port $($port.ToInt32($Null)) will be used at speed $($speed)" -ForegroundColor Yellow
        if($username -eq $null -or $username -eq ""){
            #&"C:\Software\Putty\modules\vdesk.exe" run-on-switch 2 $($softPath) -load $($puttyProfile) -serial COM$($port) -sercfg $($speed)
            write-host "Starting process $($softPath) $($specArg2) -serial COM$($port) -sercfg $($speed)"
            Start-Process -FilePath $softPath -ArgumentList "$($specArg2) -serial COM$($port) -sercfg $($speed)" -WindowStyle Maximized
        }else{
            #&"C:\Software\Putty\modules\vdesk.exe" run-on-switch 2 $($softPath) -load $($puttyProfile) -serial COM$($port) -sercfg $($speed) -l $($username)
            write-host "Starting process $($softPath) $($specArg2) $($specArg)  -serial COM$($port) -sercfg $($speed) -l $($username)"
            Start-Process -FilePath $softPath -ArgumentList "$($specArg2) $($specArg) -serial COM$($port) -sercfg $($speed) -l $($username)" -WindowStyle Maximized
        }
    }
}

if ($debugMode -eq "true"){
  sleep 150
}