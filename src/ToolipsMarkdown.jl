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
    tmd("tmd", s)
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
function tmd(name::String = "tmd", s::String = "")
    mddiv = divider(name)
    md = Markdown.parse(s)
    htm = html(md)
    htm = replace(htm, "&quot;" => "")
    mddiv[:text] = htm
    mddiv
end

end # module
