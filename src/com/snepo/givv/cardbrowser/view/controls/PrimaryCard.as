package com.snepo.givv.cardbrowser.view.controls
{
	import com.snepo.givv.cardbrowser.view.core.*;
	import com.snepo.givv.cardbrowser.model.*;
	import com.snepo.givv.cardbrowser.view.*;
	import com.snepo.givv.cardbrowser.util.*;

	import com.greensock.easing.*;
	import com.greensock.*;

	import flash.filters.*;
	import flash.display.*;
	import flash.events.*;
	import flash.net.*;

	public class PrimaryCard extends Component
	{

		protected var _imageMask : Sprite;
		protected var _image : Bitmap;
		protected var _holder : Sprite;
		protected var _hideButton : Boolean;

		protected var _processingFee : Number = 0;
		protected var _maxValue : Number = 0;

		public function PrimaryCard( hideButton : Boolean = false )
		{
			_hideButton = hideButton;
			super();
			_width = 221;
			_height = 210;
		}

		override protected function createUI ( ) : void
		{
			super.createUI ( );

			addChild ( _imageMask = new Sprite() );
			addChild ( _holder = new Sprite() );

			_holder.addChild ( commissionOverlay );

			addBtn.label = "ADD"
			addBtn.selected = false;
			addBtn.selectable = false;
			addBtn.redraw();
			addBtn.applySelection();
			if (_hideButton)
				addBtn.visible = false;
		}

		protected function feesAndCommissionsPromptFunction ( card : Object ) : String
		{
			var model : Model = Model.getInstance();

			var feesText : String;

			var totalBalance : Number = model.user.applicableBalance;

			_maxValue = model.partners.getMaxValueForBalanceWithCommission ( card.partnerID, model.cart.paymentMethod, totalBalance );
			_processingFee = totalBalance - _maxValue;

			if ( _maxValue < 0 ) _maxValue = 0;

			var total :Number = ( _maxValue + _processingFee );

			var ok : Boolean = total <= totalBalance;

			addBtn.enabled = ok;

			if ( _processingFee == 0 )
			{
				return "";
			}else
			{
				return "Exchange fee: " + StringUtil.currencyLabelFunction ( _processingFee );
			}
		}

		override protected function render ( ) : void
		{
			dispose();

			_holder.addChild ( _image = new Bitmap ( ImageCache.getInstance().getImage ( data.id, 140 / 215 ), PixelSnapping.AUTO, true ) );

			commissionOverlay.commissionText.text = feesAndCommissionsPromptFunction ( data );
			if (commissionOverlay.commissionText.text.length == 0)
				commissionOverlay.visible = false;

			DisplayUtil.smooth ( _image );

			DisplayUtil.top ( commissionOverlay );

			drawMask();
		}

		protected function drawMask ( ) : void
		{
			var g : Graphics = _imageMask.graphics;
				g.clear();
				g.beginFill ( 0xFF0000, 0.5 );
				g.drawRoundRectComplex ( 0, 0, _image.width, _image.height, 10, 10, 10, 10 );
				g.endFill();

			_imageMask.x = _image.x;
			_imageMask.y = _image.y;
			_holder.mask = _imageMask;
		}

		public function get processingFee ( ) : Number
		{
			return _processingFee;
		}

		override public function dispose ( ) : void
		{
			DisplayUtil.disposeBitmap ( _image );

			_image = null;
		}

		override public function destroy ( ) : void
		{
			DisplayUtil.remove ( this );
		}
	}
}