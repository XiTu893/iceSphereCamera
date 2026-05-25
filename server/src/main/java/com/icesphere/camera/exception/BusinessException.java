package com.icesphere.camera.exception;

import com.icesphere.camera.common.ResultCode;
import lombok.Getter;

/**
 * 业务异常
 * 用于在业务逻辑中主动抛出的异常
 */
@Getter
public class BusinessException extends RuntimeException {

    private static final long serialVersionUID = 1L;

    /**
     * 错误码
     */
    private final int code;

    /**
     * 使用ResultCode构造
     */
    public BusinessException(ResultCode resultCode) {
        super(resultCode.getMessage());
        this.code = resultCode.getCode();
    }

    /**
     * 使用自定义消息构造
     */
    public BusinessException(String message) {
        super(message);
        this.code = ResultCode.SERVER_ERROR.getCode();
    }

    /**
     * 使用自定义错误码和消息构造
     */
    public BusinessException(int code, String message) {
        super(message);
        this.code = code;
    }

}
