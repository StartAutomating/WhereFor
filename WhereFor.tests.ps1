describe WhereFor {
    it 'Combines Where-Object and Foreach-Object into a single command' {
        2 | ?% @{
            { -not ($_ % 2) } = { "$_ is even" }
        } | Should -Be "2 is even"
    }

}
