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
# SAMPLE IMPLEMENTATION
#
# Simple controller that uses Widgets on Rails
#

class UserController < ApplicationController

verify :only => [:show],
       :params => [:id],
       :render => {:nothing => true, :status => 400}

def index
  @users = ['someuser', 'johndoe']
end

def show
  # sample page using Widgets on Rails
  @id = params[:id]
  data = { :userid => @id, :api_key => APP_CONFIG['shop_api_key'] }.to_query

  # request token via secure SERVER <-> SERVER connection
  @t = Utils.get_token_from_provider(APP_CONFIG['webservice_root'], APP_CONFIG['shop_id'], 'samplepassword', APP_CONFIG['shop_secret'], data)
end

end
