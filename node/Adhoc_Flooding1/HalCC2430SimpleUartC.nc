
/*
 * Copyright (c) 2008 Hanback Electronics
 * All rights reserved.
 */

/**
 *
 * @author Changsu Suh
 */
configuration HalCC2430SimpleUartC {
  provides interface Init;
  provides interface SerialByteComm as uart0;
  provides interface SerialByteComm as uart1;
}
implementation {
  components HalCC2430SimpleUartP;

  HalCC2430SimpleUartP.Init = Init;
  HalCC2430SimpleUartP.uart0 = uart0;
  HalCC2430SimpleUartP.uart1 = uart1;

}
