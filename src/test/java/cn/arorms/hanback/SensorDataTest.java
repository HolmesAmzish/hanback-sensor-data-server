package cn.arorms.hanback;

import cn.arorms.hanback.entity.SensorDataEntity;
import cn.arorms.hanback.service.SensorDataService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest
public class SensorDataTest {
    @Autowired
    private SensorDataService sensorDataService;

    @Test
    public void testDataInsert() {
        SensorDataEntity data = new SensorDataEntity();
        data.setTemperatureValue(25.5f);
        data.setHumidityValue(60.0f);
        data.setLightValue(300f);
        sensorDataService.insertData(data);
        System.out.println("Done");
    }
}