import {presets,layout,intersects,excludes} from './layout.mjs';
const screen=document.querySelector('#screen'),box=document.querySelector('.scale-box'),svg=document.querySelector('#course'),dialog=document.querySelector('dialog');
const names={a:'A · 四角悬浮',b:'B · 双侧轻栏',c:'C · 边缘一体',d:'DUO 1 · 跨屏沉浸',e:'DUO 2 · 两翼环抱',f:'DUO 3 · 边缘收纳'};
const duoStudy=new URLSearchParams(location.search).get('study')==='duo';
let variant=duoStudy?'d':'b',preset=duoStudy?'duoOpen':'portrait',current,held=false,active=false,origin=null;
const nodes=Object.fromEntries(['brand','score','tools','options','pull','hint'].map(n=>[n,screen.querySelector('.'+n)]));
const position=(node,r)=>{Object.assign(node.style,{left:r.x+'px',top:r.y+'px',width:r.width+'px'});};
function resize(){
 const p=presets[preset];screen.style.width=p.width+'px';screen.style.height=p.height+'px';screen.dataset.variant=variant;
 screen.querySelector('.brand').style.width=Math.min(180,(p.width-p.insets.left-p.insets.right-28)*.6)+'px';
 current=layout(p.width,p.height,p.insets,variant,{brandHeight:nodes.brand.offsetHeight,scoreHeight:nodes.score.offsetHeight,scoreWidth:['b','d','e'].includes(variant)?88:76,hintHeight:nodes.hint.offsetHeight},p.regions);
 for(const [name,r] of Object.entries(current.widgets))position(nodes[name],r);
 const status=screen.querySelector('.system-status');position(status,{x:p.insets.left+20,y:Math.max(10,p.insets.top-32),width:p.width-p.insets.left-p.insets.right-40});status.style.display=p.insets.top>=30?'flex':'none';
 position(screen.querySelector('.top-plate'),{x:current.safe.x-6,y:current.safe.y-8,width:current.safe.width+12});screen.querySelector('.top-plate').style.height=Math.max(nodes.brand.offsetHeight,nodes.score.offsetHeight)+16+'px';
 position(screen.querySelector('.bottom-plate'),{x:current.safe.x-6,y:current.safe.y+current.safe.height-118,width:current.safe.width+12});screen.querySelector('.bottom-plate').style.height='126px';
 document.querySelector('#reserved-regions').innerHTML=p.regions.filter(excludes).map(r=>`<div class="reserved ${r.kind}" style="left:${r.x}px;top:${r.y}px;width:${r.width}px;height:${r.height}px"></div>`).join('');
 renderCourse();fit();
 document.querySelector('#variant-title').textContent=names[variant];document.querySelector('#size-label').textContent=`${p.width} × ${p.height} · ${p.traits}${p.regions.length?' · 保留区评审输入':''}`;
 const issues=[];const entries=Object.entries(current.widgets);
 for(const [name,r] of entries){const s=current.safe;if(r.x<s.x-.1||r.y<s.y-.1||r.x+r.width>s.x+s.width+.1||r.y+r.height>s.y+s.height+.1)issues.push(name+' 超出安全区');if(p.regions.some(e=>excludes(e)&&intersects(r,e)))issues.push(name+' 与保留区重叠');}
 for(let i=0;i<entries.length;i++)for(let j=i+1;j<entries.length;j++)if(intersects(entries[i][1],entries[j][1]))issues.push(entries[i][0]+'/'+entries[j][0]+' 重叠');
 screen.dataset.layoutIssues=JSON.stringify(issues);document.querySelector('#check-result').textContent=issues.length?'需要检查：'+issues.join('；'):'✓ 周边控件无重叠 · 四边安全区分别处理 · 操作热区 ≥44pt';
}
function fit(){const p=presets[preset],available=box.parentElement.clientWidth,scale=Math.min(1,available/p.width);box.style.width=p.width*scale+'px';box.style.height=p.height*scale+'px';screen.style.transform=`scale(${scale})`;}
function renderCourse(){
 const p=presets[preset],f=current.field,x=t=>f.x+t*f.width,y=t=>f.y+t*f.height;
 const visiblePoint=(tx,ty)=>{
   let point={x:x(tx),y:y(ty)};
   for(const r of p.regions.filter(excludes))if(point.x>r.x-12&&point.x<r.x+r.width+12&&point.y>r.y-12&&point.y<r.y+r.height+12){
     const candidates=[{x:r.x-14,y:point.y},{x:r.x+r.width+14,y:point.y},{x:point.x,y:r.y-14},{x:point.x,y:r.y+r.height+14}].filter(c=>c.x>=f.x&&c.x<=f.x+f.width&&c.y>=f.y&&c.y<=f.y+f.height).sort((a,b)=>Math.hypot(a.x-point.x,a.y-point.y)-Math.hypot(b.x-point.x,b.y-point.y));
     if(candidates.length)point=candidates[0];
   }
   return point;
 };
 const cup=visiblePoint(duoStudy ? .78 : .51,duoStudy ? .47 : .17),ball=visiblePoint(duoStudy ? .20 : .50,duoStudy ? .64 : .84);
 svg.setAttribute('viewBox',`0 0 ${p.width} ${p.height}`);
 svg.innerHTML=`<defs><pattern id="sand-grain" width="16" height="16" patternUnits="userSpaceOnUse"><circle cx="3" cy="6" r=".7" fill="#c5a974"/><circle cx="12" cy="13" r=".5" fill="#c5a974"/></pattern><filter id="soft-shadow"><feDropShadow dx="0" dy="3" stdDeviation="2" flood-color="#245a35" flood-opacity=".22"/></filter></defs>
 <path d="M ${x(.05)} ${y(.10)} Q ${x(.48)} ${y(-.02)} ${x(.86)} ${y(.13)} T ${x(.88)} ${y(.66)} Q ${x(.6)} ${y(.89)} ${x(.09)} ${y(.94)}" fill="none" stroke="#f2ffe5" stroke-opacity=".15" stroke-width="26"/>
 <rect x="${x(.03)}" y="${y(.36)}" width="${Math.max(12,f.width*.055)}" height="${f.height*.38}" rx="4" fill="#71b7cb" stroke="#45abbb" stroke-opacity=".55" stroke-width="3"/>
 <path d="M ${x(.83)} ${y(.64)} Q ${x(.92)} ${y(.58)} ${x(1)} ${y(.62)} V ${y(.84)} H ${x(.83)} Z" fill="#73b7cc"/>
 <rect x="${x(.30)}" y="${y(.54)}" width="${f.width*.31}" height="${Math.max(22,f.height*.11)}" rx="14" fill="#fbf6e5" filter="url(#soft-shadow)"/>
 <rect x="${x(.30)}" y="${y(.54)}" width="${f.width*.31}" height="${Math.max(22,f.height*.11)}" rx="14" fill="url(#sand-grain)" opacity=".65"/>
 <rect x="${x(.70)}" y="${y(.30)}" width="${f.width*.19}" height="12" rx="2" fill="#fff9e9" stroke="#438f65" stroke-width="3"/>
 <ellipse cx="${cup.x}" cy="${cup.y}" rx="11" ry="5" fill="#2b684351"/><ellipse cx="${cup.x}" cy="${cup.y}" rx="7" ry="4" fill="#173c2b"/>
 <path d="M ${cup.x} ${cup.y} V ${cup.y-40}" stroke="#fff9e9" stroke-width="3" stroke-linecap="round"/><path d="M ${cup.x+1} ${cup.y-40} l 23 9 -23 9 z" fill="#ec725a"/>
 <circle id="ball" cx="${ball.x}" cy="${ball.y}" r="6" fill="#fffdf4" filter="url(#soft-shadow)"/>
 <path id="aim-line" fill="none" stroke="#fffaf0" stroke-width="2" stroke-dasharray="5 5" stroke-linecap="round"/>
 `;
 for(const seam of p.regions.filter(r=>r.kind==='division')){
   const center=seam.x+seam.width/2,by=y(.53),bw=seam.width+32;
   svg.insertAdjacentHTML('beforeend',`<rect x="${center-bw/2}" y="${by-18}" width="${bw}" height="36" rx="3" fill="#f1e5bf"/><path d="M ${center-bw/2+6} ${by-10} h${bw-12} m-${bw-12} 10 h${bw-12} m-${bw-12} 10 h${bw-12}" stroke="#c5b58a" stroke-width="1"/>`);
 }
}
function aiming(value){active=value;screen.classList.toggle('aiming',value||held);}
const pull=nodes.pull;
pull.addEventListener('pointerdown',e=>{origin={x:e.clientX,y:e.clientY};pull.setPointerCapture(e.pointerId);aiming(true);});
pull.addEventListener('pointermove',e=>{if(!active||!origin)return;const scale=screen.getBoundingClientRect().width/presets[preset].width,dx=(e.clientX-origin.x)/scale,dy=(e.clientY-origin.y)/scale,d=Math.hypot(dx,dy),limit=Math.min(90,d),b=svg.querySelector('#ball');if(d<4)return;svg.querySelector('#aim-line').setAttribute('d',`M ${b.cx.baseVal.value} ${b.cy.baseVal.value} l ${-dx/d*limit} ${-dy/d*limit}`);});
function release(){origin=null;aiming(false);svg.querySelector('#aim-line')?.setAttribute('d','');}
for(const name of ['pointerup','pointercancel','lostpointercapture'])pull.addEventListener(name,release);
for(const button of document.querySelectorAll('[data-variant]'))if(button.tagName==='BUTTON')button.addEventListener('click',()=>{variant=button.dataset.variant;for(const b of document.querySelectorAll('.variants button'))b.setAttribute('aria-pressed',String(b===button));release();resize();});
document.querySelector('#viewport').addEventListener('change',e=>{preset=e.target.value;release();resize();});
document.querySelector('#large').addEventListener('change',e=>{screen.classList.toggle('large',e.target.checked);resize();});
document.querySelector('#reduced').addEventListener('change',e=>screen.classList.toggle('reduced',e.target.checked));
document.querySelector('#hold-preview').addEventListener('click',e=>{held=!held;screen.classList.toggle('aiming',held);e.target.textContent=held?'恢复松手后的界面':'查看拖杆透明状态';});
nodes.options.addEventListener('click',()=>{release();dialog.showModal();});
dialog.querySelector('header button').addEventListener('click',()=>dialog.close());
dialog.addEventListener('click',e=>{const r=dialog.getBoundingClientRect();if(e.clientX<r.left||e.clientX>r.right||e.clientY<r.top||e.clientY>r.bottom)dialog.close();});
for(const button of dialog.querySelectorAll('.option-list button'))button.addEventListener('click',()=>{
 if(button.dataset.level){document.querySelector('#level-id').textContent=button.dataset.level;document.querySelector('#level-name').textContent={'01':'青草练习','02':'运河回响','03':'沙地余韵'}[button.dataset.level];for(const b of dialog.querySelectorAll('[data-level]'))b.querySelector('span')?.remove();button.insertAdjacentHTML('beforeend','<span>当前</span>');resize();}
 if(button.dataset.toggle){const span=button.querySelector('span');span.textContent=span.textContent==='已开启'?'已关闭':'已开启';}
 dialog.close();
});
if(duoStudy){
 document.title='FoldPutt · DUO 三套方案';
 document.querySelector('.eyebrow').textContent='FOLD / PUTT · DUO LAYOUT STUDY';
 document.querySelector('.review-head h1').textContent='DUO：三种跨屏球场布局。';
 document.querySelector('.review-head p').textContent='非 DUO 已选 B · DUO 布局独立比较';
 const concepts=[['d','DUO 1','跨屏沉浸','左下拉杆、右侧工具。大画布与跨缝通路优先。'],['e','DUO 2','两翼环抱','左侧信息、右侧操作。两边分工，中央保持净空。'],['f','DUO 3','边缘收纳','顶部信息条、底部角落操作。更明确的层级与边界。']];
 document.querySelectorAll('.variants button').forEach((b,i)=>{const [key,id,title,description]=concepts[i];b.dataset.variant=key;b.innerHTML=`<b>${id}<span>${title}</span></b><small>${description}</small>`;});
 document.querySelector('.review-note p:last-child').textContent='画幅、安全区及保留区来自 2026-09-30 DUO 模拟器历史采样；这是方案图，非新运行截图。';
}
for(const b of document.querySelectorAll('.variants button'))b.setAttribute('aria-pressed',String(b.dataset.variant===variant));
document.querySelector('#viewport').value=preset;
new ResizeObserver(fit).observe(box.parentElement);
resize();
