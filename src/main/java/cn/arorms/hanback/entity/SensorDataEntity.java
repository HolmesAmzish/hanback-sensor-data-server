package cn.arorms.hanback.entity;

import java.time.LocalDateTime;

/**
 * SensorDataEntity
 * Represents a sensor data record.
 * @version 1.0 2025-06-29
 */

public class SensorDataEntity {
    private float temperature;
    private float humidity;
    private float light;
    private String rfidData;
    private LocalDateTime timestamp;

    // Getters and Setters

    public float getTemperature() {
        return temperature;
    }

    public void setTemperature(float temperature) {
        this.temperature = temperature;
    }

    public float getHumidity() {
        return humidity;
    }

    public void setHumidity(float humidity) {
        this.humidity = humidity;
    }

    public float getLight() {
        return light;
    }

    public void setLight(float light) {
        this.light = light;
    }

    public String getRfidData() {
        return rfidData;
    }

    public void setRfidData(String rfidData) {
        this.rfidData = rfidData;
    }

    public LocalDateTime getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(LocalDateTime timestamp) {
        this.timestamp = timestamp;
    }
}
