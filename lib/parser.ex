# CommonMark Elixir Parser and HTML renderer


defmodule Parser do

	def parse(text) do

		cInfo = text 
				|> textToList 
				|> parseLines(%{
					AST => [],
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



	# Line parsing

	defp parseLines([line|rest], cInfo) do

		
		if !empty?(line) do
			cInfo = String.graphemes(line) |> parseLineChars(cInfo)
		else
			cInfo = cInfo |> finishBlock
		end

		parseLines(rest, cInfo)
	end


	defp parseLines([], cInfo) do
		cInfo |> finishBlock
	end




	# Add block content to Syntacitc Tree

	defp finishBlock(cInfo) do
		if cInfo[CurrentBlock] do
			currentBlock = cInfo[CurrentBlock]
			Map.put(cInfo, AST, cInfo[AST] ++ [currentBlock |> trimBlockContent]) 
			|> Map.put(CurrentBlock, nil) 
			|> Map.put(PreviousBlock, currentBlock)
			|> Map.put(BlockDepth,cInfo[BlockDepth] -1)
			|> Map.put(BlockIndex,cInfo[BlockDepth] -1)
		else
			cInfo	
		end
		
	end




	# Char parsing

	defp parseLineChars([char|rest], cInfo) do


	
		if space?(char) and not firstChar?(cInfo[CurrentLine]) do

			currentLine = String.graphemes(cInfo[CurrentLine])
			previousChar = Enum.at(currentLine,-1)
			prePreviousChar = Enum.at(currentLine,-2)
				
			cond do	

				blockCharset?(previousChar) and !escaped?(Enum.at(previousChar)) ->
					cInfo = cInfo |> addBlock(previousChar) |> addChars(char)
				regularCharset?(previousChar) or previousChar == ""->
					cInfo = cInfo |> addChars(char)
			end
			
		else
			cInfo = addChars(cInfo, char)
		end

		parseLineChars(rest, Map.put(cInfo, CurrentLine, cInfo[CurrentLine] <> char))
	end

 
	# Lastchar in Line
	#defp parseLineChars([char|[]], cInfo) do
	#	
	#end


	defp firstChar?(lineContent) do
		empty?(lineContent)
	end

	defp parseLineChars([], cInfo) do
		
		Map.put(cInfo, CurrentLine, "") 
		|> Map.put(LastLine, cInfo[CurrentLine])
	end

	defp nextChar([char|rest]) do
		char
	end

	defp nextChar([]) do
		false
	end






	# add chars to current block

	defp addChars(cInfo, char) do

		if cInfo[CurrentBlock] do
			#depth = cInfo[BlockDepth]
			#index = cInfo[BlockIndex]
			
			currentBlockName = Map.keys(cInfo[CurrentBlock]) |> Enum.at(0)
			cInfo = Map.put(cInfo, CurrentBlock, %{currentBlockName => cInfo[CurrentBlock][currentBlockName] <> char})
		else
		   addBlock(cInfo, "paragraph", char)
		end
		
	end


	# add current block

	
	#defp addBlock(cInfo, blockChar) do
	#	currentBlock = Map.keys(cInfo[CurrentBlock]) |> Enum.at(0)
	#	cInfo
	#end	

	defp addBlock(cInfo, block, value) do
		Map.put(cInfo, CurrentBlock, %{block => value})
	end

	defp trimBlockContent(map) do
		blockName = Map.keys(map) |> Enum.at(0)
		Map.put(map,blockName, map[blockName] |> String.trim)
	end



	# Other

	defp escaped?(char) do
		char == "\\"
	end

	defp space?(char) do
		char == " " or char == "\t"
	end

	defp regularCharset?(char) do 
		Regex.match?(~r/[A-Za-z0-9]{1}/, char)
	end

	defp orderedListCharset?(char) do
		char == "." or char == ")"
	end

	defp blockCharset?(char) do
		char == "#" or char == "`" or char == "+" or char == "-" or char == "*" or char == "=" or char == "." or char == ")"
	end

	defp textToList(string) do
		String.split(string,"\n")
	end

	defp empty?(string) do
        String.trim(string) == ""
    end

end
