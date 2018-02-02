function Remove-SFTPFile
{
    <#
    .NOTES
    	AUTHOR: 	Jon Mattivi
    	COMPANY: 
    	CREATED DATE: 2018-02-02

    .SYNOPSIS
        Uses Putty psftp.exe to delete folder on remote hosts
        
    .DESCRIPTION
        Uses Putty psftp.exe to delete folder on remote hosts

    .PARAMETER Server
        Name of remote host to connect

    .PARAMETER Path
        Source path on remote host

    .PARAMETER FolderName
        Folder name to create on remote host

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
        Remove-SFTPFile -Server ServerX -Path "/root/dir/" -FolderName $foldername-Credential $Cred
        
    .EXAMPLE
        Remove-SFTPFile -Server ServerX -Path "/root/dir/" -FolderName $foldername -UserName svcaccount -KeyFilePath C:\sshkeys\ServerX.key

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
        [string]$FolderName,
        [Parameter(Position = 3, Mandatory = $true)]
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
            "rmdir ""$foldername""",
            "bye"
        )
    }
    ElseIf ($autoacceptkey -eq $false)
    {
        $cmd = @(
            "cd ""$path""",
            "rmdir ""$foldername""",
            "bye"
        )
    }

    if ($credential)
    {
        $username = $credential.UserName
        $password = $credential.GetNetworkCredential().Password
        #Run psftp.exe to delete folder
        $output = $cmd | & $psftp -v -pw $password $username@$server 2>&1
    }
    elseif ($keyfilepath)
    {
        #Run psftp.exe to delete folder
        $output = $cmd | & $psftp -v $username@$server -i $keyfilepath 2>&1
    }

    $err = [String]($output -like "psftp> rm*OK")
    If ($LastExitCode -ne 0)
    {
        throw "Failed to Delete Folder!!!! `n $($output)"
    }
    ElseIf (($err.StartsWith("psftp> rm") -and $err.EndsWith("OK")) -eq $false)
    {
        throw "Failed to Delete Folder!!!! `n $($output)"
    }
        

    #Create Published Data
    $output = [system.string]::Join("`n", $output)
    $pubdata = New-Object System.Management.Automation.PSObject -Property ([Ordered]@{
            Server        = $server
            Path          = $path
            FolderName      = $foldername
            AutoAcceptKey = $autoacceptkey
            UserName      = $username
        })
    
    Write-Verbose $pubdata
    Write-Output $output
}