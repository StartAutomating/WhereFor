<div align='center'>
    <img alt='WhereFor Logo (Animated)' style='width:50%' src='Assets/WhereFor-animated.svg' />
</div>

# WhereFor
Wherefore Art Thou PowerShell? Multiple Object Pipelines


## What Is WhereFor?

WhereFor is a small PowerShell module that combines Where-Object and Foreach-Object into a single useful command, `Get-WhereFor`.

Using WhereFor, it's simple and straightforward to check for multiple conditions in a single pipeline, thus avoiding repeated passes over the same data.

### Installing and Importing

You can install WhereFor from the PowerShell Gallery with Install-Module:

~~~PowerShell
Install-Module WhereFor -Scope CurrentUser
~~~

After installation, you can import the module by name:

~~~PowerShell
Import-Module WhereFor
~~~

### Examples

~~~PipeScript{
Import-Module .\
Get-Help Get-WhereFor |
    %{ $_.Examples.Example.code} |
    % -Begin { $exampleCount = 0 } -Process {
        $exampleCount++
        @(
            "#### Get-WhereFor Example $exampleCount"
            ''
            "~~~PowerShell"
            $_
            "~~~"
            ''
        ) -join [Environment]::Newline
    }
}
~~~

### How It Works

PowerShell is full of interesting features that are not broadly understood.  

WhereFor is built using one of these features, the [steppable pipeline](https://learn.microsoft.com/en-us/dotnet/api/system.management.automation.steppablepipeline?view=powershellsdk-7.4.0&wt.mc_id=MVP_321542).

SteppablePipelines allow you to run one more object pipelines step by step.

WhereFor works in a very simple way.  You provide one or more dictionaries or hashtables to WhereFor, and it creates a steppable pipeline for each condition and value.

If the condition returned a value, the action is run.
