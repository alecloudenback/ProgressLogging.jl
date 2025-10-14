module TestProgressThreads

using ProgressLogging: @progress, ProgressLevel
using Test
using Test: collect_test_logs
using Base.Threads

@testset "@progress with Threads.@threads" begin
    # Test basic threaded loop
    let counter = Threads.Atomic{Int}(0)
        logs, = collect_test_logs(min_level = ProgressLevel) do
            @progress Threads.@threads for i = 1:10
                Threads.atomic_add!(counter, 1)
            end
        end
        @test counter[] == 10
        # Should have logged at least start (nothing) and done
        @test length(logs) >= 2
        @test logs[1].kwargs[:progress] === nothing
        @test logs[end].kwargs[:progress] == "done"
    end
    
    # Test that thread-safe progress works with actual computation
    let sum_val = Threads.Atomic{Int}(0)
        logs, = collect_test_logs(min_level = ProgressLevel) do
            @progress "threaded sum" Threads.@threads for i = 1:100
                Threads.atomic_add!(sum_val, i)
            end
        end
        @test sum_val[] == sum(1:100)
        @test length(logs) >= 2
        @test logs[1].kwargs[:progress] === nothing
        @test logs[end].kwargs[:progress] == "done"
    end
    
    # Test with named progress
    let counter = Threads.Atomic{Int}(0)
        logs, = collect_test_logs(min_level = ProgressLevel) do
            @progress "named threaded" Threads.@threads for _ = 1:50
                Threads.atomic_add!(counter, 1)
            end
        end
        @test counter[] == 50
        @test length(logs) >= 2
        # Check that some progress values were logged between 0 and 1
        progress_vals = [l.kwargs[:progress] for l in logs if l.kwargs[:progress] isa Real]
        @test all(0 <= p <= 1 for p in progress_vals)
    end
    
    # Test with Base.Threads.@threads syntax
    let counter = Threads.Atomic{Int}(0)
        logs, = collect_test_logs(min_level = ProgressLevel) do
            @progress Base.Threads.@threads for _ = 1:30
                Threads.atomic_add!(counter, 1)
            end
        end
        @test counter[] == 30
        @test length(logs) >= 2
        @test logs[1].kwargs[:progress] === nothing
        @test logs[end].kwargs[:progress] == "done"
    end
    
    # Test with custom threshold
    let counter = Threads.Atomic{Int}(0)
        logs, = collect_test_logs(min_level = ProgressLevel) do
            @progress 0.1 Threads.@threads for _ = 1:100
                Threads.atomic_add!(counter, 1)
            end
        end
        @test counter[] == 100
        @test length(logs) >= 2
        # With a higher threshold, we should see fewer progress updates
        progress_vals = [l.kwargs[:progress] for l in logs if l.kwargs[:progress] isa Real]
        @test all(0 <= p <= 1 for p in progress_vals)
    end
    
    # Test that progress is actually increasing
    let counter = Threads.Atomic{Int}(0)
        logs, = collect_test_logs(min_level = ProgressLevel) do
            @progress "increasing" Threads.@threads for _ = 1:200
                Threads.atomic_add!(counter, 1)
            end
        end
        @test counter[] == 200
        # Get progress values (excluding nothing and "done")
        progress_vals = [l.kwargs[:progress] for l in logs if l.kwargs[:progress] isa Real]
        # Progress should be monotonically increasing (or at least non-decreasing)
        if length(progress_vals) > 1
            for i in 2:length(progress_vals)
                @test progress_vals[i] >= progress_vals[i-1]
            end
        end
    end
end

end  # module
