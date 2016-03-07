package com.snepo.givv.cardbrowser.util
{	
	import com.snepo.givv.cardbrowser.managers.*;
	
	public function $ ( path : String ) : *
	{
		return ConfigManager.get ( path );
	}
}