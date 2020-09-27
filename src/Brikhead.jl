module BRIKHEAD

using Libz

export load_brikhead, load_brikhead_dir

struct AFNIAttribute
    name
    type
    count
    contents
end

# This will let us use hdr.attribute_name instead of hdr[:attribute_name].contents    
function Base.getproperty(hdr::Dict{Symbol,AFNIAttribute}, sym::Symbol)
    if sym ∈ propertynames(hdr)
        # Dict has innate properties, this case handles them
        return getfield(hdr, sym)
    else
        return getindex(hdr, sym).contents
    end
end

function parse_afni_head(file)
    chunks = get_chunks(file)
    attributes = parse_chunk.(chunks)
    return pack_attributes_as_dict(attributes)    
end

function get_chunks(file)
    f = open(file)
    lines = readlines(f)
    close(f)
    typelines = contains.(lines, r"type\s*=")
    chunks = Array{String,1}[]
    idx = findall(typelines)
    for i in 2:length(idx)
        push!(chunks, lines[idx[i-1]:idx[i]-1])
    end
    return chunks
end

function parse_chunk(chunk)
    type = parse_type(chunk)
    name = parse_name(chunk)
    count = parse_count(chunk)
    contents = parse_contents(chunk, type)
    return AFNIAttribute(name, type, count, contents)
end

function parse_type(chunk)
    line = first(chunk)
    if contains(line, "string")
        return String
    elseif contains(line, "integer")
        return Int
    elseif contains(line, "float")
        return Float64
    end
    error("No valid attribute found while parsing header in chunk:\n$(chunk)")
end

function parse_name(chunk)
    nameline = chunk[2]
    name = strip(split(nameline, "=")[2])
    return name
end

function parse_count(chunk)
    countline = chunk[3]
    count = parse(Int, split(countline, "=")[2])
    return count
end

function parse_contents(chunk, ::Type{String})
    # First character is ' and last is ~, so skip em
    return chunk[4][2:end-2]
end

function parse_contents(chunk, T::Type)
    contents_str = clean_chunk_contents(chunk)
    # Julia's builtin parse() takes care of everything
    contents = parse.(T, contents_str)
    return contents
end
    
function clean_chunk_contents(chunk)
    # Join all the lines to make parsing easier
    str_joined = strip(join(chunk[4:end]))
    # Numerical array are separated by spaces (tabs?)
    str_array = split(str_joined, " ")
    # Previous step converts multiple spaces into empty elements
    filter!(element -> !isempty(element), str_array)
    return str_array
end
        
function pack_attributes_as_dict(attributes::Vector{AFNIAttribute})
    dict = Dict{Symbol, AFNIAttribute}()
    for attribute in attributes
        key = Symbol(lowercase(attribute.name))
        dict[key] = attribute
    end
    return dict
end
    
function get_shape(hdr)
    (rank, num_timepoints) = hdr.dataset_rank[1:2]
    volume_dimensions = hdr.dataset_dimensions[1:rank]
    shape = (volume_dimensions..., num_timepoints)
    return shape
end

function get_resolution(hdr)
    voxel_sizes = abs.(hdr.delta)
    if haskey(hdr, :taxis_floatss)
        temporal_resolution = hdr.taxis_floats[2]
    else
        temporal_resolution = 0
    end
    resolution = (voxel_sizes..., temporal_resolution)
    return resolution
end

function load_brikhead_dir(path)
		files = readdir(dirname(path); join = true, sort = true)
		brikfiles = filter(is_brik, files)
		return load_brikhead.(brikfiles)
end

function load_brikhead(file)
    brikhead = find_brikhead(file)
    hdr = parse_afni_head(brikhead[:head])
    img = parse_afni_brik(brikhead[:brik], hdr)
    return (; hdr, img)
end

function filename_without_ext(filepath)
    filename = basename(filepath)
    filename_body = first(split(filename, "."))
    return filename_body
end

function find_brikhead(file)
    if is_brik(file)
        brik = file
        head = find_head(file)
    elseif is_head(file)
        brik = find_brik(file)
        head = file
    else
        brik = find_brik(file)
        head = find_head(file)
    end
    return Dict(:brik => brik, :head => head)
end

find_head(file) = find_otherfile(file, is_head)
find_brik(file) = find_otherfile(file, is_brik)

function find_otherfile(file, filterfunc)
    dir = dirname(file)
    otherfiles = readdir(dir; join=true)
    filter!(filterfunc, otherfiles)
    for otherfile in otherfiles
        if filename_without_ext(otherfile) == filename_without_ext(file)
            return otherfile
        end
    end
    error("Couldn't find file paired with $(file)")
end

is_head(file) = filename_contains(file, "head")
is_brik(file) = filename_contains(file, "brik")
is_gz(file) = filename_contains(file, "gz")

function filename_contains(file, needle)
    return needle ∈ split(lowercase(basename(file)), ".")
end

const briktypes = Dict(
    0 => UInt8,
    1 => Int16,
    3 => Float32,
    5 => Float64
)

function parse_afni_brik(file, hdr)
    @assert length(unique(hdr.brick_types)) == 1
    vol_shape = get_shape(hdr)
    num_elements = prod(vol_shape)
    briktype = briktypes[hdr.brick_types[1]]
    filebytes = Libz.inflate(read(file))
    # ToDo? Account for: d.byteorder_string
    image_volume = reshape(reinterpret(briktype, filebytes), vol_shape)
    return permutedims(image_volume, (2,1,3,4))
end

end
