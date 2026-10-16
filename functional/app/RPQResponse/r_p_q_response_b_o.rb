require 'CommonModules/commonutil'

module MobiSys  
	class RPQResponseBO
		include MobiSys::CommonUtil

		QUESTION_SEQUENCE = ['RPQ_EDU_STAGE','RPQ_INVESTMENT_DURATION','RPQ_INVESTMENT_OBJECTIVE','RPQ_EXPENSES_CAN_COVERED','RPQ_RETIRE_PLAN', 'RPQ_PERCENT_TO_LINKED_PROD','RPQ_RISK_DESCRIPTION','RPQ_CURRENT_INVESTMENT_HOLD','RPQ_INV_LOSS_RESPONSE','RPQ_EXPECTED_RETURN']  

		def self.validate(errors, leadRPQ, errorQuestions)
			$currentTabId = nil
            $taskExceptionHash = []

			if errorQuestions && !errorQuestions.empty?
				errorQuestions.each do |questionKey|
					unless $rhoconfig[:TABFEATUREREQD]
						MobiSys::CommonUtil.addErrors(errors, questionKey, "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel(questionKey)])
					else
						MobiSys::CommonUtil.registerException(leadRPQ.guid, "#{leadRPQ.guid}-#{questionKey}", "ERR_MANDATORY", "ERR_MANDATORY", "tab_questionnaire",  [MobiSys::BrowserHelper.getLabel(questionKey)])
					end
				end
			end

			if leadRPQ.rpqScore.to_i > 0 && leadRPQ.visitedTabs.to_s.include?("tab_signature")
				if leadRPQ.agentSignatureCd.to_s == ""
					unless $rhoconfig[:TABFEATUREREQD]
						MobiSys::CommonUtil.addErrors(errors, "agentSignatureCd", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel("agentSignature")])
					else
						MobiSys::CommonUtil.registerException(leadRPQ.guid, "#{leadRPQ.guid}-agentSignatureCd", "ERR_MANDATORY", "ERR_MANDATORY", "tab_signature",  [MobiSys::BrowserHelper.getLabel('agentSignature')])
					end
				end

				if leadRPQ.agentSignatureDt.to_s == ""
					unless $rhoconfig[:TABFEATUREREQD]
						MobiSys::CommonUtil.addErrors(errors, "agentSignatureDt", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel("agentSignature") << " " << MobiSys::BrowserHelper.getLabel("date")])
					else
						MobiSys::CommonUtil.registerException(leadRPQ.guid, "#{leadRPQ.guid}-agentSignatureDt", "ERR_MANDATORY", "ERR_MANDATORY", "tab_signature",  [MobiSys::BrowserHelper.getLabel("agentSignature") << " " << MobiSys::BrowserHelper.getLabel("date")])
					end
				else
					if Time.parse(leadRPQ.agentSignatureDt.to_s) > Time.now
						unless $rhoconfig[:TABFEATUREREQD]
							MobiSys::CommonUtil.addErrors(errors, "agentSignatureDt", "ERR_DATE", [MobiSys::BrowserHelper.getLabel("agentSignature") << " " << MobiSys::BrowserHelper.getLabel("date"), Time.now.strftime("%d-%m-%Y")])
						else
							MobiSys::CommonUtil.registerException(leadRPQ.guid, "#{leadRPQ.guid}-agentSignatureDt", "ERR_DATE", "ERR_DATE", "tab_signature",  [MobiSys::BrowserHelper.getLabel("agentSignature") << " " << MobiSys::BrowserHelper.getLabel("date"), Time.now.strftime("%d-%m-%Y")])
						end
					end
				end

				if leadRPQ.signatureCd.to_s == ""
					unless $rhoconfig[:TABFEATUREREQD]
						MobiSys::CommonUtil.addErrors(errors, "signatureCd", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel("applicantSignature")])
					else
						MobiSys::CommonUtil.registerException(leadRPQ.guid, "#{leadRPQ.guid}-signatureCd", "ERR_MANDATORY", "ERR_MANDATORY", "tab_signature",  [MobiSys::BrowserHelper.getLabel('applicantSignature')])
					end
				end

				if leadRPQ.signatureDt.to_s == ""
					unless $rhoconfig[:TABFEATUREREQD]
						MobiSys::CommonUtil.addErrors(errors, "signatureDt", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel("applicantSignature") << " " << MobiSys::BrowserHelper.getLabel("date")])
					else
						MobiSys::CommonUtil.registerException(leadRPQ.guid, "#{leadRPQ.guid}-signatureDt", "ERR_MANDATORY", "ERR_MANDATORY", "tab_signature",  [MobiSys::BrowserHelper.getLabel("applicantSignature") << " " << MobiSys::BrowserHelper.getLabel("date")])
					end
				else
					if Time.parse(leadRPQ.signatureDt.to_s) > Time.now
						unless $rhoconfig[:TABFEATUREREQD]
							MobiSys::CommonUtil.addErrors(errors, "signatureDt", "ERR_DATE", [MobiSys::BrowserHelper.getLabel("applicantSignature") << " " << MobiSys::BrowserHelper.getLabel("date"), Time.now.strftime("%d-%m-%Y")])
						else
							MobiSys::CommonUtil.registerException(leadRPQ.guid, "#{leadRPQ.guid}-signatureDt", "ERR_DATE", "ERR_DATE", "tab_signature",  [MobiSys::BrowserHelper.getLabel("applicantSignature") << " " << MobiSys::BrowserHelper.getLabel("date"), Time.now.strftime("%d-%m-%Y")])
						end
					end
				end
			end
			if !$taskExceptionHash.empty?
				db = Rho::Database.new(Rho::Application.databaseFilePath('local'),'local')
	            db.start_transaction
	            $taskExceptionHash.each do |taskException|
	                taskException.persistAll
	            end
	            db.commit
	            $taskExceptionHash = nil
			end
		end
	end
end