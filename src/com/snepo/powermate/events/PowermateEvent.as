package com.snepo.powermate.events
{	
	/**
	* @author Andrew Wright
	*/
	
	import com.snepo.powermate.*;
	
	import flash.events.*;
	import flash.utils.*;
	
	public class PowermateEvent extends Event
	{
		public static const CONNECTION_ERROR : String = "PowermateEvent.CONNECTION_ERROR";
		public static const DEVICE_REMOVED : String = "PowermateEvent.DEVICE_REMOVED";
		public static const DEVICE_ADDED : String = "PowermateEvent.DEVICE_ADDED";
		public static const DEVICE_LIST : String = "PowermateEvent.DEVICE_LIST";
		public static const HOLD_RELEASE : String = "PowermateEvent.HOLD_RELEASE";
		public static const HOLD_ROTATE : String = "PowermateEvent.HOLD_ROTATE";
		public static const CONNECT : String = "PowermateEvent.CONNECT";
		public static const RELEASE : String = "PowermateEvent.RELEASE";
		public static const ROTATE : String = "PowermateEvent.ROTATE";
		public static const PRESS : String = "PowermateEvent.PRESS";
		public static const CLOSE : String = "PowermateEvent.CLOSE";
		public static const HOLD : String = "PowermateEvent.HOLD";

		public var delta : Number = 0;
		public var message : String = "";
		public var eventTime:int = 0;
		public var targetDevice : Powermate;
		
		public function PowermateEvent( type : String, delta : Number = 0, message : String = "", targetDevice : Powermate = null )
		{
			super( type );
			
			this.delta = delta;
			this.message = message;
			this.eventTime = getTimer();
			this.targetDevice = targetDevice;
			
		}

	}
}