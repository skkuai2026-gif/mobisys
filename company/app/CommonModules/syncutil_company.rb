module MobiSys
	module SyncUtil

        def self.deleteUserData
            #User previous data to be deleted
            userdeletedate = AgentReg.forUserId($userId)
            if userdeletedate.userDataDeleteDays
                @userdatecondition = (Date.today - userdeletedate.userDataDeleteDays).to_time
                Policy.loadObject(:all).each do |policy|
                    if((policy.signatureStatus != "" && policy.proposalSignedDt.to_s != "" && policy.proposalSignedDt < @userdatecondition.to_s) || (policy.proposalSignedDt.to_s == "" && policy.proposalReceivedDt.to_s != "" && policy.proposalReceivedDt < @userdatecondition.to_s) || policy.statusCd == "SUBMITTED")
                        linkedQuotation = Quotation.loadObject(:first, :conditions => {{:name => 'proposalNum'} =>policy.proposalNum.to_s})
                        linkedQuotation.delete if linkedQuotation
                        policy.delete  if policy
                    end
                end
                Quotation.loadObject(:all, :conditions => {{:name => 'quotationDt', :op => '<'} =>@userdatecondition.to_s}).each do |user_deleted_entity|
                    #Check if quotation is linked to any policy
                    if user_deleted_entity.proposalNum.to_s == ""
                        #Delete quotation if quotation is not linked to any policy
                        user_deleted_entity.delete
                    end
                end
            end
        end
    end
end