jQuery.fn.dataTableExt.oSort['num-html-asc']  = function(a,b) {
	var x = a.replace( /<.*?>/g, "" );
	var y = b.replace( /<.*?>/g, "" );
	x = parseFloat( x );
	y = parseFloat( y );
	return ((x < y) ? -1 : ((x > y) ?  1 : 0));
};

jQuery.fn.dataTableExt.oSort['num-html-desc'] = function(a,b) {
	var x = a.replace( /<.*?>/g, "" );
	var y = b.replace( /<.*?>/g, "" );
	x = parseFloat( x );
	y = parseFloat( y );
	return ((x < y) ?  1 : ((x > y) ? -1 : 0));
};

jQuery.fn.dataTableExt.oSort['ip-address-asc']  = function(a,b) {
	var m = a.split("."), x = "";
	var n = b.split("."), y = "";
	for(var i = 0; i < m.length; i++) {
		var item = m[i];
		if(item.length == 1) {
			x += "00" + item;
		} else if(item.length == 2) {
			x += "0" + item;
		} else {
			x += item;
		}
	}
	for(var i = 0; i < n.length; i++) {
		var item = n[i];
		if(item.length == 1) {
			y += "00" + item;
		} else if(item.length == 2) {
			y += "0" + item;
		} else {
			y += item;
		}
	}
	return ((x < y) ? -1 : ((x > y) ? 1 : 0));
};

jQuery.fn.dataTableExt.oSort['ip-address-desc']  = function(a,b) {
	var m = a.split("."), x = "";
	var n = b.split("."), y = "";
	for(var i = 0; i < m.length; i++) {
		var item = m[i];
		if(item.length == 1) {
			x += "00" + item;
		} else if (item.length == 2) {
			x += "0" + item;
		} else {
			x += item;
		}
	}
	for(var i = 0; i < n.length; i++) {
		var item = n[i];
		if(item.length == 1) {
			y += "00" + item;
		} else if (item.length == 2) {
			y += "0" + item;
		} else {
			y += item;
		}
	}
	return ((x < y) ? 1 : ((x > y) ? -1 : 0));
};

jQuery.fn.dataTableExt.oSort['ip-html-asc']  = function(a,b) {
    var a1 = a.replace( /<.*?>/g, "" );
    var b1 = b.replace( /<.*?>/g, "" );
    
    var m = a1.split("."), x = "";
    var n = b1.split("."), y = "";
    for(var i = 0; i < m.length; i++) {
		var item = m[i];
		if(item.length == 1) {
		    x += "00" + item;
		} else if(item.length == 2) {
		    x += "0" + item;
		} else {
		    x += item;
		}
    }
    for(var i = 0; i < n.length; i++) {
	var item = n[i];
		if(item.length == 1) {
		    y += "00" + item;
		} else if(item.length == 2) {
		    y += "0" + item;
		} else {
		    y += item;
		}
    }
    return ((x < y) ? -1 : ((x > y) ? 1 : 0));
};

jQuery.fn.dataTableExt.oSort['ip-html-desc']  = function(a,b) {
    var a1 = a.replace( /<.*?>/g, "" );
    var b1 = b.replace( /<.*?>/g, "" );
    
    var m = a1.split("."), x = "";
    var n = b1.split("."), y = "";
	for(var i = 0; i < m.length; i++) {
	    var item = m[i];
	    if(item.length == 1) {
		x += "00" + item;
	    } else if (item.length == 2) {
		x += "0" + item;
	    } else {
		x += item;
	    }
	}
    for(var i = 0; i < n.length; i++) {
	var item = n[i];
	if(item.length == 1) {
			y += "00" + item;
	} else if (item.length == 2) {
	    y += "0" + item;
	} else {
	    y += item;
	}
    }
    return ((x < y) ? 1 : ((x > y) ? -1 : 0));
};

function trim(str) {
	str = str.replace(/^\s+/, '');
	for (var i = str.length - 1; i >= 0; i--) {
		if (/\S/.test(str.charAt(i))) {
			str = str.substring(0, i + 1);
			break;
		}
	}
	return str;
}

jQuery.fn.dataTableExt.oSort['uk_date-asc']  = function(a,b) {
	var ukDatea = a.split('/');
	var ukDateb = b.split('/');
	
	var x = (ukDatea[2] + ukDatea[1] + ukDatea[0]) * 1;
	var y = (ukDateb[2] + ukDateb[1] + ukDateb[0]) * 1;
	
	return ((x < y) ? -1 : ((x > y) ?  1 : 0));
};

jQuery.fn.dataTableExt.oSort['uk_date-desc'] = function(a,b) {
	var ukDatea = a.split('/');
	var ukDateb = b.split('/');
	
	var x = (ukDatea[2] + ukDatea[1] + ukDatea[0]) * 1;
	var y = (ukDateb[2] + ukDateb[1] + ukDateb[0]) * 1;
	
	return ((x < y) ? 1 : ((x > y) ?  -1 : 0));
};