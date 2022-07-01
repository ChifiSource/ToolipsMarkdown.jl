<img src = "https://github.com/ChifiSource/image_dump/blob/main/toolips/toolipsmarkdown.png"></img>

Parse markdown strings into Toolips Components.
```julia
using Toolips
using ToolipsMarkdown

markdownexample1 = tmd"""# Hello world, this is an example.
This extension, **[toolips markdown](http://github.com/ChifiSource/ToolipsMarkdown.jl)** allows the conversion of regular markdown into Toolips components.
"""
heading1s = Style("h1", color = "pink")
heading1s:"hover":["color" => "lightblue"]

myroute = route("/") do c::Connection
    write!(c, heading1s)
    mdexample2 = tmd("mymarkdown", "### hello world!")
    write!(c, markdownexample1)
    write!(c, mdexample2)
end
st = ServerTemplate()
st.add(myroute)
st.start()
[2022:07:01:17:22]: 🌷 toolips> Toolips Server starting on port 8000
[2022:07:01:17:22]: 🌷 toolips> /home/emmac/dev/toolips/ToolipsMarkdown/logs/log.txt not in current working directory.
[2022:07:01:17:22]: 🌷 toolips> Successfully started server on port 8000
[2022:07:01:17:22]: 🌷 toolips> You may visit it now at http://127.0.0.1:8000
```
<img src = "https://github.com/ChifiSource/ToolipsMarkdown.jl/blob/main/tgeregergerg.png"></img>
