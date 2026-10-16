require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper'
require 'CommonModules/commonutil'
require 'rho/rhoevent.rb'
require 'date'
require 'CommonModules/mobisysuihelper_jazz'

class FNARequestController < Rho::RhoController
    include BrowserHelper
    include MobiSys::BrowserHelper
    include MobiSys::UIHelper

	def newFNA
		@fnaRequest = FNARequest.new
		@fnaProposer = FNAParty.new(:partyRoleCd => "PROPOSER")
        @fnaRequest.addFNAParty(@fnaProposer)

        @fnaInsured = FNAParty.new(:partyRoleCd => "PRIMARY")
        @fnaRequest.addFNAParty(@fnaInsured)

        @agentRegdetails =AgentReg.getCurrentAgentReg
        @fnaRequest = setAgentDetails(@fnaRequest, @agentRegdetails)
        @fnaRequest.requestDt = getScreenDate(Time.now.to_s)

		render :action => :FNACapture_jazz, :layout => :jazzLayout
	end

	def setAgentDetails(fnaRequest, agentRegdetails)
        if agentRegdetails != nil
            fnaRequest.agentId = agentRegdetails.agentId
        end
        fnaRequest
    end

	def search
		@searchResultList = {}
		if !@params.empty?
            mainSearchField = @params['mainSearchField']
            fnaNum = @params['fnaNum']
            firstName1 = @params['firstName1']
            lastName1 = @params['lastName1']


           	fnaRequestList = FNARequest.loadObject(
                :count => '200',
                :order => 'fnaNum', 
                :orderdir => 'DESC',
                :select => ['fnaNum', 'requestDt', 'statusCd', 'object']
            )

            fnaRequestList.each do |fnaRequest|
                proposer = fnaRequest.getParty("PROPOSER")
                validFNA = true

                if mainSearchField != ""
                    unless fnaRequest.fnaNum.to_s.include?(mainSearchField) || proposer.firstName1.to_s.include?(mainSearchField) || proposer.lastName1.to_s.include?(mainSearchField)
                        validFNA = false
                    end
                else
                    if fnaNum != ""
                        validFNA = false unless fnaRequest.fnaNum.to_s.include?(fnaNum)
                    end
                    
                    if firstName1 != "" && validFNA
                        validFNA = false unless proposer.firstName1.to_s.include?(firstName1)
                    end
                    
                    if lastName1 != "" && validFNA
                        validFNA = false unless proposer.lastName1.to_s.include?(lastName1)
                    end
                end

                if validFNA
                    @searchResultList[fnaRequest.object] = [fnaRequest.fnaNum.to_s,proposer.firstName1.to_s,proposer.lastName1.to_s]
                end
            end
        end
		render :action => :FNASearch_jazz, :layout => :jazzLayout
	end

	def show
		id = @params['id'][1..-1].chop
		@fnaRequest = FNARequest.loadObject( :first, :conditions => { :object => id } )
		@fnaProposer = @fnaRequest.getParty("PROPOSER")
		@fnaInsured = @fnaRequest.getParty("PRIMARY")
		render :action => :FNACapture_jazz, :layout => :jazzLayout
	end

	def getQuestionnaireCheckbox(lookupkey, fieldname, selectedvalue, object=nil, lookupdata=nil, adhocContent=nil, questionResponseIndex)
		questionResponseIndex = questionResponseIndex + 1
		if(lookupkey != DYNAMICLOOKUP)
			lookups = Lookupvalue.find(:all,
				:conditions=>{
					'key'=>lookupkey
					},
					:order=>'sortOrder',
					:orderdir=>'ASC'
					)
		else
			lookups = lookupdata
		end       
		returnStr = ""
		radioName = ""
		lookup_name = ""
		begin
			if fieldname!=nil
				lookup_name = fieldname
			else
				lookup_name = lookupkey
			end
			fieldname = $objectMapping[object.object.to_s]+"["+lookup_name+"]" unless object.nil?
			if lookups.size > 1
				returnStr << renderHiddenField('fnaQuestionLookupDataCd', object.fnaQuestionLookupDataCd, 'fnaQuestionLookupDataCd', object)
				lookups.each_with_index do |lookup,index|
					returnStr << "<div class='add-fna-data-full'> "
					returnStr << " <input type='checkbox' name='#{fieldname}#{index}' id='#{fieldname}#{index}' value='#{lookup.cd}'"
					returnStr << " checked='checked'" if ( selectedvalue.is_a?(Array) && ( selectedvalue.include?(lookup.cd.to_s) ) )
					returnStr << "onClick='javascript:checkBoxClicked(this);' "
					returnStr << "/>"
					returnStr << " <label for='#{fieldname}#{index}' style='padding-top:15px;'></label>"
					labelforQuestion = "#{Localization::LabelCache.instance.getLabel(lookup.desc.to_sym)}".force_encoding(Encoding::UTF_8)
					returnStr << labelforQuestion.gsub("___________________________","\t"+renderInputField('responseValue',object.responseValue,'others',object, ' maxlength="50" style="width:31%; border: 1px; border-style: solid; border-color: grey;" data-role="none"'))
					# returnStr << "<br/>"
					returnStr << "</div>"
				end
			else
				# labelforQuestion = "#{Localization::LabelCache.instance.getLabel(lookups[0].desc.to_sym)}".force_encoding(Encoding::UTF_8)
				# returnStr << labelforQuestion.gsub("___________________________","\t"+renderAmountField('responseValue',object.responseValue,'responseValue',object, 'maxlength="10" style="width:61%;"'))
				# returnStr << attachMask("#{getObjectMapping(object)}[responseValue]")
			end
			# returnStr << "\n<script>\n"
			# returnStr << "$('[name=\""+$objectMapping[object.object.to_s]+"[others]\"]').blur(function() {\n"
			# returnStr << "  if(this.value!=\"\" && $(this).prev().find('input:checked').size()==0) {\n"
			# returnStr << "    $(this).prev().find('label').trigger('click');\n"
			# returnStr << "  } else if(this.value==\"\" && $(this).prev().find('input:checked').size()==1)  {\n"
			# returnStr << "    $(this).prev().find('label').trigger('click');\n"
			# returnStr << "  }\n"
			# returnStr << "})\n"
			# returnStr << "$('[id*=\""+fieldname+"\"]').change(function() {\n"
			# returnStr << "  if($(this).parent().next().attr('name') == \""+$objectMapping[object.object.to_s]+"[others]\" && !$(this).is(':checked')) {\n"
			# returnStr << "    $('[name=\""+$objectMapping[object.object.to_s]+"[others]\"]').val('');\n"
			# returnStr << "  }\n"
			# returnStr << "})\n"
			# returnStr << "</script>\n"
			# if System.get_property('platform') == "ANDROID"
			# 	returnStr << "\n<script>\n"
			# 	returnStr << "$('input[name*=\"" << fieldname << "\"]').click(function(){\n"
			# 	returnStr << "$('input[type=\"text\"]:focus').blur();\n"
			# 	returnStr << "$('textarea:focus').blur();\n"
			# 	returnStr << "});\n"
			# 	returnStr << "</script>\n"
			# 	returnStr << "\n"
			# end           
		rescue StandardError => se
			RhoLog::error("getQuestionnaireCheckbox","Exception occured in getQuestionnaireRadioButton #{se}")
			puts se.backtrace
		end
		return returnStr
	end

    def getQuestionRadioButton(lookupkey, fieldname, selectedvalue, object=nil, lookupdata=nil, adhocContent=nil, desc=false)
    	if(lookupkey != DYNAMICLOOKUP)
    		lookups = Lookupvalue.find(:all,
    			:conditions=>{
    				'key'=>lookupkey
    				},
    				:order=>'sortOrder',
    				:orderdir=>'ASC'
    				)
    	else
    		lookups = lookupdata
    	end       
    	returnStr = ""
    	radioName = ""
    	lookup_name = ""
    	begin
    		if fieldname!=nil
    			lookup_name = fieldname
    		else
    			lookup_name = lookupkey
    		end
    		fieldname = $objectMapping[object.object.to_s]+"["+lookup_name+"]" unless object.nil?
    		lookups.each_with_index do |lookup,index|
    			returnStr << "<div class='add-fna-data-full'> "
    			returnStr << renderRadioButton('fnaQuestionLookupDataCd', selectedvalue,"#{fieldname}_#{index}", lookup.cd, object, adhocContent)
    			returnStr << "<label for='#{fieldname}_#{index}' style='padding-top:15px;'></label>"
    			labelkey = (desc)? lookup.desc.to_sym : lookup.cd.to_sym
    			labelforQuestion = "#{Localization::LabelCache.instance.getLabel(labelkey)}".force_encoding(Encoding::UTF_8)
    			returnStr << labelforQuestion.gsub("___________________________","\t"+renderAmountField('responseValue',object.responseValue,'others',object, 'maxlength="10" style="width:31%; border: 1px; border-style: solid; border-color: grey;" data-role="none"'))
    			returnStr << "</div>"
    		end
    		# returnStr << "\n<script>\n"
    		# returnStr << "$('[name=\""+$objectMapping[object.object.to_s]+"[others]\"]').blur(function(){\n"
    		# returnStr << "  if(this.value!=\"\" && $(this).prev().find('input:checked').size()==0) {\n"
    		# returnStr << "    $(this).prev().find('label').trigger('click');\n"
    		# returnStr << "  }\n"
    		# returnStr << "})\n"
    		# returnStr << "$('[id*=\""+fieldname+"\"]').change(function(){\n"
    		# returnStr << "  if($('[name=\""+$objectMapping[object.object.to_s]+"[others]\"]').prev().find('input').attr('id')!=$(this).attr('id')){\n"
    		# returnStr << "    $('[name=\""+$objectMapping[object.object.to_s]+"[others]\"]').val('');\n"
    		# returnStr << "  }\n"
    		# returnStr << "})\n"
    		# returnStr << "</script>\n"
    		# if System.get_property('platform') == "ANDROID"
    		# 	returnStr << "\n"
    		# 	returnStr << "<script>" << "\n"
    		# 	returnStr << "$('input[name*=\"" << fieldname << "\"]').click(function(){\n"
    		# 	returnStr << "$('input[type=\"text\"]:focus').blur();\n"
    		# 	returnStr << "$('textarea:focus').blur();\n"
    		# 	returnStr << "});\n"
    		# 	returnStr << "</script>"<< "\n"
    		# 	returnStr << "\n"
    		# end           
    	rescue StandardError => se
    		puts "Exception occured in getQuestionnaireRadioButton #{se}"
    		puts se.backtrace
    	end
    	return returnStr
    end

    def execute
    	fnaRequest = MobiSys::BrowserHelper.convertToObject('FNARequest', @params['FNARequest'])
    	if fnaRequest.fnaNum.to_s == ""
      		fnaRequest.fnaNum = SequenceNoGenerator.getNextNumber('FNA')
    	end

    	fnaRequest.persistAll
    	
    end

end

begin 
    require 'FNARequest/f_n_a_request_controller_company'
rescue LoadError => e
    puts 'f_n_a_request_controller_company not included'
end