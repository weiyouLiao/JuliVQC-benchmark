source ./bin/activate
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export MKL_DOMAIN_NUM_THREADS=1
export JULIA_NUM_THREADS=1

cd $1
if [ "$1" = "JuliVQC" ] || [ "$1" = "yao" ]; then
  julia --project ./single_gate_test.jl
else
  pytest ./single_gate_test.py --benchmark-save="single_gate_test" --benchmark-sort=name --benchmark-min-rounds=5
fi
cd ../