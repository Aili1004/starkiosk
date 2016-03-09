package com.snepo.givv.cardbrowser.events
{	
	/**
	* @author Andrew Wright
	*/
	
	import flash.events.*;
	
	public class CardEvent extends Event
	{
		public static const SELECTED_CARD_CHANGED  : String = "CardEvent.SELECTED_CARD_CHANGED";
		
		public var data : * = 0;
		
		public function CardEvent ( type : String, data : * = 0 )
		{
			super ( type );
			this.data = data;
		}

	}
}