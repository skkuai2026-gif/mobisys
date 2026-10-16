module MobiSys
	class BaseSymChart
		@vars = {}
		@addtnlCurrData1 = nil
		@addtnlCurrData2 = nil
		@addtnlCurrData3 = nil
		@width = 0
		@height = 0

		def generate(vars, width, height, addtnlCurrData1,addtnlCurrData2,addtnlCurrData3)
			@vars = vars
			@width = width
			@height = height
			@addtnlCurrData1 = addtnlCurrData1
			@addtnlCurrData2 = addtnlCurrData2
			@addtnlCurrData3 = addtnlCurrData3
			return generateChart()
		end

		def generatePieChart(dataSet, title, colorSet, legend)
			config = {}
			renderChartInfo(config)
			pieDataset = dataSet.values
			canName = 'myCanvas_'+Random.rand(2500000).to_s
			divName = Random.rand(2500000).to_s + "_rGraph"
			htmlStr = "<html>"
			htmlStr << "<script type='text/javascript' src='http://127.0.0.1:9000/public/jquery/jquery-3.7.1.min.js'></script>"
			htmlStr << "<script type='text/javascript' src='http://127.0.0.1:9000/public/js/RGraph/RGraph.bar.js'></script>"
			htmlStr << "<script type='text/javascript' src='http://127.0.0.1:9000/public/js/RGraph/RGraph.line.js'></script>"
			htmlStr << "<script type='text/javascript' src='http://127.0.0.1:9000/public/js/RGraph/RGraph.common.core.js'></script>"
			htmlStr << "<script type='text/javascript' src='http://127.0.0.1:9000/public/js/RGraph/RGraph.pie.js'></script>"
			htmlStr << "<script type='text/javascript' src='http://127.0.0.1:9000/public/js/RGraph/RGraph.common.key.js'></script>"
			htmlStr << "<img name='graph_png' src =\"\">"
			htmlStr << "<div name=\"mainWrapper\">"
			htmlStr << "<div  style =\"background-color: rgb(255,235,191)\">"
			htmlStr << "<script type=\"text/javascript\">$('div[name=\"#{divName}\"]').html('<div class=\"graphWrapper\" style = \"height:'+ $(document).width() * 0.27 +'px\">');</script>"
			htmlStr << "<div name=\"#{divName}\" style =\"width:80%;\">"
			htmlStr << "</div>"
			htmlStr << "</div>"
			htmlStr << "</div>"
			htmlStr << "</div>"
			htmlStr << "<script type=\"text/javascript\">"
			htmlStr << "$(document).ready(function(){"
			htmlStr << "$('div[name=\"#{divName}\"]').css(\"margin-left\", $(document).width() * 0.01 + \"px\");"
			htmlStr << "$('div[name=\"#{divName}\"]').html(\"<canvas id='#{canName}' name='#{canName}' width='\"+ $(document).width() * 0.25 +\"px' height='\"+ $(document).width() * 0.25 +\"px'>[No canvas support]</canvas>\");"
			htmlStr << "$('div[name=\"#{divName}\"]').trigger('create');"
			htmlStr << "myGraph = new RGraph.Pie('#{canName}', #{pieDataset});"
		  	htmlStr << "myGraph.Set('chart.text.accessible', false);"
			config.each do |key, value|
				htmlStr << "myGraph.Set('#{key}', #{value});"
			end
			htmlStr << "myGraph.Draw();"
			htmlStr << "RGraph.Register(myGraph);"
			htmlStr << "image_data = myGraph.canvas.toDataURL('image/png');"
			htmlStr << "$('img[name=\"graph_png\"').attr('src',image_data);"
			htmlStr << "imageElement = $(\"img[name='graph_png']\");"
			htmlStr << "$(\"canvas\").replaceWith(imageElement);"
			htmlStr << "});"
			htmlStr << "</script>"
			htmlStr << "</html>"



			$graphHtmlCounter = $graphHtmlCounter+1
			placeHolder = "$graphHtml_#{$graphHtmlCounter}$"

			$graphHtmlHM[placeHolder] = htmlStr

			return placeHolder


		end

		def generateBarChart(columnRowValueSet, title, categoryAxisLabel, valueAxisLabel)
			config = {}
			renderChartInfo(config)
			age_x = columnRowValueSet.keys
			finalValue_y = columnRowValueSet.values
			maxValue = finalValue_y.max
			divName = Random.rand(2500000).to_s + "_rGraph"
			canName = 'myCanvas_'+Random.rand(2500000).to_s
			htmlStr = "<html>"
			htmlStr << "<script type='text/javascript' src='http://127.0.0.1:9000/public/jquery/jquery-3.7.1.min.js'></script>"
			htmlStr << "<script type='text/javascript' src='http://127.0.0.1:9000/public/js/RGraph/RGraph.bar.js'></script>"
			htmlStr << "<script type='text/javascript' src='http://127.0.0.1:9000/public/js/RGraph/RGraph.line.js'></script>"
			htmlStr << "<script type='text/javascript' src='http://127.0.0.1:9000/public/js/RGraph/RGraph.common.core.js'></script>"
			htmlStr << "<script type='text/javascript' src='http://127.0.0.1:9000/public/js/RGraph/RGraph.pie.js'></script>"
			htmlStr << "<script type='text/javascript' src='http://127.0.0.1:9000/public/js/RGraph/RGraph.common.key.js'></script>"
			htmlStr << "<div name=\"mainWrapper\">"
			htmlStr << "<img name='graph_png' src =\"\">"
			htmlStr << "<div  style =\"background-color: rgb(255,235,191)\">"
			htmlStr << "<script type=\"text/javascript\">$('div[name=\"#{divName}\"]').html('<div class=\"graphWrapper\" style = \"height:'+ $(document).width() * 0.27 +'px\">');</script>"
			htmlStr << "<div name=\"#{divName}\" style =\"width:70%;\">"
			htmlStr << "</div>"
			htmlStr << "</div>"
			htmlStr << "</div>"
			htmlStr << "</div>"
			htmlStr << "<script type=\"text/javascript\">"
			htmlStr << "$(document).ready(function(){"
			htmlStr << "$('div[name=\"#{divName}\"]').css(\"margin-left\", $(document).width() * 0.025 + \"px\");"
			htmlStr << "$('div[name=\"#{divName}\"]').html(\"<canvas id='#{canName}' name='#{canName}' width='\"+ $(document).width() * 0.25 +\"px' height='\"+ $(document).width() * 0.25 +\"px' >[No canvas support]</canvas>\");"
			htmlStr << "$('div[name=\"#{divName}\"]').trigger('create');"
			htmlStr << "myGraph = new RGraph.Bar('#{canName}', #{finalValue_y});" #.on('draw', function (obj)"
		  	htmlStr << "myGraph.Set('chart.xaxis.labels', #{age_x});"
		  	htmlStr << "myGraph.Set('chart.text.accessible', false);"

			config.each do |key, value|
				htmlStr << "myGraph.Set('#{key}', #{value});"
			end
			
			htmlStr << "myGraph.Draw();"
			htmlStr << "RGraph.Register(myGraph);"
			htmlStr << "image_data = myGraph.canvas.toDataURL('image/png');"
			htmlStr << "$('img[name=\"graph_png\"').attr('src',image_data);"
			htmlStr << "imageElement = $(\"img[name='graph_png']\");"
			htmlStr << "$(\"canvas\").replaceWith(imageElement);"
			htmlStr << "});"
			htmlStr << "</script>"
			htmlStr << "</html>"


			$graphHtmlCounter = $graphHtmlCounter+1
			placeHolder = "$graphHtml_#{$graphHtmlCounter}$"

			$graphHtmlHM[placeHolder] = htmlStr

			return placeHolder
		end

		def generateStackedBarChart(dataset, title, categoryAxisLabel, valueAxisLabel)

		end

		def getFieldValue(fieldExpr)
			eval("@vars." + fieldExpr)
		end
	end
end