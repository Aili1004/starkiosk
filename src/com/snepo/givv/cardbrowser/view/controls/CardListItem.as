package com.snepo.givv.cardbrowser.view.controls
{
	import com.snepo.givv.cardbrowser.view.core.gesture.*;
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

	public class CardListItem extends Component implements IListItem
	{
		public static const HELP_INTERACTION : String = "CardListItem.HELP_INTERACTION";
		public static const EDIT_INTERACTION : String   = "CardListItem.EDIT_INTERACTION"  ;
		public static const DELETE_INTERACTION : String = "CardListItem.DELETE_INTERACTION";

		protected var icon : Bitmap;
		protected var _hasCommission : Boolean = false;
		protected var _hasError : Boolean = false;

		public function CardListItem()
		{
			super();

			_width = 937;
			_height = 72; //72;
		}

		protected function set buttonState ( s : String ) : void
		{

			this.applyButtonState();
		}



		protected function applyButtonState ( ) : void
		{

		}

		override protected function createUI () : void
		{

		}

		override protected function initStageEvents ( evt : Event = null ) : void
		{
			super.initStageEvents ( evt );
			addGesture ( new Gesture ( Gesture.SWIPE_RIGHT, this, 0.2, onSwipeGesture, 90 ) );
		}

		protected function onSwipeGesture ( g : Gesture ) : void
		{
			if ( hasCommission ) return;
			if ( data.hasError ) return;
			if ( data.isMax ) return;

		}

		override protected function render ( ) : void
		{
			dispose();

			refresh();

		}

		public function refresh ( ) : void
		{
			_hasError = data.hasError;

			nameField.text = data.card.name;
			nameField.x = 80;
			nameField.y = 50;

			numField.text = "x " + data.amount;
			numField.x = View.APP_WIDTH / 3 + 20;
			numField.y = 50;

			var perCard : Number = data.perCard;
			if ( data.hasAdjustedValue )
				perCard = data.adjustedPerCard;

			if ( !data.hasError )
			{
				if ( data.hasAdjustedValue )
				{
					hasCommission = true;
					renderCommission ( );
				}else
				{
					hasCommission = false;
					renderCommission ( true );
				}
			}else
			{
				hasCommission = false;
				renderError ( data.errorObject );
			}

		}

		public function get hasError ( ) : Boolean
		{
			return _hasError;
		}

		protected function renderError ( error : Object ) : void
		{

			this.height = 120;
			TweenMax.delayedCall ( 0.05, notifyManualResize );
		}

		public function set hasCommission ( h : Boolean ) : void
		{
			_hasCommission = h;

			if ( h )
			{
				this.height = 120;
				TweenMax.delayedCall ( 0.05, notifyManualResize );
			}else
			{
				this.height = 120;
				TweenMax.delayedCall ( 0.05, notifyManualResize );
			}
		}

		public function get hasCommission ( ) : Boolean
		{
			return _hasCommission;
		}

		protected function renderCommission ( estimate : Boolean = false ) : void
		{

			var processingFee : Number;

			if ( estimate )
			{
				var commPrice : Number = model.partners.getCommissionedPrice ( data.card.partnerID, Model.getInstance().cart.paymentMethod, { price : data.perCard } );
				processingFee = ( data.amount * commPrice ) - ( data.amount * data.perCard );
			}else
			{
				trace('Commission adjustment: amount=' + data.amount.toString() + ', adjustedvalue=' + data.adjustedValue + ', adjustedpercard=' + data.adjustedPerCard)
				processingFee = ( data.amount * data.adjustedValue ) - ( data.amount * data.adjustedPerCard );
			}
		}

		override public function dispose ( ) : void
		{
			removeAllGestures();

			DisplayUtil.disposeBitmap ( icon );
			DisplayUtil.remove ( icon );
		}

		public function animateOut ( ) : void
		{
			TweenMax.to ( this, 0.3, { x : -this.width - 100, ease : Quint.easeInOut, onComplete : DisplayUtil.remove, onCompleteParams : [ this ] } );
		}

		protected function notifyManualResize ( ) : void
		{
			dispatchEvent ( new Event ( Event.RESIZE ) );
		}

		override protected function invalidate ( ) : void
		{
			super.invalidate();

			hitBox.height = height;
		}
	}
}
