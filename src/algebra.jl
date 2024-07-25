import Base: ==, +, -, *, /, \, ^, inv, hash

"""
	Node{K,V}

Represents a set of `K` objects with associated nonzero values `V`.
Used to define the [`Prod`](@ref) and [`Sum`](@ref) types.
"""
struct Node{K,V}
	data::Dict{K,V}
	Node{K,V}(d::Dict) where {K,V} = new{K,V}(filter(!iszero∘last, d))
	Node{K,V}() where {K,V} = new{K,V}(Dict{K,V}())
end
Node(d::Dict{K,V}) where {K,V} = Node{K,V}(d)
(::Type{T})(a::Union{Base.Generator,Pair}...) where {T<:Node} = T(Dict(a...))

(x::Node == y::Node) = x.data == y.data
hash(x::Node, h::UInt) = hash(x.data, h)

Base.getindex(x::Node{K,V}, k) where {K,V} = get(x.data, k, zero(V))
Base.setindex!(x::Node, v, k) = iszero(v) ? delete!(x.data, k) : setindex!(x.data, v, k)

Base.length(x::Node) = length(x.data)
Base.iterate(x::Node, args...) = iterate(x.data, args...)

"""
	Prod <: Node

Represents a symbolic product of factors with integer exponents.
"""
const Prod = Node{Union{Symbol,<:Node},Int}

"""
	Sum{T} <: Node

Represents a symbolic sum of terms.
Each term is a `Prod` with a coefficient of type `T`.
"""
const Sum{T} = Node{Prod,T}
Sum(d::Dict{K,V}) where {K,V} = Sum{V}(d)

Base.isone(x::Prod) = isempty(x.data)
Base.iszero(x::Sum) = isempty(x.data)
Base.one(::Union{Prod,Type{Prod}}) = Prod()
Base.zero(::Union{Sum{T},Type{Sum{T}}}) where T = Sum{T}()
Base.one(::Union{Sum{T},Type{Sum{T}}}) where T = Sum{T}(Prod() => one(T))

var(a) = Sum(Prod(Symbol(a) => 1) => 1)
function vars(n::Integer, sym::Symbol=:x)
	[var("$sym$i") for i in 1:n]
end


#= Multiplication of products =#

(x::Prod * y::Prod) = Prod(mergewith(+, x.data, y.data))
inv(x::Prod) = Prod(k => -v for (k, v) in x)
(x::Prod / y::Prod) = x*inv(y)
(x::Prod \ y::Prod) = y*inv(x)
(x::Prod ^ p::Integer) = Prod(k => p*v for (k, v) in x)

#= Addition and multiplication of sums =#

(x::Sum + y::Sum) = Sum(mergewith(+, x.data, y.data))
-(x::Sum) = Sum(k => -v for (k, v) in x)
(x::Sum - y::Sum) = x + (-y)
(x::Sum * a::Number) = Sum(k => a*v for (k, v) in x)
(a::Number * x::Sum) = Sum(k => a*v for (k, v) in x)
(x::Sum / a::Number) = Sum(k => a/v for (k, v) in x)
(a::Number \ x::Sum) = Sum(k => a\v for (k, v) in x)

for op in [:+, :-]
	@eval $op(x::Sum, a::Number) = $op(x, Sum(Prod() => a))
	@eval $op(a::Number, x::Sum) = $op(x, Sum(Prod() => a))
end


function distribute(x::Sum{T}, y::Sum{S}) where {T,S}
	xy = Sum{promote_type(T, S)}()
	for (term1, coeff1) in x.data, (term2, coeff2) in y.data
		xy[term1*term2] += coeff1*coeff2
	end
	xy
end

(x::Sum * y::Sum) = distribute(x, y)

function (x::Sum{T} ^ p::Integer) where T
	if p < 0
		inv(x)^abs(p)
	elseif length(x) == 1
		Sum(k^p => v^p for (k, v) in x)
	else
		Sum{T}(Prod((x) => p) => one(T))
	end
end

function inv(x::Sum{T}) where T
	if length(x) == 1
		Sum(inv(k) => inv(v) for (k, v) in x)
	else
		Sum{T}(Prod((x) => -1) => one(T))
	end
end

(x::Sum / y::Sum) = x*inv(y)
(x::Sum \ y::Sum) = y*inv(x)
(a::Number / x::Sum) = a*inv(x)
(x::Sum \ a::Number) = a*inv(x)


"""
	factor(x::Sum)

Naively collect factors that are common to all terms in `x`.
For example, `x*y + x*z` becomes `x*(y + z)`, but `x^2 + 2x + 1` is left as is.
"""
function factor(x::Sum{T}) where T
	length(x) == 1 && return x
	isempty(x) && return x
	common = nothing
	for (term, coeff) in x
		if isnothing(common)
			common = term
		else
			common = Prod(k => min(v, term[k]) for (k, v) in common)
		end
	end
	isone(common) && return x
	prod = common*Prod(Sum(k/common => v for (k, v) in x) => 1)
	Sum(prod => one(T))
end


Base.show(io::IO, ::MIME"text/plain", x::Node) = print(io, summary(x), ":\n ", toexpr(x))
Base.show(io::IO, x::Node) = print(io, toexpr(x))
