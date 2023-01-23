function Get-TimeStamp {
    <#
        .SYNOPSIS
            Get a time stamp for the log file
        .DESCRIPTION
            Get a time date and time to create a custom time stamp
        .EXAMPLE
            None
        .NOTES
            Internal function
    #>
    return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)
}
function Save-Output {
    <#
        .SYNOPSIS
            Save the output to a log file
        .DESCRIPTION
            Save the output to a log file
        .EXAMPLE
            None
        .NOTES
            Internal function
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True)]
        [String]$LogLocation,
        [string]$LogFile = 'Exec.log', 
        [string]$InputString
    )
    process {
        try {
            $InputString | Out-File -FilePath (Join-Path -Path $LogLocation -ChildPath $LogFile) -Encoding UTF8 -Force -Append -ErrorAction Stop
        }
        catch {
            Write-Output "ERROR: writing to: $(Join-Path -Path $LogLocation -ChildPath $LogFile)"
        }
    }
}
function Invoke-ImageGeneration {
    <#
    .DESCRIPTION
        This PowerShell script will utilize the OpenAI API to generate images of users according to a list of names specified in a CSV file.
        It will generate a new image every second to avoid hitting the API rate limit.
        Dependant on the amount of images you are looking to generate, this script can take a long time to complete.

        The sample scripts are not supported under any Microsoft standard support 
        program or service. The sample scripts are provided AS IS without warranty  
        of any kind. Microsoft further disclaims all implied warranties including,  
        without limitation, any implied warranties of merchantability or of fitness for 
        a particular purpose. The entire risk arising out of the use or performance of  
        the sample scripts and documentation remains with you. In no event shall 
        Microsoft, its authors, or anyone else involved in the creation, production, or 
        delivery of the scripts be liable for any damages whatsoever (including, 
        without limitation, damages for loss of business profits, business interruption, 
        loss of business information, or other pecuniary loss) arising out of the use 
        of or inability to use the sample scripts or documentation, even if Microsoft 
        has been advised of the possibility of such damages.

        Author: Brian Baldock - brian.baldock@microsoft.com

        Requirements: 
            PowerShell
            OpenAI API Key - https://beta.openai.com/docs/developer-quickstart/1-authorization

    .PARAMETER ProfilePicturePath
        Enter the path where the profile pictures will be created
        (Do not include trailing "\" - Example: C: or C:\Test
        Default path is the script directory \ProfilePictures

    .PARAMETER OpenAPIKey
        Enter your OpenAI API Key, for more information: https://beta.openai.com/docs/developer-quickstart/1-authorization

    .PARAMETER CSVPath
        Enter the path to the CSV file containing the list of persons
        CSV should be formatted in the following way (Genders can be binary or non-binary)
        FirstName,LastName,DisplayName,Gender
        John,Smith,John Smith,Male
        Jane,Doe,Jane Doe,Female

    .EXAMPLE
        Invoke-ImageGeneration -OpenAPIKey "OPENAPI-KEY-HERE" -CSVPath "C:\UserNames.csv" -ProfilePicturePath "C:\ProfilePictures" -LogPath "C:\"
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $True,
        HelpMessage = 'Enter your OpenAI API Key')]
        [String]$OpenAPIKey,

        [Parameter(Mandatory = $True,
        HelpMessage = 'Enter the path to the CSV file containing the list of names and genders')]
        [String]$CSVPath,

        [Parameter(Mandatory = $True,
        HelpMessage = 'Enter the path where the profile pictures will be created')]
        [String]$ProfilePicturePath,

        [Parameter(Mandatory = $True,
        HelpMessage = 'Enter the path where the log file will be created')]
        [String]$LogPath
    )

    begin {
        try{
            if($LogPath -eq $null){
                Write-Host -ForegroundColor Red -Object "Please specify a path where the logs will be stored."
                break
            }
            if($OpenAPIKey -eq $null) {
                Write-Host -ForegroundColor Red -Object "OpenAPIKey is null, please enter your OpenAI API Key, for more information:  https://beta.openai.com/docs/developer-quickstart/1-authorization"
                break
            }
            if($CSVPath -eq $null){
                Write-Host -ForegroundColor Red -Object "Please specify the path to the CSV file.`nThe CSV file should be formatted in the following way:`nFirstName,LastName,DisplayName,Gender"
                break
            }
            if($ProfilePicturePath -eq $null){
                Write-Host -ForegroundColor Red -Object "Please specify the path where the profile pictures will be created." 
                break
            }
        }
        catch{
            write-host -ForegroundColor Red -Object "Something happened, $($_.ErrorDetails)"
            break   
        }
    }
    process{
        try{
            $People = Import-CSV -path $CSVPath
            
            $Headers = @{
                'Content-Type'  = 'application/json'
                'Authorization' = "Bearer $($OpenAPIKey)"
            }

            foreach ($Person in $People) {
                if (!(Test-Path "$($ProfilePicturePath)\$($Person.DisplayName).png")) {
                    try{
                        $Age = get-random -Minimum 26 -Maximum 70
                        Start-Sleep -Seconds 1
                        $body = @{
                            prompt          = "A portrait photograph of a $($Person.Gender) human named $($Person.DisplayName) that is $($Age) years old."
                            model           = "image-alpha-001"
                            num_images      = 1
                            size            = "1024x1024"
                            response_format = "url"
                        }
                        
                        Save-Output -LogLocation $LogPath -InputString "$(Get-TimeStamp): INFORMATION: Generating image of $($Person.DisplayName)"
                        $Response = Invoke-RestMethod -Uri 'https://api.openai.com/v1/images/generations' -Method Post -Headers $headers -Body (ConvertTo-Json $body)
                        
                        Save-Output -LogLocation $LogPath -InputString "$(Get-TimeStamp): INFORMATION: Downloading image of $($Person.DisplayName)"
                        $imageUrl = $response.data[0].url
                        try{
                            Invoke-WebRequest -Uri $imageUrl -UseBasicParsing -OutFile "$($ProfilePicturePath)\$($Person.DisplayName).png"
                            if(!(Test-Path "$($ProfilePicturePath)\$($Person.DisplayName).png")) {
                                Write-Host -ForegroundColor Red -Object "Something happened, check log at $($LogPath)\Exec.log"
                                Save-Output -LogLocation $LogPath -InputString "$(Get-TimeStamp): ERROR: Something happened, check log at $($LogPath)\Exec.log"
                                break
                            }
                            else{
                                Save-Output -LogLocation $LogPath -InputString "$(Get-TimeStamp): INFORMATION: Successfully saved image of $($Person.DisplayName)"
                            }
                        }
                        catch{
                            Write-Host -ForegroundColor Red -Object "Something happened, check log at $($LogPath)\Exec.log"
                            Save-Output -LogLocation $LogPath -InputString "$(Get-TimeStamp): ERROR: $($_.ErrorDetails.Message)"
                            break
                        }
                    }
                    catch{
                        Write-Host -ForegroundColor Red -Object "Something happened, check log at $($LogPath)\Exec.log"
                        Save-Output -LogLocation $LogPath -InputString "$(Get-TimeStamp): ERROR: $($_.ErrorDetails.Message)"
                        break
                    }
                }
                else {
                    Write-Host -ForegroundColor Red "Image for $($Person.DisplayName) already exists"
                    Save-Output -LogLocation $LogPath -InputString "$(Get-TimeStamp): ERROR: Image for $($Person.DisplayName) already exists"
                }
            }
        }
        catch{
            Write-Host -ForegroundColor Red -Object "Something happened, check log at $($LogPath)\Exec.log"
            Save-Output -LogLocation $LogPath -InputString "$(Get-TimeStamp): ERROR: $($_.ErrorDetails.Message)"
            break
        }
    }
}