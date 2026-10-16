require 'nokogiri'
xmlFile = File.open('EntityContext.xml')
doc = Nokogiri::XML(xmlFile)

expressions = {}
accessors = {}
isArray = {}
doc.xpath('//Expressions').each do |x|
	attri = x.attributes['name'].to_s
	expressions[attri] = "module #{attri}\n"
	accessors[attri] = []
	x.children.each do |child|
		if child.class==Nokogiri::XML::Element
			accessors[attri] << child['applyOn']
			if child['path'].to_s.index('$.')!=nil
				path = child['path'].split(" in ")
				isArray[child['name'].to_s] = true
				expressions[attri] << "\tdef self.#{child['name']}\n\t\tself."+child['applyOn']+"."+path[1].gsub("list","").gsub("DO","").gsub(")","")+".collect{|x| x.#{path[0].gsub("($.",'')}}\n\tend\n"
			elsif child['path'].to_s.index("||")!=nil
				paths = child['path'].split("||")
				expressions[attri] << "\tdef self.#{child['name']}\n"
				expressions[attri] << "\t\t"<<paths.collect{|path| "self."+child['applyOn']+"."+path}.join(" || ")
				expressions[attri] << "\n\tend\n"
			else
			expressions[attri] << "\tdef self.#{child['name']}\n\t\tself."+child['applyOn']+"."+child['path']+"\n\tend\n"
			end
		end
	end
	attributes = accessors[attri].uniq.join(',')
	expressions[attri] << "\tclass << self\n\t\tattr_accessor :#{accessors[attri].uniq.join(",:")}\n\tend\n"
	expressions[attri] << "\tdef self.setObject(#{accessors[attri].uniq.join(',').downcase})\n#{accessors[attri].uniq.collect{|x| "\t\tself."+x+'='+x.downcase }.join("\n")}\n\tend\n"
end


expressions.keys.each do |yz|
	expressions[yz] << "\tclass ValidationContexts"
	doc.xpath('//BusinessContext').each do |x|
		context = x.attributes
		property = x.children[1].attributes 
		if yz==context['refExpressions'].to_s
			expressions[yz] << "\n\t\tdef self."+context['name']
			if isArray[property['refExpression'].to_s]
				if property['value'].to_s.index(",")==nil
					expressions[yz] << "\n\t\t\t"+context['refExpressions'].to_s+"."+property['refExpression'].to_s+".include?('"+property['value']+"')"
				else
					expressions[yz] << "\n\t\t\t"+context['refExpressions'].to_s+"."+property['refExpression'].to_s+".size > ("+context['refExpressions'].to_s+"."+property['refExpression'].to_s+"-"+property['value'].to_s.split(",").inspect+").size"
				end
			elsif property['value'].to_s.index(",")==nil
				if property['value'].to_s.downcase=='true' || property['value'].to_s.downcase=='false'
					expressions[yz] << "\n\t\t\t"+context['refExpressions'].to_s+"."+property['refExpression'].to_s+"=="+property['value']
				else
					expressions[yz] << "\n\t\t\t"+context['refExpressions'].to_s+"."+property['refExpression'].to_s+"=='"+property['value']+"'"
				end
			else
				expressions[yz] << "\n\t\t\t"+property['value'].to_s.split(",").inspect+".include?("+context['refExpressions'].to_s+"."+property['refExpression'].to_s+")"
			end
			expressions[yz] << "\n\t\tend\n"
		end
	end
	expressions[yz] << "\tend\n"
end

expressions.each do |x,y|
	y<<"end\n"
end

file = File.open("entity_context.rb",'w')
expressions.values.each do |x|
	file.write x
end
file.close
xmlFile.close