import{a as lt}from"./chunk-S3CTNQ4R.js";import{a as st}from"./chunk-GXQQNZTH.js";import"./chunk-PVIU4N4T.js";import"./chunk-UAMEX2AP.js";import"./chunk-2KAQUH4Q.js";import"./chunk-UDCUBV2D.js";import"./chunk-DL52GMNS.js";import"./chunk-EE7OJK2I.js";import"./chunk-GVCNVHXG.js";import"./chunk-7DHCMTZQ.js";import"./chunk-FSCTEUF3.js";import"./chunk-ADQNITOP.js";import"./chunk-EVHTOJRI.js";import"./chunk-OIJC3ANW.js";import"./chunk-32MLH2UR.js";import"./chunk-56YL7P5B.js";import"./chunk-YXIM635O.js";import"./chunk-463NABI6.js";import{a as it}from"./chunk-GQYAR3CE.js";import{n as nt,o as ot}from"./chunk-N5E7CGZK.js";import"./chunk-T2HLX3JY.js";import{O as Z,T as j,U as q,V as J,W as K,X as Q,Y,Z as tt,_ as et,k as X}from"./chunk-HMJDPWRP.js";import{F as L,I as rt,b,m as at}from"./chunk-DW4GERSH.js";import{a as l}from"./chunk-YUSHYV7C.js";import"./chunk-GBA75L3X.js";var ct=X.pie,O={sections:new Map,showData:!1,config:ct},A=O.sections,F=O.showData,wt=structuredClone(ct),Ct=l(()=>structuredClone(wt),"getConfig"),$t=l(()=>{A=new Map,F=O.showData,j()},"clear"),Dt=l(({label:t,value:r})=>{if(r<0)throw new Error(`"${t}" has invalid value: ${r}. Negative values are not allowed in pie charts. All slice values must be >= 0.`);A.has(t)||(A.set(t,r),b.debug(`added new section: ${t}, with value: ${r}`))},"addSection"),yt=l(()=>A,"getSections"),Tt=l(t=>{F=t},"setShowData"),bt=l(()=>F,"getShowData"),dt={getConfig:Ct,clear:$t,setDiagramTitle:Y,getDiagramTitle:tt,setAccTitle:q,getAccTitle:J,setAccDescription:K,getAccDescription:Q,addSection:Dt,getSections:yt,setShowData:Tt,getShowData:bt},At=l((t,r)=>{lt(t,r),r.setShowData(t.showData),t.sections.map(r.addSection)},"populateDb"),_t={parse:l(async t=>{let r=await st("pie",t);b.debug(r),At(r,dt)},"parse")},kt=l(t=>`
  .pieCircle{
    stroke: ${t.pieStrokeColor};
    stroke-width : ${t.pieStrokeWidth};
    opacity : ${t.pieOpacity};
  }
  .pieCircle.highlighted{
    scale: 1.05;
    opacity: 1;
  }
  .pieCircle.highlightedOnHover:hover{
    transition-duration: 250ms;
    scale: 1.05;
    opacity: 1;
  }
  .pieOuterCircle{
    stroke: ${t.pieOuterStrokeColor};
    stroke-width: ${t.pieOuterStrokeWidth};
    fill: none;
  }
  .pieTitleText {
    text-anchor: middle;
    font-size: ${t.pieTitleTextSize};
    fill: ${t.pieTitleTextColor};
    font-family: ${t.fontFamily};
  }
  .slice {
    font-family: ${t.fontFamily};
    fill: ${t.pieSectionTextColor};
    font-size:${t.pieSectionTextSize};
    // fill: white;
  }
  .legend text {
    fill: ${t.pieLegendTextColor};
    font-family: ${t.fontFamily};
    font-size: ${t.pieLegendTextSize};
  }
`,"getStyles"),zt=kt,Et=l(t=>{let r=[...t.values()].reduce((o,m)=>o+m,0),H=[...t.entries()].map(([o,m])=>({label:o,value:m})).filter(o=>o.value/r*100>=1);return rt().value(o=>o.value).sort(null)(H)},"createPieArcs"),Rt=l((t,r,H,M)=>{var U,V;b.debug(`rendering pie chart
`+t);let o=M.db,m=et(),h=ot(o.getConfig(),m.pie),P=40,i=18,c=4,x=450,S=x,_=it(r),$=_.append("g");$.attr("transform","translate("+S/2+","+x/2+")");let{themeVariables:n}=m,[D]=nt(n.pieOuterStrokeWidth);D!=null||(D=2);let gt=h.legendPosition,G=h.textPosition,pt=h.donutHole>0&&h.donutHole<=.9?h.donutHole:0,f=Math.min(S,x)/2-P,ht=L().innerRadius(pt*f).outerRadius(f),ft=L().innerRadius(f*G).outerRadius(f*G),w=$.append("g");w.append("circle").attr("cx",0).attr("cy",0).attr("r",f+D/2).attr("class","pieOuterCircle");let y=o.getSections(),ut=Et(y),mt=[n.pie1,n.pie2,n.pie3,n.pie4,n.pie5,n.pie6,n.pie7,n.pie8,n.pie9,n.pie10,n.pie11,n.pie12],k=0;y.forEach(e=>{k+=e});let W=ut.filter(e=>(e.data.value/k*100).toFixed(0)!=="0"),z=at(mt).domain([...y.keys()]);w.selectAll("mySlices").data(W).enter().append("path").attr("d",ht).attr("fill",e=>z(e.data.label)).attr("class",e=>{let a="pieCircle";return h.highlightSlice==="hover"?a+=" highlightedOnHover":h.highlightSlice===e.data.label&&(a+=" highlighted"),a}),w.selectAll("mySlices").data(W).enter().append("text").text(e=>(e.data.value/k*100).toFixed(0)+"%").attr("transform",e=>"translate("+ft.centroid(e)+")").style("text-anchor","middle").attr("class","slice");let vt=$.append("text").text(o.getDiagramTitle()).attr("x",0).attr("y",-(x-50)/2).attr("class","pieTitleText"),C=[...y.entries()].map(([e,a])=>({label:e,value:a})),u=$.selectAll(".legend").data(C).enter().append("g").attr("class","legend");u.append("rect").attr("width",i).attr("height",i).style("fill",e=>z(e.label)).style("stroke",e=>z(e.label)),u.append("text").attr("x",i+c).attr("y",i-c).text(e=>o.getShowData()?`${e.label} [${e.value}]`:e.label);let v=Math.max(...u.selectAll("text").nodes().map(e=>{var a;return(a=e==null?void 0:e.getBoundingClientRect().width)!=null?a:0})),T=x,E=S+P,s=i+c,R=C.length*s;switch(gt){case"center":u.attr("transform",(e,a)=>{let d=s*C.length/2,g=-v/2-(i+c),p=a*s-d;return"translate("+g+","+p+")"});break;case"top":T+=R,u.attr("transform",(e,a)=>{let d=f,g=-v/2-(i+c),p=a*s-d;return`translate(${g}, ${p})`}),w.attr("transform",()=>`translate(0, ${R+s})`);break;case"bottom":T+=R,u.attr("transform",(e,a)=>{let d=-f-s,g=-v/2-(i+c),p=a*s-d;return"translate("+g+","+p+")"});break;case"left":E+=i+c+v,u.attr("transform",(e,a)=>{let d=s*C.length/2,g=-f-(i+c),p=a*s-d;return"translate("+g+","+p+")"}),w.attr("transform",()=>`translate(${v+i+c}, 0)`);break;case"right":default:E+=i+c+v,u.attr("transform",(e,a)=>{let d=s*C.length/2,g=12*i,p=a*s-d;return"translate("+g+","+p+")"});break}let B=(V=(U=vt.node())==null?void 0:U.getBoundingClientRect().width)!=null?V:0,xt=S/2-B/2,St=S/2+B/2,N=Math.min(0,xt),I=Math.max(E,St)-N;_.attr("viewBox",`${N} 0 ${I} ${T}`),Z(_,T,I,h.useMaxWidth)},"draw"),Lt={draw:Rt},It={parser:_t,db:dt,renderer:Lt,styles:zt};export{It as diagram};
