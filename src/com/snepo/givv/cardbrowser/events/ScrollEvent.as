package com.snepo.givv.cardbrowser.events
{	
	/**
	* @author Andrew Wright
	*/
	
	import flash.events.*;
	
	public class ScrollEvent extends Event
	{
		public static const SCROLL  : String = "ScrollEvent.SCROLL";
		public static const THROW	: String = "ScrollEvent.THROW";
		public static const SNAP	: String = "ScrollEvent.SNAP";
		
		public var value : * = 0;
		
		public function ScrollEvent ( type : String, value : * = 0 )
		{
			super ( type );
			this.value = value;
		}

	}
}