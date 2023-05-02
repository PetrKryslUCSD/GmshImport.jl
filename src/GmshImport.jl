module GmshImport

export gmsh_import

const _elementtypes = Dict(
1 => ("LIN 2", 2),
2 => ("TRI 3", 3),
3 => ("QUA 4", 4),
4 => ("TET 4", 4),
5 => ("HEX 8", 8),
6 => ("PRI 6", 6),
7 => ("PYR 5", 5),
8 => ("LIN 3", 3),
9 => ("TRI 6", 6),
10 => ("QUA 9", 9),
11 => ("TET 10", 10),
12 => ("HEX 27", 27),
13 => ("PRI 18", 18),
14 => ("PYR 14", 14),
15 => ("PNT", 1),
16 => ("QUA 8", 8),
17 => ("HEX 20", 20),
)

mutable struct LineReader
    _lines
    _current
end

function (b::LineReader)()
    b._current = b._current + 1
    b._current > length(b._lines) && error("Ran out of lines: reading beyond the end of the file?")
    b._lines[b._current]
end

function gmsh_import(filename)
    reader = LineReader(readlines(filename), 0)
    # Read the mesh format
    version = 0
    filetype = -1
    level = 0
    while true
        temp = reader()
        if (level == 0)
            if (length(temp) >= 11) && (uppercase(temp[1:11]) == "\$MESHFORMAT")
                level = 1
            end
        elseif (level == 1)
            A = split(replace(temp, "," => " "))
            version = parse(Float64, A[1])
            filetype = parse(Int, A[2])
            level = 2
        elseif (level == 2)
            if (length(temp) >= 14) && (uppercase(temp[1:14]) == "\$ENDMESHFORMAT")
                break
            end
        end
    end
    (version < 4) && error("Version $version cannot be handled")
    (filetype != 0) && error("File is not ASCII")

    # Read the nodes
    # $Nodes
    # 1 6 1 6     1 entity bloc, 6 nodes total, min/max node tags: 1 and 6
    # 2 1 0 6     2D entity (surface) 1, no parametric coordinates, 6 nodes
    # 1             node tag #1
    # 2             node tag #2
    # 3             etc.
    # 4
    # 5
    # 6
    # 0. 0. 0.      node #1 coordinates (0., 0., 0.)
    # 1. 0. 0.      node #2 coordinates (1., 0., 0.)
    # 1. 1. 0.      etc.
    # 0. 1. 0.
    # 2. 0. 0.
    # 2. 1. 0.
    # $EndNodes
    nodeblocks = []
    totalnnodes = 0
    level = 0
    while true
        temp = reader()
        if (level == 0)
            if (length(temp) >= 6) && (uppercase(temp[1:6]) == "\$NODES")
                temp = reader()
                A = split(replace(temp, "," => " "))
                nblocks = parse(Int, A[1])
                totalnnodes = parse(Int, A[2])
                for block in 1:nblocks
                    temp = reader()
                    A = split(replace(temp, "," => " "))
                    entdim = parse(Int, A[1])
                    enttag = parse(Int, A[2])
                    parcoor = parse(Int, A[3])
                    nnodes = parse(Int, A[4])
                    ntags = fill(0, nnodes)
                    for i in 1:nnodes
                        temp = reader()
                        ntags[i] = parse(Int, temp)
                    end
                    ncoor = fill(0.0, nnodes, 3)
                    for i in 1:nnodes
                        temp = reader()
                        A = split(replace(temp, "," => " "))
                        ncoor[i, :] = [parse(Float64, A[k]) for k in eachindex(A[1:3])]
                    end
                    push!(nodeblocks, (block = block, entdim = entdim, enttag = enttag, parcoor = parcoor, nnodes = nnodes, ntags = ntags, ncoor = ncoor))
                end
                level = 1
            end
        elseif (level == 1)
            if (length(temp) >= 9) && (uppercase(temp[1:9]) == "\$ENDNODES")
                break
            else
                error("Unexpected content, line $(reader._current)")
            end
        end
    end

    # Read elements
    # $Elements
    # 1 2 1 2     1 entity bloc, 2 elements total, min/max element tags: 1 and 2
    # 2 1 3 2     2D entity (surface) 1, element type 3 (4-node quad), 2 elements
    # 1 1 2 3 4     quad tag #1, nodes 1 2 3 4
    # 2 2 5 6 3     quad tag #2, nodes 2 5 6 3
    # $EndElements
    elementblocks = []
    totalnelements = 0
    level = 0
    while true
        temp = reader()
        if (level == 0)
            if (length(temp) >= 9) && (uppercase(temp[1:9]) == "\$ELEMENTS")
                temp = reader()
                A = split(replace(temp, "," => " "))
                nblocks = parse(Int, A[1])
                totalnelements = parse(Int, A[2])
                for block in 1:nblocks
                    temp = reader()
                    A = split(replace(temp, "," => " "))
                    entdim = parse(Int, A[1])
                    enttag = parse(Int, A[2])
                    elementtype = parse(Int, A[3])
                    nelements = parse(Int, A[4])
                    edata = _elementtypes[elementtype]
                    etags = fill(0, nelements)
                    econn = fill(0, nelements, edata[2])
                    for i in 1:nelements
                        temp = reader()
                        A = split(replace(temp, "," => " "))
                        etags[i] = parse(Int, A[1])
                        econn[i, :] .= [parse(Int, A[k+1]) for k in eachindex(A[2:size(econn, 2)+1])]
                    end
                    push!(elementblocks, (block = block, entdim = entdim, enttag = enttag, elementtype = elementtype, edata = edata, nelements = nelements, etags = etags, econn = econn))
                end
                level = 1
            end
        elseif (level == 1)
            if (length(temp) >= 12) && (uppercase(temp[1:12]) == "\$ENDELEMENTS")
                break
            else
                error("Unexpected content, line $(reader._current)")
            end
        end
    end

    return nodeblocks, elementblocks
end


end # module GmshImport
