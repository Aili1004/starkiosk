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

	public class CoinCountingTotalBox extends Component
	{

		protected var _total : Number = 0;
		protected var totalAnimator : TitleText;

		protected var _convertEnabled : Boolean = true;
		protected var convertHolder : Sprite;

		public function CoinCountingTotalBox()
		{
			super();
		}

		public function set convertEnabled ( c : Boolean ) : void
		{
			_convertEnabled = c;
			if ( c )
			{
				TweenMax.to ( totalAnimator, 1, { x : 716, ease : Quint.easeInOut } ); //x : 503
			}else
			{
				TweenMax.to ( totalAnimator, 1, { x : 716, ease : Quint.easeInOut, delay : 0.3 } );
			}
		}

		public function get convertEnabled ( ) : Boolean
		{
			return _convertEnabled;
		}

		override protected function createUI ( ) : void
		{
			super.createUI();

			addChild ( totalAnimator = new TitleText() );
			totalAnimator.move ( totalField.x, totalField.y );
			totalAnimator.setSize ( totalField.width, totalField.height );
			totalAnimator.measureSize = false;
			totalAnimator.literalTextFormat = totalField.getTextFormat();
			totalAnimator.title = "$0.00";

			totalField.visible = false;
		}

		public function set total ( t : Number ) : void
		{
			var different = t != total;

			_total = t;

			if ( different ) render();
		}

		public function get total ( ) : Number
		{
			return _total;
		}

		override protected function render ( ) : void
		{
			totalField.text = "$" + ( total / 100 ).toFixed(2);

			totalAnimator.title = totalField.text;
		}

	}
}
