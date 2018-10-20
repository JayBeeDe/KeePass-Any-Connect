Param(
  [string]$ip,
  [int]$port,
  [string]$username, #not used
  [string]$password,
  [bool]$fullScreen=$false
)

function preventSoftFailure([int]$multipleOpeningTimeout,[string]$soft,[string]$subSoft){
  if ($multipleOpeningTimeout -ne $null){
    if ($multipleOpeningTimeout -gt 0){
      try{
        if ($subSoft -ne $null){
          $res=(Get-Process -Name $subSoft -ErrorAction Stop | Select Name, StartTime | sort StartTime -Descending)[0].StartTime
        }else{
          $res=(Get-Process -Name $soft -ErrorAction Stop | Select Name, StartTime | sort StartTime -Descending)[0].StartTime
        }
        if ($res -ne $null){
          if ($res -gt 0){
            $res=$($res).AddSeconds($multipleOpeningTimeout)
            if ($(Get-Date) -le $res){
              write-host "Waiting time $res sec to prevent $soft crash"
              while ($(Get-Date) -le $res){
                sleep 1
              }
            }
          }
        }
      }catch{}
    }
  }
}

$scriptPath=$(split-path -parent $MyInvocation.MyCommand.Definition)
[xml]$XmlDocument=Get-Content -Path "$($scriptPath)\Config.xml"
$debugMode=$($XmlDocument | Select-Xml -XPath "/Settings/General/debugMode" | ForEach-Object { $_.Node.value })

$soft=$XmlDocument | Select-Xml -XPath "/Settings/Proto/VNC/app" | ForEach-Object { $_.Node.value }
$softPath="$($scriptPath)\$($XmlDocument | Select-Xml -XPath "/Settings/App/$($soft)/path" | ForEach-Object { $_.Node.value })"
$multipleOpeningTimeout="$($XmlDocument | Select-Xml -XPath "/Settings/App/$($soft)/multipleOpeningTimeout" | ForEach-Object { $_.Node.value })"
$subSoft="$($XmlDocument | Select-Xml -XPath "/Settings/App/$($soft)/subApp" | ForEach-Object { $_.Node.value })"

if($port -eq "" -or $port -eq -1){
  $port=$($XmlDocument | Select-Xml -XPath "/Settings/Proto/VNC/defaultPort" | ForEach-Object { $_.Node.value })
  if($port -eq $null){
    $username=$($XmlDocument | Select-Xml -XPath "/Settings/Proto/VNC/defaultUsername" | ForEach-Object { $_.Node.value })
    if($username -eq $null){
      $username=$($XmlDocument | Select-Xml -XPath "/Settings/General/defaultUsername" | ForEach-Object { $_.Node.value })
    }
    if ($username -eq "root"){
      $port="5901"
      write-host "port has been reset to $port since username is $username"
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
  write-host "Fullscreen option has been set"
  $specArg2="-fullscreen=yes"
}else{
  $specArg2=""
}

preventSoftFailure $multipleOpeningTimeout $subSoft $soft

write-host "Starting process $($softPath) -host=$($ip) -port=$($port) -password=******** -scale=auto $($specArg2)"
Start-Process -FilePath $($softPath) -ArgumentList "-host=$($ip) -port=$($port) -password=$($password) -scale=auto $($specArg2)" -WindowStyle Maximized

if ($debugMode -eq "true"){
  sleep 150
}