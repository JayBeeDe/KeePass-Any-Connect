Param(
  [string]$ip,
  [int]$port,
  [string]$username,
  [string]$password
)

$scriptPath=$(split-path -parent $MyInvocation.MyCommand.Definition)
$config=Import-Clixml "$($scriptPath)\Config.xml"
$softPath=$($config | Where-Object {$_.Proto -eq "SSH"}).Path
if($($config | Where-Object {$_.Proto -eq "SSH"}).PathAbsolute -ne $true){
    $softPath="$scriptPath\$softPath"
}

if($port -eq "" -or $port -eq -1){
  $port=$($config | Where-Object {$_.Proto -eq "SSH"}).defaultPort
}
if($username -eq ""){
  $username=$($config | Where-Object {$_.Proto -eq "SSH"}).defaultUsername
}
if($password -eq ""){
  $password=$($config | Where-Object {$_.Proto -eq "SSH"}).defaultPassword
}
if($ip -eq ""){
  Throw "You must specify an ip address or a host!"
}
if($($config | Where-Object {$_.Proto -eq "SSH"}).superPuttyMode -eq $true){
    $specArg="-host"
}else{
    $specArg=""
}
if($($config | Where-Object {$_.Proto -eq "SSH"}).puttyProfile -eq ""){
    $specArg2=""
}else{
    $specArg2="-load $(($config | Where-Object {$_.Proto -eq "SSH"}).puttyProfile)"
}
Start-Process -FilePath $($softPath) -ArgumentList "$($specArg2) -ssh $($specArg) $($ip) -P $($port) -l $($username) -pw $($password)" -WindowStyle Maximized