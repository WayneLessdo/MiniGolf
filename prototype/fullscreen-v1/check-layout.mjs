import assert from 'node:assert/strict';
import {layout,presets,intersects,excludes} from './layout.mjs';
let checked=0;
for(const variant of ['a','b','c','d','e','f'])for(const [name,p] of Object.entries(presets))for(const enlarged of [false,true]){
 const l=layout(p.width,p.height,p.insets,variant,enlarged?{brandHeight:72,scoreHeight:82,hintHeight:40}: {},p.regions);
 const s=l.safe,entries=Object.entries(l.widgets);
 for(const [key,r] of entries){assert(r.x>=s.x&&r.y>=s.y&&r.x+r.width<=s.x+s.width+.01&&r.y+r.height<=s.y+s.height+.01,`${variant}/${name}/${enlarged}: ${key} safe area`);assert(!p.regions.some(e=>excludes(e)&&intersects(e,r)),`${variant}/${name}: ${key} reserved`);}
 for(let i=0;i<entries.length;i++)for(let j=i+1;j<entries.length;j++)assert(!intersects(entries[i][1],entries[j][1]),`${variant}/${name}/${enlarged}: ${entries[i][0]}/${entries[j][0]} overlap`);
 checked++;
}
for(const variant of ['a','b','c','d','e','f']) {
 const p=presets.portrait;
 assert.deepEqual(layout(p.width,p.height,p.insets,variant,{},[{x:0,y:0,width:p.width,height:p.height,kind:'camera',active:false}]),layout(p.width,p.height,p.insets,variant));
}
const p=presets.portrait;
const inactiveSeam={x:172,y:0,width:30,height:p.height,kind:'division',active:false};
const adjusted=layout(p.width,p.height,p.insets,'c',{},[inactiveSeam]);
assert(!intersects(adjusted.widgets.pull,inactiveSeam),'inactive physical division still excludes the pull target');
console.log(`${checked} layout cases + 6 inactive-camera checks + 1 inactive-division check passed`);
