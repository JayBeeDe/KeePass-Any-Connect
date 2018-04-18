Param(
  [string]$ip,
  [int]$port,
  [string]$username,
  [string]$password,
  [Parameter(Mandatory=$false)][ValidateSet("true", "false")][string]$fullScreen="false",
  [string]$VM=""
)

$scriptPath=$(split-path -parent $MyInvocation.MyCommand.Definition)
$config=Import-Clixml "$($scriptPath)\Config.xml"
$softPath=$($config | Where-Object {$_.Proto -eq "RDP"}).Path
if($($config | Where-Object {$_.Proto -eq "RDP"}).PathAbsolute -ne $true){
    $softPath="$scriptPath\$softPath"
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
  $username=$($config | Where-Object {$_.Proto -eq "RDP"}).defaultUsername
}
if($password -eq ""){
  $password=$($config | Where-Object {$_.Proto -eq "RDP"}).defaultPassword
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
      $prefPort=":$($config | Where-Object {$_.Proto -eq "RDP"}).defaultPort"
    }
}
if($fullScreen -eq "true"){
    $prefFullScreen="/multimon /f"
}else{
    $prefFullScreen=""
}

cmd /c "cmdkey /generic:TERMSRV/$($ip) /user:$($username) /pass:$($password) && $($softPath) $($prefFullScreen) /v:$($ip)$($prefPort) && timeout /t 0 /nobreak && cmdkey /delete:TERMSRV/$($ip) && exit"
