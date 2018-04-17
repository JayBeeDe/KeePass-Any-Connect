Param(
  [string]$ip1,
  [string]$ip2,
  [string]$port1,
  [string]$port2,
  [string]$username1,
  [string]$username2,
  [string]$password1,
  [string]$password2,
  [string]$tunnelPort,
  [string]$mode="ssh",
  [string]$multiTunnelsArgs
)

$scriptPath=$(split-path -parent $MyInvocation.MyCommand.Definition)
$plinkPath="$scriptPath\..\Software\Putty\plink.exe"
$defaultPort=22
$defaultUsername="root"
$defaultPassword="YourPasswordHere"
$minTunnelPort=20000
$maxTunnelPort=50000

$global:currentScript=$MyInvocation.MyCommand.Name
$global:currentLocation=Split-Path -Path $MyInvocation.MyCommand.Path
trap {sleep 1}

function Get-RandomPort(){
  try{
      $moduleName="Get-NetworkStatistics.ps1"
      Unblock-File -Path "$($global:currentLocation)\modules\$($moduleName)" -ErrorAction Stop
      Import-Module "$($global:currentLocation)\modules\$($moduleName)" -Force -ErrorAction Stop -Scope Local
      do{
          $portUsed=$false
          $tunnelPort=Get-Random -Minimum $minTunnelPort -Maximum $maxTunnelPort
          foreach ($usedPort in Get-NetworkStatistics | Select LocalPort) {
              if ($usedPort.LocalPort -eq $tunnelPort){
                  $portUsed=$true
                  break
              }
          }
      } while($portUsed -eq $true)
      #cls
      return $tunnelPort
  }catch{
      Throw "An error has occured while loading the powershell module $($moduleName)!"
  }
}

$multiTunnelsArgs=$multiTunnelsArgs.Replace("`r","")
$multiTunnelsArgs=$multiTunnelsArgs.Replace("`n","")

if($multiTunnelsArgs -ne ""){
  $arrConnObj=@()
  $arr=$multiTunnelsArgs -split "-"
  $arr | foreach {
    if ($_ -ne ""){
      Write-Host $_
      write-Host "lol"
      $curSubArr=$_ -Replace "^(.*)(//)(.*)$",'$3' -split "_"
      Write-Host $curSubArr
      write-Host "lol"
      if($curSubArr[0] -eq ""){
          Throw "At least an IP must be set for the tunnel $($arr.IndexOf($_)+1)"
      }
      $connObj=New-Object PSCustomObject
      if($curSubArr[0] -eq ""){
        Throw "You must provide the ip address for each tunnel!"
      }else{
        $connObj | Add-Member -type NoteProperty -name url -Value $curSubArr[0]
      }
      if($($curSubArr[1] -replace "[\s|\n|\r]",'') -eq "" -or $curSubArr[1] -eq -1){
        $connObj | Add-Member -type NoteProperty -name port -Value $defaultPort
      }else{
        $connObj | Add-Member -type NoteProperty -name port -Value $curSubArr[1]
      }
      if($($curSubArr[2] -replace "[\s|\n|\r]",'') -eq ""){
        $connObj | Add-Member -type NoteProperty -name username -Value $defaultUsername
      }else{
        $connObj | Add-Member -type NoteProperty -name username -Value $curSubArr[2]
      }
      if($($curSubArr[3] -replace "[\s|\n|\r]",'') -eq ""){
        $connObj | Add-Member -type NoteProperty -name password -Value $defaultPassword
      }else{
        $connObj | Add-Member -type NoteProperty -name password -Value $curSubArr[3]
      }
      $arrConnObj+=$connObj
    }
  }
  Write-Host ($arrConnObj | Format-Table | Out-String)
  $arrConnObj=$arrConnObj | sort -Descending
  Write-Host ($arrConnObj | Format-Table | Out-String)
  sleep 10
  if ($($arrConnObj.Length) -lt 2){
    Throw "You must provide at least two connections in order to establish a tunnel!"
  }

  For ($i=0; $i -lt $($arrConnObj.Length-1); $i++) {
    $currConnObj=$arrConnObj[$i]
    $nextConnObj=$arrConnObj[$i+1]
    $previousTunnel=$tunnelPort
    $tunnelPort=Get-RandomPort
    write-Host "Establishing tunnel $($i+1) on local port $($tunnelPort)..." -ForegroundColor "Yellow"

    if ($previousTunnel -eq ""){
      Write-Host "$($plinkPath) -ssh $($currConnObj.url) -P $($currConnObj.port) -l $($currConnObj.username) -pw $($currConnObj.password) -C -T -L $($tunnelPort):$($nextConnObj.url):$($nextConnObj.port) -N"
      Start-Process -FilePath $($plinkPath) -ArgumentList "-ssh $($currConnObj.url) -P $($currConnObj.port) -l $($currConnObj.username) -pw $($currConnObj.password) -C -T -L $($tunnelPort):$($nextConnObj.url):$($nextConnObj.port) -N" -WindowStyle Minimized
    }else{
      Start-Process -FilePath $($plinkPath) -ArgumentList "-ssh localhost -P $($previousTunnel) -l $($currConnObj.username) -pw $($currConnObj.password) -C -T -L $($tunnelPort):$($nextConnObj.url):$($nextConnObj.port) -N" -WindowStyle Minimized
    }
    sleep 10
  }
  $lastConnObj=$arrConnObj[-1]

  if($mode -eq "scp"){
    Write-Host "&$($global:currentLocation)\Set-SCP.ps1 -ip localhost -username $($lastConnObj.username) -password $($lastConnObj.password) -port $($tunnelPort)"
    &"$($global:currentLocation)\Set-SCP.ps1" -ip "localhost" -username "$($lastConnObj.username)" -password "$($lastConnObj.password)" -port "$($tunnelPort)"
    #Start-Process -FilePath $($winSCPPath) -ArgumentList "scp://$($lastConnObj.username):$($lastConnObj.password)@localhost:$($tunnelPort)" -WindowStyle Maximized
  }elseif($mode -eq "vnc"){
    Write-Host "&$($global:currentLocation)\Set-VNC.ps1 -ip localhost -password $($lastConnObj.password) -port $($tunnelPort)"
    &"$($global:currentLocation)\Set-VNC.ps1" -ip "localhost" -port "$($tunnelPort)"
    #Start-Process -FilePath .\Set-VNC.ps1 -ip "localhost" -port $($tunnelPort) -password "$($lastConnObj.password)" -WindowStyle Maximized
  }else{
    &"$($global:currentLocation)\Set-SSH.ps1" -ip "localhost" -username "$($lastConnObj.username)" -password "$($lastConnObj.password)" -port "$($tunnelPort)"
    #Start-Process -FilePath $($puttyPath) -ArgumentList "$($specArg2) -ssh $($specArg) localhost -P $($tunnelPort) -l $($lastConnObj.username) -pw $($lastConnObj.password)" -WindowStyle Maximized    
  }

}else{
  $ip1=$ip1.Replace("`r","")
  $ip2=$ip2.Replace("`r","")
  $port1=$port1.Replace("`r","")
  $port2=$port2.Replace("`r","")
  $username1=$username1.Replace("`r","")
  $username2=$username2.Replace("`r","")
  $password1=$password1.Replace("`r","")
  $password2=$password2.Replace("`r","")
  $tunnelPort=$tunnelPort.Replace("`r","")
  if($ip1 -eq ""){
      Throw "The -ip1 argument must be set"
  }
  if($ip2 -eq ""){
      Throw "The -ip2 argument must be set"
  }

  if($port1 -eq ""){
      $port1=$defaultPort
  }
  if($port2 -eq ""){
      $port2=$defaultPort
  }
  if($username1 -eq ""){
      $username1=$defaultUsername
  }
  if($password1 -eq ""){
      $password1=$defaultPassword
  }
  if($username2 -eq ""){
      $username2=$username1
  }
  if($password2 -eq ""){
      $password2=$password1
  }

  if($tunnelPort -eq "" -or $tunnelPort -eq "{S:TunnelPort}"){
      $tunnelPort=Get-RandomPort
  }
  write-Host "Establishing tunnel on local port $($tunnelPort)..." -ForegroundColor "Yellow"
  Start-Process -FilePath $($plinkPath) -ArgumentList "-ssh $($ip1) -P $($port1) -l $($username1) -pw $($password1) -C -T -L $($tunnelPort):$($ip2):$($port2) -N" -WindowStyle Minimized
  sleep 10

  if($mode -eq "scp"){
    &"$($global:currentLocation)\Set-SCP.ps1" -ip "localhost" -username "$($username2)" -password "$($password2)" -port "$($tunnelPort)"
    #Start-Process -FilePath $($winSCPPath) -ArgumentList "scp://$($lastConnObj.username):$($lastConnObj.password)@localhost:$($tunnelPort)" -WindowStyle Maximized
  }elseif($mode -eq "vnc"){
    &"$($global:currentLocation)\Set-VNC.ps1" -ip "localhost" -password "$($password2)" -port "$($tunnelPort)"
    #Start-Process -FilePath .\Set-VNC.ps1 -ip "localhost" -port $($tunnelPort) -password "$($lastConnObj.password)" -WindowStyle Maximized
  }else{
    &"$($global:currentLocation)\Set-SSH.ps1" -ip "localhost" -username "$($username2)" -password "$($password2)" -port "$($tunnelPort)"
    #Start-Process -FilePath $($puttyPath) -ArgumentList "$($specArg2) -ssh $($specArg) localhost -P $($tunnelPort) -l $($lastConnObj.username) -pw $($lastConnObj.password)" -WindowStyle Maximized    
  }
}



sleep 150
