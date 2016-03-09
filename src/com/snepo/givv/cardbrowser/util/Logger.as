package com.snepo.givv.cardbrowser.util
{
	import com.snepo.givv.cardbrowser.view.core.gesture.*;
	import com.snepo.givv.cardbrowser.view.controls.*;
	import com.snepo.givv.cardbrowser.view.core.*;
	import com.snepo.givv.cardbrowser.view.*;
	import com.snepo.givv.cardbrowser.util.*;
	
	import com.greensock.easing.*;
	import com.greensock.*;

	import flash.display.*;
	import flash.events.*;
	import flash.utils.*;
	import flash.text.*;
	import flash.net.*;

	public class Logger extends Component
	{
		public static const LOG : String = "LOG";
		public static const INFO : String = "INFO";
		public static const WARN : String = "WARN";
		public static const ERROR : String = "ERROR"
		public static const FATAL : String = "FATAL";
		public static const TIMER : String = "TIMER";
		
		protected static var instance : Logger;
		protected static var timerTime : int = 0;
		protected static var currentTimerMessage : String = "";
		
		protected var isShown : Boolean = false;
		protected var file : FileReference;
		
    	public function Logger()
		{
			super();
		
			_width = View.APP_WIDTH - 60;
			_height = View.APP_HEIGHT - 60;

			
			instance = this;
			visible = false;
			alpha = 0;
			scaleX = 0;
			scaleY = 0;
			isShown = false;
		}

		public static function isInitialised( ) : Boolean
		{
			return instance != null;
		}
		
		public static function test ( ) : void
		{
			log ( "This is a log", LOG );
			log ( "This is an info", INFO );
			log ( "This is a warn", WARN );
			log ( "This is an error", ERROR );
			log ( "This is a fatal", FATAL );

		}

		public static function beginTimer ( message : String ) : void
		{
			timerTime = getTimer();
			currentTimerMessage = message;
		}

		public static function endTimer ( message : String ) : void
		{
			var ms : int = getTimer() - timerTime;
			log ( currentTimerMessage + "........" + message + " [ Completed in " + ms + " ms. ]", TIMER );
		}

		public static function getFontForLevel ( level : String, message : String ) : String
		{
			var colors : Object = { LOG : "#000000", INFO : "#0099FF", WARN : "#FFCC00", ERROR : "#FF6600", FATAL : "#BD0000", TIMER : "#00BD00" }; 
			var color : String = colors[level];
				
			var weight : String = "normal";
				weight = level == FATAL ? "bold" : "normal";	
			
			var messageOut : String = "<font color='" + color + "'>" + message + "</font>";
			if ( weight == "bold" ) messageOut = "<b>" + messageOut + "</b>";

			return messageOut;

		}

		public static function get datetime ( ) : String
		{
			var now : Date = new Date();
			var time : String = StringUtil.padZeros ( now.getHours() ) + ":" + StringUtil.padZeros ( now.getMinutes() ) + ":" + StringUtil.padZeros ( now.getSeconds() );
			var date : String = StringUtil.padZeros ( now.getDate() ) + "/" + StringUtil.padZeros ( now.getMonth() + 1 ) + "/" + now.getFullYear();

			return date + "-" + time;
		}

		public static function dump ( ) : void
		{
			show();		
			instance.file = new FileReference();
			instance.file.addEventListener ( Event.COMPLETE, restoreFullScreen );
			instance.file.addEventListener ( Event.CANCEL, restoreFullScreen );
			try
			{
				instance.file.save ( instance.logText.text, "Log_" + new Date().getTime() + ".log" );
//				instance.logText.text = "";
			}catch ( e : Error )
			{
				log ( e.toString() );
				show();
			}	

			log ( "Logs dumped at " + datetime );
		}

		protected static function restoreFullScreen ( evt : Event ) : void
		{
//			View.getStage().displayState = StageDisplayState.FULL_SCREEN;
		}

		public static function newline ( count : int ) : void
		{
			instance.newline ( count );
		}

		public function newline ( count : int ) : void
		{
			logText.htmlText += new Array ( count ).join ( "\n" );
			logText.scrollV = logText.maxScrollV;
		}

		public function log ( message : String, level : String = INFO, linefeed : Boolean = true ) : void
		{
			message = "[" + level + "]\t  " + datetime + "\t\t" + message;
			trace ( message );

			instance.logText.htmlText += getFontForLevel(level, message);
			if ( linefeed ) newline(1);
			instance.logText.scrollV = instance.logText.maxScrollV;

			if ( isShown )
			{
				DisplayUtil.top ( this );
			}
		}

		public static function log ( message : String, level : String = INFO, linefeed : Boolean = true ) : void
		{
			instance.log ( message, level, linefeed );
		}
		
		public static function show ( ) : void
		{
			instance.show();
		}

		public static function hide ( ) : void
		{
			instance.hide();
		}

		override protected function initStageEvents ( evt : Event = null ) : void
		{
			super.initStageEvents ( evt );

			addGesture ( new Gesture ( Gesture.SWIPE_LEFT, this, 0.3, close ) );
			addGesture ( new Gesture ( Gesture.SWIPE_RIGHT, this, 0.3, close ) );
			addGesture ( new Gesture ( Gesture.SWIPE_UP, this, 0.3, close ) );
			addGesture ( new Gesture ( Gesture.SWIPE_DOWN, this, 0.3, close ) );
		}

		protected function close ( g : Gesture ) : void
		{
			this.hide();
		}

		public function show ( ) : void
		{
			isShown = true;

			DisplayUtil.top ( this );
			this.x = View.APP_WIDTH / 2;
			this.y = View.APP_HEIGHT / 2;
			this.scaleX = 0;
			this.scaleY = 0;

			TweenMax.to ( this, 0.3, { autoAlpha : 1, scaleX : 1, scaleY : 1, x : View.APP_WIDTH / 2 - this.width / 2, y : View.APP_HEIGHT / 2 - this.height / 2, ease : Back.easeOut })

		}

		public function hide ( ) : void
		{
			isShown = false;
			
			TweenMax.to ( this, 0.3, { autoAlpha : 0, scaleX : 0, scaleY : 0, x : View.APP_WIDTH / 2, y : View.APP_HEIGHT / 2, ease : Back.easeIn })
		}

	}

}