function report=run_research(out)
%RUN_RESEARCH Single entry: correctness gate, conversion and analytical outputs.
root=fileparts(fileparts(mfilename('fullpath')));
if nargin<1,out=fullfile(root,'results','validated_v2');end
report=run_validation_tests(out);assert(report.passed);
paperDir=fullfile(root,'data','paper_digitized_reference');
assert(isfile(fullfile(paperDir,'reflection_states.csv')),'ris:MissingReference','Generate the documented paper digitization with tools/digitize_figure2.py first.');
convert_cst_exports(root,fullfile(root,'data','cst_simulated_hardware'),1,'UNVERIFIED physical polarization; legacy Floquet mode 1','PROVISIONAL');
paper=ris_array_model(fullfile(paperDir,'reflection_states.csv'),fullfile(out,'paper_digitized_reference'),true);
actual=ris_array_model(fullfile(root,'data','cst_simulated_hardware','reflection_states.csv'),fullfile(out,'cst_simulated_hardware_provisional'),false);
if isfile(fullfile(root,'cst','experiments','D010_OFF_strict','complex_sparameters.csv'))
 for mode=1:2
  diagnostic=convert_diagnostic_pair(root,mode);
  ris_array_model(diagnostic,fullfile(out,sprintf('cst_strict_mode%d_provisional',mode)),false);
 end
end
run_impedance_example(fullfile(out,'illustrative_impedance_example'));
if isfile(fullfile(root,'results','cst_diagnostics','simulation_summary.csv')),plot_cst_diagnostics();end
report.export_readback_pass=true;report.paper_main_cases=height(paper);report.cst_provisional_main_cases=height(actual);
report.physical_hardware_validation='PROVISIONAL; these software tests do not establish physical hardware validity.';
fid=fopen(fullfile(out,'run_summary.json'),'w');fwrite(fid,jsonencode(report,PrettyPrint=true));fclose(fid);
fprintf('Research generation complete. MATLAB tests PASS; historical CST states remain PROVISIONAL.\n');
end
