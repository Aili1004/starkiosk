package com.snepo.givv.cardbrowser.services.events
{
	import flash.events.*;

	public class CoinSorterServiceEvent extends Event
	{
		public static const ERROR					: String = "CoinSorterServiceEvent.ERROR";
		public static const MACHINE_STATUS 			: String = "CoinSorterServiceEvent.MACHINE_STATUS";
		public static const COUNTING_UPDATED 		: String = "CoinSorterServiceEvent.COUNTING_UPDATED";
		public static const GET_DISPLAY 			: String = "CoinSorterServiceEvent.GET_DISPLAY";
		public static const GET_DENOMINATIONS		: String = "CoinSorterServiceEvent.GET_DENOMINATIONS";
		public static const RESET_TOTALS 			: String = "CoinSorterServiceEvent.RESET_TOTALS";
		public static const MOTOR_CHANGED			: String = "CoinSorterServiceEvent.MOTOR_CHANGED";
		public static const COUNTING_FINALIZED		: String = "CoinSorterServiceEvent.COUNTING_FINALIZED"; 
		public static const COMMUNICATION_BREAKDOWN : String = "CoinSorterServiceEvent.COMMUNICATION_BREAKDOWN";

		public var data : *;

		public function CoinSorterServiceEvent ( type : String, data : * = null )
		{
			super ( type );
			this.data = data;
		}
	}
}