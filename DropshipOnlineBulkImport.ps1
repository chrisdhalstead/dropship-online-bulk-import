<#
.SYNOPSIS
Bulk Import Devices into Workspace ONE Dropship Online

.NOTES
  Version:        1.0
  Author:         Chris Halstead - chalstead@vmware.com
  Creation Date:  5/10/2024
  Purpose/Change: Initial script development
  
#>

#----------------------------------------------------------[Declarations]----------------------------------------------------------
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#Define Variables

#-----------------------------------------------------------[Functions]------------------------------------------------------------

Function Write-Log {
  [CmdletBinding()]

     Param (
         [Parameter(
             Mandatory=$true,
             ValueFromPipeline=$true,
             Position=0)]
         [ValidateNotNullorEmpty()]
         [String]$Message,

       [Parameter(Position=1)]
         [ValidateSet("Information","Warning","Error","Debug","Verbose")]
         [String]$Level = 'Information',

         [String]$script:Path = [IO.Path]::GetTempPath()
        
           )

     Process {
         $DateFormat = "%m/%d/%Y %H:%M:%S"

         If (-Not $NoHost) {
           Switch ($Level) {
             "information" {
               Write-Host ("[{0}] {1}" -F (Get-Date -UFormat $DateFormat), $Message)
               Break
             }
             "warning" {
               Write-Warning ("[{0}] {1}" -F (Get-Date -UFormat $DateFormat), $Message)
               Break
             }
             "error" {
               Write-Error ("[{0}] {1}" -F (Get-Date -UFormat $DateFormat), $Message)
               Break
             }
             "debug" {
               Write-Debug ("[{0}] {1}" -F (Get-Date -UFormat $DateFormat), $Message) -Debug:$true
               Break
             }
             "verbose" {
               Write-Verbose ("[{0}] {1}" -F (Get-Date -UFormat $DateFormat), $Message) -Verbose:$true
               Break
             }
           }
         }


        $logDateFormat = "%m_%d_%Y"
        $sdate = Get-Date -UFormat $logDateFormat

        $script:logfilename = "uem-dropship-import-$sdate.log"
       
        Add-Content -Path (Join-Path $Path $logfilename) -Value ("[{0}] ({1}) {2}" -F (Get-Date -UFormat $DateFormat), $Level, $Message)

        
     }
 }


Function ImportDevices() {

  #Bind to the UEM API Server
  $WSOServer = Read-Host -Prompt 'Enter the Workspace ONE UEM API Server Name'
  $oguuid = Read-Host -Prompt 'Enter the UUID of the OG to add devices to'
  $Username = Read-Host -Prompt 'Enter the UEM Username'
  $Password = Read-Host -Prompt 'Enter the UEM Password' -AsSecureString
  $apikey = Read-Host -Prompt 'Enter the UEM API Key'
    
  #Convert the Password
  $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
  $UnsecurePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

  #Base64 Encode UEM Username and Password
  $combined = $Username + ":" + $UnsecurePassword
  $encoding = [System.Text.Encoding]::ASCII.GetBytes($combined)
  $cred = [Convert]::ToBase64String($encoding)

  $header = @{
  "Authorization"  = "Basic $cred";
  "aw-tenant-code" = $apikey;
  "Accept"		 = "application/json;version=3";
  "Content-Type"   = "application/json;version=3";}

  Write-Log "Starting Script" -Level Information
  Write-Log "Log file $script:path$script:logfilename" -Level Information
  Write-Log "Searching $wsoserver" -Level Information

  try {
    
    $sog = Invoke-RestMethod -Method Get -Uri "https://$wsoserver/API/system/groups/$oguuid" -ContentType "application/json" -Header $header
  
  }
  
  catch {
    Write-Log "An error occurred when searching OGs:  $_" -Level "Warning"
    exit
  
  }

  $ogfn = $sog.name

  Write-Log "Selected Organization Group: $ogfn" Information

  $CSV = Import-Csv -Path "$PSScriptRoot\Devices.csv"

foreach($row in $CSV){

  #Assumes Column Header Name of: Serial Number
  $serialnumber = ""
  $serialnumber = $row."Serial Number"

  #Assumes Column Header Name of: Tag Name
  $tagname = ""
  $tagname = $row."Tag Name"

  #Assumes Column Header Name of: Device Friendly Name
  $friendlyname = ""
  $friendlyname = $row."Device Friendly Name"

  #Assumes Column Header Name of: Model Name
  $modelname = ""
  $modelname = $row."Model Name"


  try {
  
$Body = @"
{
  "serial_number":"$serialnumber",
  "tags": [{"name":"$tagname"}],
  "friendly_name":"$friendlyname",
  "organization_group_uuid":"$oguuid",
  "model_number":"$modelname",
  "ownership_type":"CorporateDedicated"
}
"@

$sdevice = Invoke-RestMethod -Method Post -Uri "https://$wsoserver/api/mdm/enrollment-tokens" -ContentType "application/json" -Header $header -Body $Body
  
  }
  
  catch {
    Write-Log "An error occurred when searching OGs:  $_" -Level "Warning"
    exit
  
  }

 Write-Log "Added Device: $sdevice.device_friendly_name" Information

}

#Sync Devices
Write-Log "Syncing with OPS" Information

try {
   
  Invoke-RestMethod -Method Post -Uri "https://$wsoserver/API/mdm/dropship-action/organization-group/$oguuid/sync-devices" -ContentType "application/json" -Header $header
    
    }
    
    catch {
      Write-Log "An error occurred when searching OGs:  $_" -Level "Warning"
      exit
    
    }
  
Write-Log "Sync Completed at: " Information
 
 








}


##########
#Run Code
ImportDevices

