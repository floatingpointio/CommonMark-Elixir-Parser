defmodule ParserTest do
  use ExUnit.Case
  doctest Parser

  test "paragrafGeneral" do
		input = ~s(Ovo je    paragraf broj 1 \n    \n   Ovo je  paragraf broj 2\n\n\n   a ovo je i zadnji paragraf\nskupa s ovim\n\n)

		expected = [
			%{
				Block => "paragraph",Content => [%{Text => "Ovo je paragraf broj 1", Type => "normal"}]
			},
			%{
				Block => "paragraph",Content => [%{Text => "Ovo je paragraf broj 2", Type => "normal"}]
			},
			%{
				Block => "paragraph",Content => [%{Text => "a ovo je i zadnji paragraf", Type => "normal"},
				                                 %{Text => "skupa s ovim", Type => "normal"}]
			}
			
		]
		result = Parser.parse(input)
		assert(result == expected)
	end

	test "paragrafBreaks" do
		input = ~s(Ovo je paragraf\\\nkoji se nastavlja sa breakom  \nkoji se isto nastavlja sa breakom)

		expected = [
			%{
				Block => "paragraph",Content => [%{Text => "Ovo je paragraf", Type => "normal"},
												 %{Block => "break"},
												 %{Text => "koji se nastavlja sa breakom", Type => "normal"},
												 %{Block => "break"},
												 %{Text => "koji se isto nastavlja sa breakom", Type => "normal"},
												]
			}
			
		]
		result = Parser.parse(input)
		assert(result == expected)
	end

	

 	test "headingTest1" do
		input = ~s(#         Ovo je prvi heading        \n\n ## h2 #\n### h3\n#### h4\n##### h5\n###### h6  )

		expected = [
			%{
				Block => "heading" ,Content => [%{Text => "Ovo je prvi heading", Type => "normal"}], Level => 1
			},
			%{
				Block => "heading" ,Content => [%{Text => "h2", Type => "normal"}], Level => 2
			},
			%{
				Block => "heading" ,Content => [%{Text => "h3", Type => "normal"}], Level => 3
			},
			%{
				Block => "heading" ,Content => [%{Text => "h4", Type => "normal"}], Level => 4
			},
			%{
				Block => "heading" ,Content => [%{Text => "h5", Type => "normal"}], Level => 5
			},
			%{
				Block => "heading" ,Content => [%{Text => "h6", Type => "normal"}], Level => 6
			}	

		]
		result = Parser.parse(input)
		assert(result == expected)
	end

	test "headingTest2" do
		input = ~s(# Ovo je prvi heading #### \n\n##Ovo je paragraf  \n\n## #h3\n####### Ovo je isto paragraf)

		expected = [
			%{
				Block => "heading" ,Content => [%{Text => "Ovo je prvi heading", Type => "normal"}], Level => 1
			},
			%{
				Block => "paragraph" ,Content => [%{Text => "##Ovo je paragraf", Type => "normal"},
												  %{Block => "break"}
												 ]
			},
			%{
				Block => "heading" ,Content => [%{Text => "#h3", Type => "normal"}], Level => 2
			},
			%{
				Block => "paragraph" ,Content => [%{Text => "####### Ovo je isto paragraf", Type => "normal"}]
			}
		]
		result = Parser.parse(input)
		assert(result == expected)
	end

	test "headingTest3" do
		input = ~s(Ovo je prvi heading\n====       \n\n   - - - - - -\n****  ** **** ** * **     \nDrugi heading\n  ----------\n\n___________)

		expected = [
			%{
				Block => "heading" ,Content => [%{Text => "Ovo je prvi heading", Type => "normal"}], Level => 1
			},
			%{
				Block => "horizontal line"
												 
			},
			%{
				Block => "horizontal line"
												 
			},
			%{
				Block => "heading" ,Content => [%{Text => "Drugi heading", Type => "normal"}], Level => 2
												 
			},
			%{
				Block => "horizontal line"
												 
			}
		]
		result = Parser.parse(input)
		assert(result == expected)
	end

	test "codeBlockTest1" do
		input = ~s(```testna\nblablabla\nblbalbalb\n\njos malo blablbalba\n----------\n\n___________\n# Nije heading\n`````)

		expected = [
			%{
				Block => "code block" ,Content => [%{Text => "blablabla", Type => "normal"},
												   %{Text => "blbalbalb", Type => "normal"},
												   %{Text => "jos malo blablbalba", Type => "normal"},
												   %{Text => "----------", Type => "normal"},
												   %{Text => "___________", Type => "normal"},
												   %{Text => "# Nije heading", Type => "normal"},
												  ], Class => "language-testna"
			}
		]
		result = Parser.parse(input)
		assert(result == expected)
	end

	test "codeBlockTest2" do
		input = ~s(    janjetinajanjetina\n    prastetinaprasetina\nsrnetinasrnetina\n      zec)

		expected = [
			%{
				Block => "code block" ,Content => [%{Text => "janjetinajanjetina", Type => "normal"},
												   %{Text => "prastetinaprasetina", Type => "normal"}
												  ]
			},
			%{
				Block => "paragraph",Content => [%{Text => "srnetinasrnetina", Type => "normal"}]
			},
			%{
				Block => "code block" ,Content => [%{Text => "  zec", Type => "normal"}]
			}
		]
		result = Parser.parse(input)
		assert(result == expected)
	end
 
end
