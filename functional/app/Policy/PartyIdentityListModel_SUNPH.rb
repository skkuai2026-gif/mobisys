require 'CommonClasses/BaseModel'
require 'Policy/PartyIdentityListModel'

module MobiSys
	
	class PartyIdentityListModel_SUNPH < PartyIdentityListModel
        attr_accessor :defaultIdentityTypeList

        def initialize(io)
            # puts "~~~in PartyIdentityListModelSUNPH initialize: #{io.inspect}"
            super(io)
            self.defaultIdentityTypeList = []
            #puts "~~~baseIO:#{self.baseIO}"
        end

		def getModel
			#logInfo("~~~baseIO in PartyIdentityListModel:#{self.baseIO.inspect}")
            #logInfo("~~~in self.parentBaseDO : #{self.parentBaseDO.class.name}")
            partyIdentityList = []
            if self.parentBaseDO.PartyIdentityList.size == 0 || self.parentBaseDO.PartyIdentityList.size == 2
                partyIdentity = PartyIdentity.new
                partyIdentityList.push(partyIdentity)
            else
                partyIdentityList = self.parentBaseDO.PartyIdentityList
            end
      

            returnPartyIdentityList = []
            if partyIdentityList.size > 0
                setDefaultIdentityTypeList
                partyIdentityList.each do |partyId|
                    if (partyId.identityTypeCd == nil || (partyId.identityTypeCd != nil && !defaultIdentityTypeList.include?(partyId.identityTypeCd)))
                            returnPartyIdentityList << partyId
                    end
                end
            end
            return returnPartyIdentityList
        end

        def setModel(entity)
            if entity != nil && entity.size > 0
                entity.each do |ent|
                    if ent != nil
                        # ent.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(ent)

                        ent.expiryDt = getDBDate(ent.expiryDt) if ent.expiryDt.to_s != ""
                        ent.issueDt = getDBDate(ent.issueDt) if ent.issueDt.to_s != ""
                    end
                end
            end

            newPartyIdentityDOList = []
            newPartyIdentityDOList = newPartyIdentityDOList + entity
            setDefaultIdentityTypeList
            self.parentBaseDO.PartyIdentityList.each do |partyId|
                if defaultIdentityTypeList.include?(partyId.identityTypeCd.to_s)
                    newPartyIdentityDOList << partyId
                end
            end
            self.parentBaseDO.setPartyIdentityList(newPartyIdentityDOList)

            return newPartyIdentityDOList
        end

        def setDefaultIdentityTypeList
            if defaultIdentityTypeList.size == 0
                defaultIdentityLookup = Lookupvalue.loadObject(:all, :conditions=>{{:name=>'key'}=>'DEFAULTIDENTITYTYPE'})
                if defaultIdentityLookup.size > 0
                    defaultIdentityLookup.each do |defIdLkp|
                        defaultIdentityTypeList << defIdLkp.cd.to_s
                    end
                end
            end
        end
    end
end

begin 
    require 'Policy/PartyIdentityListModel_company'
rescue LoadError => e
    puts 'PartyIdentityListModel_company not included'
end