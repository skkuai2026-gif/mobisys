require 'CommonClasses/BaseModel'

module MobiSys

	class PolicyPlanModel < BaseModel

        def initialize(io)
            #puts "~~~in PolicyPlanModel initialize: #{io.inspect}"
            super(io)
            #puts "~~~baseIO:#{self.baseIO}"
        end

		def getModel
			#logInfo("~~~baseIO in PolicyPlanModel:#{self.baseIO.inspect}")
            #logInfo("~~~in self.parentBaseDO : #{self.parentBaseDO.class.name}")
            policy = self.parentBaseDO
            policyProduct = policy.getBaseProduct
            $currentProduct = MobiSys::ProductUtil.getProduct(policy.baseProductSeq)

            quotation = MobiSys::PolicyBO.convertToQuotation(policy)
            quotationBasePlan = quotation.getBaseProduct

            fundRequiredDetailsDT = $currentProduct.getFacetValue("FUNDSREQUIREDNB")
            modelArray = MobiSys::PolicyService.getPortfolioModels($currentProduct,quotation,quotationBasePlan) if fundRequiredDetailsDT == 'YES'

            #Set productPlanOptionDesc
            policyProduct.productPlanOptionDesc = policyProduct.getProductPlanOptionDesc

            product = MobiSys::ProductUtil.getProduct(policyProduct.productSeq) if policyProduct.productSeq.to_s != ""
            policyProduct.productLongName = product.longName if product

            # if policyProduct.PolicyProductInsuredList.count == 0
            #     primaryParty = self.parentBaseDO.getParty("PRIMARY")
            #     policyProduct.addPolicyProductInsured(PolicyProductInsured.new(:roleCd => "PRIMARY", :insuredSequenceTypeCd => "PRIMARY", :refGuid => primaryParty.guid, :partyId => primaryParty.partyId))
            # end

            return policyProduct
		end

        def setModel(policyProduct)
            if policyProduct.to_s != "" && policyProduct.productTypeCd.to_s == ""
                policyProduct.productTypeCd.to_s = "PLAN"
            end

            return policyProduct
        end

	end
end

begin
    require 'Policy/PolicyPlanModel_company'
rescue LoadError => e
    puts 'PolicyPlanModel_company not included'
end
