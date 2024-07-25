# define a total ordering for sorting
(x::T <ₜ y::T) where T = x < y
(x::T <ₜ y::S) where {T,S} = nameof(T) < nameof(S)
(x::Node <ₜ y::Node) = all(splat(<ₜ), zip(keys(x.data), keys(y.data)))
sortbykeys(a) = sort(collect(a), by=first, lt=(<ₜ))

toexpr(x::Union{Symbol,Expr}) = x

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