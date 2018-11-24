# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

Describe "Tests for New-PSDrive cmdlet." -Tag "CI","RequireAdminOnWindows" {
    Context "Validate New-PSDrive Cmdlet with -Persist switch." {
        BeforeEach {
            $PSDriveName = "W"
            $RemoteShare = "\\$env:COMPUTERNAME\$($env:SystemDrive.replace(':','$\'))"
        }

        AfterEach {
            Remove-PSDrive -Name $PSDriveName -Force -ErrorAction SilentlyContinue
        }

        It "Should not throw exception for persistent PSDrive creation." -Skip:(-not $IsWindows) {
            { New-PSDrive -Name $PSDriveName -PSProvider FileSystem -Root $RemoteShare -Persist -ErrorAction Stop } | Should -Not -Throw
        }

        it "Should throw exception if root is not a remote share." {
            { New-PSDrive -Root "TestDrive:\" -PSProvider FileSystem -Name $PSDriveName -Persist -ErrorAction Stop } | Should -Throw -ErrorId 'DriveRootNotNetworkPath'
        }

        it "Should throw exception if PSDrive is not a drive letter supported by operating system." {
            $PSDriveName = 'AB'
            { New-PSDrive -Root $RemoteShare -PSProvider FileSystem -Name $PSDriveName -Persist -ErrorAction Stop } | Should -Throw -ErrorId 'DriveNameNotSupportedForPersistence'
        }
    }
}