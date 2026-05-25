package com.icesphere.camera.service;

import java.util.List;
import java.util.Map;

/**
 * 图像拼接服务接口
 */
public interface StitchingService {

    /**
     * 启动拼接任务
     * @param imagePaths 待拼接的图片路径列表
     * @param houseId 房源ID
     * @param sceneName 场景名称
     * @return 任务ID
     */
    String startStitching(List<String> imagePaths, Long houseId, String sceneName);

    /**
     * 获取拼接任务进度
     * @param taskId 任务ID
     * @return 进度信息（包含status、progress、resultUrl等）
     */
    Map<String, Object> getProgress(String taskId);

}
