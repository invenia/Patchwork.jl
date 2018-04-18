import Compat: Dates
import Dates: Hour

function strip_lineno!(expr::Expr)
   filter!(expr.args) do ex
       isa(ex, LineNumberNode) && return false
       if isa(ex, Expr)
           ex.head === :line && return false
           strip_lineno!(ex::Expr)
       end
       return true
   end
   return expr
end

@testset "patch" begin
    @testset "basic" begin
        p = @patch f(a, b::Int64, c=3, d::Integer=4; e=5, f::Int=6) = nothing
        @test p.signature == :(f(a, b::Core.Int64, c=3, d::Core.Integer=4; e=5, f::$INT_EXPR=6))
        @test p.modules == Set([:Core])
        expected = quote
            import Core
            f(a, b::Core.Int64, c=3, d::Core.Integer=4; e=5, f::$INT_EXPR=6) = $(p.body)(a, b, c, d; e=e, f=f)
        end
        @test Mocking.convert(Expr, p) == strip_lineno!(expected)
    end

    @testset "variable argument parameters" begin
        p = @patch f(a::Integer...) = nothing
        @test p.signature == :(f(a::Core.Integer...))
        @test p.modules == Set([:Core])
        expected = quote
            import Core
            f(a::Core.Integer...) = $(p.body)(a...)
        end
        @test Mocking.convert(Expr, p) == strip_lineno!(expected)
    end

    @testset "variable keyword parameters" begin
        p = @patch f(; a...) = nothing
        @test p.signature == :(f(; a...))
        @test p.modules == Set()
        expected = quote
            f(; a...) = $(p.body)(; a...)
        end
        @test Mocking.convert(Expr, p) == strip_lineno!(expected)
    end

    # Issue #15
    @testset "anonymous parameter" begin
        anon = next_gensym("anon", 1)
        p = @patch f(::Type{UInt8}, b::Int64) = nothing
        @test p.signature == :(f($anon::Core.Type{Core.UInt8}, b::Core.Int64))
        @test p.modules == Set([:Core])
        expected = quote
            import Core
            f($anon::Core.Type{Core.UInt8}, b::Core.Int64) = $(p.body)($anon, b)
        end
        @test Mocking.convert(Expr, p) == strip_lineno!(expected)
    end

    @testset "assertion expression" begin
        p = @patch f(t::typeof(+)) = nothing
        @test p.signature == :(f(t::typeof(Base.:+)))
        @test p.modules == Set([:Base])
        expected = quote
            import Base
            f(t::typeof(Base.:+)) = $(p.body)(t)
        end
        @test Mocking.convert(Expr, p) == strip_lineno!(expected)
    end

    @testset "assertion qualification" begin
        patches = [
            @patch f(h::Base.Core.Int64=rand(Base.Core.Int64)) = nothing
            @patch f(h::Core.Int64=rand(Core.Int64)) = nothing
            @patch f(h::Int64=rand(Int64)) = nothing
        ]
        for p in patches
            @test p.signature == :(f(h::Core.Int64=$RAND_EXPR(Core.Int64)))
            @test p.modules == Set([:Core, RAND_MOD_EXPR])
        end
    end

    @testset "array default" begin
        p = @patch f(a=[]) = a
        @test p.signature == :(f(a=[]))
        @test p.modules == Set()
    end

    @testset "tuple default" begin
        p = @patch f(a=()) = a
        @test p.signature == :(f(a=()))
        @test p.modules == Set()
    end
end
