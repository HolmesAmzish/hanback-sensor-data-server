CREATE TABLE IF NOT EXISTS sensor_data (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    light_value FLOAT NOT NULL COMMENT '光照值（单位：lux）',
    temperature_value FLOAT NOT NULL COMMENT '温度值（单位：℃）',
    humidity_value FLOAT NOT NULL COMMENT '湿度值（单位：%RH）',
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '记录时间'
);