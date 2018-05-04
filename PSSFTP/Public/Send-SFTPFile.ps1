function Send-SFTPFile
{
    <#
    .NOTES
    	AUTHOR: 	Jon Mattivi
    	COMPANY: 
    	CREATED DATE: 2018-02-02

    .SYNOPSIS
        Uses Putty psftp.exe to upload file(s) on remote hosts
        
    .DESCRIPTION
        Uses Putty psftp.exe to upload file(s) on remote hosts

    .PARAMETER DestServer
        Name of remote host to connect

    .PARAMETER SourcePath
        Source path locally

    .PARAMETER DestPath
        Remote path to upload the file(s)
    
    .PARAMETER FileName
        File or filemask to transfer

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
        Send-SFTPFile -DestServer ServerX -SourcePath "C:\temp\" -DestPath "/root/dir/" -FileName "file.txt" -Credential $Cred
        
    .EXAMPLE
        Send-SFTPFile -DestServer ServerX -SourcePath "C:\temp\" -DestPath "/root/dir/" -FileName "file.txt" -UserName svcaccount -KeyFilePath C:\sshkeys\ServerX.key

    #>
    
    [CmdletBinding(DefaultParameterSetName = 'UsePasswordAuthentication')]
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$DestServer,
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
        [bool]$AutoAcceptKey = $true,
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

    if ($autoacceptkey -eq $true)
    {
        $cmd = @(
            "y",
            "This is a really, really, really, really long bogus cmd", #Required for timing issue while running the expect commands
            "lcd ""$sourcepath""",
            "cd ""$destpath""",
            "mput ""$filename""",
            "bye"
        )
    }
    elseif ($autoacceptkey -eq $false)
    {
        $cmd = @(
            "lcd ""$sourcepath""",
            "cd ""$destpath""",
            "mput ""$filename""",
            "bye"
        )
    }

    if ($credential)
    {
        $username = $credential.UserName
        $password = $credential.GetNetworkCredential().Password
        #Run psftp.exe to Upload File
        $output = $cmd | & $psftp -v -pw $password $username@$destserver 2>&1
    }
    elseif ($keyfilepath)
    {
        #Run psftp.exe to Upload File
        $output = $cmd | & $psftp -v $username@$destserver -i $keyfilepath 2>&1
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
            DestServer    = $destserver
            SourcePath    = $sourcepath
            DestPath      = $destpath
            FileName      = $filename
            AutoAcceptKey = $autoacceptkey
            UserName      = $username
        })
    
    Write-Verbose $pubdata
    Write-Output $output
}