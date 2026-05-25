package com.icesphere.camera.service;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.service.IService;
import com.icesphere.camera.entity.HouseInfo;

/**
 * 房源信息服务接口
 */
public interface HouseInfoService extends IService<HouseInfo> {

    /**
     * 创建房源
     * @param houseInfo 房源信息
     * @return 创建后的房源
     */
    HouseInfo createHouse(HouseInfo houseInfo);

    /**
     * 更新房源
     * @param houseInfo 房源信息
     * @return 是否成功
     */
    boolean updateHouse(HouseInfo houseInfo);

    /**
     * 删除房源
     * @param houseId 房源ID
     * @return 是否成功
     */
    boolean deleteHouse(Long houseId);

    /**
     * 根据ID获取房源详情
     * @param houseId 房源ID
     * @return 房源信息
     */
    HouseInfo getHouseById(Long houseId);

    /**
     * 分页查询房源列表
     * @param page 分页参数
     * @param userId 用户ID（可选过滤）
     * @return 分页结果
     */
    IPage<HouseInfo> listHouses(IPage<HouseInfo> page, Long userId);

    /**
     * 查询已上线的房源列表
     * @param page 分页参数
     * @return 分页结果
     */
    IPage<HouseInfo> listOnlineHouses(IPage<HouseInfo> page);

    /**
     * 更新房源状态
     * @param houseId 房源ID
     * @param status 新状态
     * @return 是否成功
     */
    boolean updateStatus(Long houseId, Integer status);

}
