module MicroCAS

using OrderedCollections: OrderedDict

export vars
export Node, Prod, Sum
export factor
export subexprs, squash, toexpr

include("algebra.jl")
include("subexprs.jl")
include("toexpr.jl")

end # module MicroCAS
