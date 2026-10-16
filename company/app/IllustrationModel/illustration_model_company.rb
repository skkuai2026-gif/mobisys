# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
class IllustrationModel
	include MobiSys::MobiSysFixedSchema

	set :schema_version, '1.0'
	set :partition, :master

	# Uncomment the following line to enable sync with IllustrationModel.
	# enable :sync
	
	# This method is to be overridden at company layer to explicitly type cast additional fields
	def typeCastingAdditionalFields(facet)
	    # This is just an example of how  to typecast additional field
	    # facet.expression.gsub!("self.quotation.quotAddtnlField4.to_s", "self.quotation.quotAddtnlField4.to_i")
	    facet.expression.gsub!("self.quotation.quotAddtnlField4.to_s", "self.quotation.quotAddtnlField4.to_f")
	    facet.expression.gsub!("self.quotation.quotAddtnlField3.to_s", "self.quotation.quotAddtnlField3.to_f")
	    facet.expression.gsub!("self.quotationProduct.addtnField2.to_s", "self.quotationProduct.addtnField2.to_f")
	    facet.expression.gsub!("self.quotationProduct.addtnField3.to_s", "self.quotationProduct.addtnField3.to_f")
	    facet.expression.gsub!(".targetPeriod<", ".targetPeriod.to_i<")
	    facet.expression.gsub!(".targetPeriod>", ".targetPeriod.to_i>")
	    facet.expression.gsub!(".allocatedtorole", ".allocatedToRole")
	    facet.expression.gsub!(".payingYears<", ".payingYears.to_i<")
	    facet.expression.gsub!(".payingYears>", ".payingYears.to_i>")
	    if facet.expression.include?("include?")
		    facet.expression.gsub!(")=='false'", ")==false")
		    facet.expression.gsub!(")=='true'", ")==true")
		end    
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
				Regexp.new(/(com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyRiderDO.getPolicyProductForParty\()(\"[\w\"\,]*\"\,[\w\"\.]*\))(\.?\w*)/),
				'self.quotationProduct.getPolicyProductForParty(self.quotation,',
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
		        'WITHDRAWALMETHOD',
		        'withdrawalmethod',
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
				Regexp.new(/(PolicyDocumentDO)((?:\.\w+)+)/), 
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
			# puts"facet.origElementName======#{facet.origElementName}"
			firstChar = facet.computedElementName.slice(0,1)
			# puts"firstChar======#{firstChar}"
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
					puts"facet.expression========#{facet.expression}"
				if self.modelFor == 'UNDERWRITING' || self.modelFor == 'POLICY' || self.modelFor == 'DYNAMICDT'
					# puts"regexUWConditions========#{regexUWConditions}"
					regexUWConditions.each do |regexArray|
						regexReplacer(facet.expression.to_s, regexArray[0], regexArray[1], regexArray[2])
					end
				else
					regexQuotationConditions.each do |regexArray|
						regexReplacer(facet.expression.to_s, regexArray[0], regexArray[1], regexArray[2])
					end
					# facet.expression = ""
				end
				# puts"regexUtilityConditions=========#{regexUtilityConditions}"
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
					# puts"key==========#{key}"
					# puts"value==========#{value}"
					ift.expression.gsub!(/_#{key}_/i, "_#{value}_")
					ift.expression.gsub!("_#{key}","_#{value}") if self.modelFor == 'UNDERWRITING' || self.modelFor == 'POLICY'
					puts"ift.expression=======#{ift.expression}" if ift.elementLabel.to_s =="ElementA"
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
end
