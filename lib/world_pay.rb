module WorldPay
  
  # post new payment to worldpay server from within controller
  
  def self.uri
    WorldPay::Post.uri
  end
  
  class Post
    # class to submit form from within controller using net/http?
    
    def initialize(installation_id, cart_id, amount, options = {})
      @params = {
        :instId => "#{installation_id}",
        :cartId => "#{cart_id}",
        :amount => "#{amount}",
        :currency => "GBP",
        :desc => "Purchase"
      }.merge(options)
      
      @params.merge!({ :testMode => 100 }) if WorldPay::Post.test?
    end
    
    def params
      @params
    end
    
    def headers
      {
        'Referer' => 'http://www.fittedbootstore.com/orders/review',
        'User-Agent' => 'Rails 2.2.2'
      }
    end
    
    def send
      url = URI.parse(WorldPay::Post.uri)
      request = Net::HTTP::Post.new(url.path, headers)
      request.set_form_data(params)
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      response = http.start { |http| http.request(request) }
      # ActiveRecord::Base.logger.debug "** RESPONSE: #{response['Set-Cookie']}"
    end
    
    # set the submission uri to sandbox for development and live for production
    def self.uri
      WorldPay::Post.in_production? ? "https://select.worldpay.com/wcc/purchase/" : "https://select-test.worldpay.com/wcc/purchase/"
    end

    def self.test?
      not WorldPay::Post.in_production?
    end
    
    def self.in_production?
      Rails.env == 'production'
    end
    
  end
  
  # process payment response notifications
  
  class Response
    
    def initialize(params, raw_post)
      @params = params.merge!(Hash[*raw_post.scan(/(\w+)\=(.+?)&/).flatten])
    end
    
    # checker methods
    
    def is_authorized_by_callback_password?(password = '')
      password == @params['callbackPW']
    end
    
    def success?
      transaction_result == 'Y'
    end
    
    def total_amounts_match?(order_total)
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
    def world_pay_form(installation_id, cart_id, amount, options = {})
      params = {
        :instId => "#{installation_id}",
        :cartId => "#{cart_id}",
        :amount => "#{amount}",
        :currency => "GBP",
        :desc => "Purchase"
      }.merge(options)
      
      params.merge!({ :testMode => 100 }) if WorldPay::Post.test?
      
      output = []
      
      output << form_tag(uri)
      params.each_pair do |name, value|
        output << hidden_field_tag(name, value)
      end
      output << submit_tag('Proceed to Payment Page', 'class' => 'large')
      output << '</form>'
      
      output.join("\n")
    end  
  end
  
end