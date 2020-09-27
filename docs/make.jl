using BRIKHEAD
using Documenter

makedocs(;
    modules=[BRIKHEAD],
    authors="Zaki A <zaki@live.ca> and contributors",
    repo="https://github.com/notZaki/BRIKHEAD.jl/blob/{commit}{path}#L{line}",
    sitename="BRIKHEAD.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://notZaki.github.io/BRIKHEAD.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/notZaki/BRIKHEAD.jl",
)
