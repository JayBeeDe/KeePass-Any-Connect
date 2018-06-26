Param(
  [string]$ip,
  [int]$port,
  [string]$username, #not used
  [string]$password,
  [bool]$fullScreen=$false
)

$scriptPath=$(split-path -parent $MyInvocation.MyCommand.Definition)
[xml]$XmlDocument=Get-Content -Path "$($scriptPath)\Config.xml"


$soft=$XmlDocument | Select-Xml -XPath "/Settings/Proto/VNC/app" | ForEach-Object { $_.Node.value }
$softPath="$($scriptPath)\$($XmlDocument | Select-Xml -XPath "/Settings/App/$($soft)/path" | ForEach-Object { $_.Node.value })"

if($port -eq "" -or $port -eq -1){
  $port=$($XmlDocument | Select-Xml -XPath "/Settings/Proto/VNC/defaultPort" | ForEach-Object { $_.Node.value })
  if($port -eq $null){
    $username=$($XmlDocument | Select-Xml -XPath "/Settings/Proto/VNC/defaultUsername" | ForEach-Object { $_.Node.value })
    if($username -eq $null){
      $username=$($XmlDocument | Select-Xml -XPath "/Settings/General/defaultUsername" | ForEach-Object { $_.Node.value })
    }
    if ($username -eq "root"){
      $port="5901"
    }
  }
}
if($password -eq ""){
  $password=$($XmlDocument | Select-Xml -XPath "/Settings/Proto/VNC/defaultPassword" | ForEach-Object { $_.Node.value })
  if($password -eq $null){
    $password=$($XmlDocument | Select-Xml -XPath "/Settings/General/defaultPassword" | ForEach-Object { $_.Node.value })
  }
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