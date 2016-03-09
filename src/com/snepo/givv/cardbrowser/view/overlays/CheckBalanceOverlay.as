﻿package com.snepo.givv.cardbrowser.view.overlays{	import com.snepo.givv.cardbrowser.view.core.gesture.*;	import com.snepo.givv.cardbrowser.services.pinpad.*;	import com.snepo.givv.cardbrowser.services.events.*;	import com.snepo.givv.cardbrowser.services.tokens.*;	import com.snepo.givv.cardbrowser.view.controls.*;	import com.snepo.givv.cardbrowser.view.core.*;	import com.snepo.givv.cardbrowser.managers.*;	import com.snepo.givv.cardbrowser.events.*;	import com.snepo.givv.cardbrowser.view.*;	import com.snepo.givv.cardbrowser.util.*;	import com.greensock.easing.*;	import com.greensock.*;	import flash.display.*;	import flash.filters.*;	import flash.events.*;	import flash.geom.*;	import flash.text.*;	import flash.ui.*;	public class CheckBalanceOverlay extends Component implements IOverlay	{		public static const CARD : String = "CheckBalanceOverlay.CARD";		public static const USER : String = "CheckBalanceOverlay.USER";		protected var image : Bitmap;		protected var imageHolder : Sprite;		protected var imageMasker : Sprite;		public var mode : String = CARD;		public function CheckBalanceOverlay ( )		{			super();			_width = 440;			_height = 725;		}		override protected function createUI ( ) : void		{			super.createUI ( );			addChild ( imageHolder = new Sprite() );			imageHolder.addChild ( imageMasker = new Sprite() );			cancelBtn.label = "OK"			cancelBtn.selected = false;			cancelBtn.selectable = false;			cancelBtn.offFillColor = 0x6c8e17; // green			cancelBtn.redraw();			cancelBtn.applySelection();			cancelBtn.addEventListener ( MouseEvent.MOUSE_DOWN, closeOverlay, false, 0, true );			DisplayUtil.startPulse(cancelBtn);		}		public function onRequestClose ( ) : void		{		}		public function get canClose ( ) : Boolean		{			return true;		}		override public function dispose ( ) : void		{			DisplayUtil.disposeBitmap ( image );			image = null;		}		override protected function render ( ) : void		{			if ( data.mobile.text().length() > 0 )			{				titleField.text = "Your account balance";			}else			{				titleField.text = "Your card balance";			}			balanceBox.balanceField.text = StringUtil.currencyLabelFunction ( data.card.balance.text() );			imageHolder.addChild ( image = new Bitmap ( ImageCache.getInstance().getImage ( (data.card.productid.text() + ""), 1), PixelSnapping.AUTO, true ) ) ;			// Default yellow bitmap;			if ( image.height == 10 )			{				image.visible = false;				balanceBox.y = 150;			}			var g : Graphics = imageMasker.graphics;				g.clear();				g.beginFill ( 0x000000, 1 );				g.drawRoundRectComplex ( 0, 0, image.width, image.height, 15, 15, 15, 15 );				g.endFill();			image.mask = imageMasker;			imageHolder.x = (View.getInstance().modalOverlay.currentContent.width / 2) - (imageHolder.width / 2);			imageHolder.y = 85;		}		protected function closeOverlay( evt : MouseEvent ) : void		{			View.getInstance().modalOverlay.hide();		}	}}