Describe 'ConvertTo-Json' -tags "CI" {
    It 'Newtonsoft.Json.Linq.Jproperty should be converted to Json properly' {
        $EgJObject = New-Object -TypeName Newtonsoft.Json.Linq.JObject
        $EgJObject.Add("TestValue1", "123456")
        $EgJObject.Add("TestValue2", "78910")
        $EgJObject.Add("TestValue3", "99999")
        $dict = @{}
        $dict.Add('JObject', $EgJObject)
        $dict.Add('StrObject', 'This is a string Object')
        $properties = @{'DictObject' = $dict; 'RandomString' = 'A quick brown fox jumped over the lazy dog'}
        $object = New-Object -TypeName psobject -Property $properties
        $jsonFormat = ConvertTo-Json -InputObject $object
        $jsonFormat.contains("TestValue1") | Should Be True 
        $jsonFormat.contains("123456") | Should Be True
        $jsonFormat.contains("TestValue2") | Should Be True
        $jsonFormat.contains("78910") | Should Be True
        $jsonFormat.contains("TestValue3") | Should Be True
        $jsonFormat.contains("99999") | Should Be True
    }
}
