Param(
  [string]$ip,
  [int]$port,
  [string]$username,
  [string]$password
)

$scriptPath=$(split-path -parent $MyInvocation.MyCommand.Definition)
$winSCPPath="$scriptPath\..\Software\WinSCP\WinSCP.exe"
$defaultPort=22
$defaultUsername="root"
$defaultPassword="YourPasswordHere"

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

Start-Process -FilePath $($winSCPPath) -ArgumentList "scp://$($username):$($password)@$($ip):$($port)" -WindowStyle Maximized