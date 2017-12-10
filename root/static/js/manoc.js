function showDialogForm(url, title, on_close) {
    var modalBox = bootbox.dialog({
        message: '<div id="modalBoxMessage">Loading...</div>',
        title: title,
    });
    var submit_func = function(form) {
	    $.ajax({
	        data: form.serialize(),
	        type: form.attr('method'),
	        url:  url,
	        success: function(data) {
                if (data.html) {
                    $('#modalBoxMessage').html(data.html);
                    form = $('#modalBoxMessage form');
                    form.submit(function(e) { e.preventDefault(e); submit_func(form); });
                    return;
                }
                modalBox.modal('hide');
                on_close(data);
            }
	    }).fail(function() { alert( "Manoc internal error" ); } );
    };
    $.ajax({
        type: 'GET',
        url: url,
        success: function(data) {
            $('#modalBoxMessage').html(data.html);
            form = $('#modalBoxMessage form');
            form.submit(function(e) { e.preventDefault(e); submit_func(form); });
            $(".selectpicker").selectpicker('refresh');
        }
    });
    return true;
}

/* Manoc Form plugin */
(function( $ ) {
    $.fn.manocAjaxForm = function() {
        var submit_func = function(e) {
            e.preventDefault(e);
            var form = $( this );
	        $.ajax({
	            data: form.serialize(),
	            type: form.attr('method'),
	            url:  window.location,
	            success: function(data) {
                    if (data.html) {
                        form.html(data.html);
                        return;
                    }
                    form.replaceWith('<p>' + data.message + '</p>');
                    if (data.redirect) {
                        window.location.replace(data.redirect);
                    }
                }
	        });
	    };
        this.submit(submit_func);
        return this;
    };
}( jQuery ));

/* Remote Tab */
(function( $ ) {
    $('a[data-toggle="tab"]').on('show.bs.tab', function (e) {
        var currTabTarget = $(e.target).attr('href');
        var remoteUrl = $(this).attr('data-tab-remote');
        var loadedOnce = $(this).data('loaded');
        if (remoteUrl && remoteUrl !== '' && !loadedOnce) {
            $(currTabTarget).load(remoteUrl)
            $(this).data('loaded',true);
        }
    })
}( jQuery ));

/* Repeatable form fields */

$(function() {

    $('.form-btn-add:not(:last)')
        .removeClass('form-btn-add').addClass('form-btn-remove')
        .removeClass('btn-success').addClass('btn-danger')
        .html('<span class="glyphicon glyphicon-minus"></span>');

    $(document).on('click', '.form-btn-add', function(e)
    {
        e.preventDefault();

        var containerId = $(this).attr('data-rep-id');
        var container = $('#' + $.escapeSelector(containerId));

        var lastEntry = container.find('.hfh-repinst:last');

        var entryClone = lastEntry.clone().wrap('<div>').parent();
        var newEntryHtml = entryClone.html();

        var lastIndex = container.attr('data-rep-count');
        if ( lastIndex == undefined ) {
            lastIndex = container.find('.hfh-repinst').length - 1;
        } else {
            lastIndex = parseInt(lastIndex);
        }
        var newIndex  = lastIndex + 1;
        container.attr('data-rep-count', newIndex);

        newEntryHtml = newEntryHtml.replace(
            new RegExp( containerId + '.' + lastIndex,  'g'),
            containerId + '.' + newIndex);

        container.append(newEntryHtml);

        $('#' + $.escapeSelector(containerId + '.' + newIndex)).find('input').val('');

        container.find('.form-btn-add:not(:last)')
            .removeClass('form-btn-add').addClass('form-btn-remove')
            .removeClass('btn-success').addClass('btn-danger')
            .html('<span class="glyphicon glyphicon-minus"></span>');
        return false;
    });

    // support manoc implementation of repeteable forms
    $(document).on('click', '.form-btn-remove', function(e)
    {
		$(this).parents('.hfh-repinst:first').remove();

		e.preventDefault();
		return false;
	});


    if ( ! $('ul.nav a.active').length ) {
        var myurl = window.location.href;
        var urls = $('ul.nav a')
            .filter( function() { return !this.href.endsWith('#') })
            .map(function() { return this.href } );

        if (urls) {
            var best_url = null;
            var match_len = 0;
            for (var i = 0, len = urls.length; i < len; i++) {
                if ( myurl.startsWith(urls[i]) ) {
                    if ( urls[i].length > match_len ) {
                        match_len = urls[i].length;
                        best_url = urls[i];
                    }
                }
            }
            if ( match_len > 0 ) {
                var element = $('ul.nav a').filter(function() {
                    return this.href == best_url;
                }).addClass('active').parent();

                while (true) {
                    if (element.is('li')) {
                        element = element.parent().addClass('in').parent();
                    } else {
                        break;
                    }
                }
            }
        }
    }

});
