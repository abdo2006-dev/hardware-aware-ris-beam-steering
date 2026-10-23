function plot_cst_diagnostics()
% All numerical curves come from saved source CSVs, never manually edited.
root=fileparts(fileparts(mfilename('fullpath')));out=fullfile(root,'results','cst_diagnostics');
C=readtable(fullfile(out,'open_short_comparison.csv'),'TextType','string');
f=figure('Visible','off','Color','w','Position',[100 100 900 480]);
bar(reshape(C.wrapped_phase_difference_deg,2,2).');xticklabels({'Original topology','Added copper connections'});grid on;
ylabel('Open / short phase change (degrees)');legend('Floquet mode 1','Floquet mode 2','Location','northwest');
title({'Controlled CST load tests at 26.168 GHz','Initial meshes, both modes; provisional physical interpretation'});
exportgraphics(f,fullfile(out,'open_short_polarization.png'),'Resolution',180);close(f);
P=readtable(fullfile(out,'adaptive_mesh_history.csv'),'TextType','string');
f=figure('Visible','off','Color','w','Position',[100 100 1000 500]);hold on;grid on;
for ex=unique(P.experiment).'
 r=P(P.experiment==ex,:);semilogy(r.tetrahedra,r.all_S_delta,'-o','DisplayName',ex);
end
yline(.005,'--','Strict complex-difference target','HandleVisibility','off');set(gca,'YScale','log');xlabel('Tetrahedra');ylabel('CST all-S complex change between adaptive passes');
legend('Interpreter','none','Location','best');title({'Actual adaptive solver history at 26.168 GHz','Solver stopping criteria and project acceptance gates are distinct'});
exportgraphics(f,fullfile(out,'mesh_refinement.png'),'Resolution',180);close(f);
paper=readtable(fullfile(root,'data','paper_digitized_reference','reflection_states.csv'));
actual=readtable(fullfile(out,'simulation_summary.csv'),'TextType','string');
f=figure('Visible','off','Color','w','Position',[100 100 1050 520]);
for panel=1:2
 subplot(1,2,panel);hold on;grid on;
 for state=0:1
  r=paper(paper.state==state,:);if panel==1,v=r.magnitude;else,v=r.phase_unwrapped_deg;end
  labels={'Paper ON (approx.)','Paper OFF (approx.)'};
  plot(r.frequency_GHz,v,'LineWidth',1.7,'DisplayName',labels{state+1});
 end
 for state=0:1
  ex={'D009_ON_strict','D010_OFF_strict'};
  for mode=1:2
   q=actual(actual.experiment==ex{state+1}&actual.mode==mode,:);
   if isempty(q),continue;end
   if panel==1,v=q.magnitude;else,v=q.phase_deg;end
   markers={'^','s'};colors=[0 .447 .741;.85 .325 .098];
   scatter(q.frequency_GHz,v,65,colors(state+1,:),markers{mode},'filled','DisplayName',sprintf('CST state %d, mode %d',state,mode));
  end
 end
 xlabel('Frequency (GHz)');if panel==1,ylabel('Reflection magnitude');ylim([.6 1.02]);else,ylabel('Unwrapped reflection phase (degrees)');end
 legend('Location','best');
end
sgtitle({'Published Figure 2 curves and actual CST operating-point results','Paper curves approximate; CST markers directly solved at 26.168 GHz (strict meshes)'});
exportgraphics(f,fullfile(out,'paper_reference_curves.png'),'Resolution',180);close(f);
if isfile(fullfile(out,'coarse_broadband_comparison.csv'))
 b=readtable(fullfile(out,'coarse_broadband_comparison.csv'),'TextType','string');
 f=figure('Visible','off','Color','w','Position',[100 100 1100 700]);
 for mode=1:2
  for panel=1:2
   subplot(2,2,(mode-1)*2+panel);hold on;grid on;
   for state=0:1
    q=b(b.mode==mode & b.state==state,:);z=q.CST_real+1j*q.CST_imag;p=q.paper_real+1j*q.paper_imag;
    if panel==1,a=abs(z);v=abs(p);else,a=rad2deg(unwrap(angle(z)));v=rad2deg(unwrap(angle(p)));end
    color=[0 .447 .741;.85 .325 .098];
    plot(q.frequency_GHz,a,'Color',color(state+1,:),'LineWidth',1.5,'DisplayName',sprintf('CST state %d',state));
    plot(q.frequency_GHz,v,'--','Color',color(state+1,:),'LineWidth',1.3,'DisplayName',sprintf('Paper state %d approx.',state));
   end
   xlabel('Frequency (GHz)');if panel==1,ylabel('Reflection magnitude');else,ylabel('Unwrapped phase (degrees)');end
   title(sprintf('Floquet mode %d',mode));legend('Location','best');
  end
 end
 sgtitle({'Coarse broadband diagnostic versus approximate published curves','D015/D016: 2910 tetrahedra; 8 directly solved frequencies; broadband convergence unverified'});
 exportgraphics(f,fullfile(out,'coarse_broadband_comparison.png'),'Resolution',180);close(f);
end
end
