module MobiSys

	class UIGenUtilCompanyHelper


		def self.alterDataInOutput
			$quotationIO.htmlContent.each do |htmlContent|
				htmlContent.each_pair do |pageNumber, page|
                    page["content"].gsub!("Grepa5YRCT", "5YRCT")
			        page["content"].gsub!("WPDD", "WDD")
                end
            end
		end

		def self.roundingTableData(mvelHashMap,strToFormat=nil)
		  dec='.'
		  sep=','
		  round = 0
		  begin
		  	if strToFormat == nil
		  		num = MobiSys::Math.roundNearest(mvelHashMap.to_f,round)
		  	else
			   	num = MobiSys::Math.roundNearest(strToFormat.to_f,round) if strToFormat.to_s != ""
		  	end
		  rescue
			num = strToFormat
		  end
		  #num = strToFormat unless strToFormat
		  num = num.to_f if num.to_s == ""
		  num = num.to_s.sub(/\./, dec)
		  dec = Regexp.escape dec
		  maskedNum = num.reverse.gsub(/(\d{3})(?=\d)(?!\d*#{dec})/, "\\1#{sep}").reverse
		  #puts ">>>number: #{num} maskednumber: #{maskedNum}"
		  if num.to_f == 0.0
		   maskedNum = ""
		  elsif num.to_f > 0.0
			maskedNum = maskedNum.to_s.split('.')[0]
		   elsif num.to_f  < 0.0
			maskedNum = maskedNum.to_s.split('.')[0]
			maskedNum = "(" +maskedNum.gsub("-","") +")"
		  end
		  return maskedNum
		end

		def self.generateFundPieChart(quotationIO, fundList, fundDOHashMap)
			companyColour = OfflineApplication.find(:first, :conditions =>{{:name =>'PROPERTY'} =>'COMPANYCOLOUR'})
			if companyColour != nil && companyColour.value == "SLOCPI"
				if $showPdf == true
					fundHash = Hash.new
					sortHash = Hash.new
					i = 0
					fundList.each do |fund|
						fundHash[fund.fundCd] = fund.allocationPerc
						sortHash[i] = fund.fundCd
						i = i + 1
					end
					fundMasterHash = Hash.new

					fundDOHashMap.each{|fundCd, fund|
						fundName = fund.fundDesc
						fundName = fundName[0,fundName.length-5] if fundName.include? "Fund"
						fundMasterHash[fundCd] = fundName
					}
					productIDHash = Hash.new
					productIDHash["productID"] = quotationIO.baseDO.getBaseProduct.productId.to_s
					masterHash = Hash.new
					masterHash["fundHash"] = fundHash
					masterHash["fundMasterHash"] = fundMasterHash
					masterHash["sortHash"] = sortHash
					masterHash["productID"] = productIDHash
					jsonStr = ::JSON.generate(masterHash)

					imageName = quotationIO.baseDO.quotationRefNum + Random.rand(100000).to_s + ".png"
					fileName = Rho::RhoApplication.get_blob_folder + File::SEPARATOR + imageName
					#puts ">>>filename: #{fileName}"
					cmdStr = "javaw -classpath #{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}pdf.jar;"
					cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}flexjson-2.1.jar;"
					cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}jcommon-1.0.21.jar;"
					cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}jfreechart-1.0.17.jar;"
					cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}jfreechart-1.0.17-experimental.jar;"
					cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}jfreechart-1.0.17-swt.jar;"
					cmdStr << " com.c2lbiz.mobisys.win32.PieChartGenerator "
					cmdStr << jsonStr.gsub('"','\"').gsub(' ','$SPACE$')
					cmdStr << " #{fileName}"


					#puts "cmdStr generateFundPieChart: #{cmdStr}"

					answer = system(cmdStr)

					#puts ">>>answer: #{answer} errorStatus: #{$?}"

					return "<img src=\"#{imageName}\" width=\"100%\"/>"

				else
					localFundList = fundList
					companyColour = $rhoconfig[:SunPHComp]					
					localFundDOHashMap = fundDOHashMap
					pieDataset = []
					pieLabelset = []
					renderer = ""
					localFundList.each do |fd|
					  	pieDataset << fd.allocationPerc
					  	pieLabelset << "#{fd.allocationPerc.to_i}%"
						if fd.fundCd == "SLPEF"  #SUNSS 2504 
						renderer << "'rgb(235,137,44)'"
						elsif fd.fundCd == "SLPBA"
						renderer << "'rgb(254,190,16)'"
						elsif fd.fundCd == "SLPBF"
						renderer << "'rgb(0,57,70)'"
						elsif fd.fundCd == "TDF20"
						renderer << "'rgb(25,55,103)'"
						elsif fd.fundCd == "TDF25"
						renderer << "'rgb(172, 97, 0)'"
						elsif fd.fundCd == "SLPP3"
						renderer << "'rgb(84, 130, 171)'"
						elsif fd.fundCd == "SLUSP"
						renderer << "'rgb(172, 97, 0)'"
						elsif fd.fundCd == "TDF30"
						renderer << "'rgb(19,129,121)'"
						elsif fd.fundCd == "TDF35"
						renderer << "'rgb(134,167,173)'"
						elsif fd.fundCd == "TDF40"
							renderer << "'rgb(225,220,210)'"
						elsif fd.fundCd == "SLPIF"
							renderer << "'rgb(0,76,108)'"
						elsif fd.fundCd == "SLPOF"
							renderer << "'rgb(255,203,5)'"
						elsif fd.fundCd == "SLPGF"
							renderer << "'rgb(223,114,39)'"
						elsif fd.fundCd == "SLUIF"
							renderer << "'rgb(0,76,108)'"
						elsif fd.fundCd == "SLUOF"
							renderer << "'rgb(255,203,5)'"
						elsif fd.fundCd == "SLUBF"
							renderer << "'rgb(74,114,131)'"
						elsif fd.fundCd == "SGFBA"
							renderer << "'rgb(192,0,0)'"
						elsif fd.fundCd == "SGFBF"
							renderer << "'rgb(255,0,0)'"
						elsif fd.fundCd == "SGFEF"
							renderer << "'rgb(255,192,0)'"
						elsif fd.fundCd == "SGUIF"
							renderer << "'rgb(255,0,0)'"
						elsif fd.fundCd == "SGUOF"
							renderer << "'rgb(255,192,0)'"
						elsif fd.fundCd == "SGFGF"
							renderer << "'rgb(0,176,240)'"
						elsif fd.fundCd == "SGFIF"
							renderer << "'rgb(0,112,192)'"
						elsif fd.fundCd == "SGFOF"
							renderer << "'rgb(0,32,96)'"
						elsif fd.fundCd == "SLPGPF"
							renderer << "'rgb(198,216,212)'"
						elsif fd.fundCd == "SLPGP"
							renderer << "'rgb(250,166,31)'"
						elsif fd.fundCd == "SGFGPF"
							renderer << "'rgb(0,176,80)'"
						elsif fd.fundCd == "SLUD9"
							renderer << "'rgb(84,130,171)'"
						elsif fd.fundCd == "SLPP1"
							renderer << "'rgb(11,113,58)'"
						# slocpi 5 extra fund changes start
						elsif fd.fundCd == "SLPF1"
							renderer << "'rgb(133,21,52)'"
						elsif fd.fundCd == "SLPF2"
							renderer << "'rgb(154,154,154)'"
						elsif fd.fundCd == "SLPF3"
							renderer << "'rgb(235,137,44)'"
						elsif fd.fundCd == "SLPF4"
							renderer << "'rgb(72,191,173)'"
						elsif fd.fundCd == "SLPF5"
							renderer << "'rgb(0,84,139)'"
						# slocpi 5 extra fund changes end
						# slgfi 5 extra fund changes start
						elsif fd.fundCd == "SLGF1"
							renderer << "'rgb(0, 139, 139)'"
						elsif fd.fundCd == "SLGF2"
							renderer << "'rgb(222, 184, 135)'"
						elsif fd.fundCd == "SLGF3"
							renderer << "'rgb(186, 85, 211)'"
						elsif fd.fundCd == "SLGF4"
							renderer << "'rgb(205, 133, 63)'"
						elsif fd.fundCd == "SLGF5"
							renderer << "'rgb(255, 99, 71)'"
						# slgfi 5 extra fund changes end
						elsif fd.fundCd == "SLPXF"
							renderer << "'rgb(1,71,71)'"
						elsif fd.fundCd == "TEMP" + quotationIO.baseDO.getBaseProduct.productId.to_s
							if companyColour == "SLOCPI"
								renderer << "'rgb(85,127,168)'"
							else
								renderer << "'rgb(85,127,168)'"
							end
						elsif fd.fundCd == "SGFGO"
							renderer << "'rgb(155,229,255)'"
						elsif fd.fundCd == "SGFGG"
							renderer << "'rgb(121,198,255)'"
						elsif fd.fundCd == "SGFGI"
							renderer << "'rgb(0,78,234)'"
						elsif fd.fundCd == "SGUOP"
							renderer << "'rgb(255,255,0)'"
						elsif fd.fundCd == "SLPGO"
							renderer << "'rgb(85,85,85)'"
						elsif fd.fundCd == "SLPGG"
							renderer << "'rgb(255,221,0)'"
						elsif fd.fundCd == "SLPGI"
							renderer << "'rgb(0,180,189)'"
						elsif fd.fundCd == "SLUOP"
							renderer << "'rgb(119,108,98)'"
						elsif fd.fundCd == "FND01"
							renderer << "'rgb(255,255,0)'"
						elsif fd.fundCd == "FND02"
							renderer << "'rgb(192,0,0)'"
						elsif fd.fundCd == "FND03"
							renderer << "'rgb(146,208,80)'"	
						elsif fd.fundCd == "FND04"
							renderer << "'rgb(255,255,153)'"
						elsif fd.fundCd == "FND05"
							renderer << "'rgb(192,227,153)'"
						elsif fd.fundCd == "SLPTG"
							renderer << "'rgb(201,152,89)'"
						elsif fd.fundCd == "SLPTP"
							renderer << "'rgb(230,144,106)'"
						elsif fd.fundCd == "SLUTP"
							renderer << "'rgb(230,144,106)'"
						elsif fd.fundCd == "SLUTG"
							renderer << "'rgb(201,152,89)'"	
						end
					end
					pieHeight = 0.11
					piebgHeight = 0.083
					if quotationIO.baseDO.getBaseProduct.productId.to_s == "TBDGrepa"
							pieHeight = 0.12
							piebgHeight = 0.9
					elsif quotationIO.baseDO.getBaseProduct.productId.to_s == "SGPAB"
							pieHeight = 0.12
							piebgHeight = 0.10			
					end 
					renderer = renderer.gsub(")''",")','")
					canName = 'myCanvas_'+Random.rand(2500000).to_s
					divName = Random.rand(2500000).to_s + "_rGraph"
					htmlStr = ""
					$graphHtmlCounter = $graphHtmlCounter+1
					placeHolder = "$graphHtml_#{$graphHtmlCounter}$"
					if quotationIO.offlinePDFGeneration.to_s != "true"
						htmlStr = "<html>"
						htmlStr << "<script type='text/javascript' src='jquery-3.7.1.min.js'></script>"
						htmlStr << "<script type='text/javascript' src='RGraph.bar.js'></script>"
						htmlStr << "<script type='text/javascript' src='RGraph.line.js'></script>"
						htmlStr << "<script type='text/javascript' src='RGraph.common.core.js'></script>"
						htmlStr << "<script type='text/javascript' src='RGraph.pie.js'></script>"
						htmlStr << "<script type='text/javascript' src='RGraph.common.key.js'></script>"
						htmlStr << "<div name=\"mainWrapper\" id=\"#{placeHolder}\">"
						htmlStr << "<img name='graph_png' src =\"\">"
					end
					htmlStr << "<div  style =\"background-color: rgb(255,235,191);#{pieHeight}\">"
					# htmlStr << "<script type=\"text/javascript\">$('div[name=\"#{divName}\"]').html('<div class=\"graphWrapper\" style = \"height:'+ $(document).width() * 0.11 +'px\">');</script>"
					htmlStr << "<div name=\"#{divName}\" style =\"width:70%;\">"
					htmlStr << "</div>"
					htmlStr << "</div>"
					htmlStr << "</div>"
					htmlStr << "</div>" if quotationIO.offlinePDFGeneration.to_s != "true"
					htmlStr << "<script type=\"text/javascript\">"
					htmlStr << "$(document).ready(function(){"
					htmlStr << "$('div[name=\"#{divName}\"]').css(\"margin-left\", $(document).width() * 0.02 + \"px\");"
					htmlStr << "$('div[name=\"#{divName}\"]').html(\"<canvas id='#{canName}' name='#{canName}' width='\"+ $(document).width() * 0.165 +\"px' height='\"+ $(document).width() * #{pieHeight} +\"px'>[No canvas support]</canvas>\");"
					htmlStr << "$('div[name=\"#{divName}\"]').trigger('create');"
					htmlStr << "myGraph = new RGraph.Pie('#{canName}', #{pieDataset});"
					# htmlStr << "myGraph.Set('chart.labels',#{pieLabelset});"
					htmlStr << "myGraph.Set('chart.text','75%');"
					htmlStr << "myGraph.Set('chart.colors.stroke',[#{renderer}]);"
					htmlStr << "myGraph.Set('chart.labels.ingraph', true);"
					htmlStr << "myGraph.Set('chart.labels.ingraph.radius', $(document).width() * 0.03);"
					htmlStr << "myGraph.Set('chart.labels.ingraph.bounding', false);"
					htmlStr << "myGraph.Set('chart.labels.ingraph.bounding.fill', [#{renderer}]);"
					htmlStr << "myGraph.Set('chart.labels.ingraph.bounding.stroke', [#{renderer}]);"
		            htmlStr << "myGraph.Set('chart.labels.ingraph.size', 7.5);"
		            htmlStr << "myGraph.Set('chart.labels.ingraph.font', 'Arial');"
		            htmlStr << "myGraph.Set('chart.shadow', false);"
		            #htmlStr << "myGraph.Set('chart.labels.ingraph.bold', true);"
		            htmlStr << "myGraph.Set('chart.labels.ingraph.color', 'white');"
		            htmlStr << "myGraph.Set('chart.labels.ingraph.units.post', '%');"
		            htmlStr << "myGraph.Set('chart.backgroundColor','rgb(255,235,191)');"
					htmlStr << "myGraph.Set('chart.colors', [#{renderer}]);"
					companyColour = OfflineApplication.find(:first, :conditions =>{{:name =>'PROPERTY'} =>'COMPANYCOLOUR'})
			      	if companyColour != nil && companyColour.value != "SLGFI"
						htmlStr << "myGraph.Set('chart.radius', $(document).width() * 0.045);"
					else
						htmlStr << "myGraph.Set('chart.radius', $(document).width() * 0.055);"
					end

					htmlStr << "myGraph.Set('chart.linewidth', 0);"
					htmlStr << "myGraph.Set('chart.text.accessible', false);"

					htmlStr << "myGraph.Set('chart.backgroundColor','rgb(255,235,191)');"
					htmlStr << "myGraph.Draw();"
					htmlStr << "RGraph.Register(myGraph);"
					if quotationIO.offlinePDFGeneration.to_s != "true"
						htmlStr << "image_data = myGraph.canvas.toDataURL('image/png');"
			            htmlStr << "$('img[name=\"graph_png\"').attr('src',image_data);"
			            htmlStr << "imageElement = $(\"img[name='graph_png']\");"
			            htmlStr << "$(\"canvas\").replaceWith(imageElement);"
			        end
					htmlStr << "});"
					htmlStr << "</script>"
					if quotationIO.offlinePDFGeneration.to_s != "true"
						htmlStr << "</html>"
						$graphHtmlHM[placeHolder] = htmlStr

						return placeHolder
					else
						return htmlStr
					end
			  	end
			else
				if $showPdf == true
					fundHash = Hash.new
					sortHash = Hash.new
					i = 0
					fundList.each do |fund|
						fundHash[fund.fundCd] = fund.allocationPerc
						sortHash[i] = fund.fundCd
						i = i + 1
					end
					fundMasterHash = Hash.new

					fundDOHashMap.each{|fundCd, fund|
						fundName = fund.fundDesc
						fundName = fundName[0,fundName.length-5] if fundName.include? "Fund"
						fundMasterHash[fundCd] = fundName
					}
					productIDHash = Hash.new
					productIDHash["productID"] = quotationIO.baseDO.getBaseProduct.productId.to_s
					masterHash = Hash.new
					masterHash["fundHash"] = fundHash
					masterHash["fundMasterHash"] = fundMasterHash
					masterHash["sortHash"] = sortHash
					masterHash["productID"] = productIDHash
					jsonStr = ::JSON.generate(masterHash)

					imageName = quotationIO.baseDO.quotationRefNum + Random.rand(100000).to_s + ".png"
					fileName = Rho::RhoApplication.get_blob_folder + File::SEPARATOR + imageName
					#puts ">>>filename: #{fileName}"
					cmdStr = "javaw -classpath #{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}pdf.jar;"
					cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}flexjson-2.1.jar;"
					cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}jcommon-1.0.21.jar;"
					cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}jfreechart-1.0.17.jar;"
					cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}jfreechart-1.0.17-experimental.jar;"
					cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}jfreechart-1.0.17-swt.jar;"
					cmdStr << " com.c2lbiz.mobisys.win32.PieChartGenerator "
					cmdStr << jsonStr.gsub('"','\"').gsub(' ','$SPACE$')
					cmdStr << " #{fileName}"


					#puts "cmdStr generateFundPieChart: #{cmdStr}"

					answer = system(cmdStr)

					#puts ">>>answer: #{answer} errorStatus: #{$?}"

					return "<img src=\"#{imageName}\" width=\"75%\"/>"

				else
					localFundList = fundList
				   companyColour = $rhoconfig[:SunPHComp]
				
					localFundDOHashMap = fundDOHashMap
					pieDataset = []
					pieLabelset = []
					renderer = ""
					localFundList.each do |fd|
						pieDataset << fd.allocationPerc
						pieLabelset << "#{fd.allocationPerc.to_i}%"

						if fd.fundCd == "SLPEF"  #SUNSS 2505
							renderer << "'rgb(255,192,0)'"
						elsif fd.fundCd == "SLPBA"
							renderer << "'rgb(192,0,0)'"
						elsif fd.fundCd == "SLPBF"
							renderer << "'rgb(255,0,0)'"
						elsif fd.fundCd == "TDF20"
							renderer << "'rgb(1,71,71)'"
						elsif fd.fundCd == "TDF25"
							renderer << "'rgb(172, 97, 0)'"
						elsif fd.fundCd == "SGUSP"
							renderer << "'rgb(172, 97, 0)'"
						elsif fd.fundCd == "TDF30"
							renderer << "'rgb(19,129,121)'"
						elsif fd.fundCd == "TDF35"
							renderer << "'rgb(134,167,173)'"
						elsif fd.fundCd == "TDF40"
							renderer << "'rgb(225,220,210)'"
						elsif fd.fundCd == "SLPIF"
							renderer << "'rgb(25,55,103)'"
						elsif fd.fundCd == "SLPOF"
							renderer << "'rgb(0,32,96)'"
						elsif fd.fundCd == "SLPGF"
							renderer << "'rgb(0,176,240)'"
						elsif fd.fundCd == "SLUIF"
							renderer << "'rgb(255,0,0)'"
						elsif fd.fundCd == "SLUOF"
							renderer << "'rgb(255,192,0)'"
						elsif fd.fundCd == "SLUBF"
							renderer << "'rgb(146,208,80)'"
						elsif fd.fundCd == "SGFBA"
							renderer << "'rgb(254,190,16)'"
						elsif fd.fundCd == "SGFBF"
							renderer << "'rgb(0,57,70)'"
						elsif fd.fundCd == "SGFEF"
							renderer << "'rgb(235,137,44)'"
						elsif fd.fundCd == "SGUIF"
							renderer << "'rgb(0,76,108)'"
						elsif fd.fundCd == "SGUOF"
							renderer << "'rgb(255,203,5)'"
						elsif fd.fundCd == "SGFGF"
							renderer << "'rgb(223,114,39)'"
						elsif fd.fundCd == "SGFIF"
							renderer << "'rgb(0,76,108)'"
						elsif fd.fundCd == "SGFOF"
							renderer << "'rgb(255,203,5)'"
						elsif fd.fundCd == "SLPGPF"
							renderer << "'rgb(0,176,80)'"
						elsif fd.fundCd == "SGFGPF"
							renderer << "'rgb(198,216,212)'"
						elsif fd.fundCd == "SGFGP"
							renderer << "'rgb(250,166,31)'"
						elsif fd.fundCd == "SLUD9"
							renderer << "'rgb(0,176,80)'"
						elsif fd.fundCd == "SLPP1"
							renderer << "'rgb(0,176,240)'"
						# slocpi 5 extra fund changes start
						elsif fd.fundCd == "SLPF1"
							renderer << "'rgb(128,128,128)'"
						elsif fd.fundCd == "SLPF2"
							renderer << "'rgb(146,208,80)'"
						elsif fd.fundCd == "SLPF3"
							renderer << "'rgb(192,0,0)'"
						elsif fd.fundCd == "SLPF4"
							renderer << "'rgb(172,185,202)'"
						elsif fd.fundCd == "SLPF5"
							renderer << "'rgb(197,140,240)'"
						# slocpi 5 extra fund changes end
						# slgfi 5 extra fund changes start
						elsif fd.fundCd == "SLGF1"
							renderer << "'rgb(0, 139, 139)'"
						elsif fd.fundCd == "SLGF2"
							renderer << "'rgb(222, 184, 135)'"
						elsif fd.fundCd == "SLGF3"
							renderer << "'rgb(186, 85, 211)'"
						elsif fd.fundCd == "SLGF4"
							renderer << "'rgb(205, 133, 63)'"
						elsif fd.fundCd == "SLGF5"
							renderer << "'rgb(255, 99, 71)'"
						# slgfi 5 extra fund changes end
						elsif fd.fundCd == "SLPXF"
							renderer << "'rgb(112,48,160)'"
						elsif fd.fundCd == "TEMP" + quotationIO.baseDO.getBaseProduct.productId.to_s
							if companyColour == "SLOCPI"
								renderer << "'rgb(85,127,168)'"
							else
								renderer << "'rgb(85,127,168)'"
							end
						elsif fd.fundCd == "SGFGO"
							renderer << "'rgb(85,85,85)'"
						elsif fd.fundCd == "SGFGG"
							renderer << "'rgb(255,221,0)'"
						elsif fd.fundCd == "SGFGI"
							renderer << "'rgb(0,180,189)'"
						elsif fd.fundCd == "SGUOP"
							renderer << "'rgb(119,108,98)'"
						elsif fd.fundCd == "SLPGO"
							renderer << "'rgb(155,229,255)'"
						elsif fd.fundCd == "SLPGG"
							renderer << "'rgb(121,198,255)'"
						elsif fd.fundCd == "SLPGI"
							renderer << "'rgb(0,78,234)'"
						elsif fd.fundCd == "SLUOP"
							renderer << "'rgb(128,128,128)'"
						elsif fd.fundCd == "FND01"
							renderer << "'rgb(133,21,52)'"
						elsif fd.fundCd == "FND02"
							renderer << "'rgb(235,137,44)'"
						elsif fd.fundCd == "FND03"
							renderer << "'rgb(154,154,154)'"	
						elsif fd.fundCd == "FND04"
							renderer << "'rgb(72,191,173)'"
						elsif fd.fundCd == "FND05"
							renderer << "'rgb(0,84,139)'"
						elsif fd.fundCd == "SGPTG"
							renderer << "'rgb(201,152,89)'"
						elsif fd.fundCd == "SGPTP"
							renderer << "'rgb(230,144,106)'"
						elsif fd.fundCd == "SGGTP"
							renderer << "'rgb(230,144,106)'"
						elsif fd.fundCd == "SGGTG"
							renderer << "'rgb(201,144,89)'"
						end
					end
					pieHeight = 0.110
					piebgHeight = 0.11
					if quotationIO.baseDO.getBaseProduct.productId.to_s == "TBDGrepa"
							# pieHeight = 0.14
							# piebgHeight = 0.9
					elsif quotationIO.baseDO.getBaseProduct.productId.to_s == "SGPAB"
							pieHeight = 0.110
							piebgHeight = 0.10			
					end 
					renderer = renderer.gsub(")''",")','")
					canName = 'myCanvas_'+Random.rand(2500000).to_s
					divName = Random.rand(2500000).to_s + "_rGraph"
					htmlStr = ""
					$graphHtmlCounter = $graphHtmlCounter+1
					placeHolder = "$graphHtml_#{$graphHtmlCounter}$"
					if quotationIO.offlinePDFGeneration.to_s != "true"
						htmlStr = "<html>"
						htmlStr << "<script type='text/javascript' src='jquery-3.7.1.min.js'></script>"
						htmlStr << "<script type='text/javascript' src='RGraph.bar.js'></script>"
						htmlStr << "<script type='text/javascript' src='RGraph.line.js'></script>"
						htmlStr << "<script type='text/javascript' src='RGraph.common.core.js'></script>"
						htmlStr << "<script type='text/javascript' src='RGraph.pie.js'></script>"
						htmlStr << "<script type='text/javascript' src='RGraph.common.key.js'></script>"
						htmlStr << "<div name=\"mainWrapper\" id=\"#{placeHolder}\">"
						htmlStr << "<img name='graph_png' src =\"\">"
					end
					htmlStr << "<div  style =\"background-color: rgb(255,235,191);#{pieHeight}\">"
					# htmlStr << "<script type=\"text/javascript\">$('div[name=\"#{divName}\"]').html('<div class=\"graphWrapper\" style = \"height:'+ $(document).width() * 0.085 +'px\">');</script>"
					htmlStr << "<div name=\"#{divName}\" style =\"width:70%;\">"
					htmlStr << "</div>"
					htmlStr << "</div>"
					htmlStr << "</div>"
					htmlStr << "</div>" if quotationIO.offlinePDFGeneration.to_s != "true"
					htmlStr << "<script type=\"text/javascript\">"
					htmlStr << "$(document).ready(function(){"
					htmlStr << "$('div[name=\"#{divName}\"]').css(\"margin-left\", $(document).width() * 0.025 + \"px\");"
					if quotationIO.offlinePDFGeneration.to_s != "true"
						htmlStr << "$('div[name=\"#{divName}\"]').html(\"<canvas id='#{canName}' name='#{canName}' width='\"+ $(document).width() * 0.22 +\"px' height='\"+ $(document).width() * #{pieHeight} +\"px'>[No canvas support]</canvas>\");"
					else
						htmlStr << "$('div[name=\"#{divName}\"]').html(\"<canvas id='#{canName}' name='#{canName}' width='\"+ $(document).width() * 0.165 +\"px' height='\"+ $(document).width() * #{pieHeight} +\"px'>[No canvas support]</canvas>\");"
					end
					htmlStr << "$('div[name=\"#{divName}\"]').trigger('create');"
					htmlStr << "myGraph = new RGraph.Pie('#{canName}', #{pieDataset});"
					# htmlStr << "myGraph.Set('chart.labels',#{pieLabelset});"
					htmlStr << "myGraph.Set('chart.text','70%');"
					htmlStr << "myGraph.Set('chart.colors.stroke',[#{renderer}]);"
					htmlStr << "myGraph.Set('chart.labels.ingraph', true);"
					htmlStr << "myGraph.Set('chart.labels.ingraph.radius', $(document).width() * 0.035);"
					htmlStr << "myGraph.Set('chart.labels.ingraph.bounding', false);"
					htmlStr << "myGraph.Set('chart.labels.ingraph.bounding.fill', [#{renderer}]);"
					htmlStr << "myGraph.Set('chart.labels.ingraph.bounding.stroke', [#{renderer}]);"
		            htmlStr << "myGraph.Set('chart.labels.ingraph.size', 6);"
		            htmlStr << "myGraph.Set('chart.labels.ingraph.font', 'Arial');"
		            htmlStr << "myGraph.Set('chart.shadow', false);"
		            #htmlStr << "myGraph.Set('chart.labels.ingraph.bold', true);"
		            #htmlStr << "myGraph.Set('chart.labels.ingraph.color', 'white');"
		            htmlStr << "myGraph.Set('chart.labels.ingraph.units.post', '%');"
		            htmlStr << "myGraph.Set('chart.text.accessible', false);"
		            htmlStr << "myGraph.Set('chart.backgroundColor','rgb(255,235,191)');"
					htmlStr << "myGraph.Set('chart.colors', [#{renderer}]);"
					companyColour = OfflineApplication.find(:first, :conditions =>{{:name =>'PROPERTY'} =>'COMPANYCOLOUR'})
			      	if companyColour != nil && companyColour.value != "SLGFI"
						htmlStr << "myGraph.Set('chart.radius', $(document).width() * 0.06);"
					else
						htmlStr << "myGraph.Set('chart.radius', $(document).width() * 0.045);"
					end

					htmlStr << "myGraph.Set('chart.linewidth', 0);"

					htmlStr << "myGraph.Draw();"
					htmlStr << "RGraph.Register(myGraph);"
					if quotationIO.offlinePDFGeneration.to_s != "true"
						htmlStr << "image_data = myGraph.canvas.toDataURL('image/png');"
			            htmlStr << "$('img[name=\"graph_png\"').attr('src',image_data);"
			            htmlStr << "imageElement = $(\"img[name='graph_png']\");"
			            htmlStr << "$(\"canvas\").replaceWith(imageElement);"
			        end
					htmlStr << "});"
					htmlStr << "</script>"
					if quotationIO.offlinePDFGeneration.to_s != "true"
						htmlStr << "</html>"
						$graphHtmlHM[placeHolder] = htmlStr

						return placeHolder
					else
						return htmlStr
					end
			  	end
			end
		end

	def self.getPieChartLegendItem(quotationIO,fundList,fundDOHashMap)
		companyColour = OfflineApplication.find(:first, :conditions =>{{:name =>'PROPERTY'} =>'COMPANYCOLOUR'})
		if quotationIO.offlinePDFGeneration.to_s != "true"
			pPATH = "/assets/theme/images/company/"
		else
			pPATH = "/public/images/outputimages/"
		end
	  if companyColour != nil && companyColour.value == "SLGFI"	
	  	getSLGFIPieChartLegendItem(quotationIO,fundList,fundDOHashMap)
	  else
			finalString = ""
			finalString << "<div class=\"fund-alloc-legend\"> <table class=\"fund-alloc-list\" width = \"100%\">"
			counter = 0;
			fundList.each do |fund|
				fundDO = fundDOHashMap[fund.fundCd]
				fundName = fundDO.fundDesc
				fundName = fundName[0,fundName.length-5] if fundName.include? "Fund"
				if(counter == 0)
					finalString << "<tr>"
				end

				finalString << "<td><img src=\"#{pPATH}#{fund.fundCd}.png\" width = \"10px\" style = \"margin: 2px 5px 0px 0px;verticle-align:bottom;\"/>#{fundName}</td>"
				counter = counter + 1
				if(counter == 2)
					finalString << "</tr>"
					counter = 0
				end
			end
			finalString << "</table></div>"
		end	
	end
################changes done by Sachin#################################	
		def self.getSLGFIPieChartLegendItem(quotationIO,fundList,fundDOHashMap)
			finalString = ""
			changefundname = ""
			if quotationIO.baseDO.getBaseProduct.productId.to_s == "TBDGrepa"
				finalString << "<div class=\"fund-alloc-legend1\"> <table class=\"fund-alloc-list\" width = \"100%\">"
			else
				finalString << "<div class=\"fund-alloc-legend\"> <table class=\"fund-alloc-list\" width = \"100%\">"
			end	
			counter = 0;
			fundList.each do |fund|
				fundDO = fundDOHashMap[fund.fundCd]
				fundName = fundDO.fundDesc
				fundName = fundName[0,fundName.length-5] if fundName.include? "Fund"
				#puts "fundName=========>#{fundName}"
				if quotationIO.offlinePDFGeneration.to_s != "true"
					pPATH = "/assets/theme/images/company/"
				else
					pPATH = "/public/images/outputimages/"
				end
				if(counter == 0)
					finalString << "<tr>"
				end
					if(fundName == "SLG Opportunity Tracker" || fundName == "SLG Global Opportunity")
						if(fundName == "SLG Opportunity Tracker")
	                   		changefundname << "<span>SLG Opportunity</span><br/><span>Tracker</span>"
	                	elsif(fundName == "SLG Global Opportunity")
	                		changefundname << "<span>SLG Global</span><br/><span>Opportunity</span>"
	                	end
		                    finalString << "<td><img src=\"#{pPATH}#{fund.fundCd}.png\" width = \"12px\" style = \"margin: 2px 5px 0px 0px;vertical-align:bottom;\"/>#{changefundname}</td>"
		                	counter = counter + 1
	            	elsif(fundName == "SLG Global Asset Builder - PriMO")
	            		finalString << "<td colspan=\"2\"><img src=\"#{pPATH}#{fund.fundCd}.png\" width = \"12px\" style = \"margin: 2px 5px 0px 0px;vertical-align:bottom;\"/>#{fundName}</td>"
	                	counter = counter + 2 	                
	                else                 
	                	finalString << "<td><img src=\"#{pPATH}#{fund.fundCd}.png\" width = \"12px\" style = \"margin: 2px 5px 0px 0px;vertical-align:bottom;\"/>#{fundName}</td>"
	                	counter = counter + 1	                               
	                end
				if(counter == 2)
					finalString << "</tr>"
					counter = 0
				end
			end
			finalString << "</table></div>"
	    end

	def self.generateStackedBarChart(quotationIO , localElement1 , localElement2 , tickUnit, maxRange, inRate1, inRate2, ageCondition,str="NOTAPPLICABLE")
		#puts "generateStackedBarChart------------str111111------>#{str}"
	  companyColour = OfflineApplication.find(:first, :conditions =>{{:name =>'PROPERTY'} =>'COMPANYCOLOUR'})
	  if companyColour != nil && companyColour.value == "SLGFI"	
	  	generateSLGFIStackedBarChart(quotationIO , localElement1 , localElement2 , tickUnit, maxRange, inRate1, inRate2, ageCondition,str="NOTAPPLICABLE")
	  else	
		if $showPdf == true
			inputHash = Hash.new
			inputHash["tickUnit"] = tickUnit
			inputHash["maxRange"] = maxRange
			inputHash["ageCondition"] = ageCondition
			inputHash["str"] = str
			inputHash["age"] = quotationIO.baseDO.getPartyListByRoleCd("PRIMARY")[0].age

			guaranteedValueHash = Hash.new
			nonGuaranteedValueHash = Hash.new
			prdTerm = quotationIO.baseDO.getBasePlan.productTerm.to_i
			(1..prdTerm).each do |policyYear|
				break unless quotationIO.finalMap[policyYear]
				guaranteedValue = (quotationIO.finalMap[policyYear][localElement1][inRate1].to_f/1000).round(2)
				totalValue = (quotationIO.finalMap[policyYear][localElement2][inRate2].to_f/1000).round(2)
				nonGuaranteedValue = totalValue - guaranteedValue
				guaranteedValueHash[policyYear.to_s] = guaranteedValue
				nonGuaranteedValueHash[policyYear.to_s] = nonGuaranteedValue
			end

			inputHash["guaranteedValueHash"] = guaranteedValueHash
			inputHash["nonGuaranteedValueHash"] = nonGuaranteedValueHash
			inputHash["companyColour"] = $rhoconfig[:SunPHComp]

			jsonStr = ::JSON.generate(inputHash)

			imageName = quotationIO.baseDO.quotationRefNum + Random.rand(100000).to_s + ".png"
			fileName = Rho::RhoApplication.get_blob_folder + File::SEPARATOR + imageName
			cmdStr = "javaw -classpath #{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}pdf.jar;"
			cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}flexjson-2.1.jar;"
			cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}jcommon-1.0.21.jar;"
			cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}jfreechart-1.0.17.jar;"
			cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}jfreechart-1.0.17-experimental.jar;"
			cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}jfreechart-1.0.17-swt.jar;"
		cmdStr << " com.c2lbiz.mobisys.win32.StackedBarChartGenerator "
		cmdStr << jsonStr.gsub('"','\"').gsub(' ','$SPACE$')
		cmdStr << " #{fileName}"

		#puts "cmdStr: #{cmdStr}"

		answer = system(cmdStr)

		#puts ">>>answer: #{answer} errorStatus: #{$?}"

		return "<img src=\"#{imageName}\" width=\"75%\"/>"
		else
			rate1 = inRate1
			rate2 = inRate1
			element1 = localElement1
			element2 = localElement2

			maxValue = 0
			value = 0

			age =  quotationIO.baseDO.getPartyListByRoleCd("PRIMARY")[0].age

			facetActionValueChart = ""
			product = quotationIO.baseDO.getBasePlan.getProduct
			barChartFacet = product.getFacet('BARCHART')
	        if barChartFacet != nil 
	          facetActionValueChart = barChartFacet.actionValue.to_s
	        end
			if facetActionValueChart == "YES"
				generateStackedBarChartForGWSP0A(quotationIO , localElement1 , localElement2 , tickUnit, maxRange, inRate1, inRate2, ageCondition)
			else
				printAge = 0
				policyYear = 0

				if(ageCondition != 1)
					if (age <=45)
						policyYear = 50 - age
						printAge = 50
					elsif(age <= 60)
						policyYear = 65 - age
						printAge = 65
					elsif(age <= 65)
						policyYear = 70 - age
						printAge = 70
					elsif(age <= 70)
						policyYear = 75 - age
						printAge = 75
					elsif(age <= 80)
						policyYear = 85 - age
						printAge = 85
					end
				else
					policyYear = 5
					printAge = age + 5
				end

				age_x = []
				finalValue_y = []
				if (quotationIO.baseDO != nil)
					if(quotationIO.baseDO.getBaseProduct != nil)
						counter = 0
						i = policyYear
						while i <= (95-age) do
							innerValue_y = []
							if quotationIO.finalMap[i] == nil    #SUNSS 2425
								i = quotationIO.baseDO.getBaseProduct.productTerm;
							end
							if quotationIO.finalMap[i] != nil
								if (!age_x.include?(printAge))
								age_x << printAge
								guaranteedValue = (quotationIO.finalMap[i][element1][rate1].to_f/1000).round(2)
								totalValue = (quotationIO.finalMap[i][element2][rate1].to_f/1000).round(2)
								nonGuaranteedValue = totalValue - guaranteedValue;
								maxValue = (maxValue > (guaranteedValue+nonGuaranteedValue)) ? maxValue : (guaranteedValue+nonGuaranteedValue);
								if nonGuaranteedValue < 0
									nonGuaranteedValue = 0.0
								end
								innerValue_y << nonGuaranteedValue
								innerValue_y << guaranteedValue
								finalValue_y << innerValue_y
								end
							end
							if quotationIO.baseDO.getBaseProduct.productTerm.to_i < 20 && counter == 2
								printAge = age + quotationIO.baseDO.getBaseProduct.product.getFacetValue("MATURITYAGE").to_i
							else
								printAge = printAge+5;
							end
							# printAge = printAge+5
							i=i+5
				counter = counter+1
							if(counter == 4)
								break
							end
						end
					end
				end

				#puts ">>>maxValue..#{maxValue.inspect}....finalValue_y..#{finalValue_y}....age_x....#{age_x}"
				renderer = ""
		  		companyColour = $rhoconfig[:SunPHComp]

				if companyColour == "SLGFI"
					renderer << "'rgb(34,85,164)'"
				elsif companyColour == "SLOCPI"
				    if str=='NOTAPPLICABLE'
					renderer << "'rgb(84,110,49)'"
					else
				   	renderer << "'rgb(84, 130, 171)'"

				  end

				end
				renderer << "'rgb(250,182,41)'"
				renderer = renderer.gsub(")''",")','")

				keyRenderer=""
				keyRenderer << "'rgb(250,182,41)'"
				if companyColour == "SLGFI"
					keyRenderer << "'rgb(34,85,164)'"
				elsif companyColour == "SLOCPI"
				   if str=='NOTAPPLICABLE'
					keyRenderer << "'rgb(84,110,49)'"
				   else
				   	keyRenderer << "'rgb(84, 130, 171)'"

				  end

				end

				keyRenderer = keyRenderer.gsub(")''",")','")

				maxRange = 0
		        divisionUnit =  1000000000
		        divisor = 10
		        while (divisionUnit >= 1) do
		            if(maxValue >= divisionUnit)
		                if(maxValue%divisionUnit == 0)
		                      maxRange = maxValue
		                else
		                      maxRange = (((maxValue / divisionUnit).to_i) + 1) * divisionUnit
		                end
		                break
		            end
		            divisionUnit = divisionUnit/divisor
		        end
		        tickUnitWholeNumber = maxRange/4
				while((maxRange % 4) != 0) do
		          	maxRange = maxRange + divisionUnit
		            tickUnitWholeNumber = maxRange/4
		        end
		        ySpecificLabels = [0]
		        dec='.'
	    		sep=','
		        (1..4).each do |i|
		        	ySpecificLabels << (tickUnitWholeNumber * i).to_s.reverse.scan(/\d{3}|.+/).join(",").reverse
		        end
		        ySpecificLabels = ySpecificLabels.reverse
		       	#p "tickUnitWholeNumber===>#{tickUnitWholeNumber} #{maxRange}"

				divName = Random.rand(2500000).to_s + "_rGraph"
				canName = 'myCanvas_'+Random.rand(2500000).to_s
				htmlStr = ""
				$graphHtmlCounter = $graphHtmlCounter+1
	            placeHolder = "$graphHtml_#{$graphHtmlCounter}$"
				if quotationIO.offlinePDFGeneration.to_s != "true"
					htmlStr = "<html>"
	                htmlStr << "<script type='text/javascript' src='jquery-3.7.1.min.js'></script>"
	                htmlStr << "<script type='text/javascript' src='RGraph.bar.js'></script>"
	                htmlStr << "<script type='text/javascript' src='RGraph.line.js'></script>"
	                htmlStr << "<script type='text/javascript' src='RGraph.common.core.js'></script>"
	                htmlStr << "<script type='text/javascript' src='RGraph.pie.js'></script>"
	                htmlStr << "<script type='text/javascript' src='RGraph.common.key.js'></script>"
	                htmlStr << "<div name=\"mainWrapper\" id=\"#{placeHolder}\">"
	                htmlStr << "<img name='graph_png' src =\"\">"
	            end
				htmlStr << "<div  style =\"background-color: rgb(255,235,191);height:150px\">"
				# htmlStr << "<script type=\"text/javascript\">$('div[name=\"#{divName}\"]').html('<div class=\"graphWrapper\" style = \"height:'+ $(document).width() * 0.11 +'px\">');</script>"
				htmlStr << "<div name=\"#{divName}\" style =\"width:50%;\">"
				htmlStr << "</div>"
				htmlStr << "</div>"
				htmlStr << "</div>"
				htmlStr << "</div>" if quotationIO.offlinePDFGeneration.to_s != "true"
				htmlStr << "<script type=\"text/javascript\">"
				htmlStr << "$(document).ready(function(){"
				htmlStr << "$('div[name=\"#{divName}\"]').css(\"margin-left\", $(document).width() * 0.01 + \"px\");"
				htmlStr << "$('div[name=\"#{divName}\"]').html(\"<canvas id='#{canName}' name='#{canName}' width='\"+ $(document).width() * 0.24 +\"px' height='\"+ $(document).width() * 0.155 +\"px'>[No canvas support]</canvas>\");"
				htmlStr << "$('div[name=\"#{divName}\"]').trigger('create');"
				htmlStr << "myGraph = new RGraph.Bar('#{canName}', #{finalValue_y});"
				htmlStr << "myGraph.Set('chart.xaxis.labels', #{age_x});"
				htmlStr << "myGraph.Set('chart.xaxis.title','AGE');"
				htmlStr << "myGraph.Set('chart.yaxis.title','THOUSANDS');"
				#htmlStr << "myGraph.Set('chart.hmargin',9);"
				htmlStr << "myGraph.Set('chart.xaxis.title.size',7);"
				htmlStr << "myGraph.Set('chart.xaxis.title.font','Arial');"
	            #htmlStr << "myGraph.Set('chart.xaxis.title.bold', true);"
	            #htmlStr << "myGraph.Set('chart.xaxis.labels.bold', true);"
				htmlStr << "myGraph.Set('chart.xaxis.labels.size', 6);"
				htmlStr << "myGraph.Set('chart.xaxis.labels.font', 'Arial');"
				htmlStr << "myGraph.Set('chart.xaxis.tickmarks.last', false);"
				htmlStr << "myGraph.Set('chart.xaxis.tickmarks.count', 0);"
				htmlStr << "myGraph.Set('chart.margin.left', 60);"
				htmlStr << "myGraph.Set('chart.margin.right', 20);"
				htmlStr << "myGraph.Set('chart.margin.bottom', 85);"
				htmlStr << "myGraph.Set('chart.margin.top', 25);"
				htmlStr << "myGraph.Set('chart.yaxis',false);"
				htmlStr << "myGraph.Set('chart.yaxis.title.pos',0.17);"
				htmlStr << "myGraph.Set('chart.yaxis.title.size',7);"
				htmlStr << "myGraph.Set('chart.yaxis.title.font','Arial');"
	            #htmlStr << "myGraph.Set('chart.yaxis.title.bold', true);"
				htmlStr << "myGraph.Set('chart.yaxis.scale.max',#{maxRange});"
			  	htmlStr << "myGraph.Set('chart.yaxis.labels.count', 4);"
	            #htmlStr << "myGraph.Set('chart.yaxis.labels.bold', true);"
			  	htmlStr << "myGraph.Set('chart.yaxis.labels.size', 6);"
			  	htmlStr << "myGraph.Set('chart.yaxis.labels.font', 'Arial');"
			  	htmlStr << "myGraph.Set('chart.yaxis.labels.specific',#{ySpecificLabels});"
			  	htmlStr << "myGraph.Set('chart.yaxis.tickmarks.count', 4);"
			  	htmlStr << "myGraph.Set('chart.background.grid.hlines.count',4);"
				htmlStr << "myGraph.Set('chart.colors', [#{renderer}]);"
				htmlStr << "myGraph.Set('chart.grouping','stacked');"
				htmlStr << "myGraph.Set('chart.background.grid.color','rgb(0,0,0)');"
				htmlStr << "myGraph.Set('chart.background.grid.border',false);"
				htmlStr << "myGraph.Set('chart.background.grid.width','4');"
				htmlStr << "myGraph.Set('chart.background.grid.autofit',true);"
				htmlStr << "myGraph.Set('chart.background.grid.autofit.numhlines','4');"
				htmlStr << "myGraph.Set('chart.background.grid.vlines', false);"
				htmlStr << "myGraph.Set('chart.background.grid.linewidth', 1);"
				htmlStr << "myGraph.Set('chart.key', ['GUARANTEED','NON-GUARANTEED']);"
				htmlStr << "myGraph.Set('chart.key.colors', [#{keyRenderer}]);"
				htmlStr << "myGraph.Set('chart.key.position', 'margin');"
				htmlStr << "myGraph.Set('chart.key.labels.size', 7);"
				htmlStr << "myGraph.Set('chart.key.labels.font', 'Arial');"
	            #htmlStr << "myGraph.Set('chart.key.labels.bold', true);"
				htmlStr << "myGraph.Set('chart.key.labels.offsety', 0);"
				htmlStr << "myGraph.Set('chart.key.position.y',$(document).width() * 0.120);"
				htmlStr << "myGraph.Set('chart.key.position.x',$(document).width() * 0.02);"
		  		# htmlStr << "myGraph.Set('chart.key.position.x',0);"
	            #htmlStr << "myGraph.Set('chart.key.background', 'rgba(255,255,255,0.7)');"
				htmlStr << "myGraph.Set('chart.key.position.margin.boxed', true);"
				htmlStr << "myGraph.Set('chart.key.halign', 'bottom');"
				htmlStr << "myGraph.Set('chart.text.accessible', false);"
				htmlStr << "myGraph.Set('chart.backgroundColor','rgb(255,235,191)');"
				htmlStr << "myGraph.Set('noyaxis', true);"
				htmlStr << "myGraph.Draw();"
				htmlStr << "RGraph.Register(myGraph);"
				if quotationIO.offlinePDFGeneration.to_s != "true"
					htmlStr << "image_data = myGraph.canvas.toDataURL('image/png');"
	                htmlStr << "$('img[name=\"graph_png\"').attr('src',image_data);"
	                htmlStr << "imageElement = $(\"img[name='graph_png']\");"
	                htmlStr << "$(\"canvas\").replaceWith(imageElement);"
	            end
				htmlStr << "});"
				htmlStr << "</script>"
				if quotationIO.offlinePDFGeneration.to_s != "true"
					htmlStr << "</html>"
	                $graphHtmlHM[placeHolder] = htmlStr
	                return placeHolder
	            else
	            	return htmlStr
	            end
			end
		end
	  end	
	end

	def self.getBankPartnerOutputdetails(quotationIO,mvelHashMap)
		tripTypeCd = quotationIO.baseDO.tripTypeCd.to_s
		tripTypeCdDesc = ""
		bankPartnerStaticText= MobiSys::UIGenUtilHelper.getLabelValue('BANKPARTNERTEXT',"EN")
		bankPartnerText = ""
		bankPartnerLookUpData = MobiSys::UIGenUtilHelper.getLookupValue("BANKPARTNERTEXT", tripTypeCd)
		if(mvelHashMap["agentDO"].to_s != "" && mvelHashMap["agentDO"].channel.to_s != "" && mvelHashMap["agentDO"].channel.to_s == "BANCA" && quotationIO.baseDO.tripTypeCd.to_s != "" && quotationIO.baseDO.tripTypeCd.to_s != "NONBANK")
			bankPartnerText= "#{bankPartnerStaticText}#{bankPartnerLookUpData}."
		end
		return bankPartnerText
	end
	def self.generateSLGFIStackedBarChart(quotationIO , localElement1 , localElement2 , tickUnit, maxRange, inRate1, inRate2, ageCondition,str="NOTAPPLICABLE")
		# puts "generateStackedBarChart------------str111111------>#{str}"
		if $showPdf == true
			inputHash = Hash.new
			inputHash["tickUnit"] = tickUnit
			inputHash["maxRange"] = maxRange
			inputHash["ageCondition"] = ageCondition
			inputHash["str"] = str
			inputHash["age"] = quotationIO.baseDO.getPartyListByRoleCd("PRIMARY")[0].age

			guaranteedValueHash = Hash.new
			nonGuaranteedValueHash = Hash.new
			prdTerm = quotationIO.baseDO.getBasePlan.productTerm.to_i
			(1..prdTerm).each do |policyYear|
				break unless quotationIO.finalMap[policyYear]
				guaranteedValue = (quotationIO.finalMap[policyYear][localElement1][inRate1].to_f/1000).round(2)
				totalValue = (quotationIO.finalMap[policyYear][localElement2][inRate2].to_f/1000).round(2)
				nonGuaranteedValue = totalValue - guaranteedValue
				guaranteedValueHash[policyYear.to_s] = guaranteedValue
				nonGuaranteedValueHash[policyYear.to_s] = nonGuaranteedValue
			end

			inputHash["guaranteedValueHash"] = guaranteedValueHash
			inputHash["nonGuaranteedValueHash"] = nonGuaranteedValueHash
			inputHash["companyColour"] = $rhoconfig[:SunPHComp]

			jsonStr = ::JSON.generate(inputHash)

			imageName = quotationIO.baseDO.quotationRefNum + Random.rand(100000).to_s + ".png"
			fileName = Rho::RhoApplication.get_blob_folder + File::SEPARATOR + imageName
			cmdStr = "javaw -classpath #{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}pdf.jar;"
			cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}flexjson-2.1.jar;"
			cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}jcommon-1.0.21.jar;"
			cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}jfreechart-1.0.17.jar;"
			cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}jfreechart-1.0.17-experimental.jar;"
			cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}jfreechart-1.0.17-swt.jar;"
		cmdStr << " com.c2lbiz.mobisys.win32.StackedBarChartGenerator "
		cmdStr << jsonStr.gsub('"','\"').gsub(' ','$SPACE$')
		cmdStr << " #{fileName}"

		#puts "cmdStr: #{cmdStr}"

		answer = system(cmdStr)

		#puts ">>>answer: #{answer} errorStatus: #{$?}"

		return "<img src=\"#{imageName}\" width=\"75%\"/>"
		else
			rate1 = inRate1
			rate2 = inRate1
			element1 = localElement1
			element2 = localElement2

			maxValue = 0
			value = 0

			age =  quotationIO.baseDO.getPartyListByRoleCd("PRIMARY")[0].age
		facetActionValueChart = ""
		product = quotationIO.baseDO.getBasePlan.getProduct
		barChartFacet = product.getFacet('BARCHART')
	        if barChartFacet != nil 
	          facetActionValueChart = barChartFacet.actionValue.to_s
	        end
		if facetActionValueChart == "YES"
			generateStackedBarChartForGWSP0A(quotationIO , localElement1 , localElement2 , tickUnit, maxRange, inRate1, inRate2, ageCondition)
		else
			printAge = 0
			policyYear = 0

			if(ageCondition != 1)
				if (age <=45)
					policyYear = 50 - age
					printAge = 50
				elsif(age <= 60)
					policyYear = 65 - age
					printAge = 65
				elsif(age <= 65)
					policyYear = 70 - age
					printAge = 70
				elsif(age <= 70)
					policyYear = 75 - age
					printAge = 75
				elsif(age <= 80)
					policyYear = 85 - age
					printAge = 85
				end
			else
				policyYear = 5
				printAge = age + 5
			end

			age_x = []
			finalValue_y = []
			if (quotationIO.baseDO != nil)
				if(quotationIO.baseDO.getBaseProduct != nil)
					counter = 0
					i = policyYear
					while i <= (95-age) do
						innerValue_y = []
						if quotationIO.finalMap[i] != nil
						age_x << printAge
						guaranteedValue = (quotationIO.finalMap[i][element1][rate1].to_f/1000).round(2)
						totalValue = (quotationIO.finalMap[i][element2][rate1].to_f/1000).round(2)
						nonGuaranteedValue = totalValue - guaranteedValue;
						maxValue = (maxValue > (guaranteedValue+nonGuaranteedValue)) ? maxValue : (guaranteedValue+nonGuaranteedValue);
						if nonGuaranteedValue < 0
							nonGuaranteedValue = 0.0
						end
						innerValue_y << nonGuaranteedValue
						innerValue_y << guaranteedValue
						finalValue_y << innerValue_y
						end
						printAge = printAge+5
						i=i+5
			counter = counter+1
						if(counter == 4)
							break
						end
					end
				end
			end

			#puts ">>>maxValue..#{maxValue.inspect}....finalValue_y..#{finalValue_y}....age_x....#{age_x}"
			renderer = ""
	  		companyColour = $rhoconfig[:SunPHComp]

			if companyColour == "SLGFI"
				renderer << "'rgb(34,85,164)'"
			elsif companyColour == "SLOCPI"
			    if str=='NOTAPPLICABLE'
				renderer << "'rgb(84,110,49)'"
				else
			   	renderer << "'rgb(84, 130, 171)'"

			  end

			end
			renderer << "'rgb(250,182,41)'"
			renderer = renderer.gsub(")''",")','")

			keyRenderer=""
			keyRenderer << "'rgb(250,182,41)'"
			if companyColour == "SLGFI"
				keyRenderer << "'rgb(34,85,164)'"
			elsif companyColour == "SLOCPI"
			   if str=='NOTAPPLICABLE'
				keyRenderer << "'rgb(84,110,49)'"
			   else
			   	keyRenderer << "'rgb(84, 130, 171)'"

			  end

			end

			keyRenderer = keyRenderer.gsub(")''",")','")

			maxRange = 0
	        divisionUnit =  1000000000
	        divisor = 10
	        while (divisionUnit >= 1) do
	            if(maxValue >= divisionUnit)
	                if(maxValue%divisionUnit == 0)
	                      maxRange = maxValue
	                else
	                      maxRange = (((maxValue / divisionUnit).to_i) + 1) * divisionUnit
	                end
	                break
	            end
	            divisionUnit = divisionUnit/divisor
	        end
	        tickUnitWholeNumber = maxRange/4
			while((maxRange % 4) != 0) do
	          	maxRange = maxRange + divisionUnit
	            tickUnitWholeNumber = maxRange/4
	        end
	        ySpecificLabels = [0]
	        dec='.'
    		sep=','
	        (1..4).each do |i|
	        	ySpecificLabels << (tickUnitWholeNumber * i).to_s.reverse.scan(/\d{3}|.+/).join(",").reverse
	        end
	        ySpecificLabels = ySpecificLabels.reverse
	       	#p "tickUnitWholeNumber===>#{tickUnitWholeNumber} #{maxRange}"

	       	grapheight = 0.160
	        height = 130
	        wrapper = 0.08
	        yaxis = 0.112
			if quotationIO.baseDO.getBaseProduct.productId.to_s == "PWHP0A" || quotationIO.baseDO.getBaseProduct.productId.to_s == "PWGP0A" || quotationIO.baseDO.getBaseProduct.productId.to_s == "PWIP0A" 
				#p"inside the product condition============="
				grapheight = 0.150
				height = 130
				wrapper = 0.6
				yaxis = 0.115
			end
			$graphHtmlCounter = $graphHtmlCounter+1
            placeHolder = "$graphHtml_#{$graphHtmlCounter}$"
			divName = Random.rand(2500000).to_s + "_rGraph"
			canName = 'myCanvas_'+Random.rand(2500000).to_s
			htmlStr = ""
            if quotationIO.offlinePDFGeneration.to_s != "true"
                htmlStr = "<html>"
                htmlStr << "<script type='text/javascript' src='jquery-3.7.1.min.js'></script>"
                htmlStr << "<script type='text/javascript' src='RGraph.bar.js'></script>"
                htmlStr << "<script type='text/javascript' src='RGraph.line.js'></script>"
                htmlStr << "<script type='text/javascript' src='RGraph.common.core.js'></script>"
                htmlStr << "<script type='text/javascript' src='RGraph.pie.js'></script>"
                htmlStr << "<script type='text/javascript' src='RGraph.common.key.js'></script>"
                htmlStr << "<div name=\"mainWrapper\" id=\"#{placeHolder}\">"
                htmlStr << "<img name='graph_png' src =\"\">"
            end
			htmlStr << "<div  style =\"background-color: rgb(255,235,191);height:#{height}px\">"
			# htmlStr << "<script type=\"text/javascript\">$('div[name=\"#{divName}\"]').html('<div class=\"graphWrapper\" style = \"height:'+ $(document).width() * #{wrapper} +'px\">');</script>"
			htmlStr << "<div name=\"#{divName}\" style =\"width:50%;\">"
			htmlStr << "</div>"
			htmlStr << "</div>"
			htmlStr << "</div>"
			htmlStr << "</div>" if quotationIO.offlinePDFGeneration.to_s != "true"
			htmlStr << "<script type=\"text/javascript\">"
			htmlStr << "$(document).ready(function(){"
			htmlStr << "$('div[name=\"#{divName}\"]').css(\"margin-left\", $(document).width() * 0.017 + \"px\");"
			htmlStr << "$('div[name=\"#{divName}\"]').html(\"<canvas id='#{canName}' name='#{canName}' width='\"+ $(document).width() * 0.21 +\"px' height='\"+ $(document).width() * #{grapheight} +\"px'>[No canvas support]</canvas>\");"
			htmlStr << "$('div[name=\"#{divName}\"]').trigger('create');"
			htmlStr << "myGraph = new RGraph.Bar('#{canName}', #{finalValue_y});"
			htmlStr << "myGraph.Set('chart.xaxis.labels', #{age_x});"
			htmlStr << "myGraph.Set('chart.xaxis.title','AGE');"
			htmlStr << "myGraph.Set('chart.yaxis.title','THOUSANDS');"
			#htmlStr << "myGraph.Set('chart.hmargin',9);"
			htmlStr << "myGraph.Set('chart.xaxis.title.size',6);"
			htmlStr << "myGraph.Set('chart.xaxis.title.font','Arial');"
            #htmlStr << "myGraph.Set('chart.xaxis.title.bold', true);"
            #htmlStr << "myGraph.Set('chart.xaxis.labels.bold', true);"
			htmlStr << "myGraph.Set('chart.xaxis.labels.size', 6);"
			htmlStr << "myGraph.Set('chart.xaxis.labels.font', 'Arial');"
			htmlStr << "myGraph.Set('chart.xaxis.tickmarks.last', false);"
			htmlStr << "myGraph.Set('chart.xaxis.tickmarks.count', 0);"
			htmlStr << "myGraph.Set('chart.margin.left', 60);"
			htmlStr << "myGraph.Set('chart.margin.right', 20);"
			htmlStr << "myGraph.Set('chart.margin.bottom', 80);"
			htmlStr << "myGraph.Set('chart.margin.top', 25);"
			htmlStr << "myGraph.Set('chart.yaxis',false);"
			htmlStr << "myGraph.Set('chart.xaxis.title.pos',0.8);"
			htmlStr << "myGraph.Set('chart.yaxis.title.pos',0.18);"
			htmlStr << "myGraph.Set('chart.yaxis.title.size',6);"
			htmlStr << "myGraph.Set('chart.yaxis.title.font','Arial');"
            #htmlStr << "myGraph.Set('chart.yaxis.title.bold', true);"
			htmlStr << "myGraph.Set('chart.yaxis.scale.max',#{maxRange});"
		  	htmlStr << "myGraph.Set('chart.yaxis.labels.count', 4);"
            #htmlStr << "myGraph.Set('chart.yaxis.labels.bold', true);"
		  	htmlStr << "myGraph.Set('chart.yaxis.labels.size', 6);"
		  	htmlStr << "myGraph.Set('chart.yaxis.labels.font', 'Arial');"
		  	htmlStr << "myGraph.Set('chart.yaxis.labels.specific',#{ySpecificLabels});"
		  	htmlStr << "myGraph.Set('chart.yaxis.tickmarks.count', 4);"
		  	htmlStr << "myGraph.Set('chart.background.grid.hlines.count',4);"
			htmlStr << "myGraph.Set('chart.colors', [#{renderer}]);"
			htmlStr << "myGraph.Set('chart.grouping','stacked');"
			htmlStr << "myGraph.Set('chart.background.grid.color','rgb(0,0,0)');"
			htmlStr << "myGraph.Set('chart.background.grid.border',false);"
			htmlStr << "myGraph.Set('chart.background.grid.width','4');"
			htmlStr << "myGraph.Set('chart.background.grid.autofit',true);"
			htmlStr << "myGraph.Set('chart.background.grid.autofit.numhlines','4');"
			htmlStr << "myGraph.Set('chart.background.grid.vlines', false);"
			htmlStr << "myGraph.Set('chart.background.grid.linewidth', 1);"
			htmlStr << "myGraph.Set('chart.key', ['GUARANTEED','NON-GUARANTEED']);"
			htmlStr << "myGraph.Set('chart.key.colors', [#{keyRenderer}]);"
			htmlStr << "myGraph.Set('chart.key.position', 'margin');"
			htmlStr << "myGraph.Set('chart.key.labels.size', 6);"
			htmlStr << "myGraph.Set('chart.key.labels.font', 'Arial');"
            #htmlStr << "myGraph.Set('chart.key.labels.bold', true);"
			htmlStr << "myGraph.Set('chart.key.labels.offsety', 0);"
			htmlStr << "myGraph.Set('chart.key.position.y',$(document).width() * #{yaxis});"
	  		htmlStr << "myGraph.Set('chart.key.position.x',0);"
            #htmlStr << "myGraph.Set('chart.key.background', 'rgba(255,255,255,0.7)');"
			htmlStr << "myGraph.Set('chart.key.position.margin.boxed', true);"
			htmlStr << "myGraph.Set('chart.key.halign', 'bottom');"
			htmlStr << "myGraph.Set('chart.text.accessible', false);"
			htmlStr << "myGraph.Set('chart.backgroundColor','rgb(255,235,191)');"
			htmlStr << "myGraph.Set('noyaxis', true);"
			htmlStr << "myGraph.Draw();"
			htmlStr << "RGraph.Register(myGraph);"
			if quotationIO.offlinePDFGeneration.to_s != "true"
                htmlStr << "image_data = myGraph.canvas.toDataURL('image/png');"
                htmlStr << "$('img[name=\"graph_png\"').attr('src',image_data);"
                htmlStr << "imageElement = $(\"img[name='graph_png']\");"
                htmlStr << "$(\"canvas\").replaceWith(imageElement);"
            end
			htmlStr << "});"
			htmlStr << "</script>"
			if quotationIO.offlinePDFGeneration.to_s != "true"
                htmlStr << "</html>"
                $graphHtmlHM[placeHolder] = htmlStr
                return placeHolder
            else
                return htmlStr
            end
		end
	    end
	end

	def self.generateStackedBarChartForGWSP0A(quotationIO , localElement1 , localElement2 , tickUnit, maxRange, inRate1, inRate2, ageCondition)
		# p "in generateStackedBarChartForGWSP0A"
		if $showPdf == true
				inputHash = Hash.new
				inputHash["tickUnit"] = tickUnit
				inputHash["maxRange"] = maxRange
				inputHash["ageCondition"] = ageCondition
				inputHash["age"] = quotationIO.baseDO.getPartyListByRoleCd("PRIMARY")[0].age
				product = quotationIO.baseDO.getBasePlan.getProduct
				inputHash["productId"] = product.productId.to_s
				guaranteedValueHash = Hash.new
				nonGuaranteedValueHash = Hash.new
				prdTerm = quotationIO.baseDO.getBasePlan.productTerm.to_i
				(4..7).each do |policyYear|
					break unless quotationIO.finalMap[policyYear]
					guaranteedValue = (quotationIO.finalMap[policyYear][localElement1][inRate1].to_f/1000).round(2)
					totalValue = (quotationIO.finalMap[policyYear][localElement2][inRate2].to_f/1000).round(2)
					nonGuaranteedValue = totalValue - guaranteedValue
					guaranteedValueHash[policyYear.to_s] = guaranteedValue
					nonGuaranteedValueHash[policyYear.to_s] = nonGuaranteedValue
				end

				inputHash["guaranteedValueHash"] = guaranteedValueHash
				inputHash["nonGuaranteedValueHash"] = nonGuaranteedValueHash
				inputHash["companyColour"] = Rho::RhoConfig.SunPHComp

				jsonStr = ::JSON.generate(inputHash)
				# p "jsonStr===>#{jsonStr}"

				imageName = quotationIO.baseDO.quotationRefNum + Random.rand(100000).to_s + ".png"
				fileName = Rho::RhoApplication.get_blob_folder + File::SEPARATOR + imageName
				cmdStr = "javaw -classpath #{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}pdf.jar;"
				cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}flexjson-2.1.jar;"
				cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}jcommon-1.0.21.jar;"
				cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}jfreechart-1.0.17.jar;"
				cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}jfreechart-1.0.17-experimental.jar;"
				cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}jfreechart-1.0.17-swt.jar;"
				cmdStr << " com.c2lbiz.mobisys.win32.StackedBarChartGenerator "
				cmdStr << jsonStr.gsub('"','\"').gsub(' ','$SPACE$')
				cmdStr << " #{fileName}"

				puts "cmdStr: #{cmdStr}"
				  
				answer = system(cmdStr)

				#puts ">>>answer: #{answer} errorStatus: #{$?}"

				return "<img src=\"#{imageName}\" width=\"100%\"/>"
		else
			maxValue = 0
			printYear = 4
			rate1 = inRate1
			rate2 = inRate1
			element1 = localElement1
			element2 = localElement2
			age = quotationIO.baseDO.getPartyListByRoleCd("PRIMARY")[0].age
			age_x = []
			finalValue_y = []
			if(ageCondition != 1)
				if (age <=45)
					policyYear = 50 - age
					printAge = 50
				elsif(age <= 60)
					policyYear = 65 - age
					printAge = 65
				elsif(age <= 65)
					policyYear = 70 - age
					printAge = 70
				elsif(age <= 70)
					policyYear = 75 - age
					printAge = 75
				elsif(age <= 80)
					policyYear = 85 - age
					printAge = 85
				end
			else
				policyYear = 4
				printAge = age + 1
			end
			if (quotationIO.baseDO != nil)
				if(quotationIO.baseDO.getBaseProduct != nil)
					counter = 0
					i = printYear
					while i <= 7 do
						innerValue_y = []
						age_x << i
						guaranteedValue = (quotationIO.finalMap[i][element1][rate1].to_f/1000).round(2)
						totalValue = (quotationIO.finalMap[i][element2][rate1].to_f/1000).round(2)
						nonGuaranteedValue = totalValue - guaranteedValue;
						maxValue = (maxValue > (guaranteedValue+nonGuaranteedValue)) ? maxValue : (guaranteedValue+nonGuaranteedValue);
						if nonGuaranteedValue < 0
							nonGuaranteedValue = 0.0
						end
						# innerValue_y << nonGuaranteedValue 
						innerValue_y << guaranteedValue
						finalValue_y << innerValue_y
						# printAge = printAge+5
						i=i+1
						counter = counter+1
					end
				end
			end
			# p "in generateStackedBarChartForGWSP0A===>finalValue_y===>#{finalValue_y}===>age_x===>#{age_x}"
			renderer = ""
	  		companyColour = Rho::RhoConfig.SunPHComp
	  
			if companyColour == "SLGFI"
				renderer << "'rgb(34,85,164)'"
			elsif companyColour == "SLOCPI"
				renderer << "'rgb(84,110,49)'"
			end
			renderer << "'rgb(250,182,41)'"
			renderer = renderer.gsub(")''",")','")

			keyRenderer=""
			keyRenderer << "'rgb(250,182,41)'"
			if companyColour == "SLGFI"
				keyRenderer << "'rgb(34,85,164)'"
			elsif companyColour == "SLOCPI"
				keyRenderer << "'rgb(84,110,49)'"
			end
			
			keyRenderer = keyRenderer.gsub(")''",")','")

			#Below Code written for bar chart same as online 27092022
			maxRange = 0
		        divisionUnit =  1000000000
		        divisor = 10
		        while (divisionUnit >= 1) do
		            if(maxValue >= divisionUnit)
		                if(maxValue%divisionUnit == 0)
		                      maxRange = maxValue
		                else
		                      maxRange = (((maxValue / divisionUnit).to_i) + 1) * divisionUnit
		                end
		                break
		            end
		            divisionUnit = divisionUnit/divisor
		        end
		        tickUnitWholeNumber = maxRange/4
				while((maxRange % 4) != 0) do
		          	maxRange = maxRange + divisionUnit
		            tickUnitWholeNumber = maxRange/4
		        end
		        ySpecificLabels = [0]
		        dec='.'
	    		sep=','
		        (1..4).each do |i|
		        	ySpecificLabels << (tickUnitWholeNumber * i).to_s.reverse.scan(/\d{3}|.+/).join(",").reverse
		        end
		        ySpecificLabels = ySpecificLabels.reverse

			divName = Random.rand(2500000).to_s + "_rGraph"
			canName = 'myCanvas_'+Random.rand(2500000).to_s
			htmlStr = ""
			$graphHtmlCounter = $graphHtmlCounter+1
		    placeHolder = "$graphHtml_#{$graphHtmlCounter}$"
			if quotationIO.offlinePDFGeneration.to_s != "true"
				htmlStr = "<html>"
		        htmlStr << "<script type='text/javascript' src='jquery-3.7.1.min.js'></script>"
		        htmlStr << "<script type='text/javascript' src='RGraph.bar.js'></script>"
		        htmlStr << "<script type='text/javascript' src='RGraph.line.js'></script>"
		        htmlStr << "<script type='text/javascript' src='RGraph.common.core.js'></script>"
		        htmlStr << "<script type='text/javascript' src='RGraph.pie.js'></script>"
		        htmlStr << "<script type='text/javascript' src='RGraph.common.key.js'></script>"
		        htmlStr << "<div name=\"mainWrapper\" id=\"#{placeHolder}\">"
		        htmlStr << "<img name='graph_png' src =\"\">"
		    end
			htmlStr << "<div  style =\"background-color: rgb(255,235,191);height:138px;\">"
			# htmlStr << "<script type=\"text/javascript\">$('div[name=\"#{divName}\"]').html('<div class=\"graphWrapper\" style = \"height:'+ $(document).width() * 0.2 +'px\">');</script>"
			htmlStr << "<div name=\"#{divName}\" style =\"width:50%;\">"
			htmlStr << "</div>"
			htmlStr << "</div>"
			htmlStr << "</div>"
			htmlStr << "</div>" if quotationIO.offlinePDFGeneration.to_s != "true"
			htmlStr << "<script type=\"text/javascript\">"
			htmlStr << "$(document).ready(function(){"
			htmlStr << "$('div[name=\"#{divName}\"]').css(\"margin-left\", $(document).width() * 0.008 + \"px\");"
			htmlStr << "$('div[name=\"#{divName}\"]').html(\"<canvas id='#{canName}' name='#{canName}' width='\"+ $(document).width() * 0.225 +\"px' height='\"+ $(document).width() * 0.11 +\"px'>[No canvas support]</canvas>\");"
			htmlStr << "$('div[name=\"#{divName}\"]').trigger('create');"
			htmlStr << "myGraph = new RGraph.Bar('#{canName}', #{finalValue_y});"
			#htmlStr << "myGraph.Set('chart.labels.self', #{age_x});"
			htmlStr << "myGraph.Set('chart.pieLabelset', #{age_x});"
			# htmlStr << "myGraph.Set('chart.labels', #{age_x});"
			htmlStr << "myGraph.Set('chart.xaxis.labels', #{age_x});"
			#htmlStr << "myGraph.Set('chart.labels.above', true);"
			# htmlStr << "myGraph.Set('chart.title.xaxis','YEAR');"
			htmlStr << "myGraph.Set('chart.xaxis.title','YEAR');"
			htmlStr << "myGraph.Set('chart.yaxis.title','THOUSANDS');"
			htmlStr << "myGraph.Set('chart.yaxis.title.size',7.0);"
			htmlStr << "myGraph.Set('chart.yaxis.title.font','Arial');"
			htmlStr << "myGraph.Set('chart.xaxis.title.size',7.0);"
			htmlStr << "myGraph.Set('chart.xaxis.title.font','Arial');"
			htmlStr << "myGraph.Set('chart.margin.left', 50);"
			htmlStr << "myGraph.Set('chart.margin.bottom', 45);"
			htmlStr << "myGraph.Set('chart.margin.top', 15);"
			htmlStr << "myGraph.Set('chart.margin.right', 25);"
			htmlStr << "myGraph.Set('chart.yaxis.title.pos',0.3);"
			htmlStr << "myGraph.Set('chart.xaxis.title.pos',0.4);"
			htmlStr << "myGraph.Set('chart.xaxis.title.valign',top);"
			htmlStr << "myGraph.Set('chart.colors', [#{renderer}]);"
			htmlStr << "myGraph.Set('chart.grouping','stacked');"
			htmlStr << "myGraph.Set('chart.yaxis.scale.max',#{maxRange});"
			htmlStr << "myGraph.Set('chart.yaxis.labels.count', 4);"
			htmlStr << "myGraph.Set('chart.yaxis.labels.specific',#{ySpecificLabels});"
			htmlStr << "myGraph.Set('chart.yaxis.tickmarks.count', 4);"
			htmlStr << "myGraph.Set('chart.background.grid.hlines.count',4);"
			htmlStr << "myGraph.Set('chart.yaxis.labels.count', 5);"
			htmlStr << "myGraph.Set('chart.yaxis.labels.size', 6);"
			htmlStr << "myGraph.Set('chart.yaxis.labels.font', 'Arial');"
			htmlStr << "myGraph.Set('chart.xaxis.labels.size', 6);"
			htmlStr << "myGraph.Set('chart.xaxis.labels.font', 'Arial');"
			htmlStr << "myGraph.Set('chart.background.grid.color','rgb(0,0,0)');"
			htmlStr << "myGraph.Set('chart.background.grid.border',false);"
			htmlStr << "myGraph.Set('chart.background.grid.width','2');"
			htmlStr << "myGraph.Set('chart.background.grid.autofit',true);"
			htmlStr << "myGraph.Set('chart.background.grid.autofit.numhlines','5');"
			htmlStr << "myGraph.Set('chart.background.grid.vlines', false);"
			htmlStr << "myGraph.Set('chart.yaxis',false);"
			htmlStr << "myGraph.Set('chart.xaxis',false);"	
			htmlStr << "myGraph.Set('key.colors', [#{keyRenderer}]);"
			htmlStr << "myGraph.Set('key.position', 'gutter');"
			if (System.get_property('platform') == 'WINDOWS_DESKTOP')
	            htmlStr << "myGraph.Set('key.position.y',375);"
	            htmlStr << "myGraph.Set('key.text.size', 8);"
	        elsif (System.get_property('platform') == 'ANDROID')
				htmlStr << "myGraph.Set('key.position.y',235);"
				htmlStr << "myGraph.Set('key.text.size', 8);"
			else 
				htmlStr << "myGraph.Set('key.position.y',237);"
				htmlStr << "myGraph.Set('key.text.size', 8);"
			end	
		  		htmlStr << "myGraph.Set('key.position.x',12);"
				htmlStr << "myGraph.Set('noendxtick', true);"
				htmlStr << "myGraph.Set('noyaxis', true);"
				htmlStr << "myGraph.Set('chart.text.accessible', false);"
				htmlStr << "myGraph.Set('chart.backgroundColor','rgb(255,235,191)');"
				htmlStr << "myGraph.Draw();"
				htmlStr << "RGraph.Register(myGraph);"
				if quotationIO.offlinePDFGeneration.to_s != "true"
					htmlStr << "image_data = myGraph.canvas.toDataURL('image/png');"
		            htmlStr << "$('img[name=\"graph_png\"').attr('src',image_data);"
		            htmlStr << "imageElement = $(\"img[name='graph_png']\");"
		            htmlStr << "$(\"canvas\").replaceWith(imageElement);"
		        end
				htmlStr << "});"
				htmlStr << "</script>"
				if quotationIO.offlinePDFGeneration.to_s != "true"
					htmlStr << "</html>"
		            $graphHtmlHM[placeHolder] = htmlStr
		            return placeHolder
		        else
		        	return htmlStr
		        end
		end
	end

	def self.getPureMFFAgeListForMD1U0CandML1P0E(mvelHashMap , quotationIO , localElement , tickUnit, maxRange, inRate, colorSelector)
		  age = quotationIO.baseDO.getPartyListByRoleCd("PRIMARY")[0].age
		  print_age = 0
		  policyYear = 0
		  printAge = 0
		  pureMFFAgeList = mvelHashMap["PureMFFAgeList"]
		  age_x = []
		  	product = quotationIO.baseDO.getBasePlan.getProduct

	  		if pureMFFAgeList == nil
				if colorSelector == 1 || colorSelector == 2
					if age <= 75
						policyYear = 80 - age
						printAge = 80
					elsif age <= 80
						policyYear = 85 - age
						printAge = 85
					end
				elsif colorSelector == 3
					if age <= 50
						policyYear = 55 - age
						printAge = 55
					elsif age <= 60
						policyYear = 65 - age
						printAge = 65
					elsif age <= 64
						policyYear = 70 - age
						printAge = 70
					end
				elsif colorSelector == 4 || colorSelector == 5
					policyYear = 4
					printAge = age + 4
				end
			end
			# PureMFF block 1 end
			if (quotationIO.baseDO != nil && pureMFFAgeList == nil)
				if(quotationIO.baseDO.getBaseProduct != nil)
					counter = 0
					# PureMFF block 2 start
					if(colorSelector != 4 && colorSelector != 5)
						i = policyYear
						while i<=(90-age) do
							#for (int i = policyYear;i<=(90-age);i=i+3)
							if localElement.to_s == "ONLYFACEAMOUNT"
								age_x << printAge.to_s
							else
								if(quotationIO.finalMap[i] != nil)
									age_x << printAge.to_s
								end
							end
							printAge = printAge+3
							counter = counter + 1
							if(colorSelector != 3)
								if(counter == 4)
									break
								end
							else
								if(printAge == 75)
									printAge = printAge - 1
								end
								if(printAge > 75)
									break
								end
							end
							i=i+3
						end
					else
						i = policyYear
						while i<policyYear+4 do
							#for (int i = policyYear;i<policyYear+4;i++)
							age_x << printAge.to_s# dataset.setValue(value, "GUARANTEED", String.valueOf(printAge))
							printAge = printAge + 1
							counter = counter + 1
							i = i + 1
						end
					end
					# PureMFF block 2 end
				end
			end

		 return age_x
	end

	def self.generateBarChart(mvelHashMap , quotationIO , localElement , tickUnit, maxRange, inRate, colorSelector)
		#puts ">>>inside generateBarChart platform: #{System.get_property('platform')} localElement: #{localElement} inRate: #{inRate}"
	  companyColour = OfflineApplication.find(:first, :conditions =>{{:name =>'PROPERTY'} =>'COMPANYCOLOUR'})
	  if companyColour != nil && companyColour.value == "SLGFI"	
	  	generateSLGFIBarChart(mvelHashMap , quotationIO , localElement , tickUnit, maxRange, inRate, colorSelector)
	  else	
		if $showPdf == true
				inputHash = Hash.new
				inputHash["age"] = quotationIO.baseDO.getPartyByRole("PRIMARY").age.to_i
				inputHash["colorSelector"] = colorSelector
				inputHash["tickUnit"] = tickUnit
				pureMFFAgeList = mvelHashMap["PureMFFAgeList"]

				product = quotationIO.baseDO.getBasePlan.getProduct
			  	barGraphFacet = product.getFacet('BARGRAPH')
		        if barGraphFacet != nil
		          facetActionValue = barGraphFacet.actionValue
		        end

				if pureMFFAgeList != nil
					inputHash["PureMFFAgeList"] = mvelHashMap["PureMFFAgeList"]
				elsif facetActionValue == "YES"
					# var = []
					pureMFFAgeListVal = getPureMFFAgeListForMD1U0CandML1P0E(mvelHashMap , quotationIO , localElement , tickUnit, maxRange, inRate, colorSelector)
					# x = Hash[(1...var.size+1).zip var]
					# p "+++++++++++++++x: #{x}"
					inputHash["PureMFFAgeList"] = pureMFFAgeListVal
				end
				valueHashMap = Hash.new
				value = nil
				prdTerm = quotationIO.baseDO.getBasePlan.productTerm.to_i
				(1..prdTerm).each do |policyYear|
					break unless quotationIO.finalMap[policyYear]
					if localElement == "ONLYFACEAMOUNT"
						value = (quotationIO.baseDO.getBasePlan.baseSumAssured * 2.0)/1000
					else
						value =(quotationIO.finalMap[policyYear][localElement][inRate.to_s]).to_f/1000
					end
					valueHashMap[policyYear.to_s] = value
				end
				inputHash["valueHashMap"] = valueHashMap
				inputHash["companyColour"] = $rhoconfig[:SunPHComp]

				jsonStr = ::JSON.generate(inputHash)

				imageName = quotationIO.baseDO.quotationRefNum + Random.rand(100000).to_s + ".png"
				fileName = Rho::RhoApplication.get_blob_folder + File::SEPARATOR + imageName
				cmdStr = "javaw -classpath #{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}pdf.jar;"
				cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}flexjson-2.1.jar;"
				cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}jcommon-1.0.21.jar;"
				cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}jfreechart-1.0.17.jar;"
				cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}jfreechart-1.0.17-experimental.jar;"
				cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}jfreechart-1.0.17-swt.jar;"
				cmdStr << " com.c2lbiz.mobisys.win32.BarChartGenerator "
				cmdStr << jsonStr.gsub('"','\"').gsub(' ','$SPACE$')
				cmdStr << " #{fileName}"

				#puts "cmdStr: #{cmdStr}"

				answer = system(cmdStr)

				#puts ">>>answer: #{answer} errorStatus: #{$?}"

				return "<img src=\"#{imageName}\" width=\"75%\"/>"

		else
		  maxValue = 0
		  age = quotationIO.baseDO.getPartyListByRoleCd("PRIMARY")[0].age.to_i
		  print_age = 0
		  policyYear = 0
		  printAge = 0
		  pureMFFAgeList = mvelHashMap["PureMFFAgeList"]
		  age_x = []
		  finalValue_y = []
		  	product = quotationIO.baseDO.getBasePlan.getProduct
		  	barGraphFacet = product.getFacet('BARGRAPH')
	        if barGraphFacet != nil
	          facetActionValue = barGraphFacet.actionValue
	        end

		  	if facetActionValue == "YES"
		  		if pureMFFAgeList == nil
					if colorSelector == 1 || colorSelector == 2
						if age <= 75
							policyYear = 80 - age
							printAge = 80
						elsif age <= 80
							policyYear = 85 - age
							printAge = 85
						end
					elsif colorSelector == 3
						if age <= 50
							policyYear = 55 - age
							printAge = 55
						elsif age <= 60
							policyYear = 65 - age
							printAge = 65
						elsif age <= 64
							policyYear = 70 - age
							printAge = 70
						end
					elsif colorSelector == 4 || colorSelector == 5
						policyYear = 4
						printAge = age + 4
					end
				else
					pureMFFAgeList.each do |pureMffAge|
						value = (quotationIO.finalMap[pureMffAge.to_i-age.to_i][localElement][inRate]).to_f/1000
						age_x << pureMffAge # dataset.setValue(value, "GUARANTEED", String.valueOf(pureMffAge))
						finalValue_y << value
						maxValue = (maxValue > value) ? maxValue : value
					end
				end
				# PureMFF block 1 end
				if (quotationIO.baseDO != nil && pureMFFAgeList == nil)
					if(quotationIO.baseDO.getBaseProduct != nil)
						counter = 0
						# PureMFF block 2 start
						if(colorSelector != 4 && colorSelector != 5)
							i = policyYear
							while i<=(90-age) do
								#for (int i = policyYear;i<=(90-age);i=i+3)
								if localElement.to_s == "ONLYFACEAMOUNT"
									value = (quotationIO.baseDO.getBaseProduct.baseSumAssured*2).to_f/1000
									age_x << printAge
									finalValue_y << value
								else
									if(quotationIO.finalMap[i] != nil)
										value =(quotationIO.finalMap[i][localElement][inRate]).to_f/1000
										age_x << printAge
										finalValue_y << value
									end
								end
								maxValue = (maxValue > value) ? maxValue : value
								printAge = printAge+3
								counter = counter + 1
								if(colorSelector != 3)
									if(counter == 4)
										break
									end
								else
									if(printAge == 75)
										printAge = printAge - 1
									end
									if(printAge > 75)
										break
									end
								end
								i=i+3
							end
						else
							i = policyYear
							while i<policyYear+4 do
								#for (int i = policyYear;i<policyYear+4;i++)
								value =(quotationIO.finalMap[i][localElement][inRate]).to_f/1000
								age_x << printAge# dataset.setValue(value, "GUARANTEED", String.valueOf(printAge))
								finalValue_y << value
								maxValue = (maxValue > value) ? maxValue : value
								printAge = printAge + 1
								counter = counter + 1
								i = i + 1
							end
						end
						# PureMFF block 2 end
					end
				end
		  	else
				if pureMFFAgeList == nil
				  if(colorSelector == 1 || colorSelector == 2)
							if (age <=45)
								policyYear = 50 - age
								printAge = 50
							elsif(age <= 60)
								policyYear = 65 - age
								printAge = 65
							elsif(age <= 65)
								policyYear = 70 - age
								printAge = 70
							elsif(age <= 70)
								policyYear = 75 - age
								printAge = 75
							end
					elsif(colorSelector == 3)
						if (age <= 50)
							policyYear = 55 - age
							printAge = 55
						elsif(age <= 60)
							policyYear = 65 - age
							printAge = 65
						elsif(age <= 64)
							policyYear = 70 - age
							printAge = 70
						end
					elsif(colorSelector == 4 || colorSelector == 5)
						policyYear = 4
						 printAge = age + 4
					end
				else
					pureMFFAgeList.each do |pureMffAge|
						value =	(quotationIO.finalMap[pureMffAge.to_i-age.to_i][localElement][inRate]).to_f/1000
						age_x << pureMffAge # dataset.setValue(value, "GUARANTEED", String.valueOf(pureMffAge));
						finalValue_y << value
						maxValue = (maxValue > value) ? maxValue : value
					end
				end
				if (quotationIO.baseDO != nil && pureMFFAgeList == nil)
					if(quotationIO.baseDO.getBaseProduct != nil)
					  	counter = 0
					  	if(colorSelector != 4 && colorSelector != 5)
						  	i = policyYear
						  	while i <= (85-age) do
								if localElement == "ONLYFACEAMOUNT"
									value = (quotationIO.baseDO.getBaseProduct.baseSumAssured*2).to_f/1000
									age_x << printAge
									finalValue_y << value
								else
									value =(quotationIO.finalMap[i][localElement][inRate]).to_f/1000
									age_x << printAge
									finalValue_y << value
								end
								# if(colorSelector != 4 && colorSelector != 5)
								# 	printAge = printAge + 5
								# 	i = i + 5
								# else
								# 	printAge = printAge + 1
								# 	i = i + 1
								# end

								maxValue = (maxValue > value) ? maxValue : value
								printAge = printAge+5
								counter = counter+1
								if(colorSelector != 3)
									if(counter == 4)
									 	break
									end
							  	else
									if(printAge == 75)
										printAge = printAge - 1
									end
									if(printAge > 75)
										break
									end
								end
								i=i+5
						  	end
						else
							i = policyYear
							while i<policyYear+4 do
								#for (int i = policyYear;i<policyYear+4;i++)
								value =(quotationIO.finalMap[i][localElement][inRate]).to_f/1000
								# dataset.setValue(value, "GUARANTEED", String.valueOf(printAge))
								age_x << printAge
								finalValue_y << value
								maxValue = (maxValue > value) ? maxValue : value
								printAge = printAge+1
								counter = counter+1
								i = i+1
							end
						end
					end
				end
			end
		  #puts ">>>maxValue..#{maxValue.inspect}....finalValue_y..#{finalValue_y}....age_x....#{age_x}"

		  renderer = ""
		  companyColour = $rhoconfig[:SunPHComp]
		  case colorSelector
			when 1
				if companyColour == "SLOCPI"
					renderer = 'rgb(189,80,24)'
				elsif companyColour == "SLGFI"
					renderer = 'rgb(34,85,164)'
				end
			when 2
				if companyColour == "SLOCPI"
					renderer = 'rgb(250,182,41)'
				elsif companyColour == "SLGFI"
					renderer = 'rgb(250,182,41)'
				end
			when 3
				if companyColour == "SLOCPI"
					renderer = 'rgb(0,57,70)'
				elsif companyColour == "SLGFI"
					renderer = 'rgb(34,85,164)'
				end
			when 4
	    		if companyColour == "SLOCPI"
	    			renderer = 'rgb(130,120,111)'
	    		elsif companyColour == "SLGFI"
	    			renderer = 'rgb(34,85,164)'
	    		end
	    	when 5
	    		if companyColour == "SLOCPI"
	    			renderer = 'rgb(235,171,1)'
	    		elsif companyColour == "SLGFI"
	    			renderer = 'rgb(235,171,1)'
				end
			else
				renderer = 'rgb(250,182,41)'
			end

			maxRange = 0
	        divisionUnit =  1000000000
	        divisor = 10
	        tickUnitWholeNumber1=0
            while (divisionUnit >= 1) do
                if(maxValue >= divisionUnit)
                    if(maxValue%divisionUnit == 0)
                          maxRange = maxValue.to_i
                    else
                          maxRange = (((maxValue / divisionUnit).to_i) + 1) * divisionUnit
                    end
                    break
                end
                divisionUnit = divisionUnit/divisor
            end
            tickUnitWholeNumber = maxRange/4
			while((maxRange % 4) != 0) do
              	maxRange = maxRange + divisionUnit
                tickUnitWholeNumber = maxRange/4
            end
            ySpecificLabels = [0]
            (1..4).each do |i|
            	ySpecificLabels << (tickUnitWholeNumber * i).to_s.reverse.scan(/\d{3}|.+/).join(",").reverse
            end
            ySpecificLabels = ySpecificLabels.reverse
            #p "tickUnitWholeNumber===>#{tickUnitWholeNumber} #{maxRange}"
             #----- SUNSS-1080 - 16-06-2020-ganesh
			widthpara = 0.23
			titlepos = 0.2
			# if quotationIO.baseDO.getBaseProduct.productId.to_s == "5RCP0A"
			# 	widthpara = 0.23
			# 	titlepos = 0.45
			# end
			# if quotationIO.baseDO.getBaseProduct.productId.to_s == "MGXP0A" || quotationIO.baseDO.getBaseProduct.productId.to_s == "MGVP0A"
			# 	widthpara = 0.23
			# 	titlepos = 0.40
			# end
			divName = Random.rand(2500000).to_s + "_rGraph"
			canName = 'myCanvas_'+Random.rand(2500000).to_s
			htmlStr = ""
			htmlStr = "<div style =\"background-color: rgb(255,235,191)\">"
			$graphHtmlCounter = $graphHtmlCounter+1
			placeHolder = "$graphHtml_#{$graphHtmlCounter}$"
			if quotationIO.offlinePDFGeneration.to_s != "true"
				htmlStr = "<html>"
				htmlStr << "<script type='text/javascript' src='jquery-3.7.1.min.js'></script>"
				htmlStr << "<script type='text/javascript' src='RGraph.bar.js'></script>"
				htmlStr << "<script type='text/javascript' src='RGraph.line.js'></script>"
				htmlStr << "<script type='text/javascript' src='RGraph.common.core.js'></script>"
				htmlStr << "<script type='text/javascript' src='RGraph.pie.js'></script>"
				htmlStr << "<script type='text/javascript' src='RGraph.common.key.js'></script>"
				htmlStr << "<div style =\"background-color: rgb(255,235,191)\">"
				htmlStr << "<div name=\"mainWrapper\" id=\"#{placeHolder}\">"
				htmlStr << "<img name='graph_png' src =\"\">"
				htmlStr << "</div>"
			end
			htmlStr << "<div  style =\"background-color: rgb(255,235,191)\">"
			# htmlStr << "<script type=\"text/javascript\">$('div[name=\"#{divName}\"]').html('<div class=\"graphWrapper\" style = \"height:'+ $(document).width() * 0.11 +'px\">');</script>"
			htmlStr << "<div name=\"#{divName}\" style =\"width:60%;\">"
			htmlStr << "</div>"
			htmlStr << "</div>"
			htmlStr << "</div>"
			htmlStr << "</div>" if quotationIO.offlinePDFGeneration.to_s != "true"
			htmlStr << "<script type=\"text/javascript\">"
			htmlStr << "$(document).ready(function(){"
			htmlStr << "$('div[name=\"#{divName}\"]').css(\"margin-left\", $(document).width() * 0.008 + \"px\");"
			# htmlStr << "$('div[name=\"#{divName}\"]').html(\"<canvas id='#{canName}' name='#{canName}' width='\"+ $(document).width() * 0.22 +\"px' height='\"+ $(document).width() * 0.16 +\"px' >[No canvas support]</canvas>\");"
			####SUNSS-1080##################################
			htmlStr << "$('div[name=\"#{divName}\"]').html(\"<canvas id='#{canName}' name='#{canName}' width='\"+ $(document).width() * #{widthpara} +\"px' height='\"+ $(document).width() * 0.110 +\"px' >[No canvas support]</canvas>\");"
			htmlStr << "$('div[name=\"#{divName}\"]').trigger('create');"
			htmlStr << "myGraph = new RGraph.Bar('#{canName}', #{finalValue_y});"
			htmlStr << "myGraph.Set('chart.xaxis.labels', #{age_x});"
			htmlStr << "myGraph.Set('chart.xaxis.title','AGE');"
			htmlStr << "myGraph.Set('chart.yaxis.title','THOUSANDS');"
			htmlStr << "myGraph.Set('chart.hmargin', 5);"
			htmlStr << "myGraph.Set('chart.xaxis.title.pos',0.5);"
			htmlStr << "myGraph.Set('chart.xaxis.title.size',7);"
			htmlStr << "myGraph.Set('chart.xaxis.title.font','Arial');"
            #htmlStr << "myGraph.Set('chart.xaxis.title.bold', true);"
            #htmlStr << "myGraph.Set('chart.xaxis.labels.bold', true);"
			htmlStr << "myGraph.Set('chart.xaxis.labels.size', 6);"
			htmlStr << "myGraph.Set('chart.xaxis.labels.font', 'Arial');"
			htmlStr << "myGraph.Set('chart.xaxis.tickmarks.last', false);"
			htmlStr << "myGraph.Set('chart.xaxis.tickmarks.count', 0);"
			htmlStr << "myGraph.Set('chart.margin.left', 60);"
			htmlStr << "myGraph.Set('chart.margin.right', 20);"
			htmlStr << "myGraph.Set('chart.margin.top', 15);"
			htmlStr << "myGraph.Set('chart.margin.bottom', 30);"
			htmlStr << "myGraph.Set('chart.yaxis',false);"
			# htmlStr << "myGraph.Set('chart.yaxis.title.pos',0.2);"
			htmlStr << "myGraph.Set('chart.yaxis.title.pos',#{titlepos});"####SUNSS-1080
			htmlStr << "myGraph.Set('chart.yaxis.title.size',7);"
			htmlStr << "myGraph.Set('chart.yaxis.title.font','Arial');"
            #htmlStr << "myGraph.Set('chart.yaxis.title.bold', true);"
			htmlStr << "myGraph.Set('chart.yaxis.scale.max',#{maxRange});"
			htmlStr << "myGraph.Set('chart.yaxis.labels.count', 4);"
            #htmlStr << "myGraph.Set('chart.yaxis.labels.bold', true);"
		  	htmlStr << "myGraph.Set('chart.yaxis.labels.size', 6);"
		  	htmlStr << "myGraph.Set('chart.yaxis.labels.font', 'Arial');"
			htmlStr << "myGraph.Set('chart.yaxis.labels.specific',#{ySpecificLabels});"
			htmlStr << "myGraph.Set('chart.yaxis.tickmarks.count', 4);"
			htmlStr << "myGraph.Set('chart.background.grid.hlines.count',4);"
			htmlStr << "myGraph.Set('chart.colors', ['#{renderer}']);"
			htmlStr << "myGraph.Set('chart.background.grid.color','rgb(0,0,0)');"
			htmlStr << "myGraph.Set('chart.background.grid.border',false);"
			htmlStr << "myGraph.Set('chart.background.grid.width','4');"
			htmlStr << "myGraph.Set('chart.background.grid.autofit',true);"
			htmlStr << "myGraph.Set('chart.background.grid.autofit.numhlines', 4);"
			htmlStr << "myGraph.Set('chart.background.grid.vlines', false);"
			htmlStr << "myGraph.Set('chart.background.grid.linewidth', 1);"
			htmlStr << "myGraph.Set('chart.text.accessible', false);"
			htmlStr << "myGraph.Set('chart.backgroundColor','rgb(255,235,191)');"
			htmlStr << "myGraph.Set('noendxtick', true);"
			htmlStr << "myGraph.Set('noyaxis', true);"
			htmlStr << "myGraph.Draw();"
			htmlStr << "RGraph.Register(myGraph);"
			if quotationIO.offlinePDFGeneration.to_s != "true"
				htmlStr << "image_data = myGraph.canvas.toDataURL('image/png');"
				htmlStr << "$('img[name=\"graph_png\"').attr('src',image_data);"
				htmlStr << "imageElement = $(\"img[name='graph_png']\");"
				htmlStr << "$(\"canvas\").replaceWith(imageElement);"
			end
			htmlStr << "});"
			htmlStr << "</script>"
			if quotationIO.offlinePDFGeneration.to_s != "true"
				htmlStr << "</html>"
				$graphHtmlHM[placeHolder] = htmlStr

				return placeHolder
			else
				return htmlStr
			end
		end
	  end	
	end

    def self.generateSLGFIBarChart(mvelHashMap , quotationIO , localElement , tickUnit, maxRange, inRate, colorSelector)
		#puts ">>>inside generateBarChart platform: #{System.get_property('platform')} localElement: #{localElement} inRate: #{inRate}"
		if $showPdf == true
				inputHash = Hash.new
				inputHash["age"] = quotationIO.baseDO.getPartyByRole("PRIMARY").age
				inputHash["colorSelector"] = colorSelector
				inputHash["tickUnit"] = tickUnit
				pureMFFAgeList = mvelHashMap["PureMFFAgeList"]

				product = quotationIO.baseDO.getBasePlan.getProduct
			  	barGraphFacet = product.getFacet('BARGRAPH')
		        if barGraphFacet != nil
		          facetActionValue = barGraphFacet.actionValue
		        end

				if pureMFFAgeList != nil
					inputHash["PureMFFAgeList"] = mvelHashMap["PureMFFAgeList"]
				elsif facetActionValue == "YES"
					# var = []
					pureMFFAgeListVal = getPureMFFAgeListForMD1U0CandML1P0E(mvelHashMap , quotationIO , localElement , tickUnit, maxRange, inRate, colorSelector)
					# x = Hash[(1...var.size+1).zip var]
					# p "+++++++++++++++x: #{x}"
					inputHash["PureMFFAgeList"] = pureMFFAgeListVal
				end
				valueHashMap = Hash.new
				value = nil
				prdTerm = quotationIO.baseDO.getBasePlan.productTerm.to_i
				(1..prdTerm).each do |policyYear|
					break unless quotationIO.finalMap[policyYear]
					if localElement == "ONLYFACEAMOUNT"
						value = (quotationIO.baseDO.getBasePlan.baseSumAssured * 2.0)/1000
					else
						value =(quotationIO.finalMap[policyYear][localElement][inRate.to_s]).to_f/1000
					end
					valueHashMap[policyYear.to_s] = value
				end
				inputHash["valueHashMap"] = valueHashMap
				inputHash["companyColour"] = $rhoconfig[:SunPHComp]
				

				jsonStr = ::JSON.generate(inputHash)

				imageName = quotationIO.baseDO.quotationRefNum + Random.rand(100000).to_s + ".png"
				fileName = Rho::RhoApplication.get_blob_folder + File::SEPARATOR + imageName
				cmdStr = "javaw -classpath #{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}pdf.jar;"
				cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}flexjson-2.1.jar;"
				cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}jcommon-1.0.21.jar;"
				cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}jfreechart-1.0.17.jar;"
				cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}jfreechart-1.0.17-experimental.jar;"
				cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}jfreechart-1.0.17-swt.jar;"
				cmdStr << " com.c2lbiz.mobisys.win32.BarChartGenerator "
				cmdStr << jsonStr.gsub('"','\"').gsub(' ','$SPACE$')
				cmdStr << " #{fileName}"

				#puts "cmdStr: #{cmdStr}"

				answer = system(cmdStr)

				#puts ">>>answer: #{answer} errorStatus: #{$?}"

				return "<img src=\"#{imageName}\" width=\"100%\"/>"

		else
		  maxValue = 0
		  age = quotationIO.baseDO.getPartyListByRoleCd("PRIMARY")[0].age
		  print_age = 0
		  policyYear = 0
		  printAge = 0
		  pureMFFAgeList = mvelHashMap["PureMFFAgeList"]
		  age_x = []
		  finalValue_y = []
		  	product = quotationIO.baseDO.getBasePlan.getProduct
		  	barGraphFacet = product.getFacet('BARGRAPH')
	        if barGraphFacet != nil
	          facetActionValue = barGraphFacet.actionValue
	        end

		  	if facetActionValue == "YES"
		  		if pureMFFAgeList == nil
					if colorSelector == 1 || colorSelector == 2
						if age <= 75
							policyYear = 80 - age
							printAge = 80
						elsif age <= 80
							policyYear = 85 - age
							printAge = 85
						end
					elsif colorSelector == 3
						if age <= 50
							policyYear = 55 - age
							printAge = 55
						elsif age <= 60
							policyYear = 65 - age
							printAge = 65
						elsif age <= 64
							policyYear = 70 - age
							printAge = 70
						end
					elsif colorSelector == 4 || colorSelector == 5
						policyYear = 4
						printAge = age + 4
					end
				else
					pureMFFAgeList.each do |pureMffAge|
						value = (quotationIO.finalMap[pureMffAge.to_i-age.to_i][localElement][inRate]).to_f/1000
						age_x << pureMffAge # dataset.setValue(value, "GUARANTEED", String.valueOf(pureMffAge))
						finalValue_y << value
						maxValue = (maxValue > value) ? maxValue : value
					end
				end
				# PureMFF block 1 end
				if (quotationIO.baseDO != nil && pureMFFAgeList == nil)
					if(quotationIO.baseDO.getBaseProduct != nil)
						counter = 0
						# PureMFF block 2 start
						if(colorSelector != 4 && colorSelector != 5)
							i = policyYear
							while i<=(90-age) do
								#for (int i = policyYear;i<=(90-age);i=i+3)
								if localElement.to_s == "ONLYFACEAMOUNT"
									value = (quotationIO.baseDO.getBaseProduct.baseSumAssured*2).to_f/1000
									age_x << printAge
									finalValue_y << value
								else
									if(quotationIO.finalMap[i] != nil)
										value =(quotationIO.finalMap[i][localElement][inRate]).to_f/1000
										age_x << printAge
										finalValue_y << value
									end
								end
								maxValue = (maxValue > value) ? maxValue : value
								printAge = printAge+3
								counter = counter + 1
								if(colorSelector != 3)
									if(counter == 4)
										break
									end
								else
									if(printAge == 75)
										printAge = printAge - 1
									end
									if(printAge > 75)
										break
									end
								end
								i=i+3
							end
						else
							i = policyYear
							while i<policyYear+4 do
								#for (int i = policyYear;i<policyYear+4;i++)
								value =(quotationIO.finalMap[i][localElement][inRate]).to_f/1000
								age_x << printAge# dataset.setValue(value, "GUARANTEED", String.valueOf(printAge))
								finalValue_y << value
								maxValue = (maxValue > value) ? maxValue : value
								printAge = printAge + 1
								counter = counter + 1
								i = i + 1
							end
						end
						# PureMFF block 2 end
					end
				end
		  	else
				if pureMFFAgeList == nil
				  if(colorSelector == 1 || colorSelector == 2)
							if (age <=45)
								policyYear = 50 - age
								printAge = 50
							elsif(age <= 60)
								policyYear = 65 - age
								printAge = 65
							elsif(age <= 65)
								policyYear = 70 - age
								printAge = 70
							elsif(age <= 70)
								policyYear = 75 - age
								printAge = 75
							end
					elsif(colorSelector == 3)
						if (age <= 50)
							policyYear = 55 - age
							printAge = 55
						elsif(age <= 60)
							policyYear = 65 - age
							printAge = 65
						elsif(age <= 64)
							policyYear = 70 - age
							printAge = 70
						end
					elsif(colorSelector == 4 || colorSelector == 5)
						policyYear = 4
						 printAge = age + 4
					end
				else
					pureMFFAgeList.each do |pureMffAge|
						value =	(quotationIO.finalMap[pureMffAge.to_i-age.to_i][localElement][inRate]).to_f/1000
						age_x << pureMffAge # dataset.setValue(value, "GUARANTEED", String.valueOf(pureMffAge));
						finalValue_y << value
						maxValue = (maxValue > value) ? maxValue : value
					end
				end
				if (quotationIO.baseDO != nil && pureMFFAgeList == nil)
					if(quotationIO.baseDO.getBaseProduct != nil)
					  	counter = 0
					  	if(colorSelector != 4 && colorSelector != 5)
						  	i = policyYear
						  	while i <= (85-age) do
								if localElement == "ONLYFACEAMOUNT"
									value = (quotationIO.baseDO.getBaseProduct.baseSumAssured*2).to_f/1000
									age_x << printAge
									finalValue_y << value
								else
									value =(quotationIO.finalMap[i][localElement][inRate]).to_f/1000
									age_x << printAge
									finalValue_y << value
								end
								# if(colorSelector != 4 && colorSelector != 5)
								# 	printAge = printAge + 5
								# 	i = i + 5
								# else
								# 	printAge = printAge + 1
								# 	i = i + 1
								# end

								maxValue = (maxValue > value) ? maxValue : value
								printAge = printAge+5
								counter = counter+1
								if(colorSelector != 3)
									if(counter == 4)
									 	break
									end
							  	else
									if(printAge == 75)
										printAge = printAge - 1
									end
									if(printAge > 75)
										break
									end
								end
								i=i+5
						  	end
						else
							i = policyYear
							while i<policyYear+4 do
								#for (int i = policyYear;i<policyYear+4;i++)
								value =(quotationIO.finalMap[i][localElement][inRate]).to_f/1000
								# dataset.setValue(value, "GUARANTEED", String.valueOf(printAge))
								age_x << printAge
								finalValue_y << value
								maxValue = (maxValue > value) ? maxValue : value
								printAge = printAge+1
								counter = counter+1
								i = i+1
							end
						end
					end
				end
			end
		  # puts ">>>maxValue.barchart.......#{maxValue.inspect}....finalValue_y..#{finalValue_y}....age_x....#{age_x}"

		  renderer = ""
		  companyColour = $rhoconfig[:SunPHComp]
		  case colorSelector
			when 1
				if companyColour == "SLOCPI"
					renderer = 'rgb(189,80,24)'
				elsif companyColour == "SLGFI"
					renderer = 'rgb(34,85,164)'
				end
			when 2
				if companyColour == "SLOCPI"
					renderer = 'rgb(250,182,41)'
				elsif companyColour == "SLGFI"
					renderer = 'rgb(250,182,41)'
				end
			when 3
				if companyColour == "SLOCPI"
					renderer = 'rgb(0,57,70)'
				elsif companyColour == "SLGFI"
					renderer = 'rgb(34,85,164)'
				end
			when 4
	    		if companyColour == "SLOCPI"
	    			renderer = 'rgb(130,120,111)'
	    		elsif companyColour == "SLGFI"
	    			renderer = 'rgb(34,85,164)'
	    		end
	    	when 5
	    		if companyColour == "SLOCPI"
	    			renderer = 'rgb(235,171,1)'
	    		elsif companyColour == "SLGFI"
	    			renderer = 'rgb(235,171,1)'
				end
			else
				renderer = 'rgb(250,182,41)'
			end

          maxRange = 0
	        divisionUnit =  1000000000
	        divisor = 10
	        tickUnitWholeNumber1=0
            while (divisionUnit >= 1) do
                if(maxValue >= divisionUnit)
                    if(maxValue%divisionUnit == 0)
                          maxRange = maxValue.to_i
                    else
                          maxRange = (((maxValue / divisionUnit).to_i) + 1) * divisionUnit
                    end
                    break
                end
                divisionUnit = divisionUnit/divisor
            end
            tickUnitWholeNumber = maxRange/4
			while((maxRange % 4) != 0) do
              	maxRange = maxRange + divisionUnit
                tickUnitWholeNumber = maxRange/4
            end
            ySpecificLabels = [0]
            (1..4).each do |i|
            	ySpecificLabels << (tickUnitWholeNumber * i).to_s.reverse.scan(/\d{3}|.+/).join(",").reverse
            end
            ySpecificLabels = ySpecificLabels.reverse
            #p "tickUnitWholeNumber===>#{tickUnitWholeNumber} #{maxRange}"
             #----- SUNSS-1080 - 16-06-2020-ganesh
			widthpara = 0.22
			titlepos = 0.15
			if quotationIO.baseDO.getBaseProduct.productId.to_s == "5RCP0A"
				widthpara = 0.34
				titlepos = 0.2
			end
			garphHeight = 0.110
		    bgHeight = 0.08
			if quotationIO.baseDO.getBaseProduct.productId.to_s == "TBDGrepa"
				garphHeight = 0.115
				bgHeight    = 0.8
			elsif quotationIO.baseDO.getBaseProduct.productId.to_s == "SGPAB"
					garphHeight = 0.115
					bgHeight    = 0.09
			end	
			divName = Random.rand(2500000).to_s + "_rGraph"
			canName = 'myCanvas_'+Random.rand(2500000).to_s
			htmlStr = ""
			$graphHtmlCounter = $graphHtmlCounter+1
	        placeHolder = "$graphHtml_#{$graphHtmlCounter}$"
	        if quotationIO.offlinePDFGeneration.to_s != "true"
	            htmlStr = "<html>"
	            htmlStr << "<script type='text/javascript' src='jquery-3.7.1.min.js'></script>"
	            htmlStr << "<script type='text/javascript' src='RGraph.bar.js'></script>"
	            htmlStr << "<script type='text/javascript' src='RGraph.line.js'></script>"
	            htmlStr << "<script type='text/javascript' src='RGraph.common.core.js'></script>"
	            htmlStr << "<script type='text/javascript' src='RGraph.pie.js'></script>"
	            htmlStr << "<script type='text/javascript' src='RGraph.common.key.js'></script>"
	            htmlStr << "<div name=\"mainWrapper\" id=\"#{placeHolder}\">"
	            htmlStr << "<img name='graph_png' src =\"\">"
	        end
			htmlStr << "<div  style =\"background-color: rgb(255,235,191);#{garphHeight}\">"
			# htmlStr << "<script type=\"text/javascript\">$('div[name=\"#{divName}\"]').html('<div class=\"graphWrapper\" style = \"height:'+ $(document).width() * #{bgHeight} +'px\">');</script>"
			htmlStr << "<div name=\"#{divName}\" style =\"width:60%;\">"
			htmlStr << "</div>"
			htmlStr << "</div>"
			htmlStr << "</div>"
			htmlStr << "</div>" if quotationIO.offlinePDFGeneration.to_s != "true"
			htmlStr << "<script type=\"text/javascript\">"
			htmlStr << "$(document).ready(function(){"
			htmlStr << "$('div[name=\"#{divName}\"]').css(\"margin-left\", $(document).width() * 0.008 + \"px\");"
			# htmlStr << "$('div[name=\"#{divName}\"]').html(\"<canvas id='#{canName}' name='#{canName}' width='\"+ $(document).width() * 0.22 +\"px' height='\"+ $(document).width() * 0.16 +\"px' >[No canvas support]</canvas>\");"
			####SUNSS-1080##################################
			htmlStr << "$('div[name=\"#{divName}\"]').html(\"<canvas id='#{canName}' name='#{canName}' width='\"+ $(document).width() * #{widthpara} +\"px' height='\"+ $(document).width() * #{garphHeight} +\"px' >[No canvas support]</canvas>\");"
			htmlStr << "$('div[name=\"#{divName}\"]').trigger('create');"
			htmlStr << "myGraph = new RGraph.Bar('#{canName}', #{finalValue_y});"
			htmlStr << "myGraph.Set('chart.xaxis.labels', #{age_x});"
			htmlStr << "myGraph.Set('chart.xaxis.title','AGE');"
			htmlStr << "myGraph.Set('chart.yaxis.title','THOUSANDS');"
			htmlStr << "myGraph.Set('chart.hmargin',5);"
			htmlStr << "myGraph.Set('chart.xaxis.title.pos',0.5);"
			htmlStr << "myGraph.Set('chart.xaxis.title.size', 7);"
			htmlStr << "myGraph.Set('chart.xaxis.title.font','Arial');"
            #htmlStr << "myGraph.Set('chart.xaxis.title.bold', true);"
            #htmlStr << "myGraph.Set('chart.xaxis.labels.bold', true);"
			htmlStr << "myGraph.Set('chart.xaxis.labels.size', 6);"
			htmlStr << "myGraph.Set('chart.xaxis.labels.font', 'Arial');"
			htmlStr << "myGraph.Set('chart.xaxis.tickmarks.last', false);"
			htmlStr << "myGraph.Set('chart.xaxis.tickmarks.count', 0);"
			htmlStr << "myGraph.Set('chart.margin.left', 60);"
			htmlStr << "myGraph.Set('chart.margin.right', 20);"
			htmlStr << "myGraph.Set('chart.margin.top', 15);"
			htmlStr << "myGraph.Set('chart.margin.bottom', 30);"
			htmlStr << "myGraph.Set('chart.yaxis',false);"
			# htmlStr << "myGraph.Set('chart.yaxis.title.pos',0.2);"
			htmlStr << "myGraph.Set('chart.yaxis.title.pos',#{titlepos});"####SUNSS-1080
			htmlStr << "myGraph.Set('chart.yaxis.title.size', 7);"
			htmlStr << "myGraph.Set('chart.yaxis.title.font','Arial');"
            #htmlStr << "myGraph.Set('chart.yaxis.title.bold', true);"
			htmlStr << "myGraph.Set('chart.yaxis.scale.max',#{maxRange});"
			htmlStr << "myGraph.Set('chart.yaxis.labels.count', 4);"
            #htmlStr << "myGraph.Set('chart.yaxis.labels.bold', true);"
		  	htmlStr << "myGraph.Set('chart.yaxis.labels.size', 6);"
		  	htmlStr << "myGraph.Set('chart.yaxis.labels.font', 'Arial');"
			htmlStr << "myGraph.Set('chart.yaxis.labels.specific',#{ySpecificLabels});"
			htmlStr << "myGraph.Set('chart.yaxis.tickmarks.count', 4);"
			htmlStr << "myGraph.Set('chart.background.grid.hlines.count',4);"
			htmlStr << "myGraph.Set('chart.colors', ['#{renderer}']);"
			htmlStr << "myGraph.Set('chart.backgroundColor','rgb(255,235,191)');"
			htmlStr << "myGraph.Set('chart.background.grid.color','rgb(0,0,0)');"
			htmlStr << "myGraph.Set('chart.background.grid.border',false);"
			htmlStr << "myGraph.Set('chart.background.grid.width','4');"
			htmlStr << "myGraph.Set('chart.background.grid.autofit',true);"
			htmlStr << "myGraph.Set('chart.background.grid.autofit.numhlines', 4);"
			htmlStr << "myGraph.Set('chart.background.grid.vlines', false);"
			htmlStr << "myGraph.Set('chart.background.grid.linewidth', 1);"
			htmlStr << "myGraph.Set('noendxtick', true);"
			htmlStr << "myGraph.Set('noyaxis', true);"
			htmlStr << "myGraph.Set('chart.text.accessible', false);"
			htmlStr << "myGraph.Set('chart.backgroundColor','rgb(255,235,191)');"
			htmlStr << "myGraph.Draw();"
			htmlStr << "RGraph.Register(myGraph);"
			if quotationIO.offlinePDFGeneration.to_s != "true"
                htmlStr << "image_data = myGraph.canvas.toDataURL('image/png');"
                htmlStr << "$('img[name=\"graph_png\"').attr('src',image_data);"
                htmlStr << "imageElement = $(\"img[name='graph_png']\");"
                htmlStr << "$(\"canvas\").replaceWith(imageElement);"
            end
            htmlStr << "});"
            htmlStr << "</script>"
            if quotationIO.offlinePDFGeneration.to_s != "true"
	            htmlStr << "</html>"
	            $graphHtmlHM[placeHolder] = htmlStr
	            return placeHolder
	        else
	            return htmlStr
	        end
		end
	end


		def self.getRiderRowRegularPay(rider, quotationIO)
			finalString="";
			regularPremium="";
			isWOP ="";
			perDay = "";
			currency = "";
			extraPremium=0.0;
			baseAnnualPremium=0.0;

			#30Sept start
			if quotationIO.finalMap[1] != nil && quotationIO.finalMap[1]["rideroutput"] != nil
				regularPremium = quotationIO.finalMap[1]["rideroutput"]["0" + rider.productId.to_s]
			else
				# extraPremium= rider.extraPremium == nil ? 0 : rider.extraPremium.to_f
				# baseAnnualPremium= rider.baseAnnualPremium == nil ? 0 : rider.baseAnnualPremium.to_f
				regularPremium = rider.annualizedPremium #(extraPremium +baseAnnualPremium).to_s if ((extraPremium + baseAnnualPremium) != 0.0)
			end

			#30Sept end
			isWOP = "";
			perDay = "";
			currency = (quotationIO.baseDO.getBasePlan.currencyCd != nil && quotationIO.baseDO.getBasePlan.currencyCd == "USD") ? "US$" : "Ps"

			riderProductDO = MobiSys::ProductUtil.getProduct(rider.productSeq)
            riderPrdFacet = riderProductDO.getFacet("PERDAYCHECK") if riderProductDO

			# if(rider.product.productKey != nil)
			if riderPrdFacet && riderPrdFacet.actionValue.to_s == "YES"
				perDay = riderPrdFacet.actionValue.to_s == "YES" ? " /day" : ""
			end

			if(rider.productId == "TDB") && rider.product.getFacet("OTHERDETAILS")!= nil  && rider.product.getOtherDetailsFacet.OfflineOtherDetailsList[0].isWOPFl == "YES"

				isWOP = " (Waiver of Premium)";
			end
			finalString = finalString.concat("<tr>			<td class=\"border1 fontFamilyGFB\" style=\"border-bottom:0px$SEMI$border-top:0px$SEMI$vertical-align: top$SEMI$padding-left:2px\">")
			######################rider symbol permanent fix########################
			quotation = quotationIO.baseDO
          	quotationResultDO = nil
          	@riderNameFacet = CompanyFacet.find(:first,:conditions=>{:facetCd=>"RIDERSYMBOL"})
          	riderSymbol = @riderNameFacet.actionValue if @riderNameFacet
         	quotationResultDO = MobiSys::ProductBO.evaluateModel(quotation, rider, riderSymbol, false)
          	if quotationResultDO.getFieldValueObject('rideroutput').to_s != "" && quotationResultDO.getFieldValueObject('rideroutput').to_s != "0.0"          		
          		riderName = quotationResultDO.getFieldValueObject('rideroutput').to_s
      		else
      			if quotationIO.baseDO.getBaseProduct.product.productFamilyId == "TRAD"
      				riderName = rider.product.shortName.to_s
      			else
      				riderName = rider.product.longName.to_s
      			end
      		end
      		finalString = finalString.concat(riderName.to_s)
      		######################rider symbol permanent fix ends########################
			# if quotationIO.baseDO.getBaseProduct.product.productFamilyId== "TRAD"
			# 	finalString = finalString.concat(rider.product.shortName == nil ? "" : rider.product.shortName + isWOP + " - " + rider.productId)
			# else
			# 	if rider.productId == "TDB"
			# 		riderName = "Total Disability Benefit (Waiver of Premium)"
			# 		finalString = finalString.concat(rider.product.longName == nil ? "" : riderName + isWOP + " - " + rider.productId)
			# 	elsif rider.productId == "CBTD"
			# 		riderName = "N/A"
			# 		finalString = finalString.concat(rider.product.longName == nil ? "" : riderName + isWOP + " - " + rider.productId)
			# 	elsif	rider.productId == "WPD"
			# 		riderName = "Premium Coverage After Death of Initial Owner (Waiver of Premium on Death of Initial Owner)"
			# 		finalString = finalString.concat(rider.product.longName == nil ? "" : riderName + isWOP + " - " + rider.productId)
			# 	elsif	rider.productId == "HIB"
			# 		riderName = "Hospital Income Benefit"
			# 		finalString = finalString.concat(rider.product.longName == nil ? "" : riderName + isWOP + " - " + rider.productId)
			# 	elsif	rider.productId == "CIB"
			# 		riderName = "Critical Illness Benefit"
			# 		finalString = finalString.concat(rider.product.longName == nil ? "" : riderName + isWOP + " - " + rider.productId)
			# 	elsif rider.productId != "TDB" ||rider.productId != "CBTD" || rider.productId != "WPD" || rider.productId != "HIB"||rider.productId != "CIB"
			# 		finalString = finalString.concat(rider.product.longName == nil ? "" : rider.product.longName + isWOP + " - " + rider.productId)
			# 	end
			# end
			# finalString = finalString.concat("<tr>			<td class=\"border1 fontFamilyGFB\" style=\"border-bottom:0px$SEMI$border-top:0px$SEMI$vertical-align: top$SEMI$padding-left:2px\">")
			# finalString = finalString.concat(rider.product.shortName == nil ? "" : rider.product.shortName + isWOP + " - " + rider.productId)
			if(rider.productId == "TDB" || rider.productId.to_s == "TDB of 5YRCT") || (rider.product.getFacet("OTHERDETAILS")!= nil  && rider.product.getOtherDetailsFacet.OfflineOtherDetailsList[0].isWOPFl == "YES")
				finalString = finalString.concat("</td>			<td style=\"text-align:right\" class=\"fontFamilyGFB\"> ")
				finalString = finalString.concat("</td>				<td style=\"border-right:1px solid black$SEMI$text-align:right\" class=\"fontFamilyGFB\">")
			else
				finalString = finalString.concat("</td>			<td style=\"text-align:right\" class=\"fontFamilyGFB\"> ")
				finalString = finalString.concat( rider.baseSumAssured == nil ? "" : currency)
				finalString = finalString.concat("</td>				<td style=\"border-right:1px solid black$SEMI$text-align:right$SEMI$padding-right:2px$SEMI$\" class=\"fontFamilyGFB\">")
				finalString = finalString.concat( (rider.baseSumAssured == nil ? "" : UIGenUtilCompanyHelper.getFormatDoubleTwoDecimalWithComma(rider.baseSumAssured.to_s))	+perDay)
			end
			finalString = finalString.concat("</td>				<td style=\"text-align:right\"class=\"fontFamilyGFB\">")
			finalString = finalString.concat((regularPremium.to_f) == 0.0 ? "" : currency)
			finalString = finalString.concat("</td>				<td style=\"border-right:1px solid black$SEMI$text-align:right$SEMI$padding-right:2px\" class=\"fontFamilyGFB\">")

			finalString = finalString.concat(UIGenUtilCompanyHelper.getFormatDoubleTwoDecimalWithComma(regularPremium))
			finalString = finalString.concat("</td></tr>")
			return finalString;
		end

		def self.getRiderRowSinglePay(rider,quotationIO)
			finalString="";
			regularPremium="";
			isWOP ="";
			perDay = "";
			currency="";
			extraPremium=0.0;
			baseAnnualPremium=0.0;
			#30 sept start
			if quotationIO.finalMap[1] != nil && quotationIO.finalMap[1]["rideroutput"] != nil
				regularPremium = quotationIO.finalMap[1]["rideroutput"]["0" + rider.productId]
			else
				# extraPremium= rider.extraPremium == nil ? 0 : rider.extraPremium.to_f ;
				# baseAnnualPremium= rider.baseAnnualPremium == nil ? 0 : rider.baseAnnualPremium.to_f;
				regularPremium = rider.annualizedPremium.to_f #(extraPremium +baseAnnualPremium).to_s if ((extraPremium + baseAnnualPremium) != 0.0)
			end

			#30 sept end
			isWOP = "";
			perDay = "";
			currency = quotationIO.baseDO.getBasePlan.currencyCd!= nil && quotationIO.baseDO.getBasePlan.currencyCd == "USD" ? "US$" : "Ps"


			riderProductDO = MobiSys::ProductUtil.getProduct(rider.productSeq)
            riderPrdFacet = riderProductDO.getFacet("PERDAYCHECK") if riderProductDO

			# if(rider.product.productKey != nil)
			if riderPrdFacet && riderPrdFacet.actionValue.to_s == "YES"
				perDay = riderPrdFacet.actionValue.to_s == "YES" ? "/ day" : "";
			end
			
			if(rider.productId == "TDB") &&  rider.product.getFacetDO("OTHERDETAILS")!=nil && rider.product.getOtherDetailsFacet.OfflineOtherDetailsList[0].isWOPFl == "YES"

				isWOP = " (Waiver of Premium)";
			end

			finalString = finalString.concat("<tr>				<td class=\"border1 fontFamilyGFB\" style=\"border-bottom:0px$SEMI$border-top:0px$SEMI$vertical-align: top$SEMI$padding-left:2px\">")
			if quotationIO.baseDO.getBaseProduct.product.productFamilyId == "TRAD"
				finalString = finalString.concat(rider.product.shortName == nil ? "" : rider.product.shortName + isWOP + " (Premium = "+currency+" "+UIGenUtilCompanyHelper.getFormatDoubleTwoDecimalWithComma(regularPremium) +")" + " - " + rider.productId)
			else
				finalString = finalString.concat(rider.product.longName == nil ? "" : rider.product.longName + isWOP + " (Premium = "+currency+" "+UIGenUtilCompanyHelper.getFormatDoubleTwoDecimalWithComma(regularPremium) +")" + " - " + rider.productId)
			end
			if(rider.productId == "TDB")|| (rider.product.getFacet("OTHERDETAILS")!= nil  && rider.product.getOtherDetailsFacet.OfflineOtherDetailsList[0].isWOPFl == "YES")
				finalString = finalString.concat("</td>			<td style=\"text-align:right\" class=\"fontFamilyGFB\"> ")
				finalString = finalString.concat("</td>				<td style=\"border-right:1px solid black$SEMI$text-align:right\" class=\"fontFamilyGFB\">")
			else
				finalString = finalString.concat("</td>			<td style=\"text-align:right\" class=\"fontFamilyGFB\"> ")
				finalString = finalString.concat( rider.baseSumAssured == nil ? "" : currency)
				finalString = finalString.concat("</td>				<td style=\"border-right:1px solid black$SEMI$text-align:right$SEMI$padding-right:1px\" class=\"fontFamilyGFB\">")
				finalString = finalString.concat( (rider.baseSumAssured == nil ? "" : UIGenUtilCompanyHelper.getFormatDoubleTwoDecimalWithComma(rider.baseSumAssured.to_s))	+perDay)
			end
			finalString = finalString.concat("</td>				<td style=\"text-align:right$SEMI$\"class=\"fontFamilyGFB\">")
			finalString = finalString.concat("</td>				<td style=\"border-right:1px solid black$SEMI$text-align:right$SEMI$padding-right:2px\" class=\"fontFamilyGFB\">")
			finalString = finalString.concat("</td></tr>")
			return finalString;
		end

		# def generateSummaryOfBenefitsPageClassic(quotationIO, mvelHashMap)
		# 	htmlBuffer = ""
		# 	repeatHashMap = {}
		# 	SectionDetailsDO sectionDetailsDO = new SectionDetailsDO;
		# 	String element="";
		# 	String rate="";
		# 	String tdStyle="";
		# 	int productTerm= quotationIO.baseDO.getBasePlan.getProductTerm;
		# 	int temp1=productTerm%5;
		# 	int milestone3 = productTerm - temp1;
		# 	int milestone1 = milestone3 - 10;
		# 	int milestone2 = milestone3 - 5;
		# 	String policyYearCondition="1,3,5,10,14,20"+milestone1+","+milestone2+","+milestone3;

		# 	if(quotationIO.baseDO.getBasePlan.getAddtnField4 == "PR") || quotationIO.baseDO.getBasePlan .getAddtnField4() == "DA"))
		# 	{
		# 		//Plan option is Premium Reduction or Dividend Accum.
		# 		element="PolicyYear,Attainedage,SummaryGDB,SummaryGCV,SummaryAccumulatedDividendCurrent,SOBEBPDAPRTotalLivingBenefit,SOBEBPDAPRTotalDeathBenefit";
		# 		rate="0,0,0,0,0,0,0";
		# 		tdStyle="style=\"text-align:center\"class=\"col1\",style=\"text-align:center\"class=\"col2\",style=\"text-align:right\"class=\"col3\",style=\"text-align:right\"class=\"col4\",style=\"text-align:right\"class=\"col5\",style=\"text-align:right\"class=\"col6\",style=\"text-align:right\"class=\"col7\"";
		# 		String DARateCurrent = UIGenUtilHelper.formatDoubleTwoDecimal(""+Double.parseDouble(quotationIO.getIllustrationHeaderFieldValue("DARateCurrent"))*100)+"%";
		# 		String DARateAlternate = UIGenUtilHelper.formatDoubleTwoDecimal(""+Double.parseDouble(quotationIO.getIllustrationHeaderFieldValue("DARateAlternate"))*100)+"%";
		# 		htmlBuffer=htmlBuffer.concat("<div class=\"SLFSoB\">  "+
		# 									"<div class=\"SLFSectionTitle\" style=\"margin-top:20px$SEMI$\">Summary of Benefits</div>"+
		# 									"<table class=\"SLFSoBTable fontFamilyGFB fontSize12\">"+
		# 									"<tr> <td rowspan=\"2\" class=\"SoB-header fontFamilyATL fontSize13\">End<br>of<br>Year</td>" +
		# 								   " <td rowspan=\"2\" class=\"SoB-header fontFamilyATL fontSize13\">Att Age</td>" +
		# 								   "<td rowspan=\"2\" class=\"SoB-header fontFamilyATL fontSize13\" style=\"text-align:right\">Guaranteed<br>Death<br>Benefit</td>" +
		# 								   " <td rowspan=\"2\" class=\"SoB-header fontFamilyATL fontSize13\" style=\"text-align:right\">Guaranteed<br>Cash<br>Value</td>" +
		# 								   "<td colspan=\"3\" class=\"SoB-header fontFamilyATL fontSize13\">Scenario 1<br>Current Dividend Scale<br>Accumulation Rate at "+DARateCurrent+"</td>" +
		# 								   "</tr>" +
		# 								   " <tr>" +
		# 								   "<td class=\"SoB-header fontFamilyATL fontSize13\" style=\"text-align:right\">Illustrative<br>Accum. Dividend</td>" +
		# 								   " <td class=\"SoB-header fontFamilyATL fontSize13\" style=\"text-align:right\">Total Living<br>Benefit</td>" +
		# 								   " <td class=\"SoB-header fontFamilyATL fontSize13\" style=\"text-align:right\">Total Death<br>Benefit</td>" +
		# 									"</tr>")
		# 		UIGenUtil.getInstance().processTable(repeatHashMap, 0, quotationIO, element, rate, htmlBuffer, sectionDetailsDO, "PolicyYear", "", repeatHashMap, tdStyle, policyYearCondition, "", false);

		# 		htmlBuffer=htmlBuffer.concat("</table>");
		# 		//Generate Second Table
		# 		element="PolicyYear,Attainedage,SummaryGDB,SummaryGCV,SummaryAccumulatedDividendAlternate,SOBEBPDAPRAltTLB,SOBEBPDAPRAltTDB";
		# 		rate="0,0,0,0,0,0,0";
		# 		tdStyle="style=\"text-align:center\"class=\"col1\",style=\"text-align:center\"class=\"col2\",style=\"text-align:right\"class=\"col3\",style=\"text-align:right\"class=\"col4\",style=\"text-align:right\"class=\"col5\",style=\"text-align:right\"class=\"col6\",style=\"text-align:right\"class=\"col7\"";

		# 		htmlBuffer=htmlBuffer.concat("<table class=\"SLFSoBTable fontFamilyGFB fontSize12\">"+
		# 									"<tr> <td rowspan=\"2\" class=\"SoB-header fontFamilyATL fontSize13\">End<br>of<br>Year</td>" +
		# 								   " <td rowspan=\"2\" class=\"SoB-header fontFamilyATL fontSize13\">Att Age</td>" +
		# 								   "<td rowspan=\"2\" class=\"SoB-header fontFamilyATL fontSize13\" style=\"text-align:right\">Guaranteed<br>Death<br>Benefit</td>" +
		# 								   " <td rowspan=\"2\" class=\"SoB-header fontFamilyATL fontSize13\" style=\"text-align:right\">Guaranteed<br>Cash<br>Value</td>" +
		# 								   "<td colspan=\"3\" class=\"SoB-header fontFamilyATL fontSize13\">Scenario 2<br>Accumulation Rate at "+DARateAlternate+"</td>" +
		# 								   "</tr>" +
		# 								   " <tr>" +
		# 								   "<td class=\"SoB-header fontFamilyATL fontSize13\" style=\"text-align:right\">Illustrative<br>Accum. Dividend</td>" +
		# 								   " <td class=\"SoB-header fontFamilyATL fontSize13\" style=\"text-align:right\">Total Living<br>Benefit</td>" +
		# 								   " <td class=\"SoB-header fontFamilyATL fontSize13\" style=\"text-align:right\">Total Death<br>Benefit</td>" +
		# 									"</tr>");
		# 		UIGenUtil.getInstance().processTable(repeatHashMap, 0, quotationIO, element, rate, htmlBuffer, sectionDetailsDO, "PolicyYear", "", repeatHashMap, tdStyle, policyYearCondition, "", false);

		# 		htmlBuffer=htmlBuffer.concat("</table></div>");
		# 		htmlBuffer=htmlBuffer.concat("<p class=\"fontFamilyGFB fontSize12\">Total Living Benefit is the sum of Guaranteed Cash Value and Illustrative Accumulated Dividends.<br>"+
		# 				"Total Death Benefit is the sum of Guaranteed Death Benefit and Illustrative Accumulated Dividends..</p>");


		# 	}
		# 	else if(quotationIO.baseDO().getBasePlan .getAddtnField4() == "PUA")){
		# 		//Plan Option is Paid Up Addition
		# 		element="PolicyYear,Attainedage,SummaryGDB,SummaryGCV,SummaryCVAccPUACurrent,SOBEBPPUATLB,SummaryAccPUACurrent,SOBEBPPUATDB";
		# 		rate="0,0,0,0,0,0,0,0";
		# 		tdStyle="style=\"text-align:center\" class=\"col1\",style=\"text-align:center\"class=\"col2\",style=\"text-align:right\"class=\"col3\",style=\"text-align:right\"class=\"col4\",style=\"text-align:right\"class=\"col5\",style=\"text-align:right\"class=\"col6\",style=\"text-align:right\"class=\"col7\",style=\"text-align:right\"class=\"col8\"";

		# 		htmlBuffer=htmlBuffer.concat("<div class=\"SLFSoB\">  "+
		# 									"<div class=\"SLFSectionTitle \">Summary of Benefits</div>"+
		# 									"<table class=\"SLFSoBTable fontFamilyGFB fontSize12\">"+
		# 									"<tr> <td rowspan=\"2\" class=\"SoB-header fontFamilyATL fontSize13\">End<br>of<br>Year</td>" +
		# 								   " <td rowspan=\"2\" class=\"SoB-header fontFamilyATL fontSize13\">Att Age</td>" +
		# 								   "<td rowspan=\"2\" class=\"SoB-header fontFamilyATL fontSize13\" style=\"text-align:right\">Guaranteed<br>Death<br>Benefit</td>" +
		# 								   " <td rowspan=\"2\" class=\"SoB-header fontFamilyATL fontSize13\" style=\"text-align:right\">Guaranteed<br>Cash<br>Value</td>" +
		# 								   "<td colspan=\"4\" class=\"SoB-header fontFamilyATL fontSize13\">Scenario 1<br>Current Dividend Scale</td>" +
		# 								   "</tr>" +
		# 								   " <tr>" +
		# 								   "<td class=\"SoB-header fontFamilyATL fontSize13\" style=\"text-align:right\">Illustrative<br>Cash Value<br>of Accum. PUA</td>" +
		# 								   " <td class=\"SoB-header fontFamilyATL fontSize13\" style=\"text-align:right\">Total Living<br>Benefit</td>" +
		# 								   "<td class=\"SoB-header fontFamilyATL fontSize13\" style=\"text-align:right\">Illustrative<br>Accumulated PUA</td>" +
		# 								   " <td class=\"SoB-header fontFamilyATL fontSize13\" style=\"text-align:right\">Total Death<br>Benefit</td>" +
		# 									"</tr>");
		# 		UIGenUtil.getInstance().processTable(repeatHashMap, 0, quotationIO, element, rate, htmlBuffer, sectionDetailsDO, "PolicyYear", "", repeatHashMap, tdStyle, policyYearCondition, "", false);
		# 		htmlBuffer=htmlBuffer.concat("</table>");

		# 		//Generate Second Table
		# 		element="PolicyYear,Attainedage,SummaryGDB,SummaryGCV,SummaryCVAccPUAAlternate,SOBEBPPUAAltTLB,SummaryAccPUAAlternate,SOBEBPPUAAltTDB";
		# 		rate="0,0,0,0,0,0,0,0";
		# 		tdStyle="style=\"text-align:center\" class=\"col1\",style=\"text-align:center\"class=\"col2\",style=\"text-align:right\"class=\"col3\",style=\"text-align:right\"class=\"col4\",style=\"text-align:right\"class=\"col5\",style=\"text-align:right\"class=\"col6\",style=\"text-align:right\"class=\"col7\",style=\"text-align:right\"class=\"col8\"";

		# 		htmlBuffer=htmlBuffer.concat("<table class=\"SLFSoBTable fontFamilyGFB fontSize12\">"+
		# 									"<tr> <td rowspan=\"2\" class=\"SoB-header fontFamilyATL fontSize13\">End<br>of<br>Year</td>" +
		# 								   " <td rowspan=\"2\" class=\"SoB-header fontFamilyATL fontSize13\">Att Age</td>" +
		# 								   "<td rowspan=\"2\" class=\"SoB-header fontFamilyATL fontSize13\" style=\"text-align:right\">Guaranteed<br>Death<br>Benefit</td>" +
		# 								   " <td rowspan=\"2\" class=\"SoB-header fontFamilyATL fontSize13\" style=\"text-align:right\">Guaranteed<br>Cash<br>Value</td>" +
		# 								   "<td colspan=\"4\" class=\"SoB-header fontFamilyATL fontSize13\">Scenario 2 Dividend Scale</td>" +
		# 								   "</tr>" +
		# 								   " <tr>" +
		# 								   "<td class=\"SoB-header fontFamilyATL fontSize13\" style=\"text-align:right\">Illustrative<br>Cash Value<br>of Accum. PUA</td>" +
		# 								   " <td class=\"SoB-header fontFamilyATL fontSize13\" style=\"text-align:right\">Total Living<br>Benefit</td>" +
		# 								   "<td class=\"SoB-header fontFamilyATL fontSize13\" style=\"text-align:right\">Illustrative<br>Accumulated PUA</td>" +
		# 								   " <td class=\"SoB-header fontFamilyATL fontSize13\" style=\"text-align:right\">Total Death<br>Benefit</td>" +
		# 									"</tr>");
		# 		UIGenUtil.getInstance().processTable(repeatHashMap, 0, quotationIO, element, rate, htmlBuffer, sectionDetailsDO, "PolicyYear", "", repeatHashMap, tdStyle, policyYearCondition, "", false);
		# 		htmlBuffer=htmlBuffer.concat("</table></div>");

		# 		htmlBuffer=htmlBuffer.concat("<p class=\"fontFamilyGFB fontSize12\">Total Living Benefit is the sum of Guaranteed Cash Value and Illustrative Cash Value of Accumulated PUA.<br>"+
		# 				"Total Death Benefit is the sum of Guaranteed Death Benefit and 200% of Illustrative Accumulated PUA.</p>");

		# 	}


		# 	return htmlBuffer;
		# }

		def self.generateSummaryOfBenefitsPageClassic(quotationIO, mvelHashMap)
		end

		def self.getFormattedInputDate(inDate, format)
			#puts "inDate======#{inDate}"
			#puts "format======#{format}"
			if inDate
				time = Time.parse(inDate.to_s)
				newDateTime = time.strftime(format)
			end
			#puts "time======= #{time}"
			#puts "newDateTime #{newDateTime}"
			return newDateTime
		end

		def self.generateAgeConditionForPHAndIB(quotationIO, pageName)
			finalString = "";
			numberOfYears = 0 ;
			if quotationIO.baseDO.topupOptionCd == nil || quotationIO.baseDO.topupOptionCd == "" || quotationIO.baseDO.topupOptionCd == "EXCESSWITHOUTPH" || quotationIO.baseDO.topupOptionCd == "EXCESSWITHPH" || quotationIO.baseDO.topupOptionCd == "TFCALCULATIONWITHOUTPH"
				numberOfYears=quotationIO.baseDO.getBasePlan.payingYears==nil ? 0 : quotationIO.baseDO.getBasePlan.payingYears.to_i; # max fund duration comes from the model element
				return AgeConditionOption1(quotationIO,pageName,numberOfYears);
			elsif(quotationIO.baseDO.topupOptionCd == "TFCALCULATIONWITHPH" || quotationIO.baseDO.topupOptionCd == "EXCESSANDTFCALCULATIONWITHPH")
				numberOfYears=quotationIO.baseDO.getBasePlan.payingYears!=nil ? quotationIO.baseDO.getBasePlan.payingYears.to_i : 0 ;
				return AgeConditionOption2(quotationIO,pageName,numberOfYears);
			end
			return finalString;
		end

		def self.AgeConditionOption2(quotationIO, pageName, numberOfYears)
			finalString="";
			targetPeriod = quotationIO.baseDO.getBasePlan.targetPeriod != nil ? quotationIO.baseDO.getBasePlan.targetPeriod.to_i : 0;
			primaryAge = quotationIO.baseDO.getPartyByRole("PRIMARY").age.to_i;
			if (quotationIO.baseDO.getBasePlan.targetPeriodRefCd != nil && quotationIO.baseDO.getBasePlan.targetPeriodRefCd == "TARGETAGE")
				#convert to duration if target period given in age.
				targetPeriod = targetPeriod - primaryAge;
			end
			# calculation of milestone ages
			x = targetPeriod;
			y = x+5;
			z = x+10;
			v = (88 - primaryAge);
			maxFundDuration = v; # comes from model
			ageArray = []
			if(x>=v && v <= maxFundDuration)
				ageArray.push(v);
			elsif(x<v  && x <= maxFundDuration)
				ageArray.push(x);
				if(y>=v  && v <= maxFundDuration)
					ageArray.push(v);
				elsif(y<v  && y <= maxFundDuration)
					ageArray.push(y);
					if(z>=v  && v <= maxFundDuration)
						ageArray.push(v);
					elsif(z<v  && z <= maxFundDuration)
						ageArray.push(z);
					end
				end
			end
			if(pageName == "PH" && numberOfYears>20)
				ageArray.push(numberOfYears);
			end
			ageArray.each do |i|
				finalString=finalString.concat(i.to_s+",")
			end
			if(finalString.length>1)
				finalString=finalString[0,finalString.length-1];
			end
			return finalString;
		end

		def self.AgeConditionOption1(quotationIO , pageName ,numberOfYears)

			primaryAge= quotationIO.baseDO.getPartyByRole("PRIMARY").age.to_i
			finalString="";

			#calculation of milestone ages
			x = 55-primaryAge;
			y = 60 - primaryAge;
			z = 65 - primaryAge;
			if (quotationIO.baseDO.topupOptionCd != nil && quotationIO.baseDO.topupOptionCd == "EXCESSWITHPH")
				maxFundDuration = 88-primaryAge; # from model element
			else
				maxFundDuration=quotationIO.baseDO.getBasePlan.productTerm; # product term(88-issue age)
			end
			ageArray = []
			if(numberOfYears.to_i < 20)
				if(maxFundDuration>=x && x>0)
					ageArray.push(x);
				end
				if(maxFundDuration>=y && y>0)
					ageArray.push(y);
				end
				if(maxFundDuration>=z&& z>0)
					ageArray.push(z);
				end
			else
				ageArray.push(x);
				ageArray.push(y);
				ageArray.push(z);
			end
			if pageName == "PH" && numberOfYears.to_i > 20
				ageArray.push(numberOfYears.to_i);
				ageArray.sort!
			end
			ageArray.each do |i|
				finalString=finalString.concat(i.to_s+",");
			end
			if(finalString.length>1)
				finalString=finalString[0,finalString.length-1];
			end
			if(finalString == "")
				finalString="500"; #give a high age value so that it dose not print any row
			end
			return finalString;
		end

		def self.setcomputedTotalPremium(mvelHashMap, quotationIO , riderList,apoFl)
			extraPremium=0;
			riderBaseAnnualPremium=0;
			riderTotalPremium=0;
			totalPremiumTitlePage = 0;
			annualexcesspremium = 0;
			annualexcesspremium = 0

			if(apoFl == "YES")
			mvelHashMap["apototalPremiumTitlePage"] = totalPremiumTitlePage
			else
			mvelHashMap["totalPremiumTitlePage"] = totalPremiumTitlePage
			end

			riderList.each do |rd|
				if quotationIO.finalMap[1] != nil && quotationIO.finalMap[1]["rideroutput"] != nil && mvelHashMap["productDO"].productFamilyId == "VUL"
				riderTotalPremium = riderTotalPremium.to_f + quotationIO.finalMap[1]["rideroutput"]["0" + rd.productId].to_f
				elsif quotationIO.finalMap[1] != nil && quotationIO.finalMap[1]["riderpremium"] != nil && mvelHashMap["productDO"].productFamilyId == "TRAD"
				riderTotalPremium = riderTotalPremium.to_f + quotationIO.finalMap[1]["riderpremium"]["0" + rd.productId].to_f
				else
					# extraPremium= rd.extraPremium == nil ? 0 : rd.extraPremium.to_f ;
					# baseAnnualPremium= rd.baseAnnualPremium == nil ? 0 : rd.baseAnnualPremium.to_f
					riderTotalPremium += rd.annualizedPremium.to_f #(riderTotalPremium.to_f + extraPremium.to_f + baseAnnualPremium.to_f).to_s if ((extraPremium.to_f + baseAnnualPremium.to_f) != 0.0)
				end
			end
			planBaseAnnualPremium = quotationIO.baseDO.getBasePlan.baseAnnualPremium==nil ? 0 : quotationIO.baseDO.getBasePlan.baseAnnualPremium.to_f;
			annualPremium = quotationIO.baseDO.getBasePlan.extraPremium == nil ? 0.0 : quotationIO.baseDO.getBasePlan.extraPremium.to_f;
			quotationIO.baseDO.QuotationTopUpList.each do |qt|
				if qt.topUpTypeCd != nil && qt.topUpTypeCd == "REGULARTOPUP"
					annualexcesspremium = qt.topUpAmount== nil ? 0.0 : qt.topUpAmount.to_f
				end
			end
			if mvelHashMap["productDO"].getFacet("PREMIUMDETAILS") != nil && (mvelHashMap["productDO"].getFacet("PREMIUMDETAILS").getPremiumDetails.premiumTypeCd != "SINGLE")
				totalPremiumTitlePage = MobiSys::Math.roundNearest(((riderTotalPremium).to_f + (planBaseAnnualPremium).to_f + (annualPremium).to_f),2)
				totalPremium = MobiSys::Math.roundNearest(((riderTotalPremium).to_f + (planBaseAnnualPremium).to_f + (annualPremium).to_f + (annualexcesspremium).to_f),2)
				if(apoFl == "YES")
				mvelHashMap["apototalPremiumTitlePage"] = totalPremiumTitlePage
				else
				mvelHashMap["totalPremiumTitlePage"] = totalPremiumTitlePage
				end
			else
				totalPremium =MobiSys::Math.roundNearest(((planBaseAnnualPremium).to_f + (annualPremium).to_f),2)
				if(apoFl == "YES")
				mvelHashMap["apototalPremiumTitlePage"] = totalPremium
				else
				mvelHashMap["totalPremiumTitlePage"] = totalPremium
				end
			end
			return totalPremium
		end

		def self.getUpdateHashMap(mvelHashMap)
			quotationIO= mvelHashMap["quotationIO"]
			# puts "quotationIO.finalMap-----------#{quotationIO.finalMap}"
			#2014-08-13
			apoquotationIO = mvelHashMap["apoquotationIO"]
			if (quotationIO.outputPreferencesDO && quotationIO.outputPreferencesDO.field4.to_s == 'NO')
				if (quotationIO.baseDO.getBasePlan.productFamilyCd.to_s == 'VUL')
					quotationIO.outputPreferencesDO.field4 = "YES"
				end
			end
	  		mvelHashMap["outputPreferencesDO"] = quotationIO.outputPreferencesDO

			riderList = mvelHashMap["riderList"]


	  		riderList.each do |rider|
				   mvelHashMap[rider.productId] = rider
				 end
			computedTotalPremium = setcomputedTotalPremium(mvelHashMap, quotationIO, riderList,"NO")
			mvelHashMap["computedTotalPremium"] = computedTotalPremium

			riderList.each do |rider|
				mvelHashMap[rider.productId] = rider
			end


			if(quotationIO.baseDO.userId != nil)
				agentDO = AgentReg.getCurrentAgentReg
				mvelHashMap["agentDO"] = agentDO if agentDO
			end

			noAdditionalDeathBenefitRiderList = []
			mvelHashMap["ADBRiderSelect"] = false
			riderList.each do |rd|
				if(rd.productId != "ADB25"&& rd.productId != "ADB50" && rd.productId != "ADB75" && rd.productId != "ADB100")
					noAdditionalDeathBenefitRiderList.push(rd);
				else
					mvelHashMap["ADBRiderSelect"] = true
				end
			end
			mvelHashMap["noAdditionalDeathBenefitRiderList"] = noAdditionalDeathBenefitRiderList

			fundList = mvelHashMap["fundList"]
			fundList.each do |fd|
				mvelHashMap["chosenFundCd"] = fd.fundCd
				break;
			end
			#getting the actual illustration rates attached with the illutration model.

			illustrationModelDOs = []
			illustrationModelDO = quotationIO.illustrationModel

			# IllustrationModelDO findIllustrationModelDO = new IllustrationModelDO();
			# findIllustrationModelDO.setId(illustrationModelDO.getId());
			# FinderUtil<IllustrationModelDO> finderUtil = FinderUtil.getInstance();
			# illustrationModelDO = finderUtil.getEntityById(findIllustrationModelDO);

			illustrationRateDOsList = illustrationModelDO.IllustrationRateList


			if(illustrationRateDOsList != nil && illustrationRateDOsList.size >0)
				mvelHashMap["illustrationRateDOsList"] = illustrationRateDOsList
			end


			if(apoquotationIO != nil)
				apoRiderList = apoquotationIO.baseDO.getRiders
				apocomputedTotalPremium = setcomputedTotalPremium(mvelHashMap, apoquotationIO, apoRiderList,"YES")
				if(apocomputedTotalPremium != 0.0)
					mvelHashMap["apocomputedTotalPremium"] = apocomputedTotalPremium
				end
				apoIllustrationRateDOsList = apoquotationIO.originalSIModel.IllustrationRateList

				if apoIllustrationRateDOsList != nil && apoIllustrationRateDOsList.size >0
					mvelHashMap["apoIllustrationRateDOsList"] = apoIllustrationRateDOsList
				end

				noapoAdditionalDeathBenefitRiderList = []
				mvelHashMap["ADBRiderSelect"] = false
				apoRiderList.each do |rd|
					if(rd.productId != "ADB25" && rd.productId != "ADB50" && rd.productId != "ADB75" && rd.productId != "ADB100")
						noapoAdditionalDeathBenefitRiderList.push(rd)
					else
						mvelHashMap["ADBRiderSelect"] =  true
					end
				end
				mvelHashMap["noapoAdditionalDeathBenefitRiderList"] =  noapoAdditionalDeathBenefitRiderList

				mvelHashMap["isapoCashSurrenderApplicable"] = false
				ruleSeq=0
				apoquotationIO.originalSIModel.IllustrationFacetList.each do |illustrationFacetDO|
					if illustrationFacetDO.computedElementName != nil &&
							(illustrationFacetDO.computedElementName == "SurrenderCharges" or illustrationFacetDO.computedElementName == "surrendercharges")
						 ruleSeq =  illustrationFacetDO.ruleSeq
						 break
					end
				end
				if(ruleSeq!=0)
					mvelHashMap["isapoCashSurrenderApplicable"] = true
				end

				getDTFundRate(apoquotationIO,mvelHashMap,"FMCWoST")
			end

			mvelHashMap["allChosenFundRateFlag"] = false
			illustrationRateDOsList.each do |illustrationRateDO|
				mvelHashMap["avg"+illustrationRateDO.rateTypeCd.to_s] = illustrationRateDO.rate.to_s
				rate = illustrationRateDO.rate.to_f*100;
				rate = UIGenUtilCompanyHelper.getFormatDoubleTwoDecimalWithComma(rate).to_f
				rateInt = rate.to_i
				difference = rate - rateInt;
				if(difference != 0.00)
					mvelHashMap["allChosenFundRateFlag"] = true
				end
			end


			#for Apo quotationIO (added)
			if apoquotationIO != nil
				illustrationModelDOs = []
				illustrationModelDO = apoquotationIO.illustrationModel
				illustrationRateDOsList = illustrationModelDO.IllustrationRateList
				illustrationRateDOsList.each do |illustrationRateDO|
					mvelHashMap["apoavg"+illustrationRateDO.rateTypeCd.to_s] = illustrationRateDO.rate.to_s
				end
			end

			getDTFundRate(quotationIO,mvelHashMap,"fmcwost");
			mvelHashMap["isCashSurrenderApplicable"] = false
			ruleSeq=0.0;
			quotationIO.originalSIModel.IllustrationFacetList.each do |illustrationFacetDO|
				if(illustrationFacetDO.computedElementName != nil && illustrationFacetDO.computedElementName.casecmp("SurrenderCharges").zero?)
					 ruleSeq =  illustrationFacetDO.ruleSeq
					 break;
				end
			end
			if(ruleSeq!=0.0)
				mvelHashMap["isCashSurrenderApplicable"] = true
			end
			mvelHashMap["termRiderInitialString"] = ""
			if mvelHashMap["productDO"].getFacet("PREMIUMDETAILS") != nil && (mvelHashMap["productDO"].getFacet("PREMIUMDETAILS").getPremiumDetails.premiumTypeCd != "SINGLE")
				if(mvelHashMap["CIB"] != nil || mvelHashMap["FCI"] != nil || mvelHashMap["FCM"] != nil)
					mvelHashMap["termRiderInitialString"] = "Initial "
				end
			end

			#changes 04 Aug 2014 start #changes 30 jan 2015 start
			mvelHashMap["DBRateFlag"] = false
			illustrationModel = quotationIO.illustrationModel
			elemDO = CommonUtil.convertToHash(illustrationModel.IllustrationFacetList, 'computedElementName')["dbrate"]
			if elemDO != nil && elemDO.computationFreqCd == "EVERYCYCLE"
				mvelHashMap["DBRateFlag"] = true
			end
			# if(quotationIO.finalMap[1]["dbrate"]!= nil && quotationIO.finalMap[2]["dbrate"] != nil)
			# 	if(quotationIO.finalMap[1]["dbrate"]["0"] != quotationIO.finalMap[2]["dbrate"]["0"])
			# 		mvelHashMap["DBRateFlag"] = true
			# 	end
			# end
			#changes 30 jan 2015 end

			#changes 16 oct 2014 start
			rateHigh = getRate(mvelHashMap, mvelHashMap["chosenFundCd"])["High"] + mvelHashMap["chosenFundCd"]  if mvelHashMap["chosenFundCd"] != nil
			i = 1
			for i in i..quotationIO.baseDO.basePlan.productTerm
				if(mvelHashMap["chosenFundCd"] != nil && quotationIO.finalMap[i.to_i] != nil && quotationIO.finalMap[i.to_i]["deathbenefit"] != nil &&
						quotationIO.finalMap[i.to_i]["deathbenefit"][rateHigh] != nil && quotationIO.finalMap[i.to_i]["deathbenefit"][rateHigh].to_f == 0.0)
					mvelHashMap["maxTableYear"] = i-1
					break
				end
			end
			#changes 16 oct 2014 end

			fundList = mvelHashMap["fundList"]
			#changes 12 Nov 2014 start
				mvelHashMap["isPureMyFutureFund"] = false
				mvelHashMap["maxMaturityYear"] = quotationIO.baseDO.getBasePlan.productTerm.to_i
				mffCounter = 0;
				maxMaturityYear = 0;
				fundList.each do |quotationProductFund|
					if quotationProductFund.fundTypeCd == "MyFuture"
						maxMaturityYearValue = DateTime.strptime(quotationProductFund.maturityDt.to_s, "%Y-%m-%d").year - DateTime.strptime(quotationIO.baseDO.issueDt.to_s, "%Y-%m-%d").year;
						maxMaturityYear = maxMaturityYearValue.to_i > maxMaturityYear.to_i ? maxMaturityYearValue.to_i : maxMaturityYear.to_i
						mffCounter = mffCounter + 1
					end
				end
				if mffCounter == fundList.size && quotationIO.baseDO.getBaseProduct.product.productFamilyId == "VUL" && fundList.size != 0
					mvelHashMap["maxTableYear"]  = maxMaturityYear;
					mvelHashMap["maxMaturityYear"] = maxMaturityYear;
					mvelHashMap["isPureMyFutureFund"] = true;
				end
				if quotationIO.baseDO.getBaseProduct.product.productFamilyId == "VUL"
					getFundWithdrawalHashMap(mvelHashMap);
				end
				#Changes 05 Nov changes start
				fundValueDur =false;
				fundValueDurLowYear = 0;
				fundValueDurVeryLowYear = 0;
				fundValueDurMediumYear = 0;
				fundValueDurHighYear = 0;
				i = 1
				while i <= (quotationIO.baseDO.getBasePlan.productTerm.to_i) do
				if(quotationIO.finalMap.has_key?(i))
					if(quotationIO.finalMap[i]["fundvaluedur"] != nil )
							if(mvelHashMap["avgLOW"] != nil)
								if(quotationIO.finalMap[i]["fundvaluedur"][mvelHashMap["avgLOW"]] == 1 && fundValueDurLowYear == 0)
									if(i <= mvelHashMap["maxMaturityYear"].to_i)
										fundValueDur =true;
										fundValueDurLowYear = i;
									end
								end
							end
							if(mvelHashMap["avgMEDIUM"] != nil)
								if(quotationIO.finalMap[i]["fundvaluedur"][mvelHashMap["avgMEDIUM"]] == 1 && fundValueDurMediumYear == 0)
									if(i <= mvelHashMap["maxMaturityYear"].to_i)
										fundValueDur =true;
										fundValueDurMediumYear = i;
									end
								end
							end
							if(mvelHashMap["avgHIGH"] != nil)
								if(quotationIO.finalMap[i]["fundvaluedur"][mvelHashMap["avgHIGH"]] == 1 && fundValueDurHighYear == 0)
									if(i <= mvelHashMap["maxMaturityYear"].to_i)
										fundValueDur =true;
										fundValueDurHighYear = i;
									end
								end
							end
							if(mvelHashMap["avgVERYLOW"] != nil)
								if(quotationIO.finalMap[i]["fundvaluedur"][mvelHashMap["avgVERYLOW"]] == 1 && fundValueDurVeryLowYear == 0)
									if(i <= mvelHashMap["maxMaturityYear"].to_i)
										fundValueDur =true;
										fundValueDurVeryLowYear = i;
									end
								end
							end
					end
				end
					i=i+1;
				end
					mvelHashMap["FundValueDur"] = fundValueDur
					mvelHashMap["FundValueDurLowYear"] = fundValueDurLowYear
					mvelHashMap["FundValueDurMediumYear"] = fundValueDurMediumYear
					mvelHashMap["FundValueDurHighYear"] = fundValueDurHighYear
					mvelHashMap["FundValueDurVeryLowYear"] = fundValueDurVeryLowYear

				#Changes 05 Nov changes end
				mvelHashMap["footerPageNumber"] = 0
				#changes 12 Nov 2014 end

				mvelHashMap["totalRowsVARFUTable"] = 0
				#changes 29 Dec 2014 start
				if (quotationIO.baseDO.getBaseProduct.product.productFamilyId == "TRAD" && quotationIO.baseDO.QuotationWithdrawalList.size > 0)
					startyear = quotationIO.baseDO.payingYears.to_i+1
					lastyear =(quotationIO.outputPreferencesDO != nil  && quotationIO.outputPreferencesDO.field3 == "YES") ? quotationIO.baseDO.getBaseProduct.productTerm.to_s : quotationIO.finalMap[1]["maxwithdrawaldur"]["0"]
					totalRowsInTable = lastyear.to_i - startyear.to_i + 1
					ageString = getVarfuMileStoneAgeTRAD(mvelHashMap)
					ageArray = ageString.split(',')
					totalRowsInTable = totalRowsInTable + ageArray.size + 1 if ageString.to_s != "500"
					mvelHashMap["totalRowsVARFUTable"] = totalRowsInTable
				end

				#changes 29 Dec 2014 end
				if(quotationIO.baseDO.getBaseProduct.product.productFamilyId == "VUL")
					mvelHashMap["PureMFFAgeList"] = getPureMFFAgeList(mvelHashMap)
				end
				#sun dollar maximizer fund list
				if(fundList == nil || fundList.size <= 0 && quotationIO.baseDO.getBaseProduct.product.productFamilyId == "VUL")
					fd = Fund.new
					facetDO = nil
					product = quotationIO.baseDO.getBasePlan.getProduct
					if(product != nil)
						facetDO = product.getFacet("STRUCTUREDNOTEFUND")
					end
					if facetDO
						fd.fundDesc = facetDO.actionValue
						fd.fundCd = "TEMP"+product.productId.to_s
						fundDOHashMap = mvelHashMap["fundDOHashMap"]
						fundDOHashMap[fd.fundCd] = fd;
						 mvelHashMap["fundDOHashMap"] = fundDOHashMap
						fund = QuotationProductInvestmentFund.new;
						fund.allocationPerc = 100.0;
						fund.fundCd = fd.fundCd;
						fundList.push(fund);
				    end		
				end
				#changes 23 jan 2015 end
				mvelHashMap["isTDB5YRCTSelect"] = false
				if(quotationIO.baseDO.getBaseProduct.product.productFamilyId == "TRAD")
					riderList.each do |rd|
						if(rd.productId == "TDB of 5YRCT")
							mvelHashMap["isTDB5YRCTSelect"] = true
						end
					end
				end

				iswaterMark = false
				if quotationIO.baseDO.uploadFlag.to_s == "YES"
					iswaterMark = true
				else
					if quotationIO.baseDO.quoteStatusCd.to_s != "" && quotationIO.baseDO.quoteStatusCd.to_s =="COMPLETED"
							iswaterMark = true
					else
							iswaterMark = false
					end
				end
				mvelHashMap["waterMark"] = iswaterMark
		end

		def self.getPureMFFAgeList(mvelHashMap)
			maxMaturityYear = mvelHashMap["maxMaturityYear"].to_i
			quotationIO = mvelHashMap["quotationIO"]
			isPureMyFutureFund = mvelHashMap["isPureMyFutureFund"]
			age =  quotationIO.baseDO.getPartyByRole("PRIMARY").age.to_i
			pureMFFAgeList = nil
			if(isPureMyFutureFund && maxMaturityYear < quotationIO.baseDO.getBaseProduct.productTerm)
				pureMFFAgeList = []
				i = 3
				b=(maxMaturityYear/4).to_i
				while(i >= 0)
					pureMFFAgeList.push((maxMaturityYear - (b*i) + age).to_s)
					i = i - 1
				end
				return pureMFFAgeList
			else
				return nil
			end
		end


		def self.getApoRate(mvelHashMap, fundCd)
			rateDOList = mvelHashMap["apoIllustrationRateDOsList"]
			rateHashMap = {}
			rateDOList.each do |illustrationRateDO|
				if illustrationRateDO.fundCd != nil && illustrationRateDO.fundCd.casecmp(fundCd).zero? &&
						illustrationRateDO.rateTypeCd.casecmp("High").zero?
					rateHashMap["High"] = illustrationRateDO.rate.to_s
				elsif illustrationRateDO.fundCd != nil && illustrationRateDO.fundCd.casecmp(fundCd).zero? &&
						illustrationRateDO.rateTypeCd.casecmp("Medium").zero?
					rateHashMap["Medium"] = illustrationRateDO.rate.to_s
				elsif illustrationRateDO.fundCd != nil && illustrationRateDO.fundCd.casecmp(fundCd).zero? &&
						illustrationRateDO.rateTypeCd.casecmp("Low").zero?
					rateHashMap["Low"] = illustrationRateDO.rate.to_s
				end
			end
			return rateHashMap;
		end

		def self.getRate(mvelHashMap, fundCd)

		  	illustrationRateDOsListAll = mvelHashMap["quotationIO"].originalSIModel.IllustrationRateList
			#puts ">>>>>>illustrationRateDOsListAll....#{illustrationRateDOsListAll.inspect}"
			rateDOList = mvelHashMap["illustrationRateDOsListAll"]
			rateHashMap = {}
	  		illustrationRateDOsListAll.each do |illustrationRateDO|
				if illustrationRateDO.fundCd != nil && illustrationRateDO.fundCd.casecmp(fundCd).zero? &&
						illustrationRateDO.rateTypeCd.casecmp("High").zero?
					rateHashMap["High"] = illustrationRateDO.rate.to_s
				elsif illustrationRateDO.fundCd != nil && illustrationRateDO.fundCd.casecmp(fundCd).zero? &&
						illustrationRateDO.rateTypeCd.casecmp("Medium").zero?
					rateHashMap["Medium"] = illustrationRateDO.rate.to_s
				elsif illustrationRateDO.fundCd != nil && illustrationRateDO.fundCd.casecmp(fundCd).zero? &&
						illustrationRateDO.rateTypeCd.casecmp("Low").zero?
					rateHashMap["Low"] = illustrationRateDO.rate.to_s
				elsif illustrationRateDO.fundCd != nil && illustrationRateDO.fundCd.casecmp(fundCd).zero? &&
						illustrationRateDO.rateTypeCd.casecmp("VeryLow").zero?
					rateHashMap["VeryLow"] = illustrationRateDO.rate.to_s
				end
			end
			return rateHashMap;
		end

		def self.getFundWithdrawalAgeCondition(quotationIO)
			finalString="";
			begin
				maxWithdrawalYear = quotationIO.finalMap[1]["maxwithdrawaldur"]["0"].to_i
			rescue
				maxWithdrawalYear=20;
			end
			beginingYear = 20;
			issueAge = quotationIO.baseDO.getPartyByRole("PRIMARY").age.to_i
			if(maxWithdrawalYear > 20)
				beginingYear = maxWithdrawalYear;
			end

			i=beginingYear+5
			while i<(88-issueAge.to_i) do
				finalString << (i.to_s + ",")
				i=i+5
			end
			finalString=finalString.length>1 ? finalString[0,finalString.length-1] : "500";
			return finalString;
		end

		def  self.getDTRate(quotationIO,policyYear,dtName)
			ruleSeq = 0.0;
			quotationIO.illustrationModel.IllustrationFacetList.each do |illustrationFacetDO|
				if illustrationFacetDO.computedElementName != nil &&
					illustrationFacetDO.computedElementName.casecmp(dtName).zero?
					ruleSeq =  illustrationFacetDO.ruleSeq
					break;
				end
			end
			quotationIO.baseDO.policyYear = policyYear
			dtd = MobiSys::ProductBO.getProductDefinitionTable(ruleSeq, quotationIO.baseDO, quotationIO.baseDO.getBasePlan)
			if(dtd != nil)
				rate = dtd.rate.to_f * 100
				return rate.to_i.to_s
			else
				return "";
			end
		end

		def self.getDTFundRate( quotationIO, mvelHashMap, dtName = nil)
			fundRate = nil;
			ruleSeq = 0.0;
			quotationIO.illustrationModel.IllustrationFacetList.each do |illustrationFacetDO|
				if illustrationFacetDO.computedElementName != nil &&
					illustrationFacetDO.computedElementName.casecmp(dtName.to_s).zero?
					ruleSeq =  illustrationFacetDO.ruleSeq
					break;
				end
			end
			dtd = MobiSys::ProductBO.getProductDefinitionTableList(ruleSeq, quotationIO.baseDO, quotationIO.baseDO.getBasePlan);
			quotationIO.baseDO.getBaseProduct.QuotationProductInvestmentFundList.each do |investmentFundDO|
				if(dtd != nil && dtd != [])
					dtd.each do |dt|
						if investmentFundDO.fundCd == dt.fundCd
							mvelHashMap["fmcFundRate"+investmentFundDO.fundCd] = dt.rate
						end
					end
				end
			end
		end

		def self.getFundNotes(quotationIO, fundID, mvelHashMap, fmcRate)
			rate = quotationIO.finalMap[1]["loyaltybonusaate"]["0"].to_f * 100
			finalString = "";
			if(quotationIO.baseDo.getBaseProduct.productId == "FLRP0B")
				finalString = finalString.concat("<p class=\"fontSize12 fontFamilyGFB\"> The projected values are net of: (a) premium charges of ")
				finalString = finalString.concat(UIGenUtilCompanyHelper.getDTRate(quotationIO,1,"BasicPremiumCharge"))
				finalString = finalString.concat("% of annual regular premium on the first policy year and ")
				finalString = finalString.concat(UIGenUtilCompanyHelper.getDTRate(quotationIO,2,"BasicPremiumCharge"))
				finalString = finalString.concat("% of annual regular premium from the second to the tenth year, all excess premiums shall be subject to a premium charge of ")
				finalString = finalString.concat(UIGenUtilCompanyHelper.getDTRate(quotationIO,11,"BasicPremiumCharge"))
				finalString = finalString.concat("%$SEMI$ (b) monthly periodic charge of ")
				finalString = finalString.concat(UIGenUtilCompanyHelper.getDTRate(quotationIO,2,"PeriodicCharge"))
				finalString = finalString.concat("%of the annual regular premium on the second year,")
				finalString = finalString.concat(UIGenUtilCompanyHelper.getDTRate(quotationIO,3,"PeriodicCharge"))
				finalString = finalString.concat("% on the third year and ")
				finalString = finalString.concat(UIGenUtilCompanyHelper.getDTRate(quotationIO,4,"PeriodicCharge"))
				finalString = finalString.concat("% on the fourth and fifth year and monthly insurance charges; and (c) a fund management charge of ")
				finalString = finalString.concat(fmcRate)
				finalString = finalString.concat("% (plus VAT) of the fund value. The figures shown above are net of all charges. The monthly charges are deducted from the fund. No premium charge and monthly periodic charge are imposed on any extra premium and additional benefit premium.  </p>   <p class=\"fontSize12 fontFamilyGFB\">  A loyalty bonus on the 10th policy anniversary year and every 5 years thereafter is included in the above illustration. The loyalty bonus is currently equal to ")
				finalString = finalString.concat(rate.to_i.to_s)
				finalString = finalString.concat(" of the average monthly fund balance of the preceding 5 years. It is non-guaranteed and it will depend on the actual performance of the fund.   </p>   <p class=\"fontSize12 fontFamilyGFB\">   You should only invest in this product if you intend to pay the regular remium for the whole of your chosen payment term. Should you terminate the policy early, you may suffer a loss as illustrated above.   </p>")
			elsif(quotationIO.getBaseProduct.productId =="FL1P0A")
				finalString = finalString.concat("<p class=\"fontSize12 fontFamilyGFB\">The projected values are net of premium charge of ")
				finalString = finalString.concat(UIGenUtilCompanyHelper.getDTRate(quotationIO,1,"BasicPremiumCharge"))
				finalString = finalString.concat("% of the single premium, all excess premiums shall be subject to a premium charge of ")
				finalString = finalString.concat(UIGenUtilCompanyHelper.getDTRate(quotationIO,2,"BasicPremiumCharge"))
				finalString = finalString.concat("%$SEMI$ fund management charge of ")
				finalString = finalString.concat(fmcRate)
				finalString = finalString.concat("% (plus VAT) of the fund value; and insurance charges shall be deducted monthly from the investment fund. The figures shown above are net of all charges.   </p>   <p class=\"fontSize12 fontFamilyGFB\"> A loyalty bonus on the 10th policy anniversary year and every 5 years thereafter is included in the above illustration. The loyalty bonus is currently equal to  ")
				finalString = finalString.concat(rate.to_i.to_s )
				finalString = finalString.concat("% of the average monthly fund balance of the preceding 5 years. It is non-guaranteed and it will depend on the actual performance of the fund.   </p>  <p class=\"fontSize12 fontFamilyGFB\">  You should only invest in this product if you intend to pay the regular premium for the whole of your chosen payment term. Should you terminate the policy early, you may suffer a loss as illustrated above.  </p>")
			elsif(quotationIO.getBaseProduct.productId =="FD1U0A")
				finalString = finalString.concat("  <p class=\"fontSize12 fontFamilyGFB\">The projected values are net of premium charge of ")
				finalString = finalString.concat(	UIGenUtilCompanyHelper.getDTRate(quotationIO,1,"BasicPremiumCharge"))
				finalString = finalString.concat("% of the single premium, all excess premiums shall be subject to a premium charge of ")
				finalString = finalString.concat(UIGenUtilCompanyHelper.getDTRate(quotationIO,2,"BasicPremiumCharge"))
				finalString = finalString.concat("%$SEMI$ fund management charge of ")
				finalString = finalString.concat(fmcRate)
				finalString = finalString.concat("% (plus VAT) of the fund value; and insurance charges for the (1) basic benefit and, (2) additional death benefit as shown in the Proposal Information page, if any shall be deducted monthly from the investment fund. The figures shown above are net of all charges.  </p>  <p class=\"fontSize12 fontFamilyGFB\"> A loyalty bonus on the 10th policy anniversary year and every 5 years thereafter is included in the above illustration. The loyalty bonus is currently equal to ")
				finalString = finalString.concat(rate.to_i.to_s )
				finalString = finalString.concat("% of the average monthly fund balance of the preceding 5 years. It is non-guaranteed and it will depend on the actual performance of the fund.   </p>   <p class=\"fontSize12 fontFamilyGFB\">   You should only invest in this product if you intend to pay the regular premium for the whole of your chosen payment term. Should you terminate the policy early, you may suffer a loss as illustrated above.  </p>")
			elsif(quotationIO.getBaseProduct.productId =="MD1U0A" ||quotationIO.getBaseProduct.productId =="ML1P0A")
				finalString = finalString.concat("<p class=\"fontSize12 fontFamilyGFB\"> The projected values are net of a fund management charge of ")
				finalString = finalString.concat(fmcRate)
				finalString = finalString.concat("% (plus VAT) of the fund value; and insurance charges shall be deducted monthly from the investment fund. The figures shown above are net of all charges.   </p>  <p class=\"fontSize12 fontFamilyGFB\">")
				if(quotationIO.finalMap[1].has_Key?("surrendercharges"))
				finalString = finalString.concat( "Cash Surrender Value is equal to the Fund Value less Surrender Charge and is payable in case of policy surrender. Surrender Charges during the first five (5) years are " +
						UIGenUtilCompanyHelper.getDTRate(quotationIO,1,"SurrenderCharges")+"%, "+UIGenUtilCompanyHelper.getDTRate(quotationIO,2,"SurrenderCharges")+"%, "+UIGenUtilCompanyHelper.getDTRate(quotationIO,3,"SurrenderCharges")+"%, "+UIGenUtilCompanyHelper.getDTRate(quotationIO,4,"SurrenderCharges")+"% and "+UIGenUtilCompanyHelper.getDTRate(quotationIO,5,"SurrenderCharges")+"% of the Fund Value, respectively. The policy value could be lower than the premium paid. Partial withdrawal during the 1st 5 years shall also be subject to the same charges as above.")
				end
				finalString = finalString.concat("</p>  <p class=\"fontSize12 fontFamilyGFB\"> A loyalty bonus on the 10th policy anniversary year and every 5 years thereafter is included in the above illustration. The loyalty bonus is currently equal to ")
				finalString = finalString.concat(rate.to_i.to_s)
				finalString = finalString.concat("% of the average monthly fund balance of the preceding 5 years. It is non-guaranteed and it will depend on the actual performance of the fund.  </p>")
				if quotationIO.baseDO.getBasePlan !=nil && quotationIO.baseDO.getBasePlan.addtnField1 != nil && quotationIO.baseDO.getBasePlan.addtnField1 == "GIO"
					finalString=finalString.concat("<p class=\"fontSize12 fontFamilyGFB\">  The Death Benefit illustrated for the first two years is based on the assumption that the policy is settled under GIO and death is due to causes other than accident. In case of death due to accident within the first two policy years, death benefit will be equal to the higher of (1) the Fund Value or (2) the minimum death benefit. </p>   <p class=\"fontSize12 fontFamilyGFB\">   The term ''accident'' as used in this proposal, shall mean an unforeseen and involuntary event, which causes a bodily injury independently of disease,medical or surgical treatment. </p>   <p class=\"fontSize12 fontFamilyGFB\">   Death of the life insured from an accident must occur within one year from the date of the accident and is not as a result of any of the following: (a)homicide$SEMI$ (b) suicide$SEMI$ (c) poison, carbon monoxide or drug overdose$SEMI$ (d) self-inflicted firearm injury$SEMI$ (e) committing a criminal offense$SEMI$ and (f)insurrection, civil commotion or hostile action of armed forces, whether or not the life insured was actually participating therein. </p>")
				end
			elsif(quotationIO.getBaseProduct.productId =="FLVP0A")
				 finalString = finalString.concat(" <p class=\"fontSize12 fontFamilyGFB\"> The projected values are net of: (a) premium charges of ")
				 finalString = finalString.concat(UIGenUtilCompanyHelper.getDTRate(quotationIO,1,"BasicPremiumCharge"))
				 finalString = finalString.concat("% of annual regular premium on the first policy year and ")
				 finalString = finalString.concat(UIGenUtilCompanyHelper.getDTRate(quotationIO,2,"BasicPremiumCharge"))
				 finalString = finalString.concat("% of annual regular premium from the second to third year, all excess premiums shall be subject to a premium charge of ")
				 finalString = finalString.concat(UIGenUtilCompanyHelper.getDTRate(quotationIO,4,"BasicPremiumCharge"))
				 finalString = finalString.concat("%$SEMI$ (b) monthly periodic charge of ")
				 finalString = finalString.concat(UIGenUtilCompanyHelper.getDTRate(quotationIO,2,"PeriodicCharge"))
				 finalString = finalString.concat("$ of the annual regular premium on the second year, ")
				 finalString = finalString.concat(UIGenUtilCompanyHelper.getDTRate(quotationIO,3,"PeriodicCharge"))
				 finalString = finalString.concat("% on the third to fifth year; (c) monthly insurance charge of ")
				 finalString = finalString.concat((quotationIO.finalMap[1]["mic"]["0"] *100).to_i.to_s)
				 finalString = finalString.concat("% of the Face Amount multiplied by the insurance rate determined by the Company, plus additional benefit premiums, if any; and (d) a fund management charge of ")
				 finalString = finalString.concat(fmcRate)
				 finalString = finalString.concat("% (plus VAT) of the fund value. The figures shown above are net of all charges. The monthly charges are deducted from the fund. No premium charge and monthly periodic charge are imposed on any extra premium and additional benefit premium.  </p>  <p class=\"fontSize12 fontFamilyGFB\"> A loyalty bonus on the 10th policy anniversary year and every 5 years thereafter is included in the above illustration. The loyalty bonus is currently equal to ")
				 finalString = finalString.concat(rate.to_i.to_s)
				 finalString = finalString.concat("% of the average monthly fund balance of the preceding 5 years. It is non-guaranteed and it will depend on the actual performance of the fund.   </p>  <p class=\"fontSize12 fontFamilyGFB\">  You should only invest in this product if you intend to pay the regular premium for the whole of your chosen payment term. Should you terminate the policy early, you may suffer a loss as illustrated above.   </p>")
			elsif(quotationIO.getBaseProduct.productId =="FLXP0A")
				finalString = finalString.concat(" <p class=\"fontSize12 fontFamilyGFB\"> The projected values are net of: (a) premium charges of ")
				finalString = finalString.concat(UIGenUtilCompanyHelper.getDTRate(quotationIO,1,"BasicPremiumCharge"))
				finalString = finalString.concat("% of annual regular premium on the first policy year and ")
				finalString = finalString.concat(UIGenUtilCompanyHelper.getDTRate(quotationIO,2,"BasicPremiumCharge"))
				finalString = finalString.concat("% of annual regular premium from the second to the fifth year, all excess premiums shall be subject to a premium charge of ")
				finalString = finalString.concat(UIGenUtilCompanyHelper.getDTRate(quotationIO,6,"BasicPremiumCharge"))
				finalString = finalString.concat("%$SEMI$ (b) monthly periodic charge of ")
				finalString = finalString.concat(UIGenUtilCompanyHelper.getDTRate(quotationIO,2,"PeriodicCharge"))
				finalString = finalString.concat("% of the annual regular premium on the second year, ")
				finalString = finalString.concat(UIGenUtilCompanyHelper.getDTRate(quotationIO,3,"PeriodicCharge"))
				finalString = finalString.concat("% on the third year and ")
				finalString = finalString.concat(UIGenUtilCompanyHelper.getDTRate(quotationIO,4,"PeriodicCharge"))
				finalString = finalString.concat("% on the fourth and fifth; (c) monthly insurance charge of ")
				finalString = finalString.concat((quotationIO.finalMap[1]["mic"]["0"] * 100).to_i.to_s)
				finalString = finalString.concat("% of the Face Amount multiplied by the insurance rate determined by the Company, plus additional benefit premiums, if any; and (d) a fund management charge of ")
				finalString = finalString.concat(fmcRate)
				finalString = finalString.concat("% (plus VAT) of the fund value. The figures shown above are net of all charges. The monthly charges are deducted from the fund. No premium charge and monthly periodic charge are imposed on any extra premium and additional benefit premium.  </p>  <p class=\"fontSize12 fontFamilyGFB\"> A loyalty bonus on the 10th policy anniversary year and every 5 years thereafter is included in the above illustration. The loyalty bonus is currently equal to ")
				finalString = finalString.concat(rate.to_i.to_s)
				finalString = finalString.concat("% of the average monthly fund balance of the preceding 5 years. It is non-guaranteed and it will depend on the actual performance of the fund.   </p>  <p class=\"fontSize12 fontFamilyGFB\">  You should only invest in this product if you intend to pay the regular premium for the whole of your chosen payment term. Should you terminate the policy early, you may suffer a loss as illustrated above.  </p>")
			elsif(quotationIO.getBaseProduct.productId =="FDRU0B")
				finalString = finalString.concat("  <p class=\"fontSize12 fontFamilyGFB\">The projected values are net of: (a) premium charges of ")
				finalString = finalString.concat(UIGenUtilCompanyHelper.getDTRate(quotationIO,1,"BasicPremiumCharge"))
				finalString = finalString.concat("% of annual regular premium on the first policy year and ")
				finalString = finalString.concat(UIGenUtilCompanyHelper.getDTRate(quotationIO,2,"BasicPremiumCharge"))
				finalString = finalString.concat("% of annual regular premium from the second to the tenth year, all excess premiums shall be subject to a premium charge of ")
				finalString = finalString.concat(UIGenUtilCompanyHelper.getDTRate(quotationIO,11,"BasicPremiumCharge"))
				finalString = finalString.concat("%$SEMI$ (b) monthly periodic charge of ")
				finalString = finalString.concat(UIGenUtilCompanyHelper.getDTRate(quotationIO,2,"PeriodicCharge"))
				finalString = finalString.concat("% of the annual regular premium on the second year, ")
				finalString = finalString.concat(UIGenUtilCompanyHelper.getDTRate(quotationIO,3,"PeriodicCharge"))
				finalString = finalString.concat("% on the third year and ")
				finalString = finalString.concat(UIGenUtilCompanyHelper.getDTRate(quotationIO,4,"PeriodicCharge"))
				finalString = finalString.concat("% on the fourth and fifth year and monthly insurance charges; and (c) a fund management charge of ")
				finalString = finalString.concat(fmcRate)
				finalString = finalString.concat("% (plus VAT) of the fund value. The figures shown above are net of all charges. The monthly charges are deducted from the fund. No premium charge and monthly periodic charge are imposed on any extra premium and additional benefit premium.   </p>  <p class=\"fontSize12 fontFamilyGFB\"> A loyalty bonus on the 10th policy anniversary year and every 5 years thereafter is included in the above illustration. The loyalty bonus is currently equal to ")
				finalString = finalString.concat(rate.to_i.to_s)
				finalString = finalString.concat("% of the average monthly fund balance of the preceding 5 years. It is non-guaranteed and it will depend on the actual performance of the fund.  </p>  <p class=\"fontSize12 fontFamilyGFB\">  You should only invest in this product if you intend to pay the regular premium for the whole of your chosen payment term. Should you terminate the policy early, you may suffer a loss as illustrated above.  </p>")
			end
			return finalString;
		end

		def self.getMileStoneAges(quotationIO)
			if (quotationIO.baseDO.getPartyByRole("PRIMARY").age.to_i != nil)
				ageValue = quotationIO.baseDO.getPartyByRole("PRIMARY").age.to_i;
				if(ageValue >= 65)
					return "500";
				elsif(ageValue > 60)
					return "65";
				elsif(ageValue > 55)
					return "60,65";
				else
					return "55,60,65";
				end
			else
				return "500";
			end
		end

		def self.getFundWithdrawalCondition(quotationIO, avgLOW)
			totalFV=0;
			if(quotationIO.finalMap[(quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["maxwithdrawaldur"]["0"].to_i+1).to_i]["totalfv"] != nil)
				totalFVString = quotationIO.finalMap[(quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["maxwithdrawaldur"]["0"].to_i+1).to_i]["totalfv"][avgLOW]
			end
			if(totalFVString.to_f >10000)
				return true;
			end
			return false;
		end

	def self.getRiderPremiumTable(quotationIO, riderId, riderPremiumElement, quotationProductDO, tableCount)
		productDO = Product.loadObject(:first, :conditions => {{:name => 'id'} => quotationProductDO.productSeq })
		productName=productDO.longName;
		counter = 0;
		tblCounter = 0;
		productTerm= quotationProductDO.productTerm;
		sb="";
		upperLimit=0;
		lowerLimit = 0;
		isTableCreated = false;
		isSingleTable = (tableCount == "SINGLE") ? true : false
		riderPremium = 0;
		isCalanderYearIllustration = false;
		isAgeIllustration=false;

		upperLimitTemp = 0;
		lowerLimitTemp = 0;
		riderDur = 0;
		tableWidth = ""
		isDoubleRowReq = false;
		isDoubleRowReqTemp = false;

		issueAge = quotationIO.baseDO.getPartyByRole("PRIMARY").age.to_i;
		currCalanderYear = DateTime.strptime(quotationIO.baseDO.quotationDt.to_s,"%Y-%m-%d %H:%M:%S %z").year

			if(quotationProductDO.QuotationProductExtraList.size() > 0)
				quotationProductDO.QuotationProductExtraList.each do |quotationProductExtraDO|
							if(quotationProductExtraDO.extraTypeCd != nil && quotationProductExtraDO.extraFlatDuration != nil && quotationProductExtraDO.extraFlatDuration != "")
									riderDur = quotationProductExtraDO.extraFlatDuration.to_i;
							elsif(quotationProductExtraDO.extraTypeCd != nil && quotationProductExtraDO.extraPercDuration != nil && quotationProductExtraDO.extraPercDuration != "")
									riderDur = quotationProductExtraDO.extraPercDuration.to_i;
							end
				end
			end
			 i = 1
			for i in  i ..productTerm
				if(quotationIO.finalMap[i.to_i] != nil &&  (i-1)%5 == 0)
					lowerLimit=i;
					if(i+4 > productTerm)
					   upperLimit=productTerm.to_i;
					else
					   upperLimit=i+4;
					end
					if(riderDur >= lowerLimit && riderDur < upperLimit)
						isDoubleRowReqTemp = true;
						break;
					end
				end
			end
			if(((productTerm > 30) || (productTerm <= 30 && productTerm > 25 && (isDoubleRowReqTemp))) && !(isSingleTable))
						tableWidth = "60";
					else
						isSingleTable = true;
						tableWidth = "30";
					end

					if(isSingleTable)
						tableWidth = "30";
					end


			if quotationIO.outputPreferencesDO != nil && quotationIO.outputPreferencesDO.field2 == "CALENDARYEAR"
				isCalanderYearIllustration=true;
			end
			#Changes 24 Sept start
			if quotationIO.outputPreferencesDO != nil && quotationIO.outputPreferencesDO.field2 == "AGE"
				isAgeIllustration = true;
			end
			#end Changes 24 Sept start
	  		sb << "<table width=\"100%\"><tr>"
			if(isSingleTable)
				sb << "<td style=\"text-align:center;padding-right:20px;vertical-align:top\">"
			else
				sb << "<td width=\"50%\" "
				sb << " style=\"text-align:center;padding-right:20px;vertical-align:top\">"
			end
			if(isCalanderYearIllustration)
				sb << "<table align=\"center\" style=\"border-collapse:collapse;border-spacing:0px;width:"+tableWidth+"%; border-spacing:0px;border:1px solid black;\"class=\"fontSize12 fontFamilyGFB\"><tr> <td style=\"text-align: center;border:1px solid black;width:35%\">Year</td>	<td style=\"text-align: center;border:1px solid black;width:65%\">" + productName + " Premium</td></tr>			  "
			elsif(isAgeIllustration)
				sb << "<table align=\"center\" style=\"border-collapse:collapse;border-spacing:0px;width:"+tableWidth+"%;border-spacing:0px;border:1px solid black;\"class=\"fontSize12 fontFamilyGFB\"><tr> <td style=\"text-align: center;border:1px solid black;width:35%\">Age</td>	<td style=\"text-align: center;border:1px solid black;width:65%\">" + productName + " Premium</td></tr>			  "
			#Changes 24 Sept end
			else
				sb << "<table align=\"center\" style=\"border-collapse:collapse;border-spacing:0px;width:"+tableWidth+"%;border-spacing:0px;border:1px solid black;\"class=\"fontSize12 fontFamilyGFB\"><tr> <td style=\"text-align: center;border:1px solid black;width:35%\">Duration</td>	<td style=\"text-align: center;border:1px solid black;width:65%\">" + productName + " <br>Premium</td></tr>			  "
			end


		i = 1
		for i in  i ..productTerm
		if(quotationIO.finalMap[i.to_i] != nil &&  (i-1)%5 == 0)
		  lowerLimit=i;
		  if(i+4 > productTerm)
			upperLimit=productTerm.to_i;
		  else
			upperLimit=i+4;
		  end
		  # if(lowerLimit==upperLimit)
		  #   sb<< "<tr>  <td style=\"text-align:center\">"
		  #   sb<< lowerLimit.to_s
		  #   sb<< "</td>"
		  #   riderPremium = quotationIO.finalMap[lowerLimit.to_i][riderPremiumElement.downcase]["0" + riderId] != nil ? quotationIO.finalMap[lowerLimit.to_i][riderPremiumElement.downcase]["0" + riderId].to_f : 0;
		  # else

			if(riderDur >= lowerLimit && riderDur < upperLimit)
				upperLimitTemp = riderDur;
				lowerLimitTemp = riderDur + 1;
				isDoubleRowReq = true;
			else
				upperLimitTemp = upperLimit;
				lowerLimitTemp = lowerLimit;
				isDoubleRowReq = false;
			end


		  if(isTableCreated)
			  isTableCreated = false;
			if(isCalanderYearIllustration)
							sb << "<table align=\"center\" style=\"border-collapse:collapse;border-spacing:0px;width:60%; border-spacing:0px;border:1px solid black;\"class=\"fontSize12 fontFamilyGFB\"><tr> <td style=\"text-align: center;border:1px solid black;width:35%\">Year</td>	<td style=\"text-align: center;border:1px solid black;width:65%\">" + productName + " Premium</td></tr>			  "
						elsif(isAgeIllustration)
									sb << "<table align=\"center\" style=\"border-collapse:collapse;border-spacing:0px;width:60%; border-spacing:0px;border:1px solid black;\"class=\"fontSize12 fontFamilyGFB\"><tr> <td style=\"text-align: center;border:1px solid black;width:35%\">Age</td>	<td style=\"text-align: center;border:1px solid black;width:65%\">" + productName + " Premium</td></tr>			  "
								#/Changes 24 Sept end
						else
							sb << "<table align=\"center\" style=\"border-collapse:collapse;border-spacing:0px;width:60%; border-spacing:0px;border:1px solid black;\"class=\"fontSize12 fontFamilyGFB\"><tr> <td style=\"text-align: center;border:1px solid black;width:35%\">Duration</td>	<td style=\"text-align: center;border:1px solid black;width:65%\">" + productName + " <br>Premium</td></tr>			  "
						end
			  # sb << "<table class=\"SLFPremiumSchedTable fontSize12 fontFamilyGFB\" style=\"\"> <tr> <td class=\"header\">Duratio</td>  <td class=\"header\">" + productName + " Premium</td>     </tr>       "
		  end

		riderPremium = quotationIO.finalMap[lowerLimit.to_i][riderPremiumElement.downcase]["0" + riderId] != nil ? quotationIO.finalMap[lowerLimit.to_i][riderPremiumElement.downcase]["0" + riderId].to_f : 0

		  if(isCalanderYearIllustration)
						lowerLimit = lowerLimit + currCalanderYear - 1;
						#upperLimit = upperLimit + currCalanderYear - 1;
						upperLimitTemp = upperLimitTemp + currCalanderYear - 1;
				  end
				  #Changes 24 Sept start
					if(isAgeIllustration)
						lowerLimit = lowerLimit + issueAge - 1;
						#upperLimit = upperLimit + issueAge - 1;
						upperLimitTemp = upperLimitTemp + issueAge - 1;
					end
					#Changes 24 Sept end
					if(lowerLimit==upperLimitTemp)
					counter = counter +1;
			  sb<< "<tr>	<td style=\"text-align:center;border-right:1px solid black\">"
			  sb<< lowerLimit.to_s
			  sb<< "</td>"
		  else
			  # riderPremium = quotationIO.finalMap[lowerLimit.to_i][riderPremiumElement.downcase]["0" + riderId] != nil ? quotationIO.finalMap[lowerLimit.to_i][riderPremiumElement.downcase]["0" + riderId].to_f : 0;
			counter = counter +1;
			sb<< "<tr>	<td style=\"text-align:center;border-right:1px solid black\">"
			sb<< lowerLimit.to_s
			sb<< " - "
			sb<< upperLimitTemp.to_s
			sb<< "</td>"
		  end
		# end
		sb<< "<td style=\"text-align:right;border-right:1px solid black;padding-right:2px\">"
		sb<< UIGenUtilCompanyHelper.getFormatDoubleTwoDecimalWithComma(riderPremium.to_s);
		sb<< "</td> </tr>"
		if !(isSingleTable)
			if(counter == 6)
				tblCounter = tblCounter +1;
				if(tblCounter < 2)
				  sb << "</table> </td> <td width=\"50%\" style=\"text-align:left;padding-right:20px;vertical-align:top;\">"
				  isTableCreated = true;
				  counter = 0;
				end
			  end
			end

			if(isDoubleRowReq)
				if(isTableCreated)
					isTableCreated = false;
						if(isCalanderYearIllustration)
							sb << "<table align=\"center\" style=\"border-collapse:collapse;border-spacing:0px;width:60%; border-spacing:0px;border:1px solid black;\"class=\"fontSize12 fontFamilyGFB\">	<tr> <td style=\"text-align: center;border:1px solid black;width:35%\">Year</td>	<td style=\"text-align: center;border:1px solid black;width:65%\">" + productName + " Premium</td>		  </tr>			  "
						elsif(isAgeIllustration)
									sb << "<table align=\"center\" style=\"border-collapse:collapse;border-spacing:0px;width:60%; border-spacing:0px;border:1px solid black;\"class=\"fontSize12 fontFamilyGFB\">	<tr> <td style=\"text-align: center;border:1px solid black;width:35%\">Age</td>	<td style=\"text-align: center;border:1px solid black;width:65%\">" + productName + " Premium</td>		  </tr>			  "
								#/Changes 24 Sept end
					else
						sb << "<table align=\"center\" style=\"border-collapse:collapse;border-spacing:0px;width:60%; border-spacing:0px;border:1px solid black;\"class=\"fontSize12 fontFamilyGFB\">	<tr> <td style=\"text-align: center;border:1px solid black;width:35%\">Duration</td>	<td style=\"text-align: center;border:1px solid black;width:65%\">" + productName + " <br>Premium</td>		  </tr>			  "
					end
				# sb << "<table class=\"SLFPremiumSchedTable fontSize12 fontFamilyGFB\" style=\"\"> <tr> <td class=\"header\">Duratio</td>  <td class=\"header\">" + productName + " Premium</td>     </tr>       "
			end
		riderPremium = quotationIO.finalMap[lowerLimitTemp.to_i][riderPremiumElement.downcase]["0" + riderId] != nil ? quotationIO.finalMap[lowerLimitTemp.to_i][riderPremiumElement.downcase]["0" + riderId].to_f : 0

		if(isCalanderYearIllustration)
			lowerLimitTemp = lowerLimitTemp + currCalanderYear - 1;
			upperLimit = upperLimit + currCalanderYear - 1;
		end
		#Changes 24 Sept start
		if(isAgeIllustration)
			lowerLimitTemp = lowerLimitTemp + issueAge - 1;
			upperLimit = upperLimit + issueAge - 1;
		end
		#Changes 24 Sept end
		if(lowerLimitTemp==upperLimit)
			counter = counter +1;
			sb<< "<tr>	<td style=\"text-align:center;border-right:1px solid black\">"
			sb<< lowerLimitTemp.to_s
			sb<< "</td>"
		else
			  # riderPremium = quotationIO.finalMap[lowerLimit.to_i][riderPremiumElement.downcase]["0" + riderId] != nil ? quotationIO.finalMap[lowerLimitTemp.to_i][riderPremiumElement.downcase]["0" + riderId].to_f : 0;
			counter = counter +1;
			sb<< "<tr>	<td style=\"text-align:center;border-right:1px solid black\">"
			sb<< lowerLimitTemp.to_s
			sb<< " - "
			sb<< upperLimit.to_s
			sb<< "</td>"
		end
		# end
		sb<< "<td style=\"text-align:right;border-right:1px solid black;padding-right:2px\">"
		sb<< UIGenUtilCompanyHelper.getFormatDoubleTwoDecimalWithComma(riderPremium.to_s);
		sb<< "</td> </tr>"
		if !(isSingleTable)
			if(counter == 6)
				tblCounter = tblCounter +1;
				if(tblCounter < 2)
				  sb << "</table> </td> <td width=\"50%\" style=\"text-align:left;padding-right:20px;vertical-align:top;\">"
				  isTableCreated = true;
				  counter = 0;
				end
			end
		end
	end
	  end
	  end

	  if(counter < 6 && tblCounter == 1)
		i = 1
		while i <= (6-counter) do
		sb << ("<tr>	<td style=\"text-align:center;border-right:1px solid black\"> &nbsp; </td><td style=\"text-align:center;border-right:1px solid black\"> &nbsp; </td> </tr>");
		i = i+1
		end
	end

	  sb<< "</table></td> </tr> </table>"
	  return sb.to_s;
		end

		def self.getRiderPremiumSingleTable(quotationIO, riderId, riderPremiumElement, quotationProductDO)
			productDO = Product.loadObject(:first, :conditions => {{:name => 'id'} => quotationProductDO.productSeq })
			productName = productDO.longName
			productTerm= quotationProductDO.productTerm
			sb = ""
			upperLimit=0;
			lowerLimit = 0;
			riderPremium = 0;
			sb.concat("<table class=\"SLFPremiumSchedTable fontSize12 fontFamilyGFB\" align=\"center\">	<tr> <td class=\"header\">Duration</td>	<td class=\"header\">" + productName + " Premium</td>		  </tr>			  ")
			i = 1
			for i in i..productTerm
				if(quotationIO.finalMap[i.to_i] != nil &&  (i-1)%5 == 0)
					lowerLimit=i;
					if(i+4 > productTerm)
						upperLimit=productTerm;
					else
						upperLimit=i+4;
					end

					if(lowerLimit==upperLimit)
						sb.concat("<tr>	<td style=\"text-align:center\">")
						sb.concat(lowerLimit)
						sb.concat("</td>")
					else
						sb.concat("<tr>	<td style=\"text-align:center\">")
						sb.concat(lowerLimit)
						sb.concat(" - ")
						sb.concat(upperLimit )
						sb.concat("</td>")
					end
					riderPremium = quotationIO.finalMap[lowerLimit.to_i][riderPremiumElement.downcase]["0" + riderId] != nil ? quotationIO.finalMap[lowerLimit.to_i][riderPremiumElement.downcase]["0" + riderId].to_f : 0;
					sb.concat("<td style=\"text-align:right\">")
					sb.concat(getFormatDoubleTwoDecimalWithComma(riderPremium))
					sb.concat("</td> </tr>")
				end
			end
			sb.concat("</table>");
			return sb.toString();
		end

		def self.getPolicyYearTRADWithPYear(inQuotationIO, mvelHashMap, field)
			outputPreferencesDO = mvelHashMap["outputPreferencesDO"]
			quotationIO = inQuotationIO
			if (quotationIO.outputPreferencesDO !=nil && quotationIO.outputPreferencesDO.field3 != "YES" && quotationIO.baseDO.quotAddtnlField3 != nil)
				if (field == 3)
					pYear = quotationIO.baseDO.quotAddtnlField3.to_i;
				else
					pYear = quotationIO.baseDO.quotAddtnlField4.to_i;
				end
				if(pYear <=20)
					return "policyYearCondition${1-#{pYear}}$policyYearCondition";
				else
					return "policyYearCondition${1-20,#{pYear}}$policyYearCondition";
				end
			else
				return "";
			end
		end

		def self.getPthYearTRAD(pYearElement)
			pYear = pYearElement.to_i
			if (pYear >= 11 && pYear <= 13)
				return pYear.to_s+"th";
			end
			pYear = case (pYear % 10)
				when 1  then  pYear.to_s+"st";
				when 2 then  pYear.to_s+"nd";
				when 3  then  pYear.to_s+"rd";
				else  pYear.to_s+"th";
		   end
		end

			def self.get5YRCTPremiumTable(quotationIO,mvelHashMap)
			riderList = mvelHashMap['riderList']
			outputPreferencesDO = mvelHashMap['outputPreferencesDO']
			productTerm= quotationIO.baseDO.getBaseProduct.productTerm.to_i
			sb = ""
			upperLimit=0;
			lowerLimit = 0;
			basicPremium="";
			extraLoading="";
			totalDB="";
			accidentalDB="";
			total ="";
			issueAge=quotationIO.baseDO.getPartyByRole("PRIMARY").age.to_i;
			totalDBPeriod = 0;
			accidentalDBPeriod = 0;
			extraLoadingPeriod = 0;
			tdbRiderLoading =0;
			extraLoadingPeriodPolYear=0;
			currCalanderYear = mvelHashMap["calendarYear"].to_i
			totalDBFlag=false;
			extraLoadingFlag=false;
			accidentalDBFlag=false;
			isCalanderYearIllustration = false;
			isAgeIllustration = false;
			tableHeader = "Dur";
			noteDuration = "the end of duration";
			if outputPreferencesDO != nil && outputPreferencesDO.field2 == "CALENDARYEAR"
				isCalanderYearIllustration=true;
				tableHeader="Year";
				noteDuration = "year";
			end
			if outputPreferencesDO != nil && outputPreferencesDO.field2 == "AGE"
				isAgeIllustration=true;
				tableHeader="Age";
				noteDuration = "attained age";
			end
			sb << "<div>"
			quotationIO.baseDO.QuotationProductList.each do |quotationProduct|
				if quotationProduct.productId == '5YRCT' || quotationProduct.productId == '5RCP0A' || quotationProduct.productId == 'GPTP0A' || quotationProduct.productId == 'Grepa5YRCT'  || quotationProduct.productId == 'GPTP0A_A'
					if quotationProduct.productTypeCd == 'PLAN'
						basicPremiumDouble = 0;
						extraLoadingDouble = 0;
						totalDBDouble = 0;
						accDBDouble = 0;
						totalPremium=0;
						if quotationProduct.getExtraQuotationProducts.size > 0 && ((quotationProduct.getExtraQuotationProducts[0].extraFlatAmt != nil && quotationProduct.getExtraQuotationProducts[0].extraFlatAmt != "" ) || (quotationProduct.getExtraQuotationProducts[0].extraPercent != nil && quotationProduct.getExtraQuotationProducts[0].extraPercent != "" && quotationProduct.getExtraQuotationProducts[0].extraPercent > 1))
							#for BasePlan where Extra Loading is Selected
							sb << " <div class='SLF-premium-sched-header fontFamilyATLBold fontSize15'>		  Premium Schedule :		  </div>"
							sb << " <div class='SLF5yrtc' style='margin-left:3%'>"
							sb << "<table class ='fontFamilyGFB fontSize12 SLFPremiumSchedTable' style='border: 1px solid black; margin-top: 8px; border-collapse:collapse;width:80%;border: 1px solid black;' cellspacing='0'>"
							sb << "<tr style='border: 1px solid black;'><td width='10%' class='fontFamilyATLBold fontSize14 header'>"+tableHeader+"</td>"
							sb << "<td class='fontFamilyATLBold fontSize14 header' width ='18%' style='border: 1px solid black;'>Basic<br/> Premium</td>"
							sb << "<td class='fontFamilyATLBold fontSize14 header' width ='18%' style='border: 1px solid black;'>Extra<br/>Premium</td>"
							sb << "<td class='fontFamilyATLBold fontSize14 header' width ='18%' style='border: 1px solid black;'>Total<br/>Disability<br/>Benefit</td>"
							sb << "<td class='fontFamilyATLBold fontSize14 header' width ='18%' style='border: 1px solid black;'>Accidental<br/>Death<br/>Benefit</td>"
							sb << "<td class='fontFamilyATLBold fontSize14 header' width ='18%' style='border: 1px solid black;'>Total</td></tr>"

							if quotationProduct.getExtraQuotationProducts[0].extraFlatAmt != nil && quotationProduct.getExtraQuotationProducts[0].extraFlatAmt != ""
								extraLoadingPeriod = quotationProduct.getExtraQuotationProducts[0].extraFlatDuration != nil ? quotationProduct.getExtraQuotationProducts[0].extraFlatDuration.to_i : 0
							end
							if quotationProduct.getExtraQuotationProducts[0].extraPercent != nil && quotationProduct.getExtraQuotationProducts[0].extraPercent != ""
								extraLoadingPeriod = quotationProduct.getExtraQuotationProducts[0].extraPercDuration != nil ? quotationProduct.getExtraQuotationProducts[0].extraPercDuration.to_i : 0
							end
							extraLoadingPeriodPolYear=extraLoadingPeriod;
							if(isCalanderYearIllustration)
								extraLoadingPeriod = extraLoadingPeriod + currCalanderYear;
							end
							if(isAgeIllustration)
								extraLoadingPeriod = extraLoadingPeriod + issueAge;
							end
							i = 1
							for i in (i..productTerm)
								if quotationIO.finalMap[i] != nil && (i-1)%5 == 0
									lowerLimit = i
									if i + 4 > productTerm
										upperLimit = productTerm
									else
										upperLimit = i + 4
									end
									basicPremiumDouble = quotationIO.finalMap[i]["basicpremiumcompute"]["0"] != nil ? quotationIO.finalMap[i]["basicpremiumcompute"]["0"] : 0
									extraLoadingDouble = quotationIO.finalMap[i]["extrapremiumcompute"]["0"] !=nil ? quotationIO.finalMap[i]["extrapremiumcompute"]["0"] : 0
									if quotationIO.finalMap[i]["ridermodalpremium"] != nil
										totalDBDouble = quotationIO.finalMap[i]["ridermodalpremium"]["0TDB of 5YRCT"] != nil ? quotationIO.finalMap[i]["ridermodalpremium"]["0TDB of 5YRCT"] : 0
									end
									if quotationIO.finalMap[i]["ridermodalpremium"] != nil
										accDBDouble = quotationIO.finalMap[i]["ridermodalpremium"]["0ADB of 5YRCT"] != nil ? quotationIO.finalMap[i]["ridermodalpremium"]["0ADB of 5YRCT"] : 0
									end
									#issueAge = quotationIO.baseDO.getPartyByRole("PRIMARY").age.to_i
									riderList.each do |rd|
										if totalDBPeriod == 0
											totalDBPeriod = rd.productId == "TDB of 5YRCT" ? rd.productTerm : 0
										end
										if(accidentalDBPeriod==0)
											accidentalDBPeriod=rd.productId == "ADB of 5YRCT" ? rd.productTerm : 0
										end
									end
									totalDBIndicator = "";
									accidentalDBIndicator = "";
									extraLoadingIndicator = "";
									if(totalDBPeriod >= lowerLimit && totalDBPeriod < upperLimit)
										totalDBFlag = true;
										totalDBIndicator = "*";
									end
									if(accidentalDBPeriod >=lowerLimit && accidentalDBPeriod < upperLimit)
										accidentalDBFlag=true;
										accidentalDBIndicator="^";
									end
									if extraLoadingPeriodPolYear >= lowerLimit && (extraLoadingPeriodPolYear < upperLimit|| (upperLimit==productTerm&&upperLimit%5!=0))
										extraLoadingIndicator="#";
									end
									sb << "<tr>"
									sb << "<td style=' text-align: center; border-right: 1px solid #000;' >"

									if(isCalanderYearIllustration)
										lowerLimit = lowerLimit + currCalanderYear - 1;
										upperLimit = upperLimit + currCalanderYear - 1;
									end

									if(isAgeIllustration)
										lowerLimit = lowerLimit + issueAge - 1;
										upperLimit = upperLimit + issueAge - 1;
									end
									if(lowerLimit==upperLimit)
										sb << lowerLimit.to_s
									else
										sb << lowerLimit.to_s
										sb << " - "
										sb << upperLimit.to_s
									end
									basicPremium=basicPremiumDouble
									extraLoading=extraLoadingDouble
									totalDB=totalDBDouble
									accidentalDB = accDBDouble
									totalPremium = basicPremiumDouble + extraLoadingDouble +totalDBDouble+accDBDouble;
									total = totalPremium
									sb << "</td>"
									sb << "<td style='text-align: right; border-right: 1px solid #000; padding-right: 3px;'>"
									sb << getFormatDoubleTwoDecimalWithComma(basicPremium)
									sb << "</td>"
									sb << "<td style='text-align: right; border-right: 1px solid #000; padding-right: 3px;'>"
									sb << getFormatDoubleTwoDecimalWithComma(extraLoading)+extraLoadingIndicator
									sb << "</td>"
									sb << "<td style='text-align: right; border-right: 1px solid #000; padding-right: 3px;'>"
									sb << getFormatDoubleTwoDecimalWithComma(totalDB)+totalDBIndicator
									sb << "</td>"
									sb << "<td style='text-align: right; border-right: 1px solid #000; padding-right: 3px;'>"
									sb << getFormatDoubleTwoDecimalWithComma(accidentalDB)+accidentalDBIndicator
									sb << "</td>"
									sb << "<td style='text-align: right; padding-right: 3px;'>"
									sb << getFormatDoubleTwoDecimalWithComma(total)
									sb << "</td>"
									sb << "</tr>"
									basicPremium = "";
									totalDB = "";
									accidentalDB = "";
									total = "";
								end
							end
							if(isCalanderYearIllustration)
								totalDBPeriod = totalDBPeriod + currCalanderYear;
								accidentalDBPeriod = accidentalDBPeriod + currCalanderYear;
							end
							if(isAgeIllustration)
								totalDBPeriod = totalDBPeriod + issueAge;
								accidentalDBPeriod = accidentalDBPeriod + issueAge;
							end
							sb << "</table></div>"
							# if(extraLoadingFlag)
							if(extraLoadingPeriod.to_i % 5) != 0 #SUNSS 2594
							sb << "<div class ='fontFamilyGFB fontSize11'  style='padding-left:40px$SEMI$margin-top:6px'># Extra premium payment terminates at "+noteDuration.to_s+" "+extraLoadingPeriod.to_i.to_s+".</div>"
							end
							# end

							if(totalDBFlag)
								sb << "<div class ='fontFamilyGFB fontSize11' style='padding-left:40px' >* TDB premium payment terminates at "+noteDuration.to_s+" "+totalDBPeriod.to_i.to_s+".</div>"
							end
							if(accidentalDBFlag)
								sb << "<div class ='fontFamilyGFB fontSize11' style='padding-left:40px'>^ ADB premium payment terminates at "+noteDuration.to_s+" "+accidentalDBPeriod.to_i.to_s+".</div>"
							end
						else
							#For BasePlan where Extra Loading is not Selected
							sb << " <div class='SLF-premium-sched-header fontFamilyATLBold fontSize15'>		  Premium Schedule :		  </div>"
							sb << " <div class='center SLF5yrtc' style='margin-left:3%'>"
							sb << "<table class= 'fontFamilyGFB fontSize12 SLFPremiumSchedTable' style='border: 1px solid black; margin-top: 8px; border-collapse:collapse;width:80%;border: 1px solid black;' cellspacing='0'>"
							sb << "<tr><td width='12%' class='fontFamilyATLBold fontSize14 header'style=\"border:1px solid black;\">"+tableHeader+"</td>"
							sb << "<td class='fontFamilyATLBold fontSize14 header' style=\"border:1px solid black;\"width ='22%'>Basic<br/> Premium</td>"
							sb << "<td class='fontFamilyATLBold fontSize14 header' style=\"border:1px solid black;\" width ='22%'>Total<br/>Disability<br/>Benefit</td>"
							sb << "<td class='fontFamilyATLBold fontSize14 header' style=\"border:1px solid black;\"width ='22%'>Accidental<br/>Death<br/>Benefit</td>"
							sb << "<td class='fontFamilyATLBold fontSize14 header' style=\"border:1px solid black;\"width ='22%'>Total</td></tr>"
							i = 1
							for i in (i..productTerm)
								if quotationIO.finalMap[i] != nil && (i-1)%5 == 0
									lowerLimit = i
									if i+4 > productTerm
										upperLimit = productTerm
									else
										upperLimit = i+4
									end
									basicPremiumDouble=quotationIO.finalMap[i]["basicpremiumcompute"]["0"] != nil ? quotationIO.finalMap[i]["basicpremiumcompute"]["0"] : 0
									if(quotationIO.finalMap[i]["ridermodalpremium"] != nil)
										totalDBDouble = quotationIO.finalMap[i]["ridermodalpremium"]["0TDB of 5YRCT"] != nil ? quotationIO.finalMap[i]["ridermodalpremium"]["0TDB of 5YRCT"] : 0
									end
									if(quotationIO.finalMap[i]["ridermodalpremium"] != nil)
										accDBDouble=quotationIO.finalMap[i]["ridermodalpremium"]["0ADB of 5YRCT"] != nil ? quotationIO.finalMap[i]["ridermodalpremium"]["0ADB of 5YRCT"] : 0
									end
									issueAge = quotationIO.baseDO.getPartyByRole("PRIMARY").age.to_i
									riderList.each do |rd|
										if totalDBPeriod == 0
										totalDBPeriod = rd.productId == "TDB of 5YRCT" ? rd.productTerm : 0
										end
										if(accidentalDBPeriod==0)
										accidentalDBPeriod=rd.productId == "ADB of 5YRCT" ? rd.productTerm : 0
										end
									end
									totalDBIndicator = "";
									accidentalDBIndicator = "";
									if(totalDBPeriod >= lowerLimit && totalDBPeriod < upperLimit)
										totalDBFlag = true;
										totalDBIndicator = "*";
									end
									if(accidentalDBPeriod >=lowerLimit && accidentalDBPeriod < upperLimit)
										accidentalDBFlag=true;
										accidentalDBIndicator="^";
									end
									sb << "<tr>"
									sb << "<td style=' text-align: center; border-right: 1px solid #000;' >"
									if(isCalanderYearIllustration)
										lowerLimit = lowerLimit + currCalanderYear - 1;
										upperLimit = upperLimit + currCalanderYear - 1;
									end
									if(isAgeIllustration)

										lowerLimit = lowerLimit + issueAge - 1;
										upperLimit = upperLimit + issueAge - 1;
									end
									if(lowerLimit==upperLimit)
										sb << lowerLimit.to_s
									else
										sb << lowerLimit.to_s
										sb << " - "
										sb << upperLimit.to_s
									end
									basicPremium=basicPremiumDouble
									extraLoading=extraLoadingDouble
									totalDB=totalDBDouble
									accidentalDB = accDBDouble
									totalPremium = basicPremiumDouble + extraLoadingDouble +totalDBDouble+accDBDouble;
									total = totalPremium
									sb << "</td>"
									sb << "<td style='text-align: right; border-right: 1px solid #000; padding-right: 3px;'>"
									sb << getFormatDoubleTwoDecimalWithComma(basicPremium)
									sb << "</td>"
									sb << "<td style='text-align: right; border-right: 1px solid #000; padding-right: 3px;'>"
									sb << getFormatDoubleTwoDecimalWithComma(totalDB)+totalDBIndicator
									sb << "</td>"
									sb << "<td style='text-align: right; border-right: 1px solid #000; padding-right: 3px;'>"
									sb << getFormatDoubleTwoDecimalWithComma(accidentalDB)+accidentalDBIndicator
									sb << "</td>"
									sb << "<td style='text-align: right; padding-right: 3px;'>"
									sb << getFormatDoubleTwoDecimalWithComma(total)
									sb << "</td>"
									sb << "</tr>"
									basicPremium = "";
									totalDB = "";
									accidentalDB = "";
									total = "";
								end
							end
							if(isCalanderYearIllustration)
										totalDBPeriod = totalDBPeriod + currCalanderYear;
										accidentalDBPeriod = accidentalDBPeriod + currCalanderYear;
							end
							if(isAgeIllustration)
								totalDBPeriod = totalDBPeriod + issueAge;
								accidentalDBPeriod = accidentalDBPeriod + issueAge;
							end
							sb << "</table></div>"
							if(totalDBFlag)
								sb << "<div class ='fontFamilyGFB fontSize11' style='padding-left:40px$SEMI$margin-top:10px' >* TDB premium payment terminates at "+noteDuration.to_s+" "+totalDBPeriod.to_i.to_s+".</div>"
							end
							if(accidentalDBFlag)
								padding = ""
								padding = "$SEMI$margin-top:10px" if (!totalDBFlag)
								sb << "<div class ='fontFamilyGFB fontSize11' style='padding-left:40px#{padding}'>^ ADB premium payment terminates at "+noteDuration.to_s+" "+accidentalDBPeriod.to_i.to_s+".</div>"
							end
						end
						break;
					elsif (quotationProduct.productTypeCd == 'RIDER')
						productTerm=quotationProduct.premiumPayingTerm.to_i
						basicPremiumDouble = 0;
						extraLoadingDouble = 0;
						totalDBBasicDouble = 0;
						totalDBExtraDouble = 0;
						totalPremiumDouble=0;
						 lowerLimitTemp = 0;
						 upperLimitTemp = 0;
						 lowerLimitTemp2 = 0;
						 upperLimitTemp2 = 0;
						 loadingCompareVariable1 = 0;
						 loadingCompareVariable2 = 0;
						 isFirstLoadingBreakDone = false;
						 isSecondLoadingBreakDone = false;
						 repeatLoopRequired = false;
						 isRepeating = false;
						sb << " <div class='SLF-premium-sched-header fontFamilyATLBold fontSize15' style='margin-top:7px;'>		  Premium Schedule :		  </div>"
						if quotationProduct.getExtraQuotationProducts.size > 0 && ((quotationProduct.getExtraQuotationProducts[0].extraFlatAmt != nil && quotationProduct.getExtraQuotationProducts[0].extraFlatAmt != "" ) || (quotationProduct.getExtraQuotationProducts[0].extraPercent != nil && quotationProduct.getExtraQuotationProducts[0].extraPercent != "" && quotationProduct.getExtraQuotationProducts[0].extraPercent > 1))
							#c
							sb << " <div class='center SLF5yrtc' style='margin-left:3%'>"
							sb << "<table class= 'fontFamilyGFB fontSize13 SLFPremiumSchedTable' style='border: 1px solid black; margin-top: 10px; border-collapse:collapse' cellspacing='0' width='80%'>"
							sb << "<tr><td width='12%' class='fontFamilyATLBold fontSize14 header'style=\"border:1px solid black;\"style=\"border:1px solid black;\">"+tableHeader.to_s+"</td>"
							sb << "<td class='fontFamilyATLBold fontSize14 header' style=\"border:1px solid black;\"style=\"border:1px solid black;\"width ='22%'>Basic<br/> Premium</td>"
							sb << "<td class='fontFamilyATLBold fontSize14 header'style=\"border:1px solid black;\"style=\"border:1px solid black;\" width ='22%'>Extra<br/> Premium</td>"
							sb << "<td class='fontFamilyATLBold fontSize14 header' style=\"border:1px solid black;\"style=\"border:1px solid black;\"width ='22%'>Total<br/>Disability<br/>Benefit</td>"
							sb << "<td class='fontFamilyATLBold fontSize14 header'style=\"border:1px solid black;\"style=\"border:1px solid black;\" width ='22%'>Total</td></tr>"
							sb << "<tr><td  class='fontFamilyATLBold fontSize14 col1'>&nbsp;</td>"
							sb << "<td class='fontFamilyATLBold fontSize14 col2' width ='22%'></td>"
							sb << "<td class='fontFamilyATLBold fontSize14 col3' width ='22%'></td>"
							sb << "<td class='fontFamilyATLBold fontSize14 col4' width ='22%'></td>"
							sb << "<td class='fontFamilyATLBold fontSize14 col5' width ='22%'></tr>"


							if quotationProduct.getExtraQuotationProducts[0].extraFlatAmt.to_s != ""
								# puts "quotationProduct.getExtraQuotationProducts[0] :- #{quotationProduct.getExtraQuotationProducts[0].inspect}"
								extraLoadingPeriod = quotationProduct.getExtraQuotationProducts[0].extraFlatDuration.to_i
							end
							if quotationProduct.getExtraQuotationProducts[0].extraPercent.to_s != ""
								extraLoadingPeriod = quotationProduct.getExtraQuotationProducts[0].extraPercDuration.to_i
								# puts "quotationProduct.getExtraQuotationProducts[0] :- #{quotationProduct.getExtraQuotationProducts[0].inspect}"
							end
							extraLoadingPeriodPolYear=extraLoadingPeriod;
							#puts "extraLoadingPeriodPolYear :- #{extraLoadingPeriodPolYear.inspect}"
							if(isCalanderYearIllustration)
								extraLoadingPeriod = extraLoadingPeriod + currCalanderYear;
							end
							if(isAgeIllustration)
								extraLoadingPeriod = extraLoadingPeriod + issueAge;
							end


							riderList.each do |rd|
								if rd.productId == "TDB of 5YRCT"
									totalDBPeriod=rd.productTerm.to_i
									if(rd.QuotationProductExtraList.size > 0)
											rd.QuotationProductExtraList.each do |quotationProductExtraDO|
												#puts "quotationProductExtraDO :- #{quotationProductExtraDO.inspect}"
															if(quotationProductExtraDO.extraTypeCd != nil && quotationProductExtraDO.extraFlatDuration != nil && quotationProductExtraDO.extraFlatDuration != "")
																tdbRiderLoading = quotationProductExtraDO.extraFlatDuration.to_i;
															elsif(quotationProductExtraDO.extraTypeCd != nil && quotationProductExtraDO.extraPercDuration != nil && quotationProductExtraDO.extraPercDuration != "")
																tdbRiderLoading = quotationProductExtraDO.extraPercDuration.to_i;
															end
											end
									end
									break;
								end
							end
							i = 1
							#for i in (i..productTerm)

								while i <= productTerm  do

								if quotationIO.finalMap[i] != nil && (i-1)%5 == 0

								if(tdbRiderLoading < extraLoadingPeriodPolYear)
									loadingCompareVariable1 = tdbRiderLoading;
									loadingCompareVariable2 = extraLoadingPeriodPolYear;
								else
									loadingCompareVariable1 = extraLoadingPeriodPolYear;
									loadingCompareVariable2 = tdbRiderLoading;
								end
								if(isRepeating)
									lowerLimit = lowerLimitTemp2;
									upperLimit = upperLimitTemp2;
									isRepeating = false;
								else
									lowerLimitTemp=i;  #this will hold the original lower limit always
									lowerLimitTemp2 = i;
									lowerLimit = i;
										if(i+4 > productTerm)
											upperLimitTemp=productTerm; #this will hold the original upper limit always
											upperLimitTemp2=productTerm;
											upperLimit=productTerm;
										else
											upperLimitTemp=i+4;
											upperLimitTemp2=i+4;
											upperLimit=i+4;
										end
								end

								if(!isFirstLoadingBreakDone)

									if(loadingCompareVariable1 == 0 || loadingCompareVariable1 == upperLimit)

										isFirstLoadingBreakDone = true;
									end
									if(loadingCompareVariable1 > (lowerLimit+1) && loadingCompareVariable1 < upperLimit)      #SUNSS 2409
										basicPremiumDouble = quotationIO.finalMap[i]["riderbasepremiumoutput"]["0"+quotationProduct.productId]
										upperLimitTemp2 = upperLimit;
										upperLimit = loadingCompareVariable1;
										lowerLimitTemp2 = loadingCompareVariable1 + 1;
										repeatLoopRequired = true;
										isFirstLoadingBreakDone = true;
									end
								end
								if(!isSecondLoadingBreakDone && isFirstLoadingBreakDone)
									if(loadingCompareVariable2 >= lowerLimit && loadingCompareVariable2 < upperLimit)
										upperLimitTemp2 = upperLimit;
										upperLimit = loadingCompareVariable2;
										lowerLimitTemp2 = loadingCompareVariable2 + 1;
										repeatLoopRequired = true;
										isSecondLoadingBreakDone = true;
									end
								end


									if quotationIO.finalMap[lowerLimit]["riderbasepremiumoutput"] != nil
										basicPremiumDouble = quotationIO.finalMap[lowerLimit]["riderbasepremiumoutput"]["0"+quotationProduct.productId]
									end
									basicPremium=basicPremiumDouble
									if quotationIO.finalMap[lowerLimit]["riderextrapremiumoutput"] != nil
										extraLoadingDouble= quotationIO.finalMap[lowerLimit]["riderextrapremiumoutput"]["0"+quotationProduct.productId]
									end
									extraLoading=extraLoadingDouble

									if(quotationIO.finalMap[lowerLimit]["riderbasepremiumoutput"] != nil)
										totalDB=quotationIO.finalMap[lowerLimit]["riderbasepremiumoutput"]["0TDB of 5YRCT"] != nil ? quotationIO.finalMap[lowerLimit]["riderbasepremiumoutput"]["0TDB of 5YRCT"] : "0"
										totalDBBasicDouble = totalDB.to_f
									end
									if(quotationIO.finalMap[lowerLimit]["riderextrapremiumoutput"] != nil)
										totalDB=quotationIO.finalMap[lowerLimit]["riderextrapremiumoutput"]["0TDB of 5YRCT"] != nil ? quotationIO.finalMap[lowerLimit]["riderextrapremiumoutput"]["0TDB of 5YRCT"] : "0";
									end
									totalDBExtraDouble=totalDB.to_f
									totalPremiumDouble=basicPremiumDouble+extraLoadingDouble+totalDBBasicDouble+totalDBExtraDouble;
									totalDB = (totalDBBasicDouble+totalDBExtraDouble)
									total=totalPremiumDouble
									issueAge = quotationIO.baseDO.getPartyByRole("PRIMARY").age.to_i


									# set the extraloadingperiod value  pending.
									#set the extraloadingflag and extraloadingindicator pending.
									totalDBIndicator = "";
									extraLoadingIndicator = "";
									if(extraLoadingPeriodPolYear >= lowerLimit && extraLoadingPeriodPolYear < upperLimit)
										extraLoadingFlag=true;
										extraLoadingIndicator="#";
									end
									if(totalDBPeriod >= lowerLimit && totalDBPeriod <= upperLimit && totalDBPeriod % 5 != 0) #SUNSS 2409
										totalDBFlag=true;
										totalDBIndicator="*";
									end
									sb << "<tr>"
									sb << "<td style=' text-align: center; border-right: 1px solid #000;' >"
									if(isCalanderYearIllustration)
										lowerLimit = lowerLimit + currCalanderYear - 1;
										upperLimit = upperLimit + currCalanderYear - 1;
									end
									if(isAgeIllustration)
										lowerLimit = lowerLimit + issueAge - 1;
										upperLimit = upperLimit + issueAge - 1;
									end
									if(lowerLimit==upperLimit)
										sb << lowerLimit.to_s
									else
										sb << lowerLimit.to_s
										sb << " - "
										sb << upperLimit.to_s
									end
									sb << "</td>"
									sb << "<td style='text-align: right; border-right: 1px solid #000; padding-right: 3px;'>"
									sb << getFormatDoubleTwoDecimalWithComma(basicPremium)
									sb << "</td>"
									sb << "<td style='text-align: right; border-right: 1px solid #000; padding-right: 3px;'>"
									sb << getFormatDoubleTwoDecimalWithComma(extraLoading)+extraLoadingIndicator
									sb << "</td>"
									sb << "<td style='text-align: right; border-right: 1px solid #000; padding-right: 3px;'>"
									sb << getFormatDoubleTwoDecimalWithComma(totalDB)+totalDBIndicator
									sb << "</td>"
									sb << "<td style='text-align: right; padding-right: 3px;'>"
									sb << getFormatDoubleTwoDecimalWithComma(total)
									sb << "</td>"
									sb << "</tr>"
									basicPremium = "";
									totalDB = "";
									total = "";
									if(repeatLoopRequired)
										repeatLoopRequired = false;
										isRepeating = true;
										i = i - 1;
									end
								end
								i +=1
							end
							if(isCalanderYearIllustration)
								totalDBPeriod = totalDBPeriod + currCalanderYear;
							end
							if(isAgeIllustration)
								totalDBPeriod = totalDBPeriod + issueAge;
							end
							sb << "</table>"
							if(extraLoadingFlag)
								if(extraLoadingPeriod.to_i % 5) != 0 #SUNSS 2594
								sb << "<div class ='fontFamilyGFB fontSize11'style='padding-left:40px$SEMI$margin-top:10px'># Extra premium payment terminates at "+noteDuration.to_s+" "+extraLoadingPeriod.to_i.to_s+".</div>"
								end
							end
							if(totalDBFlag)
								padding = ""
								padding = "$SEMI$margin-top:10px" if (!extraLoadingFlag)
								sb << "<div class ='fontFamilyGFB fontSize11'style='padding-left:40px#{padding}'>* TDB premium payment terminates at "+noteDuration.to_s+" "+totalDBPeriod.to_i.to_s+".</div>"
							end
							sb << "</div>"
						else
							#Rider Without Extra Loading
							sb << " <div class='center SLF5yrtc' style='margin-left:10%'>"
							sb << "<table class= 'fontFamilyGFB fontSize12 SLFPremiumSchedTable' style='border: 1px solid black; margin-top: 10px; border-collapse:collapse' cellspacing='0' width='85.5%'>"
							sb << "<tr><td width='16%' class='fontFamilyATLBold fontSize14 header'style=\"border:1px solid black;\">"+tableHeader+"</td>"
							sb << "<td class='fontFamilyATLBold fontSize14 header' style=\"border:1px solid black;\"width ='28%'>Basic<br/> Premium</td>"
							sb << "<td class='fontFamilyATLBold fontSize14 header'style=\"border:1px solid black;\" width ='28%'>Total<br/>Disability<br/>Benefit</td>"
							sb << "<td class='fontFamilyATLBold fontSize14 header' style=\"border:1px solid black;\"width ='28%'>Total</td></tr>"
							sb << "<tr><td  class='fontFamilyATL fontSize14 col1'>&nbsp;</td>"
							sb << "<td class='fontFamilyATLBold fontSize14 col2'></td>"
							sb << "<td class='fontFamilyATLBold fontSize14 col3'></td>"
							sb << "<td class='fontFamilyATLBold fontSize14 col4'></td></tr>"

							riderList.each do |rd|
								if rd.productId == "TDB of 5YRCT"
									totalDBPeriod=rd.productTerm
									if(rd.QuotationProductExtraList.size() > 0)
											rd.QuotationProductExtraList.each do |quotationProductExtraDO|
															if(quotationProductExtraDO.extraTypeCd != nil && quotationProductExtraDO.extraFlatDuration != nil && quotationProductExtraDO.extraFlatDuration != "")
																tdbRiderLoading = quotationProductExtraDO.extraFlatDuration.to_i;
															elsif(quotationProductExtraDO.extraTypeCd != nil && quotationProductExtraDO.extraPercDuration != nil && quotationProductExtraDO.extraPercDuration != "")
																tdbRiderLoading = quotationProductExtraDO.extraPercDuration.to_i;
															end
											end
									end
									break;
								end
							end

							i = 1
						while i <= productTerm  do
							if quotationIO.finalMap[i] != nil && (i-1)%5 == 0

								loadingCompareVariable1 = tdbRiderLoading;

								if(isRepeating)
									lowerLimit = lowerLimitTemp2;
									upperLimit = upperLimitTemp2;
									isRepeating = false;

								else
									lowerLimitTemp=i;  #this will hold the original lower limit always
									lowerLimitTemp2 = i;
									lowerLimit = i;
									if(i+4 > productTerm)
										upperLimitTemp=productTerm; #this will hold the original upper limit always
										upperLimitTemp2=productTerm;
										upperLimit=productTerm;
									else
										upperLimitTemp=i+4;
										upperLimitTemp2=i+4;
										upperLimit=i+4;
									end
								end

								if(!isFirstLoadingBreakDone)

									if(loadingCompareVariable1 == 0 || loadingCompareVariable1 == upperLimit)
										isFirstLoadingBreakDone = true;
									end
									if(loadingCompareVariable1 > (lowerLimit+1) && loadingCompareVariable1 < upperLimit ) #SUNSS 2409

										upperLimitTemp2 = upperLimit;
										upperLimit = loadingCompareVariable1;
										lowerLimitTemp2 = loadingCompareVariable1 + 1;
										repeatLoopRequired = true;
										isFirstLoadingBreakDone = true;
									end
								end

									if quotationIO.finalMap[lowerLimit]["riderbasepremiumoutput"] != nil
										basicPremiumDouble = quotationIO.finalMap[lowerLimit]["riderbasepremiumoutput"]["0"+quotationProduct.productId]
									end
									basicPremium=basicPremiumDouble
									if(quotationIO.finalMap[lowerLimit]["riderbasepremiumoutput"] != nil)
										totalDB=quotationIO.finalMap[lowerLimit]["riderbasepremiumoutput"]["0TDB of 5YRCT"] != nil ? quotationIO.finalMap[lowerLimit]["riderbasepremiumoutput"]["0TDB of 5YRCT"] : "0"
										totalDBBasicDouble = totalDB.to_f
									end
									if(quotationIO.finalMap[lowerLimit]["riderextrapremiumoutput"] != nil)
										totalDB=quotationIO.finalMap[lowerLimit]["riderextrapremiumoutput"]["0TDB of 5YRCT"] != nil ? quotationIO.finalMap[lowerLimit]["riderextrapremiumoutput"]["0TDB of 5YRCT"] : "0";
									end
									totalDBExtraDouble=totalDB.to_f
									totalPremiumDouble=basicPremiumDouble+extraLoadingDouble+totalDBBasicDouble+totalDBExtraDouble;
									totalDB = (totalDBBasicDouble+totalDBExtraDouble)
									total=totalPremiumDouble
									issueAge = quotationIO.baseDO.getPartyByRole("PRIMARY").age.to_i

									# set the extraloadingperiod value  pending.
									#set the extraloadingflag and extraloadingindicator pending.
									totalDBIndicator = "";
									if(totalDBPeriod >= lowerLimit && totalDBPeriod <= upperLimit && totalDBPeriod % 5 != 0) #SUNSS 2409
										totalDBFlag=true;
										totalDBIndicator="*";
									end
									sb << "<tr>"
									sb << "<td style=' text-align: center; border-right: 1px solid #000;' >"
									if(isCalanderYearIllustration)
										lowerLimit = lowerLimit + currCalanderYear - 1;
										upperLimit = upperLimit + currCalanderYear - 1;
									end
									if(isAgeIllustration)
										lowerLimit = lowerLimit + issueAge - 1;
										upperLimit = upperLimit + issueAge - 1;
									end
									if(lowerLimit==upperLimit)
										sb << lowerLimit.to_s
									else
										sb << lowerLimit.to_s
										sb << " - "
										sb << upperLimit.to_s
									end
									sb << "</td>"
									sb << "<td style='text-align: right; border-right: 1px solid #000; padding-right: 3px;'>"
									sb << getFormatDoubleTwoDecimalWithComma(basicPremium)
									sb << "</td>"
									sb << "<td style='text-align: right; border-right: 1px solid #000; padding-right: 3px;'>"
									sb << getFormatDoubleTwoDecimalWithComma(totalDB)+totalDBIndicator
									sb << "</td>"
									sb << "<td style='text-align: right; padding-right: 3px;'>"
									sb << getFormatDoubleTwoDecimalWithComma(total)
									sb << "</td>"
									sb << "</tr>"
									basicPremium = "";
									totalDB = "";
									total = "";
									if(repeatLoopRequired)
										repeatLoopRequired = false;
										isRepeating = true;
										i = i - 1;
									end
								end
								i +=1
							end
							if(isCalanderYearIllustration)
								totalDBPeriod = totalDBPeriod + currCalanderYear;
							end
							if(isAgeIllustration)
								totalDBPeriod = totalDBPeriod + issueAge;
							end
							sb << "</table>"
							if(totalDBFlag)
								sb << "<div class ='fontFamilyGFB fontSize11' style='padding-left:40px$SEMI$margin-top:10px'>* TDB premium payment terminates at "+noteDuration.to_s+" "+totalDBPeriod.to_i.to_s+".</div>"
							end
							sb << "</div>"
						end
						break;
					end
				end
			end
			sb << "</div>"
			return sb.to_s
		end



		def self.getFormatDoubleTwoDecimalWithComma(number)
		  return number = "" if number == 0 || number == ""
		  dec='.'
		  sep=','
		  begin
			num = MobiSys::Math.round(number.to_f, 2) if number.to_s != ""
		  rescue
			 num = number
		  end
		  num = number unless number
		  num = num.to_s.sub(/\./, dec)
		  dec = Regexp.escape dec
		  maskedNum = num.reverse.gsub(/(\d{3})(?=\d)(?!\d*#{dec})/, "\\1#{sep}").reverse
		  #puts ">>>number: #{number} maskednumber: #{maskedNum}"
		  if maskedNum.include? "."
			if maskedNum.index(".")+3 > maskedNum.length
			  maskedNum << "0"
			end
			# #added by manoj lad to remove 0 after decimal point(.)
			# if maskedNum.split(".")[-1].to_i == 0
			# 	maskedNum = maskedNum.split(".")[0]
			# end
		  end
		  maskedNum
		end

		def self.getRiderRowRegularPayTRAD(rider, riderList ,mvelHashMap)
		#	p "rider===>#{rider}"

			quotationIO= mvelHashMap["quotationIO"]
			product = quotationIO.baseDO.getBasePlan.getProduct
			finalString = ""
			if (rider.productId == "TDB of 5YRCT" || rider.productId == "TDB - 5YRCT") && !(product.productId == "SMPP0A" || product.productId == "SMDP0A")
				return "";
			end
			if rider.productId == "LBR"
				finalString = finalString.concat("<tr  style=\"line-height:13px;\" class=\"fontSize13\">			<td class=\"border1 fontFamilyGFB\" style=\"border-bottom:0px$SEMI$border-top:0px$SEMI$vertical-align: top$SEMI$padding-left:2px$SEMI$padding-right:2px$SEMI$padding-bottom:1px$SEMI$\">")
				finalString = finalString.concat("Living Benefit Rider*")
				finalString = finalString.concat("</td>			<td style=\"text-align:right$SEMI$padding-left:2px$SEMI$padding-right:2px$SEMI$padding-bottom:1px$SEMI$\" class=\"fontFamilyGFB\"> ")
				finalString = finalString.concat("</td>				<td style=\"border-right:1px solid black$SEMI$text-align:right$SEMI$padding-left:2px$SEMI$padding-right:2px$SEMI$padding-bottom:1px$SEMI$\" class=\"fontFamilyGFB\">")
				finalString = finalString.concat("</td>				<td style=\"text-align:right$SEMI$padding-left:2px$SEMI$padding-right:2px$SEMI$padding-bottom:1px$SEMI$\"class=\"fontFamilyGFB\">")
				finalString = finalString.concat("</td>				<td style=\"border-right:1px solid black$SEMI$text-align:right$SEMI$padding-left:2px$SEMI$padding-right:2px$SEMI$padding-bottom:1px$SEMI$\" class=\"fontFamilyGFB\">")
				finalString = finalString.concat("F R E E</td></tr>")
				return finalString;
			end
			riderName="";
			regularPremium="0.0";
			perDay = "";
			extraPremium=0.0;
			baseAnnualPremium=0.0;
			isTDBSelect = false;
			isSL5Select = false;
			isTDBSL5Select = false;
			isSL5SLGFISelect = false;
			isWOP = false;
			tdb5YRCTRegularPremium = 0;
			if rider.productId == "5YRCT" || rider.productId == "Grepa5YRCT"
				mvelHashMap['riderList'].each do |rd|
					if rd.productId == "TDB"
						isTDBSelect=true;
					end
					if rd.productId == "5YRCT"
						isSL5Select=true;
					end
					if rd.productId == "Grepa5YRCT"
						isSL5SLGFISelect=true;
					end
					if rd.productId == "TDB of 5YRCT"
						isTDBSL5Select=true;
						if quotationIO.finalMap[1] != nil && quotationIO.finalMap[1]["riderpremium"] != nil
							tdb5YRCTRegularPremium = quotationIO.finalMap[1]["riderpremium"]["0TDB of 5YRCT"]
						end
					end
				end
			end
			if quotationIO.finalMap[1] != nil && quotationIO.finalMap[1]["riderpremium"] != nil
				regularPremium = quotationIO.finalMap[1]["riderpremium"]["0" + rider.productId.to_s]
			end
			perDay = "";

            riderProductDO = MobiSys::ProductUtil.getProduct(rider.productSeq)
            riderPrdFacet = riderProductDO.getFacet("PERDAYCHECK") if riderProductDO

			# if rider.product != nil && rider.product.productKey != nil
			if riderPrdFacet && riderPrdFacet.actionValue.to_s == "YES"
				perDay = riderPrdFacet.actionValue.to_s == "YES" ? "/ day" : "";
			end
			######################rider symbol permanent fix########################
			quotation = quotationIO.baseDO
          	quotationResultDO = nil
          	@riderNameFacet = CompanyFacet.find(:first,:conditions=>{:facetCd=>"RIDERSYMBOL"})
          	riderSymbol = @riderNameFacet.actionValue if @riderNameFacet
         	quotationResultDO = MobiSys::ProductBO.evaluateModel(quotation, rider, riderSymbol, false)
          	if quotationResultDO.getFieldValueObject('rideroutput').to_s != "" && quotationResultDO.getFieldValueObject('rideroutput').to_s != "0.0"	
          		riderName = quotationResultDO.getFieldValueObject('rideroutput').to_s
      		else
      			if quotationIO.baseDO.getBaseProduct.product.productFamilyId == "TRAD"
      				riderName = rider.product.shortName.to_s
      			else
      				riderName = rider.product.longName.to_s
      			end
      		end
      		# finalString = finalString.concat(riderName.to_s)
      		######################rider symbol permanent fix ends########################
			#get rider name in a variable --SUNSS 2407--
			# riderName = rider.product.shortName == nil ? "" : rider.product.shortName
			if((isTDBSelect && isSL5Select) || (isSL5Select && isTDBSL5Select))
				if rider.productId == "5YRCT"
					riderName = "Safer Life Rider - 5 Year Renewable and Convertible Term w/ TDB";
				end
			end


			if((isTDBSelect && isSL5SLGFISelect) || (isSL5SLGFISelect && isTDBSL5Select))
				if   rider.productId == "Grepa5YRCT"
					riderName = "ProTerm Rider - 5 Year Renewable and Convertible Term w/ TDB";
				end
			end

			#check wether the rider is WOP
			productDO = Product.loadObject(:first, :conditions => {{:name => 'productId'} => rider.productId })

			if productDO.getOtherDetailsFacet != nil
				otherDetailsDO = productDO.getOtherDetailsFacet.OfflineOtherDetailsList[0]
				if otherDetailsDO != nil
					if otherDetailsDO.isWOPFl != nil && otherDetailsDO.isWOPFl == "YES"
						isWOP = true;
					end
				end
			end


			finalString = finalString.concat("<tr  style=\"line-height:13px;\" class=\"fontSize13\" >			<td class=\"border1 fontFamilyGFB\" style=\"border-bottom:0px$SEMI$border-top:0px$SEMI$vertical-align: top$SEMI$padding-left:2px$SEMI$padding-right:2px$SEMI$padding-bottom:1px$SEMI$\">")
			finalString = finalString.concat(riderName)
			if rider.productId == "TDB" || rider.productId == "CBTD" || isWOP
				finalString = finalString.concat("</td>			<td style=\"text-align:right$SEMI$padding-left:2px$SEMI$padding-right:2px$SEMI$padding-bottom:1px$SEMI$\" class=\"fontFamilyGFB\"> ")
				finalString = finalString.concat("</td>				<td style=\"border-right:1px solid black$SEMI$text-align:right$SEMI$padding-left:2px$SEMI$padding-right:2px$SEMI$padding-bottom:1px$SEMI$\" class=\"fontFamilyGFB\">")
			else
				finalString = finalString.concat("</td>			<td style=\"text-align:right$SEMI$padding-bottom:1px$SEMI$\" class=\"fontFamilyGFB\"> ")
				finalString = finalString.concat( rider.baseSumAssured == nil ? "" :"Ps")
				finalString = finalString.concat("</td>				<td style=\"border-right:1px solid black$SEMI$text-align:right$SEMI$padding-left:2px$SEMI$padding-right:2px$SEMI$padding-bottom:1px$SEMI$\" class=\"fontFamilyGFB\">")
				finalString = finalString.concat( (rider.baseSumAssured == nil ? "" : getFormatDoubleTwoDecimalWithComma(rider.baseSumAssured.to_s))	+ perDay)
			end
			finalString = finalString.concat("</td>				<td style=\"text-align:right$SEMI$padding-left:2px$SEMI$padding-right:2px$SEMI$padding-bottom:1px$SEMI$\"class=\"fontFamilyGFB\">")
			finalString = finalString.concat(regularPremium.to_f == 0.0 ? "" : "Ps")
			finalString = finalString.concat("</td>				<td style=\"border-right:1px solid black$SEMI$text-align:right$SEMI$padding-left:2px$SEMI$padding-right:2px$SEMI$padding-bottom:1px$SEMI$\" class=\"fontFamilyGFB\">")

			if(isTDBSL5Select && (rider.productId == "5YRCT" || rider.productId == "Grepa5YRCT"))
				regularPremium = (regularPremium.to_f + tdb5YRCTRegularPremium.to_f).to_s;
			end
			finalString = finalString.concat(getFormatDoubleTwoDecimalWithComma(regularPremium).to_s)
			finalString = finalString.concat("</td></tr>")
			#if condition for guaranteed value row
			if rider.productId == "5YRCT" ||  rider.productId == "Grepa5YRCT"
				finalString = finalString.concat("<tr   style=\"line-height:13px;\" class=\"fontSize13\" >			<td class=\"border1 fontFamilyGFB\" style=\"border-bottom:0px$SEMI$border-top:0px$SEMI$vertical-align: top$SEMI$padding-bottom:1px$SEMI$\">")
				finalString = finalString.concat("(Guaranteed Death Benefit equals 200% of Term Face Amount)")
				finalString = finalString.concat("</td>			<td style=\"text-align:right$SEMI$padding-left:2px$SEMI$padding-right:2px$SEMI$padding-bottom:1px$SEMI$\" class=\"fontFamilyGFB\"> ")
				finalString = finalString.concat("</td>				<td style=\"border-right:1px solid black$SEMI$text-align:right$SEMI$padding-left:2px$SEMI$padding-right:2px$SEMI$padding-bottom:1px$SEMI$\" class=\"fontFamilyGFB\">")
				finalString = finalString.concat("</td>				<td style=\"text-align:right$SEMI$padding-left:2px$SEMI$padding-right:2px$SEMI$padding-bottom:1px$SEMI$\"class=\"fontFamilyGFB\">")
				finalString = finalString.concat("</td>				<td style=\"border-right:1px solid black$SEMI$text-align:right$SEMI$padding-left:2px$SEMI$padding-right:2px$SEMI$padding-bottom:1px$SEMI$\" class=\"fontFamilyGFB\">")
				finalString = finalString.concat("</td></tr>")
			end
			#hardcode row for Living Benefit
			return finalString;
		end

		def self.getFooterPageNote(quotationIO = nil)
			if(quotationIO != nil)
				if(quotationIO.baseDO.getBaseProduct.product.productFamilyId == "TRAD")
					return "This is only an illustration, not a contract of insurance."
				else
					return "This is only an illustration.";
				end
			end
		end

		def self.getPYearMYearTRAD(quotationIO, productDO)

			facetDO = nil

				product = quotationIO.baseDO.getBasePlan.getProduct
				if(product != nil)
					facetDO = product.getFacet("TIMELINEILLUSTRATION")
				end
	  finalString = "";
	  mYear="";
	  if facetDO.actionValue == "WLXP0A" || facetDO.actionValue == "WLVP0A" || facetDO.actionValue == "FCXP0A" || facetDO.actionValue == "FCVP0A"
		if quotationIO.baseDO.getBasePlan.addtnField4 != nil && quotationIO.baseDO.getBasePlan.addtnField4 == "PUA"
		  if(quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["bipuamyear"] !=nil)
			mYear = quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["bipuamyear"]["0"]
			finalString << "(P "
			finalString<<quotationIO.baseDO.getBasePlan.premiumPayingTerm.to_s
			finalString<<" $SEMI$ M "
			finalString<<mYear.to_s
			finalString<<")"
		  end
		elsif quotationIO.baseDO.getBasePlan.addtnField4 != nil && quotationIO.baseDO.getBasePlan.addtnField4 == "DA" ||quotationIO.baseDO.getBasePlan.addtnField4 == "PR"
		  if(quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["bidaprmyear"]!=nil)
			mYear = quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["bidaprmyear"]["0"]
			finalString << "(P "
			finalString << quotationIO.baseDO.getBasePlan.premiumPayingTerm.to_s
			finalString << " $SEMI$ M "
			finalString << mYear.to_s
			finalString << ")"
		  end
		end
	  elsif facetDO.actionValue == "WEXP0A" || facetDO.actionValue == "WEVP0A" || facetDO.actionValue == "IBXP0A" || facetDO.actionValue == "IBVP0A" || facetDO.actionValue == "SA8P0A"
		if(quotationIO.baseDO.getBasePlan.addtnField4 != nil && quotationIO.baseDO.getBasePlan.addtnField4 == "PUA")
		  if(quotationIO.baseDO.getBasePlan.addtnField6.to_s != "" && quotationIO.baseDO.getBasePlan.addtnField6.to_s == "Both")
			if(quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["bipuaebpmyear"] !=nil) #PUA EBP
			  mYear= quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["bipuaebpmyear"]["0"];
			  finalString <<"(P "
			  finalString <<quotationIO.baseDO.getBasePlan.premiumPayingTerm.to_s
			  finalString <<" $SEMI$ M "
			  finalString <<mYear.to_s
			  finalString <<") "
			end #bipuaebpmyear
			if(quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["bipuaaebmyear"]!=nil) # PUA AEB
			  mYear= quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["bipuaaebmyear"]["0"];
			  finalString << "(P "
			  finalString << quotationIO.baseDO.getBasePlan.premiumPayingTerm.to_s << "*"
			  finalString << " $SEMI$ M "
			  finalString << mYear.to_s << "*"
			  finalString << ")"
			end #bipuaaebmyear
		  elsif(quotationIO.baseDO.getBasePlan.addtnField6.to_s != "" && quotationIO.baseDO.getBasePlan.addtnField6.to_s == "EBP")
			if(quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["bipuaebpmyear"]!=nil)
			  mYear = quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["bipuaebpmyear"]["0"];
			  finalString << "(P "
			  finalString << quotationIO.baseDO.getBasePlan.premiumPayingTerm.to_s
			  finalString << " $SEMI$ M "
			  finalString << mYear.to_s
			  finalString << ")"
			end #bipuaebpmyear
		  elsif(quotationIO.baseDO.getBasePlan.addtnField6.to_s != "" && quotationIO.baseDO.getBasePlan.addtnField6.to_s == "AEB")
			if(quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["bipuaaebmyear"]!=nil)
			  mYear = quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["bipuaaebmyear"]["0"];
			  finalString << "(P "
			  finalString << quotationIO.baseDO.getBasePlan.premiumPayingTerm.to_s
			  finalString << " $SEMI$ M "
			  finalString << mYear.to_s
			  finalString << ")"
			end #bipuaaebmyear
		  end  #addtnField6
		elsif (quotationIO.baseDO.getBasePlan.addtnField4 != nil && (quotationIO.baseDO.getBasePlan.addtnField4 == "DA" || quotationIO.baseDO.getBasePlan.addtnField4 == "PR"))
		  if(quotationIO.baseDO.getBasePlan.addtnField6.to_s != "" && quotationIO.baseDO.getBasePlan.addtnField6.to_s == "Both")
			if(quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["bidaprebpmyear"]!=nil)
			  mYear= quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["bidaprebpmyear"]["0"];
			  finalString << "(P "
			  finalString << quotationIO.baseDO.getBasePlan.premiumPayingTerm.to_s
			  finalString << " $SEMI$ M "
			  finalString << mYear.to_s
			  finalString << ") "
			end #bidaprebpmyear
			if(quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["bidapraebmyear"]!=nil)
			  mYear= quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["bidapraebmyear"]["0"];
			  finalString << "(P "
			  finalString << quotationIO.baseDO.getBasePlan.premiumPayingTerm.to_s << "*"
			  finalString << " $SEMI$ M "
			  finalString << mYear.to_s << "*"
			  finalString << ")"
			end #bidapraebmyear
		  elsif(quotationIO.baseDO.getBasePlan.addtnField6.to_s != "" && quotationIO.baseDO.getBasePlan.addtnField6.to_s == "EBP")
			if(quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["bidaprebpmyear"]!=nil)
			  mYear = quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["bidaprebpmyear"]["0"];
			  finalString << "(P "
			  finalString << quotationIO.baseDO.getBasePlan.premiumPayingTerm.to_s
			  finalString << " $SEMI$ M "
			  finalString << mYear.to_s
			  finalString << ")"
			end #bidaprebpmyear
		  elsif(quotationIO.baseDO.getBasePlan.addtnField6.to_s != "" && quotationIO.baseDO.getBasePlan.addtnField6.to_s == "AEB")
			if(quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["bidapraebmyear"]!=nil)
			  mYear= quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["bidapraebmyear"]["0"];
			  finalString << "(P "
			  finalString << quotationIO.baseDO.getBasePlan.premiumPayingTerm.to_s
			  finalString << " $SEMI$ M "
			  finalString << mYear.to_s
			  finalString << ")"
			end #bidapraebmyear
		  end #addtnField6
		end #getAddtnField4
	  elsif facetDO.actionValue == "SA8P0A" || facetDO.actionValue == "EV8P0A"
		if(quotationIO.baseDO.getBasePlan.addtnField6.to_s != "" && quotationIO.baseDO.getBasePlan.addtnField6.to_s == "Both")
		  if(quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["bidaprebpmyear"]!=nil)
			mYear= quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["bidaprebpmyear"]["0"];
			finalString << "(P "
			finalString << quotationIO.baseDO.getBasePlan.premiumPayingTerm.to_s
			finalString << " $SEMI$ M "
			finalString << mYear.to_s
			finalString << ") "
		  end
		  if(quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["bidapraebmyear"]!=nil)
			mYear= quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["bidapraebmyear"]["0"];
			finalString << "(P "
			finalString << quotationIO.baseDO.getBasePlan.premiumPayingTerm.to_s << "*"
			finalString << " $SEMI$ M "
			finalString << mYear.to_s << "*"
			finalString << ")"
		  end
		elsif(quotationIO.baseDO.getBasePlan.addtnField6.to_s != "" && quotationIO.baseDO.getBasePlan.addtnField6.to_s == "EBP")
		  if(quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["bidaprebpmyear"]!=nil)
			mYear = quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["bidaprebpmyear"]["0"]
			finalString << "(P "
			finalString << quotationIO.baseDO.getBasePlan.premiumPayingTerm.to_s
			finalString << " $SEMI$ M "
			finalString << mYear.to_s
			finalString << ")"
		  end
		elsif(quotationIO.baseDO.getBasePlan.addtnField6.to_s != "" && quotationIO.baseDO.getBasePlan.addtnField6.to_s == "AEB")
		  if(quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["bidapraebmyear"] != nil)
			mYear = quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["bidapraebmyear"]["0"];
			finalString << "(P "
			finalString << quotationIO.baseDO.getBasePlan.premiumPayingTerm.to_s
			finalString << " $SEMI$ M "
			finalString << mYear.to_s
			finalString << ")"
		  end
		end
#Elite RP, ProSecure Plus Regular Pay
	  elsif facetDO.actionValue == "WERP0A" || facetDO.actionValue == "GPPP0A"
		if quotationIO.baseDO.getBasePlan.addtnField4 != nil && quotationIO.baseDO.getBasePlan.addtnField4 == "PUA"
		  #PUA  Both
		  if quotationIO.baseDO.getBasePlan.addtnField6.to_s != "" && quotationIO.baseDO.getBasePlan.addtnField6.to_s == "Both"
			if quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["efebppuapyear"] != nil && quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["efebppuamyear"] != nil
			  mYear = quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["efebppuamyear"]["0"]
			  pYear = quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["efebppuapyear"]["0"]
			  finalString << "(P "
			  finalString << pYear.to_s
			  finalString << " $SEMI$ M "
			  finalString << mYear.to_s
			  finalString << ") "
			end
			if quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["efaebpuapyear"] != nil && quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["efaebpuamyear"]!=nil
			  pYear = quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["efaebpuapyear"]["0"]
			  mYear = quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["efaebpuamyear"]["0"]
			  finalString << "(P "
			  finalString << pYear.to_s << "*"
			  finalString << " $SEMI$ M "
			  finalString << mYear.to_s << "*"
			  finalString << ")"
			end
		  #PUA  EBP
		  elsif quotationIO.baseDO.getBasePlan.addtnField6.to_s != "" && quotationIO.baseDO.getBasePlan.addtnField6.to_s == "EBP"
			if quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["efebppuapyear"] !=nil && quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["efebppuamyear"] != nil
			  mYear = quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["efebppuamyear"]["0"]
			  pYear = quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["efebppuapyear"]["0"]
			  finalString << "(P "
			  finalString << pYear.to_s
			  finalString << " $SEMI$ M "
			  finalString << mYear.to_s
			  finalString << ")"
			end
		  #PUA  AEB
		  elsif quotationIO.baseDO.getBasePlan.addtnField6.to_s != "" && quotationIO.baseDO.getBasePlan.addtnField6.to_s == "AEB"
			if quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["efaebpuapyear"]!=nil && quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["efaebpuamyear"]!=nil
			  pYear = quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["efaebpuapyear"]["0"]
			  mYear = quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["efaebpuamyear"]["0"]
			  finalString << "(P "
			  finalString << pYear.to_s
			  finalString << " $SEMI$ M "
			  finalString << mYear.to_s
			  finalString << ")"
			end
		  end
		#IF DA/PR
		elsif quotationIO.baseDO.getBasePlan.addtnField4 != nil && quotationIO.baseDO.getBasePlan.addtnField4 == "DA" || quotationIO.baseDO.getBasePlan.addtnField4 == "PR"
		  if quotationIO.baseDO.getBasePlan.addtnField6.to_s != "" && quotationIO.baseDO.getBasePlan.addtnField6== "Both"
			if quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["efebpdapyear"]!=nil &&
				quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["efebpdamyear"]!=nil
			  pYear = quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["efebpdapyear"]["0"]
			  mYear = quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["efebpdamyear"]["0"]
			  finalString << "(P "
			  finalString << pYear.to_s
			  finalString << " $SEMI$ M "
			  finalString << mYear.to_s
			  finalString << ") "
			end
			if quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["efaebdapyear"]!=nil && quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["efaebdamyear"]!=nil
			  pYear= quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["efaebdapyear"]["0"]
			  mYear= quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["efaebdamyear"]["0"]
			  finalString << "(P "
			  finalString << pYear.to_s << "*"
			  finalString << " $SEMI$ M "
			  finalString << mYear.to_s << "*"
			  finalString << ")"
			end
		  # DA/PR - EBP
		  elsif quotationIO.baseDO.getBasePlan.addtnField6.to_s != "" && quotationIO.baseDO.getBasePlan.addtnField6.to_s == "EBP"
			if quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["efebpdapyear"] !=nil && quotationIO.finalMap[ quotationIO.baseDO.getBasePlan.productTerm.to_i]["efebpdamyear"] !=nil
			  pYear = quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["efebpdapyear"]["0"]
			  mYear = quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["efebpdamyear"]["0"]
			  finalString << "(P "
			  finalString << pYear.to_s
			  finalString << " $SEMI$ M "
			  finalString << mYear.to_s
			  finalString << ")"
			end
		  #DA/PR - AEB
		  elsif quotationIO.baseDO.getBasePlan.addtnField6.to_s != "" && quotationIO.baseDO.getBasePlan.addtnField6.to_s =="AEB"
			if quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["efaebdapyear"]!=nil && quotationIO.finalMap[ quotationIO.baseDO.getBasePlan.productTerm.to_i]["efaebdamyear"]!=nil
			  pYear= quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["efaebdapyear"]["0"]
			  mYear= quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["efaebdamyear"]["0"]
			  finalString << "(P "
			  finalString << pYear.to_s
			  finalString << " $SEMI$ M "
			  finalString << mYear.to_s
			  finalString << ")"
			end
		  end
		end
	  # Classic RP , ProSecure Regular Pay
	  elsif facetDO.actionValue == "WLRP0A" || facetDO.actionValue == "GPSP0A"
		if quotationIO.baseDO.getBasePlan.addtnField4 != nil && quotationIO.baseDO.getBasePlan.addtnField4 == "PUA"
		  if quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["efebppuapyear"]!=nil && quotationIO.finalMap[ quotationIO.baseDO.getBasePlan.productTerm.to_i]["efebppuamyear"]!=nil
			pYear= quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["efebppuapyear"]["0"]
			mYear= quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["efebppuamyear"]["0"]
			finalString << "(P "
			finalString<< pYear.to_s
			finalString<<" $SEMI$ M "
			finalString<< mYear.to_s
			finalString<<")"
		  end
		elsif quotationIO.baseDO.getBasePlan.addtnField4 != nil && quotationIO.baseDO.getBasePlan.addtnField4 == "DA" ||quotationIO.baseDO.getBasePlan.addtnField4 == "PR"
		  if quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["efebpdapyear"]!=nil && quotationIO.finalMap[ quotationIO. baseDO.getBasePlan.productTerm.to_i]["efebpdamyear"]!=nil
			pYear= quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["efebpdapyear"]["0"]
			mYear= quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["efebpdamyear"]["0"]
			finalString << "(P "
			finalString << pYear.to_s
			finalString << " $SEMI$ M "
			finalString << mYear.to_s
			finalString << ")"
		  end
		end
	  end
	  return finalString;
		end

		 def self.getFundPageHeaderSection(quotationIO, fundID, mvelHashMap, pageOrder)
			finalString = "";
			surrenderApplicable = mvelHashMap["isCashSurrenderApplicable"]
			rateHashMap = getRate(mvelHashMap, fundID);
			rate1=rateHashMap["Low"]
			rate2=rateHashMap["Medium"]
			rate3=rateHashMap["High"]
			displayRate1 = (rate1.to_f*100).to_i;
			displayRate2 = (rate2.to_f*100).to_i;
			displayRate3 = (rate3.to_f*100).to_i;
			isChargeSelected=false;

			if mvelHashMap["outputPreferencesDO"] !=nil && mvelHashMap["outputPreferencesDO"].field4 == "YES"
				isChargeSelected=true;
			end
			fundName="";
			fundAllocatonPercent=0;
			fundName = mvelHashMap["fundDOHashMap"][fundID].fundDesc;
			fundAllocatonPercent = mvelHashMap[fundID].allocationPerc.to_i;

			finalString << "<div class=\"SLFSectionTitle fontFamilyATLBold fontSize20\" >	Illustration of Benefits - "+fundName+" ("+(fundAllocatonPercent.to_s) +"%) "
			if(surrenderApplicable)
				finalString=finalString.concat(pageOrder.to_s+" of 2");
			end
			finalString=finalString.concat("</div>");
			if(quotationIO.baseDO.topupOptionCd !=nil && quotationIO.baseDO.topupOptionCd != "")
				if (quotationIO.baseDO.topupOptionCd == "EXCESSWITHPH" || quotationIO.baseDO.topupOptionCd == "TFCALCULATIONWITHPH" || quotationIO.baseDO.topupOptionCd == "EXCESSANDTFCALCULATIONWITHPH")
					finalString=finalString.concat("<p class=\"fontSize13 fontFamilyGFB\">It is assumed in the table below that the regular premiums are paid in full throughout the duration of the contract.</p>");
				end
			end
			finalString=finalString.concat("<p class=\"fontSize13 fontFamilyGFB\">The values illustrated below are not guaranteed. The investment returns used are for illustrative purposes and are not based on past performance with respect to the fund where your policy is linked. The returns are likely to change during the investment period. Also, the assumed returns do not represent the upper and lower limits of the actual return that may be realized. Values are calculated assuming the fund is earning "+displayRate1.to_s+"%*, "+displayRate2.to_s+"%* and "+displayRate3.to_s+"%*.");
			if(mvelHashMap["productDO"].getFacetFast("PREMIUMDETAILS")!= nil && mvelHashMap["productDO"].getFacetFast("PREMIUMDETAILS").getPremiumDetails.premiumTypeCd != "SINGLE")
			#if(quotationIO.baseDO.getBaseProduct.product.getFacetFast("PREMIUMDETAILS")!= nil && quotationIO.baseDO.getBaseProduct.product.getFacetFast("PREMIUMDETAILS").getPremiumDetails.premiumTypeCd != "SINGLE")
				finalString=finalString.concat(" It is assumed that the mode of payment is annual. If mode of payment is other than annual, values shown may change.");
			end
			finalString=finalString.concat("</p>");


			#Generate Top notes
			 if(isChargeSelected)
				 finalString=finalString.concat("<table class=\"SLFBenefitTable fontSize12 fontFamilyGFB\">");
				 finalString=finalString.concat("	    <tr  Style=\"line-height:13px;\">");
				 finalString=finalString.concat("			  <td colspan=\"4\" ></td>");
				 finalString=finalString.concat("			  <td colspan=\"8\" Style=\"text-align: center;\">PROJECTED BENEFITS</td>");
				 finalString=finalString.concat("				</tr>  <tr>");
				 finalString=finalString.concat("			  <td class=\"benefitHeader\" rowspan=\"3\"width=\"3%\">End of Year</td>");
				 finalString=finalString.concat("			  <td class=\"benefitHeader\" rowspan=\"3\"width=\"9%\">Attained<br/> Age</td>");
				 finalString=finalString.concat("			  <td class=\"benefitHeader\" rowspan=\"3\"width=\"9%\">Premiums<br/>Paid</td>");
				 finalString=finalString.concat("			  <td class=\"benefitHeader\" rowspan=\"3\"width=\"9%\">Charges**</td>");
				 finalString=finalString.concat("			  <td class=\"separator\">&nbsp;</td>");
				 finalString=finalString.concat("			  <td class=\"fundEarningTop\" colspan=\"3\">Policy Fund Value</td>");
				 finalString=finalString.concat("			  <td class=\"separator\">&nbsp;</td>");
				 if(pageOrder ==1)
				 finalString=finalString.concat("			  <td class=\"fundEarningTop\" colspan=\"3\">Cash Surrender Value</td>");
				 else
					 finalString=finalString.concat("			  <td class=\"fundEarningTop\" colspan=\"3\">Death Benefit</td>");
				 end
				 finalString=finalString.concat("		 	  </tr><tr>");
				 finalString=finalString.concat("			  <td class=\"separator\" >&nbsp;</td>");
				 finalString=finalString.concat("			  <td class=\"fundPercentTop\"width=\"12%\">"+displayRate1.to_s+"%</td>");
				 finalString=finalString.concat("			  <td class=\"fundPercentTop\"width=\"12%\">"+displayRate2.to_s+"%</td>");
				 finalString=finalString.concat("			  <td class=\"fundPercentTop\"width=\"11%\">"+displayRate3.to_s+"%</td>");
				 finalString=finalString.concat("			  <td class=\"separator\">&nbsp;</td>");
				 finalString=finalString.concat("			  <td class=\"fundPercentTop\"width=\"12%\">"+displayRate1.to_s+"%</td>");
				 finalString=finalString.concat("			  <td class=\"fundPercentTop\"width=\"12%\">"+displayRate2.to_s+"%</td>");
				 finalString=finalString.concat("			  <td class=\"fundPercentTop\"width=\"11%\">"+displayRate3.to_s+"%</td>");
				 finalString=finalString.concat("		    </tr><tr>");
				 finalString=finalString.concat("			 <td class=\"separator\" >&nbsp;</td>");
				 finalString=finalString.concat("			  <td class=\"fund-blank\">&nbsp;</td>");
				 finalString=finalString.concat("			  <td class=\"fund-blank\">&nbsp;</td>");
				 finalString=finalString.concat("			  <td class=\"fund-blank\">&nbsp;</td>");
				 finalString=finalString.concat("			  <td class=\"separator\">&nbsp;</td>");
				 finalString=finalString.concat("			  <td class=\"fund-blank\">&nbsp;</td>");
				 finalString=finalString.concat("			  <td class=\"fund-blank\">&nbsp;</td>");
				 finalString=finalString.concat("			  <td class=\"fund-blank\">&nbsp;</td></tr>");
			 else
				 finalString=finalString.concat("<table class=\"SLFBenefitTable fontSize12 fontFamilyGFB\">");
				 finalString=finalString.concat("	    <tr  Style=\"line-height:13px;\">");
				 finalString=finalString.concat("			  <td colspan=\"3\" ></td>");
				 finalString=finalString.concat("			  <td colspan=\"8\" Style=\"text-align: center;\">PROJECTED BENEFITS</td>");
				 finalString=finalString.concat("				</tr>  <tr>");
				 finalString=finalString.concat("			  <td class=\"benefitHeader\" rowspan=\"3\"width=\"4%\">End of Year</td>");
				 finalString=finalString.concat("			  <td class=\"benefitHeader\" rowspan=\"3\"width=\"13%\">Attained<br> Age</td>");
				 finalString=finalString.concat("			  <td class=\"benefitHeader\" rowspan=\"3\"width=\"13%\">Premiums<br> Paid</td>");
				 finalString=finalString.concat("			  <td class=\"separator\">&nbsp;</td>");
				 finalString=finalString.concat("			  <td class=\"fundEarningTop\" colspan=\"3\">Policy Fund Value</td>");
				 finalString=finalString.concat("			  <td class=\"separator\">&nbsp;</td>");
				 if(pageOrder ==1)
				 finalString=finalString.concat("			  <td class=\"fundEarningTop\" colspan=\"3\">Cash Surrender Value</td>");
				 else
					 finalString=finalString.concat("			  <td class=\"fundEarningTop\" colspan=\"3\">Death Benefit</td>");
				 end
				 finalString=finalString.concat("		 	  </tr><tr>");
				 finalString=finalString.concat("			  <td class=\"separator\" >&nbsp;</td>");
				 finalString=finalString.concat("			  <td class=\"fundPercentTop\"width=\"12%\">"+displayRate1.to_s+"%</td>");
				 finalString=finalString.concat("			  <td class=\"fundPercentTop\"width=\"12%\">"+displayRate2.to_s+"%</td>");
				 finalString=finalString.concat("			  <td class=\"fundPercentTop\"width=\"11%\">"+displayRate3.to_s+"%</td>");
				 finalString=finalString.concat("			  <td class=\"separator\">&nbsp;</td>");
				 finalString=finalString.concat("			  <td class=\"fundPercentTop\"width=\"12%\">"+displayRate1.to_s+"%</td>");
				 finalString=finalString.concat("			  <td class=\"fundPercentTop\"width=\"12%\">"+displayRate2.to_s+"%</td>");
				 finalString=finalString.concat("			  <td class=\"fundPercentTop\"width=\"11%\">"+displayRate3.to_s+"%</td>");
				 finalString=finalString.concat("		    </tr><tr>");
				 finalString=finalString.concat("			 <td class=\"separator\" >&nbsp;</td>");
				 finalString=finalString.concat("			  <td class=\"fund-blank\">&nbsp;</td>");
				 finalString=finalString.concat("			  <td class=\"fund-blank\">&nbsp;</td>");
				 finalString=finalString.concat("			  <td class=\"fund-blank\">&nbsp;</td>");
				 finalString=finalString.concat("			  <td class=\"separator\">&nbsp;</td>");
				 finalString=finalString.concat("			  <td class=\"fund-blank\">&nbsp;</td>");
				 finalString=finalString.concat("			  <td class=\"fund-blank\">&nbsp;</td>");
				 finalString=finalString.concat("			  <td class=\"fund-blank\">&nbsp;</td></tr>");
			 end
			 finalString=finalString.concat("<tr style=\"line-height:2px;\"><td colspan=\"9\">&nbsp;</td></tr>");  #to add a space between the first entry and the table headers
			return finalString ;
		end

		def self.getFundPageTableSection(quotationIO, fundID, mvelHashMap, pageOrder, section)
			getUpdateHashMap(mvelHashMap)
			# puts "fundID===>#{fundID}"
			 # puts "mvelHashMap===#{mvelHashMap}"
			# puts "finalMap===>#{quotationIO.finalMap[1].to_json}"
			finalString="";
			rateHashMap = getRate(mvelHashMap, fundID);
			#p "rateHashMap===>#{rateHashMap}"
			rate1=rateHashMap["Low"]
			rate2=rateHashMap["Medium"]
			rate3=rateHashMap["High"]
			tdStyle = "";
			isChargeSelected=false;
			isCalendarYear=false;
			chargesElement = "accumchargescompute";
			facetDO = mvelHashMap["productDO"].getFacetFast("RIDERASSOCIATION")
			if(facetDO != nil)
			riderAssociationDOList = facetDO.OfflineRiderAssociationList
				riderAssociationDOList.each do |riderAssociationDO|
					if(riderAssociationDO.productId != nil)
						if(riderAssociationDO.productId == "ADB25" || riderAssociationDO.productId == "ADB50" || riderAssociationDO.productId == "ADB75" || riderAssociationDO.productId == "ADB100")
							chargesElement = "accumchargesad";
							break;
						end
					end
				end
			end
			if(mvelHashMap["outputPreferencesDO"]!=nil && mvelHashMap["outputPreferencesDO"].field4 == "YES")
				isChargeSelected=true;
			end

			if(mvelHashMap["outputPreferencesDO"]!=nil && mvelHashMap["outputPreferencesDO"].field2 == "CALENDARYEAR")
				isCalendarYear=true;
			end

			if(isChargeSelected)
				tdStyle="style=\"text-align:center\",style=\"text-align:center\",style=\"text-align:right\",style=\"text-align:right\",style=\"text-align:right\"colspan=\"2\",style=\"text-align:right\",style=\"text-align:right\",style=\"text-align:right\"colspan=\"2\",style=\"text-align:right\",style=\"text-align:right\"";
				if(pageOrder ==2)
					element = "duration,attainedage,premiumspaid,"+chargesElement+",fundvalue,fundvalue,fundvalue,deathbenefit,deathbenefit,deathbenefit";
					 rate = "0,0,"+rate1.to_s+fundID+","+rate1.to_s+fundID+","+rate1.to_s+fundID+","+rate2.to_s+fundID+","+rate3.to_s+fundID+","+rate1.to_s+fundID+","+rate2.to_s+fundID+","+rate3.to_s+fundID ;
				else
					element = "duration,attainedage,premiumspaid,"+chargesElement+",fundvalue,fundvalue,fundvalue,cashvalue,cashvalue,cashvalue";
					 rate = "0,0,"+rate1.to_s+fundID+","+rate1.to_s+fundID+","+rate1.to_s+fundID+","+rate2.to_s+fundID+","+rate3.to_s+fundID+","+rate1.to_s+fundID+","+rate2.to_s+fundID+","+rate3.to_s+fundID  ;
				end
			else
				tdStyle="style=\"text-align:center\",style=\"text-align:center\",style=\"text-align:right\",style=\"text-align:right\"colspan=\"2\",style=\"text-align:right\",style=\"text-align:right\",style=\"text-align:right\"colspan=\"2\",style=\"text-align:right\",style=\"text-align:right\"";
				if(pageOrder ==2)
					element = "duration,attainedage,premiumspaid,fundvalue,fundvalue,fundvalue,deathbenefit,deathbenefit,deathbenefit";
					rate = "0,0,"+rate1.to_s+fundID+","+rate1.to_s+fundID+","+rate2.to_s+fundID+","+rate3.to_s+fundID+","+rate1.to_s+fundID+","+rate2.to_s+fundID+","+rate3.to_s+fundID ;
				else
					element = "duration,attainedage,premiumspaid,fundvalue,fundvalue,fundvalue,cashvalue,cashvalue,cashvalue";
					rate = "0,0,"+rate1.to_s+fundID+","+rate1.to_s+fundID+","+rate2.to_s+fundID+","+rate3.to_s+fundID+","+rate1.to_s+fundID+","+rate2.to_s+fundID+","+rate3.to_s+fundID  ;
				end
			end
			finalString = finalString.concat("element${"+element+"}$element");
			finalString = finalString.concat("rate${"+rate+"}$rate");
			finalString = finalString.concat("mvelPolicyYear${duration}$mvelPolicyYear");
			finalString = finalString.concat("tdStyle${"+tdStyle+"}$tdStyle");


			if(isCalendarYear)
				finalString = finalString.concat("duration_modifyPerCycle${ 					" +
						"mvelPerCycle${						" +
						"if(quotationIO.outputPreferencesDO !=nil && quotationIO.outputPreferencesDO.field2 == \"CALENDARYEAR\");							" +
							"policyYear =duration;				" +
							"calanderYear = policyYear + mvelHashMap[\"calendarYear\"].to_i;							" +
							"return \"\"+calanderYear.to_s;										" +
						"else;
							return duration;					" +
						"end;					}$mvelPerCycle				" +
							"}$duration_modifyPerCycle");
			end
			if(section == "age")
				myFutureMaturityYear="";
				if(mvelHashMap[fundID] && mvelHashMap[fundID].fundTypeCd == "MyFuture")
					fd = mvelHashMap[fundID];
					milestoneYear = DateTime.strptime(fd.maturityDt.to_s, "%Y-%m-%d").year - DateTime.strptime(quotationIO.baseDO.issueDt.to_s, "%Y-%m-%d").year;
					myFutureMaturityYear = milestoneYear > 20 ? ("," + milestoneYear.to_s) : "";
				end
			finalString = finalString.concat( "policyYearCondition${"+generateAgeConditionForPHAndIB(quotationIO,"BI")+myFutureMaturityYear+"}$policyYearCondition");
			#changes 16 oct start
			if(quotationIO.baseDO.topupOptionCd != nil && (quotationIO.baseDO.topupOptionCd == "TFCALCULATIONWITHPH" || quotationIO.baseDO.topupOptionCd == "EXCESSANDTFCALCULATIONWITHPH"))
				finalString = finalString.concat( "yearConditionSort${false}$yearConditionSort");
			end
			#changes 16 oct end
			elsif(mvelHashMap["outputPreferencesDO"] !=nil && mvelHashMap["outputPreferencesDO"].field3 != "YES")
				finalString = finalString.concat( "policyYearCondition${1-20}$policyYearCondition");
			end
			finalString = finalString.concat( "max${25}$max");
		#	p "finalString===>#{finalString}"
			return finalString;

		end

		def self.ordinalSuffix(fundValue)
		   	last_number = fundValue % 10
		    second_number = fundValue % 100
		    if (last_number == 1 && second_number != 11) 
		    	return "#{fundValue}<sup>st</sup>"
		    end
		    if (last_number == 2 && second_number != 12) 
		    	return "#{fundValue}<sup>nd</sup>"
		    end
		    if (last_number == 3 && second_number != 13) 
		    	return "#{fundValue}<sup>rd</sup>"
		    end   
		    return "#{fundValue}<sup>th</sup>"
		end


		def self.getFundPageBottomNotes( quotationIO, fundID, mvelHashMap)
			finalString = "";
			finalString=finalString.concat("</table>");
			key = "fmcFundRate"+fundID;
			fmcRate=UIGenUtilCompanyHelper.getFormatDoubleTwoDecimalWithComma((mvelHashMap[key].to_f*100))
			isChargeSelected = false;
			if(mvelHashMap["outputPreferencesDO"] !=nil && (mvelHashMap["outputPreferencesDO"].field4 == "YES") )
				isChargeSelected =true;
			end
			rateHashMap = getRate(mvelHashMap, fundID);
			rate1=rateHashMap["Low"]
			displayRate1 = (rate1.to_f*100).to_i
			 #Generate Bottom notes
            maxiLinkFacet = mvelHashMap["productDO"].getFacet("INDIVIDUALFUNDLIST")
			#Changes 18 Sept 2014 start
			currCalanderYear = mvelHashMap["calendarYear"].to_i
			fundValueDurLowYear = mvelHashMap["FundValueDurLowYear"].to_i
			fundValueDurMediumYear = mvelHashMap["FundValueDurMediumYear"].to_i
			fundValueDurHighYear =  mvelHashMap["FundValueDurHighYear"].to_i

			if(mvelHashMap["fundList"].size == 1) && !maxiLinkFacet
				if(mvelHashMap["FundValueDur"])
					 if mvelHashMap["productDO"].getFacet("PREMIUMDETAILS") != nil && (mvelHashMap["productDO"].getFacet("PREMIUMDETAILS").getPremiumDetails.premiumTypeCd == "LIMITED")
							finalString << "<div class=\"fontSize12 fontFamilyGFB tableFootnote \" style =\"padding-top:3px\">"
							finalString << "Premium payment period of "+(quotationIO.baseDO.getBasePlan.premiumPayingTerm).to_s+ " years is not guaranteed. You may still be required to pay additional premium after " + (quotationIO.baseDO.getBasePlan.premiumPayingTerm).to_s+ " years if the fund value is insufficient to pay the charges. "
							finalString << "</div>"

					else
							if(fundValueDurHighYear > 0)
								 if quotationIO.outputPreferencesDO != nil && quotationIO.outputPreferencesDO.field2 == "CALENDARYEAR"
								finalString << "<div class=\"fontSize12 fontFamilyGFB tableFootnote \" style =\"padding-top:3px\">"
								finalString << "Based on a #{UIGenUtilCompanyHelper.roundingWeightedAvgRate(mvelHashMap["avgHIGH"],mvelHashMap["allChosenFundRateFlag"]) }% projected rate of return, your policy may continue until the end of the " + (fundValueDurHighYear+currCalanderYear-1).to_s + ". If excess premium payment is not made on the " + (fundValueDurHighYear+currCalanderYear).to_s + ", the policy will terminate since fund value is not sufficient to pay for the monthly charges.";
								finalString << "</div>"
								else
								finalString << "<div class=\"fontSize12 fontFamilyGFB tableFootnote \" style =\"padding-top:3px\">"
								finalString << "Based on a #{UIGenUtilCompanyHelper.roundingWeightedAvgRate(mvelHashMap["avgHIGH"],mvelHashMap["allChosenFundRateFlag"]) }% projected rate of return, your policy may continue until the end of the " + ordinalSuffix(fundValueDurHighYear-1).to_s + " policy year. If excess premium payment is not made on the " + ordinalSuffix(fundValueDurHighYear).to_s + " policy year, the policy will terminate since fund value is not sufficient to pay for the monthly charges.";
								finalString << "</div>"
								end
							end

							if(fundValueDurMediumYear > 0)
								 if quotationIO.outputPreferencesDO != nil && quotationIO.outputPreferencesDO.field2 == "CALENDARYEAR"
								finalString << "<div class=\"fontSize12 fontFamilyGFB tableFootnote \" style =\"padding-top:3px\">"
								finalString << "Based on a #{UIGenUtilCompanyHelper.roundingWeightedAvgRate(mvelHashMap["avgMEDIUM"],mvelHashMap["allChosenFundRateFlag"]) }% projected rate of return, your policy may continue until the end of the " + (fundValueDurMediumYear+currCalanderYear-1).to_s + ". If excess premium payment is not made on the " + (fundValueDurMediumYear+currCalanderYear).to_s + ", the policy will terminate since fund value is not sufficient to pay for the monthly charges.";
								finalString << "</div>"
								else
								finalString << "<div class=\"fontSize12 fontFamilyGFB tableFootnote \" style =\"padding-top:3px\">"
								finalString << "Based on a #{UIGenUtilCompanyHelper.roundingWeightedAvgRate(mvelHashMap["avgMEDIUM"],mvelHashMap["allChosenFundRateFlag"]) }% projected rate of return, your policy may continue until the end of the " + ordinalSuffix(fundValueDurMediumYear-1).to_s + " policy year. If excess premium payment is not made on the " + ordinalSuffix(fundValueDurMediumYear).to_s + " policy year, the policy will terminate since fund value is not sufficient to pay for the monthly charges.";
								finalString << "</div>"
								end
							end

							if(fundValueDurLowYear > 0)
								 if quotationIO.outputPreferencesDO != nil && quotationIO.outputPreferencesDO.field2 == "CALENDARYEAR"
								finalString << "<div class=\"fontSize12 fontFamilyGFB tableFootnote \" style =\"padding-top:3px\">"
								finalString << "Based on a  #{UIGenUtilCompanyHelper.roundingWeightedAvgRate(mvelHashMap["avgLOW"],mvelHashMap["allChosenFundRateFlag"]) }% projected rate of return, your policy may continue until the end of the " + (fundValueDurLowYear+currCalanderYear-1).to_s + ". If excess premium payment is not made on the " + (fundValueDurLowYear+currCalanderYear).to_s + ", the policy will terminate since fund value is not sufficient to pay for the monthly charges.";
								finalString << "</div>"
								else
								finalString << "<div class=\"fontSize12 fontFamilyGFB tableFootnote \" style =\"padding-top:3px\">"
								finalString << "Based on a #{UIGenUtilCompanyHelper.roundingWeightedAvgRate(mvelHashMap["avgLOW"],mvelHashMap["allChosenFundRateFlag"]) }% projected rate of return, your policy may continue until the end of the " + ordinalSuffix(fundValueDurLowYear-1).to_s + " policy year. If excess premium payment is not made on the " + ordinalSuffix(fundValueDurLowYear).to_s + "policy year, the policy will terminate since fund value is not sufficient to pay for the monthly charges.";
								finalString << "</div>"
								end
							end

					end
				end
			end
			if maxiLinkFacet
				if(fundValueDurLowYear > 0)
					if quotationIO.outputPreferencesDO != nil && quotationIO.outputPreferencesDO.field2 == "CALENDARYEAR"
					finalString << "<div class=\"fontSize12 fontFamilyGFB tableFootnote \" style =\"padding-top:5px$SEMI$padding-bottom:3px\">"
					finalString << "Based on a  #{UIGenUtilCompanyHelper.roundingWeightedAvgRate(rateHashMap["Low"],mvelHashMap["allChosenFundRateFlag"]) }% projected rate of return, policy may continue until the end of year " + (fundValueDurLowYear+currCalanderYear-1).to_s + ". If additional premium payment is not made on year " + (fundValueDurLowYear+currCalanderYear).to_s + ", the policy will terminate since fund value is not sufficient to pay for the monthly charges.";
					finalString << "</div>"
					else
					finalString << "<div class=\"fontSize12 fontFamilyGFB tableFootnote \" style =\"padding-top:5px$SEMI$padding-bottom:3px\">"
					finalString << "Based on a #{UIGenUtilCompanyHelper.roundingWeightedAvgRate(rateHashMap["Low"],mvelHashMap["allChosenFundRateFlag"]) }% projected rate of return, policy may continue until the end of the " + ordinalSuffix(fundValueDurLowYear-1).to_s + " policy year. If additional premium payment is not made on the " + ordinalSuffix(fundValueDurLowYear).to_s + " policy year, the policy will terminate since fund value is not sufficient to pay for the monthly charges.";
					finalString << "</div>"
					end
				end
			end
			#Changes 18 Sept 2014 end

	 		mfGroupName = ""
	    	mmFundName = ""
		    if(quotationIO.finalMap[1] != nil && quotationIO.finalMap[1]["myfuturefundgroupname"] != nil && quotationIO.finalMap[1]["myfuturefundgroupname"]["0"] != nil)
		      mfGroupName =quotationIO.finalMap[1]["myfuturefundgroupname"]["0"].gsub("\"","")
		  	end
		    if(quotationIO.finalMap[1] != nil && quotationIO.finalMap[1]["transferfundname"] != nil && quotationIO.finalMap[1]["transferfundname"]["0"] != nil)
		      mmFundName =quotationIO.finalMap[1]["transferfundname"]["0"].gsub("\"","")
		  	end
			#Generate Bottom notes
			 finalString=finalString.concat("<div class=\"fontSize12 fontFamilyGFB tableFootnote \" style =\"padding-bottom:5px\">");
			 if (mvelHashMap[fundID].fundTypeCd =="MyFuture")
				finalString << "Three (3) months prior to maturity, you will be notified of the maturing #{mfGroupName} and you will be asked of your reinvestment decision with "
				finalString << "regards to the #{mfGroupName} maturity benefit. If no instruction is received from you, then the #{mfGroupName} maturity benefit will be transferred to "
				finalString	<< "the #{mmFundName}. It is assumed in the illustration that the #{mfGroupName} Maturity Benefit is withdrawn by you at the maturity date.<br>"
			 end
			fundName="";
			fundList = mvelHashMap["fundList"]
			if (quotationIO.baseProduct.getFacet("PREMIUMDETAILS") != nil && quotationIO.baseProduct.getFacet("PREMIUMDETAILS").getPremiumDetails != nil && quotationIO.baseProduct.getFacet("PREMIUMDETAILS").getPremiumDetails.premiumTypeCd == "SINGLE")
				if(fundList.size==1 && quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["maxwithdrawaldur"] != nil && quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["maxwithdrawaldur"]["0"] != 0)
					fundName = mvelHashMap["fundDOHashMap"][fundID].fundDesc;
				end
			end
			finalString = finalString.concat("*The investment returns used are net of the fund management charge of "+fmcRate.to_s+"% (plus VAT) of the fund value");
			if(fundName == "")
				 finalString = finalString.concat(".");
			else
				 finalString = finalString.concat(" for "+fundName+".");
			end
			   finalString = finalString.concat("</div>");
			if(isChargeSelected) #SUNSS 2508
			 	productDO = quotationIO.baseDO.getBasePlan.getProduct
				illustrationcaveat = productDO.getFacet("ILLUSTRATIONBENEFITCAVEAT")
				if illustrationcaveat
			    	caveatLabel = illustrationcaveat.actionValue.to_s
			    end
				if illustrationcaveat
					finalString=finalString.concat("<div class=\"fontSize12 fontFamilyGFB\" style=\"margin-bottom:5px\">");
					finalString=finalString.concat(MobiSys::BrowserHelper.getLabel(caveatLabel));
					finalString=finalString.concat(" "+displayRate1.to_s+"%.</div>");
				else
					finalString=finalString.concat("<div class=\"fontSize12 fontFamilyGFB\" style=\"margin-bottom:5px\"> ** Charges are based on a "+displayRate1.to_s+"% investment return.</div>");
				end
			end
			 return finalString;
		end

		#18/08/2014: Swati Ahire
		#Changes added by comparing code with online
		def self.getTitlePageRiderSection(inMvelHashMap)
			mvelHashMap = inMvelHashMap
			finalString = ""
			riderList = mvelHashMap["riderList"]
			quotationIO = mvelHashMap["quotationIO"]
			printBlankTD = false
			dbRate = 0
			riderList.each do |rd|
				if quotationIO.baseDO.getBaseProduct.product.productFamilyId == "TRAD"
					#puts "ingetTitlePageRiderSection--- TRAD"
					riderName = rd.product.shortName == nil ? "" : ((rd.product.shortName.upcase.gsub(' OF 5YRCT', '').gsub(' (WAIVER OF PREMIUM)','')) + " (" + (rd.productId.gsub(' of 5YRCT', '')) +")")
				else
					#puts "ingetTitlePageRiderSection--- Vul"
					riderName = rd.product.longName == nil ? "" : ((rd.product.longName.upcase.gsub(' OF 5YRCT', '').gsub(' (WAIVER OF PREMIUM)','')) + " (" + (rd.productId.gsub(' of 5YRCT', '')) +")")
				end
				#riderName = rd.product.shortName == nil ? "" : ((rd.product.shortName.upcase.gsub(' OF 5YRCT', '').gsub(' (WAIVER OF PREMIUM)','')) + " (" + (rd.productId.gsub(' of 5YRCT', '')) +")")
				#changes 09 Oct 2014 start
				#if(rd.productId == "LBR")
				#	riderName = rd.product.longName == nil ? "" : rd.product.longName.upcase
				#end
				#changes 09 Oct 2014 end
				sumAssured = UIGenUtilCompanyHelper.getFormatDoubleTwoDecimalWithComma(rd.baseSumAssured.to_s)
				printBlankTD = (rd.baseSumAssured == nil ||  rd.baseSumAssured == 0) ? true : false

				if((rd.productId == "TDB of 5YRCT") && !(quotationIO.baseDO.getBasePlan.productId == "5RCP0A"  || quotationIO.baseDO.getBasePlan.productId == "GPTP0A" || quotationIO.baseDO.getBasePlan.productId == "GPTP0A_A"))
					next
				end

				if rd.productId == "5YRCT"
					dbRate = quotationIO.getIllustrationHeaderFieldValue("dbrate").to_f
					if mvelHashMap["isTDB5YRCTSelect"] == true
						finalString << "<tr><td class=\"col1\">SAFER LIFE RIDER - 5YRCT WITH TDB</td></tr>"
					else
						finalString << "<tr><td class=\"col1\">SAFER LIFE RIDER - 5YRCT</td></tr>"
					end
					finalString << "<tr><td class=\"col1\" style = \"padding-left:10px;\">FACE AMOUNT</td>"
					finalString << "<td><div class=\"col3\">"
					finalString << UIGenUtilCompanyHelper.getFormatDoubleTwoDecimalWithComma(rd.baseSumAssured.to_s)
					finalString << "</div></td></tr><tr><td class=\"col1\"style = \"padding-left:10px;\">LIFE INSURANCE COVERAGE</td><td><div class=\"col3\">"
					finalString << UIGenUtilCompanyHelper.getFormatDoubleTwoDecimalWithComma((rd.baseSumAssured * dbRate).to_s)
					finalString << "</div></td></tr>"
					next
				end
				if  rd.productId == "Grepa5YRCT"
					dbRate = quotationIO.getIllustrationHeaderFieldValue("dbrate").to_f
					if mvelHashMap["isTDB5YRCTSelect"] == true
						finalString << "<tr><td class=\"col1\">PROTERM RIDER - 5YRCT WITH TDB</td></tr>"
					else
						finalString << "<tr><td class=\"col1\">PROTERM RIDER - 5YRCT</td></tr>"
					end
				  finalString << "<tr><td class=\"col1\" style = \"padding-left:10px;\">FACE AMOUNT</td>"
				  finalString << "<td><div class=\"col3\">"
				  finalString << UIGenUtilCompanyHelper.getFormatDoubleTwoDecimalWithComma(rd.baseSumAssured.to_s)
				  finalString << "</div></td></tr><tr><td class=\"col1\"style = \"padding-left:10px;\">LIFE INSURANCE COVERAGE</td><td><div class=\"col3\">"
				  finalString << UIGenUtilCompanyHelper.getFormatDoubleTwoDecimalWithComma((rd.baseSumAssured * dbRate).to_s)
				  finalString << "</div></td></tr>"
				  next
				end
				################################################################# production support START~~~~SUNSS-1865~~~~~~~
				quotation = quotationIO.baseDO
	          	quotationResultDO = nil
	          	@riderNameFacet = CompanyFacet.find(:first,:conditions=>{:facetCd=>"RIDERSYMBOLTITLE"})
	          	riderSymbol = @riderNameFacet.actionValue if @riderNameFacet
	         	quotationResultDO = MobiSys::ProductBO.evaluateModel(quotation, rd, riderSymbol, false)
	          	if quotationResultDO && quotationResultDO.getFieldValueObject('rideroutput').to_s != "" && quotationResultDO.getFieldValueObject('rideroutput').to_s != "0.0"
	          		riderName = quotationResultDO.getFieldValueObject('rideroutput').to_s.upcase
	      		else
	      			if quotationIO.baseDO.getBaseProduct.product.productFamilyId == "TRAD"
	      				riderName = rd.product.longName.to_s.upcase.gsub(' OF 5YRCT', '').gsub(' (WAIVER OF PREMIUM)','') + " (" + (rd.productId.gsub(' of 5YRCT', '')) +")"
	      			else
	      				# riderName = rd.product.longName.to_s.upcase + " (" + (rd.productId.gsub(' of 5YRCT', '')) +")"
	      				riderName = riderName.gsub(/[^A-Za-z0-9, ()]/, '')
	      			end
	      		end
	      		# finalString = finalString.concat(riderName.to_s)
	      		################################################################### production support END~~~~~SUNSS-1865~~~~~~
				# riderName = riderName.gsub(/[^A-Za-z0-9 ()]/, '') #sunss-1175--- 19-09-2020
				# if(quotationIO.baseDO.getBaseProduct.product.productFamilyId == "VUL")
				# 	# p"inside the if cndtn================="
				# 	riderName = riderName.gsub(/[^A-Za-z0-9, ()]/, '') #sunss-1175--- 19-09-2020
				# end	
				finalString << "<tr><td class=\"col1\" style = \"text-align:left;\">"+riderName+"</td>"
				if printBlankTD || rd.productId == "TDB"|| rd.productId == "CBTD" || rd.productId == "TDB of 5YRCT" || (rd.product.getFacetFast("OTHERDETAILS") != nil && rd.product.getOtherDetailsFacet.OfflineOtherDetailsList[0].isWOPFl != "NO")
					finalString << "<td class=\"col3\"style=\"background-color:#FFFFFF\"></td>"
				else
					finalString << "<td><div class=\"col3\">"+sumAssured+"</div></td>"
				end
				finalString << "</tr>"
			end
			return finalString
		end

		def self.getAssumedInvestmentReturns(inQuotationIO, inFundList, inMvelHashMap)
			quotationIO = inQuotationIO
			fundList =  inFundList
			finalString = ""
			mvelHashMap = inMvelHashMap
			isMyFutureSelect = false
			myFutureFundDO = nil

			finalString << "<table  style=\"border-spacing:0px;width:50%;\" align=\"center\">"

			fundList.each do |fd|
				if fd.fundTypeCd == "MyFuture"
					isMyFutureSelect = true
					myFutureFundDO = mvelHashMap["fundDOHashMap"][fd.fundCd]
				end
			end

			fundList.each do |fd|
				if fd.fundTypeCd != "MyFuture"
					finalString << "<tr><td class=\"border1\" width=\"50%\" style=\"text-align:center;padding-right:10px;padding-left:10px;\">"
					fundName = mvelHashMap["fundDOHashMap"][fd.fundCd].fundDesc
					finalString << fundName.gsub(" Fund","")
					finalString << "</td><td class=\"border1\" width=\"50%\" style=\"text-align:center\">"
					finalString << UIGenUtilCompanyHelper.roundingTableData(getRate(mvelHashMap, fd.fundCd)["Low"].to_f*100).to_s+"%"
					finalString << "</td></tr>"
				end
			end

			if isMyFutureSelect
								   mfGroupName = ""
      			if(quotationIO.finalMap[1] != nil && quotationIO.finalMap[1]["myfuturefundgroupname"] != nil && quotationIO.finalMap[1]["myfuturefundgroupname"]["0"] != nil)
        			mfGroupName =quotationIO.finalMap[1]["myfuturefundgroupname"]["0"].gsub("\"","")
    			end
				moneyMarketFundName = quotationIO.finalMap[1]["transferfundname"]["0"].gsub("\"","")
				moneyMarketFundPercentage = UIGenUtilCompanyHelper.roundingTableData(((quotationIO.finalMap[1]["accumulationinterestratetf"]["0"]).to_f*100))
				finalString << "<tr><td class=\"border1\" width=\"50%\" style=\"text-align:center;padding-right:10px;padding-left:10px;\">#{mfGroupName}</td> <td class=\"border1\" width=\"50%\" style=\"text-align:center\"> "
				finalString << UIGenUtilCompanyHelper.roundingTableData(((getRate(mvelHashMap,myFutureFundDO.fundCd)["Low"].to_f*100)).to_s)
				finalString << "% </td></tr>"
				finalString << "<tr><td class=\"border1\" width=\"50%\" style=\"text-align:center;padding-right:10px;padding-left:10px;\">"+moneyMarketFundName+"</td> <td class=\"border1\" width=\"50%\" style=\"text-align:center\"> "+moneyMarketFundPercentage.to_s+"% </td></tr>"
			end
			finalString << "</table>"

			return finalString
		end

		def self.getDateForStructuredNotePlan(inDate, format, inQuotationIO)
			quotationIO = inQuotationIO
			date = Time.parse(inDate.to_s)
			newDate = DateTime.new(date.strftime("%Y").to_i + quotationIO.baseDO.getBasePlan.productTerm.to_i, date.month, date.day, 0, 0, 0, 0)
			return getFormattedInputDate(newDate,format);
		end

		def self.roundingWeightedAvgRate(rate, isRateWholeNumber)
			return isRateWholeNumber ? (UIGenUtilCompanyHelper.getFormatDoubleTwoDecimalWithComma(rate.to_f*100)) : (rate.to_f*100).round(2).to_i
		end

	#Swati Ahire 28-08-2014
	def self.getVarfuMileStoneAgeTRAD(inMvelHashMap)
	   mvelHashMap = inMvelHashMap
	   finalString = ""
	   quotationIO = mvelHashMap["quotationIO"]
	   lastYear = quotationIO.finalMap[1]["maxwithdrawaldur"]["0"].to_i
	   primaryAge=quotationIO.baseDO.getPartyListByRoleCd("PRIMARY")[0].age
	   modValue = (lastYear+ primaryAge) % 5
	   difference = 5 - modValue;
	   startAge = ((lastYear + difference + primaryAge) >= 45) ? (lastYear + difference) : 45 - primaryAge
	   lastAge = 80-primaryAge;
	   milestoneAges ="";
	   counter = 5;
	   i=startAge
	   while i <= lastAge
		 if counter == 5
			milestoneAges = milestoneAges.concat(i.to_s+",")
			counter = 0
		 end
		 counter = counter + 1
		 i = i+1
	   end
	   if milestoneAges.to_s == ""
		 milestoneAges = "500"
	   else
		 len = milestoneAges.length-1
		 milestoneAges = milestoneAges[0..len]
	   end
	   return milestoneAges
	end

	#Swati Ahire 28-08-2014
	def self.getPremiumHolidayPHDuration(inMvelHashMap,rate)
	  mvelHashMap = inMvelHashMap;
	  quotationIO = mvelHashMap["quotationIO"]
		productTerm = quotationIO.baseDO.getBasePlan.productTerm.to_i
		 fund =  mvelHashMap["chosenFundCd"];
		 fundrate = getRate(mvelHashMap, fund)[rate];
		i = 1
		while i <= productTerm
		  if(quotationIO.finalMap[i]["phduration"] != nil && quotationIO.finalMap[i]["phduration"][fundrate+fund].to_s == "1")
			return i
		 end
	   i = i+1;
		end
		return (productTerm+1)
	end

	def self.getFMCNotes(quotationIO,mvelHashMap)
			fundList=mvelHashMap["fundList"]
			finalString = ""
			i = 1
			fmc=""
			key = ""
			isMyFuture = false
			isSingleMyFuture = false
			mfGroupName = ""
    		if(quotationIO.finalMap[1] != nil && quotationIO.finalMap[1]["myfuturefundgroupname"] != nil && quotationIO.finalMap[1]["myfuturefundgroupname"]["0"] != nil)
      	 		mfGroupName =quotationIO.finalMap[1]["myfuturefundgroupname"]["0"].gsub("\"","")
      	 	end
			fundList.each do |fd|
				if(!(isMyFuture))
					isMyFuture = (fd.fundTypeCd == "MyFuture")
					key= "fmcFundRate"+fd.fundCd
					fmc=UIGenUtilCompanyHelper.getFormatDoubleTwoDecimalWithComma(mvelHashMap[key].to_f*100).to_s
					if(isMyFuture)
						finalString = finalString[0,finalString.length-1] if finalString != ""
						if(!(isSingleMyFuture) and finalString != "")
							finalString= finalString.concat(" and ")
						end
						finalString = finalString.concat(fmc+"% (plus VAT) of the fund value for #{mfGroupName} ")
					else
						finalString = finalString.concat(" "+fmc+"% (plus VAT) of the fund value for "+ mvelHashMap["fundDOHashMap"][fd.fundCd].fundDesc + " ");
					end
					if(i<(fundList.size-1) && !(isMyFuture))
						finalString = finalString[0,finalString.length-1]
						finalString= finalString.concat(",")
					else
						if((i==fundList.size-1) && !(isMyFuture))
							isSingleMyFuture = true;
							finalString= finalString.concat("and  ");
						end
					end
					i += 1
				end
			end
			finalString = finalString[0,finalString.length-1]
			return finalString;
		end

		def self.getAPOFMCNotes(quotationIO,mvelHashMap)

			fundList=mvelHashMap["apoFundList"]
			quotationIO = mvelHashMap["quotationIO"]
			finalString = ""
			i = 1
			fmc=""
			key = ""
			fundName = ""
			isMyFuture = false
			isSingleMyFuture = false
			mfGroupName = ""
		    if(quotationIO.finalMap[1] != nil && quotationIO.finalMap[1]["myfuturefundgroupname"] != nil && quotationIO.finalMap[1]["myfuturefundgroupname"]["0"] != nil)
		        mfGroupName =quotationIO.finalMap[1]["myfuturefundgroupname"]["0"].gsub("\"","")
		    end
			fundList.each do |fd|
				if( !(isMyFuture))
					isMyFuture = (fd.fundTypeCd == "MyFuture")
					key= "fmcFundRate"+fd.fundCd
					fmc=UIGenUtilCompanyHelper.getFormatDoubleTwoDecimalWithComma(mvelHashMap[key].to_f*100).to_s
					if(isMyFuture)
						fundName =  "for #{mfGroupName} "
					else
						fundName =  "for #{mvelHashMap["fundDOHashMap"][fd.fundCd].fundDesc} "
					end

					if(isMyFuture)
						finalString = finalString[0,finalString.length-1] if finalString != ""
						if(!(isSingleMyFuture) and finalString != "")
							finalString= finalString.concat(" and ")
						end
						finalString = finalString.concat(fmc+"% (plus VAT) of the fund value " +fundName)
					else
						finalString = finalString.concat(" "+fmc+"% (plus VAT) of the fund value "+fundName)
					end
					if(i<(fundList.size-1) && !(isMyFuture))
						finalString = finalString[0,finalString.length-1]
						finalString= finalString.concat(",")
					else
						if((i==fundList.size-1) && !(isMyFuture))
							isSingleMyFuture = true;
							finalString= finalString.concat("and  ");
						end
					end
					i += 1
				end
			end
			finalString = finalString[0,finalString.length-1]
			return finalString;
		end

		#changes 11 Nov 2014 Start
		def self.getFundNameForIllustrationOfBenefits(mvelHashMap,fundId)
			quotationIO = mvelHashMap["quotationIO"]
			fundName = ""
			fundList = mvelHashMap["fundList"]
			if(fundList.size <= 1 && quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["maxwithdrawaldur"] != nil && quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["maxwithdrawaldur"]["0"] != 0)
				fundName =  " for "+ mvelHashMap["fundDOHashMap"][fundId].fundDesc
			end
			return fundName;
		end
		#changes 11 Nov 2014 End



   #changes 11 Nov 2014 Start
		def self.getFundWithdrawalHashMap(mvelHashMap)
			quotationIO = mvelHashMap["quotationIO"]
			maxWithdrawalYear = 0;
			firstFinalMap = quotationIO.finalMap.values.first
			maxWithdrawalYear = firstFinalMap["maxwithdrawaldur"]["0"].to_i if firstFinalMap["maxwithdrawaldur"]
			#p "age in getFundWithdrawalHashMap===>#{quotationIO.baseDO.getPartyByRole("PRIMARY")}"
			issueAge = quotationIO.baseDO.getPartyByRole("PRIMARY").age.to_i
			isWithdrawalAt88 = false;
			if(quotationIO.finalMap.has_key?(quotationIO.baseDO.getBasePlan.productTerm.to_i))
				if(quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["maxwithdrawaldur"] != nil)
				maxWithdrawalYear = quotationIO.finalMap[quotationIO.baseDO.getBasePlan.productTerm.to_i]["maxwithdrawaldur"]["0"].to_i
				end
			end
						 if((maxWithdrawalYear.to_i+issueAge.to_i) == 88)

							 maxWithdrawalYear = maxWithdrawalYear.to_i-1;
							 isWithdrawalAt88 = true;
						 end
						 productTerm = quotationIO.baseDO.getBasePlan.productTerm.to_i;
						 isEducationBenefit = "EDUCATION" == quotationIO.baseDO.withdrawalRateTypeCd;
						 isWithdrawalTaken = true
						 isPureMFF =  mvelHashMap["isPureMyFutureFund"];
						 isSinglePageIllustration = false;
						 isTwoPageIllustration = false;
						 isThreePageIllustration = false;
						 page1TableYears="1-20";
						 page2TableYears="";
						 page3TableYears=88-issueAge.to_i;
						 astrikYear = "";
						 printNotesOnPage1 = false;
						 printNotesOnPage2 = false;
						 printNotesOnPage3 = false;
						 mileStoneAgeExists = true;
						 mileStoneAges = getFundWithdrawalAgeCondition(quotationIO);
						 a=mileStoneAges.split(",");

						 mileStoneAgeExists = (a[0] != "500") ? true : false;
						 totalRows = (a[0] != "500" ? (a.length + 1) : 0);
						 yearsList = MobiSys::UIGenUtil.getlist("1-"+ (maxWithdrawalYear>20 ? maxWithdrawalYear.to_s : "20"), "");
						 astrikYear = yearsList[yearsList.size-1].to_s;
						 totalRows = totalRows + yearsList.size;
						 for age in a
								yearsList.push(age.to_i) if age.to_s != "500";
						 end
						 if maxWithdrawalYear.to_s == "0"
							isWithdrawalTaken = false
						 end

						if((productTerm <= 20 || (isEducationBenefit && maxWithdrawalYear <= 14)) && isWithdrawalTaken)
							isSinglePageIllustration = true;
							if(isEducationBenefit)
								page1TableYears = "1-" + maxWithdrawalYear.to_s;
								mileStoneAgeExists = false;
							else
								page1TableYears = "1-" + productTerm.to_s;
							end
							mileStoneAgeExists = false;
							printNotesOnPage1 = true;
						end

						if(((productTerm > 20 && (totalRows <= 80) && !isEducationBenefit) || (isEducationBenefit && maxWithdrawalYear > 14)) && isWithdrawalTaken)

							isTwoPageIllustration = true;
							printNotesOnPage2 = true;
							page1TableYears = "";
							page2TableYears = "";
							if(isEducationBenefit)
								page1TableYears = "1-" + maxWithdrawalYear.to_s;
								page2TableYears =  maxWithdrawalYear.to_s;
								mileStoneAgeExists = false;
							else
								yearsList.push(88-issueAge);
								counter = 0;
									for year in yearsList
										if(counter < 53 && (year != (88-issueAge.to_i) || isWithdrawalAt88))

											if (year == (88-issueAge.to_i))
												page2TableYears = (88-issueAge.to_i).to_s + ","
											else
												page1TableYears = page1TableYears.concat(year.to_s+",")
											end
										else
											# SUNSS -1866 Start
											productDO = quotationIO.baseDO.getBasePlan.getProduct
											withdrawalFacet = productDO.getFacet("WITHDRAWALAGE100")
											if withdrawalFacet
												page2TableYears = (100-issueAge.to_i).to_s + ","
											else
												page2TableYears = page2TableYears.concat(year.to_s+",");
											end
											# SUNSS -1866 End
										end
										if(year == astrikYear.to_i && mileStoneAgeExists)
											counter += 1
										end
										counter = counter+1
									end
								page1TableYears=page1TableYears[0,page1TableYears.length-1];
								page2TableYears=page2TableYears[0,page2TableYears.length-1];
							end
						end

						if(((productTerm.to_i > 20 && (totalRows.to_i > 80))) && isWithdrawalTaken)

							page1TableYears = "";
							page2TableYears = "";
							isThreePageIllustration = true;
							counter = 0;
							for year in yearsList
								if(counter < 53)
									page1TableYears = page1TableYears.concat(year.to_s+",");
								else
									page2TableYears = page2TableYears.concat(year.to_s+",");
								end
								counter = counter+1
							end
							page1TableYears=page1TableYears[0,page1TableYears.length-1];
							page2TableYears=page2TableYears[0,page2TableYears.length-1];
							page3TableYears = productTerm.to_s;
							printNotesOnPage3 = true;
						end
						if((yearsList.index(astrikYear.to_i) != yearsList.size-1) && (isTwoPageIllustration) && astrikYear.to_i != (87 - issueAge.to_i))
							mileStoneAgeExists = true
						end
						mvelHashMap["maxWithdrawalYear"] = maxWithdrawalYear
						mvelHashMap["issueAge"] = issueAge
						mvelHashMap["isPureMFF"] = isPureMFF
						mvelHashMap["isSinglePageIllustration"] = isSinglePageIllustration
						mvelHashMap["isTwoPageIllustration"] = isTwoPageIllustration
						mvelHashMap["isThreePageIllustration"] = isThreePageIllustration
						mvelHashMap["page1TableYears"] = page1TableYears
						mvelHashMap["page2TableYears"] = page2TableYears
						mvelHashMap["page3TableYears"] = page3TableYears
						mvelHashMap["astrikYear"] = astrikYear
						mvelHashMap["mileStoneAgeExists"] = mileStoneAgeExists
						mvelHashMap["printNotesOnPage1"] =  printNotesOnPage1
						mvelHashMap["printNotesOnPage2"] =  printNotesOnPage2
						mvelHashMap["printNotesOnPage3"] =  printNotesOnPage3

		end
		#changes 11 Nov 2014 End

		def self.updateMaxTableYear(mvelHashMap,elementToUpdate)
			quotationIO = mvelHashMap["quotationIO"]
			rateHigh="";
			rate = "High";
			if elementToUpdate == "deathbenefitwithdrawallow"

				isBreakDone = false;
				rate = "Low";
				if mvelHashMap["maxWithdrawalYear"] != nil

					rateHigh = getRate(mvelHashMap, mvelHashMap["chosenFundCd"])[rate].to_s + mvelHashMap["chosenFundCd"];
				end
				#i =1;
				(1..quotationIO.baseDO.getBasePlan.productTerm.to_i).each do |i|
				# 	puts "#{i.inspect}"
				# end
				# quotationIO.baseDO.getBasePlan.productTerm.to_i.times do |i|
					if (quotationIO.finalMap[i] != nil && quotationIO.finalMap[i][elementToUpdate.to_s] != nil &&
							quotationIO.finalMap[i][elementToUpdate.to_s][rateHigh.to_s] != nil &&
							quotationIO.finalMap[i][elementToUpdate.to_s][rateHigh.to_s] == "0.0")
						mvelHashMap["maxTableYear"] = (i-1);
						isBreakDone=true;
						break;
					end
					i = i +1
				end
				if(!isBreakDone)
					mvelHashMap["maxTableYear"] = quotationIO.baseDO.getBasePlan.productTerm.to_i;
				end
			elsif elementToUpdate == "APOPage"
				apoFundList	= mvelHashMap["apoFundList"]
				mvelHashMap["maxTableYear"] = quotationIO.baseDO.getBasePlan.productTerm.to_i
				mffCounter = 0;
				maxMaturityYear = 0;
				apoFundList.each do |quotationProductFund|
					if quotationProductFund.fundTypeCd == "MyFuture"
						maxMaturityYearValue = DateTime.strptime(quotationProductFund.maturityDt.to_s, "%Y-%m-%d").year - DateTime.strptime(quotationIO.baseDO.issueDt.to_s, "%Y-%m-%d").year;
						maxMaturityYear = maxMaturityYearValue.to_i > maxMaturityYear.to_i ? maxMaturityYearValue.to_i : maxMaturityYear.to_i
						mffCounter = mffCounter + 1
					end
				end
				if mffCounter == apoFundList.size && quotationIO.baseDO.getBaseProduct.product.productFamilyId == "VUL" && apoFundList.size != 0
					mvelHashMap["maxTableYear"]  = maxMaturityYear;
				end
			else
				mvelHashMap["maxTableYear"] = mvelHashMap["maxMaturityYear"].to_i;
			end

		end

		def self.addTimeLineIllustrationGraph(mvelHashMap)
			# pagesectionseq = 205008 in sectiondetails make a new sectiondetails entry
			# in existing display order - 1 and 2 set the mvel condition call this method from the new section





			facetDO = nil
			quotationIO = nil
			if(mvelHashMap["quotationIO"] != nil)
				quotationIO = mvelHashMap["quotationIO"]
				product = quotationIO.baseDO.getBasePlan.getProduct
				if(product != nil)
					facetDO = product.getFacet("TIMELINEILLUSTRATION")
				end
			end
			masterHash = Hash.new
			generatedImageName = ""
			baseImage = ""
			issueAge = quotationIO.baseDO.getPartyByRole("PRIMARY").age.to_i
			masterHash["issueAge"] = issueAge;
			# facetDO = OfflineFacet.new(:actionValue => product.productId) if facetDO == nil
			if(facetDO != nil)
				if(facetDO.actionValue != nil)
					age =  quotationIO.baseDO.getPartyByRole("PRIMARY").age.to_i
					listOfAge = nil
					startingAgeList = (0..10).map{|i| (age + i) }

					if(mvelHashMap["PureMFFAgeList"]== nil)
						listOfAge = []
					else
						listOfAge = mvelHashMap["PureMFFAgeList"]
						listOfAge.push((mvelHashMap["maxMaturityYear"].to_i+age).to_s)
					end
					mvelHashMap["startingAgeList"] = startingAgeList

					if(facetDO.actionValue == "FLRP0B") # Sun FlexiLink
						if (age <=45)
							if(listOfAge == [])
								listOfAge.push("50")
								listOfAge.push("55")
								listOfAge.push("60")
								listOfAge.push("65")
								listOfAge.push("88")
							end
							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunFlexiLink_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunFlexiLinkImage1.generateGraph(mvelHashMap)
							end

						elsif(age <= 60)
							if(listOfAge == [])
								listOfAge.push("65")
								listOfAge.push("70")
								listOfAge.push("75")
								listOfAge.push("80")
								listOfAge.push("88")
							end
							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunFlexiLink_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunFlexiLinkImage1.generateGraph(mvelHashMap)
							end

						elsif(age <= 65)
							if(listOfAge == [])
								listOfAge.push("70")
								listOfAge.push("75")
								listOfAge.push("80")
								listOfAge.push("85")
								listOfAge.push("88")
							end
							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunFlexiLink_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunFlexiLinkImage1.generateGraph(mvelHashMap)
							end
						elsif(age <= 70)
							if(listOfAge == [])
								listOfAge.push("70")
								listOfAge.push("75")
								listOfAge.push("80")
								listOfAge.push("88")
							else
								listOfAge.delete_at(0)
							end
							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunFlexiLink_image2"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunFlexiLinkImage2.generateGraph(mvelHashMap)
							end
						end
					elsif(facetDO.actionValue == "ML1P0A") # Sun MaxiLink One

						if (age <=45)

							listOfAge.push("50")
							listOfAge.push("55")
							listOfAge.push("60")
							listOfAge.push("65")
							listOfAge.push("88")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunMaxiLinkOne_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunMaxiLinkOneImage1.generateGraph(mvelHashMap)
							end
						elsif(age <= 60)

							listOfAge.push("65")
							listOfAge.push("70")
							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("88")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunMaxiLinkOne_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunMaxiLinkOneImage1.generateGraph(mvelHashMap)
							end

						elsif(age <= 65)

							listOfAge.push("70")
							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("85")
							listOfAge.push("88")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunMaxiLinkOne_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunMaxiLinkOneImage1.generateGraph(mvelHashMap)
							end

						elsif(age <= 70)

							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("85")
							listOfAge.push("88")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunMaxiLinkOne_image2"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunMaxiLinkOneImage2.generateGraph(mvelHashMap)
							end

						end
					elsif(facetDO.actionValue == "MD1U0A") # Sun MaxiLink Dollar One

						if (age <=45)

							listOfAge.push("50")
							listOfAge.push("55")
							listOfAge.push("60")
							listOfAge.push("65")
							listOfAge.push("88")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunMaxiLinkDollarOne_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunMaxiLinkDollarOneImage1.generateGraph(mvelHashMap)
							end

						elsif(age <= 60)

							listOfAge.push("65")
							listOfAge.push("70")
							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("88")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunMaxiLinkDollarOne_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunMaxiLinkDollarOneImage1.generateGraph(mvelHashMap)
							end


						elsif(age <= 65)

							listOfAge.push("70")
							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("85")
							listOfAge.push("88")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunMaxiLinkDollarOne_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunMaxiLinkDollarOneImage1.generateGraph(mvelHashMap)
							end

						elsif(age <= 70)

							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("85")
							listOfAge.push("88")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunMaxiLinkDollarOne_image2"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunMaxiLinkDollarOneImage2.generateGraph(mvelHashMap)
							end

						end
					elsif(facetDO.actionValue == "FLXP0A") # Sun MaxiLink Prime
						if (age <=45)
							if(listOfAge == [])
								listOfAge.push("50")
								listOfAge.push("55")
								listOfAge.push("60")
								listOfAge.push("65")
								listOfAge.push("88")
							end
							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunMaxiLinkPrime"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunMaxiLinkPrime.generateGraph(mvelHashMap)
							end

						elsif(age <= 60)
							if(listOfAge == [])
								listOfAge.push("65")
								listOfAge.push("70")
								listOfAge.push("75")
								listOfAge.push("80")
								listOfAge.push("88")
							end
							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunMaxiLinkPrime"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunMaxiLinkPrime.generateGraph(mvelHashMap)
							end


						elsif(age <= 65)
							if(listOfAge == [])
								listOfAge.push("70")
								listOfAge.push("75")
								listOfAge.push("80")
								listOfAge.push("85")
								listOfAge.push("88")
							end
							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunMaxiLinkPrime"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunMaxiLinkPrime.generateGraph(mvelHashMap)
							end

						end
					elsif(facetDO.actionValue == "FD1U0A") # Sun FlexiDollar1

						if (age <=45)

							listOfAge.push("50")
							listOfAge.push("55")
							listOfAge.push("60")
							listOfAge.push("65")
							listOfAge.push("88")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunFlexiDollar1_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunFlexiDollar1Image1.generateGraph(mvelHashMap)
							end

						elsif(age <= 60)

							listOfAge.push("65")
							listOfAge.push("70")
							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("88")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunFlexiDollar1_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunFlexiDollar1Image1.generateGraph(mvelHashMap)
							end


						elsif(age <= 65)

							listOfAge.push("70")
							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("85")
							listOfAge.push("88")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunFlexiDollar1_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunFlexiDollar1Image1.generateGraph(mvelHashMap)
							end

						elsif(age <= 70)

							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("85")
							listOfAge.push("88")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunFlexiDollar1_image2"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunFlexiDollar1Image2.generateGraph(mvelHashMap)
							end

						end
					elsif(facetDO.actionValue == "FDRU0B") # Sun FlexiDollar

						if (age <=45)

							listOfAge.push("50")
							listOfAge.push("55")
							listOfAge.push("60")
							listOfAge.push("65")
							listOfAge.push("88")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunFlexiDollar_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunFlexiDollarImage1.generateGraph(mvelHashMap)
							end

						elsif(age <= 60)

							listOfAge.push("65")
							listOfAge.push("70")
							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("88")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunFlexiDollar_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunFlexiDollarImage1.generateGraph(mvelHashMap)
							end


						elsif(age <= 65)

							listOfAge.push("70")
							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("85")
							listOfAge.push("88")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunFlexiDollar_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunFlexiDollarImage1.generateGraph(mvelHashMap)
							end

						elsif(age <= 70)

							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("85")
							listOfAge.push("88")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunFlexiDollar_image2"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunFlexiDollarImage2.generateGraph(mvelHashMap)
							end

						end
					elsif(facetDO.actionValue == "FL1P0A") # Sun FlexiLinkOne

						if (age <=45)
							if(listOfAge == [])
								listOfAge.push("50")
								listOfAge.push("55")
								listOfAge.push("60")
								listOfAge.push("65")
								listOfAge.push("88")
							end
							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunFlexiLinkOne_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunFlexiLinkOneImage1.generateGraph(mvelHashMap)
							end

						elsif(age <= 60)
							if(listOfAge == [])
								listOfAge.push("65")
								listOfAge.push("70")
								listOfAge.push("75")
								listOfAge.push("80")
								listOfAge.push("88")
							end
							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunFlexiLinkOne_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunFlexiLinkOneImage1.generateGraph(mvelHashMap)
							end


						elsif(age <= 65)
							if(listOfAge == [])
								listOfAge.push("70")
								listOfAge.push("75")
								listOfAge.push("80")
								listOfAge.push("85")
								listOfAge.push("88")
							end
							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunFlexiLinkOne_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunFlexiLinkOneImage1.generateGraph(mvelHashMap)
							end

						elsif(age <= 70)
							if(listOfAge == [])
								listOfAge.push("75")
								listOfAge.push("80")
								listOfAge.push("85")
								listOfAge.push("88")
							else
								listOfAge.delete_at(0)
							end
							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunFlexiLinkOne_image2"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunFlexiLinkOneImage2.generateGraph(mvelHashMap)
							end

						end
					elsif(facetDO.actionValue == "FLVP0A") # Sun MaxiLink Bright

						if (age <=45)
							if(listOfAge == [])
								listOfAge.push("50")
								listOfAge.push("55")
								listOfAge.push("60")
								listOfAge.push("65")
								listOfAge.push("88")
							end
							mvelHashMap["ageList"] = listOfAge

							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunMaxiLinkBright_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunMaxiLinkBrightImage1.generateGraph(mvelHashMap)
							end
						elsif(age <= 60)
							if(listOfAge == [])
								listOfAge.push("65")
								listOfAge.push("70")
								listOfAge.push("75")
								listOfAge.push("80")
								listOfAge.push("88")
							end
							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunMaxiLinkBright_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunMaxiLinkBrightImage1.generateGraph(mvelHashMap)
							end

						end
					elsif(facetDO.actionValue == "WLVP0A") # SUN Smarter Life Classic Peso 5

						if (age <=45)

							listOfAge.push("50")
							listOfAge.push("55")
							listOfAge.push("60")
							listOfAge.push("65")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunSmarterLifeClassicPeso5_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunSmarterLifeClassicPeso5Image1.generateGraph(mvelHashMap)
							end

						elsif(age <= 60)

							listOfAge.push("65")
							listOfAge.push("70")
							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunSmarterLifeClassicPeso5_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunSmarterLifeClassicPeso5Image1.generateGraph(mvelHashMap)
							end


						elsif(age <= 65)

							listOfAge.push("70")
							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("85")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunSmarterLifeClassicPeso5_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunSmarterLifeClassicPeso5Image1.generateGraph(mvelHashMap)
							end

						elsif(age <= 70)

							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("85")
							listOfAge.push("90")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunSmarterLifeClassicPeso5_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunSmarterLifeClassicPeso5Image1.generateGraph(mvelHashMap)
							end

						elsif(age <= 80)

							listOfAge.push("85")
							listOfAge.push("90")
							listOfAge.push("95")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunSmarterLifeClassicPeso5_image2"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunSmarterLifeClassicPeso5Image2.generateGraph(mvelHashMap)
							end

						end
					elsif(facetDO.actionValue == "WLXP0A") # SUN Smarter Life Classic Peso 10

						if (age <=45)

							listOfAge.push("50")
							listOfAge.push("55")
							listOfAge.push("60")
							listOfAge.push("65")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunSmarterLifeClassicPeso10_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunSmarterLifeClassicPeso10Image1.generateGraph(mvelHashMap)
							end

						elsif(age <= 60)

							listOfAge.push("65")
							listOfAge.push("70")
							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunSmarterLifeClassicPeso10_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunSmarterLifeClassicPeso10Image1.generateGraph(mvelHashMap)
							end


						elsif(age <= 65)

							listOfAge.push("70")
							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("85")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunSmarterLifeClassicPeso10_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunSmarterLifeClassicPeso10Image1.generateGraph(mvelHashMap)
							end

						elsif(age <= 70)

							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("85")
							listOfAge.push("90")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunSmarterLifeClassicPeso10_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunSmarterLifeClassicPeso10Image1.generateGraph(mvelHashMap)
							end

						elsif(age <= 80)

							listOfAge.push("85")
							listOfAge.push("90")
							listOfAge.push("95")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunSmarterLifeClassicPeso10_image2"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunSmarterLifeClassicPeso10Image2.generateGraph(mvelHashMap)
							end

						end
					elsif(facetDO.actionValue == "WLRP0A") # SUN Smarter Life Classic Peso Regular Pay

						if (age <=45)

							listOfAge.push("50")
							listOfAge.push("55")
							listOfAge.push("60")
							listOfAge.push("65")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunSmarterLifeClassicPesoRegularPay_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunSmarterLifeClassicPesoRegularPayImage1.generateGraph(mvelHashMap)
							end

						elsif(age <= 60)

							listOfAge.push("65")
							listOfAge.push("70")
							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunSmarterLifeClassicPesoRegularPay_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunSmarterLifeClassicPesoRegularPayImage1.generateGraph(mvelHashMap)
							end


						elsif(age <= 65)

							listOfAge.push("70")
							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("85")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunSmarterLifeClassicPesoRegularPay_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunSmarterLifeClassicPesoRegularPayImage1.generateGraph(mvelHashMap)
							end

						elsif(age <= 70)

							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("85")
							listOfAge.push("90")
							listOfAge.push("100")
							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunSmarterLifeClassicPesoRegularPay_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunSmarterLifeClassicPesoRegularPayImage1.generateGraph(mvelHashMap)
							end

						elsif(age <= 80)

							listOfAge.push("85")
							listOfAge.push("90")
							listOfAge.push("95")
							listOfAge.push("100")
							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunSmarterLifeClassicPesoRegularPay_image2"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunSmarterLifeClassicPesoRegularPayImage2.generateGraph(mvelHashMap)
							end

						end
					elsif(facetDO.actionValue == "WEVP0A") # SUN Smarter Life Elite Peso 5

						if (age <=45)

							listOfAge.push("50")
							listOfAge.push("55")
							listOfAge.push("60")
							listOfAge.push("65")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunSmarterLifeElitePeso5_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunSmarterLifeElitePeso5Image1.generateGraph(mvelHashMap)
							end

						elsif(age <= 60)

							listOfAge.push("65")
							listOfAge.push("70")
							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("100")
							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunSmarterLifeElitePeso5_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunSmarterLifeElitePeso5Image1.generateGraph(mvelHashMap)
							end


						elsif(age <= 70)

							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("85")
							listOfAge.push("90")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunSmarterLifeElitePeso5_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunSmarterLifeElitePeso5Image1.generateGraph(mvelHashMap)
							end

						elsif(age <= 80)

							listOfAge.push("85")
							listOfAge.push("90")
							listOfAge.push("95")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunSmarterLifeElitePeso5_image2"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunSmarterLifeElitePeso5Image2.generateGraph(mvelHashMap)
							end

						end
					elsif(facetDO.actionValue == "WEXP0A") # SUN Smarter Life Elite Peso 10

						if (age <=45)

							listOfAge.push("50")
							listOfAge.push("55")
							listOfAge.push("60")
							listOfAge.push("65")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunSmarterLifeElitePeso10_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunSmarterLifeElitePeso10Image1.generateGraph(mvelHashMap)
							end

						elsif(age <= 60)

							listOfAge.push("65")
							listOfAge.push("70")
							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunSmarterLifeElitePeso10_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunSmarterLifeElitePeso10Image1.generateGraph(mvelHashMap)
							end


						elsif(age <= 65)

							listOfAge.push("70")
							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("85")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunSmarterLifeElitePeso10_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunSmarterLifeElitePeso10Image1.generateGraph(mvelHashMap)
							end

						elsif(age <= 70)

							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("85")
							listOfAge.push("90")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunSmarterLifeElitePeso10_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunSmarterLifeElitePeso10Image1.generateGraph(mvelHashMap)
							end

						elsif(age <= 80)

							listOfAge.push("85")
							listOfAge.push("90")
							listOfAge.push("95")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunSmarterLifeElitePeso10_image2"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunSmarterLifeElitePeso10Image2.generateGraph(mvelHashMap)
							end

						end
					elsif(facetDO.actionValue == "WERP0A") # SUN Smarter Life Elite Peso Regular Pay

						if (age <=45)

							listOfAge.push("50")
							listOfAge.push("55")
							listOfAge.push("60")
							listOfAge.push("65")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunSmarterLifeElitePesoRegularPay_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunSmarterLifeElitePesoRegularPayImage1.generateGraph(mvelHashMap)
							end

						elsif(age <= 60)

							listOfAge.push("65")
							listOfAge.push("70")
							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunSmarterLifeElitePesoRegularPay_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunSmarterLifeElitePesoRegularPayImage1.generateGraph(mvelHashMap)
							end


						elsif(age <= 65)

							listOfAge.push("70")
							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("85")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunSmarterLifeElitePesoRegularPay_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunSmarterLifeElitePesoRegularPayImage1.generateGraph(mvelHashMap)
							end

						elsif(age <= 70)


							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("85")
							listOfAge.push("90")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunSmarterLifeElitePesoRegularPay_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunSmarterLifeElitePesoRegularPayImage1.generateGraph(mvelHashMap)
							end

						elsif(age <= 80)


							listOfAge.push("85")
							listOfAge.push("90")
							listOfAge.push("95")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunSmarterLifeElitePesoRegularPay_image2"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunSmarterLifeElitePesoRegularPayImage2.generateGraph(mvelHashMap)
							end

						end
					elsif(facetDO.actionValue == "FCVP0A") # Sun Grepa ProSecure 5

						if (age <=45)

							listOfAge.push("50")
							listOfAge.push("55")
							listOfAge.push("60")
							listOfAge.push("65")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "ProSecure5_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::ProSecure5Image1.generateGraph(mvelHashMap)
							end

						elsif(age <= 60)

							listOfAge.push("65")
							listOfAge.push("70")
							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "ProSecure5_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::ProSecure5Image1.generateGraph(mvelHashMap)
							end


						elsif(age <= 70)

							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("85")
							listOfAge.push("90")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "ProSecure5_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::ProSecure5Image1.generateGraph(mvelHashMap)
							end

						elsif(age <= 80)

							listOfAge.push("85")
							listOfAge.push("90")
							listOfAge.push("95")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "ProSecure5_image2"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::ProSecure5Image2.generateGraph(mvelHashMap)
							end

						end
					elsif(facetDO.actionValue == "FCXP0A") # Sun Grepa ProSecure 10

						if (age <=45)

							listOfAge.push("50")
							listOfAge.push("55")
							listOfAge.push("60")
							listOfAge.push("65")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "ProSecure10_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::ProSecure10Image1.generateGraph(mvelHashMap)
							end

						elsif(age <= 60)

							listOfAge.push("65")
							listOfAge.push("70")
							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "ProSecure10_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::ProSecure10Image1.generateGraph(mvelHashMap)
							end


						elsif(age <= 70)

							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("85")
							listOfAge.push("90")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "ProSecure10_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::ProSecure10Image1.generateGraph(mvelHashMap)
							end

						elsif(age <= 80)

							listOfAge.push("85")
							listOfAge.push("90")
							listOfAge.push("95")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "ProSecure10_image2"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::ProSecure10Image2.generateGraph(mvelHashMap)
							end

						end
					elsif(facetDO.actionValue == "IBVP0A") # Sun Grepa ProSecure Plus 5

						if (age <=45)

							listOfAge.push("50")
							listOfAge.push("55")
							listOfAge.push("60")
							listOfAge.push("65")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "ProSecurePlus5_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::ProSecurePlus5Image1.generateGraph(mvelHashMap)
							end

						elsif(age <= 60)

							listOfAge.push("65")
							listOfAge.push("70")
							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "ProSecurePlus5_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::ProSecurePlus5Image1.generateGraph(mvelHashMap)
							end


						elsif(age <= 70)

							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("85")
							listOfAge.push("90")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "ProSecurePlus5_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::ProSecurePlus5Image1.generateGraph(mvelHashMap)
							end

						elsif(age <= 80)

							listOfAge.push("85")
							listOfAge.push("90")
							listOfAge.push("95")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "ProSecurePlus5_image2"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::ProSecurePlus5Image2.generateGraph(mvelHashMap)
							end

						end
					elsif(facetDO.actionValue == "IBXP0A") # Sun Grepa ProSecure Plus 10

						if (age <=45)

							listOfAge.push("50")
							listOfAge.push("55")
							listOfAge.push("60")
							listOfAge.push("65")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "ProSecurePlus10_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::ProSecurePlus10Image1.generateGraph(mvelHashMap)
							end

						elsif(age <= 60)

							listOfAge.push("65")
							listOfAge.push("70")
							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "ProSecurePlus10_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::ProSecurePlus10Image1.generateGraph(mvelHashMap)
							end


						elsif(age <= 70)

							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("85")
							listOfAge.push("90")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "ProSecurePlus10_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::ProSecurePlus10Image1.generateGraph(mvelHashMap)
							end

						elsif(age <= 80)

							listOfAge.push("85")
							listOfAge.push("90")
							listOfAge.push("95")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "ProSecurePlus10_image2"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::ProSecurePlus10Image2.generateGraph(mvelHashMap)
							end

						end
					elsif(facetDO.actionValue == "GPPP0A") # Sun Grepa ProSecure Plus Regular Pay

						if (age <=45)

							listOfAge.push("50")
							listOfAge.push("55")
							listOfAge.push("60")
							listOfAge.push("65")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "ProSecurePlusRegPay_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::ProSecurePlusRegPayImage1.generateGraph(mvelHashMap)
							end

						elsif(age <= 60)

							listOfAge.push("65")
							listOfAge.push("70")
							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "ProSecurePlusRegPay_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::ProSecurePlusRegPayImage1.generateGraph(mvelHashMap)
							end


						elsif(age <= 70)

							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("85")
							listOfAge.push("90")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "ProSecurePlusRegPay_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::ProSecurePlusRegPayImage1.generateGraph(mvelHashMap)
							end

						elsif(age <= 80)

							listOfAge.push("85")
							listOfAge.push("90")
							listOfAge.push("95")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "ProSecurePlusRegPay_image2"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::ProSecurePlusRegPayImage2.generateGraph(mvelHashMap)
							end

						end
					elsif(facetDO.actionValue == "GPSP0A") # Sun Grepa ProSecure Regular Pay

						if (age <=45)

							listOfAge.push("50")
							listOfAge.push("55")
							listOfAge.push("60")
							listOfAge.push("65")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "ProSecureRegPay_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::ProSecureRegPayImage1.generateGraph(mvelHashMap)
							end

						elsif(age <= 60)

							listOfAge.push("65")
							listOfAge.push("70")
							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "ProSecureRegPay_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::ProSecureRegPayImage1.generateGraph(mvelHashMap)
							end


						elsif(age <= 70)

							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("85")
							listOfAge.push("90")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "ProSecureRegPay_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::ProSecureRegPayImage1.generateGraph(mvelHashMap)
							end

						elsif(age <= 80)

							listOfAge.push("85")
							listOfAge.push("90")
							listOfAge.push("95")
							listOfAge.push("100")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "ProSecureRegPay_image2"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::ProSecureRegPayImage2.generateGraph(mvelHashMap)
							end

						end
					elsif(facetDO.actionValue == "RFVP0A") # Sun Grepa Power Builder 5

						if (age <=45)

							listOfAge.push("50")
							listOfAge.push("55")
							listOfAge.push("60")
							listOfAge.push("65")
							listOfAge.push("88")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunGrepaPowerBuilder5_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunGrepaPowerBuilder5Image1.generateGraph(mvelHashMap)
							end

						elsif(age <= 60)

							listOfAge.push("65")
							listOfAge.push("70")
							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("88")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunGrepaPowerBuilder5_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunGrepaPowerBuilder5Image1.generateGraph(mvelHashMap)
							end

						end
					elsif(facetDO.actionValue == "RFXP0A") # Sun Grepa Power Builder 10

						if (age <=45)

							listOfAge.push("50")
							listOfAge.push("55")
							listOfAge.push("60")
							listOfAge.push("65")
							listOfAge.push("88")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunGrepaPowerBuilder10_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunGrepaPowerBuilder10Image1.generateGraph(mvelHashMap)
							end

						elsif(age <= 60)

							listOfAge.push("65")
							listOfAge.push("70")
							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("88")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunGrepaPowerBuilder10_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunGrepaPowerBuilder10Image1.generateGraph(mvelHashMap)
							end

						elsif(age <= 65)

							listOfAge.push("70")
							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("85")
							listOfAge.push("88")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunGrepaPowerBuilder10_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunGrepaPowerBuilder10Image1.generateGraph(mvelHashMap)
							end

						end
					elsif(facetDO.actionValue == "RL1P0A") # Sun Grepa Power Builder 1

						if (age <=45)

							listOfAge.push("50")
							listOfAge.push("55")
							listOfAge.push("60")
							listOfAge.push("65")
							listOfAge.push("88")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunGrepaPowerBuilder1_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunGrepaPowerBuilder1Image1.generateGraph(mvelHashMap)
							end

						elsif(age <= 60)

							listOfAge.push("65")
							listOfAge.push("70")
							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("88")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunGrepaPowerBuilder1_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunGrepaPowerBuilder1Image1.generateGraph(mvelHashMap)
							end


						elsif(age <= 65)

							listOfAge.push("70")
							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("85")
							listOfAge.push("88")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunGrepaPowerBuilder1_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunGrepaPowerBuilder1Image1.generateGraph(mvelHashMap)
							end

						elsif(age <= 70)

							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("85")
							listOfAge.push("88")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunGrepaPowerBuilder1_image2"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunGrepaPowerBuilder1Image2.generateGraph(mvelHashMap)
							end

						end
					elsif(facetDO.actionValue == "RD1U0A") # Sun Grepa Power Builder Dollar 1

						if (age <=45)

							listOfAge.push("50")
							listOfAge.push("55")
							listOfAge.push("60")
							listOfAge.push("65")
							listOfAge.push("88")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunGrepaPowerBuilderDollar1_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunGrepaPowerBuilderDollar1Image1.generateGraph(mvelHashMap)
							end

						elsif(age <= 60)

							listOfAge.push("65")
							listOfAge.push("70")
							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("88")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunGrepaPowerBuilderDollar1_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunGrepaPowerBuilderDollar1Image1.generateGraph(mvelHashMap)
							end


						elsif(age <= 65)

							listOfAge.push("70")
							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("85")
							listOfAge.push("88")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunGrepaPowerBuilderDollar1_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunGrepaPowerBuilderDollar1Image1.generateGraph(mvelHashMap)
							end

						elsif(age <= 70)

							listOfAge.push("75")
							listOfAge.push("80")
							listOfAge.push("85")
							listOfAge.push("88")

							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunGrepaPowerBuilderDollar1_image2"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunGrepaPowerBuilderDollar1Image2.generateGraph(mvelHashMap)
							end

						end
					elsif(facetDO.actionValue == "5RCP0A") # Sun Safer Life 5YRCT
						startingAgeList = []
						initialAge = age
						startingAgeList.push(initialAge)
						agePlusFive = initialAge + 5
						for i in 0..8
							initialAge=initialAge+1
							startingAgeList.push(initialAge)
						end
						regularAge = initialAge + 1 ;
						listOfAge.push(agePlusFive.to_s)
						mvelHashMap["startingAgeList"] = startingAgeList
						if (age <= 50)
							listOfAge.push(regularAge.to_s)
							listOfAge.push("55")
							listOfAge.push("60")
							listOfAge.push("65")
							listOfAge.push("70")

							mvelHashMap["startingAgeList"].push("74")
							mvelHashMap["startingAgeList"].push("75")
							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData5YRCT(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunSaferLife5YRCT_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunSaferLife5YRCTImage1.generateGraph(mvelHashMap)
							end

						elsif(age <= 60)
							listOfAge.push(regularAge.to_s)
							listOfAge.push("65")
							listOfAge.push("70")
							listOfAge.push("74")

							mvelHashMap["startingAgeList"].push("75")
							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData5YRCT(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunSaferLife5YRCT_image2"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunSaferLife5YRCTImage2.generateGraph(mvelHashMap)
							end

						elsif(age <= 64)
							listOfAge.push(regularAge.to_s)
							listOfAge.push("70")
							listOfAge.push("74")

							mvelHashMap["startingAgeList"].push("75")
							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData5YRCT(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunSaferLife5YRCT_image3"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::SunSaferLife5YRCTImage3.generateGraph(mvelHashMap)
							end

						end
					elsif(facetDO.actionValue == "GPTP0A") # Sun Grepa Proterm - 5YRCT
						startingAgeList = []
						initialAge = age
						startingAgeList.push(initialAge)
						agePlusFive = initialAge + 5
						for i in 0..8
							initialAge=initialAge+1
							startingAgeList.push(initialAge)
						end
						regularAge = initialAge + 1 ;
						listOfAge.push(agePlusFive.to_s)
						mvelHashMap["startingAgeList"] = startingAgeList
						if (age <= 50)

							listOfAge.push(regularAge.to_s)
							listOfAge.push("55")
							listOfAge.push("60")
							listOfAge.push("65")
							listOfAge.push("70")

							mvelHashMap["startingAgeList"].push("74")
							mvelHashMap["startingAgeList"].push("75")
							mvelHashMap["ageList"] = listOfAge

							if $showPdf == true
								data = extractData5YRCT(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "Proterm5YRCT_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::Proterm5YRCTImage1.generateGraph(mvelHashMap)
							end

						elsif(age <= 60)

							listOfAge.push(regularAge.to_s)
							listOfAge.push("65")
							listOfAge.push("70")
							listOfAge.push("74")

							mvelHashMap["startingAgeList"].push("75")
							mvelHashMap["ageList"] = listOfAge

							if $showPdf == true
								data = extractData5YRCT(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "Proterm5YRCT_image2"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::Proterm5YRCTImage2.generateGraph(mvelHashMap)
							end

						elsif(age <= 64)

							listOfAge.push(regularAge.to_s)
							listOfAge.push("70")
							listOfAge.push("74")

							mvelHashMap["startingAgeList"].push("75")
							mvelHashMap["ageList"] = listOfAge
							if $showPdf == true
								data = extractData5YRCT(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "Proterm5YRCT_image3"
								jsonStr = ::JSON.generate(masterHash)
							else
								generatedImageName = MobiSys::Proterm5YRCTImage3.generateGraph(mvelHashMap)
							end

						end
					elsif(facetDO.actionValue == "EV8P0A") # Sun Grepa Elev8
						if $showPdf == true
								data = extractDataAcceler8(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunGrepaElev8_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
							generatedImageName = MobiSys::SunGrepaElev8Image1.generateGraph(mvelHashMap)
						end
					elsif(facetDO.actionValue == "SA8P0A") # Sun Acceler8
						if $showPdf == true
								data = extractDataAcceler8(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunAcceler8_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
							generatedImageName = MobiSys::SunAcceler8Image1.generateGraph(mvelHashMap)
						end
					elsif(facetDO.actionValue == "TBD") # Sun Grepa Elev8
						if $showPdf == true
								listOfAge = [4,5,6]
								data = extractDataSDM(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "SunDollarMaximizer_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
							generatedImageName = MobiSys::SunDollarMaximizerImage1.generateGraph(mvelHashMap)
						end
					elsif(facetDO.actionValue == "TBDGrepa") # Sun Grepa Elev8
						if $showPdf == true
								listOfAge = [4,5,6]
								data = extractDataSDM(mvelHashMap, quotationIO, issueAge, listOfAge)
								masterHash["listOfAge"] = listOfAge
								masterHash["data"] = data
								masterHash["classToCall"] = "GlobalAssetBuilder_image1"
								jsonStr = ::JSON.generate(masterHash)
							else
							generatedImageName = MobiSys::GlobalAssetBuilderImage1.generateGraph(mvelHashMap)
						end
					end

				end
			end
			if $showPdf == true
				imageName = quotationIO.baseDO.quotationRefNum + Random.rand(100000).to_s + ".png"
				fileName = Rho::RhoApplication.get_blob_folder + File::SEPARATOR + imageName
				baseImagePath = "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}images#{File::SEPARATOR}outputimages"
				cmdStr = "javaw -classpath #{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}pdf.jar;"
				cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}flexjson-2.1.jar;"
				cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}jcommon-1.0.21.jar;"
				cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}jfreechart-1.0.17.jar;"
				cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}jfreechart-1.0.17-experimental.jar;"
				cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}jfreechart-1.0.17-swt.jar;"
				cmdStr << " com.c2lbiz.mobisys.win32.TimeLineIllustrationWrapper "
				cmdStr << jsonStr.gsub('"','\"').gsub(' ','$SPACE$')
				cmdStr << " #{fileName}"
				  cmdStr << " #{baseImagePath}#{File::SEPARATOR}"
				#puts "cmdStr: #{cmdStr}"

				answer = system(cmdStr)

				#puts ">>>answer: #{answer} errorStatus: #{$?}"

				return "<img src=\"#{imageName}\" width=\"100%\"/>"
			else
				return generatedImageName
			end
			return generatedImageName
		end

		def self.extractData(mvelHashMap, quotationIO, issueAge, listOfAge)
			data = {}
			totalFV = deathBenefit = totalFVElement = deathBenefitElement = totalFVRate = deathBenefitRate = nil
			totalFVList = []
			deathBenefitList = []
			ageList = []
			elementRate = getElementsAndRate(mvelHashMap, quotationIO)
			deathBenefitElement = (elementRate[0] != nil ? elementRate[0] : "")
			totalFVElement = (elementRate[1] != nil ? elementRate[1] : "")
			deathBenefitRate = (elementRate[2] != nil ? elementRate[2] : "0")
			totalFVRate = (elementRate[3] != nil ? elementRate[3] : "0")
			totalPremium = 0.0
			totalPremiumList = []

			currencyCd = "Ps."
			currency = "PHP"
			partialTotalPremium = paymentModePremium = 0.0
			ppt = 0

			if(quotationIO != nil)
				if(quotationIO.baseDO != nil)
					if(quotationIO.baseDO.getBasePlan != nil)
						if(quotationIO.baseDO.getBasePlan.currencyCd != nil)
							currency = quotationIO.baseDO.getBasePlan.currencyCd
							if(currency == "PHP")
								currencyCd = "Ps. "
							elsif(currency == "USD")
								currencyCd = "US $"
							end
						end
						if(quotationIO.baseDO.getBasePlan.premiumPayingTerm != nil)
							ppt = quotationIO.baseDO.getBasePlan.premiumPayingTerm
						end
					end
				end
			end

			if(listOfAge != nil)
				listOfAge.each do |age|
					curAge = age
					ageList.push(age)
					age = (age.to_i - issueAge).to_s
					if(quotationIO.finalMap != nil)
						if(quotationIO.finalMap[age.to_i] != nil)
							if(quotationIO.finalMap[age.to_i][deathBenefitElement] != nil)
								deathBenefit = quotationIO.finalMap[age.to_i][deathBenefitElement][deathBenefitRate]
								if(deathBenefit != nil)
									if(deathBenefit== "0.0")
										deathBenefitList.push("0")
									else
										deathBenefitList.push(MobiSys::UIGenUtilCompanyHelper.roundingTableData(deathBenefit))
									end
								else
									deathBenefitList.push("0")
								end
							end
							if(quotationIO.finalMap[age.to_i][totalFVElement] != nil)
								totalFV = quotationIO.finalMap[age.to_i][totalFVElement][totalFVRate]
								if(totalFV != nil)
									if(totalFV == "0.0")
										totalFVList.push("0")
									else
										if(curAge.to_s == "88" || curAge.to_s == "100")
											totalFVList.push(currencyCd + MobiSys::UIGenUtilCompanyHelper.roundingTableData(totalFV))
										else
											totalFVList.push(MobiSys::UIGenUtilCompanyHelper.roundingTableData(totalFV))
										end
									end
								else
									totalFVList.push("0")
								end
							end
						else
							deathBenefitList.push("0")
							totalFVList.push("0")
						end
					end
				end

				lst = quotationIO.baseDO.QuotationProductList
				paymentMode = ""
				paymentMode = MobiSys::UIGenUtilHelper.getLookupValue("FREQUENCY", quotationIO.baseDO.getBasePlan.paymentFrequencyCd)
				premium = 0.0
				if(lst != nil)
					if(lst[0] != nil)
						premium = lst[0].modalPremium
					end
				end

				productDO = facetDO = nil
				if(mvelHashMap["quotationIO"] != nil)
					quotationIO = mvelHashMap["quotationIO"]
					productDO = quotationIO.baseDO.getBasePlan.getProduct
					if(productDO != nil)
						facetDO = productDO.getFacet("TIMELINEILLUSTRATION")
					end
				end

				# facetDO = OfflineFacet.new(:actionValue => productDO.productId) if facetDO == nil
				totalPremium = mvelHashMap["totalPremiumTitlePage"].to_s.to_f
				if(productDO != nil)
					if(productDO.productFamilyId == "TRAD")
						if(paymentMode == "Quarterly")
							paymentModePremium = totalPremium * 0.275
						elsif(paymentMode == "Semi-annual")
							paymentModePremium = totalPremium * 0.53
							paymentMode = "Semi-Annual"
						else
							paymentModePremium = totalPremium
						end
					elsif(productDO.productFamilyId == "VUL")
						if(paymentMode == "Quarterly")
							partialTotalPremium = (totalPremium / 4)
						elsif(paymentMode == "Semi-annual")
							paymentMode = "Semi-Annual"
							partialTotalPremium = (totalPremium / 2)
						else
							partialTotalPremium = totalPremium
						end
					end
				end

				isRiderSelect = ""

				if(quotationIO.baseDO.getRiders.size != 0)
					isRiderSelect = "[inclusive of riders]"
				end

				if facetDO != nil
					if(facetDO.actionValue == "FDRU0B" || facetDO.actionValue == "FLRP0B")
						# Sun FlexiDollar, Sun FlexiLink
						label1 = paymentMode + " premium of " + currencyCd
						label2 = " payable until age 87 #{isRiderSelect}"
						totalPremiumList.push(label1 + MobiSys::UIGenUtilCompanyHelper.roundingTableData(partialTotalPremium.to_f) + label2)

					elsif(facetDO.actionValue == "WLRP0A" || facetDO.actionValue == "WERP0A" || facetDO.actionValue == "GPPP0A" || facetDO.actionValue == "GPSP0A")
						# SUN Smarter Life Classic Peso Regular Pay, SUN Smarter Life Elite Peso Regular Pay,
						#Sun Grepa ProSecure Plus Regular Pay, Sun Grepa ProSecure Regular Pay

						String label1 = paymentMode + " premium of " + currencyCd
						String label2 = " payable until age 99 #{isRiderSelect}"
						totalPremiumList.push(label1 + MobiSys::UIGenUtilCompanyHelper.roundingTableData(paymentModePremium.to_f) + label2)

					elsif(facetDO.actionValue == "FLVP0A" || facetDO.actionValue == "RFVP0A" || facetDO.actionValue == "RFXP0A")
						# Sun MaxiLink Bright, Sun Grepa Power Builder 5, Sun Grepa Power Builder 10

						totalPremiumList.push(currencyCd +MobiSys::UIGenUtilCompanyHelper.roundingTableData(partialTotalPremium.to_f))
						totalPremiumList.push(paymentMode + " premium")
						totalPremiumList.push( "payable in #{ppt.to_s} years" )
						totalPremiumList.push("#{isRiderSelect}")

					elsif(facetDO.actionValue == "WLVP0A" || facetDO.actionValue == "FCVP0A")
						#  SUN Smarter Life Classic Peso 5 , Sun Grepa ProSecure 5

						totalPremiumList.push(currencyCd +MobiSys::UIGenUtilCompanyHelper.roundingTableData(paymentModePremium.to_f))
						totalPremiumList.push(paymentMode + " premium payable")
						totalPremiumList.push("in 5 years #{isRiderSelect}")

					elsif(facetDO.actionValue == "WLXP0A" || facetDO.actionValue == "WEXP0A" || facetDO.actionValue == "FCXP0A" || facetDO.actionValue == "IBXP0A")
						# SUN Smarter Life Classic Peso 10, SUN Smarter Life Elite Peso 10, Sun Grepa ProSecure 10
						# Sun Grepa ProSecure Plus 10

						totalPremiumList.push(currencyCd +MobiSys::UIGenUtilCompanyHelper.roundingTableData(paymentModePremium.to_f))
						totalPremiumList.push(paymentMode + " premium payable in")
						totalPremiumList.push("10 years #{isRiderSelect}")

					elsif(facetDO.actionValue == "IBVP0A" || facetDO.actionValue == "WEVP0A")
						#  Sun Grepa ProSecure Plus 5, SUN Smarter Life Elite Peso 5

						totalPremiumList.push(currencyCd +MobiSys::UIGenUtilCompanyHelper.roundingTableData(paymentModePremium.to_f))
						totalPremiumList.push(paymentMode + " premium")
						totalPremiumList.push("payable in 5 years")
						totalPremiumList.push("#{isRiderSelect}")

					elsif(facetDO.actionValue == "FLXP0A")
						# Sun MaxiLink Prime
						totalPremiumList.push(currencyCd +MobiSys::UIGenUtilCompanyHelper.roundingTableData(partialTotalPremium.to_f))
						totalPremiumList.push(paymentMode + " premium payable" )
						totalPremiumList.push("in #{ppt} years #{isRiderSelect}")

					elsif(facetDO.actionValue == "MD1U0A" || facetDO.actionValue == "FD1U0A" || facetDO.actionValue == "FL1P0A" || facetDO.actionValue == "ML1P0A" || facetDO.actionValue == "RL1P0A" || facetDO.actionValue == "RD1U0A")
						# Sun MaxiLink Dollar One, Sun FlexiDollar1,
						# Sun FlexiLinkOne, Sun MaxiLink One
						# Sun Grepa Power Builder 1, Sun Grepa Power Builder Dollar 1

						totalPremiumList.push(currencyCd +MobiSys::UIGenUtilCompanyHelper.roundingTableData(partialTotalPremium.to_f))
						totalPremiumList.push("#{isRiderSelect}")
					else
						totalPremiumList.push(currencyCd +MobiSys::UIGenUtilCompanyHelper.roundingTableData(premium.to_s))
					end
				end
			end

			if(totalPremiumList.size > 0)
				data["totalPremiumList"] = totalPremiumList
			end
			data["ageList"] = ageList
			data["deathBenefitList"] = deathBenefitList
			data["totalFVList"] = totalFVList
			data["startingAgeList"] = mvelHashMap["startingAgeList"]

			return data
		end

		def self.getElementsAndRate(mvelHashMap, quotationIO)
			elementRate = []
			productDO = quotationIO.baseDO.getBasePlan.getProduct
			premiumFacetDO =  productDO.getFacet("PREMIUMDETAILS")
			premiumDetailsDO = nil
			if(premiumFacetDO != nil)
				premiumDetailsDO = premiumFacetDO.getPremiumDetails
			end
			if(productDO.productFamilyId == "VUL")
				elementRate[0] = "deathbenefit"
				elementRate[1] = "totalfv"
				elementRate[2] = MobiSys::UIGenUtilCompanyHelper.getRate(mvelHashMap, mvelHashMap["chosenFundCd"].to_s)["Medium"] + mvelHashMap["chosenFundCd"].to_s
				elementRate[3] = mvelHashMap["avgMEDIUM"]
			else
				elementRate[2] = "0"
				elementRate[3] = "0"
				if(quotationIO.baseDO.getBasePlan.addtnField6.to_s != "")
					if(quotationIO.baseDO.getBasePlan.addtnField6 == "Both" || quotationIO.baseDO.getBasePlan.addtnField6 == "AEB")
						if(quotationIO.baseDO.getBasePlan.addtnField4 == "PUA")
							if(premiumDetailsDO != nil && premiumDetailsDO.premiumTypeCd == "REGULAR")
								elementRate[1] = "sobaebpuacurrenttlb"
								elementRate[0] = "sobaebpuacurrenttdb"
							else
								elementRate[1] = "sobaebpuacurrenttlb"
								elementRate[0] = "sobaebpuacurrenttdb"
							end
						else
							if(premiumDetailsDO != nil && premiumDetailsDO.premiumTypeCd == "REGULAR")
								elementRate[1] = "sobaebcurrenttlb"
								elementRate[0] = "sobaebcurrenttdb"
							else
								elementRate[1] = "sobaebcurrenttlb"
								elementRate[0] = "sobaebcurrenttdb"
							end
						end
					else
						if(quotationIO.baseDO.getBasePlan.addtnField4 == "PUA")
							if(premiumDetailsDO != nil && premiumDetailsDO.premiumTypeCd == "REGULAR")
								elementRate[1] = "sobebppuatlb"
								elementRate[0] = "sobebppuatdb"
							else
								elementRate[1] = "sobebppuatlb"
								elementRate[0] = "sobebppuatdb"
							end
						else
							if(premiumDetailsDO != nil && premiumDetailsDO.premiumTypeCd == "REGULAR")
								elementRate[1] = "sobebpdaprtotallivingbenefit"
								elementRate[0] = "sobebpdaprtotaldeathbenefit"
							else
								elementRate[1] = "sobebpdaprtotallivingbenefit"
								elementRate[0] = "sobebpdaprtotaldeathbenefit"
							end
						end
					end
				else
					if(quotationIO.baseDO.getBasePlan.addtnField4 == "PUA")
						if(premiumDetailsDO != nil && premiumDetailsDO.premiumTypeCd == "REGULAR")
							elementRate[1] = "sobebppuatlb"
							elementRate[0] = "sobebppuatdb"
						else
							elementRate[1] = "sobebppuatlb"
							elementRate[0] = "sobebppuatdb"
						end
					else
						if(premiumDetailsDO != nil && premiumDetailsDO.premiumTypeCd == "REGULAR")
							elementRate[1] = "sobebpdaprtotallivingbenefit"
							elementRate[0] = "sobebpdaprtotaldeathbenefit"
						else
							elementRate[1] = "sobebpdaprtotallivingbenefit"
							elementRate[0] = "sobebpdaprtotaldeathbenefit"
						end
					end
				end
			end
			return elementRate
		end

		def self.extractDataAcceler8(mvelHashMap, quotationIO, issueAge, listOfAge)
			data = {}
			deathBenefit = livingBenefit = deathBenefitElement = livingBenefitElement = nil
			deathBenefitEvenList = []
			deathBenefitOddList = []
			elementRate = getElementsAndRateAcceler8(mvelHashMap, quotationIO)
			deathBenefitElement = (elementRate[0] != nil ? elementRate[0] : "")
			livingBenefitElement = (elementRate[1] != nil ? elementRate[1] : "")
			currencyCd = "Ps. "
			currency = "PHP"
			ppt = 0
			productDO = facetDO = nil
			paymentMode = ""
			paymentMode = MobiSys::UIGenUtilHelper.getLookupValue("FREQUENCY", quotationIO.baseDO.getBasePlan.paymentFrequencyCd)
			partialTotalPremium = paymentModePremium = totalPremium = 0.0
			totalPremiumList = []

			if(quotationIO != nil)
				if(quotationIO.baseDO != nil)
					if(quotationIO.baseDO.getBasePlan != nil)
						productDO = quotationIO.baseDO.getBasePlan.getProductDO
						if(quotationIO.baseDO.getBasePlan.currencyCd != nil)
							currency = quotationIO.baseDO.getBasePlan.currencyCd
							if(currency == "PHP")
								currencyCd = "Ps. "
							elsif(currency == "USD")
								currencyCd = "US $"
							end
						end
						if(quotationIO.baseDO.getBasePlan.premiumPayingTerm != nil)
							ppt = quotationIO.baseDO.getBasePlan.premiumPayingTerm
						end
					end
				end
			end

			(1...8).step(2) do |age|
				if(quotationIO.finalMap != nil && quotationIO.finalMap[age.to_i] != nil && quotationIO.finalMap[age.to_i][deathBenefitElement] != nil)
					deathBenefit = quotationIO.finalMap[age.to_i][deathBenefitElement]["0"]
					if(deathBenefit != nil)
						if(deathBenefit == "0.0")
							deathBenefitOddList.push("0")
						else
							deathBenefitOddList.push(" " + MobiSys::UIGenUtilCompanyHelper.roundingTableData(deathBenefit))
						end
					else
						deathBenefitOddList.push("0")
					end
				end
			end
			if(quotationIO.finalMap[20] != nil && quotationIO.finalMap[20][deathBenefitElement] != nil)
				deathBenefitOddList.push(currencyCd + MobiSys::UIGenUtilCompanyHelper.roundingTableData(quotationIO.finalMap[20][deathBenefitElement]["0"]))
			end
			(2..8).step(2) do |age|
				if(quotationIO.finalMap != nil && quotationIO.finalMap[age.to_i] != nil && quotationIO.finalMap[age.to_i][deathBenefitElement] != nil)
					deathBenefit = quotationIO.finalMap[age.to_i][deathBenefitElement]["0"]
					if(deathBenefit != nil)
						if(deathBenefit == "0.0")
							deathBenefitEvenList.push("0")
						else
							deathBenefitEvenList.push(" " + MobiSys::UIGenUtilCompanyHelper.roundingTableData(deathBenefit))
						end
					else
						deathBenefitEvenList.push("0")
					end
				end
			end

			(8..20).step(2) do |age|
				if(quotationIO.finalMap != nil && quotationIO.finalMap[age.to_i] != nil && quotationIO.finalMap[age.to_i][livingBenefitElement] != nil)
					livingBenefit = quotationIO.finalMap[age.to_i][livingBenefitElement]["0"]
					if(livingBenefit != nil)
						if(livingBenefit == "0.0")
							deathBenefitEvenList.push("0")
						else
							deathBenefitEvenList.push(" " + MobiSys::UIGenUtilCompanyHelper.roundingTableData(livingBenefit))
						end
					else
						deathBenefitEvenList.push("0")
					end
				end
			end

			if(quotationIO.finalMap[20] != nil && quotationIO.finalMap[20][livingBenefitElement] != nil)
				deathBenefitEvenList.push(currencyCd + MobiSys::UIGenUtilCompanyHelper.roundingTableData(quotationIO.finalMap[20][livingBenefitElement]["0"]))
			end

			if(mvelHashMap["quotationIO"] != nil)
				quotationIO = mvelHashMap["quotationIO"]
				productDO = quotationIO.baseDO.getBasePlan.getProduct
				if(productDO != nil)
					facetDO = productDO.getFacet("TIMELINEILLUSTRATION")
				end
			end

			totalPremium = mvelHashMap["totalPremiumTitlePage"].to_s.to_f
			if(productDO != nil)
				if(productDO.productFamilyId == "TRAD")
					if(paymentMode == "Quarterly")
						paymentModePremium = totalPremium * 0.275
					elsif(paymentMode == "Semi-annual")
						paymentModePremium = totalPremium * 0.53
						paymentMode = "Semi-Annual"
					else
						paymentModePremium = totalPremium
					end
				elsif(productDO.productFamilyId == "VUL")
					if(paymentMode == "Quarterly")
						partialTotalPremium = (totalPremium / 4)
					elsif(paymentMode == "Semi-annual")
						paymentMode = "Half Yearly"
						partialTotalPremium = (totalPremium / 2)
					else
						partialTotalPremium = totalPremium
					end
				end
			end

			isRiderSelect = ""

				if(quotationIO.baseDO.getRiders.size != 0)
					isRiderSelect = "[inclusive of riders]"
				end


			if(facetDO != nil)
				if(facetDO.actionValue == "EV8P0A")
					#Sun Grepa Elev8

					if(paymentModePremium.to_s == "0.0")
						totalPremiumList.push(currencyCd + "0.0")
					else
						totalPremiumList.push(currencyCd + MobiSys::UIGenUtilCompanyHelper.roundingTableData(paymentModePremium.to_f))
					end
				elsif(facetDO.actionValue == "SA8P0A")
					#Sun Acceler8

					if(paymentModePremium.to_s == "0.0")
						totalPremiumList.push(currencyCd + "0.0")
					else
						totalPremiumList.push(currencyCd + MobiSys::UIGenUtilCompanyHelper.roundingTableData(paymentModePremium.to_f))
					end
				end
				totalPremiumList.push(paymentMode + " premium payable" + " in ")
				totalPremiumList.push("#{ppt} years #{isRiderSelect}")
			end

			data["deathBenefitEvenList"] = deathBenefitEvenList
			data["deathBenefitOddList"] = deathBenefitOddList
			if(totalPremiumList.size > 0)
				data["totalPremiumList"] = totalPremiumList
			end
			return data
		end

		def self.getElementsAndRateAcceler8(mvelHashMap, quotationIO)
			elementRate = []
			if(quotationIO.baseDO.getBasePlan.addtnField6.to_s != "")
				if(quotationIO.baseDO.getBasePlan.addtnField6 == "Both" || quotationIO.baseDO.getBasePlan.addtnField6 == "AEB")
					elementRate[0] = "aebcurrtdb"
					elementRate[1] = "aebcurrtlb"
				else
					elementRate[0] = "ebpcurrtdb"
					elementRate[1] = "ebpcurrtlb"
				end
			end
			return elementRate
		end
		def self.extractData5YRCT(mvelHashMap, quotationIO, issueAge, listOfAge)
			data = {}
			premiumList = []
			ageList = []
			totalPremium = 0.0
			totalPremiumList = []

			totalInitialAnnualPremium = total = 0.0
			basicPremium=""
			totalDB=""

			basicPremiumDouble = extraLoadingDouble = totalDBDouble = accDBDouble = totalPrem = 0
			productDO = facetDO = nil
			currencyCd = "Ps. "
			currency = "PHP"
			partialTotalPremium = paymentModePremium = 0.0
			ppt = 0

			if(quotationIO != nil)
				if(quotationIO.baseDO != nil)
					if(quotationIO.baseDO.getBasePlan != nil)
						if(quotationIO.baseDO.getBasePlan.currencyCd != nil)
							currency = quotationIO.baseDO.getBasePlan.currencyCd
							if(currency == "PHP")
								currencyCd = "Ps. "
							elsif(currency == "USD")
								currencyCd = "US $"
							end
						end
						if(quotationIO.baseDO.getBasePlan.premiumPayingTerm != nil)
							ppt = quotationIO.baseDO.getBasePlan.premiumPayingTerm
						end
					end
				end
			end


			if(listOfAge != nil)
				listOfAge.each do |age|
					total = 0.0
					curAge = age
					ageList.push(age)
					age = (age.to_i - issueAge + 1).to_s
					productTerm = quotationIO.baseDO.getBasePlan.productTerm
					if(quotationIO.baseDO.getBasePlan != nil)
							productDO = quotationIO.baseDO.getBasePlan.getProduct
					end
					i = age.to_s
					if(quotationIO.finalMap != nil)
						if(quotationIO.finalMap[i.to_i] != nil)
							if(quotationIO.finalMap[i.to_i]["basicpremiumcompute"] != nil)
								basicPremiumDouble = quotationIO.finalMap[i.to_i]["basicpremiumcompute"]["0"] != nil ? quotationIO.finalMap[i.to_i]["basicpremiumcompute"]["0"].to_f : 0
							else
								basicPremiumDouble = 0.0
							end
							if(quotationIO.finalMap[i.to_i]["extrapremiumcompute"] != nil)
								extraLoadingDouble = quotationIO.finalMap[i.to_i]["extrapremiumcompute"]["0"] != nil ? quotationIO.finalMap[i.to_i]["extrapremiumcompute"]["0"].to_f : 0
							else
								extraLoadingDouble = 0.0
							end
							if(quotationIO.finalMap[i.to_i]["ridermodalpremium"] != nil)
								if(curAge.to_s == "60")
									tempI = curAge.to_i - issueAge.to_i;
									temp2 = tempI % 5;
									tempAge = temp2==0 ? tempI+1 : tempI;
									totalDBDouble = quotationIO.finalMap[tempAge.to_i]["ridermodalpremium"]["0TDB of 5YRCT"] != nil ? quotationIO.finalMap[tempAge.to_i]["ridermodalpremium"]["0TDB of 5YRCT"].to_f : 0
								else
									totalDBDouble = quotationIO.finalMap[i.to_i]["ridermodalpremium"]["0TDB of 5YRCT"] != nil ? quotationIO.finalMap[i.to_i]["ridermodalpremium"]["0TDB of 5YRCT"].to_f : 0
								end
								if(curAge.to_s == "70")
									tempI = curAge.to_i - issueAge.to_i;
									temp2 = tempI % 5;
									tempAge = temp2==0 ? tempI+1 : tempI;
									accDBDouble = quotationIO.finalMap[tempAge.to_i]["ridermodalpremium"]["0ADB of 5YRCT"] != nil ? quotationIO.finalMap[tempAge.to_i]["ridermodalpremium"]["0ADB of 5YRCT"].to_f : 0
								else
									accDBDouble = quotationIO.finalMap[i.to_i]["ridermodalpremium"]["0ADB of 5YRCT"] != nil ? quotationIO.finalMap[i.to_i]["ridermodalpremium"]["0ADB of 5YRCT"].to_f : 0
								end
							end
							totalPrem = basicPremiumDouble + extraLoadingDouble + totalDBDouble+ accDBDouble
							total = totalPrem

						else
							total = 0.0
						end
					else
						total = 0.0
					end
					if(total.to_s == "0.0")
						premiumList.push("0.00")
					else
						premiumList.push(MobiSys::UIGenUtilCompanyHelper.roundingTableData(total.to_s))
					end

				end
			end

			lst = quotationIO.baseDO.QuotationProductList
			paymentMode = ""
			paymentMode = MobiSys::UIGenUtilHelper.getLookupValue("FREQUENCY",quotationIO.baseDO.getBasePlan.paymentFrequencyCd)

			if(mvelHashMap["quotationIO"] != nil)
				quotationIO = mvelHashMap["quotationIO"]
				productDO = quotationIO.baseDO.getBasePlan.getProduct
				if(productDO != nil)
					facetDO = productDO.getFacet("TIMELINEILLUSTRATION")
				end
			end

			if(quotationIO.finalMap[1]["basicpremiumcompute"] != nil)
				basicPremiumDouble = quotationIO.finalMap[1]["basicpremiumcompute"]["0"] != nil ? quotationIO.finalMap[1]["basicpremiumcompute"]["0"].to_f : 0
			else
				basicPremiumDouble = 0.0
			end
			if(quotationIO.finalMap[1]["extrapremiumcompute"] != nil)
				extraLoadingDouble = quotationIO.finalMap[1]["extrapremiumcompute"]["0"] != nil ? quotationIO.finalMap[1]["extrapremiumcompute"]["0"].to_f : 0
			else
				extraLoadingDouble = 0.0
			end
			if(quotationIO.finalMap[1]["ridermodalpremium"] != nil)
				totalDBDouble = quotationIO.finalMap[1]["ridermodalpremium"]["0TDB of 5YRCT"] != nil ? quotationIO.finalMap[1]["ridermodalpremium"]["0TDB of 5YRCT"].to_f : 0
				accDBDouble = quotationIO.finalMap[1]["ridermodalpremium"]["0ADB of 5YRCT"] != nil ? quotationIO.finalMap[1]["ridermodalpremium"]["0ADB of 5YRCT"].to_f : 0
			end
			paymentModePremium = basicPremiumDouble + extraLoadingDouble + totalDBDouble+ accDBDouble
			isRiderSelect = ""

				if(quotationIO.baseDO.getRiders.size != 0)
					isRiderSelect = "[inclusive of riders]"
				end

			# facetDO = OfflineFacet.new(:actionValue => productDO.productId) if facetDO == nil
			if(facetDO != nil)
				if(facetDO.actionValue == "5RCP0A" || facetDO.actionValue == "GPTP0A")
					# Sun Safer Life 5YRCT , Sun Grepa Proterm - 5YRCT

					totalPremiumList.push(currencyCd + MobiSys::UIGenUtilCompanyHelper.roundingTableData(paymentModePremium.to_f))
					totalPremiumList.push(paymentMode + " premium")
					totalPremiumList.push("initially payable in 5 years")
					totalPremiumList.push("#{isRiderSelect}")
				end
			end

			if(totalPremiumList.size > 0)
				data["totalPremiumList"] = totalPremiumList
			end
			data["ageList"] = ageList
			data["premiumList"] = premiumList
			data["startingAgeList"] = mvelHashMap["startingAgeList"]

			return data
		end
		def self.extractDataSDM(mvelHashMap, quotationIO, issueAge, listOfAge)
	  		data = {}
			livingBenefitList = []
			deathBenefitList = []
			totalPremiumList = []
			maturityBenefitList = []
			productNameList = []

			prdNameFacetDO = capProcPercFacetDO = productDO = facetDO = nil
			currencyCd = "Ps. "
			currency = "PHP"

			if(quotationIO != nil)
				if(quotationIO.baseDO != nil)
					if(quotationIO.baseDO.getBasePlan != nil)
						if(quotationIO.baseDO.getBasePlan.currencyCd != nil)
							currency = quotationIO.baseDO.getBasePlan.currencyCd
							if(currency == "PHP")
								currencyCd = "Ps. "
							elsif(currency == "USD")
								currencyCd = "US $"
							end
						end
					end
				end
			end
			if(listOfAge != nil)
				listOfAge.each do |age|
					if(quotationIO.baseDO.getBasePlan != nil)
							productDO = quotationIO.baseDO.getBasePlan.getProduct
					end
					i = age.to_s
					if(quotationIO.finalMap != nil)
						if(quotationIO.finalMap[i.to_i] != nil)
							if(quotationIO.finalMap[i.to_i]["fundvalue"] != nil)
								livingBenefitList.push(quotationIO.finalMap[i.to_i]["fundvalue"]["0.04"] != nil ? MobiSys::UIGenUtilCompanyHelper.roundingTableData(quotationIO.finalMap[i.to_i]["fundvalue"]["0.04"]) : "0")
							else
								livingBenefitList.push("0")
							end
							if(quotationIO.finalMap[i.to_i]["deathbenefit"] != nil)
								deathBenefitList.push(quotationIO.finalMap[i.to_i]["deathbenefit"]["0.04"] != nil ? MobiSys::UIGenUtilCompanyHelper.roundingTableData(quotationIO.finalMap[i.to_i]["deathbenefit"]["0.04"]) : "0")
							else
								deathBenefitList.push("0")
							end
						else
							total = 0.0
						end
					else
						total = 0.0
					end
				end
			end

			lst = quotationIO.baseDO.QuotationProductList

			if(mvelHashMap["quotationIO"] != nil)
				quotationIO = mvelHashMap["quotationIO"]
				productDO = quotationIO.baseDO.getBasePlan.getProduct
				if(productDO != nil)
					facetDO = productDO.getFacet("TIMELINEILLUSTRATION")
				end
				if(productDO != nil)
					prdNameFacetDO = productDO.getFacet("TIMELINENAMEOFSTRUCTUREDNOTE")
				end
				if(productDO != nil)
					capProcPercFacetDO = productDO.getFacet("TIMELINECAPITALPROTECTION")
				end
			end
			totalPremiumList.push(currencyCd + MobiSys::UIGenUtilCompanyHelper.roundingTableData(quotationIO.baseDO.getBasePlan.baseAnnualPremium.to_s))
			#puts "prdNameFacetDO.actionValue=======#{prdNameFacetDO.actionValue.inspect}"
			if(prdNameFacetDO != nil && prdNameFacetDO.actionValue != nil)
				productNameList.push(prdNameFacetDO.actionValue.to_s)
			end

			if(quotationIO.finalMap[7]["fundvalue"] != nil)
				maturityBenefitList.push(currencyCd + (quotationIO.finalMap[7]["fundvalue"]["0.04"] != nil ? MobiSys::UIGenUtilCompanyHelper.roundingTableData(quotationIO.finalMap[7]["fundvalue"]["0.04"]) : "0"))
			else
				maturityBenefitList.push(currencyCd+"0")
			end

			if(capProcPercFacetDO != nil)
				if(capProcPercFacetDO.actionValue != nil)
					maturityBenefitList.push("With "+capProcPercFacetDO.actionValue.to_s+"% Capital Protection")
				else
					maturityBenefitList.push("With 100% Capital Protection")
				end
			end

			if(totalPremiumList.size > 0)
				data["totalPremiumList"] = totalPremiumList
			end

			data["deathBenefitList"] = deathBenefitList
			data["productNameList"] = productNameList
			data["livingBenefitList"] = livingBenefitList
			data["maturityBenefitList"] = maturityBenefitList
			return data
		end

	# def self.getPremiumTable(quotationIO,inRiderList,inMvelHashMap)
	# 		puts "inRiderList---> #{inRiderList.inspect}"
	# 		# puts "quotationIO---> #{quotationIO.inspect}"
	# 		# puts "inMvelHashMap---> #{inMvelHashMap.inspect}"
	# 		mvelHashMap = inMvelHashMap
	# 		outputPreferencesDO = mvelHashMap['outputPreferencesDO']
	# 		riderList=inRiderList
	# 		p "--------------riderList: #{riderList}"
	# 		productTerm= quotationIO.baseDO.getBaseProduct.productTerm.to_i
	# 		sb = ""
	# 		upperLimit=0
	# 		lowerLimit = 0
	# 		basicPremium=""
	# 		extraLoading=""
	# 		totalDB=""
	# 		accidentalDB=""
	# 		totalCIB=""
	# 		total =""
	# 		issueAge=quotationIO.baseDO.getPartyByRole("PRIMARY").age.to_i;
	# 		totalDBPeriod = 0
	# 		accidentalDBPeriod=0
	# 		currCalanderYear = mvelHashMap["calendarYear"].to_i
	# 		extraLoadingFlag=false
	# 		isCalanderYearIllustration = false
	# 		isAgeIllustration = false
	# 		tableHeader = "Dur"
	# 		noteDuration = "the end of duration"
	# 	    if outputPreferencesDO != nil && outputPreferencesDO.field2 == "CALENDARYEAR"
	# 			isCalanderYearIllustration=true
	# 			tableHeader="Year"
	# 			noteDuration = "year"
	# 		end
	# 		if outputPreferencesDO != nil && outputPreferencesDO.field2 == "AGE"
	# 			isAgeIllustration=true
	# 			tableHeader="Age"
	# 			noteDuration = "attained age"
	# 		end
	# 		sb << "<div>"
	# 		quotationIO.baseDO.QuotationProductList.each do |quotationProduct|
	# 			if quotationProduct.productTypeCd == 'PLAN'
	# 				puts "if quotationProduct.productTypeCd == 'PLAN'"
	# 				basicPremiumDouble = 0
	# 				extraLoadingDouble = 0
	# 				totalDBDouble = 0
	# 				totalCIBDouble = 0
	# 				accDBDouble = 0
	# 				totalPremium=0

	# 		        if quotationProduct.getExtraQuotationProducts.size > 0 && (quotationProduct.getExtraQuotationProducts[0].extraFlatAmt.to_s != ""  || (quotationProduct.getExtraQuotationProducts[0].extraPercent.to_s != ""  && quotationProduct.getExtraQuotationProducts[0].extraPercent.to_i > 1))
	# 			        #for BasePlan where Extra Loading is Selected
	# 			        adbRider = quotationIO.finalMap[1]["ridermodalpremium"]==nil ? false :  quotationIO.finalMap[1]["ridermodalpremium"]["0ADB of 5YRCT"]== nil ? false : true

	# 					tdbRider = quotationIO.finalMap[1]["ridermodalpremium"]==nil ? false :  quotationIO.finalMap[1]["ridermodalpremium"]["0TDB of 5YRCT"]== nil ? false : true

	# 					cibRider = quotationIO.finalMap[1]["ridermodalpremium"]==nil ? false :  quotationIO.finalMap[1]["ridermodalpremium"]["0CIB"]== nil ? false : true

	# 					sb << " <div class='SLF5yrtc'>"
	# 					sb << "<table align='center' class ='fontFamilyGFB fontSize12 SLFPremiumSchedTable' style='border: 1px solid black; margin-top: 10px; border-collapse:collapse;width:30%;margin-top:10px;border: 1px solid black;' cellspacing='0'>"
	# 					sb << "<tr style='border: 1px solid black;'><td width='10%' class='fontFamilyATL fontSize14 header'>"+tableHeader+"</td>"
	# 					sb << "<td class=\"fontFamilyATL fontSize14 header\" width =\"15%\">Basic Premium</td>"
	# 					sb << "<td class=\"fontFamilyATL fontSize14 header\" width =\"15%\">Extra Premium</td>"
	# 					if tdbRider
	# 						sb << "<td class=\"fontFamilyATL fontSize14 header\" width =\"15%\">Total<br/>Disability<br/>Benefit</td>"
	# 					end
	# 					if adbRider
	# 						sb << "<td class=\"fontFamilyATL fontSize14 header\" width =\"15%\">Accidental<br>Death Benefit</td>"
	# 					end
	# 					if cibRider
	# 						sb << "<td class=\"fontFamilyATL fontSize14 header\" width =\"15%\">Critical Illness<br>Benefit</td>"
	# 					end
	# 					sb << "<td class=\"fontFamilyATL fontSize14 header\" width =\"15%\">Total<br/>Premium</td></tr>"

	# 					i = 1
	# 					for i in (i..productTerm)

	# 						if quotationIO.finalMap[i] != nil && (i-1)%5 == 0
	# 							lowerLimit = i
	# 							if i + 4 > productTerm
	# 								upperLimit = productTerm
	# 							else
	# 								upperLimit = i + 4
	# 							end
	# 							basicPremiumDouble = quotationIO.finalMap[i]["basicpremiumcompute"]["0"] != nil ? quotationIO.finalMap[i]["basicpremiumcompute"]["0"] : 0
	# 							extraLoadingDouble = quotationIO.finalMap[i]["extrapremiumcompute"]["0"] !=nil ? quotationIO.finalMap[i]["extrapremiumcompute"]["0"] : 0
	# 							if quotationIO.finalMap[i]["ridermodalpremium"] != nil
	# 								totalDBDouble = quotationIO.finalMap[i]["ridermodalpremium"]["0TDB of 5YRCT"] != nil ? quotationIO.finalMap[i]["ridermodalpremium"]["0TDB of 5YRCT"] : 0
	# 							end
	# 							if quotationIO.finalMap[i]["ridermodalpremium"] != nil
	# 								accDBDouble = quotationIO.finalMap[i]["ridermodalpremium"]["0ADB of 5YRCT"] != nil ? quotationIO.finalMap[i]["ridermodalpremium"]["0ADB of 5YRCT"] : 0
	# 							end
	# 							if quotationIO.finalMap[i]["ridermodalpremium"] != nil
	# 								totalCIBDouble = quotationIO.finalMap[i]["ridermodalpremium"]["0CIB"] != nil ? quotationIO.finalMap[i]["ridermodalpremium"]["0CIB"] : 0
	# 							end

	# 							if riderList.respond_to?('each')
	# 								riderList.each do |rd|
	# 									if totalDBPeriod == 0
	# 										totalDBPeriod = rd.productId == "TDB of 5YRCT" ? rd.productTerm : 0
	# 									end
	# 									if(accidentalDBPeriod==0)
	# 										accidentalDBPeriod=rd.productId == "ADB of 5YRCT" ? rd.productTerm : 0
	# 									end
	# 								end
	# 							end

	# 							sb << "<tr>"
	# 							sb << "<td style=' text-align: center; border-right: 1px solid #000;' >"

	# 							if(isCalanderYearIllustration)
	# 								lowerLimit = lowerLimit + currCalanderYear - 1
	# 								upperLimit = upperLimit + currCalanderYear - 1
	# 							end

	# 							if(isAgeIllustration)
	# 								lowerLimit = lowerLimit + issueAge - 1
	# 								upperLimit = upperLimit + issueAge - 1
	# 							end
	# 							if(lowerLimit==upperLimit)
	# 								sb << lowerLimit.to_s
	# 							else
	# 								sb << lowerLimit.to_s
	# 								sb << " - "
	# 								sb << upperLimit.to_s
	# 							end
	# 							basicPremium=basicPremiumDouble
	# 							extraLoading=extraLoadingDouble
	# 							totalDB=totalDBDouble
	# 							accidentalDB = accDBDouble
	# 							totalCIB = totalCIBDouble
	# 							totalPremium = basicPremiumDouble + extraLoadingDouble +totalDBDouble+accDBDouble+totalCIBDouble
	# 							total = totalPremium

	# 							sb << "</td>"
	# 							sb << "<td style='text-align: right; border-right: 1px solid #000; padding-right: 3px;'>"
	# 							sb << getFormatDoubleTwoDecimalWithComma(basicPremium)
	# 							sb << "</td>"
	# 							sb << "<td style='text-align: right; border-right: 1px solid #000; padding-right: 3px;'>"
	# 							sb << getFormatDoubleTwoDecimalWithComma(extraLoading)
	# 							sb << "</td>"
	# 							if tdbRider
	# 								sb << "<td style='text-align: right; border-right: 1px solid #000; padding-right: 3px;'>"
	# 								sb << getFormatDoubleTwoDecimalWithComma(totalDB)
	# 								sb << "</td>"
	# 							end
	# 							if adbRider
	# 								sb << "<td style='text-align: right; border-right: 1px solid #000; padding-right: 3px;'>"
	# 								sb << getFormatDoubleTwoDecimalWithComma(accidentalDB)
	# 								sb << "</td>"
	# 							end
	# 							if cibRider
	# 								sb << "<td style='text-align: right; border-right: 1px solid #000; padding-right: 3px;'>"
	# 								sb << getFormatDoubleTwoDecimalWithComma(totalCIB)
	# 								sb << "</td>"
	# 							end
	# 							sb << "<td style='text-align: right; border-right: 1px solid #000; padding-right: 3px;'>"
	# 							sb << getFormatDoubleTwoDecimalWithComma(total)
	# 							sb << "</td>"
	# 							sb << "</tr>"
	# 							basicPremium = ""
	# 							totalDB = ""
	# 							accidentalDB = ""
	# 							totalCIB = ""
	# 							total = ""
	# 						end
	# 			        end
	# 			        sb << "</table></div>"
	# 			    else
	# 					#For BasePlan where Extra Loading is not Selected
	# 					adbRider = quotationIO.finalMap[1]["ridermodalpremium"]==nil ? false :  quotationIO.finalMap[1]["ridermodalpremium"]["0ADB of 5YRCT"]== nil ? false : true

	# 					tdbRider = quotationIO.finalMap[1]["ridermodalpremium"]==nil ? false :  quotationIO.finalMap[1]["ridermodalpremium"]["0TDB of 5YRCT"]== nil ? false : true

	# 					cibRider = quotationIO.finalMap[1]["ridermodalpremium"]==nil ? false :  quotationIO.finalMap[1]["ridermodalpremium"]["0CIB"]== nil ? false : true

	# 					sb << " <div class='center SLF5yrtc'>"
	# 					sb << "<table align='center' class= 'fontFamilyGFB fontSize12 SLFPremiumSchedTable' style='border: 1px solid black; margin-top: 10px; border-collapse:collapse;margin-top:10px;width:30%;margin-top:10px;border: 1px solid black;' cellspacing='0'>"
	# 					sb << "<tr><td width='12%' class='fontFamilyATL fontSize14 header'style=\"border:1px solid black;\">"+tableHeader+"</td>"
	# 					sb << "<td class=\"fontFamilyATL fontSize14 header\" width =\"15%\">Basic Premium</td>"
	# 					if tdbRider
	# 						sb << "<td class=\"fontFamilyATL fontSize14 header\" width =\"15%\">Total<br/>Disability<br/>Benefit</td>"
	# 					end
	# 					if adbRider
	# 						sb << "<td class=\"fontFamilyATL fontSize14 header\" width =\"15%\">Accidental<br>Death Benefit</td>"
	# 					end
	# 					if cibRider
	# 						sb << "<td class=\"fontFamilyATL fontSize14 header\" width =\"15%\">Critical Illness<br>Benefit</td>"
	# 					end
	# 					sb << "<td class=\"fontFamilyATL fontSize14 header\" width =\"15%\">Total<br/>Premium</td></tr>"
	# 					i = 1
	# 			        for i in (i..productTerm)
	# 			        	puts "else inside if for loop"
	# 						if quotationIO.finalMap[i] != nil && (i-1)%5 == 0
	# 							lowerLimit = i
	# 							if i+4 > productTerm
	# 								upperLimit = productTerm
	# 							else
	# 								upperLimit = i+4
	# 							end
	# 							basicPremiumDouble=quotationIO.finalMap[i]["basicpremiumcompute"]["0"] != nil ? quotationIO.finalMap[i]["basicpremiumcompute"]["0"] : 0
	# 							if(quotationIO.finalMap[i]["ridermodalpremium"] != nil)
	# 								totalDBDouble = quotationIO.finalMap[i]["ridermodalpremium"]["0TDB of 5YRCT"] != nil ? quotationIO.finalMap[i]["ridermodalpremium"]["0TDB of 5YRCT"] : 0
	# 							end
	# 							if(quotationIO.finalMap[i]["ridermodalpremium"] != nil)
	# 								accDBDouble=quotationIO.finalMap[i]["ridermodalpremium"]["0ADB of 5YRCT"] != nil ? quotationIO.finalMap[i]["ridermodalpremium"]["0ADB of 5YRCT"] : 0
	# 							end
	# 							if(quotationIO.finalMap[i]["ridermodalpremium"] != nil)
	# 								totalCIBDouble=quotationIO.finalMap[i]["ridermodalpremium"]["0CIB"] != nil ? quotationIO.finalMap[i]["ridermodalpremium"]["0CIB"] : 0
	# 							end
	# 							issueAge = quotationIO.baseDO.getPartyByRole("PRIMARY").age.to_i

	# 							sb << "<tr>"
	# 							sb << "<td style=' text-align: center; border-right: 1px solid #000;' >"
	# 							if(isCalanderYearIllustration)
	# 								lowerLimit = lowerLimit + currCalanderYear - 1;
	# 								upperLimit = upperLimit + currCalanderYear - 1;
	# 							end
	# 							if(isAgeIllustration)

	# 								lowerLimit = lowerLimit + issueAge - 1;
	# 								upperLimit = upperLimit + issueAge - 1;
	# 							end
	# 							if(lowerLimit==upperLimit)
	# 								sb << lowerLimit.to_s
	# 							else
	# 								sb << lowerLimit.to_s
	# 								sb << " - "
	# 								sb << upperLimit.to_s
	# 							end
	# 							basicPremium=basicPremiumDouble
	# 							extraLoading=extraLoadingDouble
	# 							totalDB=totalDBDouble
	# 							accidentalDB = accDBDouble
	# 							totalCIB = totalCIBDouble
	# 							totalPremium = basicPremiumDouble + extraLoadingDouble +totalDBDouble+accDBDouble;
	# 							total = totalPremium
	# 							sb << "</td>"
	# 							sb << "<td style='text-align: right; border-right: 1px solid #000; padding-right: 3px;'>"
	# 							sb << getFormatDoubleTwoDecimalWithComma(basicPremium)
	# 							sb << "</td>"
	# 							if tdbRider
	# 								sb << "<td style='text-align: right; border-right: 1px solid #000; padding-right: 3px;'>"
	# 								sb << getFormatDoubleTwoDecimalWithComma(totalDB)
	# 								sb << "</td>"
	# 							end
	# 							if adbRider
	# 								sb << "<td style='text-align: right; border-right: 1px solid #000; padding-right: 3px;'>"
	# 								sb << getFormatDoubleTwoDecimalWithComma(accidentalDB)
	# 								sb << "</td>"
	# 							end
	# 							if cibRider
	# 								sb << "<td style='text-align: right; border-right: 1px solid #000; padding-right: 3px;'>"
	# 								sb << getFormatDoubleTwoDecimalWithComma(totalCIB)
	# 								sb << "</td>"
	# 							end
	# 							sb << "<td style='text-align: right; border-right: 1px solid #000; padding-right: 3px;'>"
	# 							sb << getFormatDoubleTwoDecimalWithComma(total)
	# 							sb << "</td>"
	# 							sb << "</tr>"

	# 							basicPremium = ""
	# 							totalDB = ""
	# 							accidentalDB = ""
	# 							totalCIB = ""
	# 							total = ""
	# 						end
	# 					end
	# 		            sb << "</table></div>"
	# 				end
	# 				break
	# 			end
	# 		end
	# 		sb << "</div>"
	# 		p "-----------------sb: #{sb}"
	# 		return sb.to_s
	# end

		def self.getPremiumTable(quotationIO,inRiderList,inMvelHashMap)
			# puts "inRiderList---> #{inRiderList.inspect}"
			# puts "quotationIO---> #{quotationIO.inspect}"
			# puts "inMvelHashMap---> #{inMvelHashMap.inspect}"
			mvelHashMap = inMvelHashMap
			outputPreferencesDO = mvelHashMap['outputPreferencesDO']
			riderList=inRiderList
			# p "--------------riderList: #{riderList}"
			productTerm= quotationIO.baseDO.getBaseProduct.productTerm.to_i
			sb = ""
			upperLimit=0
			lowerLimit = 0
			basicPremium=""
			extraLoading=""
			totalDB=""
			accidentalDB=""
			totalCIB=""
			total =""
			issueAge=quotationIO.baseDO.getPartyByRole("PRIMARY").age.to_i;
			totalDBPeriod = 0
			accidentalDBPeriod=0
			currCalanderYear = mvelHashMap["calendarYear"].to_i
			extraLoadingFlag=false
			isCalanderYearIllustration = false
			isAgeIllustration = false
			tableHeader = "Dur"
			noteDuration = "the end of duration"
		    if outputPreferencesDO != nil && outputPreferencesDO.field2 == "CALENDARYEAR"
				isCalanderYearIllustration=true
				tableHeader="Year"
				noteDuration = "year"
			end
			if outputPreferencesDO != nil && outputPreferencesDO.field2 == "AGE"
				isAgeIllustration=true
				tableHeader="Age"
				noteDuration = "attained age"
			end
			sb << "<div>"
			quotationIO.baseDO.QuotationProductList.each do |quotationProduct|
				if quotationProduct.productTypeCd == 'PLAN'
					# puts "if quotationProduct.productTypeCd == 'PLAN'"
					basicPremiumDouble = 0
					extraLoadingDouble = 0
					totalDBDouble = 0
					totalCIBDouble = 0
					accDBDouble = 0
					totalPremium=0

			        if quotationProduct.getExtraQuotationProducts.size > 0 && (quotationProduct.getExtraQuotationProducts[0].extraFlatAmt.to_s != ""  || (quotationProduct.getExtraQuotationProducts[0].extraPercent.to_s != ""  && quotationProduct.getExtraQuotationProducts[0].extraPercent.to_f > 1.0))
				        #for BasePlan where Extra Loading is Selected
				        #p "====inside if caveat"
				        adbRider = quotationIO.finalMap[1]["ridermodalpremium"]==nil ? false :  quotationIO.finalMap[1]["ridermodalpremium"]["0ADB"]== nil ? false : true

						tdbRider = quotationIO.finalMap[1]["ridermodalpremium"]==nil ? false :  quotationIO.finalMap[1]["ridermodalpremium"]["0TDB"]== nil ? false : true

						cibRider = quotationIO.finalMap[1]["ridermodalpremium"]==nil ? false :  quotationIO.finalMap[1]["ridermodalpremium"]["0CIB"]== nil ? false : true

						sb << " <div class='SLF5yrtc'>"
						sb << "<table align='center' class= 'fontFamilyGFB fontSize12 SLFPremiumSchedTable' style='border: 1px solid black; margin-top: 10px; border-collapse:collapse;margin-top:10px; border:1px solid black; table-layout:fixed;' cellspacing='0' width='90%' >"
						sb << "<tr style='border: 1px solid black;'><td width='14%' class='fontFamilyATLBold fontSize14 header'>"+tableHeader+"</td>"
						sb << "<td class=\"fontFamilyATLBold fontSize14 header\" width =\"14%\">Basic Premium</td>"
						sb << "<td class=\"fontFamilyATLBold fontSize14 header\" width =\"14%\">Extra Premium</td>"
						if tdbRider
							sb << "<td class=\"fontFamilyATLBold fontSize14 header\" width =\"14%\">Total Disability<br/>Benefit</td>"
						end
						if adbRider
							sb << "<td class=\"fontFamilyATLBold fontSize14 header\" width =\"14%\">Accidental<br>Death Benefit</td>"
						end
						if cibRider
							sb << "<td class=\"fontFamilyATLBold fontSize14 header\" width =\"15%\">Critical Illness<br>Benefit</td>"
						end
						sb << "<td class=\"fontFamilyATLBold fontSize14 header\" width =\"14%\">Total Premium</td></tr>"

						i = 1
						for i in (i..productTerm)
							#p "===quotationIO.finalMap[i]: #{quotationIO.finalMap[i]}"
							#p "===(i-1)%5: #{(i-1)%5}"
							if quotationIO.finalMap[i] != nil && (i-1)%5 == 0
								lowerLimit = i
								if i + 4 > productTerm
									upperLimit = productTerm
								else
									upperLimit = i + 4
								end
								basicPremiumDouble = quotationIO.finalMap[i]["basicpremiumcompute"]["0"] != nil ? quotationIO.finalMap[i]["basicpremiumcompute"]["0"] : 0
								extraLoadingDouble = quotationIO.finalMap[i]["extrapremiumcompute"]["0"] !=nil ? quotationIO.finalMap[i]["extrapremiumcompute"]["0"] : 0
								#p "===========extraLoadingDouble: #{extraLoadingDouble}"
								if quotationIO.finalMap[i]["ridermodalpremium"] != nil
									totalDBDouble = quotationIO.finalMap[i]["ridermodalpremium"]["0TDB"] != nil ? quotationIO.finalMap[i]["ridermodalpremium"]["0TDB"] : 0
								end
								if quotationIO.finalMap[i]["ridermodalpremium"] != nil
									accDBDouble = quotationIO.finalMap[i]["ridermodalpremium"]["0ADB"] != nil ? quotationIO.finalMap[i]["ridermodalpremium"]["0ADB"] : 0
								end
								if quotationIO.finalMap[i]["ridermodalpremium"] != nil
									totalCIBDouble = quotationIO.finalMap[i]["ridermodalpremium"]["0CIB"] != nil ? quotationIO.finalMap[i]["ridermodalpremium"]["0CIB"] : 0
								end
								issueAge = quotationIO.baseDO.getPartyByRole("PRIMARY").age.to_i
								if riderList.respond_to?('each')
									riderList.each do |rd|
										if totalDBPeriod == 0
											totalDBPeriod = rd.productId == "TDB" ? rd.productTerm : 0
										end
										if(accidentalDBPeriod == 0)
											accidentalDBPeriod = rd.productId == "ADB" ? rd.productTerm : 0
										end
									end
								end

								sb << "<tr>"
								sb << "<td style=' text-align: center; border-right: 1px solid #000;' >"
                                totalDBIndicator = ""
								        accidentalDBIndicator = ""
								        # p "---------totalDBPeriod: #{totalDBPeriod}"
								        # p "---------lowerLimit: #{lowerLimit}"
								        # p "---------totalDBPeriod: #{totalDBPeriod}"
								        # p "---------upperLimit: #{upperLimit}"
								        if(totalDBPeriod >= lowerLimit && totalDBPeriod < upperLimit)
								        	#p "====if flag change"
								                              totalDBFlag = true
								                              totalDBIndicator = "*"
								        end
								        if(accidentalDBPeriod >=lowerLimit && accidentalDBPeriod < upperLimit)
								                              accidentalDBFlag=true
								                              accidentalDBIndicator="^"
								        end

								if(isCalanderYearIllustration)
									lowerLimit = lowerLimit + currCalanderYear - 1
									upperLimit = upperLimit + currCalanderYear - 1
								end

								if(isAgeIllustration)
									lowerLimit = lowerLimit + issueAge - 1
									upperLimit = upperLimit + issueAge - 1
								end
								if(lowerLimit==upperLimit)
									sb << lowerLimit.to_s
								else
									sb << lowerLimit.to_s
									sb << " - "
									sb << upperLimit.to_s
								end
								basicPremium=basicPremiumDouble
								extraLoading=extraLoadingDouble
								totalDB=totalDBDouble
								accidentalDB = accDBDouble
								totalCIB = totalCIBDouble
								totalPremium = basicPremiumDouble + extraLoadingDouble +totalDBDouble+accDBDouble+totalCIBDouble
								total = totalPremium

								sb << "</td>"
								sb << "<td style='text-align: right; border-right: 1px solid #000; padding-right: 3px;'>"
								sb << getFormatDoubleTwoDecimalWithComma(basicPremium)
								sb << "</td>"
								sb << "<td style='text-align: right; border-right: 1px solid #000; padding-right: 3px;'>"
								sb << getFormatDoubleTwoDecimalWithComma(extraLoading)
								sb << "</td>"
								if tdbRider
									sb << "<td style='text-align: right; border-right: 1px solid #000; padding-right: 3px;'>"
									sb << getFormatDoubleTwoDecimalWithComma(totalDB)
									sb << "</td>"
								end
								if adbRider
									sb << "<td style='text-align: right; border-right: 1px solid #000; padding-right: 3px;'>"
									sb << getFormatDoubleTwoDecimalWithComma(accidentalDB)
									sb << "</td>"
								end
								if cibRider
									sb << "<td style='text-align: right; border-right: 1px solid #000; padding-right: 3px;'>"
									sb << getFormatDoubleTwoDecimalWithComma(totalCIB)
									sb << "</td>"
								end
								sb << "<td style='text-align: right; border-right: 1px solid #000; padding-right: 3px;'>"
								sb << getFormatDoubleTwoDecimalWithComma(total)
								sb << "</td>"
								sb << "</tr>"
								basicPremium = ""
								totalDB = ""
								accidentalDB = ""
								totalCIB = ""
								total = ""
							end
							end
						    # code start for caveat
							if(isCalanderYearIllustration)
								totalDBPeriod = totalDBPeriod + currCalanderYear;
								accidentalDBPeriod = accidentalDBPeriod + currCalanderYear;
								#puts "++++++++++totalDBPeriod: #{totalDBPeriod}"
							end
							if(isAgeIllustration)
								totalDBPeriod = totalDBPeriod + issueAge;
								accidentalDBPeriod = accidentalDBPeriod + issueAge;
							end
							sb << "</table></div>"
							#p "==================outside if totalDBFlag: #{totalDBFlag}"
							if(totalDBFlag)
								sb << "<div class ='fontFamilyGFB fontSize11' style='padding-left:40px$SEMI$margin-top:10px' >* TDB premium payment terminates at "+noteDuration.to_s+" "+totalDBPeriod.to_i.to_s+".</div>"
							#puts "~~~~~~~~~~~~ #{totalDBFlag}"
							end

							if(accidentalDBFlag)
								padding = ""
								padding = "$SEMI$margin-top:10px" if (!totalDBFlag)
								sb << "<div class ='fontFamilyGFB fontSize11' style='padding-left:40px#{padding}'>^ ADB premium payment terminates at "+noteDuration.to_s+" "+accidentalDBPeriod.to_i.to_s+".</div>"
							end
						# code end for caveat
				    else
						#For BasePlan where Extra Loading is not Selected
						# making changes to show missing coloum premiumScheduleTable by changing 0TDB of 5YRCT = 0TDB & 0ADB of 5YRCT = 0ADB
						#p "======================inside else"
						adbRider = quotationIO.finalMap[1]["ridermodalpremium"]==nil ? false :  quotationIO.finalMap[1]["ridermodalpremium"]["0ADB"]== nil ? false : true
						#p "-----adbRider1 #{adbRider}"
						tdbRider = quotationIO.finalMap[1]["ridermodalpremium"]==nil ? false :  quotationIO.finalMap[1]["ridermodalpremium"]["0TDB"]== nil ? false : true
						#p "-----tdbRider1 #{tdbRider}"
						cibRider = quotationIO.finalMap[1]["ridermodalpremium"]==nil ? false :  quotationIO.finalMap[1]["ridermodalpremium"]["0CIB"]== nil ? false : true
						#p "-----cibRider1 #{cibRider}"
						sb << " <div class='center SLF5yrtc' style='margin-left:11%'>"
						 # sb << "<table align='center' class= 'fontFamilyGFB fontSize12 SLFPremiumSchedTable' style='border: 1px solid black; margin-top: 10px; border-collapse:collapse;margin-top:10px;width:35%;margin-top:10px;border: 1px solid black;' cellspacing='0'>"

						sb << "<table align='center' class= 'fontFamilyGFB fontSize12 SLFPremiumSchedTable' style='border: 1px solid black; margin-top: 10px; border-collapse:collapse;margin-top:10px; border:1px solid black; table-layout:fixed;' cellspacing='0' width='90%' >"

						sb << "<tr><td width='14%' class='fontFamilyATLBold fontSize14 header'style=\"border:1px solid black;\">"+tableHeader+"</td>"
						sb << "<td class=\"fontFamilyATLBold fontSize14 header\" width =\"14%\">Basic Premium</td>"
						if tdbRider
							sb << "<td class=\"fontFamilyATLBold fontSize14 header\" width =\"14%\">Total Disability<br/>Benefit</td>"
						end
						if adbRider
							sb << "<td class=\"fontFamilyATLBold fontSize14 header\" width =\"14%\">Accidental<br>Death Benefit</td>"
						end
						if cibRider
							sb << "<td class=\"fontFamilyATLBold fontSize14 header\" width =\"15%\">Critical Illness<br>Benefit</td>"
						end
						sb << "<td class=\"fontFamilyATLBold fontSize14 header\" width =\"14%\">Total Premium</td></tr>"
						i = 1
						# making changes to show missing values in TDB & ADB coloum by changing 0TDB of 5YRCT = 0TDB & 0ADB of 5YRCT = 0ADB
				        for i in (i..productTerm)
				        	#puts "else inside if for loop"
							if quotationIO.finalMap[i] != nil && (i-1)%5 == 0
								lowerLimit = i
								if i+4 > productTerm
									upperLimit = productTerm
								else
									upperLimit = i+4
								end
								basicPremiumDouble=quotationIO.finalMap[i]["basicpremiumcompute"]["0"] != nil ? quotationIO.finalMap[i]["basicpremiumcompute"]["0"] : 0
								if(quotationIO.finalMap[i]["ridermodalpremium"] != nil)
									totalDBDouble = quotationIO.finalMap[i]["ridermodalpremium"]["0TDB"] != nil ? quotationIO.finalMap[i]["ridermodalpremium"]["0TDB"] : 0
								end
								if(quotationIO.finalMap[i]["ridermodalpremium"] != nil)
									accDBDouble=quotationIO.finalMap[i]["ridermodalpremium"]["0ADB"] != nil ? quotationIO.finalMap[i]["ridermodalpremium"]["0ADB"] : 0
								end
								if(quotationIO.finalMap[i]["ridermodalpremium"] != nil)
									totalCIBDouble=quotationIO.finalMap[i]["ridermodalpremium"]["0CIB"] != nil ? quotationIO.finalMap[i]["ridermodalpremium"]["0CIB"] : 0
								end
								issueAge = quotationIO.baseDO.getPartyByRole("PRIMARY").age.to_i


								# code start for caveat
								# making changes to show missing caveat coloum by changing 0TDB of 5YRCT=0TDB & 0ADB of 5YRCT=0ADB
								 if riderList.respond_to?('each')
									riderList.each do |rd|
									if (totalDBPeriod == 0)
										totalDBPeriod = rd.productId == "TDB" ? rd.productTerm : 0
									end
									if(accidentalDBPeriod==0)
										accidentalDBPeriod=rd.productId == "ADB" ? rd.productTerm : 0
									end
									end
								 end
								 		sb << "<tr>"
										sb << "<td style=' text-align: center; border-right: 1px solid #000;' >"
										totalDBIndicator = ""
								        accidentalDBIndicator = ""
								        # p "---------totalDBPeriod: #{totalDBPeriod}"
								        # p "---------lowerLimit: #{lowerLimit}"
								        # p "---------totalDBPeriod: #{totalDBPeriod}"
								        # p "---------upperLimit: #{upperLimit}"
								        if(totalDBPeriod >= lowerLimit && totalDBPeriod < upperLimit)
								        	#p "====if flag change"
								                              totalDBFlag = true
								                              totalDBIndicator = "*"
								        end
								        if(accidentalDBPeriod >=lowerLimit && accidentalDBPeriod < upperLimit)
								                              accidentalDBFlag=true
								                              accidentalDBIndicator="^"
								        end
								# code end for caveat

								if(isCalanderYearIllustration)
									lowerLimit = lowerLimit + currCalanderYear - 1;
									upperLimit = upperLimit + currCalanderYear - 1;
								end
								if(isAgeIllustration)

									lowerLimit = lowerLimit + issueAge - 1;
									upperLimit = upperLimit + issueAge - 1;
								end
								if(lowerLimit==upperLimit)
									sb << lowerLimit.to_s
								else
									sb << lowerLimit.to_s
									sb << " - "
									sb << upperLimit.to_s
								end
								basicPremium=basicPremiumDouble
								extraLoading=extraLoadingDouble
								totalDB=totalDBDouble
								accidentalDB = accDBDouble
								totalCIB = totalCIBDouble
								totalPremium = basicPremiumDouble + extraLoadingDouble +totalDBDouble+accDBDouble+totalCIB;
								total = totalPremium
								sb << "</td>"
								sb << "<td style='text-align: right; border-right: 1px solid #000; padding-right: 3px;'>"
								sb << getFormatDoubleTwoDecimalWithComma(basicPremium)
								sb << "</td>"
								if tdbRider
									sb << "<td style='text-align: right; border-right: 1px solid #000; padding-right: 3px;'>"
									sb << getFormatDoubleTwoDecimalWithComma(totalDB)
									sb << "</td>"
								end
								if adbRider
									sb << "<td style='text-align: right; border-right: 1px solid #000; padding-right: 3px;'>"
									sb << getFormatDoubleTwoDecimalWithComma(accidentalDB)
									sb << "</td>"
								end
								if cibRider
									sb << "<td style='text-align: right; border-right: 1px solid #000; padding-right: 3px;'>"
									sb << getFormatDoubleTwoDecimalWithComma(totalCIB)
									sb << "</td>"
								end
								sb << "<td style='text-align: right; border-right: 1px solid #000; padding-right: 3px;'>"
								sb << getFormatDoubleTwoDecimalWithComma(total)
								sb << "</td>"
								sb << "</tr>"

								basicPremium = ""
								totalDB = ""
								accidentalDB = ""
								totalCIB = ""
								total = ""
							end
						end
						# code start for caveat
						if(isCalanderYearIllustration)
							totalDBPeriod = totalDBPeriod + currCalanderYear;
							accidentalDBPeriod = accidentalDBPeriod + currCalanderYear;
							#puts "++++++++++totalDBPeriod: #{totalDBPeriod}"
						end
						if(isAgeIllustration)
							totalDBPeriod = totalDBPeriod + issueAge;
							accidentalDBPeriod = accidentalDBPeriod + issueAge;
						end
						sb << "</table></div>"
						#p "==================outside if totalDBFlag: #{totalDBFlag}"
						if(totalDBFlag)
							sb << "<div class ='fontFamilyGFB fontSize11' style='padding-left:40px$SEMI$margin-top:10px' >* TDB premium payment terminates at "+noteDuration.to_s+" "+totalDBPeriod.to_i.to_s+".</div>"
						#puts "~~~~~~~~~~~~ #{totalDBFlag}"
						end

						if(accidentalDBFlag)
							padding = ""
							padding = "$SEMI$margin-top:10px" if (!totalDBFlag)
							sb << "<div class ='fontFamilyGFB fontSize11' style='padding-left:40px#{padding}'>^ ADB premium payment terminates at "+noteDuration.to_s+" "+accidentalDBPeriod.to_i.to_s+".</div>"
						end
						# code end for caveat
					end
					break
				end
			end
			sb << "</div>"
			#p "-----------------sb: #{sb}"
			return sb.to_s
	    end

	    # added new method to display signature and date in PDF by akshata
		def self.getSignatureImage(quotationIO)
	      	sb = ""
	      	# puts "quotationIO=====#{quotationIO}"
	      	# if ((System::get_property('platform') == 'ANDROID') || (System::get_property('platform') == 'APPLE'))
	      	#puts "quotationIO.baseDO.signature.to_s======= #{quotationIO.baseDO.signature.to_s}"
	        if quotationIO.baseDO.signature.to_s !="" && quotationIO.baseDO.signature.to_s !="SUCCESS"
	        	signatureString = deCompressSignatureImage(quotationIO.baseDO.signature.to_s)
	          	sb = "<img src='#{signatureString}' width='200' height='30'>"
	        end
	        return sb
			# 	else
			#   sb = ""
			#   return sb
			# end
	    end
#
		# method to decrypt signature by akshata
		def self.deCompressSignatureImage(compressedSignature)
			if compressedSignature != "" && !compressedSignature.start_with?('data:image/png;base64,')
			    compressed_signature = compressedSignature.gsub!('ZLIBCMP','')
			    signature_decoded = MobiSys::Encryption.decodeContents(compressed_signature)
			    inflatedString = MobiSys::Encryption.unZipData(signature_decoded)
			    signatureString = 'data:image/png;base64,' + MobiSys::Encryption.encodeContents(inflatedString)
			elsif compressedSignature != "" && compressedSignature.start_with?('data:image/png;base64,')
			    signatureString = compressedSignature
			end
			return signatureString.to_s
		end

		# method for QR Code by akshata
		def self.generateQRCode(mvelHashMap)
			if $showPdf == true
				quotationIO = mvelHashMap["quotationIO"]
				qrCodeText = quotationIO.baseDO.quotationRefNum
				inputHash = Hash.new
				imageName = "QR_" + quotationIO.baseDO.quotationRefNum + Random.rand(100000).to_s
				#puts "imageName===#{imageName}"
				filePath = Rho::RhoApplication.get_blob_folder + File::SEPARATOR + imageName + ".png"
				#puts "filePath===#{filePath}"
				inputHash["qrCodeText"] = qrCodeText
				inputHash["imageName"] = imageName
				inputHash["filePath"] = filePath
				#puts "inputHash===#{inputHash}"
				jsonStr = ::JSON.generate(inputHash)
				#puts "jsonStr===#{jsonStr}"
				cmdStr = "javaw -classpath #{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}pdf.jar;"
				cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}zxing-j2se-1.7.jar;"
				cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}zxing-core-1.7.jar;"
				cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}flexjson-2.1.jar;"
				cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}jcommon-1.0.21.jar;"
				cmdStr << " com.c2lbiz.mobisys.win32.QrCodeGenerator "
				cmdStr << jsonStr.gsub('"','\"').gsub(' ','$SPACE$')
				cmdStr << " #{filePath}"
				cmdStr << " #{qrCodeText}"
				cmdStr << " #{imageName}"
				# cmdStr << " 1>D:#{File::SEPARATOR}1.txt 2>C:#{File::SEPARATOR}2.txt" #to debug
				#puts "cmdStr1: #{cmdStr}"
				answer = system(cmdStr)
				#puts ">>>answer1: #{answer} errorStatus: #{$?}"
				return "<img src=\"#{imageName + ".png"}\"/>"
			else
				return ""
			end
		end

	def self.getPremiumScheduleTable(quotationIO,inRiderList,inMvelHashMap)
			#puts "inRiderList---> #{inRiderList.inspect}"
			# puts "quotationIO---> #{quotationIO.inspect}"
			# puts "inMvelHashMap---> #{inMvelHashMap.inspect}"
			mvelHashMap = inMvelHashMap
			outputPreferencesDO = mvelHashMap['outputPreferencesDO']
			riderList=inRiderList
			#p "--------------riderList: #{riderList}"
			productTerm= quotationIO.baseDO.getBaseProduct.productTerm.to_i
			sb = ""
			upperLimit=0;
			lowerLimit = 0;
			basicPremium="";
			extraLoading="";
			totalDB="";
			accidentalDB="";
			total ="";
			issueAge=quotationIO.baseDO.getPartyByRole("PRIMARY").age.to_i;
			totalDBPeriod = 0;
			accidentalDBPeriod=0;
			extraLoadingPeriod = 0;
			tdbRiderLoading =0;
			extraLoadingPeriodPolYear=0;
			currCalanderYear = mvelHashMap["calendarYear"].to_i
			totalDBFlag=false;
			extraLoadingFlag=false;
			accidentalDBFlag=false;
			isCalanderYearIllustration = false;
			isAgeIllustration = false;
			tableHeader = "Dur";
			noteDuration = "the end of duration";
		    if outputPreferencesDO != nil && outputPreferencesDO.field2 == "CALENDARYEAR"
				isCalanderYearIllustration=true;
				tableHeader="Year";
				noteDuration = "year";
			end
			if outputPreferencesDO != nil && outputPreferencesDO.field2 == "AGE"
				isAgeIllustration=true;
				tableHeader="Age";
				noteDuration = "attained age";
			end
			sb << "<div>"
			quotationIO.baseDO.QuotationProductList.each do |quotationProduct|
				if quotationProduct.productTypeCd == 'PLAN'
					#puts "if quotationProduct.productTypeCd == 'PLAN'"
					basicPremiumDouble = 0;
					extraLoadingDouble = 0;
					totalDBDouble = 0;
					accDBDouble = 0;
					totalPremium=0;
			        if quotationProduct.getExtraQuotationProducts.size > 0 && (quotationProduct.getExtraQuotationProducts[0].extraFlatAmt != nil  || (quotationProduct.getExtraQuotationProducts[0].extraPercent != nil  && quotationProduct.getExtraQuotationProducts[0].extraPercent > 1))
				                            #for BasePlan where Extra Loading is Selected
						sb << " <div class='SLF5yrtc' style='padding-left:-12%'>"
						sb << "<table align='center' class ='fontFamilyGFB fontSize12 SLFPremiumSchedTable' style='border: 1px solid black; margin-top: 10px; border-collapse:collapse;width:30%;margin-top:10px;border: 1px solid black;' cellspacing='0'>"
						sb << "<tr style='border: 1px solid black;'><td width='10%' class='fontFamilyATLBold fontSize14 header'>"+tableHeader+"</td>"
						sb << "<td class='fontFamilyATLBold fontSize14 header' width ='18%' style='border: 1px solid black;'>Premium</td></tr>"

						if quotationProduct.getExtraQuotationProducts[0].extraFlatAmt != nil && quotationProduct.getExtraQuotationProducts[0].extraFlatAmt != ""
							extraLoadingPeriod = quotationProduct.getExtraQuotationProducts[0].extraFlatDuration != nil ? quotationProduct.getExtraQuotationProducts[0].extraFlatDuration.to_i : 0
						end
						if quotationProduct.getExtraQuotationProducts[0].extraPercent != nil && quotationProduct.getExtraQuotationProducts[0].extraPercent != ""
							extraLoadingPeriod = quotationProduct.getExtraQuotationProducts[0].extraPercDuration != nil ? quotationProduct.getExtraQuotationProducts[0].extraPercDuration.to_i : 0
						end
						extraLoadingPeriodPolYear=extraLoadingPeriod;
						if(isCalanderYearIllustration)
							extraLoadingPeriod = extraLoadingPeriod + currCalanderYear;
						end
						if(isAgeIllustration)
							extraLoadingPeriod = extraLoadingPeriod + issueAge;
						end
						i = 1
						for i in (i..productTerm)

							if quotationIO.finalMap[i] != nil && (i-1)%5 == 0
								lowerLimit = i
								if i + 4 > productTerm
									upperLimit = productTerm
								else
									upperLimit = i + 4
								end
								basicPremiumDouble = quotationIO.finalMap[i]["basicpremiumcompute"]["0"] != nil ? quotationIO.finalMap[i]["basicpremiumcompute"]["0"] : 0
								extraLoadingDouble = quotationIO.finalMap[i]["extrapremiumcompute"]["0"] !=nil ? quotationIO.finalMap[i]["extrapremiumcompute"]["0"] : 0
								if quotationIO.finalMap[i]["ridermodalpremium"] != nil
									totalDBDouble = quotationIO.finalMap[i]["ridermodalpremium"]["0TDB of 5YRCT"] != nil ? quotationIO.finalMap[i]["ridermodalpremium"]["0TDB of 5YRCT"] : 0
								end
								if quotationIO.finalMap[i]["ridermodalpremium"] != nil
									accDBDouble = quotationIO.finalMap[i]["ridermodalpremium"]["0ADB of 5YRCT"] != nil ? quotationIO.finalMap[i]["ridermodalpremium"]["0ADB of 5YRCT"] : 0
								end

								if riderList.respond_to?('each')
									riderList.each do |rd|
										#p "------------rd.productId: #{rd.productId}"
										#p "------------rd.productTerm: #{rd.productTerm}"
										if totalDBPeriod == 0
											totalDBPeriod = rd.productId == "TDB of 5YRCT" ? rd.productTerm : 0
										end
										if(accidentalDBPeriod==0)
											accidentalDBPeriod=rd.productId == "ADB of 5YRCT" ? rd.productTerm : 0
										end
									end
								end
								totalDBIndicator = "";
								accidentalDBIndicator = "";
								extraLoadingIndicator = "";
								if(totalDBPeriod >= lowerLimit && totalDBPeriod < upperLimit)
									totalDBFlag = true;
									totalDBIndicator = "*";
								end
								if(accidentalDBPeriod >=lowerLimit && accidentalDBPeriod < upperLimit)
									accidentalDBFlag=true;
									accidentalDBIndicator="^";
								end
								if extraLoadingPeriodPolYear >= lowerLimit && (extraLoadingPeriodPolYear < upperLimit|| (upperLimit==productTerm&&upperLimit%5!=0))
									extraLoadingIndicator="#";
								end
								basicPremium=basicPremiumDouble
								if basicPremiumDouble != 0.0
									sb << "<tr>"
									sb << "<td style=' text-align: center; border-right: 1px solid #000;' >"

									if(isCalanderYearIllustration)
										lowerLimit = lowerLimit + currCalanderYear - 1;
										upperLimit = upperLimit + currCalanderYear - 1;
									end

									if(isAgeIllustration)
										lowerLimit = lowerLimit + issueAge - 1;
										upperLimit = upperLimit + issueAge - 1;
									end
									if(lowerLimit==upperLimit)
										sb << lowerLimit.to_s
									else
										sb << lowerLimit.to_s
										sb << " - "
										sb << upperLimit.to_s
									end
									# basicPremium=basicPremiumDouble
									sb << "</td>"
									sb << "<td style='text-align: right; border-right: 1px solid #000; padding-right: 3px;'>"
									sb << getFormatDoubleTwoDecimalWithComma(basicPremium)
									sb << "</td>"
									sb << "</tr>"
							   end
								basicPremium = "";
							end
				        end

			            if(isCalanderYearIllustration)
					     	totalDBPeriod = totalDBPeriod + currCalanderYear;
							accidentalDBPeriod = accidentalDBPeriod + currCalanderYear;
						end
						if(isAgeIllustration)
							totalDBPeriod = totalDBPeriod + issueAge;
							accidentalDBPeriod = accidentalDBPeriod + issueAge;
						end
						sb << "</table></div>"
						if(extraLoadingFlag)
							if(extraLoadingPeriod.to_i % 5) != 0 #SUNSS 2594
							sb << "<div class ='fontFamilyGFB fontSize11'  style='padding-left:40px$SEMI$margin-top:10px'># Extra premium payment terminates at "+noteDuration.to_s+" "+extraLoadingPeriod.to_i.to_s+".</div>"
							end
						end

						if(totalDBFlag)
							sb << "<div class ='fontFamilyGFB fontSize11' style='padding-left:40px' >* TDB premium payment terminates at "+noteDuration.to_s+" "+totalDBPeriod.to_i.to_s+".</div>"
						end
						if(accidentalDBFlag)
							sb << "<div class ='fontFamilyGFB fontSize11' style='padding-left:40px'>^ ADB premium payment terminates at "+noteDuration.to_s+" "+accidentalDBPeriod.to_i.to_s+".</div>"
						end
				    else

						#For BasePlan where Extra Loading is not Selected
						sb << " <div class='center SLF5yrtc'>"
						sb << "<table align='center' class= 'fontFamilyGFB fontSize12 SLFPremiumSchedTable' style='border: 1px solid black; margin-top: 10px; border-collapse:collapse;margin-top:10px;width:30%;margin-top:10px;border: 1px solid black;' cellspacing='0'>"
						sb << "<tr><td width='12%' class='fontFamilyATLBold fontSize14 header'style=\"border:1px solid black;\">"+tableHeader+"</td>"
						sb << "<td class='fontFamilyATLBold fontSize14 header' style=\"border:1px solid black;\"width ='22%'>Premium</td></tr>"
						i = 1
				        for i in (i..productTerm)
				        	#puts "else inside if for loop"
							if quotationIO.finalMap[i] != nil && (i-1)%5 == 0
								lowerLimit = i
								if i+4 > productTerm
									upperLimit = productTerm
								else
									upperLimit = i+4
								end
								basicPremiumDouble=quotationIO.finalMap[i]["basicpremiumcompute"]["0"] != nil ? quotationIO.finalMap[i]["basicpremiumcompute"]["0"] : 0
								if(quotationIO.finalMap[i]["ridermodalpremium"] != nil)
									totalDBDouble = quotationIO.finalMap[i]["ridermodalpremium"]["0TDB of 5YRCT"] != nil ? quotationIO.finalMap[i]["ridermodalpremium"]["0TDB of 5YRCT"] : 0
								end
								if(quotationIO.finalMap[i]["ridermodalpremium"] != nil)
									accDBDouble=quotationIO.finalMap[i]["ridermodalpremium"]["0ADB of 5YRCT"] != nil ? quotationIO.finalMap[i]["ridermodalpremium"]["0ADB of 5YRCT"] : 0
								end
								issueAge = quotationIO.baseDO.getPartyByRole("PRIMARY").age.to_i

                                     if riderList.respond_to?('each')
								 riderList.each do |rd|
									#p "------------rd.productId: #{rd.productId}"
									#p "------------rd.productTerm: #{rd.productTerm}"
									if totalDBPeriod == 0
									totalDBPeriod = rd.productId == "TDB of 5YRCT" ? rd.productTerm : 0
									end
									if(accidentalDBPeriod==0)
									accidentalDBPeriod=rd.productId == "ADB of 5YRCT" ? rd.productTerm : 0
									end
								  end
							    end

								totalDBIndicator = "";
								accidentalDBIndicator = "";


								if(totalDBPeriod >= lowerLimit && totalDBPeriod < upperLimit)
									totalDBFlag = true;
									totalDBIndicator = "*";
								end
								if(accidentalDBPeriod >=lowerLimit && accidentalDBPeriod < upperLimit)
									accidentalDBFlag=true;
									accidentalDBIndicator="^";
								end
								basicPremium=basicPremiumDouble
								extraLoading=extraLoadingDouble
								totalDB=totalDBDouble
								accidentalDB = accDBDouble
								totalPremium = basicPremiumDouble + extraLoadingDouble +totalDBDouble+accDBDouble;
								total = totalPremium
								if totalPremium != 0.0
									sb << "<tr>"
									sb << "<td style=' text-align: center; border-right: 1px solid #000;' >"
									if(isCalanderYearIllustration)
										lowerLimit = lowerLimit + currCalanderYear - 1;
										upperLimit = upperLimit + currCalanderYear - 1;
									end
									if(isAgeIllustration)

										lowerLimit = lowerLimit + issueAge - 1;
										upperLimit = upperLimit + issueAge - 1;
									end
									if(lowerLimit==upperLimit)
										sb << lowerLimit.to_s
									else
										sb << lowerLimit.to_s
										sb << " - "
										sb << upperLimit.to_s
									end
									# basicPremium=basicPremiumDouble
									# extraLoading=extraLoadingDouble
									# totalDB=totalDBDouble
									# accidentalDB = accDBDouble
									# totalPremium = basicPremiumDouble + extraLoadingDouble +totalDBDouble+accDBDouble;
									# total = totalPremium
									sb << "</td>"
									sb << "<td style='text-align: right; border-right: 1px solid #000; padding-right: 3px;'>"
									sb << getFormatDoubleTwoDecimalWithComma(basicPremium)
									sb << "</td>"
									sb << "</tr>"
								end
								basicPremium = "";
								totalDB = "";
								accidentalDB = "";
								total = "";
							end
						end
			            if(isCalanderYearIllustration)
							totalDBPeriod = totalDBPeriod + currCalanderYear;
							accidentalDBPeriod = accidentalDBPeriod + currCalanderYear;
						end
						if(isAgeIllustration)
							totalDBPeriod = totalDBPeriod + issueAge;
							accidentalDBPeriod = accidentalDBPeriod + issueAge;
						end
						sb << "</table></div>"
						if(totalDBFlag)
							sb << "<div class ='fontFamilyGFB fontSize11' style='padding-left:40px$SEMI$margin-top:10px' >* TDB premium payment terminates at "+noteDuration.to_s+" "+totalDBPeriod.to_i.to_s+".</div>"
						end
						if(accidentalDBFlag)
							padding = ""
							padding = "$SEMI$margin-top:10px" if (!totalDBFlag)
							sb << "<div class ='fontFamilyGFB fontSize11' style='padding-left:40px#{padding}'>^ ADB premium payment terminates at "+noteDuration.to_s+" "+accidentalDBPeriod.to_i.to_s+".</div>"
						end
					end
					break;
				end
			end
			sb << "</div>"
			#p "-----------------sb: #{sb}"
			return sb.to_s
	end

	def self.getApplicationProperty(propertyName)
		propertyVal = ""
		applicationProperty = OfflineApplication.find(:first, :conditions =>{{:name =>'PROPERTY'} =>propertyName.to_s})
		propertyVal = applicationProperty.value.to_s if applicationProperty
		return propertyVal.to_s
	end

	# method missing in offline for qrcode display - Deepak
	def self.getQuotationStatus(inMvelHashMap)
		mvelHashMap = inMvelHashMap
		quotationIO = mvelHashMap["quotationIO"]
		status = false
		 if(quotationIO.baseDO.quoteStatusCd.to_s != "" && (quotationIO.baseDO.quoteStatusCd.to_s == 'ACCEPTED' || quotationIO.baseDO.quoteStatusCd.to_s == 'SYNCDONE'))
		 	status = true
		 else
		 	status = false
		 end
		 return status
	end

	
	def self.getRateForPaymentMode(quotationIO)
		quotation = quotationIO.baseDO
		policyHolder = quotation.getPartyByRole("PROPOSER")
		returnRate = 1.0
		product = quotation.getBasePlan.getProduct
		baseProduct = quotation.getBasePlan
		paymentFrequency = baseProduct.paymentFrequencyCd
		premiumFacet = product.getFacet('PREMIUMDETAILS')
		offlinePremiumDetail = premiumFacet.OfflinePremiumDetailsList[0] if premiumFacet
		ruleSeq = nil
		if offlinePremiumDetail
			premiumModelCd = offlinePremiumDetail.premiumModelCd.to_s
			premiumModel = IllustrationModel.loadObject(:first, :conditions => {{ :name => 'modelCd' } => premiumModelCd})
			if premiumModel
				premiumModel.IllustrationFacetList.each do |illFacet|
					if (illFacet.computedElementName.to_s == 'modaldt')
						ruleSeq =  illFacet.ruleSeq
						break
					end
				end
			end
			allowPaymentModePds = MobiSys::ProductUtil.getProductDefinitionTableDO(ruleSeq, quotation, baseProduct, policyHolder) if ruleSeq
			returnRate = allowPaymentModePds.rate.to_f if allowPaymentModePds
		end
		return returnRate
	end

	def formatDoubleTwoDecimal(strToFormat) 
	    return MobiSys::UIGenUtilHelper.maskDecimal(strToFormat)
	end

	end
end
