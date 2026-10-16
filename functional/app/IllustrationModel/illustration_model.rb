# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
class IllustrationModel
	include MobiSys::MobiSysFixedSchema

	set :schema_version, '1.0'
	set :partition, :master

	# Uncomment the following line to enable sync with IllustrationModel.
	# enable :sync

	#add model specifc code here
	property :modelCd, :string
	property :modelDesc, :string
	property :computationFrequencyCd, :string
	property :xslTemplateName, :string
	property :modelFor, :string
	property :useGeneratedCode, :string
	property :generateResults, :string
	property :riskCd, :string
	property :computePerInstanceOf, :string
	property :executeIterativelyFl, :string

	# derived attributes
	property :parentKey, :string
	property :versionID, :integer
	property :id, :integer
	property :guid, :string
	property :systemCreatedDt, :time
	property :systemUpdatedDt, :time

	has_many 'IllustrationFacet'
	has_many 'IllustrationRate'

	index :im_modelCd, [:modelCd]

	def self.onlineClassName
		return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.product.IllustrationModelDO"
	end


	def getIllustrationRate(rateType, fundCd = nil, year = nil)
		self.IllustrationRateList.each do |rate|
			if rateType == rate.rateTypeCd
				if fundCd
					if fundCd == rate.fundCd
						if rate.policyYearFrom.to_s == "" || year.to_s == ""
							return rate
						elsif rate.policyYearFrom.to_s != "" && year.to_s != "" && rate.policyYearTo.to_s != ""
							if rate.policyYearFrom.to_i <= year.to_i && rate.policyYearTo.to_i >= year.to_i
								return rate
							end
						end
					end 
				elsif rate.policyYearFrom.to_s != "" && year.to_s != "" && rate.policyYearTo.to_s != ""
					if rate.policyYearFrom.to_i <= year.to_i && rate.policyYearTo.to_i >= year.to_i
						return rate
					end
				else
					return rate
				end
			end
		end
		return nil 
	end


	def getIllustrationRateListForType(rateType)
		illustrationRateListForType = Array.new
		self.IllustrationRateList.each do |rate|
			illustrationRateListForType.push rate if rate.rateTypeCd == rateType
		end #self.IllustationRateList.each do |rate|
		return illustrationRateListForType
	end


	# This method is to be overridden at company layer to explicitly type cast additional fields
	def typeCastingAdditionalFields(facet)
		# This is just an example of how  to typecast additional field
		# facet.expression.gsub!("self.quotation.quotAddtnlField4.to_s", "self.quotation.quotAddtnlField4.to_i")
	end  


	#Method to perform actual regex replacement operation
	def regexReplacer(sourceString, regex, replacementString, objectClass)
		#Hashmap of attributes which do not match across models
		fieldsMapper = {
			:occupationClass    => "occupationCd",
			:firstName1         => "firstname",
			:lastName1          => "lastname",
			:proposalEntryDt    => "quotationDt",
			:proposalReceivedDt => "quotationDt",
			:proposalSignedDt   => "quotationDt",
			:policyIssueDt      => "quotationDt",
			:baseProductId      => "productId",
			:birthDt            => "dob",
			:jointLife          => "jointLifeFlag",
			:maritalStatusCd    => "maritalStatus",
			:educationLevelCd   => "educationCd"
		}
		sourceString.gsub!(regex) do |match|
			#Initialize replacementString for each set of matches
			replacementStringModified = replacementString
			#For model based regex replacement
			if objectClass.to_s != ""
				#Extract attribute/method for evaluation
				attribute = Regexp.last_match[2][1..-1].to_s
				#Special case wherein multiple match groups are present
				if Regexp.last_match.size == 4
					attribute = Regexp.last_match[3][1..-1].to_s
					replacementStringModified = replacementString+Regexp.last_match[2]
				end
				if attribute != ""
					#Replace attribute with target model attribute in case of mismatch
					attribute = fieldsMapper[attribute.to_sym] if fieldsMapper.has_key?(attribute.to_sym) && self.modelFor.to_s != 'UNDERWRITING' && self.modelFor.to_s != 'POLICY' && self.modelFor.to_s != 'DYNAMICDT'
					#Append to_s or to_f based on dataType of attribute defined in the model
					if Rho::RhoConfig.sources[objectClass]["schema"]["property"].has_key?(attribute)
						dataType = Rho::RhoConfig.sources[objectClass]["schema"]["property"][attribute][0].to_s
						if dataType == "float"
							if objectClass == "QuotationParty" && (match.include?(".PartyDO") || match.include?("PolicyJointLifeDO") || match.include?("PolicyProposerDO") || match.include?("PolicyPrimaryInsuredDO"))
								match = replacementStringModified+"."+attribute+").to_f"
							elsif match.include?("PolicyOtherPartyDOWithRelation") || match.include?("PolicyOtherPartyDOWithRole")
								match = "("+replacementStringModified+"==nil?0.0:"+replacementStringModified+"."+attribute+".to_f)"
							else
								match = replacementStringModified+"."+attribute+".to_f"
							end
						elsif dataType == "integer" 
							if objectClass == "QuotationParty" && (match.include?(".PartyDO") || match.include?("PolicyJointLifeDO") || match.include?("PolicyProposerDO") || match.include?("PolicyPrimaryInsuredDO"))
								match = replacementStringModified+"."+attribute+").to_i"
							elsif match.include?("PolicyOtherPartyDOWithRelation") || match.include?("PolicyOtherPartyDOWithRole")
								match = "("+replacementStringModified+"==nil?0:"+replacementStringModified+"."+attribute+".to_i)"
							else
								match = replacementStringModified+"."+attribute+".to_i"
							end
						else
							if objectClass == "QuotationParty" && (match.include?(".PartyDO") || match.include?("PolicyJointLifeDO") || match.include?("PolicyProposerDO") || match.include?("PolicyPrimaryInsuredDO"))
								match = replacementStringModified+"."+attribute+").to_s"
							elsif match.include?("PolicyOtherPartyDOWithRelation") || match.include?("PolicyOtherPartyDOWithRole")
								match = "("+replacementStringModified+"==nil?'':"+replacementStringModified+"."+attribute+".to_s)"
							else
								match = replacementStringModified+"."+attribute+".to_s"
							end
						end
					#Check for method on model as an exact match
					elsif Object.const_get(objectClass).instance_methods(false).include?(attribute.to_sym)
						if objectClass == "QuotationParty" && (match.include?(".PartyDO") || match.include?("PolicyJointLifeDO") || match.include?("PolicyProposerDO") || match.include?("PolicyPrimaryInsuredDO"))
							match = replacementStringModified+"."+attribute+")"
						elsif match.include?("PolicyOtherPartyDOWithRelation") || match.include?("PolicyOtherPartyDOWithRole")
							match = "("+replacementStringModified+"==nil?nil:"+replacementStringModified+"."+attribute+")"
						else
							match = replacementStringModified+"."+attribute
						end
					#Check for method on model in the form of .get*
					elsif Object.const_get(objectClass).instance_methods(false).include?(("get"+attribute[0].upcase+attribute[1..-1]).to_sym)
						if objectClass == "QuotationParty" && (match.include?(".PartyDO") || match.include?("PolicyJointLifeDO") || match.include?("PolicyProposerDO") || match.include?("PolicyPrimaryInsuredDO"))
							match = replacementStringModified+".get"+attribute[0].upcase+attribute[1..-1]+")"
						elsif match.include?("PolicyOtherPartyDOWithRelation") || match.include?("PolicyOtherPartyDOWithRole")
							match = "("+replacementStringModified+"==nil?nil:"+replacementStringModified+".get"+attribute[0].upcase+attribute[1..-1]+")"
						else
							match = replacementStringModified+".get"+attribute[0].upcase+attribute[1..-1]
						end
					#If nothing matches append attribute as is
					else
						if objectClass == "QuotationParty" && (match.include?(".PartyDO") || match.include?("PolicyJointLifeDO") || match.include?("PolicyProposerDO") || match.include?("PolicyPrimaryInsuredDO"))
							match = replacementStringModified+"."+attribute+")"
						elsif match.include?("PolicyOtherPartyDOWithRelation") || match.include?("PolicyOtherPartyDOWithRole")
							match = "("+replacementStringModified+"==nil?nil:"+replacementStringModified+"."+attribute+")"
						elsif objectClass == "QuestionSet"
							match = replacementStringModified+"['"+attribute+"']"
						else
							match = replacementStringModified+"."+attribute
						end
					end
				#If attribute is blank just perform match replacement  
				else
					if objectClass == "QuotationParty" && (match.include?(".PartyDO") || match.include?("PolicyJointLifeDO") || match.include?("PolicyProposerDO") || match.include?("PolicyPrimaryInsuredDO"))
						match = replacementStringModified+")"
					elsif match.include?("PolicyOtherPartyDOWithRelation") || match.include?("PolicyOtherPartyDOWithRole")
						match = "("+replacementStringModified+"==nil?nil:"+replacementStringModified+")"
					else
						match = replacementStringModified
					end
				end
			#For string based regex replacement
			else
				if Regexp.last_match.size == 3
					if replacementStringModified.include?("include")
						match = replacementStringModified+"("+Regexp.last_match[2]+")"
					elsif replacementStringModified.include?("group_valueAsOf")
						firstChar = Regexp.last_match[2].slice(0,1)
						if firstChar == firstChar.upcase
							match = replacementStringModified+"'"+Regexp.last_match[2].downcase+"'"
						else
							match = replacementStringModified+"'"+Regexp.last_match[2]+"'"
						end
					else
						match = replacementStringModified+"["+Regexp.last_match[2]+"]"
					end
				else
					match = replacementStringModified
				end
			end
		end
		return sourceString
	end


	def afterSync
		puts "+++After sync called for modelcd #{self.modelCd}"
		if self.modelFor == "SI"
			case self.xslTemplateName
			when 'quotation/SunSmartLifeQuote'
				self.xslTemplateName = 'SunSmartL1ifeQuote'
			when 'quotation/FWD'
				self.xslTemplateName = 'newBenefitTable'  
			end
		end

		if self.computePerInstanceOf
			replacements = [ ["DO", ""], ["()", ""], ["getList", "get"], [".List", "."], ["BaseIO", "Policy"] ]
			# replacements = [ ["DO", ""], ["()", ""]] if self.modelFor == "POLICY"
			replacements.each {|replacement| self.computePerInstanceOf.gsub!(replacement[0], replacement[1])}
		end

		#Regex conditions and replacement values for IllustrationModel facets
		regexQuotationConditions = [
			[
				Regexp.new(/(com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyRiderDO.getPolicyProduct\()(\"[\w\"\,]*\"\))(\.?\w*)/), 
				'self.quotationProduct.getQuotationProduct(self.quotation,',
				'QuotationProduct'
			],
			[
				Regexp.new(/(com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyRiderDO.getPolicyProductAdditionalDO\()(\"[\w\"\,]*\"\))(\.?\w*)/), 
				'self.quotationProduct.getPolicyProductAdditionalDO(self.quotation,',
				'QuotationProductAdditional'
			],
			[
				Regexp.new(/(PolicyOtherRiderExtraDO.getPolicyProduct\()(\"\w*\"\))(\.?[\w\(\)\"]*)/), 
				'self.quotationProduct.getQuotationProduct(self.quotation,',
				'QuotationProduct'
			],
			[
				Regexp.new(/(com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyProductDO|com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyRiderDO|PolicyBasePlanExtraDO|PolicyRiderExtraDO)(\.?\w*)/), 
				'self.quotationProduct',
				'QuotationProduct'
			],
			[
				Regexp.new(/(PolicyBasePlanDO)(\.?\w*)/), 
				'self.basePlan',
				'QuotationProduct'
			],
			[
				Regexp.new(/(PolicyMainRiderDO)(\.?\w*)/), 
				'self.quotation.getMainRider(self.quotationProduct)',
				'QuotationProduct'
			],
			[
				Regexp.new(/(PolicyMainRiderExtraDO)(\.?\w*)/), 
				'self.quotation.getMainRider(self.quotationProduct)',
				'QuotationProduct'
			],
			[
				Regexp.new(/(com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyDO.getBasePlanAdditionalDO\(\))(\.?\w*)/), 
				'self.quotation.getBasePlanAdditionalDO',
				'QuotationProductAdditional'
			],
			[
				Regexp.new(/(com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyDO)(\.?\w*)/), 
				'self.quotation',
				'Quotation'
			],
			[
				Regexp.new(/(PolicyOtherPartyDOWithRelation.getPartyByRelation\()(\"\w*\"\))(\.?[\w\"]*)/),  
				'self.quotation.getPartyByRelation(',
				'QuotationParty'
			],
			[
				Regexp.new(/(PolicyOtherPartyDOWithRole.getPartyByRole\()(\"\w*\"\))(\.?[\w\"]*)/),  
				'self.quotation.getPartyByRole(',
				'QuotationParty'
			],
			[
				Regexp.new(/(com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PartyDO|com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.party.PartyDO)(\.?\w*)/), 
				'(self.quotation.getParty(self.quotationProduct)==nil?nil:self.quotation.getParty(self.quotationProduct)',
				'QuotationParty'
			],
			[
				Regexp.new(/(PolicyJointLifeDO)(\.?\w*)/), 
				"(self.quotation.getPartyByRole('JOINT')==nil?nil:self.quotation.getPartyByRole('JOINT')",
				'QuotationParty'
			],
			[
				Regexp.new(/(PolicyProposerDO)(\.?\w*)/), 
				"(self.quotation.getPartyByRole('PROPOSER')==nil?nil:self.quotation.getPartyByRole('PROPOSER')",
				'QuotationParty'
			],
			[
				Regexp.new(/(PolicyPrimaryInsuredDO)(\.?\w*)/), 
				"(self.quotation.getPartyByRole('PRIMARY')==nil?nil:self.quotation.getPartyByRole('PRIMARY')",
				'QuotationParty'
			],
			[
				Regexp.new(/(com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyWithdrawalDO)(\.?\w*)/), 
				'self.quotation.getWithdrawal(currPolicyYear.to_i)',
				'QuotationWithdrawal'
			],
			[
				Regexp.new(/(PolicyWithdrawalCatgDO\.\()(\"[\w\"\,\s]*\"\))(\.?\w*)/), 
				'self.quotation.getPolicyWithdrawalByCategory(currPolicyYear.to_i, currPolicyMonth.to_i,',
				'QuotationWithdrawal'
			],
			[
				Regexp.new(/(com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyTopUpDO.getPolicyTopup\()(\"\w*\"\))(\.?[\w\"]*)/), 
				'self.quotation.getQuotationTopup(currPolicyYear.to_i,',
				'QuotationTopUp'
			],
			[
				Regexp.new(/(com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyTopUpDO.regularPolicyTopupAmt)(\.?\w*)/), 
				'self.quotation.getRegularPolicyTopupAmt(currPolicyYear.to_i)',
				'QuotationTopUp'
			],
			[
				Regexp.new(/(com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyTopUpDO.initialInvestmentAmt)(\.?\w*)/), 
				'self.quotation.getInitialInvestmentAmt(currPolicyYear.to_i)',
				'QuotationTopUp'
			],
			[
				Regexp.new(/(com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyTopUpDO.regularTopUpPeriod)(\.?\w*)/), 
				'self.quotation.getRegularTopUpPeriod.to_f',
				'QuotationTopUp'
			],
			[
				Regexp.new(/(com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyTopUpDO)(\.?\w*)/), 
				'self.quotation.getTopup(currPolicyYear.to_i)',
				'QuotationTopUp'
			],
			[
				Regexp.new(/(com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyProductInvestmentFundDO)(\.?\w*)/), 
				'investmentFund',
				'QuotationProductInvestmentFund'
			],
			[
				Regexp.new(/(PolicyAdditionalFieldsDO)(\.?\w*)/), 
				'self.quotation.getQuotationAdditionalFieldsDO',
				'QuotationAdditionalFields'
			],
			[
				'Base Plan.', 
				'self.basePlan.',
				''
			],
			[
				'group_summation',
				'self.quotationIO.group_summation',
				''
			],
			[
				'group_minimum',
				'self.quotationIO.group_minimum',
				''
			],
			[
				'group_maximum',
				'self.quotationIO.group_maximum',
				''
			],
			[
				'group_irr',
				'self.quotationIO.group_irr',
				''
			],
			[
				'group_irr_NotNull',
				'self.quotationIO.group_irr_NotNull',
				''
			],
			[
				'group_valueAsOf',
				'self.quotationIO.group_valueAsOf',
				''
			],
			[
				'group_ProjectionValue',
				'self.quotationIO.group_ProjectionValue',
				''
			],
			[
				'input_maximum',
				'self.quotationIO.input_maximum',
				''
			],
			[
				'input_minimum',
				'self.quotationIO.input_minimum',
				''
			],
			[
				'currCycleCount',
				'self.currCycleCount',
				''
			],
			[
				'currPolicyYear',
				'self.currPolicyYear',
				''
			],
			[
				'currPolicyMonth',
				'self.currPolicyMonth',
				''
			],
			[
				'currIllusNetRate',
				'self.currIllusNetRate',
				''
			],
			[
		        'BreakType',
		        'breaktype',
		        ''
		    ]
		]
		#Regex conditions and replacement values for UWModel facets
		regexUWConditions = [
			[
				Regexp.new(/(com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyRiderDO.getPolicyProduct\()(\"[\w\"\,]*\"\))(\.?\w*)/),
				'@currentProcessingValues[POLPRODUCT_DO].getPolicyProduct(@currentProcessingValues[POLICY_DO],',
				'PolicyProduct'
			],
			[
				Regexp.new(/(com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyRiderDO.getPolicyProductForParty\()(\"[\w\"\,]*\"\,[\w\"\.]*\))(\.?\w*)/),
				'@currentProcessingValues[POLPRODUCT_DO].getPolicyProductForParty(@currentProcessingValues[POLICY_DO],',
				'PolicyProduct'
			],
	      	[
	        	Regexp.new(/(com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyRiderDO)(\.?\w*)/), 
	        	'@currentProcessingValues[POLRIDER_DO]',
	        	'QuotationProduct'
	      	],
			[
				Regexp.new(/(com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyProductDO)(\.?\w*)/), 
				'@currentProcessingValues[POLPRODUCT_DO]',
				'PolicyProduct'
			],
			[
				Regexp.new(/(PolicyRiderExtraDO)(\.?\w*)/), 
				'@currentProcessingValues[POLPRODUCT_DO]',
				'PolicyProductExtra'
			],
			[
				Regexp.new(/com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyDO.PolicyAdditionalFieldsDO.field21/), 
				"@currentProcessingValues[POLICY_DO].@currentProcessingValues[POLPRODUCT_DO].topUpTypeCd",
				''
			],
			[
				Regexp.new(/(com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyDO.initialPaymentMethods)(\.?\w*)/), 
				"@currentProcessingValues[POLICY_DO].getInitialPaymentMethods",
				''
			],
			[
				Regexp.new(/(com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyDO)(\.?\w*)/), 
				'@currentProcessingValues[POLICY_DO]',
				'Policy'
			],
			[
				Regexp.new(/(com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyWithdrawalDO)(\.?\w*)/), 
				'@currentProcessingValues[POLICYWITHDRAWAL_DO]',
				'Policy'
			],
			[
				Regexp.new(/(com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyTopUpDO)(\.?\w*)/), 
				'@currentProcessingValues[POLICYTOPUP_DO]',
				'Policy'
			],
			[
				Regexp.new(/(com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PartyDO|com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.party.PartyDO|PartyDO)(\.?\w*)/), 
				'@currentProcessingValues[PARTY_DO]',
				'Party'
			],
			[
				Regexp.new(/(PolicyJointLifeDO)(\.?\w*)/), 
				"@currentProcessingValues[POLICY_DO].getParty('JOINT')",
				'Party'
			],
			[
				Regexp.new(/(PolicyProposerDO)(\.?\w*)/), 
				"@currentProcessingValues[POLICY_DO].getParty('PROPOSER')",
				'Party'
			],
			[
				Regexp.new(/(PolicyPrimaryInsuredDO)(\.?\w*)/), 
				"@currentProcessingValues[POLICY_DO].getParty('PRIMARY')",
				'Party'
			],
			[	
				Regexp.new(/(PolicySupplementaryLifeDO)(\.?\w*)/), 
				"@currentProcessingValues[POLICY_DO].getParty('SUPPLEMENTARY')",
				'Party'
			],
			[
				Regexp.new(/(PolicyOtherPartyDOWithRole.getPartyByRole\()(\"\w*\"\))(\.?[\w\"]*)/),  
				'@currentProcessingValues[POLICY_DO].getPartyByRole(',
				'Party'
			],
			[
				Regexp.new(/(PartyEmploymentDO)(\.?\w*)/), 
				"@currentProcessingValues[PARTY_DO].getPartyEmployment",
				'PartyEmployment'
			],
			[
				Regexp.new(/(PartyAddressDO)(\.?\w*)/), 
				"@currentProcessingValues[PARTYADDRESS_DO]",
				'PartyAddress'
			],
			[
				Regexp.new(/(PartyIdentityDO)(\.?\w*)/), 
				"@currentProcessingValues[PARTYIDENTITY_DO]",
				'PartyIdentity'
			],
			[
				Regexp.new(/(getPartyAdditionalFieldsDO\(\))(\.?\w*)/),
				'getPartyAdditionalField(true)',
				'PartyAdditionalFields'
			],
			[
				Regexp.new(/(PartyAdditionalFieldsDO)(\.?\w*)/), 
				'@currentProcessingValues[PARTYADDTNL_DO]',
				'PartyAdditionalFields'
			],
			[
				Regexp.new(/(PolicyQuestionSetDO.get\()(\.?\w*)/), 
				'@currentProcessingValues[QUESTIONNAIRE_ELEMS].get(',
				'QuestionSet'
			],
			[
				Regexp.new(/(PolicyBasePlanExtraDO)(\.?\w*)/), 
				'@currentProcessingValues[POLBASEPLAN_DO]',
				'PolicyProductExtra'
			],
			[
				Regexp.new(/(PolicyBasePlanDO)(\.?\w*)/), 
				'@currentProcessingValues[POLBASEPLAN_DO]',
				'PolicyProduct'
			],
			[
				Regexp.new(/(PolicyBasePlanMultiExtraDO)(\.?\w*)/), 
				'self.quotation.getBasePlanMulti(currInsured)',
				'QuotationProduct'
			],
			[
				Regexp.new(/(PolicyAdditionalFieldsDO)(\.?\w*)/), 
				'@currentProcessingValues[POLICYADDTNL_DO]',
				'PolicyAdditionalFields'
			],
			[
				Regexp.new(/(PolicyPartyRoleDO)(\.?\w*)/), 
				"@currentProcessingValues[PARTYROLE_DO]",
				'PolicyPartyRole'
			],
			[
				Regexp.new(/(PolicyDocumentDO.get\()(\.?\w*)/), 
				'@currentProcessingValues[DOCUMENT_ELEMS].get(',
				'QuestionSet'
			],
			[
				Regexp.new(/(PolicyDocumentDO)(\.?\w*)/), 
				'@currentProcessingValues[DOCUMENT_ELEMS]',
				'ServiceDocument'
			],
			[
				Regexp.new(/(AgentDO)(\.?\w*)/), 
				"@currentProcessingValues[AGENT_DO]",
				'AgentReg'
			],
			[
				Regexp.new(/(PolicyUWRiskResultDO)(\.?\w*)/), 
				'@currentProcessingValues[UWRISKRESULT_DO]',
				'QuestionSet'
			],
            [
            	Regexp.new(/(com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyDO.getPayerPolicyPartyRoleDO)(\.?\w*)/), 
                '@currentProcessingValues[POLICY_DO].getPayerPartyRole',
                'PolicyPartyRole'
            ],
            [
            	Regexp.new(/(com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyDO.riderCountForParty)(\.?\w*)/), 
                '@currentProcessingValues[POLICY_DO].getRiderCountForParty(@currentProcessingValues[PARTY_DO].guid)',
                'Policy'
            ],
            [
            	Regexp.new(/(com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyDO.lifeCountForRider)(\.?\w*)/), 
                '@currentProcessingValues[POLICY_DO].getLifeCountForRider(@currentProcessingValues[POLPRODUCT_DO].productId)',
                'Policy'
            ],
            [
                Regexp.new(/(PolicyBasePlanMultiDO)(\.?\w*)/), 
                '@currentProcessingValues[POLBASEPLANMULTI_DO]',
                'PolicyProduct'
            ],
            [
				Regexp.new(/(com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyProductInvestmentFundDO|PolicyProductInvestmentFundDO)(\.?\w*)/), 
				'@currentProcessingValues[PLANINVESTMENTFUND_DO]',
				'PolicyProductInvestmentFund'
			],
			[
				Regexp.new(/(PolicyModelOtherResultDO)(\.?\w*)/), 
				'@currentProcessingValues[OTHERMODELRESULT_DO]',
				'QuestionSet'
			],
			[
				Regexp.new(/(BaseIO)(\.?\w*)/), 
				'@currentProcessingValues[BASE_IO]',
				'Policy'
			],
			[
				Regexp.new(/(ProductMasterDO)(\.?\w*)/), 
				'@currentProcessingValues[PRD_MASTER]',
				'QuestionSet'
			],
			[  ### this is to replace only word PolicyQuestionSetDO
				Regexp.new(/(PolicyQuestionSetDO)(\.?\w*)/), 
				'@currentProcessingValues[QUESTIONNAIRE_ELEMS]',
				'QuestionSet'
			],
			[
				'currentUWDecisionPriority',
				'@currentProcessingValues["currentUWDecisionPriority"]',
				''
			],
			[
				'previousUWDecisionPriority',
				'@currentProcessingValues["previousUWDecisionPriority"]',
				''
			],
			[
				Regexp.new(/(uwDecisionCount).get\((\"\w*\")\)/), 
				'@uwDecisionCount',
				''
			],
			[
				Regexp.new(/(uwDecisionCount).([^get\(\"]\w*)/), 
				'@uwDecisionCount',
				''
			],
			[
				Regexp.new(/(uwDecisionPriority).get\((\"\w*\")\)/), 
				'@uwDecisionPriority',
				''
			],
			[
				Regexp.new(/(uwDecisionPriority).([^get\(\"]\w*)/), 
				'@uwDecisionPriority',
				''
			],
			[
				Regexp.new(/(currentUWDecision)(?!.*Priority)/),
				'@currentProcessingValues["currentUWDecision"]',
				''
			],
			[
				Regexp.new(/(peviousUWDecision)(?!.*Priority)/),
				'@currentProcessingValues["previousUWDecision"]',
				''
			],
			[
				'getPartyByRole',
				'getParty',
				''
			],
			[
				'getAddress',
				'getPartyAddress',
				''
			],
			[
				'riderCount',
				'getRiderCount',
				''
			],
			[
				'nomineeCount',
				'getNomineeCount',
				''
			],
			[
				'supplementaryLivesCount',
				'getSupplementaryLivesCount',
				''
			],
			[
				'industryCd',
				'getIndustryCd',
				''
			],
			[
				'occupationCd',
				'getOccupationCd',
				''
			],
			[
				'natureOfDuty',
				'getNatureOfDuty',
				''
			],
			[
				'occupationTypeCd',
				'getOccupationTypeCd',
				''
			],
			[
				'getPartyEmployment.getIndustryCd',
				'getPartyEmployment.industryCd',
				''
			],
			[
				'getPartyEmployment.getOccupationCd',
				'getPartyEmployment.occupationCd',
				''
			],
			[
				'getPartyEmployment.getNatureOfDuty',
				'getPartyEmployment.natureOfDuty',
				''
			],
			[
				'getPartyEmployment.getOccupationTypeCd',
				'getPartyEmployment.occupationTypeCd',
				''
			],
			[
				'currUIAction',
				'@currentProcessingValues[CURRENT_UIACTION]',
				''
			],
			[
				'currCycleCount',
				'@currentProcessingValues[CURRENT_CYCLE]',
				''
			],
			[
				'group_summation',
				'@currentProcessingValues[QUOTATION_IO].group_summation',
				''
			],
			[
				'group_minimum',
				'@currentProcessingValues[QUOTATION_IO].group_minimum',
				''
			],
			[
				'group_maximum',
				'@currentProcessingValues[QUOTATION_IO].group_maximum',
				''
			],
			[
				'group_irr',
				'@currentProcessingValues[QUOTATION_IO].group_irr',
				''
			],
			[
				'group_irr_NotNull',
				'@currentProcessingValues[QUOTATION_IO].group_irr_NotNull',
				''
			],
			[
				'group_ProjectionValue',
				'@currentProcessingValues[QUOTATION_IO].group_ProjectionValue',
				''
			],
			[
				'input_maximum',
				'@currentProcessingValues[QUOTATION_IO].input_maximum',
				''
			],
			[
				'input_minimum',
				'@currentProcessingValues[QUOTATION_IO].input_minimum',
				''
			],
			[
                Regexp.new(/(group_valueAsOf\()\"(\w*)\"/), 
				'@currentProcessingValues[QUOTATION_IO].group_valueAsOf(',
				''
			],
			[
				'currActiveTab',
				'@currentProcessingValues[CURRENT_UITAB]'
			],
			[
				'getListCalculation()',
				'@currentProcessingValues[QUOTATION_IO].listCalculation'
			]
		]
		#Regex common utility conditions and replacement values
		regexUtilityConditions = [
			[
				'&lt;', 
				'<',
				''
			],
			[
				'&gt;',
				'>',
				''
			],
			[
				'&amp;&amp;',
				'&&',
				''
			],
			[
				'?',
				' ? ',
				''
			],
			[
				':',
				' : ',
				''
			],
			[
				'(int)',
				'MobiSys::Math.toInt',
				''
			],
			[
				'Math.pow(', 
				'MobiSys::Math.pow(',
				''
			],
			[
				'Math.log(', 
				'::Math.log(',
				''
			],
			[
				'Math.log10(', 
				'::Math.log10(',
				''
			],
			[
				'Math.log1p(', 
				'::Math.log(1+',
				''
			],
			[
				'Math.round(', 
				'MobiSys::Math.round(',
				''
			],
			[
				'com.c2lbiz.symbiosys.systemcommon.util.CommonUtil.getRoundedUpDouble(', 
				'MobiSys::Math.roundUp(',
				''
			],
			[
				'com.c2lbiz.symbiosys.systemcommon.util.CommonUtil.getRoundedDownDouble(', 
				'MobiSys::Math.roundDown(',
				''
			],
			[
				'com.c2lbiz.symbiosys.systemcommon.util.CommonUtil.getRoundedNearestDouble(', 
				'MobiSys::Math.roundNearest(',
				''
			],
			[
				'com.c2lbiz.symbiosys.systemcommon.util.CommonUtil.getAmountFormat(', 
				'MobiSys::Math.getAmountFormat(',
				''
			],
			[
				'com.c2lbiz.symbiosys.systemcommon.util.CommonUtil.getRoundedNearestDoubleB(', 
				'MobiSys::Math.roundNearest(',
				''
			],
			[
				'com.c2lbiz.symbiosys.systemcommon.util.CommonUtil.mround(', 
				'MobiSys::Math.mround(',
				''
			],
			[
				'com.c2lbiz.symbiosys.systemcommon.util.CommonUtil.ceiling(', 
				'MobiSys::Math.ceiling(',
				''
			],
			[
				'com.c2lbiz.symbiosys.systemcommon.util.CommonUtil.floor(', 
				'MobiSys::Math.floor(',
				''
			],
			[
				'com.c2lbiz.symbiosys.systemcommon.util.DateUtil.getNearestAge(', 
				'MobiSys::ProductUtil.getNearestAge(',
				''
			],
			[
				'com.c2lbiz.symbiosys.systemcommon.util.DateUtil.getDifferenceInDays(', 
				'MobiSys::ProductUtil.getDifferenceInDays(',
				''
			],
			[
				'Round nearest decimal(', 
				'MobiSys::Math.roundNearestDecimal(',
				''
			],
			[
				'com.c2lbiz.symbiosys.systemcommon.util.DateUtil.getDate(',
				'MobiSys::PolicyBO.getDBDateTemp(',
				''
			],
			[
				'com.c2lbiz.symbiosys.systemcommon.util.DateUtil.getDifferenceInMonths(',
				'MobiSys::DateTimeUtils.dateDifferenceInMonths(',
				''
			],
			[
				'com.c2lbiz.symbiosys.systemcommon.util.DateUtil.forwardSqlDateByDays(',
				'MobiSys::DateTimeUtils.forwardSqlDateByDays(',
				''
			],
			[
				'com.c2lbiz.symbiosys.systemcommon.util.DateUtil.forwardSqlDateByMonths(',
				'MobiSys::DateTimeUtils.forwardSqlDateByMonths(',
				''
			],
			[
				'com.c2lbiz.symbiosys.systemcommon.util.DateUtil.forwardSqlDateByYear(',
				'MobiSys::DateTimeUtils.forwardSqlDateByYear(',
				''
			],
			[
				'DateDifferenceInDays',
				'MobiSys::DateTimeUtils.dateDifferenceInDays',
				''
			],
			[
				'negativeSign',
				'MobiSys::Math.negativeSign',
				''
			],
			[
				'YEAR_OF(',
				'MobiSys::DateTimeUtils.year(',
				''
			],
			[
				'MONTH_OF(',
				'MobiSys::DateTimeUtils.month(',
				''
			],
			[
				'DAY_OF(',
				'MobiSys::DateTimeUtils.day(',
				''
			],
			[
				'FormatDate',
				'MobiSys::DateTimeUtils.formatDate',
				''
			],
			[
				'com.c2lbiz.symbiosys.systemcommon.util.DateUtil.getSystemDate()',
				'Time.now',
				''
			],
			[
				'null',
				'(nil)',
				''
			],
			[
				'"',
				"'",
				''
			],
			[
				"'(nil)'",
				'nil',
				''
			],
			[
				'com.c2lbiz.symbiosys.systemcommon.util.CommonUtil.getStringValue(', 
				'String(',
				''
			],
			[
				'com.c2lbiz.symbiosys.systemcommon.util.CommonUtil.getDoubleValue', 
				'MobiSys::CommonUtil.getDoubleValue',
				''
			],
			[
				'createException(',
				'MobiSys::CommonUtil.createException(@currentProcessingValues[POLICY_DO].guid,',
				''
			],
			[
				'toUpperCase()', 
				'upcase',
				''
			],
			[
				'.length()',
				'.to_s.size',
				''
			],
			[
				Regexp.new(/(\[contains\]|contains|\.contains)(\(?'?[a-zA-Z0-9_]*\'?\)?)/),
				'.include?',
				''
			],
			[
				'isObjectSelected',
				'selected',
				''
			],
			[
				'.to_i= ',
				' = ',
				''
			],
			[
				'.to_s= ',
				' = ',
				''
			],
			[
				'.to_f= ',
				' = ',
				''
			],
			[
				'.substring(', 
				'.to_s.slice(',
				''
			],
			[
				'com.c2lbiz.symbiosys.systemcommon.util.ParameterUtil.getLookupDataDesc(', 
				'getLookupValDesc(',
				''
			],
			[
				'com.c2lbiz.symbiosys.systemcommon.util.ParameterUtil.getLookupDataObject(', 
				'getLookupDataObject(',
				''
			]
		]

		caseHash = Hash.new
		self.IllustrationFacetList.each do |facet|
			#Step 1: Modify computed element name values in computedElementName, computedFieldNameForRule, inputDataElement, expression
			#Change computedElementName - start
			facet.origElementName = "#{facet.computedElementName.to_s}"
			firstChar = facet.computedElementName.slice(0,1)
			if firstChar == firstChar.upcase
				#if facet.computedElementName == facet.computedElementName.upcase
				#implies computedElementName is in upper case. Change it to lower case
				caseHash[facet.computedElementName] = facet.computedElementName.downcase
				facet.computedElementName.downcase!
				#Condition done for checking if first element is number or not
				#If yes prefix it with "_"
			elsif firstChar === /\A[+-]?\d+\z/
				newElementName = "_"+facet.computedElementName
				caseHash[facet.computedElementName] = newElementName
				facet.computedElementName = newElementName
			end  
			#Change computedElemetName - end

			#Step 2: Modify expression based on replacement conditions
			if facet.expression.to_s != ""
				facet.expression = facet.expression.gsub(/( |(".*?"))/, "\\2")
				if self.modelFor == 'UNDERWRITING' || self.modelFor == 'POLICY' || self.modelFor == 'DYNAMICDT'
					regexUWConditions.each do |regexArray|
						regexReplacer(facet.expression.to_s, regexArray[0], regexArray[1], regexArray[2])
					end
				else
					regexQuotationConditions.each do |regexArray|
						regexReplacer(facet.expression.to_s, regexArray[0], regexArray[1], regexArray[2])
					end
					# facet.expression = ""
				end
				regexUtilityConditions.each do |regexArray|
					regexReplacer(facet.expression.to_s, regexArray[0], regexArray[1], regexArray[2])
				end
				typeCastingAdditionalFields(facet)

				# removing typecasting for assigining statements
				
				regex = Regexp.new(/(.to_f|.to_s|.to_i)=[^=]/)
				matchedStr = facet.expression.to_s.match(regex).to_s
				if matchedStr != ""
					replacementStr = matchedStr[0..4] # get .to_i/.to_s/.to_f
					replaceMatchedStr = matchedStr.gsub(replacementStr,"")
					facet.expression.gsub!(matchedStr,replaceMatchedStr)
				end

			end

			#Step 3: Modify inputElementSource & inputDataElement based on replacement conditions
			if facet.inputElementSource == 'com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyDO'
				inputDE = facet.inputDataElement
				case inputDE
				when "proposerLADifferent"
					facet.inputDataElement = "getProposerLADifferent"
				when "proposalEntryDt"
					facet.inputDataElement = "quotationDt"
				when "proposalReceivedDt"
					facet.inputDataElement = "quotationDt"
				when "proposalSignedDt"
					facet.inputDataElement = "quotationDt"
				when "policyIssueDt"
					facet.inputDataElement = "quotationDt"
				when "jointLife"
					facet.inputDataElement = "getJointLifeFlag"
				when "riderCount"
					facet.inputDataElement = "getRiderCount"    
				end
				facet.inputElementSource = "quotation"
			elsif facet.inputElementSource == 'com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.party.PartyDO'
				inputDE = facet.inputDataElement
				case inputDE
				when "birthDt"
					facet.inputElementSource = "quotation.getParty(quotationProduct)"
					facet.inputDataElement = "dob"
				when "genderCd"
					facet.inputElementSource = "quotation.getParty(quotationProduct)"
					facet.inputDataElement = "genderCd"
				when "smoker"
					facet.inputElementSource = "quotation.getParty(quotationProduct)"
					facet.inputDataElement = "smoker"
				when "firstName1"
					facet.inputElementSource = "quotation.getParty(quotationProduct)"
					facet.inputDataElement = "firstname"
				when "lastName1"
					facet.inputElementSource = "quotation.getParty(quotationProduct)"
					facet.inputDataElement = "lastname"
				when "occupationClass"
					facet.inputElementSource = "quotation.getParty(quotationProduct)"
					facet.inputDataElement = "occupationCd"
				when "age"
					facet.inputElementSource = "quotation.getParty(quotationProduct)"
					facet.inputDataElement = "age"
				when "maritalStatusCd"
					facet.inputElementSource = "quotation.getParty(quotationProduct)"
					facet.inputDataElement = "maritalStatus"
				when "educationLevelCd"
					facet.inputElementSource = "quotation.getParty(quotationProduct)"
					facet.inputDataElement = "educationCd"
				when "coverageCityCd"
					facet.inputElementSource = "quotation.getParty(quotationProduct)"
					facet.inputDataElement = "coverageCityCd"
				end
			elsif facet.inputElementSource == 'com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyProductDO'
				inputDE = facet.inputDataElement
				case inputDE
				when "emrDuration"
					facet.inputDataElement = "emrDuration.to_f"
				when "flatExtraDuration"
					facet.inputDataElement = "flatExtraDuration.to_f"
				when "occuExtra"
					facet.inputDataElement = "occuExtra.to_f"
				when "occuExtraDuration"
					facet.inputDataElement = "occuExtraDuration.to_f"
				when "productFamilyCd"
					facet.inputDataElement = "productFamilyCd"
				when "paymentFrequencyCd"
					facet.inputDataElement = "paymentFrequencyCd"
				when "healthExtra"
					facet.inputDataElement = "healthExtra.to_f"
				when "healthExtraDuration"
					facet.inputDataElement = "healthExtraDuration.to_f"
				when "annuityAge"
					facet.inputDataElement = "annuityAge.to_f"
				when "annuityPerc"
					facet.inputDataElement = "annuityPerc.to_f"
				when "ropPerc"
					facet.inputDataElement = "ropPerc.to_f"
				when "discountPerc"
					facet.inputDataElement = "discountPerc.to_f"
				when "discountDuration"
					facet.inputDataElement = "discountDuration.to_f"
				when "annuityOptionCd"
					facet.inputDataElement = "annuityOptionCd"
				when "nsapExtra"
					facet.inputDataElement = "nsapExtra.to_f"
				when "nsapExtraDuration"
					facet.inputDataElement = "nsapExtraDuration.to_f"
				when "productTypeCd"
					facet.inputDataElement = "productTypeCd"
				when "addtnField1"
					facet.inputDataElement = "addtnField1"
				when "addtnField2"
					facet.inputDataElement = "addtnField2"
				when "addtnField3"
					facet.inputDataElement = "addtnField3"
				when "portfolioModelCd"
					facet.inputDataElement = "portfolioModelCd"
				when "annualizedPremium"
					facet.inputDataElement = "annualizedPremium.to_f"
				when "totAnnualizedPremium"
					facet.inputDataElement = "totAnnualizedPremium.to_f"
				when "educationCess"
					facet.inputDataElement = "educationCess.to_f"
				when "serviceTax"
					facet.inputDataElement = "serviceTax.to_f"
				when "extraPremium"
					facet.inputDataElement = "extraPremium.to_f"
				when "totDiscount"
					facet.inputDataElement = "totDiscount.to_f"
				when "monthlyIncome"
					facet.inputDataElement = "monthlyIncome.to_f"
				when "annualIncome"
					facet.inputDataElement = "annualIncome.to_f"
				when "baseAnnualPremium"
					facet.inputDataElement = "baseAnnualPremium.to_f"
				when "productId"
					facet.inputDataElement = "productId.to_f"
				when "productTerm"
					facet.inputDataElement = "productTerm.to_f"
				when "premiumPayingTerm"
					facet.inputDataElement = "premiumPayingTerm.to_f"
				when "baseSumAssured"
					facet.inputDataElement = "baseSumAssured.to_f"
				when "modalPremium"
					facet.inputDataElement = "modalPremium.to_f"
				when "emr"
					facet.inputDataElement = "emr.to_f"
				when "flatExtra"
					facet.inputDataElement = "flatExtra.to_f"
				when "productPlanOptionCd"
					facet.inputDataElement = "productPlanOptionCd"
				when "paymentFrequencyInMonths"
					facet.inputDataElement = "getPaymentFrequencyInMonths.to_f"
				when "currencyCd"
					facet.inputDataElement = "currencyCd"
				when "paymentTypeCd"
					facet.inputDataElement = "paymentTypeCd"
				when "paymentFrequencyCd"
					facet.inputDataElement = "paymentFrequencyCd"
				when "capturedPremiumAmt"
					facet.inputDataElement = "capturedPremiumAmt.to_f"
				end
				facet.inputElementSource = "quotationProduct"
			elsif facet.inputElementSource == 'com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyBasePlanDO'
				inputDE = facet.inputDataElement
				case inputDE
				when "emrDuration"
					facet.inputDataElement = "emrDuration.to_f"
				when "flatExtraDuration"
					facet.inputDataElement = "flatExtraDuration.to_f"
				when "occuExtra"
					facet.inputDataElement = "occuExtra.to_f"
				when "occuExtraDuration"
					facet.inputDataElement = "occuExtraDuration.to_f"
				when "productFamilyCd"
					facet.inputDataElement = "productFamilyCd"
				when "paymentFrequencyCd"
					facet.inputDataElement = "paymentFrequencyCd"
				when "healthExtra"
					facet.inputDataElement = "healthExtra.to_f"
				when "healthExtraDuration"
					facet.inputDataElement = "healthExtraDuration.to_f"
				when "annuityAge"
					facet.inputDataElement = "annuityAge.to_f"
				when "annuityPerc"
					facet.inputDataElement = "annuityPerc.to_f"
				when "ropPerc"
					facet.inputDataElement = "ropPerc.to_f"
				when "discountPerc"
					facet.inputDataElement = "discountPerc.to_f"
				when "discountDuration"
					facet.inputDataElement = "discountDuration.to_f"
				when "annuityOptionCd"
					facet.inputDataElement = "annuityOptionCd"
				when "nsapExtra"
					facet.inputDataElement = "nsapExtra.to_f"
				when "nsapExtraDuration"
					facet.inputDataElement = "nsapExtraDuration.to_f"
				when "productTypeCd"
					facet.inputDataElement = "productTypeCd"
				when "addtnField1"
					facet.inputDataElement = "addtnField1"
				when "addtnField2"
					facet.inputDataElement = "addtnField2"
				when "addtnField3"
					facet.inputDataElement = "addtnField3"
				when "portfolioModelCd"
					facet.inputDataElement = "portfolioModelCd"
				when "annualizedPremium"
					facet.inputDataElement = "annualizedPremium.to_f"
				when "totAnnualizedPremium"
					facet.inputDataElement = "totAnnualizedPremium.to_f"
				when "educationCess"
					facet.inputDataElement = "educationCess.to_f"
				when "serviceTax"
					facet.inputDataElement = "serviceTax.to_f"
				when "extraPremium"
					facet.inputDataElement = "extraPremium.to_f"
				when "totDiscount"
					facet.inputDataElement = "totDiscount.to_f"
				when "monthlyIncome"
					facet.inputDataElement = "monthlyIncome.to_f"
				when "annualIncome"
					facet.inputDataElement = "annualIncome.to_f"
				when "baseAnnualPremium"
					facet.inputDataElement = "baseAnnualPremium.to_f"
				when "productId"
					facet.inputDataElement = "productId.to_f"
				when "productTerm"
					facet.inputDataElement = "productTerm.to_f"
				when "premiumPayingTerm"
					facet.inputDataElement = "premiumPayingTerm.to_f"
				when "baseSumAssured"
					facet.inputDataElement = "baseSumAssured.to_f"
				when "modalPremium"
					facet.inputDataElement = "modalPremium.to_f"
				when "emr"
					facet.inputDataElement = "emr.to_f"
				when "flatExtra"
					facet.inputDataElement = "flatExtra.to_f"
				when "productPlanOptionCd"
					facet.inputDataElement = "productPlanOptionCd"
				when "paymentFrequencyInMonths"
					facet.inputDataElement = "getPaymentFrequencyInMonths.to_f"
				when "currencyCd"
					facet.inputDataElement = "currencyCd"
				when "paymentTypeCd"
					facet.inputDataElement = "paymentTypeCd"
				when "paymentFrequencyCd"
					facet.inputDataElement = "paymentFrequencyCd"
				when "capturedPremiumAmt"
					facet.inputDataElement = "capturedPremiumAmt.to_f"
				end
				facet.inputElementSource = "basePlan"
			#Topup start
			elsif facet.inputElementSource == 'com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyTopUpDO'
				inputDE = facet.inputDataElement
				case inputDE
				when "topupFrequencyValUnit"
					facet.inputDataElement = "topupFrequencyValUnit"
					facet.inputElementSource = "quotation.getTopup( currPolicyYear )"
				when "policyYearFrom"
					facet.inputDataElement = "policyYearFrom"
					facet.inputElementSource = "quotation.getTopup( currPolicyYear )"
				when "policyYearTo"
					facet.inputDataElement = "policyYearTo"
					facet.inputElementSource = "quotation.getTopup( currPolicyYear )"
				when "topUpAmount"
					facet.inputDataElement = "topUpAmount"
					facet.inputElementSource = "quotation.getTopup( currPolicyYear )"
				when "topupFrequencyVal"
					facet.inputDataElement = "topupFrequencyVal"
					facet.inputElementSource = "quotation.getTopup( currPolicyYear )"
				when "regularPolicyTopupAmt"
					facet.inputDataElement = "getRegularPolicyTopupAmt( currPolicyYear )"
					facet.inputElementSource = "quotation"
				when "initialInvestmentAmt"
					facet.inputDataElement = "getInitialInvestmentAmt( currPolicyYear )"
					facet.inputElementSource = "quotation"  
				end
			#Topup end
			#Withdrawal start
			elsif facet.inputElementSource == 'com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyWithdrawalDO'
				inputDE = facet.inputDataElement
				case inputDE
				when "policyYearFrom"
					facet.inputDataElement = "policyYearFrom"
				when "policyYearFrom"
					facet.inputDataElement = "policyYearFrom"
				when "withdrawalAmount"
					facet.inputDataElement = "withdrawalAmount"
				end
				facet.inputElementSource = "quotation.getWithdrawal( currPolicyYear )"  
			#Withdrawal end
			#Joint life start
			elsif facet.inputElementSource == 'PolicyJointLifeDO'
				inputDE = facet.inputDataElement
				case inputDE
				when "birthDt"
					facet.inputDataElement = "dob"
				when "genderCd"
					facet.inputDataElement = "genderCd"
				when "firstName1"
					facet.inputDataElement = "firstname"
				when "lastName1"
					facet.inputDataElement = "lastname"
				when "titleCd"
					facet.inputDataElement = "title"
				when "age"
					facet.inputDataElement = "age"
				end  
				facet.inputElementSource = "quotation.getPartyByRole('JOINT')"
			#Joint life end
			#Proposer info start
			elsif facet.inputElementSource == 'PolicyProposerDO'
				inputDE = facet.inputDataElement
				case inputDE
				when "birthDt"
					facet.inputDataElement = "dob"
				when "genderCd"
					facet.inputDataElement = "genderCd"
				when "firstName1"
					facet.inputDataElement = "firstname"
				when "lastName1"
					facet.inputDataElement = "lastname"
				when "titleCd"
					facet.inputDataElement = "title"
				when "age"
					facet.inputDataElement = "age"
				when "smoker"
					facet.inputDataElement = "smoker"
				end  
				facet.inputElementSource = "quotation.getPartyByRole('PROPOSER')"
			#proposer info end
			elsif facet.inputElementSource == "PolicyRiderExtraDO"
				facet.inputElementSource = "policyRiderExtraDO"
			elsif facet.inputElementSource == "PolicyBasePlanExtraDO"
				facet.inputElementSource = "policyBasePlanExtraDO"
			elsif facet.inputElementSource == 'com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyRiderDO'
				facet.inputElementSource = "policyRiderDO"
			elsif facet.inputElementSource == "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyProductInvestmentFundDO"
				facet.inputElementSource = "investmentFund"
			end
		end  

		self.IllustrationFacetList.each do |ift|
			if ift.facetTypeCd == "GROUPING"
				ift.inputDataElement = caseHash[ift.inputDataElement] if caseHash[ift.inputDataElement]
			elsif ift.facetTypeCd == "COMPUTEDFORMULA"
				next unless ift.expression
				caseHash.each_pair{|key,value|
					# Modified below line to make case insensitive replacement of key, required by sunph v8
					ift.expression.gsub!(/_#{key}_/i, "_#{value}_")
					ift.expression.gsub!("_#{key}","_#{value}") if self.modelFor == 'UNDERWRITING' || self.modelFor == 'POLICY'
				}
				if self.modelFor == 'UNDERWRITING' || self.modelFor == 'POLICY' || self.modelFor == 'DYNAMICDT'
					ift.expression.gsub!(/(Computed_)/, "@currentProcessingValues['")
					ift.expression.gsub!(/(_end\b)/, "']")
				else
					ift.expression.gsub!(/(Computed_)/, "self.")
					ift.expression.gsub!(/(_end\b)/, "")
				end
			elsif ift.facetTypeCd == "COMPUTEDLOOKUP"
				next unless ift.expression
				caseHash.each_pair{|key,value|
					ift.expression.gsub!("'#{key}'","'#{value}'")
					ift.expression.gsub!("_#{key}","_#{value}") if self.modelFor == 'UNDERWRITING' || self.modelFor == 'POLICY'
				}
				if self.modelFor == 'UNDERWRITING' || self.modelFor == 'POLICY' || self.modelFor == 'DYNAMICDT'
					ift.expression.gsub!(/(Computed_)/, "@currentProcessingValues['")
					ift.expression.gsub!(/(_end\b)/, "']")
				else
					ift.expression.gsub!(/(Computed_)/, "self.")
					ift.expression.gsub!(/(_end\b)/, "")
				end
			elsif ift.facetTypeCd == "COMPUTEDDECISIONTBL"
				next unless ift.computedFieldNameForRule
				caseHash.each_pair{|key,value|
					ift.computedFieldNameForRule.gsub!("_#{key}_", "_#{value}_")
				}
				ift.computedFieldNameForRule.gsub!(/(Computed_)/, "")
				ift.computedFieldNameForRule.gsub!(/(_end\b)/, "")    
			end
		end
		self.persist('fromSync')
	end


	def getIllustrationFacet(computedElementName)
		@illustrationFacet ||= {}
		@illustrationFacet[computedElementName] ||= self.IllustrationFacetList.select{|facet| facet.computedElementName == computedElementName}.first
	end


	def getIllustrationFacetsByFacetTypeCd(facetTypeCd)
		@illustrationFacetsByFacetTypeCd ||= {}
		@illustrationFacetsByFacetTypeCd[facetTypeCd] ||= self.IllustrationFacetList.select{|facet| facet.facetTypeCd == facetTypeCd}
	end


	def getFundRate(fundCd, rateType)
		@illustrationRates ||= {}
		rateTypeHash = @illustrationRates[rateType]
		unless rateTypeHash
			rateTypeHash = Hash.new
			@illustrationRates[rateType] = rateTypeHash
		end
		illustrationRate = rateTypeHash[fundCd]
		unless illustrationRate
			self.IllustrationRateList.each do |ir|
				illustrationRate = ir if ir.rateTypeCd == rateType and fundCd == ir.fundCd
				rateTypeHash[fundCd] = illustrationRate
			end  
		end
		return illustrationRate
	end


	def self.prepareParseLevelHashmap(illustrationFacets)
		hash = Hash.new
		illustrationFacets.each do |ift|
			parseLevel = ift.parseLevel ? ift.parseLevel.to_i : 1
			facetArray = hash[parseLevel]
			unless facetArray
				facetArray = Array.new
				hash[parseLevel] = facetArray
			end
			facetArray.push ift
		end
		return Hash[hash.sort]
	end


	def generateCode(generateExpression = true)
		illustrationModel = self
		if illustrationModel.useGeneratedCode.to_s == 'YES'
			puts ">>>model loaded: #{illustrationModel.modelCd}"
			puts ">>>path: #{Rho::Application.bundleFolder}"
			#Segregate rider and fund facets
			riderFacets = Array.new
			fundFacets = Array.new
			lifeFacets = Array.new
			lifeFacetsPerCyclePerRate = Array.new
			illustrationModel.IllustrationFacetList.each do |ift|
				if ift.computePerInstanceOf == "FUND" && ift.computationFreqCd != "ONCEPERFUND"
					fundFacets.push ift.computedElementName
				elsif ift.computePerInstanceOf == "RIDER"
					riderFacets.push ift.computedElementName
				elsif ift.computePerInstanceOf == "LIFE"
					if ift.computationFreqCd == "EVERYCYCLE"
						lifeFacets.push ift.computedElementName
					elsif ift.computationFreqCd == "EVERYCYCLEPERRATE"
						lifeFacetsPerCyclePerRate.push ift.computedElementName
					end
				end
			end  
			groupedFacetNames = Array.new
			illustrationModel.IllustrationFacetList.each do |ift|
				if ift.facetTypeCd == "COMPUTEDLOOKUP"
					if ift.expression and ift.expression.include? "group_"
						exp = ift.expression.sub(/self.quotationIO.group_[a-zA-Z]+\('/,"")
						elementName = exp[0,exp.index("'")]
						groupedFacetNames.push elementName
					end
				end
				if ift.isSystemFl and ift.isSystemFl == "YES"
					groupedFacetNames.push ift.computedElementName
				end
			end
			lines = Array.new
			lines.push "class #{illustrationModel.modelCd}#{generateExpression.to_s.upcase}"
			lines.push "	def self.calculateIllustration(quotationIO, calledFrom = nil)"
			lines.push "    	@isCalculateIllust = true "
			lines.push "		@isSolverCall = false "
			lines.push "		@quotePlan = quotationIO.baseDO.getBaseProduct"
			lines.push "		return quotationIO unless @quotePlan.productTerm"
			lines.push "		stepStartTime = illusTotalStartTime = Time.now"
			lines.push '		RhoLog.error("' << "#{illustrationModel.modelCd}" << '", ">>>Starting calculateIllustration for quotation ref num: #{quotationIO.baseDO.quotationRefNum} at #{illusTotalStartTime.to_s}' << "#{generateExpression}" << '")'
			lines.push '		if calledFrom != "SOLVER"'
			lines.push '			GC.enable'
			lines.push '			GC.start'
			lines.push '		end'
			lines.push '		quotation = quotationIO.baseDO'
			lines.push '		MobiSys::ProductBO.populateProduct(quotation)'
			# lines.push '		quotation.QuotationProductList.each do |qp|'
			# lines.push '			qp.pdfPeriod = 0 unless qp.pdfPeriod'
			# lines.push '		end'
			lines.push ''
			lines.push "		$firstIterationValueHash[\"#{illustrationModel.modelCd}\"] = nil if calledFrom != 'SOLVER'  && $firstIterationValueHash != nil"
			lines.push "		$firstIterationValueHash = Hash.new if calledFrom == 'SOLVER' && $firstIterationValueHash == nil  "
			lines.push "		$firstIterationValueHash[\"#{illustrationModel.modelCd}\"] = Hash.new if calledFrom == 'SOLVER' && $firstIterationValueHash[\"#{illustrationModel.modelCd}\"] == nil  "
			lines.push '		product = @quotePlan.product'
			lines.push '		if quotationIO.illustrationModel == nil'
			lines.push "			RhoLog.error(\"#{illustrationModel.modelCd}\",\"Inside load model from Database\")"
			lines.push '			illustrationModelCd = product.getOtherDetailsFacet.OfflineOtherDetailsList[0].illustrationFormat'
			lines.push '			raise StandardError.new("illustration model not configured for product #{product.productId}") unless illustrationModelCd'
			lines.push "			illustrationModel = IllustrationModel.loadObject(:first, :conditions => {{ :name => 'modelCd' } => illustrationModelCd})"
			lines.push '			raise StandardError.new("Illustration model for modelcd #{illustrationModelCd} not found") unless illustrationModel'
			lines.push '			quotationIO.illustrationModel =  illustrationModel'
			lines.push '			quotationIO.originalSIModel = quotationIO.illustrationModel.cloneObject'
			lines.push '		end'			
		
			lines.push '		quotationIO.originalSIModel = quotationIO.illustrationModel.cloneObject if calledFrom != "SOLVER"'
			lines.push '		illustrationModel = quotationIO.illustrationModel'
			lines.push ''			
			if Rho::RhoConfig.LogToOutput.to_i == 1
				lines.push'        writelog("SIModel", quotation)'
			end

			lines.push '		if quotationIO.getModelAdditionalParams["SOLVER_CALL"].to_s != ""'
			lines.push '			@isSolverCall = quotationIO.getModelAdditionalParams["SOLVER_CALL"]'
			lines.push '		end'

			if Rho::RhoConfig.LogToOutput.to_i == 1 && @isCalculateIllust && !@isSolverCall
				lines.push'         modellog(illustrationModel) '
			end
			lines.push ''
			lines.push '		riderProductHash = Hash.new'
			lines.push '		riderList = Array.new'
			lines.push ''
			lines.push "		if $firstIterationValueHash == nil || $firstIterationValueHash[\"#{illustrationModel.modelCd}\"] == nil || $firstIterationValueHash[\"#{illustrationModel.modelCd}\"][:RESULTS] == nil"
			lines.push '			results = MobiSys::DataObjects::Results.new'
			lines.push '			results.createAttr("quotation")'
			lines.push '			results.createAttr("quotationProduct")'
			lines.push '			results.createAttr("basePlan")'
			lines.push '			results.createAttr("currCycleCount")'
			lines.push '			results.createAttr("currPolicyYear")'
			lines.push '			results.createAttr("currPolicyMonth")'
			lines.push '			results.createAttr("currIllusNetRate")'
			lines.push '			results.createAttr("quotationIO")'
			lines.push '			results.createAttr("investmentFund")'
			lines.push '			results.createAttr("fieldValueEvalOnceForFilter")'
			riderFacets.each do |ift|
				lines.push "			results.createAttr(\"group_#{ift}\")"
			end
			fundFacets.each do |ift|
				lines.push "			results.createAttr(\"group_#{ift}\")"
			end
			lifeFacets.each do |ift|
				lines.push "			results.createAttr(\"group_#{ift}\")"
			end
			lifeFacetsPerCyclePerRate.each do |ift|
				lines.push "			results.createAttr(\"group_#{ift}\")"
			end
			lines.push '		else'
			lines.push "			resultsCloned = $firstIterationValueHash[\"#{illustrationModel.modelCd}\"][:RESULTS].deep_clone"
			lines.push '			results = resultsCloned'
			lines.push '		end'
			lines.push '		quotationIO.results = results'
			lines.push '		results.quotation = quotation'
			lines.push '		results.basePlan = @quotePlan'
			# lines.push '		riders = quotation.getNonBuiltInRiders'
			lines.push ''
			lines.push '		results.quotationIO = quotationIO'
			#WOP changes start  
			lines.push "		riders = Array.new"
			lines.push "		wopRidersList = Array.new"
			lines.push "		nonWopRidersList = Array.new"
			# lines.push "		riders.each do |quotationProduct|"
			# lines.push "			if MobiSys::ProductBO.isWOP(quotationProduct,quotation)"
			# lines.push "			else"
			# lines.push "				nonWopRidersList.push quotationProduct"
			# lines.push "			end"
			# lines.push "		end"
			lines.push '		quotation.QuotationProductList.each do |qp|'
			lines.push '			qp.pdfPeriod = 0 unless qp.pdfPeriod'
			lines.push '			next if qp.productTypeCd == "PLAN" || qp.productTypeCd == "PLANMULTI"'
			lines.push '			riderProductHash[qp.productId] = qp.product'
			lines.push '			if qp.productTypeCd == "RIDER" and qp.builtInRiderFl != "YES"'
			lines.push '				if !(MobiSys::ProductBO.isWOP(qp,quotation))'
			lines.push '					riderList.push qp'
			lines.push "					nonWopRidersList.push qp"
			lines.push "				else"
			lines.push "					wopRidersList.push qp"
			lines.push "				end"
			lines.push '				eval("results.createAttr(\"fieldValueEvalOnceForFilter#{qp.guid}\")")'
			lines.push "				riders.push qp"
			lines.push '			end  '
			
			lines.push '		end'
			# lines.push '		riders.each do |quotationProduct|'
			# lines.push '		end'
			# lines.push '		riderList.each do |quotationProduct|'
			# lines.push '		end'
			lines.push '		if quotationIO.getModelAdditionalParams["ADDITIONAL_EVAL_PARAMS"] != nil'
			lines.push '			quotationIO.getModelAdditionalParams["ADDITIONAL_EVAL_PARAMS"].each do |key, hash|'
			lines.push '				results.createAttr(key)'
			lines.push '				results.setAttr(key, hash)'
			lines.push '			end'
			lines.push '		end'

			lines.push '		fieldValueEvalOnceForFilter = nil'
			lines.push ''
			lines.push '		resFieldForHeader = nil'
			if illustrationModel.generateResults and illustrationModel.generateResults != "NO"
				lines.push '		resFieldForHeader = MobiSys::DataObjects::FieldResult.new'
				lines.push '		resFieldForHeader.versionID = 1'
				lines.push '		quotationIO.illustrationHeader = resFieldForHeader'
				lines.push '		#inititalizing these fields only for SIModel and not otherwise ..eg. we dont require these for solver etc.'
				lines.push '		@calcYearlyResultsOutput = []'
				lines.push '		@currCycleCalcOutputData = nil'
				lines.push '		@siCalcCompleteOutputData = {}'
				lines.push '		@siCalcGlobalOutputData = {}'
				lines.push '		@currSICalcFundDO = nil'
				lines.push '		@currSICalcRiderDO = nil'
				lines.push '		@currSICalcRateDO = nil'
				lines.push '		@siCalcCompleteOutputData["TermData"] = @calcYearlyResultsOutput'
				lines.push '		@siCalcCompleteOutputData["GlobalData"] = @siCalcGlobalOutputData'
				lines.push '		quotationIO.additionalData = {} if !(quotationIO.additionalData.is_a?Hash)'
				lines.push '		quotationIO.additionalData["SICalc"] = @siCalcCompleteOutputData'

			end  
			lines.push '		quotePlan = @quotePlan'
			lines.push ''
			lines.push '		MobiSys::ProductBO.initializeIllustrationRates(quotePlan, illustrationModel, product, quotationIO)'
			

			lines.push ''
			string = 'groupedFacetNames = ['
			groupedFacetNames.each_with_index do |facetName, index|
				string << "\"#{facetName}\""
				string << "," if index!=(groupedFacetNames.size - 1)
			end  
			string << ']'
			lines.push "		#{string}"
			lines.push "		if $firstIterationValueHash == nil || $firstIterationValueHash[\"#{illustrationModel.modelCd}\"] == nil || $firstIterationValueHash[\"#{illustrationModel.modelCd}\"][:RESULTS] == nil"
			lines.push '			illustrationModel.IllustrationFacetList.each do |ift|'
			lines.push '				#Method creation start'
			lines.push '				if ift.facetTypeCd == "INPUT"'
			lines.push '					results.defineMethod("#{ift.computedElementName}_m","self.#{ift.inputElementSource}.#{ift.inputDataElement}")'
			lines.push '					results.createAttr(ift.computedElementName)'
			lines.push '				elsif ift.computePerInstanceOf == \'FUND\''
			lines.push '					@quotePlan.QuotationProductInvestmentFundList.each do |qpif|'
			lines.push '						next unless (qpif.allocationPerc and qpif.allocationPerc.to_f > 0) or (qpif.topupAllocationPerc and qpif.topupAllocationPerc.to_f > 0)'
			lines.push '						if ift.computationFreqCd == "ONCEPERFUND"'
			lines.push '							if ift.expression'
			lines.push '								newExp = ift.expression.clone'
			lines.push '								data = newExp.scan(/\b(self.perFundOnce_[a-zA-Z0-9]*)\b/)'
			lines.push '								data.each do |match|'
			lines.push '									original = match[0].to_s'
			lines.push '									newString = String.new(original.gsub("perFundOnce_",""))'
			lines.push '									newString << qpif.fundCd'
			lines.push '									newExp.sub!(original, newString)'
			lines.push '								end #data.each do |match|'
			lines.push '								results.defineMethod("#{ift.computedElementName}#{qpif.fundCd}_m", newExp)'
			lines.push '							end'
			lines.push '							results.createAttr("#{ift.computedElementName}#{qpif.fundCd}")'
			lines.push '							if groupedFacetNames.include? ift.computedElementName'
			lines.push '								attrName = "arr_#{ift.computedElementName}#{qpif.fundCd}"'
			lines.push '								results.createAttr(attrName)'
			lines.push '								methodName = "#{attrName}=".to_sym'
			lines.push '								results.send methodName, Array.new'
			lines.push '							end'
			lines.push '						else'
			lines.push '							illustrationModel.IllustrationRateList.each do |irt|'
			lines.push '								if ift.expression'
			lines.push '									newExp = ift.expression.clone'
			lines.push '									data = newExp.scan(/\b(self.perFundOnce_[a-zA-Z0-9]*)\b/)'
			lines.push '									data.each do |match|'
			lines.push '										original = match[0].to_s'
			lines.push '										newString = String.new(original.gsub("perFundOnce_",""))'
			lines.push '										newString << qpif.fundCd'
			lines.push '										newExp.sub!(original, newString)'
			lines.push '									end #data.each do |match|'
			lines.push ''
			lines.push '									data = newExp.scan(/\b(self.perFund_[a-zA-Z0-9]*)\b/)'
			lines.push '									data.each do |match|'
			lines.push '										original = match[0].to_s'
			lines.push '										newString = String.new(original.gsub("perFund_",""))'
			lines.push '										newString << qpif.fundCd'
			lines.push '										newString << irt.rateTypeCd.to_s'
			lines.push '										newExp.sub!(original, newString)'
			lines.push '									end #data.each do |match|'
			lines.push ''
			lines.push '									data = newExp.scan((/\b(self.perRate_[a-zA-Z0-9]*)\b/))'
			lines.push '									data.each do |match|'
			lines.push '										original=match[0].to_s'
			lines.push '										newString=String.new(original.gsub("perRate_",""))'
			lines.push '										newString << irt.rateTypeCd.to_s'
			lines.push '										newExp.sub!(original,newString)'
			lines.push '									end  '
			lines.push '									results.defineMethod("#{ift.computedElementName}#{qpif.fundCd}#{irt.rateTypeCd}_m", newExp)'
			lines.push '								end'
			lines.push '								results.createAttr("#{ift.computedElementName}#{qpif.fundCd}#{irt.rateTypeCd}")'
			lines.push '								if groupedFacetNames.include? ift.computedElementName'
			lines.push '									attrName = "arr_#{ift.computedElementName}#{qpif.fundCd}#{irt.rateTypeCd}"'
			lines.push '									results.createAttr(attrName)'
			lines.push '									methodName = "#{attrName}=".to_sym'
			lines.push '									results.send methodName, Array.new'
			lines.push '								end'
			lines.push '							end'
			lines.push '						end'
			lines.push '					end'
			lines.push '				elsif ift.computePerInstanceOf == "LIFE"'
			lines.push '					quotation.QuotationPartyList.each do |quotationParty|'
			lines.push '						if ift.computationFreqCd == "EVERYCYCLE"'
			lines.push '								if ift.expression'
			lines.push '									newExp = ift.expression'
			lines.push '									data = newExp.scan(/\b(self.perLife_[a-zA-Z0-9]*)\b/)'
			lines.push '									data.each do |match|'
			lines.push '										original = match[0].to_s'
			lines.push '										newString = String.new(original.gsub("perLife_",""))'
			lines.push '										newString << quotationParty.roleCd'
			lines.push '										newExp = newExp.sub(original, newString)'
			lines.push '									end #data.each do |match|'
			lines.push '									results.defineMethod("#{ift.computedElementName}#{quotationParty.roleCd}_m", newExp) unless ift.facetTypeCd == "COMPUTEDDECISIONTBL"'
			lines.push '								end'	
			lines.push '							results.createAttr("#{ift.computedElementName}#{quotationParty.roleCd}")'
			lines.push '							results.createAttr("#{ift.computedElementName}_summation#{quotationParty.roleCd}") if groupedFacetNames.include? ift.computedElementName'
			lines.push '							ift.isBreakExpression = ift.expression.include? "break" if ift.expression'
			lines.push '						elsif ift.computationFreqCd == "EVERYCYCLEPERRATE"'
			lines.push '							illustrationModel.IllustrationRateList.each do |irt|'
			lines.push '								if ift.expression'
			lines.push '									newExp = ift.expression'
			lines.push '									data = newExp.scan(/\b(self.perLife_[a-zA-Z0-9]*)\b/)'
			lines.push '									data.each do |match|'
			lines.push '										original = match[0].to_s'
			lines.push '										newString = String.new(original.gsub("perLife_",""))'
			lines.push '										newString << quotationParty.roleCd'
			lines.push '										newString << irt.id.to_s'
			lines.push '										newExp = newExp.sub(original, newString)'
			lines.push '									end #data.each do |match|'
			lines.push ''
			lines.push '									data = newExp.scan(/\b(self.perRate_[a-zA-Z0-9]*)\b/)'
			lines.push '									data.each do |match|'
			lines.push '										original = match[0].to_s'
			lines.push '										newString = String.new(original.gsub("perRate_", ""))'
			lines.push '										newString << irt.id.to_s'
			lines.push '										newExp = newExp.sub(original, newString)'
			lines.push '									end #data.each do |match|'
			lines.push '									results.defineMethod("#{ift.computedElementName}#{quotationParty.roleCd}#{irt.id}_m", newExp) unless ift.facetTypeCd == "COMPUTEDDECISIONTBL"'
			lines.push '								end'
			lines.push '								results.createAttr("#{ift.computedElementName}#{quotationParty.roleCd}#{irt.id}")'
			lines.push '								results.createAttr("#{ift.computedElementName}_summation#{quotationParty.roleCd}#{irt.id}") if groupedFacetNames.include? ift.computedElementName'
			lines.push '								ift.isBreakExpression = ift.expression.include? "break" if ift.expression'
			lines.push '							end'
			lines.push '						end'
			lines.push '					end'
			lines.push '				else'
			lines.push '					unless ift.computationFreqCd == "EVERYCYCLEPERRATE" or ift.computationFreqCd == "EVERYCYCLEPERRATEFM" or ift.computationFreqCd == "ONCEATENDPERRATE"'
			lines.push '						if ift.computePerInstanceOf == \'POLICY\' or ift.computePerInstanceOf == \'RIDER\''
			lines.push '							results.defineMethod("#{ift.computedElementName}_m", ift.expression) unless ift.facetTypeCd == "COMPUTEDDECISIONTBL"'
			lines.push '							results.createAttr(ift.computedElementName)'
			lines.push '							if groupedFacetNames.include? ift.computedElementName'
			lines.push '								attrName = "arr_#{ift.computedElementName}"'
			lines.push '								results.createAttr(attrName)'
			lines.push '								methodName = "#{attrName}=".to_sym'
			lines.push '								results.send methodName, Array.new'
			lines.push '							end'
			lines.push '							ift.isBreakExpression = ift.expression.include? "break" if ift.expression'
			lines.push '						end'
			lines.push '					else'
			lines.push '						illustrationModel.IllustrationRateList.each do |irt|'
			lines.push '							if ift.expression'
			lines.push '								newExp = ift.expression'
			lines.push '								data = newExp.scan(/\b(self.perRate_[a-zA-Z0-9]*)\b/)'
			lines.push '								data.each do |match|'
			lines.push '									original = match[0].to_s'
			lines.push '									newString = String.new(original.gsub("perRate_", ""))'
			lines.push '									newString << irt.rateTypeCd.to_s'
			lines.push '									newExp = newExp.sub(original, newString)'
			lines.push '								end #data.each do |match|'
			lines.push '								results.defineMethod("#{ift.computedElementName}#{irt.rateTypeCd}_m", newExp) unless ift.facetTypeCd == "COMPUTEDDECISIONTBL"'
			lines.push '							end'
			lines.push '							results.createAttr("#{ift.computedElementName}#{irt.rateTypeCd}")'
			lines.push '							if groupedFacetNames.include? ift.computedElementName'
			lines.push '								attrName = "arr_#{ift.computedElementName}#{irt.rateTypeCd}"'
			lines.push '								results.createAttr(attrName)'
			lines.push '								methodName = "#{attrName}=".to_sym'
			lines.push '								results.send methodName, Array.new'
			lines.push '							end'
			lines.push '							ift.isBreakExpression = ift.expression.include? "break" if ift.expression'
			lines.push '						end'
			lines.push '					end'
			lines.push '				end'
			lines.push '				#method creation end'
			lines.push '			end'
			lines.push '		end'
			lines.push ''
			lines.push '		#Copy over quotationParty.age to quotationParty.entryAge'
			lines.push '		#quotationParty.entryAge will later be used to restore entry age in quotationParty.age'
			lines.push '		quotation.QuotationPartyList.each do |qp|'
			lines.push '			qp.entryAge = qp.age'
			lines.push '		end'
			lines.push "		if $firstIterationValueHash != nil && $firstIterationValueHash[\"#{illustrationModel.modelCd}\"] != nil && $firstIterationValueHash[\"#{illustrationModel.modelCd}\"][:RESULTS] == nil"
			lines.push '			resultsClone = results.deep_clone'
			lines.push "			$firstIterationValueHash[\"#{illustrationModel.modelCd}\"][:RESULTS] = resultsClone"
			lines.push '		end'
			lines.push ''
			lines.push '		resFieldsOnceComputed = nil'
			lines.push '		siIllustrationResult = Array.new'
			lines.push '		quotationIO.listCalculation = siIllustrationResult'
			lines.push '		fieldValueEvalOnceForFilter = nil'
			lines.push ''
			lines.push '		freqMultiplier = MobiSys::ProductUtil.getFrequencyMultiplier(illustrationModel.computationFrequencyCd)'
			lines.push '		computationCycles = quotePlan.productTerm.to_i * freqMultiplier.to_i'
			lines.push ''
			if illustrationModel.useGeneratedCode == "YESWITHMERGING"
				lines.push "		minWithdrawalYears = quotationIO.input_minimum(\"self.quotation.getWithdrawal(self.currPolicyYear)\",\"policyYearFrom\")"
				lines.push "		commonCycles = (minWithdrawalYears - 1 ) * freqMultiplier"
			end  
			if illustrationModel.generateResults and illustrationModel.generateResults != "NO"
				lines.push '		resFieldsOnceComputed = MobiSys::DataObjects::FieldResult.new'
				lines.push '		resFieldsOnceComputed.versionID = 1'
			end  
			lines.push '		results.quotationProduct = @quotePlan'
			lines.push ''
			#get max parse level for all basic facets - start
			maxBasicParseLevel = 1
			maxFundParseLevel = 1
			maxLifeParseLevel = 1
			illustrationModel.IllustrationFacetList.each do |ift|
				ift.parseLevel = 1 unless ift.parseLevel
				case ift.computePerInstanceOf
				when "POLICY"
					maxBasicParseLevel = ift.parseLevel if ift.parseLevel > maxBasicParseLevel
				when "FUND"
					maxFundParseLevel = ift.parseLevel if ift.parseLevel > maxFundParseLevel
				when "LIFE"
					maxLifeParseLevel = ift.parseLevel if ift.parseLevel > maxLifeParseLevel					
				end
			end
			puts "max basic parse level: #{maxBasicParseLevel}"
			puts "max fund parseLevel: #{maxFundParseLevel}"
			puts "max life parseLevel: #{maxLifeParseLevel}"
			#get max parse level for all basic facets - end
			(1..maxBasicParseLevel).each do |parseLevel|
				puts ">>>processing parseLevel: #{parseLevel}"
				lines.push "		#parse count #{parseLevel} starts"
				lines.push '		results.createAttr("currBasicParseCount")'
				lines.push "		results.currBasicParseCount = #{parseLevel}"
				lines.push ''
				facetsComputedOnceForCurrentParseLevel = Array.new
				illustrationModel.IllustrationFacetList.each do |ift|
					# if parseLevel == ift.parseLevel
						facetsComputedOnceForCurrentParseLevel.push ift if (ift.computationFreqCd == 'ONCE' or ift.computationFreqCd == "ONCEFILTER") and ift.computePerInstanceOf == "POLICY"
					# end
				end
				if facetsComputedOnceForCurrentParseLevel.size > 0
					lines.push "		#fields computed once starts"
					#iterate facets and generate code for facets where parse level =1 and comptation frequency is ONCE
					facetsComputedOnceForCurrentParseLevel.sort!{|x,y| x.computationOrder <=> y.computationOrder}
					facetsComputedOnceForCurrentParseLevel.each do |ift|
						if Rho::RhoConfig.LogToOutput.to_i == 1
							lines.push '		illusStartTime = Time.now'
						end
						lines.push '		evaluatedValue = 0.0'
					
						if ift.parseLevel != parseLevel
							lines.push "		if resFieldsOnceComputed && resFieldsOnceComputed.containsFieldInMap(\"#{ift.computedElementName}\")"
							lines.push "			results.setAttr(\"#{ift.computedElementName}\", resFieldsOnceComputed.getFieldValue(\"#{ift.computedElementName}\"))"
							# lines.push "		else"
							# lines.push "			results.setAttr(\"#{ift.computedElementName}\",evaluatedValue)"
							lines.push "		end"
							lines.push ""
							next
						end
						if ift.outputDisplayTypeCd != "ONCEPERSOLVER" || generateExpression


							# lines.push "		attrName=:#{ift.computedElementName}="
							if ift.facetTypeCd == "COMPUTEDFORMULA" or ift.facetTypeCd == "COMPUTEDLOOKUP"
								lines.push "		methodName=:#{ift.computedElementName}_m" unless ift.facetTypeCd == "COMPUTEDDECISIONTBL"
								lines.push '		evaluatedValue = results.send methodName'
							elsif ift.facetTypeCd == "COMPUTEDDECISIONTBL"
								if ift.computedFieldNameForRule
									lines.push "		quotation.additionalField = results.send \"#{ift.computedFieldNameForRule}\".to_sym"
								end
								lines.push "		dt = MobiSys::ProductUtil.getProductDefinitionTableDO(#{ift.ruleSeq},quotation, @quotePlan)"
								lines.push "		evaluatedValue = (dt != nil ? dt.getValue : 0.0)"
							end
							lines.push "		results.#{ift.computedElementName} = evaluatedValue"
							if ift.outputDisplayTypeCd == "PARTOFFIELD"
								lines.push "		setModelFieldData(quotation,1,\"#{ift.inputDataElement}\",\"#{ift.inputElementSource}\", evaluatedValue)"
							end
							if illustrationModel.generateResults and illustrationModel.generateResults != "NO"
								if ift.outputDisplayTypeCd == "PARTOFHEADER"
									lines.push "		resFieldForHeader.addFieldValue(nil, \"#{ift.computedElementName}\", evaluatedValue, \"#{ift.elementLabel}\",#{ift.computationOrder})"
									if Rho::RhoConfig.LogToOutput.to_i == 1
										lines.push "		log(\"#{ift.computedElementName}\",evaluatedValue,nil,#{parseLevel}) "
									end
								else  
									lines.push "		resFieldsOnceComputed.addFieldValue(nil, \"#{ift.computedElementName}\", evaluatedValue, \"#{ift.elementLabel}\",#{ift.computationOrder})"
									if Rho::RhoConfig.LogToOutput.to_i == 1
										lines.push "		log(\"#{ift.computedElementName}\",evaluatedValue,nil,#{parseLevel}) "
									end
								end
							else

								if Rho::RhoConfig.LogToOutput.to_i == 1
									lines.push "		log(\"#{ift.computedElementName}\",evaluatedValue,nil,#{parseLevel}) "
								end
							end

							if ift.outputDisplayTypeCd == "ONCEPERSOLVER"
								lines.push "			#{spacer}if $firstIterationValueHash != nil && $firstIterationValueHash[\"#{illustrationModel.modelCd}\"] != nil"
								lines.push "			#{spacer}	$firstIterationValueHash[\"#{illustrationModel.modelCd}\"][cycleCount][:#{ift.computedElementName}] = evaluatedValue"
								lines.push "			#{spacer}end"
							end
						end
						if ift.outputDisplayTypeCd == "ONCEPERSOLVER" && !generateExpression
							lines.push "				#{spacer}evaluatedValue = $firstIterationValueHash[\"#{illustrationModel.modelCd}\"][cycleCount][:#{ift.computedElementName}]"
						end
						#add fields computed once to the output hashmap here
							if illustrationModel.generateResults != "NO" && ift.outputDisplayTypeCd.to_s != ""
							lines.push '		if(@siCalcCompleteOutputData != nil)'
							lines.push "			addElementToOutputMap(evaluatedValue,\"#{ift.origElementName}\",\"#{ift.computationFreqCd}\",\"#{ift.outputDisplayTypeCd}\")"
							lines.push '		end'
						end
						
						if ift.computationFreqCd == "ONCEFILTER"
							lines.push '		fieldValueEvalOnceForFilter = evaluatedValue'
							lines.push '		results.fieldValueEvalOnceForFilter = evaluatedValue'
						end  
						lines.push ''
					end  
					lines.push "		#fields computed once end"
					lines.push ""
				end
				# lines.push '			onceEndTime = Time.now'
				facetsComputedOncePerFund = Array.new
				illustrationModel.IllustrationFacetList.each do |ift|
					# facetsComputedOncePerFund.push ift if ift.parseLevel == parseLevel and ift.computationFreqCd == "ONCEPERFUND" and ift.computePerInstanceOf == "FUND"
					facetsComputedOncePerFund.push ift if ift.computationFreqCd == "ONCEPERFUND" and ift.computePerInstanceOf == "FUND"
				end

				if facetsComputedOncePerFund.size > 0
					facetsComputedOncePerFund.sort!{|x,y| x.computationOrder <=> y.computationOrder}
					lines.push "		#Once per fund facets start"
					lines.push "		fundData = {}"
					lines.push "		fundList = @quotePlan.QuotationProductInvestmentFundList"
					lines.push "		fundList.each do |investmentFund|"
					lines.push "			next unless (investmentFund.allocationPerc and investmentFund.allocationPerc.to_f > 0) or (investmentFund.topupAllocationPerc and investmentFund.topupAllocationPerc.to_f > 0)"
					lines.push "			results.investmentFund=investmentFund"
					lines.push "			@quotePlan.fundCd=investmentFund.fundCd"
					lines.push "			fundElemData = {}"
					lines.push "			fundData[investmentFund.fundCd] = fundElemData"
					facetsComputedOncePerFund.each do |ift|
						lines.push "			attrName=\"#{ift.computedElementName}\#{investmentFund.fundCd}\""
						lines.push '			evaluatedValue = 0.0'
						if ift.parseLevel != parseLevel
							lines.push "		if resFieldsOnceComputed && resFieldsOnceComputed.containsFieldInMap(\"#{ift.computedElementName}\")"
							lines.push "			results.setAttr(attrName, resFieldsOnceComputed.getFieldValue(\"#{ift.computedElementName}\"))"
							# lines.push "		else"
							# lines.push "			results.setAttr(attrName, evaluatedValue)"
							lines.push "		end"
							lines.push ""
							next
						end
						lines.push '			methodName="#{attrName}_m".to_sym' unless ift.facetTypeCd == "COMPUTEDDECISIONTBL"
						if ift.facetTypeCd == "COMPUTEDFORMULA" or ift.facetTypeCd == "COMPUTEDLOOKUP"
							lines.push '			evaluatedValue = results.send methodName'
						elsif ift.facetTypeCd == "COMPUTEDDECISIONTBL"
							if ift.computedFieldNameForRule
								lines.push "			quotation.additionalField = results.send \"#{ift.computedFieldNameForRule}\".to_sym"
							end  
							lines.push "			dt = MobiSys::ProductUtil.getProductDefinitionTableDO(#{ift.ruleSeq},quotation, @quotePlan)"
							lines.push "			evaluatedValue = (dt != nil ? dt.getValue : 0.0)"
						end
						lines.push '			results.setAttr(attrName, evaluatedValue)'
						if illustrationModel.generateResults and illustrationModel.generateResults != "NO"
							lines.push "		resFieldsOnceComputed.entityTypeCd = investmentFund.fundCd"
						  	lines.push "		resFieldsOnceComputed.addFieldValue(nil, \"#{ift.computedElementName}\", evaluatedValue, \"#{ift.elementLabel}\",#{ift.computationOrder})"
						  	# Adding the element appended with the fund code since the element value keeps getting overwritten for each fund.
						  	lines.push "    	resFieldsOnceComputed.addFieldValue(nil, \"#{ift.computedElementName}_investmentFund.fundCd\", evaluatedValue, \"#{ift.elementLabel}\", #{ift.computationOrder})"
						end
						#add fields computed once per fund to the output hashmap here
							if illustrationModel.generateResults != "NO" && ift.outputDisplayTypeCd.to_s != ""
							lines.push "			fundElemData[\"#{ift.computedElementName}\"] = evaluatedValue"
						end
						if  Rho::RhoConfig.LogToOutput.to_i == 1
							lines.push "	log(\"#{ift.computedElementName}\",evaluatedValue,nil,#{parseLevel},nil,investmentFund.fundCd)"
						end

					end 
					lines.push "		end"
					lines.push "		if @siCalcCompleteOutputData[\"GlobalData\"] != nil"
					lines.push "			@siCalcCompleteOutputData[\"GlobalData\"][\"FundData\"] = fundData"
					lines.push "		end"
					lines.push "		results.investmentFund=nil"
					if illustrationModel.generateResults and illustrationModel.generateResults != "NO"
						lines.push "		resFieldsOnceComputed.entityTypeCd = nil"
					end
					lines.push "		\#Once per fund facets end"
					lines.push ""
				end  

				#Changes for Rider facet computed once for filter start
				
				facetsComputedOnceFilterForRiderAtCurrentParseLevel = Array.new
				illustrationModel.IllustrationFacetList.each do |ift|
					# if parseLevel == ift.parseLevel
						facetsComputedOnceFilterForRiderAtCurrentParseLevel.push ift if (ift.computationFreqCd == "ONCEFILTER") and ift.computePerInstanceOf == "RIDER"
					# end
				end
				
				if facetsComputedOnceFilterForRiderAtCurrentParseLevel.size > 0
					lines.push "		#fields computed for Rider facet computed once for filter start"
					#iterate facets and generate code for facets where parse level =1 and comptation frequency is ONCE
					facetsComputedOnceFilterForRiderAtCurrentParseLevel.sort!{|x,y| x.computationOrder <=> y.computationOrder}
					facetsComputedOnceFilterForRiderAtCurrentParseLevel.each do |ift|
						lines.push "		riderList.each do |quotationProduct|"
						lines.push "			if (quotationProduct.productTypeCd.to_s != 'PLAN' && @quotePlan.product && @quotePlan.product.getFacetValue('RIDERAUTOPOPULATIONREQUIRED') == \"YES\" && (quotationProduct.selected != \"on\" &&quotationProduct.selected != \"YES\" )) || quotationProduct.removed == \"YES\""
						lines.push "				next"
						lines.push "			end"
						lines.push "			results.quotationProduct = quotationProduct"
						lines.push "			attrName=:#{ift.computedElementName}="
						lines.push "			methodName=:#{ift.computedElementName}_m" unless ift.facetTypeCd == "COMPUTEDDECISIONTBL"
						lines.push '			evaluatedValue = results.send methodName'

						if ift.computationFreqCd == "ONCEFILTER"
							lines.push "		eval(\"results.fieldValueEvalOnceForFilter\#{quotationProduct.guid} = \\\"\#{evaluatedValue}\\\"\")"
						end  
						lines.push '		end'
						lines.push '		results.quotationProduct = results.basePlan'
						lines.push ''
					end  
					lines.push "		#fields computed for Rider facet computed once for filter end"
					lines.push ""
				end
				#Changes for Rider facet computed once for filter end

				#

				# #WOP changes start  
				# lines.push "		wopRidersList = Array.new"
				# lines.push "		nonWopRidersList = Array.new"
				# # lines.push "		riders = quotation.getRiders"
				# lines.push "		riders.each do |quotationProduct|"
				# lines.push "			if MobiSys::ProductBO.isWOP(quotationProduct,quotation)"
				# lines.push "				wopRidersList.push quotationProduct"
				# lines.push "			else"
				# lines.push "				nonWopRidersList.push quotationProduct"
				# lines.push "			end"
				# lines.push "		end"
				lines.push "		wopRiderCount = wopRidersList.size"
				lines.push "		riderCount = riders.size"
				#WOP changes end

				lines.push "		policyMonth = 0"
				lines.push "		policyYear = 0"
				lines.push "		cycleCount = 1"
				if illustrationModel.useGeneratedCode == "YESWITHMERGING"
					lines.push "		if $commonResults"
					lines.push "			policyYear = (commonCycles / freqMultiplier).to_i"
					lines.push "			cycleCount = commonCycles.to_i + 1"
					lines.push "			results = $commonResults.deep_clone"
					lines.push "			quotationIO.results = results"
					lines.push "			results.quotationProduct = @quotePlan"
					lines.push "			results.basePlan = @quotePlan"
					lines.push "			results.quotationIO = quotationIO"
					lines.push "			results.quotation = quotation"
					lines.push "		end"
					lines.push ""
				end
				lines.push "		shouldBreak = false"
				lines.push "		@attrNameHash = {}\n		@methodNameHash = {}"
				if(illustrationModel.computationFrequencyCd == "MONTHLY")
					lines.push "		@isMonthly = true"
				else
					lines.push "		@isMonthly = false"
				end
				lines.push "		while cycleCount <= computationCycles"
				lines.push "			$firstIterationValueHash[\"#{illustrationModel.modelCd}\"][cycleCount] = Hash.new if calledFrom == 'SOLVER' && $firstIterationValueHash[\"#{illustrationModel.modelCd}\"] != nil && $firstIterationValueHash[\"#{illustrationModel.modelCd}\"][cycleCount] == nil  "
				lines.push "			riderFacetsComputed = false"
				lines.push "			shouldBreak = false"
				lines.push "			hmRiderGroupedAttribValues = resFieldsPerCycle = nil"
				lines.push ""
				if illustrationModel.generateResults and illustrationModel.generateResults != "NO"
					if parseLevel == 1
						lines.push "			resFieldsPerCycle = MobiSys::DataObjects::FieldResult.new"
						lines.push "			siIllustrationResult.push resFieldsPerCycle"
						lines.push "			resFieldsPerCycle.id=cycleCount"
						lines.push "			if(@siCalcCompleteOutputData != nil)"
						lines.push "				if(@isMonthly)"
						lines.push "					#for monthly we need calcOutputData only for each year"
						lines.push "					if(cycleCount % 12 == 0)"
						lines.push "						@currCycleCalcOutputData = {}"
						lines.push "					else"
						lines.push "						@currCycleCalcOutputData = nil"
						lines.push "					end"
						lines.push "				else"
						lines.push "					@currCycleCalcOutputData = {}"
						lines.push "				end"
						lines.push "				if(@currCycleCalcOutputData != nil)"
						lines.push "					@calcYearlyResultsOutput << @currCycleCalcOutputData"
						lines.push "				end"
						lines.push "			end"
					else
						lines.push "			resFieldsPerCycle = siIllustrationResult[cycleCount - 1]"
						lines.push "			if(@siCalcCompleteOutputData != nil) "
						lines.push "				if(@isMonthly)"
						lines.push "					if(cycleCount % 12 == 0)"
						lines.push "						@currCycleCalcOutputData = @calcYearlyResultsOutput[(cycleCount/12) -1]"
						lines.push "					else"
						lines.push "						@currCycleCalcOutputData = nil"
						lines.push "					end"
						lines.push "				else"
						lines.push "					@currCycleCalcOutputData = @calcYearlyResultsOutput[cycleCount -1]"
						lines.push "				end"
						lines.push "			end"
					end
					lines.push " 			resFieldsPerCycle.versionID = #{parseLevel.to_i}"
				end 
				lines.push ""
				lines.push "			results.currCycleCount = cycleCount"
				lines.push ""
				lines.push "			policyMonth = 0 if policyMonth == 12 or illustrationModel.computationFrequencyCd == \"YEARLY\""
				lines.push ""
				lines.push "			policyYear = (cycleCount/freqMultiplier)"
				lines.push "			policyYear += 1 unless cycleCount%freqMultiplier == 0"
				lines.push ""
				lines.push "			policyMonth += 1"
				lines.push ""

				lines.push "			quotation.policyYear = policyYear"
				lines.push '			quotationIO.addModelAdditionalParams("modelTotalCycles", cycleCount)'
				lines.push ""
				lines.push "			if(policyMonth == 1 && (policyYear > 1 || #{parseLevel} > 1 || @isSolverCall))"
				lines.push "				if policyYear > 1"
				lines.push "					quotation.QuotationPartyList.each do |party|"
				lines.push "						party.policyYear = policyYear"
				lines.push "						if(party.age.to_s != '')"
				lines.push "							party.age = party.age.to_i + 1"
				lines.push "						end"
				lines.push "					end"
				lines.push "				end"
				lines.push "				MobiSys::ProductBO.calculateModelBasedPremium(policyYear, quotation, quotePlan, product) if policyYear <= (@quotePlan.premiumPayingTerm.to_i + 1)"
				lines.push "			end"
				lines.push ""

				lines.push ""
				lines.push "			results.currPolicyYear = policyYear"
				lines.push "			results.currPolicyMonth = policyMonth"
				lines.push "			quotationIO.currentRate = nil"
				lines.push ""
				lines.push "			results.quotationProduct = quotePlan"

				facetsComputedEveryCycleForCurrentParseLevel = Array.new
				illustrationModel.IllustrationFacetList.each do |ift|
					if (ift.computationFreqCd == "EVERYCYCLE" or ift.computationFreqCd=="EVERYCYCLEFM") and ift.computePerInstanceOf == "POLICY"
						# if parseLevel == ift.parseLevel
							facetsComputedEveryCycleForCurrentParseLevel.push ift
							ift.isBreakExpression = ift.expression.include? "break" if ift.expression
						# end
					end  
				end
				facetsComputedEveryCycleForCurrentParseLevel.sort!{|x,y| x.computationOrder <=> y.computationOrder}
				riderFacetNonFMOnly = facetsComputedEveryCycleForCurrentParseLevel.find_all{|ift| (ift.facetTypeCd == "GROUPING" && ift.computePerInstanceOf == "POLICY" && ift.computationFreqCd != "EVERYCYCLEFM" && ift.inputElementSource == "policyRiderDO")}
				riderFacetNonGlobalOnly = facetsComputedEveryCycleForCurrentParseLevel.find_all{|ift| (ift.facetTypeCd == "GROUPING" && ift.computePerInstanceOf == "POLICY" && ift.outputDisplayTypeCd != "ONCEPERSOLVER" && ift.inputElementSource == "policyRiderDO")}
				lifeFacetNonGlobalOnly = facetsComputedEveryCycleForCurrentParseLevel.find_all{|ift| (ift.facetTypeCd == "GROUPING" && ift.computePerInstanceOf == "POLICY" && ift.outputDisplayTypeCd != "ONCEPERSOLVER" && ift.inputElementSource == "quotationProduct")}
				lines.push ""
				lines.push "			\#facets computed every cycle start"
				riderFacetsComputed = false
				lifeFacetsComputedPerCycle = false
				facetsComputedEveryCycleForCurrentParseLevel.each do |ift|


					if ift.parseLevel != parseLevel
						lines.push "			if resFieldsPerCycle && resFieldsPerCycle.containsFieldInMap(\"#{ift.computedElementName}\")"
						lines.push "				results.setAttr(\"#{ift.computedElementName}\", resFieldsPerCycle.getFieldValue(\"#{ift.computedElementName}\"))"
						# lines.push "			else"
						# lines.push "				results.setAttr(\"#{ift.computedElementName}\", 0.0)"
						lines.push "			end"
						lines.push ""
						next
					end
					
					if ift.facetTypeCd == "GROUPING"
						if ift.inputElementSource == "quotationProduct"
							unless lifeFacetsComputedPerCycle
								#life facets are computed once per cycle for all Plan lives and then grouped
								if lifeFacetNonGlobalOnly.size == 0
									lines.push "			if $firstIterationValueHash == nil || $firstIterationValueHash[\"#{illustrationModel.modelCd}\"] == nil || $firstIterationValueHash[\"#{illustrationModel.modelCd}\"][cycleCount][:LIFEFACET] != 'YES'"
									lines.push "				$firstIterationValueHash[\"#{illustrationModel.modelCd}\"][cycleCount][:LIFEFACET] = 'YES'  if $firstIterationValueHash && $firstIterationValueHash[\"#{illustrationModel.modelCd}\"]"
								end
								lines.push "				if quotation.getPlanList.size > 0"
								lines.push "					hmRiderGroupedAttribValues = calculateLifeFacets(illustrationModel, quotation, results, quotationIO, nil)"
								lines.push "				end"
								lines.push "				results.quotationProduct = quotePlan"
								if lifeFacetNonGlobalOnly.size == 0
									lines.push "			end"
								end
								lifeFacetsComputedPerCycle = true
							end
							
						else
							unless riderFacetsComputed
								if riderFacetNonGlobalOnly.size == 0
									lines.push "			if $firstIterationValueHash == nil || $firstIterationValueHash[\"#{illustrationModel.modelCd}\"] == nil || $firstIterationValueHash[\"#{illustrationModel.modelCd}\"][cycleCount][:RIDERFACETCALLED] != 'YES'"
									lines.push "				$firstIterationValueHash[\"#{illustrationModel.modelCd}\"][cycleCount][:RIDERFACETCALLED] = 'YES'  if $firstIterationValueHash && $firstIterationValueHash[\"#{illustrationModel.modelCd}\"]"
								end
								if riderFacetNonFMOnly.size == 0
									lines.push "				if policyMonth == 1"
								end
								#lines.push "			hmRiderGroupedAttribValues = calculateRiderFacets(illustrationModel, quotation, results, quotationIO, riderProductHash) if quotation.getRiderCount > 0"
								lines.push "					if quotation.getRiderCount > 0"
								lines.push "						hmRiderGroupedAttribValues = calculateRiderFacets(illustrationModel, quotation, results, quotationIO, riderProductHash, nonWopRidersList)"
								lines.push "						if wopRidersList.size > 0"
								lines.push "							hmRiderGroupedAttribValues = calculateWopRiderFacets(illustrationModel, quotation, results, quotationIO, riderProductHash, wopRidersList)"
								lines.push "						end"
								lines.push "					end"
								lines.push "					results.quotationProduct = quotePlan"
								lines.push ""
								riderFacetsComputed = true
								if riderFacetNonFMOnly.size == 0
									lines.push "				end"
								end
								if riderFacetNonGlobalOnly.size == 0
									lines.push "			end"
								end
							end
						end
					end 
					if groupedFacetNames.include? ift.computedElementName
						lines.push "			evaluatedValue = 0.0"
					end  
					spacer = ""
					# lines.push "			#{spacer}attrName=:#{ift.computedElementName}="
					if ift.elementFilter
						lines.push "			if ('#{ift.elementFilter}'.include?(results.fieldValueEvalOnceForFilter))"
						spacer << "\t"
					end
					if ift.outputDisplayTypeCd != "ONCEPERSOLVER" || generateExpression
						# lines.push "			#{spacer}if  $firstIterationValueHash == nil || $firstIterationValueHash[cycleCount][:#{ift.computedElementName}] == nil"
						# spacer << "\t"
					# end
						if ift.computationFreqCd == "EVERYCYCLEFM"
							lines.push "			#{spacer}evaluatedValue = nil"
							lines.push "			#{spacer}if policyMonth > 1"
							lines.push "				#{spacer}evaluatedValue = results.send :#{ift.computedElementName}"
							lines.push "			#{spacer}else"
							spacer << "\t"
						end  
						
						if ift.facetTypeCd == "COMPUTEDFORMULA" or ift.facetTypeCd == "COMPUTEDLOOKUP"
							lines.push "			#{spacer}methodName=:#{ift.computedElementName}_m"
							lines.push "			#{spacer}evaluatedValue=results.send methodName"
						elsif ift.facetTypeCd == "COMPUTEDDECISIONTBL"
							if ift.computedFieldNameForRule
								lines.push "			#{spacer}quotation.additionalField = results.send :#{ift.computedFieldNameForRule}"
							end  
							lines.push "			#{spacer}dt = MobiSys::ProductUtil.getProductDefinitionTableDO(#{ift.ruleSeq},quotation, @quotePlan)"
							lines.push "			#{spacer}evaluatedValue = (dt != nil ? dt.getValue : 0.0)"
						elsif ift.facetTypeCd == "GROUPING"
							#lines.push "			#{spacer}evaluatedValue=(hmRiderGroupedAttribValues and hmRiderGroupedAttribValues.has_key?(\"Group_#{ift.inputDataElement}\".to_sym)) ? hmRiderGroupedAttribValues[\"Group_#{ift.inputDataElement}\".to_sym] : 0.0"
							lines.push "			#{spacer}evaluatedValue=results.send :group_#{ift.inputDataElement}"
						end  

						if ift.computationFreqCd == "EVERYCYCLEFM"
							spacer = spacer[0, spacer.length-2]
							lines.push "			#{spacer}end"
						end
						

						if ift.outputDisplayTypeCd == "ONCEPERSOLVER"
							lines.push "			#{spacer}if $firstIterationValueHash != nil && $firstIterationValueHash[\"#{illustrationModel.modelCd}\"] != nil"
							lines.push "			#{spacer}	$firstIterationValueHash[\"#{illustrationModel.modelCd}\"][cycleCount][:#{ift.computedElementName}] = evaluatedValue"
							lines.push "			#{spacer}end"
						end
					end
					if ift.outputDisplayTypeCd == "ONCEPERSOLVER" && !generateExpression
						lines.push "				#{spacer}evaluatedValue = $firstIterationValueHash[\"#{illustrationModel.modelCd}\"][cycleCount][:#{ift.computedElementName}]"
					end
					lines.push "			#{spacer}results.#{ift.computedElementName} = evaluatedValue"
					if illustrationModel.generateResults and illustrationModel.generateResults != "NO"
						lines.push "			#{spacer}resFieldsPerCycle.addFieldValue(nil, \"#{ift.computedElementName}\", evaluatedValue, \"#{ift.elementLabel}\",#{ift.computationOrder})"
					end

					if Rho::RhoConfig.LogToOutput.to_i == 1
						lines.push "				#{spacer}log(\"#{ift.computedElementName}\",evaluatedValue,cycleCount,#{parseLevel.to_s}) " 
					end
					lines.push "			#{spacer}end"  if ift.elementFilter

					if ift.outputDisplayTypeCd == "PARTOFFIELD"
						lines.push "			#{spacer}setModelFieldData(quotation, policyYear, \"#{ift.inputDataElement}\",\"#{ift.inputElementSource}\", evaluatedValue)"
					end  
					if ift.isBreakExpression
						lines.push "			#{spacer}if (evaluatedValue and evaluatedValue.is_a?(String) and evaluatedValue.include?(\"break\"))"
						lines.push "				#{spacer}shouldBreak = true"
						lines.push "			#{spacer}end"
					end  
					if ift.outputDisplayTypeCd != "ONCEPERSOLVER" || generateExpression
						if groupedFacetNames.include? ift.computedElementName
							lines.push "			methodName = :arr_#{ift.computedElementName}"
							lines.push "			array = results.send methodName"
							lines.push "			array.push evaluatedValue"
						end
					end
					#add fields computed once to the output hashmap here
						if illustrationModel.generateResults != "NO" && ift.outputDisplayTypeCd.to_s != ""
						lines.push '		if(@siCalcCompleteOutputData != nil)'
						lines.push "			addElementToOutputMap(evaluatedValue,\"#{ift.origElementName}\",\"#{ift.computationFreqCd}\",\"#{ift.outputDisplayTypeCd}\")"
						lines.push '		end'
					end
					lines.push ""
				end
				lines.push "			\#facets computed every cycle end"

				facetsComputedEveryCyclePerRateForCurrentParseLevel = Array.new
				illustrationModel.IllustrationFacetList.each do |ift|
					if (ift.computationFreqCd == "EVERYCYCLEPERRATE" or ift.computationFreqCd=="EVERYCYCLEPERRATEFM") and ift.computePerInstanceOf == "POLICY"
						facetsComputedEveryCyclePerRateForCurrentParseLevel.push ift
						ift.isBreakExpression = ift.expression.include? "break" if ift.expression
					end  
				end

				if facetsComputedEveryCyclePerRateForCurrentParseLevel.size  > 0
					facetsComputedEveryCyclePerRateForCurrentParseLevel.sort!{|x,y| x.computationOrder <=> y.computationOrder}
					lines.push "			rateCounter = 0"
					lines.push "			illustrationModel.IllustrationRateList.each do |illustrationRate|"
					lines.push "				rateattrName = @attrNameHash[illustrationRate.rateTypeCd] ||= {}"
					lines.push "				ratemethodName = @methodNameHash[illustrationRate.rateTypeCd] ||= {}"
					lines.push "				@currSICalcRateDO = illustrationRate"
					lines.push "				fundFacetsComputed = false"
					lines.push "				lifeFacetsComputedPerRate = false"
					lines.push "				hmFundGroupedAttribValues = Hash.new"
					lines.push "				resFieldsPerCyclePerRate = nil"
	
					if illustrationModel.generateResults and illustrationModel.generateResults != "NO"
						if parseLevel == 1
							lines.push "				resFieldsPerCyclePerRate = MobiSys::DataObjects::FieldResult.new"
							lines.push "				resFieldsPerCycle.addFieldResult(resFieldsPerCyclePerRate)"
							lines.push "				resFieldsPerCyclePerRate.objectName = illustrationRate.rate.to_s"
						else
							lines.push "				resFieldsPerCyclePerRate = resFieldsPerCycle.fieldResultList[rateCounter]"
						end  
						lines.push "				resFieldsPerCyclePerRate.id = cycleCount.to_i"
						lines.push "				resFieldsPerCyclePerRate.versionID = #{parseLevel.to_i}"
						lines.push "				resFieldsPerCyclePerRate.objectName = illustrationRate.rate.to_s"
					end  
					lines.push ""
					lines.push "				results.currIllusNetRate = illustrationRate.rate.to_f"
					lines.push ""
					lines.push "				quotePlan.illustrationRate = illustrationRate.rate"
					lines.push "				quotePlan.currentRate = illustrationRate.rate"
					lines.push "				quotationIO.currentRate = illustrationRate.rate"
					lines.push "				quotationIO.currentIllustrationRate = illustrationRate"
					lines.push "				results.quotationProduct = quotePlan"
					lines.push ""
					lines.push "				hmFundGroupedAttribValues = calculateFundFacets(quotation, results, quotationIO, illustrationRate, illustrationModel)"
					lines.push " if quotation.getPlanList.size > 0 " 
					lines.push "				hmFundGroupedAttribValues = calculateLifeFacetsPerRate(illustrationModel, quotation, results, quotationIO, illustrationRate)"
					lines.push "end"
					lines.push ""
					lines.push "				@currSICalcRateDO = illustrationRate"

					facetsComputedEveryCyclePerRateForCurrentParseLevel.each do |ift|
						if groupedFacetNames.include? ift.computedElementName
							lines.push "				evaluatedValue = 0.0"
						end
						spacer = ""
						lines.push "				#{spacer}rateattrName[:#{ift.computedElementName}=]||=:\"#{ift.computedElementName}\#{illustrationRate.rateTypeCd}=\""
						if ift.parseLevel != parseLevel
							lines.push "				if resFieldsPerCyclePerRate && resFieldsPerCyclePerRate.containsFieldInMap(\"#{ift.computedElementName}\")"
							lines.push "					results.setAttr(rateattrName[:#{ift.computedElementName}=], resFieldsPerCyclePerRate.getFieldValue(\"#{ift.computedElementName}\"))"
							# lines.push "				else"
							# lines.push "					results.setAttr(rateattrName[:#{ift.computedElementName}=], evaluatedValue)"
							lines.push "				end"
							lines.push ""
							next
						end
						if ift.elementFilter
							lines.push "				if ('#{ift.elementFilter}'.include?(results.fieldValueEvalOnceForFilter))"
							spacer << "\t"
						end

						if ift.computationFreqCd == "EVERYCYCLEPERRATEFM"
							lines.push "				#{spacer}evaluatedValue = nil"
							lines.push "				#{spacer}if policyMonth > 1"
							lines.push "					#{spacer}evaluatedValue = results.send rateattrName[:#{ift.computedElementName}]||=:\"#{ift.computedElementName}\#{illustrationRate.rateTypeCd}\""
							lines.push "				#{spacer}end"
							spacer << "\t"
						end  

						if ift.facetTypeCd == "COMPUTEDFORMULA" or ift.facetTypeCd == "COMPUTEDLOOKUP"
							lines.push "				#{spacer}ratemethodName[:#{ift.computedElementName}]||=:\"#{ift.computedElementName}\#{illustrationRate.rateTypeCd}_m\""
							lines.push "				#{spacer}evaluatedValue=results.send ratemethodName[:#{ift.computedElementName}]"
						elsif ift.facetTypeCd == "COMPUTEDDECISIONTBL"
							if ift.computedFieldNameForRule
								ift.computedFieldNameForRule.gsub!("perRate_","")
								lines.push "				#{spacer}quotation.additionalField = results.send :\"#{ift.computedFieldNameForRule}\#{illustrationRate.rateTypeCd}_m\""
							end  
							lines.push "				#{spacer}dt = MobiSys::ProductUtil.getProductDefinitionTableDO(#{ift.ruleSeq},quotation, @quotePlan)"
							lines.push "				#{spacer}evaluatedValue = (dt != nil ? dt.getValue : 0.0)"
						elsif ift.facetTypeCd == "GROUPING"
							#lines.push "				#{spacer}evaluatedValue=hmFundGroupedAttribValues[\"Group_#{ift.inputDataElement}\".to_sym]"
							lines.push "				#{spacer}evaluatedValue= results.send :group_#{ift.inputDataElement}"
						end  

						if ift.computationFreqCd == "EVERYCYCLEFM"
							spacer = spacer[0, spacer.length-2]
							lines.push "				#{spacer}end"
						end

						lines.push "				#{spacer}results.setAttr1(rateattrName[:#{ift.computedElementName}=], evaluatedValue)"
						if illustrationModel.generateResults and illustrationModel.generateResults != "NO"
							lines.push "				#{spacer}resFieldsPerCyclePerRate.addFieldValue(nil, \"#{ift.computedElementName}\", evaluatedValue, \"#{ift.elementLabel}\",#{ift.computationOrder})"
						end
						if Rho::RhoConfig.LogToOutput.to_i == 1
							lines.push "			log(\"#{ift.computedElementName}\",evaluatedValue,cycleCount,#{parseLevel.to_i},illustrationRate.rate.to_s) "
						end
						if ift.outputDisplayTypeCd == "PARTOFFIELD"
							lines.push "				#{spacer}setModelFieldData(quotation, policyYear, \"#{ift.inputDataElement}\",\"#{ift.inputElementSource}\", evaluatedValue)"
						end  
						if ift.isBreakExpression
							lines.push "				#{spacer}if (evaluatedValue and evaluatedValue.is_a?(String) and evaluatedValue.include?(\"break\"))"
							lines.push "					#{spacer}shouldBreak = true"
							lines.push "				#{spacer}end"
						end  
						lines.push "				end" if ift.elementFilter
						if groupedFacetNames.include? ift.computedElementName
							lines.push "				ratemethodName[:arr_#{ift.computedElementName}] ||= :\"arr_#{ift.computedElementName}\#{illustrationRate.rateTypeCd}\""
							lines.push "				array = results.send ratemethodName[:arr_#{ift.computedElementName}]"
							lines.push "				array.push evaluatedValue"
						end
						#add fields computed once to the output hashmap here
							if illustrationModel.generateResults != "NO" && ift.outputDisplayTypeCd.to_s != ""
							lines.push '		if(@siCalcCompleteOutputData != nil)'
							lines.push "			addElementToOutputMap(evaluatedValue,\"#{ift.origElementName}\",\"#{ift.computationFreqCd}\",\"#{ift.outputDisplayTypeCd}\")"
							lines.push '		end'
						end
						lines.push ""
					end #facetsComputedEveryCyclePerRateForCurrentParseLevel.each do |ift|

					lines.push "				rateCounter += 1"
					lines.push "				@currSICalcRateDO = nil"
					lines.push "			end \#illustrationModel.IllustrationRateList.each do |illustrationRate|"
					lines.push "			quotationIO.currentIllustrationRate = nil"
					lines.push "			quotePlan.illustrationRate = nil"
					lines.push "			quotePlan.currentRate = nil"
					lines.push "			quotationIO.currentRate = nil"
					lines.push "			quotationIO.currentIllustrationRate = nil"
					lines.push ""
				end

				if illustrationModel.generateResults and illustrationModel.generateResults != "NO"
					lines.push "			for onceFieldCounter in (0...resFieldsOnceComputed.fieldValueList.length)"
					lines.push "				fldValueComputedOnce = resFieldsOnceComputed.fieldValueList[onceFieldCounter]"
					lines.push "				resFieldsPerCycle.fieldValueList.insert((fldValueComputedOnce.sortOrder-1), fldValueComputedOnce)"
					lines.push "			end"
				end  
				lines.push ""
				lines.push "			quotationIO.computationCycles = cycleCount"
				if illustrationModel.useGeneratedCode == "YESWITHMERGING"
					lines.push "			if cycleCount == commonCycles and $commonResults == nil"
					lines.push "				$commonResults = results.deep_clone"
					lines.push "			end"
					lines.push ""
				end  
				lines.push "			break if shouldBreak == true"
				lines.push ""
				spacer=""
				if illustrationModel.generateResults == "YES"
					if illustrationModel.computationFrequencyCd != "YEARLY"
						lines.push "			if cycleCount%12 == 0"
						spacer << "\t"
					end
					lines.push "			#{spacer}percentage = ((cycleCount + ((#{parseLevel} - 1) * computationCycles.to_f))/(computationCycles.to_f * #{maxBasicParseLevel}) * 100 )"
					string = 'WebView.execute_js("update_progress(\"#{percentage}\", \"#{calledFrom}\")")'
					lines.push "			#{spacer}#{string}"
					if illustrationModel.computationFrequencyCd != "YEARLY"
						lines.push "			end"
					end
				end

				lines.push "			cycleCount += 1"
				lines.push "		end \#while cycleCount <= computationCycles"
				lines.push ""

				#code generation for facets computed once at end - starts
				facetsComputedOnceAtEndForCurrentParseLevel = Array.new

				illustrationModel.IllustrationFacetList.each do |ift|
					facetsComputedOnceAtEndForCurrentParseLevel.push ift if ift.computationFreqCd == "ONCEATEND"
				end

				if facetsComputedOnceAtEndForCurrentParseLevel.size > 0
					facetsComputedOnceAtEndForCurrentParseLevel.sort!{|x,y| x.computationOrder <=> y.computationOrder}
					lines.push "		\#Facets computed once at end start"  
					facetsComputedOnceAtEndForCurrentParseLevel.each do |ift|

						if ift.parseLevel != parseLevel
							lines.push "		if resFieldForHeader && resFieldForHeader.containsFieldInMap(\"#{ift.computedElementName}\")"
							lines.push "			results.setAttr(\"#{ift.computedElementName}\", resFieldForHeader.getFieldValue(\"#{ift.computedElementName}\"))"
							# lines.push "		else"
							# lines.push "			results.setAttr(\"#{ift.computedElementName}\", 0.0)"
							lines.push "		end"
							lines.push ""
							next
						end

						lines.push "		attrName=\"#{ift.computedElementName}\""
						if ift.facetTypeCd == "COMPUTEDFORMULA" or ift.facetTypeCd == "COMPUTEDLOOKUP"
							lines.push '		methodName="#{attrName}_m".to_sym' unless ift.facetTypeCd == "COMPUTEDDECISIONTBL"
							lines.push '		evaluatedValue = results.send methodName'
						elsif ift.facetTypeCd == "COMPUTEDDECISIONTBL"
							if ift.computedFieldNameForRule
								lines.push "		quotation.additionalField = results.send \"#{ift.computedFieldNameForRule}\".to_sym"
							end  
							lines.push "		dt = MobiSys::ProductUtil.getProductDefinitionTableDO(#{ift.ruleSeq},quotation, @quotePlan)"
							lines.push "		evaluatedValue = (dt != nil ? dt.getValue : 0.0)"
						end
						lines.push "		results.#{ift.computedElementName} = evaluatedValue"
						if ift.outputDisplayTypeCd == "PARTOFFIELD"
							lines.push "		setModelFieldData(quotation,0,\"#{ift.inputDataElement}\",\"#{ift.inputElementSource}\", evaluatedValue)"
						end
						if illustrationModel.generateResults and illustrationModel.generateResults != "NO"
							lines.push "		resFieldForHeader.addFieldValue(nil, \"#{ift.computedElementName}\", evaluatedValue, \"#{ift.elementLabel}\",#{ift.computationOrder})"
						end
						if Rho::RhoConfig.LogToOutput.to_i == 1
							lines.push "			log(\"#{ift.computedElementName}\",evaluatedValue,nil,#{parseLevel.to_s}) "
						end
						if ift.computationFreqCd == "ONCEFILTER"
							lines.push '		fieldValueEvalOnceForFilter = evaluatedValue'
							lines.push '		results.fieldValueEvalOnceForFilter = evaluatedValue'
						end  
						lines.push ''
						#add fields computed once to the output hashmap here
							if illustrationModel.generateResults != "NO" && ift.outputDisplayTypeCd.to_s != ""
							lines.push '		if(@siCalcCompleteOutputData != nil)'
							lines.push "			addElementToOutputMap(evaluatedValue,\"#{ift.origElementName}\",\"#{ift.computationFreqCd}\",\"#{ift.outputDisplayTypeCd}\")"
							lines.push '		end'
						end
					end
					lines.push "		\#Facets computed once at end end"
					lines.push ""
				end
				#code generation for facets computed once at end - ends

				#code generation for facets computed once at end per rate - starts
				facetsComputedOnceAtEndPerRateForCurrentParseLevel = Array.new

				illustrationModel.IllustrationFacetList.each do |ift|
					facetsComputedOnceAtEndPerRateForCurrentParseLevel.push ift if ift.computationFreqCd == "ONCEATENDPERRATE"
				end

				if facetsComputedOnceAtEndPerRateForCurrentParseLevel.size > 0
					facetsComputedOnceAtEndPerRateForCurrentParseLevel.sort!{|x,y| x.computationOrder <=> y.computationOrder}
					lines.push "		\#facets computed once at end per rate start"
					lines.push "		rateCounter = 0"
					lines.push "		illustrationModel.IllustrationRateList.each do |illustrationRate|"

					lines.push "			resFieldsAtEndPerRate = nil"	
					if illustrationModel.generateResults and illustrationModel.generateResults != "NO"

						if parseLevel == 1
							lines.push "			resFieldsAtEndPerRate = MobiSys::DataObjects::FieldResult.new"
						
							lines.push "			resFieldForHeader.addFieldResult resFieldsAtEndPerRate"
						else
							lines.push "			resFieldsAtEndPerRate = resFieldForHeader.fieldResultList[rateCounter]"
						end
						lines.push "			resFieldsAtEndPerRate.objectName = illustrationRate.rate.to_s"
					end
				# lines.push"	end  "
					lines.push "			results.currIllusNetRate = illustrationRate.rate.to_f"
					lines.push "			quotationIO.currentRate = illustrationRate.rate"
					lines.push ""
					facetsComputedOnceAtEndPerRateForCurrentParseLevel.each do |ift|

						spacer = ""
						if ift.parseLevel != parseLevel
							lines.push "			#{spacer}if resFieldsAtEndPerRate && resFieldsAtEndPerRate.containsFieldInMap(\"#{ift.computedElementName}\")"
							lines.push "			#{spacer}	results.setAttr(\"#{ift.computedElementName}+\#{illustrationRate.rateTypeCd}\", resFieldsAtEndPerRate.getFieldValue(\"#{ift.computedElementName}\"))"
							# lines.push "			#{spacer}else"
							# lines.push "			#{spacer}	results.setAttr(\"#{ift.computedElementName}+\#{illustrationRate.rateTypeCd}\", 0.0)"
							lines.push "			#{spacer}end"
							lines.push ""
							next
						end
						if ift.elementFilter
							lines.push "			if ('#{ift.elementFilter}'.include?(results.fieldValueEvalOnceForFilter))"
							spacer << "\t"
						end
						lines.push "			#{spacer}attrName=\"#{ift.computedElementName}\#{illustrationRate.rateTypeCd}\""

						

						if ift.computationFreqCd == "EVERYCYCLEFM"
							lines.push "			#{spacer}evaluatedValue = nil"
							lines.push "			#{spacer}if policyMonth > 1"
							lines.push "				#{spacer}evaluatedValue = results.send attrName.to_sym"
							lines.push "			#{spacer}else"
							spacer << "\t"
						end  

						if ift.facetTypeCd == "COMPUTEDFORMULA" or ift.facetTypeCd == "COMPUTEDLOOKUP"
							lines.push "			#{spacer}methodName=\"\#{attrName}_m\".to_sym"
							lines.push "			#{spacer}evaluatedValue=results.send methodName"
						elsif ift.facetTypeCd == "COMPUTEDDECISIONTBL"
							if ift.computedFieldNameForRule
								lines.push "			#{spacer}quotation.additionalField = results.send \"#{ift.computedFieldNameForRule}\".to_sym"
							end  
							lines.push "			#{spacer}dt = MobiSys::ProductUtil.getProductDefinitionTableDO(#{ift.ruleSeq},quotation, @quotePlan)"
							lines.push "			#{spacer}evaluatedValue = (dt != nil ? dt.getValue : 0.0)"
						elsif ift.facetTypeCd == "GROUPING"
							lines.push "			#{spacer}evaluatedValue=hmFundGroupedAttribValues[\"Group_#{ift.inputDataElement}\".to_sym]"
						end  

						if ift.computationFreqCd == "EVERYCYCLEFM"
							spacer = spacer[0, spacer.length-2]
							lines.push "			#{spacer}end"
						end

						lines.push "			#{spacer}results.setAttr(attrName, evaluatedValue)"
						if illustrationModel.generateResults and illustrationModel.generateResults != "NO"
							lines.push "			#{spacer}resFieldsAtEndPerRate.addFieldValue(nil, \"#{ift.computedElementName}\", evaluatedValue, \"#{ift.elementLabel}\",#{ift.computationOrder})"
						end
						if Rho::RhoConfig.LogToOutput.to_i == 1
							lines.push "			log(\"#{ift.elementLabel}\",evaluatedValue,nil,#{parseLevel},illustrationRate.rate.to_s) " 
						end

						if ift.outputDisplayTypeCd == "PARTOFFIELD"
							lines.push "			#{spacer}setModelFieldData(quotation, policyYear, \"#{ift.inputDataElement}\",\"#{ift.inputElementSource}\", evaluatedValue)"
						end  
						if ift.isBreakExpression
							lines.push "			#{spacer}if (evaluatedValue and evaluatedValue.is_a?(String) and evaluatedValue.include?(\"break\"))"
							lines.push "				#{spacer}shouldBreak = true"
							lines.push "			#{spacer}end"
						end  
						lines.push "			end" if ift.elementFilter
						lines.push ""
					end #facetsComputedOnceAtEndPerRateForCurrentParseLevel.each do |ift|
					lines.push "			rateCounter += 1"
					lines.push "		end"
					lines.push "		\#facets computed once at end per rate end"
				end
				#code generation for facets computed once at end per rate - ends

				lines.push "		\#parse count #{parseLevel} ends"
				lines.push ""
				lines.push "		\#Copy over quotationParty.age into quotationParty.attainedAge as the age attribute has incremented in every cycle."
				lines.push "		\#Copy over quotationParty.entryAge into quotationParty.age as that was the original value before incrementing."
				lines.push "		quotation.QuotationPartyList.each do |qp|"
				lines.push "			qp.attainedAge = qp.age"
				lines.push "			qp.age = qp.entryAge"
				lines.push "		end"
				lines.push ""
			end #(1..maxBasicParseLevel).each do |parseLevel|

			lines.push "		\#Done. Finished."
			lines.push ""

			lines.push "		illusEndTime = Time.now"
			lines.push "		RhoLog.error(\"#{illustrationModel.modelCd}\",\"Calculated illustration at \#{illusEndTime.to_s} in \#{illusEndTime-illusTotalStartTime}s\")"

			if Rho::RhoConfig.LogToOutput.to_i == 1
				lines.push "			closelog "
			end

			lines.push ""
			lines.push "		return quotationIO"


			lines.push "	end \#def self.calculateIllustration(quotationIO)"
			lines.push ""
			#Done rendering calculateIllustration method

			#Render calculateWopRiderFacets method
			lines.push "	def self.calculateWopRiderFacets(illustrationModel, quotation, results, quotationIO, riderProductHash, riderList)"
			lines.push "		riderList.each do |quotationProduct|"
			lines.push "			MobiSys::ProductBO.calculateWOPSumAssured(quotation, quotationProduct)"
			lines.push "		end"
			lines.push "		calculateRiderFacets(illustrationModel, quotation, results, quotationIO, riderProductHash, riderList, true)"
			lines.push "	end \#def self.calculateWopRiderFacets(illustrationModel, quotation, results, quotationIO, riderProductHash, riderList)"
			#Done rendering calculateWopRiderFacets method

			#Render calculateRiderFacets method
			facetsComputedPerRider = Array.new

			illustrationModel.IllustrationFacetList.each do |ift|
				facetsComputedPerRider.push ift if ift.computePerInstanceOf == "RIDER" && ift.computationFreqCd != "ONCEFILTER"
			end
			facetsComputedPerRider.sort!{|x,y| x.computationOrder <=> y.computationOrder}

			lines.push ""
			lines.push "	def self.calculateRiderFacets(illustrationModel, quotation, results, quotationIO, riderProductHash, riderList, dontResetGroups=nil)"

			lines.push "		\#riderList = quotation.getRiders"
			lines.push "		unless dontResetGroups"
			riderFacets.each do |ift|
				lines.push "			results.group_#{ift} = 0.0"
			end
			lines.push "		end"
			if illustrationModel.generateResults and illustrationModel.generateResults != 'NO'
				lines.push "		hmRiderAttributes = quotationIO.hmRiderComputedAttributes"
			end  
			#lines.push "		hmGroupedSumValue = Hash.new"
			lines.push "		riderList.each do |quotationProduct|"
			lines.push "			if (@quotePlan.product && @quotePlan.product.getFacetValue('RIDERAUTOPOPULATIONREQUIRED') == \"YES\" && (quotationProduct.selected != \"on\" &&quotationProduct.selected != \"YES\" ) ) || quotationProduct.removed == \"YES\""
			lines.push "				next"
			lines.push "			end"
			lines.push "			@currSICalcRiderDO = quotationProduct"
			if illustrationModel.generateResults and illustrationModel.generateResults != "NO"
				lines.push "			resFieldsPerRider = MobiSys::DataObjects::FieldResult.new"
				lines.push "			listResFieldRider = hmRiderAttributes[quotationProduct]"
				lines.push "			unless listResFieldRider"
				lines.push "				listResFieldRider = Array.new"
				lines.push "				hmRiderAttributes[quotationProduct] = listResFieldRider"
				lines.push "			end"
				lines.push "			listResFieldRider.push resFieldsPerRider"
			end  
			lines.push "			results.quotationProduct = quotationProduct"
			lines.push "			policyMonth = results.currPolicyMonth"
			lines.push "			policyYear = results.currPolicyYear"
			lines.push "			currParseCount = results.currBasicParseCount"
			lines.push "            currentCycle = results.currCycleCount"                 
			lines.push "			product = riderProductHash[quotationProduct.productId]"
			lines.push "			if policyMonth == 1 and (policyYear > 1 || currParseCount > 1 || @isSolverCall) and quotationProduct.builtInRiderFl != \"YES\" and policyYear <= (quotationProduct.premiumPayingTerm.to_i + 1) && illustrationModel.modelFor.to_s == 'SI'"
			lines.push "				MobiSys::ProductBO.calculateModelBasedPremium(policyYear, quotation, quotationProduct, product) "
			lines.push "				MobiSys::ProductBO.calculateRiderValues(quotation, quotationProduct,policyYear)"
			lines.push "			end"
			lines.push ""
			lines.push "			quotationProduct.baseAnnualPremium = 0 unless quotationProduct.baseAnnualPremium"
			lines.push "			quotationProduct.baseSumAssured = 0 unless quotationProduct.baseSumAssured"
			lines.push "			quotationProduct.modalPremium = 0 unless quotationProduct.modalPremium"
			lines.push "			quotationProduct.extraPremium = 0 unless quotationProduct.extraPremium"
			lines.push ""
			lines.push "			fieldValueEvalOnceForFilter = eval(\"results.fieldValueEvalOnceForFilter\#{quotationProduct.guid}\")"
			if illustrationModel.generateResults and illustrationModel.generateResults != "NO"
				lines.push "				resFieldsPerRider.id = currentCycle.to_i"
				lines.push "				resFieldsPerRider.versionID = currParseCount.to_i"
				lines.push "				resFieldsPerRider.entityTypeCd = quotationProduct.product.longName"
			end  

			facetsComputedPerRider.each do |ift|
	
				spacer = "\t"
				if ift.elementFilter
					lines.push "			if ('#{ift.elementFilter}'.include?(fieldValueEvalOnceForFilter))"
					spacer << "\t"
				end
				lines.push "			#{spacer}attrName=\"#{ift.computedElementName}\""
				if ift.facetTypeCd == "COMPUTEDFORMULA" or ift.facetTypeCd == "COMPUTEDLOOKUP"
					lines.push "			#{spacer}methodName=\"\#{attrName}_m\".to_sym"
					lines.push "			#{spacer}evaluatedValue=results.send methodName"
				elsif ift.facetTypeCd == "COMPUTEDDECISIONTBL"
					if ift.computedFieldNameForRule
						lines.push "			#{spacer}quotation.additionalField = results.send \"#{ift.computedFieldNameForRule}\".to_sym"
					end  
					lines.push "			#{spacer}dt = MobiSys::ProductUtil.getProductDefinitionTableDO(#{ift.ruleSeq},quotation, quotationProduct)"
					lines.push "			#{spacer}evaluatedValue = (dt != nil ? dt.getValue : 0.0)"
				end  
				lines.push "			#{spacer}results.setAttr(attrName, evaluatedValue)"
				lines.push "			#{spacer}methodName = :group_#{ift.computedElementName}"
				lines.push "			#{spacer}existingValue = results.send methodName"
				lines.push "			#{spacer}existingValue += evaluatedValue unless evaluatedValue.is_a? String"
				lines.push "			#{spacer}methodName = :group_#{ift.computedElementName}="
				lines.push "			#{spacer}results.send methodName, existingValue"
				#lines.push "			groupKey = \"Group_#{ift.computedElementName}\""
				#lines.push "			addToGroup(hmGroupedSumValue, groupKey, evaluatedValue)"
				if illustrationModel.generateResults and illustrationModel.generateResults != "NO"
					lines.push "			#{spacer}resFieldsPerRider.addFieldValue(nil, \"#{ift.computedElementName}\", evaluatedValue, \"#{ift.elementLabel}\", #{ift.computationOrder})"
				end
				if Rho::RhoConfig.LogToOutput.to_i == 1
					lines.push "			log(\"#{ift.computedElementName}\",evaluatedValue,currentCycle.to_i,currParseCount.to_i,nil,quotationProduct.product.longName) "
				end

				if ift.elementFilter
					lines.push "			\telse"
					lines.push "			\t\tevaluatedValue = 0.0"
					lines.push "			\tend"
				end
				#add fields computed once to the output hashmap here
					if illustrationModel.generateResults != "NO" && ift.outputDisplayTypeCd.to_s != ""
					lines.push '		if(@siCalcCompleteOutputData != nil)'
					lines.push "			addElementToOutputMap(evaluatedValue,\"#{ift.origElementName}\",\"#{ift.computationFreqCd}\",\"#{ift.outputDisplayTypeCd}\")"
					lines.push '		end'
				end
			end
			lines.push "		@currSICalcRiderDO = nil"
			lines.push "		end"
			if illustrationModel.generateResults and illustrationModel.generateResults != "NO"
				lines.push "		quotationIO.hmRiderComputedAttributes = hmRiderAttributes"
			end

			#lines.push "		return hmGroupedSumValue"
			lines.push "	end"
			lines.push ""
			#Done rendering calculateRiderFacets method

			#Method to add computed value to hashmap for Output json - Start
			lines.push "	#method to add element evaluation value to hashmap for Output json"
			lines.push "	def self.addElementToOutputMap(hmEvalVal,elementName,computationFreqCd = nil, outputDisplayTypeCd = nil)"
			lines.push "		#Check if it is part of table then add it to the Ouput display map."
			lines.push "		if(@currCycleCalcOutputData != nil)"
			lines.push "			#if evaluated once per cycle directly add it else add to fund map else to rate map else to rider map "
			lines.push "			if(@currSICalcFundDO != nil)"
			lines.push "				fundCalcMap = @currCycleCalcOutputData[elementName]"
			lines.push "				if(fundCalcMap == nil)"
			lines.push "					fundCalcMap = {}"
			lines.push "					@currCycleCalcOutputData[elementName] = fundCalcMap"
			lines.push "				end"
			lines.push "				fundRateCalcMap = fundCalcMap[@currSICalcFundDO.fundCd]"
			lines.push "				if(fundRateCalcMap == nil)"
			lines.push "					fundRateCalcMap = {}"
			lines.push "					fundCalcMap[@currSICalcFundDO.fundCd] = fundRateCalcMap"
			lines.push "				end"
			lines.push "				fundRateCalcMap[@currSICalcRateDO.rateTypeCd] = hmEvalVal"
			lines.push "			elsif(@currSICalcRateDO != nil)"
			lines.push "				rateCalcMap = @currCycleCalcOutputData[elementName]"
			lines.push "				if(rateCalcMap == nil)"
			lines.push "					rateCalcMap = {}"
			lines.push "					@currCycleCalcOutputData[elementName] = rateCalcMap"
			lines.push "				end"
			lines.push "				rateCalcMap[@currSICalcRateDO.rateTypeCd] = hmEvalVal"
			lines.push "			elsif (@currSICalcRiderDO != nil) "
			lines.push "				partyRiderCalcMap = @currCycleCalcOutputData[elementName]"
			lines.push "				if(partyRiderCalcMap == nil)"
			lines.push "					partyRiderCalcMap = {}"
			lines.push "					@currCycleCalcOutputData[elementName] = partyRiderCalcMap"
			lines.push "				end"
			lines.push "				riderCalcMap = partyRiderCalcMap[@currSICalcRiderDO.insuredPartyRefGuid]"
			lines.push "				if(riderCalcMap == nil)"
			lines.push "					riderCalcMap = {}"
			lines.push "					partyRiderCalcMap[@currSICalcRiderDO.insuredPartyRefGuid] = riderCalcMap"
			lines.push "				end"
			lines.push "				riderCalcMap[@currSICalcRiderDO.productId] = hmEvalVal"
			lines.push "			else #per cycle elements"
			lines.push "				@currCycleCalcOutputData[elementName] = hmEvalVal"
			lines.push "			end"
			lines.push "		else #else check if defined once then add to output display"
			lines.push "			if((computationFreqCd == \"ONCE\" || computationFreqCd == \"ONCEATEND\") && outputDisplayTypeCd.to_s != \"\")"
			lines.push "				if @siCalcCompleteOutputData[\"GlobalData\"] != nil"
			lines.push "					@siCalcCompleteOutputData[\"GlobalData\"][elementName] = hmEvalVal"
			lines.push "				end"
			lines.push "			end"
			lines.push "		end"
			lines.push "	end"

			#Method to add computed value to hashmap for Output json - End


			#Render addToGroup method - start
			lines.push "	def self.addToGroup(hash, groupKey, evaluatedValue)"
			lines.push "		hashKey = groupKey.to_sym"
			lines.push "		groupedObjVal = hash[hashKey]"
			lines.push "		groupedVal = (groupedObjVal ? groupedObjVal.to_f : 0) + evaluatedValue.to_f"
			lines.push "		hash[hashKey] = groupedVal"
			lines.push "	end"
			#Render addToGroup method - end

			#Render setModelFieldData method - start
			lines.push ""
			lines.push "	def self.setModelFieldData(quotation, cycleCount, inputDataElement, inputElementSource, evaluatedVal)"
			lines.push "		bdo = nil;"
			lines.push ""
			lines.push "		if(inputElementSource != nil)"
			lines.push "			if inputElementSource == \"quotation\""
			lines.push "				bdo = quotation;"
			lines.push "			elsif inputElementSource == \"quotationProduct\""
			lines.push "				bdo = @quotePlan"
			lines.push "			elsif inputElementSource == \"quotation.getParty(quotationProduct)\" "
			lines.push "				bdo = quotation.getPartyByRole(\"PRIMARY\")"
			lines.push "			elsif inputElementSource == \"quotation.getPartyByRole('JOINT')\""
			lines.push "				bdo = quotation.getPartyByRole(""JOINT"")"
			lines.push "			elsif inputElementSource == \"quotation.getPartyByRole('PROPOSER')\" "
			lines.push "				bdo = quotation.getPartyByRole(\"PROPOSER\")"
			lines.push "			elsif inputElementSource == \"basePlan\""
			lines.push "				bdo = @quotePlan"
			lines.push "			elsif inputElementSource == \"quotation.getTopup( currPolicyYear )\""
			lines.push "				#for topups and withdrawals create new instances and set as a schedule is to be generated."
			lines.push "				#new instance is to be created per cycle .. thus for each element in the cycle check if already created"
			lines.push "				if(quotation.QuotationTopUpList.size == cycleCount)"
			lines.push "					bdo = quotation.QuotationTopUpList.last"
			lines.push "				else"
			lines.push "					bdo = QuotationTopUp.new"
			lines.push "					quotation.addQuotationTopUp(bdo)"
			lines.push "				end"
			lines.push "				#for the first cycle clear the existing data and going forward only the generated data would get added.        "
			lines.push "				if(cycleCount == 1 && bdo.guid == nil)"
			lines.push "					bdo.removed = ""YES"""
			lines.push "					#if it is new implies created from screen so new one shd get created after clearing."
			lines.push "					bdo = QuotationTopUp.new"
			lines.push "					quotation.addQuotationTopUp(bdo)"
			lines.push "				end"
			lines.push "			elsif inputElementSource == \"quotation.getWithdrawal( currPolicyYear )\""
			lines.push "				bdo = quotation.getWithdrawal(cycleCount)"
			lines.push "				if quotation.QuotationWithdrawalList.include? bdo"
			lines.push "					currPolicyWithdrawalDO = bdo"
			lines.push "					if currPolicyWithdrawalDO.policyYearFrom and currPolicyWithdrawalDO.policyYearTo"
			lines.push "						if currPolicyWithdrawalDO.policyYearFrom.to_i < currPolicyWithdrawalDO.policyYearTo.to_i"
			lines.push "							quotation.removeQuotationWithdrawal bdo"
			lines.push "							i = currPolicyWithdrawalDO.policyYearFrom.to_i"
			lines.push "							while i <= currPolicyWithdrawalDO.policyYearTo.to_i"
			lines.push "								generateWithdrawalDO = QuotationWithdrawal.new"
			lines.push "								generateWithdrawalDO.policyYearFrom = i"
			lines.push "								generateWithdrawalDO.policyYearTo = i"
			lines.push "								quotation.addQuotationWithdrawal generateWithdrawalDO"
			lines.push "								i += 1"
			lines.push "							end"
			lines.push "							quotation.QuotationWithdrawalList.sort!{|a,b| a.policyYearFrom.to_i <=> b.policyYearFrom.to_i}"
			lines.push "							bdo = quotation.getWithdrawal(cycleCount)"
			lines.push "						end"
			lines.push "					end"
			lines.push "				else"
			lines.push "					bdo = nil"
			lines.push "				end"
			lines.push "			end"
			lines.push "		end"
			lines.push ""
			lines.push "		if(inputDataElement != nil && bdo != nil && evaluatedVal != nil)"
			lines.push "			begin"
			lines.push "				methodName = \"\#{inputDataElement.gsub(\".to_f\",\"\")}=\".to_sym"
			lines.push "				bdo.send(methodName,evaluatedVal)"
			lines.push "			rescue StandardError => boom"
			lines.push "				puts \">>>StandardError occured in eval: \#{boom}\""
			lines.push "			end"
			lines.push "		end"
			lines.push "	end"
			lines.push ""
			#Render setModelFieldData method - end

			#Render calculateFundFacets method - start
			lines.push "	def self.calculateFundFacets(quotation, results, quotationIO, illustrationRate, illustrationModel)"

			lines.push "		listQuotationProductFunds = @quotePlan.QuotationProductInvestmentFundList"
			if illustrationModel.generateResults and illustrationModel.generateResults != "NO"
				lines.push "		hmFundAttributes = quotationIO.hmFundComputedAttributes"
			end  
			fundFacets.each do |ift|
				lines.push "		results.group_#{ift} = 0.0"
			end
			#lines.push "		hmGroupedSumValue = Hash.new"
			lines.push "		currentCycle = results.currCycleCount"
			lines.push "		quotationProduct = @quotePlan"
			lines.push "		currIllusNetRate = results.currIllusNetRate"

			(1..maxFundParseLevel).each do |parseLevel|
				fundFacetsForCurrentParseLevel = Array.new
				illustrationModel.IllustrationFacetList.each do |ift|
					# fundFacetsForCurrentParseLevel.push ift if ift.parseLevel == parseLevel and ift.computePerInstanceOf == "FUND" && ift.computationFreqCd != "ONCEPERFUND"
					fundFacetsForCurrentParseLevel.push ift if ift.computePerInstanceOf == "FUND" && ift.computationFreqCd != "ONCEPERFUND"
				end
				fundFacetsForCurrentParseLevel.sort!{|x,y| x.computationOrder <=> y.computationOrder}
				lines.push ""
				lines.push "		\#parse level #{parseLevel} start"
				lines.push "		listQuotationProductFunds.each do |qpif|"
				lines.push "			next unless (qpif.allocationPerc and qpif.allocationPerc.to_f > 0) or (qpif.topupAllocationPerc and qpif.topupAllocationPerc.to_f > 0)"
				lines.push "			@currSICalcFundDO = qpif"
				lines.push "			fundattrName = @attrNameHash[qpif.fundCd] ||= {}"
				lines.push "			fundrateattrName = fundattrName[illustrationRate.rateTypeCd] ||= {}"
				lines.push "			fundmethodName = @methodNameHash[qpif.fundCd] ||= {}"
				lines.push "			fundratemethodName = fundmethodName[illustrationRate.rateTypeCd] ||= {}"
				lines.push "			fundRate = illustrationRate.rate"
				lines.push "			if quotationIO.isSIModelRateFundWise"
				lines.push "				illustrationFundRate = quotationIO.originalSIModel.getIllustrationRate(illustrationRate.rateTypeCd,qpif.fundCd,results.currPolicyYear)"
				lines.push "				if illustrationFundRate == nil"
				lines.push "					RhoLog.error(\"CalculateIllustration\",\"No rate defined for fund: \#{qpif.fundCd} for rate type: \#{illustrationRate.rateTypeCd}\")"
				lines.push "					next"
				lines.push "				end"
				lines.push "				fundRate = illustrationFundRate.rate"
				lines.push "				results.currIllusNetRate = fundRate.to_f"
				lines.push "				@currSICalcRateDO = illustrationFundRate;"
				lines.push "			end"
				lines.push ""
				lines.push "			results.investmentFund = qpif"
				lines.push "			quotationIO.currentRate = fundRate"
				lines.push "			quotationIO.currentRateTypeCd = illustrationRate.rateTypeCd"
				lines.push "			quotationIO.currentQuotationPrdInvFundDO = qpif"
				lines.push "			quotationProduct.fundCd = qpif.fundCd"
				lines.push "			qpif.allocationPerc ||= 0"
				lines.push "			resFieldsPerFundPerRate = nil"
				lines.push "			fieldResultPerFundCycle = nil"
				if illustrationModel.generateResults and illustrationModel.generateResults != "NO"
					lines.push "			results.investmentFund = qpif"        
					lines.push ""
					if parseLevel == 1
						lines.push "			resFieldsPerFundPerRate = MobiSys::DataObjects::FieldResult.new"
						lines.push "			resFieldsPerFundPerRate.id = currentCycle.to_i"
						lines.push "			resFieldsPerFundPerRate.objectName = fundRate.to_s"
						lines.push "            resFieldsPerFundPerRate.versionID = #{parseLevel.to_i}"
						lines.push "			resFieldsPerFundPerRate.entityTypeCd = qpif.fundCd "
						lines.push "				qpif.allocationPerc ||= 0 "
						lines.push "			listResFieldFundPerCycle = hmFundAttributes[qpif]"
						lines.push "			unless listResFieldFundPerCycle"
						lines.push "				listResFieldFundPerCycle = Array.new"
						lines.push "				fieldResultPerFundCycle = MobiSys::DataObjects::FieldResult.new"
						lines.push "				fieldResultPerFundCycle.id = currentCycle.to_i"
						lines.push "					fieldResultPerFundCycle.entityTypeCd = qpif.fundCd"
						lines.push "				fieldResultPerFundCycle.objectName = fundRate.to_s"
						lines.push "					fieldResultPerFundCycle.versionID = #{parseLevel.to_i}"
						lines.push "				fieldResultPerFundCycle.fieldResultList.push resFieldsPerFundPerRate"
						lines.push "				listResFieldFundPerCycle.push fieldResultPerFundCycle"
						lines.push "				hmFundAttributes[qpif] = listResFieldFundPerCycle"
						lines.push "			else"
						lines.push "				if listResFieldFundPerCycle.size == currentCycle"
						lines.push "					fieldResultPerFundCycle = listResFieldFundPerCycle[currentCycle - 1]"
						lines.push "					fieldResultPerFundCycle.fieldResultList.push resFieldsPerFundPerRate"
						lines.push "				else"
						lines.push "					fieldResultPerFundCycle = MobiSys::DataObjects::FieldResult.new"
						lines.push "					fieldResultPerFundCycle.id = currentCycle.to_i"
						lines.push " 					fieldResultPerFundCycle.entityTypeCd = qpif.fundCd"
						lines.push " 					fieldResultPerFundCycle.objectName = fundRate.to_s "
						lines.push "					fieldResultPerFundCycle.versionID = #{parseLevel.to_i}"
						lines.push "					fieldResultPerFundCycle.fieldResultList.push resFieldsPerFundPerRate"
						lines.push "					listResFieldFundPerCycle.push fieldResultPerFundCycle"
						lines.push "				end"
						lines.push "			end"
					else
						lines.push "			fieldResultPerFundCycle = hmFundAttributes[qpif].at(currentCycle - 1)"
						lines.push "			fieldResultPerFundCycle.fieldResultList.each do |fieldResDO|"
						lines.push "				if fieldResDO.objectName == fundRate.to_s"
						lines.push "					resFieldsPerFundPerRate = fieldResDO"
						lines.push "					break"
						lines.push "				end"
						lines.push "			end"
					end  
				end
				fundFacetsForCurrentParseLevel.each do |ift|
					spacer = ""
					if groupedFacetNames.include? ift.computedElementName
						lines.push "			evaluatedValue = 0.0"
					end  
					lines.push "			#{spacer}fundrateattrName[:#{ift.computedElementName}] ||= :\"#{ift.computedElementName}\#{qpif.fundCd}\#{illustrationRate.rateTypeCd}=\"" unless ift.computationFreqCd == "ONCEPERFUND"
					if ift.parseLevel != parseLevel
						lines.push "			if resFieldsPerFundPerRate && resFieldsPerFundPerRate.containsFieldInMap(\"#{ift.computedElementName}\")"
						lines.push "				#{spacer}results.setAttr1(fundrateattrName[:#{ift.computedElementName}], resFieldsPerFundPerRate.getFieldValue(\"#{ift.computedElementName}\"))"
						# lines.push "			else"
						# lines.push "				#{spacer}results.setAttr1(fundrateattrName[:#{ift.computedElementName}], 0.0)"
						lines.push "			end"
						lines.push ""
						next
					end
					if ift.elementFilter
						lines.push "			if ('#{ift.elementFilter}'.include?(results.fieldValueEvalOnceForFilter))"
						spacer << "\t"
					end
					lines.push "			#{spacer}if \"#{ift.rateTypeCd}\" == nil or \"#{ift.rateTypeCd}\" == illustrationRate.rateTypeCd" if ift.rateTypeCd.to_s != ""
						if ift.computationFreqCd == "ONCEPERFUND"
							lines.push "			#{spacer}fundmethodName[:#{ift.computedElementName}] ||= :\"#{ift.computedElementName}\#{qpif.fundCd}\""
							lines.push "			#{spacer}evaluatedValue=results.send fundmethodName[:#{ift.computedElementName}]"
						elsif ift.facetTypeCd == "COMPUTEDFORMULA" or ift.facetTypeCd == "COMPUTEDLOOKUP"
							lines.push "			#{spacer}fundratemethodName[:#{ift.computedElementName}] ||= :\"#{ift.computedElementName}\#{qpif.fundCd}\#{illustrationRate.rateTypeCd}_m\""
							lines.push "			#{spacer}evaluatedValue=results.send fundratemethodName[:#{ift.computedElementName}]"
						elsif ift.facetTypeCd == "COMPUTEDDECISIONTBL"
							if ift.computedFieldNameForRule
								lines.push "			#{spacer}quotation.additionalField = results.send \"#{ift.computedFieldNameForRule}\".to_sym"
							end  
							lines.push "			#{spacer}dt = MobiSys::ProductUtil.getProductDefinitionTableDO(#{ift.ruleSeq},quotation, @quotePlan)"
							lines.push "			#{spacer}evaluatedValue = (dt != nil ? dt.getValue : 0.0)"
						elsif ift.facetTypeCd == "GROUPING"
							#lines.push "			#{spacer}evaluatedValue=hmGroupedSumValue[\"Group_#{ift.inputDataElement}\".to_sym]"
							lines.push "			#{spacer}evaluatedValue=results.send :group_#{ift.inputDataElement}"
						end
						if ift.rateTypeCd.to_s != ""
							lines.push "			#{spacer}else"
							lines.push "			#{spacer}	evaluatedValue = 0.0"
							lines.push "			#{spacer}end"
						end
						lines.push "			#{spacer}results.setAttr1(fundrateattrName[:#{ift.computedElementName}], evaluatedValue)" unless ift.computationFreqCd == "ONCEPERFUND"

					#lines.push "			#{spacer}mapKey=\"Group_#{ift.computedElementName}\""
					#lines.push "			#{spacer}addToGroup(hmGroupedSumValue, mapKey, evaluatedValue)"
					lines.push "			#{spacer}methodName = :group_#{ift.computedElementName}"
					lines.push "			#{spacer}existingValue = results.send methodName"
					lines.push "			#{spacer}existingValue += evaluatedValue"
					lines.push "			#{spacer}methodName = :group_#{ift.computedElementName}="
					lines.push "			#{spacer}results.send methodName, existingValue"
					if illustrationModel.generateResults and illustrationModel.generateResults != "NO"
						lines.push "			#{spacer}resFieldsPerFundPerRate.addFieldValue(nil, \"#{ift.computedElementName}\", evaluatedValue, \"#{ift.elementLabel}\",#{ift.computationOrder})"
					end
					if Rho::RhoConfig.LogToOutput.to_i == 1
						lines.push "			log(\"#{ift.computedElementName}\",evaluatedValue,currentCycle.to_s,#{parseLevel.to_i},fundRate.to_s,qpif.fundCd) "
					end
					lines.push "			end" if ift.elementFilter
					if groupedFacetNames.include? ift.computedElementName
						lines.push "			fundratemethodName[:arr_#{ift.computedElementName}] ||= :\"arr_#{ift.computedElementName}\#{qpif.fundCd}\#{illustrationRate.rateTypeCd}\""
						lines.push "			array = results.send fundratemethodName[:arr_#{ift.computedElementName}]"
						lines.push "			array.push evaluatedValue"
					end
					#add fields computed once to the output hashmap here
						if illustrationModel.generateResults != "NO" && ift.outputDisplayTypeCd.to_s != ""
						lines.push '		if(@siCalcCompleteOutputData != nil)'
						lines.push "			addElementToOutputMap(evaluatedValue,\"#{ift.origElementName}\",\"#{ift.computationFreqCd}\",\"#{ift.outputDisplayTypeCd}\")"
						lines.push '		end'
					end
				end  
				lines.push "		end #listQuotationProductFunds.each do |qpif|"
				lines.push "		\#parse level #{parseLevel} end"
			end  
			lines.push "		results.investmentFund = nil"
			lines.push "		@currSICalcFundDO = nil"
			lines.push "		@currSICalcRateDO = nil"
			lines.push ""
			lines.push "		quotationIO.currentRate = nil"
			lines.push "		quotationIO.currentRateTypeCd = nil"
			lines.push "		quotationIO.currentQuotationPrdInvFundDO = nil"
			lines.push "		quotationProduct.fundCd = nil"
			lines.push "		results.currIllusNetRate = currIllusNetRate"
			if illustrationModel.generateResults and illustrationModel.generateResults != "NO"
				lines.push "		quotationIO.hmFundComputedAttributes = hmFundAttributes"
			end

			#lines.push "		return hmGroupedSumValue"
			lines.push "	end"
			#Render calculateFundFacets method - end

			#Render calculateLifeFacets method - start
			lines.push "	def self.calculateLifeFacets(illustrationModel, quotation, results, quotationIO, illustrationRate)"

			lines.push "		listPolicyProductLives = quotation.getPlanList"
			lines.push "		originalQuotationProduct = results.quotationProduct"
			if illustrationModel.generateResults and illustrationModel.generateResults != "NO"
				lines.push "		hmMultiLifeAttributes = quotationIO.hmMultiLifeComputedAttributes"
			end  
				lines.push "		hmGroupedSumValue = Hash.new"
			lifeFacets.each do |ift|
				lines.push "		results.group_#{ift} = 0.0"
			end
			#lines.push "		hmGroupedSumValue = Hash.new"
			lines.push "		currentCycle = results.currCycleCount"
			lines.push "		quotationProduct = @quotePlan"
			lines.push "		currIllusNetRate = results.currIllusNetRate"

			(1..maxLifeParseLevel).each do |parseLevel|
				lifeFacetsForCurrentParseLevel = Array.new
				illustrationModel.IllustrationFacetList.each do |ift|

					# if ift.parseLevel == parseLevel and ift.computePerInstanceOf == "LIFE"
					if ift.computePerInstanceOf == "LIFE"
						if (ift.computationFreqCd == "EVERYCYCLE")
							lifeFacetsForCurrentParseLevel.push ift 
						end
					end
				end
				lifeFacetsForCurrentParseLevel.sort!{|x,y| x.computationOrder <=> y.computationOrder}
				lines.push ""
				lines.push "		\#parse level #{parseLevel} start"

				lines.push "		listPolicyProductLives.each do |policyProductLifeDO|"
				lines.push "			begin"

				lines.push "			rescue"
				lines.push "			end"

				lines.push "			lifeattrName = @attrNameHash[policyProductLifeDO.partyRoleCd] ||= {}"
				lines.push "			lifemethodName = @methodNameHash[policyProductLifeDO.partyRoleCd] ||= {}"


				lines.push ""
				lines.push "			results.quotationProduct = policyProductLifeDO"
				if illustrationModel.generateResults and illustrationModel.generateResults != "NO"
					lines.push "			fieldResultPerLifePerCyclePerRate = nil"
					lines.push "			fieldResultPerLifePerCycle = nil"        
					lines.push "			fieldResultPerLifeToAddData = nil"        
					lines.push ""
					if parseLevel == 1
						lines.push "			listResFieldMultiLifePerCycle = hmMultiLifeAttributes[policyProductLifeDO]"
						lines.push "			if listResFieldMultiLifePerCycle != nil && listResFieldMultiLifePerCycle.size == currentCycle"
						lines.push "				fieldResultPerLifePerCycle = listResFieldMultiLifePerCycle[currentCycle - 1]"
						lines.push "			else"
						lines.push "				fieldResultPerLifePerCycle = MobiSys::DataObjects::FieldResult.new"
						lines.push "				fieldResultPerLifePerCycle.id = currentCycle.to_i"
						lines.push "			end"
						lines.push "			fieldResultPerLifeToAddData = fieldResultPerLifePerCycle"

						lines.push "			#if rate wise data"
						lines.push "			if illustrationRate"
						lines.push "				fieldResultPerLifePerCyclePerRate = MobiSys::DataObjects::FieldResult.new"
						lines.push "				fieldResultPerLifePerCyclePerRate.id = currentCycle.to_i"
						lines.push "				fieldResultPerLifePerCyclePerRate.objectName = currIllusNetRate"
						lines.push "				fieldResultPerLifePerCyclePerRate.sortOrder = illustrationRate.id"
						lines.push "				fieldResultPerLifeToAddData = fieldResultPerLifePerCyclePerRate"
						lines.push "				fieldResultPerLifePerCycle.addFieldResult(fieldResultPerLifePerCyclePerRate)"
						lines.push "			end"


						lines.push "			#if no records found for that life then create list for the first time."
						lines.push "			if listResFieldMultiLifePerCycle == nil"
						lines.push "				listResFieldMultiLifePerCycle  = []"
						lines.push "				listResFieldMultiLifePerCycle.push(fieldResultPerLifePerCycle)"
						lines.push "				hmMultiLifeAttributes[policyProductLifeDO] = listResFieldMultiLifePerCycle"
						lines.push "			elsif listResFieldMultiLifePerCycle.size < currentCycle"
						lines.push "			listResFieldMultiLifePerCycle.push(fieldResultPerLifePerCycle)"
						lines.push "			end"
					else
						lines.push "			fieldResultPerLifePerCycle = hmMultiLifeAttributes[policyProductLifeDO][currentCycle - 1]"
						lines.push "			fieldResultPerLifeToAddData = fieldResultPerLifePerCycle"
						lines.push "			if illustrationRate"
						lines.push "				fieldResultPerLifePerCycle.fieldResultList.each do |fieldResDO|"
						lines.push "					if fieldResDO.objectName.to_s == illustrationRate.rate.to_s"
						lines.push "						fieldResultPerLifeToAddData = fieldResDO"
						lines.push "						break"
						lines.push "					end"
						lines.push "				end"
						lines.push "			end"
					end  
				end
				lifeFacetsForCurrentParseLevel.each do |ift|
					spacer = ""
					if groupedFacetNames.include? ift.computedElementName
						lines.push "			evaluatedValue = 0.0"
					end  
						# lines.push "			origComputedElementName = ift.computedElementName"
					if ift.elementFilter
						lines.push "			if ('#{ift.elementFilter}'.include?(results.fieldValueEvalOnceForFilter))"
						spacer << "\t"
					end
					lines.push "			#{spacer}lifeattrName[:#{ift.computedElementName}] ||= :\"#{ift.computedElementName}\#{policyProductLifeDO.partyRoleCd}=\"" unless ift.computationFreqCd == "ONCEPERFUND"

					if ift.facetTypeCd == "COMPUTEDFORMULA" or ift.facetTypeCd == "COMPUTEDLOOKUP"
						lines.push "			#{spacer}lifemethodName[:#{ift.computedElementName}] ||= :\"#{ift.computedElementName}\#{policyProductLifeDO.partyRoleCd}_m\""
						lines.push "			#{spacer}evaluatedValue=results.send lifemethodName[:#{ift.computedElementName}]"
					elsif ift.facetTypeCd == "COMPUTEDDECISIONTBL"
						if ift.computedFieldNameForRule
							lines.push "			#{spacer}quotation.additionalField = results.send \"#{ift.computedFieldNameForRule}\".to_sym"
						end  
						lines.push "			#{spacer}dt = MobiSys::ProductUtil.getProductDefinitionTableDO(#{ift.ruleSeq},quotation, policyProductLifeDO)"
						lines.push "			#{spacer}evaluatedValue = (dt != nil ? dt.getValue : 0.0)"
					elsif ift.facetTypeCd == "GROUPING"
						#lines.push "			#{spacer}evaluatedValue=hmGroupedSumValue[\"Group_#{ift.inputDataElement}\".to_sym]"
						lines.push "			#{spacer}evaluatedValue=results.send :group_#{ift.inputDataElement}"
					end

					lines.push "			#{spacer}results.setAttr1(lifeattrName[:#{ift.computedElementName}], evaluatedValue)" unless ift.computationFreqCd == "ONCEPERFUND"
					#lines.push "			#{spacer}mapKey=\"Group_#{ift.computedElementName}\""
					#lines.push "			#{spacer}addToGroup(hmGroupedSumValue, mapKey, evaluatedValue)"
					lines.push "			#{spacer}methodName = :group_#{ift.computedElementName}"
					lines.push "			#{spacer}existingValue = results.send methodName"
					lines.push "			#{spacer}existingValue += evaluatedValue"
					lines.push "			#{spacer}methodName = :group_#{ift.computedElementName}="
					lines.push "			#{spacer}results.send methodName, existingValue"
					if illustrationModel.generateResults and illustrationModel.generateResults != "NO"
						lines.push "			#{spacer}fieldResultPerLifePerCycle.addFieldValue(nil, \"#{ift.computedElementName}\", evaluatedValue, \"#{ift.elementLabel}\",#{ift.computationOrder})"
					end
					if Rho::RhoConfig.LogToOutput.to_i == 1
						lines.push "			log(\"#{ift.computedElementName}\",evaluatedValue,currentCycle.to_s) "
					end
					lines.push "			end" if ift.elementFilter
					if groupedFacetNames.include? ift.computedElementName
						lines.push "			lifemethodName[:arr_#{ift.computedElementName}] ||= :\"arr_#{ift.computedElementName}\#{policyProductLifeDO.partyRoleCd}\""
						lines.push "			array = results.send lifemethodName[:arr_#{ift.computedElementName}]"
						lines.push "			array.push evaluatedValue"					
					end
				end  
				lines.push "		end #listPolicyProductLives.each do |policyProductLifeDO|"
				lines.push "		\#parse level #{parseLevel} end"
			end  
			lines.push "		quotationIO.currentRate = nil"
			lines.push "		quotationIO.currentRateTypeCd = nil"
			lines.push "		results.currIllusNetRate = currIllusNetRate"
			lines.push "		results.quotationProduct = originalQuotationProduct"

			if illustrationModel.generateResults and illustrationModel.generateResults != "NO"
				lines.push "		quotationIO.hmMultiLifeComputedAttributes = hmMultiLifeAttributes"
			end
			#lines.push "		return hmGroupedSumValue"
			lines.push "	end"
			#Render calculateLifeFacets method - end

			#Render calculateLifeFacetsPerRate method - start
			lines.push "	def self.calculateLifeFacetsPerRate(illustrationModel, quotation, results, quotationIO, illustrationRate)"
			lines.push "		listPolicyProductLives = quotation.getPlanList"
			if illustrationModel.generateResults and illustrationModel.generateResults != "NO"
				lines.push "		hmMultiLifeAttributes = quotationIO.hmMultiLifeComputedAttributes"
			end  
				lines.push "		hmGroupedSumValue = Hash.new"
			lifeFacetsPerCyclePerRate.each do |ift|
				lines.push "		results.group_#{ift} = 0.0"
			end
			#lines.push "		hmGroupedSumValue = Hash.new"
			lines.push "		currentCycle = results.currCycleCount"
			lines.push "		quotationProduct = @quotePlan"
			lines.push "		currIllusNetRate = results.currIllusNetRate"
			lines.push "		originalQuotationProduct = results.quotationProduct"

			(1..maxLifeParseLevel).each do |parseLevel|
				lifeFacetsPerRateForCurrentParseLevel = Array.new
				illustrationModel.IllustrationFacetList.each do |ift|

					# if ift.parseLevel == parseLevel and ift.computePerInstanceOf == "LIFE"
					if ift.computePerInstanceOf == "LIFE"
						if (ift.computationFreqCd == "EVERYCYCLEPERRATE") 
							lifeFacetsPerRateForCurrentParseLevel.push ift
						end
					end
				end
				lifeFacetsPerRateForCurrentParseLevel.sort!{|x,y| x.computationOrder <=> y.computationOrder}
				lines.push ""
				lines.push "		\#parse level #{parseLevel} start"
				lines.push "		listPolicyProductLives.each do |policyProductLifeDO|"
				lines.push "			results.quotationProduct = policyProductLifeDO"
				lines.push "			lifeattrName = @attrNameHash[policyProductLifeDO.partyRoleCd] ||= {}"
				lines.push "			lifemethodName = @methodNameHash[policyProductLifeDO.partyRoleCd] ||= {}"
				lines.push "			if illustrationRate"
				lines.push "				liferateattrName = lifeattrName[illustrationRate.rateTypeCd] ||= {}"
				lines.push "				liferatemethodName = lifemethodName[illustrationRate.rateTypeCd] ||= {}"
				lines.push "				lifeRate = illustrationRate.rate"
				lines.push "			end"
				lines.push ""
				lines.push "			quotationIO.currentRate = lifeRate"
				lines.push "			if illustrationRate"
				lines.push "				quotationIO.currentRateTypeCd = illustrationRate.rateTypeCd"
				lines.push "			end"

				if illustrationModel.generateResults and illustrationModel.generateResults != "NO"
					lines.push "			fieldResultPerLifePerCyclePerRate = nil"
					lines.push "			fieldResultPerLifePerCycle = nil"        
					lines.push "			fieldResultPerLifeToAddData = nil"        
					lines.push ""
					if parseLevel == 1
						lines.push "			listResFieldMultiLifePerCycle = hmMultiLifeAttributes[policyProductLifeDO]"
						lines.push "			if listResFieldMultiLifePerCycle != nil && listResFieldMultiLifePerCycle.size == currentCycle"
						lines.push "				fieldResultPerLifePerCycle = listResFieldMultiLifePerCycle[currentCycle - 1]"
						lines.push "			else"
						lines.push "				fieldResultPerLifePerCycle = MobiSys::DataObjects::FieldResult.new"
						lines.push "				fieldResultPerLifePerCycle.id = currentCycle"
						lines.push "			end"
						lines.push "			fieldResultPerLifeToAddData = fieldResultPerLifePerCycle"

						lines.push "			#if rate wise data"
						lines.push "			if illustrationRate"
						lines.push "				fieldResultPerLifePerCyclePerRate = MobiSys::DataObjects::FieldResult.new"
						lines.push "				fieldResultPerLifePerCyclePerRate.id = currentCycle"
						lines.push "				fieldResultPerLifePerCyclePerRate.objectName = currIllusNetRate"
						lines.push "				fieldResultPerLifePerCyclePerRate.sortOrder = illustrationRate.id"
						lines.push "				fieldResultPerLifeToAddData = fieldResultPerLifePerCyclePerRate"
						lines.push "				fieldResultPerLifePerCycle.addFieldResult(fieldResultPerLifePerCyclePerRate)"
						lines.push "			end"


						lines.push "			#if no records found for that life then create list for the first time."
						lines.push "			if listResFieldMultiLifePerCycle == nil"
						lines.push "				listResFieldMultiLifePerCycle  = []"
						lines.push "				listResFieldMultiLifePerCycle.push(fieldResultPerLifePerCycle)"
						lines.push "				hmMultiLifeAttributes[policyProductLifeDO] = listResFieldMultiLifePerCycle"
						lines.push "			elsif listResFieldMultiLifePerCycle.size < currentCycle"
						lines.push "			listResFieldMultiLifePerCycle.push(fieldResultPerLifePerCycle)"
						lines.push "			end"
					else
						lines.push "			fieldResultPerLifePerCycle = hmMultiLifeAttributes[policyProductLifeDO][currentCycle - 1]"
						lines.push "			fieldResultPerLifeToAddData = fieldResultPerLifePerCycle"
						lines.push "			if illustrationRate"
						lines.push "				fieldResultPerLifePerCycle.fieldResultList.each do |fieldResDO|"
						lines.push "					if fieldResDO.objectName.to_s == illustrationRate.rate.to_s"
						lines.push "						fieldResultPerLifeToAddData = fieldResDO"
						lines.push "						break"
						lines.push "					end"
						lines.push "				end"
						lines.push "			end"
					end  
				end
				lifeFacetsPerRateForCurrentParseLevel.each do |ift|
					spacer = ""
					if groupedFacetNames.include? ift.computedElementName
						lines.push "			evaluatedValue = 0.0"
					end  
						# lines.push "			origComputedElementName = ift.computedElementName"
					if ift.elementFilter
						lines.push "			if ('#{ift.elementFilter}'.include?(results.fieldValueEvalOnceForFilter))"
						spacer << "\t"
					end
					lines.push "			#{spacer}liferateattrName[:#{ift.computedElementName}] ||= :\"#{ift.computedElementName}\#{policyProductLifeDO.partyRoleCd}\#{illustrationRate.rateTypeCd}=\"" unless ift.computationFreqCd == "ONCEPERFUND"

					if ift.facetTypeCd == "COMPUTEDFORMULA" or ift.facetTypeCd == "COMPUTEDLOOKUP"
						lines.push "			#{spacer}liferatemethodName[:#{ift.computedElementName}] ||= :\"#{ift.computedElementName}\#{policyProductLifeDO.partyRoleCd}\#{illustrationRate.rateTypeCd}_m\""
						lines.push "			#{spacer}evaluatedValue=results.send liferatemethodName[:#{ift.computedElementName}]"
					elsif ift.facetTypeCd == "COMPUTEDDECISIONTBL"
						if ift.computedFieldNameForRule
							lines.push "			#{spacer}quotation.additionalField = results.send \"#{ift.computedFieldNameForRule}\".to_sym"
						end  
						lines.push "			#{spacer}dt = MobiSys::ProductUtil.getProductDefinitionTableDO(#{ift.ruleSeq},quotation, policyProductLifeDO)"
						lines.push "			#{spacer}evaluatedValue = (dt != nil ? dt.getValue : 0.0)"
					elsif ift.facetTypeCd == "GROUPING"
						#lines.push "			#{spacer}evaluatedValue=hmGroupedSumValue[\"Group_#{ift.inputDataElement}\".to_sym]"
						lines.push "			#{spacer}evaluatedValue=results.send :group_#{ift.inputDataElement}"
					end

					lines.push "			#{spacer}results.setAttr1(liferateattrName[:#{ift.computedElementName}], evaluatedValue)" unless ift.computationFreqCd == "ONCEPERFUND"
					#lines.push "			#{spacer}mapKey=\"Group_#{ift.computedElementName}\""
					#lines.push "			#{spacer}addToGroup(hmGroupedSumValue, mapKey, evaluatedValue)"
					lines.push "			#{spacer}methodName = :group_#{ift.computedElementName}"
					lines.push "			#{spacer}existingValue = results.send methodName"
					lines.push "			#{spacer}existingValue += evaluatedValue"
					lines.push "			#{spacer}methodName = :group_#{ift.computedElementName}="
					lines.push "			#{spacer}results.send methodName, existingValue"
					if illustrationModel.generateResults and illustrationModel.generateResults != "NO"
						lines.push "			#{spacer}fieldResultPerLifePerCyclePerRate.addFieldValue(nil, \"#{ift.computedElementName}\", evaluatedValue, \"#{ift.elementLabel}\",#{ift.computationOrder})"
					end
					if Rho::RhoConfig.LogToOutput.to_i == 1
						lines.push "			log(\"#{ift.computedElementName}\",evaluatedValue,currentCycle,nil,currIllusNetRate) "
					end

					lines.push "end" if ift.elementFilter
					if groupedFacetNames.include? ift.computedElementName
						lines.push "			liferatemethodName[:arr_#{ift.computedElementName}] ||= :\"arr_#{ift.computedElementName}\#{policyProductLifeDO.partyRoleCd}\#{illustrationRate.rateTypeCd}\""
						lines.push "			array = results.send liferatemethodName[:arr_#{ift.computedElementName}]"
						lines.push "			array.push evaluatedValue"
					end
				end  
				lines.push "		end #listPolicyProductLives.each do |policyProductLifeDO|"
				lines.push "		\#parse level #{parseLevel} end"
			end  
			lines.push "		quotationIO.currentRate = nil"
			lines.push "		quotationIO.currentRateTypeCd = nil"
			lines.push "		results.currIllusNetRate = currIllusNetRate"
			lines.push "		results.quotationProduct = originalQuotationProduct"
			if illustrationModel.generateResults and illustrationModel.generateResults != "NO"
				lines.push "		quotationIO.hmMultiLifeComputedAttributes = hmMultiLifeAttributes"
			end
			#lines.push "		return hmGroupedSumValue"
			lines.push "	end"
			#Render calculateLifeFacetsPerRate method - end

			lines.push	"			def self.log(elementName,elementValue,cycleCount=nil,parseCount=nil,rate=nil,fundCd=nil) "
			lines.push	"				cycleCount = cycleCount != nil ? cycleCount.to_s : ''  "
			lines.push	"				parseCount = parseCount != nil ? parseCount.to_s : '' "
			lines.push	"				rate = 	rate != nil ? rate.to_s : '' "
			lines.push	"				fundCd = fundCd != nil ? fundCd.to_s : '' "
		
			lines.push	"				@calculate_loggin_file.puts( parseCount + ' , ' + cycleCount + ' , ' + rate + ' , ' + fundCd + ' , ' +  elementName.to_s + ',' +elementValue.to_s)"
			lines.push	" 			end "

			lines.push "			def self.writelog(logFor, quotation) "
			lines.push " 				if Rho::RhoConfig.LogToOutput.to_i == 1 "
			lines.push " 					@calculate_loggin_file = File.open(Rho::RhoApplication.get_blob_folder + File::SEPARATOR + \"\#{quotation.quotationRefNum}.csv\",'w') "
			lines.push " 					if ( logFor == 'SIModel' )"
			lines.push " 						@calculate_loggin_file.puts('Parse,Cycle,Rate,Fund/Rider,Element,Value')"
			lines.push " 					end "
			lines.push "				end "
			lines.push " 			end "
			lines.push " 			def self.closelog "
			lines.push " 				@calculate_loggin_file.close "
			lines.push " 			end "
			lines.push " 			def self.modellog(modeldo) "
			lines.push "				if Rho::RhoConfig.LogToOutput.to_i == 1 &&  @isCalculateIllust
											@calculate_loggin_file.puts(' , , , , Model>>>>' + modeldo.modelFor + ' >>>>, ' + modeldo.modelCd ) "
			lines.push " 				end "
			lines.push " 			end "

			lines.push "		end"
			dbversion = Application.getValue('DBVERSION').value
			fileName = "#{Rho::Application.userFolder}#{illustrationModel.modelCd}_#{generateExpression}_#{dbversion}.rb"
			file = File.open(fileName,'w')# do |f|
			lines.each do |line|
				file.puts line
			end
			file.close
			if Rho::System.platform != "APPLE"
				seq = RubyVM::InstructionSequence.compile_file(fileName)
				arr = seq.to_a
				newName = fileName.sub('.rb','.iseq')
				fseq = File.new(newName, 'w')
				Marshal.dump(arr,fseq)
				fseq.close
			end
		end
	end

	def getFrequencyMultiplier
		frequencyCd = self.computationFrequencyCd
		case frequencyCd
		when "YEARLY"
			1
		when "MONTHLY"
			12
		when "HALFYEARLY"
			2
		when "QUARTERLY"
			4
		when "SINGLE"
			1
		when "DAILY"
			365
		else
			0
		end
	end
end

begin 
	require 'IllustrationModel/illustration_model_company'
rescue LoadError => e
	puts 'illustration_model_company not included'
end