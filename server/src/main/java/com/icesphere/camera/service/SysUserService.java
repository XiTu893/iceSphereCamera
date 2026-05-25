package com.icesphere.camera.service;

import com.icesphere.camera.entity.SysUser;

/**
 * 系统用户服务接口
 */
public interface SysUserService {

    /**
     * 用户注册
     * @param user 用户信息
     * @return 注册后的用户（含ID）
     */
    SysUser register(SysUser user);

    /**
     * 用户登录
     * @param username 用户名或手机号
     * @param password 密码
     * @return 登录后的用户信息
     */
    SysUser login(String username, String password);

    /**
     * 根据ID获取用户
     * @param userId 用户ID
     * @return 用户信息
     */
    SysUser getUserById(Long userId);

    /**
     * 更新用户信息
     * @param user 用户信息
     * @return 是否成功
     */
    boolean updateUser(SysUser user);

}
