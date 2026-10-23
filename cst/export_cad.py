"""Export the actual current CST model viewport through CST's documented API."""
import os,sys
sys.path.insert(0,r'C:\Program Files (x86)\CST Studio Suite 2023\AMD64\python_cst_libraries')
import cst.interface
d=cst.interface.DesignEnvironment.connect(int(sys.argv[1]))
folder=os.path.abspath(sys.argv[2]);os.makedirs(folder,exist_ok=True)
p=d.open_project(os.path.join(folder,os.path.basename(folder)+'.cst'));p.activate()
code='Sub Main\nSelectTreeItem("Components")\nPlot.ShowCutplane "False"\nPlot.ZoomToStructure\nPlot.Update\nPlot.ExportImage("'+os.path.join(folder,'cad_current_view.png')+'",1400,1000)\nEnd Sub'
p.modeler._execute_vba_code(code)
for normal,ratio,label in [('z',.9692982456140351,'xy_copper_section'),('y',.5,'xz_center_section'),('x',.5,'yz_center_section')]:
    code='Sub Main\nSelectTreeItem("Components")\nPlot.CutPlaneNormal "'+normal+'"\nPlot.CutPlaneRatio "'+str(ratio)+'"\nPlot.ShowCutplane "True"\nPlot.Draw2DWithCutPlane "True"\nPlot.ZoomToStructure\nPlot.Update\nPlot.ExportImage("'+os.path.join(folder,'cad_'+label+'.png')+'",1400,1000)\nEnd Sub'
    p.modeler._execute_vba_code(code)
p.modeler._execute_vba_code('Sub Main\nPlot.ShowCutplane "False"\nPlot.Draw2DWithCutPlane "False"\nEnd Sub')
print('Exported actual CAD viewport',flush=True)
