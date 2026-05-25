package com.icesphere.camera.common;

/**
 * 系统常量
 */
public class Constants {

    /**
     * Sa-Token 令牌名称
     */
    public static final String TOKEN_NAME = "Authorization";

    /**
     * 用户类型：普通用户
     */
    public static final int USER_TYPE_NORMAL = 1;

    /**
     * 用户类型：经纪人
     */
    public static final int USER_TYPE_AGENT = 2;

    /**
     * 用户类型：管理员
     */
    public static final int USER_TYPE_ADMIN = 3;

    /**
     * 房源状态：待审核
     */
    public static final int HOUSE_STATUS_PENDING = 0;

    /**
     * 房源状态：已上线
     */
    public static final int HOUSE_STATUS_ONLINE = 1;

    /**
     * 房源状态：已下架
     */
    public static final int HOUSE_STATUS_OFFLINE = 2;

    /**
     * 拼接任务状态：排队中
     */
    public static final String STITCH_STATUS_QUEUED = "QUEUED";

    /**
     * 拼接任务状态：处理中
     */
    public static final String STITCH_STATUS_PROCESSING = "PROCESSING";

    /**
     * 拼接任务状态：已完成
     */
    public static final String STITCH_STATUS_COMPLETED = "COMPLETED";

    /**
     * 拼接任务状态：失败
     */
    public static final String STITCH_STATUS_FAILED = "FAILED";

    /**
     * 全景图宽高比（等距柱状投影 2:1）
     */
    public static final double PANORAMA_ASPECT_RATIO = 2.0;

    /**
     * 全景图默认宽度
     */
    public static final int PANORAMA_DEFAULT_WIDTH = 4096;

    /**
     * 全景图默认高度
     */
    public static final int PANORAMA_DEFAULT_HEIGHT = 2048;

    private Constants() {
        // 私有构造，防止实例化
    }

}
