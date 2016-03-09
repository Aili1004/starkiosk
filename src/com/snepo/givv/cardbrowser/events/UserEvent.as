package com.snepo.givv.cardbrowser.events
{	
	/**
	* @author Andrew Wright
	*/
	
	import flash.events.*;
	
	public class UserEvent extends Event
	{
		public static const BALANCE_CHANGED  : String = "UserEvent.BALANCE_CHANGED";
		public static const JOINED  : String = "UserEvent.JOINED";
		public static const LEFT  : String = "UserEvent.LEFT";
		
		public var data : Object = null;
		
		public function UserEvent ( type : String, data : Object = null )
		{
			super( type );
			this.data = data;
		}

	}
}