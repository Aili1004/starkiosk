package com.snepo.givv.cardbrowser.view.overlays
{	
	/**
	* @author Andrew Wright
	*/
	
	import com.snepo.givv.cardbrowser.view.controls.*;
	import com.snepo.givv.cardbrowser.view.core.*;
	import com.snepo.givv.cardbrowser.managers.*;
	import com.snepo.givv.cardbrowser.control.*;
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
	import flash.net.*;
			
	public class MarketPlaceOverlay extends Component implements IOverlay
	{
		
		public static const IDLE : String = "MarketPlaceOverlay.IDLE";
		public static const SEARCHING : String = "MarketPlaceOverlay.SEARCHING";
		public static const RESULTS : String = "MarketPlaceOverlay.RESULTS";

		protected var _state : String = IDLE;
		protected var serviceLoader : URLLoader;
		protected var titleAnimator : TitleText;
		protected var contentAnimator : TitleText;
		
		protected var lastBuffer : String = "";
		protected var list : List;
			
		public function MarketPlaceOverlay ( ) 
		{
			super();
			
			_width = 420;
			_height = 715;
		}

		public function onRequestClose ( ) : void
		{
			if ( state == SEARCHING ) cancelSearch();
		}

		public function get canClose ( ) : Boolean
		{
			return true;
		}
		
		override protected function createUI ( ) : void
		{
			super.createUI ( );

			titleField.text = model.host.loyaltyTitle;

			okBtn.label = "OK"
			okBtn.offFillColor = 0x6c8e17; // green
			okBtn.onLabelColor = 0xFFFFFF;
			okBtn.offLabelColor = 0xFFFFFF;
			okBtn.selected = false;
			okBtn.selectable = false;	
			okBtn.redraw();
			okBtn.applySelection();
			okBtn.addEventListener ( MouseEvent.MOUSE_DOWN, performOK );
			DisplayUtil.startPulse( okBtn );

			spinner.alpha = 0;
			spinner.visible = false;
			spinner.scaleX = 0;
			spinner.scaleY = 0;

			addChild ( contentAnimator = new TitleText() );
			contentAnimator.move ( 14, 150 );
			contentAnimator.setSize ( 400, 380 );
			contentAnimator.measureSize = false;
			contentAnimator.textProperties = { multiline : true, wordWrap : true };
			contentAnimator.literalTextFormat = contentField.getTextFormat();
			contentAnimator.title = '';

			addChild ( titleAnimator = new TitleText() );
			titleAnimator.move ( 14, 7 );
			titleAnimator.setSize ( 400, 55 );
			titleAnimator.measureSize = false;
			titleAnimator.textProperties = { multiline : true, wordWrap : true };
			titleAnimator.literalTextFormat = titleField.getTextFormat();
			titleAnimator.title = model.host.loyaltyTitle;
						
			titleField.visible = false;

			addChild ( list = new List ( TextDisplayBlock ) );
			list.move ( contentField.x, contentField.y - 80 );
			list.setSize ( contentField.width, contentField.height + 80 );
		}

		public function performScan ( buffer : String ) : void
		{
			if ( lastBuffer == buffer ) return;

			lastBuffer = buffer;

			TweenMax.killDelayedCallsTo ( performOK );

			state = SEARCHING;

			if ( serviceLoader ) cancelSearch();

			var endpoint : String = model.host.loyaltyEndpoint;
			var data : URLVariables = new URLVariables();
				data["swipe[card_number]"] = buffer;

			var request : URLRequest = new URLRequest( endpoint );
				request.method = URLRequestMethod.POST;
				request.data = data;

			serviceLoader = new URLLoader();
			serviceLoader.addEventListener ( Event.COMPLETE, onSwipeSuccess, false, 0 , true );
			serviceLoader.addEventListener ( IOErrorEvent.IO_ERROR, onSwipeError, false, 0 , true );
			serviceLoader.addEventListener ( SecurityErrorEvent.SECURITY_ERROR, onSwipeError, false, 0 , true );
			serviceLoader.load ( request );
		}

		protected function onSwipeSuccess ( evt : Event ) : void
		{
			var loader : URLLoader = evt.target as URLLoader;
			var response : Object = JSON.parse ( loader.data );

			trace ( "SUCCESS: " + loader.data );

			renderResponse ( response );

			state = IDLE;
		}

		protected function renderResponse ( response : Object ) : void
		{
			var i : int;
			var j : int;
			var printMessage : String = "{center}{emph_off}";
			var screenItems : Array = [];
			var lineItem : Object;

			for ( i = 0; i < response.header.length; i++ )
			{
				lineItem = response.header[i];
				screenItems.push ( lineItem );

				if ( lineItem.heading )
				{
					printMessage += "{emph_on}" + lineItem.heading + "{emph_off}{cr}";
				}

				if ( lineItem.body )
				{
					printMessage += lineItem.body + "{cr}";
				}

			}

			var hasPrintMessage : Boolean = false;

			if ( response.is_winner )
			{
				for ( i = 0; i < response.prizes.length; i++ )
				{
					for ( j = 0; j < response.prizes[i].screen_message.length; j++ )
					{
						lineItem = response.prizes[i].screen_message[j];
						screenItems.push ( lineItem );
					}

					if ( response.prizes[i].printout_message.length ) hasPrintMessage = true;

					for ( j = 0; j < response.prizes[i].printout_message.length; j++ )
					{
						lineItem = response.prizes[i].printout_message[j];
										
						if ( lineItem.heading )
						{
							printMessage += "{emph_on}" + lineItem.heading.replace(/\r\n/g, "{cr}") + "{emph_off}{cr}";
						}

						if ( lineItem.body )
						{
							printMessage += lineItem.body.replace(/\r\n/g, "{cr}") + "{cr}";
						}
					}
				}
			}

			for ( i = 0; i < response.footer.length; i++ )
			{
				lineItem = response.footer[i];
				screenItems.push ( lineItem );

				if ( lineItem.heading )
				{
					printMessage += "{emph_on}" + lineItem.heading + "{emph_off}{cr}";
				}

				if ( lineItem.body )
				{
					printMessage += lineItem.body + "{cr}";
				}

			}

			if ( printMessage.length && hasPrintMessage )
			{
				Controller.getInstance().printMessage ( printMessage );
			}

			list.dataProvider = screenItems;
			list.alpha = 0;

			TweenMax.to ( list, 1.0, { autoAlpha : 1, ease : Quint.easeInOut, delay : 0.5 } );
		}

		protected function onSwipeError ( evt : Event ) : void
		{
			state = IDLE;

			var loader : URLLoader = evt.target as URLLoader;
			trace ( "raw: " + loader.data );
			
			if ( loader.data.length )
			{
				try
				{
					var response : Object = JSON.parse ( loader.data );
					renderResponse ( response );
				}catch ( e : Error )
				{
					displayError ( "There was an error contacting the server. Please try again." );
				}
			}else
			{
				displayError ( "There was an error contacting the server. Please try again." );
			}

		}

		protected function displayMessage ( message : String ) : void
		{
			contentAnimator.title = message;

			TweenMax.delayedCall ( 15, performOK );
		}

		protected function displayError ( message : String ) : void
		{
			trace ( "Got Error from swipes: " + message );
			contentAnimator.title = message;

			TweenMax.delayedCall ( 5, performOK );
		}

		protected function performOK ( evt : MouseEvent = null ) : void
		{
			View.getInstance().modalOverlay.hide();
		}

		public function set state ( s : String ) : void
		{
			if ( state == s ) return;

			_state = s;
			applyState();
		}

		public function get state ( ) : String
		{
			return _state;
		}

		protected function applyState ( ) : void
		{
			switch ( state )
			{
				case IDLE :
				{
					TweenMax.to ( scanner, 0.4, { autoAlpha : 1, ease : Quint.easeOut } );
					TweenMax.to ( spinner, 0.4, { scaleX : 0, scaleY : 0, autoAlpha : 0, ease : Back.easeIn } )
					break;
				}

				case SEARCHING :
				{
					TweenMax.to ( scanner, 0.4, { autoAlpha : 0, ease : Quint.easeOut } )
					TweenMax.to ( spinner, 0.4, { scaleX : 1.75, scaleY : 1.75, autoAlpha : 1, ease : Back.easeOut } );
					break;
				}

				case RESULTS :
				{

					break;
				}
			}
		}

		protected function resetText ( ) : void
		{
			contentAnimator.title = '';
		}

		protected function cancelSearch ( ) : void
		{
			if ( serviceLoader ) 
			{
				serviceLoader.close();
				serviceLoader = null;
			}

		}
	}
}