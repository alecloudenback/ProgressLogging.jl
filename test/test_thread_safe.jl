module TestThreadSafe

using ProgressLogging: @progress, ProgressLevel
using Test
using Test: collect_test_logs
using Base.Threads

@testset "Thread-safe @progress" begin
    # Test 1: Regular loop (should work as before)
    let counter = 0
        logs, = collect_test_logs(min_level = ProgressLevel) do
            @progress for i = 1:100
                counter += 1
            end
        end
        @test counter == 100
        @test length(logs) >= 2
        @test logs[1].kwargs[:progress] === nothing
        @test logs[end].kwargs[:progress] == "done"
    end
    
    # Test 2: Threaded loop - the progress macro is now thread-safe by default
    let counter = Threads.Atomic{Int}(0)
        logs, = collect_test_logs(min_level = ProgressLevel) do
            Threads.@threads for i = 1:100
                @progress for j = 1:1
                    Threads.atomic_add!(counter, 1)
                end
            end
        end
        @test counter[] == 100
    end
    
    # Test 3: Named progress with thread-safe operations
    let sum_val = Threads.Atomic{Int}(0)
        logs, = collect_test_logs(min_level = ProgressLevel) do
            @progress "computing" for i = 1:50
                Threads.atomic_add!(sum_val, i)
            end
        end
        @test sum_val[] == sum(1:50)
        @test length(logs) >= 2
    end
    
    # Test 4: Array comprehension (should still work)
    let result
        logs, = collect_test_logs(min_level = ProgressLevel) do
            @progress result = [i^2 for i = 1:10]
        end
        @test result == [i^2 for i = 1:10]
    end
end

end  # module
