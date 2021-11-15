$log = "C:\temp\Ruckus\capture.log"
Start-Transcript $log -Verbose

# Queries vSZ controllers using powershell
$UrlBase = "https://VSZIP:7443/api/public";
$apiVer = "v10_0"
$Body = [pscustomobject]@{ 
    username = ''
    password = ''
    $apmac = ''
    timeZoneUtcOffset = "-06:00" #USA/Chicago
}

 $capture = @{
     captureInterface='ETH0'

} |  ConvertTo-Json

$json = $Body | ConvertTo-Json
$session = Invoke-WebRequest -Uri $UrlBase/$apiVer/session  -Method Post -Body $json -ContentType 'application/json' -skipcertificatecheck -SessionVariable websession -ErrorAction Stop 

# Translate Cookie header into useable string
$stringCookie = [string]$session.Headers["Set-Cookie"]
$cookie = $stringCookie.substring(0,($stringCookie.length - 21))

# Add cookie to header
$headers = @{}
$headers.Add("Cookie",$cookie)
Invoke-RestMethod -Uri $UrlBase/$apiVer/session -Method GET -Headers $headers -ContentType 'application/json' -WebSession $websession -Skipcertificatecheck -ErrorAction Stop

# 
Invoke-RestMethod -Uri "$UrlBase/v10_0/aps/$apmac/apPacketCapture/startFileCapture" -Method POST -Headers $headers -Body $capture -ContentType 'application/json'  -WebSession $websession -Skipcertificatecheck

stop-Transcript