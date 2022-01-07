module GaussianProcessRegression

using ParallelArrays
using GPUArrays
using LinearAlgebra
using LoopVectorization
using Optim

export AbstractKernel, AbstractDistanceMetric, Euclidean, SquaredExp, WhiteNoise,
       ComposedKernel, kernel, kernel!, serial_kernel, distance, distance!, dim_hp, grad!,
       grad, AbstractModel, AbstractModelCache, AbstractGPRModel, GPRModel, GPRModelCache,
       predict, predict!, predict_mean, predict_mean!, predict_covar_impl!,
       predict_mean_impl!, update!, posterior, AbstractProcess, AbstractDistribution,
       NormalDistribution, sample, GaussianProcess, update_params!, update_cache!, loss,
       MarginalLikelihood, alloc_kernels, kernels, kernels!, add_noise!, model_cache,
       TrainGPRCache, train!, train, Cmap, SplitKernel, SplitDistanceA, SplitDistanceC,
       hessian_fd, hessian_fd!, bfgs_quad!, bfgs_quad, bfgs_hessian

const lz = LazyTensor

include("covariance.jl")
include("compose_covar.jl")
include("deriv_covar.jl")
include("models.jl")
include("distributions.jl")
include("predict.jl")
include("split_kernel.jl")
include("loss.jl")
include("train.jl")
include("update_model.jl")

end
