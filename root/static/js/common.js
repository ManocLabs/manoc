function showUrlInDialog(url, options){
  options = options || {};
  var tag = $("<div></div>"); //This tag will the hold the dialog content.
  $.ajax({
    url: url,
    type: (options.type || 'GET'),
    beforeSend: options.beforeSend,
    error: options.error,
    complete: options.complete,
    success: function(data, textStatus, jqXHR) {
      tag.html(data).dialog({modal: options.modal, title: options.title, width: options.width}).dialog('open');
      $.isFunction(options.success) && (options.success)(data, textStatus, jqXHR);
    }
  })
}
