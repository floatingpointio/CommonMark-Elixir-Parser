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

			cond do

				Regex.match?(~r/^=+\s*$/,line) ->
					IO.inspect("Tu sam")
					if cInfo[CurrentBlock][Block] == "paragraph" do
						cInfo = cInfo |> moveBlockContent(cInfo[CurrentBlock][Content], "heading", 1)	
					end
				Regex.match?(~r/^-+\s*$/,line) ->
					if cInfo[CurrentBlock][Block] == "paragraph" do
						cInfo = cInfo |> moveBlockContent(cInfo[CurrentBlock][Content], "heading", 2)	
					end
				Regex.match?(~r/^_+\s*$/,line) ->
					
					if cInfo[CurrentBlock] do
						cInfo = cInfo |> finishBlock
					end
					cInfo = cInfo |> addBlock("horizontal line")
				true ->
					cInfo = String.graphemes(line) |> parseLineChars(cInfo)

			end


			if cInfo[CurrentBlock][Block] == "heading" or cInfo[CurrentBlock][Block] == "horizontal line" do
				cInfo = cInfo |> finishBlock
			end

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
				put_in(cInfo, [CurrentBlock, Content], cInfo[CurrentBlock][Content] ++ [%{Block => "break"}])
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
			prePreviousChar = if Enum.at(currentLine,-2) do Enum.at(currentLine,-2) else "" end

				
			cond do	

				blockCharset?(previousChar) and !escaped?(previousChar) ->
					cInfo = cInfo |> processBlock(previousChar) |> addChars(char)
				regularCharset?(previousChar) or previousChar == ""->
					cInfo = cInfo |> addChars(char)
			    space?(previousChar) and cInfo[CurrentBlock] ->
			    	cInfo = cInfo

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


			if regularCharset?(char) do
				addBlock(cInfo, "paragraph", cInfo[CurrentLine] <> char, "normal")	
			else
				cInfo
			end

		end
		
	end








	# add current block

	
	defp processBlock(cInfo, blockChar) do
		cond do 
			blockChar == "#"->
				cInfo |> headingBlock
			true ->
				cInfo
		end
	end

	defp addBlock(cInfo, block) do
		Map.put(cInfo, CurrentBlock, %{Block => block})
	end	

	defp addBlock(cInfo, block,value, type) do
		Map.put(cInfo, CurrentBlock, %{Block => block, Content => [%{Text => value, Type => type}]})
	end

	defp addBlock(cInfo, block, level,value, type) do
		Map.put(cInfo, CurrentBlock, %{Block => block, Content => [%{Text => value, Type => type}], Level => level})
	end

	defp moveBlockContent(cInfo, content, block) do
		Map.put(cInfo, CurrentBlock, %{Block => block, Content => content})
	end

	defp moveBlockContent(cInfo, content, block, level) do
		Map.put(cInfo, CurrentBlock, %{Block => block, Content => content, Level => level})
	end

	defp headingBlock(cInfo) do

		if !cInfo[CurrentBlock][Block] do
			hPrefix = String.trim(cInfo[CurrentLine])
			if Regex.match?(~R/^#{1,6}$/, hPrefix) do
				level = String.length(hPrefix)
				addBlock(cInfo, "heading", level, "", "normal")
			else
				addBlock(cInfo, "paragraph", hPrefix, "normal")
			end
			
		else
			cInfo
		end
		
	end

	defp trimBlockContent(block) do

		if Map.has_key?(block, Content) do
			Map.put(block, Content, trimContent(block[Content],[]))
		else
			block
		end
		

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
        String.trim(string) == "" or string == nil
    end

end


