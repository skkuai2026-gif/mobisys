#encoding: UTF-8
require 'Application/application'
require 'CommonModules/mobisysbrowserhelper_company'
#require 'Quotation/UIGenUtilCompanyHelper'
#require 'Policy/UIGenUtilEappHelper'
# Owner Sanket Tikhande
require 'time'
module MobiSys
	class UIGenUtilEapp
		include BrowserHelper
	  	include MobiSys::BrowserHelper
	  	include MobiSys::UIHelper

	  	 def self.getReflexiveQuestion(questionSetQuestionList)
			reflexiveQuestion = nil
			questionSetQuestionList.each do |questionSetQuestion|
				if questionSetQuestion[:conditional] == "REFLEXIVE"
					reflexiveQuestion = questionSetQuestion
					break
				end
			end
			return reflexiveQuestion
		end
		
		def self.getQuestionnaireTableForParentQue(policyIO,mvelHashMap)
			policyIO.baseDO.PartyList.each_with_index do |party,index|
				mvelHashMap["questionnaire"+party.roleCd] = {}
				@policy = policyIO.baseDO
				@life  =  policyIO.baseDO.getPartyByRole(party.roleCd)

				@questionContainer = QuestionContainer.loadObject(
					:first,
					:conditions=>{
							{:name=>'entityGuid'} => @life.guid.to_s,
							{:name=>'policyGuid'} => @policy.guid.to_s
					},
					:op => 'AND'
				)
				serviceQueResponseHash = {}
				return if !@questionContainer
				@questionContainer.ServiceQuestionResponseList.each do |serviceQuesResponse|
					 # if serviceQuesResponse.parentReferencePath.include? "#{questionSetCd}~"
						serviceQueResponseHash["#{serviceQuesResponse.questionSetCd}-#{serviceQuesResponse.questionDataElementCd}|#{serviceQuesResponse.parentReferencePath}"] = serviceQuesResponse.responseValue
					 # end
				end
				mvelHashMap["questionnaire"+party.roleCd] = serviceQueResponseHash
			end
		end

		def self.getChildArray(policyIO,roleCd,questionSetCd)
			questionSetMapData = QuestionSetMap.find(
							:all,
							:order => ['parentQuestionSetCd', 'displayOrder']
						)
			@questionnaireHash = MobiSys::Questionnaire.getQuestionnaire($questionSetData, questionSetMapData, questionSetCd)
			@policy = policyIO.baseDO
			life  =  Party.loadObject(
						:first,
						:conditions => {
								{:name => 'parentKey'} =>  policyIO.baseDO.object,
								{:name => 'roleCd'} => roleCd
						},
						:op => 'AND'
				)
			@questionContainer = QuestionContainer.loadObject(
						:first,
						:conditions=>{
								{:name=>'entityGuid'} => life.guid.to_s,
								{:name=>'policyGuid'} => @policy.guid.to_s
						},
						:op => 'AND'
				)

			serviceQueResponseHash = {}
			return if !@questionContainer
			@questionContainer.ServiceQuestionResponseList.each do |serviceQuesResponse|
				if (serviceQuesResponse.questionSetCd.to_s == "#{questionSetCd}") || (serviceQuesResponse.parentReferencePath.to_s.include? "#{questionSetCd}")
					serviceQueResponseHash["#{serviceQuesResponse.questionSetCd}|#{serviceQuesResponse.questionDataElementCd}"] = serviceQuesResponse.responseValue
				end
			end
			finalArrayForLeaf(@questionnaireHash,serviceQueResponseHash)
		end

		def self.finalArrayForLeaf(questionnaireHash,serviceQueResponseHash,finalString=[])
			if questionnaireHash.has_key?("listQuestionSetQuestionDOList")
				questionnaireHash["listQuestionSetQuestionDOList"].each do |questionSetQuestionObj|
	                responseValue = serviceQueResponseHash["#{questionSetQuestionObj[:questionSetCd]}|#{questionSetQuestionObj[:dataElementCd]}"]

					if responseValue.to_s != ""
						if questionSetQuestionObj[:inputTypeCd] == "COMBO"
							lkpResponse1 = MobiSys::UIGenUtilHelper.getLookupValue(questionSetQuestionObj[:lookupkey],responseValue.to_s)
							finalString.push(MobiSys::UIGenUtilHelper.getLabelValue("#{questionSetQuestionObj[:question]}",Application.getValue('DEFAULTLOCALE').value).to_s + "=>" + lkpResponse1.to_s)
						elsif questionSetQuestionObj[:inputTypeCd] == "FCOMBO"
							lkpResponse2 = MobiSys::UIGenUtilHelper.getLookupValue(questionSetQuestionObj[:lookupkey],responseValue.to_s)
							finalString.push(MobiSys::UIGenUtilHelper.getLabelValue("#{questionSetQuestionObj[:question]}",Application.getValue('DEFAULTLOCALE').value).to_s + "=>" + lkpResponse2.to_s) 
						elsif questionSetQuestionObj[:inputTypeCd] == "RADIO"
							lkpResponse3 = MobiSys::UIGenUtilHelper.getLookupValue(questionSetQuestionObj[:lookupkey],responseValue.to_s)
							finalString.push(MobiSys::UIGenUtilHelper.getLabelValue("#{questionSetQuestionObj[:question]}",Application.getValue('DEFAULTLOCALE').value).to_s + "=>" + lkpResponse3.to_s) 
						elsif questionSetQuestionObj[:inputTypeCd] == "HIDDEN"
							next
						else
							finalString.push(MobiSys::UIGenUtilHelper.getLabelValue("#{questionSetQuestionObj[:question]}",Application.getValue('DEFAULTLOCALE').value).to_s + "=>" + responseValue.to_s) 
						end
					end
				end
			end

			if questionnaireHash.has_key?("listQuestionSetDOList")
				questionnaireHash["listQuestionSetDOList"].each do |questionSetDO|
					if questionnaireHash["listQuestionSetQuestionDOList"]
						questionnaireHash["listQuestionSetQuestionDOList"].each do |questionSetQuestionObj|	
							finalArrayForLeaf(questionSetDO,serviceQueResponseHash,finalString)
						end
					end
				end
			end
			return finalString.compact
		end

		def self.getHtmlStringandGeneratePDF(isHtml, policyIO, apoPolicyIO=nil)
			$mvelHashMap = {}
			htmlBufferFinal = "".force_encoding(Encoding::UTF_8)
			htmlBufferPage = ""
			ulhtmlBuffer = ""
			htmlContent = Hash.new
			policyIO.htmlContent = htmlContent

			listPageSectionDO = []

			if apoPolicyIO
				finalMapNew(apoPolicyIO)
			end

			if apoPolicyIO
				$mvelHashMap = populateMvelHashMap(policyIO, $mvelHashMap, apoPolicyIO) #Need to write method for populateMvelHashMap
			else
				$mvelHashMap = populateMvelHashMap(policyIO, $mvelHashMap) #Need to write method for populateMvelHashMap
			end

			#call for questinaires

			
			getQuestionnairesDetailsOfParty(policyIO,$mvelHashMap)
			getQuestionnaireTableForParentQue(policyIO,$mvelHashMap)

			#unless illustrationModelDO == nil
			# elemMap = CommonUtil.convertToHash(illustrationModelDO.IllustrationFacetList, 'computedElementName')
			#end
			if policyIO.templatePageMappingDO != nil and policyIO.templatePageMappingDO.size > 0
				htmlBufferFinal << getCssStyle if isHtml #Need to write method for getCssStyle

				pagenumber = 0

				policyIO.templatePageMappingDO.each do |templatePageMappingDOo|
					# puts ">>>Processing templatePageMappingDO with id: #{templatePageMappingDOo.id}, pageName: #{templatePageMappingDOo.pageName}"
					if templatePageMappingDOo.mvelConditionRuby.to_s == "" or checkMvelCondition(templatePageMappingDOo,policyIO,$mvelHashMap)

						isFundList = false
						fundList = nil
						recurringFund = 1
						isFundList = ("fundList" == templatePageMappingDOo.fund)

						if($mvelHashMap["fundList"] != nil)
							fundList = $mvelHashMap["fundList"]
						end
						if(isFundList)
							recurringFund = fundList.size
						end
						begin
							if fundList.size != 0
								$mvelHashMap["currentFundDO"] = fundList[fundList.size-recurringFund]
								$mvelHashMap["currentFundCd"] = fundList[fundList.size-recurringFund].fundCd
							end
							returnHashMap = {}
							returnHashMap["repeatPage"] = true

							$mvelHashMap["pagenumber"] = pagenumber + 1
							while returnHashMap["repeatPage"] == true do
								if templatePageMappingDOo.isAPOFl and templatePageMappingDOo.isAPOFl == "YES"
									returnHashMap = createPage(isHtml, apoPolicyIO, templatePageMappingDOo, $mvelHashMap, returnHashMap, pagenumber)
								else
									returnHashMap = createPage(isHtml, policyIO, templatePageMappingDOo, $mvelHashMap, returnHashMap, pagenumber)
								end
								htmlContent[returnHashMap['pagenumber']] = {"name" => templatePageMappingDOo.pageName, "content" => returnHashMap['page'], "signature"=>$mvelHashMap["signatureHM"]}
								htmlBufferPage << returnHashMap["page"].force_encoding(Encoding::UTF_8)
								pagenumber = returnHashMap["pagenumber"]
								# puts ">>>processed page: #{pagenumber}"
							end
							recurringFund = recurringFund -1
						end while (recurringFund >= 1)
					end
				end

				totalPages = htmlContent.keys.size
				totalSkipNumber = 0
				i = 1
				while i<=pagenumber
					if htmlContent[i]["content"].include? "$SKIPPAGENUMBER$"
						totalSkipNumber = totalSkipNumber - 1
					end
					i = i + 1
				end
				skipPageNumber = 0
				htmlBuffer = ""
				i = 1
				while i<=pagenumber
					if htmlContent[i]["content"].include? "$SKIPPAGENUMBER$"
						skipPageNumber = skipPageNumber - 1
						htmlContent[i]["content"].gsub!('$SKIPPAGENUMBER$',"") unless $showPdf
					else
						htmlContent[i]["content"].gsub!('$PAGENUMBER$',(i+skipPageNumber).to_s)
						htmlContent[i]["content"].gsub!('$TOTALPAGENUMBER$',(pagenumber + totalSkipNumber).to_s)
					end
					i = i + 1
				end
				pagenumber = pagenumber - 1
			end

			htmlBufferFinal << htmlBufferPage
		end

		def self.getCssStyle
			return "<style type='text/css'>
							.body{
								font-family: Verdana;
								word-wrap: break-word;
								background-color: #FFFFFF;
								height: 100%;
							}

							.shadetabs{
							padding: 3px 0;
							margin-left: 0;
							margin-top: 1px;
							margin-bottom: 0;
							font: bold 12px Verdana;
							list-style-type: none;
							text-align: left; /*set to left, center, or right to align the menu as desired*/
							}

							.shadetabs li{
							display: inline;
							margin: 0;
							}

							.shadetabs li a{
							text-decoration: none;
							position: relative;
							z-index: 1;
								padding: 3px 7px;
								margin-right: 3px;
								border: 1px solid #778;
								color: #fff;
								background-color:#06F;
								}

								.shadetabs li a:visited{
								color: #fff;
								}

								.shadetabs li a:hover{
								text-decoration: underline;
								color: #fff;
								}

								.shadetabs li a.selected{ /*selected main tab style */
								position: relative;
								top: 1px;
								}

							.shadetabs li a.selected{ /*selected main tab style */
							background-color:#fff;
							border-bottom-color: white;
							color:#000;
							}

							.shadetabs li a.selected:hover{ /*selected main tab style */
							text-decoration: none;
							}

							</style>"
		end

		def self.populateMvelHashMap(policyIO, mvelHashMap, apoPolicyIO=nil)
		      #p "in populateMvelHashMap"
		      mvelHashMap["policyIO"] = policyIO
		      mvelHashMap["policyDO"] = policyIO.baseDO
		      @policy = policyIO.baseDO
		      @proposerParty=policyIO.baseDO.getParty("PROPOSER")
		      @primaryParty=policyIO.baseDO.getParty("PRIMARY")
		      @mailingParty=policyIO.baseDO.getParty("MAILING")
		      @beneficiaryPartyRoles =policyIO.baseDO.getPartyList("NOMINEE")
		     
		      @beneficiaryPolicyPartyRoles =policyIO.baseDO.getPolicyPartyRoleList("NOMINEE")
		   
		      beneficiaryList = []
		      benforCreditorList = []
		      beneficiaryOnDeathPrimaryList = []
		      beneficiaryOnDeathContingentList=[]
		      beneficiaryOnMaturityList = []
		      beneficiaryOnEndownmentList = []
		      shareOnDeathList=[]
		      onEndownList=[]
		      onMatureList=[]
		      onContingentList=[]
		      beneficiaryForCreditorBank=[]
		      beneficiaryForKeyMan=[]
		      beneficiaryForEmpFam=[]
		      beneficiaryForEmpNEmpFam=[]
		      beneficiaryForCreditorClause=[]
		      party_primary=[]
		      beneficiaryForCreditorEntity=[]
		     

		      mvelHashMap["allNomineeList"]= @beneficiaryPartyRoles
		      mvelHashMap["allNomineePolicyPartyList"]= @beneficiaryPolicyPartyRoles

		      hashmap = {}
		      
		      @beneficiaryPolicyPartyRoles.each do |beneficiaryPolicyPartyRoles|
		      	key = "#{beneficiaryPolicyPartyRoles.refGuid}"
		      	hashmap[key] = policyIO.baseDO.getPartyByGuid(beneficiaryPolicyPartyRoles.refGuid)
		      end

		      
		      mvelHashMap["hashmap"] = hashmap
		      
		       party_primary = PolicyPartyRole.loadObject(
		            :first,
		            :conditions => {
		                { :name => 'roleCd' } => "PRIMARY",
		                { :name => 'partySameAsCd' } => "PROPOSER",
		                { :name => 'parentKey' } => @policy.object,
		                :op => 'AND'
		            }
		        )
		       if party_primary
		       mvelHashMap["party_primary"]=party_primary
		        end



		      # counter = 1

		        @beneficiaryPartyRoles.each do |partyRole|




		         
		            party = PolicyPartyRole.loadObject(:first, :conditions => {{ :name => 'refguid' } => partyRole.guid})
		           

		        #     polallbicyPartyRole = PolicyPartyRole.loadObject(
		        #     :first,
		        #     :conditions => {
		        #         {:name => 'parentKey'} => @policy.object,
		        #         {:name => 'roleCd'} => "NOMINEE",
		        #         :op => 'AND',
		        #     }
		        # )
		        

		            # if party.eventTypeCd=="D"
		            #   beneficiaryOnDeathList << party
		            # elsif party.eventTypeCd=="M"
		            #   beneficiaryOnMaturityList << party
		            # elsif party.eventTypeCd=="E"
		            #   beneficiaryOnEndownmentList << party
		            # else
		            # beneficiaryList << party
		            
		            # end

		            if party.eventTypeCd=="D" and party.nomineeTypeCd=="P"
		                beneficiaryOnDeathPrimaryList << partyRole
		                shareOnDeathList<<party
		              elsif party.eventTypeCd=="D" and party.nomineeTypeCd=="C"
		                beneficiaryOnDeathContingentList << partyRole
		                onContingentList<<party
		              elsif party.eventTypeCd=="M"
		                beneficiaryOnMaturityList << partyRole
		                onMatureList<<party
		              elsif party.eventTypeCd=="E"
		                beneficiaryOnEndownmentList << partyRole
		                onEndownList<<party
		              else
		              beneficiaryList << partyRole
		                
		              end
		                if party.partySameAsCd=="BANK" || party.partySameAsCd=="CREDITOR"
		                  beneficiaryForCreditorBank << partyRole
		              end
		              if party.partySameAsCd=="EMPLOYERKEYMAN"
		                  beneficiaryForKeyMan << partyRole
		              end

		              if party.partySameAsCd=="EMPLOYEESFAMILYMEM"
		                  beneficiaryForEmpFam << partyRole
		              end

		              if party.partySameAsCd=="EMPANDAMPLOYERFAMILYMEM"
		                  beneficiaryForEmpNEmpFam << partyRole
		              end

		              if party.partySameAsCd=="BENEFICIARYCREDITORCLAUSE"
		                beneficiaryForCreditorClause << partyRole
		              end

		              if party.partySameAsCd=="BENFORCREDITOR"
		            	benforCreditorList << partyRole
		            end
		            if party.partySameAsCd=="CREDITORENTITY" || party.partySameAsCd=="CREDITORIND"
		                  beneficiaryForCreditorEntity << partyRole
		              end


		        end

              agent_array = @policy.getPolicyAgentList(true)
		      mvelHashMap["policyAgent"] = @policyAgent1 = agent_array[0]
		      mvelHashMap["beneficiaryOnDeathPrimaryList"] = beneficiaryOnDeathPrimaryList
		      mvelHashMap["beneficiaryOnDeathContingentList"] = beneficiaryOnDeathContingentList
		      mvelHashMap["beneficiaryOnMaturityList"] = beneficiaryOnMaturityList
		      mvelHashMap["beneficiaryOnEndownmentList"] = beneficiaryOnEndownmentList
		      mvelHashMap["beneficiaryList"] = beneficiaryList
		      mvelHashMap["benforCreditorList"] = benforCreditorList
		      
		      mvelHashMap["shareOnDeathList"] = shareOnDeathList
		      mvelHashMap["beneficiaryForCreditorClause"]=beneficiaryForCreditorClause
		      mvelHashMap["beneficiaryForKeyMan"]=beneficiaryForKeyMan
		      mvelHashMap["beneficiaryForEmpFam"]=beneficiaryForEmpFam
		      mvelHashMap["beneficiaryForEmpNEmpFam"]=beneficiaryForEmpNEmpFam

		      mvelHashMap["beneficiaryForCreditorBank"]=beneficiaryForCreditorBank
		      mvelHashMap["onContingentList"]=onContingentList
		      mvelHashMap["onMatureList"]=onMatureList
		      mvelHashMap["onEndownList"]=onEndownList
		      mvelHashMap["beneficiaryForCreditorEntity"]=beneficiaryForCreditorEntity
		     
		      mvelHashMap["proposerParty"] = @proposerParty if @proposerParty
		      mvelHashMap["primaryParty"] = @primaryParty if @primaryParty
		      mvelHashMap["mailingParty"] = @mailingParty if @mailingParty
		      mvelHashMap["primaryPartyAdditional"] = @primaryParty.getPartyAdditionalField(false) if @primaryParty.getPartyAdditionalField(false)
		      mvelHashMap["proposerPartyAdditional"] = @proposerParty.getPartyAdditionalField(false) if @proposerParty.getPartyAdditionalField(false)
		      mvelHashMap["proposerPolicyAdditional"] = @policy.getAdditionalFields(false) if @policy.getAdditionalFields(false)

		      mvelHashMap["primaryPartyAddressRESIDENTIAL"] = @primaryParty.getPartyAddress("RESIDENTIAL") if @primaryParty.getPartyAddress("RESIDENTIAL")
		      mvelHashMap["primaryPartyAddressPERMANENT"] = @primaryParty.getPartyAddress("PERMANENT") if @primaryParty.getPartyAddress("PERMANENT")
		      mvelHashMap["primaryPartyAddressOFFICE"] = @primaryParty.getPartyAddress("OFFICE") if @primaryParty.getPartyAddress("OFFICE")
		      mvelHashMap["proposerPartyAddressRESIDENTIAL"] = @proposerParty.getPartyAddress("RESIDENTIAL") if @proposerParty.getPartyAddress("RESIDENTIAL")
		      mvelHashMap["proposerPartyAddressPERMANENT"] = @proposerParty.getPartyAddress("PERMANENT") if @proposerParty.getPartyAddress("PERMANENT")
		      mvelHashMap["proposerPartyAddressOFFICE"] = @proposerParty.getPartyAddress("OFFICE") if @proposerParty.getPartyAddress("OFFICE")

		      if mvelHashMap["proposerParty"].copyFromAddr2 == "SAMEASPRESENTRES"
		        mvelHashMap["proposerPartyAddressPERMANENT"] = mvelHashMap["proposerPartyAddressRESIDENTIAL"]
		      end

		      if mvelHashMap["proposerParty"].copyFromAddr3 =="SAMEASPRESENTRES"
		        mvelHashMap["proposerPartyAddressOFFICE"] = mvelHashMap["proposerPartyAddressRESIDENTIAL"]
		      elsif mvelHashMap["proposerParty"].copyFromAddr3 =="SAMEASPERMANENTRES"
		         mvelHashMap["proposerPartyAddressOFFICE"] = mvelHashMap["proposerPartyAddressPERMANENT"]
		      end

		       if mvelHashMap["primaryParty"].copyFromAddr1 =="SAMEASPRESENTRES"
		        mvelHashMap["primaryPartyAddressRESIDENTIAL"] = mvelHashMap["proposerPartyAddressRESIDENTIAL"]
		       elsif mvelHashMap["primaryParty"].copyFromAddr1 =="SAMEASPERMANENTRES"
		         mvelHashMap["primaryPartyAddressRESIDENTIAL"] = mvelHashMap["proposerPartyAddressPERMANENT"]
		       elsif mvelHashMap["primaryParty"].copyFromAddr1 =="SAMEASBUSINESS"
		           mvelHashMap["primaryPartyAddressRESIDENTIAL"] = mvelHashMap["proposerPartyAddressOFFICE"]
		       end


		       if mvelHashMap["primaryParty"].copyFromAddr2 =="SAMEASPRESENTRES"
		        mvelHashMap["primaryPartyAddressPERMANENT"] = mvelHashMap["proposerPartyAddressRESIDENTIAL"]
		       elsif mvelHashMap["primaryParty"].copyFromAddr2 =="SAMEASPERMANENTRES"
		         mvelHashMap["primaryPartyAddressPERMANENT"] = mvelHashMap["proposerPartyAddressPERMANENT"]
		       elsif mvelHashMap["primaryParty"].copyFromAddr2 =="SAMEASBUSINESS"
		           mvelHashMap["primaryPartyAddressPERMANENT"] = mvelHashMap["proposerPartyAddressOFFICE"]
		       elsif mvelHashMap["primaryParty"].copyFromAddr2 =="SAMEASPRESENTRESINSURED"
		           mvelHashMap["primaryPartyAddressPERMANENT"] = mvelHashMap["primaryPartyAddressRESIDENTIAL"]
		       end

		       if mvelHashMap["primaryParty"].copyFromAddr3 =="SAMEASPRESENTRES"
		        mvelHashMap["primaryPartyAddressOFFICE"] = mvelHashMap["proposerPartyAddressRESIDENTIAL"]
		       elsif mvelHashMap["primaryParty"].copyFromAddr3 =="SAMEASPERMANENTRES"
		         mvelHashMap["primaryPartyAddressOFFICE"] = mvelHashMap["proposerPartyAddressPERMANENT"]
		       elsif mvelHashMap["primaryParty"].copyFromAddr3 =="SAMEASBUSINESS"
		           mvelHashMap["primaryPartyAddressOFFICE"] = mvelHashMap["proposerPartyAddressOFFICE"]
		       elsif mvelHashMap["primaryParty"].copyFromAddr3 =="SAMEASPRESENTRESINSURED"
		           mvelHashMap["primaryPartyAddressOFFICE"] = mvelHashMap["primaryPartyAddressRESIDENTIAL"]
		       elsif mvelHashMap["primaryParty"].copyFromAddr3 =="SAMEASPERMANENTRESINSURED"
		           mvelHashMap["primaryPartyAddressOFFICE"] = mvelHashMap["primaryPartyAddressPERMANENT"]
		       end

		       mvelHashMap["proposerPartyAddressMAILINGADDRESS"] = @proposerParty.getPartyAddress("MAILINGADDRESS") if @proposerParty.getPartyAddress("MAILINGADDRESS")

		      mvelHashMap["proposerPartyEmployment"] = @proposerParty.getPartyEmployment if @proposerParty.getPartyEmployment
		      mvelHashMap["primaryPartyEmployment"] = @primaryParty.getPartyEmployment if @primaryParty.getPartyEmployment

		      mvelHashMap["proposerPartyContact"] = @proposerParty.getPartyContact("PHILIPPINESNUM") if @proposerParty.getPartyContact("PHILIPPINESNUM")

		      mvelHashMap["proposerPartyEmail"] = @proposerParty.getPartyEmail if @proposerParty.getPartyEmail

		      mvelHashMap["policyAdditional"] = policyIO.baseDO.getAdditionalFields if policyIO.baseDO.getAdditionalFields

		      identityarrayProposer = @proposerParty.getPartyIdentityList(false)
		       mvelHashMap["PTINProposer"]=identityarrayProposer[0]
		      mvelHashMap["SSNProposer"]=identityarrayProposer[1]
		      mvelHashMap["identityarrayProposer"]=identityarrayProposer


		       identityarrayPrimary = @primaryParty.getPartyIdentityList(false)
		       mvelHashMap["PTINPrimary"]=identityarrayPrimary[0]
		      mvelHashMap["SSNPrimary"]=identityarrayPrimary[1]
		      mvelHashMap["identityarrayPrimary"]=identityarrayPrimary

		      mvelHashMap["primaryPartyEmail"] = @primaryParty.getPartyEmail if @primaryParty.getPartyEmail

			if beneficiaryForCreditorEntity
			 	counter = 1
			    beneficiaryForCreditorEntity.each do |clause|		        	
			 		 #puts "clause-------->#{clause}"
		          	mvelHashMap["nomineePartyAddressPerm" + counter.to_s] = clause.getPartyAddress("PERMANENT") if clause.getPartyAddress("PERMANENT")
			          #puts "clause.getPartyAddress('OFFICE')------>#{clause.getPartyAddress("OFFICE")}" if clause.getPartyAddress("OFFICE")
			        mvelHashMap["nomineePartyAddressOffice" + counter.to_s] = clause.getPartyAddress("OFFICE") if clause.getPartyAddress("OFFICE")

			        mvelHashMap["nomineePartyPhoneRes" + counter.to_s] = clause.getPartyContact("RESIDENTIAL") if clause.getPartyContact("RESIDENTIAL")
			        mvelHashMap["nomineePartyPhoneOffice" + counter.to_s] = clause.getPartyContact("OFFICE") if clause.getPartyContact("OFFICE")
			        mvelHashMap["nomineePartyPhoneMob" + counter.to_s] = clause.getPartyContact("MOBILE") if clause.getPartyContact("MOBILE")

		        	counter +=1        	
				end
			end


			if benforCreditorList
			counter = 1
		        benforCreditorList.each do |benclause|					        	

			          mvelHashMap["benPartyAddressPerm" + counter.to_s] = benclause.getPartyAddress("PERMANENT") if benclause.getPartyAddress("PERMANENT")

			          mvelHashMap["benPartyPhoneRes" + counter.to_s] = benclause.getPartyContact("RESIDENTIAL") if benclause.getPartyContact("RESIDENTIAL")
			          mvelHashMap["benPartyPhoneMob" + counter.to_s] = benclause.getPartyContact("MOBILE") if benclause.getPartyContact("MOBILE")
			      
			        	counter +=1


				end
			end

			if beneficiaryForEmpFam
				counter = 1
		        beneficiaryForEmpFam.each do |empfamclause|					        	
		        	mvelHashMap["empfamPartyAdditionalField" + counter.to_s] = empfamclause.getPartyAdditionalField if empfamclause.getPartyAdditionalField

			        mvelHashMap["empfamPartyAddressPerm" + counter.to_s] = empfamclause.getPartyAddress("PERMANENT") if empfamclause.getPartyAddress("PERMANENT")

			        mvelHashMap["empfamPartyContactRes" + counter.to_s] = empfamclause.getPartyContact("RESIDENTIAL") if empfamclause.getPartyContact("RESIDENTIAL")
			        
			        mvelHashMap["empfamPartyContactOffice" + counter.to_s] = empfamclause.getPartyContact("OFFICE") if empfamclause.getPartyContact("OFFICE")
			        
			        mvelHashMap["empfamPartyContactMob" + counter.to_s] = empfamclause.getPartyContact("MOBILE") if empfamclause.getPartyContact("MOBILE")
			    
			        counter +=1
				end
			end

			if beneficiaryForKeyMan
				counter = 1
		        beneficiaryForKeyMan.each do |empkeymanclause|					        	
		        	mvelHashMap["empkeymanPartyAdditionalField" + counter.to_s] = empkeymanclause.getPartyAdditionalField if empkeymanclause.getPartyAdditionalField

			        mvelHashMap["empkeymanPartyAddressOff" + counter.to_s] = empkeymanclause.getPartyAddress("OFFICE") if empkeymanclause.getPartyAddress("OFFICE")

			        mvelHashMap["empkeymanPartyContactRes" + counter.to_s] = empkeymanclause.getPartyContact("RESIDENTIAL") if empkeymanclause.getPartyContact("RESIDENTIAL")
			        
			        mvelHashMap["empkeymanPartyContactOffice" + counter.to_s] = empkeymanclause.getPartyContact("OFFICE") if empkeymanclause.getPartyContact("OFFICE")
			        
			        mvelHashMap["empkeymanPartyContactMob" + counter.to_s] = empkeymanclause.getPartyContact("MOBILE") if empkeymanclause.getPartyContact("MOBILE")
			    
			        counter +=1
				end
			end

			if beneficiaryForEmpNEmpFam
				counter = 1
		        beneficiaryForEmpNEmpFam.each do |empnempfamclause|					        	
		        	mvelHashMap["empnempfamPartyAdditionalField" + counter.to_s] = empnempfamclause.getPartyAdditionalField if empnempfamclause.getPartyAdditionalField

			        mvelHashMap["empnempfamPartyAddressPerm" + counter.to_s] = empnempfamclause.getPartyAddress("PERMANENT") if empnempfamclause.getPartyAddress("PERMANENT")

			        mvelHashMap["empnempfamPartyContactRes" + counter.to_s] = empnempfamclause.getPartyContact("RESIDENTIAL") if empnempfamclause.getPartyContact("RESIDENTIAL")
			        
			        mvelHashMap["empnempfamPartyContactOffice" + counter.to_s] = empnempfamclause.getPartyContact("OFFICE") if empnempfamclause.getPartyContact("OFFICE")
			        
			        mvelHashMap["empnempfamPartyContactMob" + counter.to_s] = empnempfamclause.getPartyContact("MOBILE") if empnempfamclause.getPartyContact("MOBILE")
			    
			        counter +=1
				end
			end
 
		      productHash = Hash.new
		      mvelHashMap['productHash'] = productHash
		      productDO = Product.find(:first, :conditions => {:Id => policyIO.baseDO.getBaseProduct.productSeq})
		      productHash[productDO.id] = productDO
		      #if productNameDO != nil
		      mvelHashMap["productDO"] = productDO if productDO
		      #end

		       if mvelHashMap["productDO"].productId == "ADB" || mvelHashMap["productDO"].productId == "TDB"
		       mvelHashMap["rider"] = mvelHashMap["productDO"].shortName
		      end

		      policyproduct = PolicyProduct.loadObject(:first, :conditions=>{:parentKey=> @policy.object})
		      mvelHashMap["policyproduct"] = policyproduct if policyproduct


		      	policyproductrider = PolicyProduct.loadObject(
		      	:all,
		      	:conditions=>{
		      	{ :name => 'parentKey' }=> @policy.object,
                { :name => 'productTypeCd' }=> "RIDER"
                },
                :op => 'AND'
		      )
		      	
		      # offlinerider = OffineRiderAssociation.loadObject(
		      #	:all,
		      	#:conditions=>{
		      	#{ :name => 'appplicableRoles' }=> "PRIMARY",
               	#}
		     # )
		     


		      mvelHashMap["policyproductrider"] = policyproductrider.sort!{|x,y| x.sortOrder.to_i <=> y.sortOrder.to_i} if policyproductrider



              policyProductAdditional = policyIO.baseDO.getPolicyProductAdditional(false)
		      #policyProductAdditional = PolicyProductAdditional.loadObject(:first, :conditions=>{:parentKey=> policyproduct.object})
		      mvelHashMap["policyProductAdditional"] = policyProductAdditional if policyProductAdditional

		    propSignatureObject = ServiceSignature.loadObject(
					:first,
					:conditions=>{
							{:name=>'entityGuid'} => policyIO.baseDO.guid,
							{:name=>'partyGuid'} => @proposerParty.guid
					},
					:op => 'AND'
			)
			mvelHashMap["propSignatureObject"] = propSignatureObject

			#advisor report
			# if policyIO.baseDO.transferControlTo.to_s == ""
				# $allSignature = "false"
			# end
			if policyIO.baseDO.travelGeographyCd.to_s == "YES"
				mvelHashMap["allSignature"] = "true"#policyIO.baseDO.travelGeographyCd.to_s
			else
				mvelHashMap["allSignature"] = "false"
			end
			
			# if (@primary && @primary.age.to_i >= 18 && sign.signatureTypeCd.to_s == "SIGNATURECAPTURE" && sign.roleCd.to_s == "PRIMARY")
			
			#     if sign.signature.to_s != ""
			
			#         $allSignature = "true"
			#     else
		
			#         $allSignature = "false"
			#     end
			# end
			# if ((@policyAdditionalField.field11 == "Y") || (@proposer.relationCd != "" && (@proposer.relationCd == "FATH" || @proposer.relationCd == "MOTH") && @primary && @primary.age.to_i < 18))
			
			#     if sign.signatureTypeCd.to_s == "PARENTSIGNATURECAPTURE" && sign.roleCd == "PRIMARY"
			
			#         if sign.signature.to_s != ""
		
			#             $allSignature = "true"
			#         else
			
			#             $allSignature = "false"
			#         end
			#     end
			# end



		      # @signatureContainer = SignatureContainer.loadObject(:first, :conditions => {:entityGuid => @policy.guid})
		     

		      # @agentSign, @proposerSign, @insuredSign, @supplementarySign, @parentSign, @fatcaSign = nil
		      # @agentSign, @proposerSign, @insuredSign, @supplementarySign, @parentSign, @fatcaSign = MobiSys::SignatureUtil.getSignatures(@policy,@signatureContainer) if @signatureContainer
		    

		      # mvelHashMap["agentSign"] = @agentSign if @agentSign
		      # mvelHashMap["proposerSign"] = @proposerSign if @proposerSign
		      # mvelHashMap["insuredSign"] = @insuredSign if @insuredSign
		      # mvelHashMap["parentSign"] = @parentSign if @parentSign
		      # mvelHashMap["fatcaSign"] = @fatcaSign if @fatcaSign


		      #  signatureString = ""
		      # sign = ServiceSignature.loadObject(
		      #                               :first,
		      #                               :conditions => {
		      #                                   { :name => "entityGuid" } =>  @policy.guid,
		      #                                   { :name => "signatureTypeCd", } => "FATCASIGNATURECAPTURE"
		      #                               },

		      #                               :op => "AND"


		      #                           )

		         

		        # if(sign == nil)
		        #   signatureString = ""
		        # else
		        #   signatureString = deCompressSignatureImage(sign.signature.to_s)
		        # end

		        # mvelHashMap["fatcaDeclarationString"] = signatureString


		      #signature compression related changes
		      signatureString = ""
		      sign = ServiceSignature.loadObject(
		                                    :first,
		                                    :conditions => {
		                                        { :name => "entityGuid" } =>  @policy.guid,
		                                        { :name => "signatureTypeCd", } => "AGENTDECLARATION"
		                                    },

		                                    :op => "AND"


		                                )

		            

		        if(sign == nil)
		          signatureString = ""
		        else
		          signatureString = deCompressSignatureImage(sign.signature.to_s)
		        end

		        mvelHashMap["agentDeclarationString"] = signatureString
		        mvelHashMap["agentSignatureDate"] = sign.signatureDt if sign
		      
		      #signature compression related changes
		      # signatureString = ""
		      # sign = ServiceSignature.loadObject(
		      #                               :first,
		      #                               :conditions => {
		      #                                   { :name => "entityGuid" } =>  @policy.guid,
		      #                                   { :name => "signatureTypeCd", } => "AGENTSIGNATURECAPTURE"
		      #                               },

		      #                               :op => "AND"


		      #                           )

		        # if(sign == nil)
		        #   signatureString = ""
		        # else
		        #   signatureString = deCompressSignatureImage(sign.signature.to_s)
		        # end

		        # mvelHashMap["agentSignatureString"] = signatureString
		       
		      #signature compression related changes
		      # signatureString = ""
		      # sign = ServiceSignature.loadObject(
		      #                               :first,
		      #                               :conditions => {
		      #                                   { :name => "entityGuid" } =>  @policy.guid,
		      #                                   { :name => "signatureTypeCd", } => "PARENTSIGNATURECAPTURE"
		      #                               },

		      #                               :op => "AND"


		      #                           )

		      
		        # if(sign == nil)
		        #   signatureString = ""
		        # else
		        #   signatureString = deCompressSignatureImage(sign.signature.to_s)
		        # end

		        # mvelHashMap["parentSignatureString"] = signatureString
		      
		      #signature compression related changes
		      # signatureString = ""
		      # sign = ServiceSignature.loadObject(
		      #                               :first,
		      #                               :conditions => {
		      #                                   { :name => "entityGuid" } =>  @policy.guid,
		      #                                   { :name => "signatureTypeCd" } => "SIGNATURECAPTURE",
		      #                                   { :name => "roleCd" } => "PROPOSER"
		      #                               },

		      #                               :op => "AND"


		      #                           )

		            

		        # if(sign == nil)
		        #   signatureString = ""
		        # else
		        #   signatureString = deCompressSignatureImage(sign.signature.to_s)
		        # end

		        # mvelHashMap["ownerSignatureString"] = signatureString
		     

		        #signature compression related changes
		      # signatureString = ""
		      # sign = ServiceSignature.loadObject(
		      #                               :first,
		      #                               :conditions => {
		      #                                   { :name => "entityGuid" } =>  @policy.guid,
		      #                                   { :name => "signatureTypeCd" } => "SIGNATURECAPTURE",
		      #                                   { :name => "roleCd" } => "PRIMARY"
		      #                               },

		      #                               :op => "AND"


		      #                           )

		         

		        # if(sign == nil)
		        #   signatureString = ""
		        # else
		        #   signatureString = deCompressSignatureImage(sign.signature.to_s)
		        # end

		        # mvelHashMap["insuredSignatureString"] = signatureString
		     
		       quotation = Quotation.loadObject(:first, :conditions => {{ :name => 'guid' } => policyIO.baseDO.quotationRefGuid})
				mvelHashMap["quotationDO"] = quotation

		      fundDOFinderList = Fund.loadObject(:all, :order => 'sortOrder', :orderdir => 'ASC')
		      fundDOHashMap = CommonUtil.convertToHash(fundDOFinderList, "fundCd")

		      if apoPolicyIO
		        mvelHashMap["apoPolicyIO"] = apoPolicyIO

		        premiumFacetDO =  apoPolicyIO.baseDO.getBasePlan().product.getFacet("PREMIUMDETAILS")

		        if premiumFacetDO and premiumFacetDO.OfflinePremiumDetailsList[0]
		          mvelHashMap["apoPremiumDetailsDO"] = premiumFacetDO.OfflinePremiumDetailsList[0]
		        else
		          mvelHashMap["apoPremiumDetailsDO"] = nil
		        end

		        apoPolicyIO.baseDO.getBasePlan.QuotationProductInvestmentFundList.each do |qpif|
		          if qpif.allocationPerc
		            mvelHashMap["apochosenFundCd"] = qpif.fundCd
		          end
		        end



		        #//14th Nov 2013 start
		        #mvelHashMap["apoFundList"] = apopolicyIO.baseDO.getBasePlan.QuotationProductInvestmentFundList
		        apoFundList = []
		        apoFundListHashMap = CommonUtil.convertToHash(apoPolicyIO.baseDO.getBasePlan.QuotationProductInvestmentFundList, "fundCd") #Need to code for ruby
		        fundDOFinderList.each do |fundDO2|
		          if apoFundListHashMap.has_key?(fundDO2.fundCd)
		            if apoFundListHashMap[fundDO2.fundCd].allocationPerc != nil
		              apoFundList << apoFundListHashMap[fundDO2.fundCd]
		            end
		          end
		        end
		        mvelHashMap["apoFundList"] = apoFundList
		        #//14th Nov 2013 end



		        apoRiderLIst = apoPolicyIO.baseDO.getRiders
		        apoRiderLIst.each do |rider|
		          mvelHashMap[rider.productId] = rider
		        end
		        mvelHashMap["apoRiderList"] = apoRiderLIst
		      else
		        mvelHashMap["apoPolicyIO"] = nil
		      end
		     if policyIO.baseDO.getRiders.to_s!=""
		      policyIO.baseDO.getRiders.each do |rider|
		        mvelHashMap[rider.productId] = rider
		      end
		     end
		      finderList = Product.find(:all, :conditions => {:productTypeCd => 'RIDER'}, :order => 'sortOrder', :orderdir => 'ASC') #Need to add sort condition

		      finderList.each do |productDO2|
		        if !mvelHashMap.has_key?(productDO2.productId)
		          mvelHashMap[productDO2.productId] = nil
		        else
		          productHash[productDO2.id] = Product.find(:first,:conditions=>{:productId=>productDO2.productId})
		        end
		      end

		      if policyIO.baseDO.getRiders.to_s!=""
		      riderListHashMap = CommonUtil.convertToHash(policyIO.baseDO.getRiders, "productId")

		      @riderList = []
		      finderList.each do |productDO2|
		        if riderListHashMap.has_key?(productDO2.productId)
		          @riderList << riderListHashMap[productDO2.productId]
		        end
		      end
		      end
		      #generating the hashmap for the ridersQuotationProduts that are not attatched with quotation
		      #quotationProductDORiderHashMap = CommonUtil.getInstance().getHashedList("productId", finderList) #Ruby code required

		      policyProductDORiderHashMap = CommonUtil.convertToHash(finderList, "productId")

		      policyIO.baseDO.getBaseProduct.PolicyProductInvestmentFundList.each do |fund|
		        if fund.allocationPerc != nil
		          mvelHashMap[fund.fundCd] = fund
		        end
		      end



		      fundDOFinderList.each do |fundDO2|
		        if !mvelHashMap.has_key?(fundDO2.fundCd)
		          mvelHashMap[fundDO2.fundCd] = nil
		        end
		      end

		      fundList = []
		      fundListHashMap = CommonUtil.convertToHash(policyIO.baseDO.getBaseProduct.PolicyProductInvestmentFundList, "fundCd") #Need to code for ruby

		      fundDOFinderList.each do |fundDO2|
		        if fundListHashMap.has_key?(fundDO2.fundCd)
		          if fundListHashMap[fundDO2.fundCd].allocationPerc != nil
		            fundList << fundListHashMap[fundDO2.fundCd]
		          end
		        end
		      end



		      mvelHashMap["fundList"] = fundList
		      mvelHashMap["riderList"] = @riderList
		      mvelHashMap["fundDOHashMap"] = fundDOHashMap
		      mvelHashMap["policyProductDORiderHashMap"] = policyProductDORiderHashMap

		      #adding helper class in hashmap
		      #UIGenUtilCompanyHelper.getUpdateHashMap(mvelHashMap)
		      mvelHashMap["mvelHashMap"] = mvelHashMap
		      mvelHashMap["riderListHashMap"] = riderListHashMap

		    mvelHashMap["signatureHM"] = {}
			policy = mvelHashMap["policyDO"]
		    if $rhoconfig[:captureSignOnEappPreview]
				signatureDtHtml = ""
				signatureContainer = SignatureContainer.loadObject(:first, :conditions => {:entityGuid => policy.guid})
				if signatureContainer.to_s == ""
		            signatureContainer = SignatureContainer.new(:entityGuid => policy.guid, :entityTypeCd => policy.class.name.to_s)
		            # setObjectCount(signatureContainer, 50)
		            # setObjectMapping(signatureContainer, signatureContainer.class.name)
		        end
		    	agentSign, proposerSign, insuredSign, supplementarySigns, parentSign, fatcaSign = nil
			    agentSign, proposerSign, insuredSign, supplementarySigns, parentSign, fatcaSign = MobiSys::SignatureUtil.getSignatures(policy,signatureContainer) if signatureContainer

			    if agentSign
			    	if agentSign.guid.to_s == ""
			    		agentSign.guid = agentSign.uniqueKey
			    	end
				    mvelHashMap["signatureHM"]["agentSign"] = Hash.new if !mvelHashMap["signatureHM"]["agentSign"]
					mvelHashMap["signatureHM"]["agentSign"] = agentSign
				end
				if parentSign
			    	if parentSign.guid.to_s == ""
			    		parentSign.guid = parentSign.uniqueKey
			    	end
				    mvelHashMap["signatureHM"]["parentSign"] = Hash.new if !mvelHashMap["signatureHM"]["parentSign"]
					mvelHashMap["signatureHM"]["parentSign"] = parentSign
				end
				if fatcaSign
			    	if fatcaSign.guid.to_s == ""
			    		fatcaSign.guid = fatcaSign.uniqueKey
			    	end
				    mvelHashMap["signatureHM"]["fatcaSign"] = Hash.new if !mvelHashMap["signatureHM"]["fatcaSign"]
					mvelHashMap["signatureHM"]["fatcaSign"] = fatcaSign
				end
				if proposerSign
			    	if proposerSign.guid.to_s == ""
			    		proposerSign.guid = proposerSign.uniqueKey
			    	end
					mvelHashMap["signatureHM"]["proposerSign"] = Hash.new if !mvelHashMap["signatureHM"]["proposerSign"]
					mvelHashMap["signatureHM"]["proposerSign"] = proposerSign
				end
				if insuredSign
			    	if insuredSign.guid.to_s == ""
			    		insuredSign.guid = insuredSign.uniqueKey
			    	end
					mvelHashMap["signatureHM"]["insuredSign"] = Hash.new if !mvelHashMap["signatureHM"]["insuredSign"]
					mvelHashMap["signatureHM"]["insuredSign"] = insuredSign
				end
				if !supplementarySigns.empty?
			    	if supplementarySigns[0].guid.to_s == ""
			    		supplementarySigns[0].guid = supplementarySigns[0].uniqueKey
			    	end
					mvelHashMap["signatureHM"]["supplementarySign"] = Hash.new if !mvelHashMap["signatureHM"]["supplementarySign"]
					mvelHashMap["signatureHM"]["supplementarySign"] = supplementarySigns[0]
				end
			end

			  #begin
		      dt = Time.parse(policyIO.baseDO.quotationDt.to_s)
		      mvelHashMap["calendarYear"] = dt.year
			  #end
		     # mvelHashMap["formtypeadvgio"]=Application.getValue('FORMTYPECODEADVGIO').value if Application.getValue('FORMTYPECODEADVGIO')
		     # mvelHashMap["formtypeadvsio"]=Application.getValue('FORMTYPECODEADVSIO').value if Application.getValue('FORMTYPECODEADVSIO')
		     # mvelHashMap["formtypesio"]=Application.getValue('FORMTYPECODESIO').value  if Application.getValue('FORMTYPECODESIO')
		     # mvelHashMap["formtypegio"]=Application.getValue('FORMTYPECODEGIO').value if Application.getValue('FORMTYPECODEGIO')
		     formtypeadvgio = OfflineApplication.find(:first, :conditions =>{{:name =>'PROPERTY'} =>'FORMTYPECODEADVGIO'})
		     formtypeadvsio = OfflineApplication.find(:first, :conditions =>{{:name =>'PROPERTY'} =>'FORMTYPECODEADVSIO'})
		     formtypesio = OfflineApplication.find(:first, :conditions =>{{:name =>'PROPERTY'} =>'FORMTYPECODESIO'})
		     formtypegio = OfflineApplication.find(:first, :conditions =>{{:name =>'PROPERTY'} =>'FORMTYPECODEGIO'})
		     formtyperu = OfflineApplication.find(:first, :conditions =>{{:name =>'PROPERTY'} =>'FORMTYPECODERU'})
		     formtypeadvru = OfflineApplication.find(:first, :conditions =>{{:name =>'PROPERTY'} =>'FORMTYPECODEADVRU'})
		     formtypegiotrad = OfflineApplication.find(:first, :conditions =>{{:name =>'PROPERTY'} =>'FORMTYPECODEGIOTRAD'})
             formtypeadvgiotrad = OfflineApplication.find(:first, :conditions =>{{:name =>'PROPERTY'} =>'FORMTYPECODEADVGIOTRAD'})    

		     mvelHashMap["formtypeadvgio"] = formtypeadvgio.value if formtypeadvgio
		     mvelHashMap["formtypeadvsio"] = formtypeadvsio.value if formtypeadvsio
		     mvelHashMap["formtypesio"] = formtypesio.value if formtypesio
		     mvelHashMap["formtypegio"] = formtypegio.value if formtypegio
		     mvelHashMap["formtyperu"] = formtyperu.value if formtyperu
		     mvelHashMap["formtypeadvru"] = formtypeadvru.value if formtypeadvru
		     mvelHashMap["formtypegiotrad"] = formtypegiotrad.value if formtypegiotrad
 			 mvelHashMap["formtypeadvgiotrad"] = formtypeadvgiotrad.value if formtypeadvgiotrad
 			 inwardList = []
 			 inwardList = policyIO.baseDO.getInwardList(@policy.proposalNum)
		     completedStatusList = ["PENDING", "SUCCESS"]
		     paymentMethodList = []
		     if inwardList && inwardList.size > 0
			     inwardList.each do |inward|
			     	if inward && completedStatusList.include?(inward.inwardStatusCd.to_s)
			     		if inward.paymentMethodCd.to_s != "" && !paymentMethodList.include?(inward.paymentMethodCd)
							paymentMethodList << inward.paymentMethodCd
						end
			     	end
			     end
			 end
		     paymentString = ""
		     paymentList = []
		     paymentMethodList.each do |pm|
		     	paymentList << MobiSys::UIGenUtilHelper.getLookupValue("CPAGPAYMENTMETHOD", pm) if MobiSys::UIGenUtilHelper.getLookupValue("CPAGPAYMENTMETHOD", pm).to_s != ""
		     end
		     paymentString = paymentList.join(", ") if paymentList != []

		     mvelHashMap["PaymentMethod"] = paymentString

		     return mvelHashMap
	    end

        def self.deCompressSignatureImage(compressedSignature)
            if compressedSignature != "" && !compressedSignature.start_with?('data:image/png;base64,')
                compressed_signature = compressedSignature.gsub!('ZLIBCMP','')
                signature_decoded = MobiSys::Encryption.decodeContents(compressed_signature)
                inflatedString = MobiSys::Encryption.unZipData(signature_decoded)
                signatureString = 'data:image/png;base64,' + MobiSys::Encryption.encodeContents(inflatedString)
            elsif compressedSignature != "" && compressedSignature.start_with?('data:image/png;base64,')
                signatureString = compressedSignature
            end
          return signatureString.to_s
        end

        def self.checkMvelCondition(sectionDetailsDO, policyIO, mvelHashMap)
	      policyDO = mvelHashMap["policyDO"]
	     
	      if sectionDetailsDO.mvelConditionRuby.to_s != ""
	       # eval sectionDetailsDO.mvelConditionRuby
	      end
        end

	    def self.createPage(ishtml, policyIO, templatePageMappingDO, mvelHashMap, returnHashMap, pagenumber)
	     
	      pageSectionDO = PageSection.new
	      htmlBuffer = "".force_encoding(Encoding::UTF_8)
	      newtemplatePageMappingDO = {}
	      newtemplatePageMappingDO = templatePageMappingDO

	      if ishtml #and $showPdf != true
	        htmlBuffer << "<!--Processing page: #{templatePageMappingDO.id}-->".force_encoding(Encoding::UTF_8)
	        htmlBuffer << getCssStyle.force_encoding(Encoding::UTF_8)
	        htmlBuffer << "<div id=\"output"+pagenumber.to_s+"\" class=\"tabcontent\">".force_encoding(Encoding::UTF_8)
	      end

	      listPageHeaderSectionMappingDO = PageHeaderSectionMapping.loadObject(:all, :conditions => {:pageHeaderSeq => newtemplatePageMappingDO.pageHeaderSeq}, :order => 'displayOrder', :orderdir => 'ASC')
	      repeatHashMap = {}
	      if returnHashMap.has_key?("repeatPageFrom")
	        repeatHashMap["repeatPageFrom"] = returnHashMap["repeatPageFrom"]
	        repeatHashMap["skipPolicyseq"] = returnHashMap["skipPolicyseq"]
	        repeatHashMap["skipAge"] = returnHashMap["skipAge"]
	      end
	      listPageHeaderSectionMappingDO.each do |pageHeaderSectionMappingDO|
	        pageSectionDO = PageSection.loadObject(:first, :conditions => {:id => pageHeaderSectionMappingDO.pageSectionSeq})
	        if pageSectionDO != nil && (pageHeaderSectionMappingDO.mvelConditionRuby == nil || (eval pageHeaderSectionMappingDO.mvelConditionRuby))
	          # if pageSectionDO
	         
	          pageSectionDO.SectionDetailsList.sort{|x,y| x.displayOrder.to_i<=>y.displayOrder.to_i}.each do |sectionDetailsDO|
	            #next unless Application.getValue('SectionDetails').value.include? sectionDetailsDO.id.to_s
	           
	            if sectionDetailsDO.mvelConditionRuby.to_s == "" or checkMvelCondition(sectionDetailsDO,policyIO,mvelHashMap)
	              if sectionDetailsDO and sectionDetailsDO.elementType and sectionDetailsDO.onlyType and (sectionDetailsDO.onlyType == "HTML" or sectionDetailsDO.onlyType=="PDF")
	                if sectionDetailsDO.onlyType == "HTML" and $showPdf != true
	                  repeatHashMap = processPage(sectionDetailsDO,policyIO,htmlBuffer,mvelHashMap,repeatHashMap,ishtml,true)
	                elsif sectionDetailsDO.onlyType == "PDF" and $showPdf == true
	                  repeatHashMap = processPage(sectionDetailsDO,policyIO,htmlBuffer,mvelHashMap,repeatHashMap,ishtml,true)
	                end
	              else
	                repeatHashMap = processPage(sectionDetailsDO,policyIO,htmlBuffer,mvelHashMap,repeatHashMap,ishtml,true)
	              end
	            end
	          end
	        end
	      end

	      if ishtml
	        htmlBuffer << "</div><!--div class tabcontent end-->".force_encoding(Encoding::UTF_8)
	      else
	        #If condition used for PDF generation on client side
	        QuotationRequestUtil.getInstance().generateQuotationPDFFileUsingBuffer(policyIO, nil, htmlBuffer, policyIO.getBaseDO().getId() +"-"+ pagenumber)
	      end
	      returnHashMap["page"] = htmlBuffer
	      pagenumber = pagenumber+1
	      returnHashMap["pagenumber"] = pagenumber
	      returnHashMap["repeatPage"] = false
	      if repeatHashMap.has_key?("repeatPageFrom")
	        returnHashMap["repeatPageFrom"] = repeatHashMap["repeatPageFrom"]
	        returnHashMap["skipPolicyseq"] = repeatHashMap["skipPolicyseq"]
	        returnHashMap["skipAge"] = repeatHashMap["skipAge"]
	        returnHashMap["repeatPage"] = true
	      end

	      return returnHashMap
	    end

		def self.processPage(sectionDetailsDO, policyIO, htmlBuffer, mvelHashMap, returnHashMapPage, ishtml, divHide)
			htmlBuffer << "<!-- Processing sectionDetailsDO with id #{sectionDetailsDO.id} -->".force_encoding(Encoding::UTF_8)
			element = ""
			rate = ""
			max = 0
			policyYearCondition = ""
			ageCondition = ""
			mvelPolicyYear = ""
			mvelAge = ""
			tdStyle = ""
			tableSpace=""

			if true

				if policyIO.outputPreferencesDO && policyIO.outputPreferencesDO.languageCd != nil && policyIO.outputPreferencesDO.languageCd.upcase != 'EN'
					sectionDetailsDO.label1Ruby = sectionDetailsDO.label2Ruby
				end

				if sectionDetailsDO != nil and sectionDetailsDO.includeTd and sectionDetailsDO.includeTd.upcase! == "YES"
					htmlBuffer << "#{sectionDetailsDO.property1}>".force_encoding(Encoding::UTF_8)
					divHide = false
				end

				label1Ruby = nil
				if sectionDetailsDO != nil && sectionDetailsDO.elementType != nil && sectionDetailsDO.elementType == "HTML"
					value = ""
					if sectionDetailsDO.label1Ruby != nil && sectionDetailsDO.label1Ruby.include?("$PATH$") #need to write equivalent code for ruby
						pPATH = ""
						if ishtml
							pPATH = "/assets/theme/images/company/"
							label1Ruby = sectionDetailsDO.label1Ruby.gsub("$PATH$", pPATH) #Need to write ruby equivalent code
						else
							label1Ruby = sectionDetailsDO.label1Ruby.gsub("$PATH$", pPATH) #Need to write ruby equivalent code
						end
					else
						label1Ruby = sectionDetailsDO.label1Ruby
					end
					htmlBuffer << processProperty(label1Ruby, policyIO, mvelHashMap).force_encoding(Encoding::UTF_8) if processProperty(label1Ruby, policyIO, mvelHashMap).to_s!=""
				elsif sectionDetailsDO != nil && sectionDetailsDO.elementType != nil && sectionDetailsDO.elementType == "IMAGE"
					if ishtml
						htmlBuffer << "<img src=\"/systemcommon/pdfGenerated/illustration/" + sectionDetailsDO + "\" " + sectionDetailsDO.property1 + " >".force_encoding(Encoding::UTF_8)
					else
						htmlBuffer << "<img src=\"" + sectionDetailsDO + "\" " + sectionDetailsDO.property1 + " >".force_encoding(Encoding::UTF_8)
					end

				elsif sectionDetailsDO != nil && sectionDetailsDO.elementType != nil && sectionDetailsDO.elementType == "STATIC"
					if divHide
						htmlBuffer << "<div #{sectionDetailsDO.property1}>".force_encoding(Encoding::UTF_8)
					end
					str = processProperty(sectionDetailsDO.label1Ruby,policyIO,mvelHashMap).force_encoding(Encoding::UTF_8)
					htmlBuffer << str.force_encoding(Encoding::UTF_8)
					if divHide
						htmlBuffer << "</div>".force_encoding(Encoding::UTF_8)
					end

				elsif sectionDetailsDO != nil && sectionDetailsDO.elementType != nil && sectionDetailsDO.elementType == "STYLE"
					htmlBuffer << "<style type=\"text/css\">".force_encoding(Encoding::UTF_8)
					htmlBuffer << sectionDetailsDO.label1Ruby.force_encoding(Encoding::UTF_8)
					htmlBuffer << "</style>".force_encoding(Encoding::UTF_8)

				elsif sectionDetailsDO != nil && sectionDetailsDO.elementType != nil && sectionDetailsDO.elementType == "TABLE" && policyIO.baseDO.getBaseProduct.productTerm !=nil
					sectionDetailsDO.label1Ruby = sectionDetailsDO.label1Ruby.gsub("\r","").gsub("\n","")
					if sectionDetailsDO.label1Ruby!= nil && sectionDetailsDO.label1Ruby.include?("${") && sectionDetailsDO.label1Ruby.include?("}$") #Need to write ruby equivalent code
						if sectionDetailsDO.label1Ruby.include?("mvel${") && sectionDetailsDO.label1Ruby.include?("}$mvel") #Need to write ruby equivalent code
							staticcontent = sectionDetailsDO.label1Ruby
							finalString = ""
							while staticcontent.include?("mvel${") #Need to write ruby equivalent code for the whole block
								startindex = staticcontent.index("mvel${")
								finalString << staticcontent[0, startindex]
								staticcontent = staticcontent[startindex+"mvel${".length,staticcontent.length]
								endindex = staticcontent.index("}$mvel")
								element2 = staticcontent[0,endindex]
								element2 = element2.strip
								finalString << (eval(element2))
								staticcontent = staticcontent[endindex+"mvel${".length,staticcontent.length]
								staticcontent = staticcontent.gsub("#", ";")#Need to see if code is required or not
							end
							tempStr = (finalString + staticcontent).gsub("$SEMI$", "")
							sectionDetailsDO.label1Ruby = tempStr #Need to see if code is required or not
						end #467
						if sectionDetailsDO.label1Ruby.include?("element${") && sectionDetailsDO.label1Ruby.include?("}$element")
							element = extract(sectionDetailsDO.label1Ruby,"element")
						end
						if sectionDetailsDO.label1Ruby.include?("rate${") && sectionDetailsDO.label1Ruby.include?("}$rate")
							rate = extract(sectionDetailsDO.label1Ruby,"rate")
						else
							elemlabel1Ruby = element.split(",")
							elemlabel1Ruby.each do |ev|
								if(ev.include?("~"))
									rate << "0~0,"
								else
									rate << "0,"
								end
							end
							rate = rate[0, rate.length-1]
						end

						if sectionDetailsDO.label1Ruby.include?("max${") && sectionDetailsDO.label1Ruby.include?("}$max")
							max = extract(sectionDetailsDO.label1Ruby,"max")
						end

						if sectionDetailsDO.label1Ruby.include?("policyYearCondition${") && sectionDetailsDO.label1Ruby.include?("}$policyYearCondition") #Need to write ruby equivalent code for the whole block
							policyYearCondition = extract(sectionDetailsDO.label1Ruby,"policyYearCondition")
						end

						if sectionDetailsDO.label1Ruby.include?("ageCondition${") && sectionDetailsDO.label1Ruby.include?("}$ageCondition")
							ageCondition = extract(sectionDetailsDO.label1Ruby,"ageCondition")
						end

						if sectionDetailsDO.label1Ruby.include?("mvelPolicyYear${") && sectionDetailsDO.label1Ruby.include?("}$mvelPolicyYear")
							mvelPolicyYear = extract(sectionDetailsDO.label1Ruby, "mvelPolicyYear")
						end

						if sectionDetailsDO.label1Ruby.include?("mvelAge${") && sectionDetailsDO.label1Ruby.include?("}$mvelAge")
							mvelAge = extract(sectionDetailsDO.label1Ruby,"mvelAge")
						end

						if sectionDetailsDO.label1Ruby.include?("tableSpace${") && sectionDetailsDO.label1Ruby.include?("}$tableSpace")
							tableSpace = extract(sectionDetailsDO.label1Ruby,"tableSpace")
						end

						if sectionDetailsDO.label1Ruby.include?("tdStyle${") && sectionDetailsDO.label1Ruby.include?("}$tdStyle")
							tdStyle = extract(sectionDetailsDO.label1Ruby,"tdStyle")
						else
							elemValue=element.split(",")
							elemValue.each do |ev|
								if ev.include?("~")
									tdStyle << "nil~nil,"
								else
									tdStyle << "nil,"
								end
							end
							tdStyle = tdStyle[0, tdStyle.length-1]
						end
					end
				end
			end
			#Swati Ahire 19-06-2014: Replaced sectionDetailsDO.includeTd with sectionDetailsDO.includeTD
			if sectionDetailsDO != nil && sectionDetailsDO.includeTD && sectionDetailsDO.includeTD.upcase! == "YES"
				htmlBuffer << "</TD>".force_encoding(Encoding::UTF_8)
			end
			
			if sectionDetailsDO != nil && mvelHashMap["CurrentSignature"] != "" && ((sectionDetailsDO.label1Ruby.to_s != "" && sectionDetailsDO.label1Ruby.include?("getSignature")) || (sectionDetailsDO.label2Ruby.to_s != "" && sectionDetailsDO.label2Ruby.include?("getSignature")))
				returnHashMapPage["signature"] = Array.new if !returnHashMapPage["signature"].is_a?(Array)
				returnHashMapPage["signature"].push(mvelHashMap["CurrentSignature"])
			end
			return returnHashMapPage
		end
		#Returns list of years in string format
		def self.getlist(value, sectionDetailsDOValue)
			numbers = Array.new
			new_str = value.to_s.split(',')
			new_str.each_with_index do |str_arr, i|
				if str_arr.include?('-')
					new_str_arr = str_arr.split('-')
					if new_str_arr[0] == nil || new_str_arr[0].strip  == ""
						next
					end
					if new_str_arr[0].to_i > new_str_arr[1].to_i
						new_str_arr[1].to_i.upto(new_str_arr[0].to_i) do |innerStr|
							numbers.push innerStr
						end
					else
						new_str_arr[0].to_i.upto(new_str_arr[1].to_i) do |innerStr|
							numbers.push innerStr
						end
					end
				else
					numbers.push str_arr.to_i
				end
			end
			yearConditionSort = true
			if sectionDetailsDOValue.include? "yearConditionSort${" and sectionDetailsDOValue.include? "}$yearConditionSort"
				yearConditionSort = extract(sectionDetailsDOValue, "yearConditionSort")
			end
			if yearConditionSort and yearConditionSort.to_s.downcase == "true"
				numbers.sort!
			end
			return numbers
		end

		def self.evaluateExpression(expression, mvelHashMap, policyIO)
				results = MobiSys::DataObjects::Results.new
				results.createAttr('policyIO')
				results.setAttr('policyIO', policyIO)
				results.createAttr('productDO')
				results.setAttr('productDO', mvelHashMap['productDO'])
				results.createAttr('productHash')
				results.setAttr('productHash', mvelHashMap['productHash'])
				# results.createAttr('quotationProductDORiderHashMap')
				# results.setAttr('quotationProductDORiderHashMap',mvelHashMap['quotationProductDORiderHashMap'])
				results.createAttr('mvelHashMap')
				results.setAttr('mvelHashMap', mvelHashMap)
				# results.createAttr('apopolicyIO')
				# results.setAttr('apopolicyIO', mvelHashMap['apopolicyIO'])
				results.defineMethod("testing",expression)
				return results.testing.to_s
		end

		def self.processProperty(value, policyIO, mvelHashMap)
			finalString = "".force_encoding(Encoding::UTF_8)
			staticcontent = value
			
			if staticcontent && staticcontent.include?("si${") && staticcontent.include?("}$si")
				while staticcontent.include?("si${")
					startindex = staticcontent.index("si${")
					finalString << staticcontent[0, startindex].force_encoding(Encoding::UTF_8)
					staticcontent = staticcontent[startindex+"si${".length, staticcontent.length] #Need ruby code
					endindex = staticcontent.index("}$si")
					element = staticcontent[0, endindex]
					element = element.strip

					if policyIO.getIllustrationHeaderFieldValue(element) == nil
						finalString << "Element "+element+" Not found".force_encoding(Encoding::UTF_8) #Need to check if code works in ruby or not
					else
						finalString << policyIO.getIllustrationHeaderFieldValue(element).force_encoding(Encoding::UTF_8)
					end
					staticcontent = staticcontent[endindex+"si${".length,staticcontent.length] #Ruby code required
				end
				return processProperty(finalString + staticcontent, policyIO, mvelHashMap)
			elsif staticcontent && staticcontent.include?("label${") && staticcontent.include?("}$label")
				while staticcontent.include?("label${")
					startindex = staticcontent.index("label${")
					finalString << staticcontent[0, startindex].force_encoding(Encoding::UTF_8)
					staticcontent << staticcontent[startindex+"label${".length, staticcontent.length]
					endindex = staticcontent.index("}$label")
					element = staticcontent[0,endindex]
					element=element.strip
					finalString = MobiSys::UIGenUtilHelper.getLabelValue(element, Application.getValue('DEFAULTLOCALE').value).force_encoding(Encoding::UTF_8)
					staticcontent = staticcontent[endindex+"label${".length, staticcontent.length]
				end
				return processProperty(finalString + staticcontent, policyIO, mvelHashMap)
			elsif staticcontent && staticcontent.include?("mvel${") && staticcontent.include?("}$mvel")
				
				i = 1
				while staticcontent.include?("mvel${")
					startindex = staticcontent.index("mvel${")
					finalString << staticcontent[0,startindex].force_encoding(Encoding::UTF_8)
					staticcontent = staticcontent[startindex + "mvel${".length,staticcontent.length]
					endindex=staticcontent.index("}$mvel")
					element = staticcontent[0,endindex]

					# finalString << evaluateExpression(element, mvelHashMap, policyIO).force_encoding(Encoding::UTF_8)

					begin
						finalString << evaluateExpression(element, mvelHashMap, policyIO).force_encoding(Encoding::UTF_8)
					rescue Exception => e
						finalString << e.to_s
					end

					
					staticcontent = staticcontent[endindex + "mvel${".length, staticcontent.length]
					i+=1
				end
				return processProperty((finalString + staticcontent).gsub("$SEMI$", ";"), policyIO, mvelHashMap)
			else
				finalString = staticcontent
			end
			return finalString
		end

		def self.extract(source,marker)
			
			ext = source[source.index("#{marker}${") + "#{marker}${".length,source.index("}$#{marker}")]
			ext = ext[0,ext.index("}$#{marker}")]
			
			return ext
		end

		#sanket preview for eapp
	    def self.findTemplatePageMapping(policyIO,pageName)

	      product = policyIO.baseDO.baseProductId
	      	productVersion = policyIO.baseDO.getBaseProduct.productVersion
	        applicationType = policyIO.baseDO.getBaseProduct.addtnField1

	     
	      offlineOutputBaseDonVersion= OfflineApplication.loadObject(
	                                                                   		:first,
	                                                                   		:conditions => {
	                                                                   		{:name => 'PROPERTY' } => 'OUTPUTBASEDONVERSION'})

	        finalTemplatePageMappingDOList = []
		      if (offlineOutputBaseDonVersion && offlineOutputBaseDonVersion.value == 'YES')
                if applicationType.to_s != ""
				    queryString ="Select tpmDO.* from OutputContext outputDO , TemplatePageMapping tpmDO where
						  		outputDO.product = '#{product}' and (outputDO.entityTypeCd = 'EAPP')  and outputDO.currency = '#{applicationType}' and outputDO.productVersion = '#{productVersion}' and outputDO.templateMasterSeq = tpmDO.templateMasterSeq
						  		order by tpmDO.displayOrder"
				else
					
					queryString ="Select tpmDO.* from OutputContext outputDO , TemplatePageMapping tpmDO where
			  		outputDO.product = '#{product}' and (outputDO.entityTypeCd = 'EAPP')  and outputDO.productVersion = '#{productVersion}' and outputDO.templateMasterSeq = tpmDO.templateMasterSeq
			  		order by tpmDO.displayOrder"
			  	end

		      templatePageMappingDOList = TemplatePageMapping.find_by_sql(queryString)
		     
		        if(templatePageMappingDOList.size <= 0)
				        	Rho::Notification.showPopup( {:message => "No template defined for product: "+(policyIO.baseProduct ? policyIO.baseProduct.shortName : "" )+" and product version: "+productVersion.to_s, :title => "Error", :icon => :alert, :buttons => ['OK'] }, '/app/Product/popupCallback')
		                 # alert("No template defined for product : "+quotationIO.BaseProduct.shortName+" and product version : "+productVersion)
				end
		          templatePageMappingDOList.each do |templatePageMappingDOListev|
		            finalTemplatePageMappingDOList << templatePageMappingDOListev
		          end
			end
			riderList = policyIO.baseDO.getRiders

			riderListString = ""
				if riderList.to_s!=""
				    maxElement = riderList.size
					riderList.each_with_index do |rider, i|
					riderListString << "'#{rider.productId}'"
					riderListString << "," if i < maxElement - 1
					end
				end
			$policyIO.templatePageMappingDO = finalTemplatePageMappingDOList
        end

		
 		def self.getQuestionnairesDetailsOfParty(policyIO,mvelHashMap)
		        serviceQuestionResponseAgentAFIHashMap=Hash.new
		        serviceQuestionResponseHashMap=Hash.new
		        proposer=policyIO.baseDO.getParty("PROPOSER")
		        
		        @life = Party.loadObject(:first, :conditions=>{{:name=>'guid'}=>proposer.guid})
		     
		        @policy = policyIO.baseDO
		        @quotation = MobiSys::PolicyBO.convertToQuotation(@policy)
		        @baseProduct = MobiSys::QuotationBO.getBaseProduct(@quotation)
		        rowGuidArray=[]
		        gridHM={}
		        gridAgentHM={}
		        rowGuidArrayAgent=[]
		        rowGuidArrayIns = []
		        
		        questionMap={}
		        @allQuestions = QuestionSetQuestion.loadObject(:all)
		        mvelHashMap["allQuestions"]=@allQuestions
		        @allQuestions.each do |quest|
		          questionMap[quest.questionSetCd+"_"+quest.dataElementCd]=quest.question
		        end
		        mvelHashMap["questionMap"]=questionMap

		        @totalQuestionSetQuestionCount = @allQuestions.length
		        questionSetMapData = QuestionSetMap.find(
		            :all,
		            :order => ['parentQuestionSetCd', 'displayOrder']
		        )
		        
		        @questionContainer = QuestionContainer.loadObject(
		            :first,
		            :conditions=>{
		                {:name=>'entityGuid'} => @life.uniqueKey,
		                {:name=>'policyGuid'} => @policy.uniqueKey
		            },
		            :op => 'AND'
		        )

		        primary=@policy.getParty("PRIMARY")
		        @insured=Party.loadObject(:first, :conditions=>{{:name=>'guid'}=>primary.guid})
		        if primary
		           @primaryContainer = QuestionContainer.loadObject(
		            :first,
		            :conditions=>{
		                 {:name=>'entityGuid'} => @insured.uniqueKey,
		                {:name=>'policyGuid'} => policyIO.baseDO.uniqueKey
		           },
		            :op => 'AND'
		        )

		        end


		        
		        @agentContainer = QuestionContainer.loadObject(
		            :first,
		            :conditions=>{
		                {:name=>'entityTypeCd'} => 'AGENT',
		                {:name=>'policyGuid'} => policyIO.baseDO.uniqueKey
		            },
		            :op => 'AND'
		        )

		        #responseHash = MobiSys::Questionnaire.setupResponseHash(@questionContainer)
		       if @primaryContainer
			        @primaryContainer.ServiceQuestionResponseList.each do |serviceQuestionResponse|

			          serviceQuestionResponseHashMap[serviceQuestionResponse.questionSetCd+"_"+serviceQuestionResponse.questionDataElementCd] =  serviceQuestionResponse.responseValue
			          if serviceQuestionResponse.rowGuid!=nil  	
			            rowGuidArrayIns.push(serviceQuestionResponse.rowGuid) 
			          end
			        end
			    end
		        # mvelHashMap["serviceQuestionResponseHashMap"]=serviceQuestionResponseHashMap
		        if @questionContainer	
			        @questionContainer.ServiceQuestionResponseList.each do |serviceQuestionResponse|

			          serviceQuestionResponseHashMap[serviceQuestionResponse.questionSetCd+"_"+serviceQuestionResponse.questionDataElementCd] =  serviceQuestionResponse.responseValue
			          	if serviceQuestionResponse.rowGuid != nil
				          rowGuidArray.push(serviceQuestionResponse.rowGuid)
				        end
			        end
			    end
		        rowGuidArrayCount=rowGuidArray.uniq.sort!
		   
		      	mvelHashMap["rowGuidArrayCount"]=rowGuidArrayCount
		        mvelHashMap["serviceQuestionResponseHashMap"]=serviceQuestionResponseHashMap
		       

		        if @agentContainer
		        @agentContainer.ServiceQuestionResponseList.each do |serviceQuestionResponse|
		          serviceQuestionResponseAgentAFIHashMap[serviceQuestionResponse.questionSetCd+"_"+serviceQuestionResponse.questionDataElementCd] =  serviceQuestionResponse.responseValue
		          if serviceQuestionResponse.rowGuid!=nil
	                rowGuidArrayAgent.push(serviceQuestionResponse.rowGuid)
	              end
		        end
		        mvelHashMap["serviceQuestionResponseAgentAFIHashMap"]=serviceQuestionResponseAgentAFIHashMap
		        end
		      if @questionContainer 
			      for i in rowGuidArrayCount
			        @questionContainer.ServiceQuestionResponseList.each do |serviceQuestionResponse|
			          if serviceQuestionResponse.rowGuid!=nil && serviceQuestionResponse.rowGuid==i
			            gridHM[serviceQuestionResponse.questionSetCd+"_"+serviceQuestionResponse.questionDataElementCd+"_"+serviceQuestionResponse.rowGuid]=serviceQuestionResponse.responseValue
			          end
			        end
			      end
			  end
		      mvelHashMap["gridHM"]=gridHM
		        

		     # end
		        if @primaryContainer

		            rowGuidArrayCountIns=rowGuidArrayIns.uniq.sort!
		          
		            mvelHashMap["rowGuidArrayCount"]=rowGuidArrayCountIns
		           

		            for i in rowGuidArrayCountIns
		              @primaryContainer.ServiceQuestionResponseList.each do |serviceQuestionResponse|
		                if serviceQuestionResponse.rowGuid!=nil && serviceQuestionResponse.rowGuid==i
		                  gridHM[serviceQuestionResponse.questionSetCd+"_"+serviceQuestionResponse.questionDataElementCd+"_"+serviceQuestionResponse.rowGuid]=serviceQuestionResponse.responseValue
		                end
		              end
		            end
		            mvelHashMap["gridHM"]=gridHM
		        end
		        


		    
		      if @agentContainer
		           
		            rowGuidArrayAgentCount=rowGuidArrayAgent.uniq.sort!
		            mvelHashMap["rowGuidArrayAgentCount"]=rowGuidArrayAgentCount

		            for i in rowGuidArrayAgentCount
		              @agentContainer.ServiceQuestionResponseList.each do |serviceQuestionResponse|
		                if serviceQuestionResponse.rowGuid!=nil && serviceQuestionResponse.rowGuid==i
		                  gridAgentHM[serviceQuestionResponse.questionSetCd+"_"+serviceQuestionResponse.questionDataElementCd+"_"+serviceQuestionResponse.rowGuid]=serviceQuestionResponse.responseValue
		                end
		              end
		            end
		            mvelHashMap["gridAgentHM"]=gridAgentHM
		            
		         end# end of party if
		        # end# end of party loop
		     # end
        end


		def self.renderQuestionnaire(questionnaireHash, reflexiveQuestionDO, questionContainer, responseHash, party, quotation, baseProduct)
	      strRetBuff = ""
	      header = ""
	      displayProperty = ""

	      if questionnaireHash[:header].to_s != ""
	        if questionnaireHash[:displayNumber].to_s != ""
	          if questionnaireHash[:questionSetTypeCd] == "LEAF"
	            header = "<div>#{questionnaireHash[:displayNumber]}. #{Localization::LabelCache.instance.getLabel(questionnaireHash[:questionSetCd].to_sym)}</div><br>"
	          else
	            header = "<div class='strongLabel'>#{questionnaireHash[:displayNumber]}. #{Localization::LabelCache.instance.getLabel(questionnaireHash[:questionSetCd].to_sym)}</div><br>"
	          end
	        else
	          if questionnaireHash[:questionSetTypeCd] == "LEAF"

	            header = "<div>#{Localization::LabelCache.instance.getLabel(questionnaireHash[:questionSetCd].to_sym)}</div><br>" if $dis!="No<br>"
	          else
	            header = "<h12 class='strongLabel'>#{Localization::LabelCache.instance.getLabel(questionnaireHash[:questionSetCd].to_sym)}</h12><br>"
	          end
	        end
	      end


	      strRetBuff << "<div class='questionSetBlock' for='#{questionnaireHash[:object]}'>"
	      strRetBuff << header

	      if questionnaireHash.has_key?("listQuestionSetQuestionDOList")

	        reflexiveQuestionDO =  MobiSys::Questionnaire.getReflexiveQuestion(questionnaireHash["listQuestionSetQuestionDOList"]) if !reflexiveQuestionDO

	        if questionnaireHash[:isGridTypeFl] == "YES"
	          renderGridQuestions(questionnaireHash["listQuestionSetQuestionDOList"], reflexiveQuestionDO, strRetBuff, true, questionContainer, responseHash, party)
	        else
	          renderNonGridQuestions(questionnaireHash["listQuestionSetQuestionDOList"], reflexiveQuestionDO, strRetBuff, false, questionContainer, responseHash, party)
	        end
	      end

	      if questionnaireHash.has_key?("listQuestionSetDOList")
	        questionnaireHash["listQuestionSetDOList"].each do |questionSetDO|
	          if questionSetDO[:ruleSeq].to_s == ""
	            reflexiveQuestionDO = MobiSys::Questionnaire.getReflexiveQuestion(questionnaireHash["listQuestionSetQuestionDOList"]) if questionnaireHash.has_key?("listQuestionSetQuestionDOList")
	            strRetBuff << renderQuestionnaire(questionSetDO, reflexiveQuestionDO, questionContainer, responseHash, party, quotation, baseProduct)
	          else
	            # quotationParty = quotation.getPartyByRole(party.roleCd) if party.to_s!=""
	            quotationParty = quotation.getPartyByGuid(party.guid) if party.to_s!=""
	            if quotationParty
	              pdt = MobiSys::ProductUtil.getProductDefinitionTableDO(questionSetDO[:ruleSeq], quotation, baseProduct, quotationParty, false, false)
	            end
	            if quotationParty.to_s!="" && pdt != nil && pdt.outputAction == "YES"
	              reflexiveQuestionDO = MobiSys::Questionnaire.getReflexiveQuestion(questionnaireHash["listQuestionSetQuestionDOList"]) if questionnaireHash.has_key?("listQuestionSetQuestionDOList")
	              strRetBuff << renderQuestionnaire(questionSetDO, reflexiveQuestionDO, questionContainer, responseHash, party, quotation, baseProduct)
	            else
	              ServiceQuestionResponse.delete_all(
	                  :conditions => {
	                      {:name=>'parentkey'} => questionContainer.object,
	                      {:name=>'questionSetCd'} => questionSetDO[:questionSetCd]
	                  },
	                  :op => 'AND'
	              )
	            end
	          end
	        end
	      end

	      strRetBuff << "</div>"
	      return strRetBuff
        end

		def self.renderNonGridQuestions(questionSetQuestionList, reflexiveQuestionDO, strRetBuff, isGridTypeFl, questionContainer, responseHash, party)

	      displayProperty = ""
	      questionSetQuestionList.each do |questionSetQuestionDO|
	        responseObj = getResponse(questionSetQuestionDO, isGridTypeFl, questionContainer, responseHash, party)

	        if questionSetQuestionDO[:inputTypeCd].to_s == "HIDDEN"
	          htmlString, displayProperty = renderQuestionAnswer(questionSetQuestionDO, reflexiveQuestionDO, responseObj,isGridTypeFl, questionContainer, responseHash, party)
	          strRetBuff << htmlString
	        else
	          htmlString, displayProperty = renderQuestionAnswer(questionSetQuestionDO, reflexiveQuestionDO, responseObj, isGridTypeFl, questionContainer, responseHash, party)

	         if displayProperty.to_s!="no"
	          strRetBuff << "<table class='***Ans 2' border:1px solid black;><tr>"
	          strRetBuff << "<td style='width:1000px' class='active---1'>#{Localization::LabelCache.instance.getLabel(questionSetQuestionDO[:questionCd].to_sym)}</td>"
	          strRetBuff << "<td>"+htmlString+"</td>"
	          strRetBuff << "</tr></table>"
	         end
	        end
	      end
	      return displayProperty
        end

		def self.renderGridQuestions(questionSetQuestionList, reflexiveQuestionDO, strRetBuff, isGridTypeFl, questionContainer, responseHash, party)

	      if reflexiveQuestionDO != nil
	        responseObj = getResponse(reflexiveQuestionDO, false, questionContainer, responseHash, party)

	        if reflexiveQuestionDO[:inputTypeCd].to_s == "HIDDEN"
	          htmlString, displayProperty = renderQuestionAnswer(questionSetQuestionDO, reflexiveQuestionDO, responseObj, isGridTypeFl, questionContainer, responseHash, party)
	          strRetBuff << htmlString
	        else
	          htmlString, displayProperty = renderQuestionAnswer(reflexiveQuestionDO, reflexiveQuestionDO, responseObj, isGridTypeFl, questionContainer, responseHash, party)
	         if displayProperty!="no"
	          strRetBuff << "<table border:1px solid black;><tr>"
	          strRetBuff << "<td style='width:1000px' class='active--2'>#{Localization::LabelCache.instance.getLabel(reflexiveQuestionDO[:questionCd].to_sym)}</td>"
	          strRetBuff << "<td>"+htmlString+"</td>"
	          strRetBuff << "</tr></table>"
	         end
	        end
	      end
	      reflexiveResponseObj = responseObj
	      rowGuidArray = getRowGuidArray(questionSetQuestionList, reflexiveQuestionDO, responseHash, party)
	      rowGuidArray.push(0) if rowGuidArray.empty?
	      for i in rowGuidArray
	        strRetBuff << "<table class='illustrationdisplay questionSetBlock' data-rowguid='#{i}' data-removed='false'><tr>"

	        questionSetQuestionList.each do |questionSetQuestionDO|
	          if (reflexiveQuestionDO != nil && questionSetQuestionDO[:questionCd] != reflexiveQuestionDO[:questionCd]) || reflexiveQuestionDO == nil
	            responseObj = getResponse(questionSetQuestionDO, isGridTypeFl, questionContainer, responseHash, party, i)

	            if questionSetQuestionDO[:inputTypeCd].to_s == "HIDDEN"
	              htmlString, displayProperty = renderQuestionAnswer(questionSetQuestionDO, reflexiveQuestionDO, responseObj, isGridTypeFl, questionContainer, responseHash, party)
	              strRetBuff << "<table><tr>"
	              strRetBuff << "<td>"+htmlString.force_encoding("UTF-8")+"</td>"
	              strRetBuff << "</tr></table>"
	            else

	              htmlString, displayProperty = renderQuestionAnswer(questionSetQuestionDO, reflexiveQuestionDO, responseObj, isGridTypeFl, questionContainer, responseHash, party)


	              if displayProperty.to_s!="no"
	                strRetBuff << "<table border:1px solid black;><tr>"
	                strRetBuff << "<td style='width:1000px' class='active'>#{Localization::LabelCache.instance.getLabel(questionSetQuestionDO[:questionCd].to_sym).force_encoding("UTF-8")}</td>"
	                strRetBuff << "<td>"+htmlString.force_encoding("UTF-8")+"</td>"
	                strRetBuff << "</tr></table>"
	              end
	            end
	          end
	        end

	        strRetBuff << "</div>"

	      end
	      return displayProperty
        end
		#############################################################################################

		def self.getLabel(labelKey)
	      toreturn_str = ""

	      begin
	        toreturn_str << Localization::LabelCache.instance.getLabel(labelKey.to_sym).to_s.force_encoding("UTF-8")
	      rescue StandardError => se
	        puts se
	      end

	      return toreturn_str
        end

		def self.getResponse(questionSetQuestion, isGridTypeFl, questionContainer, responseHash, party, rowGuid=nil)
			if isGridTypeFl
				if party
					key = "#{questionSetQuestion[:questionSetCd]}|#{questionSetQuestion[:dataElementCd]}|#{party.uniqueKey}"
				else
					key = "#{questionSetQuestion[:questionSetCd]}|#{questionSetQuestion[:dataElementCd]}"
				end
				key << "|#{rowGuid}" if rowGuid
				if !responseHash.has_key?(key) || responseHash[key] == nil
					values = {
							:entityGuid => questionContainer.entityGuid,
							:questionSetCd => questionSetQuestion[:questionSetCd],
							:questionDataElementCd => questionSetQuestion[:dataElementCd],
							:rowGuid => rowGuid,
							:removed => ""
					}

					serviceQuestionResponse = ServiceQuestionResponse.new(values)
					serviceQuestionResponse.partyGuid = party.uniqueKey if party
					questionContainer.addServiceQuestionResponse(serviceQuestionResponse)
				else
					serviceQuestionResponse = responseHash[key]
				end
			else
				if party
					key = "#{questionSetQuestion[:questionSetCd]}|#{questionSetQuestion[:dataElementCd]}|#{party.uniqueKey}"
				else
					key = "#{questionSetQuestion[:questionSetCd]}|#{questionSetQuestion[:dataElementCd]}"
				end
				if !responseHash.has_key?(key) || responseHash[key] == nil
					values = {
							:entityGuid => questionContainer.entityGuid,
							:questionSetCd => questionSetQuestion[:questionSetCd],
							:questionDataElementCd => questionSetQuestion[:dataElementCd],
							:removed => ""
					}
					serviceQuestionResponse = ServiceQuestionResponse.new(values)
					serviceQuestionResponse.partyGuid = party.uniqueKey if party
					questionContainer.addServiceQuestionResponse(serviceQuestionResponse)
					responseHash[key] = serviceQuestionResponse
				else
					serviceQuestionResponse = responseHash[key]
				end
			end

			return serviceQuestionResponse
		end

		#sankett change the html here
		def self.renderQuestionAnswer(questionSetQuestion, reflexiveQuestionDO, responseObj, isGridTypeFl, questionContainer, responseHash, party)

			output = ""
			displayProperty = ""
			maxLength = questionSetQuestion[:maxLength]
			parent = "data-questioncd='#{questionSetQuestion[:questionSetCd]}|#{questionSetQuestion[:dataElementCd]}'"
			if reflexiveQuestionDO != nil && '#{reflexiveQuestionDO[:questionSetCd]}|#{reflexiveQuestionDO[:dataElementCd]}' != '#{questionSetQuestion[:questionSetCd]}|#{questionSetQuestion[:dataElementCd]}'
				parentName = questionSetQuestion[:dataParent]
				if parentName.to_s != ""
					questionSetCd = parentName.split('|')[0]
					dataElementCd = parentName.split('|')[1]
					parentQ = QuestionSetQuestion.find(
							:first,
							:conditions=>{
									{:name=>'dataElementCd'} => dataElementCd,
									{:name=>'questionSetCd'} => questionSetCd
							},
							:op => 'AND'
					)
					parentResponseObj = getResponse(parentQ.hashForSync, isGridTypeFl, questionContainer, responseHash, party)
					if parentResponseObj && parentResponseObj.responseValue == questionSetQuestion[:condReflexiveValue]
						displayProperty = ""
						responseObj.removed = ""
					else
						#displayProperty = "style='display:none;'"
						displayProperty = "no"
						responseObj.removed = "YES"
					end
				end

				parent << " data-parent='#{questionSetQuestion[:dataParent]}'"
				parent << " data-reflexivevalue='#{questionSetQuestion[:condReflexiveValue]}'"
			end

			case questionSetQuestion[:inputTypeCd]
				when "TEXT"
					parent << " maxLength= '#{maxLength}'"
					 output << responseObj.responseValue if responseObj.responseValue.to_s!=""
				when "DATE"
					output << renderDateField("responseValue", responseObj.responseValue, nil, responseObj, parent)
				when "RADIO"
					parent << " onClick = '$(this).reflexiveParentChildDisplayMapping(this);'" if questionSetQuestion[:conditional] == "REFLEXIVE"
					radioLookup = Lookupvalue.find(:all, :conditions=>{'key'=>questionSetQuestion[:lookupkey]})
					lookups = Array.new
					if radioLookup && radioLookup.size > 0
						sortByOrderLookups,remainingLookups = radioLookup.partition{|lookup| lookup.sortOrder.to_s != ""}
						sortByOrderLookups.sort_by!{|lookUp| lookUp.sortOrder.to_i} if sortByOrderLookups.size > 0
						remainingLookups.sort!{|a, b| a.desc.to_s <=> b.desc.to_s} if remainingLookups.size > 0
						lookups = sortByOrderLookups.concat remainingLookups
					end

					lookups.each do |lookup|
						if questionSetQuestion[:lookupkey] != "YESNO"
							output << Localization::LabelCache.instance.getLabel(responseObj.responseValue.to_sym)  if responseObj.responseValue.to_s!=""
						elsif lookup.cd == "YES"
							output << Localization::LabelCache.instance.getLabel(responseObj.responseValue.to_sym) if responseObj.responseValue.to_s!=""
						end
					end
				when "COMBO", "NCOMBO"
					output <<  Localization::LabelCache.instance.getLabel(responseObj.responseValue.to_sym).to_s.force_encoding("UTF-8")  if responseObj.responseValue.to_s!=""
				when "TEXTAREA"
					parent << " maxLength= '#{maxLength}'"
					output <<  Localization::LabelCache.instance.getLabel(responseObj.responseValue.to_sym).to_s.force_encoding("UTF-8") if responseObj.responseValue.to_s!=""
				when "HIDDEN"
					output << responseObj.responseValue if responseObj.responseValue.to_s!=""
			end
			 $dis=""
			 $dis = output
			 output << "<br>"


			
			return output,displayProperty
		end

		#Method to get an array of all rowGuid values within a list of QuestionSetQuestions
		def self.getRowGuidArray(questionSetQuestionList, reflexiveQuestionDO, responseHash, party)
			rowGuidArray = []
			questionSetQuestionList.each do |questionSetQuestion|
				if (reflexiveQuestionDO != nil && questionSetQuestion[:questionCd] != reflexiveQuestionDO[:questionCd]) || reflexiveQuestionDO == nil
					responseHash.each do |key, response|
						if key.include?("#{questionSetQuestion[:questionSetCd]}|#{questionSetQuestion[:dataElementCd]}|#{party.uniqueKey}")
							rowGuidArray.push(response.rowGuid.to_i)
						end
					end
				end
			end
			return rowGuidArray.uniq.sort!
		end
		#############################################################################################
		def self.getSupplementaryTable(policyIO,mvelHashMap,roleCd,guid = false)

			count=0;
			finalString="";

			isProposerPresent=false;

			policyIO.baseDO.PolicyProductList.each do |ppDO|
				ppDO.PolicyProductInsuredList.each do |pqDO|

			if(pqDO.roleCd == "PROPOSER")

				isProposerPresent=true;
			end;
			end;
			end;
			if(isProposerPresent==true)

			count=3;

			else

			count=2;
			end;

			policyIO.baseDO.getPartyList("SUPPLEMENTARY").each do |ppDO|

			finalString+=("<table style=\"width: 100%$SEMI$border-collapse:collapse;border: 1px solid black$SEMI$\" cellpadding=\"3px\" cellspacing=\"0px\">");
			finalString+=("<tr><td></td><td><input type=\"button\" onclick=\"get_tab('getQuestionnaires','#{ppDO.object.to_s}')\" value=\"EDIT\" style=\"float: right$SEMI$\"></td></tr>");
			finalString+=("<tr bgcolor=\"#eaac25\">");

			if(count == 2)

				finalString+=("<td style=\"border:1px solid black$SEMI$\" class=\"Qtableheaderfontsize\"><b>");
				finalString+=(MobiSys::UIGenUtilHelper.getLabelValue("qheader1","VT"));
				finalString+=("</b><br/>");
			end;
			if(count == 3)

				finalString+=("<td style=\"border:1px solid black$SEMI$\" class=\"Qtableheaderfontsize\"><b>");
				finalString+=(MobiSys::UIGenUtilHelper.getLabelValue("qheader2","VT"));
				finalString+=("</b><br/>");
			end;

			if(count == 4)

				finalString+=("<td style=\"border:1px solid black$SEMI$\" class=\"Qtableheaderfontsize\"><b>");
				finalString+=(MobiSys::UIGenUtilHelper.getLabelValue("qheader3","VT"));
				finalString+=("</b><br/>");
			end;

			if(count == 5)

				finalString+=("<td style=\"border:1px solid black$SEMI$\" class=\"Qtableheaderfontsize\"><b>");
				finalString+=(MobiSys::UIGenUtilHelper.getLabelValue("qheader4","VT"));
				finalString+=("</b><br/>");
			end;

			if(count == 6)

				finalString+=("<td style=\"border:1px solid black$SEMI$\" class=\"Qtableheaderfontsize\"><b>");
				finalString+=(MobiSys::UIGenUtilHelper.getLabelValue("qheader5","VT"));
				finalString+=("</b><br/>");
			end;

			if(count == 7)

				finalString+=("<td style=\"border:1px solid black$SEMI$\" class=\"Qtableheaderfontsize\"><b>");
				finalString+=(MobiSys::UIGenUtilHelper.getLabelValue("qheader6","VT"));
				finalString+=("</b><br/>");
			end;

			if(count == 8)

				finalString+=("<td style=\"border:1px solid black$SEMI$\" class=\"Qtableheaderfontsize\"><b>");
				finalString+=(MobiSys::UIGenUtilHelper.getLabelValue("qheader7","VT"));
				finalString+=("</b><br/>");
			end;

			finalString+=(ppDO.lastName1 != nil ? ppDO.lastName1 : "");

			if(count == 2)

				finalString+=("</td>");
				finalString+=("<td style=\"border:1px solid black$SEMI$\" class=\"Qtableheaderfontsize\"><b>");
				finalString+=(MobiSys::UIGenUtilHelper.getLabelValue("qans1","VT"));
				finalString+=("</b><br/>");
			end;
			if(count == 3)

				finalString+=("</td>");
				finalString+=("<td style=\"border:1px solid black$SEMI$\" class=\"Qtableheaderfontsize\"><b>");
				finalString+=(MobiSys::UIGenUtilHelper.getLabelValue("qans2","VT"));
				finalString+=("</b><br/>");
			end;
			if(count == 4)

				finalString+=("</td>");
				finalString+=("<td style=\"border:1px solid black$SEMI$\" class=\"Qtableheaderfontsize\"><b>");
				finalString+=(MobiSys::UIGenUtilHelper.getLabelValue("qans3","VT"));
				finalString+=("</b><br/>");
			end;

			if(count == 5)

				finalString+=("</td>");
				finalString+=("<td style=\"border:1px solid black$SEMI$\" class=\"Qtableheaderfontsize\"><b>");
				finalString+=(MobiSys::UIGenUtilHelper.getLabelValue("qans4","VT"));
				finalString+=("</b><br/>");
			end;
			if(count == 6)

				finalString+=("</td>");
				finalString+=("<td style=\"border:1px solid black$SEMI$\" class=\"Qtableheaderfontsize\"><b>");
				finalString+=(MobiSys::UIGenUtilHelper.getLabelValue("qans5","VT"));
				finalString+=("</b><br/>");
			end;
			if(count == 7)

				finalString+=("</td>");
				finalString+=("<td style=\"border:1px solid black$SEMI$\" class=\"Qtableheaderfontsize\"><b>");
				finalString+=(MobiSys::UIGenUtilHelper.getLabelValue("qans6","VT"));
				finalString+=("</b><br/>");
			end;
			if(count == 8)

				finalString+=("</td>");
				finalString+=("<td style=\"border:1px solid black$SEMI$\" class=\"Qtableheaderfontsize\"><b>");
				finalString+=(MobiSys::UIGenUtilHelper.getLabelValue("qans7","VT"));
				finalString+=("</b><br/>");
			end;

			# finalString+=(getQuestionnairesDetailsOfParty(policyIO,mvelHashMap,ppDO.roleCd,ppDO.guid));
			finalString+=("</table>");

			count=count.to_i+1
			end;

			return finalString;
		end

		def self.getSupplementaryTable1(policyIO,mvelHashMap,roleCd,guid = false)

			count=0;
			finalString="";

			isProposerPresent=false;


			 policyIO.baseDO.PolicyProductList.each do |ppDO|
				ppDO.PolicyProductInsuredList.each do |pqDO|

			if(pqDO.roleCd == "JOINT")

				isProposerPresent=true;
			end;
			end;
			end;
			if(isProposerPresent==true)

			count=3;

			else

			count=2;
			end;

			policyIO.baseDO.getPartyList("SUPPLEMENTARY").each do |ppDO|

			finalString+=("<table style=\"width: 100%$SEMI$border-collapse:collapse;border: 1px solid black$SEMI$\" cellpadding=\"3px\" cellspacing=\"0px\">");
			finalString+=("<tr><td></td><td><input type=\"button\" onclick=\"get_tab('getQuestionnaires','#{ppDO.object}')\" value=\"EDIT\" style=\"float: right$SEMI$\"></td></tr>");
			finalString+=("<tr bgcolor=\"#eaac25\">");

			if(count == 2)

				finalString+=("<td style=\"border:1px solid black$SEMI$\" class=\"Qtableheaderfontsize\"><b>");
				finalString+=(MobiSys::UIGenUtilHelper.getLabelValue("qheader1","VT"));
				finalString+=("</b><br/>");
			end;
			if(count == 3)

				finalString+=("<td style=\"border:1px solid black$SEMI$\" class=\"Qtableheaderfontsize\"><b>");
				finalString+=(MobiSys::UIGenUtilHelper.getLabelValue("qheader2","VT"));
				finalString+=("</b><br/>");
			end;

			if(count == 4)

				finalString+=("<td style=\"border:1px solid black$SEMI$\" class=\"Qtableheaderfontsize\"><b>");
				finalString+=(MobiSys::UIGenUtilHelper.getLabelValue("qheader3","VT"));
				finalString+=("</b><br/>");
			end;

			if(count == 5)

				finalString+=("<td style=\"border:1px solid black$SEMI$\" class=\"Qtableheaderfontsize\"><b>");
				finalString+=(MobiSys::UIGenUtilHelper.getLabelValue("qheader4","VT"));
				finalString+=("</b><br/>");
			end;

			if(count == 6)

				finalString+=("<td style=\"border:1px solid black$SEMI$\" class=\"Qtableheaderfontsize\"><b>");
				finalString+=(MobiSys::UIGenUtilHelper.getLabelValue("qheader5","VT"));
				finalString+=("</b><br/>");
			end;

			if(count == 7)

				finalString+=("<td style=\"border:1px solid black$SEMI$\" class=\"Qtableheaderfontsize\"><b>");
				finalString+=(MobiSys::UIGenUtilHelper.getLabelValue("qheader6","VT"));
				finalString+=("</b><br/>");
			end;

			if(count == 8)

				finalString+=("<td style=\"border:1px solid black$SEMI$\" class=\"Qtableheaderfontsize\"><b>");
				finalString+=(MobiSys::UIGenUtilHelper.getLabelValue("qheader7","VT"));
				finalString+=("</b><br/>");
			end;
			finalString+=(ppDO.lastName1 != nil ? ppDO.lastName1 : "");

			if(count == 2)

				finalString+=("</td>");
				finalString+=("<td style=\"border:1px solid black$SEMI$\" class=\"Qtableheaderfontsize\"><b>");
				finalString+=(MobiSys::UIGenUtilHelper.getLabelValue("qans1","VT"));
				finalString+=("</b><br/>");
			end;
			if(count == 3)

				finalString+=("</td>");
				finalString+=("<td style=\"border:1px solid black$SEMI$\" class=\"Qtableheaderfontsize\"><b>");
				finalString+=(MobiSys::UIGenUtilHelper.getLabelValue("qans2","VT"));
				finalString+=("</b><br/>");
			end;
			if(count == 4)

				finalString+=("</td>");
				finalString+=("<td style=\"border:1px solid black$SEMI$\" class=\"Qtableheaderfontsize\"><b>");
				finalString+=(MobiSys::UIGenUtilHelper.getLabelValue("qans3","VT"));
				finalString+=("</b><br/>");
			end;
			if(count == 5)

				finalString+=("</td>");
				finalString+=("<td style=\"border:1px solid black$SEMI$\" class=\"Qtableheaderfontsize\"><b>");
				finalString+=(MobiSys::UIGenUtilHelper.getLabelValue("qans4","VT"));
				finalString+=("</b><br/>");
			end;
			if(count == 6)

				finalString+=("</td>");
				finalString+=("<td style=\"border:1px solid black$SEMI$\" class=\"Qtableheaderfontsize\"><b>");
				finalString+=(MobiSys::UIGenUtilHelper.getLabelValue("qans5","VT"));
				finalString+=("</b><br/>");
			end;
			if(count == 7)

				finalString+=("</td>");
				finalString+=("<td style=\"border:1px solid black$SEMI$\" class=\"Qtableheaderfontsize\"><b>");
				finalString+=(MobiSys::UIGenUtilHelper.getLabelValue("qans6","VT"));
				finalString+=("</b><br/>");
			end;
			if(count == 8)

				finalString+=("</td>");
				finalString+=("<td style=\"border:1px solid black$SEMI$\" class=\"Qtableheaderfontsize\"><b>");
				finalString+=(MobiSys::UIGenUtilHelper.getLabelValue("qans7","VT"));
				finalString+=("</b><br/>");
			end;

			# finalString+=(getQuestionnairesDetailsOfParty(policyIO,mvelHashMap,ppDO.roleCd,ppDO.guid));
			finalString+=("</table>");

			count=count.to_i+1
			end;

			return finalString;
		end

		def self.getSignature(mvelHashMap, signatureGuid)
			policy = mvelHashMap["policyDO"]
			serviceSignature = nil
			signatureContainer = SignatureContainer.loadObject(:first, :conditions => {:entityGuid => policy.guid})
		    serviceSignature = signatureContainer.ServiceSignatureList.select{|serviceSign| serviceSign.guid == signatureGuid}.first if signatureContainer
		    if serviceSignature.to_s != ""
		    	if serviceSignature.signature.to_s != "" && serviceSignature.signature.to_s.start_with?('ZLIBCMP')
		    		serviceSignature.signature = serviceSignature.signature.gsub!('ZLIBCMP','')
		    		original_signature_decoded = MobiSys::Encryption.decodeContents(serviceSignature.signature)
		    		uncompressed_signature = MobiSys::Encryption.unZipData(original_signature_decoded)
		    		serviceSignature.signature = 'data:image/png;base64,' + MobiSys::Encryption.encodeContents(uncompressed_signature)
		    	end
		    	sigantureImage = "<img src='#{serviceSignature.signature}' id='signature#{signatureGuid}_img' width='245' height='50'>"
		    else
		    	sigantureImage = "<img id='signature#{signatureGuid}_img' width='245' height='50' style='display:none'>"
		    end
		    return sigantureImage
		end

		def self.getSignatureDt(mvelHashMap, signatureGuid)
			policy = mvelHashMap["policyDO"]
			serviceSignature = nil
			signatureDtHtml = ""
			signatureContainer = SignatureContainer.loadObject(:first, :conditions => {:entityGuid => policy.guid})
		    serviceSignature = signatureContainer.ServiceSignatureList.select{|serviceSign| serviceSign.guid == signatureGuid}.first if signatureContainer
		    if serviceSignature.to_s != "" && serviceSignature.signatureDt.to_s != ""
		    	time = Time.parse(serviceSignature.signatureDt.to_s)
    			signatureDt = time.strftime("%d-%b-%Y").upcase
			end
			signatureDtHtml = "<span id='signature#{signatureGuid}_dt'>#{signatureDt}</span>"
		    return signatureDtHtml
		end

		def self.getSignaturePlace(mvelHashMap, signatureGuid)
			policy = mvelHashMap["policyDO"]

			signaturePlaceHtml = ""
			signaturePlaceHtml = "<span id='captureSignature_#{signatureGuid}_placeOfSignature'></span>"
		    return signaturePlaceHtml
		end

		
	end
end

