package com.snepo.givv.cardbrowser.events
{
	import flash.events.*;
		
	public class LoginEvent extends Event
	{	
		public static const LOGIN : String = "LoginEvent.LOGIN";
		public static const CREATE : String = "LoginEvent.CREATE";

		public var data : *;
		
		public function LoginEvent ( type : String, data : * = null )
		{
			super ( type );
			this.data = data;
		}
	}
}