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
import Toolips: Modifier
using Markdown
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
function tmd(name::String = " ", s::String = "",
    code_mods::Vector{String, TextModifier})
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

mutable struct TextModifier <: Modifier
    raw::String
    marks::Dict{Symbol, Vector{UnitRange{Int64}}}
    styles::Dict{Symbol, Vector{Pair{String, String}}}
    function TextModifier(raw::String)
        marks = Dict{Symbol, UnitRange{Int64}}()
        styles = Dict{Symbol, Vector{Pair{String, String}}}()
        new(raw, marks, styles)
    end
end

mutable struct CodeAction{T <: Any} end

function tmd_do!(f::Function, ch::CodeAction{:julia}, t::String)
    tm = TextModifier(t)
    func_marks = findall("function", t)
end

export tmd, @tmd_str
end # module
