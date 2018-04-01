# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
Describe "Add-Content cmdlet tests" -Tags "CI" {
  $file1 = "file1.txt"
  Setup -File "$file1"

  Context "Add-Content should actually add content" {
    It "should Add-Content to testdrive:\$file1" {
      $result=add-content -path testdrive:\$file1 -value "ExpectedContent" -passthru
      $result| Should -BeExactly "ExpectedContent"
    }
    It "should return expected string from testdrive:\$file1" {
      $result = get-content -path testdrive:\$file1
      $result | Should -BeExactly "ExpectedContent"
    }
    It "should Add-Content to testdrive:\dynamicfile.txt with dynamic parameters" -Pending:($IsLinux -Or $IsMacOS) {#https://github.com/PowerShell/PowerShell/issues/891
      $result=add-content -path testdrive:\dynamicfile.txt -value "ExpectedContent" -passthru
      $result| Should -BeExactly "ExpectedContent"
    }
    It "should return expected string from testdrive:\dynamicfile.txt" -Pending:($IsLinux -Or $IsMacOS) {#https://github.com/PowerShell/PowerShell/issues/891
      $result = get-content -path testdrive:\dynamicfile.txt
      $result | Should -BeExactly "ExpectedContent"
    }
    It "should Add-Content to testdrive:\$file1 even when -Value is `$null" {
      $AsItWas=get-content testdrive:\$file1
      {add-content -path testdrive:\$file1 -value $null -ErrorAction Stop} | Should -Not -Throw
      get-content testdrive:\$file1 | Should -BeExactly $AsItWas
    }
    It "should throw 'ParameterArgumentValidationErrorNullNotAllowed' when -Path is `$null" {
      { Add-Content -Path $null -Value "ShouldNotWorkBecausePathIsNull" -ErrorAction Stop } | Should -Throw -ErrorId "ParameterArgumentValidationErrorNullNotAllowed,Microsoft.PowerShell.Commands.AddContentCommand"
    }
    #[BugId(BugDatabase.WindowsOutOfBandReleases, 903880)]
    It "should throw `"Cannot bind argument to parameter 'Path'`" when -Path is `$()" {
      { Add-Content -Path $() -Value "ShouldNotWorkBecausePathIsInvalid" -ErrorAction Stop } | Should -Throw -ErrorId "ParameterArgumentValidationErrorNullNotAllowed,Microsoft.PowerShell.Commands.AddContentCommand"
    }
    #[BugId(BugDatabase.WindowsOutOfBandReleases, 906022)]
    It "should throw 'NotSupportedException' when you add-content to an unsupported provider" -Skip:($IsLinux -Or $IsMacOS) {
      { Add-Content -Path HKLM:\\software\\microsoft -Value "ShouldNotWorkBecausePathIsUnsupported" -ErrorAction Stop } | Should -Throw -ErrorId "NotSupported,Microsoft.PowerShell.Commands.AddContentCommand"
    }
    #[BugId(BugDatabase.WindowsOutOfBandReleases, 9058182)]
    It "should be able to pass multiple [string]`$objects to Add-Content through the pipeline to output a dynamic Path file" -Pending:($IsLinux -Or $IsMacOS) {#https://github.com/PowerShell/PowerShell/issues/891
      "hello","world"|add-content testdrive:\dynamicfile2.txt
      $result=get-content testdrive:\dynamicfile2.txt
      $result.length | Should -Be 2
      $result[0]     | Should -BeExactly "hello"
      $result[1]     | Should -BeExactly "world"
    }
  }
}
