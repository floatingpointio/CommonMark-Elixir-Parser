# Functions which deal with a blocks

defmodule Blocks do

	alias Fun

	def finishBlock(cInfo) do

		if cInfo[CurrentBlock] do

			currentBlock = cInfo[CurrentBlock]

			cond do
				currentBlock[Block] == "code block" ->
					if currentBlock[Type] == 1 or currentBlock[Type] == 3 do
						currentBlock = Map.delete(currentBlock,TagLength) 
					end

					currentBlock = Map.delete(currentBlock,Type)

				currentBlock[Block] == "HTML block" ->

					currentBlock = Map.delete(currentBlock,TagType)
					
				currentBlock[Block] == "heading" ->
					if Regex.match?(~R/\s#+\s*$/,Enum.at(currentBlock[Content],-1)[Text]) do
						currentBlock = currentBlock |> trimSpecialHeading |> trimBlockContent
					else
						currentBlock = currentBlock |> trimBlockContent
					end 
				true ->
					currentBlock = currentBlock |> trimBlockContent
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

	def processBlock(cInfo, blockChar) do
		cond do 
			blockChar == "#" ->
				cInfo |> headingBlock
			true ->
				cInfo
		end
	end

	def addBlock(cInfo, block) do
		Map.put(cInfo, CurrentBlock, %{Block => block})
	end	

	def addBlock(cInfo, block,value, type) do
		Map.put(cInfo, CurrentBlock, %{Block => block, Content => [%{Text => value, Type => type}]})
	end

	def addBlock(cInfo, block, level,value, type) do
		Map.put(cInfo, CurrentBlock, %{Block => block, Content => [%{Text => value, Type => type}], Level => level})
	end

	def addBlockAttribute(cInfo, attribute, value) do
		put_in(cInfo, [CurrentBlock, attribute], value)
	end

	def createBlockContent(cInfo) do
		put_in(cInfo, [CurrentBlock, Content], [])
	end

	def moveBlockContent(cInfo, content, block) do
		Map.put(cInfo, CurrentBlock, %{Block => block, Content => content})
	end

	def moveBlockContent(cInfo, content, block, level) do
		Map.put(cInfo, CurrentBlock, %{Block => block, Content => content, Level => level})
	end

	def headingBlock(cInfo) do

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


	def trimBlockContent(block) do

		if Map.has_key?(block, Content) do
			Map.put(block, Content, trimContent(block[Content],[]))
		else
			block
		end
		

	end

	def trimContent([content|rest], newContent) do

		if Map.has_key?(content, Text) do
			content = Map.put(content, Text, content[Text] |> String.trim |>  String.trim_trailing("\\"))
		end
		
		trimContent(rest, newContent ++ [content])
	end

	def trimContent([],newContent) do
		newContent
	end

	def trimSpecialHeading(block) do
		
		lastText = Enum.at(block[Content],-1)
		match = Enum.at(Regex.run(~R/\s#+\s*$/, lastText[Text]), -1)
		lastText = Map.put(lastText,Text, String.replace_suffix(lastText[Text], match, ""))
		put_in(block, [Content], List.replace_at(block[Content], -1, lastText))
	
	end

end