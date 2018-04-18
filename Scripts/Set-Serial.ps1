Param(
  [int]$speed,
  [string]$username
)

$scriptPath=$(split-path -parent $MyInvocation.MyCommand.Definition)
$config=Import-Clixml "$($scriptPath)\Config.xml"
$softPath=$($config | Where-Object {$_.Proto -eq "Serial"}).Path
if($($config | Where-Object {$_.Proto -eq "Serial"}).PathAbsolute -ne $true){
    $softPath="$scriptPath\$softPath"
}

if(-Not($speed -gt 1000)){
    $speed=$($config | Where-Object {$_.Proto -eq "Serial"}).defaultSpeed
}
if($($config | Where-Object {$_.Proto -eq "Serial"}).superPuttyMode -eq $true){
    $specArg=""
}else{
    $specArg=""
}
if($($config | Where-Object {$_.Proto -eq "Serial"}).puttyProfile -eq ""){
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
