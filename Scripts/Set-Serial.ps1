Param(
  [int]$speed,
  [string]$username
)

$scriptPath=$(split-path -parent $MyInvocation.MyCommand.Definition)
[xml]$XmlDocument=Get-Content -Path "$($scriptPath)\Config.xml"
$soft=$XmlDocument | Select-Xml -XPath "/Settings/Proto/Serial/app" | ForEach-Object { $_.Node.value }
$softPath="$($scriptPath)\$($XmlDocument | Select-Xml -XPath "/Settings/App/$($soft)/path" | ForEach-Object { $_.Node.value })"

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
            Start-Process -FilePath $softPath -ArgumentList "$($specArg2) -serial COM$($port) -sercfg $($speed)" -WindowStyle Maximized
        }else{
            #&"C:\Software\Putty\modules\vdesk.exe" run-on-switch 2 $($softPath) -load $($puttyProfile) -serial COM$($port) -sercfg $($speed) -l $($username)
            Start-Process -FilePath $softPath -ArgumentList "$($specArg2) $($specArg) -serial COM$($port) -sercfg $($speed) -l $($username)" -WindowStyle Maximized
        }
    }
}
