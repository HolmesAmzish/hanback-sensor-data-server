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

#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <termios.h>
#include <stdio.h>
#include <pthread.h>

#include "RFID_Control.h"
#define BAUDRATE B57600
#define MODEMDEVICE "/dev/ttyS4"

#define uint8 unsigned char
#define uint16 unsigned short
#define uint32 unsigned long
#define TOSH_DATA_LENGTH 29

pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;

struct TOS_Msg
{
  uint16_t addr;
  uint8_t type;
  uint8_t group;
  uint8_t length;
  uint8_t data[TOSH_DATA_LENGTH];
  uint16_t crc;
};

//////// Values for receiving data from serial ////////
struct TOS_Msg RecvMsg;
uint8_t RecvBuff[50];
uint8_t Startflag;
uint8_t SevenD_flag;
int Rindex;
///////////////////////////////////////////////////////

//////// Values for transmitting data to serial ////////
struct TOS_Msg SendMsg;
uint8_t SendBuff[50];
uint8_t Sindex;
uint16_t CRC_Value;
uint8_t Type    = 0x07;
uint8_t GroupID = 0x77;
///////////////////////////////////////////////////////

int fd;

void Parsing_Buff(uint8_t *RecvBuff, uint8_t RecvLen);
void SendMsgtoSerial(uint8_t *SendData, uint8_t SendLen);

void InitSerial()
{
	int i,recv_cnt, len;
	unsigned char insert, c, stx, buff[256];
	short length;
	struct termios oldtio,newtio;
	unsigned char data;
	tcflag_t baudflag = BAUDRATE;

	fd = open(MODEMDEVICE, O_RDWR | O_NOCTTY);
	if (fd <0) {perror(MODEMDEVICE); exit(1); }

	tcgetattr(fd,&oldtio); /* save current serial port settings */
	bzero(&newtio, sizeof(newtio)); /* clear struct for new port settings */
	newtio.c_cflag = CS8 | CLOCAL | CREAD;
	newtio.c_iflag = IGNPAR | IGNBRK;

	cfsetispeed(&newtio, baudflag);
	cfsetospeed(&newtio, baudflag);
	newtio.c_oflag = 0;

	tcflush(fd, TCIFLUSH);
	tcsetattr(fd,TCSANOW,&newtio);
}

void ListenfromSerial() {
	uint8_t recvChar;

	while (1){
		read(fd, &recvChar, 1);
		printf("%x ", recvChar);

		if (recvChar==0x7E){
			if (Startflag==0)
			{
				Startflag = 1;
				Rindex = 0;
				SevenD_flag = 0;
				RecvBuff[Rindex++] = recvChar;

			}else if(Startflag==1){
				int i;
				Startflag = 0;
				RecvBuff[Rindex++] = recvChar;
				//printf("\n");
				//for ( i=0 ; i<Rindex ; i++ )
				//	printf("%X ", RecvBuff[i]);
				printf("\n\n");
				Parsing_Buff(RecvBuff, Rindex);
				//SendMsgtoSerial(RecvMsg.data, RecvMsg.length);
			}
		
		}else if (recvChar==0x7D){
			SevenD_flag = 1;

		}else if (SevenD_flag==1){
			if (recvChar == 0x5E){
				RecvBuff[Rindex++] = 0x7E;
			}else if (recvChar == 0x5D){
				RecvBuff[Rindex++] = 0x7D;
			}
			SevenD_flag = 0;

		}else if (Startflag == 1){
			RecvBuff[Rindex++] = recvChar;
		}
	}
}

void Parsing_Buff(uint8_t *RecvBuff, uint8_t RecvLen)
{
	// RecvBuff[0] and [1] are 0x7E and 0x42
	/* typedef struct TOS_Msg{
	     uint16_t addr;
	     uint8_t type;
	     uint8_t group;
	     uint8_t length;
	     int8_t data[TOSH_DATA_LENGTH];
	     uint16_t crc;
	   } */
	int i;
	memcpy(&RecvMsg.addr, RecvBuff+2, 2);
	RecvMsg.type = RecvBuff[4];
	RecvMsg.group = RecvBuff[5];
	RecvMsg.length = RecvBuff[6];
	for ( i=0 ; i<RecvMsg.length ; i++ ) {
		RecvMsg.data[i] = RecvBuff[7+i];
	}
}

uint16_t crcByte(uint16_t crc, uint8_t b)
{
  uint8_t i;
  crc = crc ^ b << 8;
  i = 8;
  do
    if (crc & 0x8000)
      crc = crc << 1 ^ 0x1021;
    else
      crc = crc << 1;
  while (--i);

  return crc;
}

void insertToSendBuff(uint8_t input)
{
	if (input==0x7E)	{
		SendBuff[Sindex++] = 0x7D;
		SendBuff[Sindex++] = 0x5E;
		CRC_Value = crcByte(CRC_Value, 0x7D);
		CRC_Value = crcByte(CRC_Value, 0x5E);
	}else if (input==0x7D){
		SendBuff[Sindex++] = 0x7D;
		SendBuff[Sindex++] = 0x5D;
		CRC_Value = crcByte(CRC_Value, 0x7D);
		CRC_Value = crcByte(CRC_Value, 0x5D);
	}else{
		SendBuff[Sindex++] = input;
		CRC_Value = crcByte(CRC_Value, input);
	}
}

void SendMsgtoSerial(uint8_t *SendData, uint8_t SendLen)
{
	uint8_t i;
	Sindex = 0;
	CRC_Value = 0;
	
	// start byte and ack type
	SendBuff[Sindex++] = 0x7E;
	SendBuff[Sindex++] = 0x42;
	CRC_Value = crcByte(CRC_Value, 0x42);

	// address
	insertToSendBuff(0x7E);
	insertToSendBuff(0x00);
	// type
	insertToSendBuff(Type);
	// group
	insertToSendBuff(GroupID);
	// length
	insertToSendBuff(SendLen);
	// Data
	for ( i=0 ; i<SendLen ; i++ )
	{
		insertToSendBuff(SendData[i]);
	}
	// CRC
	SendBuff[Sindex++] = (uint8_t) (CRC_Value & 0xFF);
	SendBuff[Sindex++] = (uint8_t) ((CRC_Value>>8) & 0xFF);
	
	// End Byte
	SendBuff[Sindex++] = 0x7E;
	///*
	for ( i=0 ; i<Sindex ; i++ )
		printf("%X ", SendBuff[i]);
	printf("\n\n");
	//*/
	write(fd, SendBuff, Sindex);
}

void send_processing()
{
	RFID_COMM_MSG send_data;
	char buff[256], insert, i, StartChar=0x7E;

	while (1)
	{
		send_data.comm = 0;
		send_data.block = 5;

		printf("insert RFID card TYPE ('a'=14443A, 'b'=15693): ");
		gets(buff);
		insert = buff[0];

		if (insert=='a')
		{
			printf("your choice is 14443A type, This card supprot getID only\n", insert);
			printf("insert CMD ('any key'=getID, 'x'=exit): ");
			gets(buff);
			insert = buff[0];

			if (insert=='x')
				break;

			send_data.comm = 1;

		}else{
			printf("your choice is 15693 type\n", insert);
			printf("insert CMD ('i'=getID, 'r'=readData, 'w'=writeData, 'x'=exit): ");
			gets(buff);
			insert = buff[0];
			printf("your choice: %c\n\n", insert);

			if(insert == 'i')
			{
				send_data.comm = 2;
			}
			else if(insert == 'r')
			{
				send_data.comm = 3;
				send_data.block = 5;
			}
			else if(insert == 'w')
			{
				unsigned char lrc=0;
				memset(buff,0,4);
				printf("insert data (data length is limited 4) : ");
				gets(buff);

				for (i=0;i<4;i++)
				{
					if( '0'<=buff[i] && buff[i]<='9')
						send_data.wbuff[i] = buff[i] - '0';
					else if (buff[i]=='A')
						send_data.wbuff[i] = 0x0A;
					else
						send_data.wbuff[i] = buff[i];

					printf("%x ", send_data.wbuff[i]);
				}
				send_data.block = 5;
				send_data.comm = 4;
			}else if(insert == 'x')	{
				break;
			}else{
				continue;
			}
		}
		//SendMsgtoSerial((uint8_t*)&send_data, sizeof(send_data));
		write(fd, &StartChar, 1);
		write(fd, &send_data, sizeof(send_data));
		usleep(1000000);
		printf("\n");
		//break;
	}
}

void recv_processing()
{
	char recvChar;
	while(1)
	{
		read(fd, &recvChar, 1);
		printf("%c", recvChar);
	}
}

int main()
{	
	pthread_t thread_;
	printf("Start serial program [Changsu Suh]\n\n");
	
	InitSerial();

	if ( pthread_create(&thread_, NULL, (void *) recv_processing, NULL) != 0)
			printf("pthread_create ERROR!!!\n");
	send_processing();
	return 1;
}
