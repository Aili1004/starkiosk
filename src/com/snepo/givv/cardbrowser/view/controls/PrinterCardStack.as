package com.snepo.givv.cardbrowser.view.controls
{	
	/**
	* @author Andrew Wright
	*/
	
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

	public class PrinterCardStack extends Component
	{
		protected var cards : Array = [];
		protected var _selectedIndex : int = -1;
		protected var _selectedCard : PrinterCard;

		public var offset : Rectangle;
		public var shown : Boolean = false;

		public function PrinterCardStack()
		{
			super();

			visible = false;
		}

		public function show ( ) : void
		{
			if ( shown ) return;
			this.shown = true;

			this.visible = true;
			this.alpha = 1;

			for ( var i : int = 0; i < cards.length; i++ )
			{
				var card : PrinterCard = cards[i] as PrinterCard;
				TweenMax.to ( card, 0.8, { x : card.targetX, y : card.targetY, scaleX : 1, scaleY : 1, ease : Back.easeOut, delay : i / 30 } );
			}

		}

		public function startStack() : void
		{
			dispatchEvent ( new Event ( Event.SELECT ) );
		}

		public function hide ( ) : void
		{
			TweenMax.to ( this, 1, { x : 500, autoAlpha : 0, ease : Quint.easeInOut } );
		}

		public function set selectedIndex ( s : int ) : void
		{
			_selectedIndex = s;
			_selectedCard = cards [ s ];

			_selectedCard.killGlow();

			TweenMax.to ( _selectedCard, 0.9, { x : 440, ease : Quint.easeInOut } );
		}

		public function get selectedIndex ( ) : int
		{
			return _selectedIndex;
		}

		public function get selectedCard ( ) : PrinterCard
		{
			return _selectedCard;
		}

		override public function dispose ( ) : void
		{
			for each ( var card : PrinterCard in cards )
			{
				card.dispose();
				card.destroy();
				card = null;
			}

			cards = [];
			_selectedCard = null;
		}

		override public function destroy ( ) : void
		{
			DisplayUtil.remove ( this );
		}

		public function completeCardAt ( index : int ) : void
		{
			var card : PrinterCard = cards [ index ];
			TweenMax.to ( card, 0.9, { x : 679, ease : Quint.easeInOut } );
			TweenMax.to ( card.filler, 0.9, { alpha : 0, ease : Quint.easeOut } );
		}

		override protected function render ( ) : void
		{
			for ( var i : int = 0; i < data.amount; i++ )
			{
				var card : PrinterCard = new PrinterCard();
					card.data = data;
					card.targetX = ( ( ( data.amount - 1 ) - i ) * 10 );
					card.targetY = 0;
					card.scaleX = card.scaleY = 0.6;

					card.x = offset.x;
					card.y = 300;

				addChild ( card );
				cards.push ( card );
			}
		}
				
	}
}