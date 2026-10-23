"""List public changes against the preserved baseline; do not enumerate ignored data."""
import hashlib,json,os,subprocess
from pathlib import Path
R=Path(__file__).resolve().parents[1]
G=os.environ.get('RIS_GIT','git')
baseline='4d61322a2864f6540cac1c53baa1eb6080cee4db'
def git(*args):return subprocess.check_output([G,*args],cwd=R,stderr=subprocess.DEVNULL)
names=set(git('diff','--name-only',baseline).decode().splitlines())
names.update(git('ls-files','--others','--exclude-standard').decode().splitlines())
names.discard('docs/FILE_INDEX.md')
baseline_names=set(git('ls-tree','-r','--name-only',baseline).decode().splitlines())
rows=[]
for name in sorted(names):
 p=R/name
 if not p.is_file():continue
 kind='modified' if name in baseline_names else 'created'
 rows.append([kind,name,len(p.read_bytes()),hashlib.sha256(p.read_bytes()).hexdigest()])
body=['# Exact public change index','',f'Compared with baseline `{baseline}`. Ignored recordings, expanded native result folders and failed preparation copies remain local. This generated index excludes itself to avoid a recursive hash.','', '| Change | File | Bytes | SHA-256 |','|---|---|---:|---|']
body+=['| '+ ' | '.join(map(str,row))+' |' for row in rows]
(R/'docs/FILE_INDEX.md').write_text('\n'.join(body)+'\n',encoding='utf-8')
print(json.dumps({'files':len(rows),'bytes':sum(r[2] for r in rows)}))
