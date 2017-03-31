# Module which deals with blocks wich contain inline elements

defmodule Inlines do

	alias Lines
	alias Blocks
	alias Parser
	alias Fun

	def parseLineChars([char|rest], cInfo) do

		currentBlock = cInfo[CurrentBlock][Block]
		
		if Fun.space?(char) and not Fun.firstChar?(cInfo[CurrentLine]) do

			
			currentLine = String.graphemes(cInfo[CurrentLine])
			previousChar = if Enum.at(currentLine,-1) do Enum.at(currentLine,-1) else "" end 
			prePreviousChar = if Enum.at(currentLine,-2) do Enum.at(currentLine,-2) else "" end

			cond do	

				Fun.blockCharset?(previousChar) and !Fun.escaped?(previousChar) ->
					cInfo = cInfo |> Blocks.processBlock(previousChar) |> Fun.addChars(char)
				Fun.space?(previousChar) and cInfo[CurrentBlock] ->
					if cInfo[CurrentBlock][Block] == "code block" or cInfo[CurrentBlock][Block] == "HTML block" do
						cInfo = cInfo |> Fun.addChars(char)
					else
						cInfo = cInfo
					end
			    	
				Fun.regularCharset?(previousChar) or previousChar == ""->
					cInfo = cInfo |> Fun.addChars(char)
			    
			end
			
		else

			cInfo = Fun.addChars(cInfo, char)
		end
		
		parseLineChars(rest, Map.put(cInfo, CurrentLine, cInfo[CurrentLine] <> char))
	end



	def parseLineChars([], cInfo) do
		
		cInfo = Lines.lineEndCheck(cInfo)
		
		Map.put(cInfo, CurrentLine, "") 
		|> Map.put(LastLine, cInfo[CurrentLine])
	end


end