
#requires -version 2
<#
.SYNOPSIS
  Check for new hosts and create new LocalAdm groups
.DESCRIPTION
  This script collects all computer objects for a OU given and checks for existance of a localadm group for local admin permissions. If no group found
  a new one will be created using the hostname of the computer object.
.PARAMETER <SearchBase>
    OU to start looking for computer objects
.PARAMETER <GroupPath>
    OU path where new groups are created
.INPUTS
  None
.OUTPUTS
  Log file stored in C:\Windows\Temp\LADM_Creation.log
.NOTES
  Version:        1.0
  Author:         Christiaan Verschoor
  Creation Date:  20-11-2023
  Purpose/Change: Initial script development
  
.EXAMPLE
  Create-LocalAdmGroups.ps1 -SearchBase "OU=Tier 1,OU=Computers,OU=Corp,DC=test,DC=local" -GroupPath 'OU=LocalAdm_Tier1,OU=Users,OU=Tier 1,OU=Administration,OU=Corp,DC=test,DC=local'
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

param($SearchBase, $GroupPath)

#Set Error Action to Silently Continue
$ErrorActionPreference = "SilentlyContinue"

#Dot Source required Function Libraries
. "C:\Scripts\Functions\Logging_Functions.ps1"

#----------------------------------------------------------[Declarations]----------------------------------------------------------

#Script Version
$sScriptVersion = "1.0"

#Log File Info
$sLogPath = "C:\Windows\Temp"
$sLogName = "LADM_Creation.log"
$sLogFile = Join-Path -Path $sLogPath -ChildPath $sLogName

#-----------------------------------------------------------[Functions]------------------------------------------------------------

Function Get-ComputerObjects {
  Param($SearchBase, $GroupPath)
  
  Process{
    Try{
      $ComputerObjects = Get-ADComputer -Filter '*' -SearchBase $SearchBase
      return $ComputerObjects
    }
    
    Catch{
      write-host "Error gathering Computer Objects"
      Break
    }
  }
  
  End{
    If($?){
      Log-Write -LogPath $sLogFile -LineValue "Completed Successfully."
      Log-Write -LogPath $sLogFile -LineValue " "
    }
  }
}

Function Check-Groups {
    Param($ComputerName, $GroupPath)
    try {
        Get-ADGroup -Identity "$($ComputerName)_LocalAdm"
    } catch {
        Write-Host "LADM group for $($ComputerName) does not exist"
        Create-Group -Computername $ComputerName -GroupPath $GroupPath
    }
}

Function Create-Group {
    Param($ComputerName, $GroupPath)

    write-host "Creating groups"

    try {
        New-ADGroup -Name $ComputerName -GroupScope Global -GroupCategory Security -Path $GroupPath -Description "Local Admin group for: $($ComputerName)"        
    } catch {
        Write-Host "Failed creating group"
    }

#-----------------------------------------------------------[Execution]------------------------------------------------------------

Write-Host "Checking LADM groups for found computers" -ForegroundColor Green
Write-Host "************************************"
$computers = Get-ComputerObjects -SearchBase $SearchBase

foreach ($computer in $computers) {
    write-host "Found Computer object: $($computer.name)"

    Check-Groups -ComputerName $computer.name -GroupPath $GroupPath
}
