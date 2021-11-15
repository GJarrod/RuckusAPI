$log = "C:\temp\Ruckus\reboot.log"
Start-Transcript $log -Verbose

# zero out the counters
$successcount = 0
$failcount = 0
# define the URL (Change VSZIP to IP of the Virtual Smart Zone)
$UrlBase = "https://VSZIP:7443/api/public"
$apiVer = "v10_0"
$Body =@{ 
    username = ''
    password = ''
    timeZoneUtcOffset = "-06:00" #USA/Chicago
}

$json = $Body | ConvertTo-Json
$session = Invoke-WebRequest -Uri $UrlBase/$apiVer/session -skipcertificatecheck -Method Post -Body $json -ContentType 'application/json' -SessionVariable websession -ErrorAction Stop

# Translate Cookie header into useable string
$stringCookie = [string]$session.Headers["Set-Cookie"]
$cookie = $stringCookie.substring(0,($stringCookie.length - 21))

# Add cookie to header
$headers = @{}
$headers.Add("Cookie",$cookie)
Invoke-RestMethod -Uri $UrlBase/$apiVer/session -Method GET -Headers $headers -ContentType 'application/json' -WebSession $websession -Skipcertificatecheck -ErrorAction Stop

#get the list of APs, limited to 350, and pipe it into a foreach

(Invoke-RestMethod -Uri $UrlBase/$apiver/aps?listSize=350 -Method GET -Headers $headers -ContentType 'application/json'  -WebSession $websession -Skipcertificatecheck).list | Foreach-object
    {
        $mac=$_."mac"

        try{    
            #Reboot the AP            
            Invoke-RestMethod -Uri $UrlBase/$apiver/aps/$mac/reboot -Method PUT -Headers $headers -ContentType 'application/json'  -WebSession $websession -Skipcertificatecheck 
            write-host "Rebooting $mac"

            #allow the AP time to reboot before rebooting the next
            start-sleep 40 
            $successcount = $successcount + 1      
            }
        catch {
            $failcount = $failcount + 1
            write-host "Failed to reboot $mac 'r'n"
        }
       
    }



stop-Transcript

#send-mail message with $successcount and $failcount with attached transcript to get an idea for APs that were not rebooted