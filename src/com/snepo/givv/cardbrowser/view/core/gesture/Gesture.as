package com.snepo.givv.cardbrowser.view.core.gesture
{

	import com.snepo.givv.cardbrowser.view.core.*;
	import com.snepo.givv.cardbrowser.view.*;
	import com.snepo.givv.cardbrowser.util.*;

	import flash.display.*;
	import flash.events.*;
	import flash.utils.*;
	import flash.geom.*;
	import flash.net.*;

	import com.greensock.*;

	public class Gesture
	{
		public static const SWIPE_UP : String = "Gesture.SWIPE_UP";
		public static const SWIPE_DOWN : String = "Gesture.SWIPE_DOWN";
		public static const SWIPE_LEFT : String = "Gesture.SWIPE_LEFT";
		public static const SWIPE_RIGHT : String = "Gesture.SWIPE_RIGHT";

		public var type : String;
		public var time : Number;
		public var stage : Stage;
		public var target : Component;
		public var callback : Function;
		public var threshold : Number = 50;

		protected var touchTime : int = 0;
		protected var touchPoint : Point = new Point();

    	public function Gesture( type : String, target : Component, time : Number, callback : Function, threshold : Number = 50 )
		{
			this.type = type;
			this.time = time;
			this.target = target;
			this.callback = callback;
			this.threshold = threshold;

			if ( target.stage )
			{
				init();
			}else
			{
				target.addEventListener ( Event.ADDED_TO_STAGE, init );
			}

		}

		protected function init ( evt : Event = null ) : void
		{
			target.removeEventListener ( Event.ADDED_TO_STAGE, init );
			this.stage = target.stage;

			target.addEventListener ( MouseEvent.MOUSE_DOWN, startGestureCheck, false, 0, true );
			
		}

		protected function startGestureCheck ( evt : MouseEvent ) : void
		{
			this.touchTime = getTimer();
			this.touchPoint = new Point ( stage.mouseX, stage.mouseY );
			
			stage.addEventListener ( MouseEvent.MOUSE_UP, checkForGesturePerformed, false, 0, true );

			TweenMax.to ( this, time, { onComplete : tooLateForGesture } );
						
		}

		protected function checkForGesturePerformed ( evt : MouseEvent ) : void
		{
			var endPoint : Point = new Point ( stage.mouseX, stage.mouseY );

			var deltaX : Number = endPoint.x - touchPoint.x;
			var deltaY : Number = endPoint.y - touchPoint.y;

			var gestureSatisfied : Boolean = false;

			switch ( type )
			{
				case SWIPE_UP :
				{
					gestureSatisfied = ( deltaY < -threshold );
					break;
				}

				case SWIPE_DOWN :
				{
					gestureSatisfied = ( deltaY > threshold );
					break;
				}

				case SWIPE_LEFT :
				{
					gestureSatisfied = ( deltaX < -threshold );
					break;
				}

				case SWIPE_RIGHT :
				{
					gestureSatisfied = ( deltaX > threshold );
					break;
				}
			}

			if ( gestureSatisfied && callback != null )
			{
				try
				{
					callback.apply ( null, [ this ] );
				}catch ( e : Error )
				{
					
				}
			}

			tooLateForGesture();

		}

		protected function tooLateForGesture ( ) : void
		{
			stage.removeEventListener ( MouseEvent.MOUSE_UP, checkForGesturePerformed );
		}

		public function destroy ( ) : void
		{
			if ( stage )
			{
				stage.removeEventListener ( MouseEvent.MOUSE_UP, checkForGesturePerformed );
			}

			if ( target )
			{
				target.removeEventListener ( MouseEvent.MOUSE_DOWN, startGestureCheck );
			}

			target = null;
		}

	}

}