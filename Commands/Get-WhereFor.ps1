function Get-WhereFor
{
    <#
    .SYNOPSIS
        WhereFor: Where-Object + Foreach-Object
    .DESCRIPTION
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
    .EXAMPLE
        1..3 | ?% @{
            {$_ % 2} = {"$_ is odd"}
            {-not ($_ %2)}={"$_ is even"}
        }
    .EXAMPLE
        Get-Process | 
            WhereFor @{
                { $_.Handles -gt 1kb } = { "$($_.Name) [ $($_.Id) ] has $($_.handles) open handles " }
                { $_.WorkingSet -gt 1gb } = { "$($_.Name) [ $($_.Id) ] is using $($_.WorkingSet) of memory" }
            }
    .EXAMPLE
        "the quick brown fox jumped over the lazy dog" -split '\s' | 
            Get-WhereFor ([Ordered]@{
                { $_ } =
                    { "Word: $_"; "Length: $($_.Length)" }
                { $_ -match '[aeiou]' } =
                    { "Vowels: $($_.ToCharArray() -match '[aeiou]')" }
                { $_ -match '[^aeiou]' } =
                    { "Consonant: $($_.ToCharArray() -match '[^aeiou]')" }
            })
    #>
    [Alias('WhereFor','WhereFore','Get-WhereFore','?%')]
    param(
    # A dictionary of conditions and actions to take.
    # Each key and value must be a `[ScriptBlock]`.
    [Parameter(Position=0)]
    [ValidateScript({
        foreach ($key in $_.Keys) {
            if ($key -isnot [ScriptBlock]) {
                throw "Key $key must be script blocks"
            }
            if ($_[$key] -isnot [ScriptBlock]) {
                throw "Value for key $key must be a script blocks"
            }
        }
        return $true
    })]
    [Collections.IDictionary[]]
    $WhereFor,    

    # One or more input objects to process.
    [Parameter(ValueFromPipeline,Position=1)]
    [PSObject[]]
    $InputObject    
    )

    begin {
        # We start off by creating a dictionary of steppable pipelines for each Where.
        $stepWhere =
            [Collections.Generic.Dictionary[
                ScriptBlock, Management.Automation.SteppablePipeline
            ]]::new()
        # and each for.
        $stepFor =
            [Collections.Generic.Dictionary[
                ScriptBlock, Management.Automation.SteppablePipeline
            ]]::new()
        # Then we resolve Where-Object and Foreach-Object ahead of time, to reduce overhead.
        $WhereObjectCommand = $ExecutionContext.SessionState.InvokeCommand.GetCommand('Where-Object','Cmdlet')
        $ForeachObjectCommand = $ExecutionContext.SessionState.InvokeCommand.GetCommand('Foreach-Object','Cmdlet')
    }

    process {
        # Now we iterate over each dictionary in the WhereFor list.
        # We use loop labels in case any of the script blocks want to break or continue the loop.
        :nextDictionary foreach ($whereForDictionary in $WhereFor) {
            :nextWhere foreach ($whereForCondition in $whereForDictionary.Keys) {
                # If we have not created a steppable pipeline for this condition,
                if (-not $stepWhere.ContainsKey($whereForCondition)) {
                    # we create a steppable pipeline for it,
                    $stepWhere[$whereForCondition] = {. $WhereObjectCommand $whereForCondition}.GetSteppablePipeline()
                    $stepWhere[$whereForCondition].Begin($true) # and start it.
                }
                # Now we iterate over each input object provided to the process block
                :nextInput foreach ($in in $InputObject) {
                    # We run the input object through the Where-Object steppable pipeline.
                    $whereForShallIRunThis = $stepWhere[$whereForCondition].Process($in)
                    # If the object passed the Where-Object condition,
                    if ($whereForShallIRunThis) {
                        # we check if we have not created a steppable pipeline for the Foreach-Object condition.
                        if (-not $stepFor.ContainsKey($whereForDictionary[$whereForCondition])) {
                            # If we have not, we create a steppable pipeline for it,
                            $stepFor[$whereForDictionary[$whereForCondition]] =
                                {
                                    . $ForeachObjectCommand $whereForDictionary[$whereForCondition]
                                }.GetSteppablePipeline()
                            # and start it.
                            $stepFor[$whereForDictionary[$whereForCondition]].Begin($true)
                        }
                        # We run the input object through the Foreach-Object steppable pipeline.
                        $stepFor[$whereForDictionary[$whereForCondition]].Process($in)
                    }
                }
            }
        }
    }

    end {
        # When all the input objects have been processed, we end the steppable pipelines.
        foreach ($step in $stepWhere.Values) {
            $step.End()
        }
        foreach ($step in $stepFor.Values) {
            $step.End()
        }
    }
}
