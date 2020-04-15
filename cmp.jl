using ArgParse
using Printf

struct Args
    c::String
    jl::String
end

function parse_parameters()::Args
    s = ArgParseSettings()
    @add_arg_table! s begin
        "--c-output", "-c"
            help = "file in which c output is stored"
            required = true
            arg_type = String
        "--julia-output", "-j"
            help = "file in which julia output is stored"
            required = true
            arg_type = String
    end
    args = parse_args(ARGS, s)
    Args(args["c-output"], args["julia-output"])
end

function main()
    args = parse_parameters()
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

    Printf.@printf "%50s %14s %14s %14s %14s\n" "" "C" "Julia" "Abs Diff" "Rel Diff"
    for (c, jl) in zip(c_val, jl_val)
        if jl[2] - c[2] < 0 # julia is faster
            if (jl[2]-c[2])/c[2] < -0.5 # >50% faster
                Printf.@printf "%50s %14.10f %14.10f \e[37;42m%14.10f %14.10f\e[0m\n" c[1] c[2] jl[2] (jl[2]-c[2]) (jl[2]-c[2])/c[2]
            else
                Printf.@printf "%50s %14.10f %14.10f \e[32m%14.10f %14.10f\e[0m\n" c[1] c[2] jl[2] (jl[2]-c[2]) (jl[2]-c[2])/c[2]
            end
        elseif abs(jl[2] - c[2]) < 10e-9 # roughly equal
            Printf.@printf "%50s %14.10f %14.10f %14.10f %14.10f\n" c[1] c[2] jl[2] (jl[2]-c[2]) (jl[2]-c[2])/c[2]
        else # c is faster
            if (jl[2]-c[2])/c[2] > 0.5 # >50% faster
                Printf.@printf "%50s %14.10f %14.10f \e[37;41m%14.10f %14.10f\e[0m\n" c[1] c[2] jl[2] (jl[2]-c[2]) (jl[2]-c[2])/c[2]
            else
                Printf.@printf "%50s %14.10f %14.10f \e[31m%14.10f %14.10f\e[0m\n" c[1] c[2] jl[2] (jl[2]-c[2]) (jl[2]-c[2])/c[2]
            end
        end
    end

end

main()