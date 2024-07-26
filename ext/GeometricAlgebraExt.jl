module GeometricAlgebraExt

using MicroCAS, GeometricAlgebra

import Base: /
import MicroCAS: toexpr, squash, factor

function Multivector{Sig,K}(s::Symbol) where {Sig,K}
	bits = GeometricAlgebra.componentbits(Multivector{Sig,K})
	suffixes = [join(GeometricAlgebra.bits_to_indices(b)) for b in bits]
	syms = Symbol.(string.(s, suffixes))
	Multivector{Sig,K}(MicroCAS.var.(syms))
end

(a::Multivector{Sig,K} / x::MicroCAS.Node) where {Sig,K} = Multivector{Sig,K}(a.comps ./ Ref(x))

factor(a::Multivector{Sig,K}) where {Sig,K} = Multivector{Sig,K}(factor.(a.comps))

toexpr(a::Multivector{Sig,K}) where {Sig,K} = :(Multivector{$Sig,$K}($(toexpr(a.comps))))

squash(a::Multivector) = a |> toexpr |> subexprs |> squash |> toexpr



end #module