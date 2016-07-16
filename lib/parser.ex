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

		currentBlock = cInfo[CurrentBlock][Block]

		if !empty?(line) do	

			cond do


				Regex.match?(~r/^`{3,}\s*/,line) ->

					if currentBlock do
						if currentBlock == "code block" do
							cInfo = cInfo |> finishBlock
						else
							cInfo = cInfo |> addBlock("code block") |> createBlockContent |> addBlockAttribute(Type,1)
							class = Regex.replace(~r/^`{3,}\s*/, line, "")
							if !empty?(class) do
								cInfo = cInfo |> addBlockAttribute(Class,"language-" <> class)
							end 	
						end
					else
						cInfo = cInfo |> addBlock("code block") |> createBlockContent |> addBlockAttribute(Type,1)
						class = Regex.replace(~r/^`{3,}\s*/, line, "")
						if !empty?(class) do
							cInfo = cInfo |> addBlockAttribute(Class,"language-" <> class)
						end 
					end

				Regex.match?(~r/^\s{4}.+$/, line) ->

					text = Regex.replace(~r/^\s{4}/, line, "")
					if !currentBlock do
						cInfo = cInfo |> addBlock("code block") |> createBlockContent |> addBlockAttribute(Type,2) |> addChars(text)
					else
						cond do
							currentBlock == "paragraph" ->
								cInfo =  cInfo |> finishBlock |> addBlock("code block") |> createBlockContent |> addBlockAttribute(Type, 2) |> addChars(text)
							currentBlock == "code block" and cInfo[CurrentBlock][Type] == 1 ->
								cInfo = cInfo |> addChars(line) 
							currentBlock == "code block" and cInfo[CurrentBlock][Type] == 2 ->
								cInfo = cInfo |> addChars(text) 	
						end
						
					end

				(Regex.match?(~R/^#{1,6}$/, line) or Regex.match?(~R/^#{1,6}\s+#+\s*$/,line)) and currentBlock != "code block"->

					if currentBlock == "paragraph" do
						cInfo = cInfo |> finishBlock
					end

					level = String.length(String.trim(Enum.at(Regex.run(~R/^\s*#{1,6}/,line),-1)))
					cInfo = cInfo |> addBlock("heading", level, "", "normal") |> finishBlock

				Regex.match?(~r/^\s{0,3}=+\s*$/,line) and currentBlock != "code block"->
					if currentBlock do
						if currentBlock == "paragraph" do
							cInfo = cInfo |> moveBlockContent(cInfo[CurrentBlock][Content], "heading", 1)	
						else
							cInfo = cInfo |> addChars(line)
						end
					else
						cInfo = cInfo
					end

				Regex.match?(~r/^\s{0,3}-+\s*$/,line) and currentBlock != "code block" ->
					if currentBlock do
						if currentBlock == "paragraph" do
							cInfo = cInfo |> moveBlockContent(cInfo[CurrentBlock][Content], "heading", 2)	
						else
							cInfo = cInfo |> addChars(line)
						end
					else
						cInfo = cInfo |> addBlock("horizontal line")
					end
				(Regex.match?(~R/^\s*(_|\*|-)+\s*$/,line) or Regex.match?(~r/^\s*(-+\s+){2}(-+\s*)*$/,line) or Regex.match?(~R/^\s*(_+\s+){2}(_+\s*)*$/,line) or Regex.match?(~R/^\s*(\*+\s+){2}(\*+\s*)*$/,line) or Regex.match?(~R/^\s*(=+\s+){2}(=+\s*)*$/,line)) and currentBlock != "code block" ->

					if cInfo[CurrentBlock] do
						cInfo = cInfo |> finishBlock
					end
					cInfo = cInfo |> addBlock("horizontal line")
				true ->
					if (currentBlock == "code block"  and cInfo[CurrentBlock][Type] == 2) do
						cInfo = cInfo |> finishBlock
					end 
					cInfo = String.graphemes(line) |> parseLineChars(cInfo)

			end


			if cInfo[CurrentBlock][Block] == "heading" or cInfo[CurrentBlock][Block] == "horizontal line" do
				cInfo = cInfo |> finishBlock
			end

		else
			if currentBlock != "code block" or (currentBlock == "code block" and cInfo[CurrentBlock][Type] == "2") do
				cInfo = cInfo |> finishBlock
			end	
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

			cond do
				cInfo[CurrentBlock][Block] == "code block" ->
					currentBlock = Map.delete(cInfo[CurrentBlock],Type)
				cInfo[CurrentBlock][Block] == "heading" ->
					if Regex.match?(~R/\s#+\s*$/,Enum.at(cInfo[CurrentBlock][Content],-1)[Text]) do
						currentBlock = cInfo[CurrentBlock] |> trimSpecialHeading |> trimBlockContent
					else
						currentBlock = cInfo[CurrentBlock] |> trimBlockContent
					end 
				true ->
					currentBlock = cInfo[CurrentBlock] |> trimBlockContent
			end
			
			Map.put(cInfo, AST, cInfo[AST] ++ [currentBlock])
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

		currentBlock = cInfo[CurrentBlock][Block]

		
		
		if space?(char) and not firstChar?(cInfo[CurrentLine]) do

			
			currentLine = String.graphemes(cInfo[CurrentLine])
			previousChar = if Enum.at(currentLine,-1) do Enum.at(currentLine,-1) else "" end 
			prePreviousChar = if Enum.at(currentLine,-2) do Enum.at(currentLine,-2) else "" end

			cond do	

				blockCharset?(previousChar) and !escaped?(previousChar) ->
					cInfo = cInfo |> processBlock(previousChar) |> addChars(char)
				space?(previousChar) and cInfo[CurrentBlock] ->
			    	cInfo = cInfo
				regularCharset?(previousChar) or previousChar == ""->
					cInfo = cInfo |> addChars(char)
			    
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
			
			if !(Enum.at(String.graphemes(cInfo[CurrentLine]),-1) == " " and char == " ") do
				
				if String.length(cInfo[CurrentLine]) == 0 do
				
					cInfo = put_in(cInfo, [CurrentBlock, Content], cInfo[CurrentBlock][Content] ++ [%{Text => "", Type => "normal"}])
				end

				put_in(cInfo, [CurrentBlock, Content], List.replace_at(cInfo[CurrentBlock][Content], -1, Map.put(Enum.at(cInfo[CurrentBlock][Content],-1), Text, Enum.at(cInfo[CurrentBlock][Content],-1)[Text] <> char)))
			else
				cInfo
			end
			
			
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
			blockChar == "#" ->
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

	defp addBlockAttribute(cInfo, attribute, value) do
		put_in(cInfo, [CurrentBlock, attribute], value)
	end

	defp createBlockContent(cInfo) do
		put_in(cInfo, [CurrentBlock, Content], [])
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

	defp trimSpecialHeading(block) do
		
		lastText = Enum.at(block[Content],-1)
		match = Enum.at(Regex.run(~R/\s#+\s*$/, lastText[Text]), -1)
		lastText = Map.put(lastText,Text, String.replace_suffix(lastText[Text], match, ""))
		put_in(block, [Content], List.replace_at(block[Content], -1, lastText))
	
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

	defp inlineCharset?(char) do
		char == "*" or char == "_"
	end

	defp textToList(string) do
		String.split(string,"\n")
	end

	defp empty?(string) do
        String.trim(string) == "" or string == nil
    end

end


