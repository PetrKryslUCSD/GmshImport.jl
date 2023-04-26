module test_1

using MeshCore: IncRel, ShapeColl, T3, P1, ir_skeleton, ir_transpose, ir_bbyfacets
using GmshImport
using WriteVTK

function test()
    nodeblocks, elementblocks = gmsh_import("t1.msh")

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

    b = elementblocks[4]
    triangles = ShapeColl(T3, b.nelements)
    vertices = ShapeColl(P1, maxnnumber)
    # Incidence relation (2, 0): the connectivity, triangles to vertices
    t2v = IncRel(triangles, vertices, b.econn)
    # The skeleton: edges to vertices
    e2v = ir_skeleton(t2v)
    # Vertices to edges
    v2e = ir_transpose(e2v)
    # Triangles to edges
    t2e = ir_bbyfacets(t2v, e2v, v2e)
    # Edges to triangles
    e2t = ir_transpose(t2e)
    @show e2t # This lists for each edge the two triangles that are adjacent

    nothing
end

test()
end
