ace.define("ace/mode/q_highlight_rules",["require","exports","module","ace/lib/oop","ace/mode/text_highlight_rules"], function(require, exports, module) {
"use strict"

var oop = require("../lib/oop");
var TextHighlightRules = require("./text_highlight_rules").TextHighlightRules;

var qHighlightRules = function() {
    var keywordControl = "do|if|while|select|update|delete|exec|from|by";
    var keywordOperator = "and|or|except|inter|like|each|cross|vs|sv|within|where|in|asof|bin|binr|cor|cov|cut|ej|fby|div|ij|insert|lj|ljf|" +
	"mavg|mcount|mdev|med|mmax|mmin|mmu|mod|msum|over|prior|peach|pj|scan|scov|setenv|ss|sublist|uj|union|upsert|wavg|wsum|xasc|xbar|xcol|" +
	"xcols|xdesc|xexp|xgroup|xkey|xlog|xprev|xrank";
    var constantLanguage = "0[nNwW][hijefcpmdznuvt]?";
    var supportFunctions = "first|enlist|value|type|get|set|count|string|key|max|min|sum|prd|last|flip|distinct|raze|neg|til|upper|lower|abs|" +
	"acos|aj|aj0|not|null|any|asc|asin|attr|avg|avgs|ceiling|cols|cos|csv|all|atan|deltas|desc|differ|dsave|dev|eval|exit|exp|fills|fkeys|" +
	"floor|getenv|group|gtime|hclose|hcount|hdel|hopen|hsym|iasc|idesc|inv|keys|load|log|lsq|ltime|ltrim|maxs|md5|meta|mins|next|parse|plist|" +
	"prds|prev|rand|rank|ratios|read0|read1|reciprocal|reverse|rload|rotate|rsave|rtrim|save|sdev|show|signum|sin|sqrt|ssr|sums|svar|system|" +
	"tables|tan|trim|txf|ungroup|var|view|views|wj|wj1|ww";

    var keywordMapper = this.createKeywordMapper({
        "keyword.control": keywordControl,
        "keyword.operator": keywordOperator,
	"variable.language": "x|y|z",
        "support.function": supportFunctions
    }, "identifier");

    this.$rules = 
        {
    "start": [
        {
            token : "comment",
	    regex : "^/\\s*$",
	    next  : "mcomment"
        }, {
            token : "comment",
	    regex : "^\\\\\\s*$",
	    next  : "mmcomment"
	}, {
	    token : "constant.other",
	    regex : "^\\\\.*$"
	}, {
            token : "comment",
            regex : "(?:^/.*$|\\s+/.*$)"
        }, {
	    token : "string.double",
	    regex : '["](?:(?:\\\\.)|(?:[^"\\\\]))*?["]'
	}, {
	    token : "constant.numeric",
            regex : "(?:\\d+D|\\d\\d\\d\\d\\.[01]\\d\\.[0123]\\d[DT])(?:[01]\\d\\:[0-5]\\d(?:\\:[0-5]\\d(?:\\.\\d+)?)?|([01]\\d)?)[zpn]?\\b"
	}, {
	    token : "constant.numeric",
            regex : "[01]\\d\\:[0-5]\\d(?:\\:[0-5]\\d(\\.\\d+)?)?[uvtpn]?\\b"
	}, {
	    token : "constant.numeric",
	    regex : "\\d{4}\\.[01]\\d\\.[0-3]\\d[dpnzm]?\\b"
	}, {
            token : "constant.numeric", // float
            regex : "(?:(?:\\d+(?:\\.\\d*)?|\\.\\d+)[eE][+-]?\\d+|\\d+\\.\\d*|\\.\\d+)[efpnt]?"
        }, {
            token : keywordMapper,
            regex : "[a-zA-Z][a-zA-Z0-9]*\\b"
        }, {
	    token : "support.function",
	    regex : "\\.[z|Q|q|h|o]\\.[a-zA-Z]+"
	}, {
	    token : "support.function",
	    regex : "-[1-9][0-9]?\\s*!",
	}, {
	    token : "support.variable",
	    regex : "\\.[a-zA-Z][a-zA-Z0-9_\\.]*"
	}, {
	    token : "support.constant",
	    regex : "`\\:[\\:a-zA-Z0-9\\._/]*"
	}, {
	    token : "support.constant",
	    regex : "`(?:[a-zA-Z0-9\\.][\\:a-zA-Z0-9\\._]*)?"
	}, {
            token : "constant.numeric", // hex
            regex : "0x[0-9a-fA-F]+"
        }, {
	    token : "keyword.operator",
	    regex : "\\'|\\/\\:|\\\\\:|\\'\\:|\\\\|\\/|0\\:|1\\:|2\\:"
	}, {
	    token : "constant.language",  // nulls and infinities
	    regex : "0[nNwW][hijefcpmdznuvt]?\\b"
	}, {
            token : "constant.numeric", // number
	    regex : "\\d+[bhicjefpnuvt]?\\b"
	}, {
            token : "keyword.operator",
            regex : "(?:<=|>=|<>|::)|(?:\\$|%|&|\\@|\\.|\\_|\\#|\\*|\\^|\\-|\\+|\\+|~|\\,|!|>|<|=|\\||\\?|\\:)\\:?"
        }, {
            token : "punctuation.operator",
            regex : "\\;"
        }, {
            token : "paren.lparen",
            regex : "[\\[({]"
        }, {
            token : "paren.rparen",
            regex : "[\\])}]"
            // next  : "pcomment"
        }, {
            token : "text",
            regex : "\\s+"
        }
    ],
	    "pcomment": [
	    {
		    token : "comment",
		    regex : "/.*$",
		    next : "start"
	    },
	    {
		    token : "comment",
		    regex : "",
		    next : "start"
	    }
		    ],
	    "mcomment": [
	    {
		    token : "comment",
		    regex : "^\\\\\\s*$",
		    next  : "start"
	    }, {
		    token : "comment",
		    regex : ".*"
	    }
		    ],
            "mmcomment": [
	    {
		    token : "comment",
		    regex : ".*"
	    }
		    ]
	};

};

oop.inherits(qHighlightRules, TextHighlightRules);

exports.qHighlightRules = qHighlightRules;
});

ace.define("ace/mode/matching_brace_outdent",["require","exports","module","ace/range"], function(require, exports, module) {
"use strict";

var Range = require("../range").Range;

var MatchingBraceOutdent = function() {};

(function() {

    this.checkOutdent = function(line, input) {
        if (! /^\s*$/.test(line))
            return false;

        return /^\s*\}/.test(input);
    };

    this.autoOutdent = function(doc, row) {
        var line = doc.getLine(row);
        var match = line.match(/^(\s*\})/);

        if (!match) return 0;

        var column = match[1].length;
        var openBracePos = doc.findMatchingBracket({row: row, column: column});

        if (!openBracePos || openBracePos.row == row) return 0;

        var indent = this.$getIndent(doc.getLine(openBracePos.row));
	if (indent == '')  indent = ' ';
	if (column == 0) { column = 1; indent = ' }'};
        doc.replace(new Range(row, 0, row, column-1), indent);
    };

    this.$getIndent = function(line) {
        return line.match(/^\s*/)[0];
    };

}).call(MatchingBraceOutdent.prototype);

exports.MatchingBraceOutdent = MatchingBraceOutdent;
});

ace.define("ace/mode/behaviour/q",["require","exports","module","ace/lib/oop","ace/mode/behaviour","ace/token_iterator","ace/lib/lang"], function(require, exports, module) {
"use strict";

var oop = require("../../lib/oop");
var Behaviour = require("../behaviour").Behaviour;
var TokenIterator = require("../../token_iterator").TokenIterator;
var lang = require("../../lib/lang");

var SAFE_INSERT_IN_TOKENS =
    ["text", "paren.rparen", "punctuation.operator"];
var SAFE_INSERT_BEFORE_TOKENS =
    ["text", "paren.rparen", "punctuation.operator", "comment"];

var context;
var contextCache = {};
var initContext = function(editor) {
    var id = -1;
    if (editor.multiSelect) {
        id = editor.selection.index;
        if (contextCache.rangeCount != editor.multiSelect.rangeCount)
            contextCache = {rangeCount: editor.multiSelect.rangeCount};
    }
    if (contextCache[id])
        return context = contextCache[id];
    context = contextCache[id] = {
        autoInsertedBrackets: 0,
        autoInsertedRow: -1,
        autoInsertedLineEnd: "",
        maybeInsertedBrackets: 0,
        maybeInsertedRow: -1,
        maybeInsertedLineStart: "",
        maybeInsertedLineEnd: ""
    };
};

var getWrapped = function(selection, selected, opening, closing) {
    var rowDiff = selection.end.row - selection.start.row;
    return {
        text: opening + selected + closing,
        selection: [
                0,
                selection.start.column + 1,
                rowDiff,
                selection.end.column + (rowDiff ? 0 : 1)
            ]
    };
};

var CstyleBehaviour = function() {
    this.add("braces", "insertion", function(state, action, editor, session, text) {
        var cursor = editor.getCursorPosition();
        var line = session.doc.getLine(cursor.row);
        if (text == '{') {
            initContext(editor);
            var selection = editor.getSelectionRange();
            var selected = session.doc.getTextRange(selection);
            if (selected !== "" && selected !== "{" && editor.getWrapBehavioursEnabled()) {
                return getWrapped(selection, selected, '{', '}');
            } else if (CstyleBehaviour.isSaneInsertion(editor, session)) {
                // if (/[\]\}\)]/.test(line[cursor.column]) || editor.inMultiSelectMode) {
                    CstyleBehaviour.recordAutoInsert(editor, session, "}");
                    return {
                        text: '{}',
                        selection: [1, 1]
                    };
               // } else {
               //     CstyleBehaviour.recordMaybeInsert(editor, session, "{");
               //    return {
               //         text: '{',
               //         selection: [1, 1]
               //     };
               // }
            }
        } else if (text == '}') {
            initContext(editor);
            var rightChar = line.substring(cursor.column, cursor.column + 1);
            if (rightChar == '}') {
                var matching = session.$findOpeningBracket('}', {column: cursor.column + 1, row: cursor.row});
                if (matching !== null && CstyleBehaviour.isAutoInsertedClosing(cursor, line, text)) {
                    CstyleBehaviour.popAutoInsertedClosing();
                    return {
                        text: '',
                        selection: [1, 1]
                    };
                }
            }
        } else if (text == "\n" || text == "\r\n") {
            initContext(editor);
            var closing = "";
            // if (CstyleBehaviour.isMaybeInsertedClosing(cursor, line)) {
            //    closing = lang.stringRepeat("}", context.maybeInsertedBrackets);
            //    CstyleBehaviour.clearMaybeInsertedClosing();
            // }
            var rightChar = line.substring(cursor.column, cursor.column + 1);
            if (rightChar === '}') {
                var openBracePos = session.findMatchingBracket({row: cursor.row, column: cursor.column+1}, '}');
                if (!openBracePos)
                     return null;
                var next_indent = this.$getIndent(session.getLine(openBracePos.row));
		if (next_indent == "") next_indent=' ';
            // } else if (closing) {
            //    var next_indent = this.$getIndent(line);
            } else {
                CstyleBehaviour.clearMaybeInsertedClosing();
                return;
            }
            var indent = next_indent + session.getTabString();

            return {
                text: '\n' + indent + '\n' + next_indent + closing,
                selection: [1, indent.length, 1, indent.length]
            };
        } else {
            CstyleBehaviour.clearMaybeInsertedClosing();
        }
    });

    this.add("braces", "deletion", function(state, action, editor, session, range) {
        var selected = session.doc.getTextRange(range);
        if (!range.isMultiLine() && selected == '{') {
            initContext(editor);
            var line = session.doc.getLine(range.start.row);
            var rightChar = line.substring(range.end.column, range.end.column + 1);
            if (rightChar == '}') {
                range.end.column++;
                return range;
            } else {
                context.maybeInsertedBrackets--;
            }
        }
    });

    this.add("parens", "insertion", function(state, action, editor, session, text) {
        if (text == '(') {
            initContext(editor);
            var selection = editor.getSelectionRange();
            var selected = session.doc.getTextRange(selection);
            if (selected !== "" && editor.getWrapBehavioursEnabled()) {
                return getWrapped(selection, selected, '(', ')');
            } else if (CstyleBehaviour.isSaneInsertion(editor, session)) {
                CstyleBehaviour.recordAutoInsert(editor, session, ")");
                return {
                    text: '()',
                    selection: [1, 1]
                };
            }
        } else if (text == ')') {
            initContext(editor);
            var cursor = editor.getCursorPosition();
            var line = session.doc.getLine(cursor.row);
            var rightChar = line.substring(cursor.column, cursor.column + 1);
            if (rightChar == ')') {
                var matching = session.$findOpeningBracket(')', {column: cursor.column + 1, row: cursor.row});
                if (matching !== null && CstyleBehaviour.isAutoInsertedClosing(cursor, line, text)) {
                    CstyleBehaviour.popAutoInsertedClosing();
                    return {
                        text: '',
                        selection: [1, 1]
                    };
                }
            }
        }
    });

    this.add("parens", "deletion", function(state, action, editor, session, range) {
        var selected = session.doc.getTextRange(range);
        if (!range.isMultiLine() && selected == '(') {
            initContext(editor);
            var line = session.doc.getLine(range.start.row);
            var rightChar = line.substring(range.start.column + 1, range.start.column + 2);
            if (rightChar == ')') {
                range.end.column++;
                return range;
            }
        }
    });

    this.add("brackets", "insertion", function(state, action, editor, session, text) {
	var cursor = editor.getCursorPosition();
	var line = session.doc.getLine(cursor.row);
        if (text == '[') {
            initContext(editor);
            var selection = editor.getSelectionRange();
            var selected = session.doc.getTextRange(selection);
            if (selected !== "" && editor.getWrapBehavioursEnabled()) {
                return getWrapped(selection, selected, '[', ']');
            } else if (CstyleBehaviour.isSaneInsertion(editor, session)) {
		var txt = "[]";
		var t = line.substring(0,cursor.column);
		if (/.*(?:if|while|do)\s*/.test(t)) txt = txt + ';';
                CstyleBehaviour.recordAutoInsert(editor, session, "]");
                return {
                    text: txt,
                    selection: [1, 1]
                };
            }
        } else if (text == ']') {
            initContext(editor);
             var rightChar = line.substring(cursor.column, cursor.column + 1);
            if (rightChar == ']') {
                var matching = session.$findOpeningBracket(']', {column: cursor.column + 1, row: cursor.row});
                if (matching !== null && CstyleBehaviour.isAutoInsertedClosing(cursor, line, text)) {
                    CstyleBehaviour.popAutoInsertedClosing();
                    return {
                        text: '',
                        selection: [1, 1]
                    };
                }
            }
        } else if (text == "\n" || text == "\r\n") {
	    initContext(editor);
            var rightChar = line.substring(cursor.column, cursor.column + 1);
            if (rightChar === ']') {
                var openBrkPos = session.findMatchingBracket({row: cursor.row, column: cursor.column+1}, ']');
                if (!openBrkPos)
                     return null;
                var next_indent = this.$getIndent(session.getLine(openBrkPos.row));
            } else return;
            var indent = next_indent + session.getTabString();

            return {
                text: '\n' + indent + '\n' + next_indent,
                selection: [1, indent.length, 1, indent.length]
            };
	}
    });

    this.add("brackets", "deletion", function(state, action, editor, session, range) {
        var selected = session.doc.getTextRange(range);
        if (!range.isMultiLine() && selected == '[') {
            initContext(editor);
            var line = session.doc.getLine(range.start.row);
            var rightChar = line.substring(range.start.column + 1, range.start.column + 2);
            if (rightChar == ']') {
                range.end.column++;
                return range;
            }
        }
    });

    this.add("string_dquotes", "insertion", function(state, action, editor, session, text) {
        if (text == '"') {
            initContext(editor);
            var quote = text;
            var selection = editor.getSelectionRange();
            var selected = session.doc.getTextRange(selection);
            if (selected !== "" && selected != '"' && editor.getWrapBehavioursEnabled()) {
                return getWrapped(selection, selected, quote, quote);
            } else if (!selected) {
                var cursor = editor.getCursorPosition();
                var line = session.doc.getLine(cursor.row);
                var leftChar = line.substring(cursor.column-1, cursor.column);
                var rightChar = line.substring(cursor.column, cursor.column + 1);
                
                var token = session.getTokenAt(cursor.row, cursor.column);
                var rightToken = session.getTokenAt(cursor.row, cursor.column + 1);
		var pair;
                if (leftChar == "\\") {
                    return {
			    text : '"',
		            selection: [1,1]
		    }
		} else {
	                var stringBefore = token && /string/.test(token.type);
        	        var stringAfter = !rightToken || /string/.test(rightToken.type);
                
                        if (rightChar == quote) {
                 	    pair = stringBefore !== stringAfter;
	                } else {
        	            if (stringBefore && !stringAfter)
                	        return null; // wrap string with different quote
	                    if (stringBefore && stringAfter)
        	                return null; // do not pair quotes inside strings
                	    var wordRe = session.$mode.tokenRe;
	                    wordRe.lastIndex = 0;
        	            var isWordBefore = wordRe.test(leftChar);
                	    wordRe.lastIndex = 0;
	                    var isWordAfter = wordRe.test(leftChar);
        	            if (isWordBefore || isWordAfter)
                	        return null; // before or after alphanumeric
	                    if (rightChar && !/[\s;,.})\]\\]/.test(rightChar))
        	                return null; // there is rightChar and it isn't closing
                	    pair = true;
		         }
                };
                return {
                    text: pair ? quote + quote : "",
                    selection: [1,1]
                };
            }
        }
    });

    this.add("string_dquotes", "deletion", function(state, action, editor, session, range) {
        var selected = session.doc.getTextRange(range);
        if (!range.isMultiLine() && (selected == '"' || selected == "'")) {
            initContext(editor);
            var line = session.doc.getLine(range.start.row);
            var rightChar = line.substring(range.start.column + 1, range.start.column + 2);
            if (rightChar == selected) {
                range.end.column++;
                return range;
            }
        }
    });

};

CstyleBehaviour.isSaneInsertion = function(editor, session) {
    var cursor = editor.getCursorPosition();
    var iterator = new TokenIterator(session, cursor.row, cursor.column);
    if (!this.$matchTokenType(iterator.getCurrentToken() || "text", SAFE_INSERT_IN_TOKENS)) {
        var iterator2 = new TokenIterator(session, cursor.row, cursor.column + 1);
        if (!this.$matchTokenType(iterator2.getCurrentToken() || "text", SAFE_INSERT_IN_TOKENS))
            return false;
    }
    iterator.stepForward();
    return iterator.getCurrentTokenRow() !== cursor.row ||
        this.$matchTokenType(iterator.getCurrentToken() || "text", SAFE_INSERT_BEFORE_TOKENS);
};

CstyleBehaviour.$matchTokenType = function(token, types) {
    return types.indexOf(token.type || token) > -1;
};

CstyleBehaviour.recordAutoInsert = function(editor, session, bracket) {
    var cursor = editor.getCursorPosition();
    var line = session.doc.getLine(cursor.row);
    if (!this.isAutoInsertedClosing(cursor, line, context.autoInsertedLineEnd[0]))
        context.autoInsertedBrackets = 0;
    context.autoInsertedRow = cursor.row;
    context.autoInsertedLineEnd = bracket + line.substr(cursor.column);
    context.autoInsertedBrackets++;
};

CstyleBehaviour.recordMaybeInsert = function(editor, session, bracket) {
    var cursor = editor.getCursorPosition();
    var line = session.doc.getLine(cursor.row);
    if (!this.isMaybeInsertedClosing(cursor, line))
        context.maybeInsertedBrackets = 0;
    context.maybeInsertedRow = cursor.row;
    context.maybeInsertedLineStart = line.substr(0, cursor.column) + bracket;
    context.maybeInsertedLineEnd = line.substr(cursor.column);
    context.maybeInsertedBrackets++;
};

CstyleBehaviour.isAutoInsertedClosing = function(cursor, line, bracket) {
    return context.autoInsertedBrackets > 0 &&
        cursor.row === context.autoInsertedRow &&
        bracket === context.autoInsertedLineEnd[0] &&
        line.substr(cursor.column) === context.autoInsertedLineEnd;
};

CstyleBehaviour.isMaybeInsertedClosing = function(cursor, line) {
    return context.maybeInsertedBrackets > 0 &&
        cursor.row === context.maybeInsertedRow &&
        line.substr(cursor.column) === context.maybeInsertedLineEnd &&
        line.substr(0, cursor.column) == context.maybeInsertedLineStart;
};

CstyleBehaviour.popAutoInsertedClosing = function() {
    context.autoInsertedLineEnd = context.autoInsertedLineEnd.substr(1);
    context.autoInsertedBrackets--;
};

CstyleBehaviour.clearMaybeInsertedClosing = function() {
    if (context) {
        context.maybeInsertedBrackets = 0;
        context.maybeInsertedRow = -1;
    }
};



oop.inherits(CstyleBehaviour, Behaviour);

exports.CstyleBehaviour = CstyleBehaviour;
});

ace.define("ace/mode/folding/q",["require","exports","module","ace/lib/oop","ace/range","ace/mode/folding/fold_mode"], function(require, exports, module) {
"use strict";

var oop = require("../../lib/oop");
var Range = require("../../range").Range;
var BaseFoldMode = require("./fold_mode").FoldMode;

var FoldMode = exports.FoldMode = function(commentRegex) {
    if (commentRegex) {
        this.foldingStartMarker = new RegExp(
            this.foldingStartMarker.source.replace(/\|[^|]*?$/, "|" + commentRegex.start)
        );
        this.foldingStopMarker = new RegExp(
            this.foldingStopMarker.source.replace(/\|[^|]*?$/, "|" + commentRegex.end)
        );
    }
};
oop.inherits(FoldMode, BaseFoldMode);

(function() {
    
    // this.foldingStartMarker = /(\{|\[)[^\}\]]*$|^\s*(\/\*)/;
    // this.foldingStopMarker = /^[^\[\{]*(\}|\])|^[\s\*]*(\*\/)/;
    this.foldingStartMarker = /(\{|\[).*$/;
    this.foldingStopMarker = /^.*(\}|\])/;
    this.singleLineBlockCommentRe= /^\s*\/.*$/;
    this.startRegionRe = /^\s*\/\/#?region\b/;
    this.bigComment = /^\/\s*$/;
    this.bigCommentEnd = /^\\\s*$/;
    this._getFoldWidgetBase = this.getFoldWidget;
    this.getFoldWidget = function(session, foldStyle, row) {
        var line = session.getLine(row);
        if (this.bigComment.test(line)) return "start";
	// if (this.bigCommentEnd.test(line)) return "end";
        if (this.singleLineBlockCommentRe.test(line)) {
            if (!this.startRegionRe.test(line))
                return "";
        } else if (this.foldingStartMarker.test(line)) {
		var match = line.match(this.foldingStartMarker);
		if (match) {;
			var i = match.index;

	                if (!match[1]) return "";
			var start = {row: row, column: i + 1};
                	var end = session.$findClosingBracket(match[1], start);
	                if (!end) return "";
			if (start.row >= end.row) {  // lets try indent rule
				if (row+1 == session.getLength()) return "";
				var ind = this.lIndent(line);
				if (ind>=this.lIndent(session.getLine(row+1))) return "";
			}
		} else {
			match = line.match(this.foldingStopMarker);
			if(!match) return "";
			var i = match.index;
	                if (!match[1]) return "";
                	var rng = this.closingBracketBlock(session, match[1], row, i);
	                if (!rng) return "";
			if (rng.start.row >= rng.end.row) return "";
		}
	}
    
        var fw = this._getFoldWidgetBase(session, foldStyle, row);
    
        if (!fw && this.startRegionRe.test(line))
            return "start"; // lineCommentRegionStart
    
        return fw;
    };

    this.lIndent = function (line) {
	    var m = line.match(/^(\s*)/);
	    if (m) return m[0].length;
	    return 0;
    }

    this.getFoldWidgetRange = function(session, foldStyle, row, forceMultiline) {
        var line = session.getLine(row);
	var len = line.length;
        
	if (this.bigComment.test(line))
		return this.getBigCommentBlock(session, line, row);

	// if (this.bigCommentEnd.test(line))
	//	return this.getBigCommentEndBlock(session, line, row);

        if (this.startRegionRe.test(line))
            return this.getCommentRegionBlock(session, line, row);
        
        var match = line.match(this.foldingStartMarker);
        if (match) {
            var i = match.index;

            if (match[1]) {
                var r = this.openingBracketBlock(session, match[1], row, i);
		if ( !r || r.start.row == r.end.row ) { // try to match by indent
			var ind = this.lIndent(line);
			var lind = 0;
			row = r.start.row;
			var lastGood = row;
			while (++row < session.getLength()) {
				line = session.getLine(row);
				lind = this.lIndent(line);
				if (!/^\s*$/.test(line)) {
					if (ind>=lind) break;
					lastGood=row;
				}
			}
			if (r.start.row == lastGood) return;
			r.end.row = lastGood;
			r.end.column = 1;
		}
		r.start.column = len; // adjust to see args, condition and etc
		return r;
	    };
                
            // var range = session.getCommentFoldRange(row, i + match[0].length, 1);
            
            //if (range && !range.isMultiLine()) {
            //    if (forceMultiline) {
            //        range = this.getSectionRange(session, row);
            //    } else if (foldStyle != "all")
            //        range = null;
            //}
            
            return;
        }

        if (foldStyle === "markbegin")
            return;

        var match = line.match(this.foldingStopMarker);
        if (match) {
            var i = match.index + match[0].length;

            if (match[1]) {
                var rng =  this.closingBracketBlock(session, match[1], row, i);
		if (rng) rng.start.column = session.getLine(rng.start.row).length;
		return rng;
	    }

            return session.getCommentFoldRange(row, i, -1);
        }
    };
    
    this.getSectionRange = function(session, row) {
        var line = session.getLine(row);
        var startIndent = line.search(/\S/);
        var startRow = row;
        var startColumn = line.length;
        row = row + 1;
        var endRow = row;
        var maxRow = session.getLength();
        while (++row < maxRow) {
            line = session.getLine(row);
            var indent = line.search(/\S/);
            if (indent === -1)
                continue;
            if  (startIndent > indent)
                break;
            var subRange = this.getFoldWidgetRange(session, "all", row);
            
            if (subRange) {
                if (subRange.start.row <= startRow) {
                    break;
                } else if (subRange.isMultiLine()) {
                    row = subRange.end.row;
                } else if (startIndent == indent) {
                    break;
                }
            }
            endRow = row;
        }
        
        return new Range(startRow, startColumn, endRow, session.getLine(endRow).length);
    };
    this.getCommentRegionBlock = function(session, line, row) {
        var startColumn = line.search(/\s*$/);
        var maxRow = session.getLength();
        var startRow = row;
        
        var re = /^\s*\/\/#?(end)?region\b/;
        var depth = 1;
        while (++row < maxRow) {
            line = session.getLine(row);
            var m = re.exec(line);
            if (!m) continue;
            if (m[1]) depth--;
            else depth++;

            if (!depth) break;
        }

        var endRow = row;
        if (endRow > startRow) {
            return new Range(startRow, startColumn, endRow, line.length);
        }
    };
    this.getBigCommentBlock = function(session, line, row) {
	    var maxRow = session.getLength();
	    var startRow = row;
	    while (++row < maxRow) {
		    line = session.getLine(row);
		    if (/^\\\s*$/.test(line)) break;
	    }
	    return new Range(startRow, 1, row, 0);
    };
    this.getBigCommentEndBlock = function(session, line, row) {
	    var endRow = row;
	    while (--row >= 0) {
		    line = session.getLine(row);
		    if (/^\/\s*$/.test(line)) break;
	    }
	    return new Range(row, 1, endRow, 1);
    }

}).call(FoldMode.prototype);

});

ace.define("ace/mode/q",["require","exports","module","ace/lib/oop","ace/mode/text","ace/mode/q_highlight_rules","ace/mode/matching_brace_outdent","ace/range","ace/mode/behaviour/cstyle","ace/mode/folding/cstyle"], function(require, exports, module) {
"use strict";

var oop = require("../lib/oop");
var TextMode = require("./text").Mode;
var qHighlightRules = require("./q_highlight_rules").qHighlightRules;
var MatchingBraceOutdent = require("./matching_brace_outdent").MatchingBraceOutdent;
var Range = require("../range").Range;
var CstyleBehaviour = require("./behaviour/q").CstyleBehaviour;
var CStyleFoldMode = require("./folding/q").FoldMode;

var Mode = function() {
    this.HighlightRules = qHighlightRules;

    this.$outdent = new MatchingBraceOutdent();
    this.$behaviour = new CstyleBehaviour();

    this.foldingRules = new CStyleFoldMode();
};
oop.inherits(Mode, TextMode);

(function() {

    this.lineCommentStart = "/";
    this.blockComment = {start: "/*", end: "*/"};

    this.getNextLineIndent = function(state, line, tab) {
        var indent = this.$getIndent(line);

        var tokenizedLine = this.getTokenizer().getLineTokens(line, state);
        var tokens = tokenizedLine.tokens;
        var endState = tokenizedLine.state;

        if (tokens.length && tokens[tokens.length-1].type == "comment") {
            return indent;
        }
        if (state == "start") {
            var match = line.match(/^.*[\{\(\[]\s*$/);
            if (match) {
                indent += tab;
            } else {
		var brk = 0;
		var brs = 0;
		var par = 0;
        	for (var t in tokens) {
			var v = tokens[t].value;
			if (v == '(') par++
			else if (v == ')') par--
			else if (v == '[') brk++
			else if (v == ']') brk--
			else if (v == '{') brs++
			else if (v == '}') brs--;
		}
		if (brk>0 || brs>0) indent += tab;
		if (par>0) indent += ' ';
	    }
	    return indent;
        } else if (state == "doc-start") {
            if (endState == "start") {
                return "";
            }
            // var match = line.match(/^\s*(\/?)\*/);
            //if (match) {
            //    if (match[1]) {
            //        indent += " ";
            //    }
            //    indent += "* ";
            //}
        }
	return indent;
    };

    this.checkOutdent = function(state, line, input) {
        return this.$outdent.checkOutdent(line, input);
    };

    this.autoOutdent = function(state, doc, row) {
        this.$outdent.autoOutdent(doc, row);
    };

    this.$id = "ace/mode/q";
}).call(Mode.prototype);

exports.Mode = Mode;
});
