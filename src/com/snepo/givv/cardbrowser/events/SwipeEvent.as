package com.snepo.givv.cardbrowser.events
{	
	/**
	* @author Andrew Wright
	*/
	
	import flash.events.*;
	
	public class SwipeEvent extends Event
	{
		public static const SWIPE  : String = "SwipeEvent.SWIPE";
		
		public var buffer : String = "";
		
		public function SwipeEvent ( type : String, buffer : String = "" )
		{
			super( type );
			this.buffer = buffer;
		}

	}
}