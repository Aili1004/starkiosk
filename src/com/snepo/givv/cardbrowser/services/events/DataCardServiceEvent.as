package com.snepo.givv.cardbrowser.services.events
{

	import flash.events.*;

	public class DataCardServiceEvent extends Event
	{
		public static const STATE_CHANGE : String = "DataCardServiceEvent.STATE_CHANGE";
		public static const ERROR_RECEIVED : String = "DataCardServiceEvent.ERROR_RECEIVED";
	
		public var command : Object;
	
		public function DataCardServiceEvent ( type : String, command : Object )
		{
			super ( type );
			this.command = command;
		}
	}
}