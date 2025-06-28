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

module FloodingM {

  provides {
	interface StdControl;
	interface AMSend as SendFromAPP;
	interface Receive as RecvToAPP;  
  }
  uses {
    interface Timer<TMilli>;
    interface ParameterInit<uint16_t> as SeedInit;
    interface Random;
    interface SplitControl as CommControl;
    interface AMSend as SendToMAC;
    interface Receive as RecvFromMAC;
  }

}implementation{

  message_t SendMsg, RecvMsg, ForwardMsg[MAX_Forward_Buff];//定义发送数据，接收数据
  Route_Msg NWKF; // 路由信息
  uint16_t Next_Addr; // 下一跳节点地址
  uint8_t Forward_Buff_Index; 
  uint8_t RTable_Index; // 路由表下标
  uint8_t mySequence; // 序列号
  Route_Table RTable[MAX_RTABLE]; // 路由表

  command error_t StdControl.start() { // 启动StdControl
    uint8_t i;
    uint16_t random_num;
    
    call SeedInit.init(TOS_NODE_ID);
    random_num = call Random.rand16();

    atomic {
	Next_Addr = AM_BROADCAST_ADDR; // 广播地址
	Forward_Buff_Index = 0;
	RTable_Index = 0;
	mySequence = (uint8_t) (random_num%0xFF);	// 0~255之间的随机数
	for (i=0;i<MAX_RTABLE;i++) {	// 路由表赋初值
		RTable[i].FinalDstAddr = UnknownAddr;	// 最终地址未知
		RTable[i].OrigiSrcAddr = UnknownAddr;   // 源地址未知
		RTable[i].Sequence = 0xFF;  // 序列号为255
	}
    }
    call CommControl.start();	// 启动分相控制
    return SUCCESS;
  }

  command error_t StdControl.stop() {return SUCCESS;} // 启动std控制结束
  event void CommControl.startDone(error_t error) {} // 启动分相控制启动完成事件
  event void CommControl.stopDone(error_t error) {} // 启动分相控制关闭完成事件

//////////////////////////////////////////////////////////////////////
  void insertMSGtoRTable(message_t* msg) { // 将接收到的路由信息写入路由表
	Route_Msg pack;
	memcpy(&pack, call SendToMAC.getPayload(msg), sizeof(Route_Msg)); // 获取数据载荷

	atomic{
		RTable[RTable_Index].FinalDstAddr = pack.FinalDstAddr; 
		RTable[RTable_Index].OrigiSrcAddr = pack.OrigiSrcAddr;
		RTable[RTable_Index].Sequence = pack.Sequence;

		RTable_Index++;
		RTable_Index %= MAX_RTABLE;
	}
  }

  bool isRecvPrevious (message_t* msg) { // 是否以前接收过一样的数据包 （0，没有，1，有）
	Route_Msg pack;
	bool return_status = 0; // 曾经没有接收过
	uint8_t i;

	memcpy(&pack, call SendToMAC.getPayload(msg), sizeof(Route_Msg));
	for (i=0;i<MAX_RTABLE;i++) { // 查看路由表是否已经记录过
		if (RTable[i].FinalDstAddr == pack.FinalDstAddr &&
			RTable[i].OrigiSrcAddr == pack.OrigiSrcAddr &&
			RTable[i].Sequence == pack.Sequence)
		{
			return_status = 1; // 曾经接收过
			break;
		}
	}
	return return_status; 
  }

//////////////////////////////////////////////////////////////////////

  command error_t SendFromAPP.send(am_addr_t addr, message_t* msg, uint8_t len){ 

	Route_Msg Route_M;
	void *DataPayLoad = call SendToMAC.getPayload(msg); // 获取MAC层数据载荷
	error_t return_status;	
	// 路由信息
	Route_M.FrameControl = GeneralDataFrame; 
	Route_M.FinalDstAddr = addr;
	Route_M.OrigiSrcAddr = TOS_NODE_ID;
	Route_M.Sequence = mySequence;
	Route_M.TTL = Default_TTL;
	Route_M.Dst2_for_multihop = UnknownAddr;
	Route_M.Dst3_for_multihop = UnknownAddr;
	memcpy((void *)&(Route_M.AppData), DataPayLoad, len);	// 将数据载荷拷贝给路由信息的数据字段
	memcpy(call SendToMAC.getPayload(&SendMsg), (uint8_t *)&Route_M, sizeof(Route_Msg)); // 将路由信息拷贝给待发送至MAC层数据载荷

	mySequence++;
	mySequence %= 0xFF;	// 序列号 + 1

	return_status = call SendToMAC.send(Next_Addr, &SendMsg, sizeof(Route_Msg)); // 发送至MAC层
	if (return_status == SUCCESS)
		insertMSGtoRTable(&SendMsg);	// 将发送信息写入到路由表

	return return_status;
  }

  command error_t SendFromAPP.cancel(message_t* msg){
	return call SendToMAC.cancel(msg);
  }

  command uint8_t SendFromAPP.maxPayloadLength(){
	return call SendToMAC.maxPayloadLength();
  }

  command void* SendFromAPP.getPayload(message_t* msg){
	return call SendToMAC.getPayload(msg);
  }

  event void SendToMAC.sendDone(message_t* msg, error_t error) {
	signal SendFromAPP.sendDone(msg, error);
  }

//////////////////////////////////////////////////////////////////////

  task void RecvToAPP_task(){  // 接收数据包转发给应用层
	memcpy(&NWKF, call SendToMAC.getPayload(&RecvMsg), sizeof(Route_Msg));
	signal RecvToAPP.receive(&RecvMsg, (void *)&(NWKF.AppData), sizeof(Route_Msg));
  }
  
  task void Forwarding_task(){ // 转发数据包任务
	if (call SendToMAC.send(Next_Addr, &ForwardMsg[Forward_Buff_Index], sizeof(Route_Msg))==SUCCESS)
		insertMSGtoRTable(&ForwardMsg[Forward_Buff_Index]);
  }

  event message_t* RecvFromMAC.receive(message_t* msg, void* payload, uint8_t len) {

	Route_Msg *pack = (Route_Msg *) call SendToMAC.getPayload(msg);

	if (pack->FinalDstAddr == TOS_NODE_ID) { // 如果最终目的节点为本节点

#ifndef SHOW_OVERLAP_PACKET
		if (!isRecvPrevious(msg))	// 以前未曾接收过
#endif
		{
			memcpy((void*)&RecvMsg, (void*)msg, sizeof(message_t));		    
			insertMSGtoRTable(msg);	 // 将数据插入路由表
			post RecvToAPP_task(); // 将数据上传给应用层
		}	

	}else{  // 如果最终目的节点不是本节点
		if (!isRecvPrevious(msg)){	// 以前未曾接收过
			if (pack->TTL>0) {	// 如果 TTL > 0
				pack->TTL--;	// TTL 减一
				
				Forward_Buff_Index++;	// 转发次数加1
				Forward_Buff_Index %= MAX_Forward_Buff;
				memcpy((void*)&ForwardMsg[Forward_Buff_Index], (void*)msg, sizeof(message_t));

				// Change Route Field
				{
					Route_Msg Forward_NWKF;	// 转发路由信息
					
					memcpy (&Forward_NWKF, call SendToMAC.getPayload(&ForwardMsg[Forward_Buff_Index]), sizeof(Route_Msg));
					Forward_NWKF.FrameControl = ForwardDataFrame;	
					if (Forward_NWKF.Dst2_for_multihop == UnknownAddr){
						Forward_NWKF.Dst2_for_multihop = TOS_NODE_ID; 
					}else{
						Forward_NWKF.Dst3_for_multihop = Forward_NWKF.Dst2_for_multihop;
						Forward_NWKF.Dst2_for_multihop = TOS_NODE_ID;
					}
					memcpy (call SendToMAC.getPayload(&ForwardMsg[Forward_Buff_Index]), &Forward_NWKF, sizeof(Route_Msg));
				}
				
				post Forwarding_task();	// 抛出转发任务
			}
		}
	}
	return msg;
  }

  command void* RecvToAPP.getPayload(message_t* msg, uint8_t* len){
	return call RecvFromMAC.getPayload(msg, len);
  }
  command uint8_t RecvToAPP.payloadLength(message_t* msg){
	return call RecvFromMAC.payloadLength(msg);
  }

  event void Timer.fired() {}
}
