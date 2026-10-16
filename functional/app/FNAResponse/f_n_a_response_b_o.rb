require 'CommonModules/commonutil'

module MobiSys
	class FNAResponseBO
		include MobiSys::CommonUtil                         

		def self.validate(errors, leadfna, errorQuestions)
			errorQuestions.each do |questionKey|
				MobiSys::CommonUtil.addErrors(errors, questionKey, "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel(questionKey)])
			end

			if leadfna.outputInsurancePlanSuited.to_s != "" || leadfna.outputRiders.to_s != "" || leadfna.outputInsuranceProtectionAmount.to_s != "" || leadfna.outputPaymentPeriod.to_s != ""
				if leadfna.agentSignatureCd.to_s == ""
					MobiSys::CommonUtil.addErrors(errors, "agentSignatureCd", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel("agentSignature")])
				end

				if leadfna.agentSignatureDt.to_s == ""
					MobiSys::CommonUtil.addErrors(errors, "agentSignatureDt", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel("agentSignature") << " " << MobiSys::BrowserHelper.getLabel("date")])
				else
					if Time.parse(leadfna.agentSignatureDt.to_s) > Time.now
						MobiSys::CommonUtil.addErrors(errors, "agentSignatureDt", "ERR_DATE", [MobiSys::BrowserHelper.getLabel("agentSignature") << " " << MobiSys::BrowserHelper.getLabel("date"), Time.now.strftime("%d-%m-%Y")])
					end
				end

				if leadfna.signatureCd.to_s == ""
					MobiSys::CommonUtil.addErrors(errors, "signatureCd", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel("applicantSignature")])
				end

				if leadfna.signatureDt.to_s == ""
					MobiSys::CommonUtil.addErrors(errors, "signatureDt", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel("applicantSignature") << " " << MobiSys::BrowserHelper.getLabel("date")])
				else
					if Time.parse(leadfna.signatureDt.to_s) > Time.now
						MobiSys::CommonUtil.addErrors(errors, "signatureDt", "ERR_DATE", [MobiSys::BrowserHelper.getLabel("applicantSignature") << " " << MobiSys::BrowserHelper.getLabel("date"), Time.now.strftime("%d-%m-%Y")])
					end
				end
			end
		end
	end
end