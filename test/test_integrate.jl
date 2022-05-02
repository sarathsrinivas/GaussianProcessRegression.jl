
gaussian(x, xs, w) = exp(-w^2 * (x - xs)^2)

@testset "Definite Gaussian integrals" begin
    for i = 1:100
        xs = 3.0 * rand()
        w = 3.0 * rand()
        a = -3.0 + 6 * rand()
        b = -3.0 + 6 * rand()
        @testset "Gaussian integral" begin
            integ_quad = quadgk(x -> gaussian(x, xs, w), a, b; rtol = 1e-5)[1]
            integ_adrv = gauss_integ(xs, w, a, b)
            @test integ_quad ≈ integ_adrv
        end
        @testset "Erf integral" begin
            integ2_quad = quadgk(x -> gauss_integ(x, w, a, b), a, b; rtol = 1e-5)[1]
            integ2_adrv = erf_integ(w, a, b)
            @test integ2_quad ≈ integ2_adrv
        end
    end
end

@testset "SquaredExp antiderivative" begin
    @testset "dim=$dim n=$n" for dim = 2:5, n = 100:100:500
        xs = rand(dim, n)
        hp = 5.0 .* rand(dim_hp(SquaredExp(), dim))
        a = -2 .+ 4 .* rand(dim)
        b = a .+ 2.0 .* rand(dim)
        na = [CartesianIndex()]
        w = view(hp, 2:(dim+1))
        integ = hp[1]^2 .*
                prod(gauss_integ.(xs[:, :], w[:, na], a[:, na], b[:, na]); dims = 1)
        integ_loop = antideriv(SquaredExp(), xs, hp, a, b)
        @test dropdims(integ; dims = 1) ≈ integ_loop
    end
end

function gauss_leg_integ_3d(f, xg, wg)
    integ = zero(eltype(x))
    for i in eachindex(xg), j in eachindex(xg), k in eachindex(xg)
        integ += wg[i] * wg[j] * wg[k] * f(xg[i], xg[j], xg[k])
    end
    return integ
end

@testset "GP Integration" begin
    @testset "dim = 3 n = $n" for n = 100:100:500
        x = rand(3, n)
        y = dropdims(sin.(prod(x; dims = 1)) .^ 2; dims = 1)
        mds = GPRModel(SquaredExp(), x, y)
        hpmin, res = train(mds, MarginalLikelihood(); method = NewtonTrustRegion(),
                           options = Optim.Options(; g_tol = 1e-3))
        mds.params .= hpmin
        μ, σ = integrate(mds, zeros(3), ones(3))
        xg, wg = gauss(20, 0, 1)
        gauss_integral = gauss_leg_integ_3d((x, y, z) -> sin(x * y * z)^2, xg, wg)
        @test μ ≈ gauss_integral atol = 2σ
    end
end