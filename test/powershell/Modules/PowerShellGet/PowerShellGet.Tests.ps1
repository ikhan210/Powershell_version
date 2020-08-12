# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# no progress output during these tests
$ProgressPreference = "SilentlyContinue"

$RepositoryName = 'INTGallery'
$SourceLocation = 'https://www.poshtestgallery.com/api/v2'
$RegisteredINTRepo = $false
$ContosoServer = 'ContosoServer'
$FabrikamServerScript = 'Fabrikam-ServerScript'
$Initialized = $false

$myDocumentsPath = [Environment]::GetFolderPath(5)
$programFilesPath = [Environment]::GetFolderPath(38)

$myDocumentsPathPS = [System.IO.Path]::Combine($myDocumentsPath, "PowerShell");
$programFilesPathPS = [System.IO.Path]::Combine($programFilesPath, "PowerShell");


$myDocumentsPathPSModules = [System.IO.Path]::Combine($myDocumentsPathPS, "Modules");
$programFilesPathPSModules = [System.IO.Path]::Combine($programFilesPathPS, "Modules");


#region Utility functions

function IsInbox { $PSHOME.EndsWith('\WindowsPowerShell\v1.0', [System.StringComparison]::OrdinalIgnoreCase) }
function IsWindows { $PSVariable = Get-Variable -Name IsWindows -ErrorAction Ignore; return (-not $PSVariable -or $PSVariable.Value) }
function IsCoreCLR { $PSVersionTable.ContainsKey('PSEdition') -and $PSVersionTable.PSEdition -eq 'Core' }

#endregion

#region Install locations for modules and scripts

if(IsInbox)
{
    $script:ProgramFilesPSPath = Microsoft.PowerShell.Management\Join-Path -Path $env:ProgramFiles -ChildPath "WindowsPowerShell"
}
elseif(IsCoreCLR) {
    if(IsWindows) {
        $script:ProgramFilesPSPath = Microsoft.PowerShell.Management\Join-Path -Path $env:ProgramFiles -ChildPath 'PowerShell'
    }
    else {
        $script:ProgramFilesPSPath = Split-Path -Path ([System.Management.Automation.Platform]::SelectProductNameForDirectory('SHARED_MODULES')) -Parent
    }
}

try
{
    $script:MyDocumentsFolderPath = [Environment]::GetFolderPath("MyDocuments")
}
catch
{
    $script:MyDocumentsFolderPath = $null
}

if(IsInbox)
{
    $script:MyDocumentsPSPath = if($script:MyDocumentsFolderPath)
                                {
                                    Microsoft.PowerShell.Management\Join-Path -Path $script:MyDocumentsFolderPath -ChildPath "WindowsPowerShell"
                                }
                                else
                                {
                                    Microsoft.PowerShell.Management\Join-Path -Path $env:USERPROFILE -ChildPath "Documents\WindowsPowerShell"
                                }
}
elseif(IsCoreCLR) {
    if(IsWindows)
    {
        $script:MyDocumentsPSPath = if($script:MyDocumentsFolderPath)
        {
            Microsoft.PowerShell.Management\Join-Path -Path $script:MyDocumentsFolderPath -ChildPath 'PowerShell'
        }
        else
        {
            Microsoft.PowerShell.Management\Join-Path -Path $HOME -ChildPath "Documents\PowerShell"
        }
    }
    else
    {
        $script:MyDocumentsPSPath = Split-Path -Path ([System.Management.Automation.Platform]::SelectProductNameForDirectory('USER_MODULES')) -Parent
    }
}

$script:ProgramFilesModulesPath = Microsoft.PowerShell.Management\Join-Path -Path $script:ProgramFilesPSPath -ChildPath 'Modules'
$script:MyDocumentsModulesPath = Microsoft.PowerShell.Management\Join-Path -Path $script:MyDocumentsPSPath -ChildPath 'Modules'

$script:ProgramFilesScriptsPath = Microsoft.PowerShell.Management\Join-Path -Path $script:ProgramFilesPSPath -ChildPath 'Scripts'
$script:MyDocumentsScriptsPath = Microsoft.PowerShell.Management\Join-Path -Path $script:MyDocumentsPSPath -ChildPath 'Scripts'

#endregion

#region Register a test repository

function Initialize
{
    # Cleaned up commands whose output to console by deleting or piping to Out-Null
    Import-Module CompatPowerShellGet -Force

    Register-PSRepository -Name $RepositoryName -SourceLocation $SourceLocation -InstallationPolicy Trusted
    $script:RegisteredINTRepo = $true

    $repo = Get-PSRepository -ErrorAction SilentlyContinue |
                Where-Object {$_.Url.StartsWith($SourceLocation, [System.StringComparison]::OrdinalIgnoreCase)}
    if($repo)
    {
        $script:RepositoryName = $repo.Name
    }
}

#endregion

function Remove-InstalledModules
{
    Get-InstalledModule -Name $ContosoServer -AllVersions -ErrorAction SilentlyContinue | CompatPowerShellGet\Uninstall-Module -Force
}

Describe "PowerShellGet - Module tests" -tags "Feature" {

    BeforeAll {
        if ($script:Initialized -eq $false) {
            Initialize
            $script:Initialized = $true
        }
    }

    BeforeEach {
        Remove-InstalledModules
    }

    It "Should find a module correctly" {
        $psgetModuleInfo = Find-Module -Name $ContosoServer -Repository $RepositoryName
        $psgetModuleInfo.Name | Should -Be $ContosoServer
        $psgetModuleInfo.Repository | Should -Be $RepositoryName
    }

    It "Should install a module correctly to the required location with default CurrentUser scope" {
        Write-Host("PSModulePath: $env:PSModulePath")
        Write-Host("GMO CompatPowerShellGet: ")
        gmo CompatPowerShellGet -ListAvailable

        Write-Host("Test paths: ")
        Write-Host("test MyDocuments path: " + (test-path $myDocumentsPath))
        Write-Host("test Program Files path: " + (test-path $programFilesPath))

        Write-Host("test MyDocuments\PowerShell path: " + (test-path $myDocumentsPathPS))
        Write-Host("test Program Files\PowerShell path: " + (test-path $programFilesPathPS))

        Write-Host("test MyDocuments\PowerShell\Modules path: " + (test-path $myDocumentsPathPSModules))
        Write-Host("test Program Files\PowerShell\Modules path: " + (test-path $programFilesPathPSModules))

        Install-Module -Name $ContosoServer -Repository $RepositoryName -AllowClobber
        $installedModuleInfo = Get-InstalledModule -Name $ContosoServer
        $installedModuleInfo | Should -Not -BeNullOrEmpty
        $installedModuleInfo.Name | Should -Be $ContosoServer
        # Not implemented yet
        #$installedModuleInfo.InstalledLocation.StartsWith($script:MyDocumentsModulesPath, [System.StringComparison]::OrdinalIgnoreCase) | Should -BeTrue

        $module = Get-InstalledModule $ContosoServer
        $module.Name | Should -Be $ContosoServer
        #$module.ModuleBase | Should -Be $installedModuleInfo.InstalledLocation
    }

    AfterAll {
        Remove-InstalledModules
    }
}

Describe "PowerShellGet - Module tests (Admin)" -Tags @('Feature', 'RequireAdminOnWindows', 'RequireSudoOnUnix') {

    BeforeAll {
        if ($script:Initialized -eq $false) {
            Initialize
            $script:Initialized = $true
        }
    }

    BeforeEach {
        Remove-InstalledModules
    }

    It "Should install a module correctly to the required location with AllUsers scope" {
        Write-Host("PSModulePath: $env:PSModulePath")
        Write-Host("GMO CompatPowerShellGet: ")
        gmo CompatPowerShellGet -ListAvailable

        Write-Host("Test paths: ")
        Write-Host("test MyDocuments path: " + (test-path $myDocumentsPath))
        Write-Host("test Program Files path: " + (test-path $programFilesPath))

        Write-Host("test MyDocuments\PowerShell path: " + (test-path $myDocumentsPathPS))
        Write-Host("test Program Files\PowerShell path: " + (test-path $programFilesPathPS))

        Write-Host("test MyDocuments\PowerShell\Modules path: " + (test-path $myDocumentsPathPSModules))
        Write-Host("test Program Files\PowerShell\Modules path: " + (test-path $programFilesPathPSModules))


        Install-Module -Name $ContosoServer -Repository $RepositoryName -Scope AllUsers -AllowClobber
        $installedModuleInfo = Get-InstalledModule -Name $ContosoServer

        $installedModuleInfo | Should -Not -BeNullOrEmpty
        $installedModuleInfo.Name | Should -Be $ContosoServer
        # Not implemented yet
        #$installedModuleInfo.InstalledLocation.StartsWith($script:programFilesModulesPath, [System.StringComparison]::OrdinalIgnoreCase) | Should -BeTrue

        #$module = Get-Module $ContosoServer -ListAvailable
        #$module.Name | Should -Be $ContosoServer
        #$module.ModuleBase | Should -Be $installedModuleInfo.InstalledLocation
    }

    AfterAll {
        Remove-InstalledModules
    }
}

function Remove-InstalledScripts
{
    Get-InstalledScript -Name $FabrikamServerScript -ErrorAction SilentlyContinue | Uninstall-Script -Force
}

Describe "PowerShellGet - Script tests" -tags "Feature" {

    BeforeAll {
        if ($script:Initialized -eq $false) {
            Initialize
            $script:Initialized = $true
        }
    }

    BeforeEach {
        Remove-InstalledScripts
    }

    It "Should find a script correctly" {
        $psgetScriptInfo = Find-Script -Name $FabrikamServerScript -Repository $RepositoryName
        $psgetScriptInfo.Name | Should -Be $FabrikamServerScript
        $psgetScriptInfo.Repository | Should -Be $RepositoryName
    }

    It "Should install a script correctly to the required location with default CurrentUser scope" {
        Write-Host("PSModulePath: $env:PSModulePath")
        Write-Host("GMO CompatPowerShellGet: ")
        gmo CompatPowerShellGet -ListAvailable

        Write-Host("Test paths: ")
        Write-Host("test MyDocuments path: " + (test-path $myDocumentsPath))
        Write-Host("test Program Files path: " + (test-path $programFilesPath))

        Write-Host("test MyDocuments\PowerShell path: " + (test-path $myDocumentsPathPS))
        Write-Host("test Program Files\PowerShell path: " + (test-path $programFilesPathPS))

        Write-Host("test MyDocuments\PowerShell\Modules path: " + (test-path $myDocumentsPathPSModules))
        Write-Host("test Program Files\PowerShell\Modules path: " + (test-path $programFilesPathPSModules))


        Install-Script -Name $FabrikamServerScript -Repository $RepositoryName -NoPathUpdate
        $installedScriptInfo = Get-InstalledScript -Name $FabrikamServerScript

        $installedScriptInfo | Should -Not -BeNullOrEmpty
        $installedScriptInfo.Name | Should -Be $FabrikamServerScript
        #$installedScriptInfo.InstalledLocation.StartsWith($script:MyDocumentsScriptsPath, [System.StringComparison]::OrdinalIgnoreCase) | Should -BeTrue
    }

    AfterAll {
        Remove-InstalledScripts
    }
}

Describe "PowerShellGet - Script tests (Admin)" -Tags @('Feature', 'RequireAdminOnWindows', 'RequireSudoOnUnix') {

    BeforeAll {
        if ($script:Initialized -eq $false) {
            Initialize
            $script:Initialized = $true
        }
    }

    BeforeEach {
        Remove-InstalledScripts
    }

    It "Should install a script correctly to the required location with AllUsers scope" {
        Write-Host("PSModulePath: $env:PSModulePath")
        Write-Host("GMO CompatPowerShellGet: ")
        gmo CompatPowerShellGet -ListAvailable

        Write-Host("Test paths: ")
        Write-Host("test MyDocuments path: " + (test-path $myDocumentsPath))
        Write-Host("test Program Files path: " + (test-path $programFilesPath))

        Write-Host("test MyDocuments\PowerShell path: " + (test-path $myDocumentsPathPS))
        Write-Host("test Program Files\PowerShell path: " + (test-path $programFilesPathPS))

        Write-Host("test MyDocuments\PowerShell\Modules path: " + (test-path $myDocumentsPathPSModules))
        Write-Host("test Program Files\PowerShell\Modules path: " + (test-path $programFilesPathPSModules))


        Install-Script -Name $FabrikamServerScript -Repository $RepositoryName -Scope AllUsers
        $installedScriptInfo = Get-InstalledScript -Name $FabrikamServerScript

        $installedScriptInfo | Should -Not -BeNullOrEmpty
        $installedScriptInfo.Name | Should -Be $FabrikamServerScript
        #$installedScriptInfo.InstalledLocation.StartsWith($script:ProgramFilesScriptsPath, [System.StringComparison]::OrdinalIgnoreCase) | Should -BeTrue
    }

    AfterAll {
        Remove-InstalledScripts
    }
}

<# Currently Not Implemented
Describe 'PowerShellGet Type tests' -tags @('CI') {
    BeforeAll {
        Import-Module PowerShellGet -Force
    }


    It 'Ensure PowerShellGet Types are available' {
        $PowerShellGetNamespace = 'Microsoft.PowerShell.Commands.PowerShellGet'
        $PowerShellGetTypeDetails = @{
            InternalWebProxy = @('GetProxy', 'IsBypassed')
        }

        if((IsWindows)) {
            $PowerShellGetTypeDetails['CERT_CHAIN_POLICY_PARA'] = @('cbSize','dwFlags','pvExtraPolicyPara')
            $PowerShellGetTypeDetails['CERT_CHAIN_POLICY_STATUS'] = @('cbSize','dwError','lChainIndex','lElementIndex','pvExtraPolicyStatus')
            $PowerShellGetTypeDetails['InternalSafeHandleZeroOrMinusOneIsInvalid'] = @('IsInvalid')
            $PowerShellGetTypeDetails['InternalSafeX509ChainHandle'] = @('CertFreeCertificateChain','ReleaseHandle','InvalidHandle')
            $PowerShellGetTypeDetails['Win32Helpers'] = @('CertVerifyCertificateChainPolicy', 'CertDuplicateCertificateChain', 'IsMicrosoftCertificate')
        }

        if('Microsoft.PowerShell.Telemetry.Internal.TelemetryAPI' -as [Type]) {
            $PowerShellGetTypeDetails['Telemetry'] = @('TraceMessageArtifactsNotFound', 'TraceMessageNonPSGalleryRegistration')
        }

        $PowerShellGetTypeDetails.GetEnumerator() | ForEach-Object {
            $ClassName = $_.Name
            $Type = "$PowerShellGetNamespace.$ClassName" -as [Type]
            $Type | Select-Object -ExpandProperty Name | Should -Be $ClassName
            $_.Value | ForEach-Object { $Type.DeclaredMembers.Name -contains $_ | Should -BeTrue }
        }
    }
}
#>

if($RegisteredINTRepo)
{
    Get-PSRepository -Name $RepositoryName -ErrorAction SilentlyContinue | Unregister-PSRepository
}
