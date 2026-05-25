package com.icesphere.camera.config;

import cn.dev33.satoken.interceptor.SaInterceptor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Web MVC配置
 * 配置静态资源映射和Sa-Token拦截器
 */
@Configuration
public class WebMvcConfig implements WebMvcConfigurer {

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // 映射本地文件上传目录为静态资源路径
        registry.addResourceHandler("/uploads/**")
                .addResourceLocations("file:uploads/");
        // 全景浏览页面静态资源（classpath:/static/ 默认已映射，这里显式声明确保优先级）
        registry.addResourceHandler("/panorama.html")
                .addResourceLocations("classpath:/static/panorama.html");
    }

}
