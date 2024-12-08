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
        $dataSet = [Data.DataSet]::new('BlueSky')
        $linkTable = $dataSet.Tables.Add('Links')
        $linkTable.Columns.AddRange(@(
            [Data.DataColumn]::New('Link', [uri],'','Attribute')
        ))
        $emojiTable = $dataSet.Tables.Add('Emoji')
        $emojiTable.Columns.AddRange(@(
            [Data.DataColumn]::New('Emoji', [string],'','Attribute')
        ))

        websocket wss://jetstream2.us-west.bsky.network/subscribe?wantedCollections=app.bsky.feed.post -TimeOut "00:00:03" -Watch |
            ?% @{
                {$_.commit.record.embed.external.uri} = {
                    $LinkTable.Rows.Add(@($_.commit.record.embed.external.uri -as [uri]))
                }                                    
                {$_.commit.record.text -match '[\p{IsLowSurrogates}\p{IsHighSurrogates}]+'} = {
                    $emojiTable.Rows.Add(@($matches.0))                    
                }
                {$_.commit.record.text} = {
                    $_.commit.record.text
                }
            }
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
        $stepWhere =
            [Collections.Generic.Dictionary[
                ScriptBlock, Management.Automation.SteppablePipeline
            ]]::new()
        $stepFor =
            [Collections.Generic.Dictionary[
                ScriptBlock, Management.Automation.SteppablePipeline
            ]]::new()
    }

    process {
        :nextDictionary foreach ($whereForDictionary in $WhereFor) {
            :nextWhere foreach ($whereForCondition in $whereForDictionary.Keys) {                
                if (-not $stepWhere.ContainsKey($whereForCondition)) {
                    $stepWhere[$whereForCondition] = {Where-Object $whereForCondition}.GetSteppablePipeline()
                    $stepWhere[$whereForCondition].Begin($true)
                }
                $whereForEach = $whereForDictionary[$whereForCondition]
                if (-not $whereForDictionary[$whereForCondition].Ast.ProcessBlock) {
                    $whereForEachProcessor = {process { . $whereForEach }}
                }
                :nextInput foreach ($in in $InputObject) {
                    $whereForShallIRunThis = $stepWhere[$whereForCondition].Process($in)
                    if ($whereForShallIRunThis) {
                        if (-not $stepFor.ContainsKey($whereForDictionary[$whereForCondition])) {
                            $stepFor[$whereForDictionary[$whereForCondition]] = {Foreach-Object $whereForDictionary[$whereForCondition]}.GetSteppablePipeline()
                            $stepFor[$whereForDictionary[$whereForCondition]].Begin($true)
                        }
                        $stepFor[$whereForDictionary[$whereForCondition]].Process($in)
                    }
                }
            }
        }
    }

    end {
        foreach ($step in $stepWhere.Values) {
            $step.End()
        }
        foreach ($step in $stepFor.Values) {
            $step.End()
        }
    }
}
