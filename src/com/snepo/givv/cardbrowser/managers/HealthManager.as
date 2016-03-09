package com.snepo.givv.cardbrowser.managers
{
	import com.snepo.givv.cardbrowser.services.*;
	import com.snepo.givv.cardbrowser.events.*;
	import com.snepo.givv.cardbrowser.errors.*;
	import com.snepo.givv.cardbrowser.util.*;
	import com.snepo.givv.cardbrowser.view.*;
	import com.snepo.givv.cardbrowser.model.*;

	import flash.events.*;
	import flash.utils.*;
	import flash.net.*;

	public class HealthManager extends EventDispatcher
	{
		public static const MESSAGE_VERSION : int = 4;

		protected static var instance : HealthManager;

		public static function getInstance ( ) : HealthManager
		{
			instance ||= new HealthManager ( new Private() );
			return instance;
		}

		protected var timer : Timer;

		public function HealthManager ( p : Private )
		{
			super ( this );
			if ( p == null ) throw new SingletonError ( "HealthManager" );

			timer = new Timer ( 1000 * 60 * 10 );
			timer.addEventListener ( TimerEvent.TIMER, ping );
			timer.start();

//			ping ( null );
		}

		protected function ping ( evt : TimerEvent ) : void
		{
			if (View.getInstance().currentScreenKey == View.OOO_SCREEN)
				report ( 1, "Out Of Order" );
			else
				report ( 0, "All is well" );
		}

		public function report ( score : int, status : String ) : void
		{
			if (Environment.KIOSK_UNIQUE_ID != Environment.DEFAULT_KIOSK_UNIQUE_ID) // make sure GUID has been loaded
			{
				var data : XML = 	<request>
														<password>{Model.getInstance().getPassword()}</password>
														<messageVersion>{MESSAGE_VERSION}</messageVersion>
														<appVersion>{Environment.VERSION + (Environment.RELEASE != null ? ' (' + Environment.RELEASE + ')': '') }</appVersion>
														<health>
															<score>{score}</score>
															<problems>
																<problem>{status}</problem>
															</problems>
														</health>
													</request>
				var request : URLRequest = new URLRequest ( CardPrintingService.PAYMENT_ENDPOINT + "/api/kiosks/" + Environment.KIOSK_UNIQUE_ID + "/log.xml" );
					request.method = URLRequestMethod.POST;
					request.contentType = "text/xml";
					request.data = data;

				var loader : URLLoader = new URLLoader();
					loader.addEventListener ( Event.COMPLETE, onReportSuccess, false, 0, true );
					loader.addEventListener ( IOErrorEvent.IO_ERROR, onReportError, false, 0, true );
					loader.load ( request );
			}
		}

		protected function onReportSuccess ( evt : Event ) : void
		{
			var response : XML = new XML ( evt.target.data );
			// look for remote control commands
			if (response.error.children().length() == 0 && response.commands.remoteControl.text().length() > 0)
			{
				Logger.log('Health Response Included Remote Control Command: ' + response.commands.remoteControl.text(), Logger.LOG);
				Model.getInstance().host.remoteControl = response.commands.remoteControl.text();
			}
		}

		protected function onReportError ( evt : ErrorEvent ) : void
		{
			Logger.log( "Health Manager Failed: " + evt.text, Logger.ERROR );
			// reset timer to fix issue with pings stopping after an internet issue
			timer.reset();
			timer.start();
		}
	}
}

class Private{}