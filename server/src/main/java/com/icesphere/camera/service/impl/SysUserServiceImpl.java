package com.icesphere.camera.service.impl;

import cn.dev33.satoken.secure.BCrypt;
import cn.dev33.satoken.stp.StpUtil;
import cn.hutool.core.util.StrUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.icesphere.camera.common.ResultCode;
import com.icesphere.camera.entity.SysUser;
import com.icesphere.camera.exception.BusinessException;
import com.icesphere.camera.mapper.SysUserMapper;
import com.icesphere.camera.service.SysUserService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

/**
 * 系统用户服务实现类
 */
@Slf4j
@Service
public class SysUserServiceImpl extends ServiceImpl<SysUserMapper, SysUser> implements SysUserService {

    @Override
    public SysUser register(SysUser user) {
        // 校验用户名是否已存在
        long count = count(new LambdaQueryWrapper<SysUser>()
                .eq(SysUser::getUsername, user.getUsername()));
        if (count > 0) {
            throw new BusinessException("用户名已存在");
        }

        // 校验手机号是否已存在
        if (StrUtil.isNotBlank(user.getPhone())) {
            long phoneCount = count(new LambdaQueryWrapper<SysUser>()
                    .eq(SysUser::getPhone, user.getPhone()));
            if (phoneCount > 0) {
                throw new BusinessException("手机号已被注册");
            }
        }

        // BCrypt加密密码
        user.setPassword(BCrypt.hashpw(user.getPassword()));
        // 默认状态为正常
        user.setStatus(1);
        // 默认用户类型为普通用户
        if (user.getUserType() == null) {
            user.setUserType(1);
        }

        save(user);
        log.info("用户注册成功: userId={}, username={}", user.getUserId(), user.getUsername());
        return user;
    }

    @Override
    public SysUser login(String username, String password) {
        // 支持用户名或手机号登录
        SysUser user = getOne(new LambdaQueryWrapper<SysUser>()
                .eq(SysUser::getUsername, username)
                .or()
                .eq(SysUser::getPhone, username));

        if (user == null) {
            throw new BusinessException(ResultCode.UNAUTHORIZED.getCode(), "用户名或密码错误");
        }

        // 校验密码
        if (!BCrypt.checkpw(password, user.getPassword())) {
            throw new BusinessException(ResultCode.UNAUTHORIZED.getCode(), "用户名或密码错误");
        }

        // 校验账号状态
        if (user.getStatus() != 1) {
            throw new BusinessException("账号已被禁用");
        }

        // Sa-Token登录
        StpUtil.login(user.getUserId());
        log.info("用户登录成功: userId={}, username={}", user.getUserId(), user.getUsername());
        return user;
    }

    @Override
    public SysUser getUserById(Long userId) {
        SysUser user = getById(userId);
        if (user == null) {
            throw new BusinessException(ResultCode.NOT_FOUND);
        }
        return user;
    }

    @Override
    public boolean updateUser(SysUser user) {
        // 不允许通过此接口修改密码
        user.setPassword(null);
        return updateById(user);
    }

}
