package com.icesphere.camera.service;

import org.springframework.web.multipart.MultipartFile;

/**
 * 对象存储服务接口
 */
public interface OssService {

    /**
     * 上传文件
     * @param file 文件
     * @param directory 存储目录
     * @return 文件访问URL
     */
    String upload(MultipartFile file, String directory);

    /**
     * 删除文件
     * @param fileUrl 文件URL
     * @return 是否成功
     */
    boolean delete(String fileUrl);

    /**
     * 获取文件访问URL
     * @param objectName 对象名称（路径）
     * @return 文件访问URL
     */
    String getUrl(String objectName);

}
