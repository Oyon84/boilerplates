# Install BinaryPasswordGenerator/1.0.3 before using this function
# This script is meant to be used interactively

<#
.DESCRIPTION
This function is primarly created to be run interactivly, it requires you to connect to Microsoft Graph using 
Connect-MgGraph -Scopes "User.ReadWrite.All"
It also requires the module BinaryPasswordGenerator (https://www.powershellgallery.com/packages/BinaryPasswordGenerator/1.0.3)
#>

function New-EntraUser {
    param (
        [Parameter(Mandatory = $true)]
        [string]$GivenName,
        [Parameter(Mandatory = $true)]
        [string]$SurName,
        [Parameter(Mandatory = $false)]
        #Change values to your own domains
        [ValidateSet("cloudidentity.se", "replacethiswithyourdomains.abc", "yourcompanydomain.xyz", "thiswasjustfortesting.net")]
        $Domain

    )
    # Thanks to https://www.github.com/Ehmiiz for a awesome password module
    if (-not (Get-Module BinaryPasswordGenerator -ListAvailable)) {
        Write-Error "Module 'binarypasswordgenertor' is needed for this function to work" -ErrorAction Stop
    }

    # Thanks to https://www.github.com/mamapi for this function
    function Remove-DiacriticChars {
        param ([String]$srcString = [String]::Empty)
        $normalized = $srcString.Normalize( [Text.NormalizationForm]::FormD )
        $sb = new-object Text.StringBuilder
        $normalized.ToCharArray() | Foreach-Object { 
            if ( [Globalization.CharUnicodeInfo]::GetUnicodeCategory($_) -ne [Globalization.UnicodeCategory]::NonSpacingMark) {
                [void]$sb.Append($_)
            }
        }
        $sb.ToString()
    }
    # If $Domain is null or empty it will check the environments default domain and use it.
    if ([string]::IsNullOrEmpty($Domain)) {
        $pd = Get-MgDomain | Where-Object { $_.IsDefault -eq 'True' }
        $userdomain = $pd.Id
    }
    else {
        $userdomain = $Domain
    }
    
    $MailName = Remove-DiacriticChars -srcString "$($GivenName).$($SurName)"

    $Password = New-Password -Length 16
    $PasswordProfile = @{
        Password                      = "$($password)"
        ForceChangePasswordNextSignIn = $true
    }
    # Define user parameters
    $userParams = @{
        GivenName         = "$($GivenName)"
        Surname           = "$($SurName)"
        DisplayName       = "$($GivenName) $($SurName)"
        PasswordProfile   = $PasswordProfile
        AccountEnabled    = $true
        MailNickname      = $MailName
        UserPrincipalName = "$($MailName)@$($userdomain)"
    }
    # Creating the new user
    $counter = 0
    $checkupn = get-mguser -search "userprincipalname:$($userparams.UserPrincipalName)" -ConsistencyLevel eventual
    if ([string]::IsNullOrEmpty($checkupn)) {
        try {
            New-MgUser @userParams -ErrorAction Stop
            Write-Output "--------- `nCreated user with username: `n$($userParams.UserPrincipalName) `nWith password: `n$Password `n---------"
        }
        catch {
            Write-Error "Failed to create user" 
        }
    }
    else {
        try {
            while ($null -ne $checkupn) {
                $counter++
                $countername = $MailName+$counter
                $userParams["MailNickname"] = $countername
                $userParams["UserPrincipalName"] = "$($countername)@$($userdomain)"
                $checkupn = get-mguser -search "userprincipalname:$($userparams.UserPrincipalName)" -ConsistencyLevel eventual
            }
            New-MgUser @userParams -ErrorAction Stop
            Write-Output "--------- `nCreated user with username: `n$($userParams.UserPrincipalName) `nWith password: `n$Password `n---------"
        }
        catch {
            Write-Error "Failed to create user"
        }
    }
}
