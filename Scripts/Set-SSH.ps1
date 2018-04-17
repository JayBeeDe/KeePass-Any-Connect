Param(
  [string]$ip,
  [int]$port,
  [string]$username,
  [string]$password
)

$scriptPath=$(split-path -parent $MyInvocation.MyCommand.Definition)
$puttyPath="$scriptPath\..\Software\SuperPutty\SuperPutty.exe"
$defaultPort=22
$defaultUsername="root"
$defaultPassword="YourPasswordHere"
$superPuttyMode=$true
$puttyProfile="RPI"

if($port -eq "" -or $port -eq -1){
  $port=$defaultPort
}
if($username -eq ""){
  $username=$defaultUsername
}
if($password -eq ""){
  $password=$defaultPassword
}
if($ip -eq ""){
  Throw "You must specify an ip address or a host!"
}
if($superPuttyMode -eq $true){
    $specArg="-host"
}else{
    $specArg=""
}
if($puttyProfile -eq ""){
    $specArg2=""
}else{
    $specArg2="-load $($puttyProfile)"
}

Start-Process -FilePath $($puttyPath) -ArgumentList "$($specArg2) -ssh $($specArg) $($ip) -P $($port) -l $($username) -pw $($password)" -WindowStyle Maximized