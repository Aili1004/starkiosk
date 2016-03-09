package com.snepo.givv.cardbrowser.services.events
{
	import flash.events.*;

	public class CardProcessorEvent extends Event
	{
		public static const STATE_CHANGE : String = "CardProcessorEvent.STATE_CHANGE";
		public static const COMPLETE : String = "CardProcessorEvent.COMPLETE";
		public static const PROGRESS : String = "CardProcessorEvent.PROGRESS";
		public static const ERROR : String = "CardProcessorEvent.ERROR";

		public var data : *;

		public function CardProcessorEvent ( type : String, data : * = null )
		{
			super ( type );
			this.data = data;
		}
	}
}