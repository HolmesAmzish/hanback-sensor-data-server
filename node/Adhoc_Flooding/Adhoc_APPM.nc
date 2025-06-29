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

module Adhoc_APPM {
	uses {
    	interface Boot;
    	interface Timer<TMilli> as Timer1;
		interface Timer<TMilli> as Timer2;
		interface Timer<TMilli> as Timer3;
		interface Timer<TMilli> as Timer4;
    	interface Leds;
    	interface BusyWait<TMicro, uint16_t>;
		interface RFID_Control;
    	interface StdControl as RControl;
    	interface AMSend as Rout_Send;
    	interface Receive as Rout_Receive;
		interface SplitControl as CommControl;
  	}

  	// Sensor components
  	uses {
		interface Read<uint16_t> as Read_Humi;
		interface Read<uint16_t> as Read_Temp;
		interface Read<uint16_t> as Read_Photo;
  	}

  	// Uart component
  	uses {
		interface StdControl as SCSuartSTD;
		interface SCSuartDBG;
  	}

}
implementation {

  	message_t TXData;

  	//// sensor data ////
  	uint16_t myTemp=0xFFFF;
  	uint16_t myHumi=0xFFFF;
  	uint16_t myPhoto=0xFFFF;
  	uint16_t Raw_Temp=0xFFFF; // Raw temp info
  	uint8_t FUN = 0x00;
  	uint8_t Data[5] = {0x00,0x00,0x00,0x00,0x00,};
  	////////////////////
	//   uint8_t OutputUartMsg[64]; // 串口输出消息buff
  	void calc_SHT_(uint16_t p_humidity ,uint16_t p_temperature);


  	event void Boot.booted() {
	    uint8_t mote_id = (uint8_t) TOS_NODE_ID;
		if (TOS_NODE_ID != Sink_Addr) // 不是sink节点
		{ 
			call Timer3.startOneShot(1000);
	    	call Timer1.startPeriodic(SHT_Interval);  // 每隔20s读取一次温湿度数据
			call Timer4.startPeriodic(3000); // 每隔7s读取一次标签
		} 
		call RControl.start(); 
    	call CommControl.start(); 
  	}

  	event void CommControl.startDone(error_t error) {
    	call SCSuartSTD.start();
    	call RFID_Control.start();
  	}

  	event void CommControl.stopDone(error_t error) {}

  	event void Timer3.fired() {
		call Timer2.startPeriodic(light_Interval); // 每隔10s读取一次光照数据
  	}
  	// get sensor data as photo, temp., humi.
  	// 定时器溢出读取光照数据
  	event void Timer2.fired() {
    	call Leds.led2Toggle();
    	call Read_Photo.read(); 
  	}
  	// 定时器溢出读取温湿度
  	event void Timer1.fired() {
		call Leds.led2Toggle();
		call Read_Temp.read();
  	}

  	// 一般节点发送给Sink节点采集到的数据
  	task void transmit_frame(){
  
	  	DataFrameStruct DFS;
	
	  	call Leds.led1On();
	
	  	DFS.Temp	= myTemp;
	  	DFS.Humi	= myHumi;
	  	DFS.Photo	= myPhoto;
	  	atomic DFS.FUN = FUN;
	  	// memcpy (DFS.ID, ID, sizeof(ID));
		memcpy (DFS.Data, Data, sizeof(Data));
	  	memcpy (call Rout_Send.getPayload(&TXData), &DFS, sizeof(DataFrameStruct));

	  	call Rout_Send.send(Sink_Addr, &TXData, sizeof(DataFrameStruct));
  	}

  	// 一般节点数据发送完成事件
  	event void Rout_Send.sendDone(message_t* m, error_t err) {
    	if (err == SUCCESS)
	    	call Leds.led1Off();
  	}

  	// sink节点接收到一般节点发送的数据事件
	event message_t* Rout_Receive.receive(message_t* msg, void* payload, uint8_t len) {
    	if (TOS_NODE_ID == Sink_Addr) 
    	{
	    	uint8_t UART_Buff[65], *UART_Buff_p;
	    	uint8_t UART_Buff_len = 0, i;
	    	Route_Msg NWKF;
	    	DataFrameStruct DFS;
	    	UartFrameStruct UFS; 

	    	memcpy(&NWKF,  call Rout_Send.getPayload(msg), sizeof(Route_Msg));
	    	memcpy(&DFS, NWKF.AppData, sizeof(DataFrameStruct));
	    	UART_Buff_p = (uint8_t *)&UFS;

	    	{
		    	uint32_t Packet_Seq = (uint32_t) NWKF.Sequence;
		    	int16_t OrigiSrcAddr = NWKF.OrigiSrcAddr;
		    	//call SCSuartDBG.UARTSend(UART_Buff, 6);

		    	memcpy (UART_Buff_p+6, (void *)&OrigiSrcAddr, 2);
		    	memcpy (UART_Buff_p+8, (void *)&TOS_NODE_ID, 2);
		    	memcpy (UART_Buff_p+10, (void *)&NWKF.Dst2_for_multihop, 2);
		  		memcpy (UART_Buff_p+12,(void *)&NWKF.Dst3_for_multihop, 2);
		  		memcpy (UART_Buff_p+14,(void *)&Packet_Seq, 4);
		  		memcpy (UART_Buff_p+18,(void *)&DFS.Temp, 2);
		  		memcpy (UART_Buff_p+20,(void *)&DFS.Humi, 2);
		  		memcpy (UART_Buff_p+22,(void *)&DFS.Photo, 2);
		  		memcpy (UART_Buff_p+24,(void *)&DFS.FUN, 1);
				// memcpy (UART_Buff_p+25,(void *)&DFS.ID, 8);
		 		memcpy (UART_Buff_p+25,(void *)&DFS.Data, 5);
	    	}
	    	UART_Buff_len = 0;
	    	for ( i=6; i<sizeof(UartFrameStruct) ; i++)
	    	{
				UART_Buff[UART_Buff_len++] = UART_Buff_p[i];
	    	}
			// call SCSuartDBG.UARTSend(DFS.Data, sizeof(DFS.Data));
        	// 串口数据发送
	    	call SCSuartDBG.UARTSend(UART_Buff, UART_Buff_len -13);
	
	    	call Leds.led0Toggle();
    	}
    	return msg;
	}

  	// 读取光照完成事件，发送数据至sink节点
  	event void Read_Photo.readDone(error_t err, uint16_t val) {
	if (err == SUCCESS)
		{
			myPhoto = val;
			atomic FUN = 1;
		}
		post transmit_frame();
  	}  

  	// 读取温度完成事件，准备读取湿度
  	event void Read_Temp.readDone(error_t err, uint16_t val) {
		if (err == SUCCESS)
			Raw_Temp = val;
		call Read_Humi.read();
  	} 
  
  	// 读取湿度完成事件，发送数据至sink节点
  	event void Read_Humi.readDone(error_t err, uint16_t val) {
		if (err == SUCCESS && Raw_Temp!=0xFFFF)
		{
			calc_SHT_(val, Raw_Temp);
			atomic FUN = 2;
		}
		post transmit_frame();
  	} 

  // 对温湿度循环冗余，得到真实数值
  	void calc_SHT_(uint16_t p_humidity ,uint16_t p_temperature)
  	//----------------------------------------------------------------------------------------
  	// calculates temperature [C] and humidity [%RH]
  	// input : humi [Ticks] (12 bit)
  	// temp [Ticks] (14 bit)
  	// output: humi [%RH]
  	// temp [C]
  	{ 
		const float C1=-4.0; // for 12 Bit
		const float C2= 0.0405; // for 12 Bit
		const float C3=-0.0000028; // for 12 Bit
		const float T_1=0.01; // for 14 Bit @ 5V
		const float T_2=0.00008; // for 14 Bit @ 5V
 
		float rh_lin; // rh_lin: Humidity linear
		float rh_true; // rh_true: Temperature compensated humidity
		float t_C; // t_C : Temperature [C]
		float rh=(float)p_humidity; // rh: Humidity [Ticks] 12 Bit
		float t=(float)p_temperature; // t: Temperature [Ticks] 14 Bit
    
		t_C=t*0.01 - 40; // calc. Temperature from ticks to [C]
		rh_lin=C3*rh*rh + C2*rh + C1; // calc. Humidity from ticks to [%RH]
		rh_true=(t_C-25)*(T_1+T_2*rh)+rh_lin; // calc. Temperature compensated humidity [%RH]
		if(rh_true>100)rh_true=100; // cut if the value is outside of
		if(rh_true<0.1)rh_true=0.1; // the physical possible range
		atomic myTemp=(uint16_t)t_C; // return temperature [C]
		atomic myHumi=(uint16_t)rh_true; // return humidity[%RH]
  	}
  	//////////////////////////////////////////////////////
  	// 获取15693ID完成后发送至Sink节点
	async event void RFID_Control.GetID_15693_Done (char status, uint8_t *buff, char size){
    	// memcpy(ID, buff, 8);
		// atomic FUN = 3;
		// post transmit_frame();
	 	// call RFID_Control.RData_15693(block);
	}
	// 获取15693标签数据完成后发送至Sink节点
	async event void RFID_Control.RData_15693_Done (char status, uint8_t *buff, char size){
      	call SCSuartDBG.UARTSend(buff, 5);
	  	memcpy(Data, buff, 5);
		atomic FUN = 3;
    	post transmit_frame();
  	}
	// 读取标签数据定时器
  	event void Timer4.fired() {
	  	call RFID_Control.RData_15693 (5); 
  	}

	async event void RFID_Control.GetID_14443A_Done(char status, uint8_t *buff, char size) {}
	async event void RFID_Control.WData_15693_Done(char status){}
}


