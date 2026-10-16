require 'CommonClasses/BaseModel'

module MobiSys
	
	class PartyAddressModel < BaseModel

        def setModel(entity)
            party = self.parentBaseDO
            if entity != nil
                if MobiSys::PolicyBO.checkForEmptyFields(entity)
                    if entity.addressTypeCd.to_s != 'MAILING'
                        entity.removed = "YES"
                    end
                elsif party.roleCd == "PROPOSER" && party.partyTypeCd == "ORGANIZATION" && (entity.addressTypeCd == "RESIDENTIAL" || entity.addressTypeCd == "PERMANENT")
                    entity.removed = "YES"
                elsif (party.copyFromAddr2.to_s != "OTHERS" && party.copyFromAddr2.to_s != "" && entity.addressTypeCd.to_s == "PERMANENT") || (party.copyFromAddr3.to_s != "OTHERS" && party.copyFromAddr3.to_s != "" && entity.addressTypeCd.to_s == "OFFICE")
                    entity.removed = "YES"
                end
            end

            return entity
        end
    end
end
