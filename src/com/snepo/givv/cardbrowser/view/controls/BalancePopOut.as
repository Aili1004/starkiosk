package com.snepo.givv.cardbrowser.view.controls
{
	import com.snepo.givv.cardbrowser.view.core.*;
	import com.snepo.givv.cardbrowser.managers.*;
	import com.snepo.givv.cardbrowser.events.*;
	import com.snepo.givv.cardbrowser.model.*;
	import com.snepo.givv.cardbrowser.view.*;
	import com.snepo.givv.cardbrowser.util.*;

	import com.greensock.easing.*;
	import com.greensock.*;

	import flash.display.*;
	import flash.events.*;
	import flash.net.*;

	public class BalancePopOut extends Component
	{
		protected var _expanded : Boolean = false;
		protected var expandedX : Number;

		protected var _displayBalance : Number = 0;
		public var actualBalance : Number = 0;

		public function BalancePopOut ( )
		{
			super();

			expandedX = this.x;
			expanded = false;

			model.cart.addEventListener ( CartEvent.COMMISSION_APPLIED, updateBalance );
			model.cart.addEventListener ( CartEvent.ITEM_REMOVED, updateBalance );
			model.cart.addEventListener ( CartEvent.ITEM_ADDED, updateBalance );
			model.cart.addEventListener ( CartEvent.ITEM_UPDATED, updateBalance );
		}

		protected function updateBalance ( evt : CartEvent ) : void
		{
			update();
		}

		public function update ( ) : void
		{
			var type : String = "";

			switch ( model.cart.paymentMethod )
			{
				case CartModel.CARDS :
				{
					type = "Card balance";
					break;
				}

				case CartModel.COINS :
				{
					type = "Coin balance";
					break;
				}

				case CartModel.NOTES :
				{
					type = "Note balance";
					break;
				}
			}

			balanceTypeField.text = type;

			var total : Number = model.cart.cartHasReviewedItems ? model.cart.commissionedTotal : model.cart.commissionedEstimateTotal;

			actualBalance = model.user.applicableBalance - total;

			if ( actualBalance < 0 ) actualBalance = 0;

			TweenMax.to ( this, 0.5, { displayBalance : actualBalance, ease : Linear.easeNone, onComplete : enforceCorrectValue } );

			
		}

		public function get displayBalance ( ) : Number
		{
			return _displayBalance;
		}

		public function set displayBalance ( b : Number ) : void
		{
			_displayBalance = b;
			balanceField.text = StringUtil.currencyLabelFunction ( ( b ) );
		} 

		protected function enforceCorrectValue ( ) : void
		{
			balanceField.text = StringUtil.currencyLabelFunction ( ( this.actualBalance ) );
		}

		override protected function createUI ( ) : void
		{
			super.createUI ( );
		}

		public function set expanded ( e : Boolean ) : void
		{
			_expanded = e;
			applyExpansion();
		}

		public function get expanded ( ) : Boolean
		{
			return _expanded;
		}

		protected function applyExpansion ( ) : void
		{
			if ( expanded ) 
			{
				TweenMax.to ( this, 0.4, { x : expandedX, autoAlpha : 1, ease : Quint.easeInOut } )
			}else
			{
				TweenMax.to ( this, 0.4, { x : expandedX + this.width, autoAlpha : 0, ease : Quint.easeInOut } )
			}
		}

		override protected function render ( ) : void
		{
			update();
		}



	}

}