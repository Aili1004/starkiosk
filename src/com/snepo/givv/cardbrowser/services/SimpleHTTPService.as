package com.snepo.givv.cardbrowser.services
{
	import com.snepo.givv.cardbrowser.events.*;
	import com.snepo.givv.cardbrowser.util.*;

	import flash.events.*;
	import flash.net.*;

	public class SimpleHTTPService extends EventDispatcher
	{
		protected var host : String;
		protected var port : int;
		protected var path : String;
		protected var method : String;

		protected var socket : Socket;
		protected var vars : URLVariables;
		public var response : Array = [];

		public function SimpleHTTPService ( url : String, method : String = "POST", vars : URLVariables = null ) : void
		{
			super ( this );
			parseURL ( url );
			this.vars = vars;
			this.method = method;
		}

		protected function parseURL ( url : String ) : void
		{
			url = url.replace ( "http://", "" );
			
			host = url.split(":")[0];
			port = url.split(":")[1] ? Number ( url.split(":")[1].split("/")[0] ) : 80;
			path = url.substring ( url.indexOf ( "/" ), url.length );

			trace ( host, port, path );
		}

		public function load ( ) : void
		{
			socket = new Socket();
			socket.timeout = 8000;
			socket.addEventListener ( Event.CONNECT, onSocketConnected, false, 0, true );
			socket.addEventListener ( Event.CLOSE   , onSocketClosed, false, 0, true );
			socket.addEventListener ( IOErrorEvent.IO_ERROR, onSocketError, false, 0, true );
			socket.addEventListener ( SecurityErrorEvent.SECURITY_ERROR, onSocketError, false, 0, true );
			socket.addEventListener ( ProgressEvent.SOCKET_DATA, processSocketBuffer, false, 0, true );
			socket.connect ( host, port );
		}

		protected function onSocketConnected ( evt : Event ) : void
		{
			var message : String = method + " " + path + " HTTP/1.1";
			
			if ( vars )
			{
				message += "\nContent-Type: application/x-www-form-urlencoded";
				message += "\nContent-Length: " + vars.toString().length + "\n\n";
				message += vars.toString() + "\n\n";
			}else
			{
				message += "\n\n";
			}

			trace ( "Writing " + message );
			
			socket.writeUTFBytes ( message );
			socket.flush();
		}

		protected function onSocketClosed ( evt : Event ) : void
		{
			trace ( "SimpleHTTPService::close")
			dispatchEvent ( new Event ( Event.CLOSE ) );
			socket = null;
		}

		protected function onSocketError ( evt : ErrorEvent ) : void
		{
			dispatchEvent ( evt.clone() );
		}

		protected function processSocketBuffer ( evt : ProgressEvent ) : void
		{
			var buffer : String = socket.readUTFBytes ( socket.bytesAvailable );
			trace ( "recv: " + buffer );
			parseBuffer( buffer );

			//socket.close();
			
			dispatchEvent ( new Event ( Event.COMPLETE ) );

			socket = null;
		}

		protected function parseBuffer ( buffer : String ) : void
		{
			var parts : Array = buffer.split ( "\r\n" );
			response [ "Response"] = parts[0];

			for ( var i : int = 1; i < parts.length; i++ )
			{
				var line : Array = parts[i].match(/([A-Za-z]+)\: (.+)/);
				if ( line && line.length > 2 )
				{
					response[line[1]] = line[2];
				}else if ( parts[i] == "0" ) // This is downright awful but it'll have to do the job for now.
				{
					if ( i > 1 )
					{
						response["Body"] = parts[i-1];
					}
				}
			}
		}
	}

}