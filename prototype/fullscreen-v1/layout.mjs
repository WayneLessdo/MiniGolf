export const presets={
 duoOpen:{"traits": "regular / regular", "width": 951.0, "height": 669.0, "insets": {"right": 84, "top": 0, "left": 0, "bottom": 34}, "regions": [{"x": 455.5, "y": 0.0, "width": 40.0, "height": 669.0, "kind": "division", "active": false}, {"x": 867.0, "y": 0.0, "width": 84.0, "height": 120.0, "kind": "camera", "active": true}], "source": "docs/screenshots/duo-immersive/duo-open-tee-off.json", "sampleDate": "2026-09-30", "note": "历史 iPhone Duo 模拟器采样；B 已确定用于非 DUO，DUO 三个新布局为设计预览"},
 portrait:{traits:"compact / regular",width:375,height:812,insets:{top:52,left:0,bottom:34,right:0},regions:[]},
 narrow:{traits:"compact / regular",width:320,height:640,insets:{top:32,left:0,bottom:24,right:0},regions:[]},
 landscape:{traits:"compact / compact",width:812,height:375,insets:{top:0,left:44,bottom:21,right:20},regions:[]},
 regular:{traits:"regular / regular",width:1024,height:768,insets:{top:24,left:0,bottom:24,right:0},regions:[]},
 reserved:{traits:"regular / regular",width:1024,height:768,insets:{top:24,left:0,bottom:24,right:0},regions:[{x:496,y:0,width:32,height:768,kind:'division',active:true},{x:550,y:28,width:26,height:44,kind:'camera',active:true}]},
 asymmetric:{traits:"compact / regular",width:528,height:678,insets:{top:0,left:0,bottom:34,right:84},regions:[]}
};
export const excludes=r=>r.kind==='division'||r.active;
export const intersects=(a,b)=>a.x<b.x+b.width&&a.x+a.width>b.x&&a.y<b.y+b.height&&a.y+a.height>b.y;
export function layout(width,height,insets,variant,sizes={},regions=[]){
 const safe={x:insets.left+14,y:insets.top+12,width:width-insets.left-insets.right-28,height:height-insets.top-insets.bottom-24};
 const right=safe.x+safe.width,bottom=safe.y+safe.height;
 const brand={width:Math.min(180,safe.width*.6),height:sizes.brandHeight??52};
 const score={width:sizes.scoreWidth??76,height:sizes.scoreHeight??65};
 const hint={width:Math.min(156,safe.width*.48),height:sizes.hintHeight??28};
 const pull={width:108,height:108};
 const rect=(x,y,size)=>({...size,x,y});
 let widgets={brand:rect(safe.x,safe.y,brand),score:rect(right-score.width,safe.y,score),tools:rect(safe.x,bottom-44,{width:96,height:44}),options:rect(safe.x+104,bottom-44,{width:44,height:44}),pull:rect(right-108,bottom-108,pull),hint:rect(safe.x,bottom-44-hint.height-16,hint)};
 if(variant==='b')widgets={...widgets,tools:rect(right-44,safe.y+brand.height+22,{width:44,height:96}),options:rect(right-44,safe.y+brand.height+126,{width:44,height:44}),pull:rect(safe.x,bottom-108,pull),score:rect(right-score.width,bottom-score.height,score),hint:rect(right-hint.width,bottom-score.height-hint.height-16,hint)};
 if(variant==='d')widgets={...widgets,tools:rect(right-44,safe.y+brand.height+22,{width:44,height:96}),options:rect(right-44,safe.y+brand.height+126,{width:44,height:44}),pull:rect(safe.x,bottom-108,pull),score:rect(right-score.width,bottom-score.height,score),hint:rect(safe.x,bottom-108-hint.height-14,hint)};
 if(variant==='e')widgets={...widgets,tools:rect(right-44,safe.y+brand.height+22,{width:44,height:96}),options:rect(right-44,safe.y+brand.height+126,{width:44,height:44}),pull:rect(right-108,bottom-108,pull),score:rect(safe.x,bottom-score.height,score),hint:rect(right-hint.width,bottom-108-hint.height-14,hint)};
 if(variant==='f')widgets={...widgets,tools:rect(right-148,bottom-44,{width:96,height:44}),options:rect(right-44,bottom-44,{width:44,height:44}),pull:rect(safe.x,bottom-108,pull),hint:rect(right-hint.width,bottom-44-hint.height-18,hint)};
 if(variant==='c')widgets={...widgets,options:rect(right-44,bottom-44,{width:44,height:44}),pull:rect(safe.x+safe.width/2-54,bottom-108,pull),hint:rect(safe.x,bottom-108-hint.height-12,hint)};
 const occupied=[];
 const exclusions=regions.filter(excludes);
 for(const [name,r] of Object.entries(widgets)){
   const blocked=c=>exclusions.some(e=>intersects(c,e))||occupied.some(e=>intersects(c,e));
   if(blocked(r)){
     const candidates=[...occupied.concat(exclusions).flatMap(e=>[rect(r.x,e.y-r.height-8,r),rect(r.x,e.y+e.height+8,r),rect(e.x-r.width-8,r.y,r),rect(e.x+e.width+8,r.y,r)]),rect(safe.x,r.y,r),rect(right-r.width,r.y,r),rect(safe.x,safe.y,r),rect(right-r.width,safe.y,r),rect(safe.x,bottom-r.height,r),rect(right-r.width,bottom-r.height,r)].map(c=>({...c,x:Math.min(right-c.width,Math.max(safe.x,c.x)),y:Math.min(bottom-c.height,Math.max(safe.y,c.y))}));
     const valid=candidates.filter(c=>!blocked(c)).sort((a,b)=>Math.hypot(a.x-r.x,a.y-r.y)-Math.hypot(b.x-r.x,b.y-r.y));
     if(valid.length)widgets[name]=valid[0];
   }
   occupied.push(widgets[name]);
 }
 return{safe,widgets,field:{x:safe.x+8,y:safe.y+Math.max(brand.height,score.height)+18,width:safe.width-16,height:Math.max(70,safe.height-Math.max(brand.height,score.height)-150)}};
}
