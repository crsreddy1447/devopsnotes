# .\5.Config-Agent.ps1 -Pool 'Self Hosted Win-UAT' -WindowsLogonAccount %COMPUTERNAME%/ehpadmin
# run the below manually in an elevated command prompt... make sure to replace the computer name
param (
    [string] $Pool = "Test Automation - DEV",
    [boolean] $Interactive = $true,
    [string] $Pat = "jqavlx4ez3imuriv6qne2s2lr2xkrjtewho6dzrqfhl4mgnfbeea",
    [string] $Proxy="",
    [string] $Project = "https://dev.azure.com/ensemblehealth",
    [string] $Pwd = 'Ehp@1234#5',
    [string] $WindowsLogonAccount = "%COMPUTERNAME%\ehpadmin",
    [int] $AgentNo = 2

)

 

cmd /c .\config.cmd remove --unattended --auth "pat" --token $Pat

if($Proxy -eq "")
{
    $Proxy = (Get-ItemProperty -Path "Registry::HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings").ProxyServer
}

if ($Interactive) {
    Write-Host "Configuring agent to run interactively"
	if($Proxy -ne "") {
    		cmd /c .\config.cmd --unattended --proxyurl $Proxy --url $Project --auth "pat" --token $Pat --pool $Pool --agent "ehpdevwinagent-I$AgentNo" --overwriteAutoLogon --runAsAutoLogon --windowsLogonAccount $WindowsLogonAccount  --WindowsLogonPassword "$Pwd" --work ".\_work"
	}
	else
	{
    		cmd /c .\config.cmd --unattended --url $Project --auth "pat" --token $Pat --pool $Pool --agent "%COMPUTERNAME%-I$AgentNo" --overwriteAutoLogon --runAsAutoLogon --windowsLogonAccount $WindowsLogonAccount  --WindowsLogonPassword "$Pwd" --work ".\_work"
	}
    Write-Host "Run.cmd will run automatically after startup.  Click 'Close' on the dialog that popsup"
}