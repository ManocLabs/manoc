function getCustomEuroDateValue(strDate) {
    var frDatea = $.trim(strDate).split(' ');
    var frTimea = frDatea[1].split(':');
    var frDatea2 = frDatea[0].split('/');
     
    var x = (frDatea2[2] + frDatea2[1] + frDatea2[0] + frTimea[0] + frTimea[1] + frTimea[2]);
    x = x * 1;
 
    return x;
}

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

function naturalSort (a, b) {
    var re = /(^-?[0-9]+(\.?[0-9]*)[df]?e?[0-9]?$|^0x[0-9a-f]+$|[0-9]+)/gi,
        sre = /(^[ ]*|[ ]*$)/g,
        dre = /(^([\w ]+,?[\w ]+)?[\w ]+,?[\w ]+\d+:\d+(:\d+)?[\w ]?|^\d{1,4}[\/\-]\d{1,4}[\/\-]\d{1,4}|^\w+, \w+ \d+, \d{4})/,
        hre = /^0x[0-9a-f]+$/i,
        ore = /^0/,
        // convert all to strings and trim()
        x = a.toString().replace(sre, '') || '',
        y = b.toString().replace(sre, '') || '',
        // chunk/tokenize
        xN = x.replace(re, '\0$1\0').replace(/\0$/,'').replace(/^\0/,'').split('\0'),
        yN = y.replace(re, '\0$1\0').replace(/\0$/,'').replace(/^\0/,'').split('\0'),
        // numeric, hex or date detection
        xD = parseInt(x.match(hre)) || (xN.length != 1 && x.match(dre) && Date.parse(x)),
        yD = parseInt(y.match(hre)) || xD && y.match(dre) && Date.parse(y) || null;
    // first try and sort Hex codes or Dates
    if (yD)
        if ( xD < yD ) return -1;
        else if ( xD > yD )  return 1;
    // natural sorting through split numeric strings and default strings
    for(var cLoc=0, numS=Math.max(xN.length, yN.length); cLoc < numS; cLoc++) {
        // find floats not starting with '0', string or 0 if not defined (Clint Priest)
        var oFxNcL = !(xN[cLoc] || '').match(ore) && parseFloat(xN[cLoc]) || xN[cLoc] || 0;
        var oFyNcL = !(yN[cLoc] || '').match(ore) && parseFloat(yN[cLoc]) || yN[cLoc] || 0;
        // handle numeric vs string comparison - number < string - (Kyle Adams)
        if (isNaN(oFxNcL) !== isNaN(oFyNcL)) return (isNaN(oFxNcL)) ? 1 : -1;
        // rely on string comparison if different types - i.e. '02' < 2 != '02' < '2'
        else if (typeof oFxNcL !== typeof oFyNcL) {
            oFxNcL += '';
            oFyNcL += '';
        }
        if (oFxNcL < oFyNcL) return -1;
        if (oFxNcL > oFyNcL) return 1;
    }
    return 0;
}

jQuery.extend( jQuery.fn.dataTableExt.oSort, {
  "date-italy-desc": function(x, y) {
    var xVal = getCustomEuroDateValue(x);
    var yVal = getCustomEuroDateValue(y);
 
    if (xVal < yVal) {
        return 1;
    } else if (xVal > yVal) {
        return -1;
    } else {
        return 0;
    }
  },
  "date-italy-asc":  function(x, y) {
    var xVal = getCustomEuroDateValue(x);
    var yVal = getCustomEuroDateValue(y);
 
    if (xVal < yVal) {
        return -1;
    } else if (xVal > yVal) {
        return 1;
    } else {
        return 0;
	  }
   },
    "natural-asc": function ( a, b ) {
	var x = a.replace( /<.*?>/g, "" );
	var y = b.replace( /<.*?>/g, "" );
	return naturalSort(x,y);
    },
    "natural-desc": function ( a, b ) {
	var x = a.replace( /<.*?>/g, "" );
	var y = b.replace( /<.*?>/g, "" );
        return naturalSort(x,y) * -1;
    }
});
