
const POLY_VERTICES = [
    SA[-20., 0., 25.],
    SA[0., 0., 25.],
    SA[0., 10., 25.],
    SA[-20., 10., 25.],
    SA[-20., 0., 15.],
    SA[0., 0., 15.],
    SA[0., 10., 15.],
    SA[-20., 10., 15.]
]

const POLY_FACES = [
    SA[1, 2, 4],
    SA[2, 3, 4],
    SA[1, 5, 6],
    SA[1, 6, 2],
    SA[1, 8, 5],
    SA[1, 4, 8],
    SA[2, 6, 7],
    SA[2, 7, 3],
    SA[4, 7, 8],
    SA[3, 7, 4],
    SA[5, 7, 6],
    SA[5, 8, 7]
]

const POLY_NORMALS = [
    SA[0.0, 0.0, 1.0], 
    SA[0.0, 0.0, 1.0],
    SA[0.0, -1.0, 0.0],
    SA[0.0, -1.0, 0.0],
    SA[-1.0, 0.0, 0.0],
    SA[-1.0, 0.0, 0.0],
    SA[1.0, 0.0, 0.0],
    SA[1.0, 0.0, 0.0],
    SA[0.0, 1.0, 0.0],
    SA[0.0, 1.0, 0.0],
    SA[0.0, 0.0, -1.0],
    SA[0.0, 0.0, -1.0],
]

const POLY_EDGE_NORMALS = [
    [[0.0, -1.0, -0.0], [0.4472135954999579, 0.8944271909999159, 0.0], [-1.0, 0.0, 0.0]],
    [[1.0, 0.0, -0.0], [0.0, 1.0, 0.0], [-0.4472135954999579, -0.8944271909999159, 0.0]],
    [[-1.0, -0.0, -0.0], [0.0, 0.0, -1.0], [0.4472135954999579, 0.0, 0.8944271909999159]],
    [[-0.4472135954999579, -0.0, -0.8944271909999159], [1.0, 0.0, -0.0], [0.0, 0.0, 1.0]],
    [[-0.0, 0.7071067811865475, 0.7071067811865475], [0.0, 0.0, -1.0], [0.0, -1.0, 0.0]],
    [[0.0, -0.0, 1.0], [0.0, 1.0, 0.0], [-0.0, -0.7071067811865475, -0.7071067811865475]],
    [[0.0, -1.0, -0.0], [0.0, 0.0, -1.0], [0.0, 0.7071067811865475, 0.7071067811865475]],
    [[0.0, -0.7071067811865475, -0.7071067811865475], [0.0, 1.0, -0.0], [0.0, 0.0, 1.0]],
    [[0.4472135954999579, -0.0, 0.8944271909999159], [0.0, 0.0, -1.0], [-1.0, 0.0, 0.0]],
    [[1.0, -0.0, 0.0], [-0.4472135954999579, 0.0, -0.8944271909999159], [0.0, 0.0, 1.0]],
    [[-0.4472135954999579, 0.8944271909999159, 0.0], [1.0, 0.0, 0.0], [-0.0, -1.0, -0.0]],
    [[-1.0, 0.0, 0.0], [-0.0, 1.0, 0.0], [0.4472135954999579, -0.8944271909999159, 0.0]]
]

const POLY_UNIQUE_EDGES = [
    (1, 2), (3, 7), (1, 4), (2, 6), (7, 8), (4, 7), (3, 4), (5, 6), (2, 7), 
    (1, 5), (4, 8), (5, 7), (1, 6), (2, 3), (5, 8), (2, 4), (6, 7), (1, 8)
]

const POLY_POTENTIAL = [
    ([27.5, 0.0, 0.0], 47.152969186107825),
    ([-27.5, 0.0, 0.0], 74.25111985011458),
    ([0.0, 27.5, 0.0], 62.50465873484183),
    ([0.0, -27.5, 0.0], 50.37170708849496),
    ([0.0, 0.0, 27.5], 154.96186050146974),
    ([0.0, 0.0, -27.5], 40.79745381995456),
    ([38.18921863655329, 26.366457066436492, 47.158029694953356], 33.84523694373697),
    ([19.492560022360088, 3.499241513850842, -38.82470573678237], 30.350297123025932),
    ([-88.79561823219863, -30.546010108331767, -22.893647484325633], 20.75332718957499),
    ([28.278934484314643, 45.65826133719488, 12.282129569594028], 35.53054499577149),
    ([-29.754993148283393, 36.34285563630308, -23.78709379249818], 34.78352544714981),
]

@test_nowarn PolyhedronGravityData{Float64}(POLY_VERTICES, POLY_FACES)
p = PolyhedronGravityData{Float64}(POLY_VERTICES, POLY_FACES)

@test_nowarn parse_model(Float64, PolyhedronGravity, p)
m = parse_model(Float64, PolyhedronGravity, p)

@testset "Face normals" begin 
    for f in eachindex(p.faces)
        @test all( Gravity.face_normal(p, f) .≈ POLY_NORMALS[f] )
    end
end;

@testset "Edge normals" begin 
    for f in eachindex(p.faces)
        edges_index = Gravity.face_edges_index(p, f)
        edges = Gravity.face_edges(p, f)
        n = Gravity.face_normal(p, f)
        for i in 1:3
            en = cross(edges[i], n)
            en /= norm(en)
            @test all( en .≈ POLY_EDGE_NORMALS[f][i] )
        end
    end
end;

@testset "Unique edges" begin 
    for key in POLY_UNIQUE_EDGES
        @test_nowarn p.adj[key]
    end
end;

@testset "Computation" verbose=true begin 

    @testset "Potential" begin 
        for ref in POLY_POTENTIAL
            pv, Uref = ref
            @test compute_potential(m, pv, 1.0, 1.0) ≈ Uref
        end
    end;

    @testset "Acceleration" begin 
        for ref in POLY_POTENTIAL 
            pv, _ = ref
            ∇Uref = ForwardDiff.gradient(x->compute_potential(m, x, 1.0, 1.0), pv)
            ∇U = compute_acceleration(m, pv, 1.0, 1.0)
            @test norm(∇Uref - ∇U) ≤ 1e-13
        end
    end;

end;
