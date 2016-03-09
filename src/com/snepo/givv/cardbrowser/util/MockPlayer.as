package com.snepo.givv.cardbrowser.util
{
	import com.greensock.*;

	import flash.events.*;
	import flash.utils.*;

	public class MockPlayer
	{
		protected var target : Object;
		protected var steps : Array = [];
		protected var currentStep : int = 0;

    	public function MockPlayer( target )
		{
			this.target = target;  
		}

		public function add ( method : Function, ...args ) : MockPlayer
		{
			steps.push ( { method : method, args : args, delay : 0 } );
			return this;
		}

		public function after ( delay : Number ) : MockPlayer
		{
			var lastStep : Object = steps [ steps.length - 1 ];
				
			if ( steps.length > 1 )
			{
				lastStep.delay = steps[steps.length - 2].delay + delay;
			}else
			{
				lastStep.delay = delay;
			}

			if ( lastStep )
			{
				TweenMax.delayedCall ( lastStep.delay, performStep, [ lastStep ] );
			}

			return this;
		}


		public function then ( method : Function, ...args ) : MockPlayer
		{
			return add ( method, args );
		}

		protected function performStep ( step : Object ) : void
		{
			currentStep = steps.indexOf ( step );
			step.method.apply ( target, step.args );
		}

		protected function addDelays ( ) : Number
		{
			var total : Number = 0;
			
			for ( var i : int = 0; i < steps.length; i++ )
			{
				total += steps[i].delay;
			}

			return total;
		}
	}

}