# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

Describe "Extended FileSystem Provider Tests for Get-ChildItem cmdlet" -Tags "CI" {
    BeforeAll {
        $restoreLocation = Get-Location

        $rootDir = Join-Path "TestDrive:" "TestDir"
        New-Item -Path $rootDir -ItemType Directory > $null

        Set-Location $rootDir

        New-Item -Path "file1.txt" -ItemType File > $null
        (New-Item -Path "filehidden1.doc" -ItemType File).Attributes = "Hidden"
        (New-Item -Path "filereadonly1.asd" -ItemType File).Attributes = "ReadOnly"

        New-Item -Path "subDir2" -ItemType Directory > $null
        Set-Location "subDir2"
        New-Item -Path "file2.txt" -ItemType File > $null
        (New-Item -Path "filehidden2.asd" -ItemType File).Attributes = "Hidden"
        (New-Item -Path "filereadonly2.doc" -ItemType File).Attributes = "ReadOnly"
        (New-Item -Path "subDir21" -ItemType Directory).Attributes = "Hidden"
        Set-Location "subDir21"
        New-Item -Path "file21.txt" -ItemType File > $null

        Set-Location $rootDir
        New-Item -Path "subDir3" -ItemType Directory > $null
        Set-Location "subDir3"
        New-Item -Path "file3.asd" -ItemType File > $null
        (New-Item -Path "filehidden3.txt" -ItemType File).Attributes = "Hidden"
        (New-Item -Path "filereadonly3.doc" -ItemType File).Attributes = "ReadOnly"

        Set-Location $rootDir
    }

    AfterAll {
        #restore the previous location
        Set-Location -Path $restoreLocation
    }

    Context 'Validate Get-ChildItem -Path' {
        It "Get-ChildItem -Path" {
            $result = Get-ChildItem -Path $rootDir
            $result.Count | Should -Be 4
            $result[0] | Should -BeOfType System.IO.DirectoryInfo
        }

        It "Get-ChildItem -Path -Hidden" {
            $result = Get-ChildItem -Path $rootDir -Hidden
            $result.Count | Should -Be 1
            $result | Should -BeOfType System.IO.FileInfo
            $result.Name | Should -BeExactly "filehidden1.doc"
        }

        It "Get-ChildItem -Path -Attribute Hidden" {
            $result = Get-ChildItem -Path $rootDir -Attributes Hidden
            $result.Count | Should -Be 1
            $result | Should -BeOfType System.IO.FileInfo
            $result.Name | Should -BeExactly "filehidden1.doc"
        }

        It "Get-ChildItem -Path -Force" {
            $result = Get-ChildItem -Path $rootDir -Force
            $result.Count | Should -Be 5
            $result | Where-Object Name -eq "filehidden1.doc" | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Validate Get-ChildItem -Path -Directory/-File' {
        It "Get-ChildItem -Path -Directory" {
            $result = Get-ChildItem -Path $rootDir -Directory
            $result.Count | Should -Be 2
        }

        It "Get-ChildItem -Path -File" {
            $result = Get-ChildItem -Path $rootDir -File
            $result.Count | Should -Be 2
        }

        It "Get-ChildItem -Path -File -Hidden" {
            $result = Get-ChildItem -Path $rootDir -File -Hidden
            $result.Count | Should -Be 1
            $result | Should -BeOfType System.IO.FileInfo
            $result.Name | Should -BeExactly "filehidden1.doc"
        }
    }

    Context 'Validate Get-ChildItem -Path -Name' {
        It "Get-ChildItem -Path -Name" {
            $result = Get-ChildItem -Path $rootDir -Name
            $result.Count | Should -Be 4
            $result[0] | Should -BeOfType [string]
        }

        It "Get-ChildItem -Path -Name -Hidden" {
            $result = Get-ChildItem -Path $rootDir -Name -Hidden
            $result.Count | Should -Be 1
            $result | Should -BeOfType [string]
            $result | Should -BeExactly "filehidden1.doc"
        }

        It "Get-ChildItem -Path -Name -Attributes Hidden" {
            $result = Get-ChildItem -Path $rootDir -Name -Attributes Hidden
            $result.Count | Should -Be 1
            $result | Should -BeOfType [string]
            $result | Should -BeExactly "filehidden1.doc"
        }

        It "Get-ChildItem -Path -Name -Force" {
            $result = Get-ChildItem -Path $rootDir -Name -Force
            $result.Count | Should -Be 5
            $result | Should -BeOfType [string]
            $result | Where-Object { $_ -eq "filehidden1.doc" } | Should -Not -BeNullOrEmpty
        }

        It "Get-ChildItem -Path -Directory -Name" {
            $result = Get-ChildItem -Path $rootDir -Directory -Name
            $result.Count | Should -Be 2
            $result[0] | Should -BeOfType [string]
        }

        It "Get-ChildItem -Path -File -Name" {
            $result = Get-ChildItem -Path $rootDir -File -Name
            $result.Count | Should -Be 2
            $result[0] | Should -BeOfType [string]
        }

        It "Get-ChildItem -Path -File -Name -Hidden" {
            $result = Get-ChildItem -Path $rootDir -File -Name -Hidden
            $result.Count | Should -Be 1
            $result | Should -BeOfType [string]
            $result | Should -BeExactly "filehidden1.doc"
        }
    }

    Context 'Validate Get-ChildItem -Path -Recurse' {
        It "Get-ChildItem -Path -Recurse" {
            $result = Get-ChildItem -Path $rootDir -Recurse
            $result.Count | Should -Be 8
        }

        It "Get-ChildItem -Path -Recurse -Hidden" {
            $result = Get-ChildItem -Path $rootDir -Recurse -Hidden
            $result.Count | Should -Be 4
            $result | Where-Object { $_.Name -eq "filehidden1.doc" -and $_.psobject.TypeNames[0] -eq "System.IO.FileInfo"} | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.Name -eq "filehidden2.asd" -and $_.psobject.TypeNames[0] -eq "System.IO.FileInfo" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.Name -eq "subDir21" -and $_.psobject.TypeNames[0] -eq "System.IO.DirectoryInfo" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.Name -eq "filehidden3.txt" -and $_.psobject.TypeNames[0] -eq "System.IO.FileInfo" } | Should -Not -BeNullOrEmpty
        }

        It "Get-ChildItem -Path -Recurse -Attributes Hidden" {
            $result = Get-ChildItem -Path $rootDir -Recurse -Attributes Hidden
            $result.Count | Should -Be 4
            $result | Where-Object { $_.Name -eq "filehidden1.doc" -and $_.psobject.TypeNames[0] -eq "System.IO.FileInfo"} | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.Name -eq "filehidden2.asd" -and $_.psobject.TypeNames[0] -eq "System.IO.FileInfo" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.Name -eq "subDir21" -and $_.psobject.TypeNames[0] -eq "System.IO.DirectoryInfo" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.Name -eq "filehidden3.txt" -and $_.psobject.TypeNames[0] -eq "System.IO.FileInfo" } | Should -Not -BeNullOrEmpty
        }

        It "Get-ChildItem -Path -Recurse -Force" {
            $result = Get-ChildItem -Path $rootDir -Recurse -Force
            $result.Count | Should -Be 13
            $result | Where-Object { $_.Name -eq "filehidden1.doc" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.Name -eq "filehidden2.asd" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.Name -eq "subDir21" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.Name -eq "filehidden3.txt" } | Should -Not -BeNullOrEmpty
        }

        It "Get-ChildItem -Path -Recurse -Directory" {
            $result = Get-ChildItem -Path $rootDir -Recurse -Directory
            $result.Count | Should -Be 2
            $result | Should -BeOfType System.IO.DirectoryInfo
            $result | Where-Object { $_.Name -eq "subDir2" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.Name -eq "subDir3" } | Should -Not -BeNullOrEmpty
        }

        It "Get-ChildItem -Path -Recurse -File" {
            $result = Get-ChildItem -Path $rootDir -Recurse -File
            $result.Count | Should -Be 6
            $result | Should -BeOfType System.IO.FileInfo
        }

        It "Get-ChildItem -Path -Recurse -File -Hidden" {
            $result = Get-ChildItem -Path $rootDir -Recurse -File -Hidden
            $result.Count | Should -Be 3
            $result | Should -BeOfType System.IO.FileInfo
            $result | Where-Object { $_.Name -eq "filehidden1.doc" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.Name -eq "filehidden2.asd" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.Name -eq "filehidden3.txt" } | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Validate Get-ChildItem -Path -Recurse -Name' {
        It "Get-ChildItem -Path -Recurse -Name" {
            $result = Get-ChildItem -Path $rootDir -Recurse -Name
            $result.Count | Should -Be 8
            $result[0] | Should -BeOfType [string]
        }

        It "Get-ChildItem -Path -Recurse -Name -Hidden" {
            $result = Get-ChildItem -Path $rootDir -Recurse -Name -Hidden
            $result.Count | Should -Be 4
            $result | Should -BeOfType [string]
            $result | Where-Object { $_ -eq "filehidden1.doc" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_ -eq "subDir2\filehidden2.asd" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_ -eq "subDir2\subDir21" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_ -eq "subDir3\filehidden3.txt" } | Should -Not -BeNullOrEmpty
        }

        It "Get-ChildItem -Path -Recurse -Name -Force" {
            $result = Get-ChildItem -Path $rootDir -Recurse -Name -Force
            $result.Count | Should -Be 13
            $result | Should -BeOfType [string]
            $result | Where-Object { $_ -eq "filehidden1.doc" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_ -eq "subDir2\filehidden2.asd" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_ -eq "subDir2\subDir21" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_ -eq "subDir3\filehidden3.txt" } | Should -Not -BeNullOrEmpty
        }

        It "Get-ChildItem -Path -Recurse -Name -Directory" {
            $result = Get-ChildItem -Path $rootDir -Recurse -Name -Directory
            $result.Count | Should -Be 2
            $result | Should -BeOfType [string]
            $result | Where-Object { $_ -eq "subDir2" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_ -eq "subDir3" } | Should -Not -BeNullOrEmpty
        }

        It "Get-ChildItem -Path -Recurse -Name -Attributes Directory" {
            $result = Get-ChildItem -Path $rootDir -Recurse -Name -Attributes Directory
            $result.Count | Should -Be 2
            $result | Should -BeOfType [string]
            $result | Where-Object { $_ -eq "subDir2" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_ -eq "subDir3" } | Should -Not -BeNullOrEmpty
        }

        It "Get-ChildItem -Path -Recurse -Name -File" {
            $result = Get-ChildItem -Path $rootDir -Recurse -Name -File
            $result.Count | Should -Be 6
            $result | Should -BeOfType [string]
        }

        It "Get-ChildItem -Path -Recurse -Name -File -Hidden" {
            $result = Get-ChildItem -Path $rootDir -Recurse -Name -File -Hidden
            $result.Count | Should -Be 3
            $result | Should -BeOfType [string]
            $result | Where-Object { $_ -eq "filehidden1.doc" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_ -eq "subDir2\filehidden2.asd" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_ -eq "subDir3\filehidden3.txt" } | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Validate Get-ChildItem -Path -Filter' {
        It 'Get-ChildItem -Path -Filter "*.txt"' {
            $result = Get-ChildItem -Path $rootDir -Filter "*.txt"
            $result.Count | Should -Be 1
            $result[0] | Should -BeOfType System.IO.FileInfo
            $result.Name | Should -BeExactly "file1.txt"
        }

        It 'Get-ChildItem -Path -Filter "file*"' {
            $result = Get-ChildItem -Path $rootDir -Filter "file*"
            $result.Count | Should -Be 2
            $result | Should -BeOfType System.IO.FileInfo
            $result | Where-Object { $_.Name -eq "file1.txt" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.Name -eq "filereadonly1.asd" } | Should -Not -BeNullOrEmpty
        }

        It 'Get-ChildItem -Path -Filter "file?.txt"' {
            $result = Get-ChildItem -Path $rootDir -Filter "file?.txt"
            $result.Count | Should -Be 1
            $result | Should -BeOfType System.IO.FileInfo
            $result.Name | Should -BeExactly "file1.txt"
        }

        It 'Get-ChildItem -Path -Filter "file*" -Hidden' {
            $result = Get-ChildItem -Path $rootDir -Filter "file*" -Hidden
            $result.Count | Should -Be 1
            $result | Should -BeOfType System.IO.FileInfo
            $result.Name | Should -BeExactly "filehidden1.doc"
        }

        It 'Get-ChildItem -Path -Filter "file*" -Force' {
            $result = Get-ChildItem -Path $rootDir -Filter "file*" -Force
            $result.Count | Should -Be 3
            $result | Should -BeOfType System.IO.FileInfo
            $result | Where-Object { $_.Name -eq "file1.txt" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.Name -eq "filehidden1.doc" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.Name -eq "filereadonly1.asd" } | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Validate Get-ChildItem -Path -Filter -Recurse' {
        It 'Get-ChildItem -Path -Filter "*.txt" -Recurse' {
            $result = Get-ChildItem -Path $rootDir -Filter "*.txt" -Recurse
            $result.Count | Should -Be 2
            $result | Should -BeOfType System.IO.FileInfo
            $result | Where-Object { $_.Name -eq "file1.txt" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.Name -eq "file2.txt" } | Should -Not -BeNullOrEmpty
        }

        It 'Get-ChildItem -Path -Filter "file*" -Recurse' {
            $result = Get-ChildItem -Path $rootDir -Filter "file*" -Recurse
            $result.Count | Should -Be 6
            $result | Should -BeOfType System.IO.FileInfo
            $result | Where-Object { $_.Name -eq "file1.txt" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.Name -eq "filereadonly1.asd" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.Name -eq "file2.txt" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.Name -eq "filereadonly2.doc" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.Name -eq "file3.asd" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.Name -eq "filereadonly3.doc" } | Should -Not -BeNullOrEmpty
        }

        It 'Get-ChildItem -Path -Filter "file?.*" -Recurse' {
            $result = Get-ChildItem -Path $rootDir -Filter "file?.*" -Recurse
            $result.Count | Should -Be 3
            $result | Should -BeOfType System.IO.FileInfo
            $result | Where-Object { $_.Name -eq "file1.txt" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.Name -eq "file2.txt" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.Name -eq "file3.asd" } | Should -Not -BeNullOrEmpty
        }

        It 'Get-ChildItem -Path $rootDir -Filter "file*" -Hidden -Recurse' {
            $result = Get-ChildItem -Path $rootDir -Filter "file*" -Hidden -Recurse
            $result.Count | Should -Be 3
            $result | Should -BeOfType System.IO.FileInfo
            $result | Where-Object { $_.Name -eq "filehidden1.doc" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.Name -eq "filehidden2.asd" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.Name -eq "filehidden3.txt" } | Should -Not -BeNullOrEmpty
        }

        It 'Get-ChildItem -Path $rootDir -Filter "file*" -Force -Recurse' {
            $result = Get-ChildItem -Path $rootDir -Filter "file*" -Force -Recurse
            $result.Count | Should -Be 10
            $result | Should -BeOfType System.IO.FileInfo
        }
    }

    Context 'Validate Get-ChildItem -Path -Filter -Recurse -Name' {
        It 'Get-ChildItem -Path -Filter "*.txt" -Recurse -Name' {
            $result = Get-ChildItem -Path $rootDir -Filter "*.txt" -Recurse -Name
            $result.Count | Should -Be 2
            $result | Should -BeOfType [string]
            $result | Where-Object { $_ -eq "file1.txt" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_ -eq "subDir2\file2.txt" } | Should -Not -BeNullOrEmpty
        }

        It 'Get-ChildItem -Path -Filter "file*" -Recurse -Name' {
            $result = Get-ChildItem -Path $rootDir -Filter "file*" -Recurse -Name
            $result.Count | Should -Be 6
            $result | Should -BeOfType [string]
            $result | Where-Object { $_ -eq "file1.txt" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_ -eq "filereadonly1.asd" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_ -eq "subDir2\file2.txt" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_ -eq "subDir2\filereadonly2.doc" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_ -eq "subDir3\file3.asd" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_ -eq "subDir3\filereadonly3.doc" } | Should -Not -BeNullOrEmpty
        }

        It 'Get-ChildItem -Path -Filter "file????only3.*" -Recurse -Name' {
            $result = Get-ChildItem -Path $rootDir -Filter "file????only3.*" -Recurse -Name
            $result.Count | Should -Be 1
            $result | Should -BeOfType [string]
            $result | Should -BeExactly "subDir3\filereadonly3.doc"
        }

        It 'Get-ChildItem -Path -Filter "file*" -Hidden -Recurse -Name' {
            $result = Get-ChildItem -Path $rootDir -Filter "file*" -Hidden -Recurse -Name
            $result.Count | Should -Be 3
            $result | Should -BeOfType [string]
            $result | Where-Object { $_ -eq "filehidden1.doc" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_ -eq "subDir2\filehidden2.asd" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_ -eq "subDir3\filehidden3.txt" } | Should -Not -BeNullOrEmpty
        }

        It 'Get-ChildItem -Path -Filter "file*" -Force -Recurse -Name' {
            $result = Get-ChildItem -Path $rootDir -Filter "file*" -Force -Recurse -Name
            $result.Count | Should -Be 10
            $result | Should -BeOfType [string]
        }
    }

    Context 'Validate Get-ChildItem -Path -Include' {
        It 'Get-ChildItem -Path $-Include "*.txt"' -Pending:$true {    # Pending due to a bug
            $result = Get-ChildItem -Path $rootDir -Include "*.txt"
            $result.Count | Should -Be 1
            $result | Should -BeOfType System.IO.FileInfo
            $result.Name | Should -BeExactly "file1.txt"
        }

        It 'Get-ChildItem -Path -Include "*.txt" -Recurse' {
            $result = Get-ChildItem -Path $rootDir -Include "*.txt" -Recurse
            $result.Count | Should -Be 2
            $result | Should -BeOfType System.IO.FileInfo
            $result | Where-Object { $_.Name -eq "file1.txt" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.Name -eq "file2.txt" } | Should -Not -BeNullOrEmpty
        }

        It 'Get-ChildItem -Path -Include "*.txt" -Recurse -Name' {
            $result = Get-ChildItem -Path $rootDir -Include "*.txt" -Recurse -Name
            $result.Count | Should -Be 2
            $result | Should -BeOfType [string]
            $result | Where-Object { $_ -eq "file1.txt" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_ -eq "subDir2\file2.txt" } | Should -Not -BeNullOrEmpty
        }

        It 'Get-ChildItem -Path -Include "*.t?t" -Recurse -Name' {
            $result = Get-ChildItem -Path $rootDir -Include "*.t?t" -Recurse -Name
            $result.Count | Should -Be 2
            $result | Should -BeOfType [string]
            $result | Where-Object { $_ -eq "file1.txt" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_ -eq "subDir2\file2.txt" } | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Validate Get-ChildItem -Path -Include' {
        It 'Get-ChildItem -Path -Include "*.txt" -Force' -Pending:$true {    # Pending due to a bug
            $result = Get-ChildItem -Path $rootDir -Include "*.txt" -Force
            $result.Count | Should -Be 1
            $result | Should -BeOfType System.IO.FileInfo
            $result.Name | Should -BeExactly "file1.txt"
        }

        It 'Get-ChildItem -Path -Include "*.txt" -Recurse -Force' {
            $result = Get-ChildItem -Path $rootDir -Include "*.txt" -Recurse -Force
            $result.Count | Should -Be 4
            $result | Should -BeOfType System.IO.FileInfo
            $result | Where-Object { $_.Name -eq "file1.txt" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.Name -eq "file2.txt" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.Name -eq "file21.txt" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.Name -eq "filehidden3.txt" } | Should -Not -BeNullOrEmpty
        }

        It 'Get-ChildItem -Path -Include "*.txt" -Recurse -Name -Force' {
            $result = Get-ChildItem -Path $rootDir -Include "*.txt" -Recurse -Name -Force
            $result.Count | Should -Be 4
            $result | Should -BeOfType [string]
            $result | Where-Object { $_ -eq "file1.txt" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_ -eq "subDir2\file2.txt" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_ -eq "subDir3\filehidden3.txt" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_ -eq "subDir2\subDir21\file21.txt" } | Should -Not -BeNullOrEmpty
        }

        It 'Get-ChildItem -Path -Include "*.t?t" -Recurse -Name -Force' {
            $result = Get-ChildItem -Path $rootDir -Include "*.t?t" -Recurse -Name -Force
            $result.Count | Should -Be 4
            $result | Should -BeOfType [string]
            $result | Where-Object { $_ -eq "file1.txt" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_ -eq "subDir2\file2.txt" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_ -eq "subDir3\filehidden3.txt" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_ -eq "subDir2\subDir21\file21.txt" } | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Validate Get-ChildItem -Path -Exclude' {
        It 'Get-ChildItem -Path $rootDir -Exclude "*.txt"' {
            $result = Get-ChildItem -Path $rootDir -Exclude "*.txt"
            $result.Count | Should -Be 3
        }

        It 'Get-ChildItem -Path $rootDir -Exclude "file*"' {
            $result = Get-ChildItem -Path $rootDir -Exclude "file*"
            $result.Count | Should -Be 2
            $result | Should -BeOfType System.IO.DirectoryInfo
            $result | Where-Object { $_.Name -eq "subDir2" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.Name -eq "subDir3" } | Should -Not -BeNullOrEmpty
        }

        It 'Get-ChildItem -Path -Exclude "*.txt" -Recurse' {
            $result = Get-ChildItem -Path $rootDir -Exclude "*.txt" -Recurse
            $result.Count | Should -Be 6
            $result | Where-Object { $_.Name -like "*.txt" } | Should -BeNullOrEmpty
        }

        It 'Get-ChildItem -Path -Exclude "*.tx?" -Recurse' {
            $result = Get-ChildItem -Path $rootDir -Exclude "*.tx?" -Recurse
            $result.Count | Should -Be 6
            $result | Where-Object { $_.Name -like "*.tx?" } | Should -BeNullOrEmpty
        }

        It 'Get-ChildItem -Path -Exclude "*.txt" -Recurse -Name' {
            $result = Get-ChildItem -Path $rootDir -Exclude "*.txt" -Recurse -Name
            $result | Should -BeOfType [string]
            $result.Count | Should -Be 6
            $result | Where-Object { $_.Name -like "*.txt" } | Should -BeNullOrEmpty
        }

        It 'Get-ChildItem -Path -Exclude "*.txt" -Recurse -Hidden' {
            $result = Get-ChildItem -Path $rootDir -Exclude "*.txt" -Recurse -Hidden
            $result.Count | Should -Be 3
            $result | Where-Object { $_.Name -eq "filehidden1.doc" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.Name -eq "filehidden2.asd" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.Name -eq "subDir21" } | Should -Not -BeNullOrEmpty
        }

        It 'Get-ChildItem -Path -Exclude "*.txt" -Recurse -Hidden -Name' {
            $result = Get-ChildItem -Path $rootDir -Exclude "*.txt" -Recurse -Hidden -Name
            $result.Count | Should -Be 3
            $result | Where-Object { $_ -eq "filehidden1.doc" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_ -eq "subDir2\filehidden2.asd" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_ -eq "subDir2\subDir21" } | Should -Not -BeNullOrEmpty
        }

        It 'Get-ChildItem -Path -Exclude "*.txt" -Include "file*" -Recurse' {
            $result = Get-ChildItem -Path $rootDir -Exclude "*.txt" -Include "file*" -Recurse
            $result.Count | Should -Be 4
            $result | Where-Object { $_.Name -like "*.txt" } | Should -BeNullOrEmpty
            $result | Where-Object { $_.Name -notlike "file*" } | Should -BeNullOrEmpty
        }
    }

    Context 'Validate Get-ChildItem -Path -Exclude -Force' {
        It 'Get-ChildItem -Path -Exclude "*.txt" -Force' {
            $result = Get-ChildItem -Path $rootDir -Exclude "*.txt" -Force
            $result.Count | Should -Be 4
        }

        It 'Get-ChildItem -Path -Exclude "file*" -Recurse -Force' {
            $result = Get-ChildItem -Path $rootDir -Exclude "file*" -Recurse -Force
            $result.Count | Should -Be 3
            $result | Should -BeOfType System.IO.DirectoryInfo
            $result | Where-Object { $_.Name -eq "subDir2" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.Name -eq "subDir3" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.Name -eq "subDir21" } | Should -Not -BeNullOrEmpty
        }

        It 'Get-ChildItem -Path -Exclude "file*" -Force -Recurse -Name' {
            $result = Get-ChildItem -Path $rootDir -Exclude "file*" -Force -Recurse -Name
            $result.Count | Should -Be 3
            $result | Should -BeOfType [string]
            $result | Where-Object { $_ -eq "subDir2" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_ -eq "subDir3" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_ -eq "subDir2\subDir21" } | Should -Not -BeNullOrEmpty
        }

        It 'Get-ChildItem -Path -Exclude "*.txt" -Recurse' {
            $result = Get-ChildItem -Path $rootDir -Exclude "*.txt" -Recurse
            $result.Count | Should -Be 6
            $result | Where-Object { $_.Name -like "*.txt" } | Should -BeNullOrEmpty
        }

        It 'Get-ChildItem -Path -Exclude "*.txt" -Force -Include "file*" -Recurse' {
            $result = Get-ChildItem -Path $rootDir -Exclude "*.txt" -Force -Include "file*" -Recurse
            $result.Count | Should -Be 6
            $result | Where-Object { $_.Name -like "*.txt" } | Should -BeNullOrEmpty
            $result | Where-Object { $_.Name -notlike "file*" } | Should -BeNullOrEmpty
        }
    }

    Context 'Validate Get-ChildItem -Path -Exclude/-Include with some filters' {
        It 'Get-ChildItem -Path -Exclude "*.txt","*.asd" -Force -Include "file*" -Recurse' {
            $result = Get-ChildItem -Path $rootDir -Exclude "*.txt","*.asd" -Force -Include "file*" -Recurse
            $result.Count | Should -Be 3
            $result | Where-Object { $_.Name -like "*.txt" } | Should -BeNullOrEmpty
            $result | Where-Object { $_.Name -like "*.asd" } | Should -BeNullOrEmpty
            $result | Where-Object { $_.Name -notlike "file*" } | Should -BeNullOrEmpty
        }

        It 'Get-ChildItem -Path -Exclude "*.txt","*.asd" -Include "file*" -Recurse' {
            $result = Get-ChildItem -Path $rootDir -Exclude "*.txt","*.asd" -Include "file*" -Recurse
            $result.Count | Should -Be 2
            $result | Where-Object { $_.Name -like "*.txt" } | Should -BeNullOrEmpty
            $result | Where-Object { $_.Name -like "*.asd" } | Should -BeNullOrEmpty
            $result | Where-Object { $_.Name -notlike "file*" } | Should -BeNullOrEmpty
        }

        It 'Get-ChildItem -Path -Exclude "*.txt" -Force -Include "*2.*","*3.*" -Recurse' {
            $result = Get-ChildItem -Path $rootDir -Exclude "*.txt" -Force -Include "*2.*","*3.*" -Recurse
            $result.Count | Should -Be 4
            $result | Where-Object { $_.Name -like "*.txt" } | Should -BeNullOrEmpty
            $result | Where-Object { $_.Name -notlike "*2.*" -and $_.Name -notlike "*3.*" } | Should -BeNullOrEmpty
        }

        It 'Get-ChildItem -Path -Exclude "*.txt" -Include "*2.*","*3.*" -Recurse' {
            $result = Get-ChildItem -Path $rootDir -Exclude "*.txt" -Include "*2.*","*3.*" -Recurse
            $result.Count | Should -Be 3
            $result | Where-Object { $_.Name -like "*.txt" } | Should -BeNullOrEmpty
            $result | Where-Object { $_.Name -notlike "*2.*" -and $_.Name -notlike "*3.*" } | Should -BeNullOrEmpty
        }
    }
}
