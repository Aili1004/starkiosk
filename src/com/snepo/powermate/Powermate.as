package com.snepo.powermate
{	
	/**
	* @author Andrew Wright
	*/
	
	import com.snepo.powermate.events.*;

	import com.greensock.easing.*;
	import com.greensock.*;
	
	import flash.events.*;
	import flash.utils.*;
	
	public class Powermate extends EventDispatcher
	{
		public static var HOLD_DELAY:int = 800;
		
		public var name : String = "";
		public var deviceID:int = 0;
		public var pressTime:int;
		public var isDown:Boolean = false;
		
		protected var _brightness:Number = 0;
		protected var _pulse:Boolean = false;
		protected var _pulseRate:Number = 0;
		
		protected var holdTimer:Timer;
		
		public function Powermate( data : Object = null )
		{
			super( this );
			
			if ( data )
			{
				this.name = data.name;
				this.deviceID = data.id;
			}
			
		}
		
		public function startHoldTimer():void
		{
			if ( holdTimer ) holdTimer.stop();
			
			holdTimer = new Timer ( HOLD_DELAY, 1 );
			holdTimer.addEventListener ( TimerEvent.TIMER, notifyHold );
			holdTimer.start();
		}
		
		public function stopHoldTimer():void
		{
			if ( holdTimer ) holdTimer.stop();
		}
		
		protected function notifyHold ( evt:TimerEvent ) : void
		{
			dispatchEvent ( new PowermateEvent ( PowermateEvent.HOLD, 0, "", this ) );
		}

		public function flash ( times : int = 3, timePer : Number = 0.2, endBrightness : int = 1 ) : void
		{
			for ( var i : int = 0; i < times; i++ )
			{
				var brightness : int = i % 2;
				TweenMax.to ( this, timePer, { brightness : brightness, delay : i * timePer, ease : Linear.easeNone } );
			}

			TweenMax.to ( this, timePer, { brightness : endBrightness, delay : (times+1) * timePer, ease : Linear.easeNone } );
			
		}
		
		public function set brightness ( b:Number ) : void
		{
			_brightness = b;
			if ( _brightness < 0 ) _brightness = 0;
			if ( _brightness > 1 ) _brightness = 1;
			
			_pulse = false;
			_pulseRate = 0;
			
			PowermateManager.sharedManager.setBrightness ( this, brightness );
		}
		
		public function get brightness ( ) : Number
		{
			return _brightness;
		}
		
		public function set pulseRate ( p:Number ) : void
		{
			_pulseRate = p;
			if ( _pulseRate < 0 ) _pulseRate = 0;
			if ( _pulseRate > 0.9 ) _pulseRate = 0.9;
			
			PowermateManager.sharedManager.setPulseRate ( this, pulseRate );
		}
		
		public function get pulseRate ( ) : Number
		{
			return _pulseRate;
		}
		
		public function set pulse ( p:Boolean ) : void
		{
			this._pulse = p;
			PowermateManager.sharedManager.setPulse ( this, pulse );
		}
		
		public function get pulse ( ) : Boolean
		{
			return this._pulse;
		}
		
		override public function toString():String
		{
			return "[Object Powermate(id='" + deviceID + "', name='" + name + "')]";
		}

	}
}