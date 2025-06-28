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

interface RFID_Control {
	command void start();
	async command void GetID_14443A();
	async command void GetID_15693 ();
	async command void RData_15693 (char BlockAddr);
	async command void WData_15693 (char BlockAddr, char *buff, char size);

	async event void GetID_14443A_Done(char status, uint8_t *buff, char size);
	async event void GetID_15693_Done (char status, uint8_t *buff, char size);
	async event void RData_15693_Done (char status, uint8_t *buff, char size);
	async event void WData_15693_Done (char status);
}

