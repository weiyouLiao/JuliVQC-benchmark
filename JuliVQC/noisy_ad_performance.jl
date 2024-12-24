using JSON, Base.Threads
using QuantumCircuits, JuliVQC, JuliVQC.Utilities, Zygote
using BenchmarkTools
import MPSSimulator.fuse_gates
using DataFrames
using CSV
using Random
mark = "JuliVQC"
BenchmarkTools.DEFAULT_PARAMETERS.seconds = 5000
BenchmarkTools.DEFAULT_PARAMETERS.samples = 5
BenchmarkTools.DEFAULT_PARAMETERS.evals = 1
const nqubit_list = [14]
const benchmarks = Dict()
println("running")
function build_noisy_circuit(L::Int)
	depth = 1
	circuit = QCircuit()
	for i in 1:L
		push!(circuit, RxGate(i, randn()*2π, isparas=true))
		push!(circuit, RzGate(i, randn()*2π, isparas=true))
		push!(circuit, Depolarizing(i, p=0.01))
	end		
	for i in 1:depth
		if isodd(i)
			for j in 1:(L-1)
		    	push!(circuit, CNOTGate(j, j+1))
			end

		else
			for j in (L-1):-1:1
		    	push!(circuit, CNOTGate(j, j+1))
			end		
		end
		for j in 1:L
			push!(circuit, RxGate(j, randn()*2π, isparas=true))
			push!(circuit, RzGate(j, randn()*2π, isparas=true))
			push!(circuit, RxGate(j, randn()*2π, isparas=true))
		end
		for i in 1:L
			push!(circuit, Depolarizing(i, p=0.01))
		end
	end
	return circuit	
end

thread_count = Threads.nthreads()
key = "vqc_thread$(thread_count)"
println(key)
benchmarks[key] = Dict(
    "thread" => string(thread_count),
    "nqubits" => nqubit_list,
    "meantimes" => Float64[],
    "stdtimes" => Float64[],
    "minimumtimes" => Float64[],
    "maximumtimes" => Float64[]
)

function ad_excute(circuit, state, ham)
	loss(circ) = real(expectation(ham, circ * state))
	gradient(loss, circuit)
end


for nqubit in nqubit_list
	result = @benchmark ad_excute($(build_noisy_circuit(nqubit)), $(DensityMatrix(ComplexF32, nqubit)), $(heisenberg_1d(nqubit)))
    push!(benchmarks[key]["meantimes"], mean(result).time/1e9)
    push!(benchmarks[key]["stdtimes"], std(result).time/1e9)
    push!(benchmarks[key]["minimumtimes"], minimum(result).time/1e9)
    push!(benchmarks[key]["maximumtimes"], maximum(result).time/1e9)
end


function read_and_append_json(filename, new_data)
    existing_data = Dict()

    if isfile(filename) && filesize(filename) > 0
        try
            existing_data = JSON.parsefile(filename)
        catch e
            println("JSON error", e)
        end
    end

    existing_data = merge(existing_data, new_data)

    json_str = JSON.json(existing_data,4)

    open(filename, "w") do io
        write(io, json_str)
    end
end
new_data = Dict(key => benchmarks[key])

filename = "./.benchmarks/Linux-CPython-3.9-64bit/noisy_ad_performance.json"


read_and_append_json(filename, new_data)