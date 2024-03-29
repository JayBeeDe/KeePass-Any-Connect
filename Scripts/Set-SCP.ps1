Param(
  [string]$ip,
  [int]$port,
  [string]$username,
  [string]$password,
  [string]$proto
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

if($proto -ne "FTP"){
    $proto="SCP"
    $prot="scp"
    write-host "Proto has been reset to $prot"
}else{
    $prot="ftp"
}

$scriptPath=$(split-path -parent $MyInvocation.MyCommand.Definition)
[xml]$XmlDocument=Get-Content -Path "$($scriptPath)\Config.xml"
$debugMode=$($XmlDocument | Select-Xml -XPath "/Settings/General/debugMode" | ForEach-Object { $_.Node.value })

$soft=$XmlDocument | Select-Xml -XPath "/Settings/Proto/$($proto)/app" | ForEach-Object { $_.Node.value }
$softPath="$($scriptPath)\$($XmlDocument | Select-Xml -XPath "/Settings/App/$($soft)/path" | ForEach-Object { $_.Node.value })"
$multipleOpeningTimeout="$($XmlDocument | Select-Xml -XPath "/Settings/App/$($soft)/multipleOpeningTimeout" | ForEach-Object { $_.Node.value })"
$subSoft="$($XmlDocument | Select-Xml -XPath "/Settings/App/$($soft)/subApp" | ForEach-Object { $_.Node.value })"

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

preventSoftFailure $multipleOpeningTimeout $subSoft $soft

write-host "Starting process $($softPath) $($prot)://$($username):********@$($ip):$($port)"
Start-Process -FilePath $($softPath) -ArgumentList "$($prot)://$($username):$($password)@$($ip):$($port)" -WindowStyle Maximized

if ($debugMode -eq "true"){
  sleep 150
}