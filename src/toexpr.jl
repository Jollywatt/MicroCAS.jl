# define a total ordering for sorting
(x::T <ₜ y::T) where T = x < y
(x::T <ₜ y::S) where {T,S} = nameof(T) < nameof(S)
(x::Node <ₜ y::Node) = all(splat(<ₜ), zip(keys(x.data), keys(y.data)))
sortbykeys(a) = sort(collect(a), by=first, lt=(<ₜ))

toexpr(x::Union{Symbol,Expr}) = x

toexpr(x::T) where T<:Node = :($T($((:($(toexpr(k)) => $v) for (k, v) in x)...)))

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

function toexpr(l::SubexprList)
	names = Dict(k => letter(i) for (i, k) in enumerate(keys(l.defs)))
	c = collect(l)
	defs = [names[k] => substitute(v, names) for (k, v) in l]
	Expr(:let, [:($k = $v) for (k, v) in defs[1:end-1]], last(defs[end]))
end