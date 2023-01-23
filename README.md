# Invoke-ImageGeneration
    This PowerShell script uses the OpenAI API to generate images of users according to a list of names specified in a CSV file.
    It will generate a new image every second to avoid hitting the API rate limit.
    Dependant on the amount of images you are looking to generate, this script can take a long time to complete.

## Author: 
    Brian Baldock - brian.baldock@microsoft.com

### Requirements: 
    PowerShell
    OpenAI API Key - https://beta.openai.com/docs/developer-quickstart/1-authorization

### EXAMPLE
        . .\Invoke-ImageGeneration.ps1
        Invoke-ImageGeneration -OpenAPIKey "OPENAPI-KEY-HERE" -CSVPath "C:\UserNames.csv" -ProfilePicturePath "C:\ProfilePictures" -LogPath "C:\"

### PARAMETER 
    **ProfilePicturePath**
        Enter the path where the profile pictures will be created
        (Do not include trailing "\" - Example: C: or C:\Test
        Default path is the script directory \ProfilePictures

### PARAMETER 
    **OpenAPIKey**
        Enter your OpenAI API Key, for more information: https://beta.openai.com/docs/developer-quickstart/1-authorization

### PARAMETER
    **CSVPath**
        Enter the path to the CSV file containing the list of persons
        CSV should be formatted in the following way (Genders can be binary or non-binary)
        
        **FirstName,LastName,DisplayName,Gender**
        John,Smith,John Smith,Male
        Jane,Doe,Jane Doe,Female