package com.icesphere.camera.stitching;

import com.icesphere.camera.common.Constants;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import javax.annotation.PreDestroy;
import java.util.List;
import java.util.Map;
import java.util.concurrent.*;

/**
 * 拼接任务管理器
 * 管理异步图像拼接任务的生命周期和进度
 */
@Slf4j
@Component
public class StitchingTaskManager {

    /**
     * 任务进度存储
     */
    private final ConcurrentHashMap<String, TaskProgress> taskProgressMap = new ConcurrentHashMap<>();

    /**
     * 异步线程池
     */
    private final ExecutorService executorService;

    /**
     * 图像拼接器
     */
    private final ImageStitcher imageStitcher;

    public StitchingTaskManager() {
        this.imageStitcher = new ImageStitcher();
        // 创建固定大小的线程池
        this.executorService = new ThreadPoolExecutor(
                2, 4, 60L, TimeUnit.SECONDS,
                new LinkedBlockingQueue<>(100),
                new ThreadFactory() {
                    private int count = 0;
                    @Override
                    public Thread newThread(Runnable r) {
                        return new Thread(r, "stitching-task-" + (++count));
                    }
                },
                new ThreadPoolExecutor.CallerRunsPolicy()
        );
    }

    /**
     * 提交拼接任务
     *
     * @param imagePaths 图片路径列表
     * @param houseId 房源ID
     * @param sceneName 场景名称
     * @param callback 拼接完成回调
     * @return 任务ID
     */
    public String submitTask(List<String> imagePaths, Long houseId, String sceneName,
                             TaskCallback callback) {
        String taskId = "STITCH_" + System.currentTimeMillis() + "_" + ThreadLocalRandom.current().nextInt(1000, 9999);

        // 初始化任务进度
        TaskProgress progress = new TaskProgress();
        progress.setTaskId(taskId);
        progress.setStatus(Constants.STITCH_STATUS_QUEUED);
        progress.setProgress(0);
        progress.setMessage("任务已排队，等待处理");
        taskProgressMap.put(taskId, progress);

        // 提交异步任务
        executorService.submit(() -> {
            try {
                executeStitching(taskId, imagePaths, callback);
            } catch (Exception e) {
                log.error("拼接任务执行异常: taskId={}", taskId, e);
                TaskProgress p = taskProgressMap.get(taskId);
                if (p != null) {
                    p.setStatus(Constants.STITCH_STATUS_FAILED);
                    p.setProgress(0);
                    p.setMessage("拼接失败: " + e.getMessage());
                }
            }
        });

        return taskId;
    }

    /**
     * 获取任务进度
     *
     * @param taskId 任务ID
     * @return 进度信息，不存在返回null
     */
    public TaskProgress getProgress(String taskId) {
        return taskProgressMap.get(taskId);
    }

    /**
     * 执行拼接任务
     */
    private void executeStitching(String taskId, List<String> imagePaths, TaskCallback callback) {
        TaskProgress progress = taskProgressMap.get(taskId);
        if (progress == null) {
            return;
        }

        try {
            // 更新状态为处理中
            progress.setStatus(Constants.STITCH_STATUS_PROCESSING);
            progress.setProgress(10);
            progress.setMessage("正在读取图片...");

            // 模拟进度更新（实际拼接过程中无法精确获取进度）
            ScheduledExecutorService progressUpdater = Executors.newSingleThreadScheduledExecutor();
            progressUpdater.scheduleAtFixedRate(() -> {
                TaskProgress p = taskProgressMap.get(taskId);
                if (p != null && Constants.STITCH_STATUS_PROCESSING.equals(p.getStatus())) {
                    int current = p.getProgress();
                    if (current < 80) {
                        p.setProgress(current + 5);
                        p.setMessage("正在拼接处理中...");
                    }
                }
            }, 2, 2, TimeUnit.SECONDS);

            // 执行拼接
            progress.setProgress(20);
            progress.setMessage("正在进行图像拼接...");
            String resultPath = imageStitcher.stitchFromPaths(imagePaths);

            // 停止进度更新器
            progressUpdater.shutdownNow();

            // 更新为完成状态
            progress.setStatus(Constants.STITCH_STATUS_COMPLETED);
            progress.setProgress(100);
            progress.setMessage("拼接完成");
            progress.setResultUrl(resultPath);

            log.info("拼接任务完成: taskId={}, resultPath={}", taskId, resultPath);

            // 执行回调
            if (callback != null) {
                callback.onComplete(resultPath);
            }

        } catch (Exception e) {
            progress.setStatus(Constants.STITCH_STATUS_FAILED);
            progress.setProgress(0);
            progress.setMessage("拼接失败: " + e.getMessage());
            log.error("拼接任务失败: taskId={}", taskId, e);
        }
    }

    /**
     * 销毁时关闭线程池
     */
    @PreDestroy
    public void destroy() {
        executorService.shutdown();
        try {
            if (!executorService.awaitTermination(60, TimeUnit.SECONDS)) {
                executorService.shutdownNow();
            }
        } catch (InterruptedException e) {
            executorService.shutdownNow();
            Thread.currentThread().interrupt();
        }
    }

    /**
     * 任务进度信息
     */
    @Data
    public static class TaskProgress {
        /**
         * 任务ID
         */
        private String taskId;

        /**
         * 任务状态：QUEUED, PROCESSING, COMPLETED, FAILED
         */
        private String status;

        /**
         * 进度百分比（0-100）
         */
        private int progress;

        /**
         * 进度消息
         */
        private String message;

        /**
         * 拼接结果文件路径
         */
        private String resultUrl;
    }

    /**
     * 拼接完成回调接口
     */
    @FunctionalInterface
    public interface TaskCallback {
        /**
         * 拼接完成回调
         * @param resultPath 结果文件路径
         */
        void onComplete(String resultPath);
    }

}
