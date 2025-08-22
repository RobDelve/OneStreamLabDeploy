# Private.Tests.ps1 - Pester tests for helper functions

# Import the functions to be tested
. "$PSScriptRoot\..\Private\HelperFunctions.ps1"

Describe 'Helper Function Tests' {
    Context 'New-OSLabDirectory' {
        $testDir = Join-Path $env:TEMP 'PesterTestDir'

        It 'should create a new directory if it does not exist' {
            New-OSLabDirectory -Path $testDir
            (Test-Path $testDir -PathType Container) | Should -Be $true
        }

        It 'should not fail if the directory already exists' {
            { New-OSLabDirectory -Path $testDir } | Should -Not -Throw
        }

        AfterAll {
            Remove-Item $testDir -Recurse -Force
        }
    }

    Context 'Set-OSRegistryValue' {
        $testKey = 'HKCU:\Software\PesterTest'

        It 'should create a registry key and set a value' {
            Set-OSRegistryValue -Path $testKey -Name 'TestValue' -Value 'Success'
            (Get-ItemProperty -Path $testKey).TestValue | Should -Be 'Success'
        }

        AfterAll {
            Remove-Item $testKey -Recurse -Force
        }
    }

    # Additional tests for Install-OSSoftware and New-OSScheduledTask would be added here.
    # Testing installers and scheduled tasks often requires more complex mocking or setup.
}
