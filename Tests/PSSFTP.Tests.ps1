
Import-Module -Force $PSScriptRoot\..\PSSFTP\PSSFTP.psm1

Describe 'Get-SFTPFolder' {
    Context 'Strict mode' {
        Set-StrictMode -Version latest

        It 'Should find the psftp executable' {
            Test-Path $PSScriptRoot\..\PSSFTP\bin\psftp.exe | Should be $true
        }
    }
}

Describe 'New-SFTPFolder' {
    Context 'Strict mode' {
        Set-StrictMode -Version latest

        It 'Should find the psftp executable' {
            Test-Path $PSScriptRoot\..\PSSFTP\bin\psftp.exe | Should be $true
        }
    }
}

Describe 'Receive-SFTPFile' {
    Context 'Strict mode' {
        Set-StrictMode -Version latest

        It 'Should find the psftp executable' {
            Test-Path $PSScriptRoot\..\PSSFTP\bin\psftp.exe | Should be $true
        }
    }
}

Describe 'Remove-SFTPFile' {
    Context 'Strict mode' {
        Set-StrictMode -Version latest

        It 'Should find the psftp executable' {
            Test-Path $PSScriptRoot\..\PSSFTP\bin\psftp.exe | Should be $true
        }
    }
}

Describe 'Remove-SFTPFolder' {
    Context 'Strict mode' {
        Set-StrictMode -Version latest

        It 'Should find the psftp executable' {
            Test-Path $PSScriptRoot\..\PSSFTP\bin\psftp.exe | Should be $true
        }
    }
}

Describe 'Rename-SFTPFile' {
    Context 'Strict mode' {
        Set-StrictMode -Version latest

        It 'Should find the psftp executable' {
            Test-Path $PSScriptRoot\..\PSSFTP\bin\psftp.exe | Should be $true
        }
    }
}

Describe 'Send-SFTPFile' {
    Context 'Strict mode' {
        Set-StrictMode -Version latest

        It 'Should find the psftp executable' {
            Test-Path $PSScriptRoot\..\PSSFTP\bin\psftp.exe | Should be $true
        }
    }
}