require 'rexml/document'

begin
	if Rho::System.platform == 'WINDOWS_DESKTOP' || Rho::System.isRhoSimulator
		sourceFile = File.open("#{Rho::Application.get_blob_folder}EntityContext.xml")
	else
		sourceFile = File.open("#{Rho::Application.userFolder}EntityContext.xml")
	end
rescue Exception => e
	sourceFile = File.open("#{Rho::RhoApplication.get_model_path('app', 'CommonModules')}EntityContext.xml")
end
doc = REXML::Document.new(sourceFile)

expressions = {}
accessors = {}
isArray = {}
REXML::XPath.each(doc, '//Expressions').each do |x|
	attri = x.attributes['name'].to_s
	expressions[attri] = "module #{attri}\n"
	accessors[attri] = []
	x.elements.each do |child|
		if child.class==REXML::Element
			accessors[attri] << child.attributes['applyOn']
			child.attributes['path'].gsub!("==null",".to_s==''")
			child.attributes['path'].gsub!("!=null",".to_s!=''")
			if child.attributes['path'].to_s.index('$.')!=nil
				path = child.attributes['path'].split(" in ")
				isArray[child.attributes['name'].to_s] = true
				expressions[attri] << "\tdef self.#{child.attributes['name']}\n"
				expressions[attri] << "\t\tif self."+child.attributes['applyOn']+"!=nil\n"
				expressions[attri] << "\t\t\tself."+child.attributes['applyOn']+"."+path[1].gsub("list","").gsub("DO","").gsub(")","")+".collect{|x| x.#{path[0].gsub("($.",'')}}\n"
				expressions[attri] << "\t\tend\n"
				expressions[attri] << "\tend\n"
			elsif child.attributes['path'].to_s.index("||")!=nil
				paths = child.attributes['path'].split("||")
				expressions[attri] << "\tdef self.#{child.attributes['name']}\n"
				expressions[attri] << "\t\tif "
				expressions[attri] << paths.collect{|path| "self."+child.attributes['applyOn']+"!=nil"}.uniq.join(" && ")
				expressions[attri] << "\n\t\t\t"
				expressions[attri] << paths.collect{|path| "self."+child.attributes['applyOn']+"."+path}.join(" || ")
				expressions[attri] << "\n\t\tend\n"
				expressions[attri] << "\tend\n"
			else
				expressions[attri] << "\tdef self.#{child.attributes['name']}\n"
				expressions[attri] << "\t\tif self."+child.attributes['applyOn']+"!=nil\n"
				expressions[attri] << "\t\t\tself."+child.attributes['applyOn']+"."+child.attributes['path']+"\n"
				expressions[attri] << "\t\tend\n"
				expressions[attri] << "\tend\n"
			end
		end
	end
	expressions[attri] << "\tclass << self\n"
	expressions[attri] << "\t\tattr_accessor :#{accessors[attri].uniq.join(",:")}\n"
	expressions[attri] << "\tend\n"


	attributes = accessors[attri].uniq.collect{|x| x.downcase + "=nil" }.join(",")
	expressions[attri] << "\tdef self.setObject(*args)\n"
	expressions[attri] << "\t\targs.each do |param|\n"
	expressions[attri] << "\t\t\tcase param.class.to_s\n"
	expressions[attri] << "#{accessors[attri].uniq.collect{|x| "\t\t\twhen '"+x+"'\n\t\t\t\tself."+x+'=param' }.join("\n")}"
	expressions[attri] << "\n\t\t\tend\n"
	expressions[attri] << "\t\tend\n"
	expressions[attri] << "\tend\n"
end


expressions.keys.each do |yz|
	expressions[yz] << "\tclass ValidationContexts"
	# Hardcoding OFFLINE context
	expressions[yz] << "\n\t\tdef self.OFFLINE"
	expressions[yz] << "\n\t\t\ttrue"
	expressions[yz] << "\n\t\tend\n"
	REXML::XPath.each(doc, '//BusinessContext').each do |x|
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

fileName = "#{Rho::Application.userFolder}entity_context.rb"
file = File.open(fileName,'w')
expressions.values.each do |x|
	file.write x
end
genericSet = "module GenericSet\n"
genericSet << "\tclass << self\n"
genericSet << "\t\tattr_accessor :currentObject\n"
genericSet << "\tend\n"
genericSet << "\tdef self.setObject(param)\n"
genericSet << "\t\tself.currentObject=param\n"
genericSet << "\tend\n"
genericSet << "\tclass ValidationContexts\n"
genericSet << "\tend\n"
genericSet << "end\n"
file.write genericSet
file.close

if Rho::System.platform != "APPLE"
	seq = RubyVM::InstructionSequence.compile_file(fileName)
	arr = seq.to_a
	newName = fileName.sub('.rb','.iseq')
	fseq = File.new(newName, 'w')
	Marshal.dump(arr,fseq)
	fseq.close
end


sourceFile.close()

def generateEntityTypeJS
	begin
		fileBuffer = "var arrEntity=new Array();"
		entityTypeMaster = EntityType.loadObject(:all)
		entityTypeMaster.each_with_index do |entityType,index|
			fileBuffer << "\nvar entity#{index}= new EntityType();"
			fileBuffer << "\nentity#{index}.entityTypeName='#{entityType.entityFieldTypeCd}';"
			fileBuffer << "\nentity#{index}.dataType='#{entityType.dataTypeCd}';"
			entityType.EntityPropertyList.each do |entityProperty|
				case entityProperty.propertyCd
				when 'BLACKLISTCHARS'
					fileBuffer << "\nentity#{index}.blacklistChars='#{entityProperty.propertyValue}';"
				when 'WHITELISTCHARS'
					fileBuffer << "\nentity#{index}.whitelistChars='#{entityProperty.propertyValue}';"
				when 'MAXLENGTH'
					fileBuffer << "\nentity#{index}.maxLength=#{entityProperty.propertyValue};"
				when 'MINVALUE'
					fileBuffer << "\nentity#{index}.minValue='#{entityProperty.propertyValue}';"
				when 'MAXVALUE'
					fileBuffer << "\nentity#{index}.maxValue='#{entityProperty.propertyValue}';"
				when 'EXTENDSENTITYTYPE'
					fileBuffer << "\nentity#{index}.extendsEntityType='#{entityProperty.propertyValue}';"
				when 'MINLENGTH'
					fileBuffer << "\nentity#{index}.minLength=#{entityProperty.propertyValue};"
				end
			end
			fileBuffer << "\narrEntity[#{index}] = entity#{index};"
		end
		fileBuffer << "\nthis.arrObj=arrEntity;"
		

		fileBuffer << "\n\n\n\n\n//Error Labels"
		errorLabelKeyArr = ['ERR_WARNINGMANDATORY','ERR_INVALIDWARNING','ERR_REQUIREDPRD','ERR_CHECKSIZE','ERR_NOTALLOW','ERR_CHECKGREATER','ERR_CHECKLESSER','ERR_INVALID','stringValue','integer','date','number','characters','Email','ERR_PLZSELECT','PLEASE_SELECT_PRODUCT_FAMILY','PLEASE_SELECT_PRODUCT','ERR_PLZENTER_PERCENTAGE','REQUIRENETWORK','productVersion','planOptionCd','TOEMAILMANDATORY','ERR_DEL_SUPPLEMENTARY','ERR_DEL_RIDER','ERR_PLZENTER_ONLINESERVER_URL','ERR_PLZCOMPLETE_SIGNATURE','ACCEPTED','SYNCDONE','CLOSED','COMPLETE','COMPLETED','ERR_MINLENGTH']
		errorLabelMaster = LabelValue.find(
			:all,
			:conditions => {
				{
					:name => 'key',
					:op => 'IN'
				} =>errorLabelKeyArr
			},
			:select => ['key','value','lang']
		)
		errorLabelKeyArr.each do |errorLabel|
			fileBuffer << "\nthis.#{errorLabel} = new Object();"
		end
		errorLabelMaster.each do |errorLabel|
			fileBuffer << "\nthis.#{errorLabel.key}.#{errorLabel.lang} = \"#{errorLabel.value}\";"
		end

		fileName = "#{Rho::Application.userFolder}EntityType.js"
		file = File.open(fileName,'w')
		file.write fileBuffer
		file.close
	rescue Exception => e
		Rho::Log.error("Error in generateEntityTypeJS--->#{e}\n#{e.backtrace}", "ContextGenerator_rexml")
	end
end