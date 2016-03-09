package com.snepo.givv.cardbrowser.view.overlays
{
	import com.snepo.givv.cardbrowser.services.tokens.*;
	import com.snepo.givv.cardbrowser.services.events.*;
	import com.snepo.givv.cardbrowser.view.core.gesture.*;
	import com.snepo.givv.cardbrowser.view.controls.*;
	import com.snepo.givv.cardbrowser.view.core.*;
	import com.snepo.givv.cardbrowser.managers.*;
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

	public class WoolworthsEDROverlay extends Component implements IOverlay
	{
		protected var barcode : BarcodeManager;
		protected static var processingBarcode : Boolean = false;

		public function WoolworthsEDROverlay ( )
		{
			super();

			_width = 440;
			_height = 725;

			BarcodeManager.acceptingReads = true;
			barcode = BarcodeManager.getInstance();
		}

		override protected function createUI ( ) : void
		{
			super.createUI ( );

			skipBtn.label = "SKIP"
			skipBtn.offFillColor = 0x0E447F; // dark blue
			skipBtn.selected = false;
			skipBtn.selectable = false;
			skipBtn.redraw();
			skipBtn.applySelection();
			skipBtn.addEventListener ( MouseEvent.MOUSE_DOWN, closeOverlay, false, 0, true );
			if (model.host.transactionReferenceText.length > 0)
				promptField.htmlText = model.host.transactionReferenceText;
		}

		public function captureBarcode() : void
		{
			BarcodeManager.forceAccept = true;
			barcode.addEventListener ( BarcodeEvent.SCAN, handleInterruptScan, false, 100, true );
		}

		protected function handleInterruptScan ( evt : BarcodeEvent ) : void
		{
			if (processingBarcode)
				return;

			processingBarcode = true;

			evt.stopImmediatePropagation();
			evt.preventDefault();

			var buffer : String = evt.data as String;

			// TODO Add EDR validation

			model.cart.addTransactionReference ( { type : CartModel.REFERENCE_TYPE_WOOLWORTHS_EDR, data : buffer } );
			processingBarcode = false;
			closeOverlay(null);
		}

		public function onRequestClose ( ) : void
		{

		}

		public function get canClose ( ) : Boolean
		{
			return true;
		}

		override protected function initStageEvents ( evt : Event = null ) : void
		{
			super.initStageEvents ( evt );
		}

		override public function dispose ( ) : void
		{
			BarcodeManager.forceAccept = false;
			barcode.removeEventListener ( BarcodeEvent.SCAN, handleInterruptScan );
			super.dispose ( );
		}

		protected function closeOverlay( evt : MouseEvent ) : void
		{
			View.getInstance().modalOverlay.hide();
			dispatchEvent ( new Event ( Event.CLOSE ) );
		}

	}

}