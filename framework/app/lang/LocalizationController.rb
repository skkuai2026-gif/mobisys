require 'rho/rhocontroller'
require 'time'
require 'date'

class LocalizationController < Rho::RhoController
  include BrowserHelper

  #GET /Localization
  def index
     render :action => :index ,:back => '/app'
  end
  
  def th
    System::set_locale("th")
    puts 'set locale th'
    redirect :action => :index  
  end

  def en
     System::set_locale("en")
    puts 'set locale en'
    redirect :action => :index  
  end
  
end
