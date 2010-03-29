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
# CONTROLLER of PROVIDER server application
#
# Implements SESSION creation and processing
#

require 'session_extended'  # load MODEL component
class SessionController < ApplicationController
  
  verify :method => :post,
         :only => [:token],
         :params => [:data, :key],
         :render => {:nothing => true, :status => 400}
         
  verify :method => :get,
         :only => [:create],
         :params => [:t],
         :render => {:nothing => true, :status => 400}
         
  before_filter :authenticate, :only => [:token]
  before_filter :check_session, :only => [:check, :session_end]

  def token
    # creates token during CONSUMER-server <-> PROVIDER-server comminucation
    return render_unauthorized 'Invalid passkey', request unless Utils.is_data_consistent(params[:data], @secret, params[:key])
    for i in 1..20 do # While True will hang up the server forever
      t = Utils.get_random_alphanum(24)
      break if Rails.cache.read(CACHE_PREFIX+t).nil?
    end

    raise "Unable to generate a valid token" if t.nil? #RuntimeError
    session_data = {:clientid=>@clientid, :token=>t}
    session_data[:secret] = Utils.get_random_alphanum(12)

    Utils.get_params_from_query_string(params[:data]).each do |param_pair|
      session_data[param_pair[0].to_sym] = param_pair[1]
    end
  
    Rails.cache.write(CACHE_PREFIX+t, session_data)
    Rails.cache.write(CACHE_PREFIX+t+'_expire', WOR_CONFIG['session_expiration'].to_i.minutes.from_now)

    render :text => t

    logger.info 'Given token [%s] for client ID [%s] to IP [%s]' % [t, @clientid, request.remote_ip]
  end

  def session_end
    # ends SESSION
    Rails.cache.delete(CACHE_PREFIX+@token)
    Rails.cache.delete(CACHE_PREFIX+@token+'_expire')
  end
  
  def check
    # validated SESSION
    render :text=>'"OK"', :content_type => 'application/json'
  end
  
#  VIRTUAL - to be implemented
#  def self.is_client_authenticated(id, password)
#    # this method checks client username (CLIENT_ID) and password provided for token generation
#    # *true* for valid and *false* for invalid
#    true
#  end

#  VIRTUAL - to be implemented
#  def self.get_secret_for_id(id)
#    # this method returns SECRET_KEY for provided CLIENT_ID
#    # (*false* or *nil* if secret is not found)
#    # to check integrity of provided data - use DB or something
#    # (for secutiry purposes SECRET_KEY is never transmitted to the server)
#    'samplesecretkey'
#  end

  private
  
  def authenticate
    # checks authentication of CUSTOMER during server<->server communication
    authenticate_or_request_with_http_basic do |userid, password|
      clientid = userid
      return false unless SessionController.is_client_authenticated(clientid, password)
      return false unless secret = SessionController.get_secret_for_id(clientid)
      @clientid = clientid
      @secret = secret
      true    # access is allowed
    end
  end

  def render_unauthorized(text=nil, request=nil)
    # shows error message
    if request
      request_data = ''
      request_data += 'for IP=%s' % request.remote_ip
      request.parameters.each_pair {|k,v| request_data += ', %s=>%s' % [k,v] }
    end
    
    logger.warn "'%s' auth error %s" % [text, (request_data or 'occured')]
    return render :nothing => true, :status => 401 unless text
    render :text => text, :status => 401
  end

end
