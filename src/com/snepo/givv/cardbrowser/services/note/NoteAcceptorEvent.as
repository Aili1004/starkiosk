package com.snepo.givv.cardbrowser.services.note
{
	import flash.events.*;

	public class NoteAcceptorEvent extends Event
	{
		public static const STARTED : String = "Started";
		public static const STOPPED : String = "Stopped";
		public static const STOPPING : String = "Stopping";
		public static const GET_STATE : String = "GetState";
		public static const STATE_CHANGE : String = "StateChange";
		public static const NOTE_ACCEPTED : String = "NoteAccepted";
		public static const GET_DENOMINATIONS : String = "GetDenominations";
		public static const UNAVAILABLE : String = "Unavailable"
		
		public var data : Object;

		public function NoteAcceptorEvent ( type : String, data : Object = null )
		{
			super ( type );

			this.data = data;
		}
	}
}