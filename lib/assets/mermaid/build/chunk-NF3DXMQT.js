import{a as jt}from"./chunk-ZN3EQT7J.js";import{a as Ht}from"./chunk-IHTGUX7V.js";import{b as Ut}from"./chunk-LAE32BEA.js";import{h as Wt}from"./chunk-NQPDPRKS.js";import{g as Vt,p as Mt}from"./chunk-N5E7CGZK.js";import{N as j,T as Nt,U as $t,V as Ft,W as Pt,X as Bt,Y as Yt,Z as Gt,_ as $,g as Rt}from"./chunk-HMJDPWRP.js";import{b as m,h as St}from"./chunk-DW4GERSH.js";import{a as p}from"./chunk-YUSHYV7C.js";var At=function(){var t=p(function(W,l,u,n){for(u=u||{},n=W.length;n--;u[W[n]]=l);return u},"o"),e=[1,2],s=[1,3],a=[1,4],r=[2,4],o=[1,9],h=[1,11],f=[1,16],d=[1,17],g=[1,18],E=[1,19],k=[1,33],F=[1,20],B=[1,21],R=[1,22],C=[1,23],D=[1,24],S=[1,26],A=[1,27],v=[1,28],Y=[1,29],w=[1,30],G=[1,31],P=[1,32],O=[1,35],J=[1,36],z=[1,37],lt=[1,38],q=[1,34],y=[1,4,5,16,17,19,21,22,24,25,26,27,28,29,33,35,37,38,41,45,48,51,52,53,54,57],ct=[1,4,5,14,15,16,17,19,21,22,24,25,26,27,28,29,33,35,37,38,39,40,41,45,48,51,52,53,54,57],wt=[4,5,16,17,19,21,22,24,25,26,27,28,29,33,35,37,38,41,45,48,51,52,53,54,57],bt={trace:p(function(){},"trace"),yy:{},symbols_:{error:2,start:3,SPACE:4,NL:5,SD:6,document:7,line:8,statement:9,classDefStatement:10,styleStatement:11,cssClassStatement:12,idStatement:13,DESCR:14,"-->":15,HIDE_EMPTY:16,scale:17,WIDTH:18,COMPOSIT_STATE:19,STRUCT_START:20,STRUCT_STOP:21,STATE_DESCR:22,AS:23,ID:24,FORK:25,JOIN:26,CHOICE:27,CONCURRENT:28,note:29,notePosition:30,NOTE_TEXT:31,direction:32,acc_title:33,acc_title_value:34,acc_descr:35,acc_descr_value:36,acc_descr_multiline_value:37,CLICK:38,STRING:39,HREF:40,classDef:41,CLASSDEF_ID:42,CLASSDEF_STYLEOPTS:43,DEFAULT:44,style:45,STYLE_IDS:46,STYLEDEF_STYLEOPTS:47,class:48,CLASSENTITY_IDS:49,STYLECLASS:50,direction_tb:51,direction_bt:52,direction_rl:53,direction_lr:54,eol:55,";":56,EDGE_STATE:57,STYLE_SEPARATOR:58,left_of:59,right_of:60,$accept:0,$end:1},terminals_:{2:"error",4:"SPACE",5:"NL",6:"SD",14:"DESCR",15:"-->",16:"HIDE_EMPTY",17:"scale",18:"WIDTH",19:"COMPOSIT_STATE",20:"STRUCT_START",21:"STRUCT_STOP",22:"STATE_DESCR",23:"AS",24:"ID",25:"FORK",26:"JOIN",27:"CHOICE",28:"CONCURRENT",29:"note",31:"NOTE_TEXT",33:"acc_title",34:"acc_title_value",35:"acc_descr",36:"acc_descr_value",37:"acc_descr_multiline_value",38:"CLICK",39:"STRING",40:"HREF",41:"classDef",42:"CLASSDEF_ID",43:"CLASSDEF_STYLEOPTS",44:"DEFAULT",45:"style",46:"STYLE_IDS",47:"STYLEDEF_STYLEOPTS",48:"class",49:"CLASSENTITY_IDS",50:"STYLECLASS",51:"direction_tb",52:"direction_bt",53:"direction_rl",54:"direction_lr",56:";",57:"EDGE_STATE",58:"STYLE_SEPARATOR",59:"left_of",60:"right_of"},productions_:[0,[3,2],[3,2],[3,2],[7,0],[7,2],[8,2],[8,1],[8,1],[9,1],[9,1],[9,1],[9,1],[9,2],[9,3],[9,4],[9,1],[9,2],[9,1],[9,4],[9,3],[9,6],[9,1],[9,1],[9,1],[9,1],[9,4],[9,4],[9,1],[9,2],[9,2],[9,1],[9,5],[9,5],[10,3],[10,3],[11,3],[12,3],[32,1],[32,1],[32,1],[32,1],[55,1],[55,1],[13,1],[13,1],[13,3],[13,3],[30,1],[30,1]],performAction:p(function(l,u,n,T,b,i,Q){var c=i.length-1;switch(b){case 3:return T.setRootDoc(i[c]),i[c];break;case 4:this.$=[];break;case 5:i[c]!="nl"&&(i[c-1].push(i[c]),this.$=i[c-1]);break;case 6:case 7:this.$=i[c];break;case 8:this.$="nl";break;case 12:this.$=i[c];break;case 13:let ut=i[c-1];ut.description=T.trimColon(i[c]),this.$=ut;break;case 14:this.$={stmt:"relation",state1:i[c-2],state2:i[c]};break;case 15:let dt=T.trimColon(i[c]);this.$={stmt:"relation",state1:i[c-3],state2:i[c-1],description:dt};break;case 19:this.$={stmt:"state",id:i[c-3],type:"default",description:"",doc:i[c-1]};break;case 20:var V=i[c],M=i[c-2].trim();if(i[c].match(":")){var rt=i[c].split(":");V=rt[0],M=[M,rt[1]]}this.$={stmt:"state",id:V,type:"default",description:M};break;case 21:this.$={stmt:"state",id:i[c-3],type:"default",description:i[c-5],doc:i[c-1]};break;case 22:this.$={stmt:"state",id:i[c],type:"fork"};break;case 23:this.$={stmt:"state",id:i[c],type:"join"};break;case 24:this.$={stmt:"state",id:i[c],type:"choice"};break;case 25:this.$={stmt:"state",id:T.getDividerId(),type:"divider"};break;case 26:this.$={stmt:"state",id:i[c-1].trim(),note:{position:i[c-2].trim(),text:i[c].trim()}};break;case 29:this.$=i[c].trim(),T.setAccTitle(this.$);break;case 30:case 31:this.$=i[c].trim(),T.setAccDescription(this.$);break;case 32:this.$={stmt:"click",id:i[c-3],url:i[c-2],tooltip:i[c-1]};break;case 33:this.$={stmt:"click",id:i[c-3],url:i[c-1],tooltip:""};break;case 34:case 35:this.$={stmt:"classDef",id:i[c-1].trim(),classes:i[c].trim()};break;case 36:this.$={stmt:"style",id:i[c-1].trim(),styleClass:i[c].trim()};break;case 37:this.$={stmt:"applyClass",id:i[c-1].trim(),styleClass:i[c].trim()};break;case 38:T.setDirection("TB"),this.$={stmt:"dir",value:"TB"};break;case 39:T.setDirection("BT"),this.$={stmt:"dir",value:"BT"};break;case 40:T.setDirection("RL"),this.$={stmt:"dir",value:"RL"};break;case 41:T.setDirection("LR"),this.$={stmt:"dir",value:"LR"};break;case 44:case 45:this.$={stmt:"state",id:i[c].trim(),type:"default",description:""};break;case 46:this.$={stmt:"state",id:i[c-2].trim(),classes:[i[c].trim()],type:"default",description:""};break;case 47:this.$={stmt:"state",id:i[c-2].trim(),classes:[i[c].trim()],type:"default",description:""};break}},"anonymous"),table:[{3:1,4:e,5:s,6:a},{1:[3]},{3:5,4:e,5:s,6:a},{3:6,4:e,5:s,6:a},t([1,4,5,16,17,19,22,24,25,26,27,28,29,33,35,37,38,41,45,48,51,52,53,54,57],r,{7:7}),{1:[2,1]},{1:[2,2]},{1:[2,3],4:o,5:h,8:8,9:10,10:12,11:13,12:14,13:15,16:f,17:d,19:g,22:E,24:k,25:F,26:B,27:R,28:C,29:D,32:25,33:S,35:A,37:v,38:Y,41:w,45:G,48:P,51:O,52:J,53:z,54:lt,57:q},t(y,[2,5]),{9:39,10:12,11:13,12:14,13:15,16:f,17:d,19:g,22:E,24:k,25:F,26:B,27:R,28:C,29:D,32:25,33:S,35:A,37:v,38:Y,41:w,45:G,48:P,51:O,52:J,53:z,54:lt,57:q},t(y,[2,7]),t(y,[2,8]),t(y,[2,9]),t(y,[2,10]),t(y,[2,11]),t(y,[2,12],{14:[1,40],15:[1,41]}),t(y,[2,16]),{18:[1,42]},t(y,[2,18],{20:[1,43]}),{23:[1,44]},t(y,[2,22]),t(y,[2,23]),t(y,[2,24]),t(y,[2,25]),{30:45,31:[1,46],59:[1,47],60:[1,48]},t(y,[2,28]),{34:[1,49]},{36:[1,50]},t(y,[2,31]),{13:51,24:k,57:q},{42:[1,52],44:[1,53]},{46:[1,54]},{49:[1,55]},t(ct,[2,44],{58:[1,56]}),t(ct,[2,45],{58:[1,57]}),t(y,[2,38]),t(y,[2,39]),t(y,[2,40]),t(y,[2,41]),t(y,[2,6]),t(y,[2,13]),{13:58,24:k,57:q},t(y,[2,17]),t(wt,r,{7:59}),{24:[1,60]},{24:[1,61]},{23:[1,62]},{24:[2,48]},{24:[2,49]},t(y,[2,29]),t(y,[2,30]),{39:[1,63],40:[1,64]},{43:[1,65]},{43:[1,66]},{47:[1,67]},{50:[1,68]},{24:[1,69]},{24:[1,70]},t(y,[2,14],{14:[1,71]}),{4:o,5:h,8:8,9:10,10:12,11:13,12:14,13:15,16:f,17:d,19:g,21:[1,72],22:E,24:k,25:F,26:B,27:R,28:C,29:D,32:25,33:S,35:A,37:v,38:Y,41:w,45:G,48:P,51:O,52:J,53:z,54:lt,57:q},t(y,[2,20],{20:[1,73]}),{31:[1,74]},{24:[1,75]},{39:[1,76]},{39:[1,77]},t(y,[2,34]),t(y,[2,35]),t(y,[2,36]),t(y,[2,37]),t(ct,[2,46]),t(ct,[2,47]),t(y,[2,15]),t(y,[2,19]),t(wt,r,{7:78}),t(y,[2,26]),t(y,[2,27]),{5:[1,79]},{5:[1,80]},{4:o,5:h,8:8,9:10,10:12,11:13,12:14,13:15,16:f,17:d,19:g,21:[1,81],22:E,24:k,25:F,26:B,27:R,28:C,29:D,32:25,33:S,35:A,37:v,38:Y,41:w,45:G,48:P,51:O,52:J,53:z,54:lt,57:q},t(y,[2,32]),t(y,[2,33]),t(y,[2,21])],defaultActions:{5:[2,1],6:[2,2],47:[2,48],48:[2,49]},parseError:p(function(l,u){if(u.recoverable)this.trace(l);else{var n=new Error(l);throw n.hash=u,n}},"parseError"),parse:p(function(l){var u=this,n=[0],T=[],b=[null],i=[],Q=this.table,c="",V=0,M=0,rt=0,ut=2,dt=1,pe=i.slice.call(arguments,1),_=Object.create(this.lexer),K={yy:{}};for(var Et in this.yy)Object.prototype.hasOwnProperty.call(this.yy,Et)&&(K.yy[Et]=this.yy[Et]);_.setInput(l,K.yy),K.yy.lexer=_,K.yy.parser=this,typeof _.yylloc=="undefined"&&(_.yylloc={});var kt=_.yylloc;i.push(kt);var Se=_.options&&_.options.ranges;typeof K.yy.parseError=="function"?this.parseError=K.yy.parseError:this.parseError=Object.getPrototypeOf(this).parseError;function ye(I){n.length=n.length-2*I,b.length=b.length-I,i.length=i.length-I}p(ye,"popStack");function Ot(){var I;return I=T.pop()||_.lex()||dt,typeof I!="number"&&(I instanceof Array&&(T=I,I=T.pop()),I=u.symbols_[I]||I),I}p(Ot,"lex");for(var x,mt,X,N,Me,_t,Z={},ft,U,It,pt;;){if(X=n[n.length-1],this.defaultActions[X]?N=this.defaultActions[X]:((x===null||typeof x=="undefined")&&(x=Ot()),N=Q[X]&&Q[X][x]),typeof N=="undefined"||!N.length||!N[0]){var Dt="";pt=[];for(ft in Q[X])this.terminals_[ft]&&ft>ut&&pt.push("'"+this.terminals_[ft]+"'");_.showPosition?Dt="Parse error on line "+(V+1)+`:
`+_.showPosition()+`
Expecting `+pt.join(", ")+", got '"+(this.terminals_[x]||x)+"'":Dt="Parse error on line "+(V+1)+": Unexpected "+(x==dt?"end of input":"'"+(this.terminals_[x]||x)+"'"),this.parseError(Dt,{text:_.match,token:this.terminals_[x]||x,line:_.yylineno,loc:kt,expected:pt})}if(N[0]instanceof Array&&N.length>1)throw new Error("Parse Error: multiple actions possible at state: "+X+", token: "+x);switch(N[0]){case 1:n.push(x),b.push(_.yytext),i.push(_.yylloc),n.push(N[1]),x=null,mt?(x=mt,mt=null):(M=_.yyleng,c=_.yytext,V=_.yylineno,kt=_.yylloc,rt>0&&rt--);break;case 2:if(U=this.productions_[N[1]][1],Z.$=b[b.length-U],Z._$={first_line:i[i.length-(U||1)].first_line,last_line:i[i.length-1].last_line,first_column:i[i.length-(U||1)].first_column,last_column:i[i.length-1].last_column},Se&&(Z._$.range=[i[i.length-(U||1)].range[0],i[i.length-1].range[1]]),_t=this.performAction.apply(Z,[c,M,V,K.yy,N[1],b,i].concat(pe)),typeof _t!="undefined")return _t;U&&(n=n.slice(0,-1*U*2),b=b.slice(0,-1*U),i=i.slice(0,-1*U)),n.push(this.productions_[N[1]][0]),b.push(Z.$),i.push(Z._$),It=Q[n[n.length-2]][n[n.length-1]],n.push(It);break;case 3:return!0}}return!0},"parse")},fe=function(){var W={EOF:1,parseError:p(function(u,n){if(this.yy.parser)this.yy.parser.parseError(u,n);else throw new Error(u)},"parseError"),setInput:p(function(l,u){return this.yy=u||this.yy||{},this._input=l,this._more=this._backtrack=this.done=!1,this.yylineno=this.yyleng=0,this.yytext=this.matched=this.match="",this.conditionStack=["INITIAL"],this.yylloc={first_line:1,first_column:0,last_line:1,last_column:0},this.options.ranges&&(this.yylloc.range=[0,0]),this.offset=0,this},"setInput"),input:p(function(){var l=this._input[0];this.yytext+=l,this.yyleng++,this.offset++,this.match+=l,this.matched+=l;var u=l.match(/(?:\r\n?|\n).*/g);return u?(this.yylineno++,this.yylloc.last_line++):this.yylloc.last_column++,this.options.ranges&&this.yylloc.range[1]++,this._input=this._input.slice(1),l},"input"),unput:p(function(l){var u=l.length,n=l.split(/(?:\r\n?|\n)/g);this._input=l+this._input,this.yytext=this.yytext.substr(0,this.yytext.length-u),this.offset-=u;var T=this.match.split(/(?:\r\n?|\n)/g);this.match=this.match.substr(0,this.match.length-1),this.matched=this.matched.substr(0,this.matched.length-1),n.length-1&&(this.yylineno-=n.length-1);var b=this.yylloc.range;return this.yylloc={first_line:this.yylloc.first_line,last_line:this.yylineno+1,first_column:this.yylloc.first_column,last_column:n?(n.length===T.length?this.yylloc.first_column:0)+T[T.length-n.length].length-n[0].length:this.yylloc.first_column-u},this.options.ranges&&(this.yylloc.range=[b[0],b[0]+this.yyleng-u]),this.yyleng=this.yytext.length,this},"unput"),more:p(function(){return this._more=!0,this},"more"),reject:p(function(){if(this.options.backtrack_lexer)this._backtrack=!0;else return this.parseError("Lexical error on line "+(this.yylineno+1)+`. You can only invoke reject() in the lexer when the lexer is of the backtracking persuasion (options.backtrack_lexer = true).
`+this.showPosition(),{text:"",token:null,line:this.yylineno});return this},"reject"),less:p(function(l){this.unput(this.match.slice(l))},"less"),pastInput:p(function(){var l=this.matched.substr(0,this.matched.length-this.match.length);return(l.length>20?"...":"")+l.substr(-20).replace(/\n/g,"")},"pastInput"),upcomingInput:p(function(){var l=this.match;return l.length<20&&(l+=this._input.substr(0,20-l.length)),(l.substr(0,20)+(l.length>20?"...":"")).replace(/\n/g,"")},"upcomingInput"),showPosition:p(function(){var l=this.pastInput(),u=new Array(l.length+1).join("-");return l+this.upcomingInput()+`
`+u+"^"},"showPosition"),test_match:p(function(l,u){var n,T,b;if(this.options.backtrack_lexer&&(b={yylineno:this.yylineno,yylloc:{first_line:this.yylloc.first_line,last_line:this.last_line,first_column:this.yylloc.first_column,last_column:this.yylloc.last_column},yytext:this.yytext,match:this.match,matches:this.matches,matched:this.matched,yyleng:this.yyleng,offset:this.offset,_more:this._more,_input:this._input,yy:this.yy,conditionStack:this.conditionStack.slice(0),done:this.done},this.options.ranges&&(b.yylloc.range=this.yylloc.range.slice(0))),T=l[0].match(/(?:\r\n?|\n).*/g),T&&(this.yylineno+=T.length),this.yylloc={first_line:this.yylloc.last_line,last_line:this.yylineno+1,first_column:this.yylloc.last_column,last_column:T?T[T.length-1].length-T[T.length-1].match(/\r?\n?/)[0].length:this.yylloc.last_column+l[0].length},this.yytext+=l[0],this.match+=l[0],this.matches=l,this.yyleng=this.yytext.length,this.options.ranges&&(this.yylloc.range=[this.offset,this.offset+=this.yyleng]),this._more=!1,this._backtrack=!1,this._input=this._input.slice(l[0].length),this.matched+=l[0],n=this.performAction.call(this,this.yy,this,u,this.conditionStack[this.conditionStack.length-1]),this.done&&this._input&&(this.done=!1),n)return n;if(this._backtrack){for(var i in b)this[i]=b[i];return!1}return!1},"test_match"),next:p(function(){if(this.done)return this.EOF;this._input||(this.done=!0);var l,u,n,T;this._more||(this.yytext="",this.match="");for(var b=this._currentRules(),i=0;i<b.length;i++)if(n=this._input.match(this.rules[b[i]]),n&&(!u||n[0].length>u[0].length)){if(u=n,T=i,this.options.backtrack_lexer){if(l=this.test_match(n,b[i]),l!==!1)return l;if(this._backtrack){u=!1;continue}else return!1}else if(!this.options.flex)break}return u?(l=this.test_match(u,b[T]),l!==!1?l:!1):this._input===""?this.EOF:this.parseError("Lexical error on line "+(this.yylineno+1)+`. Unrecognized text.
`+this.showPosition(),{text:"",token:null,line:this.yylineno})},"next"),lex:p(function(){var u=this.next();return u||this.lex()},"lex"),begin:p(function(u){this.conditionStack.push(u)},"begin"),popState:p(function(){var u=this.conditionStack.length-1;return u>0?this.conditionStack.pop():this.conditionStack[0]},"popState"),_currentRules:p(function(){return this.conditionStack.length&&this.conditionStack[this.conditionStack.length-1]?this.conditions[this.conditionStack[this.conditionStack.length-1]].rules:this.conditions.INITIAL.rules},"_currentRules"),topState:p(function(u){return u=this.conditionStack.length-1-Math.abs(u||0),u>=0?this.conditionStack[u]:"INITIAL"},"topState"),pushState:p(function(u){this.begin(u)},"pushState"),stateStackSize:p(function(){return this.conditionStack.length},"stateStackSize"),options:{"case-insensitive":!0},performAction:p(function(u,n,T,b){function i(){let c=n.yytext.indexOf("%%");if(c===0)return!1;if(c>0){let V=n.yytext.slice(0,c),M=n.yytext.slice(c);M&&u.lexer.unput(M),n.yytext=V}return!0}p(i,"processId");var Q=b;switch(T){case 0:return 38;case 1:return 40;case 2:return 39;case 3:return 44;case 4:return 51;case 5:return 52;case 6:return 53;case 7:return 54;case 8:return 5;case 9:break;case 10:break;case 11:break;case 12:break;case 13:return this.pushState("SCALE"),17;break;case 14:return 18;case 15:this.popState();break;case 16:return this.begin("acc_title"),33;break;case 17:return this.popState(),"acc_title_value";break;case 18:return this.begin("acc_descr"),35;break;case 19:return this.popState(),"acc_descr_value";break;case 20:this.begin("acc_descr_multiline");break;case 21:this.popState();break;case 22:return"acc_descr_multiline_value";case 23:return this.pushState("CLASSDEF"),41;break;case 24:return this.popState(),this.pushState("CLASSDEFID"),"DEFAULT_CLASSDEF_ID";break;case 25:return this.popState(),this.pushState("CLASSDEFID"),42;break;case 26:return this.popState(),43;break;case 27:return this.pushState("CLASS"),48;break;case 28:return this.popState(),this.pushState("CLASS_STYLE"),49;break;case 29:return this.popState(),50;break;case 30:return this.pushState("STYLE"),45;break;case 31:return this.popState(),this.pushState("STYLEDEF_STYLES"),46;break;case 32:return this.popState(),47;break;case 33:return this.pushState("SCALE"),17;break;case 34:return 18;case 35:this.popState();break;case 36:this.pushState("STATE");break;case 37:return this.popState(),n.yytext=n.yytext.slice(0,-8).trim(),25;break;case 38:return this.popState(),n.yytext=n.yytext.slice(0,-8).trim(),26;break;case 39:return this.popState(),n.yytext=n.yytext.slice(0,-10).trim(),27;break;case 40:return this.popState(),n.yytext=n.yytext.slice(0,-8).trim(),25;break;case 41:return this.popState(),n.yytext=n.yytext.slice(0,-8).trim(),26;break;case 42:return this.popState(),n.yytext=n.yytext.slice(0,-10).trim(),27;break;case 43:return 51;case 44:return 52;case 45:return 53;case 46:return 54;case 47:this.pushState("STATE_STRING");break;case 48:return this.pushState("STATE_ID"),"AS";break;case 49:if(!i())return;return this.popState(),"ID";break;case 50:this.popState();break;case 51:return"STATE_DESCR";case 52:throw new Error('Error: State name must be a single word. Found: "'+n.yytext.trim()+'"');case 53:return 19;case 54:this.popState();break;case 55:return this.popState(),this.pushState("struct"),20;break;case 56:return this.popState(),21;break;case 57:break;case 58:return this.begin("NOTE"),29;break;case 59:return this.popState(),this.pushState("NOTE_ID"),59;break;case 60:return this.popState(),this.pushState("NOTE_ID"),60;break;case 61:this.popState(),this.pushState("FLOATING_NOTE");break;case 62:return this.popState(),this.pushState("FLOATING_NOTE_ID"),"AS";break;case 63:break;case 64:return"NOTE_TEXT";case 65:if(!i())return;return this.popState(),"ID";break;case 66:if(!i())return;return this.popState(),this.pushState("NOTE_TEXT"),24;break;case 67:return this.popState(),n.yytext=n.yytext.substr(2).trim(),31;break;case 68:return this.popState(),n.yytext=n.yytext.slice(0,-8).trim(),31;break;case 69:return 6;case 70:return 6;case 71:return 16;case 72:return 57;case 73:return i()?24:void 0;case 74:return n.yytext=n.yytext.trim(),14;break;case 75:return 15;case 76:return 28;case 77:return 58;case 78:return 5;case 79:return"INVALID"}},"anonymous"),rules:[/^(?:click\b)/i,/^(?:href\b)/i,/^(?:"[^"]*")/i,/^(?:default\b)/i,/^(?:.*direction\s+TB[^\n]*)/i,/^(?:.*direction\s+BT[^\n]*)/i,/^(?:.*direction\s+RL[^\n]*)/i,/^(?:.*direction\s+LR[^\n]*)/i,/^(?:[\n]+)/i,/^(?:[\s]+)/i,/^(?:((?!\n)\s)+)/i,/^(?:#[^\n]*)/i,/^(?:%%(?!\{)[^\n]*)/i,/^(?:scale\s+)/i,/^(?:\d+)/i,/^(?:\s+width\b)/i,/^(?:accTitle\s*:\s*)/i,/^(?:(?!\n||)*[^\n]*)/i,/^(?:accDescr\s*:\s*)/i,/^(?:(?!\n||)*[^\n]*)/i,/^(?:accDescr\s*\{\s*)/i,/^(?:[\}])/i,/^(?:[^\}]*)/i,/^(?:classDef\s+)/i,/^(?:DEFAULT\s+)/i,/^(?:\w+\s+)/i,/^(?:[^\n]*)/i,/^(?:class\s+)/i,/^(?:(\w+)+((,\s*\w+)*))/i,/^(?:[^\n]*)/i,/^(?:style\s+)/i,/^(?:[\w,]+\s+)/i,/^(?:[^\n]*)/i,/^(?:scale\s+)/i,/^(?:\d+)/i,/^(?:\s+width\b)/i,/^(?:state\s+)/i,/^(?:.*<<fork>>)/i,/^(?:.*<<join>>)/i,/^(?:.*<<choice>>)/i,/^(?:.*\[\[fork\]\])/i,/^(?:.*\[\[join\]\])/i,/^(?:.*\[\[choice\]\])/i,/^(?:.*direction\s+TB[^\n]*)/i,/^(?:.*direction\s+BT[^\n]*)/i,/^(?:.*direction\s+RL[^\n]*)/i,/^(?:.*direction\s+LR[^\n]*)/i,/^(?:["])/i,/^(?:\s*as\s+)/i,/^(?:[^\n\{]*)/i,/^(?:["])/i,/^(?:[^"]*)/i,/^(?:\w+\s+\w+.*?\{)/i,/^(?:[^\n\s\{]+)/i,/^(?:\n)/i,/^(?:\{)/i,/^(?:\})/i,/^(?:[\n])/i,/^(?:note\s+)/i,/^(?:left of\b)/i,/^(?:right of\b)/i,/^(?:")/i,/^(?:\s*as\s*)/i,/^(?:["])/i,/^(?:[^"]*)/i,/^(?:[^\n]*)/i,/^(?:\s*[^:\n\s\-]+)/i,/^(?:\s*:[^:\n;]+)/i,/^(?:[\s\S]*?\n\s*end note\b)/i,/^(?:stateDiagram\s+)/i,/^(?:stateDiagram-v2\s+)/i,/^(?:hide empty description\b)/i,/^(?:\[\*\])/i,/^(?:[^:\n\s\-\{]+)/i,/^(?:\s*:(?:[^:\n;]|:[^:\n;])+)/i,/^(?:-->)/i,/^(?:--)/i,/^(?::::)/i,/^(?:$)/i,/^(?:.)/i],conditions:{LINE:{rules:[10,11,12],inclusive:!1},struct:{rules:[10,11,12,23,27,30,36,43,44,45,46,56,57,58,72,73,74,75,76,77],inclusive:!1},FLOATING_NOTE_ID:{rules:[65],inclusive:!1},FLOATING_NOTE:{rules:[62,63,64],inclusive:!1},NOTE_TEXT:{rules:[67,68],inclusive:!1},NOTE_ID:{rules:[66],inclusive:!1},NOTE:{rules:[59,60,61],inclusive:!1},STYLEDEF_STYLEOPTS:{rules:[],inclusive:!1},STYLEDEF_STYLES:{rules:[32],inclusive:!1},STYLE_IDS:{rules:[],inclusive:!1},STYLE:{rules:[31],inclusive:!1},CLASS_STYLE:{rules:[29],inclusive:!1},CLASS:{rules:[28],inclusive:!1},CLASSDEFID:{rules:[26],inclusive:!1},CLASSDEF:{rules:[24,25],inclusive:!1},acc_descr_multiline:{rules:[21,22],inclusive:!1},acc_descr:{rules:[19],inclusive:!1},acc_title:{rules:[17],inclusive:!1},SCALE:{rules:[14,15,34,35],inclusive:!1},ALIAS:{rules:[],inclusive:!1},STATE_ID:{rules:[49],inclusive:!1},STATE_STRING:{rules:[50,51],inclusive:!1},FORK_STATE:{rules:[],inclusive:!1},STATE:{rules:[10,11,12,37,38,39,40,41,42,47,48,52,53,54,55],inclusive:!1},ID:{rules:[10,11,12],inclusive:!1},INITIAL:{rules:[0,1,2,3,4,5,6,7,8,9,11,12,13,16,18,20,23,27,30,33,36,55,58,69,70,71,72,73,74,75,77,78,79],inclusive:!0}}};return W}();bt.lexer=fe;function ht(){this.yy={}}return p(ht,"Parser"),ht.prototype=bt,bt.Parser=ht,new ht}();At.parser=At;var qe=At,ge="TB",te="TB",zt="dir",et="state",tt="root",xt="relation",Te="classDef",be="style",Ee="applyClass",nt="default",ee="divider",se="fill:none",re="fill: #333",ie="c",ae="markdown",ne="normal",vt="rect",Ct="rectWithTitle",ke="stateStart",me="stateEnd",Kt="divider",Xt="roundedWithTitle",_e="note",De="noteGroup",ot="statediagram",ve="state",Ce=`${ot}-${ve}`,oe="transition",Ae="note",xe="note-edge",Le=`${oe} ${xe}`,we=`${ot}-${Ae}`,Oe="cluster",Ie=`${ot}-${Oe}`,Re="cluster-alt",Ne=`${ot}-${Re}`,le="parent",ce="note",$e="state",Lt="----",Fe=`${Lt}${ce}`,Jt=`${Lt}${le}`,he=p((t,e=te)=>{if(!t.doc)return e;let s=e;for(let a of t.doc)a.stmt==="dir"&&(s=a.value);return s},"getDir"),Pe=p(function(t,e){return e.db.getClasses()},"getClasses"),Be=p(async function(t,e,s,a){var k,F;m.info("REF0:"),m.info("Drawing state diagram (v2)",e);let{securityLevel:r,state:o,layout:h}=$();a.db.extract(a.db.getRootDocV2());let f=a.db.getData(),d=jt(e,r);f.type=a.type,f.layoutAlgorithm=h,f.nodeSpacing=(o==null?void 0:o.nodeSpacing)||50,f.rankSpacing=(o==null?void 0:o.rankSpacing)||50,$().look==="neo"?f.markers=["barbNeo"]:f.markers=["barb"],f.diagramId=e,await Ut(f,d);let E=8;try{(typeof a.db.getLinks=="function"?a.db.getLinks():new Map).forEach((R,C)=>{var P;let D=typeof C=="string"?C:typeof(C==null?void 0:C.id)=="string"?C.id:"",S=f.nodes.find(O=>O.id===D);if(!D){m.warn("\u26A0\uFE0F Invalid or missing stateId from key:",JSON.stringify(C));return}let A=(P=d.node())==null?void 0:P.querySelectorAll("g.node, g.rough-node"),v;if(A==null||A.forEach(O=>{var z;let J=(z=O.textContent)==null?void 0:z.trim();(O.id===(S==null?void 0:S.domId)||J===D)&&(v=O)}),!v){m.warn("\u26A0\uFE0F Could not find node matching text:",D);return}let Y=v.parentNode;if(!Y){m.warn("\u26A0\uFE0F Node has no parent, cannot wrap:",D);return}let w=document.createElementNS("http://www.w3.org/2000/svg","a"),G=R.url.replace(/^"+|"+$/g,"");if(w.setAttributeNS("http://www.w3.org/1999/xlink","xlink:href",G),w.setAttribute("target","_blank"),R.tooltip){let O=R.tooltip.replace(/^"+|"+$/g,"");w.setAttribute("title",O),v.setAttribute("title",O)}Y.replaceChild(w,v),w.appendChild(v),m.info("\u{1F517} Wrapped node in <a> tag for:",D,R.url)})}catch(B){m.error("\u274C Error injecting clickable links:",B)}Mt.insertTitle(d,"statediagramTitleText",(k=o==null?void 0:o.titleTopMargin)!=null?k:25,a.db.getDiagramTitle()),Ht(d,E,ot,(F=o==null?void 0:o.useMaxWidth)!=null?F:!0)},"draw"),Qe={getClasses:Pe,draw:Be,getDir:he},gt=new Map,H=0;function Tt(t="",e=0,s="",a=Lt){let r=s!==null&&s.length>0?`${a}${s}`:"";return`${$e}-${t}${r}-${e}`}p(Tt,"stateDomId");var Ye=p((t,e,s,a,r,o,h,f)=>{m.trace("items",e),e.forEach(d=>{var g;switch(d.stmt){case et:at(t,d,s,a,r,o,h,f);break;case nt:at(t,d,s,a,r,o,h,f);break;case xt:{at(t,d.state1,s,a,r,o,h,f),at(t,d.state2,s,a,r,o,h,f);let E=h==="neo",k={id:"edge"+H,start:d.state1.id,end:d.state2.id,arrowhead:"normal",arrowTypeEnd:E?"arrow_barb_neo":"arrow_barb",style:se,labelStyle:"",label:j.sanitizeText((g=d.description)!=null?g:"",$()),arrowheadStyle:re,labelpos:ie,labelType:ae,thickness:ne,classes:oe,look:h};r.push(k),H++}break}})},"setupDoc"),qt=p((t,e=te)=>{let s=e;if(t.doc)for(let a of t.doc)a.stmt==="dir"&&(s=a.value);return s},"getDir");function it(t,e,s){if(!e.id||e.id==="</join></fork>"||e.id==="</choice>")return;e.cssClasses&&(Array.isArray(e.cssCompiledStyles)||(e.cssCompiledStyles=[]),e.cssClasses.split(" ").forEach(r=>{var h;let o=s.get(r);o&&(e.cssCompiledStyles=[...(h=e.cssCompiledStyles)!=null?h:[],...o.styles])}));let a=t.find(r=>r.id===e.id);a?Object.assign(a,e):t.push(e)}p(it,"insertOrUpdateNode");function ue(t){var e,s;return(s=(e=t==null?void 0:t.classes)==null?void 0:e.join(" "))!=null?s:""}p(ue,"getClassesFromDbInfo");function de(t){var e;return(e=t==null?void 0:t.styles)!=null?e:[]}p(de,"getStylesFromDbInfo");var at=p((t,e,s,a,r,o,h,f)=>{var B,R,C;let d=e.id,g=s.get(d),E=ue(g),k=de(g),F=$();if(m.info("dataFetcher parsedItem",e,g,k),d!=="root"){let D=vt;e.start===!0?D=ke:e.start===!1&&(D=me),e.type!==nt&&(D=e.type),gt.get(d)||gt.set(d,{id:d,shape:D,description:j.sanitizeText(d,F),cssClasses:`${E} ${Ce}`,cssStyles:k});let S=gt.get(d);e.description&&(Array.isArray(S.description)?(S.shape=Ct,S.description.push(e.description)):(B=S.description)!=null&&B.length&&S.description.length>0?(S.shape=Ct,S.description===d?S.description=[e.description]:S.description=[S.description,e.description]):(S.shape=vt,S.description=e.description),S.description=j.sanitizeTextOrArray(S.description,F)),((R=S.description)==null?void 0:R.length)===1&&S.shape===Ct&&(S.type==="group"?S.shape=Xt:S.shape=vt),!S.type&&e.doc&&(m.info("Setting cluster for XCX",d,qt(e)),S.type="group",S.isGroup=!0,S.dir=qt(e),S.shape=e.type===ee?Kt:Xt,S.cssClasses=`${S.cssClasses} ${Ie} ${o?Ne:""}`);let A={labelStyle:"",shape:S.shape,label:S.description,cssClasses:S.cssClasses,cssCompiledStyles:[],cssStyles:S.cssStyles,id:d,dir:S.dir,domId:Tt(d,H),type:S.type,isGroup:S.type==="group",padding:8,rx:10,ry:10,look:h,labelType:"markdown"};if(A.shape===Kt&&(A.label=""),t&&t.id!=="root"&&(m.trace("Setting node ",d," to be child of its parent ",t.id),A.parentId=t.id),A.centerLabel=!0,e.note){let v={labelStyle:"",shape:_e,label:e.note.text,labelType:"markdown",cssClasses:we,cssStyles:[],cssCompiledStyles:[],id:d+Fe+"-"+H,domId:Tt(d,H,ce),type:S.type,isGroup:S.type==="group",padding:(C=F.flowchart)==null?void 0:C.padding,look:h,position:e.note.position},Y=d+Jt,w={labelStyle:"",shape:De,label:e.note.text,cssClasses:S.cssClasses,cssStyles:[],id:d+Jt,domId:Tt(d,H,le),type:"group",isGroup:!0,padding:16,look:h,position:e.note.position};H++,w.id=Y,v.parentId=Y,it(a,w,f),it(a,v,f),it(a,A,f);let G=d,P=v.id;e.note.position==="left of"&&(G=v.id,P=d),r.push({id:G+"-"+P,start:G,end:P,arrowhead:"none",arrowTypeEnd:"",style:se,labelStyle:"",classes:Le,arrowheadStyle:re,labelpos:ie,labelType:ae,thickness:ne,look:h})}else it(a,A,f)}e.doc&&(m.trace("Adding nodes children "),Ye(e,e.doc,s,a,r,!o,h,f))},"dataFetcher"),Ge=p(()=>{gt.clear(),H=0},"reset"),L={START_NODE:"[*]",START_TYPE:"start",END_NODE:"[*]",END_TYPE:"end",COLOR_KEYWORD:"color",FILL_KEYWORD:"fill",BG_FILL:"bgFill",STYLECLASS_SEP:","},Qt=p(()=>new Map,"newClassesList"),Zt=p(()=>({relations:[],states:new Map,documents:{}}),"newDoc"),yt=p(t=>JSON.parse(JSON.stringify(t)),"clone"),st,es=(st=class{constructor(e){this.version=e,this.nodes=[],this.edges=[],this.rootDoc=[],this.classes=Qt(),this.documents={root:Zt()},this.currentDocument=this.documents.root,this.startEndCount=0,this.dividerCnt=0,this.links=new Map,this.funs=[],this.getAccTitle=Ft,this.setAccTitle=$t,this.getAccDescription=Bt,this.setAccDescription=Pt,this.setDiagramTitle=Yt,this.getDiagramTitle=Gt,this.clear(),this.setRootDoc=this.setRootDoc.bind(this),this.getDividerId=this.getDividerId.bind(this),this.setDirection=this.setDirection.bind(this),this.trimColon=this.trimColon.bind(this),this.bindFunctions=this.bindFunctions.bind(this)}extract(e){this.clear(!0);for(let r of Array.isArray(e)?e:e.doc)switch(r.stmt){case et:this.addState(r.id.trim(),r.type,r.doc,r.description,r.note);break;case xt:this.addRelation(r.state1,r.state2,r.description);break;case Te:this.addStyleClass(r.id.trim(),r.classes);break;case be:this.handleStyleDef(r);break;case Ee:this.setCssClass(r.id.trim(),r.styleClass);break;case"click":this.addLink(r.id,r.url,r.tooltip);break}let s=this.getStates(),a=$();Ge(),at(void 0,this.getRootDocV2(),s,this.nodes,this.edges,!0,a.look,this.classes);for(let r of this.nodes)if(Array.isArray(r.label)){if(r.description=r.label.slice(1),r.isGroup&&r.description.length>0)throw new Error(`Group nodes can only have label. Remove the additional description for node [${r.id}]`);r.label=r.label[0]}}handleStyleDef(e){let s=e.id.trim().split(","),a=e.styleClass.split(",");for(let r of s){let o=this.getState(r);if(!o){let h=r.trim();this.addState(h),o=this.getState(h)}o&&(o.styles=a.map(h=>{var f;return(f=h.replace(/;/g,""))==null?void 0:f.trim()}))}}setRootDoc(e){m.info("Setting root doc",e),this.rootDoc=e,this.version===1?this.extract(e):this.extract(this.getRootDocV2())}docTranslator(e,s,a){if(s.stmt===xt){this.docTranslator(e,s.state1,!0),this.docTranslator(e,s.state2,!1);return}if(s.stmt===et&&(s.id===L.START_NODE?(s.id=e.id+(a?"_start":"_end"),s.start=a):s.id=s.id.trim()),s.stmt!==tt&&s.stmt!==et||!s.doc)return;let r=[],o=[];for(let h of s.doc)if(h.type===ee){let f=yt(h);f.doc=yt(o),r.push(f),o=[]}else o.push(h);if(r.length>0&&o.length>0){let h={stmt:et,id:Vt(),type:"divider",doc:yt(o)};r.push(yt(h)),s.doc=r}s.doc.forEach(h=>this.docTranslator(s,h,!0))}getRootDocV2(){return this.docTranslator({id:tt,stmt:tt},{id:tt,stmt:tt,doc:this.rootDoc},!0),{id:tt,doc:this.rootDoc}}addState(e,s=nt,a=void 0,r=void 0,o=void 0,h=void 0,f=void 0,d=void 0){let g=e==null?void 0:e.trim();if(!this.currentDocument.states.has(g))m.info("Adding state ",g,r),this.currentDocument.states.set(g,{stmt:et,id:g,descriptions:[],type:s,doc:a,note:o,classes:[],styles:[],textStyles:[]});else{let E=this.currentDocument.states.get(g);if(!E)throw new Error(`State not found: ${g}`);E.doc||(E.doc=a),E.type||(E.type=s)}if(r&&(m.info("Setting state description",g,r),(Array.isArray(r)?r:[r]).forEach(k=>this.addDescription(g,k.trim()))),o){let E=this.currentDocument.states.get(g);if(!E)throw new Error(`State not found: ${g}`);E.note=o,E.note.text=j.sanitizeText(E.note.text,$())}h&&(m.info("Setting state classes",g,h),(Array.isArray(h)?h:[h]).forEach(k=>this.setCssClass(g,k.trim()))),f&&(m.info("Setting state styles",g,f),(Array.isArray(f)?f:[f]).forEach(k=>this.setStyle(g,k.trim()))),d&&(m.info("Setting state styles",g,f),(Array.isArray(d)?d:[d]).forEach(k=>this.setTextStyle(g,k.trim())))}clear(e){this.nodes=[],this.edges=[],this.funs=[this.setupToolTips.bind(this)],this.documents={root:Zt()},this.currentDocument=this.documents.root,this.startEndCount=0,this.classes=Qt(),e||(this.links=new Map,Nt())}getState(e){return this.currentDocument.states.get(e)}getStates(){return this.currentDocument.states}logDocuments(){m.info("Documents = ",this.documents)}getRelations(){return this.currentDocument.relations}addLink(e,s,a){this.links.set(e,{url:s,tooltip:a}),m.warn("Adding link",e,s,a)}getLinks(){return this.links}startIdIfNeeded(e=""){return e===L.START_NODE?(this.startEndCount++,`${L.START_TYPE}${this.startEndCount}`):e}startTypeIfNeeded(e="",s=nt){return e===L.START_NODE?L.START_TYPE:s}endIdIfNeeded(e=""){return e===L.END_NODE?(this.startEndCount++,`${L.END_TYPE}${this.startEndCount}`):e}endTypeIfNeeded(e="",s=nt){return e===L.END_NODE?L.END_TYPE:s}addRelationObjs(e,s,a=""){let r=this.startIdIfNeeded(e.id.trim()),o=this.startTypeIfNeeded(e.id.trim(),e.type),h=this.startIdIfNeeded(s.id.trim()),f=this.startTypeIfNeeded(s.id.trim(),s.type);this.addState(r,o,e.doc,e.description,e.note,e.classes,e.styles,e.textStyles),this.addState(h,f,s.doc,s.description,s.note,s.classes,s.styles,s.textStyles),this.currentDocument.relations.push({id1:r,id2:h,relationTitle:j.sanitizeText(a,$())})}addRelation(e,s,a){if(typeof e=="object"&&typeof s=="object")this.addRelationObjs(e,s,a);else if(typeof e=="string"&&typeof s=="string"){let r=this.startIdIfNeeded(e.trim()),o=this.startTypeIfNeeded(e),h=this.endIdIfNeeded(s.trim()),f=this.endTypeIfNeeded(s);this.addState(r,o),this.addState(h,f),this.currentDocument.relations.push({id1:r,id2:h,relationTitle:a?j.sanitizeText(a,$()):void 0})}}addDescription(e,s){var o;let a=this.currentDocument.states.get(e),r=s.startsWith(":")?s.replace(":","").trim():s;(o=a==null?void 0:a.descriptions)==null||o.push(j.sanitizeText(r,$()))}cleanupLabel(e){return e.startsWith(":")?e.slice(2).trim():e.trim()}getDividerId(){return this.dividerCnt++,`divider-id-${this.dividerCnt}`}addStyleClass(e,s=""){this.classes.has(e)||this.classes.set(e,{id:e,styles:[],textStyles:[]});let a=this.classes.get(e);s&&a&&s.split(L.STYLECLASS_SEP).forEach(r=>{let o=r.replace(/([^;]*);/,"$1").trim();if(RegExp(L.COLOR_KEYWORD).exec(r)){let f=o.replace(L.FILL_KEYWORD,L.BG_FILL).replace(L.COLOR_KEYWORD,L.FILL_KEYWORD);a.textStyles.push(f)}a.styles.push(o)})}getClasses(){return this.classes}setupToolTips(e){let s=Wt();St(e).select("svg").selectAll("g.node, g.rough-node").on("mouseover",o=>{var g;let h=St(o.currentTarget),f=h.attr("title");if(f===null)return;let d=(g=o.currentTarget)==null?void 0:g.getBoundingClientRect();s.transition().duration(200).style("opacity",".9"),s.style("left",window.scrollX+d.left+(d.right-d.left)/2+"px").style("top",window.scrollY+d.bottom+"px"),s.html(Rt.sanitize(f)),h.classed("hover",!0)}).on("mouseout",o=>{s.transition().duration(500).style("opacity",0),St(o.currentTarget).classed("hover",!1)})}setCssClass(e,s){e.split(",").forEach(a=>{var o;let r=this.getState(a);if(!r){let h=a.trim();this.addState(h),r=this.getState(h)}(o=r==null?void 0:r.classes)==null||o.push(s)})}setStyle(e,s){var a,r;(r=(a=this.getState(e))==null?void 0:a.styles)==null||r.push(s)}setTextStyle(e,s){var a,r;(r=(a=this.getState(e))==null?void 0:a.textStyles)==null||r.push(s)}bindFunctions(e){this.funs.forEach(s=>{s(e)})}getDirectionStatement(){return this.rootDoc.find(e=>e.stmt===zt)}getDirection(){var e,s;return(s=(e=this.getDirectionStatement())==null?void 0:e.value)!=null?s:ge}setDirection(e){let s=this.getDirectionStatement();s?s.value=e:this.rootDoc.unshift({stmt:zt,value:e})}trimColon(e){return e.startsWith(":")?e.slice(1).trim():e.trim()}getData(){let e=$();return{nodes:this.nodes,edges:this.edges,other:{},config:e,direction:he(this.getRootDocV2())}}getConfig(){return $().state}},p(st,"StateDB"),st.relationType={AGGREGATION:0,EXTENSION:1,COMPOSITION:2,DEPENDENCY:3},st),Ve=p(t=>{var e;return`
defs [id$="-barbEnd"] {
    fill: ${t.transitionColor};
    stroke: ${t.transitionColor};
  }
g.stateGroup text {
  fill: ${t.nodeBorder};
  stroke: none;
  font-size: 10px;
}
g.stateGroup text {
  fill: ${t.textColor};
  stroke: none;
  font-size: 10px;

}
g.stateGroup .state-title {
  font-weight: bolder;
  fill: ${t.stateLabelColor};
}

g.stateGroup rect {
  fill: ${t.mainBkg};
  stroke: ${t.nodeBorder};
}

g.stateGroup line {
  stroke: ${t.lineColor};
  stroke-width: ${t.strokeWidth||1};
}

.transition {
  stroke: ${t.transitionColor};
  stroke-width: ${t.strokeWidth||1};
  fill: none;
}

.stateGroup .composit {
  fill: ${t.background};
  border-bottom: 1px
}

.stateGroup .alt-composit {
  fill: #e0e0e0;
  border-bottom: 1px
}

.state-note {
  stroke: ${t.noteBorderColor};
  fill: ${t.noteBkgColor};

  text {
    fill: ${t.noteTextColor};
    stroke: none;
    font-size: 10px;
  }
}

.stateLabel .box {
  stroke: none;
  stroke-width: 0;
  fill: ${t.mainBkg};
  opacity: 0.5;
}

.edgeLabel .label rect {
  fill: ${t.labelBackgroundColor};
  opacity: 0.5;
}
.edgeLabel {
  background-color: ${t.edgeLabelBackground};
  p {
    background-color: ${t.edgeLabelBackground};
  }
  rect {
    opacity: 0.5;
    background-color: ${t.edgeLabelBackground};
    fill: ${t.edgeLabelBackground};
  }
  text-align: center;
}
.edgeLabel .label text {
  fill: ${t.transitionLabelColor||t.tertiaryTextColor};
}
.label div .edgeLabel {
  color: ${t.transitionLabelColor||t.tertiaryTextColor};
}

.stateLabel text {
  fill: ${t.stateLabelColor};
  font-size: 10px;
  font-weight: bold;
}

.node circle.state-start {
  fill: ${t.specialStateColor};
  stroke: ${t.specialStateColor};
}

.node .fork-join {
  fill: ${t.specialStateColor};
  stroke: ${t.specialStateColor};
}

.node circle.state-end {
  fill: ${t.innerEndBackground};
  stroke: ${t.background};
  stroke-width: 1.5
}
.end-state-inner {
  fill: ${t.compositeBackground||t.background};
  // stroke: ${t.background};
  stroke-width: 1.5
}

.node rect {
  fill: ${t.stateBkg||t.mainBkg};
  stroke: ${t.stateBorder||t.nodeBorder};
  stroke-width: ${t.strokeWidth||1}px;
}
.node polygon {
  fill: ${t.mainBkg};
  stroke: ${t.stateBorder||t.nodeBorder};;
  stroke-width: ${t.strokeWidth||1}px;
}
[id$="-barbEnd"] {
  fill: ${t.lineColor};
}

.statediagram-cluster rect {
  fill: ${t.compositeTitleBackground};
  stroke: ${t.stateBorder||t.nodeBorder};
  stroke-width: ${t.strokeWidth||1}px;
}

.cluster-label, .nodeLabel {
  color: ${t.stateLabelColor};
  // line-height: 1;
}

.statediagram-cluster rect.outer {
  rx: 5px;
  ry: 5px;
}
.statediagram-state .divider {
  stroke: ${t.stateBorder||t.nodeBorder};
}

.statediagram-state .title-state {
  rx: 5px;
  ry: 5px;
}
.statediagram-cluster.statediagram-cluster .inner {
  fill: ${t.compositeBackground||t.background};
}
.statediagram-cluster.statediagram-cluster-alt .inner {
  fill: ${t.altBackground?t.altBackground:"#efefef"};
}

.statediagram-cluster .inner {
  rx:0;
  ry:0;
}

.statediagram-state rect.basic {
  rx: 5px;
  ry: 5px;
}
.statediagram-state rect.divider {
  stroke-dasharray: 10,10;
  fill: ${t.altBackground?t.altBackground:"#efefef"};
}

.note-edge {
  stroke-dasharray: 5;
}

.statediagram-note rect {
  fill: ${t.noteBkgColor};
  stroke: ${t.noteBorderColor};
  stroke-width: 1px;
  rx: 0;
  ry: 0;
}
.statediagram-note rect {
  fill: ${t.noteBkgColor};
  stroke: ${t.noteBorderColor};
  stroke-width: 1px;
  rx: 0;
  ry: 0;
}

.statediagram-note text {
  fill: ${t.noteTextColor};
}

.statediagram-note .nodeLabel {
  color: ${t.noteTextColor};
}
.statediagram .edgeLabel {
  color: red; // ${t.noteTextColor};
}

[id$="-dependencyStart"], [id$="-dependencyEnd"] {
  fill: ${t.lineColor};
  stroke: ${t.lineColor};
  stroke-width: ${t.strokeWidth||1};
}

.statediagramTitleText {
  text-anchor: middle;
  font-size: 18px;
  fill: ${t.textColor};
}

[data-look="neo"].statediagram-cluster rect {
  fill: ${t.mainBkg};
  stroke: ${t.useGradient?"url("+t.svgId+"-gradient)":t.stateBorder||t.nodeBorder};
  stroke-width: ${(e=t.strokeWidth)!=null?e:1};
}
[data-look="neo"].statediagram-cluster rect.outer {
  rx: ${t.radius}px;
  ry: ${t.radius}px;
  filter: ${t.dropShadow?t.dropShadow.replace("url(#drop-shadow)",`url(${t.svgId}-drop-shadow)`):"none"}
}
`},"getStyles"),ss=Ve;export{qe as a,Qe as b,es as c,ss as d};
