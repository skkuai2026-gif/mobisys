module MobiSys
	class ChartFactory
		def self.generateChart(chartName, vars, width, height, addtnlCurrData1,addtnlCurrData2,addtnlCurrData3)
			chartName = chartName.slice(0,1).capitalize + chartName.slice(1..-1)
			# require "MobiSys::QuoteBenefitBarChart"
			result = ""
			begin 
    			require "Quotation/#{chartName}"
    			isClassDefined = Object.const_defined?("MobiSys::QuoteBenefitBarChart")
				if Object.const_defined?("MobiSys::#{chartName}")
					objClass = Object.const_get("MobiSys::#{chartName}")
					obj = objClass.new
					result = obj.generate(vars,width,height, addtnlCurrData1,addtnlCurrData2,addtnlCurrData3)
				end
			rescue LoadError => e
			    puts "Quotation/#{chartName} not included"
			end
			return result
			
		end
	end
end