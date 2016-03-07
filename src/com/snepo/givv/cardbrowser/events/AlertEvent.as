package com.snepo.givv.cardbrowser.events
{
	import flash.events.*;
		
	public class AlertEvent extends Event
	{	
		public static const DISMISS : String = "AlertEvent.DISMISS";

		public var data : *;
		public var reason : String;

		public function AlertEvent ( type : String, data : * = null, reason : String = "OK" )
		{
			super ( type );
			this.data = data;
			this.reason = reason;
		}
	}
}