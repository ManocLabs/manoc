jQuery.fn.dataTableExt.aTypes.push( function ( sData )
{

	sData = typeof sData.replace == 'function' ?
		sData.replace( /<.*?>/g, "" ) : sData;
	
	if (/^\d{1,3}[\.]\d{1,3}[\.]\d{1,3}[\.]\d{1,3}$/.test(sData)) {
	    return 'ip-html';
	}
	var sValidFirstChars = "0123456789-";
	var sValidChars = "0123456789.";
	var Char;
	var bDecimal = false;
	
	/* Check for a valid first char (no period and allow negatives) */
	Char = sData.charAt(0); 
	if (sValidFirstChars.indexOf(Char) == -1) 
	{
		return null;
	}
	
	/* Check all the other characters are valid */
	for ( var i=1 ; i<sData.length ; i++ ) 
	{
		Char = sData.charAt(i); 
		if (sValidChars.indexOf(Char) == -1) 
		{
			return null;
		}
		
		/* Only allowed one decimal place... */
		if ( Char == "." )
		{
			if ( bDecimal )
			{
				return null;
			}
			bDecimal = true;
		}
	}
	
	return 'num-html';
} );

jQuery.fn.dataTableExt.aTypes.push(
	function ( sData )
	{
		if (/^\d{1,3}[\.]\d{1,3}[\.]\d{1,3}[\.]\d{1,3}$/.test(sData)) {
			return 'ip-address';
		}
		return null;
	}
);

jQuery.fn.dataTableExt.aTypes.unshift(
	function ( sData )
	{

/*	Old method to detect a date
        var iParse = Date.parse(sData);
        if ( iParse !=  null && !isNaN(iParse))
	{
           return 'date-euro';
	}
*/
        if (sData !== null && sData.match(/^(0[1-9]|[12][0-9]|3[01])\/(0[1-9]|1[012])\/(19|20|21)\d\d$/))
        {
            return 'date-euro';
        }
	return null;
	}
);

