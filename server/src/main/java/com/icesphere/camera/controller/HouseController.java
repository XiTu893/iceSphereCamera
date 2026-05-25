package com.icesphere.camera.controller;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.icesphere.camera.common.Result;
import com.icesphere.camera.entity.HouseInfo;
import com.icesphere.camera.service.HouseInfoService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * 房源控制器
 * 处理房源的CRUD操作
 */
@Slf4j
@RestController
@RequestMapping("/api/house")
@RequiredArgsConstructor
public class HouseController {

    private final HouseInfoService houseInfoService;

    /**
     * 创建房源
     */
    @PostMapping
    public Result<HouseInfo> create(@RequestBody HouseInfo houseInfo) {
        HouseInfo created = houseInfoService.createHouse(houseInfo);
        return Result.success(created);
    }

    /**
     * 更新房源
     */
    @PutMapping("/{id}")
    public Result<Void> update(@PathVariable("id") Long id, @RequestBody HouseInfo houseInfo) {
        houseInfo.setHouseId(id);
        houseInfoService.updateHouse(houseInfo);
        return Result.success();
    }

    /**
     * 删除房源
     */
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable("id") Long id) {
        houseInfoService.deleteHouse(id);
        return Result.success();
    }

    /**
     * 获取房源详情
     */
    @GetMapping("/{id}")
    public Result<HouseInfo> detail(@PathVariable("id") Long id) {
        HouseInfo houseInfo = houseInfoService.getHouseById(id);
        return Result.success(houseInfo);
    }

    /**
     * 分页查询房源列表
     * @param current 当前页码，默认1
     * @param size 每页条数，默认10
     * @param userId 用户ID（可选过滤）
     */
    @GetMapping("/list")
    public Result<IPage<HouseInfo>> list(
            @RequestParam(defaultValue = "1") Long current,
            @RequestParam(defaultValue = "10") Long size,
            @RequestParam(required = false) Long userId) {
        Page<HouseInfo> page = new Page<>(current, size);
        IPage<HouseInfo> result = houseInfoService.listHouses(page, userId);
        return Result.success(result);
    }

    /**
     * 更新房源状态
     */
    @PutMapping("/{id}/status")
    public Result<Void> updateStatus(@PathVariable("id") Long id, @RequestBody Map<String, Integer> body) {
        Integer status = body.get("status");
        if (status == null) {
            return Result.error(400, "状态值不能为空");
        }
        houseInfoService.updateStatus(id, status);
        return Result.success();
    }

}
