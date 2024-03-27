export compute_potential, compute_acceleration

@inline @inbounds function terms(gh::GravityHarmonics, x) 
    tid = Threads.threadid()    
    V = @view get_tmp(gh.V, x)[:, :, tid]
    W = @view get_tmp(gh.W, x)[:, :, tid]
    return V, W
end

@inline coefficients(gh::GravityHarmonics) = (gh.C, gh.S)


function precompute_terms!(gh::GravityHarmonics{T}, pos, R) where T

    V, W = terms(gh, pos)
    
    # Sub-expressions 
    px, py, pz = pos[1], pos[2], pos[3]
    r² = px*px + py*py + pz*pz
    
    X = px * R / r²
    Y = py * R / r²
    Z = pz * R / r²
    R̄ = R*R /  r²

    # Initialize
    V[1, 1] = sqrt(R̄)

    # Zonal & tesseral terms
    for n in 1:gh.degree+1
        η₀ = gh.η0[n+1, 1]
        tmp = n == 1 ? T(0) : - η₀ * R̄ * V[n-1, 1]
        V[n+1, 1] = (1 + η₀) * Z * V[n, 1] + tmp 

        ηₙ = gh.η0[n+1, n+1]
        V[n+1, n+1] = ηₙ * (X * V[n, n] - Y * W[n, n])
        W[n+1, n+1] = ηₙ * (X * W[n, n] + Y * V[n, n]) 
    end

    # Sectorial terms 
    for n in 2:gh.degree+1 
        for m in 1:n-1
            η, ξ = gh.η0[n+1, m+1], gh.η1[n+1, m+1]
            V[n+1, m+1] = η * Z * V[n, m+1] - ξ * R̄ * V[n-1, m+1] 
            W[n+1, m+1] = η * Z * W[n, m+1] - ξ * R̄ * W[n-1, m+1]
        end
    end

    # Normalize
    for n in 1:gh.degree+1 
        V[n+1, 1] *= gh.N[n+1, 1]
        for m in 1:n 
            V[n+1, m+1] *= gh.N[n+1, m+1]
            W[n+1, m+1] *= gh.N[n+1, m+1]
        end
    end
    nothing

end

function compute_potential(gh::GravityHarmonics{T}, pos, μ, radius; recompute=true) where T 
    recompute && precompute_terms!(gh, pos, radius)

    # Get data
    V, W = terms(gh, pos)
    C, S = coefficients(gh)
    onlyzonal = gh.zonal

    # Compute potential 
    u = 0
    for n in gh.degree+1:-1:1
        if !onlyzonal
            for m in n:-1:2 # m ≠ 0 
                u += V[n, m] * C[n, m] + W[n, m] * S[n, m]
            end
        end
        u += V[n, 1] * C[n, 1] # m = 0
    end
    return μ/radius * u
end

function compute_acceleration(gh::GravityHarmonics{T}, pos::AbstractVector{P}, μ, radius, 
    args...; recompute=true) where {T, P} 
    # Precompute terms on the current thread
    recompute && precompute_terms!(gh, pos, radius)

    V, W = terms(gh, pos)
    C, S = coefficients(gh)
    ∂η0, ∂η1, ∂η2, ∂η3, onlyzonal = gh.∂η0, gh.∂η1, gh.∂η2, gh.∂η3, gh.zonal

    g = μ/radius^2
    ẍ = T(0)
    ÿ = T(0)
    z̈ = T(0)

    @inbounds for n in gh.degree+1:-1:1
        # Zonal terms (m=0)
        ẍ += ∂η0[n] * ( -C[n, 1] * V[n+1, 2] )
        ÿ += ∂η0[n] * ( -C[n, 1] * W[n+1, 2] ) 
        z̈ += ∂η3[n, 1] * ( -C[n, 1] * V[n+1, 1] )

        if !onlyzonal 
            # Other terms
            for m in n:-1:2
                ẍ += ∂η1[n, m] * ( -C[n,m]*V[n+1, m+1] - S[n,m]*W[n+1,m+1] )
                ẍ += ∂η2[n, m] * ( C[n,m]*V[n+1,m-1] + S[n,m]*W[n+1,m-1] )
                ÿ += ∂η1[n, m] * ( -C[n,m]*W[n+1, m+1] + S[n,m]*V[n+1,m+1] )
                ÿ += ∂η2[n, m] * ( -C[n,m]*W[n+1,m-1] + S[n,m]*V[n+1,m-1] )
                z̈ += ∂η3[n, m] * ( -C[n,m]*V[n+1, m] - S[n,m]*W[n+1,m] )
            end
        end
    end

    return SVector{3, P}( g*ẍ, g*ÿ, g*z̈ )

end