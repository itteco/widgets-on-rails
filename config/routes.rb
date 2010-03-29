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
# Routes for CONTROLLER of PROVIDER server application
#

ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes"

  map.root :controller => 'main'

  map.connect 'session/token',          :controller => 'session', :action=>'token'
  map.connect 'session/create.:format', :controller => 'session', :action=>'create'
  map.connect 'session/check',          :controller => 'session', :action=>'check'
  map.connect 'session/end.',           :controller => 'session', :action=>'session_end' # "end" is reserved word

  map.connect 'process.:format', :controller => 'main', :action => 'do_process' # fix method name via route
  map.connect ':action.:format', :controller => 'main'

end
