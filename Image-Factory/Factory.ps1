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
            <InputLocale>en-us</InputLocale>
            <SystemLocale>en-us</SystemLocale>
            <UILanguage>en-us</UILanguage>
            <UILanguageFallback>en-us</UILanguageFallback>
            <UserLocale>en-us</UserLocale>
        </component>
    </settings>
</unattend>
"@

function CSVLogger {
    param
    (
        [string] $CsvFile,
		[string] $VhdFile, 
        [switch] $Sysprepped
    );

    $createLogFile = $false;
    $entryExists = $false;
    $logCsv = @();
    $newEntry = $null;

    # Check if the log file exists
    if (-not (Test-Path $CsvFile))
    {
        $createLogFile = $true;
    }
    else
    {
        $logCsv = Import-Csv $CsvFile;

        if (($logCsv.Image -eq $null) -or `
            ($logCsv.Created -eq $null) -or `
            ($logCsv.Sysprepped -eq $null) -or `
            ($logCsv.Checked -eq $null)) 
        {
            # Something is wrong with the log file
            cleanupFile $CsvFile;
            $createLogFile = $true;
        }
    }

    if ($createLogFile)
    {
        $logCsv = @();
    } 
    else 
    {
        $logCsv = Import-Csv $CsvFile;
    }

    # If we find an entry for the VHD, update it
    foreach ($entry in $logCsv)
    {
        if ($entry.Image -eq $VhdFile)
        {
            $entryExists = $true;
            $entry.Checked = ((Get-Date).ToShortDateString() + "::" + (Get-Date).ToShortTimeString());
            
            if ($Sysprepped) 
            {
                $entry.Sysprepped = ((Get-Date).ToShortDateString() + "::" + (Get-Date).ToShortTimeString());
            }
        }
    }

    # if no entry is found, create a new one
    if (-not $entryExists) 
    {
        $newEntry = New-Object PSObject -Property @{
            Image = $VhdFile
            Created = ((Get-Date).ToShortDateString() + "::" + (Get-Date).ToShortTimeString())
            Sysprepped = ((Get-Date).ToShortDateString() + "::" + (Get-Date).ToShortTimeString())
            Checked = ((Get-Date).ToShortDateString() + "::" + (Get-Date).ToShortTimeString())
        };
    }

    # Write out the CSV file
    $logCsv | Export-CSV $CsvFile -NoTypeInformation;
    if (-not ($newEntry -eq $null)) 
    {
        $newEntry | Export-CSV $CsvFile -NoTypeInformation -Append;
    }
}

function Logger {
    param
    (
        [string]$systemName,
        [string]$message
    );

    # Function for displaying formatted log messages.  Also displays time in minutes since the script was started
    write-host (Get-Date).ToShortTimeString() -ForegroundColor Cyan -NoNewline;
    write-host " - [" -ForegroundColor White -NoNewline;
    write-host $systemName -ForegroundColor Yellow -NoNewline;
    write-Host "]::$($message)" -ForegroundColor White;
}

# Helper function for no error file cleanup
function cleanupFile
{
    param
    (
        [string] $file
    )
    
    if (Test-Path $file) 
    {
        Remove-Item $file -Recurse;
    }
}

# Helper function to make sure that needed folders are present
function checkPath
{
    param
    (
        [string] $path
    )
    if (!(Test-Path $path)) 
    {
        md $path;
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

function makeUnattendFile 
{
    param
    (
		[string] $Organization,
		[string] $Owner,
		[string] $Timezone,
		[string] $AdminPassword,
		[string] $UserPassword,
        [string] $key, 
        [string] $logonCount, 
        [string] $filePath, 
        [bool] $desktop = $false, 
        [bool] $is32bit = $false
    ); 

    # Composes unattend file and writes it to the specified filepath
     
    # Reload template - clone is necessary as PowerShell thinks this is a "complex" object
    $unattend = $unattendSource.Clone();
     
    # Customize unattend XML
    GetUnattendChunk "specialize" "Microsoft-Windows-Shell-Setup" $unattend | %{$_.ProductKey = $key};
    GetUnattendChunk "specialize" "Microsoft-Windows-Shell-Setup" $unattend | %{$_.RegisteredOrganization = $Organization};
    GetUnattendChunk "specialize" "Microsoft-Windows-Shell-Setup" $unattend | %{$_.RegisteredOwner = $Owner};
    GetUnattendChunk "specialize" "Microsoft-Windows-Shell-Setup" $unattend | %{$_.TimeZone = $Timezone};
    GetUnattendChunk "oobeSystem" "Microsoft-Windows-Shell-Setup" $unattend | %{$_.UserAccounts.AdministratorPassword.Value = $AdminPassword};
    GetUnattendChunk "oobeSystem" "Microsoft-Windows-Shell-Setup" $unattend | %{$_.AutoLogon.Password.Value = $AdminPassword};
    GetUnattendChunk "oobeSystem" "Microsoft-Windows-Shell-Setup" $unattend | %{$_.AutoLogon.LogonCount = $logonCount};

    if ($desktop)
    {
        GetUnattendChunk "oobeSystem" "Microsoft-Windows-Shell-Setup" $unattend | %{$_.UserAccounts.LocalAccounts.LocalAccount.Password.Value = $UserPassword};
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
    cleanupFile $filePath; $Unattend.Save($filePath);
}

function createRunAndWaitVM 
{
    param
    (
		[string] $VirtualMachineName,
		[string] $VirtualSwitchName,
        [string] $vhd, 
        [string] $gen
    );
    
    # Function for whenever I have a VHD that is ready to run
    New-VM $VirtualMachineName -MemoryStartupBytes 2048mb -VHDPath $vhd -Generation $Gen -SwitchName $VirtualSwitchName | Out-Null;
    Set-VM -Name $VirtualMachineName -ProcessorCount 2;
    Start-VM $VirtualMachineName;

    # Give the VM a moment to start before we start checking for it to stop
    Sleep -Seconds 10;

    # Wait for the VM to be stopped for a good solid 5 seconds
    do
    {
        $state1 = (Get-VM | ? name -eq $VirtualMachineName).State;
        Start-Sleep -Seconds 5;
        
        $state2 = (Get-VM | ? name -eq $VirtualMachineName).State;
        Start-Sleep -Seconds 5;
    } 
    until (($state1 -eq "Off") -and ($state2 -eq "Off"))

    # Clean up the VM
    Remove-VM $VirtualMachineName -Force;
}

function MountVHDandRunBlock 
{
    param
    (
        [string]$vhd, 
        [scriptblock]$block
    );
     
    # This function mounts a VHD, runs a script block and unmounts the VHD.
    # Drive letter of the mounted VHD is stored in $driveLetter - can be used by script blocks
    $driveLetter = (Mount-VHD $vhd -Passthru | Get-Disk | Get-Partition | Get-Volume).DriveLetter;
    & $block;
    Dismount-VHD $vhd;

    # Wait 2 seconds for activity to clean up
    Start-Sleep -Seconds 2;
}

function Get-ParameterOrGlobalValue
{
	[CmdletBinding()]
	
	param
	(
		[string] $Name,
		[string] $Value
	);

	process
	{
		$parameterValue = $Value;

		if([string]::IsNullOrEmpty($parameterValue))
		{
			# Parameterized value is null so check global
			$parameterValue = (Get-Variable -Name "IF_$($Name)" -Scope Global).Value;
		}

		if([string]::IsNullOrEmpty($parameterValue))
		{
			throw "Required parameter $($Name) was not provided";
		}

		return $parameterValue;
	}
}

function Import-Configuration
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
		
		$path = Get-ScriptDirectory;
		$scriptName = Get-ScriptName;

		$psConfigPath = "$($path)\$($scriptName.Replace(".ps1", "config.ps1"))";
		$xmlConfigPath = "$($path)\$($scriptName).config";

		$Global:IF_Images = @();

		if(Test-Path -Path $xmlConfigPath)
		{
			$config = [xml](Get-Content -Path $xmlConfigPath);

			foreach($section in $sections)
			{
				foreach ($node in $config.configuration.$section.add)
				{
					if($section -eq "appSettings")
					{
						Set-Variable -Name "IF_$($node.Key)" -Value $node.Value -Force;
					}
					elseif($section -eq "ImageFactory.Images")
					{
						$properties = @{
							Name = $node.Name
							Path = $node.Path
							Key = $node.Key
							Edition = $node.Edition
							IsDesktop = $node.IsDesktop
							Is32Bit = $node.Is32Bit
							VmGeneration = $node.VmGeneration
							GenericSysprep = $node.GenericSysprep
						};

						$Global:IF_Images += New-Object PSObject -Property $properties;
					}
				}
			}
		}

		if(Test-Path -Path $psConfigPath)
		{
			# Dot-source PowerShell based configuration
			. $psConfigPath;
		}
	}
}

function Get-ScriptName
{
	[CmdletBinding()]

	param
	(
	);

	process
	{
		$invocation = (Get-Variable MyInvocation -Scope 2).Value;
		return $invocation.MyCommand.Name;
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
        Get-ChildItem $env:SystemDrive\Bits\PSWindowsUpdate | Unblock-File;
        Invoke-Expression 'shutdown -r -t 0'
    }

    # To get here - the files are unblocked
    Import-Module $env:SystemDrive\Bits\PSWindowsUpdate\PSWindowsUpdate;

    # Check if any updates are needed - leave a marker if there are
    if ((Get-WUList).Count -gt 0)
    {
        if (-not (Test-Path $env:SystemDrive\Bits\changesMade.txt))
        {
            New-Item $env:SystemDrive\Bits\changesMade.txt -type file;
        }
    }
 
    # Apply all the updates
    Get-WUInstall -AcceptAll -IgnoreReboot -IgnoreUserInput -NotCategory "Language packs";

    # Reboot if needed - otherwise shutdown because we are done
    if (Get-WURebootStatus -Silent) 
    {
        Invoke-Expression 'shutdown -r -t 0';
    } 
    else
    {
        invoke-expression 'shutdown -s -t 0';
    }
};

### Sysprep script block
$sysprepScriptBlock = {
    # Remove autorun key if it exists
    Get-Item -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run | ? Property -like Unattend* | Remove-Item;
             
    $unattendedXmlPath = "$ENV:SystemDrive\Bits\Unattend.xml";
    & "$ENV:SystemRoot\System32\Sysprep\Sysprep.exe" `/generalize `/oobe `/shutdown `/unattend:"$unattendedXmlPath";
};

### Post Sysprep script block
$postSysprepScriptBlock = {
    # Remove autorun key if it exists
    Get-Item -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run | ? Property -like Unattend* | Remove-Item;

    # Clean up unattend file if it is there
    if (Test-Path "$ENV:SystemDrive\Unattend.xml") 
    {
        Remove-Item -Force "$ENV:SystemDrive\Unattend.xml";
    }

    # Clean up bits
    if(Test-Path "$ENV:SystemDrive\Bits")
    {
        Remove-Item -Force -Recurse "$ENV:SystemDrive\Bits";
    } 
     
    # Put any code you want to run Post sysprep here
    Invoke-Expression 'shutdown -r -t 0';
};

# This is the main function of this script
function RunTheFactory
{
	<#
        .SYNOPSIS
			Creates or updates an VHD image with latest Windows Update patches and
			creates a sysprepped golden image which can be used for deploying virtual
			machines.
           
        .NOTES
            To make the parametrization of this function easier, the parameters 
			$ResourceDirectory, $CsvFilePath, $VirtualMachineName, 
			$VirtualSwitchName, $Organization, $Owner, $Timezone, $AdminPassword and
			$UserPassword can be omitted if $Global variables with the naming schema
			$Global:IF_<VariableName> (e.g. $Global:IF_ResourceDirectory) are set.
    #>

	[CmdletBinding()]

    param
    (
		[string] $WorkingDirectory,
		[string] $ResourceDirectory,
		[string] $CsvFilePath,
		[string] $VirtualMachineName,
		[string] $VirtualSwitchName,
		[string] $Organization,
		[string] $Owner,
		[string] $Timezone,
		[string] $AdminPassword,
		[string] $UserPassword,
        [string]$FriendlyName,
        [string]$ISOFile,
        [string]$ProductKey,
        [string]$SKUEdition,
        [bool]$desktop = $false,
        [bool]$is32bit = $false,
        [switch]$Generation2,
        [bool] $GenericSysprep = $false
    );

	process
	{
        logger $FriendlyName "Starting a new cycle!"

		# Check parameter values and/or retrieve global override
		$WorkingDirectory = Get-ParameterOrGlobalValue -Name "WorkingDirectory" -Value $WorkingDirectory;
		$ResourceDirectory = Get-ParameterOrGlobalValue -Name "ResourceDirectory" -Value $ResourceDirectory;
		$CsvFilePath = Get-ParameterOrGlobalValue -Name "CsvFilePath" -Value $CsvFilePath;
		$VirtualMachineName = Get-ParameterOrGlobalValue -Name "VirtualMachineName" -Value $VirtualMachineName;
		$VirtualSwitchName = Get-ParameterOrGlobalValue -Name "VirtualSwitchName" -Value $VirtualSwitchName;
		$Organization = Get-ParameterOrGlobalValue -Name "Organization" -Value $Organization;
		$Owner = Get-ParameterOrGlobalValue -Name "Owner" -Value $Owner;
		$Timezone = Get-ParameterOrGlobalValue -Name "Timezone" -Value $Timezone;
		$AdminPassword = Get-ParameterOrGlobalValue -Name "AdminPassword" -Value $AdminPassword;
		$UserPassword = Get-ParameterOrGlobalValue -Name "UserPassword" -Value $UserPassword;

		checkPath "$($WorkingDirectory)";
		checkPath "$($ResourceDirectory)";

        # Setup a bunch of variables 
        $sysprepNeeded = $true;
		$baseVHD = "$($WorkingDirectory)\bases\$($FriendlyName)-base.vhdx";
		$updateVHD = "$($WorkingDirectory)\$($FriendlyName)-update.vhdx";
		$sysprepVHD = "$($WorkingDirectory)\$($FriendlyName)-sysprep.vhdx";
		$finalVHD = "$($WorkingDirectory)\share\$($FriendlyName).vhdx";
   
        $VHDPartitionStyle = "MBR";
        $Gen = 1;
        if ($Generation2) 
        {
            $VHDPartitionStyle = "GPT";
            $Gen = 2;
        }

        logger $FriendlyName "Checking for existing Factory VM";

        # Check if there is already a factory VM - and kill it if there is
		        if ((Get-VM | ? Name -eq $VirtualMachineName).Count -gt 0)
        {
			        Stop-VM $VirtualMachineName -TurnOff -Confirm:$false -Passthru | Remove-VM -Force;
        }

        # Check for a base VHD
        if (-not (test-path $baseVHD))
        {
            # No base VHD - we need to create one
            logger $FriendlyName "No base VHD!";

            # Make unattend file
            logger $FriendlyName "Creating unattend file for base VHD";

            # Logon count is just "large number"
		    makeUnattendFile -Organization $Organization -Owner $Owner -Timezone $Timezone -AdminPassword $AdminPassword -UserPassword $UserPassword `
			    -key $ProductKey -logonCount "1000" -filePath "$($WorkingDirectory)\unattend.xml" -desktop $desktop -is32bit $is32bit;
      
            # Time to create the base VHD
            logger $FriendlyName "Create base VHD using Convert-WindowsImage.ps1";

		    ### Load Convert-WindowsImage
		    . "$($ResourceDirectory)\Convert-WindowsImage.ps1";
        
            $ConvertCommand = "Convert-WindowsImage";
            $ConvertCommand = $ConvertCommand + " -SourcePath `"$ISOFile`" -VHDPath `"$baseVHD`"";
            $ConvertCommand = $ConvertCommand + " -SizeBytes 80GB -VHDFormat VHDX -UnattendPath `"$($WorkingDirectory)\unattend.xml`"";
            $ConvertCommand = $ConvertCommand + " -Edition $SKUEdition -VHDPartitionStyle $VHDPartitionStyle";

            Invoke-Expression "& $ConvertCommand";

            # Clean up unattend file - we don't need it any more
            logger $FriendlyName "Remove unattend file now that that is done";
		    cleanupFile "$($WorkingDirectory)\unattend.xml";

            logger $FriendlyName "Mount VHD and copy bits in, also set startup file";
            MountVHDandRunBlock $baseVHD {
                cleanupFile -file "$($driveLetter):\Convert-WindowsImageInfo.txt";

                # Copy ResourceDirectory in
                Copy-Item ($ResourceDirectory) -Destination ($driveLetter + ":\") -Recurse;
            
                # Create first logon script
                $updateCheckScriptBlock | Out-String | Out-File -FilePath "$($driveLetter):\Bits\Logon.ps1" -Width 4096;
            }

            logger $FriendlyName "Create virtual machine, start it and wait for it to stop...";
		    createRunAndWaitVM -VirtualMachineName $VirtualMachineName -VirtualSwitchName $VirtualSwitchName -vhd $baseVHD -gen $Gen;

            # Remove Page file
            logger $FriendlyName "Removing the page file";
            MountVHDandRunBlock $baseVHD {
                attrib -s -h "$($driveLetter):\pagefile.sys";
                cleanupFile "$($driveLetter):\pagefile.sys";
            }

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
            cleanupFile $updateVHD;
            New-VHD -Path $updateVHD -ParentPath $baseVHD | Out-Null;

            logger $FriendlyName "Copy login file for update check, also make sure flag file is cleared"
            MountVHDandRunBlock $updateVHD {
                # Make the UpdateCheck script the logon script, make sure update flag file is deleted before we start
                cleanupFile "$($driveLetter):\Bits\changesMade.txt";
                cleanupFile "$($driveLetter):\Bits\Logon.ps1";
                $updateCheckScriptBlock | Out-String | Out-File -FilePath "$($driveLetter):\Bits\Logon.ps1" -Width 4096;
            }

            logger $FriendlyName "Create virtual machine, start it and wait for it to stop...";
		    createRunAndWaitVM -VirtualMachineName $VirtualMachineName -VirtualSwitchName $VirtualSwitchName -vhd $updateVHD -gen $Gen;

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
                Merge-VHD -Path $updateVHD -DestinationPath $baseVHD;
            }
            else 
            {
                logger $FriendlyName "Delete the differencing disk"; 
			    CSVLogger -CsvFile $CsvFilePath -VhdFile $finalVHD;
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
            cleanupFile $sysprepVHD; new-vhd -Path $sysprepVHD -ParentPath $baseVHD | Out-Null;

            logger $FriendlyName "Mount the differencing disk and copy in files";
            MountVHDandRunBlock $sysprepVHD {
                $sysprepScriptBlockString = $sysprepScriptBlock | Out-String;

                if($GenericSysprep)
                {
                    $sysprepScriptBlockString = $sysprepScriptBlockString.Replace(' `/unattend:"$unattendedXmlPath"', "");
                }
                else
                {
                    # Make unattend file
				    makeUnattendFile -Organization $Organization -Owner $Owner -Timezone $Timezone -AdminPassword $AdminPassword -UserPassword $UserPassword `
					    -key $ProductKey -logonCount "1" -filePath "$($driveLetter):\Bits\unattend.xml" -desktop $desktop -is32bit $is32bit;
                }
            
                # Make the logon script
                cleanupFile "$($driveLetter):\Bits\Logon.ps1";
                $sysprepScriptBlockString | Out-File -FilePath "$($driveLetter):\Bits\Logon.ps1" -Width 4096;
            }

            logger $FriendlyName "Create virtual machine, start it and wait for it to stop...";
			        createRunAndWaitVM -VirtualMachineName $VirtualMachineName -VirtualSwitchName $VirtualSwitchName -vhd $sysprepVHD -gen $Gen;

            logger $FriendlyName "Mount the differencing disk and cleanup files";
            MountVHDandRunBlock $sysprepVHD {
                cleanupFile "$($driveLetter):\Bits\unattend.xml";
                cleanupFile "$($driveLetter):\Bits\Logon.ps1";

                if(-not $GenericSysprep)
                {
                    # Make the logon script
                    $postSysprepScriptBlock | Out-String | Out-File -FilePath "$($driveLetter):\Bits\Logon.ps1" -Width 4096;
                }
                else
                {
                    # Cleanup \Bits as the postSysprepScriptBlock is not run anymore
                    cleanupFile "$($driveLetter):\Bits";
                }
            }

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
		    CSVLogger -CsvFile $CsvFilePath -VhdFile $finalVHD -Sysprepped;
            cleanupFile $sysprepVHD;
        }
    }
}

try
{
	# Import configuration from dot-source ps1 or parsed xml
	Import-Configuration;

	# Main processing loop
    if($Global:IF_Images -ne $null -and $Global:IF_Images.Count -gt 0)
    {
	    foreach($image in $Global:IF_Images)
	    {
		    $isDesktop = [bool]::Parse($image.IsDesktop);
            if(-not [string]::IsNullOrEmpty($image.IsDesktop))
            {
		        $isDesktop = [bool]::Parse($image.IsDesktop);
            }
            
            $is32Bit = $false;
            if(-not [string]::IsNullOrEmpty($image.Is32Bit))
            {
		        $is32Bit = [bool]::Parse($image.Is32Bit);
            }
		    
            $genericSysprep = $false;
            if(-not [string]::IsNullOrEmpty($image.GenericSysprep))
            {
                $genericSysprep = [bool]::Parse($image.GenericSysprep);
            }

		    if($image.VmGeneration -eq 2)
		    {
			    RunTheFactory -FriendlyName $image.Name -ISOFile $image.Path -ProductKey $image.Key -SKUEdition $image.Edition `
				    -desktop $isDesktop -is32bit $is32Bit -GenericSysprep $genericSysprep -Generation2;
		    }
		    else
		    {
			    RunTheFactory -FriendlyName $image.Name -ISOFile $image.Path -ProductKey $image.Key -SKUEdition $image.Edition `
				    -desktop $isDesktop -is32bit $is32Bit -GenericSysprep $genericSysprep;
		    }
	    }
    }
}
catch
{
	throw $_;
}