#================================#
#    PowerGram by @JoelGMSec     #
#      https://darkbyte.net      #
#================================#

# Design
$os = [Environment]::OSVersion.Platform ; if ($os -ne "Unix") {
$Host.UI.RawUI.WindowTitle = "PowerGram - by @JoelGMSec"
$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "White" }
$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"
Set-StrictMode -Off

# Token & ChatID
$token = "" # Talk with @BotFather and create it first
$chatid = "" # Talk with your Bot and send /getid to get it

# Banner
Write-Host
Write-Host "  ____                         ____                      " -ForegroundColor Blue
Write-Host " |  _ \ __ __      __ __ _ __ / ___|_ __ __ _ _ __ ___   " -ForegroundColor Blue
Write-Host " | |_) / _ \ \ /\ / / _ \ '__| |  _| '__/ _' | '_ ' _ \  " -ForegroundColor Blue
Write-Host " |  __/ (_) \ V  V /  __/ |  | |_| | | | (_| | | | | | | " -ForegroundColor Blue
Write-Host " |_|   \___/ \_/\_/ \___|_|   \____|_|  \__,_|_| |_| |_| " -ForegroundColor Blue                                                        
Write-Host
Write-Host "  ------------------- by @JoelGMSec -------------------  " -ForegroundColor Blue

# Help
function Show-Help {
Write-host ; Write-Host " Info: " -ForegroundColor Yellow -NoNewLine ; Write-Host " PowerGram is a pure PowerShell Telegram Bot"
Write-Host "        that can be run on Windows, Linux or Mac OS"
Write-Host ; Write-Host " Usage: " -ForegroundColor Yellow -NoNewLine ; Write-Host "PowerGram from PowerShell" -ForegroundColor Blue 
Write-Host "        .\PowerGram.ps1 -h" -ForegroundColor Green -NoNewLine ; Write-Host " Show this help message" 
Write-Host "        .\PowerGram.ps1 -run" -ForegroundColor Green -NoNewLine ; Write-Host " Start PowerGram Bot"
Write-Host ; Write-Host "        PowerGram from Telegram" -ForegroundColor Blue 
Write-Host "        /getid" -ForegroundColor Green -NoNewLine ; Write-Host " Get your Chat ID from Bot"
Write-Host "        /help" -ForegroundColor Green -NoNewLine ; Write-Host " Show all available commands"
Write-Host ; Write-Host " Warning: " -ForegroundColor Red -NoNewLine  ; Write-Host "All commands will be sent using HTTPS GET requests"
Write-Host "         " -NoNewLine ; Write-Host " You need your Chat ID & Bot Token to run PowerGram" ; Write-Host }

# Proxy Aware
[System.Net.WebRequest]::DefaultWebProxy = [System.Net.WebRequest]::GetSystemWebProxy()
[System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
$AllProtocols = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
[System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols

# Wake On Lan
if ($os -ne "Unix") {
function wakeonlan { Param ([Parameter(ValueFromPipeline)][String[]]$Mac)
$MacByteArray = $Mac -split "[:-]" | ForEach-Object { [Byte] "0x$_"}
[Byte[]] $MagicPacket = (,0xFF * 6) + ($MacByteArray  * 16)
$ip = (Get-WmiObject -Class Win32_NetworkAdapterConfiguration | where {$_.DefaultIPGateway -ne $null}).IPAddress
$ip = $ip | select-object -first 1 ; $ip = $ip.split(".") ; $ip = $ip[0]+"."+$ip[1]+"."+$ip[2]+".255"
$UdpClient = New-Object System.Net.Sockets.UdpClient
$UdpClient.Connect("$ip",7) | Out-Null
$UdpClient.Send($MagicPacket,$MagicPacket.Length) | Out-Null
$UdpClient.Close() | Out-Null }}

# Upload Function
function upload { Param([string]$uploadfile) ; if ($os -ne "Unix") { $slash = "\" } else { $slash = "/" }
$botupdate = Invoke-WebRequest -Uri "https://api.telegram.org/bot$($token)/getUpdates?offset=($offset2)"
$jsonresult = [array]($botupdate | ConvertFrom-Json).result
$documentid = $jsonresult.message.document.file_id | Select-Object -Last 1
$docuname = $jsonresult.message.document.file_name | Select-Object -Last 1
$Uri = "https://api.telegram.org/bot$($token)/getFile"
$Response = Invoke-WebRequest $Uri -Method Post -ContentType 'application/json' -Body "{`"file_id`":`"$documentid`"}"
$jsonpath = [array]($Response | ConvertFrom-Json).result
$uploadpath = $jsonpath.file_path
$Message = "[>] Uploading $docuname.."
$Response = Invoke-WebRequest "https://api.telegram.org/bot$($token)/sendMessage?chat_id=$($id)&text=$($Message)&parse_mode=html"
if ($uploadfile -like "*$slash*") { Invoke-WebRequest "https://api.telegram.org/file/bot$($token)/$uploadpath" -OutFile $uploadfile$slash$docuname }
else { Invoke-WebRequest "https://api.telegram.org/file/bot$($token)/$uploadpath" -OutFile $docuname }}

# Download Function
function download { Param([string]$downloadfile) ; if ($os -ne "Unix") {
if ($downloadfile -like "*.\*") { $downloadfile = $downloadfile.replace(".\","$pwd\") }
if ($downloadfile -notlike "*:\*") { $downloadfile = "$pwd\$downloadfile" }
$filename = ($downloadfile).Split('\')[-1] } ; if ($os -like "Unix") {
if ($downloadfile -notlike "*/*") { $downloadfile = "$pwd/$downloadfile" }
$filename = ($downloadfile).Split('/')[-1] }
$Uri = "https://api.telegram.org/bot$($token)/sendDocument"
$fileBytes = [System.IO.File]::ReadAllBytes($downloadfile)
$fileEncoding = [System.Text.Encoding]::GetEncoding("UTF-8").GetString($fileBytes)
$boundary = [System.Guid]::NewGuid().ToString(); $LF = "`r`n"
$bodyLines = ( "--$boundary","Content-Disposition: form-data; name=`"chat_id`"$LF",
"$chatid$LF","--$boundary","Content-Disposition: form-data; name=`"document`"; filename=`"$filename`"",
"Content-Type: application/octet-stream$LF","$fileEncoding","--$boundary--$LF" ) -join $LF
Invoke-WebRequest $Uri -Method Post -ContentType "multipart/form-data; boundary=`"$boundary`"" -Body $bodyLines }

# Start PowerGram
if ((!$args[0]) -or ($args[0] -like "-h*")) { Show-Help ; exit } ; if (!$token) { Show-Help
Write-Host "`n[!] Token not found! Please check before run PowerGram!`n" -ForegroundColor Red ; exit }
Write-Host "`n[+] Ready! Waiting for new messages..`n" -ForegroundColor Green
$Hostname = ([Environment]::MachineName).ToLower() ; $User = ([Environment]::UserName).tolower()
$Message  = "<b>----------- PowerGram by @JoelGMSec -----------</b>`n"
$Message += "`n[>] New connection from $Hostname\$User"
$Response = Invoke-WebRequest "https://api.telegram.org/bot$($token)/sendMessage?chat_id=$($chatID)&text=$($Message)&parse_mode=html"

# Main Function
while ($true) { $botupdate = Invoke-WebRequest -Uri "https://api.telegram.org/bot$($token)/getUpdates"
$jsonresult = [array]($botupdate | ConvertFrom-Json).result
$messageid = $jsonresult.message.message_id | Select-Object -Last 1
$updateid = $jsonresult.update_id | Select-Object -Last 1
if ($messageid -eq $null) { $messageid = 0 }
$updateid = [int]$updateid++ ; $messageid = [int]$messageid 
do { $botupdate = Invoke-WebRequest -Uri "https://api.telegram.org/bot$($token)/getUpdates?offset=$updateid"
$jsonresult = [array]($botupdate | ConvertFrom-Json).result
$messageid2 = $jsonresult.message.message_id | Select-Object -Last 1
$messageid2 = [int]$messageid2
sleep 1 } until ($messageid -notin $messageid2)

# Event Log
if ($jsonresult.message.document -notin $messageid2) {
$id = $jsonresult.message.from.id | Select-Object -Last 1
$username = $jsonresult.message.from.username | Select-Object -Last 1
$text = $jsonresult.message.text | Select-Object -Last 1
$time = Get-Date -UFormat "%m/%d/%Y %R"
Write-Host "[$time] " -NoNewLine -ForegroundColor Yellow ; Write-Host "`::" -NoNewLine
Write-Host " New message from @$username " -NoNewLine -ForegroundColor Magenta
Write-Host "`::" -NoNewLine ; Write-Host " $text" -ForegroundColor Green }

# Chat Commands
if ($interactive) { if ($id -in $chatid) { 
if ($text -like "/exit*") { $interactive = $null ; $Message = "[>] Interactive Shell Mode is now disabled!"
$Response = Invoke-WebRequest "https://api.telegram.org/bot$($token)/sendMessage?chat_id=$($id)&text=$($Message)&parse_mode=html" }
else { $command = iex $text
$Response = Invoke-WebRequest "https://api.telegram.org/bot$($token)/sendMessage?chat_id=$($id)&text=$($command)&parse_mode=html" }}}
else { if ($text -like "/getid*") { $Message = "Your Chat ID is $id"
$Response = Invoke-WebRequest "https://api.telegram.org/bot$($token)/sendMessage?chat_id=$($id)&text=$($Message)&parse_mode=html" }
if ($text -like "/hi*") { if ($id -in $chatid) { $Message = "Hi @$username :P"
$Response = Invoke-WebRequest "https://api.telegram.org/bot$($token)/sendMessage?chat_id=$($id)&text=$($Message)&parse_mode=html" }}
if ($text -like "/help*") { if ($id -in $chatid) { $Message  = "<b>----------- PowerGram by @JoelGMSec -----------</b>`n"
$Message += "`nAvailable Commands:`n/hi = Say hi to PowerGram Bot`n/help = Show this help message`n/wakeonlan = Send wakeonlan command"
$Message += "`n/shell = Enable Interactive Shell Mode`n/exit = Disable Interactive Shell Mode"
$Message += "`n/upload = Upload file to current folder or specific one`n/download = Download file from current folder or specific one"
$Message += "`n/exec = Execute commands on OS with PowerShell`n/getid = Obtain your Chat ID`n/kill = Kill PowerGram Bot"
$Response = Invoke-WebRequest "https://api.telegram.org/bot$($token)/sendMessage?chat_id=$($id)&text=$($Message)&parse_mode=html" }}
if ($text -like "/wakeonlan*") { if ($id -in $chatid) { $mac = $text.split(" ",2)[1] ; $Message = "[>] Sending WOL to $mac.."
$Response = Invoke-WebRequest "https://api.telegram.org/bot$($token)/sendMessage?chat_id=$($id)&text=$($Message)&parse_mode=html"
$Response = wakeonlan $mac }} 
if ($text -like "/shell*") { if ($id -in $chatid) { $interactive = "True" ; $Message = "[>] Interactive Shell Mode is now enabled!"
$Response = Invoke-WebRequest "https://api.telegram.org/bot$($token)/sendMessage?chat_id=$($id)&text=$($Message)&parse_mode=html" }}
if ($text -like "/upload*") { if ($id -in $chatid) { $document = $text.split(" ",2)[1] ; $Message = "[>] Waiting for file.."
$Response = Invoke-WebRequest "https://api.telegram.org/bot$($token)/sendMessage?chat_id=$($id)&text=$($Message)&parse_mode=html"
$Response = sleep 10 ; upload $document }}
if ($text -like "/download*") { if ($id -in $chatid) { $document = $text.split(" ",2)[1] ; $Message = "[>] Sending $document.."
$Response = Invoke-WebRequest "https://api.telegram.org/bot$($token)/sendMessage?chat_id=$($id)&text=$($Message)&parse_mode=html" 
$Response = download $document }}
if ($text -like "/exec*") { if ($id -in $chatid) { $command = iex $text.split(" ",2)[1]
$Response = Invoke-WebRequest "https://api.telegram.org/bot$($token)/sendMessage?chat_id=$($id)&text=$($command)&parse_mode=html" }}
if ($text -like "/kill*") { if ($id -in $chatid) { $Message = "[>] Killing PowerGram Bot.. Bye!"
$Response = Invoke-WebRequest "https://api.telegram.org/bot$($token)/sendMessage?chat_id=$($id)&text=$($Message)&parse_mode=html" 
Write-Host "`n[!] Killing PowerGram Bot.. Bye!`n" -ForegroundColor Red ; exit }}}}

