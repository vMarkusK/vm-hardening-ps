#############################################################################  
# VM Hardening Script 
# Written by Markus Kraus
# Version 1.1 
#  
# https://mycloudrevolution.wordpress.com/ 
#  
# Changelog:  
# 2016.01 ver 1.0 Base Release  
# 2016.02 ver 1.1 Added more Error Handling 
#  
#  
##############################################################################  


## Preparation
# Load Snapin (if not already loaded)
if (!(Get-PSSnapin -name VMware.VimAutomation.Core -ErrorAction:SilentlyContinue)) {
	if (!(Add-PSSnapin -PassThru VMware.VimAutomation.Core)) {
		# Error out if loading fails
		write-host "`nFATAL ERROR: Cannot load the VIMAutomation Core Snapin. Is the PowerCLI installed?`n"
		exit
	}
}

# Inputs
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
$yourvCenter = [Microsoft.VisualBasic.Interaction]::InputBox("Enter your vCenter FQDN or IP", "vCenter", "$env:computername") 
$yourFolderName = [Microsoft.VisualBasic.Interaction]::InputBox("Enter your vCenter VM Folder Name", "Folder Name", "vm") 

# Start vCenter Connection
Write-Host "Starting to Process vCenter Connection to " $yourvCenter " ..."-ForegroundColor Magenta
$OpenConnection = $global:DefaultVIServers | where { $_.Name -eq $yourvCenter }
if($OpenConnection.IsConnected) {
	Write-Host "vCenter is Already Connected..." -ForegroundColor Blue
	$VIConnection = $OpenConnection
} else {
	Write-Host "Connecting vCenter..."
	$VIConnection = Connect-VIServer -Server $yourvCenter
}

if (-not $VIConnection.IsConnected) {
	Write-Error "Error: vCenter Connection Failed"
    Exit
}
# End vCenter Connection

# Connect to vCenter
$trash = Connect-VIServer $yourvCenter


## Exection
# Check Folder
if (!(Get-Folder -Name $yourFolderName -ErrorAction SilentlyContinue)){
    Write-Host "Folder does Not Exist. Exiting..." -ForegroundColor Red
    }
    else{

	# Create Options
	$ExtraOptions = @{
		"isolation.tools.diskShrink.disable"="true";
		"isolation.tools.diskWiper.disable"="true";
		"isolation.tools.copy.disable"="true";
		"isolation.tools.paste.disable"="true";
		"isolation.tools.dnd.disable"="true";
		"isolation.tools.setGUIOptions.enable"="false"; 
		"log.keepOld"="10";
		"log.rotateSize"="100000"
		"RemoteDisplay.maxConnections"="2";
		"RemoteDisplay.vnc.enabled"="false";  
	
	}
	Write-Host "VM Hardening Options:"-ForegroundColor Magenta
	$ExtraOptions | Format-Table -AutoSize
	
	$vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
	
	Foreach ($Option in $ExtraOptions.GetEnumerator()) {
		$OptionValue = New-Object VMware.Vim.optionvalue
		$OptionValue.Key = $Option.Key
		$OptionValue.Value = $Option.Value
		$vmConfigSpec.extraconfig += $OptionValue
	}


	# Apply

	ForEach ($vm in (get-folder -Name $yourFolderName | Get-VM )){
		$vmv = Get-VM $vm | Get-View
		$state = $vmv.Summary.Runtime.PowerState
		Write-Host "...Starting Reconfiguring VM: $VM "
		$TaskConf = ($vmv).ReconfigVM_Task($vmConfigSpec)
			if ($state -eq "poweredOn") {
				Write-Host "...Migrating VM: $VM "
				$TaskMig = $vmv.MigrateVM_Task($null, $_.Runtime.Host, 'highPriority', $null)
				}
		}
	Write-Host "Reconfiguring Completed" -ForegroundColor Green
	}