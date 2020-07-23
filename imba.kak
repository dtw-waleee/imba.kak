# http://imbascript.org
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

# Detection
# ‾‾‾‾‾‾‾‾‾

hook global BufCreate .*[.](imba) %{
    set-option buffer filetype imba
}

# Initialization
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾

hook global WinSetOption filetype=imba %{
    require-module imba

    hook window ModeChange pop:insert:.* -group imba-trim-indent  imba-trim-indent
    hook window InsertChar \n -group imba-indent imba-indent-on-new-line

    hook -once -always window WinSetOption filetype=.* %{ remove-hooks window imba-.+ }
}

hook -group imba-highlight global WinSetOption filetype=imba %{
    add-highlighter window/imba ref imba
    hook -once -always window WinSetOption filetype=.* %{ remove-highlighter window/imba }
}


provide-module imba %[

try %{
  require-module html #for css and html-tag support
}

# Highlighters
# ‾‾‾‾‾‾‾‾‾‾‾‾

add-highlighter shared/imba regions
add-highlighter shared/imba/code     default-region group
add-highlighter shared/imba/single_string     region "'" "'"                    fill string
add-highlighter shared/imba/single_string_alt region "'''" "'''"                fill string
add-highlighter shared/imba/double_string     region '"' (?<!\\)(\\\\)*"        regions
add-highlighter shared/imba/double_string_alt region '"""' '"""'                ref shared/imba/double_string
add-highlighter shared/imba/regex             region '/' (?<!\\)(\\\\)*/[gimy]* regions
add-highlighter shared/imba/regex_alt         region '///' ///[gimy]*           ref shared/imba/regex

add-highlighter shared/imba/comment  region  '###' '###' fill comment
add-highlighter shared/imba/inlinbe_comment          region '#' '$'                    fill comment

# Regular expression flags are: g → global match, i → ignore case, m → multi-lines, y → sticky
# https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/RegExp

add-highlighter shared/imba/double_string/base default-region fill string
add-highlighter shared/imba/double_string/interpolation region -recurse \{ \Q#{ \} fill meta
add-highlighter shared/imba/regex/base default-region fill meta
add-highlighter shared/imba/regex/interpolation region -recurse \{ \Q#{ \} fill meta

# Keywords are collected at
# https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Lexical_grammar#Keywords
# http://imbascript.org/documentation/docs/lexer.html#section-63
add-highlighter shared/imba/code/ regex [$@]\w* 0:variable
add-highlighter shared/imba/code/ regex \b(Array|Boolean|Date|Function|Number|Object|RegExp|String)\b 0:type
add-highlighter shared/imba/code/ regex \b(document|false|no|null|off|on|parent|self|this|true|undefined|window|yes)\b 0:value
add-highlighter shared/imba/code/ regex \b(and|is|isnt|not|or)\b 0:operator
add-highlighter shared/imba/code/ regex \b(break|case|catch|class|tag|const|continue|debugger|default|delete|do|else|enum|export|extends|finally|for|def|css|if|implements|import|in|instanceof|interface|let|native|new|package|private|protected|public|return|static|super|switch|throw|try|typeof|var|void|while|with|yield)\b 0:keyword

# Commands
# ‾‾‾‾‾‾‾‾

define-command -hidden imba-trim-indent %{
    evaluate-commands -draft -itersel %{
        execute-keys <a-x>
        # remove trailing white spaces
        try %{ execute-keys -draft s \h + $ <ret> d }
    }
}

define-command -hidden imba-indent-on-new-line %{
    evaluate-commands -draft -itersel %{
        # copy '#' comment prefix and following white spaces
        try %{ execute-keys -draft k <a-x> s '^\h*\K#\h*' <ret> y gh j P }
        # preserve previous line indent
        try %{ execute-keys -draft <semicolon> K <a-&> }
        # filter previous line
        try %{ execute-keys -draft k : imba-trim-indent <ret> }
        # indent after start structure
        try %{ execute-keys -draft k <a-x> <a-k> ^ \h * (case|catch|class|else|finally|for|function|if|switch|try|while|with) \b | (=|->) $ <ret> j <a-gt> }
    }
}

]
