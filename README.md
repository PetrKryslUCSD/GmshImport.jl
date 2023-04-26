# GmshImport.jl

Import the finite element nodes and elements from a 4.x Gmsh file.

The node blocks and the element blocks are imported and returned.
```
nodeblocks, elementblocks = gmsh_import("t1-rect.msh")
```
To be dispatched as seen fit.

Node blocks is an array of named tuples, each with the data:
- `block` = block id, 
- `entdim` = entity dimension, 
- `enttag` = entity tag, 
- `parcoor` = parametric coordinates supplied?,
- `nnodes` = number of nodes located on this entity, 
- `ntags` = array of node tags, 
- `ncoor` = array of node coordinates, one node per row.

Element blocks is an array of named tuples, each with the data:
- `block` = block id, 
- `entdim` = entity dimension, 
- `enttag` = entity tag, 
- `elementtype` = element type, 
- `edata` = element data (name and number of nodes per element), 
- `nelements` = number of elements located on this entity, 
- `etags` = array of element tags, 
- `econn` = array of element connectivities, one element per row.
