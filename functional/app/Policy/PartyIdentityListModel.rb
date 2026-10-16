require 'CommonClasses/BaseModel'

module MobiSys
	
	class PartyIdentityListModel < BaseModel

        def initialize(io)
            #puts "~~~in PartyIdentityListModel initialize: #{io.inspect}"
            super(io)
            #puts "~~~baseIO:#{self.baseIO}"
        end

		def getModel
			#logInfo("~~~baseIO in PartyIdentityListModel:#{self.baseIO.inspect}")
            #logInfo("~~~in self.parentBaseDO : #{self.parentBaseDO.class.name}")
            partyIdentityList = []
            if self.parentBaseDO.PartyIdentityList.size == 0
                partyIdentity = PartyIdentity.new
                partyIdentityList.push(partyIdentity)
            else
                partyIdentityList = self.parentBaseDO.PartyIdentityList
            end
      
            return partyIdentityList
        end

        def setModel(entity)
            if entity != nil && entity.size > 0
                entity.each do |ent|
                    if ent != nil
                        ent.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(ent)

                        ent.expiryDt = getDBDate(ent.expiryDt) if ent.expiryDt.to_s != ""
                        ent.issueDt = getDBDate(ent.issueDt) if ent.issueDt.to_s != ""
                    end
                end
            end

            return entity
        end
    end
end

begin 
    require 'Policy/PartyIdentityListModel_company'
rescue LoadError => e
    puts 'PartyIdentityListModel_company not included'
end