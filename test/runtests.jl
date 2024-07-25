#= Run this script interactively: `julia -i runtests.jl`
... or with arguments `julia runtests.jl [testfiles...]` =#

cd(joinpath(".", dirname(@__FILE__)))

using Test, Revise, MicroCAS

alltests() = setdiff(filter(endswith(".jl"), readdir()), [basename(@__FILE__)])

test(files::String...) = test(files)
function test(files=alltests())
	isempty(files) && @info "No tests"
	@testset "$file" for file in files
		include(file)
	end
	nothing
end


if isempty(ARGS)
	@info """Run this script interactively with `julia -i runtests.jl`.
		 - Use `test()` to run some or all tests
		Keep the session alive; changes will be revised and successive runs will be faster.
		"""
	if !isinteractive()
		test()
	end
else
	test(ARGS...)
end
