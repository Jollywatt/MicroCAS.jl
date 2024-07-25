macro ident(expr)
	@assert expr isa Expr
	@assert expr.head == :call
	op, a, b = expr.args
	@assert op == :(==)
	quote
		@test $a == $b
		@test isequal($a, $b)
		@test hash($a) == hash($b)
	end |> esc
end

@testset "Term" begin

	x, y, z = Term.([:x, :y, :z] .=> 1)

	@ident x*y == y*x
	@ident x*x == x^2
	@ident inv(x) == x/x^2

end

@testset "Sum" begin

	x, y, z = Sum.(Term.([:x, :y, :z] .=> 1) .=> 1.0)

	@ident x + y == y + x
	@ident x + x == 2x
	@ident -x == x - 2x

	@ident x - x == y - y

	@ident x*y == y*x
	@ident (x + y)*z == x*z + y*z

	@ident (x + y)*(x - y) == x^2 - y^2
	@ident (x + y)^6/(y + x)^8 == inv(x + z + y - z)^2

end