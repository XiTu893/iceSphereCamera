package com.icesphere.camera.common;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * 响应状态码枚举
 */
@Getter
@AllArgsConstructor
public enum ResultCode {

    /**
     * 成功
     */
    SUCCESS(200, "操作成功"),

    /**
     * 参数错误
     */
    PARAM_ERROR(400, "参数错误"),

    /**
     * 未授权
     */
    UNAUTHORIZED(401, "未登录或登录已过期"),

    /**
     * 禁止访问
     */
    FORBIDDEN(403, "没有访问权限"),

    /**
     * 资源不存在
     */
    NOT_FOUND(404, "资源不存在"),

    /**
     * 服务器内部错误
     */
    SERVER_ERROR(500, "服务器内部错误");

    /**
     * 状态码
     */
    private final int code;

    /**
     * 提示信息
     */
    private final String message;

}
