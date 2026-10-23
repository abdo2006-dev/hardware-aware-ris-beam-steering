"""Enumerate the actual native result tree, including port-mode field entries."""
import os,sys
sys.path.insert(0,r'C:\Program Files (x86)\CST Studio Suite 2023\AMD64\python_cst_libraries')
import cst.interface
d=cst.interface.DesignEnvironment.connect(int(sys.argv[1]));p=d.active_project()
output=os.path.abspath(sys.argv[2])
code='''Sub WalkTree(ByVal parent As String)
Dim child As String
child=ResultTree.GetFirstChildName(parent)
Do While child<>""
Print #1, child
WalkTree child
child=ResultTree.GetNextItemName(child)
Loop
End Sub
Sub Main
Open "'''+output+'''" For Output As #1
WalkTree "2D/3D Results"
Close #1
End Sub'''
p.modeler._execute_vba_code(code)
print(open(output).read(),flush=True)
