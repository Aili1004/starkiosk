package com.snepo.givv.cardbrowser.services.events
{
	import flash.events.*;

	public class CardPrinterServiceEvent extends Event
	{
		public static const STARTING_CARD : String = "CardPrinterServiceEvent.STARTING_CARD";
		public static const CARD_FINISHED : String = "CardPrinterServiceEvent.CARD_FINISHED";
		public static const COMPLETE : String = "CardPrinterServiceEvent.COMPLETE";
		public static const PROGRESS : String = "CardPrinterServiceEvent.PROGRESS";
		public static const ERROR : String = "CardPrinterServiceEvent.ERROR";

		public static const PAYMENT_SUCCESSFUL : String = "CardPrinterServiceEvent.PAYMENT_SUCCESSFUL";
		public static const PAYMENT_ERROR : String = "CardPrinterServiceEvent.PAYMENT_ERROR";

		public static const STATE_CHANGE : String = "CardPrinterServiceEvent.STATE_CHANGE";

		public var data : *;

		public function CardPrinterServiceEvent ( type : String, data : * = null )
		{
			super ( type );
			this.data = data;
		}
	}
}