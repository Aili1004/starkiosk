package com.snepo.givv.cardbrowser.events
{	
	/**
	* @author Andrew Wright
	*/
	
	import flash.events.*;
	
	public class ButtonEvent extends Event
	{

		public static const REPEAT : String = "ButtonEvent.REPEAT";
		
		public var data : * = null;
		
		public function ButtonEvent( type : String, data : * = null )
		{
			super ( type );
			this.data = data;
		}

	}
}