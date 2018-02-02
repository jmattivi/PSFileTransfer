function Get-SFTPFolder
{
    <#
    .NOTES
    	AUTHOR: 	Jon Mattivi
    	COMPANY: 
    	CREATED DATE: 2018-02-02

    .SYNOPSIS
        Uses Putty psftp.exe to execute secure file transfers on remote hosts
        
    .DESCRIPTION
        Uses Putty psftp.exe to execute secure file transfers on remote hosts

    .PARAMETER Server
        Name of remote host to connect

    .PARAMETER Path
        Username to connect to remote host

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
        Get-SFTPFolder -Server ServerX -Path "/root/dir/" -Credential $Cred
        
    .EXAMPLE
        Get-SFTPFolder -Server ServerX -Path "/root/dir/" -UserName svcaccount -KeyFilePath C:\sshkeys\ServerX.key

    #>
    
    [CmdletBinding(DefaultParameterSetName = 'UsePasswordAuthentication')]
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Server,
        [Parameter(Position = 1, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,
        [Parameter(Position = 2, Mandatory = $true)]
        [Switch]$AutoAcceptKey = $true,
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
            "dir ""$Path""",
            "bye"
        )
    }
    ElseIf ($autoacceptkey -eq $false)
    {
        $cmd = @(
            "dir ""$Path""",
            "bye"
        )
    }

    if ($credential)
    {
        $username = $credential.UserName
        $password = $credential.GetNetworkCredential().Password
        #Run psftp.exe to List Folder
        $output = $cmd | & $psftp -v -pw $password $username@$server 2>&1
    }
    elseif ($keyfilepath)
    {
        #Run psftp.exe to List Folder
        $output = $cmd | & $psftp -v $username@$server -i $keyfilepath 2>&1
    }

    $err = [String]($output -like "Unable to open *: failure")
    If ($LastExitCode -ne 0)
    {
        throw "Failed to List Folder!!!! `n $($output)"
    }
    ElseIf (($err.Contains("failure") -and $err.StartsWith("Unable to open") -and $err.EndsWith("failure")) -eq $true)
    {
        throw "Failed to List Folder!!!! `n $($output)"
    }
        
    #Create Published Data
    $output = [system.string]::Join("`n", $output)
    $StartIndex = ($output.IndexOf("psftp> Listing directory"))
    $EndIndex = ($output.IndexOf("Sent EOF message")) - $StartIndex
    $output = $output.Substring($StartIndex, $EndIndex)
    $output = $output.split("`n") | ? {($_ -notlike "*Listing Directory*") -and ($_ -ne "")}
    $output = [system.string]::Join("`n", $output)

    $pubdata = New-Object System.Management.Automation.PSObject -Property ([Ordered]@{
            Server        = $server
            Path          = $path
            AutoAcceptKey = $autoacceptkey
            UserName      = $username
        })
    
    Write-Verbose $pubdata
    Write-Output $output
}