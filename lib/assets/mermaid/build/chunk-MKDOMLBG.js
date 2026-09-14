import{a as G}from"./chunk-GQYAR3CE.js";import{H as I,O as X,T as H,_ as q,i as L,u as O}from"./chunk-HMJDPWRP.js";import{b as k}from"./chunk-DW4GERSH.js";import{a as g}from"./chunk-YUSHYV7C.js";import{a as x,b as C,c as P}from"./chunk-GBA75L3X.js";var D="",E="",W="",_=[],A=new Map,F=g(e=>I(e,q()),"sanitizeText"),$=g(e=>{switch(e.type){case"terminal":return C(x({},e),{value:F(e.value)});case"nonterminal":return C(x({},e),{name:F(e.name)});case"sequence":return C(x({},e),{elements:e.elements.map($)});case"choice":return C(x({},e),{alternatives:e.alternatives.map($)});case"optional":return C(x({},e),{element:$(e.element)});case"repetition":return C(x({},e),{element:$(e.element),separator:e.separator?$(e.separator):void 0});case"special":return C(x({},e),{text:F(e.text)})}},"sanitizeAstNode"),V=g(()=>{D="",E="",W="",_.length=0,A.clear(),H(),k.debug("[Railroad] Database cleared")},"clear"),j=g(e=>{D=F(e),k.debug("[Railroad] Title set:",e)},"setTitle"),K=g(()=>D,"getTitle"),ee=g(e=>{let i=C(x({},e),{name:F(e.name),definition:$(e.definition),comment:e.comment?F(e.comment):void 0});k.debug("[Railroad] Adding rule:",i.name),A.has(i.name)&&k.warn(`[Railroad] Rule '${i.name}' is already defined. Overwriting.`),_.push(i),A.set(i.name,i)},"addRule"),te=g(()=>_,"getRules"),re=g(e=>A.get(e),"getRule"),ie=g(e=>{E=F(e).replace(/^\s+/g,""),k.debug("[Railroad] Accessibility title set:",e)},"setAccTitle"),ne=g(()=>E,"getAccTitle"),ae=g(e=>{W=F(e).replace(/\n\s+/g,`
`),k.debug("[Railroad] Accessibility description set:",e)},"setAccDescription"),oe=g(()=>W,"getAccDescription"),le=j,se=K,de={clear:V,setTitle:j,getTitle:K,addRule:ee,getRules:te,getRule:re,setAccTitle:ie,getAccTitle:ne,setAccDescription:ae,getAccDescription:oe,setDiagramTitle:le,getDiagramTitle:se},T={compactMode:!1,padding:10,verticalSeparation:8,horizontalSeparation:10,arcRadius:10,fontSize:14,fontFamily:"monospace",terminalFill:"#FFFFC0",terminalStroke:"#000000",terminalTextColor:"#000000",nonTerminalFill:"#FFFFFF",nonTerminalStroke:"#000000",nonTerminalTextColor:"#000000",lineColor:"#000000",strokeWidth:2,markerFill:"#000000",commentFill:"#E8E8E8",commentStroke:"#888888",commentTextColor:"#666666",specialFill:"#F0E0FF",specialStroke:"#8800CC",ruleNameColor:"#000066",showMarkers:!0,markerRadius:5},ce=/^#(?:[\da-f]{3,4}|[\da-f]{6}|[\da-f]{8})$|^(?:rgb|rgba|hsl|hsla|hwb|lab|lch|oklab|oklch)\([\d\s%+,./-]+\)$|^[a-z]+$/i,me=/^[\w "',.-]+$/,he=new Set(["compactMode","padding","verticalSeparation","horizontalSeparation","arcRadius","fontSize","fontFamily","terminalFill","terminalStroke","terminalTextColor","nonTerminalFill","nonTerminalStroke","nonTerminalTextColor","lineColor","strokeWidth","markerFill","commentFill","commentStroke","commentTextColor","specialFill","specialStroke","ruleNameColor","showMarkers","markerRadius"]),J=g(e=>e?Object.keys(e).every(i=>i==="railroad"||he.has(i)):!1,"isRailroadStyleOptions"),pe=g(e=>e?"railroad"in e&&e.railroad?e.railroad:J(e)?e:{}:{},"extractRailroadOverrides"),ue=g(e=>{if(!e||J(e))return{};let a=e,{railroad:i,svgId:o,theme:n,look:t}=a;return P(a,["railroad","svgId","theme","look"])},"extractThemeOverrides"),p=g((e,i)=>{if(typeof e!="string")return i;let o=e.trim();return ce.test(o)?o:i},"sanitizeColorValue"),Q=g((e,i)=>{if(typeof e!="string")return i;let o=e.trim();return me.test(o)?o:i},"sanitizeFontFamilyValue"),R=g((e,i)=>{let o=typeof e=="number"?e:typeof e=="string"?Number.parseFloat(e):Number.NaN;return Number.isFinite(o)&&o>=0?o:i},"sanitizeNumberValue"),ge=g(e=>{let i=typeof e=="number"?e:typeof e=="string"?Number.parseFloat(e):Number.NaN;return Number.isFinite(i)&&i>0?i:void 0},"parseThemeFontSize"),fe=g(e=>{var n,t,r,a,c,l,s,h,u,m,w,d,f;let i=Q(e.fontFamily,T.fontFamily),o=(n=ge(e.fontSize))!=null?n:T.fontSize;return C(x({},T),{fontFamily:i,fontSize:o,terminalFill:p((t=e.secondBkg)!=null?t:e.secondaryColor,T.terminalFill),terminalStroke:p((r=e.secondaryBorderColor)!=null?r:e.lineColor,T.terminalStroke),terminalTextColor:p((a=e.secondaryTextColor)!=null?a:e.textColor,T.terminalTextColor),nonTerminalFill:p((c=e.mainBkg)!=null?c:e.background,T.nonTerminalFill),nonTerminalStroke:p((l=e.primaryBorderColor)!=null?l:e.lineColor,T.nonTerminalStroke),nonTerminalTextColor:p((s=e.primaryTextColor)!=null?s:e.textColor,T.nonTerminalTextColor),lineColor:p(e.lineColor,T.lineColor),markerFill:p(e.lineColor,T.markerFill),commentFill:p((h=e.labelBackground)!=null?h:e.tertiaryColor,T.commentFill),commentStroke:p((u=e.tertiaryBorderColor)!=null?u:e.lineColor,T.commentStroke),commentTextColor:p((m=e.tertiaryTextColor)!=null?m:e.textColor,T.commentTextColor),specialFill:p((w=e.tertiaryColor)!=null?w:e.secondaryColor,T.specialFill),specialStroke:p((d=e.tertiaryBorderColor)!=null?d:e.secondaryBorderColor,T.specialStroke),ruleNameColor:p((f=e.titleColor)!=null?f:e.textColor,T.ruleNameColor)})},"buildThemeDefaults"),B=g(e=>{var r,a,c,l;let i=O(),o=x(x(x({},L()),(r=i.themeVariables)!=null?r:{}),ue(e)),n=fe(o),t=x(x({},(a=i.railroad)!=null?a:{}),pe(e));return{compactMode:(c=t.compactMode)!=null?c:n.compactMode,padding:R(t.padding,n.padding),verticalSeparation:R(t.verticalSeparation,n.verticalSeparation),horizontalSeparation:R(t.horizontalSeparation,n.horizontalSeparation),arcRadius:R(t.arcRadius,n.arcRadius),fontSize:R(t.fontSize,n.fontSize),fontFamily:Q(t.fontFamily,n.fontFamily),terminalFill:p(t.terminalFill,n.terminalFill),terminalStroke:p(t.terminalStroke,n.terminalStroke),terminalTextColor:p(t.terminalTextColor,n.terminalTextColor),nonTerminalFill:p(t.nonTerminalFill,n.nonTerminalFill),nonTerminalStroke:p(t.nonTerminalStroke,n.nonTerminalStroke),nonTerminalTextColor:p(t.nonTerminalTextColor,n.nonTerminalTextColor),lineColor:p(t.lineColor,n.lineColor),strokeWidth:R(t.strokeWidth,n.strokeWidth),markerFill:p(t.markerFill,n.markerFill),commentFill:p(t.commentFill,n.commentFill),commentStroke:p(t.commentStroke,n.commentStroke),commentTextColor:p(t.commentTextColor,n.commentTextColor),specialFill:p(t.specialFill,n.specialFill),specialStroke:p(t.specialStroke,n.specialStroke),ruleNameColor:p(t.ruleNameColor,n.ruleNameColor),showMarkers:(l=t.showMarkers)!=null?l:n.showMarkers,markerRadius:R(t.markerRadius,n.markerRadius)}},"buildRailroadStyleOptions"),Se=g(e=>{let{fontFamily:i,fontSize:o,terminalFill:n,terminalStroke:t,terminalTextColor:r,nonTerminalFill:a,nonTerminalStroke:c,nonTerminalTextColor:l,lineColor:s,strokeWidth:h,markerFill:u,commentFill:m,commentStroke:w,commentTextColor:d,specialFill:f,specialStroke:N,ruleNameColor:y}=B(e);return`
  .railroad-diagram {
    font-family: ${i};
    font-size: ${o}px;
  }

  .railroad-terminal rect {
    fill: ${n};
    stroke: ${t};
    stroke-width: ${h}px;
  }

  .railroad-terminal text {
    fill: ${r};
    font-family: ${i};
    font-size: ${o}px;
    text-anchor: middle;
    dominant-baseline: middle;
  }

  .railroad-nonterminal rect {
    fill: ${a};
    stroke: ${c};
    stroke-width: ${h}px;
  }

  .railroad-nonterminal text {
    fill: ${l};
    font-family: ${i};
    font-size: ${o}px;
    text-anchor: middle;
    dominant-baseline: middle;
  }

  .railroad-line {
    stroke: ${s};
    stroke-width: ${h}px;
    fill: none;
  }

  .railroad-start circle,
  .railroad-end circle {
    fill: ${u};
  }

  .railroad-comment ellipse {
    fill: ${m};
    stroke: ${w};
    stroke-width: ${h}px;
  }

  .railroad-comment text {
    fill: ${d};
    font-style: italic;
    font-family: ${i};
    font-size: ${o}px;
    text-anchor: middle;
    dominant-baseline: middle;
  }

  .railroad-special rect {
    fill: ${f};
    stroke: ${N};
    stroke-width: ${h}px;
    stroke-dasharray: 5,3;
  }

  .railroad-special text {
    fill: ${l};
    font-family: ${i};
    font-size: ${o}px;
    text-anchor: middle;
    dominant-baseline: middle;
  }

  .railroad-rule-name {
    font-weight: bold;
    fill: ${y};
    font-family: ${i};
    font-size: ${o}px;
  }

  .railroad-group {
    /* Grouping container, no specific styles */
  }
`},"getStyles"),z,v=(z=class{constructor(){this.d=""}moveTo(i,o){return this.d+=`M ${i} ${o} `,this}lineTo(i,o){return this.d+=`L ${i} ${o} `,this}horizontalTo(i){return this.d+=`H ${i} `,this}verticalTo(i){return this.d+=`V ${i} `,this}arcTo(i,o,n,t,r,a,c){return this.d+=`A ${i} ${o} ${n} ${t?1:0} ${r?1:0} ${a} ${c} `,this}build(){return this.d.trim()}},g(z,"PathBuilder"),z),b,Te=(b=class{constructor(i,o=B()){this.textCache=new Map,this.svg=i,this.config=o}measureText(i){if(this.textCache.has(i))return this.textCache.get(i);let o=this.svg.append("text").attr("font-family",this.config.fontFamily).attr("font-size",this.config.fontSize).text(i),n=o.node().getBBox(),t={width:n.width,height:n.height};return o.remove(),this.textCache.set(i,t),t}renderTerminal(i,o){let n=this.measureText(o),t=n.width+this.config.padding*2,r=n.height+this.config.padding*2,a=i.append("g").attr("class","railroad-terminal");return a.append("rect").attr("x",0).attr("y",0).attr("width",t).attr("height",r).attr("rx",10).attr("ry",10),a.append("text").attr("x",t/2).attr("y",r/2).text(o),{element:a.node(),dimensions:{width:t,height:r,up:r/2,down:r/2}}}renderNonTerminal(i,o){let n=this.measureText(o),t=n.width+this.config.padding*2,r=n.height+this.config.padding*2,a=i.append("g").attr("class","railroad-nonterminal");return a.append("rect").attr("x",0).attr("y",0).attr("width",t).attr("height",r),a.append("text").attr("x",t/2).attr("y",r/2).text(o),{element:a.node(),dimensions:{width:t,height:r,up:r/2,down:r/2}}}renderSequence(i,o){let n=o.map(s=>this.renderExpression(i,s)),t=0,r=0,a=0;for(let s of n)t+=s.dimensions.width,r=Math.max(r,s.dimensions.up),a=Math.max(a,s.dimensions.down);t+=(n.length-1)*this.config.horizontalSeparation;let c=i.append("g").attr("class","railroad-sequence"),l=0;for(let s=0;s<n.length;s++){let h=n[s],u=r-h.dimensions.up;if(c.node().appendChild(h.element).setAttribute("transform",`translate(${l}, ${u})`),s<n.length-1){let w=l+h.dimensions.width,d=w+this.config.horizontalSeparation,f=r;c.append("path").attr("class","railroad-line").attr("d",new v().moveTo(w,f).lineTo(d,f).build())}l+=h.dimensions.width+this.config.horizontalSeparation}return{element:c.node(),dimensions:{width:t,height:r+a,up:r,down:a}}}renderChoice(i,o){let n=o.map(m=>this.renderExpression(i,m)),t=0,r=0;for(let m of n)t=Math.max(t,m.dimensions.width),r+=m.dimensions.height;r+=(n.length-1)*this.config.verticalSeparation;let a=this.config.arcRadius,c=a*4,l=t+c,s=i.append("g").attr("class","railroad-choice"),h=0,u=r/2;for(let m of n){let w=h,d=w+m.dimensions.up,f=a*2+(t-m.dimensions.width)/2;s.node().appendChild(m.element).setAttribute("transform",`translate(${f}, ${w})`);let y=new v,S=d>u;d===u?y.moveTo(0,u).lineTo(f,d):y.moveTo(0,u).arcTo(a,a,0,!1,S,a,u+(S?a:-a)).lineTo(a,d-(S?a:-a)).arcTo(a,a,0,!1,!S,a*2,d).lineTo(f,d),s.append("path").attr("class","railroad-line").attr("d",y.build());let M=new v,Y=f+m.dimensions.width,Z=l-a*2;d===u?M.moveTo(Y,d).lineTo(l,u):M.moveTo(Y,d).lineTo(Z,d).arcTo(a,a,0,!1,!S,l-a,d+(S?-a:a)).lineTo(l-a,u+(S?a:-a)).arcTo(a,a,0,!1,S,l,u),s.append("path").attr("class","railroad-line").attr("d",M.build()),h+=m.dimensions.height+this.config.verticalSeparation}return{element:s.node(),dimensions:{width:l,height:r,up:u,down:r-u}}}renderOptional(i,o){let n=this.renderExpression(i,o),t=this.config.arcRadius,r=t*2,a=n.dimensions.width+t*4,c=n.dimensions.height+r,l=i.append("g").attr("class","railroad-optional"),s=t*2,h=r;l.node().appendChild(n.element).setAttribute("transform",`translate(${s}, ${h})`);let m=h+n.dimensions.up,w=new v().moveTo(0,m).lineTo(t*2,m);l.append("path").attr("class","railroad-line").attr("d",w.build());let d=new v().moveTo(s+n.dimensions.width,m).lineTo(a,m);l.append("path").attr("class","railroad-line").attr("d",d.build());let f=new v().moveTo(0,m).arcTo(t,t,0,!1,!1,t,m-t).lineTo(t,t).arcTo(t,t,0,!1,!0,t*2,0).lineTo(a-t*2,0).arcTo(t,t,0,!1,!0,a-t,t).lineTo(a-t,m-t).arcTo(t,t,0,!1,!1,a,m);return l.append("path").attr("class","railroad-line").attr("d",f.build()),{element:l.node(),dimensions:{width:a,height:c,up:m,down:c-m}}}renderRepetition(i,o,n){let t=this.renderExpression(i,o),r=this.config.arcRadius,a=r*2,c=t.dimensions.width+r*4,l=n===0,s=t.dimensions.height+a+(l?a:0),h=i.append("g").attr("class","railroad-repetition"),u=r*2,m=l?a:0;h.node().appendChild(t.element).setAttribute("transform",`translate(${u}, ${m})`);let d=m+t.dimensions.up;h.append("path").attr("class","railroad-line").attr("d",new v().moveTo(0,d).lineTo(r*2,d).build()),h.append("path").attr("class","railroad-line").attr("d",new v().moveTo(u+t.dimensions.width,d).lineTo(c,d).build());let f=m+t.dimensions.height+r,N=new v().moveTo(u+t.dimensions.width,d).arcTo(r,r,0,!1,!0,u+t.dimensions.width+r,d+r).lineTo(u+t.dimensions.width+r,f).arcTo(r,r,0,!1,!0,u+t.dimensions.width,f+r).lineTo(r*2,f+r).arcTo(r,r,0,!1,!0,r,f).lineTo(r,d+r).arcTo(r,r,0,!1,!0,r*2,d);if(h.append("path").attr("class","railroad-line").attr("d",N.build()),l){let y=new v().moveTo(0,d).arcTo(r,r,0,!1,!1,r,d-r).lineTo(r,r).arcTo(r,r,0,!1,!0,r*2,0).lineTo(c-r*2,0).arcTo(r,r,0,!1,!0,c-r,r).lineTo(c-r,d-r).arcTo(r,r,0,!1,!1,c,d);h.append("path").attr("class","railroad-line").attr("d",y.build())}return{element:h.node(),dimensions:{width:c,height:s,up:d,down:s-d}}}renderSpecial(i,o){let n=this.measureText("? "+o+" ?"),t=n.width+this.config.padding*2,r=n.height+this.config.padding*2,a=i.append("g").attr("class","railroad-special");return a.append("rect").attr("x",0).attr("y",0).attr("width",t).attr("height",r),a.append("text").attr("x",t/2).attr("y",r/2).text("? "+o+" ?"),{element:a.node(),dimensions:{width:t,height:r,up:r/2,down:r/2}}}renderExpression(i,o){switch(o.type){case"terminal":return this.renderTerminal(i,o.value);case"nonterminal":return this.renderNonTerminal(i,o.name);case"sequence":return this.renderSequence(i,o.elements);case"choice":return this.renderChoice(i,o.alternatives);case"optional":return this.renderOptional(i,o.element);case"repetition":return this.renderRepetition(i,o.element,o.min);case"special":return this.renderSpecial(i,o.text);default:throw new Error(`Unknown node type: ${o.type}`)}}renderRule(i,o){let n=this.svg.append("g").attr("class","railroad-rule").attr("transform",`translate(0, ${o})`),t=i.name+" =",r=this.measureText(t).width+20,a=r+20,c=n.append("g"),l=this.renderExpression(c,i.definition),s=Math.max(20,l.dimensions.up),h=s-l.dimensions.up;return c.attr("transform",`translate(${a}, ${h})`),n.append("g").attr("class","railroad-rule-name-group").append("text").attr("class","railroad-rule-name").attr("x",0).attr("y",s).text(t),n.append("g").attr("class","railroad-start").append("circle").attr("cx",r).attr("cy",s).attr("r",this.config.markerRadius),n.append("g").attr("class","railroad-end").append("circle").attr("cx",a+l.dimensions.width+10).attr("cy",s).attr("r",this.config.markerRadius),n.append("path").attr("class","railroad-line").attr("d",new v().moveTo(r+this.config.markerRadius,s).lineTo(a,s).build()),n.append("path").attr("class","railroad-line").attr("d",new v().moveTo(a+l.dimensions.width,s).lineTo(a+l.dimensions.width+10-this.config.markerRadius,s).build()),{height:Math.max(40,h+l.dimensions.height+this.config.padding*2),width:a+l.dimensions.width+10+this.config.markerRadius}}renderDiagram(i){let o=this.config.padding,n=0;for(let t of i){let r=this.renderRule(t,o);o+=r.height+this.config.verticalSeparation,n=Math.max(n,r.width)}return{width:n+this.config.padding*2,height:o+this.config.padding}}},g(b,"RailroadRenderer"),b),U=g((e,i,o)=>{X(e,i.height,i.width,o),e.attr("viewBox",`0 0 ${i.width} ${i.height}`)},"configureRailroadSvgSize"),xe=g((e,i,o)=>{var n;k.debug(`[Railroad] Rendering diagram
`+e);try{let t=G(i);t.attr("class","railroad-diagram");let r=O().railroad,a=(n=r==null?void 0:r.useMaxWidth)!=null?n:!0,c=de.getRules();if(k.debug(`[Railroad] Rendering ${c.length} rules`),c.length===0){k.warn("[Railroad] No rules to render"),U(t,{height:100,width:200},a);return}let s=new Te(t,B()).renderDiagram(c);U(t,s,a),k.debug("[Railroad] Render complete")}catch(t){throw k.error("[Railroad] Render error:",t),t}},"draw"),Fe={draw:xe};export{de as a,Se as b,Fe as c};
