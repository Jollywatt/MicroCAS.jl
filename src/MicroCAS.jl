module MicroCAS

using OrderedCollections: OrderedDict

export vars
export Node
export Node, Prod, Sum
export subexprs

include("algebra.jl")
include("subexprs.jl")

end # module MicroCAS
