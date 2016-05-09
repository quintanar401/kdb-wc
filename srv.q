.h.HOME:"./";
system "p 5566"

.h.oldPh:.z.ph;
.z.ph:{
  -1 "QUERY: ",x:$[type x;x;first x];
  $[x like"*&target=*";.h.hy[`html] .d.html .h.uh x;.h.oldPh x]};
.z.ws:{
 -1 "WS: ",$[10=type x;x;"[bin] ",.Q.s -9!x];
  neg[.z.w]$[10=type x;.j.j @[value;x;::];@[{-8!value -9!x};x;::]]};