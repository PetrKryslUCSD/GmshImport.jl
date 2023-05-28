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

module GmshImport_test_2
using Test
using GmshImport
using WriteVTK

function test()
    nodeblocks, elementblocks = gmsh_import("t5-tet-corner.msh")
    @test length(nodeblocks) == 180
    @test length(elementblocks) == 6

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

    for b in elementblocks
        cells = [MeshCell(VTKCellTypes.VTK_QUADRATIC_TETRA, b.econn[k, [1, 2, 3, 4, 5, 6, 7, 8, 10, 9]]) for k in eachindex(b.etags)]

        vtk_grid("$(@__MODULE__())-tetrahedra-$(b.block).vtu", x, y, z, cells) do vtk
        # add datasets...
        end
    end

    nothing
end

test()
end

module GmshImport_test_3
using Test
using GmshImport
using WriteVTK

function test()
    nodeblocks, elementblocks = gmsh_import("t5-tet-corner-coarse.msh")
    @test length(nodeblocks) == 167
    @test length(elementblocks) == 6

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

    for b in elementblocks
        cells = [MeshCell(VTKCellTypes.VTK_TETRA, b.econn[k, :]) for k in eachindex(b.etags)]

        vtk_grid("$(@__MODULE__())-tetrahedra-$(b.block).vtu", x, y, z, cells) do vtk
        # add datasets...
        end
    end

    nothing
end

test()
end


module GmshImport_test_4
using Test
using GmshImport
using WriteVTK

function test()
    nodeblocks, elementblocks = gmsh_import("t1-rect.msh", ["TRI 3",])
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
    @test (b.block, b.nelements) == (4, 1298)

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

    for b in elementblocks
        b.elementtype == 2
    end

    b = elementblocks[1]
    cells = [MeshCell(VTKCellTypes.VTK_TRIANGLE, b.econn[k, :]) for k in eachindex(b.etags)]

    vtk_grid("$(@__MODULE__())-triangles.vtu", x, y, z, cells) do vtk
        # add datasets...
    end

    nothing
end

test()
end

module GmshImport_test_5
using Test
using GmshImport
using WriteVTK

function test()
    nodeblocks, elementblocks = gmsh_import("t1-rect.msh", ["LIN 2", ])
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

    @test length(elementblocks) == 3

    for b in elementblocks
        @test b.elementtype == 1
    end

    nothing
end

test()
end



module GmshImport_test_6
using Test
using GmshImport
using WriteVTK

function test()
    nodeblocks, elementblocks = gmsh_import("t5-tet-corner-coarse.msh", ["TET 4", ])
    @test length(nodeblocks) == 167
    @test length(elementblocks) == 6

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

    for b in elementblocks
        cells = [MeshCell(VTKCellTypes.VTK_TETRA, b.econn[k, :]) for k in eachindex(b.etags)]

        vtk_grid("$(@__MODULE__())-tetrahedra-$(b.block).vtu", x, y, z, cells) do vtk
        # add datasets...
        end
    end

    nothing
end

test()
end

module GmshImport_test_7
using Test
using GmshImport
using WriteVTK

function test()
    nodeblocks, elementblocks = gmsh_import("t1-rect.msh", ["TET 4", "LIN 2", "TRI 3", ])
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
