require 'CommonModules/BaseSymChart'

module MobiSys	
	class QuoteBenefitStackedBarChart < BaseSymChart
		def generateChart
			dataset = {}
			termDataList = getFieldValue("si.SICalc.TermData")
			i = 0
			while i <= termDataList.size-1
				termData = getFieldValue("si.SICalc.TermData["+i.to_s+"]")
				attainedageValue = getFieldValue("Attainedage",termData).to_i
				guaranteedValue = getFieldValue(@addtnlCurrData1.to_s,termData).to_f / 1000
				dataset["guaranteedValue"] = guaranteedValue
				dataset["attainedageValue"] = attainedageValue

				totalValue = getFieldValue(@addtnlCurrData2.to_s, termData).to_f / 1000
				nonGuaranteedValue = totalValue - guaranteedValue
				dataset["nonGuaranteedValue"] = nonGuaranteedValue
				i = i + 5
			end

			return generateStackedBarChart(dataset, nil, "AGE", "THOUSANDS")

		end

		def renderChartInfo(config)
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

			config["chart.xaxis.title"] = "AGE"
			config["chart.yaxis.title"] = "THOUSANDS"
			config["chart.margin.left"] = 70
			config["chart.margin.bottom"] = 55
			config["chart.margin.top"] = 50
			config["chart.yaxis.title.pos"] =0.22
			config["chart.colors"] = "['#{renderer}']"
			config["chart.grouping"] = "stacked"
			config["chart.yaxis.labels.count"] = "5"
			config["chart.background.grid.color"] = "'rgb(0,0,0)'"
			config["chart.background.grid.border"] = false
			config["chart.background.grid.linewidth"] = 2
			config["chart.background.grid.autofit"] = true
			config["chart.background.grid.hlines.count"] = 5
			config["chart.background.grid.vlines"] = false
			config["chart.key"] = "['GUARANTEED','NON-GUARANTEED']"
			config["chart.key.colors"] = "['#{keyRenderer}']"
			config["chart.key.position"] = "margin"
			config["chart.key.labels.size"] = 6
			config["chart.key.position.y"] = 10
	  		config["chart.key.position.x"] = 20
			config["chart.key.background"] = "'rgba(255,255,255,0.7)'"
			config["chart.key.position.margin.boxed"] = true
			config["chart.xaxis.tickmarks.last"] = false
			config["chart.yaxis"] = false

		end


	end
end
