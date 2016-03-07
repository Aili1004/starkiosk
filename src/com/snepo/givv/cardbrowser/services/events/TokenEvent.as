package com.snepo.givv.cardbrowser.services.events
{
	import flash.events.*;

	public class TokenEvent extends Event
	{
		public static const COMPLETE : String = "TokenEvent.COMPLETE";
		public static const PROGRESS : String = "TokenEvent.PROGRESS";
		public static const ERROR : String = "TokenEvent.ERROR";

		public var data : *;

		public function TokenEvent ( type : String, data : * = null )
		{
			super ( type );
			this.data = data;
		}
	}
}