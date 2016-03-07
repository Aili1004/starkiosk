package com.snepo.givv.cardbrowser.events
{
	import flash.events.*;
		
	public class ModelEvent extends Event
	{	
		public static const READY : String = "ModelEvent.READY";
		public static const ERROR : String = "ModelEvent.ERROR";
		
		public var data : *;

		public function ModelEvent ( type : String, data : * = null )
		{
			super ( type );
			this.data = data;
		}
	}
}