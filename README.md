# BRIKHEAD 
[![Build Status](https://github.com/notZaki/BRIKHEAD.jl/workflows/CI/badge.svg)](https://github.com/notZaki/BRIKHEAD.jl/actions) 
[![Build Status](https://travis-ci.com/notZaki/BRIKHEAD.jl.svg?branch=master)](https://travis-ci.com/notZaki/BRIKHEAD.jl) 
[![Coverage](https://codecov.io/gh/notZaki/BRIKHEAD.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/notZaki/BRIKHEAD.jl)

Work-in-progress module for reading [AFNI](https://afni.nimh.nih.gov/) .BRIK and .HEAD files.

## Installation

This module is current not registered and can be installed by
```julia
]add https://github.com/notZaki/Brikhead.jl.git
```

## Loading data

To load a brikhead file:
```julia
julia> bh = load_brikhead("path/to/file")
```
where `file` can either be the `BRIK` or `HEAD` file.

The voxel data is stored in `bh.img` while the header information is in `bh.hdr`.

