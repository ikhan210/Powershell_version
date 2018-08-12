# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
Describe "Rename-Item tests" -Tag "CI" {
    BeforeAll {
        Setup -f originalFile.txt -content "This is content"
        $source = "$TESTDRIVE/originalFile.txt"
        $target = "$TESTDRIVE/ItemWhichHasBeenRenamed.txt"
        Setup -f [orig-file].txt -content "This is not content"
        $sourceSp = "$TestDrive/``[orig-file``].txt"
        $targetSpName = "ItemWhichHasBeen[Renamed].txt"
        $targetSp = "$TestDrive/ItemWhichHasBeen``[Renamed``].txt"
        Setup -Dir [test-dir]
        $wdSpName = "$TestDrive/[test-dir]"
        $wdSp = "$TestDrive/``[test-dir``]"
    }
    It "Rename-Item will rename a file" {
        Rename-Item $source $target
        test-path $source | Should -BeFalse
        test-path $target | Should -BeTrue
        "$target" | Should -FileContentMatchExactly "This is content"
    }
    It "Rename-Item will rename a file when path contains special char" {
        Rename-Item $sourceSp $targetSpName
        $sourceSp | Should -Not -Exist
        $targetSp | Should -Exist
        $targetSp | Should -FileContentMatchExactly "This is not content"
    }
    It "Rename-Item will rename a file when path and cwd contains special char" {
        $content = "This is content"
        $oldSpName = "[orig]file.txt"
        $oldSpBName = "``[orig``]file.txt"
        $oldSp = "$wdSp/``[orig``]file.txt"
        $newSpName = "[renamed]file.txt"
        $newSp = "$wdSp/``[renamed``]file.txt"
        In $wdSp -Execute {
            $null = New-Item -Name $oldSpName -ItemType File -Value $content -Force
            Rename-Item $oldSpBName $newSpName
        }
        $oldSp | Should -Not -Exist
        $newSp | Should -Exist
        $newSp | Should -FileContentMatchExactly $content
    }
}
