package com.snepo.givv.cardbrowser.events
{	
	/**
	* @author Andrew Wright
	*/
	
	import flash.events.*;
	
	public class ScreenEvent extends Event
	{
		public static const CHANGE  : String = "ScreenEvent.CHANGE";
		public static const SHOW 	: String = "ScreenEvent.SHOW";
		public static const HIDE 	: String = "ScreenEvent.HIDE";
		
		public var data : * = null;
		
		public function ScreenEvent ( type : String, data : * = null )
		{
			super( type );
			this.data = data;
		}

	}
}