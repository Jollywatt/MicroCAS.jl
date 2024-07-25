import Base: ==, +, -, *, /, \, ^, inv, hash

struct Node{K,V}
	data::Dict{K,V}
	Node{K,V}(d::Dict) where {K,V} = new{K,V}(filter(!iszero∘last, d))
end
Node{K,V}() where {K,V} = Node{K,V}(Dict{K,V}())
Node(d::Dict{K,V}) where {K,V} = Node{K,V}(d)
(::Type{T})(a::Union{Base.Generator,Pair}...) where {T<:Node} = T(Dict(a...))

(x::Node == y::Node) = x.data == y.data
hash(x::Node, h::UInt) = hash(x.data, h)

Base.getindex(x::Node{K,V}, k) where {K,V} = get(x.data, k, zero(V))
Base.setindex!(x::Node, v, k) = iszero(v) ? delete!(x.data, k) : setindex!(x.data, v, k)

Base.length(x::Node) = length(x.data)
Base.iterate(x::Node, args...) = iterate(x.data, args...)

const Prod = Node{Union{Symbol,Expr,<:Node},Int}
const Sum{T} = Node{Prod,T}

Base.isone(x::Prod) = isempty(x.data)
Base.iszero(x::Sum) = isempty(x.data)

function vars(n::Integer, sym::Symbol=:x)
	[Sum(Prod(Symbol("$sym$i") => 1) => 1.0) for i in 1:n]
end

Sum(d::Dict{K,V}) where {K,V} = Sum{V}(d)
Sum{T}(e::Expr) where T = Sum(Prod(e => 1) => one(T))

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


Base.show(io::IO, ::MIME"text/plain", x::Node) = print(io, summary(x), ":\n ", toexpr(x))
Base.show(io::IO, x::Node) = print(io, toexpr(x))
