package com.snepo.givv.cardbrowser.errors
{	
	/**
	* @author Andrew Wright
	*/
	
	public class SingletonError extends Error
	{
		public function SingletonError ( offender : String  )
		{
			super( "Do not instantiate " + offender + " directly. Use " + offender + ".getInstance() instead." );
		}

	}
}