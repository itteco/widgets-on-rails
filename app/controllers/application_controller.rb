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
# Implements general filters
#

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
require 'cgi'
require 'utils'

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  #protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  
  before_filter :add_cors_headers
  before_filter :handle_options_request_method
  
  def add_cors_headers
    # enable page to be used by CORS
    response.headers['Access-Control-Allow-Origin'] = (request.headers['Origin'] or request.headers['ORIGIN'] or request.headers['origin'] or '*')
    response.headers['Access-Control-Allow-Methods'] = 'POST, GET, PUT, DELETE, HEAD, OPTIONS'
    response.headers['Access-Control-Allow-Credentials'] = 'true'
    response.headers['Access-Control-Max-Age'] = '86400' # 24 hours
    response.headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-HTTP-Method-Override, Content-Type, Accept, Cookie'
  end

  def handle_options_request_method
    # used for CORS content negotiation
    render :nothing => true, :status => 204 if request.method == :options
  end

  def check_session
    
    @token = params[:token]
    session_invalid = @token.nil?
    
    session_invalid = true unless !session_invalid and session_data = Rails.cache.read(CACHE_PREFIX+@token)
    session_invalid = true unless !session_invalid and expires = Rails.cache.read(CACHE_PREFIX+@token+'_expire') and (expires - 0.seconds.from_now) > 0
    session_invalid = true if session_invalid or session_data[:clientid].nil? or session_data[:secret].nil?
    
    if session_invalid
      logger.error "Bad session: %s" % session_data.inspect
      render :text=>'"FAIL"', :content_type => 'text/plain'
    else
      Rails.cache.write(CACHE_PREFIX+@token+'_expire', WOR_CONFIG['session_expiration'].to_i.minutes.from_now)
    end 
  end
  
  def check_control_sum
    postdata = request.POST
    postdata.delete('checksum')
    postdata = postdata.sort() #basically this converts a HashWithIndifferentAccess into Hash, so postdata.sort! is not applicable
    postdata = (postdata.collect {|e| '%s=%s' % [ e[0],CGI.escape(e[1]) ] }).join('&')
    session_data = Rails.cache.read(CACHE_PREFIX+@token)
    unless Utils.is_data_consistent(postdata, session_data[:secret], params[:checksum])
      render :nothing => true, :status => 400 
      logger.warn 'Bad checksum for AJAX request for session [%s]' % session[:session_id]
    end
  end

end
