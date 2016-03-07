package com.snepo.givv.cardbrowser.util
{
	public class DateUtil
	{
		public static function parseDate ( d : String ) : Date
		{
			var parts : Array = d.split("-");
			
			var year : String = parts[0];
			var month : String = parts[1];
			var date : String = parts[2];

			var monthValue : int = month.charAt ( 0 ) == "0" ? Number ( month.charAt(1) ) : Number ( month );
			var dateValue : int = date.charAt ( 0 ) == "0" ? Number ( date.charAt(1) ) : Number ( date );
			var yearValue : int = Number ( year );

			return new Date ( yearValue, monthValue - 1, dateValue ); 
		}

		public static function isInDateRange ( checkDate : *, lowDate : *, highDate : * ) : Boolean
		{
			if ( checkDate is String ) checkDate = parseDate ( checkDate );
			if ( lowDate is String ) lowDate = parseDate ( lowDate );
			if ( highDate is String ) highDate = parseDate ( highDate );

			return checkDate.getTime() >= lowDate.getTime() && checkDate.getTime() <= highDate.getTime();
		}

		public static function getDate ( now : Date ) : String
		{
			var 
		}

	}

}