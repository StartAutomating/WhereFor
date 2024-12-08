describe WhereFor {
    it 'Combines Where-Object and Foreach-Object into a single command' {
        2 | ?% @{
            { -not ($_ % 2) } = { "$_ is even" }
        } | Should -Be "2 is even"
    }

    it 'Will process a pipeline in order and run multiple actions' {
        @(1..3 | ?% @{
            { $_ % 2 } = { "$_ is odd" }
            { -not ($_ % 2) } = { "$_ is even" }
        }) -join "`n" | Should -Be "1 is odd`n2 is even`n3 is odd"
    }
}
