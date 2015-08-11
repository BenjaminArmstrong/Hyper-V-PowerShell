<#
	NOTES
		This configuration file is merged with an xml based configuration
		(Factory.ps1.config) if one exists. This configuration takes precedence
		over values specified in the xml based configuration.

		Please make sure that the $Global:IF_* configuration values are only specified 
		in either file (if you use both in parallel). This does not apply to the 
		$Global:IF_Images collection as it is merge. This means you can add image 
		definitions within this configuration as well as in the xml based configuration.
#>

$Global:IF_WorkingDirectory = "D:\ImageFactory";
$Global:IF_ResourceDirectory = "$($Global:IF_WorkingDirectory)\resources";
$Global:IF_CsvFilePath = "$($Global:IF_WorkingDirectory)\Share\Details.csv";
$Global:IF_VirtualMachineName = "Factory VM";
$Global:IF_VirtualSwitchName = "Virtual Switch";
$Global:IF_Organization = "The Power Elite";
$Global:IF_Owner = "Ben Armstrong";
$Global:IF_Timezone = "Pacific Standard Time";
$Global:IF_AdminPassword = "P@ssw0rd";
$Global:IF_UserPassword = "P@ssw0rd";

<#
	Examples

	$Global:IF_Images += New-Object PSObject -Property @{
		Name = "Windows Server 2012 R2 DataCenter with GUI"
		Path = ""
		Key = ""
		Edition = "ServerDataCenter"
		IsDesktop = $false
		Is32Bit = $false
		VmGeneration = 2
		GenericSysprep = $false
	};

	$Global:IF_Images += New-Object PSObject -Property @{
		Name = "Windows Server 2012 R2 DataCenter Core"
		Path = ""
		Key = ""
		Edition = "ServerDataCenterCore"
		IsDesktop = $false
		Is32Bit = $false
		VmGeneration = 1
		GenericSysprep = $false
	};

	$Global:IF_Images += New-Object PSObject -Property @{
		Name = "Windows Server 2012 R2 with GUI - Gen 2"
		Path = ""
		Key = ""
		Edition = "ServerDataCenter"
		IsDesktop = $false
		Is32Bit = $false
		VmGeneration = 2
		GenericSysprep = $false
	};

	$Global:IF_Images += New-Object PSObject -Property @{
		Name = "Windows Server 2012 R2 Core - Gen 2"
		Path = ""
		Key = ""
		Edition = "ServerDataCenterCore"
		IsDesktop = $false
		Is32Bit = $false
		VmGeneration = 2
		GenericSysprep = $false
	};

	$Global:IF_Images += New-Object PSObject -Property @{
		Name = "Windows Server 2012 DataCenter with GUI"
		Path = ""
		Key = ""
		Edition = "ServerDataCenter"
		IsDesktop = $false
		Is32Bit = $false
		VmGeneration = 1
		GenericSysprep = $false
	};

	$Global:IF_Images += New-Object PSObject -Property @{
		Name = "Windows Server 2012 DataCenter Core"
		Path = ""
		Key = ""
		Edition = "ServerDataCenterCore"
		IsDesktop = $false
		Is32Bit = $false
		VmGeneration = 1
		GenericSysprep = $false
	};

	$Global:IF_Images += New-Object PSObject -Property @{
		Name = "Windows Server 2012 with GUI - Gen 2"
		Path = ""
		Key = ""
		Edition = "ServerDataCenter"
		IsDesktop = $false
		Is32Bit = $false
		VmGeneration = 2
		GenericSysprep = $false
	};

	$Global:IF_Images += New-Object PSObject -Property @{
		Name = "Windows Server 2012 Core - Gen 2"
		Path = ""
		Key = ""
		Edition = "ServerDataCenterCore"
		IsDesktop = $false
		Is32Bit = $false
		VmGeneration = 2
		GenericSysprep = $false
	};

	$Global:IF_Images += New-Object PSObject -Property @{
		Name = "Windows 8.1 Professional"
		Path = ""
		Key = ""
		Edition = "Professional"
		IsDesktop = $true
		Is32Bit = $false
		VmGeneration = 1
		GenericSysprep = $false
	};

	$Global:IF_Images += New-Object PSObject -Property @{
		Name = "Windows 8.1 Professional - Gen 2"
		Path = ""
		Key = ""
		Edition = "Professional"
		IsDesktop = $true
		Is32Bit = $false
		VmGeneration = 2
		GenericSysprep = $false
	};

	$Global:IF_Images += New-Object PSObject -Property @{
		Name = "Windows 8.1 Professional - 32 bit"
		Path = ""
		Key = ""
		Edition = "Professional"
		IsDesktop = $true
		Is32Bit = $true
		VmGeneration = 1
		GenericSysprep = $false
	};

	$Global:IF_Images += New-Object PSObject -Property @{
		Name = "Windows 8 Professional"
		Path = ""
		Key = ""
		Edition = "Professional"
		IsDesktop = $true
		Is32Bit = $false
		VmGeneration = 1
		GenericSysprep = $false
	};

	$Global:IF_Images += New-Object PSObject -Property @{
		Name = "Windows 8 Professional - Gen 2"
		Path = ""
		Key = ""
		Edition = "Professional"
		IsDesktop = $true
		Is32Bit = $false
		VmGeneration = 2
		GenericSysprep = $false
	};

	$Global:IF_Images += New-Object PSObject -Property @{
		Name = "Windows 8 Professional - 32 bit"
		Path = ""
		Key = ""
		Edition = "Professional"
		IsDesktop = $true
		Is32Bit = $true
		VmGeneration = 1
		GenericSysprep = $false
	};
#>