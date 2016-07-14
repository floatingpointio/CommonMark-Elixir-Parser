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

	defp lineEndCheck(cInfo) do

		cond do 
			cInfo[CurrentBlock][Block] == "paragraph" and (String.slice(cInfo[CurrentLine],-2,2) == "  " or String.slice(cInfo[CurrentLine], -1, 1) == "\\") ->
				put_in(cInfo, [CurrentBlock, Content], cInfo[CurrentBlock][Content] ++ [%{Type => "break"}])
			true ->
				cInfo
		end 
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
			previousChar = if Enum.at(currentLine,-1) do Enum.at(currentLine,-1) else "" end 
			prePreviousChar = Enum.at(currentLine,-2) do Enum.at(currentLine,-2) else "" end
				
			cond do	

				blockCharset?(previousChar) and !escaped?(Enum.at(previousChar)) ->
					cInfo = cInfo |> addBlock(previousChar) |> addChars(char)
				regularCharset?(previousChar) or previousChar == ""->
					cInfo = cInfo |> addChars(char)
			    space?(previousChar) and cInfo[CurrentBlock] ->
			    	cInfo
			end
			
		else
			cInfo = addChars(cInfo, char)
		end
		
		parseLineChars(rest, Map.put(cInfo, CurrentLine, cInfo[CurrentLine] <> char))
	end



	defp parseLineChars([], cInfo) do

		cInfo = lineEndCheck(cInfo)

		Map.put(cInfo, CurrentLine, "") 
		|> Map.put(LastLine, cInfo[CurrentLine])
	end

	defp firstChar?(lineContent) do
		empty?(lineContent)
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
			
			if String.length(cInfo[CurrentLine]) == 0 do
				
				cInfo = put_in(cInfo, [CurrentBlock, Content], cInfo[CurrentBlock][Content] ++ [%{Text => "", Type => "normal"}])
			end

			put_in(cInfo, [CurrentBlock, Content], List.replace_at(cInfo[CurrentBlock][Content], -1, Map.put(Enum.at(cInfo[CurrentBlock][Content],-1), Text, Enum.at(cInfo[CurrentBlock][Content],-1)[Text] <> char)))
			
		else
		   addBlock(cInfo, "paragraph", char, "normal")
		end
		
	end


	# add current block

	
	defp addBlock(cInfo, blockChar) do
		cInfo
	end	

	defp addBlock(cInfo, block, value, type) do
		Map.put(cInfo, CurrentBlock, %{Block => block, Content => [%{Text => value, Type => type}]})
	end

	defp trimBlockContent(block) do

		Map.put(block, Content, trimContent(block[Content],[]))

	end

	defp trimContent([content|rest], newContent) do

		if Map.has_key?(content, Text) do
			content = Map.put(content, Text, content[Text] |> String.trim |>  String.trim_trailing("\\"))
		end
		
		trimContent(rest, newContent ++ [content])
	end

	defp trimContent([],newContent) do
		newContent
	end


	# Other

	defp escaped?(char) do
		char == "\\"
	end

	defp space?(char) do
		char == " " or char == "\t"
	end

	defp regularCharset?(char) do 
		Regex.match?(~r/[A-Za-z0-9\\]{1}/, char)
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


