# Copyright (c) 2010 Itteco Software, Corp.  Artem Scorecky, Anatoly Ivanov, Alexander Lebedev.
# 
# WIDGETS ON RAILS -- MVC framework
# ----------------------------------------------------------------------
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# ----------------------------------------------------------------------
#
# SHARED library for CONSUMER and PROVIDER server applications
#
# Implements:
#   * Methods for initalizing CONSUMER <-> PROVIDER session
#   * CONTROLLER class of WIDGET
#

require 'openssl'
require 'base64'
require 'net/http'
require 'uri'
require 'cgi'

class WidgetWizard
  # CONTROLLER class of WIDGET

  class << self

    def steps   # make vitrual to allow override
      return [:none]
    end

    def none(sess, widget, data)
      return {:data => {}, :template => :none}                # success
      return {:errors => {:HEADER => 'Some error occured'}}   # general error
      return {:errors => {:HEADER => 'Some errors occured:',  
                          :product => ['Too expensive',       # field errors
                                       'Cannot fit into your house'
                                      ]
              }}
    end

    def show_other_step(new_step, sess, widget, data)
      widget[:step] = new_step
      return show_step(sess, widget, data)
    end

    def show_step(sess, widget, data)
      if widget[:step].nil? # initial opening
        widget[:step] = steps[0]
        data = {}
      end
      # TODO: keep all data to allow back button with already pre-filled values
      return send(widget[:step], sess, widget, data)
    end

  end
end

module Utils
  # Methods for initalizing CONSUMER <-> PROVIDER session

  class << self

    def get_token_from_provider(webservice_root, client_id, client_password, secret, data)
      # get token from PROVIDER (that initializes session on PROVIDER)
  
      token_service_url = '%ssession/token' % webservice_root
      checksum = Utils.calculate_checksum(data, secret)
      token = Utils.fetch_value_from_url(token_service_url, {'data'=>data, 'key'=>checksum}, client_id, client_password)
      return unless token
      return CGI.escape(token)    # url-encode

    end


    def calculate_checksum(data, secret)
      # calculates checksum for provided text using secret
      signature = OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha1'), secret, data)
      Base64.encode64(signature).strip    
    end
  
    def is_data_consistent(data, secret, key)
      # checks if checksum matches actual checksum
      #puts '%s (real) vs. %s (provided)' % [self.calculate_checksum(data, secret), key]
      self.calculate_checksum(data, secret) == key
    end
  
    def get_random_alphanum(len)
      # generate random string
      rand(36**len).to_s(36)
    end
  
    def fetch_value_from_url(url, post=nil, user=nil, password=nil)
      # get content of URL with or without HTTP auth credentials
      url = URI.parse(url)
      if post.nil?
        req = Net::HTTP::Get.new(url.path)
      else
        req = Net::HTTP::Post.new(url.path)
        req.set_form_data(post, ';')
      end      
      req.basic_auth user, password if user
   
      res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
    
      if res.is_a? Net::HTTPSuccess
        res.body
      else
        nil
      end
    end
    
    def get_user_agent(request)
      # gets user agent from provided request
      request.user_agent or request.env['HTTP_USER_AGENT'] or 'Not set'  # That way session[:user_agent].nil? would be false if user-agent is not set
    end

    def get_params_from_query_string (data)
      # parses HTTP query into list of [key, value] pairs
      # ripped from ActionController::AbstractRequest.parse_query_parameters: since the method is private we can't reuse it directly.
      data.split('&').collect do |chunk|
        next if chunk.empty?
        key, value = chunk.split('=', 2)
        next if key.empty?
        value = value.nil? ? nil : CGI.unescape(value)
        [ CGI.unescape(key), value ]
      end.compact
    end

  end
end


