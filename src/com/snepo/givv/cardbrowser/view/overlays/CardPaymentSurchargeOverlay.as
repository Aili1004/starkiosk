package com.snepo.givv.cardbrowser.view.overlays
{
	import com.snepo.givv.cardbrowser.view.controls.*;
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
	import flash.ui.*;

	public class CardPaymentSurchargeOverlay extends Component implements IOverlay
	{
		public static const NONE : String   			= 'none';
		public static const EFTPOS : String  			= 'eftpos';
		public static const MASTERCARD : String  	= HostModel.TXN_FEE_TYPE_MASTERCARD;
		public static const VISA : String  				= HostModel.TXN_FEE_TYPE_VISA;
		public static const AMEX : String 		 		= HostModel.TXN_FEE_TYPE_AMEX;

		protected var _cardType : String;

		public function CardPaymentSurchargeOverlay ( )
		{
			super();

			_width = 440;
			_height = 725;
			_cardType = NONE;
		}

		public function onRequestClose ( ) : void
		{

		}

		override public function get canShow ( ) : Boolean
		{
			if (!model.host.hasCardSurcharge)
			{
				dispatchEvent ( new Event ( Event.CLOSE ) );
				return false;
			}
			else
				return true;
		}

		public function get canClose ( ) : Boolean
		{
			return true;
		}

		override protected function createUI ( ) : void
		{
			super.createUI ( );

			eftposBtn.useHtml = true;
			eftposBtn.label = "<font size=\"60\">\n</font>" +
											  "No surcharge";
			eftposBtn.selected = false;
			eftposBtn.selectable = false;
			eftposBtn.redraw();
			eftposBtn.applySelection();
			eftposBtn.addEventListener ( MouseEvent.MOUSE_DOWN, closeOverlay, false, 0, true );

			mastercardBtn.useHtml = true;
			mastercardBtn.label = "<font size=\"60\">\n</font>" +
											 			(model.host.transactionFees.hasOwnProperty(HostModel.TXN_FEE_TYPE_MASTERCARD) ? model.host.transactionFees.master.percentage.toString()+"%" : "No") +
														" surcharge";
			mastercardBtn.selected = false;
			mastercardBtn.selectable = false;
			mastercardBtn.redraw();
			mastercardBtn.applySelection();
			mastercardBtn.addEventListener ( MouseEvent.MOUSE_DOWN, closeOverlay, false, 0, true );

			visaBtn.useHtml = true;
			visaBtn.label = "<font size=\"60\">\n</font>" +
											(model.host.transactionFees.hasOwnProperty(HostModel.TXN_FEE_TYPE_VISA) ? model.host.transactionFees.visa.percentage.toString()+"%" : "No") +
										 	" surcharge";
			visaBtn.selected = false;
			visaBtn.selectable = false;
			visaBtn.redraw();
			visaBtn.applySelection();
			visaBtn.addEventListener ( MouseEvent.MOUSE_DOWN, closeOverlay, false, 0, true );

			if (model.host.disableAmex)
			{
				amexBtn.visible = false;
				amexLogo.visible = false;
			}
			else
			{
				amexBtn.useHtml = true;
				amexBtn.label = "<font size=\"60\">\n</font>" +
												(model.host.transactionFees.hasOwnProperty(HostModel.TXN_FEE_TYPE_AMEX) ? model.host.transactionFees.american_express.percentage.toString()+"%" : "No") +
												" surcharge";
				amexBtn.selected = false;
				amexBtn.selectable = false;
				amexBtn.redraw();
				amexBtn.applySelection();
				amexBtn.addEventListener ( MouseEvent.MOUSE_DOWN, closeOverlay, false, 0, true );
				amexLogo.addEventListener ( MouseEvent.MOUSE_DOWN, closeOverlay, false, 0, true );
			}
		}

		protected function closeOverlay( evt : MouseEvent ) : void
		{
			View.getInstance().modalOverlay.hide();

			var transactionFee : Object = null;
			switch (evt.currentTarget)
			{
				case eftposBtn:
				{
					_cardType = EFTPOS;
					break;
				}
				case mastercardBtn:
				{
					_cardType = MASTERCARD;
					if (model.host.transactionFees.hasOwnProperty(HostModel.TXN_FEE_TYPE_MASTERCARD))
						transactionFee = model.host.transactionFees.master;
					break;
				};
				case visaBtn:
				{
					_cardType = VISA;
					if (model.host.transactionFees.hasOwnProperty(HostModel.TXN_FEE_TYPE_VISA))
						transactionFee = model.host.transactionFees.visa;
					break;
				}
				case amexBtn:
				case amexLogo:
				{
					_cardType = AMEX;
					if (model.host.transactionFees.hasOwnProperty(HostModel.TXN_FEE_TYPE_AMEX))
						transactionFee = model.host.transactionFees.american_express;
					break;
				}
			}

			if (transactionFee != null)
				model.cart.addTransactionFee( {feeType : _cardType, description : transactionFee.description, percentage : transactionFee.percentage, cost : 0.0} )
			model.cart.cardTypeSelected = _cardType;

			dispatchEvent ( new Event ( Event.CLOSE ) );
		}

		public function get cardType ( ) : String
		{
			return _cardType;
		}
	}

}