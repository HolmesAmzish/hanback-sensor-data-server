package cn.arorms.hanback.mapper;

import cn.arorms.hanback.entity.SensorDataEntity;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.time.LocalDateTime;
import java.util.List;

@Mapper
public interface SensorDataMapper {
    List<SensorDataEntity> selectByPageAndDate(
        @Param("offset") int offset,
        @Param("limit") int limit,
        @Param("startTime") LocalDateTime startTime,
        @Param("endTime") LocalDateTime endTime
    );

    SensorDataEntity selectById(@Param("id") Long id);

    int deleteById(@Param("id") Long id);

    int insert(SensorDataEntity data);
}
