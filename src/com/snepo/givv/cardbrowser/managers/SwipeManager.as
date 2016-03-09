package com.snepo.givv.cardbrowser.managers
{
	import com.snepo.givv.cardbrowser.errors.*;
	import com.snepo.givv.cardbrowser.events.*;
	import com.snepo.givv.cardbrowser.util.*;

	import com.greensock.*;

	import flash.events.*;
	import flash.net.*;

	public class SwipeManager extends EventDispatcher
	{
		public static var acceptingSwipes : Boolean = false;

		protected static var instance : SwipeManager;
		public static var HOST : String = "localhost";
		public static var PORT : int = 7777;

		public static function getInstance ( ) : SwipeManager
		{
			instance ||= new SwipeManager ( new Private() );
			return instance;
		}

		protected var socket : Socket;

		public function SwipeManager ( p : Private ) 
		{
			super ( this );

			if ( p == null ) throw new SingletonError ( "SwipeManager" );
		}

		public function connect ( host : String = null, port : int = -1 ) : void
		{
			if ( host ) HOST = host;
			if ( port > 0 ) PORT = port;

			if ( socket && socket.connected )
			{
				Logger.log ( "Swipe manager already connected.", Logger.ERROR );
				return;
			}

			//attemptReconnection();
			
		}

		protected function cleanupSocket ( ) : void
		{
			if ( !socket ) return;
			try
			{
				socket.close();
			}catch ( e : Error )
			{
				
			}

			try
			{
				socket.removeEventListener ( Event.CONNECT, onSocketConnect );
				socket.removeEventListener ( IOErrorEvent.IO_ERROR, onSocketError );
				socket.removeEventListener ( SecurityErrorEvent.SECURITY_ERROR, onSocketError );
				socket.removeEventListener ( ProgressEvent.SOCKET_DATA, readSocketBuffer );
				socket.removeEventListener ( Event.CLOSE, onSocketClose );
			}catch ( e : Error )
			{
				
			}

			socket = null;

		}

		protected function stopReconnectionAttempt ( ) : void
		{
			TweenMax.killDelayedCallsTo ( attemptReconnection );
		}

		protected function attemptReconnection ( ) : void
		{
			Logger.log ( "Attempting to connect to swipe service on " + HOST + ":" + PORT );
			cleanupSocket();
			stopReconnectionAttempt();

			socket = new Socket ( );
			socket.addEventListener ( Event.CONNECT, onSocketConnect, false, 0, true );
			socket.addEventListener ( IOErrorEvent.IO_ERROR, onSocketError, false, 0, true );
			socket.addEventListener ( SecurityErrorEvent.SECURITY_ERROR, onSocketError, false, 0, true );
			socket.addEventListener ( ProgressEvent.SOCKET_DATA, readSocketBuffer, false, 0, true );
			socket.addEventListener ( Event.CLOSE, onSocketClose, false, 0, true );
			socket.connect ( HOST, PORT );
		}

		protected function onSocketConnect ( evt : Event ) : void
		{
			Logger.log ( "Connected to swipe service on " + HOST + ":" + PORT );
		}

		protected function onSocketError ( evt : ErrorEvent ) : void
		{
			Logger.log ( "Error connecting to swipe service on " + HOST + ":" + PORT + ", Reason : " + evt.text, Logger.ERROR );
			TweenMax.delayedCall ( 5, attemptReconnection );
		}

		protected function onSocketClose ( evt : Event ) : void
		{
			Logger.log ( "Lost connecting to swipe service on " + HOST + ":" + PORT + ". Reconnecting in 5 seconds.", Logger.ERROR );
			TweenMax.delayedCall ( 5, attemptReconnection );
		}

		protected function readSocketBuffer ( evt : ProgressEvent ) : void
		{
			try
			{
				var buffer : String = socket.readUTFBytes ( socket.bytesAvailable );
					buffer = buffer.replace ( /[\n]/g, "" );

				if ( acceptingSwipes ) dispatchEvent ( new SwipeEvent ( SwipeEvent.SWIPE, buffer ) );
				
			}catch ( e : Error )
			{
				Logger.log ( "Error reading buffer from swipe service.", Logger.ERROR );
			}
		}

		public function processBuffer ( buffer : String ) : void
		{
			buffer = buffer.replace ( /[\n]/g, "" );

			if ( acceptingSwipes ) dispatchEvent ( new SwipeEvent ( SwipeEvent.SWIPE, buffer ) );
		}
	}
}

class Private{}