package com.icesphere.camera.config;

import cn.dev33.satoken.interceptor.SaInterceptor;
import cn.dev33.satoken.stp.StpInterface;
import cn.dev33.satoken.stp.StpUtil;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.util.ArrayList;
import java.util.List;

/**
 * Sa-Token配置
 * 配置登录路径排除和权限拦截
 */
@Configuration
public class SaTokenConfig implements WebMvcConfigurer {

    /**
     * 不需要登录校验的路径
     */
    private static final String[] EXCLUDE_PATHS = {
            "/api/auth/register",
            "/api/auth/login",
            "/api/upload/image/**",
            "/api/upload/images/**",
            "/error",
            "/doc.html",
            "/webjars/**",
            "/swagger-resources/**",
            "/v2/api-docs/**"
    };

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        // 注册Sa-Token拦截器，打开注解式鉴权功能
        registry.addInterceptor(new SaInterceptor(handle -> {
            // 校验登录状态，未登录则抛出异常
            StpUtil.checkLogin();
        })).addPathPatterns("/api/**")
          .excludePathPatterns(EXCLUDE_PATHS);
    }

}
