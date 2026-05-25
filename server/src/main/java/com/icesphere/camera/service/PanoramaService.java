package com.icesphere.camera.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.icesphere.camera.entity.PanoramaResource;

import java.util.List;

/**
 * 全景资源服务接口
 */
public interface PanoramaService extends IService<PanoramaResource> {

    /**
     * 保存全景资源
     * @param panorama 全景资源信息
     * @return 保存后的全景资源
     */
    PanoramaResource savePanorama(PanoramaResource panorama);

    /**
     * 根据房源ID获取全景列表
     * @param houseId 房源ID
     * @return 全景资源列表
     */
    List<PanoramaResource> getByHouseId(Long houseId);

    /**
     * 根据ID获取全景详情
     * @param panId 全景ID
     * @return 全景资源信息
     */
    PanoramaResource getById(Long panId);

    /**
     * 更新热点数据
     * @param panId 全景ID
     * @param hotData 热点数据（JSON）
     * @return 是否成功
     */
    boolean updateHotData(Long panId, String hotData);

}
