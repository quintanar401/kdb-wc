.h.HOME:"./";
if[not system "p";system "p 5566"]

.h.oldPh:.z.ph;

.z.ph:{-1 "QUERY: ",x:$[type x;x;first x];
  $[x like"*&target=*";procReq ."&" vs last "?" vs x;.h.oldPh x]}

procReq:{[q;t]
  t:`$$[(t:7_ t) like "*:*";":",t;t];
  -1 "REMOTE to ",string t:t^trgMap[t];
  : .h.hy[`html] first .j.j each getTrg[t] .h.uh q;
 };

procReqWS:{[q]
  if[not 10=type q; :value q];
  if[not q like "%target=*"; :value q];
  t:(n:q?"%")#q:8_ q;
  q:(n+1)_q;
  t:`$$[t like "*:*";":",t;t];
  -1 "REMOTE to ",string t:t^trgMap[t];
  : getTrg[t] q;
 };

cMap:(`int$())!`$();
trgMap:(`$())!`$();

// as an example logical srv = local srv
trgMap[`server]:`localServer;
cMap[0i]:`localServer;

getTrg:{$[null h:cMap?x;openTrg x;h]};
openTrg:{cMap[hopen x]::x;cMap?x};

.z.pc:{cMap[x]:`};

.z.ws:{
 -1 "WS: ",$[10=type x;x;"[bin] ",.Q.s -9!x];
  neg[.z.w]$[10=type x;.j.j @[procReqWS;x;::];@[{-8!procReqWS -9!x};x;::]]};

.z.pg:{-1 "Q: ",$[10=type x;x;"[bin] ",.Q.s x]; value x};