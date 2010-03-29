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
# CONTROLLER component of WIDGET
#
# Implements response to user actions
# Logic (MODEL) lays in chargify.rb
# Templates (VIEWS) lays in app/views/widget_templates directory
#
# Enabled WIDGET types are defined in config/widgets-on-rails.yml :
#    widget_types:
#       <widget_name>: <wizard_class_name>
#       <widget_name>: <wizard_class_name>
#

require 'chargify'
require 'utils'

module WidgetSteps

  class ProductSubscribeWizard < WidgetWizard
    # wizard implementation of "product-subscribe" WIDGET
  
    class << self
  
      def steps   # made vitrual to allow override
        # all wizard steps - matches class methods
        return [:subscription_list, :subscription_complete]
      end
  
      def subscription_list(sess, widget, data)
        # wizard step - show all available subscriptions / subscribe to selected subscription
        products = ChargifyProxy.get_products(sess)
  
        # no data was submitted
        if data.empty?
          products_json = products.collect do |p|
            {   :name => p.name,
                :handle => p.handle,
                :id => p.id,
                :description => p.description,
                :price_in_cents => p.price_in_cents,
                :interval => p.interval,
                :interval_unit => p.interval_unit
            }
          end
          return {:data => {:products => products_json}, :template => 'product-subscribe-list'}
        end
  
        # submitted invalid data
        if !data[:product]
          return {:errors => {
                    :product => ['Please choose a product first'],
                    :HEADER => 'Unable to subscribe:'
                 }}
        end
  
        subscription = ChargifyProxy.subscribe_for_product(sess, data[:product])
  
        # submitted invalid data
        if !subscription or !subscription.respond_to?("product")
          return {:errors => {
                    :HEADER => 'Was unable to subscribe. Please, try again.'
                 }}
        end
  
        # submitted valid data
        return show_other_step(:subscription_complete, sess, widget, {:subscription => subscription})
      end
  
      def subscription_complete(sess, widget, data)
        # wizard step - show success subscription message
        if data[:subscription]
          p = data[:subscription].product
          product = {
            :name => p.name,
            :handle => p.handle,
            :id => p.id,
            :description => p.description,
            :price_in_cents => p.price_in_cents,
            :interval => p.interval,
            :interval_unit => p.interval_unit
          }
          return {:data => {:product => product}, :template => 'product-subscribe-success'}
        end
      
        return show_other_step(nil, sess, widget, {})
      end
  
    end
  end
  
  class ShowSubscriptionsWizard < WidgetWizard
    # wizard implementation of "show-subscriptions" WIDGET
  
    class << self
  
      def steps   # made vitrual to allow override
        # all wizard steps - matches class methods
        return [:subscriptions_list]
      end
  
      def subscriptions_list(sess, widget, data)
        # wizard step - show all user subscriptions
        subscriptions = ChargifyProxy.get_customer_subscriptions(sess)
  
        subscription_json = subscriptions.collect do |s|
          p = s.product
          product = {
            :name => p.name,
            :handle => p.handle,
            :id => p.id,
            :description => p.description,
            :price_in_cents => p.price_in_cents,
            :interval => p.interval,
            :interval_unit => p.interval_unit
          }
          { :product => product,
            :activated_at => s.activated_at
          }        
        end
        return {:data => {:subscriptions => subscription_json}, :template => 'subscriptions-list'}
      end
    end
  end
end
