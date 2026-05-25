package com.icesphere.camera.service.impl;

import cn.dev33.satoken.stp.StpUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.icesphere.camera.common.Constants;
import com.icesphere.camera.common.ResultCode;
import com.icesphere.camera.entity.HouseInfo;
import com.icesphere.camera.exception.BusinessException;
import com.icesphere.camera.mapper.HouseInfoMapper;
import com.icesphere.camera.service.HouseInfoService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

/**
 * 房源信息服务实现类
 */
@Slf4j
@Service
public class HouseInfoServiceImpl extends ServiceImpl<HouseInfoMapper, HouseInfo> implements HouseInfoService {

    @Override
    public HouseInfo createHouse(HouseInfo houseInfo) {
        // 设置当前登录用户为房源所属用户
        houseInfo.setUserId(StpUtil.getLoginIdAsLong());
        // 新建房源默认待审核
        houseInfo.setStatus(Constants.HOUSE_STATUS_PENDING);
        save(houseInfo);
        log.info("房源创建成功: houseId={}, userId={}", houseInfo.getHouseId(), houseInfo.getUserId());
        return houseInfo;
    }

    @Override
    public boolean updateHouse(HouseInfo houseInfo) {
        // 校验房源是否存在
        HouseInfo existing = getById(houseInfo.getHouseId());
        if (existing == null) {
            throw new BusinessException(ResultCode.NOT_FOUND);
        }
        // 校验是否为房源所有者
        checkOwner(existing.getUserId());
        return updateById(houseInfo);
    }

    @Override
    public boolean deleteHouse(Long houseId) {
        HouseInfo existing = getById(houseId);
        if (existing == null) {
            throw new BusinessException(ResultCode.NOT_FOUND);
        }
        // 校验是否为房源所有者
        checkOwner(existing.getUserId());
        return removeById(houseId);
    }

    @Override
    public HouseInfo getHouseById(Long houseId) {
        HouseInfo houseInfo = getById(houseId);
        if (houseInfo == null) {
            throw new BusinessException(ResultCode.NOT_FOUND);
        }
        return houseInfo;
    }

    @Override
    public IPage<HouseInfo> listHouses(IPage<HouseInfo> page, Long userId) {
        LambdaQueryWrapper<HouseInfo> wrapper = new LambdaQueryWrapper<>();
        if (userId != null) {
            wrapper.eq(HouseInfo::getUserId, userId);
        }
        wrapper.orderByDesc(HouseInfo::getCreateTime);
        return page(page, wrapper);
    }

    @Override
    public IPage<HouseInfo> listOnlineHouses(IPage<HouseInfo> page) {
        LambdaQueryWrapper<HouseInfo> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(HouseInfo::getStatus, Constants.HOUSE_STATUS_ONLINE);
        wrapper.orderByDesc(HouseInfo::getCreateTime);
        return page(page, wrapper);
    }

    @Override
    public boolean updateStatus(Long houseId, Integer status) {
        HouseInfo existing = getById(houseId);
        if (existing == null) {
            throw new BusinessException(ResultCode.NOT_FOUND);
        }
        // 校验是否为房源所有者或管理员
        checkOwner(existing.getUserId());

        HouseInfo update = new HouseInfo();
        update.setHouseId(houseId);
        update.setStatus(status);
        return updateById(update);
    }

    /**
     * 校验当前用户是否为资源所有者
     */
    private void checkOwner(Long resourceUserId) {
        Long currentUserId = StpUtil.getLoginIdAsLong();
        if (!currentUserId.equals(resourceUserId)) {
            throw new BusinessException(ResultCode.FORBIDDEN);
        }
    }

}
