param([string]$IcarusBin = '')
$ErrorActionPreference='Stop'
if($IcarusBin) { $env:PATH=$IcarusBin+';'+$env:PATH }
$root=Split-Path -Parent $PSScriptRoot
$build=Join-Path $root 'build/sim'
New-Item -ItemType Directory -Force $build | Out-Null
$sources=@(Get-ChildItem -LiteralPath (Join-Path $root 'src') -Filter '*.v' | ForEach-Object FullName)
foreach($top in @('tb_spi_system','tb_spi_rx','tb_spi_uart','tb_spi_top')) {
 $image=Join-Path $build ($top+'.vvp')
 & iverilog -g2012 -Wall -s $top -o $image @sources (Join-Path $root ('sim/'+$top+'.sv'))
 if($LASTEXITCODE -ne 0) {throw "Compile failed: $top"}
 & vvp $image
 if($LASTEXITCODE -ne 0) {throw "Simulation failed: $top"}
}
