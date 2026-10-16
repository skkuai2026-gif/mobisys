require 'CommonModules/entityschema'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper'
require 'FNARequest/f_n_a_request_b_o'
# require 'Product/product_b_o'

module MobiSys
	class FNARequestService
		extend MobiSys::BrowserHelper

		def self.setAgentDetails(quotation, agentRegdetails)
	        if agentRegdetails != nil
	            quotation.agentId = agentRegdetails.agentId
	            quotation.channel = agentRegdetails.channel
	            quotation.subChannel = agentRegdetails.subChannel
	            quotation.parentAgency = agentRegdetails.parentAgency
	        end
	        return quotation
	    end

	    def self.copyFnaAndRpq(sourcefna, targetfna, sourcerpq, targetrpq)
	    	targetfna = sourcefna.cloneObject
	    	targetfna.update_attributes(:agentSignDt => nil,:witnessSignDt => nil,:applicantSignDt => nil,:agentSignature => nil,:witnessSignature => nil,:applicantSignature => nil,:statusCd => nil,:addtnField2Str => nil,:consentFl => nil,:marketingInfoFl => nil,:requestDt => Time.now, :addtnField11DT => nil, :systemCreatedDt => Time.now, :systemUpdatedDt => Time.now, :guid => nil, :id => nil, :fnaNum => nil, :versionID => nil, :addtnField4Str => nil )
	    	targetfna.fnaNum = SequenceNoGenerator.getNextNumber('FNA') if targetfna.fnaNum.to_s == ""  
	    	targetfna.guid = targetfna.object.gsub(".","_")
		    fnaProposer = targetfna.getParty("PROPOSER")
		    questionList = fnaProposer.fnaQuestionFromLookup
			if questionList && questionList.size.to_i > 0
				questionList.each do |fnaQue|
					qnaQuestionResponseObj = fnaProposer.getQuestionResponse(fnaQue.cd)
					fnaProposer.addFNAParty(qnaQuestionResponseObj)
				end
			end
	    	if sourcerpq != ""
	          	targetrpq = sourcerpq.cloneObject 
	          	targetrpq.update_attributes(:guid => nil, :id => nil, :systemCreatedDt => Time.now, :systemUpdatedDt => Time.now, :versionID => nil, :rpqId => nil, :fnaId =>nil)
	          	targetrpq.rpqId = SequenceNoGenerator.getNextNumber('RPQID')
	    		targetrpq.guid = targetrpq.object.gsub(".","_")
	    		rpqResponseList = targetrpq.getRPQResponseList
				if rpqResponseList && targetrpq.rpqId.to_s != ""
				  rpqResponseList.each do |response|
				    response.rpqId = targetrpq.rpqId
				  end
				end
	        end
	        saveValidate(targetfna,targetrpq)
	        return targetfna, targetrpq
	    end

	    def self.isRPQApplicable(fnaRequest)
	    	companyColor = OfflineApplication.find(:first, :conditions =>{{:name =>'PROPERTY'} =>'COMPANYCOLOUR'})
	    	companyColorValue = companyColor.value.to_s if companyColor
	        rpqApplicable = false
	        if companyColorValue.to_s == "SLOCPI"
	        	fnaParty = fnaRequest.getParty("PROPOSER")
		        if fnaParty != nil
		            fnaQuestionC = fnaParty.getQuestionResponse("FNA_Q1PartC")
		            q3Option = fnaQuestionC.fnaQuestionLookupDataCd
		            if q3Option != nil
		                if (q3Option.include? 'FNA_Q1PartC_option4') || (q3Option.include? 'FNA_Q1PartC_option3')
		                  rpqApplicable = true
		                else
		                  rpqApplicable = false
		                end
		            end
		        end
		    elsif companyColorValue.to_s == "SLGFI"
		    	if fnaRequest.reasonForRecoCd.to_s != ""
		    		product = Product.find(:first, :conditions=>{{:name=>'productId'} => fnaRequest.reasonForRecoCd.to_s, {:name=>'productStatusCd'} => 'LAUNCHED'},:op => 'AND')
		    		if product && product.productFamilyId.to_s == 'VUL'
		    			rpqApplicable = true
		    		end
		    	end
		    end
	        return rpqApplicable
	    end

	    def self.initializeFNARequestIO(fnaRequest, outputPreferencesDO)
	    	fnaIO = MobiSys::IO::FnaIO.new
            fnaIO.baseDO = fnaRequest
            fnaIO.outputPreferencesDO = outputPreferencesDO if $rhoconfig[:capture_output_preferences].to_s == "YES"

            if fnaIO.outputPreferencesDO == nil
            	outputPref = OutputPreferences.new
                fnaIO.outputPreferencesDO = defaultOutputPreferences(outputPref)
            end
            return fnaIO
	    end

	    def self.defaultOutputPreferences(outputPref)
	        outputPref.languageCd = "EN"
	        outputPref.field1 = "CHARTILLUSTRATION"
	        outputPref.field2 = "POLICYYEAR"
	        outputPref.field3 = "NO"
	        outputPref.field4 = "NO"
	        outputPref.field5 = "NO"
	        return outputPref
    	end

	    def self.setFundReasonApplicable(rpq)
	    	returnValue = ""
	    	return returnValue if rpq.to_s == ""
	    	
			if rpq && rpq.education.to_s != ""
			  fundlist = rpq.education.split(',')
			  risklist = []
			  riskintegerlist = []

			  companyfacetvalue = OfflineApplication.find(:first, :conditions =>{{:name =>'PROPERTY'} =>'COMPANYCOLOUR'})

			  if companyfacetvalue.value.to_s.casecmp("SLOCPI").zero?
			    rpqFundList = Lookupvalue.find(:all,:conditions=>{'key'=>"RPQFUNDS"})
			    
			    if rpqFundList
			      rpqFundList.each do |rpqfund|
			        if fundlist.include?(rpqfund.cd.to_s) && rpqfund.additionalField1.to_s != ""
			          risklist << rpqfund.additionalField1.to_s
			        end
			      end
			    end
			   

			    rpqFundListrisk = Lookupvalue.find(:all,:conditions=>{'key'=>"RISK_PROFILE"})
			    
			    if rpqFundListrisk
			      rpqFundListrisk.each do |rpqFundrisk|
			        if risklist.include?(rpqFundrisk.cd.to_s) && rpqFundrisk.additionalField1.to_s != ""
			          if rpqFundrisk.additionalField1.to_s.include?("|")
			            rpqFundrisk.additionalField1.to_s.split("|").each do |riskvalue|
			              riskintegerlist << riskvalue.to_i
			            end
			          else
			            riskintegerlist << rpqFundrisk.additionalField1.to_i
			          end
			        end
			      end
			    end
			    
			    if riskintegerlist.any?
			      maxrisk = riskintegerlist.max
			      saved_response = RPQResponse.loadObject(:all, :conditions => { :parentKey => rpq.object.to_s })
			      if saved_response.empty?
			      	 saved_response = rpq.RPQResponseList
				  end   
				   total_score = saved_response.inject(0){|sum,x| sum + x.score.to_i }
			      lookupvalue = getFundRisk(total_score)
			      if lookupvalue && lookupvalue.additionalField1.to_s != "" && maxrisk > lookupvalue.additionalField1.to_i
			          returnValue = "FUNDREASONAPPLICABLE"
			      end
			    end
			    return returnValue
			  end
			end 
	    end

	    def self.getFundRisk(rpqScore)
			rpqLookupData = nil  
			rpqFundListrisk = Lookupvalue.find(:all, :conditions => { 'key' => "RISK_PROFILE" })
		  
			if rpqFundListrisk && rpqFundListrisk.any? 
		    	rpqFundListrisk.each do |rpqFundrisk|
			     	if rpqFundrisk.valueFrom.to_s != "" && rpqFundrisk.valueTo.to_s != "" && rpqFundrisk.valueFrom.to_i <= rpqScore && rpqFundrisk.valueTo.to_i >= rpqScore
			        	rpqLookupData = rpqFundrisk
			        	break
			      	end
		    	end
		  	end
		  	return rpqLookupData 
		end

		def self.createTableForFund(fundListBasisRiskProfile, fundRiskClass)
		  htmlTable = ""
		  htmlTable << "<table width=\"100%\" class=\"border\" style=\"border: 1px solid black;\">"
		  htmlTable << "<tbody style=\"color: #8f9bb3; font-size: 0.85rem; position: relative; font-family: 'montserratregular', Arial, Helvetica, sans-serif; white-space: normal; !important;\">"
		  htmlTable << "<tr style=\"border-bottom: 1px solid black;\">"
		  htmlTable << "<td class=\"paddignLeftRight\" width=\"35%\"><b>#{MobiSys::BrowserHelper.getLabel('fundPackageName')}</b></td>"
		  htmlTable << "<td class=\"paddignLeftRight\" width=\"35%\"><b>#{MobiSys::BrowserHelper.getLabel('fundAllocationComp')}</b></td>"
		  htmlTable << "<td class=\"paddignLeftRight\" width=\"30%\"><b>#{MobiSys::BrowserHelper.getLabel('fundRisk')}</b></td>"
		  htmlTable << "</tr>"

		  (1...fundListBasisRiskProfile.length).each do |i|
		    packages = createRowsForFundPackageDetails(fundListBasisRiskProfile[i])
		    packageMain = createRowsForFundPackage(fundListBasisRiskProfile[i])
		    packagePerc = createRowsForFundPerc(fundListBasisRiskProfile[i])

		    htmlTable << "<tr>"
		    packageMain.each do |pkg|
		      htmlTable << "<td>#{pkg}</td>"
		    end

		    htmlTable << "<td>"
		    packages.each_with_index do |pkg, index|
		      htmlTable << "#{pkg} #{packagePerc[index]} %<br>"
		    end
		    htmlTable << "</td>"

		    htmlTable << "<td>#{fundRiskClass}</td>"
		    htmlTable << "</tr>"
		  end

		  htmlTable << "</tbody>"
		  htmlTable << "</table>"

		  htmlTable
		end

		def self.createRowsForFundPerc(fundPackage)
		  packagePerc = []
		  begin
		  	fundPkg = Lookupvalue.find(:all, :conditions => { 'key' => fundPackage.to_s }, :order => ['sortOrder'])
		    
		    fundPkg.each do |pkg|
		    	packagePerc.push pkg.additionalField2
		    end
		  rescue => e
		    puts e.full_message
		  end
		  packagePerc
		end

		def self.createRowsForFundPackage(fundPackage)
		  packageMain = []
		  begin
		    fundPkg = Lookupvalue.find(:all, :conditions => { 'cd' => fundPackage.to_s }, :order => ['sortOrder'])
		    
		    fundPkg.each do |pkg|
		    	packageMain.push pkg.desc
		    end
		  rescue => e
		    puts e.full_message
		  end
		  packageMain
		end

		def self.createRowsForFundPackageDetails(fundPackage)
		  packages = []
		  begin
		    fundPkg = Lookupvalue.find(:all, :conditions => { 'key' => fundPackage.to_s }, :order => ['sortOrder'])
		    
		    fundPkg.each do |pkg|
		    	packages.push pkg.desc
		    end
		  rescue => e
		    puts e.full_message
		  end
		  packages
		end

		def self.getLinkQuotation(baseIO)
			quotationIO = MobiSys::IO::QuotationIO.new
			quotationIO.baseDO = new.Quotation
			quotationIO.baseDO.userId = baseIO.baseDO.userId
			quotationIO.baseDO.quotationRefNum = baseIO.baseDO.addtnField2Str
			if quotationIO.baseDO
			  quotationIO.baseDO.fnaId = baseIO.baseDO.fnaNum
			  quotationIO.baseDO.rpqId = baseIO.baseDO.addtnField1Str
			  if baseIO.baseDO.action.nil?
			    quotationIO.baseDO.action = "Save"
			  end
			else
			  return nil
			end
			return quotationIO.baseDO
		end

	    def self.saveValidate(fna,rpq="",saveFNA=true)
	    	if rpq.to_s != ""
		    	rpq.fnaId = fna.fnaNum
		    	rpq.address1 = rpq.address1.gsub(/\\/, '').gsub(/^"|"$/, '') if rpq && rpq.address1.to_s != ""
		      	rpq.rpqId = SequenceNoGenerator.getNextNumber('RPQID') if rpq.rpqId.to_s == ""
		      	rpq.persistAll 
		      	fna.addtnField1Str = rpq.rpqId.to_s
		  	end
	   	  	fna.persistAll
	      	fna = FNARequest.loadObject(:first,:conditions=>{:object=> fna.object.to_s})
	      	isRPQApplicable = MobiSys::FNARequestService.isRPQApplicable(fna)
	      	if rpq.to_s != "" && !isRPQApplicable
	      		RPQResponse.delete_all(
                    :conditions => {
                        {:name=>'parentkey'} => rpq.object
                })
	      		rpq.rpqScore = nil
	      		rpq.nationality = nil
	      		rpq.education = nil
	      		rpq.otherTitle = nil
	      		rpq.incomeGroup = nil
	      		rpq.closureNotes = nil
	      		rpq.persistAll

	      		fnaFundList = FNAFund.loadObject(:all, :conditions => {
                        {:name=>'parentkey'} => fna.object})
	      		fnaFundList.each do |fnaFund|
	      			fna.removeFNAFund(fnaFund)
	      		end
	      	end
	      	companyColor = OfflineApplication.find(:first, :conditions =>{{:name =>'PROPERTY'} =>'COMPANYCOLOUR'})
	      	companyColorValue = companyColor.value.to_s if companyColor
	      	fnaFundList = FNAFund.find(:all,
	                :conditions => {
	                    {:name=>'parentKey'} => fna.object
	                }) if fna
	        if companyColorValue && companyColorValue.to_s == "SLGFI" && rpq && rpq.address1.to_s == "INDIVIDUAL"
	      		listFNAFundDO = []
		      	rpqFundList = Lookupvalue.find(
	                :all,
	                :conditions =>{
	                    {
	                        :name => 'key'
	                    } => "RPQFUNDS"
	                }
	            )

	            fieldTargetValueMapDOList = FieldTargetValueMap.find(
	                :all,
	                :conditions => {
	                    {:name=>'mappingKey'} => "RPQFUND"
	                }
	            )
	            
	            if !fieldTargetValueMapDOList.empty? && fieldTargetValueMapDOList.size > 0 
	                fieldTargetValueMapDOList.each do |fieldTargetValueMapDO|
	                    if fieldTargetValueMapDO.targetValue.to_s != "" && fieldTargetValueMapDO.drivingValue.to_s != ""
	                        if fieldTargetValueMapDO.drivingValue.to_s == fna.reasonForRecoCd.to_s
	                            rpqFund = rpqFundList.select{|fund| fund.cd.to_s == fieldTargetValueMapDO.targetValue.to_s }[0]
	                            listFNAFundDO.push(rpqFund.cd) if rpqFund
	                        end
	                    end
	                end
	            end
	            if !fnaFundList.empty? && fnaFundList.size > 0 
		            fnaFundList.each do |fnaFund|
		                if !listFNAFundDO.include?(fnaFund.fundCd.to_s)
		                   fnaFund.removed = "YES"
		                   fna.removeFNAFund(fnaFund)
		                end    
		            end
		        end  
		    end  

            fnaFundList.each do |fnaFund|
                if fnaFund.allocationPerc.to_s == ""
                   fnaFund.removed = "YES"
                   fna.removeFNAFund(fnaFund)
                end    
            end 

            companyColor = CompanyFacet.loadObject(:first, :conditions=>{{:name=>'facetCd'}=>"COMPANYNAME"})
	        if companyColor && companyColor.actionValue.to_s == "SLOCPI" && rpq && rpq.address1.to_s != "" && rpq.address1.to_s != "INDIVIDUAL"
	          pkgFund = rpq.address1.delete('"').to_s
	          fundPkg = Lookupvalue.find(:all, :conditions => { 'key' => pkgFund }, :order => ['sortOrder'])
			  valid_fund_cds = fundPkg.map { |fund| fund.cd.to_s }
	          fundPkg.each do |fund|
				  fnaFundList.each do |fna_fund|
					  unless valid_fund_cds.include?(fna_fund.fundCd.to_s)
					    fna_fund.removed = "YES"
					    fna.removeFNAFund(fna_fund)
					  end
				  end
				  if pkgFund.to_s == fund.key.to_s
				    # Find matching fund object from existing list
				    fnaFundDo = fnaFundList.find { |f| f.fundCd.to_s == fund.cd.to_s }
				    if fnaFundDo
				      # If found, update its values
				      fnaFundDo.field1 = fund.additionalField1
				      fnaFundDo.allocationPerc = fund.additionalField2.to_f
				      fnaFundDo.field2 = fund.privilegeCd
				      fna.addFNAFund(fnaFundDo)
				    else
				      # If not found, create new and assign values
				      fnaFundDo = FNAFund.new
				      fnaFundDo.fundCd = fund.cd
				      fnaFundDo.field1 = fund.additionalField1
				      fnaFundDo.allocationPerc = fund.additionalField2.to_f
				      fnaFundDo.field2 = fund.privilegeCd
				      fna.addFNAFund(fnaFundDo)
				    end
				  end
			  end
	        end  
	      	fna.persistAll

	      	errors = Hash.new
	      	if rpq.to_s != "" #&& isRPQApplicable
	      		rpqObj = LeadRPQ.loadObject(:first,:conditions=>{:object=> rpq.object.to_s})
	      	end
	      	MobiSys::CommonUtil.clearTaskExceptionList(fna.guid)
	      	MobiSys::CommonUtil.clearTaskExceptionList(rpqObj.guid) if rpqObj
	    	MobiSys::FNARequestBO.validate_Jazz(fna, errors)
      		MobiSys::FNARequestBO.validate_Jazz(rpqObj, errors) if rpqObj
	      	errors,errorTabs,incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(fna.guid,fna.visitedTabs)
          	if errors.empty? && incompleteTabs.empty? && saveFNA && fna.visitedTabs != ""
	        	if isRPQApplicable && fna.visitedTabs.to_s.include?('tab_riskProfile') && fna.visitedTabs.to_s.include?('tab_declaration')
	          		fna.statusCd = "COMPLETED"
	        	elsif !isRPQApplicable && fna.visitedTabs.to_s.include?('tab_fna_input') && fna.visitedTabs.to_s.include?('tab_declaration')
	          		fna.statusCd = "COMPLETED"
	        	else
	          		fna.statusCd = "PENDING"
	        	end
		    else
		        if isRPQApplicable && fna.visitedTabs.to_s.include?('tab_riskProfile') && fna.visitedTabs.to_s.include?('tab_declaration')
	          		fna.statusCd = "COMPLETED"
	        	elsif !isRPQApplicable && fna.visitedTabs.to_s.include?('tab_fna_input') && fna.visitedTabs.to_s.include?('tab_declaration')
	          		fna.statusCd = "COMPLETED"
	        	else
	          		fna.statusCd = "PENDING"
	        	end
		    end
		    fna.persistAll
       	end

	    def self.newQuotation(fna)
            $rhoconfig[:moduleForProductValidations] = "Quotation"
            quotation = Quotation.new
            quotation.fnaId = fna.fnaNum
            lead = Lead.loadObject(:first,:conditions=>{:leadId=> fna.leadId.to_s})
            leadParty = lead.PartyList[0] if lead
            leadPartyEmail = leadParty.PartyEmailList[0] if leadParty
            quotation.quotationRefNum = SequenceNoGenerator.getNextNumber('QUOTATION')
            quotation.rpqId = fna.addtnField1Str if fna.addtnField1Str != nil
            quotation.leadId = fna.leadId
            if quotation.rpqId.to_s != ""
	            rpqObj = LeadRPQ.loadObject(:first,:conditions=>{:rpqId=> quotation.rpqId.to_s})
	            quotation.quotAddtnlField12 = rpqObj.address1.delete('"').to_s if rpqObj.address1.to_s != ""
	            quotation.quotAddtnlField12 = "INDIVIDUAL" if rpqObj.address1.to_s == ""
	            flagMain = false
		    	fxFlag = false
 
		    	agent = AgentReg.getCurrentAgentReg
			    if agent && agent.field6 && agent.field6.casecmp('FX').zero?
			          fxFlag = true
			    end
	      		facet = CompanyFacet.loadObject(:first, :conditions=>{{:name=>'facetCd'}=>"PACKAGEFUNDAPPLICABLE"})
		        if facet && facet.actionValue.casecmp('YES').zero? && fxFlag
		          flagMain = true
		        end
 				p "flagMain============#{flagMain}"
		        if !flagMain
		      	  quotation.quotAddtnlField12 = "INDIVIDUAL"
		        end
	        end
            quotation.step = 0
            quotation.quoteStatusCd = "PENDING"
            if quotation.proposerLASame.to_s == ''
	            if leadParty.partyTypeCd.to_s == 'INDIVIDUAL'
		            quotation.proposerLASame = 'YES'
		        elsif leadParty.partyTypeCd.to_s == 'ORGANIZATION'
		        	quotation.proposerLASame = 'NO'
		        end
		    end
            # quotation.insuranceTypeCd = "LIFE" if quotation.insuranceTypeCd.to_s == ''
            listFNARequestAdditionalDO = fna.FNARequestAdditionalList

            if (listFNARequestAdditionalDO && listFNARequestAdditionalDO.size > 0)
                csaPlanList = Lookupvalue.find(
                    :all,
                    :conditions =>{
                        {
                            :name => 'key'
                        } => "CSAPlanCatMap"
                    }
                )

                planFamily = nil
                listFNARequestAdditionalDO.each do |fnaRequestAddtnl|
                    if fnaRequestAddtnl.field3.to_s != ''
                        planFamilyLkp = csaPlanList.select {|lookup| lookup.cd.to_s == fnaRequestAddtnl.field3.to_s}.first
                        if planFamily == nil
                            planFamily = planFamilyLkp.additionalField1.to_s
                        else
                            if !planFamily.to_s.include?(planFamilyLkp.additionalField1.to_s)
                                planFamily = 'BOTH'
                            end
                        end
                    end
                end
            end
            propVersion = OfflineApplication.find(:first, :conditions=>{:property=>'PROPOSALVERSION'})
            if quotation.proposalVersion.to_s == ''
            	quotation.proposalVersion = propVersion.value.to_s if propVersion
            end

            agentRegdetails = AgentReg.getCurrentAgentReg
            quotation = MobiSys::FNARequestService.setAgentDetails(quotation, agentRegdetails)
            quotation.quotationDt = getScreenDate(Time.now.to_s)
            #to set agent location in branch name field(quotAddtnlField2)
            quotation.quotAddtnlField2 = agentRegdetails.location if agentRegdetails
            quotation.isAgeEditableFl = nil
            isAgeEditableFl = MobiSys::BrowserHelper.getFacetMappedValue('AGECAPTUREREQUIRED',$currentProduct)
            quotation.isAgeEditableFl = isAgeEditableFl if isAgeEditableFl.to_s != ''
            quotation.quotAddtnlField11 = planFamily
            if quotation.proposerLASame.to_s == ''
                if leadParty.partyTypeCd.to_s == 'INDIVIDUAL'
                    quotation.proposerLASame = 'YES'
                elsif leadParty.partyTypeCd.to_s == 'ORGANIZATION'
                    quotation.proposerLASame = 'NO'
                end
            end
            #Copy Party Details to Quotation Party
            quotationParty = QuotationParty.new(:roleCd => "PROPOSER", :partyTypeCd => "INDIVIDUAL")
            quotation.addQuotationParty(quotationParty)

            fnaParty = fna.getParty("PROPOSER")

            if fnaParty
	           quotationParty.lastname = fnaParty.lastName1
	           quotationParty.middlename = fnaParty.middleName1
	           quotationParty.firstname = fnaParty.firstName1
	           quotationParty.extensionName = fnaParty.educationLevelCd
               quotationParty.dob = getDBDate(fnaParty.birthDt.to_s) if fnaParty.birthDt.to_s != ''
               quotationParty.age = computeAge(Time.parse(quotationParty.dob.to_s).to_i) if quotationParty.dob.to_s != ''
               quotationParty.emailAddress = leadPartyEmail.emailAddress.to_s if leadPartyEmail
	           party = quotation.getPartyByRole("PROPOSER")
	        end
	        if leadParty
	        	quotationParty.emailAddress = (leadParty.getPartyEmail("PERSONAL") ? leadParty.getPartyEmail("PERSONAL").emailAddress : nil)
	        	if lead.leadSourceOther.to_s != ''
	        		quotationParty.genderCd = leadParty.genderCd if leadParty.genderCd.to_s != ''
	        		quotationParty.smoker = leadParty.smoker if leadParty.smoker.to_s != ''
		        	quotationParty.educationCd = leadParty.copyFromAddr3 if leadParty.copyFromAddr3.to_s != ''
	                quotationParty.residency =  leadParty.copyFromAddr2 if leadParty.copyFromAddr2.to_s != ''
					leadPartyAddress = leadParty.PartyAddressList
		        	if leadPartyAddress
		        		leadPartyAddress.each do |leadAddress|
		                  quotationPartyAddress = quotationParty.getAddress(leadAddress.addressTypeCd.to_s,true)
		                  if quotationPartyAddress
		                      quotationPartyAddress.addressLine1Lang1 = leadAddress.addressLine1Lang1
		                      quotationPartyAddress.addressLine2Lang1 = leadAddress.addressLine2Lang1
		                      quotationPartyAddress.addressLine3Lang1 = leadAddress.addressLine3Lang1
		                      quotationPartyAddress.countryCd = leadAddress.countryCd
		                      quotationPartyAddress.pinCode = leadAddress.pinCode
		                      quotationPartyAddress.stateCd = leadAddress.stateCd 
		                      quotationPartyAddress.cityCd = leadAddress.cityCd
		                  end
		                end
		        	end
	        	end
	        end
            insuredParty = QuotationParty.new(:roleCd => "PRIMARY", :partyTypeCd => "INDIVIDUAL")
            quotation.addQuotationParty(insuredParty)
            quotation.status = ""
            fna = FNARequest.loadObject(:first,:conditions=>{:object=> fna.object.to_s})
            companyColor = OfflineApplication.find(:first, :conditions =>{{:name =>'PROPERTY'} =>'COMPANYCOLOUR'})
		    companyColorValue = companyColor.value.to_s if companyColor
		    if companyColorValue.to_s == "SLGFI"
		        if fna.reasonForRecoCd.to_s != ""
		            product = Product.find(
		                :first,
		                :conditions => {
		                    {:name => 'productId'}       => fna.reasonForRecoCd.to_s,
		                    {:name => 'productStatusCd'} => 'LAUNCHED'
		                },
		                :op => 'AND'
		            )
		            p "product ==> #{product}"
		            if product
		                basePlanQuoteProductDO = QuotationProduct.new
		                basePlanQuoteProductDO.productTypeCd               = "PLAN"
		                basePlanQuoteProductDO.sortOrder                   = 0
		                basePlanQuoteProductDO.productSeq                  = product.id
		                basePlanQuoteProductDO.productId                   = product.productId
		                basePlanQuoteProductDO.productFamilyCd             = product.productFamilyId
		                basePlanQuoteProductDO.productVersion              = product.productVersion
		                basePlanQuoteProductDO.topUpAllocSameAsPremAllocFl = "YES"
		                basePlanQuoteProductDO.partyRoleCd                 = "PRIMARY"
		                basePlanQuoteProductDO.annuityPerc                 = 100.0
		                basePlanQuoteProductDO.pdfFrequencyVal             = 1
		                basePlanQuoteProductDO.pdfPeriod                   = 0
		                basePlanQuoteProductDO.totAnnualizedPremium        = 0.0
		                basePlanQuoteProductDO.wopPremium                  = 0.0
		                basePlanQuoteProductDO.retirementPercent           = 0.0
		                basePlanQuoteProductDO.payoutFrequencyCd           = product.category1Cd
		                basePlanQuoteProductDO.baseAnnualPremium           = 0.0
		                basePlanQuoteProductDO.baseSumAssured              = 0.0
		                basePlanQuoteProductDO.annualizedPremium           = 0.0
		                quotation.addQuotationProduct(basePlanQuoteProductDO)
		            end
		        end
		    end
            quotation.persistAll

            MobiSys::CommonUtil.addUserActivity('CREATED_QUOTATION_FROM_FNA',"fnaId => #{quotation.fnaId},fnaGuid => #{fna.guid},quotationRefNum => #{quotation.quotationRefNum},quotationGuid => #{quotation.guid},leadId => #{quotation.leadId}", 'FNA',  quotation.quotationRefNum)

            return quotation
        end

        def self.incrementStep(fnaRequest,isErrorCheckReq=true)
        	if (fnaRequest.stepActionTabs.to_s != '')
        		stepActionTabList = fnaRequest.stepActionTabs.to_s.split(",")
        		fnaRequest.stepActionTabs = nil
	            incrementStep = true
	            if isErrorCheckReq
	            	if stepActionTabList.size > 0
		            	tabWiseTaskExceptionMap,errorTabs,incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(fnaRequest.guid, fnaRequest.visitedTabs)
		                stepActionTabList.each do |stepAction|
		                    if(tabWiseTaskExceptionMap[stepAction] != nil and tabWiseTaskExceptionMap[stepAction].size > 0)
		                        incrementStep = false
		                        break
		                    end
		                end
		            else
		            	incrementStep = false
		            end
	            end
	            fnaRequest.step = 0 if fnaRequest.step.to_s == ""
	            fnaRequest.step = (fnaRequest.step.to_i + 1) if incrementStep
        	end
        end

        def self.computeAge(dob, referenceDt=nil)
	        age = nil
 
	        if dob.to_s != ""
	            birthDt = getScreenDate(Time.at(dob).to_s) if dob.to_s != ""
	            referenceDate = getScreenDate(Time.at(referenceDt/1000).to_s) if referenceDt.to_s != ""
	            commencementDt = (referenceDate.to_s != "" ? referenceDate : getScreenDate(Time.new.to_s))
	            age = 0
	            if birthDt != nil and commencementDt != ""
	                ageCalculationBasis = MobiSys::ProductUtil::LASTBIRTHDAY
	                companyFacetAgeCalculationBasis = CompanyFacet.find(
	                    :first,
	                    :conditions => {
	                        { :name => 'facetCd' } => 'AGECALCULATIONBASIS'
	                    }
	                )
	                if companyFacetAgeCalculationBasis && companyFacetAgeCalculationBasis.actionValue.to_s != ""
	                    ageCalculationBasis = companyFacetAgeCalculationBasis.actionValue.to_s
	                end
	                age = MobiSys::ProductUtil.getAge(birthDt, ageCalculationBasis, commencementDt)
	                age = age.split("|")[0]
	            end
	        end
 
	        return age
	    end
	end
end
