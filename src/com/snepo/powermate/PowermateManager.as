package com.snepo.powermate
{	
	/**
	* @author Andrew Wright
	*/
	
	import com.adobe.serialization.json.*;
	import com.snepo.powermate.events.*;
	
	import flash.events.*;
	import flash.utils.*;
	import flash.net.*;
	
	public class PowermateManager extends EventDispatcher
	{
		protected static var _sharedManager : PowermateManager;
		protected static var host : String = "localhost";
		protected static var port : int = 7777;
		
		public static function get sharedManager() : PowermateManager { return getInstance() };
				
		public static function init ( _host : String, _port : int ) : PowermateManager
		{
			host = _host;
			port = _port;
			
			return sharedManager;
		}
		
		protected static function getInstance():PowermateManager
		{
			if ( _sharedManager == null ) _sharedManager = new PowermateManager();
			return _sharedManager;
		}
		
		public var devices : Vector.<Powermate>;
		protected var connection : Socket;

		public function get numDevices ( ) : int
		{
			return devices.length;
		}
		
		public function PowermateManager()
		{
			super( this );
			
			devices = new Vector.<Powermate>();
		}
		
		public function connect():void
		{
			connection = new Socket();
			connection.addEventListener ( SecurityErrorEvent.SECURITY_ERROR, onSocketError );
			connection.addEventListener ( ProgressEvent.SOCKET_DATA, onSocketData );
			connection.addEventListener ( IOErrorEvent.IO_ERROR, onSocketError );
			connection.addEventListener ( Event.CONNECT, onSocketConnected );
			connection.addEventListener ( Event.CLOSE, onSocketClose );
			connection.connect ( host, port );
		}
		
		protected function onSocketError ( evt:ErrorEvent ) : void
		{
			var event : PowermateEvent = new PowermateEvent ( PowermateEvent.CONNECTION_ERROR, 0, evt.text );
			dispatchEvent ( event );
		}
		
		protected function onSocketConnected ( evt:Event ) : void
		{
			var event : PowermateEvent = new PowermateEvent ( PowermateEvent.CONNECT, 0, "PowermateManager connected..." );
			dispatchEvent ( event );
		}
		
		protected function onSocketClose ( evt:Event ) : void
		{
			var event : PowermateEvent = new PowermateEvent ( PowermateEvent.CLOSE, 0, "PowermateManager closed..." );
			dispatchEvent ( event );
		}
		
		protected function onSocketData ( evt:ProgressEvent ) : void
		{
			var buffer : String = connection.readUTFBytes ( connection.bytesAvailable );
			var data : Object;
			
			try
			{
				data = JSON.parse ( buffer );
			}catch ( e:Error )
			{
				return;
			}
				
			var value : *;
			var i:int;
			var pm:Powermate;
			
			switch ( data.call )
			{
				case "DeviceList" : 
				{
					devices = new Vector.<Powermate>();
					value = data.value as Array;
					
					for ( i = 0; i < value.length; i++ )
					{
						devices.push ( new Powermate ( value[i] ) );
					}
					
					dispatchEvent ( new PowermateEvent ( PowermateEvent.DEVICE_LIST ) );
					
					break;
				}
				
				case "DeviceAdded" :
				{
					pm = new Powermate ( data.value );
					
					if ( !deviceExists ( pm ) )
					{
						devices.push ( pm );
						dispatchEvent ( new PowermateEvent ( PowermateEvent.DEVICE_ADDED, 0, "", pm ) );
					}
					
					break;
				}
				
				case "DeviceRemoved" :
				{
					pm = getDeviceByLocationID ( data.value.id );
					
					if ( pm )
					{
						devices.splice ( devices.indexOf ( pm ), 1 );
						dispatchEvent ( new PowermateEvent ( PowermateEvent.DEVICE_REMOVED, 0, "", pm ) );
					}
					
					break;
				}
				
				case "DeviceAction" :
				{
					
					var method : String = trim ( data.value.method );
					var delta : Number = data.value.delta;
					
					pm = getDeviceByLocationID ( data.value.id );
					
					if ( pm )
					{
						var eventType : String;
						switch ( method )
						{
							case "Rotate Right" :
							case "Rotate Left" :
							{
								eventType = pm.isDown ? PowermateEvent.HOLD_ROTATE : PowermateEvent.ROTATE;
								break;
							}
							
							case "Press" :
							{
								eventType = PowermateEvent.PRESS;
								pm.pressTime = getTimer();
								pm.isDown = true;
								pm.startHoldTimer();
								break;
							}
							
							case "Release" :
							{
								var timeDelta:int = getTimer() - pm.pressTime;
								pm.isDown = false;
								pm.stopHoldTimer();
								eventType = (timeDelta > Powermate.HOLD_DELAY) ? PowermateEvent.HOLD_RELEASE : PowermateEvent.RELEASE;
								break;
							}
						}
						
						if ( eventType ) pm.dispatchEvent ( new PowermateEvent ( eventType, delta, "", pm ) );
					}
					
					break;
				}
			}
			
		}
		
		public function setBrightness ( pm:Powermate, brightness:Number ) : void
		{
			var message : String = "set_brightness|" + pm.name + "|" + brightness;
			
			write( message );
		}
		
		public function setPulse ( pm:Powermate, pulse:Boolean ) : void
		{
			var message : String = "set_pulse|" + pm.name + "|" + pulse;
			
			write( message );
		}
		
		public function setPulseRate ( pm:Powermate, pulseRate:Number ) : void
		{
			var message : String = "set_pulse_rate|" + pm.name + "|" + pulseRate;
			
			write( message );
		}
		
		protected function write ( message : String ) : void
		{
			connection.writeUTFBytes ( message );
			connection.flush();
		}
		
		public function deviceExists ( pm:Powermate ) : Boolean
		{
			for ( var i:int = 0; i < devices.length; i++ )
			{
				var device : Powermate = devices[i] as Powermate;
				if ( device.deviceID == pm.deviceID && device.name == pm.name ) return true;
			}
			
			return false;
		}
		
		public function getDeviceByLocationID ( id : int ) : Powermate
		{
			for ( var i:int = 0; i < devices.length; i++ )
			{
				var device : Powermate = devices[i] as Powermate;
				if ( device.deviceID == id ) return device;
			}
			
			return null;
		}
		
		public function getDeviceByName ( name : String ) : Powermate
		{
			for ( var i:int = 0; i < devices.length; i++ )
			{
				var device : Powermate = devices[i] as Powermate;
				if ( device.name == name ) return device;
			}
			
			return null;
		}
		
		protected function trim ( source:String ) : String
		{
			var removeChars:String = ' \n\t\r';
			var pattern:RegExp = new RegExp('^[' + removeChars + ']+|[' + removeChars + ']+$', 'g');
			return source.replace(pattern, '');
		}
		

	}
	
}