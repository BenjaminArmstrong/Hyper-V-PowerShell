# Images CSV File

The images CSV file is used to manage the various Windows products, editions and options for running Image Factory.  Each row defines a Windows product, edition and processor architecture.

## File Format


### Columns

| Column        | Description           |
| ------------- |  -------------------- |
| **Name** | Optional. Used as the file name for the image.  If not specified, the Product, Edition, SB, Arch, GUI/Core and Gen1/Gen2 will be used to generate a name.
| **Product** | The name of the Windows product without the edition, for example 'Windows 10'.
| **Edition** | The edition such as DataCenter, Standard, Enterprise, Professional, etc
| **SB** | Servicing Branch or release (such as *1511* or *1607* for Windows 10, LTSB)
| **Arch** | x64 or x86. Used to set Is32Bit parameter. Needed to create the unattend file correctly.
| **GUI** | TRUE/FALSE to install GUI version. For non-server OS, this must be TRUE.
| **Core** | TRUE/FALSE to install Core version. Only applies to server products that support Core deployments.
| **Gen1** | Create a Generation 1 virtual machine.
| **Gen2** | Create a Generation 2 virtual machine.
| **ProductKey** | The product key to use for the unattended installation.
| **Image** | The ISO or WIM file to use as the base of the windows image.
| **SHA1** | The SHA1 hash of Image. Not used by Image Factory. Could be used in future to validate ISO before installing.
| **Version** | [Version of Windows](https://en.wikipedia.org/wiki/Windows_NT). Used to sort file. Not used by Image Factory. Only machines with version of 6.2 or higher can use secure boot.
| **Sort** | User field. Helper column used to help sorting when using Excel to edit.
| **Notes** | User field. User specific notes. Not used by Image Factory.
