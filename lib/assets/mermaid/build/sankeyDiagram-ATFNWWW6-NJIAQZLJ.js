import{$ as Ct,Ba as Ot,N as _t,P as vt,S as bt,T as St,U as wt,V as Lt,W as Et,X as At,Y as Tt,Z as tt,h as y,ha as G,ja as Mt}from"./chunk-SOPNMMPO.js";import"./chunk-FC2K5MUR.js";function J(t,r){let i;if(r===void 0)for(let u of t)u!=null&&(i<u||i===void 0&&u>=u)&&(i=u);else{let u=-1;for(let c of t)(c=r(c,++u,t))!=null&&(i<c||i===void 0&&c>=c)&&(i=c)}return i}function Y(t,r){let i;if(r===void 0)for(let u of t)u!=null&&(i>u||i===void 0&&u>=u)&&(i=u);else{let u=-1;for(let c of t)(c=r(c,++u,t))!=null&&(i>c||i===void 0&&c>=c)&&(i=c)}return i}function q(t,r){let i=0;if(r===void 0)for(let u of t)(u=+u)&&(i+=u);else{let u=-1;for(let c of t)(c=+r(c,++u,t))&&(i+=c)}return i}function Vt(t){return t.target.depth}function lt(t){return t.depth}function ut(t,r){return r-1-t.height}function Q(t,r){return t.sourceLinks.length?t.depth:r-1}function ft(t){return t.targetLinks.length?t.depth:t.sourceLinks.length?Y(t.sourceLinks,Vt)-1:0}function U(t){return function(){return t}}function It(t,r){return et(t.source,r.source)||t.index-r.index}function Nt(t,r){return et(t.target,r.target)||t.index-r.index}function et(t,r){return t.y0-r.y0}function ct(t){return t.value}function Wt(t){return t.index}function Ft(t){return t.nodes}function Ht(t){return t.links}function Pt(t,r){let i=t.get(r);if(!i)throw new Error("missing: "+r);return i}function Rt({nodes:t}){for(let r of t){let i=r.y0,u=i;for(let c of r.sourceLinks)c.y0=i+c.width/2,i+=c.width;for(let c of r.targetLinks)c.y1=u+c.width/2,u+=c.width}}function nt(){let t=0,r=0,i=1,u=1,c=24,p=8,m,x=Wt,s=Q,a,f,k=Ft,_=Ht,d=6;function v(){let e={nodes:k.apply(null,arguments),links:_.apply(null,arguments)};return A(e),E(e),T(e),I(e),P(e),Rt(e),e}v.update=function(e){return Rt(e),e},v.nodeId=function(e){return arguments.length?(x=typeof e=="function"?e:U(e),v):x},v.nodeAlign=function(e){return arguments.length?(s=typeof e=="function"?e:U(e),v):s},v.nodeSort=function(e){return arguments.length?(a=e,v):a},v.nodeWidth=function(e){return arguments.length?(c=+e,v):c},v.nodePadding=function(e){return arguments.length?(p=m=+e,v):p},v.nodes=function(e){return arguments.length?(k=typeof e=="function"?e:U(e),v):k},v.links=function(e){return arguments.length?(_=typeof e=="function"?e:U(e),v):_},v.linkSort=function(e){return arguments.length?(f=e,v):f},v.size=function(e){return arguments.length?(t=r=0,i=+e[0],u=+e[1],v):[i-t,u-r]},v.extent=function(e){return arguments.length?(t=+e[0][0],i=+e[1][0],r=+e[0][1],u=+e[1][1],v):[[t,r],[i,u]]},v.iterations=function(e){return arguments.length?(d=+e,v):d};function A({nodes:e,links:l}){for(let[n,o]of e.entries())o.index=n,o.sourceLinks=[],o.targetLinks=[];let h=new Map(e.map((n,o)=>[x(n,o,e),n]));for(let[n,o]of l.entries()){o.index=n;let{source:g,target:b}=o;typeof g!="object"&&(g=o.source=Pt(h,g)),typeof b!="object"&&(b=o.target=Pt(h,b)),g.sourceLinks.push(o),b.targetLinks.push(o)}if(f!=null)for(let{sourceLinks:n,targetLinks:o}of e)n.sort(f),o.sort(f)}function E({nodes:e}){for(let l of e)l.value=l.fixedValue===void 0?Math.max(q(l.sourceLinks,ct),q(l.targetLinks,ct)):l.fixedValue}function T({nodes:e}){let l=e.length,h=new Set(e),n=new Set,o=0;for(;h.size;){for(let g of h){g.depth=o;for(let{target:b}of g.sourceLinks)n.add(b)}if(++o>l)throw new Error("circular link");h=n,n=new Set}}function I({nodes:e}){let l=e.length,h=new Set(e),n=new Set,o=0;for(;h.size;){for(let g of h){g.height=o;for(let{source:b}of g.targetLinks)n.add(b)}if(++o>l)throw new Error("circular link");h=n,n=new Set}}function z({nodes:e}){let l=J(e,o=>o.depth)+1,h=(i-t-c)/(l-1),n=new Array(l);for(let o of e){let g=Math.max(0,Math.min(l-1,Math.floor(s.call(null,o,l))));o.layer=g,o.x0=t+g*h,o.x1=o.x0+c,n[g]?n[g].push(o):n[g]=[o]}if(a)for(let o of n)o.sort(a);return n}function D(e){let l=Y(e,h=>(u-r-(h.length-1)*m)/q(h,ct));for(let h of e){let n=r;for(let o of h){o.y0=n,o.y1=n+o.value*l,n=o.y1+m;for(let g of o.sourceLinks)g.width=g.value*l}n=(u-n+m)/(h.length+1);for(let o=0;o<h.length;++o){let g=h[o];g.y0+=n*(o+1),g.y1+=n*(o+1)}F(h)}}function P(e){let l=z(e);m=Math.min(p,(u-r)/(J(l,h=>h.length)-1)),D(l);for(let h=0;h<d;++h){let n=Math.pow(.99,h),o=Math.max(1-n,(h+1)/d);C(l,n,o),S(l,n,o)}}function S(e,l,h){for(let n=1,o=e.length;n<o;++n){let g=e[n];for(let b of g){let B=0,O=0;for(let{source:L,value:at}of b.targetLinks){let X=at*(b.layer-L.layer);B+=w(L,b)*X,O+=X}if(!(O>0))continue;let R=(B/O-b.y0)*l;b.y0+=R,b.y1+=R,W(b)}a===void 0&&g.sort(et),N(g,h)}}function C(e,l,h){for(let n=e.length,o=n-2;o>=0;--o){let g=e[o];for(let b of g){let B=0,O=0;for(let{target:L,value:at}of b.sourceLinks){let X=at*(L.layer-b.layer);B+=j(b,L)*X,O+=X}if(!(O>0))continue;let R=(B/O-b.y0)*l;b.y0+=R,b.y1+=R,W(b)}a===void 0&&g.sort(et),N(g,h)}}function N(e,l){let h=e.length>>1,n=e[h];V(e,n.y0-m,h-1,l),M(e,n.y1+m,h+1,l),V(e,u,e.length-1,l),M(e,r,0,l)}function M(e,l,h,n){for(;h<e.length;++h){let o=e[h],g=(l-o.y0)*n;g>1e-6&&(o.y0+=g,o.y1+=g),l=o.y1+m}}function V(e,l,h,n){for(;h>=0;--h){let o=e[h],g=(o.y1-l)*n;g>1e-6&&(o.y0-=g,o.y1-=g),l=o.y0-m}}function W({sourceLinks:e,targetLinks:l}){if(f===void 0){for(let{source:{sourceLinks:h}}of l)h.sort(Nt);for(let{target:{targetLinks:h}}of e)h.sort(It)}}function F(e){if(f===void 0)for(let{sourceLinks:l,targetLinks:h}of e)l.sort(Nt),h.sort(It)}function w(e,l){let h=e.y0-(e.sourceLinks.length-1)*m/2;for(let{target:n,width:o}of e.sourceLinks){if(n===l)break;h+=o+m}for(let{source:n,width:o}of l.targetLinks){if(n===e)break;h-=o}return h}function j(e,l){let h=l.y0-(l.targetLinks.length-1)*m/2;for(let{source:n,width:o}of l.targetLinks){if(n===e)break;h+=o+m}for(let{target:n,width:o}of e.sourceLinks){if(n===l)break;h-=o}return h}return v}var ht=Math.PI,dt=2*ht,H=1e-6,Yt=dt-H;function pt(){this._x0=this._y0=this._x1=this._y1=null,this._=""}function zt(){return new pt}pt.prototype=zt.prototype={constructor:pt,moveTo:function(t,r){this._+="M"+(this._x0=this._x1=+t)+","+(this._y0=this._y1=+r)},closePath:function(){this._x1!==null&&(this._x1=this._x0,this._y1=this._y0,this._+="Z")},lineTo:function(t,r){this._+="L"+(this._x1=+t)+","+(this._y1=+r)},quadraticCurveTo:function(t,r,i,u){this._+="Q"+ +t+","+ +r+","+(this._x1=+i)+","+(this._y1=+u)},bezierCurveTo:function(t,r,i,u,c,p){this._+="C"+ +t+","+ +r+","+ +i+","+ +u+","+(this._x1=+c)+","+(this._y1=+p)},arcTo:function(t,r,i,u,c){t=+t,r=+r,i=+i,u=+u,c=+c;var p=this._x1,m=this._y1,x=i-t,s=u-r,a=p-t,f=m-r,k=a*a+f*f;if(c<0)throw new Error("negative radius: "+c);if(this._x1===null)this._+="M"+(this._x1=t)+","+(this._y1=r);else if(k>H)if(!(Math.abs(f*x-s*a)>H)||!c)this._+="L"+(this._x1=t)+","+(this._y1=r);else{var _=i-p,d=u-m,v=x*x+s*s,A=_*_+d*d,E=Math.sqrt(v),T=Math.sqrt(k),I=c*Math.tan((ht-Math.acos((v+k-A)/(2*E*T)))/2),z=I/T,D=I/E;Math.abs(z-1)>H&&(this._+="L"+(t+z*a)+","+(r+z*f)),this._+="A"+c+","+c+",0,0,"+ +(f*_>a*d)+","+(this._x1=t+D*x)+","+(this._y1=r+D*s)}},arc:function(t,r,i,u,c,p){t=+t,r=+r,i=+i,p=!!p;var m=i*Math.cos(u),x=i*Math.sin(u),s=t+m,a=r+x,f=1^p,k=p?u-c:c-u;if(i<0)throw new Error("negative radius: "+i);this._x1===null?this._+="M"+s+","+a:(Math.abs(this._x1-s)>H||Math.abs(this._y1-a)>H)&&(this._+="L"+s+","+a),i&&(k<0&&(k=k%dt+dt),k>Yt?this._+="A"+i+","+i+",0,1,"+f+","+(t-m)+","+(r-x)+"A"+i+","+i+",0,1,"+f+","+(this._x1=s)+","+(this._y1=a):k>H&&(this._+="A"+i+","+i+",0,"+ +(k>=ht)+","+f+","+(this._x1=t+i*Math.cos(c))+","+(this._y1=r+i*Math.sin(c))))},rect:function(t,r,i,u){this._+="M"+(this._x0=this._x1=+t)+","+(this._y0=this._y1=+r)+"h"+ +i+"v"+ +u+"h"+-i+"Z"},toString:function(){return this._}};var yt=zt;function mt(t){return function(){return t}}function Dt(t){return t[0]}function jt(t){return t[1]}var Bt=Array.prototype.slice;function qt(t){return t.source}function Ut(t){return t.target}function Xt(t){var r=qt,i=Ut,u=Dt,c=jt,p=null;function m(){var x,s=Bt.call(arguments),a=r.apply(this,s),f=i.apply(this,s);if(p||(p=x=yt()),t(p,+u.apply(this,(s[0]=a,s)),+c.apply(this,s),+u.apply(this,(s[0]=f,s)),+c.apply(this,s)),x)return p=null,x+""||null}return m.source=function(x){return arguments.length?(r=x,m):r},m.target=function(x){return arguments.length?(i=x,m):i},m.x=function(x){return arguments.length?(u=typeof x=="function"?x:mt(+x),m):u},m.y=function(x){return arguments.length?(c=typeof x=="function"?x:mt(+x),m):c},m.context=function(x){return arguments.length?(p=x==null?null:x,m):p},m}function Gt(t,r,i,u,c){t.moveTo(r,i),t.bezierCurveTo(r=(r+u)/2,i,r,c,u,c)}function gt(){return Xt(Gt)}function Jt(t){return[t.source.x1,t.y0]}function Qt(t){return[t.target.x0,t.y1]}function xt(){return gt().source(Jt).target(Qt)}var kt=function(){var t=y(function(x,s,a,f){for(a=a||{},f=x.length;f--;a[x[f]]=s);return a},"o"),r=[1,9],i=[1,10],u=[1,5,10,12],c={trace:y(function(){},"trace"),yy:{},symbols_:{error:2,start:3,SANKEY:4,NEWLINE:5,csv:6,opt_eof:7,record:8,csv_tail:9,EOF:10,"field[source]":11,COMMA:12,"field[target]":13,"field[value]":14,field:15,escaped:16,non_escaped:17,DQUOTE:18,ESCAPED_TEXT:19,NON_ESCAPED_TEXT:20,$accept:0,$end:1},terminals_:{2:"error",4:"SANKEY",5:"NEWLINE",10:"EOF",11:"field[source]",12:"COMMA",13:"field[target]",14:"field[value]",18:"DQUOTE",19:"ESCAPED_TEXT",20:"NON_ESCAPED_TEXT"},productions_:[0,[3,4],[6,2],[9,2],[9,0],[7,1],[7,0],[8,5],[15,1],[15,1],[16,3],[17,1]],performAction:y(function(s,a,f,k,_,d,v){var A=d.length-1;switch(_){case 7:let E=k.findOrCreateNode(d[A-4].trim().replaceAll('""','"')),T=k.findOrCreateNode(d[A-2].trim().replaceAll('""','"')),I=parseFloat(d[A].trim());k.addLink(E,T,I);break;case 8:case 9:case 11:this.$=d[A];break;case 10:this.$=d[A-1];break}},"anonymous"),table:[{3:1,4:[1,2]},{1:[3]},{5:[1,3]},{6:4,8:5,15:6,16:7,17:8,18:r,20:i},{1:[2,6],7:11,10:[1,12]},t(i,[2,4],{9:13,5:[1,14]}),{12:[1,15]},t(u,[2,8]),t(u,[2,9]),{19:[1,16]},t(u,[2,11]),{1:[2,1]},{1:[2,5]},t(i,[2,2]),{6:17,8:5,15:6,16:7,17:8,18:r,20:i},{15:18,16:7,17:8,18:r,20:i},{18:[1,19]},t(i,[2,3]),{12:[1,20]},t(u,[2,10]),{15:21,16:7,17:8,18:r,20:i},t([1,5,10],[2,7])],defaultActions:{11:[2,1],12:[2,5]},parseError:y(function(s,a){if(a.recoverable)this.trace(s);else{var f=new Error(s);throw f.hash=a,f}},"parseError"),parse:y(function(s){var a=this,f=[0],k=[],_=[null],d=[],v=this.table,A="",E=0,T=0,I=0,z=2,D=1,P=d.slice.call(arguments,1),S=Object.create(this.lexer),C={yy:{}};for(var N in this.yy)Object.prototype.hasOwnProperty.call(this.yy,N)&&(C.yy[N]=this.yy[N]);S.setInput(s,C.yy),C.yy.lexer=S,C.yy.parser=this,typeof S.yylloc=="undefined"&&(S.yylloc={});var M=S.yylloc;d.push(M);var V=S.options&&S.options.ranges;typeof C.yy.parseError=="function"?this.parseError=C.yy.parseError:this.parseError=Object.getPrototypeOf(this).parseError;function W(L){f.length=f.length-2*L,_.length=_.length-L,d.length=d.length-L}y(W,"popStack");function F(){var L;return L=k.pop()||S.lex()||D,typeof L!="number"&&(L instanceof Array&&(k=L,L=k.pop()),L=a.symbols_[L]||L),L}y(F,"lex");for(var w,j,e,l,h,n,o={},g,b,B,O;;){if(e=f[f.length-1],this.defaultActions[e]?l=this.defaultActions[e]:((w===null||typeof w=="undefined")&&(w=F()),l=v[e]&&v[e][w]),typeof l=="undefined"||!l.length||!l[0]){var R="";O=[];for(g in v[e])this.terminals_[g]&&g>z&&O.push("'"+this.terminals_[g]+"'");S.showPosition?R="Parse error on line "+(E+1)+`:
`+S.showPosition()+`
Expecting `+O.join(", ")+", got '"+(this.terminals_[w]||w)+"'":R="Parse error on line "+(E+1)+": Unexpected "+(w==D?"end of input":"'"+(this.terminals_[w]||w)+"'"),this.parseError(R,{text:S.match,token:this.terminals_[w]||w,line:S.yylineno,loc:M,expected:O})}if(l[0]instanceof Array&&l.length>1)throw new Error("Parse Error: multiple actions possible at state: "+e+", token: "+w);switch(l[0]){case 1:f.push(w),_.push(S.yytext),d.push(S.yylloc),f.push(l[1]),w=null,j?(w=j,j=null):(T=S.yyleng,A=S.yytext,E=S.yylineno,M=S.yylloc,I>0&&I--);break;case 2:if(b=this.productions_[l[1]][1],o.$=_[_.length-b],o._$={first_line:d[d.length-(b||1)].first_line,last_line:d[d.length-1].last_line,first_column:d[d.length-(b||1)].first_column,last_column:d[d.length-1].last_column},V&&(o._$.range=[d[d.length-(b||1)].range[0],d[d.length-1].range[1]]),n=this.performAction.apply(o,[A,T,E,C.yy,l[1],_,d].concat(P)),typeof n!="undefined")return n;b&&(f=f.slice(0,-1*b*2),_=_.slice(0,-1*b),d=d.slice(0,-1*b)),f.push(this.productions_[l[1]][0]),_.push(o.$),d.push(o._$),B=v[f[f.length-2]][f[f.length-1]],f.push(B);break;case 3:return!0}}return!0},"parse")},p=function(){var x={EOF:1,parseError:y(function(a,f){if(this.yy.parser)this.yy.parser.parseError(a,f);else throw new Error(a)},"parseError"),setInput:y(function(s,a){return this.yy=a||this.yy||{},this._input=s,this._more=this._backtrack=this.done=!1,this.yylineno=this.yyleng=0,this.yytext=this.matched=this.match="",this.conditionStack=["INITIAL"],this.yylloc={first_line:1,first_column:0,last_line:1,last_column:0},this.options.ranges&&(this.yylloc.range=[0,0]),this.offset=0,this},"setInput"),input:y(function(){var s=this._input[0];this.yytext+=s,this.yyleng++,this.offset++,this.match+=s,this.matched+=s;var a=s.match(/(?:\r\n?|\n).*/g);return a?(this.yylineno++,this.yylloc.last_line++):this.yylloc.last_column++,this.options.ranges&&this.yylloc.range[1]++,this._input=this._input.slice(1),s},"input"),unput:y(function(s){var a=s.length,f=s.split(/(?:\r\n?|\n)/g);this._input=s+this._input,this.yytext=this.yytext.substr(0,this.yytext.length-a),this.offset-=a;var k=this.match.split(/(?:\r\n?|\n)/g);this.match=this.match.substr(0,this.match.length-1),this.matched=this.matched.substr(0,this.matched.length-1),f.length-1&&(this.yylineno-=f.length-1);var _=this.yylloc.range;return this.yylloc={first_line:this.yylloc.first_line,last_line:this.yylineno+1,first_column:this.yylloc.first_column,last_column:f?(f.length===k.length?this.yylloc.first_column:0)+k[k.length-f.length].length-f[0].length:this.yylloc.first_column-a},this.options.ranges&&(this.yylloc.range=[_[0],_[0]+this.yyleng-a]),this.yyleng=this.yytext.length,this},"unput"),more:y(function(){return this._more=!0,this},"more"),reject:y(function(){if(this.options.backtrack_lexer)this._backtrack=!0;else return this.parseError("Lexical error on line "+(this.yylineno+1)+`. You can only invoke reject() in the lexer when the lexer is of the backtracking persuasion (options.backtrack_lexer = true).
`+this.showPosition(),{text:"",token:null,line:this.yylineno});return this},"reject"),less:y(function(s){this.unput(this.match.slice(s))},"less"),pastInput:y(function(){var s=this.matched.substr(0,this.matched.length-this.match.length);return(s.length>20?"...":"")+s.substr(-20).replace(/\n/g,"")},"pastInput"),upcomingInput:y(function(){var s=this.match;return s.length<20&&(s+=this._input.substr(0,20-s.length)),(s.substr(0,20)+(s.length>20?"...":"")).replace(/\n/g,"")},"upcomingInput"),showPosition:y(function(){var s=this.pastInput(),a=new Array(s.length+1).join("-");return s+this.upcomingInput()+`
`+a+"^"},"showPosition"),test_match:y(function(s,a){var f,k,_;if(this.options.backtrack_lexer&&(_={yylineno:this.yylineno,yylloc:{first_line:this.yylloc.first_line,last_line:this.last_line,first_column:this.yylloc.first_column,last_column:this.yylloc.last_column},yytext:this.yytext,match:this.match,matches:this.matches,matched:this.matched,yyleng:this.yyleng,offset:this.offset,_more:this._more,_input:this._input,yy:this.yy,conditionStack:this.conditionStack.slice(0),done:this.done},this.options.ranges&&(_.yylloc.range=this.yylloc.range.slice(0))),k=s[0].match(/(?:\r\n?|\n).*/g),k&&(this.yylineno+=k.length),this.yylloc={first_line:this.yylloc.last_line,last_line:this.yylineno+1,first_column:this.yylloc.last_column,last_column:k?k[k.length-1].length-k[k.length-1].match(/\r?\n?/)[0].length:this.yylloc.last_column+s[0].length},this.yytext+=s[0],this.match+=s[0],this.matches=s,this.yyleng=this.yytext.length,this.options.ranges&&(this.yylloc.range=[this.offset,this.offset+=this.yyleng]),this._more=!1,this._backtrack=!1,this._input=this._input.slice(s[0].length),this.matched+=s[0],f=this.performAction.call(this,this.yy,this,a,this.conditionStack[this.conditionStack.length-1]),this.done&&this._input&&(this.done=!1),f)return f;if(this._backtrack){for(var d in _)this[d]=_[d];return!1}return!1},"test_match"),next:y(function(){if(this.done)return this.EOF;this._input||(this.done=!0);var s,a,f,k;this._more||(this.yytext="",this.match="");for(var _=this._currentRules(),d=0;d<_.length;d++)if(f=this._input.match(this.rules[_[d]]),f&&(!a||f[0].length>a[0].length)){if(a=f,k=d,this.options.backtrack_lexer){if(s=this.test_match(f,_[d]),s!==!1)return s;if(this._backtrack){a=!1;continue}else return!1}else if(!this.options.flex)break}return a?(s=this.test_match(a,_[k]),s!==!1?s:!1):this._input===""?this.EOF:this.parseError("Lexical error on line "+(this.yylineno+1)+`. Unrecognized text.
`+this.showPosition(),{text:"",token:null,line:this.yylineno})},"next"),lex:y(function(){var a=this.next();return a||this.lex()},"lex"),begin:y(function(a){this.conditionStack.push(a)},"begin"),popState:y(function(){var a=this.conditionStack.length-1;return a>0?this.conditionStack.pop():this.conditionStack[0]},"popState"),_currentRules:y(function(){return this.conditionStack.length&&this.conditionStack[this.conditionStack.length-1]?this.conditions[this.conditionStack[this.conditionStack.length-1]].rules:this.conditions.INITIAL.rules},"_currentRules"),topState:y(function(a){return a=this.conditionStack.length-1-Math.abs(a||0),a>=0?this.conditionStack[a]:"INITIAL"},"topState"),pushState:y(function(a){this.begin(a)},"pushState"),stateStackSize:y(function(){return this.conditionStack.length},"stateStackSize"),options:{"case-insensitive":!0},performAction:y(function(a,f,k,_){var d=_;switch(k){case 0:return this.pushState("csv"),4;break;case 1:return 10;case 2:return 5;case 3:return 12;case 4:return this.pushState("escaped_text"),18;break;case 5:return 20;case 6:return this.popState("escaped_text"),18;break;case 7:return 19}},"anonymous"),rules:[/^(?:sankey-beta\b)/i,/^(?:$)/i,/^(?:((\u000D\u000A)|(\u000A)))/i,/^(?:(\u002C))/i,/^(?:(\u0022))/i,/^(?:([\u0020-\u0021\u0023-\u002B\u002D-\u007E])*)/i,/^(?:(\u0022)(?!(\u0022)))/i,/^(?:(([\u0020-\u0021\u0023-\u002B\u002D-\u007E])|(\u002C)|(\u000D)|(\u000A)|(\u0022)(\u0022))*)/i],conditions:{csv:{rules:[1,2,3,4,5,6,7],inclusive:!1},escaped_text:{rules:[6,7],inclusive:!1},INITIAL:{rules:[0,1,2,3,4,5,6,7],inclusive:!0}}};return x}();c.lexer=p;function m(){this.yy={}}return y(m,"Parser"),m.prototype=c,c.Parser=m,new m}();kt.parser=kt;var rt=kt,st=[],it=[],ot=new Map,Kt=y(()=>{st=[],it=[],ot=new Map,bt()},"clear"),K,Zt=(K=class{constructor(r,i,u=0){this.source=r,this.target=i,this.value=u}},y(K,"SankeyLink"),K),te=y((t,r,i)=>{st.push(new Zt(t,r,i))},"addLink"),Z,ee=(Z=class{constructor(r){this.ID=r}},y(Z,"SankeyNode"),Z),ne=y(t=>{t=_t.sanitizeText(t,tt());let r=ot.get(t);return r===void 0&&(r=new ee(t),ot.set(t,r),it.push(r)),r},"findOrCreateNode"),re=y(()=>it,"getNodes"),oe=y(()=>st,"getLinks"),se=y(()=>({nodes:it.map(t=>({id:t.ID})),links:st.map(t=>({source:t.source.ID,target:t.target.ID,value:t.value}))}),"getGraph"),ie={nodesMap:ot,getConfig:y(()=>tt().sankey,"getConfig"),getNodes:re,getLinks:oe,getGraph:se,addLink:te,findOrCreateNode:ne,getAccTitle:wt,setAccTitle:St,getAccDescription:Et,setAccDescription:Lt,getDiagramTitle:Tt,setDiagramTitle:At,clear:Kt},$,$t=($=class{static next(r){return new $(r+ ++$.count)}constructor(r){this.id=r,this.href=`#${r}`}toString(){return"url("+this.href+")"}},y($,"Uid"),$.count=0,$),ae={left:lt,right:ut,center:ft,justify:Q},le=y(function(t,r,i,u){var V,W,F,w,j,e,l,h;let{securityLevel:c,sankey:p}=tt(),m=Ct.sankey,x;c==="sandbox"&&(x=G("#i"+r));let s=c==="sandbox"?G(x.nodes()[0].contentDocument.body):G("body"),a=c==="sandbox"?s.select(`[id="${r}"]`):G(`[id="${r}"]`),f=(V=p==null?void 0:p.width)!=null?V:m.width,k=(W=p==null?void 0:p.height)!=null?W:m.width,_=(F=p==null?void 0:p.useMaxWidth)!=null?F:m.useMaxWidth,d=(w=p==null?void 0:p.nodeAlignment)!=null?w:m.nodeAlignment,v=(j=p==null?void 0:p.prefix)!=null?j:m.prefix,A=(e=p==null?void 0:p.suffix)!=null?e:m.suffix,E=(l=p==null?void 0:p.showValues)!=null?l:m.showValues,T=u.db.getGraph(),I=ae[d];nt().nodeId(n=>n.id).nodeWidth(10).nodePadding(10+(E?15:0)).nodeAlign(I).extent([[0,0],[f,k]])(T);let P=Mt(Ot);a.append("g").attr("class","nodes").selectAll(".node").data(T.nodes).join("g").attr("class","node").attr("id",n=>(n.uid=$t.next("node-")).id).attr("transform",function(n){return"translate("+n.x0+","+n.y0+")"}).attr("x",n=>n.x0).attr("y",n=>n.y0).append("rect").attr("height",n=>n.y1-n.y0).attr("width",n=>n.x1-n.x0).attr("fill",n=>P(n.id));let S=y(({id:n,value:o})=>E?`${n}
${v}${Math.round(o*100)/100}${A}`:n,"getText");a.append("g").attr("class","node-labels").attr("font-family","sans-serif").attr("font-size",14).selectAll("text").data(T.nodes).join("text").attr("x",n=>n.x0<f/2?n.x1+6:n.x0-6).attr("y",n=>(n.y1+n.y0)/2).attr("dy",`${E?"0":"0.35"}em`).attr("text-anchor",n=>n.x0<f/2?"start":"end").text(S);let C=a.append("g").attr("class","links").attr("fill","none").attr("stroke-opacity",.5).selectAll(".link").data(T.links).join("g").attr("class","link").style("mix-blend-mode","multiply"),N=(h=p==null?void 0:p.linkColor)!=null?h:"gradient";if(N==="gradient"){let n=C.append("linearGradient").attr("id",o=>(o.uid=$t.next("linearGradient-")).id).attr("gradientUnits","userSpaceOnUse").attr("x1",o=>o.source.x1).attr("x2",o=>o.target.x0);n.append("stop").attr("offset","0%").attr("stop-color",o=>P(o.source.id)),n.append("stop").attr("offset","100%").attr("stop-color",o=>P(o.target.id))}let M;switch(N){case"gradient":M=y(n=>n.uid,"coloring");break;case"source":M=y(n=>P(n.source.id),"coloring");break;case"target":M=y(n=>P(n.target.id),"coloring");break;default:M=N}C.append("path").attr("d",xt()).attr("stroke",M).attr("stroke-width",n=>Math.max(1,n.width)),vt(void 0,a,0,_)},"draw"),ue={draw:le},fe=y(t=>t.replaceAll(/^[^\S\n\r]+|[^\S\n\r]+$/g,"").replaceAll(/([\n\r])+/g,`
`).trim(),"prepareTextForParsing"),ce=rt.parse.bind(rt);rt.parse=t=>ce(fe(t));var Je={parser:rt,db:ie,renderer:ue};export{Je as diagram};