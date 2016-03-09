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

	public class PaymentOptionOverlay extends Component implements IOverlay
	{
		public static const NOTES : String = "notes";
		public static const CARDS : String = "cards";
		public static const COINS : String = "coins";

		public var dismissReason : String;

		public function PaymentOptionOverlay ( )
		{
			super();

			_width = 440;
			_height = 725;
		}

		public function onRequestClose ( ) : void
		{

		}

		override public function get canShow ( ) : Boolean
		{
			if (model.host.paymentOption == HostModel.PAYMENT_OPTION_DISABLE_NOTES)
			{
				dismissReason = CARDS;
				dispatchEvent ( new Event ( Event.CLOSE ) );
				return false;
			}
			else if (model.host.paymentOption == HostModel.PAYMENT_OPTION_DISABLE_CARDS)
			{
				dismissReason = NOTES;
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

			footNote.visible = model.cart.minFee(CartModel.NOTES) > 0 || model.cart.minFee(CartModel.CARDS) > 0 ? true : false;
			notesBtn.useHtml = true;
			notesBtn.label = "<font size=\"30\">" + Environment.noteTitle + "</font>" +
											 (model.cart.minFee(CartModel.NOTES) > 0 || model.cart.minFee(CartModel.CARDS) > 0 ? "\n" + StringUtil.currencyLabelFunction( model.cart.minFee(CartModel.NOTES) ) + "* fee per card" : "");
			notesBtn.selected = false;
			notesBtn.selectable = false;
			notesBtn.redraw();
			notesBtn.applySelection();
			notesBtn.addEventListener ( MouseEvent.MOUSE_DOWN, closeOverlay, false, 0, true );

			cardsBtn.useHtml = true;
			cardsBtn.label = "<font size=\"30\">CARD</font>" +
											 (model.cart.minFee(CartModel.NOTES) > 0 || model.cart.minFee(CartModel.CARDS) > 0 ? "\n" + StringUtil.currencyLabelFunction( model.cart.minFee(CartModel.CARDS) ) + "* fee per card" : "");
			cardsBtn.selected = false;
			cardsBtn.selectable = false;
			cardsBtn.offFillColor = 0x6c8e17; // green
			cardsBtn.redraw();
			cardsBtn.applySelection();
			cardsBtn.addEventListener ( MouseEvent.MOUSE_DOWN, closeOverlay, false, 0, true );
			DisplayUtil.startPulse( cardsBtn );

			var values : Array = Environment.noteDenominations;

			for ( var i : int = 0; i < values.length; i++ )
			{
				var but : Button = getChildByName ( "b" + values[i] ) as Button;
					but.label = "";
					but.offFillColor = but.onFillColor = 0xADAFB2;
					but.applySelection();
					but.redraw();

				var iconType : Class = getDefinitionByName ( "Note" + values[i] + "Icon" ) as Class;
				var icon : MovieClip = new iconType() as MovieClip;
					icon.x = but.x + but.width / 2 - icon.width / 2;
					icon.y = but.y + but.height / 2 - icon.height / 2;

					addChild ( icon );
					but.mouseEnabled = false;
					but.visible = false;
			}

			if (model.host.disableAmex)
				amexLogo.visible = false;
		}

		protected function closeOverlay( evt : MouseEvent ) : void
		{
			View.getInstance().modalOverlay.hide();

			dismissReason = evt.currentTarget == notesBtn ? NOTES : CARDS;

			// TODO: Update this with a custom even that can provide details
			// as to the circumstances surrounding the closing of the window
			// E.g OK, Cancel, Submit, or whatever the case my be.

			dispatchEvent ( new Event ( Event.CLOSE ) );
		}

	}

}