
abstract type AbstractKernel end
abstract type AbstractDistanceMetric end

struct SquaredExp <: AbstractKernel end
struct WhiteNoise <: AbstractKernel end

struct Euclidean <: AbstractDistanceMetric end

@inline dim_hp(::SquaredExp, dim) = dim + 1

@inline kernel(::T, hp, x; ϵ=1e-7) where {T <: AbstractKernel} = kernel(T(), hp, x, x; ϵ=ϵ)

function kernel(::SquaredExp, hp, x, xp; ϵ=1e-7)
    kern = similar(x, size(x)[2], size(xp)[2])
    threaded_kernel_impl!(SquaredExp(), kern, hp, x, xp)
    if x === xp
        kern .= kern + ϵ * I
    end
    return kern
end

function serial_kernel(::SquaredExp, hp, x, xp)
    kern = similar(x, size(x)[2], size(xp)[2])
    kernel_impl!(SquaredExp(), kern, hp, x, xp)
    return kern
end

function distance!(::Euclidean, D, x, xp)
    n = [CartesianIndex()]
    fill!(D, zero(eltype(D)))
    sum!(D, (x[:,:,n] .- xp[:,n,:]).^2, 1)
    return nothing
end

function distance(::T, x, xp) where {T <: AbstractDistanceMetric}
    D = similar(x, size(x)[2], size(xp)[2])
    distance!(T(), D, x, xp)
return D
end

function kernel_impl!(::SquaredExp, kern, hp, x, xp)
    n = [CartesianIndex()]
    ls = @view hp[2:end]
    σ = hp[1]
    xs, xps = (x[:,:] .* ls[:,n], xp[:,:] .* ls[:,n])
    distance!(Euclidean(), kern, lz(xs), lz(xps))
    kern .= σ^2 .* exp.(-1.0 .* kern)
    return nothing
end

function halve_kernel(K, x, xp)
    lx = size(x)[2]
    lxp = size(xp)[2]
    mx = lx >> 1
    mxp = lxp >> 1
    cond = lx > lxp
    @views K1, x1, xp1 = cond ? (K[1:mx, :], x[:,1:mx], xp) : (K[:,1:mxp], x, xp[:,1:mxp])
    @views K2, x2, xp2 = cond ? (K[(1 + mx):lx,:], x[:,(1 + mx):lx], xp) : (K[:,(1 + mxp):lxp], x, xp[:,(1 + mxp):lxp])

    return K1, x1, xp1, K2, x2, xp2
end


function threaded_kernel_impl!(::T, kern, hp, x, xp, nth=Threads.nthreads()) where {T <: AbstractKernel}
    if nth == 1
        kernel_impl!(T(), kern, hp, x, xp)
        return nothing
    end

    K1, x1, xp1, K2, x2, xp2 = halve_kernel(kern, x, xp)
    nth2 = nth >> 1

    t = Threads.@spawn threaded_kernel_impl!(T(), K1, hp, x1, xp1, nth2)
    threaded_kernel_impl!(T(), K2, hp, x2, xp2, nth - nth2)
    wait(t)

    return nothing
end

@inline function threaded_kernel_impl!(::T, kern::A, x, xp, hp, 
                                nth=Threads.nthreads()) where {T <: AbstractKernel,A <: AbstractGPUArray}
    kernel_impl!(T(), kern, x, xp, hp)
end