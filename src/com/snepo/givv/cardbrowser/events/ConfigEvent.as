package com.snepo.givv.cardbrowser.events
{	
	/**
	* @author Andrew Wright
	*/
	
	import flash.events.*;
	
	public class ConfigEvent extends Event
	{
		
		public static const CONFIG_READY : String = "ConfigEvent.CONFIG_READY";
		public static const CONFIG_ERROR : String = "ConfigEvent.CONFIG_ERROR";
		
		public var data : *;
		
		public function ConfigEvent ( type : String, data : * = null )
		{
			super( type );
			this.data = data;
		}

	}
}