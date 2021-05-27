param (
	[string]$vstsAccount,
	[string]$PAT,
    [string]$vstsPoolName,
    [string]$vstsAgent,
    [string]$vmAdminPassword,
	[string]$vmAdminUserName,
    [string]$WindowsLogonAccount = "%COMPUTERNAME%\$vmAdminUserName",
	[boolean]$Interactive = $true,
	[string]$AgentNo,
	[string]$Proxy=""
    
)

Start-Transcript
Write-Host "start"

#test if an old installation exists, if so, delete the folder
if (test-path "c:\agent")
{
    Remove-Item -Path "c:\agent" -Force -Confirm:$false -Recurse
}

#create a new folder
new-item -ItemType Directory -Force -Path "c:\agent"
set-location "c:\agent"

$env:VSTS_AGENT_HTTPTRACE = $true

#github requires tls 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#get the latest build agent version
$wr = Invoke-WebRequest https://api.github.com/repos/Microsoft/azure-pipelines-agent/releases/latest -UseBasicParsing
$tag = ($wr | ConvertFrom-Json)[0].tag_name
$tag = $tag.Substring(1)

write-host "$tag is the latest version"
#build the url
$download = "https://vstsagentpackage.azureedge.net/agent/$tag/vsts-agent-win-x64-$tag.zip"

#download the agent
Invoke-WebRequest $download -Out agent.zip

#expand the zip
Expand-Archive -Path agent.zip -DestinationPath $PWD

#run the config script of the build agent
cmd /c .\config.cmd remove --unattended --auth "pat" --token $PAT

if($Proxy -eq "")
{
    $Proxy = (Get-ItemProperty -Path "Registry::HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings").ProxyServer
}

if ($Interactive) {
    Write-Host "Configuring agent to run interactively"
	if($Proxy -ne "") {
    		cmd /c .\config.cmd --unattended --proxyurl $Proxy --url "$vstsAccount" --auth pat --token "$PAT" --pool "$vstsPoolName" --agent "$vstsAgent-I$AgentNo" --overwriteAutoLogon --runAsAutoLogon --windowsLogonAccount $WindowsLogonAccount  --WindowsLogonPassword "$vmAdminPassword" --work ".\_work"
	}
	else
	{
    		cmd /c .\config.cmd --unattended --url "$vstsAccount" --auth pat --token "$PAT" --pool "$vstsPoolName" --agent "$vstsAgent-I$AgentNo" --overwriteAutoLogon --runAsAutoLogon --windowsLogonAccount $WindowsLogonAccount  --WindowsLogonPassword "$vmAdminPassword" --work ".\_work"
	}
    Write-Host "Run.cmd will run automatically after startup.  Click 'Close' on the dialog that popsup"
}
#Install IIS
Install-WindowsFeature -Name web-server -IncludeManagementTools
#Install ASP.NET 4.7, .NET Framework 3.
Install-WindowsFeature -Name web-server -IncludeAllSubFeature

# Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
#Install Chrome
choco install googlechrome -y
# Install powershell core
choco install powershell-core -y
# Install Dotnetcore
choco install dotnetcore-sdk -y
# Install VSCODE
choco install vscode -y

### Run as Service
#### cmd /c .\config.cmd --unattended --url "$vstsAccount" --auth pat --token "$PAT" --pool "$vstsPoolName" --agent "$vstsAgent" --acceptTeeEula --runAsService --windowsLogonAccount "$WindowsLogonAccount"  --WindowsLogonPassword "$vmAdminPassword" --work ".\_work"

#exit
Stop-Transcript
exit 0