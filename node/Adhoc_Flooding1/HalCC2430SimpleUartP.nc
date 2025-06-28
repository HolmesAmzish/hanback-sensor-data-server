
/*
 * Copyright (c) 2008 Hanback Electronics
 * All rights reserved.
 */

/**
 *
 * @author Changsu Suh
 */

#include <ioCC2430.h>

module HalCC2430SimpleUartP {
  provides {
    interface Init;
    interface SerialByteComm as uart0;
    interface SerialByteComm as uart1;
  }
}
implementation {
  command error_t Init.init() {

    /* Borrowed from ChipCon */
#define BAUD_E_2400	6
#define BAUD_E_4800	7
#define BAUD_E_9600	8
#define BAUD_E_14400	8
#define BAUD_E_19200	9
#define BAUD_E_28800	9
#define BAUD_E_38400	10
#define BAUD_E_57600	10
#define BAUD_E_76800	11
#define BAUD_E_115200	11
#define BAUD_E_153600	12
#define BAUD_E_230400	12
#define BAUD_E_307200	13

#define BAUD_M_2400	59
#define BAUD_M_4800	59
#define BAUD_M_9600	59
#define BAUD_M_14400	216
#define BAUD_M_19200	59
#define BAUD_M_28800	216
#define BAUD_M_38400	59
#define BAUD_M_57600	216
#define BAUD_M_76800	59
#define BAUD_M_115200	216
#define BAUD_M_153600	59
#define BAUD_M_230400	216
#define BAUD_M_307200	59

    /////////////////////////////////////////////////////
    // PERCFG selects beween alternative pin mappings for UART0
    // P0.2 = rx, P0.3 = tx
    PERCFG |= 0x00; //Alternative 1 location

    // Select Peripheral function
    P0SEL |= 0x0C; // P0.2 = rx, P0.3 = tx

    U0BAUD = BAUD_M_57600;
    U0GCR  = BAUD_E_57600;

    U0CSR |=  0x80u | 0x40u; // Mode=UART | RE=ReceiveEnable
    U0UCR |= (0x02u  | 0x80u); //((HIGH_STOP) | FLUSH), NoFlow, 8bits, NoParity, 1stop bit 

    // Clear any pending flags
    UTX0IF = 0;
    URX0IF = 0;

    // Enable Receive  interrupt interrupt
    URX0IE = 1; 
    // Enable Transmit interrupt interrupt
    IEN2 |= 1<<CC2430_IEN2_UTX0IE; // UTX0IE = 1


    /////////////////////////////////////////////////////
    // PERCFG selects beween alternative pin mappings for UART1
    // P1.7 = rx, P1.6 = tx
    PERCFG |= 0x02; //Alternative 2 location

    // Select Peripheral function
    P1SEL |= 0xC0; // P1.7 = rx, P1.6 = tx

    U1BAUD = BAUD_M_38400;
    U1GCR  = BAUD_E_38400;

    U1CSR |=  0x80u | 0x40u; // Mode=UART | RE=ReceiveEnable
    U1UCR |= (0x02u  | 0x80u); //((HIGH_STOP) | FLUSH), NoFlow, 8bits, NoParity, 1stop bit 

    // Clear any pending flags
    UTX1IF = 0;
    URX1IF = 0;

    // Enable Receive  interrupt interrupt
    URX1IE = 1; 
    // Enable Transmit interrupt interrupt
    IEN2 |= 1<<CC2430_IEN2_UTX1IE; // UTX1IE = 1

    return SUCCESS;
  }

  /////////////////////////////////////////////////////

  async command error_t uart0.put(uint8_t data){
    U0BUF = data;
    return SUCCESS;
  }

  MCS51_INTERRUPT(SIG_URX0) { //URX0 complete interrupt
    URX0IF = 0;
    signal uart0.get(U0BUF);
  }

  MCS51_INTERRUPT(SIG_UTX0) { //TRX0 complete interrupt
    if (! (U0CSR & 0x1)) {
	UTX0IF = 0;
	signal uart0.putDone();
    }
  }

  default async event void uart0.get(uint8_t data) {}
  default async event void uart0.putDone() {}
  
  /////////////////////////////////////////////////////

  async command error_t uart1.put(uint8_t data){
    U1DBUF = data;
    return SUCCESS;
  }

  MCS51_INTERRUPT(SIG_URX1) { //URX0 complete interrupt
    URX1IF = 0;
    signal uart1.get(U1DBUF);
  }

  MCS51_INTERRUPT(SIG_UTX1) { //TRX0 complete interrupt
    if (! (U1CSR & 0x1)) {
	UTX1IF = 0;
	signal uart1.putDone();
    }
  }

  default async event void uart1.get(uint8_t data) {}
  default async event void uart1.putDone() {}

}
