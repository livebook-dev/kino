import{i as F}from"./chunk-OGQKJBJE.js";import{a as P}from"./chunk-HJQMRRAT.js";import{a as V}from"./chunk-PZIJPMM7.js";import{I as $,Ja as f,Ma as q,N as z,O as G,Oa as N,Ta as E,Ua as L,ab as M,db as _,gb as R,n as T,o as I}from"./chunk-AR5UQGPT.js";var U={},X=function(t){let s=Object.keys(t);for(let k of s)U[k]=t[k]},H=function(t,s,k,i,n,b){let w=i.select(`[id="${k}"]`);Object.keys(t).forEach(function(c){let l=t[c],y="default";l.classes.length>0&&(y=l.classes.join(" ")),y=y+" flowchart-label";let u=L(l.styles),e=l.text!==void 0?l.text:l.id,o;if(f.info("vertex",l,l.labelType),l.labelType==="markdown")f.info("vertex",l,l.labelType);else if(q(_().flowchart.htmlLabels)){let m={label:e.replace(/fa[blrs]?:fa-[\w-]+/g,g=>`<i class='${g.replace(":"," ")}'></i>`)};o=F(w,m).node(),o.parentNode.removeChild(o)}else{let m=n.createElementNS("http://www.w3.org/2000/svg","text");m.setAttribute("style",u.labelStyle.replace("color:","fill:"));let g=e.split(N.lineBreakRegex);for(let C of g){let v=n.createElementNS("http://www.w3.org/2000/svg","tspan");v.setAttributeNS("http://www.w3.org/XML/1998/namespace","xml:space","preserve"),v.setAttribute("dy","1em"),v.setAttribute("x","1"),v.textContent=C,m.appendChild(v)}o=m}let d=0,r="";switch(l.type){case"round":d=5,r="rect";break;case"square":r="rect";break;case"diamond":r="question";break;case"hexagon":r="hexagon";break;case"odd":r="rect_left_inv_arrow";break;case"lean_right":r="lean_right";break;case"lean_left":r="lean_left";break;case"trapezoid":r="trapezoid";break;case"inv_trapezoid":r="inv_trapezoid";break;case"odd_right":r="rect_left_inv_arrow";break;case"circle":r="circle";break;case"ellipse":r="ellipse";break;case"stadium":r="stadium";break;case"subroutine":r="subroutine";break;case"cylinder":r="cylinder";break;case"group":r="rect";break;case"doublecircle":r="doublecircle";break;default:r="rect"}s.setNode(l.id,{labelStyle:u.labelStyle,shape:r,labelText:e,labelType:l.labelType,rx:d,ry:d,class:y,style:u.style,id:l.id,link:l.link,linkTarget:l.linkTarget,tooltip:b.db.getTooltip(l.id)||"",domId:b.db.lookUpDomId(l.id),haveCallback:l.haveCallback,width:l.type==="group"?500:void 0,dir:l.dir,type:l.type,props:l.props,padding:_().flowchart.padding}),f.info("setNode",{labelStyle:u.labelStyle,labelType:l.labelType,shape:r,labelText:e,rx:d,ry:d,class:y,style:u.style,id:l.id,domId:b.db.lookUpDomId(l.id),width:l.type==="group"?500:void 0,type:l.type,dir:l.dir,props:l.props,padding:_().flowchart.padding})})},W=function(t,s,k){f.info("abc78 edges = ",t);let i=0,n={},b,w;if(t.defaultStyle!==void 0){let a=L(t.defaultStyle);b=a.style,w=a.labelStyle}t.forEach(function(a){i++;let c="L-"+a.start+"-"+a.end;n[c]===void 0?(n[c]=0,f.info("abc78 new entry",c,n[c])):(n[c]++,f.info("abc78 new entry",c,n[c]));let l=c+"-"+n[c];f.info("abc78 new link id to be used is",c,l,n[c]);let y="LS-"+a.start,u="LE-"+a.end,e={style:"",labelStyle:""};switch(e.minlen=a.length||1,a.type==="arrow_open"?e.arrowhead="none":e.arrowhead="normal",e.arrowTypeStart="arrow_open",e.arrowTypeEnd="arrow_open",a.type){case"double_arrow_cross":e.arrowTypeStart="arrow_cross";case"arrow_cross":e.arrowTypeEnd="arrow_cross";break;case"double_arrow_point":e.arrowTypeStart="arrow_point";case"arrow_point":e.arrowTypeEnd="arrow_point";break;case"double_arrow_circle":e.arrowTypeStart="arrow_circle";case"arrow_circle":e.arrowTypeEnd="arrow_circle";break}let o="",d="";switch(a.stroke){case"normal":o="fill:none;",b!==void 0&&(o=b),w!==void 0&&(d=w),e.thickness="normal",e.pattern="solid";break;case"dotted":e.thickness="normal",e.pattern="dotted",e.style="fill:none;stroke-width:2px;stroke-dasharray:3;";break;case"thick":e.thickness="thick",e.pattern="solid",e.style="stroke-width: 3.5px;fill:none;";break;case"invisible":e.thickness="invisible",e.pattern="solid",e.style="stroke-width: 0;fill:none;";break}if(a.style!==void 0){let r=L(a.style);o=r.style,d=r.labelStyle}e.style=e.style+=o,e.labelStyle=e.labelStyle+=d,a.interpolate!==void 0?e.curve=E(a.interpolate,$):t.defaultInterpolate!==void 0?e.curve=E(t.defaultInterpolate,$):e.curve=E(U.curve,$),a.text===void 0?a.style!==void 0&&(e.arrowheadStyle="fill: #333"):(e.arrowheadStyle="fill: #333",e.labelpos="c"),e.labelType=a.labelType,e.label=a.text.replace(N.lineBreakRegex,`
`),a.style===void 0&&(e.style=e.style||"stroke: #333; stroke-width: 1.5px;fill:none;"),e.labelStyle=e.labelStyle.replace("color:","fill:"),e.id=l,e.classes="flowchart-link "+y+" "+u,s.setEdge(a.start,a.end,e,i)})},J=function(t,s){return s.db.getClasses()},K=async function(t,s,k,i){f.info("Drawing flowchart");let n=i.db.getDirection();n===void 0&&(n="TD");let{securityLevel:b,flowchart:w}=_(),a=w.nodeSpacing||50,c=w.rankSpacing||50,l;b==="sandbox"&&(l=T("#i"+s));let y=b==="sandbox"?T(l.nodes()[0].contentDocument.body):T("body"),u=b==="sandbox"?l.nodes()[0].contentDocument:document,e=new V({multigraph:!0,compound:!0}).setGraph({rankdir:n,nodesep:a,ranksep:c,marginx:0,marginy:0}).setDefaultEdgeLabel(function(){return{}}),o,d=i.db.getSubGraphs();f.info("Subgraphs - ",d);for(let p=d.length-1;p>=0;p--)o=d[p],f.info("Subgraph - ",o),i.db.addVertex(o.id,{text:o.title,type:o.labelType},"group",void 0,o.classes,o.dir);let r=i.db.getVertices(),m=i.db.getEdges();f.info("Edges",m);let g=0;for(g=d.length-1;g>=0;g--){o=d[g],I("cluster").append("text");for(let p=0;p<o.nodes.length;p++)f.info("Setting up subgraphs",o.nodes[p],o.id),e.setParent(o.nodes[p],o.id)}H(r,e,s,y,u,i),W(m,e);let C=y.select(`[id="${s}"]`),v=y.select("#"+s+" g");if(await P(v,e,["point","circle","cross"],"flowchart",s),M.insertTitle(C,"flowchartTitleText",w.titleTopMargin,i.db.getDiagramTitle()),R(e,C,w.diagramPadding,w.useMaxWidth),i.db.indexNodes("subGraph"+g),!w.htmlLabels){let p=u.querySelectorAll('[id="'+s+'"] .edgeLabel .label');for(let x of p){let S=x.getBBox(),h=u.createElementNS("http://www.w3.org/2000/svg","rect");h.setAttribute("rx",0),h.setAttribute("ry",0),h.setAttribute("width",S.width),h.setAttribute("height",S.height),x.insertBefore(h,x.firstChild)}}Object.keys(r).forEach(function(p){let x=r[p];if(x.link){let S=T("#"+s+' [id="'+p+'"]');if(S){let h=u.createElementNS("http://www.w3.org/2000/svg","a");h.setAttributeNS("http://www.w3.org/2000/svg","class",x.classes.join(" ")),h.setAttributeNS("http://www.w3.org/2000/svg","href",x.link),h.setAttributeNS("http://www.w3.org/2000/svg","rel","noopener"),b==="sandbox"?h.setAttributeNS("http://www.w3.org/2000/svg","target","_top"):x.linkTarget&&h.setAttributeNS("http://www.w3.org/2000/svg","target",x.linkTarget);let A=S.insert(function(){return h},":first-child"),B=S.select(".label-container");B&&A.append(function(){return B.node()});let D=S.select(".label");D&&A.append(function(){return D.node()})}}})},ae={setConf:X,addVertices:H,addEdges:W,getClasses:J,draw:K},Q=(t,s)=>{let k=G,i=k(t,"r"),n=k(t,"g"),b=k(t,"b");return z(i,n,b,s)},Y=t=>`.label {
    font-family: ${t.fontFamily};
    color: ${t.nodeTextColor||t.textColor};
  }
  .cluster-label text {
    fill: ${t.titleColor};
  }
  .cluster-label span,p {
    color: ${t.titleColor};
  }

  .label text,span,p {
    fill: ${t.nodeTextColor||t.textColor};
    color: ${t.nodeTextColor||t.textColor};
  }

  .node rect,
  .node circle,
  .node ellipse,
  .node polygon,
  .node path {
    fill: ${t.mainBkg};
    stroke: ${t.nodeBorder};
    stroke-width: 1px;
  }
  .flowchart-label text {
    text-anchor: middle;
  }
  // .flowchart-label .text-outer-tspan {
  //   text-anchor: middle;
  // }
  // .flowchart-label .text-inner-tspan {
  //   text-anchor: start;
  // }

  .node .label {
    text-align: center;
  }
  .node.clickable {
    cursor: pointer;
  }

  .arrowheadPath {
    fill: ${t.arrowheadColor};
  }

  .edgePath .path {
    stroke: ${t.lineColor};
    stroke-width: 2.0px;
  }

  .flowchart-link {
    stroke: ${t.lineColor};
    fill: none;
  }

  .edgeLabel {
    background-color: ${t.edgeLabelBackground};
    rect {
      opacity: 0.5;
      background-color: ${t.edgeLabelBackground};
      fill: ${t.edgeLabelBackground};
    }
    text-align: center;
  }

  /* For html labels only */
  .labelBkg {
    background-color: ${Q(t.edgeLabelBackground,.5)};
    // background-color: 
  }

  .cluster rect {
    fill: ${t.clusterBkg};
    stroke: ${t.clusterBorder};
    stroke-width: 1px;
  }

  .cluster text {
    fill: ${t.titleColor};
  }

  .cluster span,p {
    color: ${t.titleColor};
  }
  /* .cluster div {
    color: ${t.titleColor};
  } */

  div.mermaidTooltip {
    position: absolute;
    text-align: center;
    max-width: 200px;
    padding: 2px;
    font-family: ${t.fontFamily};
    font-size: 12px;
    background: ${t.tertiaryColor};
    border: 1px solid ${t.border2};
    border-radius: 2px;
    pointer-events: none;
    z-index: 100;
  }

  .flowchartTitleText {
    text-anchor: middle;
    font-size: 18px;
    fill: ${t.textColor};
  }
`,oe=Y;export{ae as a,oe as b};
