package com.icesphere.camera;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableAsync;

/**
 * 冰球全景看房系统启动类
 */
@SpringBootApplication
@MapperScan("com.icesphere.camera.mapper")
@EnableAsync
public class IceSphereCameraApplication {

    public static void main(String[] args) {
        SpringApplication.run(IceSphereCameraApplication.class, args);
    }

}
