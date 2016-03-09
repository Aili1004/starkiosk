package com.snepo.givv.cardbrowser.view.controls
{
	import com.snepo.givv.cardbrowser.view.core.*;
	import com.snepo.givv.cardbrowser.events.*;
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

	public class BigHomeButton extends Component
	{

		public var offFillColor : uint = 0xFFD435; // yellow
		public var onFillColor : uint = 0x6c8e17; // green

		protected var _shadow : DropShadowFilter;

		public function BigHomeButton()
		{
			_shadow = new DropShadowFilter ( 5, 45, 0x000000, 0.5, 10, 10, 1, 3 )

			super();
		}

		override protected function createUI ( ) : void
		{
			super.createUI();

			this.filters = [fill.filters[0]];
			fill.filters = [];

			addEventListener ( MouseEvent.MOUSE_DOWN, playClickAnimation );
		}

		protected function playClickAnimation ( evt : MouseEvent ) : void
		{
			SoundUtil.playLibrary ( ButtonTick );

			TweenMax.to ( fill, 0.4, { tint : onFillColor, ease : Quint.easeOut } );
			TweenMax.to ( fill, 0.4, { tint : offFillColor, ease : Quint.easeIn, delay : 0.4 } );
		}

		override protected function invalidate ( ) : void
		{
			super.invalidate();

			TweenMax.to ( fill, 0, { tint : offFillColor } );
		}
	}
}