Param(
  [int]$speed,
  [string]$username
)

$scriptPath=$(split-path -parent $MyInvocation.MyCommand.Definition)

$moduleName="Get-ConfigurationXML.ps1"
Unblock-File -Path "$($global:currentLocation)\modules\$($moduleName)" -ErrorAction Stop
Import-Module "$($global:currentLocation)\modules\$($moduleName)" -Force -ErrorAction Stop -Scope Local

Get-ConfigurationXML -path "$scriptPath\Config.xml"
$puttyPath="$scriptPath\..\$($appSettings["puttyPath"])"

if(-Not($speed -gt 1000)){
    $speed=9600
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
            #&"C:\Software\Putty\modules\vdesk.exe" run-on-switch 2 $($puttyPath) -load $($puttyProfile) -serial COM$($port) -sercfg $($speed)
            Start-Process -FilePath $puttyPath -ArgumentList "-load RPI -serial COM$($port) -sercfg $($speed)" -WindowStyle Maximized
        }else{
            #&"C:\Software\Putty\modules\vdesk.exe" run-on-switch 2 $($puttyPath) -load $($puttyProfile) -serial COM$($port) -sercfg $($speed) -l $($username)
            Start-Process -FilePath $puttyPath -ArgumentList "-load RPI -serial COM$($port) -sercfg $($speed) -l $($username)" -WindowStyle Maximized
        }
    }
}
