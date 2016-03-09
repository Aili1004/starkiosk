package com.snepo.givv.cardbrowser.events
{
	import flash.events.*;

	public class BarcodeEvent extends Event
	{
		public static const SCAN : String = "BarcodeEvent.SCAN";

		public var data : *;

		public function BarcodeEvent ( type : String, data : * = null )
		{
			super ( type );
			this.data = data;
		}
	}
}