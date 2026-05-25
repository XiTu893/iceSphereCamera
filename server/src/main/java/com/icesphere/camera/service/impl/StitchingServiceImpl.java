package com.icesphere.camera.service.impl;

import com.icesphere.camera.entity.PanoramaResource;
import com.icesphere.camera.service.OssService;
import com.icesphere.camera.service.PanoramaService;
import com.icesphere.camera.service.StitchingService;
import com.icesphere.camera.stitching.StitchingTaskManager;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 图像拼接服务实现类
 * 使用StitchingTaskManager管理异步拼接任务
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class StitchingServiceImpl implements StitchingService {

    private final StitchingTaskManager taskManager;
    private final PanoramaService panoramaService;
    private final OssService ossService;

    @Override
    public String startStitching(List<String> imagePaths, Long houseId, String sceneName) {
        if (imagePaths == null || imagePaths.size() < 2) {
            throw new com.icesphere.camera.exception.BusinessException("拼接至少需要2张图片");
        }

        // 生成任务ID
        String taskId = taskManager.submitTask(imagePaths, houseId, sceneName, resultPath -> {
            // 拼接完成后的回调：保存全景资源记录
            try {
                String panUrl = ossService.getUrl(resultPath);
                PanoramaResource panorama = new PanoramaResource();
                panorama.setHouseId(houseId);
                panorama.setSceneName(sceneName);
                panorama.setPanUrl(panUrl);
                panoramaService.savePanorama(panorama);
                log.info("全景资源保存成功: houseId={}, sceneName={}", houseId, sceneName);
            } catch (Exception e) {
                log.error("保存全景资源失败: ", e);
            }
        });

        log.info("拼接任务已提交: taskId={}, 图片数量={}", taskId, imagePaths.size());
        return taskId;
    }

    @Override
    public Map<String, Object> getProgress(String taskId) {
        StitchingTaskManager.TaskProgress progress = taskManager.getProgress(taskId);
        if (progress == null) {
            throw new com.icesphere.camera.exception.BusinessException("任务不存在");
        }

        Map<String, Object> result = new HashMap<>();
        result.put("taskId", taskId);
        result.put("status", progress.getStatus());
        result.put("progress", progress.getProgress());
        result.put("message", progress.getMessage());
        if (progress.getResultUrl() != null) {
            result.put("resultUrl", progress.getResultUrl());
        }
        return result;
    }

}
