package com.snepo.givv.cardbrowser.services.pinpad
{
	import flash.events.*;

	public class PinPadEvent extends Event
	{
		public static const DISPLAY : String = "Display";
		public static const CLEAR : String = "Clear";
		public static const LOGON : String = "Logon";
		public static const TRANSACTION : String = "Transaction";  
		public static const READ : String = "ReadCard";
		public static const FAIL : String = "Fail";

		public var data : XML;

		public function PinPadEvent ( type : String, data : XML )
		{
			super ( type );

			this.data = data;
		}
	}
}