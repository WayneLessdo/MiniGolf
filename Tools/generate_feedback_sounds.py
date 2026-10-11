"""Original short PCM effects, no external audio assets or dependencies."""
from pathlib import Path
import math, random, struct, wave

root=Path(__file__).resolve().parents[1]/'Resources/Sounds'
root.mkdir(parents=True,exist_ok=True)
rate=44100
rng=random.Random(7)
for name,duration in [('putt',.065),('hole',.42)]:
    path=root/(name+'.wav')
    if path.exists():raise SystemExit('Refusing overwrite: '+str(path))
    samples=[]
    for i in range(int(rate*duration)):
        t=i/rate
        if name=='putt':
            value=.32*math.exp(-t*100)*(rng.uniform(-1,1)*.55+math.sin(2*math.pi*1800*t)*.45)
        else:
            value=sum(.16*math.sin(2*math.pi*f*(t-delay))*math.exp(-(t-delay)*18) for f,delay in [(1046.5,0),(1318.5,.06),(1568,.12)] if t>=delay)
        value*=min(1,t/.001)*min(1,(duration-t)/.01)
        samples.append(struct.pack('<h',int(max(-1,min(1,value))*32767)))
    with wave.open(str(path),'wb') as audio:
        audio.setnchannels(1);audio.setsampwidth(2);audio.setframerate(rate);audio.writeframes(b''.join(samples))
