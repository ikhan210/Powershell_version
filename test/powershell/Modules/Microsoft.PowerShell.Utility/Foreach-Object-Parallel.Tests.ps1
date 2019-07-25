# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

Describe 'ForEach-Object -Parallel Basic Tests' -Tags 'CI' {

    BeforeAll {

        $sb = { "Hello!" }
    }

    It "Verifies dollar underbar variable" {

        $expected = 1..10
        $result = $expected | ForEach-Object -Parallel -ScriptBlock { $_ }
        $result.Count | Should -BeExactly $expected.Count
        $result | Should -Contain 1
        $result | Should -Contain 10
    }

    It 'Verifies using variables' {

        $var = "Hello"
        $varArray = "Hello","There"
        $result = 1..1 | ForEach-Object -Parallel -ScriptBlock { $using:var; $using:varArray[1] }
        $result.Count | Should -BeExactly 2
        $result[0] | Should -BeExactly $var
        $result[1] | Should -BeExactly $varArray[1]
    }

    It 'Verifies terminating error streaming' {

        $result = 1..1 | ForEach-Object -Parallel -ScriptBlock { throw 'Terminating Error!'; "Hello" } 2>&1
        $result.Count | Should -BeExactly 1
        $result.ToString() | Should -BeExactly 'Terminating Error!'
        $result.FullyQualifiedErrorId | Should -BeExactly 'PSTaskException'
    }

    It 'Verifies terminating error in multiple iterations' {

        $results = 1..2 | ForEach-Object -Parallel -ScriptBlock {
            if ($_ -eq 1) {
                throw 'Terminating Error!'
                "Hello!"
            }
            else {
                "Goodbye!"
            }
        } 2>&1

        $results | Should -Not -Contain "Hello!"
        $results | Should -Contain "Goodbye!"
    }

    It 'Verifies non-terminating error streaming' {

        $expectedError = 1..1 | ForEach-Object -Parallel -ScriptBlock { Write-Error "Error!" } 2>&1
        $expectedError.ToString() | Should -BeExactly 'Error!'
        $expectedError.FullyQualifiedErrorId | Should -BeExactly 'Microsoft.PowerShell.Commands.WriteErrorException'
    }

    It 'Verifies warning data streaming' {

        $expectedWarning = 1..1 | ForEach-Object -Parallel -ScriptBlock { Write-Warning "Warning!" } 3>&1
        $expectedWarning.Message | Should -BeExactly 'Warning!'
    }

    It 'Verifies verbose data streaming' {

        $expectedVerbose = 1..1 | ForEach-Object -Parallel -ScriptBlock { Write-Verbose "Verbose!" -Verbose } -Verbose 4>&1
        $expectedVerbose.Message | Should -BeExactly 'Verbose!'
    }

    It 'Verifies debug data streaming' {
    
        $expectedDebug = 1..1 | ForEach-Object -Parallel -ScriptBlock { Write-Debug "Debug!" -Debug } -Debug 5>&1
        $expectedDebug.Message | Should -BeExactly 'Debug!'
    }

    It 'Verifies information data streaming' {

        $expectedInformation = 1..1 | ForEach-Object -Parallel -ScriptBlock { Write-Information "Information!" } 6>&1
        $expectedInformation.MessageData | Should -BeExactly 'Information!'
    }

    It 'Verifies error for using script block variable' {

        { 1..1 | ForEach-Object -Parallel -ScriptBlock { $using:sb } } | Should -Throw -ErrorId 'ParallelUsingVariableCannotBeScriptBlock,Microsoft.PowerShell.Commands.ForEachObjectCommand'
    }

    It 'Verifies error for script block piped variable' {
    
        { $sb | ForEach-Object -Parallel -ScriptBlock { "Hello" } -ErrorAction Stop } | Should -Throw -ErrorId 'ParallelPipedInputObjectCannotBeScriptBlock,Microsoft.PowerShell.Commands.ForEachObjectCommand'
    }

    It 'Verifies that parallel script blocks run in FullLanguage mode by default' {

        $results = 1..1 | ForEach-Object -Parallel -ScriptBlock { $ExecutionContext.SessionState.LanguageMode }
        $results | Should -BeExactly 'FullLanguage'
    }
}

Describe 'ForEach-Object -Parallel -AsJob Basic Tests' -Tags 'CI' {

    It 'Verifies TimeoutSeconds parameter is excluded from AsJob' {

        { 1..1 | ForEach-Object -Parallel -AsJob -ScriptBlock { "Hello" } -TimeoutSeconds 60 } | Should -Throw -ErrorId 'ParallelCannotUseTimeoutWithJob,Microsoft.PowerShell.Commands.ForEachObjectCommand'
    }

    It 'Verifies ForEach-Object -Parallel jobs appear in job repository' {

        $job = 1..1 | ForEach-Object -Parallel -AsJob -ScriptBlock { "Hello" }
        Get-Job | Should -Contain $job
        $job | Wait-Job | Remove-Job
    }

    It 'Verifies dollar underbar variable' {

        $expected = 1..10
        $job = $expected | ForEach-Object -Parallel -AsJob -ScriptBlock { $_ }
        $result = $job | Wait-Job | Receive-Job
        $job | Remove-Job
        $result.Count | Should -BeExactly $expected.Count
        $result | Should -Contain 1
        $result | Should -Contain 10
    }

    It 'Verifies using variables' {

        $Var1 = "Hello"
        $Var2 = "Goodbye"
        $Var3 = 105
        $Var4 = "One","Two","Three"
        $job = 1..1 | Foreach-Object -Parallel -AsJob -ScriptBlock {
            Write-Output $using:Var1
            Write-Output $using:Var2
            Write-Output $using:Var3
            Write-Output @(,$using:Var4)
            Write-Output $using:Var4[1]
        }
        $results = $job | Wait-Job | Receive-Job
        $job | Remove-Job

        $results[0] | Should -BeExactly $Var1
        $results[1] | Should -BeExactly $Var2
        $results[2] | Should -BeExactly $Var3
        $results[3] | Should -BeExactly $Var4
        $results[4] | Should -BeExactly $Var4[1]
    }

    It 'Verifies terminating error in single iteration' {

        $job = 1..1 | ForEach-Object -Parallel -AsJob -ScriptBlock { throw "Terminating Error!"; "Hello" }
        $results = $job | Wait-Job | Receive-Job 2>$null
        $results.Count | Should -BeExactly 0
        $job.State | Should -BeExactly 'Failed'
        $job.ChildJobs[0].JobStateInfo.State | Should -BeExactly 'Failed'
        $job.ChildJobs[0].JobStateInfo.Reason.Message | Should -BeExactly 'Terminating Error!'
        $job | Remove-Job
    }

    It 'Verifies terminating error in double iteration' {

        $job = 1..2 | ForEach-Object -Parallel -AsJob -ScriptBlock {
            if ($_ -eq 1) {
                throw "Terminating Error!"
                "Goodbye!"
            }
            else {
                "Hello!"
            }
        }
        $results = $job | Wait-Job | Receive-Job 2>$null
        $results | Should -Contain 'Hello!'
        $results | Should -Not -Contain 'Goodbye!'
        $job.JobStateInfo.State | Should -BeExactly 'Failed'
        $job.ChildJobs[0].JobStateInfo.State | Should -BeExactly 'Failed'
        $job.ChildJobs[0].JobStateInfo.Reason.Message | Should -BeExactly 'Terminating Error!'
        $job.ChildJobs[1].JobStateInfo.State | Should -BeExactly 'Completed'
        $job | Remove-Job
    }

    It 'Verifies non-terminating error' {

        $job = 1..1 | ForEach-Object -Parallel -AsJob -ScriptBlock { Write-Error "Error:$_" }
        $results = $job | Wait-Job | Receive-Job 2>&1
        $job | Remove-Job
        $results.ToString() | Should -BeExactly "Error:1"
    }

    It 'Verifies warning data' {

        $job = 1..1 | ForEach-Object -Parallel -AsJob -ScriptBlock { Write-Warning "Warning:$_" }
        $results = $job | Wait-Job | Receive-Job 3>&1
        $job | Remove-Job
        $results.Message | Should -BeExactly "Warning:1"
    }

    It 'Verifies verbose data' {

        $job = 1..1 | ForEach-Object -Parallel -AsJob -ScriptBlock { Write-Verbose "Verbose:$_" -Verbose }
        $results = $job | Wait-Job | Receive-Job -Verbose 4>&1
        $job | Remove-Job
        $results.Message | Should -BeExactly "Verbose:1"
    }

    It 'Verifies debug data' {

        $job = 1..1 | ForEach-Object -Parallel -AsJob -ScriptBlock { Write-Debug "Debug:$_" -Debug }
        $results = $job | Wait-Job | Receive-Job -Debug 5>&1
        $job | Remove-Job
        $results.Message | Should -BeExactly "Debug:1"
    }

    It 'Verifies information data' {

        $job = 1..1 | ForEach-Object -Parallel -AsJob -ScriptBlock { Write-Information "Information:$_" }
        $results = $job | Wait-Job | Receive-Job 6>&1
        $job | Remove-Job
        $results.MessageData | Should -BeExactly "Information:1"
    }

    It 'Verifies job Command property' {

        $job = 1..1 | ForEach-Object -Parallel -AsJob -ScriptBlock {"Hello"}
        $job.Command | Should -BeExactly '"Hello"'
        $job.ChildJobs[0].Command | Should -BeExactly '"Hello"'
        $job | Wait-Job | Remove-Job
    }
}

Describe 'ForEach-Object -Parallel Functional Tests' -Tags 'Feature' {

    It 'Verifies job queuing and throttle limit' {

        # Run four job tasks, two in parallel at a time.
        $job = 1..4 | ForEach-Object -Parallel -ScriptBlock { Start-Sleep 60 } -AsJob -ThrottleLimit 2

        # Wait for child job 2 to begin running for up to ten seconds
        $count = 0
        while (($job.ChildJobs[1].JobStateInfo.State -ne 'Running') -and (++$count -lt 40))
        {
            Start-Sleep -Milliseconds 250
        }
        if ($job.ChildJobs[1].JobStateInfo.State -ne 'Running')
        {
            throw "ForEach-Object -Parallel child job 2 did not start"
        }

        # Two job tasks should be running and two waiting to run
        $job.ChildJobs[0].JobStateInfo.State | Should -BeExactly 'Running'
        $job.ChildJobs[1].JobStateInfo.State | Should -BeExactly 'Running'
        $job.ChildJobs[2].JobStateInfo.State | Should -BeExactly 'NotStarted'
        $job.ChildJobs[3].JobStateInfo.State | Should -BeExactly 'NotStarted'

        $job | Remove-Job -Force
    }

    It 'Verifies jobs work with Receive-Job -AutoRemove parameter' {

        $job = 1..4 | ForEach-Object -Parallel -AsJob -ScriptBlock { "Hello:$_" }
        $null = $job | Receive-Job -Wait -AutoRemoveJob
        Get-Job | Should -Not -Contain $job
    }

    It 'Verifies parallel task queuing' {

        $results = 10..1 | ForEach-Object -Parallel -ScriptBlock { Start-Sleep 1; $_ } -ThrottleLimit 5
        $results[0] | Should -BeGreaterThan 5
        $results[1] | Should -BeGreaterThan 5
        $results[2] | Should -BeGreaterThan 5
        $results[3] | Should -BeGreaterThan 5
        $results[4] | Should -BeGreaterThan 5
    }

    It 'Verifies timeout and throttle parameters' {

        # With ThrottleLimit set to 1, the two 60 second long script blocks will run sequentially, 
        # until the timeout in 5 seconds.
        $results = 1..2 | ForEach-Object -Parallel { "Output $_"; Start-Sleep -Seconds 60 } -TimeoutSeconds 5 -ThrottleLimit 1 2>&1
        $results.Count | Should -BeExactly 2
        $results[0] | Should -BeExactly 'Output 1'
        $results[1].FullyQualifiedErrorId | Should -BeExactly 'PSTaskException'
        $results[1].Exception | Should -BeOfType [System.Management.Automation.PipelineStoppedException]
    }
}
