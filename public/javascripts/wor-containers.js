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
*   Generating WIDGETS inside placeholders
*   Resizing iframes match its content
*
*/

function worCreateWidgetContainers(token) {
    // create WIDGETS inside HTML placeholders (they will load widget into themselfes)

    $("div.wor-container").each(function(i,cont){
        var cont_widget = $(cont).attr("widget") || false;
        var cont_css = $(cont).attr("css") || '';
        var cont_position = ($(cont).attr("position") || 'iframe').toLowerCase();
        var cont_text = $(cont).attr('text') || 'Show widget';
        var cont_width = $(cont).attr('width') || '0';
        var cont_height = $(cont).attr('height') || '0';
        
        if (!cont_widget) {
            return;
        }

        var cont_options = 'menubar=no,location=no,scrollbars=yes,status=no,resizable=yes';
        
        if(cont_width !='0' && cont_height != '0') {
            cont_options += ',width='+cont_width+',height='+cont_height;
        }

        var widget_url = SERVICE_URL_PREFIX + "widget." +((cont_position.toLowerCase() == 'inline') ? 'js' : 'html' );
        widget_url += "?v="+encodeURIComponent(cont_widget)+"&css="+encodeURIComponent(cont_css)+"&i="+i+"&token="+token;

        if(cont_position == 'iframe') {

            widget_url += "&origin="+encodeURIComponent(location.protocol+'//'+location.host);
            $(cont).html("<iframe id='wor_frame_"+i+"' name='wor_frame_"+i+"' src='"+widget_url+"' style='background-color: transparent; background-image: url("+SERVICE_URL_PREFIX+"images/ajax-loader-big.gif); background-repeat: no-repeat; border: solid 1px #DDD;' frameborder='0' transparency='true' allowtransparency='true' height='28' width='28' scrolling='NO'></iframe>");

        } else if(cont_position == 'inline') {

            $(cont).html("<div id='wor_"+i+"' class='wor_content wor_inline'><img src='"+SERVICE_URL_PREFIX+"images/ajax-loader-big.gif' width='28' height='28' alt='Loading...' /></div><div class='clear'></div><script type='text/javascript' src='"+widget_url+"'></script>");

        } else if(cont_position == 'window') {
            
            $(cont).html("<a href='#' onClick='window.open(\""+widget_url+"\", \"wor_"+i+"\",\""+cont_options+"\").focus();return false;'>"+cont_text+"</a>");
        }
    });
}

function worSizeToContent(new_size) {
    var h = new_size.split(':');
    var frame_name = 'wor_frame_'+h[0];
    if(frame_name in window.frames) {   // such frame present
        var f = $('#'+frame_name);
        f.animate({width: h[1], height: h[2]}, 'fast', function() {$(this).css('background-image','none');}); // with animation
        //f.css({width: h[1], height: h[2], backgroundImage: 'none'});           // without animation
    }
}
