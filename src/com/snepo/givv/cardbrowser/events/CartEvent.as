package com.snepo.givv.cardbrowser.events
{	
	/**
	* @author Andrew Wright
	*/
	
	import flash.events.*;
	
	public class CartEvent extends Event
	{
		public static const PAYMENT_METHOD_CHANGED  : String = "CartEvent.PAYMENT_METHOD_CHANGED";
		public static const SCANNED_CARD_EXISTS		: String = "CartEvent.SCANNED_CARD_EXISTS";
		public static const COMMISSION_APPLIED		: String = "CartEvent.COMMISSION_APPLIED";
		public static const MAX_CARDS_REACHED 		: String = "CartEvent.MAX_CARDS_REACHED";
		public static const LIMIT_REACHED 			: String = "CartEvent.LIMIT_REACHED";
		public static const ITEM_REMOVED  			: String = "CartEvent.ITEM_REMOVED";
		public static const ITEM_UPDATED  			: String = "CartEvent.ITEM_UPDATED";
		public static const ITEM_ADDED	  			: String = "CartEvent.ITEM_ADDED";
		public static const DRAIN		  			: String = "CartEvent.DRAIN"
		
		public var data : *;
		
		public function CartEvent( type : String, data : * = null )
		{
			super ( type );
			this.data = data;
		}

	}
}