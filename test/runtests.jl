using Brikhead
using Test

const url = "https://afni.nimh.nih.gov/pub/dist/src/"
const filenames = [
   "TT_N27+tlrc",
   "TT_N27_CA_EZ_MPM+tlrc",
   "TT_N27_CA_EZ_PMaps+tlrc",
   "TT_N27_EZ_LR+tlrc",
   "TT_N27_EZ_ML+tlrc",
   "TT_avg152T1+tlrc",
   "TT_icbm452+tlrc",
   "TTatlas+tlrc"
]

const brikhead_dir = "./brikhead_samples"

function download_sample(filename, dir = brikhead_dir; url = url)
    if !isdir(dir)
        mkdir(dir)
    end
    headname = filename * ".HEAD"
    headfile = download_file(headname, dir, url)
    brikname = filename * ".BRIK.gz" 
    brikfile = download_file(brikname, dir, url)
    return (; brik = brikfile, head = headfile)
end

function download_file(filename, dir, url)
    fileurl = joinpath(url, filename)
    file = joinpath(dir, filename)

    if !isfile(file)
        println("Downloading $filename")
        download(fileurl, file)
    else
        println("File $filename already exists and won't be downloaded")
    end
    return file
end


@testset "BRIKHEAD.jl" begin
    samples = [download_sample(file) for file in filenames]
    load_brikhead_dir(brikhead_dir)
    load_brikhead(joinpath(brikhead_dir, filenames[1]))
    load_brikhead(samples[1].brik)
    (hdr, img) = load_brikhead(samples[end].head)
    Brikhead.get_resolution(hdr)
end
