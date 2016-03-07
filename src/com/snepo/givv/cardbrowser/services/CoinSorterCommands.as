package com.snepo.givv.cardbrowser.services
{
	public class CoinSorterCommands
	{
		
		/* General Commands */
        public static const ConstructLink : int = 0x01;
        public static const ConstructLinkResponse : int = 0x02;
        public static const DestructLink : int = 0x03;
        public static const DestructLinkResponse : int = 0x04;
        public static const GetValue : int = 0x11;
        public static const GetValueResponse : int = 0x12;
        public static const SetValue : int = 0x21;
        public static const SetValueResponse : int = 0x22;
        public static const SetValueWithMotorStatus : int = 0x23;
        public static const SetValueWithMotorStatusResponse : int = 0x24;
        public static const GetDisplayContents : int = 0x31;
        public static const GetDisplayContentsResponse : int = 0x32;
        public static const SetDisplayContents : int = 0x33;
        //public static const SetDisplayContentsResponse;
        public static const SetKeyboardToStringInputMode : int = 0x35;
        public static const SetKeyboardToStringInputModeResponse : int = 0x36;
        public static const LockAndClearDisplay : int = 0x37;
        public static const LockAndClearDisplayResponse : int = 0x38;
        public static const LockKeyboard : int = 0x39;
        public static const LockKeyboardResponse : int = 0x3A;
        public static const ToggleMemoryLock : int = 0x3D;
        public static const ToggleMemoryLockResponse : int = 0x3E;
        public static const GetLastPressedKey : int = 0x53;
        public static const GetLastPressedKeyResponse : int = 0x54;
        public static const SetExternalDisplayProgramming : int = 0x71;
        public static const SetExternalDisplayProgrammingResponse : int = 0x72;
        public static const HeaderProgramming : int = 0x73;
        public static const HeaderProgrammingResponse : int = 0x74;
        public static const FooterProgramming : int = 0x75;
        public static const FooterProgrammingResponse : int = 0x76;
        public static const SetDisplayHeaderFooter : int = 0x77;
        public static const SetDisplayHeaderFooterResponse : int = 0x78
        
    	/* GetValue Commands */
        public static const GetSpecificBagContents : int = 0x10;
        public static const GetCurrentCountingResult : int = 0x16;
        public static const GetTotalCountingResult : int = 0x1C;
        public static const GetNumberOfFilledBags : int = 0x1D;
        public static const GetBagNumberAndCurrency : int = 0x1E;
        public static const GetCoinDenominations : int = 0x1F;
        public static const GetKeyboardBuffer : int = 0x21;
        public static const GetNumberOfSavedTransactions : int = 0x22;
        public static const GetTransactionData : int = 0x23;
        public static const GetSoftwareVersion : int = 0x31;
        public static const GetMachineStatus : int = 0x33;

        /* This one isn't from the ctcoin docs. I added it */
        public static const CountingFinalized : int = 0x99;


    	/* SetValue Commands */
        /* These are not command bytes; just used for managing state */
        public static const NoSetValueCommand : int = 0x0;
        public static const ResetTotals : int = 0x1;
        public static const ResetToCountingMode : int = 0x2;
        public static const CleanHopper : int = 0x3;
        public static const SimulatePrintToReset : int = 0x4
	}
}