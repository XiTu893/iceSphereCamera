package com.icesphere.camera.controller;

import cn.dev33.satoken.stp.StpUtil;
import com.icesphere.camera.common.Result;
import com.icesphere.camera.entity.SysUser;
import com.icesphere.camera.service.SysUserService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

/**
 * 认证控制器
 * 处理用户注册、登录、登出等请求
 */
@Slf4j
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final SysUserService sysUserService;

    /**
     * 用户注册
     */
    @PostMapping("/register")
    public Result<SysUser> register(@RequestBody SysUser user) {
        if (user.getUsername() == null || user.getPassword() == null) {
            return Result.error(400, "用户名和密码不能为空");
        }
        SysUser registered = sysUserService.register(user);
        // 清除密码字段
        registered.setPassword(null);
        return Result.success(registered);
    }

    /**
     * 用户登录
     */
    @PostMapping("/login")
    public Result<Map<String, Object>> login(@RequestBody Map<String, String> loginForm) {
        String username = loginForm.get("username");
        String password = loginForm.get("password");
        if (username == null || password == null) {
            return Result.error(400, "用户名和密码不能为空");
        }

        SysUser user = sysUserService.login(username, password);
        // 清除密码字段
        user.setPassword(null);

        // 构建返回数据
        Map<String, Object> data = new HashMap<>();
        data.put("token", StpUtil.getTokenValue());
        data.put("user", user);
        return Result.success(data);
    }

    /**
     * 获取当前登录用户信息
     */
    @GetMapping("/info")
    public Result<SysUser> info() {
        Long userId = StpUtil.getLoginIdAsLong();
        SysUser user = sysUserService.getUserById(userId);
        user.setPassword(null);
        return Result.success(user);
    }

    /**
     * 用户登出
     */
    @PostMapping("/logout")
    public Result<Void> logout() {
        StpUtil.logout();
        return Result.success();
    }

}
