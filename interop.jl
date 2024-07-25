using GeometricAlgebra
import Base: /
import MicroCAS: toexpr, squash

smv(sig, k, sym=:x) = Multivector{sig,k}(@. Sum(Prod(Symbol(string(sym, join(GeometricAlgebra.bits_to_indices($collect(GeometricAlgebra.componentbits(Multivector{sig,k})))))) => 1) => 1.0))

(a::Multivector / x::Node) = GeometricAlgebra.constructor(a)(a.comps ./ Ref(x))

toexpr(a::Multivector{Sig,K}) where {Sig,K} = :(Multivector{$Sig,$K}($(toexpr(a.comps))))

squash(a::Multivector) = a |> toexpr |> subexprs |> squash |> toexpr
