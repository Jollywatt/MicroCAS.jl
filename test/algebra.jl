

@testset "Term" begin

	x, y, z = Term.([:x, :y, :z] .=> 1)

	@test x*y == y*x
	@test x*x == x^2
	@test inv(x) == x/x^2

end

@testset "Sum" begin

	x, y, z = Sum.(Term.([:x, :y, :z] .=> 1) .=> 1.0)

	@test x + y == y + x
	@test x + x == 2x
	@test -x == x - 2x

	@test x*y == y*x
	@test (x + y)*z == x*z + y*z

end

@testset "hashing and equality" begin
	x, y, z = Sum.(Term.([:x, :y, :z] .=> 1) .=> 1.0)

	exprs = [
		Node(:a => 1, :b => 2) => Node(:b => 2, :a => 1)
		Term(:x => 1, :y => 2) => Term(:y => 2, :x => 1)
	]

	for (a, b) in exprs, _ in 1:10
		@test a == b
		@test isequal(a, b)
		@test hash(a) == hash(b)
	end
end