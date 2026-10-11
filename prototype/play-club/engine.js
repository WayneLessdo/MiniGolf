'use strict';
// Independent prototype simulation in world coordinates, not the native game's tuning.
FP.physics=Object.freeze({width:760,height:500,left:48,right:712,top:48,bottom:452,radius:11,drag:1.22,sandDrag:3.9,maxSpeed:830,maxPull:150,stopSpeed:5,captureRadius:20,captureSpeed:300,restitution:.81,step:1/120});
FP.validateMap=function(m){
 const P=FP.physics,errors=[];
 const inside=(p,r=16)=>p&&Number.isFinite(p.x)&&Number.isFinite(p.y)&&p.x>=P.left+r&&p.x<=P.right-r&&p.y>=P.top+r&&p.y<=P.bottom-r;
 const hit=(p,r,pad=17)=>p.x>r.x-pad&&p.x<r.x+r.w+pad&&p.y>r.y-pad&&p.y<r.y+r.h+pad;
 if(!inside(m.ball)||!inside(m.hole))errors.push('球和洞需要留在球场内，并离墙至少 16 格。');
 if(m.ball&&m.hole&&Math.hypot(m.ball.x-m.hole.x,m.ball.y-m.hole.y)<60)errors.push('球与洞至少相隔 60 格。');
 for(const key of ['walls','sand','water']){
  if(!Array.isArray(m[key])||m[key].length>20){errors.push('每类地形最多 20 块。');continue;}
  for(const r of m[key]){
   if(![r.x,r.y,r.w,r.h].every(Number.isFinite)||r.w<12||r.h<12||r.x<P.left||r.y<P.top||r.x+r.w>P.right||r.y+r.h>P.bottom)errors.push('地形不能超出边界。');
   if(key!=='sand'&&m.ball&&m.hole&&(hit(m.ball,r)||hit(m.hole,r)))errors.push('墙和水池不能盖住球或洞。');
  }
 }
 return [...new Set(errors)];
};
FP.World=class {
 constructor(map,onEvent=()=>{}){this.map=FP.copy(map);this.onEvent=onEvent;this.ball={...map.ball,vx:0,vy:0};this.safe={...map.ball};this.strokes=0;this.collisions=0;this.rescues=0;this.phase='ready';this.trace=[{x:this.ball.x,y:this.ball.y,t:0,move:true}];this.time=0;this.collected=new Set();this.contacts=new Set();this.lastSample=0;this.shotTrace=[];this.near=false;this.closest=Infinity;}
 launch(dx,dy,power){if(this.phase!=='ready'||!Number.isFinite(power))return false;const length=Math.hypot(dx,dy);if(length<.001||power<.02)return false;const speed=FP.physics.maxSpeed*Math.min(1,power);this.ball.vx=dx/length*speed;this.ball.vy=dy/length*speed;this.safe={x:this.ball.x,y:this.ball.y};this.phase='rolling';this.strokes++;this.contacts.clear();this.near=false;this.closest=Infinity;this.shotTrace=[{x:this.ball.x,y:this.ball.y,t:this.time}];this.onEvent('shot',this);return true;}
 step(dt){if(this.phase!=='rolling')return;const P=FP.physics,b=this.ball;this.time+=dt;const old={x:b.x,y:b.y};b.x+=b.vx*dt;b.y+=b.vy*dt;const touching=new Set();
  const impact=(id,nx,ny)=>{const dot=b.vx*nx+b.vy*ny;if(dot<0){b.vx=(b.vx-2*dot*nx)*P.restitution;b.vy=(b.vy-2*dot*ny)*P.restitution;}touching.add(id);if(!this.contacts.has(id)){this.collisions++;this.onEvent('collision',this);}};
  if(b.x<P.left+P.radius){b.x=P.left+P.radius;impact('left',1,0)}if(b.x>P.right-P.radius){b.x=P.right-P.radius;impact('right',-1,0)}if(b.y<P.top+P.radius){b.y=P.top+P.radius;impact('top',0,1)}if(b.y>P.bottom-P.radius){b.y=P.bottom-P.radius;impact('bottom',0,-1)}
  this.map.walls.forEach((r,i)=>{const x=Math.max(r.x,Math.min(r.x+r.w,b.x)),y=Math.max(r.y,Math.min(r.y+r.h,b.y));let dx=b.x-x,dy=b.y-y,d=Math.hypot(dx,dy);if(d>=P.radius)return;if(d<.001){const edges=[[Math.abs(old.x-r.x),-1,0],[Math.abs(old.x-r.x-r.w),1,0],[Math.abs(old.y-r.y),0,-1],[Math.abs(old.y-r.y-r.h),0,1]].sort((a,b)=>a[0]-b[0]);dx=edges[0][1];dy=edges[0][2];if(dx)b.x=dx<0?r.x-P.radius:r.x+r.w+P.radius;if(dy)b.y=dy<0?r.y-P.radius:r.y+r.h+P.radius;}else{dx/=d;dy/=d;b.x+=dx*(P.radius-d+.01);b.y+=dy*(P.radius-d+.01);}impact('wall'+i,dx,dy);});this.contacts=touching;
  this.map.stars?.forEach((s,i)=>{if(!this.collected.has(i)&&Math.hypot(b.x-s.x,b.y-s.y)<25){this.collected.add(i);this.onEvent('pickup',this);}});
  const hole=this.map.hole,distance=Math.hypot(b.x-hole.x,b.y-hole.y);this.closest=Math.min(this.closest,distance);
  if(distance<P.captureRadius&&Math.hypot(b.vx,b.vy)<P.captureSpeed){b.x=hole.x;b.y=hole.y;b.vx=b.vy=0;this.phase='won';this.record(true);this.onEvent('win',this);return;}
  if(this.map.water.some(r=>b.x>r.x&&b.x<r.x+r.w&&b.y>r.y&&b.y<r.y+r.h)){this.record(true);b.x=this.safe.x;b.y=this.safe.y;b.vx=b.vy=0;this.rescues++;this.phase='ready';this.trace.push({x:b.x,y:b.y,t:this.time,move:true});this.onEvent('water',this);return;}
  if(!this.near&&this.closest<48&&distance>this.closest+16){this.near=true;this.onEvent('near',this);}
  const sand=this.map.sand.some(r=>b.x>r.x&&b.x<r.x+r.w&&b.y>r.y&&b.y<r.y+r.h);const decay=Math.exp(-(sand?P.sandDrag:P.drag)*dt);b.vx*=decay;b.vy*=decay;this.record();
  if(Math.hypot(b.vx,b.vy)<P.stopSpeed){b.vx=b.vy=0;this.phase='ready';this.record(true);this.onEvent('stop',this);}
 }
 record(force=false){if(!force&&this.time-this.lastSample<1/30)return;this.lastSample=this.time;const sample={x:this.ball.x,y:this.ball.y,t:this.time};this.trace.push(sample);this.shotTrace.push(sample);if(this.trace.length>4000)this.trace=this.trace.filter((_,i)=>i%2===0);}
};
FP.Game=class {
 constructor(canvas,map,settings={}){this.canvas=canvas;this.ctx=canvas.getContext('2d');this.settings=settings;this.world=new FP.World(map,(type,w)=>{this.reaction=type;this.reactionAt=performance.now();settings.event?.(type,w);this.render();});this.drag=null;this.paused=false;this.destroyed=false;this.last=0;this.carry=0;this.frame=0;this.skin=settings.skin||0;this.reduced=!!settings.reduced;this.ghost=settings.ghost;this.listen=[];this.resizeObserver=new ResizeObserver(()=>this.render());this.resizeObserver.observe(canvas);this.bind();this.render();this.tick=this.tick.bind(this);this.frame=requestAnimationFrame(this.tick);}
 bind(){const on=(el,type,fn)=>{el.addEventListener(type,fn);this.listen.push(()=>el.removeEventListener(type,fn));};const canvas=this.canvas;canvas.tabIndex=0;canvas.setAttribute('aria-label','可玩高尔夫球场；拖拽球或下方拉杆，松手击球');
  const pos=e=>{const r=canvas.getBoundingClientRect();return {x:(e.clientX-r.left)*760/r.width,y:(e.clientY-r.top)*500/r.height}};
  on(canvas,'pointerdown',e=>{if(this.settings.editor){this.settings.edit?.(pos(e));return;}if(this.paused||this.world.phase!=='ready'||e.button!==0)return;const p=pos(e),b=this.world.ball;if(Math.hypot(p.x-b.x,p.y-b.y)>48)return;canvas.setPointerCapture(e.pointerId);this.startDrag(p,e.pointerId);e.preventDefault();});
  on(canvas,'pointermove',e=>{if(this.drag?.id===e.pointerId){this.moveDrag(pos(e));e.preventDefault();}});
  on(canvas,'pointerup',e=>{if(this.drag?.id===e.pointerId)this.endDrag();});on(canvas,'pointercancel',()=>this.cancel());on(canvas,'lostpointercapture',()=>{if(this.drag)this.cancel();});
  let keys=null;on(canvas,'keydown',e=>{if(e.key==='Escape'){this.cancel();keys=null;return;}if(!['ArrowLeft','ArrowRight','ArrowUp','ArrowDown'].includes(e.key)||this.settings.editor||this.paused||this.world.phase!=='ready')return;e.preventDefault();keys=keys||{x:0,y:0};keys.x+=e.key==='ArrowLeft'?-8:e.key==='ArrowRight'?8:0;keys.y+=e.key==='ArrowUp'?-8:e.key==='ArrowDown'?8:0;this.drag={start:{x:0,y:0},now:{...keys},id:'keyboard'};this.settings.aim?.(this.pull());this.render();});
  on(canvas,'keyup',e=>{if(keys&&e.key.startsWith('Arrow')){e.preventDefault();this.endDrag();keys=null;}});
 }
 bindPad(pad){const point=e=>{const r=this.canvas.getBoundingClientRect(),scale=760/r.width;return{x:e.clientX*scale,y:e.clientY*scale}};const on=(type,fn)=>{pad.addEventListener(type,fn);this.listen.push(()=>pad.removeEventListener(type,fn));};on('pointerdown',e=>{if(this.paused||this.world.phase!=='ready'||e.button!==0)return;pad.setPointerCapture(e.pointerId);this.startDrag(point(e),e.pointerId);e.preventDefault();});on('pointermove',e=>{if(this.drag?.id===e.pointerId){this.moveDrag(point(e));e.preventDefault();}});on('pointerup',e=>{if(this.drag?.id===e.pointerId)this.endDrag();});on('pointercancel',()=>this.cancel());on('lostpointercapture',()=>{if(this.drag)this.cancel();});}
 startDrag(p,id){this.drag={start:p,now:p,id};this.settings.aim?.(0);this.render();}
 moveDrag(p){this.drag.now=p;this.settings.aim?.(this.pull());this.render();}
 pull(){return this.drag?Math.min(1,Math.hypot(this.drag.now.x-this.drag.start.x,this.drag.now.y-this.drag.start.y)/FP.physics.maxPull):0;}
 endDrag(){if(!this.drag)return;const {start,now}=this.drag,power=this.pull();this.drag=null;this.settings.aim?.(0);this.world.launch(start.x-now.x,start.y-now.y,power);this.render();}
 cancel(){this.drag=null;this.settings.aim?.(0);this.render();}
 pause(value){this.paused=value;this.cancel();this.last=0;}
 tick(now){if(this.destroyed)return;const dt=this.last?Math.min(.05,(now-this.last)/1000):0;this.last=now;const rolling=this.world.phase==='rolling';if(!this.paused&&!document.hidden&&rolling){this.carry+=dt;while(this.carry>=FP.physics.step&&this.world.phase==='rolling'){this.world.step(FP.physics.step);this.carry-=FP.physics.step;}this.render();}else if(this.reactionAt&&now-this.reactionAt<900&&!this.reduced)this.render();this.frame=requestAnimationFrame(this.tick);}
 destroy(){this.destroyed=true;cancelAnimationFrame(this.frame);this.listen.forEach(fn=>fn());this.resizeObserver.disconnect();}
 render(){if(this.destroyed)return;const c=this.ctx,canvas=this.canvas,dpr=Math.min(devicePixelRatio||1,2),box=canvas.getBoundingClientRect();if(box.width===0)return;const width=Math.round(box.width*dpr),height=Math.round(box.width*500/760*dpr);if(canvas.width!==width||canvas.height!==height){canvas.width=width;canvas.height=height;}c.setTransform(width/760,0,0,height/500,0,0);const w=this.world,m=w.map,t=FP.themes[m.theme]||FP.themes.garden,P=FP.physics;const night=m.theme==='night';c.clearRect(0,0,760,500);c.fillStyle=t[0];c.fillRect(0,0,760,500);
  const rect=(x,y,ww,hh,r,color,stroke)=>{c.beginPath();c.roundRect(x,y,ww,hh,r);c.fillStyle=color;c.fill();if(stroke){c.strokeStyle=stroke;c.lineWidth=2;c.stroke();}};
  rect(44,53,672,405,34,night?'#162c39':'#9cac7e');rect(P.left,P.top,P.right-P.left,P.bottom-P.top,30,t[1],t[2]);
  c.save();c.beginPath();c.roundRect(P.left,P.top,P.right-P.left,P.bottom-P.top,30);c.clip();
  for(let i=0;i<130;i++){const x=61+(i*139)%640,y=59+(i*53)%377;c.strokeStyle=night?'#678b82':'#6b88532b';c.lineWidth=1.3;c.beginPath();c.moveTo(x,y);c.lineTo(x+3,y+3);c.lineTo(x+5,y-3);c.stroke();}
  if(this.settings.editor){c.strokeStyle='#5d785433';c.lineWidth=1;for(let x=60;x<715;x+=30){c.beginPath();c.moveTo(x,48);c.lineTo(x,452);c.stroke();}for(let y=60;y<455;y+=30){c.beginPath();c.moveTo(48,y);c.lineTo(712,y);c.stroke();}}
  m.sand.forEach(r=>{rect(r.x,r.y,r.w,r.h,15,'#e8ce94','#c3ab76');for(let i=0;i<18;i++){c.fillStyle='#b49b66';c.fillRect(r.x+8+(i*17)%Math.max(1,r.w-16),r.y+8+(i*23)%Math.max(1,r.h-16),1.7,1.7);}});
  m.water.forEach(r=>{rect(r.x,r.y,r.w,r.h,17,night?'#6d9aa7':'#9dc7c7','#74a4a6');c.strokeStyle='#e7f0dba8';c.lineWidth=2;for(let y=r.y+15;y<r.y+r.h-7;y+=15){c.beginPath();c.moveTo(r.x+9,y);c.quadraticCurveTo(r.x+r.w*.3,y+5,r.x+r.w*.5,y);c.quadraticCurveTo(r.x+r.w*.7,y-5,r.x+r.w-9,y);c.stroke();}});
  m.walls.forEach(r=>{rect(r.x,r.y+6,r.w,r.h,5,night?'#172c34':'#587345');rect(r.x,r.y,r.w,r.h,5,m.theme==='office'?'#ad8c72':t[2]);c.fillStyle='#ffffff20';c.fillRect(r.x+3,r.y+3,r.w-6,3);if(m.theme==='office'){rect(r.x+7,r.y+8,Math.min(35,r.w-14),Math.min(22,r.h-16),3,'#f5efd7');}});
  if(this.ghost?.trace?.length){const trace=this.ghost.trace;c.save();c.globalAlpha=.5;c.strokeStyle='#77549c';c.setLineDash([5,7]);c.lineWidth=2;c.beginPath();trace.forEach((p,i)=>i===0||p.move?c.moveTo(p.x,p.y):c.lineTo(p.x,p.y));c.stroke();c.setLineDash([]);if(!this.reduced){const point=trace.find(p=>p.t>=w.time)||trace.at(-1);c.fillStyle='#aa87c9';c.beginPath();c.arc(point.x,point.y,12,0,Math.PI*2);c.fill();}c.restore();}
  if(w.trace.length>1){c.save();c.strokeStyle=night?'#eee1b488':'#ffffeaa0';c.lineWidth=2;c.beginPath();w.trace.forEach((p,i)=>i===0||p.move?c.moveTo(p.x,p.y):c.lineTo(p.x,p.y));c.stroke();c.restore();}
  m.stars?.forEach((s,i)=>{if(w.collected.has(i))return;c.save();c.translate(s.x,s.y);c.rotate(.25);rect(-10,-10,m.theme==='office'?27:20,20,m.theme==='office'?3:6,m.theme==='office'?'#fff3d5':'#f8d081','#9a7844');c.fillStyle='#a67945';c.fillRect(-4,-4,3,3);c.fillRect(3,2,2,2);c.restore();});
  const h=m.hole;if(m.theme==='snack'){c.fillStyle='#fff6dd';c.strokeStyle='#c7a46a';c.lineWidth=3;c.beginPath();c.ellipse(h.x,h.y+1,35,27,0,0,Math.PI*2);c.fill();c.stroke();}c.fillStyle=night?'#203838':'#274b3b';c.beginPath();c.ellipse(h.x,h.y,22,17,0,0,Math.PI*2);c.fill();c.strokeStyle='#f8efce';c.lineWidth=3;c.beginPath();c.moveTo(h.x+2,h.y-5);c.lineTo(h.x+2,h.y-65);c.stroke();c.fillStyle=t[3];c.beginPath();c.moveTo(h.x+2,h.y-64);c.lineTo(h.x+40,h.y-54);c.lineTo(h.x+2,h.y-41);c.closePath();c.fill();
  if(m.theme==='office'){rect(h.x-34,h.y+24,69,25,5,'#f7e9ca','#936951');c.fillStyle='#795241';c.font='bold 13px sans-serif';c.textAlign='center';c.fillText('EXIT',h.x,h.y+42);}
  if(this.drag){const b=w.ball,dx=this.drag.start.x-this.drag.now.x,dy=this.drag.start.y-this.drag.now.y,len=Math.hypot(dx,dy)||1,power=this.pull();c.strokeStyle='#fffbea';c.lineWidth=3;c.setLineDash([7,7]);c.beginPath();c.moveTo(b.x,b.y);c.lineTo(b.x+dx/len*(35+power*125),b.y+dy/len*(35+power*125));c.stroke();c.setLineDash([]);c.strokeStyle=t[2];c.lineWidth=2;c.strokeRect(59,59,642,382);}
  if(w.phase!=='won'||this.settings.editor){const b=w.ball;this.drawBall(c,b.x,b.y,this.settings.classic?0:14);}
  c.restore();
  if(night){c.fillStyle='#eed9a6';for(let i=0;i<15;i++){c.beginPath();c.arc(22+(i*57)%720,i%2?25:477,1.7,0,Math.PI*2);c.fill();}}
  // Small, hand-drawn spectators never cover the playable area.
  this.flower(c,24,114,t[3]);this.flower(c,737,358,t[3]);this.flower(c,685,478,'#fff5cf');
  if(w.phase==='won'){c.save();c.fillStyle='#244833';c.font='bold 22px sans-serif';c.textAlign='center';if(this.reduced)c.fillText('好球，收好这份小成就。',380,29);else{const p=Math.min(1,(performance.now()-this.reactionAt)/800);for(let i=0;i<18;i++){const a=i*Math.PI/9;c.globalAlpha=1-p;c.fillStyle=i%2?'#fff5c6':t[3];c.beginPath();c.arc(h.x+Math.cos(a)*p*88,h.y+Math.sin(a)*p*88,4,0,Math.PI*2);c.fill();}}c.restore();}
 }
 drawBall(c,x,y){const classic=this.settings.classic,food=this.world.map.theme==='snack',colors=['#fff8df','#edb472','#dfb77c'],power=this.pull(),age=(performance.now()-(this.reactionAt||0))/1000,hit=this.reaction==='collision'&&age<.4&&!this.reduced;const r=classic?11:14;c.save();c.fillStyle='#334d3930';c.beginPath();c.ellipse(x+2,y+12,15,5,0,0,Math.PI*2);c.fill();c.translate(x,y);if(hit)c.scale(1.2,.85);c.fillStyle=classic?'#fffdf4':food?colors[this.skin%3]:'#fff5dc';c.strokeStyle='#48623f';c.lineWidth=1.6;c.beginPath();if(food&&this.skin===2)c.roundRect(-14,-13,28,26,7);else c.arc(0,0,r,0,Math.PI*2);c.fill();c.stroke();if(!classic){c.strokeStyle='#344c3b';c.lineWidth=1.8;c.lineCap='round';c.beginPath();if(power>.65){c.moveTo(-7,-5);c.lineTo(-3,-2);c.lineTo(-7,1);c.moveTo(7,-5);c.lineTo(3,-2);c.lineTo(7,1);}else{c.moveTo(-5,-4);c.lineTo(-5,-1);c.moveTo(5,-4);c.lineTo(5,-1);}c.stroke();c.beginPath();c.moveTo(-4,5);c.quadraticCurveTo(0,power>0?3:10,4,5);c.stroke();c.fillStyle='#e2a691';c.beginPath();c.arc(-9,3,2.3,0,Math.PI*2);c.arc(9,3,2.3,0,Math.PI*2);c.fill();if(food&&this.skin===1){c.fillStyle='#5e894b';c.beginPath();c.ellipse(5,-15,7,3,-.5,0,Math.PI*2);c.fill();}}c.restore();}
 flower(c,x,y,color){c.save();c.translate(x,y);c.strokeStyle='#6f855c';c.lineWidth=2;c.beginPath();c.moveTo(0,0);c.lineTo(0,12);c.stroke();c.fillStyle=color;for(let i=0;i<5;i++){const a=i*Math.PI*2/5;c.beginPath();c.ellipse(Math.cos(a)*4,Math.sin(a)*4,3.5,3.5,0,0,Math.PI*2);c.fill();}c.fillStyle='#e0b96d';c.beginPath();c.arc(0,0,2.5,0,Math.PI*2);c.fill();c.restore();}
};
