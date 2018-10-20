Param(
  [string]$ip,
  [int]$port,
  [string]$username,
  [string]$password
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

$soft=$XmlDocument | Select-Xml -XPath "/Settings/Proto/SSH/app" | ForEach-Object { $_.Node.value }
$softPath="$($scriptPath)\$($XmlDocument | Select-Xml -XPath "/Settings/App/$($soft)/path" | ForEach-Object { $_.Node.value })"
$multipleOpeningTimeout="$($XmlDocument | Select-Xml -XPath "/Settings/App/$($soft)/multipleOpeningTimeout" | ForEach-Object { $_.Node.value })"
$subSoft="$($XmlDocument | Select-Xml -XPath "/Settings/App/$($soft)/subApp" | ForEach-Object { $_.Node.value })"

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
    write-host "console profile is set to $puttyProfile"
}

preventSoftFailure $multipleOpeningTimeout $subSoft $soft

write-host "Starting process $($softPath) $($specArg2) -ssh $($specArg) $($ip) -P $($port) -l $($username) -pw ********"
Start-Process -FilePath $($softPath) -ArgumentList "$($specArg2) -ssh $($specArg) $($ip) -P $($port) -l $($username) -pw $($password)" -WindowStyle Maximized

if ($debugMode -eq "true"){
  sleep 150
}