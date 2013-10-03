function showUrlInDialog(url, options){
    options = options || {};
    var tag = $("<div></div>");
    $.ajax({
	url: url,
	type: (options.type || 'GET'),
	beforeSend: options.beforeSend,
	error: options.error,
	complete: options.complete,
	success: function(data, textStatus, jqXHR) {
	    tag.html(data).dialog({modal: options.modal, title: options.title, width: options.width}).dialog('open');
	    tag.attr('id', 'dialog');
	    $( "#dialog" ).on( "dialogclose", function() { $('#dialog').remove(); });
	    $.isFunction(options.success) && (options.success)(data, textStatus, jqXHR);
	}
    })
}

function showDialogForm(form_url, title, form_id, on_close) {
    var decorate_form = function() {
	$( "button, input:submit, a", ".buttons").button();
	$(form_id).submit(function(e) { e.preventDefault(e); });	
	$(form_id).attr('action', form_url),
	$(form_id + '\\.submit').click(submit_func);
	$(form_id + '\\.discard').click(function() { $('#dialog').dialog('close'); });
    }
    var submit_func = function() {
	$.ajax({
	    data: $(form_id).serialize(), 
	    type: $(form_id).attr('method'), 
	    url:  $(form_id).attr('action'),
	    success: function(data) {
		$('#dialog').html(data);     
 		decorate_form();
	    }
	});
    }   

    showUrlInDialog(form_url, {
	title: title, 
	width: 500,
	modal: true,
	success: function() {
	    decorate_form();
	    $( "#dialog" ).on("dialogclose", on_close);	 	    
	}
    });	


}
