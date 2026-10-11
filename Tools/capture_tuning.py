"""Capture the current Device Hub pose; never silently simulate the requested pose."""
from pathlib import Path
import argparse,json,subprocess,time,shutil,plistlib

p=argparse.ArgumentParser()
p.add_argument('name');p.add_argument('--scenario',default='tee-off',choices=['tee-off','aiming','hole-success','boost','penalty','seam-crossing','seam-collision'])
p.add_argument('--output-dir',default='docs/screenshots/tuning-v1');p.add_argument('--require-visible',action='store_true')
p.add_argument('--half-window',choices=['left','right']);p.add_argument('--handheld',action='store_true')
p.add_argument('--live',action='store_true');p.add_argument('--display',default='3')
p.add_argument('--bundle')
p.add_argument('--device',default='2B7D0712-AB02-4854-86C5-7FC76DD406F5')
a=p.parse_args();root=Path(__file__).resolve().parents[1];out=root/a.output_dir
out.mkdir(parents=True,exist_ok=True)
def sim(*args,check=True):return subprocess.run(['xcrun','simctl',*args],capture_output=True,text=True,check=check)
built=root/'work/DerivedData/Build/Products/Debug-iphonesimulator/FoldPutt.app/Info.plist'
bundle=a.bundle or plistlib.loads(built.read_bytes())['CFBundleIdentifier']
folder=Path(sim('get_app_container',a.device,bundle,'data').stdout.strip())/'Documents'
name=a.name if a.live else a.name+'-'+a.scenario
if (out/(name+'.png')).exists():raise SystemExit('Refusing overwrite: '+name)
if a.live:
    sim('io',a.device,'screenshot','--display='+a.display,str(out/(name+'.png')))
    data=json.loads((folder/'layout-diagnostics.json').read_text())
    if a.require_visible:assert data.get('courseVisible') and data.get('controlsVisible') and not data.get('buttonRegionViolations'),data
    (out/(name+'.json')).write_text(json.dumps({'fixture':data.get('regionSource')=='synthetic-debug-fixture','layout':data},ensure_ascii=False,indent=2))
    print(name,data['mode'],data['strokes'],data.get('lastLaunch'))
    raise SystemExit(0)
sim('terminate',a.device,bundle,check=False);started=time.time()
extra=[]
if a.half_window:extra=['--half-window',a.half_window,'--simulate-division']
if a.handheld:extra+=['--handheld']
sim('launch',a.device,bundle,'--capture',a.scenario,'--level','0',*extra)
proof=folder/'physics-capture.json';deadline=time.monotonic()+25
while time.monotonic()<deadline:
    if proof.exists() and proof.stat().st_mtime>=started:
        data=json.loads(proof.read_text())
        if data.get('scenario')==a.scenario:break
    time.sleep(.2)
else:raise SystemExit('No real event captured')
data['layout']=json.loads((folder/'layout-diagnostics.json').read_text())
assert not data['layout'].get('buttonRegionViolations'),data['layout']
if a.require_visible:assert data['layout'].get('courseVisible') and data['layout'].get('controlsVisible'),data['layout']
data['captureMethod']='Actual Simulator UIWindow rendering; explicit initial-condition fixture'
shutil.copy2(folder/'physics-capture.png',out/(name+'.png'))
(out/(name+'.json')).write_text(json.dumps(data,ensure_ascii=False,indent=2))
print(name,data['layout']['bounds'],data['layout'].get('arrangement'),data.get('boostCounts'))
