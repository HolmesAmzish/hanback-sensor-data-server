package cn.arorms.hanback.controller;

import cn.arorms.hanback.entity.SensorDataEntity;
import cn.arorms.hanback.service.SensorDataService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

/**
 * SensorDataController
 * @version 1.0 2025-06-29
 */
@RestController
@RequestMapping("/api/data")
public class SensorDataController {

    @Autowired
    private SensorDataService sensorDataService;

    // Get all datas by page and date time if searched
    @GetMapping
    public List<SensorDataEntity> getDataByPageAndDate(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startTime,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endTime
    ) {
        return sensorDataService.getDataByPageAndDate(page, size, startTime, endTime);
    }

    // Get data by data id
    @GetMapping("/{id}")
    public SensorDataEntity getDataById(@PathVariable Long id) {
        return sensorDataService.getDataById(id);
    }

    // delete data by data id
    @DeleteMapping("/{id}")
    public boolean deleteDataById(@PathVariable Long id) {
        return sensorDataService.deleteDataById(id);
    }
}
