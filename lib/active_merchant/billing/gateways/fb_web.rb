module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class FbWebGateway < Gateway
      require 'hpricot'
      
      TEST_URL = 'https://finanstest.fbwebpos.com/servlet/cc5ApiServer'
      LIVE_URL = 'https://www.fbwebpos.com/servlet/cc5ApiServer'
      
      # The countries the gateway supports merchants from as 2 digit ISO country codes
      self.supported_countries = ['TR']
      
      # The card types supported by the payment gateway
      self.supported_cardtypes = [:visa, :master, :american_express, :discover]
      
      # The homepage URL of the gateway
      self.homepage_url = 'http://www.fbwebpos.com/'
      
      # The name of the gateway
      self.display_name = 'FinansBank Web Pos'
      
      self.default_currency = "USD"
      
      CURRENCY_CODES = { 
        "TL"=> '949',
        "USD"=> '840',
        "EUR"=> '978'
      }
      
      TRANSACTION_TYPES = {
        "authonly" => 'PreAuth',
        "sale" => "Auth",
        "capture" => "PostAuth",
        "credit" => "Credit"
      }
      
      RESPONSE_CODES = {
        "Approved" => :success,
        "Declined" => :declined,
        "Error" => :error
      }
      
      def initialize(options = {})
        #requires!(options, :login, :password)
        @options = options
        super
      end  
      
      def authorize(money, creditcard, options = {})
        post = initialize_xml do |xml|
          add_creditcard(xml, creditcard)
          xml.tag! :Total, amount(money)
          xml.tag! :Currency, CURRENCY_CODES[(options[:currency] || self.default_currency)]
          add_transaction_type(xml, 'authonly')
        end
        commit(post)
      end
      
      def purchase(money, creditcard, options = {})
        post = initialize_xml do |xml|
          add_creditcard(xml, creditcard)
          xml.tag! :Total, amount(money)
          xml.tag! :Currency, CURRENCY_CODES[(options[:currency] || self.default_currency)]
          add_transaction_type(xml, 'sale')
        end
        commit(post)
      end                       
    
      def capture(money, authorization, options = {})

      end
    
      private     
      
      def commit(post)
        post = "DATA=" + post
        puts "Posting request...\n"
        puts post
        response = parse(ssl_post(test? ? TEST_URL : LIVE_URL, post))
      end
    
      # Initializes the xml request and passes it onto the caller
      # The entire request needs to be wrapped in a master tag
      # This method takes care of that
      # Returns a fully completed XML as a String object
      def initialize_xml
        post = ""
        xml = Builder::XmlMarkup.new :indent => 2, :target => post
        xml.instruct!(:xml, :version => "1.0", :encoding => "ISO-8859-9")
        xml.tag! :CC5Request do
          add_authentication(xml)
          add_unique_id(xml)
          yield(xml)
        end
        xml.target!
      end
      
      def add_creditcard(xml, creditcard)
        xml.tag! :Number, creditcard.number
        xml.tag! :Expires, creditcard.expiry_date.expiration.strftime("%m/%y")
        xml.tag! :Cvv2Val, creditcard.verification_value if creditcard.verification_value
      end
  
      def add_transaction_type(xml, action)
        xml.tag! :Type, TRANSACTION_TYPES[action]
      end
      
      def add_unique_id(xml)
        xml.tag! :OrderId, ActiveMerchant::Utils.generate_unique_id
      end
      
      # Adds the authentication element to the passed builder xml doc
      def add_authentication(xml)
        xml.tag! :Name, @options[:login]
        xml.tag! :Password, @options[:password]
        xml.tag! :ClientId, @options[:merchant_id]
        xml.tag! :Mode, "P"
      end
      
      def parse(body)
        xml = Hpricot::XML(body)
        body = xml.at("CC5Response")
        
        success = RESPONSE_CODES[body.at("Response").inner_html] == :success
        options = build_response_options(body)
        params = build_response_params(body)
        
        reponse = Response.new(success, body.at("ErrMsg").inner_html, params, options)
      end
      
      def build_response_options(body)
        options = {}
        options[:authorization] = body.at("AuthCode").inner_html unless body.at("AuthCode").blank?
        options[:test] = ActiveMerchant::Billing::Base.mode == :test
        options
      end
      
      def build_response_params(body)
        params = {}
        params[:original_response] = body.to_html
        params[:transaction_id] = body.at("TransId").inner_html unless body.at("TransId").blank?
        params
      end
      
    end
  end
end

