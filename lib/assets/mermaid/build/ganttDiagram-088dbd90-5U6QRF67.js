import{A as ae,B as ce,C as oe,D as Ct,E as Et,F as le,Ja as gt,M as Be,Oa as ue,ab as de,d as _t,db as nt,f as at,fb as fe,h as Pe,hb as he,i as Ne,ib as me,j as Qt,jb as ke,k as Jt,kb as ye,l as Kt,lb as ge,m as $t,mb as pe,n as dt,nb as ve,p as te,s as ee,t as wt,u as Dt,ub as be,v as St,w as ie,x as se,y as ne,z as re}from"./chunk-AR5UQGPT.js";var Te=_t((Mt,At)=>{(function(t,c){typeof Mt=="object"&&typeof At!="undefined"?At.exports=c():typeof define=="function"&&define.amd?define(c):(t=typeof globalThis!="undefined"?globalThis:t||self).dayjs_plugin_isoWeek=c()})(Mt,function(){"use strict";var t="day";return function(c,s,e){var n=function(v){return v.add(4-v.isoWeekday(),t)},l=s.prototype;l.isoWeekYear=function(){return n(this).year()},l.isoWeek=function(v){if(!this.$utils().u(v))return this.add(7*(v-this.isoWeek()),t);var E,I,Y,z,X=n(this),g=(E=this.isoWeekYear(),I=this.$u,Y=(I?e.utc:e)().year(E).startOf("year"),z=4-Y.isoWeekday(),Y.isoWeekday()>4&&(z+=7),Y.add(z,t));return X.diff(g,"week")+1},l.isoWeekday=function(v){return this.$utils().u(v)?this.day()||7:this.day(this.day()%7?v:v-7)};var f=l.startOf;l.startOf=function(v,E){var I=this.$utils(),Y=!!I.u(E)||E;return I.p(v)==="isoweek"?Y?this.date(this.date()-(this.isoWeekday()-1)).startOf("day"):this.date(this.date()-1-(this.isoWeekday()-1)+7).endOf("day"):f.bind(this)(v,E)}}})});var xe=_t((Lt,It)=>{(function(t,c){typeof Lt=="object"&&typeof It!="undefined"?It.exports=c():typeof define=="function"&&define.amd?define(c):(t=typeof globalThis!="undefined"?globalThis:t||self).dayjs_plugin_customParseFormat=c()})(Lt,function(){"use strict";var t={LTS:"h:mm:ss A",LT:"h:mm A",L:"MM/DD/YYYY",LL:"MMMM D, YYYY",LLL:"MMMM D, YYYY h:mm A",LLLL:"dddd, MMMM D, YYYY h:mm A"},c=/(\[[^[]*\])|([-_:/.,()\s]+)|(A|a|YYYY|YY?|MM?M?M?|Do|DD?|hh?|HH?|mm?|ss?|S{1,3}|z|ZZ?)/g,s=/\d\d/,e=/\d\d?/,n=/\d*[^-_:/,()\s\d]+/,l={},f=function(g){return(g=+g)+(g>68?1900:2e3)},v=function(g){return function(x){this[g]=+x}},E=[/[+-]\d\d:?(\d\d)?|Z/,function(g){(this.zone||(this.zone={})).offset=function(x){if(!x||x==="Z")return 0;var y=x.match(/([+-]|\d\d)/g),M=60*y[1]+(+y[2]||0);return M===0?0:y[0]==="+"?-M:M}(g)}],I=function(g){var x=l[g];return x&&(x.indexOf?x:x.s.concat(x.f))},Y=function(g,x){var y,M=l.meridiem;if(M){for(var V=1;V<=24;V+=1)if(g.indexOf(M(V,0,x))>-1){y=V>12;break}}else y=g===(x?"pm":"PM");return y},z={A:[n,function(g){this.afternoon=Y(g,!1)}],a:[n,function(g){this.afternoon=Y(g,!0)}],S:[/\d/,function(g){this.milliseconds=100*+g}],SS:[s,function(g){this.milliseconds=10*+g}],SSS:[/\d{3}/,function(g){this.milliseconds=+g}],s:[e,v("seconds")],ss:[e,v("seconds")],m:[e,v("minutes")],mm:[e,v("minutes")],H:[e,v("hours")],h:[e,v("hours")],HH:[e,v("hours")],hh:[e,v("hours")],D:[e,v("day")],DD:[s,v("day")],Do:[n,function(g){var x=l.ordinal,y=g.match(/\d+/);if(this.day=y[0],x)for(var M=1;M<=31;M+=1)x(M).replace(/\[|\]/g,"")===g&&(this.day=M)}],M:[e,v("month")],MM:[s,v("month")],MMM:[n,function(g){var x=I("months"),y=(I("monthsShort")||x.map(function(M){return M.slice(0,3)})).indexOf(g)+1;if(y<1)throw new Error;this.month=y%12||y}],MMMM:[n,function(g){var x=I("months").indexOf(g)+1;if(x<1)throw new Error;this.month=x%12||x}],Y:[/[+-]?\d+/,v("year")],YY:[s,function(g){this.year=f(g)}],YYYY:[/\d{4}/,v("year")],Z:E,ZZ:E};function X(g){var x,y;x=g,y=l&&l.formats;for(var M=(g=x.replace(/(\[[^\]]+])|(LTS?|l{1,4}|L{1,4})/g,function(G,k,b){var p=b&&b.toUpperCase();return k||y[b]||t[b]||y[p].replace(/(\[[^\]]+])|(MMMM|MM|DD|dddd)/g,function(T,m,S){return m||S.slice(1)})})).match(c),V=M.length,O=0;O<V;O+=1){var U=M[O],j=z[U],P=j&&j[0],N=j&&j[1];M[O]=N?{regex:P,parser:N}:U.replace(/^\[|\]$/g,"")}return function(G){for(var k={},b=0,p=0;b<V;b+=1){var T=M[b];if(typeof T=="string")p+=T.length;else{var m=T.regex,S=T.parser,w=G.slice(p),_=m.exec(w)[0];S.call(k,_),G=G.replace(_,"")}}return function(o){var u=o.afternoon;if(u!==void 0){var h=o.hours;u?h<12&&(o.hours+=12):h===12&&(o.hours=0),delete o.afternoon}}(k),k}}return function(g,x,y){y.p.customParseFormat=!0,g&&g.parseTwoDigitYear&&(f=g.parseTwoDigitYear);var M=x.prototype,V=M.parse;M.parse=function(O){var U=O.date,j=O.utc,P=O.args;this.$u=j;var N=P[1];if(typeof N=="string"){var G=P[2]===!0,k=P[3]===!0,b=G||k,p=P[2];k&&(p=P[2]),l=this.$locale(),!G&&p&&(l=y.Ls[p]),this.$d=function(w,_,o){try{if(["x","X"].indexOf(_)>-1)return new Date((_==="X"?1e3:1)*w);var u=X(_)(w),h=u.year,d=u.month,a=u.day,i=u.hours,C=u.minutes,r=u.seconds,D=u.milliseconds,F=u.zone,A=new Date,$=a||(h||d?1:A.getDate()),tt=h||A.getFullYear(),L=0;h&&!d||(L=d>0?d-1:A.getMonth());var q=i||0,et=C||0,it=r||0,ut=D||0;return F?new Date(Date.UTC(tt,L,$,q,et,it,ut+60*F.offset*1e3)):o?new Date(Date.UTC(tt,L,$,q,et,it,ut)):new Date(tt,L,$,q,et,it,ut)}catch(Ut){return new Date("")}}(U,N,j),this.init(),p&&p!==!0&&(this.$L=this.locale(p).$L),b&&U!=this.format(N)&&(this.$d=new Date("")),l={}}else if(N instanceof Array)for(var T=N.length,m=1;m<=T;m+=1){P[1]=N[m-1];var S=y.apply(this,P);if(S.isValid()){this.$d=S.$d,this.$L=S.$L,this.init();break}m===T&&(this.$d=new Date(""))}else V.call(this,O)}}})});var _e=_t((Yt,Ft)=>{(function(t,c){typeof Yt=="object"&&typeof Ft!="undefined"?Ft.exports=c():typeof define=="function"&&define.amd?define(c):(t=typeof globalThis!="undefined"?globalThis:t||self).dayjs_plugin_advancedFormat=c()})(Yt,function(){"use strict";return function(t,c){var s=c.prototype,e=s.format;s.format=function(n){var l=this,f=this.$locale();if(!this.isValid())return e.bind(this)(n);var v=this.$utils(),E=(n||"YYYY-MM-DDTHH:mm:ssZ").replace(/\[([^\]]+)]|Q|wo|ww|w|WW|W|zzz|z|gggg|GGGG|Do|X|x|k{1,2}|S/g,function(I){switch(I){case"Q":return Math.ceil((l.$M+1)/3);case"Do":return f.ordinal(l.$D);case"gggg":return l.weekYear();case"GGGG":return l.isoWeekYear();case"wo":return f.ordinal(l.week(),"W");case"w":case"ww":return v.s(l.week(),I==="w"?1:2,"0");case"W":case"WW":return v.s(l.isoWeek(),I==="W"?1:2,"0");case"k":case"kk":return v.s(String(l.$H===0?24:l.$H),I==="k"?1:2,"0");case"X":return Math.floor(l.$d.getTime()/1e3);case"x":return l.$d.getTime();case"z":return"["+l.offsetName()+"]";case"zzz":return"["+l.offsetName("long")+"]";default:return I}});return e.bind(this)(E)}}})});var Se=at(Ne(),1),R=at(Pe(),1),Ce=at(Te(),1),Ee=at(xe(),1),Me=at(_e(),1);var Fi=at(Be(),1);var Wt=function(){var t=function(_,o,u,h){for(u=u||{},h=_.length;h--;u[_[h]]=o);return u},c=[1,3],s=[1,5],e=[7,9,11,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,31,33,34,36,43,48],n=[1,32],l=[1,33],f=[1,34],v=[1,35],E=[1,36],I=[1,37],Y=[1,38],z=[1,15],X=[1,16],g=[1,17],x=[1,18],y=[1,19],M=[1,20],V=[1,21],O=[1,22],U=[1,24],j=[1,25],P=[1,26],N=[1,27],G=[1,28],k=[1,30],b=[1,39],p=[1,42],T=[5,7,9,11,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,31,33,34,36,43,48],m={trace:function(){},yy:{},symbols_:{error:2,start:3,directive:4,gantt:5,document:6,EOF:7,line:8,SPACE:9,statement:10,NL:11,weekday:12,weekday_monday:13,weekday_tuesday:14,weekday_wednesday:15,weekday_thursday:16,weekday_friday:17,weekday_saturday:18,weekday_sunday:19,dateFormat:20,inclusiveEndDates:21,topAxis:22,axisFormat:23,tickInterval:24,excludes:25,includes:26,todayMarker:27,title:28,acc_title:29,acc_title_value:30,acc_descr:31,acc_descr_value:32,acc_descr_multiline_value:33,section:34,clickStatement:35,taskTxt:36,taskData:37,openDirective:38,typeDirective:39,closeDirective:40,":":41,argDirective:42,click:43,callbackname:44,callbackargs:45,href:46,clickStatementDebug:47,open_directive:48,type_directive:49,arg_directive:50,close_directive:51,$accept:0,$end:1},terminals_:{2:"error",5:"gantt",7:"EOF",9:"SPACE",11:"NL",13:"weekday_monday",14:"weekday_tuesday",15:"weekday_wednesday",16:"weekday_thursday",17:"weekday_friday",18:"weekday_saturday",19:"weekday_sunday",20:"dateFormat",21:"inclusiveEndDates",22:"topAxis",23:"axisFormat",24:"tickInterval",25:"excludes",26:"includes",27:"todayMarker",28:"title",29:"acc_title",30:"acc_title_value",31:"acc_descr",32:"acc_descr_value",33:"acc_descr_multiline_value",34:"section",36:"taskTxt",37:"taskData",41:":",43:"click",44:"callbackname",45:"callbackargs",46:"href",48:"open_directive",49:"type_directive",50:"arg_directive",51:"close_directive"},productions_:[0,[3,2],[3,3],[6,0],[6,2],[8,2],[8,1],[8,1],[8,1],[12,1],[12,1],[12,1],[12,1],[12,1],[12,1],[12,1],[10,1],[10,1],[10,1],[10,1],[10,1],[10,1],[10,1],[10,1],[10,1],[10,1],[10,2],[10,2],[10,1],[10,1],[10,1],[10,2],[10,1],[4,4],[4,6],[35,2],[35,3],[35,3],[35,4],[35,3],[35,4],[35,2],[47,2],[47,3],[47,3],[47,4],[47,3],[47,4],[47,2],[38,1],[39,1],[42,1],[40,1]],performAction:function(o,u,h,d,a,i,C){var r=i.length-1;switch(a){case 2:return i[r-1];case 3:this.$=[];break;case 4:i[r-1].push(i[r]),this.$=i[r-1];break;case 5:case 6:this.$=i[r];break;case 7:case 8:this.$=[];break;case 9:d.setWeekday("monday");break;case 10:d.setWeekday("tuesday");break;case 11:d.setWeekday("wednesday");break;case 12:d.setWeekday("thursday");break;case 13:d.setWeekday("friday");break;case 14:d.setWeekday("saturday");break;case 15:d.setWeekday("sunday");break;case 16:d.setDateFormat(i[r].substr(11)),this.$=i[r].substr(11);break;case 17:d.enableInclusiveEndDates(),this.$=i[r].substr(18);break;case 18:d.TopAxis(),this.$=i[r].substr(8);break;case 19:d.setAxisFormat(i[r].substr(11)),this.$=i[r].substr(11);break;case 20:d.setTickInterval(i[r].substr(13)),this.$=i[r].substr(13);break;case 21:d.setExcludes(i[r].substr(9)),this.$=i[r].substr(9);break;case 22:d.setIncludes(i[r].substr(9)),this.$=i[r].substr(9);break;case 23:d.setTodayMarker(i[r].substr(12)),this.$=i[r].substr(12);break;case 25:d.setDiagramTitle(i[r].substr(6)),this.$=i[r].substr(6);break;case 26:this.$=i[r].trim(),d.setAccTitle(this.$);break;case 27:case 28:this.$=i[r].trim(),d.setAccDescription(this.$);break;case 29:d.addSection(i[r].substr(8)),this.$=i[r].substr(8);break;case 31:d.addTask(i[r-1],i[r]),this.$="task";break;case 35:this.$=i[r-1],d.setClickEvent(i[r-1],i[r],null);break;case 36:this.$=i[r-2],d.setClickEvent(i[r-2],i[r-1],i[r]);break;case 37:this.$=i[r-2],d.setClickEvent(i[r-2],i[r-1],null),d.setLink(i[r-2],i[r]);break;case 38:this.$=i[r-3],d.setClickEvent(i[r-3],i[r-2],i[r-1]),d.setLink(i[r-3],i[r]);break;case 39:this.$=i[r-2],d.setClickEvent(i[r-2],i[r],null),d.setLink(i[r-2],i[r-1]);break;case 40:this.$=i[r-3],d.setClickEvent(i[r-3],i[r-1],i[r]),d.setLink(i[r-3],i[r-2]);break;case 41:this.$=i[r-1],d.setLink(i[r-1],i[r]);break;case 42:case 48:this.$=i[r-1]+" "+i[r];break;case 43:case 44:case 46:this.$=i[r-2]+" "+i[r-1]+" "+i[r];break;case 45:case 47:this.$=i[r-3]+" "+i[r-2]+" "+i[r-1]+" "+i[r];break;case 49:d.parseDirective("%%{","open_directive");break;case 50:d.parseDirective(i[r],"type_directive");break;case 51:i[r]=i[r].trim().replace(/'/g,'"'),d.parseDirective(i[r],"arg_directive");break;case 52:d.parseDirective("}%%","close_directive","gantt");break}},table:[{3:1,4:2,5:c,38:4,48:s},{1:[3]},{3:6,4:2,5:c,38:4,48:s},t(e,[2,3],{6:7}),{39:8,49:[1,9]},{49:[2,49]},{1:[2,1]},{4:31,7:[1,10],8:11,9:[1,12],10:13,11:[1,14],12:23,13:n,14:l,15:f,16:v,17:E,18:I,19:Y,20:z,21:X,22:g,23:x,24:y,25:M,26:V,27:O,28:U,29:j,31:P,33:N,34:G,35:29,36:k,38:4,43:b,48:s},{40:40,41:[1,41],51:p},t([41,51],[2,50]),t(e,[2,8],{1:[2,2]}),t(e,[2,4]),{4:31,10:43,12:23,13:n,14:l,15:f,16:v,17:E,18:I,19:Y,20:z,21:X,22:g,23:x,24:y,25:M,26:V,27:O,28:U,29:j,31:P,33:N,34:G,35:29,36:k,38:4,43:b,48:s},t(e,[2,6]),t(e,[2,7]),t(e,[2,16]),t(e,[2,17]),t(e,[2,18]),t(e,[2,19]),t(e,[2,20]),t(e,[2,21]),t(e,[2,22]),t(e,[2,23]),t(e,[2,24]),t(e,[2,25]),{30:[1,44]},{32:[1,45]},t(e,[2,28]),t(e,[2,29]),t(e,[2,30]),{37:[1,46]},t(e,[2,32]),t(e,[2,9]),t(e,[2,10]),t(e,[2,11]),t(e,[2,12]),t(e,[2,13]),t(e,[2,14]),t(e,[2,15]),{44:[1,47],46:[1,48]},{11:[1,49]},{42:50,50:[1,51]},{11:[2,52]},t(e,[2,5]),t(e,[2,26]),t(e,[2,27]),t(e,[2,31]),t(e,[2,35],{45:[1,52],46:[1,53]}),t(e,[2,41],{44:[1,54]}),t(T,[2,33]),{40:55,51:p},{51:[2,51]},t(e,[2,36],{46:[1,56]}),t(e,[2,37]),t(e,[2,39],{45:[1,57]}),{11:[1,58]},t(e,[2,38]),t(e,[2,40]),t(T,[2,34])],defaultActions:{5:[2,49],6:[2,1],42:[2,52],51:[2,51]},parseError:function(o,u){if(u.recoverable)this.trace(o);else{var h=new Error(o);throw h.hash=u,h}},parse:function(o){var u=this,h=[0],d=[],a=[null],i=[],C=this.table,r="",D=0,F=0,A=2,$=1,tt=i.slice.call(arguments,1),L=Object.create(this.lexer),q={yy:{}};for(var et in this.yy)Object.prototype.hasOwnProperty.call(this.yy,et)&&(q.yy[et]=this.yy[et]);L.setInput(o,q.yy),q.yy.lexer=L,q.yy.parser=this,typeof L.yylloc=="undefined"&&(L.yylloc={});var it=L.yylloc;i.push(it);var ut=L.options&&L.options.ranges;typeof q.yy.parseError=="function"?this.parseError=q.yy.parseError:this.parseError=Object.getPrototypeOf(this).parseError;function Ut(){var J;return J=d.pop()||L.lex()||$,typeof J!="number"&&(J instanceof Array&&(d=J,J=d.pop()),J=u.symbols_[J]||J),J}for(var B,st,H,Tt,rt={},kt,Q,Zt,yt;;){if(st=h[h.length-1],this.defaultActions[st]?H=this.defaultActions[st]:((B===null||typeof B=="undefined")&&(B=Ut()),H=C[st]&&C[st][B]),typeof H=="undefined"||!H.length||!H[0]){var xt="";yt=[];for(kt in C[st])this.terminals_[kt]&&kt>A&&yt.push("'"+this.terminals_[kt]+"'");L.showPosition?xt="Parse error on line "+(D+1)+`:
`+L.showPosition()+`
Expecting `+yt.join(", ")+", got '"+(this.terminals_[B]||B)+"'":xt="Parse error on line "+(D+1)+": Unexpected "+(B==$?"end of input":"'"+(this.terminals_[B]||B)+"'"),this.parseError(xt,{text:L.match,token:this.terminals_[B]||B,line:L.yylineno,loc:it,expected:yt})}if(H[0]instanceof Array&&H.length>1)throw new Error("Parse Error: multiple actions possible at state: "+st+", token: "+B);switch(H[0]){case 1:h.push(B),a.push(L.yytext),i.push(L.yylloc),h.push(H[1]),B=null,F=L.yyleng,r=L.yytext,D=L.yylineno,it=L.yylloc;break;case 2:if(Q=this.productions_[H[1]][1],rt.$=a[a.length-Q],rt._$={first_line:i[i.length-(Q||1)].first_line,last_line:i[i.length-1].last_line,first_column:i[i.length-(Q||1)].first_column,last_column:i[i.length-1].last_column},ut&&(rt._$.range=[i[i.length-(Q||1)].range[0],i[i.length-1].range[1]]),Tt=this.performAction.apply(rt,[r,F,D,q.yy,H[1],a,i].concat(tt)),typeof Tt!="undefined")return Tt;Q&&(h=h.slice(0,-1*Q*2),a=a.slice(0,-1*Q),i=i.slice(0,-1*Q)),h.push(this.productions_[H[1]][0]),a.push(rt.$),i.push(rt._$),Zt=C[h[h.length-2]][h[h.length-1]],h.push(Zt);break;case 3:return!0}}return!0}},S=function(){var _={EOF:1,parseError:function(u,h){if(this.yy.parser)this.yy.parser.parseError(u,h);else throw new Error(u)},setInput:function(o,u){return this.yy=u||this.yy||{},this._input=o,this._more=this._backtrack=this.done=!1,this.yylineno=this.yyleng=0,this.yytext=this.matched=this.match="",this.conditionStack=["INITIAL"],this.yylloc={first_line:1,first_column:0,last_line:1,last_column:0},this.options.ranges&&(this.yylloc.range=[0,0]),this.offset=0,this},input:function(){var o=this._input[0];this.yytext+=o,this.yyleng++,this.offset++,this.match+=o,this.matched+=o;var u=o.match(/(?:\r\n?|\n).*/g);return u?(this.yylineno++,this.yylloc.last_line++):this.yylloc.last_column++,this.options.ranges&&this.yylloc.range[1]++,this._input=this._input.slice(1),o},unput:function(o){var u=o.length,h=o.split(/(?:\r\n?|\n)/g);this._input=o+this._input,this.yytext=this.yytext.substr(0,this.yytext.length-u),this.offset-=u;var d=this.match.split(/(?:\r\n?|\n)/g);this.match=this.match.substr(0,this.match.length-1),this.matched=this.matched.substr(0,this.matched.length-1),h.length-1&&(this.yylineno-=h.length-1);var a=this.yylloc.range;return this.yylloc={first_line:this.yylloc.first_line,last_line:this.yylineno+1,first_column:this.yylloc.first_column,last_column:h?(h.length===d.length?this.yylloc.first_column:0)+d[d.length-h.length].length-h[0].length:this.yylloc.first_column-u},this.options.ranges&&(this.yylloc.range=[a[0],a[0]+this.yyleng-u]),this.yyleng=this.yytext.length,this},more:function(){return this._more=!0,this},reject:function(){if(this.options.backtrack_lexer)this._backtrack=!0;else return this.parseError("Lexical error on line "+(this.yylineno+1)+`. You can only invoke reject() in the lexer when the lexer is of the backtracking persuasion (options.backtrack_lexer = true).
`+this.showPosition(),{text:"",token:null,line:this.yylineno});return this},less:function(o){this.unput(this.match.slice(o))},pastInput:function(){var o=this.matched.substr(0,this.matched.length-this.match.length);return(o.length>20?"...":"")+o.substr(-20).replace(/\n/g,"")},upcomingInput:function(){var o=this.match;return o.length<20&&(o+=this._input.substr(0,20-o.length)),(o.substr(0,20)+(o.length>20?"...":"")).replace(/\n/g,"")},showPosition:function(){var o=this.pastInput(),u=new Array(o.length+1).join("-");return o+this.upcomingInput()+`
`+u+"^"},test_match:function(o,u){var h,d,a;if(this.options.backtrack_lexer&&(a={yylineno:this.yylineno,yylloc:{first_line:this.yylloc.first_line,last_line:this.last_line,first_column:this.yylloc.first_column,last_column:this.yylloc.last_column},yytext:this.yytext,match:this.match,matches:this.matches,matched:this.matched,yyleng:this.yyleng,offset:this.offset,_more:this._more,_input:this._input,yy:this.yy,conditionStack:this.conditionStack.slice(0),done:this.done},this.options.ranges&&(a.yylloc.range=this.yylloc.range.slice(0))),d=o[0].match(/(?:\r\n?|\n).*/g),d&&(this.yylineno+=d.length),this.yylloc={first_line:this.yylloc.last_line,last_line:this.yylineno+1,first_column:this.yylloc.last_column,last_column:d?d[d.length-1].length-d[d.length-1].match(/\r?\n?/)[0].length:this.yylloc.last_column+o[0].length},this.yytext+=o[0],this.match+=o[0],this.matches=o,this.yyleng=this.yytext.length,this.options.ranges&&(this.yylloc.range=[this.offset,this.offset+=this.yyleng]),this._more=!1,this._backtrack=!1,this._input=this._input.slice(o[0].length),this.matched+=o[0],h=this.performAction.call(this,this.yy,this,u,this.conditionStack[this.conditionStack.length-1]),this.done&&this._input&&(this.done=!1),h)return h;if(this._backtrack){for(var i in a)this[i]=a[i];return!1}return!1},next:function(){if(this.done)return this.EOF;this._input||(this.done=!0);var o,u,h,d;this._more||(this.yytext="",this.match="");for(var a=this._currentRules(),i=0;i<a.length;i++)if(h=this._input.match(this.rules[a[i]]),h&&(!u||h[0].length>u[0].length)){if(u=h,d=i,this.options.backtrack_lexer){if(o=this.test_match(h,a[i]),o!==!1)return o;if(this._backtrack){u=!1;continue}else return!1}else if(!this.options.flex)break}return u?(o=this.test_match(u,a[d]),o!==!1?o:!1):this._input===""?this.EOF:this.parseError("Lexical error on line "+(this.yylineno+1)+`. Unrecognized text.
`+this.showPosition(),{text:"",token:null,line:this.yylineno})},lex:function(){var u=this.next();return u||this.lex()},begin:function(u){this.conditionStack.push(u)},popState:function(){var u=this.conditionStack.length-1;return u>0?this.conditionStack.pop():this.conditionStack[0]},_currentRules:function(){return this.conditionStack.length&&this.conditionStack[this.conditionStack.length-1]?this.conditions[this.conditionStack[this.conditionStack.length-1]].rules:this.conditions.INITIAL.rules},topState:function(u){return u=this.conditionStack.length-1-Math.abs(u||0),u>=0?this.conditionStack[u]:"INITIAL"},pushState:function(u){this.begin(u)},stateStackSize:function(){return this.conditionStack.length},options:{"case-insensitive":!0},performAction:function(u,h,d,a){switch(d){case 0:return this.begin("open_directive"),48;case 1:return this.begin("type_directive"),49;case 2:return this.popState(),this.begin("arg_directive"),41;case 3:return this.popState(),this.popState(),51;case 4:return 50;case 5:return this.begin("acc_title"),29;case 6:return this.popState(),"acc_title_value";case 7:return this.begin("acc_descr"),31;case 8:return this.popState(),"acc_descr_value";case 9:this.begin("acc_descr_multiline");break;case 10:this.popState();break;case 11:return"acc_descr_multiline_value";case 12:break;case 13:break;case 14:break;case 15:return 11;case 16:break;case 17:break;case 18:break;case 19:this.begin("href");break;case 20:this.popState();break;case 21:return 46;case 22:this.begin("callbackname");break;case 23:this.popState();break;case 24:this.popState(),this.begin("callbackargs");break;case 25:return 44;case 26:this.popState();break;case 27:return 45;case 28:this.begin("click");break;case 29:this.popState();break;case 30:return 43;case 31:return 5;case 32:return 20;case 33:return 21;case 34:return 22;case 35:return 23;case 36:return 24;case 37:return 26;case 38:return 25;case 39:return 27;case 40:return 13;case 41:return 14;case 42:return 15;case 43:return 16;case 44:return 17;case 45:return 18;case 46:return 19;case 47:return"date";case 48:return 28;case 49:return"accDescription";case 50:return 34;case 51:return 36;case 52:return 37;case 53:return 41;case 54:return 7;case 55:return"INVALID"}},rules:[/^(?:%%\{)/i,/^(?:((?:(?!\}%%)[^:.])*))/i,/^(?::)/i,/^(?:\}%%)/i,/^(?:((?:(?!\}%%).|\n)*))/i,/^(?:accTitle\s*:\s*)/i,/^(?:(?!\n||)*[^\n]*)/i,/^(?:accDescr\s*:\s*)/i,/^(?:(?!\n||)*[^\n]*)/i,/^(?:accDescr\s*\{\s*)/i,/^(?:[\}])/i,/^(?:[^\}]*)/i,/^(?:%%(?!\{)*[^\n]*)/i,/^(?:[^\}]%%*[^\n]*)/i,/^(?:%%*[^\n]*[\n]*)/i,/^(?:[\n]+)/i,/^(?:\s+)/i,/^(?:#[^\n]*)/i,/^(?:%[^\n]*)/i,/^(?:href[\s]+["])/i,/^(?:["])/i,/^(?:[^"]*)/i,/^(?:call[\s]+)/i,/^(?:\([\s]*\))/i,/^(?:\()/i,/^(?:[^(]*)/i,/^(?:\))/i,/^(?:[^)]*)/i,/^(?:click[\s]+)/i,/^(?:[\s\n])/i,/^(?:[^\s\n]*)/i,/^(?:gantt\b)/i,/^(?:dateFormat\s[^#\n;]+)/i,/^(?:inclusiveEndDates\b)/i,/^(?:topAxis\b)/i,/^(?:axisFormat\s[^#\n;]+)/i,/^(?:tickInterval\s[^#\n;]+)/i,/^(?:includes\s[^#\n;]+)/i,/^(?:excludes\s[^#\n;]+)/i,/^(?:todayMarker\s[^\n;]+)/i,/^(?:weekday\s+monday\b)/i,/^(?:weekday\s+tuesday\b)/i,/^(?:weekday\s+wednesday\b)/i,/^(?:weekday\s+thursday\b)/i,/^(?:weekday\s+friday\b)/i,/^(?:weekday\s+saturday\b)/i,/^(?:weekday\s+sunday\b)/i,/^(?:\d\d\d\d-\d\d-\d\d\b)/i,/^(?:title\s[^#\n;]+)/i,/^(?:accDescription\s[^#\n;]+)/i,/^(?:section\s[^#:\n;]+)/i,/^(?:[^#:\n;]+)/i,/^(?::[^#\n;]+)/i,/^(?::)/i,/^(?:$)/i,/^(?:.)/i],conditions:{acc_descr_multiline:{rules:[10,11],inclusive:!1},acc_descr:{rules:[8],inclusive:!1},acc_title:{rules:[6],inclusive:!1},close_directive:{rules:[],inclusive:!1},arg_directive:{rules:[3,4],inclusive:!1},type_directive:{rules:[2,3],inclusive:!1},open_directive:{rules:[1],inclusive:!1},callbackargs:{rules:[26,27],inclusive:!1},callbackname:{rules:[23,24,25],inclusive:!1},href:{rules:[20,21],inclusive:!1},click:{rules:[29,30],inclusive:!1},INITIAL:{rules:[0,5,7,9,12,13,14,15,16,17,18,19,22,28,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55],inclusive:!0}}};return _}();m.lexer=S;function w(){this.yy={}}return w.prototype=m,m.Parser=w,new w}();Wt.parser=Wt;var Re=Wt;R.default.extend(Ce.default);R.default.extend(Ee.default);R.default.extend(Me.default);var Z="",Pt="",Nt,Bt="",ft=[],ht=[],Rt={},jt=[],bt=[],ot="",Gt="",Ae=["active","done","crit","milestone"],Ht=[],mt=!1,Xt=!1,qt="sunday",zt=0,je=function(t,c,s){be.parseDirective(this,t,c,s)},Ge=function(){jt=[],bt=[],ot="",Ht=[],pt=0,Ot=void 0,vt=void 0,W=[],Z="",Pt="",Gt="",Nt=void 0,Bt="",ft=[],ht=[],mt=!1,Xt=!1,zt=0,Rt={},he(),qt="sunday"},He=function(t){Pt=t},Xe=function(){return Pt},qe=function(t){Nt=t},Ue=function(){return Nt},Ze=function(t){Bt=t},Qe=function(){return Bt},Je=function(t){Z=t},Ke=function(){mt=!0},$e=function(){return mt},ti=function(){Xt=!0},ei=function(){return Xt},ii=function(t){Gt=t},si=function(){return Gt},ni=function(){return Z},ri=function(t){ft=t.toLowerCase().split(/[\s,]+/)},ai=function(){return ft},ci=function(t){ht=t.toLowerCase().split(/[\s,]+/)},oi=function(){return ht},li=function(){return Rt},ui=function(t){ot=t,jt.push(t)},di=function(){return jt},fi=function(){let t=we(),c=10,s=0;for(;!t&&s<c;)t=we(),s++;return bt=W,bt},Le=function(t,c,s,e){return e.includes(t.format(c.trim()))?!1:t.isoWeekday()>=6&&s.includes("weekends")||s.includes(t.format("dddd").toLowerCase())?!0:s.includes(t.format(c.trim()))},hi=function(t){qt=t},mi=function(){return qt},Ie=function(t,c,s,e){if(!s.length||t.manualEndTime)return;let n;t.startTime instanceof Date?n=(0,R.default)(t.startTime):n=(0,R.default)(t.startTime,c,!0),n=n.add(1,"d");let l;t.endTime instanceof Date?l=(0,R.default)(t.endTime):l=(0,R.default)(t.endTime,c,!0);let[f,v]=ki(n,l,c,s,e);t.endTime=f.toDate(),t.renderEndTime=v},ki=function(t,c,s,e,n){let l=!1,f=null;for(;t<=c;)l||(f=c.toDate()),l=Le(t,s,e,n),l&&(c=c.add(1,"d")),t=t.add(1,"d");return[c,f]},Vt=function(t,c,s){s=s.trim();let n=/^after\s+([\d\w- ]+)/.exec(s.trim());if(n!==null){let f=null;if(n[1].split(" ").forEach(function(v){let E=lt(v);E!==void 0&&(f?E.endTime>f.endTime&&(f=E):f=E)}),f)return f.endTime;{let v=new Date;return v.setHours(0,0,0,0),v}}let l=(0,R.default)(s,c.trim(),!0);if(l.isValid())return l.toDate();{gt.debug("Invalid date:"+s),gt.debug("With date format:"+c.trim());let f=new Date(s);if(f===void 0||isNaN(f.getTime())||f.getFullYear()<-1e4||f.getFullYear()>1e4)throw new Error("Invalid date:"+s);return f}},Ye=function(t){let c=/^(\d+(?:\.\d+)?)([Mdhmswy]|ms)$/.exec(t.trim());return c!==null?[Number.parseFloat(c[1]),c[2]]:[NaN,"ms"]},Fe=function(t,c,s,e=!1){s=s.trim();let n=(0,R.default)(s,c.trim(),!0);if(n.isValid())return e&&(n=n.add(1,"d")),n.toDate();let l=(0,R.default)(t),[f,v]=Ye(s);if(!Number.isNaN(f)){let E=l.add(f,v);E.isValid()&&(l=E)}return l.toDate()},pt=0,ct=function(t){return t===void 0?(pt=pt+1,"task"+pt):t},yi=function(t,c){let s;c.substr(0,1)===":"?s=c.substr(1,c.length):s=c;let e=s.split(","),n={};Oe(e,n,Ae);for(let f=0;f<e.length;f++)e[f]=e[f].trim();let l="";switch(e.length){case 1:n.id=ct(),n.startTime=t.endTime,l=e[0];break;case 2:n.id=ct(),n.startTime=Vt(void 0,Z,e[0]),l=e[1];break;case 3:n.id=ct(e[0]),n.startTime=Vt(void 0,Z,e[1]),l=e[2];break}return l&&(n.endTime=Fe(n.startTime,Z,l,mt),n.manualEndTime=(0,R.default)(l,"YYYY-MM-DD",!0).isValid(),Ie(n,Z,ht,ft)),n},gi=function(t,c){let s;c.substr(0,1)===":"?s=c.substr(1,c.length):s=c;let e=s.split(","),n={};Oe(e,n,Ae);for(let l=0;l<e.length;l++)e[l]=e[l].trim();switch(e.length){case 1:n.id=ct(),n.startTime={type:"prevTaskEnd",id:t},n.endTime={data:e[0]};break;case 2:n.id=ct(),n.startTime={type:"getStartDate",startData:e[0]},n.endTime={data:e[1]};break;case 3:n.id=ct(e[0]),n.startTime={type:"getStartDate",startData:e[1]},n.endTime={data:e[2]};break}return n},Ot,vt,W=[],We={},pi=function(t,c){let s={section:ot,type:ot,processed:!1,manualEndTime:!1,renderEndTime:null,raw:{data:c},task:t,classes:[]},e=gi(vt,c);s.raw.startTime=e.startTime,s.raw.endTime=e.endTime,s.id=e.id,s.prevTaskId=vt,s.active=e.active,s.done=e.done,s.crit=e.crit,s.milestone=e.milestone,s.order=zt,zt++;let n=W.push(s);vt=s.id,We[s.id]=n-1},lt=function(t){let c=We[t];return W[c]},vi=function(t,c){let s={section:ot,type:ot,description:t,task:t,classes:[]},e=yi(Ot,c);s.startTime=e.startTime,s.endTime=e.endTime,s.id=e.id,s.active=e.active,s.done=e.done,s.crit=e.crit,s.milestone=e.milestone,Ot=s,bt.push(s)},we=function(){let t=function(s){let e=W[s],n="";switch(W[s].raw.startTime.type){case"prevTaskEnd":{let l=lt(e.prevTaskId);e.startTime=l.endTime;break}case"getStartDate":n=Vt(void 0,Z,W[s].raw.startTime.startData),n&&(W[s].startTime=n);break}return W[s].startTime&&(W[s].endTime=Fe(W[s].startTime,Z,W[s].raw.endTime.data,mt),W[s].endTime&&(W[s].processed=!0,W[s].manualEndTime=(0,R.default)(W[s].raw.endTime.data,"YYYY-MM-DD",!0).isValid(),Ie(W[s],Z,ht,ft))),W[s].processed},c=!0;for(let[s,e]of W.entries())t(s),c=c&&e.processed;return c},bi=function(t,c){let s=c;nt().securityLevel!=="loose"&&(s=(0,Se.sanitizeUrl)(c)),t.split(",").forEach(function(e){lt(e)!==void 0&&(Ve(e,()=>{window.open(s,"_self")}),Rt[e]=s)}),ze(t,"clickable")},ze=function(t,c){t.split(",").forEach(function(s){let e=lt(s);e!==void 0&&e.classes.push(c)})},Ti=function(t,c,s){if(nt().securityLevel!=="loose"||c===void 0)return;let e=[];if(typeof s=="string"){e=s.split(/,(?=(?:(?:[^"]*"){2})*[^"]*$)/);for(let l=0;l<e.length;l++){let f=e[l].trim();f.charAt(0)==='"'&&f.charAt(f.length-1)==='"'&&(f=f.substr(1,f.length-2)),e[l]=f}}e.length===0&&e.push(t),lt(t)!==void 0&&Ve(t,()=>{de.runFunc(c,...e)})},Ve=function(t,c){Ht.push(function(){let s=document.querySelector(`[id="${t}"]`);s!==null&&s.addEventListener("click",function(){c()})},function(){let s=document.querySelector(`[id="${t}-text"]`);s!==null&&s.addEventListener("click",function(){c()})})},xi=function(t,c,s){t.split(",").forEach(function(e){Ti(e,c,s)}),ze(t,"clickable")},_i=function(t){Ht.forEach(function(c){c(t)})},wi={parseDirective:je,getConfig:()=>nt().gantt,clear:Ge,setDateFormat:Je,getDateFormat:ni,enableInclusiveEndDates:Ke,endDatesAreInclusive:$e,enableTopAxis:ti,topAxisEnabled:ei,setAxisFormat:He,getAxisFormat:Xe,setTickInterval:qe,getTickInterval:Ue,setTodayMarker:Ze,getTodayMarker:Qe,setAccTitle:me,getAccTitle:ke,setDiagramTitle:pe,getDiagramTitle:ve,setDisplayMode:ii,getDisplayMode:si,setAccDescription:ye,getAccDescription:ge,addSection:ui,getSections:di,getTasks:fi,addTask:pi,findTaskById:lt,addTaskOrg:vi,setIncludes:ri,getIncludes:ai,setExcludes:ci,getExcludes:oi,setClickEvent:xi,setLink:bi,getLinks:li,bindFunctions:_i,parseDuration:Ye,isInvalidDate:Le,setWeekday:hi,getWeekday:mi};function Oe(t,c,s){let e=!0;for(;e;)e=!1,s.forEach(function(n){let l="^\\s*"+n+"\\s*$",f=new RegExp(l);t[0].match(f)&&(c[n]=!0,t.shift(1),e=!0)})}var Di=function(){gt.debug("Something is calling, setConf, remove the call")},De={monday:se,tuesday:ne,wednesday:re,thursday:ae,friday:ce,saturday:oe,sunday:ie},Si=(t,c)=>{let s=[...t].map(()=>-1/0),e=[...t].sort((l,f)=>l.startTime-f.startTime||l.order-f.order),n=0;for(let l of e)for(let f=0;f<s.length;f++)if(l.startTime>=s[f]){s[f]=l.endTime,l.order=f+c,f>n&&(n=f);break}return n},K,Ci=function(t,c,s,e){let n=nt().gantt,l=nt().securityLevel,f;l==="sandbox"&&(f=dt("#i"+c));let v=l==="sandbox"?dt(f.nodes()[0].contentDocument.body):dt("body"),E=l==="sandbox"?f.nodes()[0].contentDocument:document,I=E.getElementById(c);K=I.parentElement.offsetWidth,K===void 0&&(K=1200),n.useWidth!==void 0&&(K=n.useWidth);let Y=e.db.getTasks(),z=[];for(let k of Y)z.push(k.type);z=G(z);let X={},g=2*n.topPadding;if(e.db.getDisplayMode()==="compact"||n.displayMode==="compact"){let k={};for(let p of Y)k[p.section]===void 0?k[p.section]=[p]:k[p.section].push(p);let b=0;for(let p of Object.keys(k)){let T=Si(k[p],b)+1;b+=T,g+=T*(n.barHeight+n.barGap),X[p]=T}}else{g+=Y.length*(n.barHeight+n.barGap);for(let k of z)X[k]=Y.filter(b=>b.type===k).length}I.setAttribute("viewBox","0 0 "+K+" "+g);let x=v.select(`[id="${c}"]`),y=le().domain([Jt(Y,function(k){return k.startTime}),Qt(Y,function(k){return k.endTime})]).rangeRound([0,K-n.leftPadding-n.rightPadding]);function M(k,b){let p=k.startTime,T=b.startTime,m=0;return p>T?m=1:p<T&&(m=-1),m}Y.sort(M),V(Y,K,g),fe(x,g,K,n.useMaxWidth),x.append("text").text(e.db.getDiagramTitle()).attr("x",K/2).attr("y",n.titleTopMargin).attr("class","titleText");function V(k,b,p){let T=n.barHeight,m=T+n.barGap,S=n.topPadding,w=n.leftPadding,_=ee().domain([0,z.length]).range(["#00B9FA","#F95002"]).interpolate(te);U(m,S,w,b,p,k,e.db.getExcludes(),e.db.getIncludes()),j(w,S,b,p),O(k,m,S,w,T,_,b),P(m,S),N(w,S,b,p)}function O(k,b,p,T,m,S,w){let o=[...new Set(k.map(a=>a.order))].map(a=>k.find(i=>i.order===a));x.append("g").selectAll("rect").data(o).enter().append("rect").attr("x",0).attr("y",function(a,i){return i=a.order,i*b+p-2}).attr("width",function(){return w-n.rightPadding/2}).attr("height",b).attr("class",function(a){for(let[i,C]of z.entries())if(a.type===C)return"section section"+i%n.numberSectionStyles;return"section section0"});let u=x.append("g").selectAll("rect").data(k).enter(),h=e.db.getLinks();if(u.append("rect").attr("id",function(a){return a.id}).attr("rx",3).attr("ry",3).attr("x",function(a){return a.milestone?y(a.startTime)+T+.5*(y(a.endTime)-y(a.startTime))-.5*m:y(a.startTime)+T}).attr("y",function(a,i){return i=a.order,i*b+p}).attr("width",function(a){return a.milestone?m:y(a.renderEndTime||a.endTime)-y(a.startTime)}).attr("height",m).attr("transform-origin",function(a,i){return i=a.order,(y(a.startTime)+T+.5*(y(a.endTime)-y(a.startTime))).toString()+"px "+(i*b+p+.5*m).toString()+"px"}).attr("class",function(a){let i="task",C="";a.classes.length>0&&(C=a.classes.join(" "));let r=0;for(let[F,A]of z.entries())a.type===A&&(r=F%n.numberSectionStyles);let D="";return a.active?a.crit?D+=" activeCrit":D=" active":a.done?a.crit?D=" doneCrit":D=" done":a.crit&&(D+=" crit"),D.length===0&&(D=" task"),a.milestone&&(D=" milestone "+D),D+=r,D+=" "+C,i+D}),u.append("text").attr("id",function(a){return a.id+"-text"}).text(function(a){return a.task}).attr("font-size",n.fontSize).attr("x",function(a){let i=y(a.startTime),C=y(a.renderEndTime||a.endTime);a.milestone&&(i+=.5*(y(a.endTime)-y(a.startTime))-.5*m),a.milestone&&(C=i+m);let r=this.getBBox().width;return r>C-i?C+r+1.5*n.leftPadding>w?i+T-5:C+T+5:(C-i)/2+i+T}).attr("y",function(a,i){return i=a.order,i*b+n.barHeight/2+(n.fontSize/2-2)+p}).attr("text-height",m).attr("class",function(a){let i=y(a.startTime),C=y(a.endTime);a.milestone&&(C=i+m);let r=this.getBBox().width,D="";a.classes.length>0&&(D=a.classes.join(" "));let F=0;for(let[$,tt]of z.entries())a.type===tt&&(F=$%n.numberSectionStyles);let A="";return a.active&&(a.crit?A="activeCritText"+F:A="activeText"+F),a.done?a.crit?A=A+" doneCritText"+F:A=A+" doneText"+F:a.crit&&(A=A+" critText"+F),a.milestone&&(A+=" milestoneText"),r>C-i?C+r+1.5*n.leftPadding>w?D+" taskTextOutsideLeft taskTextOutside"+F+" "+A:D+" taskTextOutsideRight taskTextOutside"+F+" "+A+" width-"+r:D+" taskText taskText"+F+" "+A+" width-"+r}),nt().securityLevel==="sandbox"){let a;a=dt("#i"+c);let i=a.nodes()[0].contentDocument;u.filter(function(C){return h[C.id]!==void 0}).each(function(C){var r=i.querySelector("#"+C.id),D=i.querySelector("#"+C.id+"-text");let F=r.parentNode;var A=i.createElement("a");A.setAttribute("xlink:href",h[C.id]),A.setAttribute("target","_top"),F.appendChild(A),A.appendChild(r),A.appendChild(D)})}}function U(k,b,p,T,m,S,w,_){let o=S.reduce((r,{startTime:D})=>r?Math.min(r,D):D,0),u=S.reduce((r,{endTime:D})=>r?Math.max(r,D):D,0),h=e.db.getDateFormat();if(!o||!u)return;let d=[],a=null,i=(0,R.default)(o);for(;i.valueOf()<=u;)e.db.isInvalidDate(i,h,w,_)?a?a.end=i:a={start:i,end:i}:a&&(d.push(a),a=null),i=i.add(1,"d");x.append("g").selectAll("rect").data(d).enter().append("rect").attr("id",function(r){return"exclude-"+r.start.format("YYYY-MM-DD")}).attr("x",function(r){return y(r.start)+p}).attr("y",n.gridLineStartPadding).attr("width",function(r){let D=r.end.add(1,"day");return y(D)-y(r.start)}).attr("height",m-b-n.gridLineStartPadding).attr("transform-origin",function(r,D){return(y(r.start)+p+.5*(y(r.end)-y(r.start))).toString()+"px "+(D*k+.5*m).toString()+"px"}).attr("class","exclude-range")}function j(k,b,p,T){let m=$t(y).tickSize(-T+b+n.gridLineStartPadding).tickFormat(Et(e.db.getAxisFormat()||n.axisFormat||"%Y-%m-%d")),w=/^([1-9]\d*)(minute|hour|day|week|month)$/.exec(e.db.getTickInterval()||n.tickInterval);if(w!==null){let _=w[1],o=w[2],u=e.db.getWeekday()||n.weekday;switch(o){case"minute":m.ticks(wt.every(_));break;case"hour":m.ticks(Dt.every(_));break;case"day":m.ticks(St.every(_));break;case"week":m.ticks(De[u].every(_));break;case"month":m.ticks(Ct.every(_));break}}if(x.append("g").attr("class","grid").attr("transform","translate("+k+", "+(T-50)+")").call(m).selectAll("text").style("text-anchor","middle").attr("fill","#000").attr("stroke","none").attr("font-size",10).attr("dy","1em"),e.db.topAxisEnabled()||n.topAxis){let _=Kt(y).tickSize(-T+b+n.gridLineStartPadding).tickFormat(Et(e.db.getAxisFormat()||n.axisFormat||"%Y-%m-%d"));if(w!==null){let o=w[1],u=w[2],h=e.db.getWeekday()||n.weekday;switch(u){case"minute":_.ticks(wt.every(o));break;case"hour":_.ticks(Dt.every(o));break;case"day":_.ticks(St.every(o));break;case"week":_.ticks(De[h].every(o));break;case"month":_.ticks(Ct.every(o));break}}x.append("g").attr("class","grid").attr("transform","translate("+k+", "+b+")").call(_).selectAll("text").style("text-anchor","middle").attr("fill","#000").attr("stroke","none").attr("font-size",10)}}function P(k,b){let p=0,T=Object.keys(X).map(m=>[m,X[m]]);x.append("g").selectAll("text").data(T).enter().append(function(m){let S=m[0].split(ue.lineBreakRegex),w=-(S.length-1)/2,_=E.createElementNS("http://www.w3.org/2000/svg","text");_.setAttribute("dy",w+"em");for(let[o,u]of S.entries()){let h=E.createElementNS("http://www.w3.org/2000/svg","tspan");h.setAttribute("alignment-baseline","central"),h.setAttribute("x","10"),o>0&&h.setAttribute("dy","1em"),h.textContent=u,_.appendChild(h)}return _}).attr("x",10).attr("y",function(m,S){if(S>0)for(let w=0;w<S;w++)return p+=T[S-1][1],m[1]*k/2+p*k+b;else return m[1]*k/2+b}).attr("font-size",n.sectionFontSize).attr("class",function(m){for(let[S,w]of z.entries())if(m[0]===w)return"sectionTitle sectionTitle"+S%n.numberSectionStyles;return"sectionTitle"})}function N(k,b,p,T){let m=e.db.getTodayMarker();if(m==="off")return;let S=x.append("g").attr("class","today"),w=new Date,_=S.append("line");_.attr("x1",y(w)+k).attr("x2",y(w)+k).attr("y1",n.titleTopMargin).attr("y2",T-n.titleTopMargin).attr("class","today"),m!==""&&_.attr("style",m.replace(/,/g,";"))}function G(k){let b={},p=[];for(let T=0,m=k.length;T<m;++T)Object.prototype.hasOwnProperty.call(b,k[T])||(b[k[T]]=!0,p.push(k[T]));return p}},Ei={setConf:Di,draw:Ci},Mi=t=>`
  .mermaid-main-font {
    font-family: "trebuchet ms", verdana, arial, sans-serif;
    font-family: var(--mermaid-font-family);
  }
  .exclude-range {
    fill: ${t.excludeBkgColor};
  }

  .section {
    stroke: none;
    opacity: 0.2;
  }

  .section0 {
    fill: ${t.sectionBkgColor};
  }

  .section2 {
    fill: ${t.sectionBkgColor2};
  }

  .section1,
  .section3 {
    fill: ${t.altSectionBkgColor};
    opacity: 0.2;
  }

  .sectionTitle0 {
    fill: ${t.titleColor};
  }

  .sectionTitle1 {
    fill: ${t.titleColor};
  }

  .sectionTitle2 {
    fill: ${t.titleColor};
  }

  .sectionTitle3 {
    fill: ${t.titleColor};
  }

  .sectionTitle {
    text-anchor: start;
    // font-size: ${t.ganttFontSize};
    // text-height: 14px;
    font-family: 'trebuchet ms', verdana, arial, sans-serif;
    font-family: var(--mermaid-font-family);

  }


  /* Grid and axis */

  .grid .tick {
    stroke: ${t.gridColor};
    opacity: 0.8;
    shape-rendering: crispEdges;
    text {
      font-family: ${t.fontFamily};
      fill: ${t.textColor};
    }
  }

  .grid path {
    stroke-width: 0;
  }


  /* Today line */

  .today {
    fill: none;
    stroke: ${t.todayLineColor};
    stroke-width: 2px;
  }


  /* Task styling */

  /* Default task */

  .task {
    stroke-width: 2;
  }

  .taskText {
    text-anchor: middle;
    font-family: 'trebuchet ms', verdana, arial, sans-serif;
    font-family: var(--mermaid-font-family);
  }

  // .taskText:not([font-size]) {
  //   font-size: ${t.ganttFontSize};
  // }

  .taskTextOutsideRight {
    fill: ${t.taskTextDarkColor};
    text-anchor: start;
    // font-size: ${t.ganttFontSize};
    font-family: 'trebuchet ms', verdana, arial, sans-serif;
    font-family: var(--mermaid-font-family);

  }

  .taskTextOutsideLeft {
    fill: ${t.taskTextDarkColor};
    text-anchor: end;
    // font-size: ${t.ganttFontSize};
  }

  /* Special case clickable */
  .task.clickable {
    cursor: pointer;
  }
  .taskText.clickable {
    cursor: pointer;
    fill: ${t.taskTextClickableColor} !important;
    font-weight: bold;
  }

  .taskTextOutsideLeft.clickable {
    cursor: pointer;
    fill: ${t.taskTextClickableColor} !important;
    font-weight: bold;
  }

  .taskTextOutsideRight.clickable {
    cursor: pointer;
    fill: ${t.taskTextClickableColor} !important;
    font-weight: bold;
  }

  /* Specific task settings for the sections*/

  .taskText0,
  .taskText1,
  .taskText2,
  .taskText3 {
    fill: ${t.taskTextColor};
  }

  .task0,
  .task1,
  .task2,
  .task3 {
    fill: ${t.taskBkgColor};
    stroke: ${t.taskBorderColor};
  }

  .taskTextOutside0,
  .taskTextOutside2
  {
    fill: ${t.taskTextOutsideColor};
  }

  .taskTextOutside1,
  .taskTextOutside3 {
    fill: ${t.taskTextOutsideColor};
  }


  /* Active task */

  .active0,
  .active1,
  .active2,
  .active3 {
    fill: ${t.activeTaskBkgColor};
    stroke: ${t.activeTaskBorderColor};
  }

  .activeText0,
  .activeText1,
  .activeText2,
  .activeText3 {
    fill: ${t.taskTextDarkColor} !important;
  }


  /* Completed task */

  .done0,
  .done1,
  .done2,
  .done3 {
    stroke: ${t.doneTaskBorderColor};
    fill: ${t.doneTaskBkgColor};
    stroke-width: 2;
  }

  .doneText0,
  .doneText1,
  .doneText2,
  .doneText3 {
    fill: ${t.taskTextDarkColor} !important;
  }


  /* Tasks on the critical line */

  .crit0,
  .crit1,
  .crit2,
  .crit3 {
    stroke: ${t.critBorderColor};
    fill: ${t.critBkgColor};
    stroke-width: 2;
  }

  .activeCrit0,
  .activeCrit1,
  .activeCrit2,
  .activeCrit3 {
    stroke: ${t.critBorderColor};
    fill: ${t.activeTaskBkgColor};
    stroke-width: 2;
  }

  .doneCrit0,
  .doneCrit1,
  .doneCrit2,
  .doneCrit3 {
    stroke: ${t.critBorderColor};
    fill: ${t.doneTaskBkgColor};
    stroke-width: 2;
    cursor: pointer;
    shape-rendering: crispEdges;
  }

  .milestone {
    transform: rotate(45deg) scale(0.8,0.8);
  }

  .milestoneText {
    font-style: italic;
  }
  .doneCritText0,
  .doneCritText1,
  .doneCritText2,
  .doneCritText3 {
    fill: ${t.taskTextDarkColor} !important;
  }

  .activeCritText0,
  .activeCritText1,
  .activeCritText2,
  .activeCritText3 {
    fill: ${t.taskTextDarkColor} !important;
  }

  .titleText {
    text-anchor: middle;
    font-size: 18px;
    fill: ${t.textColor}    ;
    font-family: 'trebuchet ms', verdana, arial, sans-serif;
    font-family: var(--mermaid-font-family);
  }
`,Ai=Mi,Wi={parser:Re,db:wi,renderer:Ei,styles:Ai};export{Wi as diagram};
