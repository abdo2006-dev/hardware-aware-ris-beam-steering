"""CST 2023 bundled Python 3.6: open an isolated checkpoint through native API."""
import argparse,os,sys
sys.path.insert(0,r'C:\Program Files (x86)\CST Studio Suite 2023\AMD64\python_cst_libraries')
import cst.interface
p=argparse.ArgumentParser();p.add_argument('--pid',type=int,required=True);p.add_argument('--project',required=True);a=p.parse_args()
de=cst.interface.DesignEnvironment.connect(a.pid)
print('Connected:',de.is_connected(),'Projects:',de.list_open_projects(),flush=True)
print('Opening isolated checkpoint:',os.path.abspath(a.project),flush=True)
project=de.open_project(os.path.abspath(a.project))
print('Opened:',de.list_open_projects(),flush=True)
print('Project API:',dir(project),flush=True)
print('Modeler API:',dir(project.modeler),flush=True)
