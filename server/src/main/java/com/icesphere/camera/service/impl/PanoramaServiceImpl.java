package com.icesphere.camera.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.icesphere.camera.common.ResultCode;
import com.icesphere.camera.entity.PanoramaResource;
import com.icesphere.camera.exception.BusinessException;
import com.icesphere.camera.mapper.PanoramaResourceMapper;
import com.icesphere.camera.service.PanoramaService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * 全景资源服务实现类
 */
@Slf4j
@Service
public class PanoramaServiceImpl extends ServiceImpl<PanoramaResourceMapper, PanoramaResource> implements PanoramaService {

    @Override
    public PanoramaResource savePanorama(PanoramaResource panorama) {
        save(panorama);
        log.info("全景资源保存成功: panId={}, houseId={}", panorama.getPanId(), panorama.getHouseId());
        return panorama;
    }

    @Override
    public List<PanoramaResource> getByHouseId(Long houseId) {
        return list(new LambdaQueryWrapper<PanoramaResource>()
                .eq(PanoramaResource::getHouseId, houseId)
                .orderByDesc(PanoramaResource::getCreateTime));
    }

    @Override
    public PanoramaResource getById(Long panId) {
        PanoramaResource panorama = super.getById(panId);
        if (panorama == null) {
            throw new BusinessException(ResultCode.NOT_FOUND);
        }
        return panorama;
    }

    @Override
    public boolean updateHotData(Long panId, String hotData) {
        PanoramaResource panorama = super.getById(panId);
        if (panorama == null) {
            throw new BusinessException(ResultCode.NOT_FOUND);
        }
        PanoramaResource update = new PanoramaResource();
        update.setPanId(panId);
        update.setHotData(hotData);
        return updateById(update);
    }

}
