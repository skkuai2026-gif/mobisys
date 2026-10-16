require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper_company'
require 'date'
require 'json'
require 'CommonModules/mobisyssignature'

class FNADisplayController < Rho::RhoController
  include BrowserHelper
  include MobiSys::BrowserHelper
  
  def index

  end

  def index_new
    GC.enable
    render :action =>:index_new, :layout => "none"
  end

  def calculators
    WebView.navigate("/app/Fna/cal_new")
  end

end