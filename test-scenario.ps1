$nugetExeUrl = "https://dist.nuget.org/win-x86-commandline/v4.0.0/nuget.exe"
$nugetExe = "$PSScriptRoot\nuget.exe"
$nugetV3Api = "https://api.nuget.org/v3/index.json"

Function Get-NuGetExe
{
    #Write-Output "Downloading nuget.exe from $nugetExeUrl"
    Write-Output "Using modified nuget.exe from script root"

    $start_time = Get-Date

    #Invoke-WebRequest -Uri $nugetExeUrl -OutFile $nugetExe

    #Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
    Write-Output ""
}

Function New-TestScenario ($packageId, $packageVersion)
{

    Write-Output "Initiating test scenario for $packageId $packageVersion"

    $testDir = "$PSScriptRoot\TestScenario-$packageId-$packageVersion"
    $packagesDir = Join-Path $testDir "packages"

    If (Test-Path $testDir){
	    Remove-Item $testDir -Force -Recurse | Out-Null
    }
    
    & $nugetExe locals all -clear

    If (Test-Path $packagesDir){
	    Remove-Item $packagesDir -Force -Recurse | Out-Null
    }
    
    New-Item -ItemType Directory -Path $testDir | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $testDir "Properties") | Out-Null

    Add-Content -Path (Join-Path $testDir "project.json") -Value (@'
{
    "dependencies": { 
		"
'@ + $packageId + '": "' + $packageVersion + @'
"
    },
    "frameworks": {        
        ".NETFramework,Version=v4.6.1": { }
    },
    "supports": { }
}
'@)

    Add-Content -Path (Join-Path $testDir "App.config") -Value @'
<?xml version="1.0" encoding="utf-8" ?>
<configuration>
    <startup> 
        <supportedRuntime version="v4.0" sku=".NETFramework,Version=v4.6.2" />
    </startup>
</configuration>
'@

    Add-Content -Path (Join-Path $testDir "Program.cs") -Value @'
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace NuGetRestoreTest
{
    class Program
    {
        static void Main(string[] args)
        {
        }
    }
}
'@

    Add-Content -Path (Join-Path $testDir "Properties\AssemblyInfo.cs") -Value @'
using System.Reflection;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;

[assembly: AssemblyTitle("NuGetRestoreTest")]
[assembly: AssemblyDescription("")]
[assembly: AssemblyConfiguration("")]
[assembly: AssemblyCompany("")]
[assembly: AssemblyProduct("NuGetRestoreTest")]
[assembly: AssemblyCopyright("Copyright ©  2017")]
[assembly: AssemblyTrademark("")]
[assembly: AssemblyCulture("")]
[assembly: ComVisible(false)]
[assembly: Guid("4d7906ee-0ed7-4d88-8c08-b7ab7406f4b1")]
[assembly: AssemblyVersion("1.0.0.0")]
[assembly: AssemblyFileVersion("1.0.0.0")]
'@

    $projectFile = (Join-Path $testDir "NuGetRestoreTest.csproj")
    Add-Content -Path $projectFile -Value @'
<?xml version="1.0" encoding="utf-8"?>
<Project ToolsVersion="15.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
    <Import Project="$(MSBuildExtensionsPath)\$(MSBuildToolsVersion)\Microsoft.Common.props" Condition="Exists('$(MSBuildExtensionsPath)\$(MSBuildToolsVersion)\Microsoft.Common.props')" />
    <PropertyGroup>
    <Configuration Condition=" '$(Configuration)' == '' ">Debug</Configuration>
    <Platform Condition=" '$(Platform)' == '' ">AnyCPU</Platform>
    <ProjectGuid>{4D7906EE-0ED7-4D88-8C08-B7AB7406F4B1}</ProjectGuid>
    <OutputType>Exe</OutputType>
    <RootNamespace>NuGetRestoreTest</RootNamespace>
    <AssemblyName>NuGetRestoreTest</AssemblyName>
    <TargetFrameworkVersion>v4.6.2</TargetFrameworkVersion>
    <FileAlignment>512</FileAlignment>
    <AutoGenerateBindingRedirects>true</AutoGenerateBindingRedirects>
    </PropertyGroup>
    <PropertyGroup Condition=" '$(Configuration)|$(Platform)' == 'Debug|AnyCPU' ">
    <PlatformTarget>AnyCPU</PlatformTarget>
    <DebugSymbols>true</DebugSymbols>
    <DebugType>full</DebugType>
    <Optimize>false</Optimize>
    <OutputPath>bin\Debug\</OutputPath>
    <DefineConstants>DEBUG;TRACE</DefineConstants>
    <ErrorReport>prompt</ErrorReport>
    <WarningLevel>4</WarningLevel>
    </PropertyGroup>
    <PropertyGroup Condition=" '$(Configuration)|$(Platform)' == 'Release|AnyCPU' ">
    <PlatformTarget>AnyCPU</PlatformTarget>
    <DebugType>pdbonly</DebugType>
    <Optimize>true</Optimize>
    <OutputPath>bin\Release\</OutputPath>
    <DefineConstants>TRACE</DefineConstants>
    <ErrorReport>prompt</ErrorReport>
    <WarningLevel>4</WarningLevel>
    </PropertyGroup>
    <ItemGroup>
    <Reference Include="System" />
    <Reference Include="System.Core" />
    <Reference Include="Microsoft.CSharp" />
    </ItemGroup>
    <ItemGroup>
    <Compile Include="Program.cs" />
    <Compile Include="Properties\AssemblyInfo.cs" />
    </ItemGroup>
    <ItemGroup>
    <None Include="App.config" />
    </ItemGroup>
    <Import Project="$(MSBuildToolsPath)\Microsoft.CSharp.targets" />
</Project>
'@

    Write-Output "Invoking nuget restore command: $nugetExe restore $projectFile -Verbosity detailed -OutputDirectory $packagesDir -NoCache -source $nugetV3Api"
    & $nugetExe restore $projectFile -Verbosity detailed -OutputDirectory $packagesDir -NoCache -source $nugetV3Api | Tee-Object -Variable restoreCmdOutput

    $logFile = "$PSScriptRoot\TestScenario-$packageId-$packageVersion-log.txt"
    Write-Output "Creating $logFile file"
    If (Test-Path $logFile){
	    Remove-Item $logFile -Force
    }
    Add-Content $logFile $restoreCmdOutput
        
    #If (Test-Path $testDir){
	#    Remove-Item $testDir -Force -Recurse | Out-Null
    #}

    Write-Output "Completed test scenario for $packageId $packageVersion"
    Write-Output ""
}

function Get-Sha512Algo()
{
	return [System.Security.Cryptography.SHA512]::Create();
}

function Get-StreamHash([System.Security.Cryptography.HashAlgorithm]$HashAlgo, [System.IO.Stream]$Stream)
{
	$HashAlgo.ComputeHash($Stream);
}

function Get-ArrayHash([System.Security.Cryptography.HashAlgorithm]$HashAlgo, [Byte[]]$Bytes)
{
	$HashAlgo.ComputeHash($Bytes);
}

function Get-HexString([Byte[]]$Bytes)
{
	return ($Bytes | ForEach-Object {$_.ToString("X2")}) -join "";
}

function Get-Base64String([Byte[]]$Bytes)
{
	return [System.Convert]::ToBase64String($Bytes);
}

function Test-Url([string]$Url)
{
	Write-Output "[$((Get-Date).ToUniversalTime().ToString("O"))] $($Url):";
	try
	{
		$mr = Measure-Command { $r = Invoke-WebRequest -Uri $Url };
	}
	catch
	{
		Write-Output "`tFailed to retrieve: $($_.Exception.ToString())";
		return;
	}
	$sp = [System.Net.ServicePointManager]::FindServicePoint($Url);
	Write-Output "`tTime taken      : $($mr.TotalMilliseconds) ms"
	Write-Output "`tRawContentLength: $($r.RawContentLength) bytes";
	if ($r.Content -is [Byte[]])
	{
		Write-Output "`tContent length  : $($r.Content.Length) bytes";
		$hashBytes = Get-StreamHash -HashAlgo (Get-Sha512Algo) -Stream $r.RawContentStream;
#		$hashBytes = Get-ArrayHash -HashAlgo (Get-Sha512Algo) -Bytes $r.Content;
		Write-Output "`tResponse SHA512 : $(Get-HexString -Bytes $hashBytes)";
		Write-Output "`tSHA512 Base64   : $(Get-Base64String -Bytes $hashBytes)";
	}
	if ($sp -ne $null -and $sp.Certificate -ne $null)
	{
		$cert = $sp.Certificate;
		Write-Output "`tCert subject    : $($cert.Subject)";
		Write-Output "`tCert issuer     : $($cert.Issuer)";
		Write-Output "`tCert thumbprint : $($cert.GetCertHashString())";
		Write-Output "`tCert serial No  : $($cert.GetSerialNumberString())";
	}
	else
	{
		Write-Output "`tNo cert info found..."
	}
}

Get-NuGetExe
New-TestScenario "Newtonsoft.Json" "10.0.2"
New-TestScenario "NUnit" "3.6.1"
dxdiag /x dxdiag.xml

Test-Url "https://www.nuget.org/api/v2/package/Newtonsoft.Json/4.0.1" | Tee-Object -File json.net.txt
Test-Url "https://api.nuget.org/packages/newtonsoft.json.4.0.1.nupkg" | Tee-Object -File json.net.txt -Append

1..10 | ForEach-Object { Test-Url "https://api-v2v3search-0.nuget.org/query?q=karan" } | Tee-Object -File karan.txt
$guid = (New-Guid).ToString();
1..10 | ForEach-Object { Test-Url "https://api-v2v3search-0.nuget.org/query?q=$guid" } | Tee-Object -File guid.txt
1..10 | ForEach-Object { Test-Url "https://www.nuget.org/packages/TestPackage19fa75eb-9384-4371-9f82-0f4348c0aad3/" } | Tee-Object -File nuget.org.txt
1..10 | ForEach-Object { Test-Url "https://api.nuget.org/v3/registration1-gz/entityframework/index.json" } | Tee-Object -File api.nuget.org.txt
