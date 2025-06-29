/******************************************************************************/
/*                                                                            */
/*                       Copyright (c) HANBACK ELECTRONICS                    */
/*                              All rights reserved.                          */
/*                                                                            */
/*                             http://www.hanback.com                         */
/*                                                                            */
/******************************************************************************/

/******************************************************************************/
/*                                                                            */
/*============================================================================*/
/* Permission to use, copy, modify, and distribute this software and its      */
/* documentation are reserved by above authors and Hanback electronics.       */
/* The above copyright notice and authors must be described in this software. */
/*============================================================================*/
/*                                                                            */
/******************************************************************************/

includes RFID_Control;
configuration RFID_ControlC { 

  provides interface RFID_Control;

} implementation {

  components RFID_ControlM
           , HalCC2430SimpleUartC
	   , SCSuartDBGC;

  RFID_Control = RFID_ControlM;

  RFID_ControlM.HplUartInit -> HalCC2430SimpleUartC.Init;
  RFID_ControlM.HPLUART -> HalCC2430SimpleUartC.uart1;

  RFID_ControlM.SCSuartDBG -> SCSuartDBGC;

}
