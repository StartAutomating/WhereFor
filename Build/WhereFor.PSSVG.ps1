#requires -Module PSSVG
Push-Location ($psScriptRoot | Split-Path)
$powerShellChevron = Invoke-RestMethod https://pssvg.start-automating.com/Examples/PowerShellChevron.svg   
$assetsPath = Join-Path $pwd Assets
$scaleMax = 1.02


$FontSplat = [Ordered]@{
    FontFamily = "sans-serif" 
}

$φ = (1.0 + [Math]::Sqrt(5))/2
$opacityStart = 1
$opacityEnd = 0.66
$scaleMin = .8
$AnimateSplat = [Ordered]@{
    Dur = 60/128*4
    AttributeName = 'opacity'
    Values = "${opacityStart};${opacityEnd};${opacityStart}"
    RepeatCount = 'indefinite'
}
$AnimateSplat2 = [Ordered]@{
    Dur = 60/128*4
    AttributeName = 'opacity'
    Values = "${opacityEnd};${opacityStart};${opacityEnd}"
    RepeatCount = 'indefinite'
}

if (-not (Test-path $assetsPath)) {
    $null = New-Item -ItemType Directory -Path $assetsPath -Force
}


foreach ($variant in '','animated') {
svg @(
    SVG.GoogleFont -FontName $FontName    
    svg.symbol -ViewBox $powerShellChevron.svg.viewBox -Content $powerShellChevron.svg.symbol.InnerXml -Id psChevron
    
    svg.use -href '#psChevron'  -X '33%' -Y '1%' -Width '15%' -Stroke '#4488ff' -Fill '#4488ff'
    svg.text @(
        svg.tspan "?" -Children @(
            if ($variant -match 'animated') {
                SVG.animate @AnimateSplat
            }
        ) -FontSize "${scaleMin}em" 
        svg.tspan "%" -Children @(
            if ($variant -match 'animated') {
                SVG.animate @AnimateSplat2
            }
        ) -FontSize "${scaleMin}em" -Dx -0.25em
    ) -FontSize 48 -Fill '#4488ff' -X 45% -DominantBaseline 'top' -TextAnchor 'left' -Y 58% @FontSplat
) -ViewBox 300, ([Math]::Floor(300 / $φ)) -OutputPath (Join-Path $assetsPath "WhereFor$(if ($variant){"-$($variant)"}).svg")
}

Pop-Location
