param(
 [Parameter(Mandatory=$true)][ValidatePattern('^[A-Za-z0-9_-]+$')][string]$ExperimentId,
 [ValidateSet('original','connected')][string]$Topology='original',
 [double]$ResistanceOhm=0.001,
 [double]$InductanceH=0,
 [double]$CapacitanceF=0,
 [double]$FrequencyGHz=26.168,
 [switch]$PrepareOnly
)
$ErrorActionPreference='Stop'
$risRoot=Split-Path -Parent $PSScriptRoot
$risDir=Join-Path $PSScriptRoot ('experiments\'+$ExperimentId)
$risFile=Join-Path $risDir ($ExperimentId+'.cst')
if(Test-Path -LiteralPath $risFile){throw 'Refusing to overwrite a diagnostic checkpoint. Use a new ExperimentId.'}
New-Item -ItemType Directory -Path $risDir -Force | Out-Null
$risBase=Join-Path $PSScriptRoot 'off_assumed_25fF.cst'
Copy-Item -LiteralPath $risBase -Destination $risFile
$risEvents=Join-Path $risDir 'execution_events.jsonl'
function Event([string]$stage,[object]$detail){
 [ordered]@{utc=[DateTime]::UtcNow.ToString('o');stage=$stage;detail=$detail}|ConvertTo-Json -Depth 5 -Compress|Add-Content -LiteralPath $risEvents -Encoding utf8
}
$risConfig=[ordered]@{experiment=$ExperimentId;base='cst/off_assumed_25fF.cst';base_sha256=(Get-FileHash -LiteralPath $risBase -Algorithm SHA256).Hash.ToLower();topology=$Topology;R_ohm=$ResistanceOhm;L_H=$InductanceH;C_F=$CapacitanceF;frequency_GHz=$FrequencyGHz;mesh='Original tetrahedral defaults; adaptation disabled for initial controlled diagnostics';excitation='Both legacy Floquet modes at Zmax; physical polarization to audit';status='PREPARED'}
$risConfig|ConvertTo-Json -Depth 5|Set-Content -LiteralPath (Join-Path $risDir 'configuration.json') -Encoding utf8
$risInvoke=[Reflection.BindingFlags]::Public -bor [Reflection.BindingFlags]::Instance -bor [Reflection.BindingFlags]::InvokeMethod
$risGet=[Reflection.BindingFlags]::Public -bor [Reflection.BindingFlags]::Instance -bor [Reflection.BindingFlags]::GetProperty
function CstCall($obj,[string]$name,[object[]]$arguments=@()){$obj.GetType().InvokeMember($name,$risInvoke,$null,$obj,$arguments)}
try {
 Event 'connect' 'CSTStudio.Application.2023'
 $risStudio=[Activator]::CreateInstance([type]::GetTypeFromProgID('CSTStudio.Application.2023'))
 $null=CstCall $risStudio 'OpenFile' @($risFile)
 $risMws=CstCall $risStudio 'Active3D'
 $risActive=CstCall $risMws 'GetProjectPath' @('Project')
 if(-not $risActive.StartsWith($risDir,[StringComparison]::OrdinalIgnoreCase)){throw "Unexpected active project: $risActive"}
 Event 'opened_isolated_copy' $risActive
 foreach($p in @(@('Rload',$ResistanceOhm),@('Lload',$InductanceH),@('Cload',$CapacitanceF))){
  $null=CstCall $risMws 'StoreParameter' @($p[0],$p[1].ToString('G17',[Globalization.CultureInfo]::InvariantCulture))
 }
 $null=CstCall $risMws 'Rebuild'
 $risHistory=@'
With FDSolver
 .ResetSampleIntervals "all"
 .MeshAdaptionTet "False"
 .UseParallelization "True"
 .MaxCPUs "6"
 .MaximumNumberOfCPUDevices "1"
 .UseDoublePrecision "True"
End With
With LumpedElement
 .Reset
 .SetName "PIN_ON_series_RL"
 .SetType "RLCSerial"
 .SetR "Rload"
 .SetL "Lload"
 .SetC "Cload"
 .SetGs "0"
 .SetI0 "0"
 .SetT "0"
 .SetP1 "False", "-center_gap/2", "0", "substrate_thickness+copper_thickness/2"
 .SetP2 "False", "center_gap/2", "0", "substrate_thickness+copper_thickness/2"
 .SetInvert "False"
 .SetMonitor "True"
 .Modify
End With
'@
 $risF=$FrequencyGHz.ToString('G17',[Globalization.CultureInfo]::InvariantCulture)
 $risHistory+="`nFDSolver.AddSampleInterval `"$risF`", `"$risF`", `"1`", `"Single`", `"False`"`n"
 if($Topology -eq 'connected'){
  # A controlled topology diagnostic, not a claim that this pad enlargement
  # is the exact unpublished solder-land geometry from the source paper.
  $risHistory+=@'
With Brick
 .Reset
 .Name "left_bridge_overlap"
 .Component "top_patch"
 .Material "Copper_5p8e7S_per_m"
 .Xrange "-center_gap/2-2*terminal_width", "-center_gap/2"
 .Yrange "-slot_width/2-terminal_width", "slot_width/2+terminal_width"
 .Zrange "substrate_thickness", "substrate_thickness+copper_thickness"
 .Create
End With
With Brick
 .Reset
 .Name "right_bridge_overlap"
 .Component "top_patch"
 .Material "Copper_5p8e7S_per_m"
 .Xrange "center_gap/2", "center_gap/2+2*terminal_width"
 .Yrange "-slot_width/2-terminal_width", "slot_width/2+terminal_width"
 .Zrange "substrate_thickness", "substrate_thickness+copper_thickness"
 .Create
End With
Solid.Add "top_patch:left_diode_land", "top_patch:left_bridge_overlap"
Solid.Add "top_patch:left_diode_land", "top_patch:left_upper"
Solid.Add "top_patch:left_diode_land", "top_patch:left_lower"
Solid.Add "top_patch:left_diode_land", "top_patch:left_outer"
Solid.Add "top_patch:right_diode_land", "top_patch:right_bridge_overlap"
Solid.Add "top_patch:right_diode_land", "top_patch:right_upper"
Solid.Add "top_patch:right_diode_land", "top_patch:right_lower"
Solid.Add "top_patch:right_diode_land", "top_patch:right_outer"
'@
 }
 $risHistory|Set-Content -LiteralPath (Join-Path $risDir 'diagnostic_history.bas') -Encoding utf8
 $risAccepted=CstCall $risMws 'AddToHistory' @('Controlled load/connectivity diagnostic',$risHistory)
 if(-not $risAccepted){throw 'CST rejected the diagnostic history.'}
 $null=CstCall $risMws 'Save'
 Event 'prepared_and_saved' @{history_accepted=$risAccepted;checkpoint_sha256=(Get-FileHash -LiteralPath $risFile -Algorithm SHA256).Hash.ToLower()}
 if($PrepareOnly){Event 'prepare_only' 'No solver executed';exit 0}
 Event 'solver_started' @{requested_solved_frequency_GHz=$FrequencyGHz;both_Floquet_modes=$true}
 $risFd=$risMws.GetType().InvokeMember('FDSolver',$risGet,$null,$risMws,$null)
 $risResult=CstCall $risFd 'Start'
 Event 'solver_returned' $risResult
 $null=CstCall $risMws 'Save'
 $risConfig.status=if($risResult -eq 1){'SOLVER_COMPLETED_NOT_YET_VALIDATED'}else{'SOLVER_FAILED'}
 $risConfig|ConvertTo-Json -Depth 5|Set-Content -LiteralPath (Join-Path $risDir 'configuration.json') -Encoding utf8
 if($risResult -ne 1){throw 'CST solver returned failure; inspect saved solver logs.'}
 Write-Output "Solver completed for $ExperimentId; numerical/physical validation is still required."
} catch {
 Event 'exception' $_.Exception.Message
 throw
}
