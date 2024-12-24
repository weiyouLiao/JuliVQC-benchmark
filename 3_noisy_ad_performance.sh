source ./bin/activate
cd $1
threads_list=(1 2 4 8 16 32)
for threads in "${threads_list[@]}"
do
  export JULIA_NUM_THREADS=$threads
  julia --project noisy_ad_performance.jl
done

cd ../
