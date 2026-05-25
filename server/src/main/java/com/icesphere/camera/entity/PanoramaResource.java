package com.icesphere.camera.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 全景资源实体
 */
@Data
@TableName("panorama_resource")
public class PanoramaResource implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 全景ID
     */
    @TableId(value = "pan_id", type = IdType.AUTO)
    private Long panId;

    /**
     * 关联房源ID
     */
    @TableField("house_id")
    private Long houseId;

    /**
     * 场景名称
     */
    @TableField("scene_name")
    private String sceneName;

    /**
     * 全景图URL
     */
    @TableField("pan_url")
    private String panUrl;

    /**
     * 热点数据（JSON格式）
     */
    @TableField("hot_data")
    private String hotData;

    /**
     * 创建时间
     */
    @TableField(value = "create_time", fill = FieldFill.INSERT)
    private LocalDateTime createTime;

}
