Param(
  [string]$ip,
  [int]$port,
  [string]$username,
  [string]$password,
  [string]$proto
)

if($proto -ne "FTP"){
    $proto="SCP"
    $prot="scp"
}else{
    $prot="ftp"
}

$scriptPath=$(split-path -parent $MyInvocation.MyCommand.Definition)
[xml]$XmlDocument=Get-Content -Path "$($scriptPath)\Config.xml"

$soft=$XmlDocument | Select-Xml -XPath "/Settings/Proto/$($proto)/app" | ForEach-Object { $_.Node.value }
$softPath="$($scriptPath)\$($XmlDocument | Select-Xml -XPath "/Settings/App/$($soft)/path" | ForEach-Object { $_.Node.value })"

if($port -eq "" -or $port -eq -1){
    $port=$($XmlDocument | Select-Xml -XPath "/Settings/Proto/$($proto)/defaultPort" | ForEach-Object { $_.Node.value })
}
if($username -eq ""){
  $username=$($XmlDocument | Select-Xml -XPath "/Settings/Proto/$($proto)/defaultUsername" | ForEach-Object { $_.Node.value })
  if($username -eq $null){
    $username=$($XmlDocument | Select-Xml -XPath "/Settings/General/defaultUsername" | ForEach-Object { $_.Node.value })
  }
}
if($password -eq ""){
  $password=$($XmlDocument | Select-Xml -XPath "/Settings/Proto/$($proto)/defaultPassword" | ForEach-Object { $_.Node.value })
  if($password -eq $null){
    $password=$($XmlDocument | Select-Xml -XPath "/Settings/General/defaultPassword" | ForEach-Object { $_.Node.value })
  }
}
if($ip -eq ""){
  Throw "You must specify an ip address or a host!"
}

Start-Process -FilePath $($softPath) -ArgumentList "$($prot)://$($username):$($password)@$($ip):$($port)" -WindowStyle Maximized