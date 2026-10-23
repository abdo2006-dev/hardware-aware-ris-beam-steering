"""Export native CST port-mode plots from an explicitly selected checkpoint."""
import os,sys
sys.path.insert(0,r'C:\Program Files (x86)\CST Studio Suite 2023\AMD64\python_cst_libraries')
import cst.interface
folder=os.path.abspath(sys.argv[2]);d=cst.interface.DesignEnvironment.connect(int(sys.argv[1]))
p=d.open_project(os.path.join(folder,os.path.basename(folder)+'.cst'));p.activate()
for mode in [1,2]:
    tree='2D/3D Results\\Port Modes\\Zmax\\In\\e'+str(mode)
    code='Sub Main\nIf Not SelectTreeItem("'+tree+'") Then Err.Raise 1,"audit","Port field item unavailable"\nPlot.ExportImage("'+os.path.join(folder,'native_port_e'+str(mode)+'.png')+'",1400,1000)\nEnd Sub'
    p.modeler._execute_vba_code(code)
    print('Exported field plot mode',mode,flush=True)
