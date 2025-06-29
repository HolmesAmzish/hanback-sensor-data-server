package cn.arorms.hanback.serial;

import com.fazecast.jSerialComm.*;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;

import cn.arorms.hanback.entity.SensorDataEntity;

public class SerialPortListener {
    private static final int PACKET_SIZE = 30; // 数据帧长度（字节）

    public static void main(String[] args) {
        // 1. 获取可用串口列表
        SerialPort[] ports = SerialPort.getCommPorts();
        for (SerialPort port : ports) {
            System.out.println("Port: " + port.getSystemPortName());
        }

        // 2. 选择串口（需根据实际设备修改）
        SerialPort serialPort = SerialPort.getCommPort("/dev/pts/6");
        serialPort.setBaudRate(9600);
        serialPort.setNumDataBits(8);
        serialPort.setNumStopBits(1);
        serialPort.setParity(SerialPort.NO_PARITY);

        // 3. 打开串口
        if (!serialPort.openPort()) {

            System.err.println("Failed to open port!");
            return;
        }
        System.out.println("Port opened successfully.");

        // 4. 监听数据
        serialPort.addDataListener(new SerialPortDataListener() {
            @Override
            public int getListeningEvents() {
                return SerialPort.LISTENING_EVENT_DATA_AVAILABLE;
            }

            @Override
            public void serialEvent(SerialPortEvent event) {
                if (event.getEventType() != SerialPort.LISTENING_EVENT_DATA_AVAILABLE) {
                    return;
                }

                byte[] buffer = new byte[serialPort.bytesAvailable()];
                int bytesRead = serialPort.readBytes(buffer, buffer.length);

                // 解析数据帧（假设每次接收完整30字节）
                if (bytesRead == PACKET_SIZE) {
                    SensorDataEntity data = parseSensorData(buffer);
                    System.out.println("Received: " + dataToString(data));
                }
            }
        });

        // 保持程序运行
        while (true) {
            try {
                Thread.sleep(1000);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
    }

    // 解析二进制数据
    private static SensorDataEntity parseSensorData(byte[] data) {
        ByteBuffer buffer = ByteBuffer.wrap(data)
                .order(ByteOrder.LITTLE_ENDIAN); // 小端序（与C程序一致）

        SensorDataEntity sensorData = new SensorDataEntity();
        sensorData.setSourceAddr(buffer.getShort() & 0xFFFF);
        sensorData.setSinkAddr(buffer.getShort() & 0xFFFF);
        sensorData.setDst2(buffer.getShort() & 0xFFFF);
        sensorData.setDst3(buffer.getShort() & 0xFFFF);
        sensorData.setSequence(buffer.getInt() & 0xFFFFFFFFL);
        sensorData.setTemperature(buffer.getShort() / 100.0f); // 温度需除以100
        sensorData.setHumidity(buffer.getShort() / 100.0f);    // 湿度需除以100
        sensorData.setLight(buffer.getShort() & 0xFFFF);
        sensorData.setFuncCode(buffer.get() & 0xFF);

        byte[] rfidData = new byte[5];
        buffer.get(rfidData);
        sensorData.setRfidData(rfidData);

        return sensorData;
    }

    // 数据转字符串（用于打印）
    private static String dataToString(SensorDataEntity data) {
        return String.format(
                "Source: 0x%04X, Sink: 0x%04X, Seq: %d, Temp: %.1f℃, Humi: %.1f%%, Light: %d, RFID: %s",
                data.getSourceAddr(),
                data.getSinkAddr(),
                data.getSequence(),
                data.getTemperature(),
                data.getHumidity(),
                data.getLight(),
                bytesToHex(data.getRfidData())
        );
    }

    // 字节数组转十六进制字符串
    private static String bytesToHex(byte[] bytes) {
        StringBuilder sb = new StringBuilder();
        for (byte b : bytes) {
            sb.append(String.format("%02X ", b));
        }
        return sb.toString().trim();
    }
}
