require 'CommonClasses/BaseModel'

module MobiSys
	
	class PolicyInvestmentFundListModel < BaseModel

        def initialize(io)
            #puts "~~~in PolicyInvestmentFundListModel initialize: #{io.inspect}"
            super(io)
            #puts "~~~baseIO:#{self.baseIO}"
        end

		def getModel
			#logInfo("~~~baseIO in PolicyInvestmentFundListModel:#{self.baseIO.inspect}")
            #logInfo("~~~in self.parentBaseDO : #{self.parentBaseDO.class.name}")
            policyProduct = self.parentBaseDO
            policy = self.baseIO.baseDO
            return policyProduct.PolicyProductInvestmentFundList if self.respond_to?(:isOnlySelectedReqd) && self.isOnlySelectedReqd.to_s == "YES"

            if policyProduct.portfolioModelCd.to_s != ""
                model = Model.loadObject(:first,
                        :conditions =>{
                        {
                            :name => 'modelCd'
                        } => policyProduct.portfolioModelCd
                    }
                )
            end
            if model
                fundArray = model.getModelFunds.map {|x| x.fundCd.to_s}

                fundList = Fund.find(
                    :all,
                    :conditions =>{
                        {
                            :name => 'fundCd',
                            :op => 'IN' 
                        } => fundArray
                    }
                )
            else
                fundList = []
            end

            selectedFundCdList = policyProduct.PolicyProductInvestmentFundList.map{|x| x.fundCd.to_s}
            fundList.sort!{|x,y| x.sortOrder.to_i <=> y.sortOrder.to_i}
            fundCdList = fundList.map {|x| x.fundCd.to_s}
            fundList.each do |fund|
                unless selectedFundCdList.include?(fund.fundCd.to_s)
                    if self.createNewObject
                        policyProductInvestmentFund = PolicyProductInvestmentFund.new
                        policyProductInvestmentFund.fundCd = fund.fundCd
                        policyProductInvestmentFund.expiryDt = fund.expiryDt
                        policyProductInvestmentFund.fundTypeCd = fund.fundTypeCd
                        policyProductInvestmentFund.maturityDt = fund.maturityDt
                        policyProductInvestmentFund.sortOrder = fund.sortOrder
                        policyProductInvestmentFund.removed = "YES"
                        policyProduct.addPolicyProductInvestmentFund(policyProductInvestmentFund)
                    end
                end
            end
            policyProduct.PolicyProductInvestmentFundList.delete_if do |policyProductInvestmentFund|
                unless fundCdList.include?(policyProductInvestmentFund.fundCd.to_s)
                    existingFund = PolicyProductInvestmentFund.loadObject(
                        :first,
                        :loadChild => false,
                        :conditions => {
                            :object=>policyProductInvestmentFund.object
                        }
                    )
                    existingFund.destroy if existingFund
                    true
                end
            end
            
            #Sort based on fundList sortorder
            sortedList = policyProduct.PolicyProductInvestmentFundList.sort_by{|x| fundCdList.index x.fundCd} 
            policyProduct.setPolicyProductInvestmentFundList(sortedList)
            
            return policyProduct.PolicyProductInvestmentFundList
		end

        def setModel(entity)
            policyProduct = self.parentBaseDO
            policyProduct.PolicyProductInvestmentFundList.each do |investmentFund|
                if investmentFund.allocationPerc.to_f <= 0
                    investmentFund.removed = "YES"
                end
            end
            
            return entity
        end

	end
end

begin 
    require 'Policy/PolicyInvestmentFundListModel_company'
rescue LoadError => e
    puts 'PolicyInvestmentFundListModel_company not included'
end