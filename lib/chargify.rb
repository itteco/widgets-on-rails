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
# MODEL component of WIDGET
#
# Implements Chargify logic used in CONTROLLER (widget_steps.rb)
#

require 'chargify_api_ares'

module ChargifyProxy
  class << self
    
    def get_chargify_customer(domain, api_key, userid)
      Chargify.configure do |c|
        c.subdomain = domain
        c.api_key = api_key
      end
      begin
        return Chargify::Customer.find_by_reference(userid)
      rescue ActiveResource::ResourceNotFound => e
        return false
      end
    end

    def get_customer_subscriptions(sess)
      _set_chargify_credentials(sess)
      begin
        customer = Chargify::Customer.find_by_reference(sess[:userid])
      rescue ActiveResource::ResourceNotFound => e
        return []
      end

      Chargify::Subscription.find(:all, :params=>{:customer_id=>customer.id})
    end
    
    def get_products(sess)
      _set_chargify_credentials(sess)
      Chargify::Product.find(:all)
    end
    
    def subscribe_for_product(sess, prod_id)
      _set_chargify_credentials(sess)
    
      Chargify::Subscription.create(
      :customer_reference => sess[:userid],
      :product_handle => prod_id,
      :credit_card_attributes => {
        :first_name => "Some",
        :last_name => "Guy",
        :expiration_month => 1,
        :expiration_year => 2020,
        :full_number => "1"
      }
    )
    end
  
    private
    
    def _set_chargify_credentials(s)
      Chargify.configure do |c|
        c.subdomain = s[:clientid]
        c.api_key = s[:api_key]
      end
    end

  end
end
