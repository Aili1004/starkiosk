package com.snepo.givv.cardbrowser.view.controls
{
	import com.snepo.givv.cardbrowser.view.core.*;
	import com.snepo.givv.cardbrowser.events.*;
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

	public class SmallCartItem extends Component implements IListItem
	{
		public static const DELETE_INTERACTION : String = "SmallCartItem.DELETE_INTERACTION";
		public static const EDIT_INTERACTION : String = "SmallCartItem.EDIT_INTERACTION";

		protected var icon : Bitmap;
		protected var contentHolder : Sprite;

		public function SmallCartItem()
		{
			super();

		}

		override protected function createUI ( ) : void
		{
			super.createUI ( );

			editBtn.label = "Edit";
			editBtn.icon = new EditIcon();
			editBtn.addEventListener ( MouseEvent.MOUSE_DOWN, notifyInteraction );

			contentHolder = new Sprite();
			for ( var i : int = numChildren - 1; i >= 0; i-- )
			{
				var object : DisplayObject = getChildAt ( i );
					object.x -= width / 2;
					object.y -= height / 2;
				contentHolder.addChildAt ( object, 0 );
			}

			imageHolder.mask = masker;

			addChild ( contentHolder );
			contentHolder.x = width / 2;
			contentHolder.y = height / 2;

		}

		override protected function render ( ) : void
		{
			dispose();

			imageHolder.addChild ( icon = new Bitmap ( ImageCache.getInstance().getThumb ( data.card.id ), PixelSnapping.AUTO, true ) );
			DisplayUtil.smooth ( icon );

			icon.width = 126;
			icon.height = 70;

			refresh();

			contentHolder.scaleX = contentHolder.scaleY = 0;
			TweenMax.to ( contentHolder, 0.4, { scaleX : 1, scaleY : 1, ease : Back.easeOut } );

		}

		public function animateOut ( ) : void
		{
			TweenMax.to ( contentHolder, 0.3, { scaleX : 0, scaleY : 0, ease : Back.easeIn, onComplete : DisplayUtil.remove, onCompleteParams : [ this ] } );
		}

		public function refresh() : void
		{
			if ( !data.isMax )
			{
				editBtn.label = "Edit";
				editBtn.icon = new EditIcon();
				editBtn.applySelection();
				editBtn.redraw();
			}else
			{
				editBtn.label = "Del.";
				editBtn.icon = new DeleteIcon();
				editBtn.offFillColor = 0xBD0000; // Red
				editBtn.applySelection();
				editBtn.redraw();
			}

			amountField.text = data.amount + " @ $" + ( data.perCard.toFixed ( 2 ).replace(".00", "") );
		}

		override public function dispose ( ) : void
		{
			DisplayUtil.disposeBitmap ( icon );
			DisplayUtil.remove ( icon );
		}

		protected function notifyInteraction ( evt : MouseEvent ) : void
		{
			if ( data.isMax )
			{
				dispatchEvent ( new ListEvent( ListEvent.ITEM_INTERACTION, this, {}, -1, editBtn, DELETE_INTERACTION ) );
			}else
			{
				dispatchEvent ( new ListEvent( ListEvent.ITEM_INTERACTION, this, {}, -1, editBtn, EDIT_INTERACTION ) );
			}
		}

	}
}
