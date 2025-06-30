package cn.arorms.hanback.serial;

import cn.arorms.hanback.entity.SensorDataEntity;
import cn.arorms.hanback.service.SensorDataService;
import cn.arorms.hanback.websocket.SensorDataWebSocketHandler;
import com.fazecast.jSerialComm.SerialPort;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import jakarta.annotation.PostConstruct;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.time.LocalDateTime;

@Component
public class SerialPortListener {

    private final SensorDataWebSocketHandler webSocketHandler;
    private final SensorDataService sensorDataService;

    @Autowired
    public SerialPortListener(SensorDataService sensorDataService, SensorDataWebSocketHandler webSocketHandler) {
        this.sensorDataService = sensorDataService;
        this.webSocketHandler = webSocketHandler;
    }


    // socat -d -d pty,raw,echo=0 pty,raw,echo=0
    @Value("${serial.port}")
    private String serialPortName;

    @PostConstruct
    public void init() {

        SerialPort port = SerialPort.getCommPort(serialPortName);
        port.setBaudRate(9600);
        port.setComPortTimeouts(SerialPort.TIMEOUT_READ_SEMI_BLOCKING, 5000, 0);

        if (!port.openPort()) {
            System.err.println("Cannot open serial port！" + serialPortName);
            return;
        }

        System.out.println("Opened serial port, listening at " + serialPortName);

        new Thread(() -> {
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(port.getInputStream()))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    handleSerialData(line.trim());
                }
            } catch (Exception e) {
                e.printStackTrace();
            } finally {
                port.closePort();
            }
        }).start();
    }

    private void handleSerialData(String line) {
        try {
            System.out.println(line);
            String[] parts = line.split(",");
            if (parts.length != 4) {
                System.err.println("Invalid data length: " + line);
                return;
            }

            float temperature = Float.parseFloat(parts[0]);
            float humidity = Float.parseFloat(parts[1]);
            float light = Float.parseFloat(parts[2]);
            String rfidData = parts[3];

            SensorDataEntity data = new SensorDataEntity();
            data.setTemperature(temperature);
            data.setHumidity(humidity);
            data.setLight(light);
            data.setRfidData(rfidData);
            data.setTimestamp(LocalDateTime.now());

            sensorDataService.insertData(data);
            SensorDataWebSocketHandler.broadcast(data);

            System.out.printf("Inserted： Temp=%.2f, Hum=%.2f, Light=%.0f, RFID=%s, [success]\n", temperature, humidity, light, rfidData);
        } catch (NumberFormatException e) {
            System.err.println("Cannot parse data: " + line);
        }
    }
}
