module MicroCAS

using OrderedCollections: OrderedDict

export vars
export Node, Prod, Sum
export factor
export subexprs

include("algebra.jl")
include("subexprs.jl")

end # module MicroCAS
