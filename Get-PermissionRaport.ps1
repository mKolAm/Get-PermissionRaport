# variables to define
param([String]$siteUrl)

$outputFile = "LibraryPermissions.csv"
#$libraryName = "Shared Library"

# connect to SP online site collection
$credential = Get-Credential 
Connect-PnPOnline -Url $siteUrl -Credentials $credential

# output file name and location
if (Test-Path $outputFile)
{
    Remove-Item $outputFile
}
"List/Library `t Title `t LoginName `t PrincipalType `t Permission `t GivenThrough" | Out-File $outputFile -Append

$library = Get-PnpList -Includes RoleAssignments
# get document library

# get all the users and groups who has access
foreach ($lib in $library)
{
	$roleAssignments = $lib.RoleAssignments
	if($lib.BaseTemplate -eq 100 -or $lib.BaseTemplate -eq 101)
	{
		foreach ($roleAssignment in $roleAssignments)
		{
			Get-PnPProperty -ClientObject $roleAssignment -Property RoleDefinitionBindings, Member

			$loginName = $roleAssignment.Member.LoginName
			$title = $roleAssignment.Member.Title
			$principalType = $roleAssignment.Member.PrincipalType
			$givenThrough = ""
			$permissionLevel = ""
			# loop through permission levels assigned to specific user/group
			foreach ($roleDefinition in $roleAssignment.RoleDefinitionBindings){
				$PermissionLevel += $RoleDefinition.Name + ";"
			}
			$givenThrough = "Given directly"
			"$($lib.Title) `t $($title) `t $($loginName) `t $($principalType) `t $($permissionLevel) `t $($givenThrough)" | Out-File $outputFile -Append

			# if principal is SharePoint group -> get SharePoint group members
			if ($roleAssignment.Member.PrincipalType.ToString() -eq "SharePointGroup")
			{
				$givenThrough = $roleAssignment.Member.Title.ToString()

				$groupMembers = Get-PnpGroupMembers -Identity $roleAssignment.Member.LoginName
				foreach ($member in $groupMembers)
				{
					"$($lib.Title) `t $($member.Title) `t $($member.LoginName) `t $($member.PrincipalType) `t $($permissionLevel) `t $($title)" | Out-File $outputFile -Append
				}
			}
		}
	}
}