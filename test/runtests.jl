module GmshImport_test_1
using Test
using GmshImport
using WriteVTK

function test()
    nodeblocks, elementblocks = gmsh_import("t1-rect.msh")
    b = nodeblocks[1]
    @test (b.block, b.nnodes) == (1, 1)
    b = nodeblocks[2]
    @test (b.block, b.nnodes) == (2, 1)
    b = nodeblocks[3]
    @test (b.block, b.nnodes) == (3, 1)
    b = nodeblocks[4]
    @test (b.block, b.nnodes) == (4, 1)
    b = nodeblocks[5]
    @test (b.block, b.nnodes) == (5, 13)
    b = nodeblocks[6]
    @test (b.block, b.nnodes) == (6, 39)
    b = nodeblocks[7]
    @test (b.block, b.nnodes) == (7, 13)
    b = nodeblocks[8]
    @test (b.block, b.nnodes) == (8, 39)
    b = nodeblocks[9]
    @test (b.block, b.nnodes) == (9, 596)

    b = elementblocks[1]
    @test (b.block, b.nelements) == (1, 14)
    b = elementblocks[2]
    @test (b.block, b.nelements) == (2, 40)
    b = elementblocks[3]
    @test (b.block, b.nelements) == (3, 40)
    b = elementblocks[4]
    @test (b.block, b.nelements) == (4, 1298)

    for b in elementblocks
        @test size(b.econn, 2) == GmshImport._elementtypes[b.elementtype][2]
    end

    maxnnumber = 0
    for b in nodeblocks
        maxnnumber = max(maximum(b.ntags), maxnnumber)
    end
    x = fill(0.0, maxnnumber)
    y = fill(0.0, maxnnumber)
    z = fill(0.0, maxnnumber)
    for b in nodeblocks
        for k in eachindex(b.ntags)
            j = b.ntags[k]
            x[j] = b.ncoor[k, 1]
            y[j] = b.ncoor[k, 2]
            z[j] = b.ncoor[k, 3]
        end
    end

    b = elementblocks[4]
    cells = [MeshCell(VTKCellTypes.VTK_TRIANGLE, b.econn[k, :]) for k in eachindex(b.etags)]

    vtk_grid("$(@__MODULE__())-triangles.vtu", x, y, z, cells) do vtk
        # add datasets...
    end

    nothing
end

test()
end

