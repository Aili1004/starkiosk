package com.snepo.givv.cardbrowser.services.events
{
	import flash.events.*;

	public class PrintMockServiceEvent extends Event
	{
		public var data : *;

    	public function PrintMockServiceEvent( type, data : * = null )
		{
			super ( type );
			this.data = data;
		}
	}

}