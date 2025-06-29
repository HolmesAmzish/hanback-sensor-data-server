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

#ifndef _ADHOC_APP_H_
#define _ADHOC_APP_H_

#define Sink_Addr 9
#define SHT_Interval 4000
#define light_Interval 2000

#include "Adhoc_Route.h"

  	// Data Frame Structure for RF transmission //
  	typedef struct {
		uint16_t Temp;
		uint16_t Humi;
		uint16_t Photo;
		uint8_t FUN;
		// uint8_t ID[8];
		uint8_t Data[5];
	} __attribute__ ((packed)) DataFrameStruct;

  	//////////////////////////////
 	 // Data Frame Structure for UART transmission //
  	typedef struct {
		uint8_t  addr[2];
		uint8_t  type;
		uint8_t  group;
		uint8_t  length; // 32bytes
		uint16_t src;
		uint16_t dst1;
		uint16_t dst2;
		uint16_t dst3; // 13
		uint32_t seq; // 17 bytes
		uint16_t Temp;	
		uint16_t Humi;
		uint16_t Photo;	
		uint8_t FUN;	// 24
		// uint8_t ID[8];	// 32
		uint8_t Data[5]; // 37
		uint32_t Totalduration;
		uint32_t TXduration;
		uint32_t Sleepduration;
		uint16_t CRC;
  	} __attribute__ ((packed)) UartFrameStruct;

enum {SERIAL_ADHOC=10};

#endif
