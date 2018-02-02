function Rename-SFTPFile
{
    <#
    .NOTES
    	AUTHOR: 	Jon Mattivi
    	COMPANY: 
    	CREATED DATE: 2018-02-02

    .SYNOPSIS
        Uses Putty psftp.exe to delete file on remote hosts
        
    .DESCRIPTION
        Uses Putty psftp.exe to delete file on remote hosts

    .PARAMETER Server
        Name of remote host to connect

    .PARAMETER Path
        Source path on remote host

    .PARAMETER OldFileName
        File name to change on remote host
    
    .PARAMETER NewFileName
        Updated file name on remote host

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
        Rename-SFTPFile -Server ServerX -Path "/root/dir/" -OldFileName oldfilename.txt -NewFileName newfilename.txt -Credential $Cred
        
    .EXAMPLE
        Rename-SFTPFile -Server ServerX -Path "/root/dir/" -OldFileName oldfilename.txt -NewFileName newfilename.txt -UserName svcaccount -KeyFilePath C:\sshkeys\ServerX.key

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
        [ValidateNotNullOrEmpty()]
        [string]$OldFileName,
        [Parameter(Position = 3, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$NewFileName,
        [Parameter(Position = 4, Mandatory = $true)]
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
            "cd ""$path""",
            "ren ""$oldfilename"" ""$newfilename""",
            "bye"
        )
    }
    ElseIf ($autoacceptkey -eq $false)
    {
        $cmd = @(
            "cd ""$path""",
            "ren ""$oldfilename"" ""$newfilename""",
            "bye"
        )
    }

    if ($credential)
    {
        $username = $credential.UserName
        $password = $credential.GetNetworkCredential().Password
        #Run psftp.exe to delete file
        $output = $cmd | & $psftp -v -pw $password $username@$server 2>&1
    }
    elseif ($keyfilepath)
    {
        #Run psftp.exe to delete file
        $output = $cmd | & $psftp -v $username@$server -i $keyfilepath 2>&1
    }

   
    $err = [String]($output -like "*->*$NewFileName")
    If ($LastExitCode -ne 0)
    {
        throw "Failed to Rename File!!!! `n $($output)"
    }
    ElseIf (($err.Contains("->") -and $err.EndsWith("$NewFileName")) -eq $false)
    {
        throw "Failed to Rename File!!!! `n $($output)"
    }
       
    #Create Published Data
    $output = [system.string]::Join("`n", $output)
    $pubdata = New-Object System.Management.Automation.PSObject -Property ([Ordered]@{
            Server        = $server
            Path          = $path
            OldFileName   = $oldfilename
            NewFileName   = $newfilename
            AutoAcceptKey = $autoacceptkey
            UserName      = $username
        })
    
    Write-Verbose $pubdata
    Write-Output $output
}