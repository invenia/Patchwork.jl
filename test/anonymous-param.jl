# Issue #15
let f, patch
    f{T<:Unsigned}(::Type{T}, n::Int64) = rand(T, n)

    patch = @patch f(::Type{UInt8}, n::Int64) = collect(UnitRange{UInt8}(1:n))

    apply(patch) do
        @test (@mock f(UInt8, 2)) == [0x01, 0x02]
    end
end