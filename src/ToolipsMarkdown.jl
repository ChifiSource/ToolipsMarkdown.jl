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
function tmd(name::String = "markdown", s::String = "", p::Pair{String, <:Any} ...;
    args ...)
    mddiv::Component{:div} = divider(name, p ..., args ...)
    md = Markdown.parse(replace(s, "<" => "", ">" => "", "\"" => ""))
    htm::String = html(md)
    mddiv[:text] = htm
    mddiv
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
function itmd(name::String = "markdown", s::String = "")
    mddiv::Component{:div} = divider(name)
    md = Markdown.parse(s)
    htm::String = html(md)
    htm = replace(htm, "&quot;" => "", "&#40;" => "(", "&#41;" => ")", "&#61;" => "=", "&#43;" => "+")
    codepos = findall("<code", htm)
    for code in codepos
        codeend = findnext("</code>", htm, code[2])
        tgend = findnext(">", htm, code[2])[1] + 1
        codeoutput = htm[tgend[1]:codeend[1] - 1]
        htm = htm[1:code[1] - 1] * "<code>" * String(b.data) * "</code>" * htm[maximum(codeend) + 1:length(htm)]
    end
    mddiv[:text] = htm
    mddiv
end

mutable struct TextModifier <: Modifier
    raw::String
    marks::Dict{UnitRange{Int64}, Symbol}
    styles::Dict{Symbol, Vector{Pair{String, String}}}
    importances::Dict{Symbol, Int64}
    function TextModifier(raw::String)
        marks = Dict{Symbol, UnitRange{Int64}}()
        styles = Dict{Symbol, Vector{Pair{String, String}}}()
        new(raw, marks, styles, Dict{Symbol, Int64}())
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
    [push!(tm.marks, v => label) for v in finales]
end

function mark_before!(tm::TextModifier, s::String, label::Symbol;
    until::Vector{String} = Vector{String}(), includedims::Bool = false)
    includedims = Int64(includedims)
    chars = findall(s, tm.raw)
    for labelrange in chars
        previous = findprev(" ", tm.raw,  labelrange[1])
         if isnothing(previous)
            previous  = length(tm.raw)
        else
            previous = previous[1]
        end
        if length(until) > 1
            lens =  [begin
                    point = findprev(d, tm.raw,  minimum(labelrange))
                    if ~(isnothing(point))
                        minimum(point) + length(d)
                    else
                        1
                    end
                    end for d in until]
            previous = maximum(lens)
        end
        push!(tm.marks, previous - includedims:maximum(labelrange) - 1 + includedims => label)
    end
end

function mark_after!(tm::TextModifier, s::String, label::Symbol;
    until::Vector{String} = Vector{String}(), excludedims_r::Int64 = 0,
    excludedims_l::Int64 = 0)
    chars = findall(s, tm.raw)
    for labelrange in chars
        ending = findnext(" ", tm.raw,  labelrange[1])
        if isnothing(ending)
            ending  = length(tm.raw)
        else
            ending = ending[1]
        end
        if length(until) > 1
            lens =  [begin
                    point = findnext(d, tm.raw,  maximum(labelrange) + 1)
                    if ~(isnothing(point))
                        maximum(point) - length(d)
                    else
                        length(tm.raw)
                    end
                    end for d in until]
            ending = minimum(lens)
        end
        push!(tm.marks, minimum(labelrange) + excludedims_l:ending -excludedims_r => label)
    end
end
clear_marks!(tm::TextModifier) = tm.marks = Dict{UnitRange{Int64}, Symbol}()
mark_julia!(tm::TextModifier) = begin
    mark_all!(tm, "function", :func)
    mark_before!(tm, "(", :funcn, until = [" ", "\n", ",", ".", "</br>", "&nbsp;", "&nbsp;",
    "<br>"])
    mark_all!(tm, "import", :import)
    mark_all!(tm, "using", :using)
    mark_all!(tm, "end", :end)
    mark_all!(tm, "struct", :struct)
    mark_all!(tm, "mutable", :mutable)
    mark_all!(tm, "begin", :begin)
    mark_all!(tm, "module", :module)
    mark_after!(tm, "::", :type, until = [" ", ",", ")", "\n", "</br>", "&nbsp;", "&nbsp;",
    "<br>", ";"])
#    mark_between!(tm, "\"", :string)
end

highlight_julia!(tm::TextModifier) = begin
    style!(tm, :func, ["color" => "#fc038c"])
    style!(tm, :funcn, ["color" => "blue"])
    style!(tm, :using, ["color" => "teal"])
    style!(tm, :import, ["color" => "#fc038c"])
    style!(tm, :end, ["color" => "#b81870"])
    style!(tm, :mutable, ["color" => "#b81870"])
    style!(tm, :struct, ["color" => "#fc038c"])
    style!(tm, :begin, ["color" => "#fc038c"])
    style!(tm, :module, ["color" => "#fc038c"])
    style!(tm, :module, ["color" => "red"])
    style!(tm, :string, ["color" => "green"])
    style!(tm, :type, ["color" => "orange"])
    style!(tm, :multistring, ["color" => "darkgreen"])
    style!(tm, :default, ["color" => "black"])
end

function julia_block!(tm::TextModifier)
    mark_julia!(tm)
    highlight_julia!(tm)
end

function julia_block!(f::Function, tm::TextModifier)
    mark_julia!(tm)
    f(tm)
    tm
end

function split_by_range(tm::TextModifier)
    prev::Int64 = 1
    finals = Vector{Any}()
    filtmarks = [begin
        if nmark != mark && any(i -> i in keys(tm.marks), nmark)
            1:1
        elseif length(nmark) <= 0
            1:1
        elseif isnothing(nmark)
            1:1
        else
            nmark
        end
    end for nmark in collect(keys(tm.marks))]
        filter!(i -> i != 1:1,  filtmarks)
        println(filtmarks)
    [begin
        push!(finals, tm.raw[prev:minimum(mark) - 1])
        push!(finals, tm.marks[mark] => tm.raw[mark])
        prev = maximum(mark) + 1
    end for mark in sort(filtmarks)]
        if prev < length(tm.raw)
            push!(finals, tm.raw[prev:length(tm.raw)])
        end
    finals
end

string(tm::TextModifier) = begin
    println([tm.raw[mark] for mark in keys(tm.marks)])
    out::String = join([begin
    spoof = Toolips.SpoofConnection()
    txt = a("modiftxt", text = text)
    style!(txt, tm.styles[:default] ...)
        if typeof(text) == Pair{Symbol, String} && text[1] in keys(tm.styles)
            txt = a("modiftxt", text = text[2])
            style!(txt, tm.styles[text[1]] ...)
        end
    write!(spoof, txt)
    spoof.http.text
    end for text in split_by_range(tm)])
    out::String
end

export tmd, @tmd_str, TextModifier
end # module
