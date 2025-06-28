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

#include "Adhoc_Route.h"

configuration FloodingC { 

  	provides interface StdControl;
  	provides interface AMSend as SendFromAPP;
  	provides interface Receive as RecvToAPP;

}implementation{

  	components FloodingM as RouteM
           	, new TimerMilliC()
	   		, RandomC
           	, ActiveMessageC as MAC
           	, new AMSenderC(RF_FLOODING_DATA)
           	, new AMReceiverC(RF_FLOODING_DATA);
  
  	StdControl  = RouteM;
  	SendFromAPP = RouteM;
  	RecvToAPP = RouteM;

  	RouteM.Timer  -> TimerMilliC;

  	RouteM.SeedInit -> RandomC;
  	RouteM.Random -> RandomC;

  	RouteM.CommControl -> MAC;
  	RouteM.SendToMAC -> AMSenderC;
  	RouteM.RecvFromMAC -> AMReceiverC;
}
