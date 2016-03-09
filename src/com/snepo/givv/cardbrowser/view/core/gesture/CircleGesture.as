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

	public class CircleGesture extends Gesture
	{
		public static const CIRCLE_CLOCKWISE : String = "CircleGesture.CIRCLE_CLOCKWISE";
		public static const CIRCLE_ANTICLOCKWISE : String = "CircleGesture.CIRCLE_ANTICLOCKWISE";

		protected var origin : Point = new Point();
		protected var lastAngle : Number = 0;
		protected var startAngle : Number = 0;
		protected var angleSum : Number = 0;
		protected var angleTicks : int = 1;
		
    	public function CircleGesture( type : String, target : Component, time : Number, callback : Function, originOffset : Point = null )
		{
			super ( type, target, time, callback );

			this.origin = origin || new Point();
		}

		override protected function startGestureCheck ( evt : MouseEvent ) : void
		{
			this.touchTime = getTimer();
			this.touchPoint = new Point ( target.mouseX, target.mouseY );
			this.angleSum = 0;
			this.lastAngle = 0;
			this.angleTicks = 1;
			
			var dx : Number = origin.x - touchPoint.x;
			var dy : Number = origin.y - touchPoint.y;

			var a : Number = Math.atan2 ( dy, dx ) / Math.PI * 180;
								
			lastAngle = a;
			this.startAngle = a;

			stage.addEventListener ( MouseEvent.MOUSE_UP, checkForGesturePerformed, false, 0, true );
			stage.addEventListener ( MouseEvent.MOUSE_MOVE, appendAngleSum, false, 0, true );

			TweenMax.to ( this, time, { onComplete : tooLateForGesture } );
						
		}

		protected function appendAngleSum ( evt : MouseEvent ) : void
		{
			this.touchPoint = new Point ( target.mouseX, target.mouseY );

			var dx : Number = origin.x - touchPoint.x;
			var dy : Number = origin.y - touchPoint.y;

			var a : Number = Math.atan2 ( dy, dx ) / Math.PI * 180;

			angleSum += ( a - lastAngle );

			lastAngle = a;

			angleTicks++;
		}

		override protected function checkForGesturePerformed ( evt : MouseEvent ) : void
		{
			var endPoint : Point = new Point ( target.mouseX, target.mouseY );

			var gestureSatisfied : Boolean = false;

			trace ( "[" + this.type + "] angle Sum : " + angleSum );

			if ( this.type == CIRCLE_ANTICLOCKWISE && angleSum < -320 )
			{
				gestureSatisfied = true;
			}else if ( this.type == CIRCLE_CLOCKWISE && angleSum > 320 )
			{
				gestureSatisfied = true;
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

		override protected function tooLateForGesture ( ) : void
		{
			stage.removeEventListener ( MouseEvent.MOUSE_UP, checkForGesturePerformed );
			stage.removeEventListener ( MouseEvent.MOUSE_MOVE, appendAngleSum );
		}

		override public function destroy ( ) : void
		{
			if ( stage )
			{
				stage.removeEventListener ( MouseEvent.MOUSE_UP, checkForGesturePerformed );
				stage.removeEventListener ( MouseEvent.MOUSE_MOVE, appendAngleSum );
			}

			if ( target )
			{
				target.removeEventListener ( MouseEvent.MOUSE_DOWN, startGestureCheck );
			}

			target = null;
		}

	}

}