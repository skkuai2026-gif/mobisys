module MobiSys
	module SyncUtil

        def self.deleteUserData
            #User previous data to be deleted
            userdeletedate = AgentReg.forUserId($userId)
            if userdeletedate.userDataDeleteDays
                @userdatecondition = (Date.today - userdeletedate.userDataDeleteDays).to_time
                Policy.loadObject(:all).each do |policy|
                    if((policy.signatureStatus != "" && policy.proposalSignedDt.to_s != "" && policy.proposalSignedDt < @userdatecondition.to_s) || (policy.proposalReceivedDt.to_s != "" && policy.proposalReceivedDt < @userdatecondition.to_s))
                        policy.delete
                    end
                end
                
                Quotation.loadObject(:all, :conditions => {{:name => 'quotationDt', :op => '<'} =>@userdatecondition.to_s}).each do |user_deleted_entity|
                    #Check if quotation is linked to any policy
                    linkedPolicy = Policy.loadObject(:first,:conditions => {{:name => 'quotationRefGuid'} => user_deleted_entity.uniqueKey})
                    if linkedPolicy
                        if((linkedPolicy.signatureStatus != "" && linkedPolicy.proposalSignedDt.to_s != "" && linkedPolicy.proposalSignedDt < @userdatecondition.to_s) || (linkedPolicy.proposalReceivedDt.to_s != "" && linkedPolicy.proposalReceivedDt < @userdatecondition.to_s))
                            #1. If quotation is linked to policy and policy has been submitted with signed date older than userDataDeleteDays configured, delete policy and quotation
                            #2. For policy that's not submitted, delete policy if proposalReceivedDt is older than userDataDeleteDays configured
                            linkedPolicy.delete
                            user_deleted_entity.delete
                        end
                    else
                        #Delete quotation if quotation is not linked to any policy
                        user_deleted_entity.delete
                    end
                end

                FNARequest.find(
                    :all, 
                    :conditions => {
                        {
                            :name => 'statusCd'
                        } =>'FNAPENDING',
                        {
                            :name => 'consentFl',
                            :op => '<>'
                        } =>'on',
                        {
                            :name => 'consentExpiryDt',
                            :op => '<'
                        } => Date.parse(Time.now.to_s)
                    },
                    :op => 'AND'
                ).each do |user_deleted_entity| 
                    user_deleted_entity.delete
                end

                FNARequest.loadObject(:all, :conditions => {{:name => 'systemUpdatedDt', :op => '<'} =>@userdatecondition.to_s}).each do |user_deleted_entity|
                    user_deleted_entity.delete if user_deleted_entity.statusCd.to_s == 'FNAPENDING' || user_deleted_entity.statusCd.to_s == 'SYNCDONE'
                    if user_deleted_entity.statusCd.to_s == 'SYNCDONE'
                        fileName = "Fna_" + @user_deleted_entity.fnaNum + ".json"
                        filePath = Rho::RhoFile.join(Rho::Application.userFolder, "#{fileName}")
                        File::delete filePath if File::exist? filePath
                    end
                end
            end

            # deleteLeadsDataAfterDays = OfflineApplication.find(:first, :conditions =>{{:name =>'PROPERTY'} =>'DELETELEADSDATAAFTERDAYS'})
            if userdeletedate && userdeletedate.userLeadDataDeleteDays.to_s != ""
                leaddatecondition = (Date.today - userdeletedate.userLeadDataDeleteDays).to_time
                Lead.loadObject(:all, :conditions => {{:name => 'systemUpdatedDt', :op => '<'} =>leaddatecondition.to_s}).each do |user_deleted_entity|
                    user_deleted_entity.delete
                end
            end
        end
    end
end

begin 
    require 'CommonModules/syncutil_company'
rescue LoadError => e
    puts 'syncutil_company not included'
end