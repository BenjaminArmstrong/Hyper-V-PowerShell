# Hyper-V Image Factory #

This is a PowerShell script that creates and maintains a set of Windows virtual hard disks for me that are always up to date.  

# What is this all about? #

For more information - read here: http://blogs.msdn.com/b/virtual_pc_guy/archive/2015/06/16/script-image-factory-for-hyper-v.aspx


# Change Log #

8/10/15 -

* Extended the externalization of the configuration to use either .ps1 based configuration or .xml based configuration
* Extended the main function call to accept $Global configuration values to prevent variable pollution but still limit the number of parameters to be passed
* Implemented separate configurable directories/paths for working/resources/log file

8/1/15 -

* Tested with Windows 10 (yay!)
* Moved variables into separate file to make it easier to accept changes - and to stop people from giving me their product keys
* Added code to check for and create directories that are missing

7/29/15 -

* Accepted changes from Christoph Petersen that: 
   * Cleaned up files inside the virtual machine at the end
   * Added support for an external sysprep process
   * Made the code a lot prettier to look at (thanks Christoph!)

# To do #

This is the list of things currently in my "to do" list.  Feel free to tackle any of them yourself and request a pull.

* Better error handling around missing files (convert-windowsimage, factoryvariables, PSUpdate, etc...)
* MD5 summing for virtual hard drives in the share folder
* Add support for static IP addresses inside the factory VM - so the script works when DHCP does not
* Add support for connecting the factory VM to VLANs
* Add support for Windows 7 / 2008 R2 guest operating systems
* Update this readme to have more information from the blog post - and vice versa