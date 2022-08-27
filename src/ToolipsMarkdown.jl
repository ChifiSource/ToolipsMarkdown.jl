"""
Created in July, 2022 by
[chifi - an open source software dynasty.](https://github.com/orgs/ChifiSource)
by team
[toolips](https://github.com/orgs/ChifiSource/teams/toolips)
This software is MIT-licensed.
### Toolips Markdown
A simple markdown to Toolips Component parser. Wraps markdown components into
a Toolips.divier
##### Module Composition
- [**ToolipsMarkdown**](https://github.com/ChifiSource/ToolipsMarkdown.jl)
"""
module ToolipsMarkdown
using Toolips
using Markdown
using Highlights
"""
**Toolips Markdown**
### @tmd_str -> ::Component
------------------
Turns a markdown string into a Toolips Component. Markdown will always use
default styling.
#### example
```
tmd\"#hello world\"
```
"""
macro tmd_str(s::String)
    tmd("tmd", s)::Component{:div}
end

"""
**Toolips Markdown**
### tmd(name::String = "tmd", s::String = "") -> ::Component
------------------
Turns a markdown string into a Toolips Component. Markdown will always use
default styling.
#### example
```
route("/") do c::Connection
    mymdcomp = tmd("mainmarkdown", "# Hello! [click](http://toolips.app/)")
    write!(c, mymdcomp)
end
```
"""
function tmd(name::String = " ", s::String = ""; lexer::Any = Lexers.JuliaLexer)
    mddiv::Component{:div} = divider(name)
    md = Markdown.parse(s)
    htm::String = html(md)
    htm = replace(htm, "&quot;" => "", "&#40;" => "(", "&#41;" => ")", "&#61;" => "=", "&#43;" => "+")
    codepos = findall("<code", htm)
    if lexer != nothing
        for code in codepos
            codeend = findnext("</code>", htm, code[2])
            tgend = findnext(">", htm, code[2])[1] + 1
            codeoutput = htm[tgend[1]:codeend[1] - 1]
            b = IOBuffer()
            Highlights.highlight(b, MIME"text/html"(), codeoutput, lexer)
            htm = htm[1:code[1] - 1] * "<code>" * String(b.data) * "</code>" * htm[maximum(codeend) + 1:length(htm)]
        end
    end
    mddiv[:text] = htm
    mddiv
end

function julia_style()
    hljl_nf::Style = Style("span.hljl-nf", "color" => "blue")
    hljl_oB::Style = Style("span.hljl-oB", "color" => "purple", "font-weight" => "bold")
    hljl_n::Style = Style("span.hljl-ts", "color" => "orange")
    hljl_cs::Style = Style("span.hljl-cs", "color" => "gray")
    hljl_k::Style = Style("span.hljl-k", "color" => "red", "font-weight" => "bold")
    styles::Component{:sheet} = Component("tmds", "sheet")
    push!(styles, hljl_k, hljl_nf, hljl_oB, hljl_n, hljl_cs)
    styles::Component{:sheet}
end

export tmd, @tmd_str
end # module
