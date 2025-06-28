package cn.arorms.hanback.serial;

import cn.arorms.hanback.entity.SensorDataEntity;
import cn.arorms.hanback.service.SensorDataService;
import com.fazecast.jSerialComm.SerialPort;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import jakarta.annotation.PostConstruct;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.time.LocalDateTime;

@Component
public class SerialPortListener {

    private final SensorDataService sensorDataService;

    @Autowired
    public SerialPortListener(SensorDataService sensorDataService) {
        this.sensorDataService = sensorDataService;
    }

    @PostConstruct
    public void init() {
        SerialPort port = SerialPort.getCommPort("/dev/pts/3");
        port.setBaudRate(9600);
        port.setComPortTimeouts(SerialPort.TIMEOUT_READ_SEMI_BLOCKING, 5000, 0);

        if (!port.openPort()) {
            System.err.println("无法打开串口！");
            return;
        }

        System.out.println("串口已打开，开始监听 /dev/pts/3...");

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
            if (parts.length != 3) {
                System.err.println("数据格式错误: " + line);
                return;
            }

            float temperature = Float.parseFloat(parts[0]);
            float humidity = Float.parseFloat(parts[1]);
            float light = Float.parseFloat(parts[2]);

            SensorDataEntity data = new SensorDataEntity();
            data.setTemperatureValue(temperature);
            data.setHumidityValue(humidity);
            data.setLightValue(light);
            data.setTimestamp(LocalDateTime.now());

            boolean inserted = sensorDataService.insertData(data);
            System.out.printf("插入数据：Temp=%.2f, Hum=%.2f, Light=%.0f [%s]\n",
                    temperature, humidity, light, inserted ? "成功" : "失败");

        } catch (NumberFormatException e) {
            System.err.println("无法解析行: " + line);
        }
    }
}
