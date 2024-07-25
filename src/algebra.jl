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
Base.setindex!(x::Node, args...) = setindex!(x.data, args...)

const Term = Node{Union{Symbol,Expr},Int}
const Sum{T} = Node{Term,T}

Base.isone(x::Term) = isempty(x.data)
Base.iszero(x::Sum) = isempty(x.data)

function vars(n::Integer, sym::Symbol=:x)
	[Sum(Term(Symbol("$sym$i") => 1) => 1.0) for i in 1:n]
end

Sum(d::Dict{K,V}) where {K,V} = Sum{V}(d)



#= Multiplication of terms =#

(x::Term * y::Term) = Term(mergewith(+, x.data, y.data))
inv(x::Term) = Term(k => -v for (k, v) in x.data)
(x::Term / y::Term) = x*inv(y)
(x::Term \ y::Term) = y*inv(x)
(x::Term ^ p::Integer) = Term(k => p*v for (k, v) in x.data)

#= Addition and multiplication of sums =#

(x::Sum + y::Sum) = Sum(mergewith(+, x.data, y.data))
-(x::Sum) = Sum(k => -v for (k, v) in x.data)
(x::Sum - y::Sum) = x + (-y)
(x::Sum * a::Number) = Sum(k => a*v for (k, v) in x.data)
(a::Number * x::Sum) = Sum(k => a*v for (k, v) in x.data)
(x::Sum / a::Number) = Sum(k => a/v for (k, v) in x.data)
(a::Number \ x::Sum) = Sum(k => a\v for (k, v) in x.data)
for op in [:+, :-]
	@eval $op(x::Sum, a::Number) = $op(x, Sum(Term() => a))
	@eval $op(a::Number, x::Sum) = $op(x, Sum(Term() => a))
end


function distribute(x::Sum{T}, y::Sum{S}) where {T,S}
	xy = Sum{promote_type(T, S)}()
	for (term1, coeff1) in x.data, (term2, coeff2) in y.data
		xy[term1*term2] += coeff1*coeff2
	end
	xy
end

(x::Sum * y::Sum) = distribute(x, y)

Base.show(io::IO, ::MIME"text/plain", x::Node) = print(io, summary(x), ":\n ", toexpr(x))
Base.show(io::IO, x::Node) = print(io, toexpr(x))

toexpr(x::Union{Symbol,Expr}) = x

function toexpr(x::Term)
	factors = map(collect(x.data)) do (k, v)
		k = toexpr(k)
		isone(v) ? k : :($k^$v)
	end
	if length(factors) == 0
		1
	elseif length(factors) == 1
		first(factors)
	else
		Expr(:call, :*, factors...)
	end
end

function toexpr(x::Sum{T}) where {T}
	factors = map(collect(x.data)) do (k, v)
		isone(k) && return v
		k = toexpr(k)
		isone(v) ? k : :($v*$k)
	end
	if length(factors) == 0
		zero(T)
	elseif length(factors) == 1
		first(factors)
	else
		Expr(:call, :+, factors...)
	end
end