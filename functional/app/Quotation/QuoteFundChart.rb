require 'CommonModules/BaseSymChart'

module MobiSys	
	class QuoteFundChart < BaseSymChart
		def generateChart

			liFund = getFieldValue("si.Quotation.BasePlan.FundList")
			dataSet = {}
			colorSet = {}
			masterFundHM = getFieldValue("si.FundM")
			liFund.each do |fund, value|
				fundM = Fund.find(:first, :conditions=>{{:name => 'fundCd'} => fund.fundCd})
            	fundDesc = fundM.fundDesc
				dataSet[fundDesc] = fund.allocationPerc
				fundDO = masterFundHM[fund.fundCd]
				if fundDO && fundDO.addtnlFld1Str
					colorSet[fundDesc] = fundDO.addtnlFld1Str
				end
			end

			return generatePieChart(dataSet, nil, colorSet, true)
		end

		def renderChartInfo(config)
			liFund = getFieldValue("si.Quotation.BasePlan.FundList")
			renderer = ""
			pieLabelset = []
			liFund.each do |fd|
			  pieLabelset << "#{fd.allocationPerc.to_i}%"
			  if fd.fundCd == "SLPEF"
				renderer << "'rgb(85,127,168)'"
			  elsif fd.fundCd == "SLPBA"
				renderer << "'rgb(22,45, 50)'"
			  elsif fd.fundCd == "SLPBF"
				renderer << "'rgb(250, 182, 41)'"
			  elsif fd.fundCd == "TDF20"
				renderer << "'rgb(84, 110, 49)'"
			  elsif fd.fundCd == "TDF25"
				renderer << "'rgb(42, 81, 128)'"
			  elsif fd.fundCd == "TDF30"
				renderer << "'rgb(129, 115, 106)'"
			  elsif fd.fundCd == "TDF35"
				renderer << "'rgb(216, 99, 44)'"
				elsif fd.fundCd == "TDF40"
					renderer << "'rgb(148, 51, 55)'"
				elsif fd.fundCd == "SLPIF"
					renderer << "'rgb(250, 182, 41)'"
				elsif fd.fundCd == "SLPOF"
					renderer << "'rgb(22,45, 50)'"
				elsif fd.fundCd == "SLPGF"
					renderer << "'rgb(85,127,168)'"
				elsif fd.fundCd == "SLUIF"
					renderer << "'rgb(22,45, 50)'"
				elsif fd.fundCd == "SLUOF"
					renderer << "'rgb(250, 182, 41)'"
				elsif fd.fundCd == "SLUBF"
					renderer << "'rgb(85,127,168)'"
				elsif fd.fundCd == "SGFBA"
					renderer << "'rgb(22,45, 50)'"
				elsif fd.fundCd == "SGFBF"
					renderer << "'rgb(250, 182, 41)'"
				elsif fd.fundCd == "SGFEF"
					renderer << "'rgb(85,127,168)'"
				elsif fd.fundCd == "SGUIF"
					renderer << "'rgb(250, 182, 41)'"
				elsif fd.fundCd == "SGUOF"
					renderer << "'rgb(22,45, 50)'"
				elsif fd.fundCd == "SGFGF"
					renderer << "'rgb(85,127,168)'"
				elsif fd.fundCd == "SGFIF"
					renderer << "'rgb(250, 182, 41)'"
				elsif fd.fundCd == "SGFOF"
					renderer << "'rgb(22,45, 50)'"
				elsif fd.fundCd == "SLPGPF"
					renderer << "'rgb(254,85,85)'"
				elsif fd.fundCd == "SGFGPF"
					renderer << "'rgb(254,85,85)'"
			    # slocpi 5 extra fund changes start 
                elsif fd.fundCd == "SLPF1"
					renderer << "'rgb(0, 139, 139)'"
			    elsif fd.fundCd == "SLPF2"
					renderer << "'rgb(222, 184, 135)'"
			    elsif fd.fundCd == "SLPF3"
					renderer << "'rgb(186, 85, 211)'"
			    elsif fd.fundCd == "SLPF4"
					renderer << "'rgb(205, 133, 63)'"
			    elsif fd.fundCd == "SLPF5"
					renderer << "'rgb(255, 99, 71)'"
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
					renderer << "'rgb(84, 110, 49)'"
				elsif fd.fundCd == "TEMP" + getFieldValue("si.Quotation.BasePlan.productId").to_s
					if companyColour == "SLOCPI"
						renderer << "'rgb(85,127,168)'"
					else
						renderer << "'rgb(85,127,168)'"
					end

		  		end


			end
			renderer = renderer.gsub(")''",")','")
			config["chart.colors"] = "[#{renderer}]"
			config["chart.labels"] = "#{pieLabelset}"
			config["radius"] = "$(document).width() * 0.04"
			


		end
	end
end

