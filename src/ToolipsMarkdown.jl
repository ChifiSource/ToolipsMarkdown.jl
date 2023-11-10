"""
Created in July, 2022 by
[chifi - an open source software dynasty.](https://github.com/orgs/ChifiSource)
by team
[toolips](https://github.com/orgs/ChifiSource/teams/toolips)
This software is MIT-licensed.
### Toolips Markdown
A simple markdown to Toolips Component parser. Wraps markdown components into
a Toolips.div
##### Module Composition
- [**ToolipsMarkdown**](https://github.com/ChifiSource/ToolipsMarkdown.jl)
"""
module ToolipsMarkdown
using Toolips
import Toolips: Modifier
import Toolips: style!, string
import Base: push!
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
### itmd(name::String = "markdown", s::String = "", interpolators::Pair{String, Vector{Function}} ...) -> ::Component{:div}
------------------
Interpolated TMD! This method allows you to provide your own TextModifier functions
in a Vector for each type of code block inside of a markdown document.
#### example
```
route("/") do c::Connection
    mymdcomp = tmd("mainmarkdown", "# Hello! [click](http://toolips.app/)")
    write!(c, mymdcomp)
end
```
"""
function itmd(name::String = "markdown",
    interpolators::Pair{String, Vector{Function}} ...)
    throw("Interpolated TMD is a Toolips Markdown 0.1.3 feature. Not yet implemented.")
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

"""
### abstract type TextModifier <: Toolips.Modifier
TextModifiers are modifiers that change outgoing text into different forms,
whether this be in servables or web-formatted strings. These are unique in that
they can be provided to `itmd` (`0.1.3`+) in order to create interpolated tmd
blocks, or just handle these things on their own.
##### Consistencies
- raw**::String**
- marks**::Dict{UnitRange{Int64}, Symbol}**
"""
abstract type TextModifier <: Modifier end

"""
### TextStyleModifier
- raw**::String**
- marks**::Dict{UnitRange{Int64}, Symbol}**
- styles**::Dict{Symbol, Vector{Pair{String, String}}}**

This type is provided
##### example
```

```
------------------
##### constructors
- TextStyleModifier(::String)
"""
mutable struct TextStyleModifier <: TextModifier
    raw::String
    taken::Vector{Int64}
    marks::Dict{UnitRange{Int64}, Symbol}
    styles::Dict{Symbol, Vector{Pair{String, String}}}
    function TextStyleModifier(raw::String)
        marks = Dict{Symbol, UnitRange{Int64}}()
        styles = Dict{Symbol, Vector{Pair{String, String}}}()
        new(replace(raw, "<br>" => "\n", "</br>" => "\n", "&nbsp;" => " "), Vector{Int64}(), marks, styles)
    end
end

set_text!(tm::TextModifier, s::String) = tm.raw = replace(s, "<br>" => "\n", "</br>" => "\n", "&nbsp;" => " ")
clear!(tm::TextStyleModifier) = begin
    tm.marks = Dict{UnitRange{Int64}, Symbol}()
    tm.taken = Vector{Int64}()
end

function push!(tm::TextStyleModifier, p::Pair{UnitRange{Int64}, Symbol})
    r = p[1]
    found = findfirst(mark -> mark in r, tm.taken)
    if isnothing(found)
        push!(tm.marks, p)
        vecp = Vector(p[1])
        [push!(tm.taken, val) for val in p[1]]
    end
end

function push!(tm::TextStyleModifier, p::Pair{Int64, Symbol})
    if ~(p[1] in tm.taken)
        push!(tm.marks, p[1]:p[1] => p[2])
        push!(tm.taken, p[1])
    end
end
"""
**Toolips Markdown**
### style!(tm::TextStyleModifier, marks::Symbol, sty::Vector{Pair{String, String}})
------------------
Styles marks assigned with symbol `marks` to `sty`.
#### example
```

```
"""
function style!(tm::TextStyleModifier, marks::Symbol, sty::Vector{Pair{String, String}})
    push!(tm.styles, marks => sty)
end

repeat_offenders = ['\n', ' ', ',', '(', ')', ';', '\"', ']', '[']

"""
**Toolips Markdown**
### mark_all!(tm::TextModifier, s::String, label::Symbol)
------------------
Marks all instances of `s` in `tm.raw` as `label`.
#### example
```

```
"""
function mark_all!(tm::TextModifier, s::String, label::Symbol)::Nothing
    [begin
        if maximum(v) == length(tm.raw) && minimum(v) == 1
            push!(tm, v => label)
        elseif maximum(v) == length(tm.raw)
            if tm.raw[v[1] - 1] in repeat_offenders
                push!(tm, v => label)
            else
                if v[1] - 1 > 4
                    println(tm.raw[v[1] - 5:maximum(v)])
                end
            end
        elseif minimum(v) == 1
            if tm.raw[maximum(v) + 1] in repeat_offenders
                push!(tm, v => label)
            end
        else
            if tm.raw[v[1] - 1] in repeat_offenders && tm.raw[maximum(v) + 1] in repeat_offenders
                push!(tm, v => label)
            end
        end
     end for v in findall(s, tm.raw)]
    nothing
end


function mark_all!(tm::TextModifier, c::Char, label::Symbol)
    [begin
        push!(tm, v => label)
    end for v in findall(c, tm.raw)]
end

"""
**Toolips Markdown**
### mark_between!(tm::TextModifier, s::String, label::Symbol; exclude::String = "\\"", excludedim::Int64 = 2)
------------------
Marks between each delimeter, unique in that this is done with by dividing the
count by two.
#### example
```

```
"""
function mark_between!(tm::TextModifier, s::String, label::Symbol)
    positions::Vector{UnitRange{Int64}} = findall(s, tm.raw)
    discounted::Vector{UnitRange{Int64}} = Vector{Int64}()
    [begin
        if ~(pos in discounted)
            nd = findnext(s, tm.raw, maximum(pos) + length(s))
            if isnothing(nd)
                push!(tm, pos[1]:length(tm.raw) => label)
            else
                push!(discounted, nd)
                push!(tm, minimum(pos):maximum(nd) => label)
            end
        end
    end for pos in positions]
    nothing
end

function mark_between!(tm::TextModifier, s::String, s2::String, label::Symbol)
    positions::Vector{UnitRange{Int64}} = findall(s, tm.raw)
    [begin
        nd = findnext(s2, tm.raw, maximum(pos) + length(s))
        if isnothing(nd)
            push!(tm, pos[1]:length(tm.raw) => label)
        else
            push!(tm, minimum(pos):maximum(nd) => label)
        end
    end for pos in positions]
    nothing
end


"""
**Toolips Markdown**
```julia
mark_before!(tm::TextModifier, s::String, label::Symbol; until::Vector{String},
includedims_l::Int64 = 0, includedims_r::Int64 = 0)
```
------------------
marks before a given string until hitting any value in `until`.
#### example
```

```
"""
function mark_before!(tm::TextModifier, s::String, label::Symbol;
    until::Vector{String} = Vector{String}(), includedims_l::Int64 = 0,
    includedims_r::Int64 = 0)
    chars = findall(s, tm.raw)
    for labelrange in chars
        previous = findprev(" ", tm.raw,  labelrange[1])
         if isnothing(previous)
            previous  = length(tm.raw)
        else
            previous = previous[1]
        end
        if length(until) > 0
            lens =  [begin
                    point = findprev(d, tm.raw,  minimum(labelrange) - 1)
                    if ~(isnothing(point))
                        minimum(point) + length(d)
                    else
                        1
                    end
                    end for d in until]
            previous = maximum(lens)
        end
        pos = previous - includedims_l:maximum(labelrange) - 1 + includedims_r
        push!(tm, pos => label)
    end
end

"""
**Toolips Markdown**
```julia
mark_after!(tm::TextModifier, s::String, label::Symbol; until::Vector{String},
includedims_l::Int64 = 0, includedims_r::Int64 = 0)
```
------------------
marks after a given string until hitting any value in `until`.
#### example
```

```
"""
function mark_after!(tm::TextModifier, s::String, label::Symbol;
    until::Vector{String} = Vector{String}(), includedims_r::Int64 = 0,
    includedims_l::Int64 = 0)
    chars = findall(s, tm.raw)
    for labelrange in chars
        ending = findnext(" ", tm.raw,  labelrange[1])
        if isnothing(ending)
            ending  = length(tm.raw)
        else
            ending = ending[1]
        end
        if length(until) > 0
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
        pos = minimum(labelrange) - includedims_l:ending - includedims_r
        push!(tm,
        pos => label)
    end
end

"""
**Toolips Markdown**
```julia
mark_inside!(f::Function, tm::TextModifier)
```
------------------
marks before a given string until hitting any value in `until`.
#### example
```

```
"""
function mark_inside!(f::Function, tm::TextModifier, label::Symbol)
    labelmarks = findall(v -> v == label, tm.marks)
    [begin
        n = minimum(r)
        ntm = TextStyleModifier(tm.raw[r])
        f(ntm)
        [begin
            push!(tm.marks,
            minimum(rang[1]) + n:maximum(rang[1]) + n => rang[2])
        end for rang in ntm.marks]
    end for r in labelmarks]
end

"""
**Toolips Markdown**
### mark_for!(tm::TextModifier, s::String, f::Int64, label::Symbol)
------------------
Marks a certain number of characters after a given value.
#### example
```

```
"""
function mark_for!(tm::TextModifier, ch::String, f::Int64, label::Symbol)
    if length(tm.raw) == 1
        return
    end
    chars = findall(ch, tm.raw)
    [begin
    if ~(length(findall(i -> length(findall(n -> n in i, pos)) > 0,
     collect(keys(tm.marks)))) > 0)
        push!(tm.marks, minimum(pos):maximum(pos) + f => label)
    end
    end for pos in chars]
end


function mark_line_after!(tm::TextModifier, ch::String, label::Symbol)
    chars = findall(ch, tm.raw)
    for char in chars
        maximum(char:findnext("\n", char[2], tm.raw))
    end
end

function mark_line_startswith!(tm::TextModifier, ch::String, label::Symbol)
    marks = findall("\n$ch", tm.raw)
    [push!(tm.marks, mark[2]:findnext("\n", mark[2], tm.raw) => label) for mark in marks]
end

"""
**Toolips Markdown**
### clear_marks!(tm::TextModifier)
------------------
Clears all marks in text modifier.
#### example
```

```
"""
clear_marks!(tm::TextModifier) = tm.marks = Dict{UnitRange{Int64}, Symbol}()

"""
**Toolips Markdown**
### mark_julia!(tm::TextModifier)
------------------
Marks julia syntax.
#### example
```

```
"""
mark_julia!(tm::TextModifier) = begin
    # delim
    mark_before!(tm, "(", :funcn, until = [" ", "\n", ",", ".", "\"", "&nbsp;",
    "<br>", "("])
    mark_after!(tm, "::", :type, until = [" ", ",", ")", "\n", "<br>", "&nbsp;", "&nbsp;",
    ";"])
    mark_after!(tm, "#",  :comment, until  =  ["\n", "<br>"])
 #   mark_between!(tm, "\"\"\"", :multistring)
    mark_between!(tm, "\"", :string)
    mark_between!(tm, "'", :char)
    # keywords
    mark_all!(tm, "function", :func)
    mark_all!(tm, "import", :import)
    mark_all!(tm, "using", :using)
    mark_all!(tm, "end", :end)
    mark_all!(tm, "struct", :struct)
    mark_all!(tm, "abstract", :abstract)
    mark_all!(tm, "mutable", :mutable)
    mark_all!(tm, "if", :if)
    mark_all!(tm, "else", :if)
    mark_all!(tm, "elseif", :if)
    mark_all!(tm, "export ", :using)
    mark_all!(tm, "try ", :if)
    mark_all!(tm, "catch ", :if)
    mark_all!(tm, "for", :for)
    mark_all!(tm, "begin", :begin)
    mark_all!(tm, "module", :module)
    # math
    [mark_all!(tm, Char('0' + dig), :number) for dig in digits(1234567890)]
    mark_all!(tm, "true", :number)
    mark_all!(tm, "false", :number)
    [mark_all!(tm, string(op), :op) for op in split(
    """<: = == < > => -> || -= += + / * - ~ <= >= &&""", " ")]
    #mark_between!(tm, "#=", "=#", :comment])
#=    mark_inside!(tm, :string) do tm2
        mark_for!(tm2, "\\", 1, :exit)
    end =#
end

"""
**Toolips Markdown**
### highlight_julia!(tm::TextModifier)
------------------
Marks default style for julia code.
#### example
```

```
"""
highlight_julia!(tm::TextStyleModifier) = begin
    style!(tm, :default, ["color" => "#3D3D3D"])
    style!(tm, :func, ["color" => "#fc038c"])
    style!(tm, :funcn, ["color" => "#2F387B"])
    style!(tm, :using, ["color" => "#006C67"])
    style!(tm, :import, ["color" => "#fc038c"])
    style!(tm, :end, ["color" => "#b81870"])
    style!(tm, :mutable, ["color" => "#006C67"])
    style!(tm, :struct, ["color" => "#fc038c"])
    style!(tm, :begin, ["color" => "#fc038c"])
    style!(tm, :module, ["color" => "#b81870"])
    style!(tm, :string, ["color" => "#007958"])
    style!(tm, :if, ["color" => "#fc038c"])
    style!(tm, :for, ["color" => "#fc038c"])
    style!(tm, :in, ["color" => "#006C67"])
    style!(tm, :abstract, ["color" => "#006C67"])
    style!(tm, :number, ["color" => "#8b0000"])
    style!(tm, :char, ["color" => "#8b0000"])
    style!(tm, :type, ["color" => "#D67229"])
    style!(tm, :exit, ["color" => "#006C67"])
    style!(tm, :op, ["color" => "#0C023E"])
    style!(tm, :multistring, ["color" => "#1B4636"])
end

"""
**Toolips Markdown**
### julia_block!(tm::TextModifier)
------------------
Marks default style for julia code.
#### example
```

```
"""
function julia_block!(tm::TextStyleModifier)
    mark_julia!(tm)
    highlight_julia!(tm)
end

"""
**Toolips Markdown**
### string(tm::TextModifier) -> ::String
------------------
Styles marks together into `String`.
#### example
```

```
"""
function string(tm::TextStyleModifier)
    if length(tm.marks) == 0
        txt = a("modiftxt", text = rep_str(tm.raw))
        style!(txt, tm.styles[:default] ...)
        sc = Toolips.SpoofConnection()
        write!(sc, txt)
        return(sc.http.text)::String
    end
    prev = 1
    finales = Vector{Servable}()
    sortedmarks = sort(collect(tm.marks), by=x->x[1])
    lastmax::Int64 = length(tm.raw)
    loop_len = length(keys(tm.marks))
    [begin
        if length(mark) > 0
            mname = tm.marks[mark]
            if minimum(mark) - prev > 0
                txt = span("modiftxt", text = rep_str(tm.raw[prev:minimum(mark) - 1]))
                style!(txt, tm.styles[:default] ...)
                push!(finales, txt)
            end
            txt = span("modiftxt", text = rep_str(tm.raw[mark]))
            if mname in keys(tm.styles)
                style!(txt, tm.styles[mname] ...)   
            else
                style!(txt, tm.styles[:default] ...)
            end
            push!(finales, txt)
            prev = maximum(mark) + 1
        end
        if e == loop_len
            lastmax = maximum(mark)
        end
    end for (e, mark) in enumerate((k[1] for k in sortedmarks))]
    if lastmax != length(tm.raw)
        txt = span("modiftxt", text = rep_str(tm.raw[lastmax + 1:length(tm.raw)]))
        style!(txt, tm.styles[:default] ...)
        push!(finales, txt)
    end
    sc = Toolips.SpoofConnection()
    write!(sc, finales)
    sc.http.text::String
end

rep_str(s::String) = replace(s, " "  => "&nbsp;",
"\n"  =>  "<br>", "\\" => "&bsol;")

export tmd, @tmd_str
end # module
