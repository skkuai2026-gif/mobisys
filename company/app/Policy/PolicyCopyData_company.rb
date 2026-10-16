module MobiSys
	class PolicyCopyData
		attr_accessor :copyFromPolicyDO, :copyToPolicyDO

		def initialize
			@copyProposalOptionsLkp = Lookupvalue.createLookupCache(["COPYPROPOSALOPTIONS"])
			@fieldsToExcludeArr = ["guid","id", "versionID"]
		end

		def execute(copyFromPolicyDO, copyToPolicyDO, proposalDataToBeCopiedList)
			startTime = Time.now
			self.copyFromPolicyDO = copyFromPolicyDO
			self.copyToPolicyDO = copyToPolicyDO 
			if copyFromPolicyDO && copyToPolicyDO && !proposalDataToBeCopiedList.empty?
				proposalDataToBeCopiedList.each do |proposalDataToBeCopiedObj|
					proposalDataToBeCopiedHM = proposalDataToBeCopiedObj
					partyGuid = proposalDataToBeCopiedHM["partyGuid"]
					fromPartyDO = copyFromPolicyDO.getPartyDOByGuid(partyGuid)
					return if fromPartyDO.to_s == ""
					toPartyDO = copyToPolicyDO.getPartyByRole(fromPartyDO.roleCd)
					# if isSelected true means entire party record copy into current policy
					if fromPartyDO.to_s != ""
						# isSelected true means copy all child data of current party
						if proposalDataToBeCopiedHM["isSelected"].to_s == "true"
							# childDataList is not null means copy that child records
							if proposalDataToBeCopiedHM["childDataList"].to_s != "" && !proposalDataToBeCopiedHM["childDataList"].empty?
								copyParty(fromPartyDO, toPartyDO, proposalDataToBeCopiedHM)
							else

								# childDataList is null means create new and copy from that party record
								copyCompleteParty(fromPartyDO, proposalDataToBeCopiedHM)
							end
						elsif proposalDataToBeCopiedHM["isSelected"].to_s == "indeterminate"
							# indeterminate true means copy specific child data of current party
							copyParty(fromPartyDO, toPartyDO, proposalDataToBeCopiedHM);
						end
					end
				end
				RhoLog.error("PolicyCopyData", "Total time for copy policy data : #{Time.now - startTime}s")
			end
		end

		def copyParty(fromPartyDO, toPartyDO, proposalDataToBeCopiedHM)
			partyGuid = toPartyDO.guid
			quotePartyGuid = toPartyDO.quotationPartyGuid
			return if fromPartyDO.to_s == "" && toPartyDO.to_s == ""
			childDataList = proposalDataToBeCopiedHM["childDataList"]
			if childDataList.to_s != ""
				childDataList.each do |childDataObj|
					next if childDataObj.to_s == ""
					childDataHM = childDataObj
					if childDataHM["isSelected"].to_s == "true" && childDataHM["typeCdOfData"].to_s != ""
						typeCdOfData = childDataHM["typeCdOfData"].to_s
						begin
							
							self.send(typeCdOfData, fromPartyDO, toPartyDO)
			                toPartyDO.guid = partyGuid
			                toPartyDO.quotationPartyGuid = quotePartyGuid
			                toPartyDO.partyId = nil
			                toPartyDO.versionID = nil
			                toPartyDO.id = nil

						rescue StandardError => e
							RhoLog.error("PolicyCopyData", "Error invoking copy for #{typeCdOfData} and role #{proposalDataToBeCopiedHM["roleCd"]} : #{e}")
						end
					end
				end
			end
		end

		def copyCompleteParty(fromPartyDO, proposalDataToBeCopiedHM)
			# here handle supplementary ,nominee new party as well as same as case also
			toPartyDO = self.copyToPolicyDO.getPartyByRole(fromPartyDO.roleCd)
			return if proposalDataToBeCopiedHM["roleCd"].to_s == ""
			roleCd = proposalDataToBeCopiedHM["roleCd"].to_s
			copyFromPolicyPartyRoleDO = self.copyFromPolicyDO.getPolicyPartyRoleByPartyGuid(fromPartyDO.guid, roleCd)
			sameAsPartyFromDO = nil
			sameAsPartyFromDO = self.copyFromPolicyDO.getPartyByRole(copyFromPolicyPartyRoleDO.partySameAsCd) if copyFromPolicyPartyRoleDO.partySameAsCd.to_s != ""
			# if nominee same as OTHER or supplementary then create new party and party
			# role record
			if sameAsPartyFromDO == nil
				newPartyDO = Party.new
			    MobiSys::CommonUtil.copyFields(fromPartyDO, newPartyDO, @fieldsToExcludeArr)
			    newPartyDO.partyId = nil

			    newPolicyPartyRoleDO = PolicyPartyRole.new
			    MobiSys::CommonUtil.copyFields(copyFromPolicyPartyRoleDO, newPolicyPartyRoleDO, @fieldsToExcludeArr)
			    newPartyDO.guid = newPartyDO.object.gsub(".","_")
                newPartyDO.systemCreatedDt = Time.now
                newPartyDO.id = nil
                newPartyDO.versionID = nil
			    self.copyToPolicyDO.addParty(newPartyDO)
			    newPolicyPartyRoleDO.refGuid = newPartyDO.guid
			    newPolicyPartyRoleDO.partyId = nil
			    newPolicyPartyRoleDO.guid = newPolicyPartyRoleDO.object.gsub(".","_")
                newPolicyPartyRoleDO.systemCreatedDt = Time.now
                newPolicyPartyRoleDO.id = nil
                newPolicyPartyRoleDO.versionID = nil
			    self.copyToPolicyDO.addPolicyPartyRole(newPolicyPartyRoleDO)
				fromPartyDO.PartyAdditionalFieldsList.each do |copyFromPartyAdditionalsDO|
					isPartyAdditionalFieldsListRecordFound = false
					newPartyDO.PartyAdditionalFieldsList.each do |copyToPartyAdditionalsDO|
						if copyFromPartyAdditionalsDO.to_s != "" && copyToPartyAdditionalsDO.to_s != "" #
			    			copyToPartyAdditionalsDO.field4 = copyFromPartyAdditionalsDO.field4 if copyFromPartyAdditionalsDO.field4.to_s != ""
			    			copyToPartyAdditionalsDO.field5 = copyFromPartyAdditionalsDO.field5 if copyFromPartyAdditionalsDO.field5.to_s != ""
			    			copyToPartyAdditionalsDO.field6 = copyFromPartyAdditionalsDO.field6 if copyFromPartyAdditionalsDO.field6.to_s != ""
			    			copyToPartyAdditionalsDO.field7 = copyFromPartyAdditionalsDO.field7 if copyFromPartyAdditionalsDO.field7.to_s != ""
			    			copyToPartyAdditionalsDO.field8 = copyFromPartyAdditionalsDO.field8 if copyFromPartyAdditionalsDO.field8.to_s != ""
			    			copyToPartyAdditionalsDO.field9 = copyFromPartyAdditionalsDO.field9 if copyFromPartyAdditionalsDO.field9.to_s != ""
			    			copyToPartyAdditionalsDO.field15 = copyFromPartyAdditionalsDO.field15 if copyFromPartyAdditionalsDO.field15.to_s != ""
			    			copyToPartyAdditionalsDO.field26 = copyFromPartyAdditionalsDO.field26 if copyFromPartyAdditionalsDO.field26.to_s != ""
			    			copyToPartyAdditionalsDO.field27 = copyFromPartyAdditionalsDO.field27 if copyFromPartyAdditionalsDO.field27.to_s != ""
			    			copyToPartyAdditionalsDO.field28 = copyFromPartyAdditionalsDO.field28 if copyFromPartyAdditionalsDO.field28.to_s != ""
			    			copyToPartyAdditionalsDO.field29 = copyFromPartyAdditionalsDO.field29 if copyFromPartyAdditionalsDO.field29.to_s != ""
			    			copyToPartyAdditionalsDO.field18 = copyFromPartyAdditionalsDO.field18 if copyFromPartyAdditionalsDO.field18.to_s != ""
			    			copyToPartyAdditionalsDO.field21 = copyFromPartyAdditionalsDO.field21 if copyFromPartyAdditionalsDO.field21.to_s != ""
			    			copyToPartyAdditionalsDO.field40 = copyFromPartyAdditionalsDO.field40 if copyFromPartyAdditionalsDO.field40.to_s != ""
			    			copyToPartyAdditionalsDO.field19 = copyFromPartyAdditionalsDO.field19 if copyFromPartyAdditionalsDO.field19.to_s != ""
			    			copyToPartyAdditionalsDO.field41 = copyFromPartyAdditionalsDO.field41 if copyFromPartyAdditionalsDO.field41.to_s != ""
			    			copyToPartyAdditionalsDO.field42 = copyFromPartyAdditionalsDO.field42 if copyFromPartyAdditionalsDO.field42.to_s != ""
							isPartyAdditionalFieldsListRecordFound = true
							break
						end
					end
					if !isPartyAdditionalFieldsListRecordFound
						newPartyAdditionalFieldsDO = PartyAdditionalFields.new
						newPartyAdditionalFieldsDO.field4 = copyFromPartyAdditionalsDO.field4 if copyFromPartyAdditionalsDO.field4.to_s != ""
			    			newPartyAdditionalFieldsDO.field5 = copyFromPartyAdditionalsDO.field5 if copyFromPartyAdditionalsDO.field5.to_s != ""
			    			newPartyAdditionalFieldsDO.field6 = copyFromPartyAdditionalsDO.field6 if copyFromPartyAdditionalsDO.field6.to_s != ""
			    			newPartyAdditionalFieldsDO.field7 = copyFromPartyAdditionalsDO.field7 if copyFromPartyAdditionalsDO.field7.to_s != ""
			    			newPartyAdditionalFieldsDO.field8 = copyFromPartyAdditionalsDO.field8 if copyFromPartyAdditionalsDO.field8.to_s != ""
			    			newPartyAdditionalFieldsDO.field9 = copyFromPartyAdditionalsDO.field9 if copyFromPartyAdditionalsDO.field9.to_s != ""
			    			newPartyAdditionalFieldsDO.field15 = copyFromPartyAdditionalsDO.field15 if copyFromPartyAdditionalsDO.field15.to_s != ""
			    			newPartyAdditionalFieldsDO.field26 = copyFromPartyAdditionalsDO.field26 if copyFromPartyAdditionalsDO.field26.to_s != ""
			    			newPartyAdditionalFieldsDO.field27 = copyFromPartyAdditionalsDO.field27 if copyFromPartyAdditionalsDO.field27.to_s != ""
			    			newPartyAdditionalFieldsDO.field28 = copyFromPartyAdditionalsDO.field28 if copyFromPartyAdditionalsDO.field28.to_s != ""
			    			newPartyAdditionalFieldsDO.field29 = copyFromPartyAdditionalsDO.field29 if copyFromPartyAdditionalsDO.field29.to_s != ""
			    			newPartyAdditionalFieldsDO.field18 = copyFromPartyAdditionalsDO.field18 if copyFromPartyAdditionalsDO.field18.to_s != ""
			    			newPartyAdditionalFieldsDO.field21 = copyFromPartyAdditionalsDO.field21 if copyFromPartyAdditionalsDO.field21.to_s != ""
			    			newPartyAdditionalFieldsDO.field40 = copyFromPartyAdditionalsDO.field40 if copyFromPartyAdditionalsDO.field40.to_s != ""
			    			newPartyAdditionalFieldsDO.field19 = copyFromPartyAdditionalsDO.field19 if copyFromPartyAdditionalsDO.field19.to_s != ""
			    			newPartyAdditionalFieldsDO.field41 = copyFromPartyAdditionalsDO.field41 if copyFromPartyAdditionalsDO.field41.to_s != ""
			    			newPartyAdditionalFieldsDO.field42 = copyFromPartyAdditionalsDO.field42 if copyFromPartyAdditionalsDO.field42.to_s != ""
			    			newPartyAdditionalFieldsDO.id = nil
					        newPartyAdditionalFieldsDO.versionID = nil
						newPartyDO.addPartyAdditionalFields(newPartyAdditionalFieldsDO)
					end
				end
			else
				# if nominee same as primary and proposer then just need to update policy party
				# role record.
				newPolicyPartyRoleDO = PolicyPartyRole.new
				MobiSys::CommonUtil.copyFields(copyFromPolicyPartyRoleDO, newPolicyPartyRoleDO, @fieldsToExcludeArr)

				sameAsPartysTODO = self.copyToPolicyDO.getPartyByRole(newPolicyPartyRoleDO.partySameAsCd)
				if sameAsPartyTODO.to_s != ""
					newPolicyPartyRoleDO.refGuid = newPartyDO.guid
		    	newPolicyPartyRoleDO.partyId = nil
				end
				newPolicyPartyRoleDO.id = nil
				newPolicyPartyRoleDO.versionID = nil
				self.copyToPolicyDO.addPolicyPartyRole(newPolicyPartyRoleDO)
			end
		end

		def getExcludedAttributeList(lookupDataCd = "")
			key = "COPYPROPOSALOPTIONS#{lookupDataCd}".to_sym
			excludeAttributesList = @copyProposalOptionsLkp[key]&.additionalField1.to_s.split(",")
			@fieldsToExcludeArr + excludeAttributesList
		end

		def copyPersonalData(fromPartyDO, toPartyDO)
			# since party id override from from party,so retain that party id
			orgToPartyId = toPartyDO.partyId if toPartyDO.partyId #most probably not needed in offline, still considerring it for submitted cases where partyId might be returned from online
			quotPartyAddtnField4val = toPartyDO.quotPartyAddtnField4 if toPartyDO.quotPartyAddtnField4.to_s != ""
			MobiSys::CommonUtil.copyFields(fromPartyDO, toPartyDO, getExcludedAttributeList("copyPersonalData"))
            toPartyDO.quotPartyAddtnField4 = quotPartyAddtnField4val if quotPartyAddtnField4val
			toPartyDO.partyId = nil
		end

		def copyAddressData(fromPartyDO, toPartyDO)
			fromPartyDO.PartyAddressList.each do |copyFromPartyAddressDO|
				isPartyAddressRecordFound = false
				toPartyDO.PartyAddressList.each do |copyToPartyAddressDO|
					if copyFromPartyAddressDO.to_s != "" && copyToPartyAddressDO.to_s != "" && copyFromPartyAddressDO.addressTypeCd.to_s == copyToPartyAddressDO.addressTypeCd.to_s
		    			MobiSys::CommonUtil.copyFields(copyFromPartyAddressDO, copyToPartyAddressDO, getExcludedAttributeList("copyAddressData"))
						isPartyAddressRecordFound = true
						break
					end
				end
				if !isPartyAddressRecordFound
					newPartyAddressDO = PartyAddress.new
					MobiSys::CommonUtil.copyFields(copyFromPartyAddressDO, newPartyAddressDO, @fieldsToExcludeArr)
					toPartyDO.addPartyAddress(newPartyAddressDO)
				end
			end

			
		end

		def copyContactData(fromPartyDO, toPartyDO)
			fromPartyDO.PartyContactList.each do |copyFromPartyContactDO|
				isPartyContactRecordFound = false
				toPartyDO.PartyContactList.each do |copyToPartyContactDO|
					if copyFromPartyContactDO.to_s != "" && copyToPartyContactDO.to_s != "" && copyFromPartyContactDO.contactTypeCd.to_s == copyToPartyContactDO.contactTypeCd.to_s
		    			MobiSys::CommonUtil.copyFields(copyFromPartyContactDO, copyToPartyContactDO, getExcludedAttributeList("copyContactData"))
						copyToPartyContactDO.versionID = nil
						copyToPartyContactDO.id = nil
						isPartyContactRecordFound = true
						break
					end
				end
				if !isPartyContactRecordFound
					newPartyContactDO = PartyContact.new
					MobiSys::CommonUtil.copyFields(copyFromPartyContactDO, newPartyContactDO, @fieldsToExcludeArr)
					newPartyContactDO.id = nil
					newPartyContactDO.versionID = nil
					toPartyDO.addPartyContact(newPartyContactDO)
				end
			end
			fromPartyDO.PartyEmailList.each do |copyFromPartyEmailDO|
				isPartyEmailRecordFound = false
				toPartyDO.PartyEmailList.each do |copyToPartyEmailDO|
					if copyFromPartyEmailDO.emailTypeCd.to_s == copyToPartyEmailDO.emailTypeCd.to_s
						MobiSys::CommonUtil.copyFields(copyFromPartyEmailDO, copyToPartyEmailDO, getExcludedAttributeList("copyContactData"))
						copyToPartyEmailDO.versionID = nil
						copyToPartyEmailDO.id = nil
						isPartyEmailRecordFound = true
						break
					end
				end
				if !isPartyEmailRecordFound
						newPartyEmailDO = PartyEmail.new
					    MobiSys::CommonUtil.copyFields(copyFromPartyEmailDO, newPartyEmailDO, @fieldsToExcludeArr)
					    newPartyEmailDO.id = nil
					    newPartyEmailDO.versionID = nil
					toPartyDO.addPartyEmail(newPartyEmailDO)
				end	
			end
			fromPartyDO.PartyAdditionalFieldsList.each do |copyFromPartyAdditionalsDO|
				isPartyAdditionalFieldsListRecordFound = false
				toPartyDO.PartyAdditionalFieldsList.each do |copyToPartyAdditionalsDO|
					if copyFromPartyAdditionalsDO.to_s != "" && copyToPartyAdditionalsDO.to_s != "" #&& 
		    			# MobiSys::CommonUtil.copyFields(copyFromPartyAdditionalsDO, copyToPartyAdditionalsDO, getExcludedAttributeList("copyAddressData"))
		    			copyToPartyAdditionalsDO.field4 = copyFromPartyAdditionalsDO.field4 if copyFromPartyAdditionalsDO.field4.to_s != ""
		    			copyToPartyAdditionalsDO.field5 = copyFromPartyAdditionalsDO.field5 if copyFromPartyAdditionalsDO.field5.to_s != ""
		    			copyToPartyAdditionalsDO.field6 = copyFromPartyAdditionalsDO.field6 if copyFromPartyAdditionalsDO.field6.to_s != ""
		    			copyToPartyAdditionalsDO.field7 = copyFromPartyAdditionalsDO.field7 if copyFromPartyAdditionalsDO.field7.to_s != ""
		    			copyToPartyAdditionalsDO.field8 = copyFromPartyAdditionalsDO.field8 if copyFromPartyAdditionalsDO.field8.to_s != ""
		    			copyToPartyAdditionalsDO.field9 = copyFromPartyAdditionalsDO.field9 if copyFromPartyAdditionalsDO.field9.to_s != ""
		    			copyToPartyAdditionalsDO.field15 = copyFromPartyAdditionalsDO.field15 if copyFromPartyAdditionalsDO.field15.to_s != ""
		    			copyToPartyAdditionalsDO.field26 = copyFromPartyAdditionalsDO.field26 if copyFromPartyAdditionalsDO.field26.to_s != ""
		    			copyToPartyAdditionalsDO.field27 = copyFromPartyAdditionalsDO.field27 if copyFromPartyAdditionalsDO.field27.to_s != ""
		    			copyToPartyAdditionalsDO.field28 = copyFromPartyAdditionalsDO.field28 if copyFromPartyAdditionalsDO.field28.to_s != ""
		    			copyToPartyAdditionalsDO.field29 = copyFromPartyAdditionalsDO.field29 if copyFromPartyAdditionalsDO.field29.to_s != ""
		    			copyToPartyAdditionalsDO.field18 = copyFromPartyAdditionalsDO.field18 if copyFromPartyAdditionalsDO.field18.to_s != ""
		    			copyToPartyAdditionalsDO.field21 = copyFromPartyAdditionalsDO.field21 if copyFromPartyAdditionalsDO.field21.to_s != ""
		    			copyToPartyAdditionalsDO.field40 = copyFromPartyAdditionalsDO.field40 if copyFromPartyAdditionalsDO.field40.to_s != ""
		    			copyToPartyAdditionalsDO.field19 = copyFromPartyAdditionalsDO.field19 if copyFromPartyAdditionalsDO.field19.to_s != ""
		    			copyToPartyAdditionalsDO.field41 = copyFromPartyAdditionalsDO.field41 if copyFromPartyAdditionalsDO.field41.to_s != ""
		    			copyToPartyAdditionalsDO.field42 = copyFromPartyAdditionalsDO.field42 if copyFromPartyAdditionalsDO.field42.to_s != ""
						isPartyAdditionalFieldsListRecordFound = true
						break
					end
				end
				if !isPartyAdditionalFieldsListRecordFound
					newPartyAdditionalFieldsDO = PartyAdditionalFields.new
					# MobiSys::CommonUtil.copyFields(copyFromPartyAdditionalsDO, newPartyAdditionalFieldsDO, @fieldsToExcludeArr)
					newPartyAdditionalFieldsDO.field4 = copyFromPartyAdditionalsDO.field4 if copyFromPartyAdditionalsDO.field4.to_s != ""
	    			newPartyAdditionalFieldsDO.field5 = copyFromPartyAdditionalsDO.field5 if copyFromPartyAdditionalsDO.field5.to_s != ""
	    			newPartyAdditionalFieldsDO.field6 = copyFromPartyAdditionalsDO.field6 if copyFromPartyAdditionalsDO.field6.to_s != ""
	    			newPartyAdditionalFieldsDO.field7 = copyFromPartyAdditionalsDO.field7 if copyFromPartyAdditionalsDO.field7.to_s != ""
	    			newPartyAdditionalFieldsDO.field8 = copyFromPartyAdditionalsDO.field8 if copyFromPartyAdditionalsDO.field8.to_s != ""
	    			newPartyAdditionalFieldsDO.field9 = copyFromPartyAdditionalsDO.field9 if copyFromPartyAdditionalsDO.field9.to_s != ""
	    			newPartyAdditionalFieldsDO.field15 = copyFromPartyAdditionalsDO.field15 if copyFromPartyAdditionalsDO.field15.to_s != ""
	    			newPartyAdditionalFieldsDO.field26 = copyFromPartyAdditionalsDO.field26 if copyFromPartyAdditionalsDO.field26.to_s != ""
	    			newPartyAdditionalFieldsDO.field27 = copyFromPartyAdditionalsDO.field27 if copyFromPartyAdditionalsDO.field27.to_s != ""
	    			newPartyAdditionalFieldsDO.field28 = copyFromPartyAdditionalsDO.field28 if copyFromPartyAdditionalsDO.field28.to_s != ""
	    			newPartyAdditionalFieldsDO.field29 = copyFromPartyAdditionalsDO.field29 if copyFromPartyAdditionalsDO.field29.to_s != ""
	    			newPartyAdditionalFieldsDO.field18 = copyFromPartyAdditionalsDO.field18 if copyFromPartyAdditionalsDO.field18.to_s != ""
	    			newPartyAdditionalFieldsDO.field21 = copyFromPartyAdditionalsDO.field21 if copyFromPartyAdditionalsDO.field21.to_s != ""
	    			newPartyAdditionalFieldsDO.field40 = copyFromPartyAdditionalsDO.field40 if copyFromPartyAdditionalsDO.field40.to_s != ""
	    			newPartyAdditionalFieldsDO.field19 = copyFromPartyAdditionalsDO.field19 if copyFromPartyAdditionalsDO.field19.to_s != ""
	    			newPartyAdditionalFieldsDO.field41 = copyFromPartyAdditionalsDO.field41 if copyFromPartyAdditionalsDO.field41.to_s != ""
	    			newPartyAdditionalFieldsDO.field42 = copyFromPartyAdditionalsDO.field42 if copyFromPartyAdditionalsDO.field42.to_s != ""
	    			newPartyAdditionalFieldsDO.id = nil
					newPartyAdditionalFieldsDO.versionID = nil
					toPartyDO.addPartyAdditionalFields(newPartyAdditionalFieldsDO)
				end
			end
		end

		def copyEmploymentData(fromPartyDO, toPartyDO)
			copyFromPartyEmploymentDO = fromPartyDO.getPartyEmployment
			copyToPartyEmploymentDO = toPartyDO.getPartyEmployment
			if copyFromPartyEmploymentDO.to_s != "" && copyToPartyEmploymentDO.to_s != ""
				MobiSys::CommonUtil.copyFields(copyFromPartyEmploymentDO, copyToPartyEmploymentDO, getExcludedAttributeList("copyEmploymentData"))
			end
		end

		def copyIdentityData(fromPartyDO, toPartyDO)
			fromPartyDO.PartyIdentityList.each do |copyFromPartyIdentityDO|
				isPartyIdentityRecordFound = false
				isPartyIdentityRecordBlankObject = false

				toPartyDO.PartyIdentityList.each do |copyToPartyIdentityDO|
					isPartyIdentityRecordBlankObject = true if copyToPartyIdentityDO.identityTypeCd.to_s == ""
					if copyFromPartyIdentityDO.to_s != "" && copyToPartyIdentityDO.to_s != "" && copyFromPartyIdentityDO.identityTypeCd.to_s == copyToPartyIdentityDO.identityTypeCd.to_s
		    			MobiSys::CommonUtil.copyFields(copyFromPartyIdentityDO, copyToPartyIdentityDO, getExcludedAttributeList("copyIdentityData"))
						isPartyIdentityRecordFound = true
						break
					end
				end

				if isPartyIdentityRecordBlankObject
					toPartyDO.PartyIdentityList.each do |copyToPartyIdentityDO|
						if copyToPartyIdentityDO.to_s != "" && copyToPartyIdentityDO.identityTypeCd.to_s == ""
							MobiSys::CommonUtil.copyFields(copyFromPartyIdentityDO, copyToPartyIdentityDO, @fieldsToExcludeArr)
							break
						end
					end
				elsif !isPartyIdentityRecordFound
					newPartyIdentityDO = PartyIdentity.new
					MobiSys::CommonUtil.copyFields(copyFromPartyIdentityDO, newPartyIdentityDO, @fieldsToExcludeArr)
				    newPartyIdentityDO.id = nil
				    newPartyIdentityDO.versionID = nil
					toPartyDO.addPartyIdentity(newPartyIdentityDO)
				end
			end
		end

		def copyIncomeData(fromPartyDO, toPartyDO)
			# it means copy all party other income record into current policy
			fromPartyDO.PartyOtherIncomeList.each do |copyFromPartyOtherIncomeDO|
				newPartyOtherIncomeDO = PartyOtherIncome.new
		   		MobiSys::CommonUtil.copyFields(copyFromPartyOtherIncomeDO, newPartyOtherIncomeDO, getExcludedAttributeList("copyIncomeData"))
				toPartyDO.addPartyOtherIncome(newPartyOtherIncomeDO)
			end
		end

		def copyQuestionnaireData(fromPartyDO, toPartyDO)
			# remove current party question response list from current policy do and copy
			# same party question list from copied policy
			questionContainerFrom = QuestionContainer.loadObject(
		                        :first,
		                        :conditions=>{
		                            {:name=>'entityGuid'} => fromPartyDO.guid,
		                            {:name=>'policyGuid'} => self.copyFromPolicyDO.uniqueKey
		                        }
		                        )


			questionContainerTo = QuestionContainer.loadObject(
		                        :first,
		                        :conditions=>{
		                            {:name=>'entityGuid'} => toPartyDO.guid,
		                            {:name=>'policyGuid'} => self.copyToPolicyDO.uniqueKey
		                        }
		                        )

			if questionContainerFrom
			  	if questionContainerTo
				  	questionContainerTo.ServiceQuestionResponseList.each do |copyToPartyWiseServiceQuestionResponse|
				  		copyToPartyWiseServiceQuestionResponse.removed = "YES"
				  	end
                
				  	questionContainerTo.delete
				end

			  	questionContainerTo = QuestionContainer.new
			  	MobiSys::CommonUtil.copyFields(questionContainerFrom, questionContainerTo, @fieldsToExcludeArr)
			    questionContainerTo.entityGuid = toPartyDO.guid
			    questionContainerTo.policyGuid = self.copyToPolicyDO.uniqueKey
			    questionContainerTo.id = nil
			    questionContainerTo.versionID = nil

			    questionContainerFrom.ServiceQuestionResponseList.each do |copyFromPartyWiseServiceQuestionResponse|
			    	newServiceQuestionResponseDO = ServiceQuestionResponse.new
			  		MobiSys::CommonUtil.copyFields(copyFromPartyWiseServiceQuestionResponse, newServiceQuestionResponseDO, @fieldsToExcludeArr)
			    	newServiceQuestionResponseDO.partyGuid = toPartyDO.guid
			    	newServiceQuestionResponseDO.id = nil
			    	newServiceQuestionResponseDO.versionID = nil
			    	questionContainerTo.addServiceQuestionResponse(newServiceQuestionResponseDO)
			    end
			    questionContainerTo.persistAll
			end
		end

		def copyDocumentData(fromPartyDO, toPartyDO)
			# remove current party document list from current policy do and copy same party
			# document list from copied policy
			documentContainersFrom = DocumentContainer.loadObject(
		            :first,
		            :conditions=>{
		            {:name=>'entityGuid'}=> fromPartyDO.guid,
		            {:name=>'policyGuid'}=> self.copyFromPolicyDO.uniqueKey
		        }
		        )


			documentContainersTo = DocumentContainer.loadObject(
		            :first,
		            :conditions=>{
		            {:name=>'entityGuid'}=> toPartyDO.guid,
		            {:name=>'policyGuid'}=> self.copyToPolicyDO.uniqueKey
		        }
		        )

			if documentContainersFrom
				# mark deleted as true in existing document and image attached to that party
			  	if documentContainersTo
				  	documentContainersTo.ServiceDocumentList.each do |copyToServiceDocumentDO|
				  		copyToServiceDocumentDO.removed = "YES"
				  		Image.delete_all(:conditions => {{:name=>'parentRefGuid'} => copyToServiceDocumentDO.guid}, :op => 'AND')
				  		DocumentImage.delete_all(:conditions => {{:name=>'parentRefGuid'} => copyToServiceDocumentDO.guid}, :op => 'AND')
				  	end

				  	documentContainersTo.delete
				end

			  	documentContainersTo = DocumentContainer.new
			  	MobiSys::CommonUtil.copyFields(documentContainersFrom, documentContainersTo, @fieldsToExcludeArr)
			    documentContainersTo.entityGuid = toPartyDO.guid
			    documentContainersTo.policyGuid = self.copyToPolicyDO.uniqueKey
			    documentContainersTo.id = nil
			    documentContainersTo.versionID = nil

			    documentContainersFrom.ServiceDocumentList.each do |copyFromServiceDocumentDO|
			    	newServiceDocumentDO = ServiceDocument.new
			  		MobiSys::CommonUtil.copyFields(copyFromServiceDocumentDO, newServiceDocumentDO, @fieldsToExcludeArr)
			  		newServiceDocumentDO.partyGuid = toPartyDO.guid
			  		newServiceDocumentDO.id = nil
			        newServiceDocumentDO.versionID = nil
			    	documentContainersTo.addServiceDocument(newServiceDocumentDO)
			    	# add image and it's child offline file do record
			    	images = Image.loadObject(:all, :conditions => { :parentRefGuid => copyFromServiceDocumentDO.guid})	        	
			    	images.each do |img|
			    		newImageDO = Image.new
			    		MobiSys::CommonUtil.copyFields(img, newImageDO, @fieldsToExcludeArr)
			    		newImageDO.parentRefGuid = newServiceDocumentDO.uniqueKey
			    		newImageDO.id = nil
			            newImageDO.versionID = nil
						offlineFile = img.OfflineFileList[0]
						newOfflineFileDO = OfflineFile.new
						MobiSys::CommonUtil.copyFields(offlineFile, newOfflineFileDO, @fieldsToExcludeArr)
						newOfflineFileDO.id = nil
			            newOfflineFileDO.versionID = nil
						newImageDO.addOfflineFile(newOfflineFileDO)
						newImageDO.persistAll
			    	end

			    	documentImages = DocumentImage.loadObject(:all, :conditions => { :parentRefGuid => copyFromServiceDocumentDO.guid})
			    	documentImages.each do |docImg|
			    		newDocImageDO = DocumentImage.new
			    		MobiSys::CommonUtil.copyFields(docImg, newDocImageDO, @fieldsToExcludeArr)
			    		newDocImageDO.parentRefGuid = newServiceDocumentDO.uniqueKey
						newDocImageDO.persistAll
			    	end
			    end
			    documentContainersTo.persistAll
			end
		end

	end
end

begin
    require 'Policy/PolicyCopyData_company'
rescue LoadError => e
    puts 'PolicyCopyData_company not included'
end