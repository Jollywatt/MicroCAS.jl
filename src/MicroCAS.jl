module MicroCAS

using OrderedCollections: OrderedDict

export vars
export Node
export Node, Prod, Sum
export subexprs

include("algebra.jl")
include("subexprs.jl")
include("toexpr.jl")

end # module MicroCAS
