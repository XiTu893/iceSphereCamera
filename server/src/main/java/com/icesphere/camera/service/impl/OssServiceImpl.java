package com.icesphere.camera.service.impl;

import com.aliyun.oss.OSS;
import com.aliyun.oss.OSSClientBuilder;
import com.aliyun.oss.model.ObjectMetadata;
import com.icesphere.camera.config.OssConfig;
import com.icesphere.camera.exception.BusinessException;
import com.icesphere.camera.service.OssService;
import cn.hutool.core.util.IdUtil;
import cn.hutool.core.util.StrUtil;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;

/**
 * 阿里云OSS存储服务实现
 * 当配置 oss.storage-type=aliyun 时激活
 */
@Slf4j
@Service
@ConditionalOnProperty(name = "oss.storage-type", havingValue = "aliyun")
public class OssServiceImpl implements OssService {

    private final OssConfig ossConfig;

    public OssServiceImpl(OssConfig ossConfig) {
        this.ossConfig = ossConfig;
    }

    @Override
    public String upload(MultipartFile file, String directory) {
        String originalFilename = file.getOriginalFilename();
        // 生成唯一文件名
        String extName = originalFilename != null && originalFilename.contains(".")
                ? originalFilename.substring(originalFilename.lastIndexOf("."))
                : "";
        String fileName = IdUtil.simpleUUID() + extName;
        String objectName = StrUtil.isBlank(directory) ? fileName : directory + "/" + fileName;

        OSS ossClient = new OSSClientBuilder().build(
                ossConfig.getEndpoint(),
                ossConfig.getAccessKeyId(),
                ossConfig.getAccessKeySecret());

        try (InputStream inputStream = file.getInputStream()) {
            ObjectMetadata metadata = new ObjectMetadata();
            metadata.setContentLength(file.getSize());
            metadata.setContentType(file.getContentType());

            ossClient.putObject(ossConfig.getBucketName(), objectName, inputStream, metadata);
            log.info("文件上传到OSS成功: {}", objectName);
            return getUrl(objectName);
        } catch (IOException e) {
            log.error("文件上传失败: ", e);
            throw new BusinessException("文件上传失败");
        } finally {
            ossClient.shutdown();
        }
    }

    @Override
    public boolean delete(String fileUrl) {
        // 从URL中提取objectName
        String objectName = extractObjectName(fileUrl);
        if (StrUtil.isBlank(objectName)) {
            return false;
        }

        OSS ossClient = new OSSClientBuilder().build(
                ossConfig.getEndpoint(),
                ossConfig.getAccessKeyId(),
                ossConfig.getAccessKeySecret());

        try {
            ossClient.deleteObject(ossConfig.getBucketName(), objectName);
            log.info("OSS文件删除成功: {}", objectName);
            return true;
        } catch (Exception e) {
            log.error("OSS文件删除失败: ", e);
            return false;
        } finally {
            ossClient.shutdown();
        }
    }

    @Override
    public String getUrl(String objectName) {
        // 拼接外网访问URL
        return "https://" + ossConfig.getBucketName() + "." + ossConfig.getEndpoint() + "/" + objectName;
    }

    /**
     * 从完整URL中提取objectName
     */
    private String extractObjectName(String fileUrl) {
        if (StrUtil.isBlank(fileUrl)) {
            return null;
        }
        String prefix = "https://" + ossConfig.getBucketName() + "." + ossConfig.getEndpoint() + "/";
        if (fileUrl.startsWith(prefix)) {
            return fileUrl.substring(prefix.length());
        }
        return fileUrl;
    }

}
