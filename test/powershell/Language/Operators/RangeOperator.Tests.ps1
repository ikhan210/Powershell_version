Describe "Range Operator" -Tags CI {
    Context "Range integer operations" {
        It "Range operator generates arrays of integers" {
            $Range = 5..8
            $Range.count | Should Be 4
            $Range[0] | Should BeOfType [int]
            $Range[1] | Should BeOfType [int]
            $Range[2] | Should BeOfType [int]
            $Range[3] | Should BeOfType [int]
        }

        It "Range operator accepts negative integer values" {
            {
                -8..-5
            } |Should Not Throw

            $Range = -8..-5            
            $Range.count | Should Be 4
            $Range[0] |Should Be -8
            $Range[1] |Should Be -7
            $Range[2] |Should Be -6
            $Range[3] |Should Be -5
        }

        It "Range operator support single-item sequences" {
            {
                0..0
            } |Should Not Throw

            $Range = 0..0
            $Range.count | Should Be 1
            $Range[0] | Should BeOfType [int]
            $Range[0] | Should Be 0
        }

        It "Range operator works in ascending and descending order" {
            $Range = 3..4 
            $Range.count | Should Be 2
            $Range[0] | Should Be 3
            $Range[1] | Should Be 4

            $Range = 4..3
            $Range.count | Should Be 2
            $Range[0] | Should Be 4
            $Range[1] | Should Be 3
        }
    }

    Context "Character expansion" {

        It "Range operator generates an array of [char] from single-character string operands" {
            {
                'A'..'E'
            } | Should Not Throw
            $CharRange = 'A'..'E'
            $CharRange.count | Should Be 5
            $CharRange[0] | Should BeOfType [char]
            $CharRange[1] | Should BeOfType [char]
            $CharRange[2] | Should BeOfType [char]
            $CharRange[3] | Should BeOfType [char]
            $CharRange[4] | Should BeOfType [char]
        }

        It "Range operator works in ascending and descending order" {
            $CharRange = 'a'..'b'
            $CharRange.count | Should Be 2
            $CharRange[0] | Should Be ([char]'a')
            $CharRange[1] | Should Be ([char]'b')

            $CharRange = 'b'..'a'
            $CharRange.count | Should Be 2
            $CharRange[0] | Should Be ([char]'b')
            $CharRange[1] | Should Be ([char]'a')
        }

        It "Range operator works with extended unicode charactes" {
            {
                'Đ'..'Ĕ'
            } | Should Not Throw
            $UnicodeRange = 'Đ'..'Ĕ'
            $UnicodeRange.count | Should Be 5
            $UnicodeRange.Where({$_ -is [char]}).count | Should Be 5
        }
    }

    Context "Range operator operand types" {

        It "Range operator works on [int]" {
            {
                1..10
            } | Should Not Throw

            $Range = 1..10
            $Range.count | Should Be 10
            $Range.Where({$_ -is [int]}).count | Should Be 10
        }

        It "Range operator works on [long]" {
            {
                ([long]1)..([long]10)
            } | Should Not Throw
            $Range = ([long]1)..([long]10)
            $Range.count | Should Be 10
            $Range.Where({$_ -is [int]}).count | Should Be 10
        }
        
        It "Range operator works on [bigint]" {
            {
                ([bigint]1)..([bigint]10)
            } | Should Not Throw
            $Range = ([bigint]1)..([bigint]10)
            $Range.count | Should Be 10
            $Range.Where({$_ -is [int]}).count | Should Be 10
        }

        It "Range operator works on [decimal]" {
            {
                1.2d..2.9d
            } | Should Not Throw
            $Range = 1.1d..9.9d
            $Range.count | Should Be 10
            $Range.Where({$_ -is [int]}).count | Should Be 10
            $Range[0] | Should Be 1
            $Range[1] | Should Be 2
            $Range[2] | Should Be 3
            $Range[3] | Should Be 4
            $Range[4] | Should Be 5
            $Range[5] | Should Be 6
            $Range[6] | Should Be 7
            $Range[7] | Should Be 8
            $Range[8] | Should Be 9
            $Range[9] | Should Be 10
        }
    }
}