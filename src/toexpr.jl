# define a total ordering for sorting
(x::T <ₜ y::T) where T = x < y
(x::T <ₜ y::S) where {T,S} = nameof(T) < nameof(S)
(x::Node <ₜ y::Node) = all(splat(<ₜ), zip(keys(x.data), keys(y.data)))
sortbykeys(a) = sort(collect(a), by=first, lt=(<ₜ))

toexpr(x::Union{Symbol,Expr}) = x

toexpr(x::T) where T<:Node = :($T($((:($(toexpr(k)) => $v) for (k, v) in x)...)))

"""
	toexpr(::Prod)
	toexpr(::Sum)

Render a product or sum `Node` as an expression.

# Example
```julia-repl
julia> toexpr(Sum(Prod(:x => 2) => 7, Prod() => 42))
:(42 + 7 * x ^ 2)
```
"""
toexpr


function toexpr(x::Prod)
	factors = map(sortbykeys(x)) do (k, v)
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
	factors = map(sortbykeys(x)) do (k, v)
		isone(k) && return v
		k = toexpr(k)
		isone(v) && return k
		if k isa Expr && k.head == :call && first(k.args) == :*
			Expr(:call, :*, v, k.args[2:end]...)
		else
			:($v*$k)
		end
	end
	if length(factors) == 0
		zero(T)
	elseif length(factors) == 1
		first(factors)
	else
		Expr(:call, :+, factors...)
	end
end

function toexpr(a::AbstractVector)
	Expr(:vect, toexpr.(a)...)
end


"""
	toexpr(::SubexprList; pretty=false)

Render a subexpression list as a `let ... end` expression.

# Example
```jldoctest
julia> toexpr(subexprs(:(x^2 + f(x^2))), pretty=true)
:(let α = x ^ 2, β = f(α)
      α + β
  end)
```
"""
function toexpr(l::SubexprList; pretty=false)
	names = Dict(k => pretty ? letter(i) : gensym() for (i, k) in enumerate(keys(l.defs)))
	c = collect(l)
	defs = [names[k] => substitute(v, names) for (k, v) in l]
	Expr(:let, [:($k = $v) for (k, v) in defs[1:end-1]], last(defs[end]))
end