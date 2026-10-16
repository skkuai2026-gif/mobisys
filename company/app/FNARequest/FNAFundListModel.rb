require 'CommonClasses/BaseModel'
require 'CommonModules/mobisysbrowserhelper'

module MobiSys
	
	class FNAFundListModel < BaseModel
		include MobiSys::BrowserHelper

		def initialize(io)
            super(io)
        end

		def getModel
            fnaRequest = self.parentBaseDO
            return nil if fnaRequest == nil
            listFNAFundDO = []

            fundAcrreditation = ""
            agentDO = AgentReg.getCurrentAgentReg
            fundAcrreditation = agentDO.field6 if agentDO

            rpqFundListData = Lookupvalue.find(
                :all,
                :conditions =>{
                    {
                        :name => 'key'
                    } => "RPQFUNDS"
                }
            )

            rpqFundList = []

            if fundAcrreditation.to_s == ""
                FNAFund.delete_all(:conditions=>{{:name=>'parentkey'}=> fnaRequest.object, {:name=>'field2'} => 'FX'},:op => 'AND')
            end

            if !rpqFundListData.empty? && rpqFundListData.length > 0
                rpqFundListData.each do |lkpDataDO|
                    if fundAcrreditation.to_s == "" && lkpDataDO.additionalField2.to_s != ""
                      next
                    end
                    rpqFundList.push(lkpDataDO)
                end
            end


            fieldTargetValueMapDOList = FieldTargetValueMap.find(
                :all,
                :conditions => {
                    {:name=>'mappingKey'} => "RPQFUND"
                }
            )
            leadRPQ = LeadRPQ.loadObject(:first, :conditions => {:fnaId => fnaRequest.fnaNum.to_s})
            if leadRPQ.address1.to_s == ""
                if !fieldTargetValueMapDOList.empty? && fieldTargetValueMapDOList.length > 0 
                    fieldTargetValueMapDOList.each do |fieldTargetValueMapDO|
                        if fieldTargetValueMapDO.targetValue.to_s != "" && fieldTargetValueMapDO.drivingValue.to_s != ""
                            if fieldTargetValueMapDO.drivingValue.to_s == fnaRequest.reasonForRecoCd.to_s
                                rpqFund = rpqFundList.select {|fund| fund.cd.to_s == fieldTargetValueMapDO.targetValue.to_s }[0]
                                fnaFundDO = fnaRequest.getFNAFundByFundCd(rpqFund.cd.to_s, self.createNewObject) if rpqFund
                                if fnaFundDO
                                    fnaFundDO.field1 = rpqFund.additionalField1.to_s
                                    fnaFundDO.field2 = rpqFund.additionalField2.to_s
                                    risk = Lookupvalue.getLookupValue("FUNDRISKCLASS",rpqFund.additionalField1.to_s)
                                    risk = "High" if risk.to_s == ""
                                    fnaFundDO.fundRiskClassLabel = risk
                                    listFNAFundDO.push(fnaFundDO)
                                end
                            end
                        end
                    end
                    fnaRequest.setFNAFundList(listFNAFundDO)
                end
            elsif leadRPQ.address1.to_s == "INDIVIDUAL" || fnaRequest.addtnField3Str.to_s == "YES"
                if fieldTargetValueMapDOList && !fieldTargetValueMapDOList.empty?
                  fieldTargetValueMapDOList.each do |fieldTargetValueMapDO|
                    targetValue = fieldTargetValueMapDO.targetValue
                    drivingValue = fieldTargetValueMapDO.drivingValue

                    next if targetValue.nil? || drivingValue.nil?

                    if drivingValue.casecmp(fnaRequest.reasonForRecoCd.to_s).zero?
                      rpqFund = rpqFundList.select {|fund| fund.cd.to_s == fieldTargetValueMapDO.targetValue.to_s }[0]
                      rpqFundList.each do |baseDO|
                        lookupDataCd = baseDO.cd

                        if lookupDataCd.casecmp(targetValue.to_s).zero?
                          fnaFundDO = fnaRequest.getFNAFundByFundCd(lookupDataCd, false)

                          if fnaFundDO.nil?
                            fnaFundDO = FNAFund.new
                          end
                          fnaFundDO.fundCd = lookupDataCd
                          fnaFundDO.field1 = rpqFund.additionalField1.to_s
                          fnaFundDO.field2 = rpqFund.additionalField2.to_s
                          fnaFundDO.sortOrder = rpqFund.sortOrder.to_s
                          # fnaFundDO.allocationPerc = nil
                          risk = Lookupvalue.getLookupValue("FUNDRISKCLASS",rpqFund.additionalField1.to_s)
                          risk = "High" if risk.to_s == ""
                          fnaFundDO.fundRiskClassLabel = risk
                          listFNAFundDO << fnaFundDO
                          listFNAFundDO.sort_by! { |f| f.sortOrder.to_i }
                        end
                      end
                    end
                  end
                end
                fnaRequest.setFNAFundList(listFNAFundDO)
                fnaRequest.addtnField3Str = "NO"
            elsif leadRPQ.address1.to_s == "PACKAGE" 
                fnaFundDOList = fnaRequest.FNAFundList
                fnaFundDOList.each do |fnaFundDO|
                    fundList = Fund.find(
                                                :first,
                                                :conditions =>{
                                                    {
                                                        :name => 'fundCd' 
                                                    } => fnaFundDO.fundCd
                                                }
                                            )
                    fnaFundDO.field2 = fundList.addtnlFld1Str.to_s
                    risk = Lookupvalue.getLookupValue("FUNDRISKCLASS",fnaFundDO.field1.to_s)
                    risk = "High" if risk.to_s == ""
                    fnaFundDO.fundRiskClassLabel = risk
                    listFNAFundDO.push(fnaFundDO) if fnaFundDO.allocationPerc.to_s != ""
                end
            end
            fnaRequest.setFNAFundList(listFNAFundDO)             
            return listFNAFundDO
        end

		def setModel(entity)
			fnaRequest = self.parentBaseDO
			if entity && entity.size > 0
				entity.each do |fund|
                    fund.removed = "YES" if fund.allocationPerc.to_s == ""
                    fund.removed = "" if fund.allocationPerc.to_s != "" && fund.status.to_s != "N" && fund.removed.to_s == "YES"
    			end
			end
			return entity
		end
	end	
end