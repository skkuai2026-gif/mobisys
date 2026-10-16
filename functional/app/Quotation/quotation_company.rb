# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'
require 'Quotation/quotation_b_o'
require 'Product/product_b_o'
require 'CommonModules/mobisysbrowserhelper'
class Quotation
	include MobiSys::MobiSysEntitySchema

	set :schema_version, '1.0'

	# Uncomment the following line to enable sync with Label.
	# enable :sync

	property :proposalVersion, :string

	#add model specifc code here
	property :proposalVersion, :string

	#add model specifc code here
	attr_accessor :entityTypeCd
	attr_accessor :isEappLinkApplicable
	attr_accessor :entityTypeCd

	def getQuotationPartyByRole(roleCd)
		self.QuotationPartyList.each do |quotationParty|
			return quotationParty if quotationParty.roleCd == roleCd
		end
		return nil
	end
end
