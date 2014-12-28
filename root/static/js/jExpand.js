(function($){
    $.fn.jExpand = function(){
        var element = this;

	//init the style
	$("tr.master").addClass('ui-state-focus');
	$("tr.header").addClass('ui-widget-header ui-corner-all');

	$('#expandible').width($('#expandible').width());

        $("#expandible tr.master .arrow").click(function() {
	    $(this).closest("tr").nextUntil("tr.master", "tr")
		.stop(true, true).animate({
	    	    height:"toggle",
		    opacity:"toggle"
		}, 1000);
		$(this).toggleClass("up");
        });
    }		
    $.fn.jExpand_CollapseAll = function(){
	$("#expandible tr:not(.master)").hide();
	$("#expandible .header").show();
	$(".arrow").each(function(){
	    $(":not(.up)").toggleClass("up");
	});
    }
    $.fn.jExpand_ExpandAll = function(){
    	$("#expandible tr:not(.master)").show();
	$(".arrow").each(function(){
	    $(".up").toggleClass("up");
	});
    }
    
})(jQuery); 