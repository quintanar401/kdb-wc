class KDBLex
  constructor: ->
  getTokens: (txt) -> @process txt
  filter: (txt) -> @getHtml txt
  getHtml: (txt,cmap) ->
    cmap ?= {}
    retrun '' if (t = @getTokens txt)?.length is 0
    res = ''
    for o,i in t
      if o.x is 0
        res += "</div>" unless o.y is 0
        res += "<div class='"+(cmap.line||"k-line")+"'>"
      res += "<span class='#{cmap[o.type]||o.type}'>#{@escHtml o.token}</span>"
    res
  process: (txt) ->
    @toks = []
    t = txt.split '\n' if typeof txt is 'string'
    st = state:'q', txt: t, reg:'', line: null, lstart: true, x:0, y:-1
    while st.txt.length>0 or st.line?.length>0
      st = @next st
    st = @pushTxt st
    return @toks
  escHtml: (s) -> s.replace(/&/g, '&amp;').replace(/"/g, '&quot;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/ /g,'&nbsp;')
  prevChar: (st) ->
    if st.reg.length  is 0
      return ' ' if @toks.length is 0
      t = @toks[@toks.length-1]
      return ' ' if t.y isnt st.y
      t = t.token[t.token.length-1]
    else
      t = st.reg
    return 'a' if /[a-zA-Z]/.test t
    return '0' if /[0-9]/.test t
    return ' '
  next: (st) ->
    if st.line is null
      return if st.txt.length is 0
      @pushTxt st
      st.line = st.txt.shift()
      st.lstart = true
      st.x = 0; st.y += 1
    if st.state is 'sim-com'
      @toks.push type:"k-simple-comment", token: st.line, x: st.x, y: st.y
      st.state = 'q' if /^\\\s*$/.test st.line
      st.line = null
      return st
    if st.state is 'eof-com'
      @toks.push type:"k-eof-comment", token: st.line, x: st.x, y: st.y
      st.line = null
      return st
    if st.state is 'str'
      i = 0; b = false
      while st.line[i] isnt '"' or b
        if st.line.length <= i
          @toks.push type:"k-string", token: st.reg + st.line, x: st.x, y: st.y
          st.line = null
          st.reg = ''
          return st
        b = if b then false else st.line[i] is '\\'
        i += 1
      st.state = 'q'
      @toks.push type:"k-string", token: st.reg+st.line.slice(0, i+1), x: st.x-1, y: st.y
      st.line = st.line.slice i+1
      st.reg = ''
      st.x += i+1
      return st
    # state q
    if st.lstart
      st.lstart = false
      if st.line.length is 0
        st.line = null
        @toks.push type:"k-text", token: '', x: st.x, y: st.y
        return st
      if cmt = st.line.match /^\/\s*$/
        st.line = null
        st.state = 'sim-com'
        @toks.push type:"k-simple-comment", token: cmt[0], x: st.x, y: st.y
        return st
      if cmt = st.line.match /^\\\s*$/
        st.line = null
        st.state = 'eof-com'
        @toks.push type:"k-eof-comment", token: cmt[0], x: st.x, y: st.y
        return st
      if cmt = st.line.match /^\/.*/
        st.line = null
        @toks.push type:"k-comment", token: cmt[0], x: st.x, y: st.y
        return st
      if cmd = st.line.match /^\\.*/
        st.line = null
        @toks.push type:"k-command", token: cmd[0], x: st.x, y: st.y
        return st
      if cmd = st.line.match /^[a-zA-Z]\)/
        @toks.push type:"k-command", token: cmd[0], x: st.x, y: st.y
        st.x +=2
        st.line = st.line.slice 2
        return st
    if st.line.length is 0
      st.line = null
      return st
    if cmt = st.line.match /^(\s+)(\/.*)/
      @toks.push type:"k-text", token: cmt[1], x: st.x, y: st.y if cmt[1]
      st.line = 0
      @toks.push type:"k-comment", token: cmt[2], x: st.x, y: st.y
      return st
    if st.line[0] is '"'
      st.state = 'str'
      st.line = st.line.slice 1
      st.x += 1
      st.reg = '"'
      return st
    if !(@prevChar(st) in ['a','0'])
      return @pushTok st,"k-number-guid",id[0] if id = st.line.match /^[\da-f]{8}-[\da-f]{4}-[\da-f]{4}-[\da-f]{4}-[\da-f]{12}/
      if id = st.line.match /^[a-zA-Z][a-zA-Z0-9_\.]*/
        if /^(and|or|except|inter|like|each|cross|vs|sv|within|where|in|asof|bin|binr|cor|cov|cut|ej|fby|div|ij|insert|lj|ljf|mavg|mcount|mdev|mmax|mmin|mmu|mod|msum|over|prior|peach|pj|scan|scov|setenv|ss|sublist|uj|union|upsert|wavg|wsum|xasc|xbar|xcol|xcols|xdesc|xexp|xgroup|xkey|xlog|xprev|xrank)$/.test id[0]
          t = "k-keyword-operator"
        else if /^(do|if|while|select|update|delete|exec|from|by)$/.test id
          t = "k-keyword-control"
        else if id[0] in ['x','y','z']
          t = "k-keyword-language"
        else if /^(first|enlist|value|type|get|set|count|string|key|max|min|sum|prd|last|flip|distinct|raze|neg|til|upper|lower|abs|acos|aj|aj0|not|null|any|asc|asin|attr|avg|avgs|ceiling|cols|cos|csv|all|atan|deltas|desc|differ|dsave|dev|eval|exit|exp|fills|fkeys|floor|getenv|group|gtime|hclose|hcount|hdel|hopen|hsym|iasc|idesc|inv|keys|load|log|lsq|ltime|ltrim|maxs|md5|med|meta|mins|next|parse|plist|prds|prev|rand|rank|ratios|read0|read1|reciprocal|reverse|rload|rotate|rsave|rtrim|save|sdev|show|signum|sin|sqrt|ssr|sums|svar|system|tables|tan|trim|txf|ungroup|var|view|views|wj|wj1|ww)$/.test id[0]
          t = "k-keyword-function"
        else
          t = "k-name"
        return @pushTok st,t,id[0]
      return @pushTok st,(if id[0][2] is '.' and id[0][1] in ['q','Q','h','o','z'] then "k-keyword-function" else "k-variable"),id[0] if id = st.line.match /^\.[a-zA-Z][a-zA-Z0-9_\.]*/
      return @pushTok st,"k-const",id[0] if id = st.line.match /^0[nNwW][hijefcpmdznuvtg]?/
      return @pushTok st,"k-number-datetime",id[0] if id = st.line.match /^(?:\d+D|\d\d\d\d\.[01]\d\.[0123]\d[DT])(?:[012]\d\:[0-5]\d(?:\:[0-5]\d(?:\.\d+)?)?|([012]\d)?)[zpn]?/
      return @pushTok st,"k-number-time",id[0] if id = st.line.match /^[012]\d\:[0-5]\d(?:\:[0-5]\d(\.\d+)?)?[uvtpn]?/
      return @pushTok st,"k-number-date",id[0] if id = st.line.match /^\d{4}\.[01]\d\.[0-3]\d[dpnzm]?/
      return @pushTok st,"k-number-float",id[0] if id = st.line.match /^(?:(?:\d+(?:\.\d*)?|\.\d+)[eE][+-]?\d+|\d+\.\d*|\.\d+)[efpntm]?/
      return @pushTok st,"k-keyword-function",id[0] if id = st.line.match /^-[1-9][0-9]?\s*!/
      return @pushTok st,"k-const-sym",id[0] if id = st.line.match /^(`\:[\:a-zA-Z0-9\._/]*|`(?:[a-zA-Z0-9\.][\:a-zA-Z0-9\._]*)?)/
      return @pushTok st,"k-number-int",id[0] if id = st.line.match /^(0x[0-9a-fA-F]+|\d+[bhicjefpnuvt]?)/
    return @pushTok st,"k-operator",id[0] if id = st.line.match /^(\'|\/\:|\\\:|\'\:|\\|\/|0\:|1\:|2\:)/
    return @pushTok st,"k-operator",id[0] if id = st.line.match /^(?:<=|>=|<>|::)|^(?:\$|%|&|\@|\.|\_|\#|\*|\^|\-|\+|\+|~|\,|!|>|<|=|\||\?|\:)\:?/
    st.reg = st.reg + st.line[0]
    st.line = st.line.slice 1
    st.x += 1
    return st
  pushTok: (st,t,n) ->
    st = @pushTxt st
    @toks.push type:t, token: n, x: st.x, y: st.y
    st.x += n.length
    st.line = st.line.slice n.length
    return st
  pushTxt: (st) ->
    return st unless st.reg
    @toks.push type:'k-text', token: st.reg, x: st.x-st.reg.length, y: st.y
    st.reg = ''
    return st

window.KDB ?= {}
KDB.KDBLexer = new KDBLex()
KDB.KDBLex = KDBLex
