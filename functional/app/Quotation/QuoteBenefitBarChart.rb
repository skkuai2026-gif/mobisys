require 'CommonModules/BaseSymChart'

module MobiSys	
	class QuoteBenefitBarChart < BaseSymChart
		def generateChart
			value = 0
			columnRowValueSet = {}
			termDataList = getFieldValue("si.SICalc.TermData")
			i = 0

			while i <= termDataList.size-1
				chosenFundCd = getFieldValue("si.Quotation.BasePlan.FundList[0].fundCd")
				localElementRate = "si.SICalc.TermData["+i.to_s+"]."+@addtnlCurrData1.to_s+"."+chosenFundCd+".MEDIUM"
				value = getFieldValue(localElementRate).to_f/1000
				columnRowValueSet[getFieldValue("si.SICalc.TermData["+i.to_s+"].Attainedage").to_s] = value;
				i = i + 10
			end
			return generateBarChart(columnRowValueSet, nil,"AGE", "THOUSANDS")
		end

		def renderChartInfo(config)
			config["chart.margin.left"] = 70
			config["chart.margin.top"] = 50
			config["chart.margin.bottom"] = 55
			config["chart.yaxis.title.pos"] = 0.22

			renderer = @addtnlCurrData2
			config["chart.colors"] = "['#{renderer}']"
			config["chart.yaxis.labels.count"] = "4"
			config["chart.background.grid.color"] = "'rgb(0,0,0)'"
			config["chart.background.grid.border"] = false
			config["chart.background.grid.linewidth"] = "2"
			config["chart.background.grid.autofit"] = true
			config["chart.background.grid.autofit.numhlines"] = "4"
			config["chart.key.position.y"] = 10
			config["chart.key.position.x"] = 20
			config["chart.background.grid.vlines"] = false
			config["chart.background.grid.autofit.numhlines"] = "4"
			config["chart.xaxis.tickmarks.last"] = false
			config["chart.yaxis"] = false
			

		end


	end
end