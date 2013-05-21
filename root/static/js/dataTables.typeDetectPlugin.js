jQuery.fn.dataTableExt.aTypes.unshift(
        function ( sData )
        {         
            return "natural";
        }
);

jQuery.fn.dataTableExt.aTypes.unshift(
        function ( sData )
        {         
         if (sData !== null && sData.match(/^(0[1-9]|[12][0-9]|3[01])\/(0[1-9]|1[012])\/(19|20|21)\d\d \d{2}:\d{2}:\d{2}$/))
        {	    
            return 'date-italy';
        }
        return null;
        }
);
