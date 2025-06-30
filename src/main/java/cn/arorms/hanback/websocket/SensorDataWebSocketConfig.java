package cn.arorms.hanback.websocket;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.*;

@Configuration
@EnableWebSocket
public class SensorDataWebSocketConfig implements WebSocketConfigurer {

    private final SensorDataWebSocketHandler handler;

    @Autowired
    public SensorDataWebSocketConfig(SensorDataWebSocketHandler handler) {
        this.handler = handler;
    }

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(handler, "/ws/data").setAllowedOrigins("*");
    }
}
