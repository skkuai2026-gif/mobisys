require 'CommonModules/commonutil'
require 'date'
require 'singleton'

module MobiSys
	class TrackLeadBO
		include Singleton
		include MobiSys::CommonUtil

		def self.updateTrackLead(doObject)
			doClass = doObject.class.name
			trackLead = nil
			case doClass
			when "Lead"
				trackLead = TrackLead.loadObject( :first, :conditions => { :leadId => doObject.leadId } )
				if trackLead
					trackLead.statusCd = doObject.statusCd
				else
					trackLead = TrackLead.new
					trackLead.leadId = doObject.leadId
					trackLead.leadEntryDt = doObject.systemCreatedDt
					trackLead.statusCd = doObject.statusCd if doObject.fnaId.to_s == "" && doObject.quotationRefNum.to_s == ""
				end

			when "FNARequest"
				trackLead = TrackLead.loadObject( :first, :conditions => { :fnaId => doObject.fnaNum } ) if doObject.fnaNum.to_s != ""
				if trackLead
					trackLead.fnaId = doObject.fnaNum
					trackLead.fnaEntryDt = doObject.systemCreatedDt
					trackLead.statusCd = doObject.statusCd if trackLead.quotationRefNum.to_s == ""
				elsif doObject.leadId.to_s != ""
					trackLeads = TrackLead.loadObject( :all, :conditions => { :leadId => doObject.leadId } )
					trackLeads.each do |tl|
						if tl.leadId.to_s == doObject.leadId.to_s && tl.fnaId.to_s == ""
							trackLead = tl
							break
						elsif tl.leadId.to_s == "" && tl.fnaId.to_s == ""
							trackLead = tl
							break
						end
					end
					if trackLead == nil
						trackLead = TrackLead.new
						lead = Lead.loadObject( :first, :conditions => { :leadId => doObject.leadId } )
						trackLead.leadId = lead.leadId
						trackLead.leadEntryDt = lead.systemCreatedDt
					end
					if trackLead.fnaId.to_s == ""
						trackLead.fnaId = doObject.fnaNum
						trackLead.fnaEntryDt = doObject.systemCreatedDt
						trackLead.statusCd = doObject.statusCd if trackLead.quotationRefNum.to_s == ""
					end
				end

			when "Quotation"
				quotation = Quotation.loadObject( :first, :conditions => { :object => doObject.object } )
				trackLead = TrackLead.loadObject( :first, :conditions => { :quotationRefNum => quotation.quotationRefNum } ) if quotation && quotation.quotationRefNum.to_s != ""
				if trackLead && trackLead.proposalNum.to_s == ""
					trackLead.statusCd = quotation.quoteStatusCd 
					trackLead.totAnnualPremium = quotation.totAnnualPremium 
					trackLead.productId = quotation.productId
				elsif quotation && quotation.leadId.to_s != ""
					trackLeads = TrackLead.loadObject( :all, :conditions => { :leadId => quotation.leadId } )
					trackLeads.each do |tl|
						if tl.fnaId.to_s == quotation.fnaId.to_s.split("|")[0] && tl.quotationRefNum.to_s == ""
							trackLead = tl
							break
						elsif tl.fnaId.to_s == "" && tl.quotationRefNum.to_s == ""
							trackLead = tl
							break
						end
					end
					if trackLead == nil
						trackLead = TrackLead.new
						lead = Lead.loadObject( :first, :conditions => { :leadId => quotation.leadId } )
						if lead
							trackLead.leadId = lead.leadId
							trackLead.leadEntryDt = lead.systemCreatedDt
						end
					end
					if trackLead.quotationRefNum.to_s == ""
						if trackLead.fnaId.to_s == ""
							fnaNum = quotation.fnaId.to_s.split("|")[0]
							trackLead.fnaId = fnaNum
							fnaRequest = FNARequest.loadObject( :first, :conditions => { :fnaNum => fnaNum } ) if fnaNum
							trackLead.fnaEntryDt = fnaRequest.systemCreatedDt if fnaRequest
						end
						trackLead.quotationRefNum = quotation.quotationRefNum
						trackLead.quotationEntryDt = quotation.systemCreatedDt
						trackLead.statusCd = quotation.quoteStatusCd
						trackLead.totAnnualPremium = quotation.totAnnualPremium 
						trackLead.productId = quotation.productId
					end
				end


			when "Policy"
				policy = Policy.loadObject( :first, :conditions => { :object => doObject.object } )
				trackLead = TrackLead.loadObject( :first, :conditions => { :proposalNum => policy.proposalNum } )
				trackLead = TrackLead.loadObject( :first, :conditions => { :quotationRefNum => policy.quotationRefNum } ) unless trackLead
				unless trackLead
					lead = Lead.loadObject( :first, :conditions => { :leadId => policy.leadId } )
					quotation = Quotation.loadObject( :first, :conditions => { :quotationRefNum => policy.quotationRefNum } )
					if lead && quotation
						trackLead = TrackLead.new
						trackLead.leadId = lead.leadId
						trackLead.leadEntryDt = lead.systemCreatedDt
						if policy.fnaId.to_s != ""							
							fnaRequest = FNARequest.loadObject( :first, :conditions => { :fnaNum => policy.fnaId } ) 
							if fnaRequest
								trackLead.fnaId = fnaRequest.fnaNum
								trackLead.fnaEntryDt = fnaRequest.systemCreatedDt 								
							end
						end
						trackLead.quotationRefNum = quotation.quotationRefNum
						trackLead.quotationEntryDt = quotation.systemCreatedDt
						trackLead.totAnnualPremium = quotation.totAnnualPremium 
						trackLead.productId = quotation.productId
					end
				end
				if trackLead
					trackLead.policyNum = policy.policyNum
					trackLead.proposalNum = policy.proposalNum
					trackLead.statusCd = policy.statusCd
					trackLead.proposalEntryDt = policy.proposalEntryDt
					trackLead.proposalSubmitDt = policy.proposalSignedDt
					trackLead.proposalClosingDt = policy.proposalSignedDt
				end
			end
			
			trackLead.persistAll if trackLead
		end
	end
end