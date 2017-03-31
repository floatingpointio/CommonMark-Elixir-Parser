# CommonMark Elixir Parser


defmodule Parser do

	alias Lines
	alias Blocks
	alias Inlines
	alias Fun


	def parse(text) do

		cInfo = text 
				|> Fun.textToList 
				|> parseLines(%{
					AST => [],
					Links => [],
					PreviousBlock => nil,
					PossibleBlock => nil,
					CurrentBlock => nil,
					LastLine => "", 
					CurrentLine => "", 
					BlockDepth => 0, 
					BlockIndex => 0
				})

		cInfo[AST]
	end


	def parseLines([line|rest], cInfo) do

		currentBlock = cInfo[CurrentBlock][Block] 

		if !Fun.empty?(line) do

			cInfo = cInfo |> Lines.checkLineForBlocks(line)	

		else

			if currentBlock == "code block" or (currentBlock == "HTML block" and cInfo[CurrentBlock][TagType] != "Regular") do
				cInfo = cInfo |> Fun.addChars(line)
			else
				cInfo = cInfo |> Blocks.finishBlock
			end	
		end

		parseLines(rest, cInfo)
	end


	def parseLines([], cInfo) do
		cInfo |> Blocks.finishBlock
	end




end


