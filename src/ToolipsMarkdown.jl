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
    marks::Dict{UnitRange{Int64}, Symbol}
    styles::Dict{Symbol, Vector{Pair{String, String}}}
    function TextStyleModifier(raw::String)
        marks = Dict{Symbol, UnitRange{Int64}}()
        styles = Dict{Symbol, Vector{Pair{String, String}}}()
        new(raw, marks, styles)
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

"""
**Toolips Markdown**
### mark_all!(tm::TextModifier, s::String, label::Symbol)
------------------
Marks all instances of `s` in `tm.raw` as `label`.
#### example
```

```
"""
function mark_all!(tm::TextModifier, s::String, label::Symbol)
    [begin
    if ~(length(findall(i -> length(findall(n -> n in i, v)) > 0,
     collect(keys(tm.marks)))) > 0)
        push!(tm.marks, v => label)
    end
     end for v in findall(s, tm.raw)]
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
function mark_between!(tm::TextModifier, s::String, label::Symbol;
    exclude::String = "\"")
    firsts = findall(s, tm.raw)
    finales = Vector{UnitRange{Int64}}()
    uneven = length(firsts) % 2 != 0
    for i in 1:length(firsts)
        mark::UnitRange{Int64} = firsts[i]
        if length(tm.raw) > maximum(mark) + length(exclude) && length(tm.raw) > length(exclude) + length(s)
            if  contains(tm.raw[maximum(mark) + 1:maximum(mark) + length(exclude)], exclude)
                break
            end
        end
        if minimum(mark) - length(exclude) > 0 && length(tm.raw) > length(exclude) + length(s)
            if  contains(tm.raw[minimum(mark) - 1:minimum(mark) - length(exclude)], exclude)
                break
            end
        end
        if uneven && i == length(firsts)
            pos = minimum(firsts[i]):length(tm.raw)
            if ~(length(findall(i -> length(findall(n -> n in i, pos)) > 0,
             collect(keys(tm.marks)))) > 0)
                push!(finales, pos)
            end
            break
        end
        if i % 2 == 0
            continue
        end
        pos = minimum(firsts[i]):maximum(firsts[i + 1])
        if ~(length(findall(i -> length(findall(n -> n in i, pos)) > 0,
         collect(keys(tm.marks)))) > 0)
            push!(finales, pos)
        end
    end
    [push!(tm.marks, v => label) for v in finales]
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
        previous = findprev("&nbsp;", tm.raw,  labelrange[1])
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
        if ~(length(findall(i -> length(findall(n -> n in i, pos)) > 0,
         collect(keys(tm.marks)))) > 0)
            push!(tm.marks, pos => label)
        end
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
        pos = minimum(labelrange) + 1 - includedims_l:ending - includedims_r
        if ~(length(findall(i -> length(findall(n -> n in i, pos)) > 0,
         collect(keys(tm.marks)))) > 0)
            push!(tm.marks,
            pos => label)
        end
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
    mark_between!(tm, "\"\"\"", :multistring, exclude = "\"\"\"")
    mark_between!(tm, "\"", :string)
    mark_all!(tm, "function", :func)
    mark_after!(tm, "::", :type, until = [" ", ",", ")", "\n", "<br>", "&nbsp;", "&nbsp;",
    ";"])
    mark_after!(tm, "#",  :comment, until  =  ["\n", "<br>"])
    [mark_all!(tm, string(dig), :number) for dig in digits(1234567890)]
    mark_all!(tm, "true", :number)
    mark_all!(tm, "false", :number)
    [mark_all!(tm, string(op), :op) for op in split(
    """<: = == < > => -> || -= += + / * - ~ <= >= &&""", " ")]
    mark_before!(tm, "(", :funcn, until = [" ", "\n", ",", ".", "\"", "&nbsp;",
    "<br>", "("])
    mark_all!(tm, "import ", :import)
    mark_all!(tm, "using ", :using)
    mark_all!(tm, " end", :end)
    mark_all!(tm, "\nend", :end)
    mark_all!(tm, " struct ;", :struct)
    mark_all!(tm, "\nstruct ", :struct)
    mark_all!(tm, "abstract ;", :abstract)
    mark_all!(tm, "\nabstract ", :abstract)
    mark_all!(tm, " mutable ", :mutable)
    mark_all!(tm, "\nmutable", :mutable)
    mark_all!(tm, "elseif ", :if)
    mark_all!(tm, " if ", :if)
    mark_all!(tm, "if ", :if)
    mark_all!(tm, "else ", :if)
    mark_all!(tm, "export ", :import)
    mark_all!(tm, "try ", :if)
    mark_all!(tm, "catch ", :if)
    mark_all!(tm, "\nif ", :if)
    mark_all!(tm, "for ", :for)
    mark_all!(tm, "\nfor ", :for)
    mark_all!(tm, " in ", :in)
    mark_all!(tm, "\nin ", :in)
    mark_all!(tm, "begin ", :begin)
    mark_all!(tm, "begin\n", :begin)
    mark_all!(tm, "module ", :module)

    #mark_between!(tm, "#=",  :comment, until  =  ["=#"])
    mark_between!(tm, "'", :char)

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
    style!(tm, :func, ["color" => "#fc038c"])
    style!(tm, :funcn, ["color" => "blue"])
    style!(tm, :using, ["color" => "teal"])
    style!(tm, :import, ["color" => "#fc038c"])
    style!(tm, :end, ["color" => "#b81870"])
    style!(tm, :mutable, ["color" => "teal"])
    style!(tm, :struct, ["color" => "#fc038c"])
    style!(tm, :begin, ["color" => "#fc038c"])
    style!(tm, :module, ["color" => "red"])
    style!(tm, :string, ["color" => "green"])
    style!(tm, :if, ["color" => "#fc038c"])
    style!(tm, :for, ["color" => "#fc038c"])
    style!(tm, :in, ["color" => "teal"])
    style!(tm, :abstract, ["color" => "teal"])
    style!(tm, :number, ["color" => "#8b0000"])
    style!(tm, :char, ["color" => "#8b0000"])
    style!(tm, :type, ["color" => "#D67229"])
    style!(tm, :exit, ["color" => "teal"])
    style!(tm, :op, ["color" => "darkblue"])
    style!(tm, :multistring, ["color" => "darkgreen"])
    style!(tm, :default, ["color" => "#3D3D3D"])
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
### split_by_range(tm::TextModifier)
------------------
Filters marks and then collects them into a `Vector{Any}` of Strings and
Pairs of symbols and styles.
#### example
```

```
"""
function split_by_range(tm::TextModifier)
    prev::Int64 = 1
    finals = Vector{Any}()
    filtmarks = [begin
        if length(nmark) <= 0
            1:1
        elseif isnothing(nmark)
            1:1
        else
            nmark
        end
    end for nmark in collect(keys(tm.marks))]
        filter!(i -> i != 1:1,  filtmarks)
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

"""
**Toolips Markdown**
### string(tm::TextModifier) -> ::String
------------------
Styles marks together into `String`.
#### example
```

```
"""
string(tm::TextModifier) = begin
    out::String = join([begin
    spoof = Toolips.SpoofConnection()
    txt = nothing
    if typeof(text) == Pair{Symbol, String}
        txt = a("modiftxt", text = replace(text[2], " "  => "&nbsp;",
        "\n"  =>  "<br>", "</br>" => "<br>", "\\" => "&bsol;"))
        if text[1] in keys(tm.styles)
            style!(txt, tm.styles[text[1]] ...)
        end
    else
        txt = a("modiftxt", text = replace(text, " "  => "&nbsp;",
        "\n"  =>  "<br>", "</br>" => "<br>", "\\" => "&bsol;"))
        style!(txt, tm.styles[:default] ...)
    end
    write!(spoof, txt)
    spoof.http.text
    end for text in split_by_range(tm)])
    out::String
end

export tmd, @tmd_str
end # module
