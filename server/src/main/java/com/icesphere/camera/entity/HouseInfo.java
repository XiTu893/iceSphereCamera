package com.icesphere.camera.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 房源信息实体
 */
@Data
@TableName("house_info")
public class HouseInfo implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 房源ID
     */
    @TableId(value = "house_id", type = IdType.AUTO)
    private Long houseId;

    /**
     * 所属用户ID
     */
    @TableField("user_id")
    private Long userId;

    /**
     * 小区名称
     */
    @TableField("community_name")
    private String communityName;

    /**
     * 户型
     */
    @TableField("house_type")
    private String houseType;

    /**
     * 面积（平方米）
     */
    @TableField("area")
    private BigDecimal area;

    /**
     * 价格（万元）
     */
    @TableField("price")
    private BigDecimal price;

    /**
     * 状态：0=待审核 1=已上线 2=已下架
     */
    @TableField("status")
    private Integer status;

    /**
     * 创建时间
     */
    @TableField(value = "create_time", fill = FieldFill.INSERT)
    private LocalDateTime createTime;

}
