package com.snepo.givv.cardbrowser.view.controls
{
	import com.snepo.givv.cardbrowser.view.core.*;
	import com.snepo.givv.cardbrowser.managers.*;
	import com.snepo.givv.cardbrowser.events.*;
	import com.snepo.givv.cardbrowser.model.*;
	import com.snepo.givv.cardbrowser.view.*;
	import com.snepo.givv.cardbrowser.util.*;

	import com.greensock.easing.*;
	import com.greensock.*;

	import flash.display.*;
	import flash.events.*;
	import flash.net.*;

	public class Alert extends Component
	{
		protected static var stageReference : Stage;

		public static function init ( stageRef : Stage ) : void
		{
			stageReference = stageRef;
		}

		protected var modal : Sprite;
		protected var panel : Sprite;
		protected var content : AlertContent;
		protected var buttons : ButtonBar;
		protected var panelHolder : Sprite;
		public var customContent : MovieClip;

   	public function Alert()
		{
			super();
		}

		public static function show ( data : Object ) : Alert
		{
			var alert : Alert = new Alert();
				alert.setSize ( 400, 250 );
				alert.data = data;

			return alert;
		}

		override protected function createUI () : void
		{
			super.createUI ( );
			createModal();

			addChild ( panelHolder = new Sprite() );
					   panelHolder.x = View.APP_WIDTH / 2;
					   panelHolder.y = View.APP_HEIGHT / 2;

			panelHolder.addChild ( panel = new Sprite() );
			panelHolder.addChild ( content = new AlertContent() );
			content.addChild ( buttons = new ButtonBar() );

		}

		override protected function render ( ) : void
		{
			var maxWidth : Number = 500;
			var maxHeight : Number = View.APP_HEIGHT - 20;

			var title : String = data.title || "";
			var message : String = data.message || "";
			var useHtml : Boolean = data.useHtml || false;
			var buttonLabels : Array = data.buttons || [];
			var delay : Number = data.delay || 0;
			var autoDismissTime : int = data.autoDismissTime || 0;

			content.titleField.text = title;
			content.titleField.width = content.titleField.textWidth + 5;
			if ( content.titleField.width > maxWidth ) content.titleField.width = maxWidth;
			content.titleField.height = content.titleField.textHeight + 5;

			content.contentField.width = maxWidth;
			if (useHtml)
				content.contentField.htmlText = message;
			else
				content.contentField.text = message;
			content.contentField.width = content.contentField.textWidth + 5;
			if ( content.contentField.width > maxWidth ) content.contentField.width = maxWidth;
			if ( content.contentField.height > maxHeight - 150 ) content.contentField.height = maxHeight - 150;
			content.contentField.height = content.contentField.textHeight + 5;
			content.contentField.y = content.titleField.y + content.titleField.height + 5;

			var largestWidth : Number = content.titleField.width > content.contentField.width ? content.titleField.width : content.contentField.width;

			buttons.selectable = false;
			buttons.setSize ( largestWidth, 50 );
			buttons.dataProvider = buttonLabels;
			buttons.width = buttons.content.width;
			buttons.addEventListener ( Event.CHANGE, forwardDismissEvent, false, 0, true );
			buttons.y = content.contentField.y + content.contentField.height + 20;

			if ( buttonLabels.length < 1 ) content.removeChild ( buttons );

			if ( buttons.width > largestWidth ) largestWidth = buttons.width;

			var packedHeight : Number = content.height + 60;
			if ( packedHeight > maxHeight ) packedHeight = maxHeight;

			setSize ( largestWidth + 60, packedHeight );
			content.x = -content.width / 2;
			content.y = -content.height / 2;

			panelHolder.scaleX = panelHolder.scaleY = 0;

			TweenMax.to ( modal, 0.4, { alpha : 1, delay : delay } );
			TweenMax.to ( panelHolder, 0.3, { scaleX : 1, scaleY : 1, ease : Back.easeOut, delay : delay + 0.1 } );

			if ( autoDismissTime != 0 )
			{
				TweenMax.delayedCall ( autoDismissTime, forwardDismissEvent, [ null, "TIMEOUT"] );
			}
		}

		public function addContent ( c : MovieClip, fitContent : Boolean = true ) : void
		{
			panel.addChild ( customContent = c );

			if ( fitContent )
			{
				c.x = 25;
				c.y = 25;
				width = c.width + 50;
				height = c.height + 120;

				buttons.x = c.x;
				buttons.width = c.width;
				buttons.y = c.y + c.height + 20;
			}else
			{
				c.x = 25;
				c.y = content.contentField.y + content.contentField.height + 10;

				var maxWidth : Number = content.contentField.width > c.width ? content.contentField.width + 30 : c.width + 30;

				buttons.x = c.x;
				buttons.width = maxWidth - 30;
				buttons.y = c.y + c.height + 20;

				width = maxWidth;
				height = content.contentField.y + c.y + c.height + buttons.y + buttons.height + 30;

			}
			panel.addChild ( buttons );
		}

		public static function createMessageAlert ( message : String ) : Alert
		{
			var content : MovieClip = new ModalMessage();
				content.messageField.text = message;
				content.messageField.width = content.messageField.textWidth + 5;
				content.messageField.height = content.messageField.textHeight + 5;

			var alert : Alert = new Alert();
				alert.data = {};
				alert.addContent ( content );

			return alert;

		}

		protected function forwardDismissEvent ( evt : Event = null, forceLabel : String = null ) : void
		{
			TweenMax.killDelayedCallsTo ( forwardDismissEvent );

			try
			{
				var label : String = forceLabel && buttons.buttons.length ? forceLabel : buttons.buttons [ buttons.selectedIndex ].label;

				if ( data.isError ) handleError ( buttons.buttons [ buttons.selectedIndex ].data );
			}catch ( e : Error )
			{
				label = "";
			}

			dispatchEvent ( new AlertEvent ( AlertEvent.DISMISS, {}, label ) );

			dismiss();
		}

		protected function handleError ( action : Object ) : void
		{
			if ( action ) ActionManager.performAction ( action );
		}

		public function dismiss ( ) : void
		{
			TweenMax.to ( panelHolder, 0.3, { scaleX : 0, scaleY : 0, ease : Back.easeIn } );
			TweenMax.to ( modal, 0.3, { alpha : 0, ease : Back.easeIn, delay : 0.1, onComplete : destroy } );
		}

		override protected function invalidate ( ) : void
		{
			super.invalidate ( );

			if ( !panel ) return;

			var g : Graphics = panel.graphics;
				g.clear();
				g.beginFill ( 0x000000, 1 );
				g.drawRoundRectComplex ( 0, 0, width, height, 20, 20, 20, 20 );
				g.endFill();

			panel.x = -panel.width / 2;
			panel.y = -panel.height / 2;
		}

		protected function createModal ( ) : void
		{
			addChild ( modal = new Sprite() );

			var g : Graphics = modal.graphics;
				g.clear();
				g.beginFill ( 0x000000, 0.6 );
				g.drawRect ( 0, 0, View.APP_WIDTH, View.APP_HEIGHT );
				g.endFill();

			modal.alpha = 0;

		}


	}

}