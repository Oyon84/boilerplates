#------------------------------
# Script for checking AD for empty OU's
# Rum without parameter for only a report, run with parameter LIVE to remove empty OU's
# Example: Manage-ADOUs.ps1 LIVE
#------------------------------

Import-Module ActiveDirectory

#-------------------------------
# Parameters
#-------------------------------

$ENV = $args[0]

#-------------------------------
# FIND EMPTY OUs
#-------------------------------

# Get empty AD Organizational Units
$OUs = Get-ADOrganizationalUnit -Filter * | ForEach-Object { If ( !( Get-ADObject -Filter * -SearchBase $_ -SearchScope OneLevel) ) { $_ } } | Select-Object Name, DistinguishedName

#-------------------------------
# REPORTING
#-------------------------------

# Export results to CSV
$OUs | Export-Csv C:\Temp\InactiveOUs.csv -NoTypeInformation

#-------------------------------
# INACTIVE OUs MANAGEMENT
#-------------------------------

# Delete Inactive OUs
ForEach ($Item in $OUs){
  if ($ENV -eq "LIVE") {
    Remove-ADOrganizationalUnit -Identity $Item.DistinguishedName -Confirm:$false
    Write-Output "$($Item.Name) - Deleted" 
  }
}
