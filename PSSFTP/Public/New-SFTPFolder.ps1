function New-SFTPFolder
{
    <#
    .NOTES
    	AUTHOR: 	Jon Mattivi
    	COMPANY: 
    	CREATED DATE: 2018-02-02

    .SYNOPSIS
        Uses Putty psftp.exe to create folder on remote hosts
        
    .DESCRIPTION
        Uses Putty psftp.exe to create folder on remote hosts

    .PARAMETER Server
        Name of remote host to connect

    .PARAMETER Path
        Source path on remote host
    
    .PARAMETER NewFolderName
        Name of the new folder to create

    .PARAMETER AutoAcceptKey
        Automatically accept the key for the remote host - Default value is True

    .PARAMETER Credential
        Network credential object used when key authentication is not used
    
    .PARAMETER UserName
        Username specified when key authentication is used

    .PARAMETER KeyFilePath
        Path to key file when using key authentication
    	    
    .EXAMPLE
        $password = ConvertTo-SecureString "PlainTextPassword" -AsPlainText -Force
        $Cred = New-Object System.Management.Automation.PSCredential ("username", $password)
        New-SFTPFolder -Server ServerX -Path "/root/dir/" -NewFolderName newname -Credential $Cred
        
    .EXAMPLE
        New-SFTPFolder -Server ServerX -Path "/root/dir/" -NewFolderName newname -UserName svcaccount -KeyFilePath C:\sshkeys\ServerX.key    	

    #>
    [CmdletBinding(DefaultParameterSetName = 'UsePasswordAuthentication')]
    Param (
        [parameter(position = 1, mandatory = $true)]    
        [String]$Server,
        [parameter(position = 2, mandatory = $true)]
        [String]$Path,
        [parameter(position = 3, mandatory = $true)]
        [String]$NewFolderName,
        [parameter(position = 4, mandatory = $false)]
        [String]$AutoAcceptKey = $true,
        [Parameter(ParameterSetName = 'UsePasswordAuthentication', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,
        [Parameter(ParameterSetName = 'UseKeyAuthentication', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$UserName,
        [Parameter(ParameterSetName = 'UseKeyAuthentication', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$KeyFilePath
    )
    
    $output = @()
    $psftp = "$PSScriptRoot\..\bin\psftp.exe"

    If ($autoacceptkey -eq $true)
    {
        $cmd = @(
            "y",
            "This is a really, really, really, really long bogus cmd", #Required for timing issue while running the expect commands
            "cd ""$Path""",
            "mkdir ""$newfoldername""",
            "bye"
        )
    }
    ElseIf ($autoacceptkey -eq $false)
    {
        $cmd = @(
            "cd ""$Path""",
            "mkdir ""$newfoldername""",
            "bye"
        )
    }

    if ($credential)
    {
        $username = $credential.UserName
        $password = $credential.GetNetworkCredential().Password
        #Run psftp.exe to Create Directory
        $output = $cmd | & $psftp -v -pw $password $username@$server 2>&1
    }
    elseif ($keyfilepath)
    {
        #Run psftp.exe to Create Directory
        $output = $cmd | & $psftp -v $username@$server -i $keyfilepath 2>&1
    }

    $err = [String]($output -like "psftp> mkdir*OK")
    If ($LastExitCode -ne 0)
    {
        throw "Failed to Create Folder!!!! `n $($output)"
    }
    ElseIf (($err.StartsWith("psftp> mkdir") -and $err.EndsWith("OK")) -eq $false)
    {
        throw "Failed to Create Folder!!!! `n $($output)"
    }

    #Create Published Data
    $output = [system.string]::Join("`n", $output)
    $pubdata = New-Object System.Management.Automation.PSObject -Property ([Ordered]@{
            Server        = $server
            Path          = $path
            NewFolderName = $newfoldername
            AutoAcceptKey = $autoacceptkey
            UserName      = $username
        })
    
    Write-Verbose $pubdata
    Write-Output $output

}