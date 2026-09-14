import{a as P}from"./chunk-S3CTNQ4R.js";import{a as z}from"./chunk-GXQQNZTH.js";import"./chunk-PVIU4N4T.js";import"./chunk-UAMEX2AP.js";import"./chunk-2KAQUH4Q.js";import"./chunk-UDCUBV2D.js";import"./chunk-DL52GMNS.js";import"./chunk-EE7OJK2I.js";import"./chunk-GVCNVHXG.js";import"./chunk-7DHCMTZQ.js";import"./chunk-FSCTEUF3.js";import"./chunk-ADQNITOP.js";import"./chunk-EVHTOJRI.js";import"./chunk-OIJC3ANW.js";import"./chunk-32MLH2UR.js";import"./chunk-56YL7P5B.js";import"./chunk-YXIM635O.js";import"./chunk-463NABI6.js";import{a as D}from"./chunk-GQYAR3CE.js";import{o as y}from"./chunk-N5E7CGZK.js";import"./chunk-T2HLX3JY.js";import{O as S,T as k,U as O,V as R,W as I,X as _,Y as E,Z as F,i as L,k as T,u as M}from"./chunk-HMJDPWRP.js";import{b as A}from"./chunk-DW4GERSH.js";import{a as c}from"./chunk-YUSHYV7C.js";import{a as b}from"./chunk-GBA75L3X.js";var h={showLegend:!0,ticks:5,max:null,min:0,graticule:"circle"},w=32,G={axes:[],curves:[],options:h},g=structuredClone(G),X=T.radar,K=c(()=>y(b(b({},X),M().radar)),"getConfig"),B=c(()=>g.axes,"getAxes"),N=c(()=>g.curves,"getCurves"),Y=c(()=>g.options,"getOptions"),Z=c(a=>{g.axes=a.map(t=>{var e;return{name:t.name,label:(e=t.label)!=null?e:t.name}})},"setAxes"),q=c(a=>{g.curves=a.map(t=>{var e;return{name:t.name,label:(e=t.label)!=null?e:t.name,entries:J(t.entries)}})},"setCurves"),J=c(a=>{if(a[0].axis==null)return a.map(e=>e.value);let t=B();if(t.length===0)throw new Error("Axes must be populated before curves for reference entries");return t.map(e=>{let r=a.find(n=>{var s;return((s=n.axis)==null?void 0:s.$refText)===e.name});if(r===void 0)throw new Error("Missing entry for axis "+e.label);return r.value})},"computeCurveEntries"),Q=c(a=>{var e,r,n,s,l,o,i,d,p,u;let t=a.reduce((m,x)=>(m[x.name]=x,m),{});g.options={showLegend:(r=(e=t.showLegend)==null?void 0:e.value)!=null?r:h.showLegend,ticks:(s=(n=t.ticks)==null?void 0:n.value)!=null?s:h.ticks,max:(o=(l=t.max)==null?void 0:l.value)!=null?o:h.max,min:(d=(i=t.min)==null?void 0:i.value)!=null?d:h.min,graticule:(u=(p=t.graticule)==null?void 0:p.value)!=null?u:h.graticule},g.options.ticks>w&&(A.warn(`Radar diagram ticks (${g.options.ticks}) exceeds maximum allowed (${w}). Using ${w} instead.`),g.options.ticks=w)},"setOptions"),tt=c(()=>{k(),g=structuredClone(G)},"clear"),f={getAxes:B,getCurves:N,getOptions:Y,setAxes:Z,setCurves:q,setOptions:Q,getConfig:K,clear:tt,setAccTitle:O,getAccTitle:R,setDiagramTitle:E,getDiagramTitle:F,getAccDescription:_,setAccDescription:I},et=c(a=>{P(a,f);let{axes:t,curves:e,options:r}=a;f.setAxes(t),f.setCurves(e),f.setOptions(r)},"populate"),at={parse:c(async a=>{let t=await z("radar",a);A.debug(t),et(t)},"parse")},rt=c((a,t,e,r)=>{var $;let n=r.db,s=n.getAxes(),l=n.getCurves(),o=n.getOptions(),i=n.getConfig(),d=n.getDiagramTitle(),p=D(t),u=nt(p,i),m=($=o.max)!=null?$:Math.max(...l.map(C=>Math.max(...C.entries))),x=o.min,v=Math.min(i.width,i.height)/2;st(u,s,v,o.ticks,o.graticule),ot(u,s,v,i),W(u,s,l,x,m,o.graticule,i),j(u,l,o.showLegend,i),u.append("text").attr("class","radarTitle").text(d).attr("x",0).attr("y",-i.height/2-i.marginTop)},"draw"),nt=c((a,t)=>{var s;let e=t.width+t.marginLeft+t.marginRight,r=t.height+t.marginTop+t.marginBottom,n={x:t.marginLeft+t.width/2,y:t.marginTop+t.height/2};return S(a,r,e,(s=t.useMaxWidth)!=null?s:!0),a.attr("viewBox",`0 0 ${e} ${r}`).attr("overflow","visible"),a.append("g").attr("transform",`translate(${n.x}, ${n.y})`)},"drawFrame"),st=c((a,t,e,r,n)=>{if(n==="circle")for(let s=0;s<r;s++){let l=e*(s+1)/r;a.append("circle").attr("r",l).attr("class","radarGraticule")}else if(n==="polygon"){let s=t.length;for(let l=0;l<r;l++){let o=e*(l+1)/r,i=t.map((d,p)=>{let u=2*p*Math.PI/s-Math.PI/2,m=o*Math.cos(u),x=o*Math.sin(u);return`${m},${x}`}).join(" ");a.append("polygon").attr("points",i).attr("class","radarGraticule")}}},"drawGraticule"),ot=c((a,t,e,r)=>{let n=t.length;for(let s=0;s<n;s++){let l=t[s].label,o=2*s*Math.PI/n-Math.PI/2,i=Math.cos(o),d=Math.sin(o);a.append("line").attr("x1",0).attr("y1",0).attr("x2",e*r.axisScaleFactor*i).attr("y2",e*r.axisScaleFactor*d).attr("class","radarAxisLine");let p=i>.01?"start":i<-.01?"end":"middle",u=d>.01?"hanging":d<-.01?"auto":"central",m=4;a.append("text").text(l).attr("x",e*r.axisLabelFactor*i+m*i).attr("y",e*r.axisLabelFactor*d+m*d).attr("text-anchor",p).attr("dominant-baseline",u).attr("class","radarAxisLabel")}},"drawAxes");function W(a,t,e,r,n,s,l){let o=t.length,i=Math.min(l.width,l.height)/2;e.forEach((d,p)=>{if(d.entries.length!==o)return;let u=d.entries.map((m,x)=>{let v=2*Math.PI*x/o-Math.PI/2,$=V(m,r,n,i),C=$*Math.cos(v),U=$*Math.sin(v);return{x:C,y:U}});s==="circle"?a.append("path").attr("d",H(u,l.curveTension)).attr("class",`radarCurve-${p}`):s==="polygon"&&a.append("polygon").attr("points",u.map(m=>`${m.x},${m.y}`).join(" ")).attr("class",`radarCurve-${p}`)})}c(W,"drawCurves");function V(a,t,e,r){let n=Math.min(Math.max(a,t),e);return r*(n-t)/(e-t)}c(V,"relativeRadius");function H(a,t){let e=a.length,r=`M${a[0].x},${a[0].y}`;for(let n=0;n<e;n++){let s=a[(n-1+e)%e],l=a[n],o=a[(n+1)%e],i=a[(n+2)%e],d={x:l.x+(o.x-s.x)*t,y:l.y+(o.y-s.y)*t},p={x:o.x-(i.x-l.x)*t,y:o.y-(i.y-l.y)*t};r+=` C${d.x},${d.y} ${p.x},${p.y} ${o.x},${o.y}`}return`${r} Z`}c(H,"closedRoundCurve");function j(a,t,e,r){if(!e)return;let n=(r.width/2+r.marginRight)*3/4,s=-(r.height/2+r.marginTop)*3/4,l=20;t.forEach((o,i)=>{let d=a.append("g").attr("transform",`translate(${n}, ${s+i*l})`);d.append("rect").attr("width",12).attr("height",12).attr("class",`radarLegendBox-${i}`),d.append("text").attr("x",16).attr("y",0).attr("class","radarLegendText").text(o.label)})}c(j,"drawLegend");var it={draw:rt},lt=c((a,t)=>{let e="";for(let r=0;r<a.THEME_COLOR_LIMIT;r++){let n=a[`cScale${r}`];e+=`
		.radarCurve-${r} {
			color: ${n};
			fill: ${n};
			fill-opacity: ${t.curveOpacity};
			stroke: ${n};
			stroke-width: ${t.curveStrokeWidth};
		}
		.radarLegendBox-${r} {
			fill: ${n};
			fill-opacity: ${t.curveOpacity};
			stroke: ${n};
		}
		`}return e},"genIndexStyles"),ct=c(a=>{let t=L(),e=M(),r=y(t,e.themeVariables),n=y(r.radar,a);return{themeVariables:r,radarOptions:n}},"buildRadarStyleOptions"),dt=c(({radar:a}={})=>{let{themeVariables:t,radarOptions:e}=ct(a);return`
	.radarTitle {
		font-size: ${t.fontSize};
		color: ${t.titleColor};
		dominant-baseline: hanging;
		text-anchor: middle;
	}
	.radarAxisLine {
		stroke: ${e.axisColor};
		stroke-width: ${e.axisStrokeWidth};
	}
	.radarAxisLabel {
		font-size: ${e.axisLabelFontSize}px;
		color: ${e.axisColor};
	}
	.radarGraticule {
		fill: ${e.graticuleColor};
		fill-opacity: ${e.graticuleOpacity};
		stroke: ${e.graticuleColor};
		stroke-width: ${e.graticuleStrokeWidth};
	}
	.radarLegendText {
		text-anchor: start;
		font-size: ${e.legendFontSize}px;
		dominant-baseline: hanging;
	}
	${lt(t,e)}
	`},"styles"),$t={parser:at,db:f,renderer:it,styles:dt};export{$t as diagram};
