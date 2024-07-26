# MicroCAS.jl

A very minimal computer algebra system in Julia, useful for generating code.
It does only three things:

1. Simplify basic polynomial expressions.
2. Convert algebraic expressions into Julia `Expr` trees.
3. Perform basic sub-expression elimination to reduce repetition.

These are the minimal features required to perform basic symbolic code optimisation in applications such as geometric algebra.


## Application to geometric algebra

The package was created with [`GeometricAlgebra.jl`](https://github.com/jollywatt/geometricalgebra.jl) in mind, which uses (or originally used) the heavier [`SymbolicUtils.jl`](https://github.com/JuliaSymbolics/SymbolicUtils.jl) package for algebraic code simplification.

A package extension is defined for `GeometricAlgebra` that allows the creation of symbolic multivector expressions.

```julia
julia> using MicroCAS, GeometricAlgebra

julia> a = Multivector{3,1}(:a) # create a 3d vector with symbolic components
3-component Multivector{3, 1, Vector{Sum{Int64}}}:
 a1 v1
 a2 v2
 a3 v3

julia> inv(a) # perform a multivector operation algebraically
3-component Multivector{3, 1, Vector{Sum{Int64}}}:
 (a1 ^ 2 + a2 ^ 2 + a3 ^ 2) ^ -1 * a1 v1
 (a1 ^ 2 + a2 ^ 2 + a3 ^ 2) ^ -1 * a2 v2
 (a1 ^ 2 + a2 ^ 2 + a3 ^ 2) ^ -1 * a3 v3

julia> toexpr(ans)
:(Multivector{3, 1}([(a1 ^ 2 + a2 ^ 2 + a3 ^ 2) ^ -1 * a1, (a1 ^ 2 + a2 ^ 2 + a3 ^ 2) ^ -1 * a2, (a1 ^ 2 + a2 ^ 2 + a3 ^ 2) ^ -1 * a3]))

julia> squash(subexprs(ans)) # common subexpression elimination
MicroCAS.SubexprList with 2 entries:
  α => :((a1 ^ 2 + a2 ^ 2 + a3 ^ 2) ^ -1)
  β => :(Multivector{3, 1}([α * a1, α * a2, α * a3]))

julia> toexpr(ans, pretty=true) # generate simplified code
:(let α = (a1 ^ 2 + a2 ^ 2 + a3 ^ 2) ^ -1
      Multivector{3, 1}([α * a1, α * a2, α * a3])
  end)
```

While inverting a vector is a trivial example, the same works for, e.g., inverting a rotor in 3D or 4D:

```julia
julia> Multivector{3,0:2:3}(:R) |> inv |> factor |> toexpr |> subexprs |> squash |> x->toexpr(x, pretty=true)
:(let α = R ^ 2, β = R12 ^ 2, γ = R13 ^ 2, δ = R23 ^ 2, ε = (2 * α * β + 2 * α * δ + R13 ^ 4 + R23 ^ 4 + 2 * β * δ + 2 * α * γ + R ^ 4 + R12 ^ 4 + 2 * β * γ + 2 * γ * δ) ^ -1, ζ = -1α + -1β + -1γ + -1δ
      Multivector{3, 0:2:2}([(α + β + γ + δ) * ε * R, ζ * ε * R12, ζ * ε * R13, ζ * ε * R23])
  end)
```

## How it works

### Algebra

Algebraic expressions are represented with the `Sum` type, which is simply a dictionary associating terms with coefficients. Terms are of the `Prod` type, which itself is simply a dictionary associating factors with integer exponents. A factor may be a `Symbol` or another `Sum` node.

Associativity and commutativity of `+` and `*` are assumed by the unordered nature of the underlying dictionaries, and terms/factors with a coefficient/exponent of zero are eagerly removed.

```julia
julia> x, y, z = MicroCAS.var.([:x, :y, :z])
3-element Vector{Sum{Int64}}:
 x
 y
 z

julia> (6x*y/x + y)*z - z*y
Sum{Float64}:
 6.0 * y * z
```

Distributivity is eager, as this generally means terms have the opportunity to cancel, but `factor()` may be used to naively collect of common factors.

```julia
julia> x*(y + z) - z*x
Sum{Int64}:
 x * y

julia> factor(x*y + y*z)
Sum{Int64}:
 (x + z) * y
```

Nontrivial inverses are left as is:

```julia
julia> x/(y + z)
Sum{Int64}:
 (y + z) ^ -1 * x

julia> ans*(y + z)
Sum{Int64}:
 (y + z) ^ -1 * x * z + (y + z) ^ -1 * x * y
```

Factoring sometimes allows further simplifications to occur:

```julia
julia> factor(ans)
Sum{Int64}:
 x
```

### Common subexpression elimination

Given a Julia expression, `subexprs()` flattens each node in the expression tree into an ordered dictionary.

```julia
julia> subexprs(:(f(sin(a/2)) + g(sin(a/2)) + cos(a/2)))
MicroCAS.SubexprList with 6 entries:
  α => :(a / 2)
  β => :(sin(α))
  γ => :(f(β))
  δ => :(g(β))
  ε => :(cos(α))
  ζ => :(γ + δ + ε)
```

Notice that subexpressions `γ`, `δ`, and `ε` are referenced only once. These can be substituted into subsequent expressions with `squash()`.

```julia
julia> squash(ans) # keep subexpressions referenced >= 2 times
MicroCAS.SubexprList with 3 entries:
  α => :(a / 2)
  β => :(sin(α))
  γ => :(f(β) + g(β) + cos(α)) # final entry always kept
```

A subexpression list can then be rendered as a `let ... end` expression.

```julia
julia> toexpr(ans, pretty=true)
:(let α = a / 2, β = sin(α)
      f(β) + g(β) + cos(α)
  end)
```


The `toexpr()` method can also be used to convert algebraic expressions into literal `Expr` trees, which can then undergo common subexpression elimination with `squash ∘ subexprs`.