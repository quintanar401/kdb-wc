### KDB+ Web Components

# Introduction

The purpose of this library is to facilitate access to KDB+ servers from the modern web browsers as much as possible. In the extreme case all you need to do is just add two html tags
without any settings to an html page (and kdb-wc.js script) and data will be loaded and added to the page automatically.

```
<kdb-srv></kdb-srv>
<kdb-table>([] sym: 50?(5?`5);time:.z.T+til[50]*00:00:10; price: 50?40*50?1.0)</kdb-table>
```

This library is based on the new HTML5 feature - web components - entities that look like the ordinary html tags but can encapsulate arbitrary logic and perform complex tasks behind the scene. Currently not all browsers support them or enable this functionality by default thus you may need to include `document-register-element.js` library (can be found in external directory) that provides the same functionality (it is used in all examples).

This library is not intended for the production, it lacks any security, robustness and etc. It is intended for presentations, prototyping, visualizing datasets.

# Requirements

The library should work with IE10 (maybe IE9 too), the latest Firefox and Chrome and probably all other modern browsers.

Some other libraries may be needed:
* [`document-register-element.js`](https://github.com/WebReflection/document-register-element) - required if document.registerElement is not supported.
* [`c.js`](http://code.kx.com/wsvn/code/kx/kdb%2B/c/c.js) - serialization/deserialization of KDB objects for Websocket.
* [`c3`](http://c3js.org) - charts library C3.
* [`d3`](https://d3js.org/) - charts library D3 (C3 is based on it).

All libraries can be found in `external` directory.

# Components

## kdb-srv

The core of the library is `kdb-srv` component. It allows users to execute arbitrary queries either via an Ajax http request or via a websocket. It supports string and binary protocols for websockets and json, xml and sting data formats.

`kdb-srv` can be used with the default .z.ph handler. You may need to add `fix-json` attribute if your .z.ph fails to process queries like 'json? query'.

Websockets allow you to connect to any server not just the default one. You can even load your page as 'file://' and still be able to use them. You should though set the correct ws handler on the target server because the default .z.ws does nothing - use `srv.q` as an example.

Example:
```
<kdb-srv k-srv-type="ws" k-srv-uri="localhost:5566" debug="true"></kdb-srv>
```

Supported attributes:
* `k-return-type` - optional, `json` by default. Data format returned by the server. It can be `json`, `xml`, `q` or `txt`. Websockets support `json` and `q`. Http - `json`, `xml`, `txt`.
* `k-srv-type` - optional, ws or http (default).
* `k-srv-uri` - optional, target websocket server. Format: "host:port". By default it is the current web server.
* `k-srv-user` - optional, a user for http requests.
* `k-srv-pass` - optional, a password for http requests.
* `k-target` - optional, a server name or `k-id` of an element with this name. It can be used with `srv.q` to turn it into a proxy. Queries will be executed via `srv.q` on another server.
* `k-prefix` - optional, a prefix to be added to every query. `xml? ` for example. It is set to either `json? ` or `jsn? ` if it is not provided and the result type is `json`.
* `k-id` - optional, this id can be used to link other components to this one.
* `fix-json` - optional, if it is set kdb-srv will send an additional query to fix a json serialization issue in the default .z.ph in kdb+ 3.2(it will set .h.tx[\`jsn] to .j.j').
* `debug` - optional. Can be set to true to see debug prints in the browser console.

Api:
* `runQuery(query,callBack)` or `runQuery(query)` - execute a query and return the result via `callBack`. `callBack` is optional and should accept two parameters - result and error.

## kdb-query

`kdb-query` encapsulates a query, searches for its parameters, executes it, distributes the result to its consumers. It can be attached to only one `kdb-srv` but can be used by many data consumers.

`kdb-table` and `kdb-chart` components can create `kdb-query` implicitly.

Example:
```
<kdb-query k-id="q1" k-update-elements="pre" debug="true">.Q.s
 `select`txt`pass`check`radio`textarea`span!(`$s$;"$ft$";"$fp$";$fc$;`$fr$;"$fta$";$t$)</kdb-query>
```

You can provide parameters to the query by using $paramKID$ format. All such entries will be substituted with the target value. Supported targets include `select`, `textarea`, `input` with types `text`, `password`, `radio`, `checkbox` and any other element with the meaningful textContent (`span` for example). Also you can use $i$ to refer to the number of executions if `k-interval` is set.

`kdb-query` can update other elements with its result. The result should have the correct format - string for text elements, list of objects (table) for `kdb-table` and `kdb-chart`, string array for `select`. It can also update any element that has `kdbUpd` function.

Supported attributes:
* `k-query` - optional, a query can be set either in this attribute or between the tags like in the example above.
* `k-srv` - optional, link to a `kdb-srv`. If it is not set the first available `kdb-srv` component will be used.
* `k-execute-on` - optional, list of events that cause the query to execute. Contains only `load` by default. `load` - when the document is loaded, `manual` - do not execute, `timer` - use timer, `k-id` of a button - execute on click.
* `k-update-elements` - optional, users can either subscribe to `kdb-query` events or you can provide their `k-id` in this attribute, in this way you can update arbitrary html elements.
* `k-delay` - optional, in millis. With `timer` sets the delay for the first execution.
* `k-interval` - optional, in millis. With `timer` causes query to rerun every `interval` millis. The first query will be executed with the delay of either `k-delay` or this `interval`.
* `k-escape-q` - optional. If set forces `kdb-query` to escape " and \\ symbols in the query parameters (not query itself!).
* `k-id` - optional, this id can be used to link other components to this one.
* `debug` - optional. Can be set to true to see debug prints in the browser console.

There are attributes that `kdb-query` understands on its target elements:
* `k-append` - on text elements defines how the new result is added. Possible values: 'top', 'bottom', 'overwrite'.
* `k-id` - this id can be used to link other components to `kdb-query`.

Api:
* `onresult(f)` - subscribe to 'newResult' event. If the result is already ready then `f` will be called immediately. `f` should have one parameter - result.
* `setupQuery()` - call it after you change the attributes.
* `runQuery()` - run the query if it was not run before.
* `rerunQuery()` - rerun the query.

## kdb-table

`kdb-table` can be used to show a table. `kdb-table` relies on `kdb-query` to run the actual query. `kdb-query` can be set either with its `k-id` or created implicitly via `k-query` attribute or the content of the tag.

Example
```
<kdb-table>([] sym: 50?(5?`5);time:.z.T+til[50]*00:00:10; price: 50?40*50?1.0)</kdb-table>
```

Supported attributes:
* `k-srv` - optional, will be passed to `kdb-query` if it needs to be created.
* `k-query` - optional, `k-id` link to `kdb-query` or query text itself. If it is not present the content is used as in the example above.
* `k-id` - optional, this id can be used to link other components to this one.
* `k-escape-html` - escape or not HTML symbols in the result.
* `debug` - optional. Can be set to true to see debug prints in the browser console.

## kdb-chart

`kdb-chart` can be used to visualize data. It can work in the following modes:
* You can provide the full correct C3 config. Absolutely all C3 features are available. See chart example.
* If the result is a table `kdb-chart` can determine params (time and data) itself. If it succeeds it will create a timeseries chart.
* If the result is a table you can also set explicitly data and time columns and line type.
* If the result is a dictionary `kdb-chart` will create a pie chart (type can be changed to donut or gauge).
* If you set type to 'merge-config' it will merge the provided config with its own config, in this way you can add additional params to the C3 config.
* Finally you can set type to 'use-config' and `kdb-chart` will use your config and insert data into it. This gives you full control like in the first item.

Example:
```
<kdb-query k-update-elements='c2' debug="true">update ask:bid+30?0.5 from
   ([] time1:.z.T; time:(00:00:01*til 30)+.z.T; bid:50+30?5.0)</kdb-query>
<kdb-chart k-style='width:800px;height:400px;' k-id="c2" k-time-col="time"
   k-data-cols="ask bid" k-chart-type="spline" debug="true"></kdb-chart>

<kdb-query k-update-elements='c1' debug="true">enlist[`data]!enlist enlist[`columns]!
   enlist (("data1";30;200;100;400;150;250);("data2";50;20;10;40;15;25))</kdb-query>
<kdb-chart k-style='width:800px;height:400px;' k-id="c1"></kdb-chart>
```

It is quite easy to set a C3 config - you just literaly translate it from json to dictionaries and set required data. In the example above you can see how it can be done. In examples you can find other examples of this conversion.

In case you want just visualize some simple table remember this - if you do not set time column explicitly put it before other time-like columns. The same is true for the data column(s). `kdb-chart` searches for the first good enough column.

Supported attributes:
* `k-srv` - optional, will be passed to `kdb-query` if it needs to be created.
* `k-query` - optional, `k-id` link to `kdb-query` or query text itself. If it is not present the content of the tag is used.
* `k-class` - optional, classes to pass to the wrapper.
* `k-style` - optional, style to set to the wrapper.
* `k-chart-type` - optional, chart type as in C3 manual. 'line', 'spline' and etc.
* `k-time-col` - optional, time column.
* `k-data-cols` - optional, data columns.
* `k-flow` - optional, if true the chart will be updated with the new data on every update. See examples and C3 flow help/example.
* `k-id` - optional, this id can be used to link other components to this one.
* `debug` - optional. Can be set to true to see debug prints in the browser console.


# Examples

Examples can be used to quickly overview all available functionality. Simply start srv.q:
```
q srv.q
```
And enter `localhost:5566/index.html` in your browser.
