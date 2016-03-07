package com.snepo.givv.cardbrowser.view.screens
{
	import com.snepo.givv.cardbrowser.view.controls.*;
	import com.snepo.givv.cardbrowser.view.overlays.*;
	import com.snepo.givv.cardbrowser.view.core.*;
	import com.snepo.givv.cardbrowser.managers.*;
	import com.snepo.givv.cardbrowser.events.*;
	import com.snepo.givv.cardbrowser.model.*;
	import com.snepo.givv.cardbrowser.view.*;
	import com.snepo.givv.cardbrowser.util.*;

	import com.greensock.easing.*;
	import com.greensock.*;

	import flash.display.*;
	import flash.filters.*;
	import flash.events.*;
	import flash.utils.*;
	import flash.geom.*;
	import flash.text.*;

	public class OutOfOrderScreen extends Screen
	{
		public var logo : MovieClip;

		public function OutOfOrderScreen ( )
		{
			super();

			_prompt = "";

			invalidate();
		}

		override protected function createUI ( ) : void
		{
			super.createUI();

			addChild ( logo = new StarOutOfOrder() );
		}

		override protected function invalidate ( ) : void
		{
			super.invalidate();

		}

		override public function show ( delay : Number = 0, notify : Boolean = true ) : void
		{
			if ( isShown ) return;

			super.show ( delay, notify );

			logo.scaleX = logo.scaleY = 0;

			TweenMax.killDelayedCallsTo ( animateElementsOut );
			TweenMax.delayedCall ( 0.7, animateElementsIn );
			TimeoutManager.lock();
		}

		override public function hide ( delay : Number = 0, notify : Boolean = true ) : void
		{
			if ( !isShown ) return;

			super.hide ( delay + 0.2, notify );

			TweenMax.killDelayedCallsTo ( animateElementsIn );
			animateElementsOut();
			TimeoutManager.unlock();
		}

		protected function animateElementsIn ( ) : void
		{
			TweenMax.to ( logo, 0.5, { scaleX : 1, scaleY : 1, ease : Back.easeOut } );
		}

		protected function animateElementsOut ( ) : void
		{
			TweenMax.to ( logo, 0.4, { scaleX : 0, scaleY : 0, ease : Back.easeIn } );
		}
	}
}
