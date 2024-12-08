# Security

We take security seriously.  If you believe you have discovered a vulnerability, please [file an issue](https://github.com/StartAutomating/WhereFor/issues).

## Security Considerations

This module calls down directly to `Where-Object` and `Foreach-Object`.  

It will fail to work if the Runspace does not contain Where-Object and Foreach-Object.

This module directly executes a `ScriptBlock` in the context of the current user.

This is inherantly as safe as any ScriptBlock.

In order to avoid code injection, please _never_ directly run any code from the internet that you do not trust.

Presuming any object pipeline can contain poisoned data, please:

1. Do not use `Invoke-Expression`
2. Do not use `.ExpandString`