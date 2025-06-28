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

module RFID_ControlM {
  provides interface RFID_Control;

  uses {
	interface Init as HplUartInit;
	interface SerialByteComm as HPLUART;
	interface SCSuartDBG;
  }

}implementation{

  void UARTSend (uint8_t* data, uint8_t len);
  void processing_recvData();
  void gen15693crc(uint8_t* data, uint8_t len, uint8_t* byte1, uint8_t* byte2);

  #define IDLE_UART	0
  #define BUSY_UART	1
  #define buff_len	128

  norace bool state = IDLE_UART;
  norace uint8_t str_buff[buff_len];
  norace uint16_t buff_start = 0;
  norace uint16_t buff_end = 0;

  norace char StartComm14443[9] = {0x02, 0x07, 0xF1, 0x33, 0x48, 0x80, 0x02, 0x0F, 0x03};
  norace char GetID14443[5] = {0x02, 0x03, 0x6B, 0x68, 0x03};
  norace char StartComm15693[9] = {0x02, 0x07, 0xF1, 0x33, 0xEB, 0x80, 0x02, 0xAC, 0x03};
  norace char GetID15693[11] = {0x02, 0x09, 0x81, 0x08, 0x26, 0x01, 0x00, 0xF6, 0x0A, 0x5B, 0x03};
  norace char ReadData15693[12] = {0x02, 0x0A, 0x88, 0x38, 0x02, 0x23, 0x00, 0x00, 0xF7, 0x29, 0x45, 0x03};
  norace char WriteData15693[17] = {0x02, 0x0F, 0x90, 0x18, 0x00, 0x11, 0x02, 0x21, 0x00, 0x10, 0x11, 0x11, 0x11, 0x29, 0xAB, 0x36, 0x03};
  norace char SetMemoryAsscess[10] = {0x02, 0x08, 0xF2, 0x08, 0x33, 0xEB, 0x80, 0x02, 0xA8, 0x03};

  norace uint8_t RFID_State;
  norace uint8_t RFID_CardType = 0;

  enum {RFID_NULL, RFID14443A_GETID, RFID15693_GETID, RFID15693_RDATA, RFID15693_WDATA
	, RFID14443A_GETID_START, RFID15693_GETID_START, RFID15693_RDATA_START, RFID15693_WDATA_START
	, RFID15693_RDATA_MEM, RFID15693_WDATA_MEM};

  #define RFID_14443A_TYPE 1
  #define RFID_15693_TYPE  2

  #define RFID_MAX_BUFF 32
  #define RFID_Write_MAX 4

  norace uint8_t RFID_Write_Buff[RFID_MAX_BUFF];
  norace uint8_t RFID_Write_Buff_Size;
  
  norace uint8_t RecvBuff_From_RFID[RFID_MAX_BUFF];
  norace uint8_t RBuff_Index;
  norace uint8_t CheckSum_Index;

  norace uint8_t UID15693[10][RFID15693_UID_SIZE];
  norace uint8_t UID15693Index = 0;


  norace uint8_t debug1F = 0xF1;
  norace uint8_t debug2F = 0xF2;
  norace uint8_t debug3F = 0xF2;
  norace uint8_t debug4F = 0xF3;

  norace uint8_t debug1S = 0xF4;
  norace uint8_t debug2S = 0xF5;
  norace uint8_t debug3S = 0xF6;
  norace uint8_t debug4S = 0xF7;

  command void RFID_Control.start()
  {
  	char Temp_StartComm14443[9] = {0x02, 0x07, 0xF1, 0x33, 0x48, 0x80, 0x02, 0x0F, 0x03};
	char Temp_GetID14443[5] = {0x02, 0x03, 0x6B, 0x68, 0x03};
	char Temp_StartComm15693[9] = {0x02, 0x07, 0xF1, 0x33, 0xEB, 0x80, 0x02, 0xAC, 0x03};
	char Temp_GetID15693[11] = {0x02, 0x09, 0x81, 0x08, 0x26, 0x01, 0x00, 0xF6, 0x0A, 0x5B, 0x03};
	char Temp_ReadData15693[12] = {0x02, 0x0A, 0x88, 0x38, 0x02, 0x23, 0x00, 0x00, 0xF7, 0x29, 0x45, 0x03};
	char Temp_WriteData15693[17] = {0x02, 0x0F, 0x90, 0x18, 0x00, 0x11, 0x02, 0x21, 0x00, 0x10, 0x11, 0x11, 0x11, 0x29, 0xAB, 0x36, 0x03};
	char Temp_SetMemoryAsscess[10] = {0x02, 0x08, 0xF2, 0x08, 0x33, 0xEB, 0x80, 0x02, 0xA8, 0x03};

	memcpy(StartComm14443, Temp_StartComm14443, 9);
	memcpy(GetID14443, Temp_GetID14443, 5);
	memcpy(StartComm15693, Temp_StartComm15693, 9);
	memcpy(GetID15693, Temp_GetID15693, 11);
	memcpy(ReadData15693, Temp_ReadData15693, 12);
	memcpy(WriteData15693, Temp_WriteData15693, 17);
	memcpy(SetMemoryAsscess, Temp_SetMemoryAsscess, 10);

	state = IDLE_UART;
	buff_start = 0;
	buff_end = 0;
  
	RFID_CardType = 0;
	UID15693Index = 0;

	debug1F = 0xF1;
	debug2F = 0xF2;
	debug3F = 0xF2;
	debug4F = 0xF3;

	debug1S = 0xF4;
	debug2S = 0xF5;
	debug3S = 0xF6;
	debug4S = 0xF7;
	//call HplUartInit.init();
	
	//call SCSuartDBG.UARTSend(&debug1F, 1);
	//call SCSuartDBG.UARTSend(StartComm15693, 9);
	//call SCSuartDBG.UARTSend(&debug2F, 1);
  }

  async command void RFID_Control.GetID_14443A()
  {
	atomic {
		if (RFID_CardType == RFID_14443A_TYPE) {
			RFID_State = RFID14443A_GETID;
			RBuff_Index = 0;
			UARTSend (GetID14443, 5);
		}else{
			RFID_State = RFID14443A_GETID_START;
			RBuff_Index = 0;
			UARTSend (StartComm14443, 9);
		}
	}
  }

  async command void RFID_Control.GetID_15693 ()
  {
 	atomic {
		if (RFID_CardType == RFID_15693_TYPE) {
			RBuff_Index = 0;
			RFID_State = RFID15693_GETID;
			UID15693Index = 0;
			UARTSend (GetID15693, 11);
		}else{
			RFID_State = RFID15693_GETID_START;
			RBuff_Index = 0;
			UARTSend (StartComm15693, 9);
		}
	} 
  }

  async command void RFID_Control.RData_15693 (char BlockAddr)
  {
  	atomic {
		uint8_t i, Check_Sum_ = 0, CrcL, CrcH;;

		ReadData15693[RFID15693_Read_Block_Index] = BlockAddr;
		gen15693crc(ReadData15693+4, 4, &CrcL, &CrcH);
		ReadData15693[8] = CrcL;
		ReadData15693[9] = CrcH;
		for (i=1 ; i<10 ; i++)
			Check_Sum_ = Check_Sum_ ^ ReadData15693[i];
		ReadData15693[10] = Check_Sum_;

		if (RFID_CardType == RFID_15693_TYPE) {
			RBuff_Index = 0;
			RFID_State = RFID15693_RDATA_MEM;
			UARTSend (SetMemoryAsscess, 10);
		}else{
			RFID_State = RFID15693_RDATA_START;
			RBuff_Index = 0;
			UARTSend (StartComm15693, 9);
		}
	}
  }

  async command void RFID_Control.WData_15693 (char BlockAddr, char *buff, char size)
  {
  	atomic {
		uint8_t i, Check_Sum_ = 0, CrcL, CrcH;

		RFID_Write_Buff[0] = 0x02;
		RFID_Write_Buff[1] = 0x0F;
		RFID_Write_Buff[2] = 0x90;
		RFID_Write_Buff[3] = 0x18;
		RFID_Write_Buff[4] = 0x00;
		RFID_Write_Buff[5] = 0x11;
		RFID_Write_Buff[6] = 0x02;
		RFID_Write_Buff[7] = 0x21;
		RFID_Write_Buff[8] = BlockAddr;
		for (i=9 ; i<13 ; i++)
			RFID_Write_Buff[i] = (uint8_t) buff[i-9];

		gen15693crc(RFID_Write_Buff+6, 7, &CrcL, &CrcH);
		RFID_Write_Buff[i++] = CrcL; //crc
		RFID_Write_Buff[i++] = CrcH; //crc
		RFID_Write_Buff_Size = i;

		for (i=1 ; i<RFID_Write_Buff_Size ; i++)
			Check_Sum_ = Check_Sum_ ^ RFID_Write_Buff[i];
		RFID_Write_Buff[i++] = Check_Sum_;
		RFID_Write_Buff[i++] = 0x03;
		RFID_Write_Buff_Size = i;

		if (RFID_CardType == RFID_15693_TYPE) {
			RBuff_Index = 0;
			RFID_State = RFID15693_WDATA_MEM;
			UARTSend (SetMemoryAsscess, 10);
		}else{
			RFID_State = RFID15693_WDATA_START;
			RBuff_Index = 0;
			UARTSend (StartComm15693, 9);
		}
	}
  }

  async event void HPLUART.get(uint8_t data) {
	atomic{
		if(RBuff_Index == 0){
			if (data == 0x02){
				RecvBuff_From_RFID[RBuff_Index++] = data;
				//call SCSuartDBG.UARTSend(&data, 1);
			}
		}else{
			if(RBuff_Index == 1)
				CheckSum_Index = data;

			RecvBuff_From_RFID[RBuff_Index++] = data;
			//call SCSuartDBG.UARTSend(&data, 1);

			if(CheckSum_Index+2 == RBuff_Index)
				processing_recvData();
		}
	}
  }

  void processing_recvData() {
	atomic {
		RBuff_Index = 0;
		switch(RFID_State) {
			//Starting Command
			case RFID14443A_GETID_START:
				if(RecvBuff_From_RFID[RFID_ACK_INDEX]==RFID_ACK_SUCC){ //sucess
					RFID_CardType = RFID_14443A_TYPE;
					RFID_State = RFID14443A_GETID;
					UARTSend (GetID14443, 5);
				}else{
					RFID_CardType = 0;
					RFID_State = RFID_NULL;
					//call SCSuartDBG.UARTSend(&debug1F, 1);
					signal RFID_Control.GetID_14443A_Done(RFID_START_FAIL, NULL, 0);
				}
				break;

			case RFID15693_GETID_START:
				if(RecvBuff_From_RFID[RFID_ACK_INDEX]==RFID_ACK_SUCC){ //sucess
					RFID_CardType = RFID_15693_TYPE;
					RFID_State = RFID15693_GETID;
					UID15693Index = 0;
					UARTSend (GetID15693, 11);
				}else{
					RFID_CardType = 0;
					RFID_State = RFID_NULL;
					//call SCSuartDBG.UARTSend(&debug2F, 1);
					signal RFID_Control.GetID_15693_Done(RFID_START_FAIL, NULL, 0);
				}
				break;

			case RFID15693_RDATA_START:
				if(RecvBuff_From_RFID[RFID_ACK_INDEX]==RFID_ACK_SUCC){ //sucess
					RFID_CardType = RFID_15693_TYPE;
					RFID_State = RFID15693_RDATA_MEM;
					UARTSend (SetMemoryAsscess, 10);
				}else{
					RFID_CardType = 0;
					RFID_State = RFID_NULL;
					//call SCSuartDBG.UARTSend(&debug3F, 1);
					signal RFID_Control.RData_15693_Done(RFID_START_FAIL, NULL, 0);
				}
				break;
			
			case RFID15693_WDATA_START:
				if(RecvBuff_From_RFID[RFID_ACK_INDEX]==RFID_ACK_SUCC){ //sucess
					RFID_CardType = RFID_15693_TYPE;
					RFID_State = RFID15693_WDATA_MEM;
					UARTSend (SetMemoryAsscess, 10);
				}else{
					RFID_CardType = 0;
					RFID_State = RFID_NULL;
					//call SCSuartDBG.UARTSend(&debug4F, 1);
					signal RFID_Control.WData_15693_Done(RFID_START_FAIL);
				}
				break;

			// memory setting

			case RFID15693_RDATA_MEM:
				if(RecvBuff_From_RFID[RFID_ACK_INDEX]==RFID_ACK_SUCC){ //sucess
					RFID_CardType = RFID_15693_TYPE;
					RFID_State = RFID15693_RDATA;
					UARTSend (ReadData15693, 12);
				}else{
					RFID_CardType = 0;
					RFID_State = RFID_NULL;
					signal RFID_Control.RData_15693_Done(RFID_MEM_FAIL, NULL, 0);
				}
				break;

			case RFID15693_WDATA_MEM:
				if(RecvBuff_From_RFID[RFID_ACK_INDEX]==RFID_ACK_SUCC){ //sucess
					RFID_CardType = RFID_15693_TYPE;
					RFID_State = RFID15693_WDATA;
					UARTSend (RFID_Write_Buff, RFID_Write_Buff_Size);
				}else{
					RFID_CardType = 0;
					RFID_State = RFID_NULL;
					signal RFID_Control.WData_15693_Done(RFID_MEM_FAIL);
				}
				break;


			//Processing Command

			case RFID14443A_GETID:
				RFID_State = RFID_NULL;
				if(RecvBuff_From_RFID[RFID_ACK_INDEX]==RFID_ACK_SUCC) {//sucess
					//call SCSuartDBG.UARTSend(&debug1S, 1);
					signal RFID_Control.GetID_14443A_Done(RFID_SUCCESS, 
						RecvBuff_From_RFID + RFID14443A_UID_INDEX, RFID14443A_UID_SIZE);
				}else{
					//call SCSuartDBG.UARTSend(&debug1F, 1);
					signal RFID_Control.GetID_14443A_Done(RFID_FAIL, NULL, 0);
				}
				break;

			case RFID15693_GETID:
				if(RecvBuff_From_RFID[RFID_ACK_INDEX]==RFID_ACK_SUCC && UID15693Index<10){ //sucess
					uint8_t i;
					atomic { 
					  for (i=0 ; i<RFID15693_UID_SIZE ; i++)
						UID15693[UID15693Index][i] = RecvBuff_From_RFID[RFID15693_UID_INDEX+RFID15693_UID_SIZE-i-1];
					  UID15693Index++;
					}
					//call SCSuartDBG.UARTSend(&debug2S, 1);
				}else if (RecvBuff_From_RFID[RFID_ACK_INDEX]==0xFE) {
					if(UID15693Index>0)
						signal RFID_Control.GetID_15693_Done(RFID_SUCCESS, UID15693[0], UID15693Index);
					else
						signal RFID_Control.GetID_15693_Done(RFID_FAIL, NULL, 0);
					RFID_State = RFID_NULL; //finish getID from multiple cards
					UID15693Index = 0;

				}else{
					//call SCSuartDBG.UARTSend(&debug2F, 1);
					signal RFID_Control.GetID_15693_Done(RFID_FAIL, NULL, 0);
					UID15693Index = 0;

				}
				break;

			case RFID15693_RDATA:
				RFID_State = RFID_NULL;
				if(RecvBuff_From_RFID[RFID_ACK_INDEX]==RFID_ACK_SUCC) { //sucess
					//call SCSuartDBG.UARTSend(&debug3S, 1);
					signal RFID_Control.RData_15693_Done(RFID_SUCCESS, RecvBuff_From_RFID+4, 5);
				}else{
					//call SCSuartDBG.UARTSend(&debug3F, 1);
					signal RFID_Control.RData_15693_Done(RFID_FAIL, NULL, 0);
				}
				break;
			
			case RFID15693_WDATA:
				RFID_State = RFID_NULL;
				if(RecvBuff_From_RFID[RFID_ACK_INDEX]==RFID_ACK_SUCC) { //sucess
					//call SCSuartDBG.UARTSend(&debug4S, 1);
					signal RFID_Control.WData_15693_Done(RFID_SUCCESS);
				}else{
					//call SCSuartDBG.UARTSend(&debug4F, 1);
					signal RFID_Control.WData_15693_Done(RFID_FAIL);
				}
				break;	
			
			default:
				break;
		}
		RBuff_Index = 0;
	}
  }

  async event void HPLUART.putDone() {
    atomic {
	    buff_start++;
	    
	    if (buff_start>buff_len-1) 
	    	buff_start=0;
	    
		if (buff_end > buff_len-1)
			buff_end = 0;
					
	    if (buff_start != buff_end)
	    {
		call HPLUART.put(str_buff[buff_start]);
		{
			//char Debug_ch = str_buff[buff_start] + '0';
			//char Debug_ch = str_buff[buff_start];
			//call SCSuartDBG.UARTSend(&Debug_ch, 1);
		}
	  
	    }else{
		state = IDLE_UART;
	    }
    }
  }

  void UARTSend (uint8_t* data, uint8_t len)
  {
	uint8_t i;
	atomic {
		if (buff_start>buff_len-1) 
	    	buff_start=0;
			    
		for (i=0 ; i<len ; i++)
		{
			if (buff_end > buff_len-1)
				buff_end = 0;
			str_buff[buff_end] = data[i];
			buff_end++;
		}
		
		if ( state == IDLE_UART)
		{
			state = BUSY_UART;
			call HPLUART.put(str_buff[buff_start]);
			{
				//char Debug_ch = str_buff[buff_start] + '0';
				//char Debug_ch = str_buff[buff_start];
				//call SCSuartDBG.UARTSend(&Debug_ch, 1);
			}
		}
	}
  }


  void gen15693crc(uint8_t* data, uint8_t len, uint8_t* byte1, uint8_t* byte2) {
	const uint16_t POLYNOMIAL = 0x8408; // x^16 + x^12 + x^5 + 1
	const uint16_t PRESET_VALUE = 0xFFFF;

	uint16_t current_crc_value = PRESET_VALUE;

	int i,j;
	for(i=0; i<len; i++) {
		current_crc_value = current_crc_value ^ ((unsigned int)data[i]);

		for (j=0; j<8; j++)	{
			if (current_crc_value & 0x0001)	{
				current_crc_value = (current_crc_value >> 1) ^ POLYNOMIAL;
			} else {
				current_crc_value = (current_crc_value >> 1);
			}
		}
	}
	current_crc_value = (~current_crc_value) & 0xFFFF;
	
	*byte1 = (uint8_t) (current_crc_value & 0xFF);
	*byte2 = (uint8_t) (current_crc_value >> 8);
  }

}

