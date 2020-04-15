using ArgParse
using Printf

struct Args
    c::String
    jl::String
    bar::Int
end

function parse_parameters()::Args
    s = ArgParseSettings()
    @add_arg_table! s begin
        "--c-output", "-c"
            help = "file in which c output is stored"
            arg_type = String
        "--julia-output", "-j"
            help = "file in which julia output is stored"
            arg_type = String
        "--bar-width", "-b"
            help = "the width of a bar visualising the relative difference"
            arg_type = Int
            default = 10
    end
    args = parse_args(ARGS, s)
    c = args["c-output"]
    jl = args["julia-output"]
    if c == nothing && jl == nothing
        error("At least one of -c and -j needs to be given")
    elseif c == nothing
        c = string("c", jl[3:end])
    elseif jl == nothing
        jl = string("jl", c[2:end])
    end
    Args(c, jl, args["bar-width"])
end

function bar(rel::Float64, width::Int)
    abs_rel = abs(rel)
    if abs_rel >= 1
        cnt = width
    elseif abs_rel < 10e-9
        cnt = 0
    else
        cnt = floor(Int64, width * abs_rel)
    end
    return string("[","#"^cnt, " "^(width-cnt), "]")
end

function main()
    args = parse_parameters()
    
    println("#Comparing files:")
    println("#C:\t\t", args.c)
    println("#Julia:\t\t", args.jl)

    c = readlines(open(args.c))
    jl = readlines(open(args.jl))
    c = c[findfirst(s->occursin("runtime_sec", s), c)+1:end]
    jl = jl[findfirst(s->occursin("runtime_sec", s), jl)+1:end]

    c_val = Vector{Tuple{Any, Any}}(undef, 0)
    for line in c
        m = match(r"\s*([^\s]+\s*[^\s]+\s*[^\s]+)\s*(\d+\.\d+)",line)
        if m != nothing
            push!(c_val, (m[1], parse(Float64, m[2])))
        end
    end

    jl_val = Vector{Tuple{Any, Any}}(undef, 0)
    for line in jl
        m = match(r"\s*([^\s]+\s*[^\s]+\s*[^\s]+)\s*(\d+\.\d+)",line)
        if m != nothing
            push!(jl_val, (m[1], parse(Float64, m[2])))
        end
    end

    Printf.@printf "%50s %14s %14s %14s %14s %s\n" "" "C" "Julia" "Abs Diff" "Rel Diff" "Rel as bar"
    for (c, jl) in zip(c_val, jl_val)
        absolute = jl[2] - c[2]
        relative = absolute / c[2]
        if absolute < 0 # julia is faster
            if relative < -0.5 # >50% faster
                Printf.@printf "%50s %14.10f %14.10f \e[37;42m%14.10f %14.10f %s\e[0m\n" c[1] c[2] jl[2] absolute relative bar(relative, args.bar)
            else
                Printf.@printf "%50s %14.10f %14.10f \e[32m%14.10f %14.10f %s\e[0m\n" c[1] c[2] jl[2] absolute relative bar(relative, args.bar)
            end
        elseif abs(absolute) < 10e-9 # roughly equal
            Printf.@printf "%50s %14.10f %14.10f %14.10f %14.10f\n" c[1] c[2] jl[2] absolute relative
        else # c is faster
            if relative > 0.5 # >50% faster
                Printf.@printf "%50s %14.10f %14.10f \e[37;41m%14.10f %14.10f %s\e[0m\n" c[1] c[2] jl[2] absolute relative bar(relative, args.bar)
            else
                Printf.@printf "%50s %14.10f %14.10f \e[31m%14.10f %14.10f %s\e[0m\n" c[1] c[2] jl[2] absolute relative bar(relative, args.bar)
            end
        end
    end

end

main()