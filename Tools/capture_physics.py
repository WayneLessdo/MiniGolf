"""Capture six real-engine scenarios on the currently selected, actual simulator pose.

Initial conditions are Debug fixtures, labeled in the UI and proofs. No result state
is directly injected. PNGs are captured from the rendered UIWindow on Simulator.
"""
from pathlib import Path
import argparse,json,subprocess,time,shutil

parser=argparse.ArgumentParser()
parser.add_argument('pose',choices=['compact','regular','folded'])
parser.add_argument('--level',type=int,required=True)
parser.add_argument('--scenario',choices=['tee-off','aiming','hole-success','out-of-bounds','canal-collision','penalty'])
parser.add_argument('--device',default='2B7D0712-AB02-4854-86C5-7FC76DD406F5')
args=parser.parse_args()
root=Path(__file__).resolve().parents[1]
out=root/'docs/screenshots/physics-v1'
out.mkdir(parents=True,exist_ok=True)
bundle='com.foldputt.prototype'
def sim(*command,check=True):
    return subprocess.run(['xcrun','simctl',*command],capture_output=True,text=True,check=check)
folder=Path(sim('get_app_container',args.device,bundle,'data').stdout.strip())/'Documents'
for scenario in ([args.scenario] if args.scenario else ['tee-off','aiming','hole-success','out-of-bounds','canal-collision','penalty']):
    name=f'{args.pose}-{scenario}'
    png=out/(name+'.png');proof=out/(name+'.json')
    if png.exists() or proof.exists():raise SystemExit(f'Refusing overwrite: {name}')
    sim('terminate',args.device,bundle,check=False)
    started=time.time()
    sim('launch',args.device,bundle,'--capture',scenario,'--level',str(args.level))
    source=folder/'physics-capture.json'
    deadline=time.monotonic()+20
    while time.monotonic()<deadline:
        if source.exists() and source.stat().st_mtime>=started:
            data=json.loads(source.read_text())
            if data.get('scenario')==scenario:break
        time.sleep(0.2)
    else:raise SystemExit(f'{name}: no physical event reached; do not fabricate screenshot')
    screenshot=folder/'physics-capture.png'
    if screenshot.stat().st_mtime<started:raise SystemExit('Stale PNG')
    layout=json.loads((folder/'layout-diagnostics.json').read_text())
    if args.pose=='compact':assert layout['horizontalSizeClass']==1,layout
    else:assert layout['horizontalSizeClass']==2,layout
    if args.pose=='folded':assert layout['activeDivision'],layout
    assert not layout.get('buttonRegionViolations',[]),layout
    data.update(pose=args.pose,layout=layout,captureMethod='Simulator UIWindow drawHierarchy; real physics; labeled Debug initial conditions')
    shutil.copy2(screenshot,png)
    with proof.open('x') as f:json.dump(data,f,ensure_ascii=False,indent=2)
    print(name,'PASS',data['event'],flush=True)
