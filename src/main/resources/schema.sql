CREATE TABLE IF NOT EXISTS sensor_data (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    light FLOAT NOT NULL COMMENT '光照值（单位：lux）',
    temperature FLOAT NOT NULL COMMENT '温度值（单位：℃）',
    humidity FLOAT NOT NULL COMMENT '湿度值（单位：%RH）',
    rfid_data VARCHAR(20) COMMENT 'RFID标签（十六进制字符串，如"A1B2C3D4E5"）',
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '记录时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='传感器数据表';