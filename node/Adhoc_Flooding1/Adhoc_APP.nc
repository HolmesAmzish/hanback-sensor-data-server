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

includes Adhoc_APP;

configuration Adhoc_APP { }
implementation
{
  components MainC, Adhoc_APPM
           	, new TimerMilliC() as Timer1, new TimerMilliC() as Timer2,new TimerMilliC() as Timer3,new TimerMilliC() as Timer4
          	, LedsC
           	, FloodingC as Route
	   		, BusyWaitMicroC
     		, RFID_ControlC;

  	Adhoc_APPM.RFID_Control -> RFID_ControlC;

  	Adhoc_APPM.Boot -> MainC; // 初始化组件
  	Adhoc_APPM.Leds -> LedsC; // Led灯控制组件
  	Adhoc_APPM.Timer1 -> Timer1; // 定时器控制组件
  	Adhoc_APPM.Timer2 -> Timer2; // 定时器控制组件
  	Adhoc_APPM.Timer3 -> Timer3; // 定时器控制组件
  	Adhoc_APPM.Timer4 -> Timer4; 
  	Adhoc_APPM.BusyWait ->BusyWaitMicroC;

  	Adhoc_APPM.RControl	-> Route;
  	Adhoc_APPM.Rout_Send  -> Route;
  	Adhoc_APPM.Rout_Receive -> Route;

  	// Sensors Components
  	components new SensirionSht11C(), new PhotoSensorC();
  	Adhoc_APPM.Read_Humi -> SensirionSht11C.Humidity;
  	Adhoc_APPM.Read_Temp -> SensirionSht11C.Temperature;
  	Adhoc_APPM.Read_Photo -> PhotoSensorC;

  	// Uart Components
  	components SCSuartDBGC;
  	components ActiveMessageC;
  	Adhoc_APPM.CommControl -> ActiveMessageC;
  	Adhoc_APPM.SCSuartSTD -> SCSuartDBGC;
  	Adhoc_APPM.SCSuartDBG -> SCSuartDBGC;
}
