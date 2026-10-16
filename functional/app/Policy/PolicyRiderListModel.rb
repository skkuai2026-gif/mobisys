require 'CommonClasses/BaseModel'

module MobiSys
	
	class PolicyRiderListModel < BaseModel

        def initialize(io)
            #puts "~~~in PolicyRiderListModel initialize: #{io.inspect}"
            super(io)
            #puts "~~~baseIO:#{self.baseIO}"
        end

		def getModel
			#logInfo("~~~baseIO in PolicyRiderListModel:#{self.baseIO.inspect}")
            #logInfo("~~~in self.parentBaseDO : #{self.parentBaseDO.class.name}")
            riderList = self.parentBaseDO.getRiderList
            orderedPolicyRiderList = []

            if riderList.size > 0
                baseProduct = self.parentBaseDO.getBaseProduct
                $currentProduct ||= MobiSys::ProductUtil.getProduct(baseProduct.productSeq.to_s) if baseProduct
                #Set Product Long name and insuredPartyName for tabs on UI
                riderList.each do |rider|
                    product = MobiSys::ProductUtil.getProduct(rider.productSeq) if rider.productSeq.to_s != ""
                    rider.productLongName = product.longName if product
                    productInsured = rider.PolicyProductInsuredList[0]
                    insuredParty = self.parentBaseDO.getPartyByGuid(productInsured.refGuid)
                    rider.insuredPartyName = insuredParty.getFullName if insuredParty
                end

                #Order Riders as per Party Roles
                policyRiderProducts = CommonUtil.getLinkedHashedList("insuredPartyRefGuid",riderList)
                partyNames = self.parentBaseDO.getPartyNames
                partyNames.each do |partyGuid, value|
                    partyWiseRiderList = policyRiderProducts[partyGuid]
                    if partyWiseRiderList != nil and partyWiseRiderList.size > 0
                        partyWiseRiderList.sort!{|x,y| x.sortOrder.to_i<=>y.sortOrder.to_i}
                        orderedPolicyRiderList.push(partyWiseRiderList).flatten!
                    end
                end
            end

            return orderedPolicyRiderList
		end

	end
	
end

begin 
    require 'Policy/PolicyRiderListModel_company'
rescue LoadError => e
    puts 'PolicyRiderListModel_company not included'
end