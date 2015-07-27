<#
	NOTES
		
	.SYNOPSIS
		Invoke-ImageFactory.ps1 is based upon work of Ben Armstrong for creating up-to-date Windows images.
  
	.DESCRIPTION
		This script is used to create up-to-date sysprepped Windows images which can be used for deployments.

	.LINK
		https://github.com/BenjaminArmstrong/Hyper-V-PowerShell
		https://github.com/peterschen/Hyper-V-PowerShell
#>

[CmdletBinding()]

param
(
);

$Global:SCRIPT_NAME = "Invoke-ImageFactory.ps1";
$Global:SCRIPT_VERSION = "1.0.0.0";
$Global:SCRIPT_CLASSIFICATION = [string]::Format("{0} {1}", $Global:SCRIPT_NAME, $Global:SCRIPT_VERSION);

$startTime = Get-Date;

function Get-Configuration
{
	[CmdletBinding()]

    param
	(
	);

	process
	{
		$sections = @(
			"appSettings"
			"ImageFactory.Images"
		);
		
		$Path = Get-ScriptDirectory;

		$Global:CONFIGURATION = @{};
		$config = [xml](Get-Content "$($Path)\$($Global:SCRIPT_NAME).config");
		
		foreach($section in $sections)
		{
			foreach ($node in $config.configuration.$section.add)
			{
				if($section -eq "appSettings")
				{
					$value = $node.Value;
					$Global:CONFIGURATION[$node.Key] = $value;
				}
				elseif($section -eq "ImageFactory.Images")
				{
					if($null -eq $Global:CONFIGURATION["Images"])
					{
						$Global:CONFIGURATION["Images"] = @();
					}

					$properties = @{
						Name = $node.Name
						Path = $node.Path
						Key = $node.Key
						Edition = $node.Edition
						IsDesktop = $node.IsDesktop
						Is32Bit = $node.Is32Bit
						VmGeneration = $node.VmGeneration
					};

					$Global:CONFIGURATION["Images"] += New-Object PSObject -Property $properties;
				}
			}
		}
	}
}

function Get-ScriptDirectory
{
	[CmdletBinding()]

	param
	(
	);

	process
	{
		$invocation = (Get-Variable MyInvocation -Scope 2).Value;
		return Split-Path $invocation.MyCommand.Path;
	}
}

function CSVLogger
{
	param
	(
		[string] $vhd,
		[switch] $sysprepped
	);

    $csvPath = "$($Global:CONFIGURATION["Share"])\$($Global:CONFIGURATION["CsvFile"])";
	$createLogFile = $false;
	$entryExists = $false;
	$logCsv = @();
	$newEntry = $null;

	# Check if the log file exists
	if (-not (Test-Path $csvPath))
	{
		$createLogFile = $true;
	}
	else
	{
		$logCsv = Import-Csv $csvPath;
		
		if (($logCsv.Image -eq $null) -or ($logCsv.Created -eq $null) -or ($logCsv.Sysprepped -eq $null) -or ($logCsv.Checked -eq $null)) 
		{
			# Something is wrong with the log file
			cleanupFile $csvPath;
			$createLogFile = $true;
		}
	}

	if ($createLogFile)
	{
		$logCsv = @();
	} 
	else 
	{
		$logCsv = Import-Csv $csvPath;
	}

	# If we find an entry for the VHD, update it
	foreach ($entry in $logCsv)
	{
		if ($entry.Image -eq $vhd)
		{
			$entryExists = $true;
			$entry.Checked = ((Get-Date).ToShortDateString() + "::" + (Get-Date).ToShortTimeString());
			
			if ($sysprepped) 
			{
				$entry.Sysprepped = ((Get-Date).ToShortDateString() + "::" + (Get-Date).ToShortTimeString());
			}
		}
	}

	# if no entry is found, create a new one
	if (-not $entryExists) 
	{
		$newEntry = New-Object PSObject -Property @{
			Image = $vhd;
			Created = ((Get-Date).ToShortDateString() + "::" + (Get-Date).ToShortTimeString());
			Sysprepped = ((Get-Date).ToShortDateString() + "::" + (Get-Date).ToShortTimeString());
			Checked = ((Get-Date).ToShortDateString() + "::" + (Get-Date).ToShortTimeString());
		};
	}

	# Write out the CSV file
	$logCsv | Export-CSV $csvPath -NoTypeInformation;
	if (-not ($newEntry -eq $null)) 
	{
		$newEntry | Export-CSV $csvPath -NoTypeInformation -Append;
	}
}

function Logger
{
	param
	(
		[string] $systemName,
		[string] $message
	);

	# Function for displaying formatted log messages.  Also displays time in minutes since the script was started
	Write-Host (Get-Date).ToShortTimeString() -ForegroundColor Cyan -NoNewline;
	Write-Host " - [" -ForegroundColor White -NoNewline;
	Write-Host $systemName -ForegroundColor Yellow -NoNewline;
	Write-Host "] $($message)" -ForegroundColor White;
}

# Helper function for no error file cleanup
function cleanupFile
{
	param
	(
		[string] $file
	);

	if (Test-Path $file)
	{
		Remove-Item $file;
	}
}

function GetUnattendChunk 
{
	param
	(
		[string] $pass,
		[string] $component,
		[xml] $unattend
	);

	# Helper function that returns one component chunk from the Unattend XML data structure
	return $Unattend.unattend.settings | ? pass -eq $pass `
		| select -ExpandProperty component `
		| ? name -eq $component;
}

# Composes unattend file and writes it to the specified filepath
function makeUnattendFile
{
	param
	(
		[string] $key,
		[string] $logonCount,
		[string] $filePath,
		[bool] $desktop = $false,
		[bool] $is32bit = $false
	);		
     
	# Reload template - clone is necessary as PowerShell thinks this is a "complex" object
	$unattend = $unattendSource.Clone()
     
	# Customize unattend XML
	GetUnattendChunk "specialize" "Microsoft-Windows-Shell-Setup" $unattend | % {$_.ProductKey = $key};
	GetUnattendChunk "specialize" "Microsoft-Windows-Shell-Setup" $unattend | % {$_.RegisteredOrganization = $Global:CONFIGURATION["Organization"]};
	GetUnattendChunk "specialize" "Microsoft-Windows-Shell-Setup" $unattend | % {$_.RegisteredOwner = $Global:CONFIGURATION["Owner"]};
	GetUnattendChunk "specialize" "Microsoft-Windows-Shell-Setup" $unattend | % {$_.TimeZone = $Global:CONFIGURATION["Timezone"]};
	GetUnattendChunk "oobeSystem" "Microsoft-Windows-Shell-Setup" $unattend | % {$_.UserAccounts.AdministratorPassword.Value = $Global:CONFIGURATION["AdminPassword"]};
	GetUnattendChunk "oobeSystem" "Microsoft-Windows-Shell-Setup" $unattend | % {$_.AutoLogon.Password.Value = $Global:CONFIGURATION["AdminPassword"]};
	GetUnattendChunk "oobeSystem" "Microsoft-Windows-Shell-Setup" $unattend | % {$_.AutoLogon.LogonCount = $logonCount};
	
	if ($desktop)
	{
		GetUnattendChunk "oobeSystem" "Microsoft-Windows-Shell-Setup" $unattend | % {$_.UserAccounts.LocalAccounts.LocalAccount.Password.Value = $Global:CONFIGURATION["UserPassword"]};
	}
	else
	{
		# Desktop needs a user other than "Administrator" to be present
		# This will remove the creation of the other user for server images
		$ns = New-Object System.Xml.XmlNamespaceManager($unattend.NameTable);
		$ns.AddNamespace("ns", $unattend.DocumentElement.NamespaceURI);
		$node = $unattend.SelectSingleNode("//ns:LocalAccounts", $ns);
		$node.ParentNode.RemoveChild($node) | Out-Null;
	}
     
	if ($is32bit)
	{
		$unattend.InnerXml = $unattend.InnerXml.Replace('processorArchitecture="amd64"', 'processorArchitecture="x86"');
	}

	# Write it out to disk
	cleanupFile $filePath;
	$unattend.Save($filePath);
}

function createRunAndWaitVM
{
	param
	(
		[string] $vhd,
		[string] $gen
	);

	# Function for whenever I have a VHD that is ready to run
	New-VM $Global:CONFIGURATION["VirtualMachineName"] -MemoryStartupBytes 4096mb -VHDPath $vhd -Generation $Gen -SwitchName $Global:CONFIGURATION["VirtualSwitchName"] | Out-Null;
	Set-VM -Name $Global:CONFIGURATION["VirtualMachineName"] -ProcessorCount 4;
	Start-VM $Global:CONFIGURATION["VirtualMachineName"];

	# Give the VM a moment to start before we start checking for it to stop
	Start-Sleep -Seconds 10;

	# Wait for the VM to be stopped for a good solid 5 seconds
	do
	{
		$state1 = (Get-VM | ? name -eq $Global:CONFIGURATION["VirtualMachineName"]).State; 
		Start-Sleep -Seconds 5;
		
		$state2 = (Get-VM | ? name -eq $Global:CONFIGURATION["VirtualMachineName"]).State;
		Start-Sleep -Seconds 5
	} 
	until (($state1 -eq "Off") -and ($state2 -eq "Off"))

	# Clean up the VM
	Remove-VM $Global:CONFIGURATION["VirtualMachineName"] -Force
}

function MountVHDandRunBlock 
{
	param
	(
		[string]$vhd,
		[ScriptBlock]$block
	); 

	# This function mounts a VHD, runs a script block and unmounts the VHD.
	# Drive letter of the mounted VHD is stored in $driveLetter - can be used by script blocks
	$driveLetter = (Mount-VHD $vhd -Passthru | Get-Disk | Get-Partition | Get-Volume).DriveLetter;
	&$block;
	Dismount-VHD $vhd;

	# Wait 2 seconds for activity to clean up
	Start-Sleep -Seconds 2;
}

function Test-Resource
{
	param
	(
		[string] $Path,
		[string] $System = $null
	);

	if(-not (Test-Path -Path $Path))
	{
		if($null -eq $System)
		{
			$System = $Global:SCRIPT_CLASSIFICATION;
		}

		Logger $System "Resource '$($Path)' could not be found";
		exit;
	}
}

function Test-VirtualSwitch
{
	[CmdletBinding()]

	param
	(
		[string] $Name
	);

	process
	{
		$switch = Get-VMSwitch -Name $Name -ErrorAction SilentlyContinue;

		if($null -eq $switch)
		{
			Logger $Global:SCRIPT_CLASSIFICATION "Could not find virtual switch '$($Name)'";
			exit;
		}
	}
}

# Load configuration
Get-Configuration;

# Update globals
$Global:DIRECTORY_ROOT = $Global:CONFIGURATION["RootDirectory"];
$Global:DIRECTORY_WORKING = "$($Global:DIRECTORY_ROOT)\$($Global:CONFIGURATION["WorkingDirectory"])";
$Global:DIRECTORY_BASES = "$($Global:DIRECTORY_ROOT)\$($Global:CONFIGURATION["BasesDirectory"])";
$Global:DIRECTORY_RESOURCES = "$($Global:DIRECTORY_ROOT)\$($Global:CONFIGURATION["ResourcesDirectory"])";
$Global:DIRECTORY_SHARE = "$($Global:DIRECTORY_ROOT)\$($Global:CONFIGURATION["ShareDirectory"])";

### Test resources
Test-Resource -Path "$($Global:DIRECTORY_RESOURCES)\Convert-WindowsImage.ps1";
Test-VirtualSwitch -Name $Global:CONFIGURATION["VirtualSwitchName"];

### Load Convert-WindowsImage
. "$($Global:DIRECTORY_RESOURCES)\Convert-WindowsImage.ps1";

### Sysprep unattend XML
$unattendSource = [xml]@"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <servicing></servicing>
    <settings pass="specialize">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <ComputerName>*</ComputerName>
            <ProductKey>Key</ProductKey> 
            <RegisteredOrganization>Organization</RegisteredOrganization>
            <RegisteredOwner>Owner</RegisteredOwner>
            <TimeZone>TZ</TimeZone>
        </component>
        <component name="Microsoft-Windows-TerminalServices-LocalSessionManager" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"> 
             <fDenyTSConnections>false</fDenyTSConnections> 
         </component> 
         <component name="Microsoft-Windows-TerminalServices-RDP-WinStationExtensions" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"> 
             <UserAuthentication>0</UserAuthentication> 
         </component> 
         <component name="Networking-MPSSVC-Svc" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"> 
             <FirewallGroups> 
                 <FirewallGroup wcm:action="add" wcm:keyValue="RemoteDesktop"> 
                     <Active>true</Active> 
                     <Profile>all</Profile> 
                     <Group>@FirewallAPI.dll,-28752</Group> 
                 </FirewallGroup> 
             </FirewallGroups> 
         </component> 
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
                <HideLocalAccountScreen>true</HideLocalAccountScreen>
                <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                <NetworkLocation>Work</NetworkLocation>
                <ProtectYourPC>1</ProtectYourPC>
            </OOBE>
            <UserAccounts>
                <AdministratorPassword>
                    <Value>password</Value>
                    <PlainText>True</PlainText>
                </AdministratorPassword>
                <LocalAccounts>
                   <LocalAccount wcm:action="add">
                       <Password>
                           <Value>password</Value>
                           <PlainText>True</PlainText>
                       </Password>
                       <DisplayName>Demo</DisplayName>
                       <Group>Administrators</Group>
                       <Name>demo</Name>
                   </LocalAccount>
               </LocalAccounts>
            </UserAccounts>
            <AutoLogon>
               <Password>
                  <Value>password</Value>
               </Password>
               <Enabled>true</Enabled>
               <LogonCount>1000</LogonCount>
               <Username>Administrator</Username>
            </AutoLogon>
             <LogonCommands> 
                 <AsynchronousCommand wcm:action="add"> 
                     <CommandLine>%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell -NoLogo -NonInteractive -ExecutionPolicy Unrestricted -File %SystemDrive%\Bits\Logon.ps1</CommandLine> 
                     <Order>1</Order> 
                 </AsynchronousCommand> 
             </LogonCommands> 
        </component>
        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <InputLocale>de-de</InputLocale>
            <SystemLocale>de-de</SystemLocale>
            <UILanguage>en-us</UILanguage>
            <UILanguageFallback>en-us</UILanguageFallback>
            <UserLocale>de-de</UserLocale>
        </component>
    </settings>
</unattend>
"@

### Update script block
$updateCheckScriptBlock = {
	# Clean up unattend file if it is there
	if (Test-Path "$ENV:SystemDrive\Unattend.xml") 
	{
		Remove-Item -Force "$ENV:SystemDrive\Unattend.xml"
	}
     
	# Check to see if files need to be unblocked - if they do, do it and reboot
	if ((Get-ChildItem $env:SystemDrive\Bits\PSWindowsUpdate | `
        Get-Item -Stream "Zone.Identifier" -ErrorAction SilentlyContinue).Count -gt 0)
	{
		Get-ChildItem $env:SystemDrive\Bits\PSWindowsUpdate  | Unblock-File;
		Invoke-Expression 'shutdown -r -t 0';
	}

	# To get here - the files are unblocked
	import-module $env:SystemDrive\Bits\PSWindowsUpdate\PSWindowsUpdate;

	# Check if any updates are needed - leave a marker if there are
	if ((Get-WUList).Count -gt 0)
	{
		if (-not (Test-Path $env:SystemDrive\Bits\changesMade.txt)) 
	    {
			New-Item $env:SystemDrive\Bits\changesMade.txt -type file
		}
	}
 
	# Apply all the updates
	Get-WUInstall -AcceptAll -IgnoreReboot -IgnoreUserInput -NotCategory "Language packs";

	# Reboot if needed - otherwise shutdown because we are done
	if (Get-WURebootStatus -Silent) 
	{
		Invoke-Expression 'shutdown -r -t 0'
	} 
	else
	{
		Invoke-Expression 'shutdown -s -t 0'
	}
}

### Sysprep script block
$sysprepScriptBlock = {
     # Windows 10 issue - if the tiledatamodelsvc is running, it must be stopped first
     Get-Service | ? name -eq tiledatamodelsvc | Stop-Service;  
         
     $unattendedXmlPath = "$ENV:SystemDrive\Bits\Unattend.xml";
     & "$ENV:SystemRoot\System32\Sysprep\Sysprep.exe" `/generalize `/oobe `/shutdown `/unattend:"$unattendedXmlPath";
}

### Post Sysprep script block
$postSysprepScriptBlock = {
     Remove-Item -Force "$ENV:SystemDrive\Unattend.xml";
     Remove-Item -Force -Recurse "$ENV:SystemDrive\Bits";
     Remove-Item -Force "$ENV:SystemDrive\Convert-WindowsImageInfo.txt";

     # Put any code you want to run Post sysprep here
     Restart-Computer -Force;
}

# This is the main function of this script
function RunTheFactory
{ 
	param
	(
		[string]$FriendlyName,
        [string]$ISOFile,
        [string]$ProductKey,
        [string]$SKUEdition,
        [bool]$desktop = $false,
        [bool]$is32bit = $false,
        [switch]$Generation2
	);

	logger $FriendlyName "Starting a new cycle!";

	# Test if resource exists
	Test-Resource -Path $ISOFile -System $FriendlyName;

	# Setup a bunch of variables 
	$sysprepNeeded = $true
	$baseVHD = "$($Global:DIRECTORY_BASES)\$($FriendlyName)-base.vhdx"
	$updateVHD = "$($Global:DIRECTORY_WORKING)\$($FriendlyName)-update.vhdx"
	$sysprepVHD = "$($Global:DIRECTORY_WORKING)\$($FriendlyName)-sysprep.vhdx"
	$finalVHD = "$($Global:DIRECTORY_SHARE)\$($FriendlyName).vhdx"
	
	if ($Generation2) 
	{
		$VHDPartitionStyle = "GPT"; 
		$Gen = 2;
	} 
	else 
	{
		$VHDPartitionStyle = "MBR";
		$Gen = 1;
	} 

	logger $FriendlyName "Checking for existing Factory VM";

	# Check if there is already a factory VM - and kill it if there is
	if ((Get-VM | ? name -eq $Global:CONFIGURATION["VirtualMachineName"]).Count -gt 0)
	{
		Stop-VM $Global:CONFIGURATION["VirtualMachineName"] -TurnOff -Confirm:$false -Passthru | Remove-VM -Force
	}

	# Check for a base VHD
	if (-not (Test-Path $baseVHD)) 
	{
		# No base VHD - we need to create one
		logger $FriendlyName "No base VHD!";

		# Make unattend file
		logger $FriendlyName "Creating unattend file for base VHD";

		# Logon count is just "large number"
		makeUnattendFile -key $ProductKey -logonCount "1000" -filePath "$($Global:DIRECTORY_WORKING)\unattend.xml" -desktop $desktop -is32bit $is32bit;
      
		# Time to create the base VHD
		logger $FriendlyName "Create base VHD using Convert-WindowsImage.ps1";
		$ConvertCommand = "Convert-WindowsImage";
		$ConvertCommand = $ConvertCommand + " -SourcePath `"$ISOFile`" -VHDPath `"$baseVHD`"";
		$ConvertCommand = $ConvertCommand + " -SizeBytes 80GB -VHDFormat VHDX -UnattendPath `"$($Global:DIRECTORY_WORKING)\unattend.xml`"";
		$ConvertCommand = $ConvertCommand + " -Edition $SKUEdition -VHDPartitionStyle $VHDPartitionStyle";

		Invoke-Expression "& $ConvertCommand";

		# Clean up unattend file - we don't need it any more
		logger $FriendlyName "Remove unattend file now that that is done";
		cleanupFile "$($Global:DIRECTORY_WORKING)\unattend.xml";

		logger $FriendlyName "Mount VHD and copy bits in, also set startup file";
		MountVHDandRunBlock $baseVHD {
			# Copy ResourceDirectory in
			Copy-Item "$Global:DIRECTORY_RESOURCES\Bits" -Destination ($driveLetter + ":\") -Recurse;

			# Create first logon script
			$updateCheckScriptBlock | Out-String | Out-File -FilePath "$($driveLetter):\Bits\Logon.ps1" -Width 4096;
		};

		logger $FriendlyName "Create virtual machine, start it and wait for it to stop...";
		createRunAndWaitVM $baseVHD $Gen;

		# Remove Page file
		logger $FriendlyName "Removing the page file";
		MountVHDandRunBlock $baseVHD {
			attrib -s -h "$($driveLetter):\pagefile.sys";
			cleanupFile "$($driveLetter):\pagefile.sys";
		};

		# Compact the base file
		logger $FriendlyName "Compacting the base file";
		Optimize-VHD -Path $baseVHD -Mode Full;
	}
	else
	{
		# The base VHD existed - time to check if it needs an update
		logger $FriendlyName "Base VHD exists - need to check for updates";

		# create new diff to check for updates
		logger $FriendlyName "Create new differencing disk to check for updates";
		cleanupFile $updateVHD; new-vhd -Path $updateVHD -ParentPath $baseVHD | Out-Null;

		logger $FriendlyName "Copy login file for update check, also make sure flag file is cleared";
		MountVHDandRunBlock $updateVHD {
			# Make the UpdateCheck script the logon script, make sure update flag file is deleted before we start
			cleanupFile "$($driveLetter):\Bits\changesMade.txt";
			cleanupFile "$($driveLetter):\Bits\Logon.ps1";
			$updateCheckScriptBlock | Out-String | Out-File -FilePath "$($driveLetter):\Bits\Logon.ps1" -Width 4096;
		};

		logger $FriendlyName "Create virtual machine, start it and wait for it to stop...";
		createRunAndWaitVM $updateVHD $Gen;

		# Mount the VHD
		logger $FriendlyName "Mount the differencing disk";
		$driveLetter = (Mount-VHD $updateVHD -Passthru | Get-Disk | Get-Partition | Get-Volume).DriveLetter;
       
		# Check to see if changes were made
		logger $FriendlyName "Check to see if there were any updates";
		if (Test-Path "$($driveLetter):\Bits\changesMade.txt") 
		{
			cleanupFile "$($driveLetter):\Bits\changesMade.txt"; 
			logger $FriendlyName "Updates were found";
		}
		else 
		{
			logger $FriendlyName "No updates were found";
			$sysprepNeeded = $false;
		}

		# Dismount
		logger $FriendlyName "Dismount the differencing disk";
		Dismount-VHD $updateVHD;

		# Wait 2 seconds for activity to clean up
		Start-Sleep -Seconds 2;

		# If changes were made - merge them in.  If not, throw it away
		if ($sysprepNeeded) 
		{
			logger $FriendlyName "Merge the differencing disk"; 
			Merge-VHD -Path $updateVHD -DestinationPath $baseVHD
		}
		else 
		{
			logger $FriendlyName "Delete the differencing disk"; 
			CSVLogger $finalVHD; 
			cleanupFile $updateVHD;
		}
	}

	# Final Check - if the final VHD is missing - we need to sysprep and make it
	if (-not (Test-Path $finalVHD)) 
	{
		$sysprepNeeded = $true;
	}

	if ($sysprepNeeded)
	{
		# create new diff to sysprep
		logger $FriendlyName "Need to run Sysprep";
		logger $FriendlyName "Creating differencing disk";
		cleanupFile $sysprepVHD;
        New-VHD -Path $sysprepVHD -ParentPath $baseVHD | Out-Null;

		logger $FriendlyName "Mount the differencing disk and copy in files";
		MountVHDandRunBlock $sysprepVHD {
			# Make unattend file
			makeUnattendFile -key $ProductKey -logonCount "1" -filePath "$($driveLetter):\Bits\unattend.xml" -desktop $desktop -is32bit $is32bit;
			
			# Make the logon script
			cleanupFile "$($driveLetter):\Bits\Logon.ps1";
			$sysprepScriptBlock | Out-String | Out-File -FilePath "$($driveLetter):\Bits\Logon.ps1" -Width 4096;
		};

		logger $FriendlyName "Create virtual machine, start it and wait for it to stop...";
		createRunAndWaitVM $sysprepVHD $Gen;

		logger $FriendlyName "Mount the differencing disk and cleanup files";
		MountVHDandRunBlock $sysprepVHD {
			cleanupFile "$($driveLetter):\Bits\unattend.xml";

			# Make the logon script
			cleanupFile "$($driveLetter):\Bits\Logon.ps1";
			$postSysprepScriptBlock | Out-String | Out-File -FilePath "$($driveLetter):\Bits\Logon.ps1" -Width 4096;
		};

		# Remove Page file
		logger $FriendlyName "Removing the page file";
		MountVHDandRunBlock $sysprepVHD {
			attrib -s -h "$($driveLetter):\pagefile.sys";
			cleanupFile "$($driveLetter):\pagefile.sys";
		}

		# Produce the final disk
		cleanupFile $finalVHD;
		logger $FriendlyName "Convert differencing disk into pristine base image";
		Convert-VHD -Path $sysprepVHD -DestinationPath $finalVHD -VHDType Dynamic;
		logger $FriendlyName "Delete differencing disk";
		CSVLogger $finalVHD -sysprepped;
		cleanupFile $sysprepVHD;
	}
}

try
{
	# Main processing loop

	foreach($image in $Global:CONFIGURATION["Images"])
	{
		$isDesktop = [bool]::Parse($image.IsDesktop);
		$is32Bit = [bool]::Parse($image.Is32Bit);

		if($image.VmGeneration -eq 2)
		{
			RunTheFactory -FriendlyName $image.Name -ISOFile $image.Path -ProductKey $image.Key -SKUEdition $image.Edition -desktop $isDesktop -is32bit $is32Bit -Generation2;
		}
		else
		{
			RunTheFactory -FriendlyName $image.Name -ISOFile $image.Path -ProductKey $image.Key -SKUEdition $image.Edition -desktop $isDesktop -is32bit $is32Bit;
		}
	}
}
catch
{
	Logger $Global:SCRIPT_CLASSIFICATION "An error ocurred: $($_)";
}