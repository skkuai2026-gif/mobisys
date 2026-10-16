require 'rho/rhocontroller'
require 'helpers/browser_helper'

class QuotationProductController < Rho::RhoController
  include BrowserHelper
  include MobiSys::BrowserHelper
  $choosed = {}
  $saved = nil
  $saved_value = nil
  # GET /QuotationProduct
  def index
    @quotationproducts = QuotationProduct.find(:all)
    render :back => '/app'
  end

  # GET /QuotationProduct/{1}
  def show
    @quotationproduct = QuotationProduct.find(@params['id'])
    if @quotationproduct
      render :action => :show, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # GET /QuotationProduct/new
  def new
    @quotationproduct = QuotationProduct.new
    render :action => :new, :back => url_for(:action => :index)
  end

  # GET /QuotationProduct/{1}/edit
  def edit
    @quotationproduct = QuotationProduct.find(@params['id'])
    if @quotationproduct
      render :action => :edit, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # POST /QuotationProduct/create
  def create
    @quotationproduct = QuotationProduct.create(@params['quotationproduct'])
    redirect :action => :index
  end

  # POST /QuotationProduct/{1}/update
  def update
    @quotationproduct = QuotationProduct.find(@params['id'])
    @quotationproduct.update_attributes(@params['quotationproduct']) if @quotationproduct
    redirect :action => :index
  end

  # POST /QuotationProduct/{1}/delete
  def delete
    @quotationproduct = QuotationProduct.find(@params['id'])
    @quotationproduct.destroy if @quotationproduct
    redirect :action => :index  
  end
  def popup
    flag = @params['flag']
    if ['0', '1', '2'].include?(flag)
      ttt = $choosed[flag]
     
        preset_time = Time.new

      if flag == '1'
          DateTimePicker.set_change_value_callback url_for(:action => :callback)
          current_value = Time.at(preset_time).strftime('%F')
          WebView.execute_js('setFieldValue("date1","'+current_value+'");')
          $saved_value = $choosed[flag]
          if $saved_value.nil?
              $saved_value = ''
          end
      end 
      DateTimePicker.choose url_for(:action => :callback), @params['title'], preset_time, flag.to_i, Marshal.dump({:flag => flag, :field_key => @params['field_key']})
    end
    
    render :string => '', :back => 'callback:' + url_for(:action => :callback_alert)
   
  end
def callback_alert
   Alert.show_popup( :message => "Back to home.\n\n Data will be discarded.", :icon => :alert,
     :buttons => ["Ok", "Cancel"], :callback => url_for(:action => :popup_callback) )
 end

 def popup_callback
   id = @params['button_id']
   title = @params['button_title']
   puts "popup_callback: id: '#{id}', title: '#{title}'"
   WebView.navigate '/app' if title.downcase() == 'ok'
 end
  def callback
    if @params['status'] == 'ok'
        $saved = nil
        datetime_vars = Marshal.load(@params['opaque'])
        format = case datetime_vars[:flag]
            when "0" then '%F %T'
            when "1" then '%F'
            when "2" then '%T'
            else '%F %T'
        end
        formatted_result = Time.at(@params['result'].to_i).strftime(format)
        $choosed[datetime_vars[:flag]] = formatted_result
        WebView.execute_js('setFieldValue("'+datetime_vars[:field_key]+'","'+formatted_result+'");')
    end
    if @params['status'] == 'cancel'
        datetime_vars = Marshal.load(@params['opaque'])
        if datetime_vars[:flag] == '1'
            WebView.execute_js('setFieldValue("'+datetime_vars[:field_key]+'","'+$saved_value+'");')
        end
    end
    if @params['status'] == 'change'
       datetime_vars = Marshal.load(@params['opaque'])
        if datetime_vars[:flag] == '1'
           formatted_result = Time.at(@params['result'].to_i).strftime('%F')
           WebView.execute_js('setFieldValue("date1","'+formatted_result+'");')
       end
   end
 
 end
end
