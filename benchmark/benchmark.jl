using Benchmark
using RingArrays

function print_seperator(file::IOStream, name::AbstractString)
    seperator = "################################################################################"
    println(file)
    println(file, seperator)
    println(file, "# ", name)
    println(file, seperator)
    println(file)
end

open(joinpath(dirname(@__FILE__), "benchmark_result"), "w") do benchmark_file

    num_test = 100
    m_b = 10
    b_s = (10,)
    d_l = 100000
    big_data = rand(Int, d_l)

    print_seperator(benchmark_file, "constructor")

    constructor_ring_bench() = RingArray{Int, 1}(max_blocks=m_b, block_size=b_s, data_length=d_l)
    constructor_normal_array_bench() = Array{Int, 1}()

    println(benchmark_file, benchmark(constructor_ring_bench, "constructor ring", "RingArray{Int, 1}(max_blocks=m_b, block_size=b_s, data_length=d_l)", num_test), "\n")
    println(benchmark_file, benchmark(constructor_normal_array_bench, "constructor normal array", "Array{Int, 1}()", num_test), "\n")
    println(benchmark_file, compare([constructor_ring_bench, constructor_normal_array_bench], num_test), "\n")

    print_seperator(benchmark_file, "load_block")

    function loading_no_gc()
        ring = RingArray{Int, 1}(max_blocks=m_b, block_size=b_s, data_length=d_l)
        for i in 1:b_s[1]:d_l
            prev_write = ring.next_write
            load_block(ring, big_data[i:i+b_s[1]-1])
            let
                view = ring[i:b_s[1]-1]
            end
            ring.num_users[prev_write] = 0
        end
    end

    function loading_with_gc()
        ring = RingArray{Int, 1}(max_blocks=m_b, block_size=b_s, data_length=d_l)
        for i in 1:b_s[1]:d_l
            load_block(ring, big_data[i:i+b_s[1]-1])
            let
                view = ring[i:b_s[1]-1]
            end
        end
    end

    println(benchmark_file, benchmark(loading_no_gc, "loading with no gc", "load_block", num_test), "\n")
    println(benchmark_file, benchmark(loading_with_gc, "loading with gc", "load_block", num_test), "\n")
    println(benchmark_file, compare([loading_no_gc, loading_with_gc], num_test), "\n")

    empty_ring = RingArray{Int, 1}(max_blocks=m_b, block_size=b_s, data_length=d_l)
    full_ring = RingArray{Int, 1}(max_blocks=m_b, block_size=b_s, data_length=d_l)
    end_ring = RingArray{Int, 1}(max_blocks=m_b, block_size=b_s, data_length=d_l)

    for i in 1:b_s[1]:b_s[1]*m_b
        load_block(full_ring, big_data[i:i+b_s[1]-1])
    end

    for i in 1:b_s[1]:d_l
        load_block(end_ring, big_data[i:i+b_s[1]-1])
    end

    print_seperator(benchmark_file, "size")

    size_empty_bench() = size(empty_ring)
    size_full_bench() = size(full_ring)
    size_end_bench() = size(end_ring)
    size_normal_array_bench() = size(big_data)

    println(benchmark_file, benchmark(size_empty_bench, "size empty ring", "size(empty_ring)", num_test), "\n")
    println(benchmark_file, benchmark(size_full_bench, "size full ring", "size(full_ring)", num_test), "\n")
    println(benchmark_file, benchmark(size_end_bench, "size end ring", "size(end_ring)", num_test), "\n")
    println(benchmark_file, benchmark(size_normal_array_bench, "size normal array", "size(big_data)", num_test), "\n")
    println(benchmark_file, compare([size_empty_bench, size_full_bench, size_end_bench, size_normal_array_bench], num_test), "\n")

    print_seperator(benchmark_file, "checkbounds")

    #checkbounds_empty_bench() = checkbounds(empty_ring, empty_ring.range.stop) throws an error
    checkbounds_full_bench() = checkbounds(full_ring, full_ring.range.stop)
    checkbounds_end_bench() = checkbounds(end_ring, end_ring.range.stop)
    checkbounds_normal_array_bench() = checkbounds(big_data, end_ring.range.stop)

    #println(benchmark_file, benchmark(checkbounds_empty_bench, "checkbounds empty ring", "checkbounds(empty_ring, empty_ring.range.stop)", num_test), "\n")
    println(benchmark_file, benchmark(checkbounds_full_bench, "checkbounds full ring", "checkbounds(full_ring, full_ring.range.stop)", num_test), "\n")
    println(benchmark_file, benchmark(checkbounds_end_bench, "checkbounds end ring", "checkbounds(end_ring, end_ring.range.stop)", num_test), "\n")
    println(benchmark_file, benchmark(checkbounds_normal_array_bench, "checkbounds normal array", "checkbounds(big_data, end_ring.range.stop)", num_test), "\n")
    println(benchmark_file, compare([checkbounds_full_bench, checkbounds_end_bench, checkbounds_normal_array_bench], num_test), "\n")

    print_seperator(benchmark_file, "getindex")

    getindex_full_start_bench() = full_ring[full_ring.range.start]
    getindex_full_stop_bench() = full_ring[full_ring.range.stop]
    getindex_end_start_bench() = end_ring[end_ring.range.start]
    getindex_end_stop_bench() = end_ring[end_ring.range.stop]
    getindex_normal_array_bench() = big_data[end_ring.range.stop]

    println(benchmark_file, benchmark(getindex_full_start_bench, "getindex full start ring", "full_ring[full_ring.range.start]", num_test), "\n")
    println(benchmark_file, benchmark(getindex_full_stop_bench, "getindex full stop ring", "full_ring[full_ring.range.stop]", num_test), "\n")
    println(benchmark_file, benchmark(getindex_end_start_bench, "getindex end start ring", "end_ring[end_ring.range.start]", num_test), "\n")
    println(benchmark_file, benchmark(getindex_end_stop_bench, "getindex end stop ring", "end_ring[end_ring.range.stop]", num_test), "\n")
    println(benchmark_file, benchmark(getindex_normal_array_bench, "getindex normal array", "big_data[end_ring.range.stop]", num_test), "\n")
    println(benchmark_file, compare([getindex_full_start_bench, getindex_full_stop_bench, getindex_end_start_bench, getindex_end_stop_bench, getindex_normal_array_bench], num_test), "\n")

    print_seperator(benchmark_file, "getindex range")

    getindex_range_full_all_bench() = full_ring[full_ring.range]
    getindex_range_full_small_bench() = full_ring[full_ring.range.stop:full_ring.range.stop]
    getindex_range_end_all_bench() = end_ring[end_ring.range]
    getindex_range_end_small_bench() = end_ring[end_ring.range.stop:end_ring.range.stop]
    getindex_range_normal_array_all_bench() = big_data[end_ring.range]
    getindex_range_normal_array_small_bench() = big_data[end_ring.range.stop:end_ring.range.stop]

    println(benchmark_file, benchmark(getindex_range_full_all_bench, "getindex range full all ring", "full_ring[full_ring.range]", num_test), "\n")
    println(benchmark_file, benchmark(getindex_range_full_small_bench, "getindex range full small ring", "full_ring[full_ring.range.stop:full_ring.range.stop]", num_test), "\n")
    println(benchmark_file, benchmark(getindex_range_end_all_bench, "getindex range end all ring", "end_ring[end_ring.range]", num_test), "\n")
    println(benchmark_file, benchmark(getindex_range_end_small_bench, "getindex range end small ring", "end_ring[end_ring.range:end_ring.range.stop]", num_test), "\n")
    println(benchmark_file, benchmark(getindex_range_normal_array_all_bench, "getindex range normal all array", "big_data[end_ring.range]", num_test), "\n")
    println(benchmark_file, benchmark(getindex_range_normal_array_small_bench, "getindex range normal small array", "big_data[end_ring.range.stop:end_ring.range.stop]", num_test), "\n")
    println(benchmark_file, compare([getindex_range_full_all_bench, getindex_range_full_small_bench, getindex_range_end_all_bench, getindex_range_end_small_bench, getindex_range_normal_array_all_bench, getindex_range_normal_array_small_bench], num_test), "\n")

    print_seperator(benchmark_file, "overall")

    standard() = 0
    println(benchmark_file, compare(
        [
            standard,
            constructor_ring_bench, constructor_normal_array_bench,
            loading_no_gc, loading_with_gc,
            size_empty_bench, size_full_bench, size_end_bench, size_normal_array_bench,
            checkbounds_full_bench, checkbounds_end_bench, checkbounds_normal_array_bench,
            getindex_full_start_bench, getindex_full_stop_bench, getindex_end_start_bench, getindex_end_stop_bench, getindex_normal_array_bench,
            getindex_range_full_all_bench, getindex_range_full_small_bench, getindex_range_end_all_bench, getindex_range_end_small_bench, getindex_range_normal_array_all_bench, getindex_range_normal_array_small_bench,
        ],
        num_test), "\n")

end