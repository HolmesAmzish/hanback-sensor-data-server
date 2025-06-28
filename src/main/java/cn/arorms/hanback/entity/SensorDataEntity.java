package cn.arorms.hanback.entity;

import java.time.LocalDateTime;

public class SensorDataEntity {
    private Long id;
    private Float lightValue;
    private Float temperatureValue;
    private Float humidityValue;
    private LocalDateTime timestamp;

    // Getters and setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Float getLightValue() { return lightValue; }
    public void setLightValue(Float lightValue) { this.lightValue = lightValue; }

    public Float getTemperatureValue() { return temperatureValue; }
    public void setTemperatureValue(Float temperatureValue) { this.temperatureValue = temperatureValue; }

    public Float getHumidityValue() { return humidityValue; }
    public void setHumidityValue(Float humidityValue) { this.humidityValue = humidityValue; }

    public LocalDateTime getTimestamp() { return timestamp; }
    public void setTimestamp(LocalDateTime timestamp) { this.timestamp = timestamp; }
}
