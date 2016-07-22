'use strict'
# <kdb-connect srvUser="u" srvPass="p" target="h" query="starting sequence"/>
(() ->
  try
    new CustomEvent 'test'
  catch
    CE = (event, params) ->
      params = params ||  bubbles: false, cancelable: false, detail: undefined
      evt = document.createEvent 'CustomEvent'
      evt.initCustomEvent(event, params.bubbles, params.cancelable, params.detail)
      return evt
    CE.prototype = window.CustomEvent.prototype
    window.CustomEvent = CE
)()

extractInfo = (v) ->
  return v if typeof v is 'string'
  txt = ''
  if v.nodeName is 'SELECT'
    txt = v.options[v.selectedIndex].text
  else if v.nodeName is 'INPUT'
    if v.type is 'checkbox'
      txt = if v.checked then '1b' else '0b'
    else if v.type is 'radio'
      txt = v.form.querySelector("input[type='radio'][name='#{v.name}']:checked")?.value || ''
    else
      txt = v?.value || ''
  else if v.nodeName is 'TEXTAREA'
    txt = v.value
  else if v.nodeName is 'KDB-EDITOR'
    txt = v.kEditor.getValue()
  else
    txt = v.textContent
  txt

mergeCfgs = (c1,c2) ->
  for n,v of c1
    continue if (v2 = c2[n]) is undefined
    if typeof v2 is 'object' and typeof v is 'object' and !v2.length and !v.length
      c1[n] = mergeCfgs v, v2
    else
      c1[n] = v2
  for n,v of c2
    continue if c1[n]
    c1[n] = v
  c1
copyCfg = (c) ->
  cc = {}
  for n,v of c
    if typeof v is 'object' and !v.length
      cc[n] = copyCfg v
    else
      cc[n] = v
  cc
getConfig = (c) ->
  return copyCfg (c.split(".").reduce ((x,y) -> return x[y]), window) if /^[\w\.]+$/.test c
  try
    cfg = JSON.parse c
  catch err
    console.log "kdb-wc: config parse exception"
    return console.log err
keval = (s) ->
  # .split(".").reduce ((x,y) -> return x[y]), window
  try
    eval s
  catch err
    null

jsonpRegistry = {}

class _KDBSrv extends HTMLElement
  createdCallback: ->
    @srvType = @attributes['k-srv-type']?.textContent || "http"
    @target = @attributes['k-target']?.textContent || null
    @wsSrv = if @srvType in ['http','https'] then location.host else (@attributes['k-srv-uri']?.textContent || location.host)
    @srvUser = @attributes['k-srv-user']?.textContent || null
    @srvPass = @attributes['k-srv-pass']?.textContent || null
    @qPrefix = @attributes['k-prefix']?.textContent || ""
    @debug = @attributes['debug']?.textContent || null
    @rType = @attributes['k-return-type']?.textContent || "json"
    @fixJson = @attributes['fix-json']?.textContent || null
    @kFeed = (@attributes['k-feed']?.textContent || "false") is "true"
    @hidden = true
    @ws = @wsReq = null
    @wsQueue = []
    @rType = 'json' if @srvType is 'jsonp'
    @srvProto = if /^http.?\:/.test @wsSrv then '' else if @srvType is 'https' then 'https://' else 'http://'
    console.log "kdb-srv inited: srvType:#{@srvType}, target:#{@target}, prefix:#{@qPrefix}, rType:#{@rType}, proto:#{@srvProto}, srv: #{@wsSrv}" if @debug
    if @target
      @target = (document.querySelector "[k-id='#{@target}']") || @target
  runQuery: (q,cb) ->
    (cb = (r,e) -> null) unless cb
    return @sendHTTP q,cb if @srvType in ['http','xhttp','jsonp','https']
    return @sendWS q,cb if @srvType in ['ws','wss']
    console.error 'kdb-srv: unknown srv type: '+@srvType
  sendWS: (qq,clb) ->
    @wsQueue.push q:qq, cb:clb
    if !@ws
      @ws = new WebSocket("#{@srvType}://#{@wsSrv}/")
      @ws.binaryType = 'arraybuffer'
      @ws.onopen = =>
        console.log "kdb-srv-ws: opened" if @debug
        @processWSQueue()
      @ws.onclose = =>
        console.log "kdb-srv-ws: closed" if @debug
        @ws = null
        @sendWSRes null,'closed'
      @ws.onerror = (e) =>
        console.log "kdb-srv-ws: error #{e.data}" if @debug
        @sendWSRes null,e.data
      @ws.onmessage = (e) =>
        console.log "kdb-srv-ws: msg" if @debug
        try
          res = if @rType is "json" and typeof e.data is 'string' then JSON.parse e.data else if typeof e.data is 'object' then deserialize(e.data) else e.data
        catch error
          console.error "kdb-srv-ws: exception in ws parse #{error}"
          return @sendWSRes null, "result parse error: "+error.toString()
        @sendWSRes res, null
      return
    @processWSQueue() if @ws.readyState is 1
  sendWSRes: (r,e) ->
    return unless req=@wsReq
    @wsReq = null unless @kFeed
    try
      req.cb r,e
    catch err
      console.error "kdb-srv-ws: exception in callback"
      console.log err
    @processWSQueue()
  processWSQueue: ->
    return if @wsReq or @wsQueue.length is 0
    @wsReq = @wsQueue.shift()
    req = @wsReq.q
    req = @qPrefix + req if typeof req is 'string' and @qPrefix
    req = "%target=#{trg}%" + req if @target and trg=extractInfo @target
    if @rType is 'q'
      try
        req = ' '+req if typeof req is 'string' and req[0] is '`' # compensate the strange behavior of serialize
        req = serialize req
      catch error
        console.error "kdb-srv-ws: exception in ws send #{error}"
        return @sendWSRes null,'send'
    return @ws.send req if @ws and @ws.readyState is 1
    @sendWS @wsReq.q,@wsReq.cb
    @wsReq = null
  sendHTTP: (q,cb) ->
    if @fixJson
      @fixJson = null
      @qPrefix = (if @srvType is 'jsonp' then 'jsp?' else "jsn?enlist ") unless @qPrefix
      query = ".h.tx[`jsn]:(.j.j');"
      query = '.h.tx[`jsp]:{enlist "KDB.processJSONP(\'",string[x 0],"\',",(.j.j x 1),")"};' if @srvType is 'jsonp'
      query += 'if[105=type .h.hp;.h.hp:(f:{ssr[x y;"\nConnection: close";{"\nAccess-Control-Allow-Origin: *\r",x}]})[.h.hp];.h.he:f .h.he;.h.hy:{[a;b;c;d]a[b c;d]}[f;.h.hy]];' if @srvType is "xhttp"
      return @runQuery "{#{query};1}[]", (r,e) => @runQuery q, cb
    @qPrefix = (if @srvType is 'jsonp' then 'jsp?' else "json?enlist ") if !@qPrefix and @rType is "json"
    if @srvType is 'jsonp'
      q = @qPrefix + "(`#{rid = 'id'+Date.now()};#{encodeURIComponent q})"
    else
      q = @qPrefix + encodeURIComponent q
    q = q + "&target=" + trg if @target and trg=extractInfo @target
    q = @srvProto + @wsSrv + '/' + q
    console.log "kdb-srv sending request:"+q if @debug
    return @sendJSONP rid, q, cb if @srvType is 'jsonp'
    xhr = new XMLHttpRequest()
    xhr.onerror = =>
      console.log "kdb-srv error: "+xhr.statusText + " - " + xhr.responseText if @debug
      cb null, xhr.statusText+": "+xhr.responseText
    xhr.ontimeout = =>
      console.log "kdb-srv timeout" if @debug
      cb null, "timeout"
    xhr.onload = =>
      return xhr.onerror() unless xhr.status is 200
      console.log "kdb-srv data: "+xhr.responseText.slice(0,50) if @debug
      try
        try
          res = if @rType is "json" then JSON.parse xhr.responseText else if @rType is "xml" then xhr.responseXML else xhr.responseText
        catch error
          console.error "kdb-srv: exception in JSON.parse"
          return cb null, "JSON.parse error: "+error.toString()
        cb res, null
      catch err
        console.error "kdb-srv: HTTP callback exception"
        console.log err
    xhr.open 'GET', q, true, @srvUser, @srvPass
    xhr.send()
  sendJSONP: (rid,q,cb) ->
    resOk = false
    jsonpRegistry[rid] = (res) =>
      console.log "kdb-srv(jsonp) data: " + res.toString().slice(0,50) if @debug
      delete jsonpRegistry[rid]
      resOk = true
      try
        cb res, null
      catch error
        console.error "kdb-srv: HTTP callback exception"
        console.log error
    script = document.createElement('script')
    script.onload = script.onerror = =>
      return if resOk
      delete jsonpRegistry[rid]
      console.log "kdb-srv(jsonp): error" if @debug
      try
        cb null, "url: "+q
      catch error
        console.error "kdb-srv: HTTP callback exception"
        console.log error
    script.src = q
    document.body.appendChild script

class _KDBQuery extends HTMLElement
  createdCallback: ->
    @hidden = true
    @setupQuery()
  setupQuery: ->
    prvExec = @exec
    clearTimeout @ktimer if @ktimer
    @ktimer = null
    @iterationNumber = 0
    @kID = @attributes['k-id']?.textContent || "undefined"
    @query = @attributes['k-query']?.textContent || @textContent
    @srv = @attributes['k-srv']?.textContent || ""
    @exec = @attributes['k-execute-on']?.textContent.split(' ').filter((e)-> e.length > 0) || ["load"]
    @debug = @attributes['debug']?.textContent || null
    @escapeQ = @attributes['k-escape-q']?.textContent || ""
    @kDispUpd = (@attributes['k-dispatch-update']?.textContent || "false") is "true"
    @updObjs = @attributes['k-update-elements']?.textContent.split(' ').filter((e)-> e.length > 0) || []
    @updErr = @attributes['k-on-error']?.textContent.split(' ').filter((e)-> e.length > 0) || []
    @kInterval = @attributes['k-interval']?.textContent || "0"
    @kInterval = if Number.parseInt then Number.parseInt @kInterval else Number @kInterval
    @kDelay = @attributes['k-delay']?.textContent || "0"
    @kDelay = if Number.parseInt then Number.parseInt @kDelay else Number @kDelay
    @kQStatus = @attributes['k-status-var']?.textContent || null
    @kQNum = 0
    if @kFilter = @attributes['k-filter']?.textContent
      @kFilter = keval @kFilter
    @result = null
    if 'load' in @exec and (!prvExec or !('load' in prvExec))
      if document.readyState in ['complete','interactive']
        setTimeout (=> @runQuery { src:"self", txt:"load"}), 100
      else
        document.addEventListener "DOMContentLoaded", (ev) => @runQuery src:"self", txt:"load"
    for el in @exec when !(el in ['load','manual','timer'])
      @addUpdater(v,el) if v = document.querySelector "[k-id='#{el}']"
    @kRefs = @query.match(/\$(\w|\.)(\w|\.|\]|\[|\-)*\$/g)?.map (e) -> e.slice 1,e.length-1
    @kMap = null
    if 'timer' in @exec
      setTimeout (=> @rerunQuery src:"self", txt:"timer"), if @kDelay then @kDelay else @kInterval
    console.log "kdb-query inited: srv:#{@srv}, query:#{@query}, executeOn:#{@exec}, updateObs:#{@updObjs}, refs:#{@kRefs}, delay:#{@kDelay}, interval:#{@kInterval}" if @debug
  rerunQuery: (args = {}) ->
    args['pres'] = @result
    @result = null
    @runQuery args
  runQuery: (args = {}) ->
    args["i"] = @iterationNumber
    return if @result isnt null
    if typeof @srv is 'string'
      @srv = if @srv is "" then document.getElementsByTagName("kdb-srv")?[0] else document.querySelector "[k-id='#{@srv}']"
    console.log "kdb-query: executing query" if @debug
    @kQNum += 1
    @updateStatus()
    @srv.runQuery @resolveRefs(@query, args), (r,e) =>
      @kQNum -= 1
      console.log "kdb-query: got response with status #{e}" if @debug
      if e
        @updateStatus()
        @updObjWithRes o,document.querySelector("[k-id='#{o}']"),e for o in @updErr
      else
        r = (if typeof @kFilter is 'object' then @kFilter.filter r else @kFilter r) if @kFilter
        @result = r
        @updateStatus()
        @updateObjects()
        @sendEv()
      setTimeout (=> @rerunQuery src:"self", txt:"timer"), @kInterval if @kInterval and 'timer' in @exec
    @iterationNumber += 1
  sendEv: -> @dispatchEvent @getEv() if @result isnt null
  getEv: ->
    new CustomEvent "newResult",
      detail: if @kDispUpd then @result[""] else @result
      bubbles: true
      cancelable: true
  onresult: (f) ->
    @addEventListener 'newResult', f
    f @getEv() if @result isnt null
  setQueryParams: (o,c2) ->
    return c2 unless attrs = o.attributes['k-attr']?.textContent
    c1 = {}
    c1[n] = o.attributes[n].textContent || "" for n in attrs.split(' ').filter((e)-> e.length > 0)
    mergeCfgs c1,c2
  addUpdater: (v,kid) ->
    if v.nodeName is 'BUTTON'
      v.addEventListener 'click', (ev) => @rerunQuery @setQueryParams v, src:'button', id: kid
    else if v.nodeName is 'KDB-EDITOR'
      v.onexec (ev) => @rerunQuery @setQueryParams v, src:'editor', id: kid, txt: ev.detail
    else if v.nodeName is 'KDB-QUERY'
      v.onresult (ev) => @rerunQuery @setQueryParams v, src:'query', id: kid, txt: ev.detail
    else if v.nodeName in ['SELECT','TEXTAREA','INPUT']
      v.addEventListener 'change', (ev) => @rerunQuery @setQueryParams v, src:v.nodeName, id: kid, txt: extractInfo v
    else
      v.addEventListener 'click', (ev) => @rerunQuery @setQueryParams v, src:v.nodeName, id: kid, txt: if (typeof ev.kdetail isnt "undefined" and ev.kdetail isnt null) then ev.kdetail else  ev.target?.textContent
  kdbUpd: (r,kid) -> @rerunQuery  src:'query', id: kid, txt: r
  updateStatus: ->
    if @kQStatus
      a = new Function "x",@kQStatus+" = x"
      try
        a(@kQNum)
      catch
        null
    return
  updateObjects: ->
    @updateObj o,true,document.querySelector "[k-id='#{o}']" for o in @updObjs
    if @kDispUpd
      if typeof @result isnt 'object'
        console.error "kdb-query: dictionary is expected with dispatch setting"
        return console.log @result
      @updateObj n,false,document.querySelector "[k-id='#{n}']" for n of @result when n
  updateObj: (n,isUpd,o) ->
    r = if @kDispUpd then @result[if isUpd then "" else n] else @result
    return if r is undefined
    @updObjWithRes n,o,r
  updObjWithRes: (n,o,r) ->
    if !o
      a = new Function "x",n+" = x"
      try
        a(r)
      catch
        null
      return
    if o.kdbUpd
      try
        o.kdbUpd r, @kID
      catch err
        console.log "kdb-query:exception in kdbUpd"
        console.log err
    else if o.nodeName in ['SELECT','DATALIST']
      o.innerHTML = ''
      for e,i in r
        opt = document.createElement 'option'
        opt.value = e.toString()
        opt.text = e.toString()
        o.appendChild opt
    else if o.nodeName in ['KDB-CHART','KDb-TABLE','KDB-EDITOR'] # not inited
      setTimeout (=> o.kdbUpd r,@kID),0
    else
      a = o.attributes['k-append']?.textContent || 'overwrite'
      ty = o.attributes['k-content-type']?.textContent || 'text'
      s = if o.textContent then '\n' else ''
      if ty is 'text'
        if a is 'top' then o.textContent = r.toString()+s+o.textContent else if a is 'bottom' then o.textContent += s+r.toString() else o.textContent = r.toString()
      else
        return o.innerHTML = r.toString() if a is 'overwrite'
        if a is 'top' then o.insertAdjacentHTML 'afterBegin', r.toString()+s else o.insertAdjacentHTML 'beforeEnd', s+r.toString()
  resolveRefs: (q,args)->
    console.log args if @debug
    return q unless @kRefs
    if !@kMap
      @kMap = {}
      @kMap[e] = null for e in @kRefs
      @kMap[e] = document.querySelector "[k-id='#{e}']" for e of @kMap
    for n,v of @kMap
      if !v
        val = args[n]
        val = keval n if val is null or val is undefined
        txt = if val is null or val is undefined then n else val.toString()
      else
        txt = extractInfo v
      q = q.replace (new RegExp "\\$#{n.replace /(\[|\])/g,"."}\\$", "g"), @escape txt
    console.log "kdb-query: after resolve - #{q}" if @debug
    q
  escape: (s) -> if @escapeQ then s.replace(/\\/g,"\\\\").replace(/"/g,'\\"').replace(/\240/g," ").replace(/\n/g,"\\n") else s

class _KDBTable extends HTMLElement
  createdCallback: ->
    @srv = @attributes['k-srv']?.textContent || ""
    @query = @attributes['k-query']?.textContent || @textContent
    @kLib = @attributes['k-lib']?.textContent || 'table'
    @debug = @attributes['debug']?.textContent || null
    @escHtml = (@attributes['k-escape-html']?.textContent || 'true') == 'true'
    @kConfig = @attributes['k-config']?.textContent
    @kClass = @attributes['k-class']?.textContent || "kdb-table"
    @kStyle = @attributes['k-style']?.textContent || ""
    @kSearch = (@attributes['k-search']?.textContent || 'false') == 'true'
    @inited = false
    if @kLib in ['jsgrid','datatables']
      @kCont = document.createElement if @kLib is 'jsgrid' then 'div' else 'table'
      cont = document.createElement 'div'
      cont.className = @kClass
      cont.style.cssText = @kStyle
      @kCont.style.cssText = "width: 100%;" if @kLib is 'datatables'
      cont.appendChild @kCont
      this.appendChild cont
    console.log "kdb-table: srv: #{@srv}, query: #{@query}, lib:#{@kLib}" if @debug
  attachedCallback: ->
    if !@inited
      console.log "kdb-table: initing" if @debug
      @inited = true
      return if @query is ""
      if /\w+/.test @query
        @query = srv if srv = document.querySelector "[k-id='#{@query}']"
      if typeof @query is 'string'
        console.log "kdb-table: creating a query" if @debug
        q = new KDB.KDBQuery()
        q.setAttribute 'k-query', @query
        q.setAttribute 'k-srv', @srv if @srv
        q.setAttribute 'debug', @debug if @debug
        q.setupQuery()
        @query = q
      return unless @query?.runQuery
      @query.onresult (ev) => @onResult ev
      console.log "kdb-table: init complete" if @debug
      if @kLib in ['jsgrid','datatables'] and @kConfig
        cfg = getConfig @kConfig
        return unless cfg?.pageLoading or cfg?.serverSide
        console.log "kdb-table: pageLoading/serverSide is set, forcing the first page" if @debug
        @query.rerunQuery start: 0, size: 1, sortBy:"", sortOrder:"", data: null
  onResult: (ev) ->
    console.log "kdb-table: got event" if @debug
    @updateTbl ev.detail
  kdbUpd: (r) -> @updateTbl r
  updateTbl: (r) ->
    console.log "kdb-table: data" if @debug
    console.log r if @debug
    return @updateJSGrid r if @kLib is 'jsgrid' and @kCfg?.pageLoading
    return @updateDT r if @kLib is 'datatables' and @kCfg?.serverSide
    return if (r.length || 0) is 0
    return @updateJSGrid r if @kLib is 'jsgrid'
    return @updateDT r if @kLib is 'datatables'
    tbl = "<table class='#{@kClass}' style='#{@kStyle}'><tr>"
    tbl += "<th>#{@escapeHtml c}</th>" for c of r[0]
    tbl += "</tr>"
    for e in r
      tbl += "<tr>"
      tbl += "<td>#{@escapeHtml d}</td>" for c,d of e
      tbl += "</tr>"
    tbl += "</table>"
    @innerHTML = tbl
  updateJSGrid: (r) ->
    if @kCfg?.pageLoading
      return @kPromise.resolve r
    @kData = r
    f = []
    for n,v of r[0]
      if typeof v is 'string'
        f.push name:n, type: "text"
      else if typeof v is 'number'
        f.push name:n, type: "number"
      else if typeof v is 'boolean'
        f.push name:n, type: "checkbox"
      else if v instanceof Date
        f.push name:n, type: "text", subtype: 'date', itemTemplate: (v) -> v.toISOString()
      else
        f.push name:n, type: "text"
    cfg =
      width: '100%'
      height: '100%'
      filtering: @kSearch
      sorting: true
      paging: r.length>100
      pageButtonCount: 5
      pageSize: 50
      fields: f
      controller: loadData: (a) => @loadData a
    cfg = mergeCfgs cfg, getConfig @kConfig if @kConfig
    if cfg.pageLoading
      cfg.paging = true
      cfg.autoload = true
    else
      cfg.data = r
    @kCfg = cfg
    console.log "kdb-table: cfg" if @debug
    console.log cfg if @debug
    $(@kCont).jsGrid cfg
  updateDT: (r) ->
    if @kCfg?.serverSide
      @kCB r
      return @kCB = null
    c = []
    for n,v of r[0]
      c.push data: n, title: n
    cfg =
      columns: c
      searching: @kSearch
      scrollX: true
      processing: true
    cfg = mergeCfgs cfg, getConfig @kConfig if @kConfig
    @kCfg = cfg
    cfg.paging = r.length>100 or (cfg.serverSide || false) unless cfg.paging?
    if cfg.serverSide
      cfg.ajax = (d,cb,set) =>
        @kCB = cb
        @query.rerunQuery data: JSON.stringify d
    else
      cfg.data = r
    if @debug
      console.log "kdb-table: cfg"
      console.log cfg
    $(@kCont).DataTable cfg
  loadData: (f) ->
    if f.pageIndex
      @query.rerunQuery start: (f.pageIndex-1)*f.pageSize, size: f.pageSize, sortBy: f.sortField or "", sortOrder: f.sortOrder or 'asc'
      @kPromise = $.Deferred()
      return @kPromise
    return @kData.filter (e) =>
      r = true
      for v in @kCfg.fields
        if v.type is "text" and v.subtype is 'date'
          r = r and (!f[v.name] or -1<e[v.name].toISOString().indexOf f[v.name])
        else if v.type is "text"
          r = r and (!f[v.name] or -1<e[v.name].indexOf f[v.name])
        else if v.type is "number"
          r = r and (!f[v.name] or 1>Math.abs e[v.name] - f[v.name])
        else
          r = r and (f[v.name] is undefined or e[v.name] is f[v.name])
      r
  escapeHtml: (s) ->
    s = if s then s.toString() else ""
    if @escHtml then s.replace(/&/g, '&amp;').replace(/"/g, '&quot;').replace(/</g, '&lt;').replace(/>/g, '&gt;') else s

class _KDBChart extends HTMLElement
  createdCallback: ->
    @srv = @attributes['k-srv']?.textContent || ""
    @query = @attributes['k-query']?.textContent || @textContent
    @debug = @attributes['debug']?.textContent || null
    @kFlow = (@attributes['k-flow']?.textContent || "false") is "true"
    @kConfig = @attributes['k-config']?.textContent
    kClass = @attributes['k-class']?.textContent || ""
    kStyle = @attributes['k-style']?.textContent || ""
    @kChType = @attributes['k-chart-type']?.textContent || "line"
    @kTime = @attributes['k-time-col']?.textContent
    @kData = @attributes['k-data-cols']?.textContent.split(' ').filter (el) -> el.length>0
    @inited = false
    @chart = null
    @chSrc = ''
    @kCont = document.createElement 'div'
    @kCont.className = kClass
    @kCont.style.cssText = kStyle
    @kDygraph = /^dygraph/.test @kChType
    @kChType = @kChType.match(/^dygraph-(.*)$/)?[1] || 'line' if @kDygraph
    this.appendChild @kCont
    console.log "kdb-chart: query:#{@query}, type:#{@kChType}, cfg:#{@kConfig}" if @debug
  attachedCallback: ->
    if !@inited
      console.log "kdb-chart: initing" if @debug
      @inited = true
      return if @query is ""
      if /\w+/.test @query
        @query = srv if srv = document.querySelector "[k-id='#{@query}']"
      if typeof @query is 'string'
        console.log "kdb-chart: creating a query" if @debug
        q = new KDB.KDBQuery()
        q.setAttribute 'k-query', @query
        q.setAttribute 'k-srv', @srv if @srv
        q.setAttribute 'debug', @debug if @debug
        q.setupQuery()
        @query = q
      return unless @query?.runQuery
      @query.onresult (ev) => @onResult ev
      console.log "kdb-chart: init complete" if @debug
  onResult: (ev) ->
    console.log "kdb-chart: got event" if @debug
    console.log ev.detail if @debug
    @updateChart ev.detail
  kdbUpd: (r) ->
    console.log "kdb-chart: got update" if @debug
    console.log r if @debug
    @updateChart r
  updateDyChart: (r) ->
    if @chart and @kFlow
      console.log "Flow update" if @debug
      data = r if @chSrc is 'dy'
      data = @convertDyAllTbl r if @chSrc is 'user'
      data = (@convertDyTbl r,@dtCfg.time,@dtCfg.data)[1] if @chSrc is 'auto'
      console.log data if @debug
      @dyData = (@dyData.concat data).slice data.length
      return @chart.updateOptions file: @dyData
    if @kChType is 'use-config'
      return unless @kConfig and typeof r is 'object'
      return if r.length is 0
      console.log "kdb-chart: will use provided cfg" if @debug
      cfg = getConfig @kConfig
      data = @convertDyAllTbl r
      @chSrc = 'user'
    else
      if typeof r is 'object' and r.length is 2 and (r[0] instanceof Array or typeof r[0] is 'string') # raw config
        console.log 'kdb-chart: raw config' if @debug
        data = r[0]
        cfg = r[1]
        @chSrc = 'dy'
      else
        console.log "Will detect the user format" if @debug
        return unless tm = @detectTime r[0]
        console.log "Time is #{tm}" if @debug
        dt = @detectData r[0]
        console.log "Data is #{dt}" if @debug
        @dtCfg = data: dt, time: tm
        return if dt.length is 0
        r = @convertDyTbl r,tm,dt
        data = r[1]
        cfg = labels: r[0]
        @chSrc = 'auto'
    if @kChType is 'merge-config'
      console.log "kdb-chart: will merge cfgs" if @debug
      cfg = mergeCfgs cfg, getConfig @kConfig
    if typeof data is 'string'
      cfg = mergeCfgs cfg,
        xValueParser: (d) => @convDyTime d
        axes:
          x:
            valueFormatter: Dygraph.dateString_
            ticker: Dygraph.dateTicker
    console.log "kdb-chart: cfg is" if @debug
    console.log cfg if @debug
    console.log data if @debug
    @dyData = data if @kFlow
    return @updateDyChartWithData data,cfg
  updateDyChartWithData: (d,c) -> @chart = new Dygraph @kCont,d,c
  updateChart: (r) ->
    return @updateDyChart r if @kDygraph
    if @chart and @kFlow
      if @chSrc is 'c3'
        return @updateFlowWithData r
      tbl = r
      cfg = {}
      if r['data']
        cfg.to = r.to if r.to
        cfg.length = r.length if r.length
        cfg.duration = r.duration if r.duration
        tbl = r.data
      cfg.rows = @convertAllTbl tbl if @chSrc is 'user'
      cfg.rows = @convertTbl tbl,@dtCfg.time,@dtCfg.data if @chSrc is 'auto'
      cfg.columns = ([n].concat v for n,v of tbl) if @chSrc is 'dict'
      return @updateFlowWithData cfg
    if @kChType is 'use-config'
      return unless @kConfig and typeof r is 'object'
      return if r.length is 0
      console.log "kdb-chart: will use provided cfg" if @debug
      cfg = getConfig @kConfig
      cfg.data.rows = @convertAllTbl r
      @chSrc = 'user'
    else if typeof r is 'object' and r.data
      console.log "C3 format detected" if @debug
      console.log r if @debug
      @chSrc = 'c3'
      return @updateChartWithData r
    else if typeof r is 'object' and r.length>0
      # detect format
      console.log "Will detect the user format" if @debug
      return unless tm = @detectTime r[0]
      fmt = @detectTimeFmt r[0][tm]
      xfmt = @detectTimeXFmt r, tm, fmt
      console.log "Time is #{tm}, fmt is #{fmt}, xfmt is #{xfmt}" if @debug
      dt = @detectData r[0]
      console.log "Data is #{dt}" if @debug
      @dtCfg = data: dt, time: tm
      return if dt.length is 0
      cfg =
        data:
          x: tm
          rows: @convertTbl r,tm,dt
          type: @kChType
          xFormat: fmt
        point:
          show: false
        axis:
          x:
            type: 'timeseries'
            tick:
              fit: true
              format: xfmt
      @chSrc = 'auto'
    else if typeof r is 'object'
      # pie
      t = @attributes['k-chart-type']?.textContent || "pie"
      d = ([n].concat v for n,v of r)
      cfg =
        data:
          columns: d
          type: t
      @chSrc = 'dict'
    if @kChType is 'merge-config'
      console.log "kdb-chart: will merge cfgs" if @debug
      cfg = mergeCfgs cfg, getConfig @kConfig
    console.log "kdb-chart: cfg is" if @debug
    console.log cfg if @debug
    return @updateChartWithData cfg
  updateChartWithData: (d) ->
    d['bindto'] = @kCont
    @chart = c3.generate d
  updateFlowWithData: (d) -> @chart.flow d
  convertTbl: (t,tm,dt) ->
    cols = []
    for n of t[0]
      cols.push n if n is tm or n in dt
    rows = [cols]
    for rec in t
      rows.push ((if n is tm then @convTime(rec[n]) else rec[n]) for n in cols)
    rows
  convertDyTbl: (t,tm,dt) ->
    cols = [tm]
    for n of t[0]
      cols.push n if n in dt
    rows = []
    for rec in t
      rows.push ((if n is tm then @convDyTime(rec[n]) else rec[n]) for n in cols)
    [cols,rows]
  convertAllTbl: (t) ->
    t = [t] unless t.length
    cols = []; fmts = []
    for n,v of t[0]
      cols.push n
      fmts[n] = d3.time.format f if f = @detectTimeFmt v
    rows = [cols]
    for rec in t
      rows.push ((if fmts[n] then (fmts[n].parse @convTime rec[n]) else rec[n]) for n in cols)
    rows
  convertDyAllTbl: (t) ->
    t = [t] unless t.length
    rows = []
    cols = (n for n of t[0])
    for rec in t
      rows.push ((if i is 0 then @convDyTime(rec[n]) else rec[n]) for n,i in cols)
    rows
  detectData: (r) ->
    return @kData if @kData
    for n,v of r
      return [n] if typeof v is 'number' or v instanceof Number
    []
  detectTime: (r) ->
    return @kTime if @kTime and r[@kTime]
    t = null
    for n,v of r
      return n if v instanceof Date
      return n if typeof v is 'string' and @detectTimeFmt v
      t = n if !t and v instanceof Number
    t
  detectTimeFmt: (v) ->
    return ((d) -> d) if v instanceof Date
    return '%H:%M:%S.%L' if /^\d\d:\d\d:\d\d\.\d\d\d/.test v
    return '%Y-%m-%dT%H:%M:%S.%L'if /^\d\d\d\d[-\.]\d\d[-\.]\d\d[DT]\d\d:\d\d:\d\d\.\d\d\d/.test v
    return '%Y-%m-%d' if /^\d\d\d\d-\d\d-\d\d/.test v
    return '%Y.%m.%d' if /^\d\d\d\d\.\d\d\.\d\d/.test v
    return '%jT%H:%M:%S.%L' if /^\d+D\d\d:\d\d:\d\d\.\d\d\d/.test v
    return '%H:%M:%S' if /^\d\d:\d\d:\d\d/.test v
    return '%H:%M' if /^\d\d:\d\d/.test v
  detectTimeXFmt: (r,tm,f) ->
    return f if typeof f is 'string' and f.length<12
    if typeof f is 'string'
      fmt = d3.time.format f
      f = (d) -> fmt.parse d
    i = Math.abs (f @convTime r[r.length-1][tm])-(f @convTime r[0][tm])
    return '%H:%M:%S.%L' if i < 86400000
    '%Y.%m.%dT%H:%M'
  convTime: (d) ->
    return d unless typeof d is 'string' and d.length>=20
    d = d.slice(0,-6) unless d[d.length-4] is "."
    d = d.replace('.','-').replace('.','-') if d[4] is '.'
    d.replace('D','T')
  convDyTime: (d) ->
    return d unless typeof d is 'string'
    return Number d unless 0<=d.indexOf(':') or (d[4] is '.' and d[7] is '.') or d[4] is '-'
    d = d.replace('.','-').replace('.','-') if d[4] is '.' # make date like 2010-10-10
    d = d.replace('D','T') if 0<=d.indexOf "D" # change D to T
    d = d.match(/^\d+T(.*)$/)[1] unless d[4] is '-' or d[2] is ':' # timespan - remove span completely
    d = "2000-01-01T"+d if d[2] is ':'
    new Date d

class _KDBEditor extends HTMLElement
  createdCallback: ->
    @query = @attributes['k-query']?.textContent
    @debug = @attributes['debug']?.textContent || null
    @kConfig = @attributes['k-config']?.textContent
    kClass = "k-ace-editor "+(@attributes['k-class']?.textContent || "")
    kStyle = @attributes['k-style']?.textContent || ""
    @kEditor = null
    @kCont = document.createElement 'pre'
    @kCont.className = kClass
    @kCont.style.cssText = kStyle
    @kCont.textContent = this.textContent
    @kMarkers = null
    this.innerHTML = ''
    this.appendChild @kCont
    console.log "kdb-editor: query: #{@query}" if @debug
  attachedCallback: ->
    @kEditor = ace.edit @kCont
    @query = srv if srv = document.querySelector "[k-id='#{@query}']"
    @setCfg()
    if @query?.runQuery
      @query.onresult (ev) => @onResult ev
  onResult: (ev) ->
    console.log "kdb-editor: got event" if @debug
    console.log ev.detail if @debug
    @kdbUpd ev.detail
  setCfg: ->
    cfg =
      theme: 'ace/theme/textmate'
      mode: 'ace/mode/q'
      readOnly: true
      scrollPastEnd: false
      fadeFoldWidgets: false
      behavioursEnabled: true
      useSoftTabs: true
      animatedScroll: true
      verticalScrollBar: false
      horizontalScrollBar: false
      highlightSelectedWord: true
      showGutter: true
      displayIndentGuides: false
      showInvisibles: false
      highlightActiveLine: true
      selectionStyle: 'line' # line or text - how looks the selection decoration
      wrap: 'off' # off 40 80 free (til end of box)
      foldStyle: 'markbegin' # markbegin markbeginend manual
      fontSize: 12
      keybindings: 'ace' # ace emacs vim
      showPrintMargin: true
      useElasticTabstops: false
      useIncrementalSearch: false
      execLine: win: 'Ctrl-Return', mac: 'Command-Return'
      execSelection: win: 'Ctrl-e', mac: 'Command-e'
    cfg = mergeCfgs cfg, getConfig @kConfig if @kConfig
    console.log "kdb-editor: config" if @debug
    console.log cfg if @debug
    @kCfg = cfg
    @kEditor.setTheme cfg.theme
    @kEditor.getSession().setMode cfg.mode
    @kEditor.setReadOnly cfg.readOnly
    @kEditor.setOption "scrollPastEnd", cfg.scrollPastEnd
    @kEditor.setFadeFoldWidgets cfg.fadeFoldWidgets
    @kEditor.setBehavioursEnabled cfg.behavioursEnabled
    @kEditor.session.setUseSoftTabs cfg.useSoftTabs
    @kEditor.setAnimatedScroll cfg.animatedScroll
    @kEditor.setOption "vScrollBarAlwaysVisible", cfg.verticalScrollBar
    @kEditor.setOption "hScrollBarAlwaysVisible", cfg.horizontalScrollBar
    @kEditor.setHighlightSelectedWord cfg.highlightSelectedWord
    @kEditor.renderer.setShowGutter cfg.showGutter
    @kEditor.setDisplayIndentGuides cfg.displayIndentGuides
    @kEditor.setShowInvisibles cfg.showInvisibles
    @kEditor.setHighlightActiveLine cfg.highlightActiveLine
    @kEditor.setOption "selectionStyle", cfg.selectionStyle
    @kEditor.setOption "wrap", cfg.wrap
    @kEditor.session.setFoldStyle cfg.foldStyle
    @kEditor.setFontSize cfg.fontSize
    @kEditor.setKeyboardHandler cfg.keybindings unless cfg.keybindings is 'ace'
    @kEditor.renderer.setShowPrintMargin cfg.showPrintMargin
    @kEditor.setOption "useElasticTabstops", cfg.useElasticTabstops if cfg.useElasticTabstops
    @kEditor.setOption "useIncrementalSearch", cfg.useIncrementalSearch if cfg.useIncrementalSearch
    @setCommands()
  kdbUpd: (r) ->
    if @debug
      console.log "kdb-editor update"
      console.log r
    cfg = null
    if typeof r is 'object' and !Array.isArray r
      cfg = r
      r = cfg.text
    if typeof r is 'string' or Array.isArray r
      a = @attributes['k-append']?.textContent || 'overwrite'
      if a is 'overwrite'
        @kEditor.setValue r, 0
        if @kMarkers
          @kEditor.getSession().removeMarker m for m in @kMarkers
          @kMarkers = null
        @kEditor.getSession().clearAnnotations()
        @kEditor.getSession().clearBreakpoints()
      else if a is 'top'
        @kEditor.navigateFileStart()
        @kEditor.insert r
      else
        @kEditor.navigateFileEnd()
        @kEditor.navigateLineEnd()
        @kEditor.insert r
      @kEditor.navigateTo 0,0
    if cfg
      if cfg.row?
        @kEditor.scrollToLine (cfg.row or 0), true, true, null
        @kEditor.navigateTo (cfg.row or 0),(cfg.column or 0)
      if cfg.markers?
        (@kEditor.getSession().removeMarker m for m in @kMarkers) if @kMarkers
        Range = ace.require('./range').Range
        @kMarkers = (@kEditor.getSession().addMarker new Range(m.xy[0],m.xy[1],m.xy[2],m.xy[3]), m.class, m.type || "text", false for m in cfg.markers)
      if cfg.annotations?
        @kEditor.getSession().setAnnotations cfg.annotations
      if cfg.breakpoints?
        @kEditor.getSession().setBreakpoints cfg.breakpoints
  setCommands: ->
    @kEditor?.commands.addCommands [
      (name: "execLine", bindKey: @kCfg.execLine, readOnly: true, exec: (e) => @execLine e)
      name: "execSelection", bindKey: @kCfg.execSelection, readOnly: true, exec: (e) => @execSelection e
    ]
  execLine: (e) ->
    return unless l = @kEditor.getSession().getLine @kEditor.getCursorPosition().row
    console.log "exec line: #{l}" if @debug
    @sendEv l
  execSelection: (e) ->
    return unless s = @kEditor.getSelectedText()
    console.log "exec select: #{s}" if @debug
    @sendEv s
  sendEv: (s) -> @dispatchEvent @getEv(s)
  getEv: (s) ->
    new CustomEvent "execText",
      detail: s
      bubbles: true
      cancelable: true
  onexec: (f) -> @addEventListener 'execText', f

window.KDB ?= {}
KDB.processJSONP = (id,res) ->
  console.log "kdb-srv(JSONP): #{id}" + res if @debug
  jsonpRegistry[id]?(res)
KDB.rerunQuery = (kID,args) -> document.querySelector("[k-id='#{kID}']")?.rerunQuery args
KDB.KDBChart = document.registerElement('kdb-chart', prototype: _KDBChart.prototype)
KDB.KDBSrv = document.registerElement('kdb-srv', prototype: _KDBSrv.prototype)
KDB.KDBQuery = document.registerElement('kdb-query', prototype: _KDBQuery.prototype)
KDB.KDBTable = document.registerElement('kdb-table', prototype: _KDBTable.prototype)
KDB.KDBEditor = document.registerElement('kdb-editor', prototype: _KDBEditor.prototype)
