require 'net/http'
require 'openssl'
require 'logger'
require 'json'

class WebtrekkConnector
    def initialize(conf)
        @endpoint = conf[:endpoint]
        @user = conf[:user]
        @pwd = conf[:pwd]
        @customerId = conf[:customerId]
        @logger = Logger.new(STDERR)
        @logger.info("Connector set up for #{@endpoint}.")
    end

    def make_https_request(uri, payload=nil)
        @logger.info("sending request (method #{payload[:method]}) ...")
        Net::HTTP.start(uri.host, uri.port,
            :use_ssl => uri.scheme == 'https', 
            :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|

            request = Net::HTTP::Post.new(uri.request_uri)
            request.body = payload.to_json

            response = http.request(request)

            if response.code.eql?("200")
                return response.body
            else
                raise Net::HTTPError.new(response.code, response.message)
            end
        end
    end

    def call_method(method, params={})
        @logger.info("call_method: #{method}")
        payload = {
            :params => params ,
            :version => "1.1" ,
            :method => method
        }
        response = make_https_request(URI(@endpoint), payload)
        data = JSON.parse(response)
        data['result']
    end

    def get_connection_test
        response = call_method('getConnectionTest')
    end

    def get_token
        unless @customerId
            @customerId = self.get_first_account['customerId']
        end
        params = {
            :login => @user,
            :pass => @pwd ,
            :customerId => @customerId ,
            :language => "en"
        }
        response = call_method('login', params)
    end


    def login
        @token = get_token
    end

    def get_account_list
        params = {
            :login => @user,
            :pass => @pwd ,
        }
        response = call_method('getAccountList', params)
    end

    def get_first_account
        account_list = get_account_list
        account_list.first
    end

    def request_analysis(analysis_config)
        params = {
            :token => @token ,
            :analysisConfig => analysis_config
        }
        response = call_method("getAnalysisData", params)
    end

end