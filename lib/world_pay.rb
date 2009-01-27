module WorldPay
  
  # set the submission uri to sandbox for development and live for production
  def self.uri
    WorldPay.in_production? ? "https://select.worldpay.com/wcc/purchase/" : "https://select-test.worldpay.com/wcc/purchase/"
  end

  def self.test?
    not WorldPay.in_production?
  end
  
  def self.in_production?
    Rails.env == 'production'
  end
 
  # process payment response notifications
  
  class Response
    
    def initialize(params, raw_post)
      # Thanks to Peter Cooper http://www.petercooper.co.uk/
      # http://snippets.dzone.com/posts/show/2191
      # for this line to merge the parameters from WorldPay
      # IS THERE A PRETTIER WAY OF DOING THIS?
      @params = params.merge!(Hash[*raw_post.scan(/(\w+)\=(.+?)&/).flatten])
    end
    
    # checker methods
    
    def is_authorized_by_callback_password?(password = '')
      password == @params['callbackPW']
    end
    
    def success?
      transaction_result == 'Y'
    end
    
    def amounts_match?(order_total)
      order_total == total
    end
    
    def currencies_match?(order_currency = 'GBP')
      order_currency == currency
    end
    
    # get details of order
    
    def order_ref
      @params['cartId'].to_i
    end
    
    def total
      @params['authAmount'].to_f
    end
    
    def transaction_ref
      @params['transId']
    end
    
    def transaction_result
      @params['transStatus']
    end
    
    def transaction_at
      Time.parse(@params['transTime'].to_i / 1000)
    end
    
    def currency
      @params['authCurrency']
    end
    
  end
  
  # html helpers for creating the forms tags / attributes
  
  module Helpers
    
    def uri
      WorldPay.uri
    end
    
    #generate html output for 
    def world_pay_form_tag(installation_id, cart_id, amount, options = {}, &block)
      
      params = {
        :instId => "#{installation_id}",
        :cartId => "#{cart_id}",
        :amount => "#{amount}",
        :currency => "GBP",
        :desc => "Purchase"
      }.merge(options)
      
      params.merge!({ :testMode => 100 }) if WorldPay.test?
      
      output = form_tag(uri) do
        params.each_pair do |name, value|
          hidden_field_tag(name, value)
        end
        capture(&block)
      end
      
      logger.debug "** #{output}"
      
      concat output, block.binding
      
    end  
  end
  
end