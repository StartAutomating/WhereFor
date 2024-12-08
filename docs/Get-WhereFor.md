Get-WhereFor
------------

### Synopsis
WhereFor: Where-Object + Foreach-Object

---

### Description

WhereFor is a small command that allows you to filter and process objects in a single pipeline.

This allows a single object pipeline to be split into multiple conditions and actions.

WhereFor takes a list of dictionaries where each key is a condition and each value is an action.

Any input object that matches a condition will run the action.

This will all happen within a
[steppable pipeline](https://learn.microsoft.com/en-us/dotnet/api/system.management.automation.steppablepipeline?view=powershellsdk-7.4.0&wt.mc_id=MVP_321542),
so you can use it in a pipeline.

It has a few aliases:

* `?%`
* `WhereFor`
* `WhereFore`
* `Get-WhereFore`

---

### Examples
> EXAMPLE 1

```PowerShell
1..3 | ?% @{
    {$_ % 2} = {"$_ is odd"}
    {-not ($_ %2)}={"$_ is even"}
}
```
> EXAMPLE 2

```PowerShell
Get-Process | 
    WhereFor @{
        { $_.Handles -gt 1kb } = { "$($_.Name) [ $($_.Id) ] has $($_.handles) open handles " }
        { $_.WorkingSet -gt 1gb } = { "$($_.Name) [ $($_.Id) ] is using $($_.WorkingSet) of memory" }
    }
```
> EXAMPLE 3

```PowerShell
"the quick brown fox jumped over the lazy dog" -split '\s' | 
    Get-WhereFor ([Ordered]@{
        { $_ } =
            { "Word: $_"; "Length: $($_.Length)" }
        { $_ -match '[aeiou]' } =
            { "Vowels: $($_.ToCharArray() -match '[aeiou]')" }
        { $_ -match '[^aeiou]' } =
            { "Consonant: $($_.ToCharArray() -match '[^aeiou]')" }
    })
```

---

### Parameters
#### **WhereFor**
A dictionary of conditions and actions to take.
Each key and value must be a `[ScriptBlock]`.

|Type             |Required|Position|PipelineInput|
|-----------------|--------|--------|-------------|
|`[IDictionary[]]`|false   |1       |false        |

#### **InputObject**
One or more input objects to process.

|Type          |Required|Position|PipelineInput |
|--------------|--------|--------|--------------|
|`[PSObject[]]`|false   |2       |true (ByValue)|

---

### Syntax
```PowerShell
Get-WhereFor [[-WhereFor] <IDictionary[]>] [[-InputObject] <PSObject[]>] [<CommonParameters>]
```
