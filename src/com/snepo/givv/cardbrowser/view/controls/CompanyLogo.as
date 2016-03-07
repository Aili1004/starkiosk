package com.snepo.givv.cardbrowser.view.controls
{

	import com.snepo.givv.cardbrowser.view.core.gesture.*;
	import com.snepo.givv.cardbrowser.view.controls.*;
	import com.snepo.givv.cardbrowser.view.core.*;
	import com.snepo.givv.cardbrowser.managers.*;
	import com.snepo.givv.cardbrowser.control.*;
	import com.snepo.givv.cardbrowser.events.*;
	import com.snepo.givv.cardbrowser.model.*;
	import com.snepo.givv.cardbrowser.view.*;
	import com.snepo.givv.cardbrowser.util.*;

	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.net.*;

	public class CompanyLogo extends Component
	{
    	public function CompanyLogo()
		{
			super();

			_width = 205;
			_height = 153;

			buttonMode = true;
			addEventListener ( MouseEvent.CLICK, goHome );
		}

		protected function goHome ( evt : MouseEvent ) : void
		{
			if ( model.user.hasUser && model.cart.paymentMethod == CartModel.COINS )
			{
				var alert : Alert = Alert.show ( { title : "Are you sure?", message : "Pressing OK will end your current session.\nPress CANCEL to continue to redeem your exchange.", buttons : [ "OK", "CANCEL" ] } );
				alert.addEventListener ( AlertEvent.DISMISS, handleConfirmQuitDismiss, false, 0, true );

				var view : View = View.getInstance();
				view.addChild ( alert );
			}
			else
			{
				Controller.getInstance().reset();
			}
		}

		protected function handleConfirmQuitDismiss ( evt : AlertEvent ) : void
		{
			if ( evt.reason == "OK" )
			{
				Controller.getInstance().reset();
			}
		}

		override protected function initStageEvents ( evt : Event = null ) : void
		{
			super.initStageEvents ( evt );

		//	addGesture ( new Gesture ( Gesture.SWIPE_RIGHT, this, 0.3, showLogger ) );
		//	addGesture ( new Gesture ( Gesture.SWIPE_DOWN, this, 0.3, testErrorHandling ) );
		}

		protected function testErrorHandling ( g : Gesture ) : void
		{
			var codes : Array = [ "100", "101", "102" ];
			var code : String = codes [ Math.floor ( Math.random() * codes.length ) ];

			View.getInstance().addChild ( Alert.show ( ErrorManager.getInstance().getErrorByCode ( code ) ) );
		}

		protected function showLogger ( g : Gesture ) : void
		{
			Logger.show();
		}
	}

}