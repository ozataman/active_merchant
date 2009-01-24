module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class FbWebGateway < Gateway
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
    
      def parse(body)
        xml = REXML::Document.new(body)
        # res = REXML::XPath.first(xml, "//CC5Response/Response")
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
      
      def add_customer_data(xml, options)
      end

      def add_address(xml, creditcard, options)      
      end

      def add_invoice(xml, options)
      end
      
      def message_from(response)
      end
      
      def post_data(action, parameters = {})
      end
      
    end
  end
end

