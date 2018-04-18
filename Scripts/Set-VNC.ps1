Param(
  [string]$ip,
  [int]$port,
  [string]$username, #not used
  [string]$password,
  [bool]$fullScreen=$false
)

$scriptPath=$(split-path -parent $MyInvocation.MyCommand.Definition)
$config=Import-Clixml "$($scriptPath)\Config.xml"
$softPath=$($config | Where-Object {$_.Proto -eq "VNC"}).Path
if($($config | Where-Object {$_.Proto -eq "VNC"}).PathAbsolute -ne $true){
    $softPath="$scriptPath\$softPath"
}

if($port -eq "" -or $port -eq -1){
  $port=$($config | Where-Object {$_.Proto -eq "VNC"}).defaultPort
}
if($password -eq ""){
  $password=$($config | Where-Object {$_.Proto -eq "VNC"}).defaultPassword
}
if($ip -eq ""){
  Throw "You must specify an ip address or a host!"
}
if($fullscreen -eq $true){
    $specArg2="-fullscreen=yes"
}else{
    $specArg2=""
}

Start-Process -FilePath $($softPath) -ArgumentList "-host=$($ip) -port=$($port) -password=$($password) -scale=auto $($specArg2)" -WindowStyle Maximized