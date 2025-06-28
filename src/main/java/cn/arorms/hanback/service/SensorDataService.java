package cn.arorms.hanback.service;

import cn.arorms.hanback.entity.SensorDataEntity;
import cn.arorms.hanback.mapper.SensorDataMapper;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class SensorDataService {
    private SensorDataMapper sensorDataMapper;

    public List<SensorDataEntity> getDataByPageAndDate(int page, int size, LocalDateTime startTime, LocalDateTime endTime) {
        int offset = (page - 1) * size;
        return sensorDataMapper.selectByPageAndDate(offset, size, startTime, endTime);
    }

    public SensorDataEntity getDataById(Long id) {
        return sensorDataMapper.selectById(id);
    }

    public boolean deleteDataById(Long id) {
        return sensorDataMapper.deleteById(id) > 0;
    }

    public boolean insertData(SensorDataEntity data) {
        return sensorDataMapper.insert(data) > 0;
    }
}
