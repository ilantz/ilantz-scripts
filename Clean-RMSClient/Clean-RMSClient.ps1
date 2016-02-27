<#

	.SYNOPSIS
    Clean-RMSClient
   
    Ilan Lanz
    http://ilantz.com
	
    THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE 
    RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.
	
    Version 1.0, 15/02/2016
    
    .DESCRIPTION
    This script will clean traces of an AD RMS client. Including server configurations (registry), templates and RMS licenses.
	In addition, the script will "reset" the last update time watermark in the registry for allowing the AD RMS Rights Policy Template Management task to be executed and update all templates immediately.
	
			       
    Revision History
    --------------------------------------------------------------------------------
    1.0     Initial release
	
#>

# Verifying PowerShell is executed "as an administrator"

If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`

	[Security.Principal.WindowsBuiltInRole] "Administrator"))

{

	Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"

	Break

}

ELSE
{
	Write-Output "Cleaning RMS client..."

	#Clean Registry Keys

	Get-ChildItem "hkcu:\Software\Microsoft\MSDRM\" | Remove-Item -Force | Out-Null
	Get-ChildItem "HKCU:\Software\Classes\Local Settings\Software\Microsoft\MSIPC" | Remove-Item -Force -Confirm:$false -Recurse | Out-Null

	#Clean Files

	Get-ChildItem ($env:USERPROFILE+"\AppData\Local\Microsoft\DRM\Templates\") | Remove-Item -Force | Out-Null
	Get-ChildItem ($env:ALLUSERSPROFILE+"\Microsoft\DRM\Server\") | Remove-Item -Force -Recurse | Out-Null
	Get-ChildItem ($env:localappdata+"\Microsoft\MSIPC\") | Remove-Item -Force -Recurse | Out-Null

	#Run the AD RMS client template update
	Invoke-Command -ScriptBlock {& "schtasks.exe" '/run' '/tn' "\Microsoft\Windows\Active Directory Rights Management Services Client\AD RMS Rights Policy Template Management (Automated)"} | Out-Null

	Write-Output "Done !"
}