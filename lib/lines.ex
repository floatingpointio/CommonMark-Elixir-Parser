# Module which recognizes blocks within lines with specific patterns (no inline structure) such as: horizontal lines, code blocks, HTML blocks etc.

defmodule Lines do

	alias Parser
	alias Blocks
	alias Inlines
	alias Fun

	def checkLineForBlocks(cInfo, line) do


		currentBlock = cInfo[CurrentBlock][Block]
		htmlTagPairs = %{"<?" => "?>", 
						 "<!" => "!>",
		                 "<!--" => "-->", 
		                 "<![CDATA]" => "]]>", 
		                 "<SCRIPT>" => "</SCRIPT>", 
		                 "<STYLE>" => "</STYLE>", 
		                 "<PRE>" => "</PRE>"
		                }
		
		cond do



				# Link references


				Regex.match?(~r/^\s{0,3}\[[^\[^\].][^\[^\].]{0,999}\]\:/,line) ->


					cond do
						Regex.run(~r/^\s{0,3}\[[^\[^\].][^\[^\].]{0,999}\]\:\s*..*\s*\"..*\"\s*$/, line) ->
							
							name = Enum.at(Regex.run(~r/^\s{0,3}\[[^\[^\].][^\[^\].]{0,999}\]\:\s*(..*)\s*\"..*\"\s*$/, line),-1)
							url = Enum.at(Regex.run(~r/^\s{0,3}\[[^\[^\].][^\[^\].]{0,999}\]\:\s*(..*)\s*\"..*\"\s*$/, line),-1)
							title = Enum.at(Regex.run(~r/^\s{0,3}\[[^\[^\].][^\[^\].]{0,999}\]\:\s*..*\s*\"(..*)\"\s*$/, line),-1)

						Regex.run(~r/^\s{0,3}\[[^\[^\].][^\[^\].]{0,999}\]\:\s*..*\s*\'..*\'\s*$/, line) ->

							name = Enum.at(Regex.run(~r/^\s{0,3}\[[^\[^\].][^\[^\].]{0,999}\]\:\s*(..*)\s*\"..*\"\s*$/, line),-1)
							url = Enum.at(Regex.run(~r/^\s{0,3}\[[^\[^\].][^\[^\].]{0,999}\]\:\s*(..*)\s*\"..*\"\s*$/, line),-1)
							title = Enum.at(Regex.run(~r/^\s{0,3}\[[^\[^\].][^\[^\].]{0,999}\]\:\s*..*\s*\"(..*)\"\s*$/, line),-1)
							
						Regex.run(~r/^\s{0,3}\[[^\[^\].][^\[^\].]{0,999}\]\:\s*..*\s*$/, line) ->
						Regex.run(~r/^\s{0,3}\[[^\[^\].][^\[^\].]{0,999}\]\:\s*$/, line) ->

					end
					linkData = []

					if currentBlock do
						
						cond do
							currentBlock == "paragraph" ->
								cInfo = String.graphemes(line) |> Inlines.parseLineChars(cInfo)
							currentBlock == "code block" ->
								if cInfo[CurrentBlock][Type] == 1 or cInfo[CurrentBlock][Type] == 3 do
									cinfo = cInfo |> addChars(line)
								end
							currentBlock == "HTML block" ->
								cinfo = cInfo |> addChars(line)
							true ->

								cInfo = Map.put(cInfo,Links,linkData)
						end

					else

						cInfo = Map.put(cInfo,Links,linkData)
					end
					


				# HTML blocks Type 6

				Regex.match?(~r/^<\/?(adress|article|aside|base|basefront|blockquote|body|caption|center|col|colgroup|dd|details|dialog|dir|div|dl|dt|fieldset|figcaption|figure|footer|form|frame|frameset|h1|head|header|hr|html|iframe|legend|li|link|main|menu|menuitem|meta|nav|noframes|ol|optgroup|option|p|param|section|source|summary|table|tbody|td|tfoot|th|thead|title|tr|track|ul)(\s|>|\/>|$)/iu,line) ->

					if currentBlock do
						cond do
							currentBlock == "paragraph" ->
								cInfo = cInfo |> Fun.addChars(line)
							true ->
								cInfo = cInfo |> Fun.addChars(line)
						end
					else
						cInfo = cInfo 
								|> Blocks.addBlock("HTML block")
								|> Blocks.createBlockContent 
								|> Blocks.addBlockAttribute(TagType, "Regular") 
								|> Fun.addChars(line)
					end




				# HTML blocks Type 1,2,3,4,5 (Opening tags)

				Regex.match?(~r/^\s{0,3}(<!--|<\?|<![A-Z]|s<!\[CDATA\]|<(s|S)(c|C)(r|R)(i|I)(p|P)(t|T)(\s|\>|$)|<(s|S)(t|T)(y|Y)(l|L)(e|E)(\s|\>|$)|<(p|P)(r|R)(e|E)(\s|\>|$))/,line) ->

					tagType = ~r/^\s{0,3}(<!--|<\?|<![A-Z]|s<!\[CDATA\]|<(s|S)(c|C)(r|R)(i|I)(p|P)(t|T)(\s|\>|$)|<(s|S)(t|T)(y|Y)(l|L)(e|E)(\s|\>|$)|<(p|P)(r|R)(e|E)(\s|\>|$))/ 
							 	|> Regex.run(line)
							 	|> Enum.at(0)
							 	|> String.trim
							 	|> String.upcase

					
					cond do
						String.length(tagType) == 3 and String.slice(tagType,0,2) == "<!" ->
							tagType = "<!"	
						tagType == "<SCRIPT" ->
							tagType = "<SCRIPT>"
						tagType == "<STYLE" ->
							tagType = "<STYLE>"
						tagType == "<PRE" ->
							tagType == "<PRE>"
						true ->
							tagType
					end
					
					closingTag = Regex.escape(htmlTagPairs[tagType])
					closing = Regex.match?(~r/#{closingTag}/iu,line)
					
					if currentBlock do
						cond do
							currentBlock == "paragraph" or (currentBlock == "code block" and cInfo[CurrentBlock][Type] == 2)->
								cInfo = cInfo 
										|> Blocks.finishBlock 
										|> Blocks.addBlock("HTML block") 
										|> Blocks.createBlockContent 
										|> Blocks.addBlockAttribute(TagType, tagType) 
										|> Fun.addChars(line)

								if closing do cInfo = cInfo |> Blocks.finishBlock end

							true ->
								cInfo = cInfo |> Fun.addChars(line)
						end
					else
						cInfo = cInfo 
								|> Blocks.addBlock("HTML block") 
								|> Blocks.createBlockContent 
								|> Blocks.addBlockAttribute(TagType, tagType) 
								|> Fun.addChars(line)

						if closing do cInfo = cInfo |> Blocks.finishBlock end
					end
					



				# HTML blocks Type 2,3,4,5 (Closing tags)

				Regex.match?(~r/(--\>|\?>|\!>|\]\]>|<\/script\>|<\/style\>|<\/pre\>)/iu,line) -> 

					tagType = ~r/(--\>|\?>|\!>|\]\]>|<\/script\>|<\/style\>|<\/pre\>)/iu
						 	|> Regex.run(line)
						 	|> Enum.at(0)
						 	|> String.trim
						 	|> String.upcase

					if currentBlock do
						cond do
							currentBlock == "HTML block" ->
								tagTypeOpening = cInfo[CurrentBlock][TagType]
								if htmlTagPairs[tagTypeOpening] == tagType do
									cInfo = cInfo 
											|> Fun.addChars(line) 
											|> Blocks.finishBlock
								else
									cInfo = cInfo |> Fun.addChars(line) 
								end
							currentBlock == "code block" ->
								cInfo = cInfo |> Fun.addChars(line)
							currentBlock == "paragraph" ->
								cInfo = String.graphemes(line) |> Inlines.parseLineChars(cInfo)
						end
					else
						cInfo = String.graphemes(line) |> Inlines.parseLineChars(cInfo)
					end




				# Fenced code blocks  ---> ``` => Type 1 , ~~~ => Type 3


				Regex.match?(~r/^\s*(`|~){3,}\s*/,line) ->

					tag = String.trim(Enum.at(Regex.run(~r/^\s*(`|~){3,}\s*/,line),0))
					tagLen = String.length(tag)
					typeChar = String.slice(tag,0,1)


					if currentBlock do
						cond do
							currentBlock == "code block" ->
								if tagLen >= cInfo[CurrentBlock][TagLength] and ((typeChar == "`" and cInfo[CurrentBlock][Type] == 1) or (typeChar == "~" and cInfo[CurrentBlock][Type] == 3)) do
									cInfo = cInfo |> Blocks.finishBlock	
								else
									cInfo = cInfo |> Fun.addChars(line)
								end
							currentBlock == "HTML block" ->
								cInfo = cInfo |> Fun.addChars(line)
							true ->
								cInfo = cInfo 
										|> Blocks.finishBlock 
										|> Blocks.addBlock("code block") 
										|> Blocks.createBlockContent 
										|> Blocks.addBlockAttribute(TagLength,tagLen)

								if typeChar == "`" do 
									cInfo = cInfo |> Blocks.addBlockAttribute(Type,1)
									class = Regex.replace(~r/^\s*`{3,}\s*/, line, "")
								else
									cInfo = cInfo |> Blocks.addBlockAttribute(Type,3)
									class = Regex.replace(~r/^\s*~{3,}\s*/, line, "")
								end
								
								if !Fun.empty?(class) do cInfo = cInfo |> Blocks.addBlockAttribute(Class,"language-" <> class) end 	
						end
							
					else
						cInfo = cInfo 
								|> Blocks.addBlock("code block") 
								|> Blocks.createBlockContent 
								|> Blocks.addBlockAttribute(TagLength, tagLen)

						if typeChar == "`" do 
							cInfo = cInfo |> Blocks.addBlockAttribute(Type,1)
							class = Regex.replace(~r/^\s*`{3,}\s*/, line, "")
						else
							cInfo = cInfo |> Blocks.addBlockAttribute(Type,3)
							class = Regex.replace(~r/^\s*~{3,}\s*/, line, "")
						end

						if !Fun.empty?(class) do cInfo = cInfo |> Blocks.addBlockAttribute(Class,"language-" <> class) end 
					end



				# Indented code blocks  \s{4} => Type 2


				Regex.match?(~r/^\s{4}.+$/, line) ->

					text = Regex.replace(~r/^\s{4}/, line, "")
					if currentBlock do
						cond do
							currentBlock == "paragraph" ->
								cInfo =  cInfo 
										 |> Blocks.finishBlock 
										 |> Blocks.addBlock("code block") 
										 |> Blocks.createBlockContent 
										 |> Blocks.addBlockAttribute(Type, 2) 
										 |> Fun.addChars(text)
							currentBlock == "HTML block" ->
								cInfo = cInfo |> Fun.addChars(line)
							currentBlock == "code block" and (cInfo[CurrentBlock][Type] == 1 or cInfo[CurrentBlock][Type] == 3)->
								cInfo = cInfo |> Fun.addChars(line) 
							currentBlock == "code block" and cInfo[CurrentBlock][Type] == 2 ->
								cInfo = cInfo |> Fun.addChars(text) 	
						end
					else
						cInfo = cInfo 
								|> Blocks.addBlock("code block") 
								|> Blocks.createBlockContent 
								|> Blocks.addBlockAttribute(Type,2) 
								|> Fun.addChars(text)
					
					end



				# ATX Heading exceptions   example => ### ###, ##, ## ##### etc.



				Regex.match?(~R/^#{1,6}$/, line) or Regex.match?(~R/^#{1,6}\s+#+\s*$/,line) ->

					level = String.length(String.trim(Enum.at(Regex.run(~R/^\s*#{1,6}/,line),-1)))

					if currentBlock do
						cond do
							currentBlock == "paragraph" ->
								cInfo = cInfo |> Blocks.finishBlock
								cInfo = cInfo 
										|> Blocks.addBlock("heading", level, "", "normal") 
										|> Blocks.finishBlock
							currentBlock == "HTML block" or (currentBlock == "code block" and (cInfo[CurrentBlock][Type] == 1 or cInfo[CurrentBlock][Type] == 3))->
								cInfo = cInfo |> Fun.addChars(line)
							true ->
								cInfo = cInfo 
										|> Blocks.addBlock("heading", level, "", "normal") 
										|> Blocks.finishBlock
						end
					else
						cInfo = cInfo 
								|> Blocks.addBlock("heading", level, "", "normal") 
								|> Blocks.finishBlock
					end


				# Setext heading h1 ========= 
					

				Regex.match?(~r/^\s{0,3}=+\s*$/,line) ->
					
					if currentBlock do
						cond do
							currentBlock == "paragraph" ->
								cInfo = cInfo |> Blocks.moveBlockContent(cInfo[CurrentBlock][Content], "heading", 1)
							currentBlock == "HTML block" or (currentBlock == "code block" and (cInfo[currentBlock][Type] == 3 or cInfo[currentBlock][Type] == 1)) ->
								cInfo = cInfo |> Fun.addChars(line)
							true ->
								cInfo = cInfo
									 	|> Blocks.finishBlock
									 	|> Blocks.addBlock("paragraph")
									 	|> Blocks.addChars(line)
						end
					else
						cInfo = cInfo
								|> Blocks.addBlock("paragraph")
								|> Blocks.addChars(line)
					end


				# Setext heading h2 ----------  or horizontal line hl ----------------- 


				Regex.match?(~r/^\s{0,3}-+\s*$/,line) ->
					if currentBlock do
						cond do
							currentBlock == "paragraph" ->
								cInfo = cInfo |> Blocks.moveBlockContent(cInfo[CurrentBlock][Content], "heading", 2)
							currentBlock == "HTML block" or (currentBlock == "code block" and (cInfo[CurrentBlock][Type] == 3 or cInfo[CurrentBlock][Type] == 1)) ->
								cInfo = cInfo |> Fun.addChars(line)
							true ->
								cInfo = cInfo
									 	|> Blocks.finishBlock
									 	|> Blocks.addBlock("horizontal line")
						end
						
					else
						cInfo = cInfo |> Blocks.addBlock("horizontal line")
					end


				# Horizontal lines


				Regex.match?(~R/^\s*(_|\*|-)+\s*$/,line) or Regex.match?(~r/^\s*(-+\s+){2}(-+\s*)*$/,line) or Regex.match?(~R/^\s*(_+\s+){2}(_+\s*)*$/,line) or Regex.match?(~R/^\s*(\*+\s+){2}(\*+\s*)*$/,line) or Regex.match?(~R/^\s*(=+\s+){2}(=+\s*)*$/,line) ->

					if currentBlock do
						cond do
							currentBlock == "paragraph" ->
								cInfo = cInfo 
										|> Blocks.finishBlock
										|> Blocks.addBlock("horizontal line")
							currentBlock == "HTML block" or (currentBlock == "code block" and (cInfo[CurrentBlock][Type] == 1 or cInfo[CurrentBlock][Type] == 3)) ->
								cInfo = cInfo |> Fun.addChars(line)
							true ->

								cInfo = cInfo 
										|> Blocks.finishBlock
								        |> Blocks.addBlock("horizontal line")
						end
					else
						cInfo = cInfo |> Blocks.addBlock("horizontal line")
					end
					

				# Continue to inline parsing of blocks (paragraphs, headings, lists etc...s)
					
				true ->

					cond do
						currentBlock == "code block"  and cInfo[CurrentBlock][Type] == 2 ->
							cInfo = cInfo |> Blocks.finishBlock
							cInfo = String.graphemes(line) |> Inlines.parseLineChars(cInfo)
						currentBlock == "HTML block" ->
							cInfo = cInfo |> Fun.addChars(line)
						currentBlock == "code block" and (cInfo[CurrentBlock][Type] == 1 or cInfo[CurrentBlock][Type] == 3) -> 
							cInfo = cInfo |> Fun.addChars(line)
						currentBlock == "paragraph" ->
							cInfo = String.graphemes(line) |> Inlines.parseLineChars(cInfo)
						true ->
							cInfo = String.graphemes(line) |> Inlines.parseLineChars(cInfo)
						
					end 
					

			end


			if cInfo[CurrentBlock][Block] == "heading" or cInfo[CurrentBlock][Block] == "horizontal line" do
				cInfo = cInfo |> Blocks.finishBlock
			end

			cInfo

	end


	# Putting break block into a paragraph when ends with \s\s or \

	def lineEndCheck(cInfo) do

		cond do 
			cInfo[CurrentBlock][Block] == "paragraph" and (String.slice(cInfo[CurrentLine],-2,2) == "  " or String.slice(cInfo[CurrentLine], -1, 1) == "\\") ->
				put_in(cInfo, [CurrentBlock, Content], cInfo[CurrentBlock][Content] ++ [%{Block => "break"}])
			true ->
				cInfo

			# possible other checks
		end 
	end

end