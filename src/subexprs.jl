struct SubexprPointer
	x::UInt
end

struct SubexprList{T} <: AbstractDict{SubexprPointer,T}
	defs::OrderedDict{SubexprPointer,T}
	SubexprList(defs::OrderedDict) = new{valtype(defs)}(defs)
end
SubexprList() = SubexprList(OrderedDict{SubexprPointer,Any}())
SubexprList(g::Base.Generator) = SubexprList(OrderedDict(g))

Base.iterate(a::SubexprList, args...) = iterate(a.defs, args...)
Base.length(a::SubexprList) = length(a.defs)
Base.last(a::SubexprList) = last(a.defs)
Base.setindex!(a::SubexprList, args...) = setindex!(a.defs, args...)
Base.get(a::SubexprList, k, default) = get(a.defs, k, default)


function letter(i::Integer)
	alphabet = collect("αβγδεζηθκλμνξπρςστυφχψωΓΔΘΛΞΠΣΦΨΩ")
	n = length(alphabet) 
	base = alphabet[mod1(i, n)]
	Symbol(base^cld(i, n))
end

function Base.show(io::IO, ::MIME"text/plain", s::SubexprList)
	names = Dict(k => letter(i) for (i, k) in enumerate(keys(s.defs)))
	io = IOContext(io, :pointernames => names)
	@invoke show(io, MIME("text/plain"), s::AbstractDict)
end

function Base.show(io::IO, s::SubexprPointer)
	if :pointernames in keys(io)
		printstyled(io, io[:pointernames][s], bold=true)
	else
		@invoke show(io, s::Any)
	end
end

subexprs!(l::SubexprList, a::Any) = a
function subexprs!(l::SubexprList, expr::Expr)
	ref = SubexprPointer(hash(expr))
	ref in keys(l) && return ref

	args = map(expr.args) do arg
		subexprs!(l, arg)
	end

	new = Expr(expr.head, args...)
	push!(l, ref => new)
	ref
end

function subexprs(expr::Expr)
	l = SubexprList()
	subexprs!(l, expr)
	l
end

countrefs!(counts, ::Any) = nothing
function countrefs!(counts, ref::SubexprPointer)
	counts[ref] = get(counts, ref, 0) + 1
end
function countrefs!(counts, expr::Expr)
	for arg in expr.args
		countrefs!(counts, arg)
	end
end
function countrefs!(counts, l::SubexprList)
	for (ref, v) in l
		countrefs!(counts, v)
	end
end

function countrefs(a)
	counts = Dict{SubexprPointer,Int}()
	countrefs!(counts, a)
	counts
end


substitute(a, ::Any) = a
substitute(ref::SubexprPointer, subs::Dict{SubexprPointer}) = get(subs, ref, ref)
function substitute(expr::Expr, subs)
	args = map(expr.args) do arg
		substitute(arg, subs)
	end
	Expr(expr.head, args...)
end

function squash(l::SubexprList)
	counts = countrefs(l)
	tosquash = keys(filter(isone∘last, counts))
	subs = filter(in(tosquash)∘first, l)
	out = SubexprList()
	for (ref, v) in l
		new = substitute(v, subs)
		if ref ∈ keys(subs)
			subs[ref] = new
		end
		if ref ∉ tosquash
			out[ref] = new
		end
	end
	out
end

