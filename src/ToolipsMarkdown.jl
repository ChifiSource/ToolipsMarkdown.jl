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
import Toolips: style!, string
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
    code_mods::Dict{String, Function} = ["julia" => highlight_julia!])
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
    marks::Dict{UnitRange{Int64}, Symbol}
    styles::Dict{Symbol, Vector{Pair{String, String}}}
    function TextModifier(raw::String)
        marks = Dict{Symbol, UnitRange{Int64}}()
        styles = Dict{Symbol, Vector{Pair{String, String}}}()
        new(raw, marks, styles)
    end
end

function style!(tm::TextModifier, marks::Symbol, sty::Vector{Pair{String, String}})
    push!(tm.styles, marks => sty)
end

function mark_all!(tm::TextModifier, s::String, label::Symbol)
    [push!(tm.marks, v => label) for v in findall(s, tm.raw)]
end

function mark_between!(tm::TextModifier, s::String, label::Symbol)
    firsts = findall(s, tm.raw)
    finales = Vector{UnitRange{Int64}}()
    uneven = length(firsts) % 2 != 0
    for i in 1:length(firsts)
        if uneven && i == length(firsts)
            break
        end
        if i % 2 == 0
            continue
        end
        push!(finales, minimum(firsts[i]) + 1:maximum(firsts[i + 1]) - 1)
    end
    println(finales)
    [push!(tm.marks, v => label) for v in finales]
end

function mark_between!(tm::TextModifier, s::String, s2::String, label::Symbol)
    firsts = findall("s")
end


function mark_before!(tm::TextModifier, s::String, label::Symbol)

end

function mark_after!(tm::TextModifier, s::String, label::Symbol)

end

mark_julia!(tm::TextModifier) = begin
    mark_all!(tm, "function", :func)
    mark_all!(tm, "end", :end)
    mark_all!(tm, "struct", :struct)
    mark_all!(tm, "mutable", :mutable)
    mark_all!(tm, "begin", :begin)
    mark_all!(tm, "module", :module)
   # mark_after!(tm, "::", :type)
    mark_between!(tm, "\"", :string)
    mark_between!(tm, "\"\"\"", :multistring)
    mark_between!(tm, "'", :char)
  #  mark_before!(tm, "(", :method)
end

highlight_julia!(tm::TextModifier) = begin
    style!(tm, :func, ["color" => "#fc038c"])
    style!(tm, :end, ["color" => "#b81870"])
    style!(tm, :mutable, ["color" => "#b81870"])
    style!(tm, :struct, ["color" => "#fc038c"])
    style!(tm, :begin, ["color" => "#fc038c"])
    style!(tm, :module, ["color" => "#fc038c"])
    style!(tm, :string, ["color" => "#5bf0d9"])
    style!(tm, :multistring, ["color" => "#5bf0d9"])
end

string(tm::TextModifier) = begin
    s = Vector{String}()
    marks = [p[1] for p in tm.marks]
    pos = 1
    for mark in sort(marks)
        style = ("color" => "gray", "font-size" => 14px)
        if tm.marks[mark] in keys(tm.styles)
           style = tm.styles[tm.marks[mark]]
        end
        comp = a("$(tm.marks[mark])", text = tm.raw[mark])
        Toolips.style!(comp, style ...)
        spoof = Toolips.SpoofConnection()
        Toolips.write!(spoof, comp)
        untilhere = tm.raw[pos:minimum(mark) - 1]
        push!(s, untilhere)
        push!(s, spoof.http.text)
        pos = (maximum(mark) + 1)
    end
    display("text/html", join(s))
end

export tmd, @tmd_str
end # module
