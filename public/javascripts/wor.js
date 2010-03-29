/*
* Copyright (c) 2010 Itteco Software, Corp.  Artem Scorecky, Anatoly Ivanov, Alexander Lebedev.
* 
* WIDGETS ON RAILS -- MVC framework
* ----------------------------------------------------------------------
* Permission is hereby granted, free of charge, to any person obtaining
* a copy of this software and associated documentation files (the
* "Software"), to deal in the Software without restriction, including
* without limitation the rights to use, copy, modify, merge, publish,
* distribute, sublicense, and/or sell copies of the Software, and to
* permit persons to whom the Software is furnished to do so, subject to
* the following conditions:
* 
* The above copyright notice and this permission notice shall be
* included in all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
* NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
* LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
* OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
* WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
* ----------------------------------------------------------------------
* 
* Client part of VIEW component of WIDGET. Has no logic except view.
* 
* Implements:
*   Rendering TEMPLATE with provided data
*   Showing rendered TEMPLATE as UI to end user
*   Communicate with PROVIDER
* 
*/

function WORWidget(instance_name, domain, secret, widgetName, widgetId, widgetNum, origin, token, action) {
    // initializes WIDGET instance
    this.INSTANCE_NAME = instance_name;
    this.CONTAINER_ID = '#'+instance_name;
    this.DOMAIN = domain;
    this.NUM = widgetNum;
    this.AUTH_TOKEN = token;
    this.AUTH_SECRET = secret;
    this.NAME = widgetName;
    this.ID = widgetId;
    this.ORIGIN = origin;
    this.TEMPLATES = {};
    this.submit_running = false;

    this.CONTAINER = $(this.CONTAINER_ID);        // jQuery ID: tagname, #tag-id, .tag-class
    this.ERROR_CONTAINER_ID = 'div#wor-errors'; // jQuery ID: tagname, #tag-id, .tag-class

    this.loadTemplates();
    this.configureContainer();
    this.drawAction(action);
}

WORWidget.prototype.configureContainer = function() {
    // configures WIDGET container
    if(this.get_disposition() == 'iframe') {
        $('body').addClass('wor_iframe');
    }
}

WORWidget.prototype.loadTemplates = function() {
    // copy TEMPLATES into instance
    this.TEMPLATES = WOR_TEMPLATES; // use separate variable to avoid load problems issue
}

WORWidget.prototype.get_instance = function() {
    // get object instance - for hard cases when "this" is overriden by function, e.g. in callbacks
    return eval(this.INSTANCE_NAME);
}

WORWidget.prototype.start_submit = function() {
    // change UI to show that data is submitting
    if(this.submit_running) {
        return false;
        }
    this.submit_running = true;

    var div_id = this.INSTANCE_NAME+'_indicator';
    var indicator_style = "background-color:rgba(250,250,250,0.8);position:absolute;text-align:center;";
    if(this.get_disposition() == 'window') {
        indicator_style += 'top: 0; right: 0; bottom: 0; left: 0; padding-top: 45%;';
        }
    $('body').append("<div id='"+div_id+"' style='"+indicator_style+"'><img src='"+this.DOMAIN+"images/ajax-loader-big.gif' width='28' height='28' alt='Loading...' /></div>");
    var offset = this.CONTAINER.offset();
    var padding_top = Math.floor((this.CONTAINER.outerHeight()-28)/2);  // 28 = image height
    if(this.get_disposition() != 'window') {
        $('#'+div_id).css({
            width: this.CONTAINER.outerWidth(),
            height: this.CONTAINER.outerHeight() - padding_top,
            top: offset.top,
            left: offset.left,
            paddingTop: padding_top
        });
    } else {
        $('#'+div_id).css({
            paddingTop: padding_top
        });
    }
    return true;
}

WORWidget.prototype.finish_submit = function() {
    // change UI to show that data submitting is finished
    this.submit_running = false;
    $('#'+this.INSTANCE_NAME+'_indicator').remove();
}

WORWidget.prototype.on_submit = function() {
    // send user input to PROVIDER
    if(!this.start_submit()) {    // submit is already running
        return false;
    }

    var obj = this;
    this.sendAjax({
      type: "POST",
      dataType: 'json',
      checksum: true,
      data: this.CONTAINER.find('form').serialize(),
      url: this.DOMAIN+"process.js",
      complete: function(data, textStatus, request) {obj.get_instance().finish_submit();},   // "this" is replaced by XHR
      successCallback: function(data, textStatus, request) {obj.get_instance().drawAction(data);}   // "this" is replaced by XHR
    });
    return false;
    }

WORWidget.prototype.drawAction = function(action) {
    // show PROVIDER response in UI
    if(action == null) {
        alert('bad AJAX response');
        return;
        }
    if (typeof(action.errors) != 'undefined'){
        var errContainer = this.CONTAINER.find(this.ERROR_CONTAINER_ID); // Has to be redefined at every redraw call
        errContainer.html(this.renderErrors(action.errors));
        errContainer.show();
    } else { //No errors, redraw the page
        var obj = this;
        this.CONTAINER.html(this.renderAction(action)+"<div class='clear'></div>"); // to keep layout
        this.template = action.template;
        var form = this.CONTAINER.find('form');
        form.append("<input type='hidden' name='is_submit' />");
        if (typeof(action.validator) != 'undefined'){
            form.append("<input type='hidden' name='validator' value='"+action.validator+"' />");
        }
        
        form.bind('submit', function(){return obj.on_submit();});
        //form.attr('onsubmit', "alert(1245);return "+this.INSTANCE_NAME+".on_submit();");
    }
    this.pushSize();
}

WORWidget.prototype.get_disposition = function() {
    // find out in what container WIDGET is used
    if(top != window)                   {return 'iframe';}  // top ~ parent
    if($('body.wor-body').length > 0)   {return 'window';}
    else                                {return 'inline'}
}

WORWidget.prototype.pushSize = function() {
    // push WIDGET resize (because of content change)
    
    if(this.get_disposition() == 'iframe') {
        var h = '#'+this.NUM+':'+this.CONTAINER.outerWidth()+':'+this.CONTAINER.outerHeight();
        this.CONTAINER.append("<iframe src='"+this.ORIGIN+"/size_receiver.html"+h+"' width='1' height='1' style='display:none;'></irfame>");
    }
    // nothing to do for DIV - size is proper
    // nothing to do for WINDOW - cannot change the size properly
}

WORWidget.prototype.renderAction = function(action) {
    // render TEMPLATE using provided data
    if(this.TEMPLATES[action.template]) {
        return new EJS({text: this.TEMPLATES[action.template]}).render(action.data);
    }
}

WORWidget.prototype.renderErrors = function(errors) {
    // render errors
    if(this.TEMPLATES["errors"]) {
        return new EJS({text: this.TEMPLATES["errors"]}).render({"errors":errors});
    }
}

WORWidget.prototype.generalErrorCallback = function() {
    // some error occured during AJAX request
    alert('invalid AJAX response');
}

WORWidget.prototype.sessionErrorCallback = function() {
    // session error occured during AJAX request
    alert('Invalid session. Please try refreshing the page.');
}

WORWidget.prototype.sendAjax = function(options) {
    // extended jQuery AJAX - with checksum and additional params
    obj = this;
    var beforeSendReal = function(req) {};
    if (options.beforeSend) {
        beforeSendReal = options.beforeSend;
        }
    
    options.beforeSend = function(req) {
        beforeSendReal(req);
        if (req.withCredentials !== undefined) {
            req.withCredentials = true;
        }
    }
    if (options.success === undefined) {
        options.success = function(data, textStatus, request) {
            if (data=='FAIL'){
                obj.sessionErrorCallback();                    
            } else {
                options.successCallback(data, textStatus, request); 
            }
        }   
    }
    
    options.data += '&widget_id=' + encodeURIComponent(this.ID);
    options.data += '&template=' + encodeURIComponent(this.template);
    options.data += '&token=' + encodeURIComponent(this.AUTH_TOKEN);
    
    if(options.data.substring(0,1) == '&') {
        options.data = options.data.substring(1);
        }
    
    if (options.checksum !== undefined && options.checksum) {

        // Checksum is calculated the following way:
        // 1. Get the POSTDATA string in c=d&a=b&soon=so%20forth fashion
        // 2. Sort param=value pairs by key in alphabetical order a=b&c=d&soon=so%20forth
        // 3. Calculate HMAC-SHA1 signature using string from step 2 encoded by secret
        // 4. Base64-encode string from step 3 
        
        data = options.data;
        //Ripped off from jQuery
        var s = $.extend(true, {}, $.ajaxSettings, options);
        
        if ( s.data && s.processData && typeof s.data !== "string" ) {
            data = $.param(s.data, s.traditional);
        }

        data_arr = data.split('&');
        data_arr = data_arr.sort(function(a,b){return (a.substr(0,a.indexOf('=')) > b.substr(0,b.indexOf('='))) ? 1 : -1;});
        data = data_arr.join('&');

        checksum = Crypto.util.bytesToBase64(Crypto.HMAC(Crypto.SHA1, data, this.AUTH_SECRET, { asBytes: true }));
        
        options.data = data+'&checksum='+encodeURIComponent(checksum)
    }
    if (options.error === undefined) {
        options.error = this.generalErrorCallback;
    }    

    return $.ajax(options);
}
