package com.snepo.givv.cardbrowser.view.overlays
{
	import com.snepo.givv.cardbrowser.view.controls.*;
	import com.snepo.givv.cardbrowser.view.screens.*;
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
	import flash.geom.*;
	import flash.text.*;
	import flash.ui.*;

	public class CoinTermsOverlay extends Component implements IOverlay
	{
		public static const OK : String = "ok";
		public static const CANCEL : String = "cancel";

		public var dismissReason : String = OK;
		public var textFormat : TextFormat;
		public var isSuperModal : Boolean = true;

		protected var _enableButtons : Boolean;

		public function CoinTermsOverlay ( enableButtons : Boolean = false )
		{
			_width = 425;
			_height = 725;
			_enableButtons = enableButtons;
			super();
		}

		override protected function createUI ( ) : void
		{
			if (model.host.coinTerms.length > 0)
				contentField.htmlText = StringUtil.replaceKeys(model.host.coinTerms,{min_cart_value : model.host.minCartValue});
			else
				contentField.htmlText = StringUtil.replaceKeys("<font size=\"30\"> An exchange fee applies</font>" +
																											 (model.host.minCartValue > 0 ? "<br/><br/><font size=\"30\">    Minimum Deposit $${min_cart_value}</font><br/><br/><br/><ul><li>Deposits of less than $${min_cart_value} will be donated to The Salvation Army</li>" :
																											 	                              "<br/><br/><br/><ul>") +
																											 	"<li>Coin deposits are non-retrievable</li><li>Australian coins only</li></ul>" +
																											 	"       (all other coins will be rejected)<br/><ul><li>No damaged or dirty coins</li></ul>",
					                                             {min_cart_value : model.host.minCartValue});
			okBtn.enabled = false;
			okBtn.label = "I AGREE"
			okBtn.selected = false;
			okBtn.selectable = false;
			okBtn.offFillColor = 0x6c8e17; // Green
			okBtn.redraw();
			okBtn.applySelection();
			okBtn.addEventListener ( MouseEvent.MOUSE_DOWN, closeOverlay, false, 0, true );

			cancelBtn.enabled = false;
			cancelBtn.label = "I DISAGREE"
			cancelBtn.offFillColor = 0xBD0000; // Red
			cancelBtn.onLabelColor = 0xFFFFFF;
			cancelBtn.offLabelColor = 0xFFFFFF;
			cancelBtn.selected = false;
			cancelBtn.selectable = false;
			cancelBtn.redraw();
			cancelBtn.applySelection();
			cancelBtn.addEventListener ( MouseEvent.MOUSE_DOWN, closeOverlay, false, 0, true );

			spinner.visible = true;

			if (_enableButtons)
				enableButtons();
		}

		protected function closeOverlay( evt : MouseEvent ) : void
		{
			View.getInstance().modalOverlay.hide();

			this.dismissReason = evt.currentTarget == okBtn ? OK : CANCEL;

			dispatchEvent ( new Event ( Event.CLOSE ) );
		}

		public function enableButtons() : void
		{
			spinner.visible = false;
			okBtn.enabled = true
			cancelBtn.enabled = true;
			DisplayUtil.startPulse( okBtn );
		}

		public function onRequestClose ( ) : void
		{

		}

		public function get canClose ( ) : Boolean
		{
			return true;
		}
	}
}