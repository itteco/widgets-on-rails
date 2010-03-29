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
# Implements WIDGET creation and processing
#

require 'widget_steps'
class MainController < ApplicationController

  verify :method => :post,
         :only => [ :do_process ],
         :params => [:template, :widget_id],
         :render => {:nothing => true, :status => 400}

  before_filter :check_session, :except => [:index, :templates]
  before_filter :check_control_sum, :only => [ :do_process ]

  def index
    # just mockup
    render :text => 'Index', :content_type => 'text/plain'
  end
  
  def widget
    # get generate WIDGET with initial state
    #TODO: session secret must be less obvious - instead of putting its raw value to widget.js, encrypt it.
    return render :nothing => true, :status=>400 unless WOR_CONFIG['widget_types'].has_key? params[:v]

    @css = params[:css]
    @i = params['i']
    @v = params['v']
    @widget = widget_create(params[:v])
    @action = get_data(@widget, {})
    @var_name = "wor_%s" % @i
    @origin = params[:origin]
    
    session_data = get_session()
    @s = session_data[:secret]
    @t = session_data[:token]

    logger.debug  'widget: %s' % @widget.inspect
  end
  
  def do_process
    # handle data received from WIDGET
    # cannot use "process" name because it is deep-inside controller method

    unless widget = get_widget_from_cache(params[:widget_id])
      logger.error 'Failed to get widget [%s] from cache' % [params[:widget_id]]
      return render :nothing => true, :status=>400
    end 
    
    unless widget[:token] == @token
      logger.error 'Token mismatch for widget [%s]: cached="%s", passed="%s"' % [widget[:id], widget[:token], @token]
      return render :nothing => true, :status=>400
    end 
    
    data = params.reject {|k,v| [:token, :template, :widget_id, :validator, :checksum].include? k }
    
    if widget[:validator] != params[:validator] # verify step succession integrity
      logger.debug "Validation failed %s != %s; Start from beginning" % [widget[:validator], params[:validator]]
      widget = get_widget_from_cache(widget[:id])
      widget[:step] = nil
      write_widget_to_cache(widget[:id],widget)
    end
    
    action = get_data(widget, data)

    render :text=> action.to_json, :content_type => 'application/json'
  end

  def templates
    # compiles all templates (VIEWS) into single JSON file
    data = {}
    for file in Dir.entries(WIDGET_TEMPLATES_DIRECTORY) do
      if file =~ /^(.*)\.ejs$/
        data[$1.downcase] = File::read("#{WIDGET_TEMPLATES_DIRECTORY}/#{file}")
      end
    end
    return render :json => "var WOR_TEMPLATES = #{data.to_json}"
  end

  private
  
  def widget_create(w_type)
    # create unique WIDGET ID
    while true do
      widget_id = Utils.get_random_alphanum(16)
      break if get_widget_from_cache(widget_id).nil?
    end

    write_widget_to_cache(widget_id, {:type=>w_type, :step=>nil, :id=>widget_id, :token=>@token})
  end
  
  def get_data(widget, data)
    # sends data to WIDGET CONTROLLER and return its response

    wizard = WidgetSteps.const_get(WOR_CONFIG['widget_types'][widget[:type]])

    logger.debug wizard.inspect
    logger.debug widget.inspect
    
    step_data = wizard.show_step(get_session(), widget, data)
    unless step_data.include? :errors
      # add validator value if it is not errors response
      v = Utils.get_random_alphanum(10)
      logger.debug widget[:id]
      widget[:validator] = v
      step_data.update(:validator=>v)
    end
    write_widget_to_cache(widget[:id],widget)
    return step_data
  end
  
  
  def get_session
    session_data = Rails.cache.read(CACHE_PREFIX+@token)
    #Normally session_check filters invalid session, so if it isn't there then something's wrong
    raise 'Invalid session requested after session check passed' if session_data.nil? 
    session_data
  end
  
  def get_widget_from_cache(widget_id)
    Rails.cache.read(WIDGET_PREFIX+widget_id)
  end
  
  def write_widget_to_cache(widget_id, value)
    Rails.cache.write(WIDGET_PREFIX+widget_id, value)
  end

end
