# require 'rho/rhoevent.rb'

module MobiSys
  module Calendar
    
    def self.create(event)
      begin
        # event = Rho::RhoEvent.create!(event)
      rescue StandardError => error
        raise MobiSys::CalendarAccessError.new("Cannot Access Calendar")
      end
      return event
    end
    
    def self.update(id,event)
      unless id
        raise ArgumentError.new("id cannot be null in call to update")
      end
      event['id'] = id
      begin  
        # Rho::RhoEvent.update_attributes(event)
      rescue StandardError => error
        raise MobiSys::CalendarAccessError.new("Cannot Access Calendar")
      end
    end
    
    def self.find(*args)
      begin
        # results = Rho::RhoEvent.find(*args)
      rescue StandardError => error
        raise MobiSys::CalendarAccessError.new("Cannot Access Calendar")
      end
    end

    def self.delete(id)
      begin
        # Rho::RhoEvent.destroy(id)
      rescue StandardError => error
        raise MobiSys::CalendarAccessError.new("Cannot Access Calendar")
      end
    end
    
  end
  class CalendarAccessError < StandardError
  
  end
end