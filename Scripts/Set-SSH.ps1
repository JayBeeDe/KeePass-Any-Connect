Param(
  [string]$ip,
  [int]$port,
  [string]$username,
  [string]$password
)

$scriptPath=$(split-path -parent $MyInvocation.MyCommand.Definition)
[xml]$XmlDocument=Get-Content -Path "$($scriptPath)\Config.xml"
<#$XmlDocument | Select-Xml -XPath "/Settings/General/add[@key='superPuttyMode']" | ForEach-Object { $_
.Node.value }#>

$soft=$XmlDocument | Select-Xml -XPath "/Settings/Proto/SSH/app" | ForEach-Object { $_.Node.value }
$softPath="$($scriptPath)\$($XmlDocument | Select-Xml -XPath "/Settings/App/$($soft)/path" | ForEach-Object { $_.Node.value })"

if($port -eq "" -or $port -eq -1){
  $port=$($XmlDocument | Select-Xml -XPath "/Settings/Proto/SSH/defaultPort" | ForEach-Object { $_.Node.value })
}
if($username -eq ""){
  $username=$($XmlDocument | Select-Xml -XPath "/Settings/Proto/SSH/defaultUsername" | ForEach-Object { $_.Node.value })
  if($username -eq $null){
    $username=$($XmlDocument | Select-Xml -XPath "/Settings/General/defaultUsername" | ForEach-Object { $_.Node.value })
  }
}
if($password -eq ""){
  $password=$($XmlDocument | Select-Xml -XPath "/Settings/Proto/SSH/defaultPassword" | ForEach-Object { $_.Node.value })
  if($password -eq $null){
    $password=$($XmlDocument | Select-Xml -XPath "/Settings/General/defaultPassword" | ForEach-Object { $_.Node.value })
  }
}
if($ip -eq ""){
  Throw "You must specify an ip address or a host!"
}
if($soft -eq "SuperPutty"){
    $specArg="-host"
}else{
    $specArg=""
}
$puttyProfile=$($XmlDocument | Select-Xml -XPath "/Settings/Proto/SSH/profile" | ForEach-Object { $_.Node.value })
if($puttyProfile -eq $null){
    $specArg2=""
}else{
    $specArg2="-load $($puttyProfile)"
}

Start-Process -FilePath $($softPath) -ArgumentList "$($specArg2) -ssh $($specArg) $($ip) -P $($port) -l $($username) -pw $($password)" -WindowStyle Maximized