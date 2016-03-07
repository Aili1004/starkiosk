package com.snepo.givv.cardbrowser.services
{
	import com.snepo.givv.cardbrowser.services.events.*;
	import com.snepo.givv.cardbrowser.util.*;

	import com.adobe.serialization.json.*;
	import com.greensock.*;

	import flash.events.*;
	import flash.utils.*;
	import flash.net.*;

	public class CoinSorterService extends EventDispatcher
	{
		public static var HOST : String = Environment.SERVICE;
		public static var PORT : int 	= 2011;

		protected var socket : Socket;
		protected var autoStart : Boolean = false;
		protected var connected : Boolean = false;

		protected var handlers : Dictionary = new Dictionary(true);

		public function CoinSorterService( autoStart : Boolean = false )
		{
			super ( this );
			this.autoStart = autoStart;

			this.registerHandlers();
		}

		public function loadMockScript ( script : String ) : void
		{
			var loader : URLLoader = new URLLoader();
				loader.addEventListener ( Event.COMPLETE, readMockScript );
				loader.load ( new URLRequest ( script ) );
		}

		protected function readMockScript ( evt : Event ) : void
		{
			var mock : MockPlayer = new MockPlayer(this);
			var lines : Array = evt.target.data.split("\n");

			trace ( lines.length );

			for ( var i : int = 0; i < lines.length; i++ )
			{
				var parts : Array = lines[i].split ( ", ");
				trace ( "\t" + parts );
				mock.add ( readCommandFromBuffer, parts[0] ).after ( Number ( parts[1] ) );
			}


		}

		public function connect() : void
		{
			socket = new Socket();
			socket.addEventListener ( Event.CONNECT, handleConnect, false, 0, true );
			socket.addEventListener ( IOErrorEvent.IO_ERROR, handleError, false, 0, true );
			socket.addEventListener ( SecurityErrorEvent.SECURITY_ERROR, handleSecurityError, false, 0, true );
			socket.addEventListener ( ProgressEvent.SOCKET_DATA, readIncomingData, false, 0, true );
			socket.timeout = 5000;
			socket.connect ( HOST, PORT );

		}

		public function reconnect ( ) : void
		{
			trace ( "Attemping reconnect to coin sorter...")
			clearSocket();

			TweenMax.killDelayedCallsTo ( connect );
			TweenMax.delayedCall ( 3, connect );
		}

		public function mockTransaction ( ) : void
		{
			var mock : MockPlayer = new MockPlayer(this);
				mock.add ( processCommand, { started : true, command : CoinSorterCommands.SetValueWithMotorStatus } ).after ( 2 );

		}

		protected function handleConnect ( evt : Event ) : void
		{
			trace ( "CoinSorterService::connect");
			if ( autoStart ) confirmSorterConnection();
		}

		protected function handleError ( evt : ErrorEvent ) : void
		{
			trace ( "CoinSorterService::Error -> " + evt.toString() );
			dispatchEvent ( new CoinSorterServiceEvent ( CoinSorterServiceEvent.COMMUNICATION_BREAKDOWN, { reason : evt } ) );
		}

		protected function handleSecurityError ( evt : ErrorEvent ) : void
		{
			trace ( "CoinSorterService::Error -> " + evt.toString() );
		}

		protected function readIncomingData ( evt : ProgressEvent ) : void
		{
			var buffer : String = socket.readUTFBytes ( socket.bytesAvailable );
			trace ("Service got " + buffer );
			readCommandFromBuffer ( buffer );
		}

		protected function readCommandFromBuffer ( buffer : String ) : void
		{
			try
			{
				var command : Object = JSON.parse ( buffer );
				processCommand ( command );
			}catch ( e : Error )
			{
				// Most likely an unfinished JSON string.
			}
		}

		public function send ( command : String ) : void
		{
			try
			{
				socket.writeUTFBytes ( command );
				socket.flush();
			}catch ( e : Error )
			{

			}
		}

		protected function processCommand ( data : Object ) : void
		{
			if ( handlers [ data.command ] )
			{
				handlers [ data.command ] ( data );
			}else
			{
				trace ( "Unregistered handler for " + data.command );
			}
		}

		/* Handlers */
		protected function registerHandlers ( ) : void
		{
			handlers [ CoinSorterCommands.GetMachineStatus 			] = onGetMachineStatus;
			handlers [ CoinSorterCommands.GetCurrentCountingResult 	] = onGetCurrentCountingResult;
			handlers [ CoinSorterCommands.GetCoinDenominations 		] = onGetCoinDenominations;
			handlers [ CoinSorterCommands.GetDisplayContents 		] = onGetDisplayContents;
			handlers [ CoinSorterCommands.ResetTotals 				] = onResetTotals;
			handlers [ CoinSorterCommands.SetValueWithMotorStatus 	] = onSetMotorStatus;
			handlers [ CoinSorterCommands.CountingFinalized			] = onCountingFinalized;
			handlers [ CoinSorterCommands.ResetToCountingMode		] = tryReportError;
			//handlers [ CoinSorterCommands.GetTotalCountingResult	] = onGetTotalCountingResult;
		}

		protected function onGetMachineStatus ( data : Object ) : void
		{
			trace ( "CoinSorterService::onGetMachineStatus -> " + JSON.stringify (data ) )
			if (connected || data.errorState != 0)
				dispatchEvent ( new CoinSorterServiceEvent ( CoinSorterServiceEvent.MACHINE_STATUS, data ) );
			else
				end(); // clear any previous counts before starting

			if (data.errorState != 0)
				clearSocket();
		}

		protected function tryReportError ( data : Object ) : void
		{
			if ( data.hasOwnProperty ( "errorState" ) )
			{
				var errorState : int = data.errorState;
				if ( errorState > 0 )
				{
					dispatchEvent ( new CoinSorterServiceEvent ( CoinSorterServiceEvent.ERROR, data ) );
				}
			}
		}

		protected function onGetCurrentCountingResult ( data : Object ) : void
		{
			trace ( "CoinSorterService::onGetCurrentCountingResult -> " + JSON.stringify (data ) )
			dispatchEvent ( new CoinSorterServiceEvent ( CoinSorterServiceEvent.COUNTING_UPDATED, data ) );
		}

		protected function onGetCoinDenominations ( data : Object ) : void
		{
			trace ( "CoinSorterService::onGetCoinDenominations -> " + JSON.stringify (data ) )
			dispatchEvent ( new CoinSorterServiceEvent ( CoinSorterServiceEvent.GET_DENOMINATIONS, data ) );
		}

		protected function onGetDisplayContents ( data : Object ) : void
		{
			trace ( "CoinSorterService::onGetDisplayContents -> " + JSON.stringify (data ) )
			dispatchEvent ( new CoinSorterServiceEvent ( CoinSorterServiceEvent.GET_DISPLAY, data ) );
		}

		/*protected function onGetTotalCountingResult ( data : Object ) : void
		{
			if ( totalState == 0 )
			{
				totalBefore = data.total;
				totalState = 1;
				trace ( "Total Before: " + totalBefore );
				start();
			}else
			{
				totalState = 0;
				totalAfter = data.total;
				trace ( "Total After: " + totalAfter );
				trace ( "Total counting in this session:" + ( totalAfter - totalBefore ) );
				clearSocket(false);
			}

			trace ( "CoinSorterService::onGetTotalCountingResult -> " + JSON.encode (data ) );
		}*/

		protected function onResetTotals ( data : Object ) : void
		{
			trace ( "CoinSorterService::onResetTotals -> " + JSON.stringify (data ) )
			dispatchEvent ( new CoinSorterServiceEvent ( CoinSorterServiceEvent.RESET_TOTALS, data ) );
		}

		protected function onSetMotorStatus ( data : Object ) : void
		{
			trace ( "CoinSorterService::onSetMotorStatus -> " + JSON.stringify (data ) )
			dispatchEvent ( new CoinSorterServiceEvent ( CoinSorterServiceEvent.MOTOR_CHANGED, data ) );
		}

		protected function onCountingFinalized ( data : Object ) : void
		{
			trace ( "CoinSorterService::onCountingFinalized -> " + JSON.stringify (data ) )

			if (!connected)
			{
				connected = true;
				trace ( "Communication Tested..." );
				TweenMax.delayedCall ( 1, start );
			}
			else
			{
				dispatchEvent ( new CoinSorterServiceEvent ( CoinSorterServiceEvent.COUNTING_FINALIZED, data ) );
				clearSocket( true );
			}
		}

		protected function clearSocket( countFirst : Boolean = true ) : void
		{
			if ( socket && socket.connected )
			{
				try
				{
					socket.close();
					socket = null;
				}catch ( e : Error )
				{

				}
			}
		}

		/* Service Methods */
		public function start ( ) : void
		{
			trace ( "CoinSorterService::start" );
			if ( !socket || !socket.connected ) return;
			TweenMax.killDelayedCallsTo ( notifyConnectionError );
			send ( "StartStop" );
		}

		public function end ( ) : void
		{
			trace ("End Coin Count");
			send ( "EndCountingSession" );
		}

		public function getMachineStatus ( ) : void
		{
			send ( "IsMotorRunning" );
		}

		public function getDisplay ( ) : void
		{
			send ( "GetDisplayContents" );
		}

		protected function getTotalCountingResult ( ) : void
		{
			send ( "GetTotalCountingResult" );
		}

		protected function confirmSorterConnection():void
		{
			connected = false;
			getMachineStatus(); // check status and clear existing count if needed
			TweenMax.delayedCall ( 50, notifyConnectionError );
		}

		protected function notifyConnectionError ( ) : void
		{
			var errorMsg : Object = {text:"155"};
			dispatchEvent ( new CoinSorterServiceEvent ( CoinSorterServiceEvent.COMMUNICATION_BREAKDOWN, {reason:errorMsg} ) );
		}

		public function dispose ( ) : void
		{
			clearSocket(true);
		}
	}
}
