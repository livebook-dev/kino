import{a as ht}from"./chunk-S3CTNQ4R.js";import{a as xt}from"./chunk-GXQQNZTH.js";import"./chunk-PVIU4N4T.js";import"./chunk-UAMEX2AP.js";import"./chunk-2KAQUH4Q.js";import"./chunk-UDCUBV2D.js";import"./chunk-DL52GMNS.js";import"./chunk-EE7OJK2I.js";import"./chunk-GVCNVHXG.js";import"./chunk-7DHCMTZQ.js";import"./chunk-FSCTEUF3.js";import"./chunk-ADQNITOP.js";import"./chunk-EVHTOJRI.js";import"./chunk-OIJC3ANW.js";import"./chunk-32MLH2UR.js";import"./chunk-56YL7P5B.js";import"./chunk-YXIM635O.js";import"./chunk-463NABI6.js";import{a as ut}from"./chunk-GQYAR3CE.js";import{o as j}from"./chunk-N5E7CGZK.js";import"./chunk-T2HLX3JY.js";import{O as st,T as ct,U as lt,V as ft,W as dt,X as mt,Y as pt,Z as yt,i as J,k as it,u as X}from"./chunk-HMJDPWRP.js";import{b as E}from"./chunk-DW4GERSH.js";import{a as r}from"./chunk-YUSHYV7C.js";import{a as Z}from"./chunk-GBA75L3X.js";var $t=r(()=>({domains:new Map,transitions:[]}),"createDefaultData"),G=$t(),zt=r(()=>G.domains,"getDomains"),Lt=r(()=>G.transitions,"getTransitions"),Nt=r(t=>{var e;if(t)for(let n of t){let o=n.domain,c=((e=n.items)!=null?e:[]).map(f=>({label:f.label}));G.domains.set(o,{name:o,items:c})}},"setDomains"),Pt=r(t=>{t&&(G.transitions=t.filter(e=>e.from===e.to?(E.warn(`Cynefin: self-loop transition on domain "${e.from}" is not meaningful and will be skipped.`),!1):!0).map(e=>({from:e.from,to:e.to,label:e.label||void 0})))},"setTransitions"),It=r(()=>j(Z(Z({},it.cynefin),X().cynefin)),"getConfig"),Wt=r(()=>{ct(),G=$t()},"clear"),q={getDomains:zt,getTransitions:Lt,setDomains:Nt,setTransitions:Pt,getConfig:It,clear:Wt,setAccTitle:lt,getAccTitle:ft,setDiagramTitle:pt,getDiagramTitle:yt,getAccDescription:mt,setAccDescription:dt},Rt=r(t=>{ht(t,q),q.setDomains(t.domains),q.setTransitions(t.transitions)},"populate"),Ft={parse:r(async t=>{let e=await xt("cynefin",t);E.debug(e),Rt(e)},"parse")};function H(t){let e=t+1831565813|0;return e=Math.imul(e^e>>>15,e|1),e^=e+Math.imul(e^e>>>7,e|61),((e^e>>>14)>>>0)/4294967296}r(H,"seededRandom");function bt(t){let e=0;for(let n=0;n<t.length;n++){let o=t.charCodeAt(n);e=(e<<5)-e+o,e|=0}return e}r(bt,"hashString");function wt(t,e){return typeof t=="number"&&Number.isFinite(t)&&t!==0?t:bt(e)}r(wt,"resolveSeed");function Ct(t,e,n,o){let c=t/2,f=o!=null?o:t*.015,D=7,W=e/D,d=[];for(let a=0;a<=D;a++){let p=H(n+a*17)*f*2-f;d.push({x:c+p,y:a*W})}let v=`M${d[0].x},${d[0].y}`;for(let a=0;a<d.length-1;a++){let p=d[a],s=d[a+1],m=(p.y+s.y)/2,b=a%2===0?1:-1,h=f*1.5*b*H(n+a*31+7),R=p.x+h,F=m,V=s.x-h;v+=` C${R},${F} ${V},${m} ${s.x},${s.y}`}return v}r(Ct,"generateFoldPath");function Dt(t,e,n,o){let c=e/2,f=o!=null?o:e*.015,D=7,W=t/D,d=[];for(let a=0;a<=D;a++){let p=H(n+a*23)*f*2-f;d.push({x:a*W,y:c+p})}let v=`M${d[0].x},${d[0].y}`;for(let a=0;a<d.length-1;a++){let p=d[a],s=d[a+1],m=(p.x+s.x)/2,b=a%2===0?1:-1,h=f*1.5*b*H(n+a*37+11),R=m,F=p.y+h,V=m,z=s.y-h;v+=` C${R},${F} ${V},${z} ${s.x},${s.y}`}return v}r(Dt,"generateHorizontalBoundary");function vt(t,e){let n=t/2,o=e*.5,c=e,f=t*.03;return[`M${n},${o}`,`C${n+f},${o+(c-o)*.2}`,`${n-f*1.5},${o+(c-o)*.55}`,`${n+f*.5},${o+(c-o)*.75}`,`C${n-f},${o+(c-o)*.85}`,`${n+f*.3},${o+(c-o)*.95}`,`${n},${c}`].join(" ")}r(vt,"generateCliffPath");function kt(t,e,n,o){return[`M${t-n},${e}`,`A${n},${o} 0 1,1 ${t+n},${e}`,`A${n},${o} 0 1,1 ${t-n},${e}`,"Z"].join(" ")}r(kt,"generateConfusionPath");var gt={complex:{model:"Probe \u2192 Sense \u2192 Respond",practice:"Emergent Practices"},complicated:{model:"Sense \u2192 Analyse \u2192 Respond",practice:"Good Practices"},clear:{model:"Sense \u2192 Categorise \u2192 Respond",practice:"Best Practices"},chaotic:{model:"Act \u2192 Sense \u2192 Respond",practice:"Novel Practices"},confusion:{model:"",practice:"Disorder"}},Vt=r((t,e)=>{let n=t/2,o=e/2;return{complex:{cx:n/2,cy:o/2,x:0,y:0,w:n,h:o},complicated:{cx:n+n/2,cy:o/2,x:n,y:0,w:n,h:o},chaotic:{cx:n/2,cy:o+o/2,x:0,y:o,w:n,h:o},clear:{cx:n+n/2,cy:o+o/2,x:n,y:o,w:n,h:o},confusion:{cx:n,cy:o,x:n*.7,y:o*.7,w:n*.6,h:o*.6}}},"getDomainLayouts"),_t=r(()=>{let t=J(),e=X();return j(t,e.themeVariables).cynefin},"getCynefinDomainColors"),K=3,Et=r((t,e,n,o)=>{var ot;let c=o.db,f=c.getDomains(),D=c.getTransitions(),W=c.getDiagramTitle(),d=c.getAccTitle(),v=c.getAccDescription(),a=c.getConfig(),p=_t();E.debug("Rendering Cynefin diagram");let s=a.width,m=a.height,b=a.padding,h=a.showDomainDescriptions,R=a.boundaryAmplitude,F=s+b*2,V=m+b*2,z={complex:p.complexBg,complicated:p.complicatedBg,clear:p.clearBg,chaotic:p.chaoticBg,confusion:p.confusionBg},k=ut(e);st(k,V,F,(ot=a.useMaxWidth)!=null?ot:!0),k.attr("viewBox",`0 0 ${F} ${V}`),d&&k.append("title").text(d),v&&k.append("desc").text(v);let T=k.append("g").attr("transform",`translate(${b}, ${b})`),_=Vt(s,m),O=wt(a.seed,e),Tt=T.append("g").attr("class","cynefin-backgrounds"),U=["complex","complicated","chaotic","clear"];for(let l of U){let i=_[l];Tt.append("rect").attr("class","cynefinDomain").attr("x",i.x).attr("y",i.y).attr("width",i.w).attr("height",i.h).attr("fill",z[l]).attr("fill-opacity",.4).attr("stroke","none")}let Q=T.append("g").attr("class","cynefin-boundaries");Q.append("path").attr("class","cynefinBoundary").attr("d",Ct(s,m,O,R)).attr("fill","none"),Q.append("path").attr("class","cynefinBoundary").attr("d",Dt(s,m,O+100,R)).attr("fill","none"),Q.append("path").attr("class","cynefinCliff").attr("d",vt(s,m)).attr("fill","none");let At=s*.15,Bt=m*.15;T.append("path").attr("class","cynefinConfusion").attr("d",kt(s/2,m/2,At,Bt)).attr("fill",z.confusion).attr("fill-opacity",.5);let tt=T.append("g").attr("class","cynefin-labels");for(let l of U){let i=_[l];tt.append("text").attr("class","cynefinDomainLabel").attr("x",i.cx).attr("y",h?i.cy-30:i.cy).attr("text-anchor","middle").attr("dominant-baseline","middle").text(l.charAt(0).toUpperCase()+l.slice(1))}if(tt.append("text").attr("class","cynefinDomainLabel").attr("x",s/2).attr("y",h?m/2-10:m/2).attr("text-anchor","middle").attr("dominant-baseline","middle").text("Confusion"),h){let l=T.append("g").attr("class","cynefin-subtitles");for(let i of U){let u=_[i],y=gt[i];l.append("text").attr("class","cynefinSubtitle").attr("x",u.cx).attr("y",u.cy-10).attr("text-anchor","middle").attr("dominant-baseline","middle").text(y.model),l.append("text").attr("class","cynefinSubtitle").attr("x",u.cx).attr("y",u.cy+5).attr("text-anchor","middle").attr("dominant-baseline","middle").text(y.practice)}l.append("text").attr("class","cynefinSubtitle").attr("x",s/2).attr("y",m/2+8).attr("text-anchor","middle").attr("dominant-baseline","middle").text(gt.confusion.practice)}let et=T.append("g").attr("class","cynefin-items"),A=26,nt=10,St=["complex","complicated","chaotic","clear","confusion"];for(let l of St){let i=f.get(l);if(!i||i.items.length===0)continue;let u=_[l],y=l==="confusion",L=i.items,N=0;y&&i.items.length>K&&(N=i.items.length-K,L=i.items.slice(0,K));let B;if(y){let g=h?22:14;B=u.cy+g}else B=u.cy+(h?25:15);if([...L].forEach((g,S)=>{let w=B+S*(A+4),M=et.append("g"),P=M.append("text").attr("class","cynefinItemText").attr("x",0).attr("y",A/2).attr("text-anchor","middle").attr("dominant-baseline","central").text(g.label),$=g.label.length*7,x=P.node();if(x&&typeof x.getBBox=="function"){let Y=x.getBBox();Y.width>0&&($=Y.width)}let C=$+nt*2,I=u.cx-C/2;M.attr("transform",`translate(${I}, ${w})`),M.insert("rect","text").attr("class","cynefinItem").attr("x",0).attr("y",0).attr("width",C).attr("height",A).attr("rx",4).attr("ry",4).attr("fill",z[l]).attr("fill-opacity",.95),P.attr("x",C/2).attr("y",A/2)}),N>0){let g=B+L.length*(A+4),S=`+${N} more`,w=et.append("g"),M=w.append("text").attr("class","cynefinItemText").attr("x",0).attr("y",A/2).attr("text-anchor","middle").attr("dominant-baseline","central").text(S),P=S.length*7,$=M.node();if($&&typeof $.getBBox=="function"){let I=$.getBBox();I.width>0&&(P=I.width)}let x=P+nt*2,C=u.cx-x/2;w.attr("transform",`translate(${C}, ${g})`),w.insert("rect","text").attr("class","cynefinItemOverflow").attr("x",0).attr("y",0).attr("width",x).attr("height",A).attr("rx",4).attr("ry",4).attr("fill",z[l]).attr("fill-opacity",.6),M.attr("x",x/2).attr("y",A/2)}}if(D.length>0){let l=k.select("defs").empty()?k.append("defs"):k.select("defs"),i=`cynefin-arrow-${e}`;l.append("marker").attr("id",i).attr("viewBox","0 0 10 10").attr("refX",9).attr("refY",5).attr("markerWidth",6).attr("markerHeight",6).attr("orient","auto-start-reverse").append("path").attr("d","M 0 0 L 10 5 L 0 10 z").attr("class","cynefinArrowHead");let u=T.append("g").attr("class","cynefin-arrows");D.forEach(y=>{let L=_[y.from],N=_[y.to];if(!L||!N)return;if(y.from===y.to){E.warn(`Cynefin renderer: skipping self-loop on domain "${y.from}"`);return}let B=L.cx,g=L.cy,S=N.cx,w=N.cy,M=(B+S)/2,P=(g+w)/2,$=S-B,x=w-g,C=Math.sqrt($*$+x*x),I=C*.15,Y=-x/C,Mt=$/C,at=M+Y*I,rt=P+Mt*I;u.append("path").attr("class","cynefinArrowLine").attr("d",`M${B},${g} Q${at},${rt} ${S},${w}`).attr("fill","none").attr("marker-end",`url(#${i})`),y.label&&u.append("text").attr("class","cynefinArrowLabel").attr("x",at).attr("y",rt-6).attr("text-anchor","middle").attr("dominant-baseline","auto").text(y.label)})}W&&T.append("text").attr("class","cynefinTitle").attr("x",s/2).attr("y",-b/2).attr("text-anchor","middle").attr("dominant-baseline","middle").text(W)},"draw"),Ht={draw:Et},Gt=r(()=>{let t=J(),e=X();return j(t,e.themeVariables).cynefin},"getCynefinTheme"),Yt=r(()=>{let t=Gt();return`
	.cynefinDomain {
		stroke: none;
	}
	.cynefinDomainLabel {
		font-size: ${t.domainFontSize}px;
		font-weight: bold;
		fill: ${t.labelColor};
	}
	.cynefinSubtitle {
		font-size: ${t.itemFontSize-1}px;
		fill: ${t.textColor};
		font-style: italic;
	}
	.cynefinItem {
		fill-opacity: 0.95;
		stroke: ${t.boundaryColor};
		stroke-width: 1;
	}
	.cynefinItemText {
		font-size: ${t.itemFontSize}px;
		fill: ${t.textColor};
	}
	.cynefinItemOverflow {
		fill-opacity: 0.6;
		stroke: ${t.boundaryColor};
		stroke-width: 1;
		stroke-dasharray: 3 2;
	}
	.cynefinBoundary {
		stroke: ${t.boundaryColor};
		stroke-width: ${t.boundaryWidth};
		stroke-dasharray: 6 3;
	}
	.cynefinCliff {
		stroke: ${t.cliffColor};
		stroke-width: ${t.cliffWidth};
	}
	.cynefinConfusion {
		stroke: ${t.boundaryColor};
		stroke-width: 1.5;
		stroke-dasharray: 4 2;
	}
	.cynefinArrowLine {
		stroke: ${t.arrowColor};
		stroke-width: ${t.arrowWidth};
		fill: none;
	}
	.cynefinArrowHead {
		fill: ${t.arrowColor};
		stroke: none;
	}
	.cynefinArrowLabel {
		font-size: ${t.itemFontSize-1}px;
		fill: ${t.textColor};
	}
	.cynefinTitle {
		font-size: ${t.domainFontSize+2}px;
		font-weight: bold;
		fill: ${t.labelColor};
	}
	`},"styles"),Xt=Yt,Ot={parser:Ft,db:q,renderer:Ht,styles:Xt};export{Ot as diagram};
