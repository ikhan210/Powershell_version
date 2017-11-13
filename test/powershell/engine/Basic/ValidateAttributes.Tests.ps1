Describe 'Validate Attributes Tests' -Tags 'CI' {

    Context "ValidateCount" {
        BeforeAll {
           $testCases = @(
                @{
                    ScriptBlock              = { function foo { param([ValidateCount(-1,2)] [string[]] $bar) }; foo }
                    FullyQualifiedErrorId    = "ExceptionConstructingAttribute"
                    InnerErrorId             = "" 
                }
                @{
                    ScriptBlock              = { function foo { param([ValidateCount(1,-1)] [string[]] $bar) }; foo }
                    FullyQualifiedErrorId    = "ExceptionConstructingAttribute"          
                    InnerErrorId             = "" 
                }
                @{ 
                    ScriptBlock             = { function foo { param([ValidateCount(2, 1)] [string[]] $bar) }; foo }
                    FullyQualifiedErrorId   = "ValidateRangeMaxLengthSmallerThanMinLength"
                    InnerErrorId            = "" 
                }
                @{ 
                    ScriptBlock             = { function foo { param([ValidateCount(2, 2)] [string[]] $bar) }; foo 1 } 
                    FullyQualifiedErrorId   = "ParameterArgumentValidationError,foo"
                    InnerErrorId            = "ValidateCountExactFailure" 
                }
                @{ 
                    ScriptBlock             = { function foo { param([ValidateCount(2, 3)] [string[]] $bar) }; foo 1 }
                    FullyQualifiedErrorId   = "ParameterArgumentValidationError,foo"
                    InnerErrorId            = "ValidateCountMinMaxFailure" 
                }
                @{ 
                    ScriptBlock             = { function foo { param([ValidateCount(2, 3)] [string[]] $bar) }; foo 1,2,3,4 }
                    FullyQualifiedErrorId   = "ParameterArgumentValidationError,foo"
                    InnerErrorId            = "ValidateCountMinMaxFailure"
                }
           )
        }

        It 'Exception: <FullyQualifiedErrorId>:<InnerErrorId>' -TestCases $testCases {
            param($ScriptBlock, $FullyQualifiedErrorId, $InnerErrorId)

            $ScriptBlock | ShouldBeErrorId $FullyQualifiedErrorId
            if ($InnerErrorId) {
                $error[0].exception.innerexception.errorrecord.FullyQualifiedErrorId | Should Be $InnerErrorId
            }
        }

        It 'No Exception: valid argument count' {
            { function foo { param([ValidateCount(2, 4)] [string[]] $bar) }; foo 1,2,3,4 } | Should Not Throw
        }
    }

    Context "ValidateRange - ParameterConstuctors" {
        BeforeAll {
            $testCases = @(
                @{ 
                    ScriptBlock             = { function foo { param([ValidateRange('xPositive')] $bar) }; foo }
                    FullyQualifiedErrorId   = "ExceptionConstructingAttribute"
                    InnerErrorId            = "SubstringDisambiguationEnumParseThrewAnException" 
                }
                @{ 
                    ScriptBlock             = { function foo { param([ValidateRange(2,1)] [int] $bar) }; foo }
                    FullyQualifiedErrorId   = "MaxRangeSmallerThanMinRange"
                    InnerErrorId            = "" 
                }
                @{ 
                    ScriptBlock             = { function foo { param([ValidateRange("one",10)] $bar) }; foo }
                    FullyQualifiedErrorId   = "MinRangeNotTheSameTypeOfMaxRange"
                    InnerErrorId            = "" 
                }
                @{ 
                    ScriptBlock             = { function foo { param([ValidateRange(1,"two")] $bar) }; foo }
                    FullyQualifiedErrorId   = "MinRangeNotTheSameTypeOfMaxRange"
                    InnerErrorId            = "" 
                }
           )
        }

        It 'Exception: <FullyQualifiedErrorId>:<InnerErrorId>' -TestCases $testCases {
            param($ScriptBlock, $FullyQualifiedErrorId, $InnerErrorId)

            $ScriptBlock | ShouldBeErrorId $FullyQualifiedErrorId
            if ($InnerErrorId) {
                $error[0].exception.innerexception.errorrecord.FullyQualifiedErrorId | Should Be $InnerErrorId
            }
        }
    }
    Context "ValidateRange - User Defined Range"{
        BeforeAll {
           $testCases = @(
                @{ 
                    ScriptBlock             = { function foo { param([ValidateRange(1,10)] [int] $bar) }; foo -1 }
                    FullyQualifiedErrorId   = "ParameterArgumentValidationError,foo"
                    InnerErrorId            = "ValidateRangeTooSmall" 
                }
                @{ 
                    ScriptBlock             = { function foo { param([ValidateRange(1,10)] [int] $bar) }; foo 11 }
                    FullyQualifiedErrorId   = "ParameterArgumentValidationError,foo"
                    InnerErrorId            = "ValidateRangeTooBig" 
                }
                @{ 
                    ScriptBlock             = { function foo { param([ValidateRange(1,10)] $bar) }; foo "one" }
                    FullyQualifiedErrorId   = "ParameterArgumentValidationError,foo"
                    InnerErrorId            = "ValidationRangeElementType" 
                }
           )

            $validTestCases = @(
               @{ 
                   ScriptBlock = { function foo { param([ValidateRange(1,10)] [int] $bar) }; foo 5 }
                }
           )
        }

        It 'Exception: <FullyQualifiedErrorId>:<InnerErrorId>' -TestCases $testCases {
            param($ScriptBlock, $FullyQualifiedErrorId, $InnerErrorId)

            $ScriptBlock | ShouldBeErrorId $FullyQualifiedErrorId
            if ($InnerErrorId) {
                $error[0].exception.innerexception.errorrecord.FullyQualifiedErrorId | Should Be $InnerErrorId
            }
        }

        It 'No Exception: value within range' -TestCases $validTestCases {
            param($ScriptBlock)
                $ScriptBlock | Should Not Throw
        }
    }

    Context "ValidateRange - Predefined Range" {
        BeforeAll {
           $testCases = @(
                @{ 
                    ScriptBlock             = { function foo { param([ValidateRange("Positive")] [int] $bar) }; foo -1 }
                    RangeType               = "Positive"
                    FullyQualifiedErrorId   = "ParameterArgumentValidationError,foo"
                    InnerErrorId            = "ValidateRangePositiveFailure" 
                }
                @{ 
                    ScriptBlock             = { function foo { param([ValidateRange("Positive")] [int] $bar) }; foo 0 }
                    RangeType               = "Positive"
                    FullyQualifiedErrorId   = "ParameterArgumentValidationError,foo"
                    InnerErrorId            = "ValidateRangePositiveFailure" 
                }
                @{ 
                    ScriptBlock             = { function foo { param([ValidateRange("Positive")] $bar) }; foo "one" }
                    RangeType               = "Positive"
                    FullyQualifiedErrorId   = "ParameterArgumentValidationError,foo"
                    InnerErrorId            = "" 
                }
                @{
                    ScriptBlock             = { function foo { param([ValidateRange('NonNegative')] [int] $bar) }; foo -1 }
                    RangeType               = "NonNegative"
                    FullyQualifiedErrorId   = "ParameterArgumentValidationError,foo"
                    InnerErrorId            = "ValidateRangeNonNegativeFailure" 
                }
                @{ 
                   ScriptBlock              = { function foo { param([ValidateRange('NonNegative')] $bar) }; foo "one" }
                   RangeType                = "NonNegative"
                   FullyQualifiedErrorId    = "ParameterArgumentValidationError,foo"
                   InnerErrorId             = "" 
                }
                @{ 
                    ScriptBlock             = { function foo { param([ValidateRange('Negative')] [int] $bar) }; foo 1 }
                    RangeType               = "Negative"
                    FullyQualifiedErrorId   = "ParameterArgumentValidationError,foo"
                    InnerErrorId            = "ValidateRangeNegativeFailure" 
                }
                @{ 
                    ScriptBlock             = { function foo { param([ValidateRange('Negative')] [int] $bar) }; foo 0 }
                    RangeType               = "Negative"
                    FullyQualifiedErrorId   = "ParameterArgumentValidationError,foo"
                    InnerErrorId            = "ValidateRangeNegativeFailure" 
                }
                @{ 
                    ScriptBlock             = { function foo { param([ValidateRange('Negative')] $bar) }; foo "one" }
                    RangeType               = "Negative"
                    FullyQualifiedErrorId   = "ParameterArgumentValidationError,foo"
                    InnerErrorId            = "" 
                }
                @{ 
                    ScriptBlock             = { function foo { param([ValidateRange('NonPositive')] $bar) }; foo 1 }
                    RangeType               = "NonPositive"
                    FullyQualifiedErrorId   = "ParameterArgumentValidationError,foo"
                    InnerErrorId            = "ValidateRangeNonPositiveFailure" 
                }
                @{
                    ScriptBlock             = { function foo { param([ValidateRange('NonPositive')] $bar) }; foo "one" }
                    RangeType               = "NonPositive"
                    FullyQualifiedErrorId   = "ParameterArgumentValidationError,foo"
                    InnerErrorId            = "" 
                }
           )

           $validTestCases = @(
                @{ 
                   ScriptBlock  = { function foo { param([ValidateRange("Positive")] [int] $bar) }; foo 15 }
                   RangeType    = "Positive"
                   TestValue    = 15
                }
                @{ 
                   ScriptBlock  = { function foo { param([ValidateRange("Positive")] [double]$bar) }; foo ([double]::MaxValue) }; 
                   RangeType    = "Positive"
                   TestValue    = [double]::MaxValue
                }
                @{ 
                   ScriptBlock  = { function foo { param([ValidateRange('NonNegative')] [int] $bar) }; foo 0 }
                   RangeType    = "NonNegative"
                   TestValue    = 0
                }
                @{ 
                   ScriptBlock  = { function foo { param([ValidateRange('NonNegative')] [int] $bar) }; foo 15 }
                   RangeType    = "NonNegative"
                   TestValue    = 15
                }
                @{ 
                   ScriptBlock  = { function foo { param([ValidateRange('NonNegative')] [double]$bar) }; foo ([double]::MaxValue) }; 
                   RangeType    = "NonNegative"
                   TestValue    = [double]::MaxValue
                }
                @{ 
                    ScriptBlock = { function foo { param([ValidateRange('Negative')] [int] $bar) }; foo -15 }
                    RangeType   = "Negative"
                    TestValue   = -15
                }
                @{ 
                    ScriptBlock = { function foo { param([ValidateRange('Negative')] [double]$bar) }; foo ([double]::MinValue) }; 
                    TestValue   = [double]::MinValue
                    RangeType   = "Negative"
                }
                @{ 
                    ScriptBlock = { function foo { param([ValidateRange('NonPositive')] [int] $bar) }; foo 0 }
                    RangeType   = "NonPositive"
                    TestValue   = 0
                }
                @{ 
                    ScriptBlock = { function foo { param([ValidateRange('NonPositive')] [int] $bar) }; foo -15 }
                    RangeType   = "NonPositive"
                    TestValue   = -15
                }
                @{ 
                    ScriptBlock = { function foo { param([ValidateRange('NonPositive')] [double]$bar) }; foo ([double]::MinValue) }
                    RangeType   = "NonPositive"
                    TestValue   = [double]::MinValue
                }
           )
        }

        It 'Exception: <FullyQualifiedErrorId>:<InnerErrorId>, RangeType: <RangeType>' -TestCases $testCases {
            param($ScriptBlock, $RangeType, $FullyQualifiedErrorId, $InnerErrorId)

            $ScriptBlock | ShouldBeErrorId $FullyQualifiedErrorId
            if ($InnerErrorId) {
                $error[0].exception.innerexception.errorrecord.FullyQualifiedErrorId | Should Be $InnerErrorId
            }
        }

        It 'No Exception: RangeType: <RangeType> - argument "<TestValue>"' -TestCases $validTestCases {
            param($ScriptBlock, $RangeType, $testValue)
                $ScriptBlock | Should Not Throw
        }
    }

    Context "ValidateNotNull, ValidateNotNullOrEmpty and Not-Null-Or-Empty check for Mandatory parameter" {

        BeforeAll {
            function MandType {
                param(
                    [Parameter(Mandatory, ParameterSetName = "ByteArray")]
                    [byte[]] $ByteArray,

                    [Parameter(Mandatory, ParameterSetName = "ByteList")]
                    [System.Collections.Generic.List[byte]] $ByteList,

                    [Parameter(Mandatory, ParameterSetName = "ByteCollection")]
                    [System.Collections.ObjectModel.Collection[byte]] $ByteCollection,

                    [Parameter(ParameterSetName = "Default")]
                    $Value
                )
            }

            function NotNullFunc {
                param(
                    [ValidateNotNull()]
                    $Value,
                    [string] $TestType
                )

                switch ($TestType) {
                    "COM-Enumerable" { $Value | ForEach-Object Name }
                    "Enumerator"     {
                        $items = foreach ($i in $Value) { $i }
                        $items -join ","
                    }
                }
            }

            function NotNullOrEmptyFunc {
                param(
                    [ValidateNotNullOrEmpty()]
                    $Value,
                    [string] $TestType
                )

                switch ($TestType) {
                    "COM-Enumerable" { $Value | ForEach-Object Name }
                    "Enumerator"     {
                        $items = foreach ($i in $Value) { $i }
                        $items -join ","
                    }
                }
            }

            $filePath  = Join-Path -Path $PSHOME -ChildPath System.Management.Automation.dll
            $byteArray = [System.IO.File]::ReadAllBytes($filePath)
            $byteList  = [System.Collections.Generic.List[byte]] $byteArray
            $byteCollection = [System.Collections.ObjectModel.Collection[byte]] $byteArray
            ## Use the running time of 'MandType -Value $byteArray' as the baseline time
            $baseline = (Measure-Command { MandType -Value $byteArray }).Milliseconds
            ## Running time should be less than 'expected'
            $expected = $baseline + 20

            if ($IsWindows) {
                $null = New-Item -Path $TESTDRIVE/file1 -ItemType File
            }

            $testCases = @(
                @{ ScriptBlock = { MandType -ByteArray $byteArray } }
                @{ ScriptBlock = { MandType -ByteList $byteList } }
                @{ ScriptBlock = { MandType -ByteCollection $byteCollection } }
                @{ ScriptBlock = { NotNullFunc -Value $byteArray } }
                @{ ScriptBlock = { NotNullFunc -Value $byteList } }
                @{ ScriptBlock = { NotNullFunc -Value $byteCollection } }
                @{ ScriptBlock = { NotNullOrEmptyFunc -Value $byteArray } }
                @{ ScriptBlock = { NotNullOrEmptyFunc -Value $byteList } }
                @{ ScriptBlock = { NotNullOrEmptyFunc -Value $byteCollection } }
            )
        }

        It "Validate running time '<ScriptBlock>'" -TestCases $testCases {
            param ($ScriptBlock)
            (Measure-Command $ScriptBlock).Milliseconds | Should BeLessThan $expected
        }

        It "COM enumerable argument should work with 'ValidateNotNull' and 'ValidateNotNullOrEmpty'" -Skip:(!$IsWindows) {
            $shell = New-Object -ComObject "Shell.Application"
            $folder = $shell.Namespace("$TESTDRIVE")
            $items = $folder.Items()

            NotNullFunc -Value $items -TestType "COM-Enumerable" | Should Be "file1"
            NotNullOrEmptyFunc -Value $items -TestType "COM-Enumerable" | Should Be "file1"
        }

        It "Enumerator argument should work with 'ValidateNotNull' and 'ValidateNotNullOrEmpty'" {
            $data = @(1,2,3)
            NotNullFunc -Value $data.GetEnumerator() -TestType "Enumerator" | Should Be "1,2,3"
            NotNullOrEmptyFunc -Value $data.GetEnumerator() -TestType "Enumerator" | Should Be "1,2,3"
        }

        It "'ValidateNotNull' should throw on null element of a collection argument" {
            ## Should throw on null element
            { NotNullFunc -Value @("string", $null, 2) } | Should Throw
            ## Should not throw on empty string element
            { NotNullFunc -Value @("string", "", 2) } | Should Not Throw
            ## Should not throw on an empty collection
            { NotNullFunc -Value @() } | Should Not Throw
        }

        It "'ValidateNotNullOrEmpty' should throw on null element of a collection argument or empty collection/dictionary" {
            { NotNullOrEmptyFunc -Value @("string", $null, 2) } | Should Throw
            { NotNullOrEmptyFunc -Value @("string", "", 2) } | Should Throw
            { NotNullOrEmptyFunc -Value @() } | Should Throw
            { NotNullOrEmptyFunc -Value @{} } | Should Throw
        }

        It "Mandatory parameter should throw on empty collection" {
            { MandType -ByteArray ([byte[]]@()) } | Should Throw
            { MandType -ByteList ([System.Collections.Generic.List[byte]]@()) } | Should Throw
            { MandType -ByteList ([System.Collections.ObjectModel.Collection[byte]]@()) } | Should Throw
        }
    }
}
