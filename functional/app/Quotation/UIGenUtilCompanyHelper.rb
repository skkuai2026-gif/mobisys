require 'CommonModules/mobisysbrowserhelper'
#require 'CommonModules/mobisysbrowserhelper_company'

module MobiSys

	class UIGenUtilCompanyHelper

		include Singleton
		include MobiSys::BrowserHelper
		
		def self.roundingTableData(number)
			return MobiSys::UIGenUtilHelper.maskDecimal(number)
		end
		
		def self.getRiders(mvelHashMap, startFromRider, totalNummberOfRiders)
			htmlString = ""
			riderList = mvelHashMap['riderList']
			if riderList
				htmlString << "<Table style=\"border-collapse:collapse;\" class=\"fontSize10 fontFamily\" width=\"100%\"> <tr> "
				htmlString << "<th colspan=3 ; style=\"text-align:center\" > <p> Annualized Premium of Supplementary Benefits </p> <th> </tr> <tr> "
				htmlString << " <th style=\"text-align:center;border:1px solid black;padding:1px;\" width=\"20%\">Attained Age</th>"

				i = 1
				riderList.each do |quotationProduct|
					if i == startFromRider and startFromRider <= totalNummberOfRiders
						htmlString << "<th style=\"text-align:center;border:1px solid black;padding:1px;\" width=\"20%\">#{mvelHashMap['quotationProductDORiderHashMap'][quotationProduct.productId].longName}</th>"
						startFromRider += 1
					end	
					i += 1
				end
				htmlString << "</tr></tr>"	
			end	
			return htmlString
		end	

		def self.getPolicyYearCondition(quotationIO)
			policyYear = ""
			if quotationIO.baseDO and quotationIO.baseDO.getBaseProduct and quotationIO.baseDO.getBaseProduct.pdfPeriod
				value = ""
				quotationIO.baseDO.getBaseProduct.pdfPeriod.to_i.times do |i|
					value << (i + 1).to_s << ","
				end	
			end
			policyYear = value[0,value.length - 1]	
		end
		
		def self.getRidersElements(mvelHashMap,startFromRider, totalNummberOfRiders)
			htmlString = nil
			htmlElementString = nil
			riderList = mvelHashMap['riderList']
			if riderList
				htmlString = "element${SLAttainedage"
				htmlElementString = "}$element rate${0"
				i = 1
				riderList.each do |quotationProduct|
					if i == startFromRider and startFromRider <= totalNummberOfRiders
						htmlString << ",Riderpremium"
						htmlElementString	<< ",0#{quotationProduct.productId}"
						startFromRider += 1
					end	
					i += 1
				end
				htmlString << htmlElementString << "}$rate max${25}$max tdStyle${style=\"border:1px solid black;text-align:center;font-size:14px;padding:1px\", style=\"border:1px solid black;text-align:right;font-size:14px;padding:1px\", style=\"border:1px solid black;text-align:right;font-size:14px;padding:1px\"}$tdStyle"
			end	
			return htmlString
		end

		def self.generateChart(quotationIO, totalDeathBenefit , totalCashValue, premiumPaid)
			tdb = [ ]
			tcv = [ ]
			tpp = [ ]
			quotationIO.finalMap.each do |i|
				tdb.push(i[1][totalDeathBenefit]["0"])
				tcv.push(i[1][totalCashValue]["0"])
				tpp.push(i[1][premiumPaid]["0"])
			end
			keys = [totalDeathBenefit, totalCashValue, premiumPaid].map{|i| MobiSys::BrowserHelper.getLabel(i.upcase)}
			gLeftPos = 100
			interval = (tdb.size/10.to_f) < 1 ? 1 : (tdb.size/10)
			divName = Random.rand(2500000).to_s + "_rGraph" 
			htmlStr = "<div class=\"graphWrapper\" style = \"height:400px\">"
			htmlStr << "<div name=\"#{divName}\" style =\"width:80%;\">"
			htmlStr << "</div>"
			htmlStr << "</div>"
			htmlStr << "<script type=\"text/javascript\">"
			htmlStr << "$(document).ready(function(){"
			htmlStr << "$('div[name=\"#{divName}\"]').css(\"margin-left\", $(document).width() * 0.18 + \"px\");"
			htmlStr << "$('div[name=\"#{divName}\"]').html(\"<canvas id='myCanvas' name='myCanvas' width='\"+ $(document).width() * 0.6 +\"px' height='400px'>[No canvas support]</canvas>\");"
			htmlStr << "$('div[name=\"#{divName}\"]').trigger('create');"
			htmlStr << "var xLabel = new Array();"
			htmlStr << "for (var i = 0; i <= #{tdb.size} ; i += #{interval}){"
			htmlStr << "xLabel.push('' + i + '');}"
			htmlStr << "myGraph = new RGraph.Line('myCanvas', #{tdb}, #{tcv}, #{tpp});"
			htmlStr << "myGraph.Set('key', #{keys});"
			htmlStr << "myGraph.Set('key.position.x', #{(gLeftPos + 50)});"
			htmlStr << "myGraph.Set('labels', xLabel);"
			htmlStr << "myGraph.Set('colors', ['red', 'black', 'orange']);"
			htmlStr << "myGraph.Set('linewidth', 2);"
			htmlStr << "myGraph.Set('hmargin', 15);"
			htmlStr << "myGraph.Set('key.position', 'graph');"
			htmlStr << "myGraph.Set('key.shadow', true);"
			htmlStr << "myGraph.Set('key.shadow.offsetx', 0);"
			htmlStr << "myGraph.Set('key.shadow.offsety', 0);"
			htmlStr << "myGraph.Set('key.shadow.blur', 15);"
			htmlStr << "myGraph.Set('key.shadow.color', '#ccc');"
			htmlStr << "myGraph.Set('background.grid.autofit', true);"
			htmlStr << "myGraph.Set('background.color', 'white');"
			htmlStr << "myGraph.Set('title.xaxis', '" + MobiSys::BrowserHelper.getLabel("policyYear") + "');"
			htmlStr << "myGraph.Set('title.yaxis', '" + MobiSys::BrowserHelper.getLabel(quotationIO.baseDO.getBaseProduct.currencyCd) + "');"
			htmlStr << "myGraph.Set('title.xaxis.bold', false);"
			htmlStr << "myGraph.Set('title.yaxis.bold', false);"
			htmlStr << "myGraph.Set('title.xaxis.font', 'Agenda');"
			htmlStr << "myGraph.Set('title.yaxis.font', 'Agenda');"
			htmlStr << "myGraph.Set('gutter.left', #{gLeftPos});"
			htmlStr << "myGraph.Set('gutter.bottom', 50);"
			htmlStr << "myGraph.Draw();"
			htmlStr << "RGraph.Register(myGraph);"
			htmlStr << "});"
			htmlStr << "</script>"
			return htmlStr
		end	

	end


end

require 'Quotation/UIGenUtilCompanyHelper_company'