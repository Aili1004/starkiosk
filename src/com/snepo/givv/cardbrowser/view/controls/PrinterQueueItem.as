package com.snepo.givv.cardbrowser.view.controls
{
	import com.snepo.givv.cardbrowser.view.core.*;
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
	import flash.net.*;

	public class PrinterQueueItem extends Component implements IListItem
	{
		public static const IDLE : String = "PrinterQueueItem.IDLE";
		public static const PROCESSING : String = "PrinterQueueItem.PROCESSING";
		public static const COMPLETE : String = "PrinterQueueItem.COMPLETE";

		protected var icon : Bitmap;
		protected var _hash : String;

		protected var _state : String;
		protected var tickIcon : MovieClip;
		protected var spinIcon : MovieClip;

		public function PrinterQueueItem()
		{
			super();
		}

		override protected function createUI ( ) : void
		{
			super.createUI ( );

			addChild ( tickIcon = new TickIcon() );
			tickIcon.alpha = 0;
			tickIcon.scaleX = tickIcon.scaleY = 0;
			tickIcon.visible = false;
			tickIcon.filters = [ new GlowFilter ( 0x000000, 1, 3, 3 ) ];

			addChild ( spinIcon = new SpinnerIcon() );
			spinIcon.alpha = 0;
			spinIcon.scaleX = spinIcon.scaleY = 0;
			spinIcon.visible = false;
			spinIcon.filters = [ new GlowFilter ( 0x000000, 1, 3, 3 ) ];

			state = IDLE;

			invalidate();
		}

		override protected function render ( ) : void
		{
			dispose();

			_hash = data.card.id + "_" + Math.round ( Number ( data.adjustedPerCard ) );
	//		if ( data.transactionID && data.card.processas == CardModel.SCANNABLE ) _hash = data.card.id + "_" + data.transactionID;

			imageHolder.addChild ( icon = new Bitmap ( ImageCache.getInstance().getThumb ( data.card.id ), PixelSnapping.AUTO, true ) ) ;
			DisplayUtil.smooth ( icon );
			icon.width = 126;
			icon.height = 70;

			icon.alpha = 0;
			TweenMax.to ( icon, 0.7, { alpha : 1 } );

			refresh();

		}

		public function get hash ( ) : String
		{
			return _hash;
		}

		public function set state ( s : String ) : void
		{
			if ( state == s ) return;

			_state = s;

			applyState();
		}

		public function get state ( ) : String
		{
			return _state;
		}

		protected function applyState ( ) : void
		{
			switch ( state )
			{
				case IDLE :
				{
					TweenMax.to ( this, 0.3, { alpha : 0.5 } );
					TweenMax.to ( amountField, 0.3, { tint : 0x000000 } );
					break;
				}

				case PROCESSING :
				{
					TweenMax.to ( this, 0.3, { alpha : 1 } );
					TweenMax.to ( amountField, 0.3, { tint : 0xFFFFFF } );

					TweenMax.to ( spinIcon, 0.3, { autoAlpha : 1, scaleX : 1, scaleY : 1, ease : Back.easeOut } );
					startSpinning();

					break;
				}

				case COMPLETE :
				{
					stopSpinning();
					TweenMax.to ( this, 1, { alpha : 0.5 } );
					TweenMax.to ( tickIcon, 1, { autoAlpha : 1, scaleX : 1, scaleY : 1, ease : Back.easeOut } );
					break;
				}
			}
		}

		protected function startSpinning ( ) : void
		{
			TweenMax.to ( spinIcon, 0.7, { rotation : "180", ease : Back.easeOut } );
			TweenMax.delayedCall ( 1, startSpinning );
		}

		protected function stopSpinning ( ) : void
		{
			TweenMax.killTweensOf ( spinIcon );
			TweenMax.killDelayedCallsTo ( startSpinning );
			TweenMax.to ( spinIcon, 0.3, { autoAlpha : 0, scaleX : 0, scaleY : 0, ease : Back.easeIn } );

		}

		public function refresh() : void
		{
			amountField.text = data.amount + " @ $" + data.adjustedPerCard.toFixed(2).replace(".00", "");
		}

		override public function dispose ( ) : void
		{
			DisplayUtil.disposeBitmap ( icon );
			DisplayUtil.remove ( icon );

			icon = null;
		}

		override protected function invalidate ( ) : void
		{
			super.invalidate();
			if ( tickIcon )
			{
				tickIcon.x = width / 2;
				tickIcon.y = height / 2 - 10;

				spinIcon.x = width / 2;
				spinIcon.y = height / 2 - 12;
			}
		}
	}
}
