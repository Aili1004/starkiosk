package com.snepo.givv.cardbrowser.view.controls
{
	import com.snepo.givv.cardbrowser.view.core.gesture.*;
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
	import flash.net.*;

	public class DenominationListItem extends Component implements IListItem
	{
		public var numValue : Number = 0;
		public var totalValue : Number = 0;

		public var actualNum : Number = 0;
		public var actualTotal : Number = 0;

		protected var numAnimator : TitleText;
		protected var totalAnimator : TitleText;

		public function DenominationListItem()
		{
			super();

			_width = 550;
			_height = 65;

		}

		override protected function createUI ( ) : void
		{
			super.createUI();

			addChild ( numAnimator = new TitleText() );
			numAnimator.move ( numField.x, numField.y );
			numAnimator.setSize ( numField.width, numField.height );
			numAnimator.measureSize = false;
			numAnimator.literalTextFormat = numField.defaultTextFormat;

			numField.visible = false;

			addChild ( totalAnimator = new TitleText() );
			totalAnimator.move ( totalField.x, totalField.y );
			totalAnimator.setSize ( totalField.width, totalField.height );
			totalAnimator.measureSize = false;
			totalAnimator.literalTextFormat = totalField.defaultTextFormat;

			totalField.visible = false;
		}

		public function updateValues ( update : Object ) : void
		{
			if ( !update.denomination ) update.denomination = data.denomination;
			_data = update;

			var different : Boolean = ( data.amount != actualNum ) || ( ( data.amount * ( data.denomination / 100 ) ) != actualTotal );

			actualNum = data.amount;
			actualTotal = data.amount * ( data.denomination / 100 );

			if ( different ) renderValues();
		}

		protected function renderValues ( ) : void
		{
			numField.text = Math.round ( actualNum ) + "";
			numAnimator.title = numField.text;

			totalField.text = renderDollarsAndCents ( Math.round ( actualNum ), data.denomination );
			totalAnimator.title = totalField.text;
		}

		protected function renderDollarsAndCents ( v : int, d : Number ) : String
		{
/*			if ( d >= 100 )
			{
				return "$" + ( actualNum * ( d / 100 ) );
			}else
			{
				var value : int = v * d;
				if ( value < 100 )
				{
					return value + "c";
				}else
				{*/
					return "$" + (( v * d ) / 100).toFixed(2);/*.replace(".00", "");
				}
			}
*/
		}

		override protected function render ( ) : void
		{
			if ( !data.hasOwnProperty ( "amount" ) ) data.amount = 0;
			refresh();
		}

		public function refresh ( ) : void
		{
			denomField.text = StringUtil.currencyLabelFunction ( data.denomination / 100 );
			renderValues();
		}

		override public function dispose ( ) : void
		{
			removeAllGestures();

		}

		public function animateOut ( ) : void
		{
			TweenMax.to ( this, 0.3, { x : -this.width - 100, ease : Quint.easeInOut, onComplete : DisplayUtil.remove, onCompleteParams : [ this ] } );
		}

	}
}