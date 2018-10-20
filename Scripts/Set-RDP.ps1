Param(
  [string]$ip,
  [int]$port,
  [string]$username,
  [string]$password,
  [Parameter(Mandatory=$false)][ValidateSet("true", "false")][string]$fullScreen="false",
  [string]$VM=""
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

$soft=$XmlDocument | Select-Xml -XPath "/Settings/Proto/RDP/app" | ForEach-Object { $_.Node.value }
if ($soft -eq $null){
  $softPath="C:\Windows\System32\mstsc.exe"
} else {
  $softPath="$($scriptPath)\$($XmlDocument | Select-Xml -XPath "/Settings/App/$($soft)/path" | ForEach-Object { $_.Node.value })"
  $multipleOpeningTimeout="$($XmlDocument | Select-Xml -XPath "/Settings/App/$($soft)/multipleOpeningTimeout" | ForEach-Object { $_.Node.value })"
  $subSoft="$($XmlDocument | Select-Xml -XPath "/Settings/App/$($soft)/subApp" | ForEach-Object { $_.Node.value })"
}

if($VM -ne ""){
  if($(Get-Service | Where-Object {$_.Name -eq "vmms"}).Status -ne "Running"){
    try{
      Start-Service -Name vmms -ErrorAction Stop
      Write-Host "Waiting for vmms service to startup..."
      sleep 5
    }catch{
      Write-Host "Error while starting vmms service" -ForegroundColor Red
      sleep 5
      exit
    }
  }
  if($(Get-Service | Where-Object {$_.Name -eq "vmcompute"}).Status -ne "Running"){
    try{
      Start-Service -Name vmcompute -ErrorAction Stop
      Write-Host "Waiting for vmcompute service to startup..."
      sleep 5
    }catch{
      Write-Host "Error while starting vmcompoute service" -ForegroundColor Red
      sleep 5
      exit
    }
  }
  #The next block failed since must be launched as Administrator
  try{
    if($(Get-VM -ErrorAction Stop | Where-Object {$_.Name -eq $VM}).State -ne "Running"){
      try{
        Start-VM -Name $VM -ErrorAction Stop | Out-Null
        Write-Host "Waiting for VM to startup..."
        sleep 25
      }catch{
        Write-Host "Error while starting VM $($VM)" -ForegroundColor Red
        sleep 5
        exit
      }
    }
  }catch{
    Write-Host "Error while reading VM status: you are not Administrator: trying anyway!" -ForegroundColor Yellow
  }
}

if($username -eq ""){
  $username=$($XmlDocument | Select-Xml -XPath "/Settings/Proto/RDP/defaultUsername" | ForEach-Object { $_.Node.value })
  if($username -eq $null){
    $username=$($XmlDocument | Select-Xml -XPath "/Settings/General/defaultUsername" | ForEach-Object { $_.Node.value })
  }
}
if($password -eq ""){
  $password=$($XmlDocument | Select-Xml -XPath "/Settings/Proto/RDP/defaultPassword" | ForEach-Object { $_.Node.value })
  if($password -eq $null){
    $password=$($XmlDocument | Select-Xml -XPath "/Settings/General/defaultPassword" | ForEach-Object { $_.Node.value })
  }
}
if($ip -eq ""){
  Throw "You must specify an ip address or a host!"
}
if($port -ne "" -and $port -ne -1){
    $prefPort=":$($port)"
}else{
    if($($config | Where-Object {$_.Proto -eq "RDP"}).defaultPort -eq 3389){
      $prefPort=""
    }else{
      $prefPort=":$($XmlDocument | Select-Xml -XPath "/Settings/Proto/RDP/defaultPort" | ForEach-Object { $_.Node.value })"
    }
}
if($fullScreen -eq "true"){
    $prefFullScreen="/multimon /f"
    write-host "fullScreen has been set"
}else{
    $prefFullScreen=""
}

preventSoftFailure $multipleOpeningTimeout $subSoft $soft

if ($soft -eq $null){
  write-host "cmd /c cmdkey /generic:TERMSRV/$($ip) /user:$($username) /pass:******** && $($softPath) $($prefFullScreen) /v:$($ip)$($prefPort) && timeout /t 0 /nobreak && cmdkey /delete:TERMSRV/$($ip) && exit"
  cmd /c "cmdkey /generic:TERMSRV/$($ip) /user:$($username) /pass:$($password) && $($softPath) $($prefFullScreen) /v:$($ip)$($prefPort) && timeout /t 0 /nobreak && cmdkey /delete:TERMSRV/$($ip) && exit"
}
#not implemented otherwise

if ($debugMode -eq "true"){
  sleep 150
}