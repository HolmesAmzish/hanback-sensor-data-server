package cn.arorms.hanback.entity;

import java.time.LocalDateTime;

/**
 * SensorDataEntity
 * @version 1.0 2025-06-29
 */

public class SensorDataEntity {
    private int sourceAddr;      // 源节点地址（2字节）
    private int sinkAddr;        // Sink节点地址（2字节）
    private int dst2;            // 多跳地址2（2字节）
    private int dst3;            // 多跳地址3（2字节）
    private long sequence;      // 序列号（4字节）
    private float temperature;  // 温度（原始值/100.0）
    private float humidity;     // 湿度（原始值/100.0）
    private float light;           // 光照（ADC值）
    private int funcCode;       // 功能标识（1字节）
    private byte[] rfidData;     // RFID数据（5字节）

    // Getters and Setters

    public int getSourceAddr() {
        return sourceAddr;
    }

    public void setSourceAddr(int sourceAddr) {
        this.sourceAddr = sourceAddr;
    }

    public int getSinkAddr() {
        return sinkAddr;
    }

    public void setSinkAddr(int sinkAddr) {
        this.sinkAddr = sinkAddr;
    }

    public int getDst2() {
        return dst2;
    }

    public void setDst2(int dst2) {
        this.dst2 = dst2;
    }

    public int getDst3() {
        return dst3;
    }

    public void setDst3(int dst3) {
        this.dst3 = dst3;
    }

    public long getSequence() {
        return sequence;
    }

    public void setSequence(long sequence) {
        this.sequence = sequence;
    }

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

    public int getFuncCode() {
        return funcCode;
    }

    public void setFuncCode(int funcCode) {
        this.funcCode = funcCode;
    }

    public byte[] getRfidData() {
        return rfidData;
    }

    public void setRfidData(byte[] rfidData) {
        this.rfidData = rfidData;
    }
}
