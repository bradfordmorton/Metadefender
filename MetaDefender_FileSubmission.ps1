###### FILESCAN SCRIPT FOR METADEFENDER CORE API ######
 
###### Created by Bradford Morton for Department of the Treasury (bradford.morton@treasury.gov.au) ######
###### Available at my github https://github.com/bradfordmorton ######

###### This script is used to submit files to METADEFENDER CORE.  It also authenicates the user to the applicance ######
###### and provides information on the product_id and version running ######

#Prompts for username and password
$Credentials = Get-Credential -Credential $null
$RESTAPIUser = $Credentials.UserName
$Credentials.Password | ConvertFrom-SecureString
$RESTAPIPassword = $Credentials.GetNetworkCredential().password
$BaseURL = "http://" + "x:8008"

$LoginSessionURL = $BaseURL + "/login"

#Sets the username and password parameters
$params = @{
    "@type"="login";
    "user"="$RESTAPIUser";
    "password"="$RESTAPIPassword";
}

#Logins and gets session id
$LoginSession = Invoke-RestMethod -Uri $LoginSessionURL -Method POST -Body ($params|ConvertTo-Json) -ContentType "application/json"
$apikey = $LoginSession.session_id

#Set session id as apikey header
$headers = @{
    "apikey"="$apikey";
}

$GetVersionURL = $BaseURL + "/version"

#Gets version details and prints to screen
$GetVersion = Invoke-RestMethod -Uri $GetVersionURL -Method GET -Headers $headers -ContentType "application/json"
Write-Host("#### METADEFENDER SCAN STARTING #### ") -ForegroundColor Yellow 
Write-Host("Product is: ")  $GetVersion.product_id
Write-Host ("Version is: ") $GetVersion.version

$SubmitFileURL = $BaseURL + "/file"

#Prompts for file submission using Windows dialog box
    $openFileDialog = New-Object windows.forms.openfiledialog   
     $openFileDialog.initialDirectory = [System.IO.Directory]::GetCurrentDirectory()   
     $openFileDialog.title = "Select PublishSettings Configuration File to Import"   
     $openFileDialog.filter = "All files (*.*)| *.*"   
     $openFileDialog.ShowHelp = $True   
     Write-Host "Select Downloaded Settings File... (see FileOpen Dialog)" -ForegroundColor Green  
     $result = $openFileDialog.ShowDialog()   # Display the Dialog / Wait for user response 
     # in ISE you may have to alt-tab or minimize ISE to see dialog box 
     $result 
     if($result -eq "OK")    {    
             Write-Host "Selected Downloaded Settings File:"  -ForegroundColor Green  
             $OpenFileDialog.filename   
             # $OpenFileDialog.CheckFileExists 
             # Import-AzurePublishSettingsFile -PublishSettingsFile $openFileDialog.filename  
             # Unremark the above line if you actually want to perform an import of a publish settings file  
             Write-Host "Import Settings File Imported!" -ForegroundColor Green 
         } 
         else { Write-Host "Import Settings File Cancelled!" -ForegroundColor Yellow}
$filename = $OpenFileDialog.SafeFileName
$filepath = $OpenFileDialog.InitialDirectory + "\"

#Sets the filename and filepath parameters
$hdrs = @{}
$hdrs.Add("filename","$filename")
$hdrs.Add("filepath","$filepath")

#Testing
#$filebody = [System.IO.File]::ReadAllBytes($filepath)
#$enc = [System.Text.Encoding]::GetEncoding("utf-8")
#$filedata = $enc.GetString($filebody)

$FileSubmissionID = Invoke-RestMethod -Uri $SubmitFileURL -Method POST -Headers $hdrs -Body $hdrs

#Submits file and checks progress.  Waits until file is not longer processing before continueing
$RequestResponseURL = $BaseURL + "/file/" + $FileSubmissionID.data_id
$FetchResponseArray = Invoke-RestMethod -Uri $RequestResponseURL -Method GET -ContentType "application/json"
while ($true) {
       if ($FetchResponseArray.scan_results.scan_all_result_a -contains "In Progress"){
              write-host("######Scan in Progress######")
              Start-Sleep -s 2
              $FetchResponseArray = Invoke-RestMethod -Uri $RequestResponseURL -Method GET -ContentType "application/json"
              } else {
              write-host("#######Scan Complete########")
              Break
       }
  }

#Outputs results of scan
write-host("Submission ID: ") $FetchResponseArray.data_id
write-host("Name of file is: ") $FetchResponseArray.file_info.display_name
write-host("SHA1 of file is: ") $FetchResponseArray.file_info.sha1
write-host("Scan starttime is: ") $FetchResponseArray.scan_results.start_time
write-host("File is deemed: ") $FetchResponseArray.scan_results.scan_all_result_a
write-host("File was detected as malicious by this many vendors: ") $FetchResponseArray.scan_results.scan_all_result_i
write-host("Reason file should be blocked: ") $FetchResponseArray.process_info.blocked_reason
write-host("The file should be: ") $FetchResponseArray.process_info.result

#Clears variables
Clear-Variable -name filename
Clear-Variable -name SubmitFileURL
Clear-Variable -name RESTAPIUser
Clear-Variable -name filepath
Clear-Variable -name hdrs
Clear-Variable -name FileSubmissionID
Clear-Variable -name RequestResponseURL
Clear-Variable -name FetchResponseArray
Clear-Variable -name params
Clear-Variable -name LoginSessionURL
Clear-Variable -name RESTAPIPassword
write-host("The sessionID used to perform this scan was: ") $LoginSession.session_id

#Logs out of session
$LogoutSessionURL = $BaseURL + "/logout"
$LogOut = Invoke-RestMethod -Uri $LogoutSessionURL -Method POST -Headers $headers
write-host("You have been logged out: ") $LogOut.response

#Clears remaining variables
Clear-Variable -name BaseURL
Clear-Variable -name LogoutSessionURL
