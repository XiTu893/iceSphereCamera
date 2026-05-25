package com.icesphere.camera.controller;

import com.icesphere.camera.common.Result;
import com.icesphere.camera.entity.PanoramaResource;
import com.icesphere.camera.service.PanoramaService;
import com.icesphere.camera.service.StitchingService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * 全景资源控制器
 * 处理全景图的拼接、查询和热点管理
 */
@Slf4j
@RestController
@RequestMapping("/api/panorama")
@RequiredArgsConstructor
public class PanoramaController {

    private final PanoramaService panoramaService;
    private final StitchingService stitchingService;

    /**
     * 启动拼接任务
     * 接收图片文件ID列表、房源ID和场景名称，启动异步拼接
     */
    @PostMapping("/stitch")
    public Result<Map<String, Object>> stitch(@RequestBody Map<String, Object> params) {
        @SuppressWarnings("unchecked")
        List<String> imagePaths = (List<String>) params.get("imagePaths");
        Long houseId = Long.valueOf(params.get("houseId").toString());
        String sceneName = (String) params.get("sceneName");

        String taskId = stitchingService.startStitching(imagePaths, houseId, sceneName);

        Map<String, Object> data = Map.of(
                "taskId", taskId,
                "message", "拼接任务已提交"
        );
        return Result.success(data);
    }

    /**
     * 获取拼接任务进度
     */
    @GetMapping("/stitch/{taskId}")
    public Result<Map<String, Object>> getStitchProgress(@PathVariable String taskId) {
        Map<String, Object> progress = stitchingService.getProgress(taskId);
        return Result.success(progress);
    }

    /**
     * 保存全景资源信息
     */
    @PostMapping
    public Result<PanoramaResource> save(@RequestBody PanoramaResource panorama) {
        PanoramaResource saved = panoramaService.savePanorama(panorama);
        return Result.success(saved);
    }

    /**
     * 根据房源ID获取全景列表
     */
    @GetMapping("/list")
    public Result<List<PanoramaResource>> listByHouseId(@RequestParam Long houseId) {
        List<PanoramaResource> list = panoramaService.getByHouseId(houseId);
        return Result.success(list);
    }

    /**
     * 获取全景详情
     */
    @GetMapping("/{id}")
    public Result<PanoramaResource> detail(@PathVariable("id") Long id) {
        PanoramaResource panorama = panoramaService.getById(id);
        return Result.success(panorama);
    }

    /**
     * 更新热点数据
     */
    @PutMapping("/{id}/hotspot")
    public Result<Void> updateHotspot(@PathVariable("id") Long id, @RequestBody Map<String, String> body) {
        String hotData = body.get("hotData");
        if (hotData == null) {
            return Result.error(400, "热点数据不能为空");
        }
        panoramaService.updateHotData(id, hotData);
        return Result.success();
    }

}
