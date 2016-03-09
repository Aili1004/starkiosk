package com.snepo.givv.cardbrowser.util
{
	public class StringUtil
	{
		public static const WHITESPACE:String = '  \n\t\r';
		public static const MONTHS : Array = [ "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" ];

		public static function currencyLabelFunction ( v : Number ) : String
		{
			if ( v == Number.NEGATIVE_INFINITY || v == Number.POSITIVE_INFINITY ) return "Any";

			var decimal : Number = ( v - ( Math.floor ( v ) ) );
			var decimalPrint : String = decimal.toFixed(2).split("0")[1];

			var rounded : int = Math.floor ( v );

			var fixed : String;

			if ( v == 0 )
				return "$0"
			if ( v < 1 )
			{
				fixed = (v * 100).toFixed(0);
				if ( fixed.indexOf(".00") > -1 ) fixed = fixed.replace(".00", "");
//				if ( fixed.indexOf( "." ) > -1 ) return "$" + fixed;

				return fixed  + "c";
			}
			if ( v < 1000 )
			{
				fixed = "$" + v.toFixed(2);
				if ( fixed.indexOf(".00") > -1 ) fixed = fixed.replace(".00", "");

				return fixed;
			}

			var value : Array = (rounded + "").split("");

			for ( var i : int = value.length - 3; i > 0; i -= 3 )
			{
				value.splice ( i, 0, "," );
			}

			var output : String = "$" + value.join("");

			if ( output.indexOf(".00") > -1 ) output = output.replace(".00", ".0");

			if ( decimal != 0 )
			{
				output = output.split(".")[0] + decimalPrint
			}

			return output;
		}

		public static function isEmail ( email : String ) : Boolean
		{
			var emailExpression:RegExp = /^([a-zA-Z0-9_\.\-\!\#\$\%\^\&\*\(\)\{\}\`\~\+\-\=\/\?\|])+\@(([a-zA-Z0-9\-])+\.)+([a-zA-Z0-9]{2,4})+$/ ;
  		    return emailExpression.test(email);
		}

		public static function replaceKeys ( template : String, propertyMap : Object ) : String
		{
			for ( var i : String in propertyMap )
			{
				var regex : RegExp = new RegExp("\\$\\{" + i + "\\}", "g" );
				template = template.replace( regex, propertyMap[i] );
			}

			return template;
		}

		public static function generateFakeGUID ( length : int ) : String
		{
			var chars : String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";
			var output : String = ""
			while ( output.length < length ) output += chars.charAt ( Math.round ( Math.random() * chars.length ) );
			return output;
		}

		public static function titleCase ( t : String ) : String
		{
			return t.charAt(0).toUpperCase() + t.substring ( 1, t.length ).toLowerCase();
		}

		public static function trimLeft(source:String, removeChars:String = StringUtil.WHITESPACE):String
		{
			var pattern:RegExp = new RegExp('^[' + removeChars + ']+', '');
			return source.replace(pattern, '');
		}

		public static function trimRight(source:String, removeChars:String = StringUtil.WHITESPACE):String
		{
			var pattern:RegExp = new RegExp('[' + removeChars + ']+$', '');
			return source.replace(pattern, '');
		}

		public static function firstWord ( source : String ) : String
		{
			var pattern:RegExp = new RegExp( "\\b.(\\w*).\\b",'gi' );
			return trim(source.match( pattern )[0],' ');
		}

		public static function trim(source:String, removeChars:String = StringUtil.WHITESPACE):String
		{
			var pattern:RegExp = new RegExp('^[' + removeChars + ']+|[' + removeChars + ']+$', 'g');
			return source.replace(pattern, '');
		}

		public static function getDateTime() : String
		{
			var now : Date = new Date();
			return getDate(now) + " " + getTime(now);
		}

		public static function getDate ( d : Date, includeDay : Boolean = true ) : String
		{
			var month : String = padZeros ( d.getMonth() + 1 );
			var date : String = padZeros ( d.getDate() );
			var year : String = d.getFullYear() + "";

			return (includeDay ? date + "/" : "") + month + "/" + year;
		}

		public static function getLongDate ( d : Date ) : String
		{
			var month : String = MONTHS [ d.getMonth() ];
			var date : String = padZeros ( d.getDate() );
			var year : String = d.getFullYear() + "";

			return [ date, month, year ].join ( " " );
		}

		public static function getTime ( d : Date ) : String
		{
			var hours : String = padZeros ( d.getHours() );
			var minutes : String = padZeros ( d.getMinutes() );

			return hours + ":" + minutes;
		}

		public static function getPad ( len : int, char : String = " ")
		{
			return new Array(len).join(char);
		}

		public static function padZeros ( v : Number ) : String
		{
			if ( v < 10 ) return "0" + v;
			return "" + v;
		}
	}
}