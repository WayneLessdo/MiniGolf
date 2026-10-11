/* FoldPutt visual study. Motion paths below are presentation choreography,
   not the Swift project's physics, level data, reward rules, or DUO adapter. */
'use strict';
(() => {
  const $ = id => document.getElementById(id);
  const NS = 'http://www.w3.org/2000/svg';
  const course = $('course');
  const systemMotion = matchMedia('(prefers-reduced-motion: reduce)');
  const motion = Object.freeze({ swing: 240, charge: 780, roll: 1500, slowRoll: 2050, sink: 270, particles: 800, expression: 850, bubble: 1600 });
  const home = { x: 304, y: 470 }, cup = { x: 320, y: 221 };
  const state = { mood: 'cozy', skin: 'rice', phase: 'ready', ball: { ...home }, strokes: 0, seen: new Set(), reduced: systemMotion.matches, sound: false, epoch: 0, drag: null };
  const jobs = new Set();
  const faces = {
    smile: ['M-7-3v3M7-3v3', 'M-4 7q4 4 8 0'],
    focus: ['M-11-5l7 3M11-5 4-2', 'M-4 8h8'],
    effort: ['M-11-4l6 3-6 3M11-4 5-1l6 3', 'M-4 8q4-4 8 0'],
    roll: ['M-10-2q3-5 6 0M4-2q3-5 6 0', 'M-5 6q5 8 10 0Z'],
    surprise: ['M-7-5v5M7-5v5', 'M-3 7a3 4 0 1 0 6 0a3 4 0 1 0-6 0'],
    side: ['M-11-2v3M1-2v3', 'M-9 8h7'],
    happy: ['M-11 0q4-7 8 0M3 0q4-7 8 0', 'M-5 6q5 8 10 0'],
    flat: ['M-12-1h7M5-1h7', 'M-4 8h8']
  };
  const story = {
    cozy: {
      ready: '小球已经就位。\n它说，它一点都不紧张。', face: '认真脸、包子脸、开心脸。\n一颗小球，也有好多小情绪。', swing: '往后一点点，再轻轻一挥。\n小小的出发，也值得认真对待。', letters: '啵，是出发。沙沙，是路过。\n咕噜，是终于找到自己的小窝。', near: '我们刚刚对视了一眼。\n没关系，再靠近一点就好。', win: '到家啦。\n今天的小小成就，收好。', idle: '球停下来，也可以歇一会儿。\n下一杆，还是慢慢来。', drag: '认真起来，连腮帮子都鼓了。\n松手就出发，不用再点确认。'
    },
    silly: {
      ready: '今日计划：一杆入洞。\n实在不行，就当出来散步。', face: '球不大，戏挺多。\n尤其是觉得自己能进的时候。', swing: '架势已经拿捏了。\n至于球技，下次一定。', letters: '球可以没进，\n但出场音效必须到位。', near: '洞：你礼貌吗？\n球：路过，路过。', win: '终于下班了！\n本球今日的运动量，已超标。', idle: '停在这里，主要是看看风景。\n不是没劲了，真的。', drag: '正在加载：职业选手气质。\n球：别拉了，脸要憋圆了。'
    }
  };
  const skin = {
    rice: { name: '糯米团子', caption: '圆，是一种生活态度。', color: '#fffbea', shade: '#eee8c8' },
    peach: { name: '桃桃丸子', caption: '脸红，只是因为晒了太阳。', color: '#f6c6b6', shade: '#e8ac97' },
    sesame: { name: '芝麻小圆', caption: '外表稳重，内心弹弹。', color: '#d3d7c4', shade: '#b3bca0' }
  };
  function el(tag, attributes = {}, parent) {
    const node = document.createElementNS(NS, tag);
    for (const [name, value] of Object.entries(attributes)) node.setAttribute(name, value);
    if (parent) parent.append(node);
    return node;
  }
  // Deterministic vector scenery; no external fonts, images, or libraries.
  let seed = 821;
  const random = () => { seed = (seed * 16807) % 2147483647; return (seed - 1) / 2147483646; };
  for (let i = 0; i < 72; i++) {
    const x = 15 + random() * 570, y = 93 + random() * 502;
    if (x > 137 && x < 462 && y < 538) continue;
    el('use', { href: '#tuft', transform: `translate(${x} ${y}) scale(${.65 + random() * .45})`, opacity: .35 + random() * .3 }, $('ground-doodles'));
  }
  [[92,232],[112,245],[486,314],[500,322],[224,568],[245,576],[407,114],[73,388],[490,547]].forEach(([x,y],i) => el('use',{href:'#flower',transform:`translate(${x} ${y}) scale(${i%2 ? .64 : .85})`},$('ground-doodles')));

  function say(key) { $('story').textContent = story[state.mood][key] || key; }
  function phase(next, label) { state.phase = next; document.body.dataset.phase = next; $('phase-label').textContent = label; }
  function face(name) {
    const [eyes, mouth] = faces[name] || faces.smile;
    $('eyes').setAttribute('d', eyes); $('mouth').setAttribute('d', mouth);
    $('sweat').setAttribute('opacity', name === 'effort' && state.mood === 'silly' ? 1 : 0);
    course.dataset.expression = name;
  }
  function ball(x, y, scale = 1, turn = 0) {
    state.ball = { x, y };
    $('ball').setAttribute('transform', `translate(${x} ${y})`);
    $('ball-body').setAttribute('transform', `scale(${scale}) rotate(${state.reduced ? 0 : turn})`);
    $('ball-shadow').setAttribute('opacity', scale < 1 ? .3 * scale : .3);
  }
  function cancel() {
    state.epoch++;
    for (const stop of [...jobs]) stop();
    jobs.clear();
    if (state.drag && course.hasPointerCapture(state.drag.id)) course.releasePointerCapture(state.drag.id);
    state.drag = null;
  }
  function pause(ms) {
    return new Promise(resolve => {
      const timer = setTimeout(() => { jobs.delete(stop); resolve(true); }, ms);
      const stop = () => { clearTimeout(timer); jobs.delete(stop); resolve(false); };
      jobs.add(stop);
    });
  }
  function animate(ms, step) {
    if (state.reduced) { step(1); return Promise.resolve(true); }
    return new Promise(resolve => {
      const start = performance.now(); let frame;
      const stop = () => { cancelAnimationFrame(frame); jobs.delete(stop); resolve(false); };
      const tick = now => { const t = Math.min(1, (now - start) / ms); step(t); if (t < 1) frame = requestAnimationFrame(tick); else { jobs.delete(stop); resolve(true); } };
      jobs.add(stop); frame = requestAnimationFrame(tick);
    });
  }
  function bubble(text, x, y, { size = 24, angle = -6, color = '#536a44', boxed = false, duration = motion.bubble } = {}) {
    const group = el('g', { transform: `translate(${x} ${y}) rotate(${angle})` }, $('effects'));
    if (boxed) {
      const width = Math.max(40, Array.from(text).length * size + 20);
      el('rect', { x: -width/2, y: -size-8, width, height:size+22, rx:12, fill:'#fffbed', stroke:'#a7b287', 'stroke-width':1.3 }, group);
      el('path', { d:'M-5 13 0 22 7 13', fill:'#fffbed', stroke:'#a7b287', 'stroke-width':1.2 }, group);
    }
    const label = el('text', { 'text-anchor':'middle', class:'hand', 'font-size':size, fill:color, 'font-weight':500, 'paint-order':'stroke', stroke:boxed?'none':'#f0f3d9','stroke-width':boxed?0:4,'stroke-linejoin':'round' }, group);
    label.textContent = text;
    if (duration > 0) pause(duration).then(alive => { if (alive) group.remove(); });
    return group;
  }
  function clearAim() { $('aim-path').setAttribute('d',''); $('pull-path').setAttribute('d',''); $('pull-end').setAttribute('opacity',0); }
  function reset({ silent = false } = {}) {
    cancel(); state.strokes = 0; $('strokes').textContent = '0'; $('result').hidden = true;
    $('effects').replaceChildren(); $('particles').replaceChildren(); $('hole-eyes').setAttribute('opacity',0);
    $('ball').setAttribute('opacity',1); clearAim(); ball(home.x,home.y); face('smile');
    $('club-position').setAttribute('transform',`translate(${home.x-29} ${home.y+2})`);
    $('club-position').setAttribute('opacity',1); $('club').setAttribute('transform','rotate(-23)');
    phase('ready','准备好啦');
    document.querySelectorAll('.idea').forEach(button => { button.classList.remove('active'); button.removeAttribute('aria-current'); });
    if (!silent) say('ready');
  }
  function visited(id) {
    state.seen.add(id);
    const button = document.querySelector(`.idea[data-idea="${id}"]`);
    if (button) { button.classList.add('visited'); button.querySelector('.idea-check').textContent = '✓'; }
    $('seen-count').textContent = `${state.seen.size} / 5`;
  }
  function selectIdea(id) {
    visited(id);
    document.querySelectorAll('.idea').forEach(button => { const active = button.dataset.idea === id; button.classList.toggle('active',active); if(active)button.setAttribute('aria-current','true');else button.removeAttribute('aria-current'); });
    say(id);
  }
  let audio;
  function sound(kind) {
    if (!state.sound) return;
    try {
      audio ||= new (window.AudioContext || window.webkitAudioContext)();
      if (audio.state === 'suspended') audio.resume().catch(()=>{});
      const sequence = kind === 'win' ? [523.25,659.25,783.99] : kind === 'tap' ? [420] : [280];
      sequence.forEach((frequency,index) => {
        const oscillator = audio.createOscillator(), gain = audio.createGain(), at = audio.currentTime + index * .11;
        oscillator.type = 'sine'; oscillator.frequency.setValueAtTime(frequency,at); gain.gain.setValueAtTime(0,at); gain.gain.linearRampToValueAtTime(.055,at+.012); gain.gain.exponentialRampToValueAtTime(.001,at+.2);
        oscillator.connect(gain); gain.connect(audio.destination); oscillator.start(at); oscillator.stop(at+.22);
      });
    } catch { state.sound=false; updateSound(); }
  }
  async function confetti() {
    if(state.reduced) return;
    const pieces=[];
    for(let i=0;i<16;i++) {
      const angle=i/16*Math.PI*2, radius=40+random()*50;
      const piece=el('path',{d:'M0-5 1.5-1.5 5 0 1.5 1.5 0 5-1.5 1.5-5 0-1.5-1.5Z',fill:['#e0ab6b','#f6f3d0','#ecba9c','#6e966b'][i%4]},$('particles'));
      pieces.push({piece,angle,radius});
    }
    await animate(motion.particles,t=>pieces.forEach(({piece,angle,radius})=>piece.setAttribute('transform',`translate(${cup.x+Math.cos(angle)*radius*t} ${cup.y-20+Math.sin(angle)*radius*t+t*t*40}) scale(${1-t*.9}) rotate(${t*180})`)));
    pieces.forEach(({piece})=>piece.remove());
  }
  async function finishWin() {
    const epoch=state.epoch;
    phase('sinking','咕噜，入洞了'); face('happy'); visited('win'); visited('letters');
    bubble('咕噜',cup.x-51,cup.y+22,{size:24,duration:1000}); sound('win');
    if(!await animate(motion.sink,t=>ball(cup.x,cup.y+t*5,1-t)))return;
    $('ball').setAttribute('opacity',0); confetti();
    say('win'); phase('success',state.mood==='silly'?'打卡下班！':'今天也很棒');
    $('result-title').textContent=state.mood==='silly'?'终于下班了！':'到家啦。';
    $('result-copy').textContent=state.mood==='silly'?'本球今日运动量，已超标。':`${state.strokes} 杆的小小成就，值得好好收起来。`;
    if(!await pause(state.reduced?0:420)||state.epoch!==epoch)return;
    $('result').hidden=false;
  }
  async function nearMoment() {
    visited('near'); face(state.mood==='silly'?'flat':'side'); $('hole-eyes').setAttribute('opacity',1);
    phase('ready','差一点点，再来'); say('near');
    bubble('？',cup.x-38,cup.y-22,{size:34,duration:0});
    bubble(state.mood==='silly'?'路过，路过。':'刚刚在叫我吗？',state.ball.x+4,state.ball.y-53,{size:16,boxed:true,angle:4,duration:0});
    if(state.mood==='silly')bubble('你礼貌吗',cup.x-81,cup.y+43,{size:17,angle:-8,duration:0});
  }
  function segmentDistance(point,a,b) {
    const dx=b.x-a.x,dy=b.y-a.y,length=dx*dx+dy*dy;
    const t=length?Math.max(0,Math.min(1,((point.x-a.x)*dx+(point.y-a.y)*dy)/length)):0;
    return Math.hypot(point.x-a.x-dx*t,point.y-a.y-dy*t);
  }
  async function shoot({ target, outcome='auto', lettering=false, slow=false }) {
    const start={...state.ball}; const epoch=state.epoch;
    state.strokes++; $('strokes').textContent=state.strokes;
    visited('face'); visited('swing'); phase('swing','小球杆，出发'); clearAim(); face('focus');
    $('effects').replaceChildren(); $('hole-eyes').setAttribute('opacity',0);
    const direction=Math.atan2(target.y-start.y,target.x-start.x)*180/Math.PI+90;
    $('club-position').setAttribute('transform',`translate(${start.x-24} ${start.y+3}) rotate(${direction})`);
    if(!await animate(motion.swing,t=>$('club').setAttribute('transform',`rotate(${-65+95*(1-(1-t)**3)})`)))return;
    $('club-position').setAttribute('opacity',0);
    sound('tap'); bubble(state.mood==='silly'?'走你！':'啵',start.x-44,start.y-24,{size:29,angle:-12,duration:1000}); visited('letters');
    phase('rolling','咕噜噜…'); face('roll');
    const win=outcome==='win'||(outcome==='auto'&&segmentDistance(cup,start,target)<19);
    const clipped={x:Math.min(442,Math.max(155,target.x)),y:Math.min(517,Math.max(159,target.y))};
    const bounced=outcome==='auto'&&(clipped.x!==target.x||clipped.y!==target.y);
    const end=win?cup:clipped;
    let sandShown=false,bounceShown=false;
    const duration=slow?motion.slowRoll:motion.roll;
    if(!await animate(duration,t=>{
      const eased=1-(1-t)**2;
      // The lettering vignette deliberately visits the sand before the cup.
      const x=lettering?(1-eased)**2*start.x+2*(1-eased)*eased*140+eased**2*end.x:start.x+(end.x-start.x)*eased;
      const y=lettering?(1-eased)**2*start.y+2*(1-eased)*eased*190+eased**2*end.y:start.y+(end.y-start.y)*eased;
      ball(x,y,1,Math.sin(t*Math.PI*7)*7*(1-t));
      if(lettering&&!sandShown&&t>.3){sandShown=true;bubble('沙沙',x-49,y+5,{size:26,duration:950});}
      if(bounced&&!bounceShown&&t>.8){bounceShown=true;bubble(state.mood==='silly'?'邦！':'叩',x-28,y-39,{size:28,color:'#96764d'});sound('bump');}
    }))return;
    if(state.epoch!==epoch)return;
    if(win){await finishWin();return;}
    if(outcome==='near'||Math.hypot(end.x-cup.x,end.y-cup.y)<67){await nearMoment();return;}
    face(bounced?'surprise':'smile'); phase('ready','再试一小杆'); say('idle');
  }
  async function chargePreview() {
    phase('charging','认真蓄力中');
    return animate(motion.charge,t=>{
      face(t>.72?'effort':'focus');
      $('club').setAttribute('transform',`rotate(${-23-t*42})`);
      $('aim-path').setAttribute('d',`M${home.x} ${home.y-30}L${home.x+(cup.x-home.x)*t} ${home.y-30-150*t}`);
      $('pull-path').setAttribute('d',`M${home.x} ${home.y+27}l0 ${t*46}`);
    });
  }
  async function playIdea(id) {
    reset({silent:true});selectIdea(id);
    if(id==='face'){
      visited('face');phase('expression','表情营业中');
      const sequence=state.mood==='silly'?[['focus','拿捏。'],['effort','憋住！'],['flat','就这？'],['happy','嘿嘿。']]:[['smile','你好呀'],['focus','认真了'],['effort','攒点劲'],['happy','好开心']];
      if(state.reduced){face('happy');bubble(sequence.at(-1)[1],home.x+59,home.y-42,{boxed:true,size:18,duration:0});phase('ready','静态表情预览');return;}
      for(const [expression,text] of sequence){face(expression);$('effects').replaceChildren();bubble(text,home.x+59,home.y-44,{boxed:true,size:19,duration:0});if(!await pause(motion.expression))return;}
      phase('ready','表情已就位'); return;
    }
    if(!await chargePreview())return;
    if(id==='near')await shoot({target:{x:370,y:208},outcome:'near'});
    else if(id==='letters')await shoot({target:cup,outcome:'win',lettering:true,slow:true});
    else await shoot({target:cup,outcome:'win',slow:id==='win'});
  }
  function point(event) {
    const matrix=course.getScreenCTM();
    return new DOMPoint(event.clientX,event.clientY).matrixTransform(matrix.inverse());
  }
  function updateDrag(event) {
    if(!state.drag||event.pointerId!==state.drag.id)return;
    const current=point(event), dx=current.x-state.drag.start.x,dy=current.y-state.drag.start.y,length=Math.hypot(dx,dy),limit=95;
    state.drag.dx=dx*Math.min(1,limit/(length||1));state.drag.dy=dy*Math.min(1,limit/(length||1));state.drag.power=Math.min(1,length/limit);
    face(state.drag.power>.72?'effort':'focus');
    const origin=state.ball;
    const aim={x:origin.x-state.drag.dx*2.9,y:origin.y-state.drag.dy*2.9};
    $('aim-path').setAttribute('d',`M${origin.x} ${origin.y}L${aim.x} ${aim.y}`);
    $('pull-path').setAttribute('d',`M${origin.x} ${origin.y}l${state.drag.dx} ${state.drag.dy}`);
    $('pull-end').setAttribute('cx',origin.x+state.drag.dx);$('pull-end').setAttribute('cy',origin.y+state.drag.dy);$('pull-end').setAttribute('opacity',1);
    const direction=Math.atan2(-state.drag.dy,-state.drag.dx)*180/Math.PI+90;
    $('club-position').setAttribute('opacity',1);$('club-position').setAttribute('transform',`translate(${origin.x-24} ${origin.y+3}) rotate(${direction})`);
    $('club').setAttribute('transform',`rotate(${-23-state.drag.power*42})`);
    $('phase-label').textContent=`蓄力 ${Math.round(state.drag.power*100)}%`;
  }
  course.addEventListener('pointerdown',event=>{
    if(event.button!==0||!event.isPrimary||state.phase!=='ready')return;
    const local=point(event);
    if(Math.hypot(local.x-state.ball.x,local.y-state.ball.y)>48)return;
    event.preventDefault();cancel();$('effects').replaceChildren();$('hole-eyes').setAttribute('opacity',0);
    state.drag={id:event.pointerId,start:local,dx:0,dy:0,power:0};course.setPointerCapture(event.pointerId);
    phase('charging','认真蓄力中');face('focus');visited('face');say('drag');
  });
  course.addEventListener('pointermove',updateDrag);
  course.addEventListener('pointerup',event=>{
    if(!state.drag||event.pointerId!==state.drag.id)return;
    updateDrag(event);
    const drag=state.drag;state.drag=null;
    if(course.hasPointerCapture(event.pointerId))course.releasePointerCapture(event.pointerId);
    clearAim();
    if(Math.hypot(drag.dx,drag.dy)<5){phase('ready','准备好啦');face('smile');say('ready');return;}
    shoot({target:{x:state.ball.x-drag.dx*2.9,y:state.ball.y-drag.dy*2.9}});
  });
  const cancelDrag=()=>{if(!state.drag)return;state.drag=null;clearAim();face('smile');phase('ready','拉杆已取消');};
  course.addEventListener('pointercancel',cancelDrag);course.addEventListener('lostpointercapture',cancelDrag);
  document.addEventListener('keydown',event=>{if(event.key==='Escape')reset();});
  document.querySelectorAll('[data-idea]').forEach(button=>button.addEventListener('click',()=>{
    playIdea(button.dataset.idea);
    if(button.classList.contains('moment')||innerWidth<=660)$('course-frame').scrollIntoView({behavior:state.reduced?'instant':'smooth',block:'center'});
  }));
  $('auto-play').addEventListener('click',()=>playIdea('swing'));
  $('reset').addEventListener('click',()=>reset());
  $('again').addEventListener('click',()=>{reset();$('auto-play').focus({preventScroll:true});});
  document.querySelector('.brand').addEventListener('click',event=>{event.preventDefault();reset();window.scrollTo({top:0,behavior:state.reduced?'instant':'smooth'});});
  document.querySelectorAll('.mood-switch button').forEach(button=>button.addEventListener('click',()=>{
    state.mood=button.dataset.mood;document.body.dataset.mood=state.mood;
    document.querySelectorAll('.mood-switch button').forEach(item=>{const on=item===button;item.classList.toggle('selected',on);item.setAttribute('aria-pressed',on);});
    $('intro-title').innerHTML=state.mood==='silly'?'今天，整点<br><span>小小的好活。</span>':'今天，打个<br><span>小小的好球。</span>';
    $('intro-copy').innerHTML=state.mood==='silly'?'球技先放一边，<br>可爱这件事，咱们很专业。':'让小球慢慢滚，<br>把今天的烦恼留在草地上。';
    document.querySelector('.weather').textContent=state.mood==='silly'?'今天宜：整点好活':'今天宜：慢慢来';
    $('flag-cloth').setAttribute('fill',state.mood==='silly'?'#dfb16d':'#eeaa86');reset();
  }));
  document.querySelectorAll('[data-skin]').forEach(button=>button.addEventListener('click',()=>{
    state.skin=button.dataset.skin;const choice=skin[state.skin];
    $('ball-name').textContent=choice.name;$('ball-caption').textContent=choice.caption;
    document.querySelector('.skin-fill').setAttribute('fill',choice.color);
    $('ball-gradient-stop').setAttribute('stop-color',choice.shade);
    document.querySelector('#ball-grad stop').setAttribute('stop-color',choice.color);
    document.querySelectorAll('[data-skin]').forEach(item=>{item.classList.toggle('selected',item===button);item.setAttribute('aria-pressed',item===button);});
    if(state.phase==='ready'){face('happy');bubble('是我呀',state.ball.x+55,state.ball.y-43,{boxed:true,size:18});}
  }));
  function updateSound(){$('sound').setAttribute('aria-pressed',state.sound);$('sound').querySelector('span').textContent=state.sound?'声音开':'声音关';}
  $('sound').addEventListener('click',()=>{state.sound=!state.sound;updateSound();if(state.sound)sound('tap');else if(audio)audio.suspend().catch(()=>{});});
  function updateMotion(value){state.reduced=value;document.body.classList.toggle('reduce-motion',value);$('motion').setAttribute('aria-pressed',value);$('motion').querySelector('span').textContent=value?'静态反馈':'减少动效';reset();}
  $('motion').addEventListener('click',()=>updateMotion(!state.reduced));
  systemMotion.addEventListener('change',event=>updateMotion(event.matches));
  document.addEventListener('visibilitychange',()=>{if(document.hidden&&state.phase!=='ready'&&state.phase!=='success')reset();});
  new ResizeObserver(()=>{if(state.drag){cancel();clearAim();face('smile');phase('ready','拉杆已取消');}}).observe(course);
  updateMotion(state.reduced);
})();
