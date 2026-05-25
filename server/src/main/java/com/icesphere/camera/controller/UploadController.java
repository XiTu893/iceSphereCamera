package com.icesphere.camera.controller;

import com.icesphere.camera.common.Result;
import com.icesphere.camera.service.OssService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 文件上传控制器
 * 处理图片上传到OSS
 */
@Slf4j
@RestController
@RequestMapping("/api/upload")
@RequiredArgsConstructor
public class UploadController {

    private final OssService ossService;

    /**
     * 上传单张图片
     */
    @PostMapping("/image")
    public Result<Map<String, String>> uploadImage(@RequestParam("file") MultipartFile file) {
        if (file.isEmpty()) {
            return Result.error(400, "上传文件不能为空");
        }

        // 校验文件类型
        String contentType = file.getContentType();
        if (contentType == null || !contentType.startsWith("image/")) {
            return Result.error(400, "只能上传图片文件");
        }

        String url = ossService.upload(file, "images");
        Map<String, String> data = new HashMap<>();
        data.put("url", url);
        data.put("originalName", file.getOriginalFilename());
        return Result.success(data);
    }

    /**
     * 批量上传图片
     */
    @PostMapping("/images")
    public Result<List<Map<String, String>>> uploadImages(@RequestParam("files") MultipartFile[] files) {
        if (files == null || files.length == 0) {
            return Result.error(400, "上传文件不能为空");
        }

        List<Map<String, String>> resultList = new ArrayList<>();
        for (MultipartFile file : files) {
            if (file.isEmpty()) {
                continue;
            }
            // 校验文件类型
            String contentType = file.getContentType();
            if (contentType == null || !contentType.startsWith("image/")) {
                continue;
            }

            String url = ossService.upload(file, "images");
            Map<String, String> item = new HashMap<>();
            item.put("url", url);
            item.put("originalName", file.getOriginalFilename());
            resultList.add(item);
        }

        return Result.success(resultList);
    }

}
