﻿function Receive-SFTPFile
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

    .PARAMETER SourceServer
        Name of remote host to connect

    .PARAMETER SourcePath
        Username to connect to remote host

    .PARAMETER DestPath
        Command to run on remote host
    
    .PARAMETER FileName
        Command to run on remote host

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
        Receive-SFTPFile -SourceServer ServerX -SourcePath "/root/dir/" -DestPath "C:\temp\" -FileName "file.txt" -Credential $Cred
        
    .EXAMPLE
        Receive-SFTPFile -SourceServer ServerX -SourcePath "/root/dir/" -DestPath "C:\temp\" -FileName "file.txt" -UserName svcaccount -KeyFilePath C:\sshkeys\ServerX.key

    #>
    
    [CmdletBinding(DefaultParameterSetName = 'UsePasswordAuthentication')]
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SourceServer,
        [Parameter(Position = 1, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SourcePath,
        [Parameter(Position = 2, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$DestPath,
        [Parameter(Position = 3, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FileName,
        [Parameter(Position = 4, Mandatory = $false)]
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
            "lcd ""$destpath""",
            "cd ""$sourcepath""",
            "mget ""$filename""",
            "bye"
        )
    }
    ElseIf ($autoacceptkey -eq $false)
    {
        $cmd = @(
            "lcd ""$destpath""",
            "cd ""$sourcepath""",
            "mget ""$filename""",
            "bye"
        )
    }

    If ($credential)
    {
        $username = $credential.UserName
        $password = $credential.GetNetworkCredential().Password
        #Run psftp.exe to Download File
        $output = $cmd | & $psftp -v -pw $password $username@$sourceserver 2>&1
    }
    ElseIf ($keyfilepath)
    {
        #Run psftp.exe to Download File
        $output = $cmd | & $psftp -v $username@$sourceserver -i $keyfilepath 2>&1
    }
        
    $err = [String]($output -like "*=>*")
    $localerr = [String]($output -like "*New local directory is*")
    $remoteerr = [String]($output -like "*Remote directory is now*")
    If ($LastExitCode -ne 0)
    {
        throw "File Failed to Transfer!!!! `n $($output)"
    }
    ElseIf (($localerr.Contains("New local directory is")) -eq $false)
    {
        throw "Failed to Change Local Directory!!!! `n $($output)"
    }
    ElseIf (($remoteerr.Contains("Remote directory is now")) -eq $false)
    {
        throw "Failed to Change Remote Directory!!!! `n $($output)"
    }
    ElseIf (($err.Contains("=>")) -eq $false)
    {
        throw "File Failed to Transfer!!!! `n $($output)"
    }
    
    #Create Published Data
    $output = [system.string]::Join("`n", $output)
    $pubdata = New-Object System.Management.Automation.PSObject -Property ([Ordered]@{
            SourceServer  = $sourceserver
            SourcePath    = $sourcepath
            DestPath      = $destpath
            FileName      = $filename
            AutoAcceptKey = $autoacceptkey
            UserName      = $username
        })
    
    Write-Verbose $pubdata
    Write-Output $output
}