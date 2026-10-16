require 'CommonModules/commonutil'

module MobiSys
  class InwardBO
    include MobiSys::CommonUtil
    
    PENDING = "PENDING"
    READYFORSYNC = "READYFORSYNC"
    SYNCDONE = "SYNCDONE"
    
    ###################################################################################################
    
    def self.getDashboard()      
      inwards = Inward.loadObject(  :all, 
                                :conditions => {
                                    { 
                                      :name => 'inwardStatusCd',
                                      :op => 'LIKE'
                                    } => READYFORSYNC
                                }                                    
                              )
      inwardsDashboard = Array.new
      inwards.each do |inward|
        inwardsHM = Hash.new
        inwardsHM['RECEIPTREFNUM'] = inward.receiptRefNum
        inwardsDashboard.push(inwardsHM)            
      end
      
      return inwardsDashboard
    end # self.getDashboard
  
    ###################################################################################################
    
    def self.validate(inward, msg, errors)
      
      isValid = true

      #################################
      # inward mandatory validations
      #################################

      # inward validations
      if inward.receiptRefNum == nil || inward.receiptRefNum == ""
        MobiSys::CommonUtil.addErrors(errors, "receiptRefNum", "ERR_MANDATORY", ["RECEIPTREFNUM"])
        isValid = false    
      elsif inward.receiptRefNum.size > 10
        MobiSys::CommonUtil.addErrors(errors, "receiptRefNum", "ERR_MAXLEN", ["RECEIPTREFNUM", "10"])
        isValid = false
      end
      
      
      # check if all errors have been retained or removed
      puts "+++" << errors.to_s

      isValid = true
      errors.each do |key, value|
        
        if value != nil
          value.each do |errorlist|
            
            if errorlist != nil
              isValid = false
              break
            end
            
          end
        end
        
      end

            
      return isValid #&& isProductValid
    end # validate
    
    ###################################################################################################
    
  end
end