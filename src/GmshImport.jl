module GmshImport

export gmsh_import

# key: name of element type, value: (element type number, number of nodes)a
const elementtypes_definitions = Dict(
    "LIN 2" => (1, 2),
    "TRI 3" => (2, 3),
    "QUA 4" => (3, 4),
    "TET 4" => (4, 4),
    "HEX 8" => (5, 8),
    "PRI 6" => (6, 6),
    "PYR 5" => (7, 5),
    "LIN 3" => (8, 3),
    "TRI 6" => (9, 6),
    "QUA 9" => (10, 9),
    "TET 10" => (11, 10),
    "HEX 27" => (12, 27),
    "PRI 18" => (13, 18),
    "PYR 14" => (14, 14),
    "PNT" => (15, 1),
    "QUA 8" => (16, 8),
    "HEX 20" => (17, 20),
    "PRI 15" => (18, 15),
    "PYR 13" => (19, 13),
    )

mutable struct _LineReader
    _lines
    _current
end

function (b::_LineReader)()
    b._current = b._current + 1
    b._current > length(b._lines) && error("Ran out of lines: reading beyond the end of the file?")
    b._lines[b._current]
end

"""
    gmsh_import(filename,
        process_elementtypes = String[],
        add_elementtypes = Dict()
        )

Import GMSH finite element mesh file.

# Optional arguments

- `process_elementtypes`: array of names of the element type derived from the
  definitions in
  `https://gitlab.onelab.info/gmsh/gmsh/blob/master/src/common/GmshDefines.h`.
  To derive the name of the element type, take as an example `#define MSH_QUA_4
  3`. Strip off `MSH_`, and replace the underscore with a space: "QUA 4". If
  the array `process_elementtypes` is empty (which is the default), the
  assumption is that all element types should be processed. Example: `
  ["LIN 2", ]` requests that only line elements with two nodes should be
  processed.
- `add_elementtypes`: dictionary of additional element type definitions. Refer
  to `https://gmsh.info/doc/texinfo/gmsh.html#MSH-file-format`. The dictionary
  is indexed by the name of the element type (a string), and the value is a
  tuple of the element type integer, and the number of nodes per element.
  Example: Passing `Dict("TRI 15" => (23, 15),)` will add the type of triangles
  with 15 nodes. The current defaults are `GmshImport.elementtypes_definitions`.

# Returns

- `nodeblocks`: Node blocks is an array of named tuples, each with the data:
    + `block` = block id,
    + `entdim` = entity dimension,
    + `enttag` = entity tag,
    + `parcoor` = parametric coordinates supplied?,
    + `nnodes` = number of nodes located on this entity,
    + `ntags` = array of node tags,
    + `ncoor` = array of node coordinates, one node per row.

- `elementblocks`: Element blocks is an array of named tuples, each with the data:
    + `block` = block id,
    + `entdim` = entity dimension,
    + `enttag` = entity tag,
    + `elementname` = name of the element type,
    + `elementtype` = numerical element type (as defined by Gmsh),
    + `nnodes` = number of nodes per element,
    + `nelements` = number of elements located on this entity,
    + `etags` = array of element tags,
    + `econn` = array of element connectivities, one element per row.
"""
function gmsh_import(filename,
    process_elementtypes = String[],
    add_elementtypes = Dict()
    )
    _elementtypes_definitions = merge(elementtypes_definitions, add_elementtypes)
    if isempty(process_elementtypes)
        elementtypes = Dict()
        for (k, v) in _elementtypes_definitions
            elementtypes[v[1]] = (k, v[2])
        end
    else
        elementtypes = Dict()
        for k in process_elementtypes
            haskey(_elementtypes_definitions, k) || error("Name of element type not recognized ($(k))")
            v = _elementtypes_definitions[k]
            elementtypes[v[1]] = (k, v[2])
        end
    end

    reader = _LineReader(readlines(filename), 0)
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
                    edata = ("", 0)
                    knowntype =  haskey(elementtypes, elementtype)
                    if knowntype
                        edata = elementtypes[elementtype]
                        etags = fill(0, nelements)
                        econn = fill(0, nelements, edata[2])
                    end
                    for i in 1:nelements
                        temp = reader()
                        if knowntype
                            A = split(replace(temp, "," => " "))
                            etags[i] = parse(Int, A[1])
                            econn[i, :] .= [parse(Int, A[k+1]) for k in eachindex(A[2:size(econn, 2)+1])]
                        end
                    end
                    if knowntype
                        push!(elementblocks, (block = block, entdim = entdim, enttag = enttag, elementname = edata[1], elementtype = elementtype, nnodes = edata[2], nelements = nelements, etags = etags, econn = econn))
                    end
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
