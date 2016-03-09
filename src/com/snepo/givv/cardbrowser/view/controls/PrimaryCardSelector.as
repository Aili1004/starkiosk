package com.snepo.givv.cardbrowser.view.controls
{
	import com.snepo.givv.cardbrowser.view.overlays.*;
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

	public class PrimaryCardSelector extends Component implements IOverlay
	{
		protected var optionList : Container;
		protected var options : Array = [];
		protected var _dataProvider : Array = [];

		protected var modal : Sprite;
		protected var _card : Object = null;
		protected var _cardValue : Number = 0;

		public var isSuperModal : Boolean = true;

		public function PrimaryCardSelector()
		{
			_width = 480;
			_height = 725;

			super();

			_width = 480;
			_height = 725;
		}

		public function get canClose ( ) : Boolean
		{
			return true;
		}

		public function onRequestClose ( ) : void
		{

		}

		override protected function createUI ( ) : void
		{
			super.createUI ( );

			addChild ( optionList = new Container() );
			optionList.padding = 0;
			optionList.verticalSpacing = 15;
			optionList.horizontalSpacing = 15;
			optionList.horizontalScrollEnabled = false;
			optionList.verticalScrollEnabled = false;
		}

		protected function handleSelectionOfCard ( evt : MouseEvent ) : void
		{
			var primaryCard : PrimaryCard = evt.currentTarget.parent as PrimaryCard;
			_card = primaryCard.data;
			_cardValue = model.user.applicableBalance - primaryCard.processingFee;
			dismiss();
		}

		protected function dismiss ( ) : void
		{
			View.getInstance().modalOverlay.hide();
			dispatchEvent ( new Event ( Event.CLOSE ) );
		}

		protected function createModal ( ) : void
		{
			addChildAt ( modal = new Sprite(), 0 );

			var g : Graphics = modal.graphics;
				g.clear();
				g.beginFill ( 0x000000, 0.6 );
				g.drawRect ( 0, 0, View.APP_WIDTH, View.APP_HEIGHT );
				g.endFill();

			modal.alpha = 0;

		}

		public function set dataProvider ( d : Array ) : void
		{
			_dataProvider = d;
			this.render();
		}

		public function get dataProvider ( ) : Array
		{
			return this._dataProvider;
		}

		public function get card () : Object
		{
			return _card;
		}

		public function get cardValue () : Number
		{
			return _cardValue;
		}

		override protected function render () : void
		{
			trace('CARDS = ' + dataProvider.length.toString())
			if (dataProvider.length > 3)
			{
				optionList.setSize ( 460, 700 );
				optionList.move ( 480 / 2 - 460 / 2, 120 );
				optionList.layoutStrategy = new GridFlowLayoutStrategy();
			}
			else
			{
				optionList.setSize ( 238, 700 );
				optionList.move ( 480 / 2 - 238 / 2, 90 );
				optionList.layoutStrategy = new VerticalLayoutStrategy(false);
			}

			for ( var i : int = 0; i < dataProvider.length; i++ )
			{
				var option : PrimaryCard = new PrimaryCard();
				option.addBtn.addEventListener ( MouseEvent.CLICK, handleSelectionOfCard, false, 0, true );
				option.data = dataProvider[i];

				options.push ( option );
				optionList.addChild ( option );
			}

			optionList.redraw();
		}

		override public function dispose():void
		{
			super.dispose();

			for ( var i : int = 0; i < options.length; i++ )
			{
				options[i].dispose();
			}

			options = [];

			DisplayUtil.remove ( this );
		}
	}
}