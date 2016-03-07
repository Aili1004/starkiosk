package com.snepo.givv.cardbrowser.view.overlays
{
	import com.snepo.givv.cardbrowser.view.controls.*;
	import com.snepo.givv.cardbrowser.view.core.*;
	import com.snepo.givv.cardbrowser.events.*;
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

	public class GenericMessageOverlay extends Component implements IOverlay
	{
		public static const OK : String = "ok";
		public static const CANCEL : String = "cancel";

		public var textFormat : TextFormat;
		public var dismissReason : String = OK;

		public function GenericMessageOverlay ( )
		{
			super();

			_width = 440;
			_height = 725;
		}

		public function get defaultTF ( ) : TextFormat
		{
			return contentField.getTextFormat();
		}

		public function set defaultTF ( tf : TextFormat ) : void
		{
			contentField.defaultTextFormat = tf;
			contentField.setTextFormat ( tf )
		}

		override protected function render ( ) : void
		{
			titleField.text = data.title || "";
			titleField.width = this.width - 30;
			titleField.height = titleField.textHeight + 20;
			titleField.x = width / 2 - titleField.width / 2;

			contentField.y = titleField.y + titleField.height + 10;
			contentField.text = data.message || "";
			contentField.width = this.width - 60;
			contentField.height = contentField.textHeight + 20;

			if ( contentField.height > ( ( okBtn.y - 5 ) - contentField.y ) ) contentField.height = ( okBtn.y - 5 ) - contentField.y;

			contentField.x = width / 2 - contentField.width / 2;

			okBtn.redraw();
			okBtn.applySelection();

			cancelBtn.redraw();
			cancelBtn.applySelection();

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

			okBtn.label = "OK"
			okBtn.selected = false;
			okBtn.selectable = false;
			okBtn.offFillColor = 0x6c8e17; // green
			okBtn.redraw();
			okBtn.applySelection();
			okBtn.addEventListener ( MouseEvent.MOUSE_DOWN, closeOverlay, false, 0, true );
			DisplayUtil.startPulse( okBtn );

			cancelBtn.label = "CANCEL"
			cancelBtn.offFillColor = 0xBD0000; //red
			cancelBtn.onLabelColor = 0xFFFFFF;
			cancelBtn.offLabelColor = 0xFFFFFF;
			cancelBtn.selected = false;
			cancelBtn.selectable = false;
			cancelBtn.redraw();
			cancelBtn.applySelection();
			cancelBtn.addEventListener ( MouseEvent.MOUSE_DOWN, closeOverlay, false, 0, true );

			cancelBtn.visible = false;
		}

		public function showCancelBtn ( ) : void
		{
			cancelBtn.visible = true;
		}

		protected function closeOverlay( evt : MouseEvent ) : void
		{
			View.getInstance().modalOverlay.hide();

			this.dismissReason = evt.currentTarget == okBtn ? OK : CANCEL;

			// TODO: Update this with a custom even that can provide details
			// as to the circumstances surrounding the closing of the window
			// E.g OK, Cancel, Submit, or whatever the case my be.

			dispatchEvent ( new Event ( Event.CLOSE ) );
		}
	}
}