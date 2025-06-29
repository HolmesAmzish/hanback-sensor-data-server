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

#ifndef _ADHOC_ROUTE_H_
#define _ADHOC_ROUTE_H_

#include "Adhoc_APP.h"

#define MAX_Forward_Buff 5
#define Default_TTL	5
#define MAX_RTABLE 30
#define UnknownAddr 0xFFFE

// FrameControl values
#define Hello_BySink		1
#define Hello_ByNode		2
#define GeneralDataFrame	4
#define ForwardDataFrame	5

typedef struct {
	uint16_t FrameControl;
    uint16_t FinalDstAddr;
	uint16_t OrigiSrcAddr;
	uint8_t  Sequence;
	uint8_t  TTL;
	uint16_t Dst2_for_multihop;
	uint16_t Dst3_for_multihop; // 12
	uint8_t  AppData[15];
} __attribute__ ((packed)) Route_Msg;

typedef struct {
	uint16_t FrameControl;
	uint16_t OrigiSrcAddr;
	uint16_t HopNum_from_Sink;
} __attribute__ ((packed)) Hello_Frame;

typedef struct{
    uint16_t FinalDstAddr;
	uint16_t OrigiSrcAddr;
	uint8_t  Sequence;
} __attribute__ ((packed)) Route_Table;

typedef struct {
	uint16_t Naddr;
	uint16_t HopNum_from_Sink;
	char  RSSI;
	uint8_t  LQI;
	uint16_t Insert_time; //second
} __attribute__ ((packed)) NeighborTable;

enum{RF_FLOODING_DATA=11, RF_GOSSIPING_DATA=12, RF_TREE_DATA=13, RF_HELLO_FRAME=14};

#endif
