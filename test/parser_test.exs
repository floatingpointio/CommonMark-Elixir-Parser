defmodule ParserTest do
  use ExUnit.Case
  doctest Parser

  test "paragraf1" do
		input = ~s(Ovo je paragraf broj 1 \n\n   Ovo je paragraf broj 2\n\n       a ovo je i zadnji paragraf)

		expected = [
			%{
				"paragraph" => "Ovo je paragraf broj 1"
			},
			%{
				"paragraph" => "Ovo je paragraf broj 2"
			},
			%{
				"paragraph" => "a ovo je i zadnji paragraf"
			}
		]
		result = Parser.parse(input)
		assert(result == expected)
	end

	test "paragraf2" do
		input = ~s(Ovo je paragraf broj 1\n\n \n \nOvo je paragraf broj 2\n   \na ovo je i zadnji paragraf)

		expected = [
			%{
				"paragraph" => "Ovo je paragraf broj 1"
			},
			%{
				"paragraph" => "Ovo je paragraf broj 2"
			},
			%{
				"paragraph" => "a ovo je i zadnji paragraf"
			}
		]
		result = Parser.parse(input)
		assert(result == expected)
	end

	test "paragraf3" do
		input = ~s(Ovo je paragraf broj 1\nOvo je paragraf broj 2\na ovo je i zadnji paragraf)

		expected = [
			%{
				"paragraph" => "Ovo je paragraf broj 1Ovo je paragraf broj 2a ovo je i zadnji paragraf"
			}

		]
		result = Parser.parse(input)
		assert(result == expected)
	end
 
 
end
