# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'

class PolicyProductAdditional
    include MobiSys::MobiSysEntitySchema

    set :schema_version, '1.0'
    # Uncomment the following line to enable sync with PolicyProductAdditional.
    # enable :sync
  
    #add model specific code here
    property :removed, :string   

end

begin 
    require 'PolicyProductAdditional/policy_product_additional_company'
rescue LoadError => e
    puts 'policy_product_additional_company not included'
end 
