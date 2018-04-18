Param(
  [string]$ip,
  [int]$port,
  [string]$username,
  [string]$password
)

$scriptPath=$(split-path -parent $MyInvocation.MyCommand.Definition)
$config=Import-Clixml "$($scriptPath)\Config.xml"
$softPath=$($config | Where-Object {$_.Proto -eq "SCP"}).Path
if($($config | Where-Object {$_.Proto -eq "SCP"}).PathAbsolute -ne $true){
    $softPath="$scriptPath\$softPath"
}

if($port -eq "" -or $port -eq -1){
    $port=$($config | Where-Object {$_.Proto -eq "SCP"}).defaultPort
}
if($username -eq ""){
    $username=$($config | Where-Object {$_.Proto -eq "SCP"}).defaultUsername
}
if($password -eq ""){
    $password=$($config | Where-Object {$_.Proto -eq "SCP"}).defaultPassword
}
if($ip -eq ""){
  Throw "You must specify an ip address or a host!"
}

Start-Process -FilePath $($softPath) -ArgumentList "scp://$($username):$($password)@$($ip):$($port)" -WindowStyle Maximized