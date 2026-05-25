package com.icesphere.camera.service.impl;

import cn.hutool.core.io.FileUtil;
import cn.hutool.core.util.IdUtil;
import cn.hutool.core.util.StrUtil;
import com.icesphere.camera.exception.BusinessException;
import com.icesphere.camera.service.OssService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;

/**
 * 本地文件存储服务实现
 * 开发环境使用，当配置 oss.storage-type=local 时激活
 */
@Slf4j
@Service
@ConditionalOnProperty(name = "oss.storage-type", havingValue = "local", matchIfMissing = true)
public class LocalOssServiceImpl implements OssService {

    /**
     * 本地文件存储根路径
     */
    @Value("${oss.local.path:uploads}")
    private String localStoragePath;

    /**
     * 文件访问URL前缀
     */
    @Value("${oss.local.url-prefix:/uploads/}")
    private String urlPrefix;

    @Override
    public String upload(MultipartFile file, String directory) {
        String originalFilename = file.getOriginalFilename();
        // 生成唯一文件名
        String extName = "";
        if (originalFilename != null && originalFilename.contains(".")) {
            extName = originalFilename.substring(originalFilename.lastIndexOf("."));
        }
        String fileName = IdUtil.simpleUUID() + extName;

        // 构建存储路径
        String relativePath = StrUtil.isBlank(directory) ? fileName : directory + File.separator + fileName;
        String absolutePath = localStoragePath + File.separator + relativePath;

        // 确保目录存在
        File destFile = new File(absolutePath);
        FileUtil.mkParentDirs(destFile);

        try {
            file.transferTo(destFile);
            log.info("文件上传到本地成功: {}", absolutePath);
            return getUrl(relativePath.replace("\\", "/"));
        } catch (IOException e) {
            log.error("文件上传失败: ", e);
            throw new BusinessException("文件上传失败");
        }
    }

    @Override
    public boolean delete(String fileUrl) {
        String relativePath = extractRelativePath(fileUrl);
        if (StrUtil.isBlank(relativePath)) {
            return false;
        }
        String absolutePath = localStoragePath + File.separator + relativePath;
        boolean deleted = FileUtil.del(absolutePath);
        if (deleted) {
            log.info("本地文件删除成功: {}", absolutePath);
        }
        return deleted;
    }

    @Override
    public String getUrl(String objectName) {
        return urlPrefix + objectName;
    }

    /**
     * 从URL中提取相对路径
     */
    private String extractRelativePath(String fileUrl) {
        if (StrUtil.isBlank(fileUrl) || !fileUrl.startsWith(urlPrefix)) {
            return fileUrl;
        }
        return fileUrl.substring(urlPrefix.length());
    }

}
