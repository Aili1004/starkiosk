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

	public class NotePaymentNoticeOverlay extends Component implements IOverlay
	{
		public static const NOTES : String    = "notes";
		public static const CARDS : String    = "cards";

		public var dismissReason : String;

		public function NotePaymentNoticeOverlay ( )
		{
			super();

			_width = 440;
			_height = 725;
		}

		public function onRequestClose ( ) : void
		{

		}

		public function get canClose ( ) : Boolean
		{
			return true;
		}

		override protected function createUI ( ) : void
		{
			super.createUI ( );

			if (model.cart.minFee(CartModel.NOTES) == 0)
			{
				perCardFeeText.text = ""
				processingFeeText.text = "\n\nIf you would like to pay by card\n" +
								     						 "then select Pay By Card\n";
				footNote.visible = false;
			}
			else
			{
				perCardFeeText.text = StringUtil.currencyLabelFunction( model.cart.minFee(CartModel.NOTES) ) + "* per card";
				processingFeeText.text = "Please note a processing fee of\n\n\n\n" +
						                     "applies to note payments\n\n" +
														     "Select Continue to review the fees\n\n" +
								     						 "If you would like to pay by card\n" +
								     						 "then select Pay By Card\n" +
								     						 " (" + StringUtil.currencyLabelFunction( model.cart.minFee(CartModel.CARDS ) ) + "* per card)";
				footNote.visible = true;
			};
			continueBtn.useHtml = true;
			continueBtn.label = "CONTINUE";
			continueBtn.selected = false;
			continueBtn.selectable = false;
			continueBtn.offFillColor = 0x6c8e17; // green
			continueBtn.redraw();
			continueBtn.applySelection();
			continueBtn.addEventListener ( MouseEvent.MOUSE_DOWN, closeOverlay, false, 0, true );
			if (model.host.paymentOption == HostModel.PAYMENT_OPTION_DISABLE_CARDS)
			{
				var overlay : ModalOverlay = View.getInstance().modalOverlay;
				cardsBtn.visible = false;
				continueBtn.x = (overlay.currentContent.width / 2) - (cardsBtn.width / 2);
			}
			else
			{
				cardsBtn.useHtml = true;
				cardsBtn.label = "PAY BY CARD";
				cardsBtn.selected = false;
				cardsBtn.selectable = false;
				cardsBtn.offFillColor = 0xBD0000; // red
				cardsBtn.redraw();
				cardsBtn.applySelection();
				cardsBtn.addEventListener ( MouseEvent.MOUSE_DOWN, closeOverlay, false, 0, true );
			}
			DisplayUtil.startPulse( continueBtn );
		}

		protected function closeOverlay( evt : MouseEvent ) : void
		{
			View.getInstance().modalOverlay.hide();
			dismissReason = evt.currentTarget == continueBtn ? NOTES : CARDS;
			dispatchEvent ( new Event ( Event.CLOSE ) );
		}
	}
}
