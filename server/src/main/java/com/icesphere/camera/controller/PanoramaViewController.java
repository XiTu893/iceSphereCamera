package com.icesphere.camera.controller;

import com.icesphere.camera.common.Result;
import com.icesphere.camera.entity.PanoramaResource;
import com.icesphere.camera.service.PanoramaService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Web 3D全景浏览控制器
 * 提供Web端全景浏览页面和API
 */
@Slf4j
@Controller
@RequestMapping("/panorama")
@RequiredArgsConstructor
public class PanoramaViewController {

    private final PanoramaService panoramaService;

    /**
     * 重定向到全景浏览页面
     * 访问方式：GET /panorama/view/{id}
     *
     * @param id 全景资源ID
     */
    @GetMapping("/view/{id}")
    public void viewPanorama(@PathVariable Long id, HttpServletResponse response) throws IOException {
        PanoramaResource panorama = panoramaService.getById(id);
        if (panorama == null) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND, "全景资源不存在");
            return;
        }

        // 获取同一房源下的所有场景
        List<PanoramaResource> allScenes = panoramaService.getByHouseId(panorama.getHouseId());

        // 构建场景列表JSON
        String scenesJson = allScenes.stream()
                .map(s -> String.format(
                        "{\"sceneName\":\"%s\",\"panUrl\":\"%s\",\"createTime\":\"%s\"}",
                        escapeJson(s.getSceneName() != null ? s.getSceneName() : "未命名"),
                        escapeJson(s.getPanUrl() != null ? s.getPanUrl() : ""),
                        escapeJson(s.getCreateTime() != null ? s.getCreateTime().toString() : "")
                ))
                .collect(Collectors.joining(",", "[", "]"));

        // 重定向到全景浏览HTML页面，通过URL参数传递数据
        String redirectUrl = String.format("/panorama.html?url=%s&name=%s&scenes=%s",
                URLEncoder.encode(panorama.getPanUrl(), StandardCharsets.UTF_8.name()),
                URLEncoder.encode(panorama.getSceneName() != null ? panorama.getSceneName() : "球形全景拍摄", StandardCharsets.UTF_8.name()),
                URLEncoder.encode(scenesJson, StandardCharsets.UTF_8.name())
        );

        response.sendRedirect(redirectUrl);
    }

    /**
     * 通过房源ID浏览全景（跳转到第一个场景）
     * 访问方式：GET /panorama/house/{houseId}
     */
    @GetMapping("/house/{houseId}")
    public void viewByHouse(@PathVariable Long houseId, HttpServletResponse response) throws IOException {
        List<PanoramaResource> scenes = panoramaService.getByHouseId(houseId);
        if (scenes == null || scenes.isEmpty()) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND, "该房源暂无全景场景");
            return;
        }

        // 重定向到第一个场景
        response.sendRedirect("/panorama/view/" + scenes.get(0).getPanId());
    }

    /**
     * 获取全景浏览页面所需的API数据
     * GET /panorama/api/scenes/{houseId}
     */
    @ResponseBody
    @GetMapping("/api/scenes/{houseId}")
    public Result<List<PanoramaResource>> getScenes(@PathVariable Long houseId) {
        List<PanoramaResource> list = panoramaService.getByHouseId(houseId);
        return Result.success(list);
    }

    /**
     * 获取全景浏览页面嵌入数据（用于iframe嵌入）
     * GET /panorama/embed/{id}
     */
    @ResponseBody
    @GetMapping("/embed/{id}")
    public Result<Map<String, Object>> getEmbedData(@PathVariable Long id) {
        PanoramaResource panorama = panoramaService.getById(id);
        if (panorama == null) {
            return Result.error(404, "全景资源不存在");
        }

        List<PanoramaResource> allScenes = panoramaService.getByHouseId(panorama.getHouseId());

        Map<String, Object> data = new HashMap<>();
        data.put("panorama", panorama);
        data.put("scenes", allScenes);
        data.put("viewerUrl", "/panorama/view/" + id);

        return Result.success(data);
    }

    /**
     * 转义JSON字符串中的特殊字符
     */
    private String escapeJson(String str) {
        if (str == null) return "";
        return str.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t");
    }
}
