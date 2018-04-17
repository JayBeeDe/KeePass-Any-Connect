Param(
  [string]$ip,
  [int]$port,
  [string]$username, #not used
  [string]$password,
  [bool]$fullScreen=$false
)

$scriptPath=$(split-path -parent $MyInvocation.MyCommand.Definition)
$vncPath="$scriptPath\..\Software\TightVNC\tvnviewer.exe"
$defaultPort=5901
$defaultPassword="YourPasswordHere"

if($port -eq "" -or $port -eq -1){
  $port=$defaultPort
}
if($password -eq ""){
  $password=$defaultPassword
}
if($ip -eq ""){
  Throw "You must specify an ip address or a host!"
}
if($fullscreen -eq $true){
    $specArg2="-fullscreen=yes"
}else{
    $specArg2=""
}

Start-Process -FilePath $($vncPath) -ArgumentList "-host=$($ip) -port=$($port) -password=$($password) -scale=auto $($specArg2)" -WindowStyle Maximized