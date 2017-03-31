# Other functions

defmodule Fun do

	alias Blocks

	def escaped?(char) do
		char == "\\"
	end

	def space?(char) do
		char == " " or char == "\t"
	end

	def regularCharset?(char) do 
		Regex.match?(~r/[A-Za-z0-9\\]{1}/, char)
	end

	def orderedListCharset?(char) do
		char == "." or char == ")"
	end

	def blockCharset?(char) do
		char == "#" or char == "`" or char == "+" or char == "-" or char == "*" or char == "=" or char == "." or char == ")"
	end

	def inlineCharset?(char) do
		char == "*" or char == "_"
	end

	def textToList(string) do
		String.split(string,"\n")
	end

	def empty?(string) do
        String.trim(string) == "" or string == nil
    end

    def firstChar?(lineContent) do
		empty?(lineContent)
	end

	def nextChar([char|rest]) do
		char
	end

	def nextChar([]) do
		false
	end

	def addChars(cInfo, char) do

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
				Blocks.addBlock(cInfo, "paragraph", cInfo[CurrentLine] <> char, "normal")	
			else
				cInfo
			end

		end
		
	end

end