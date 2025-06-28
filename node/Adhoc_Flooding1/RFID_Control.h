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

#ifndef RFID_CONTROL_H
#define RFID_CONTROL_H

#include <stdio.h>

#define RFID_SUCCESS 0
#define RFID_FAIL 1
#define RFID_START_SUCCESS 2
#define RFID_START_FAIL 3
#define RFID_MEM_FAIL 4
#define RFID_BUSY 5


#define RFID14443A_UID_INDEX 6
#define RFID14443A_UID_SIZE	15

#define RFID15693_UID_INDEX	10
#define RFID15693_UID_SIZE	8

#define RFID_ACK_INDEX	3
#define RFID_ACK_SUCC	0

#define RFID15693_Read_Block_Index	6

#define Sink_Addr 9

typedef struct {
	uint8_t comm;
	uint8_t block;
	uint8_t reserved1; 
	uint8_t reserved2; 
	uint8_t wbuff[4];
}RFID_COMM_MSG;

typedef struct {
	uint16_t SendAddress;
	uint8_t  RFID_CMD_Type;
	uint8_t  RFID_CMD_SUCCESS_FAIL;
	uint8_t  RFID_Data[10];
}RFID_DATA_MSG;

enum {CMD_GetID_14443A=1, CMD_GetID_15693=2, CMD_RData_15693=3, CMD_WData_15693=4};
enum {RFID_MSG=7};

#endif
