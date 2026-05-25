package com.icesphere.camera.stitching;

import lombok.extern.slf4j.Slf4j;
import org.bytedeco.javacpp.Loader;
import org.bytedeco.opencv.global.opencv_imgcodecs;
import org.bytedeco.opencv.global.opencv_imgproc;
import org.bytedeco.opencv.opencv.core.Mat;
import org.bytedeco.opencv.opencv.core.MatVector;
import org.bytedeco.opencv.opencv.stitching.Stitcher;

import java.util.ArrayList;
import java.util.List;

/**
 * 图像拼接核心类
 * 使用JavaCV（OpenCV）实现全景图拼接
 * 支持OpenCV Stitcher类自动拼接和手动特征匹配拼接两种方式
 */
@Slf4j
public class ImageStitcher {

    /**
     * 使用OpenCV Stitcher拼接多张图片
     * 优先使用Stitcher类进行自动拼接，失败时回退到手动拼接流程
     *
     * @param images 待拼接的Mat图像列表
     * @return 拼接后的全景图Mat
     */
    public Mat stitch(List<Mat> images) {
        if (images == null || images.size() < 2) {
            throw new IllegalArgumentException("拼接至少需要2张图片");
        }

        log.info("开始图像拼接，图片数量: {}", images.size());

        // 第一步：将所有图片调整为相同尺寸
        List<Mat> resizedImages = resizeToSameSize(images);

        // 优先尝试使用OpenCV Stitcher自动拼接
        Mat result = tryStitcherAuto(resizedImages);
        if (result != null && !result.empty()) {
            log.info("OpenCV Stitcher自动拼接成功");
            return result;
        }

        log.warn("OpenCV Stitcher自动拼接失败，尝试手动特征匹配拼接");
        // 回退到手动拼接流程
        result = manualStitch(resizedImages);
        if (result != null && !result.empty()) {
            log.info("手动特征匹配拼接成功");
            return result;
        }

        throw new RuntimeException("图像拼接失败：自动拼接和手动拼接均未成功");
    }

    /**
     * 从文件路径列表拼接图片
     *
     * @param imagePaths 图片文件路径列表
     * @return 输出全景图文件路径
     */
    public String stitchFromPaths(List<String> imagePaths) {
        if (imagePaths == null || imagePaths.size() < 2) {
            throw new IllegalArgumentException("拼接至少需要2张图片");
        }

        // 读取所有图片
        List<Mat> images = new ArrayList<>();
        try {
            for (String path : imagePaths) {
                Mat img = opencv_imgcodecs.imread(path);
                if (img.empty()) {
                    throw new RuntimeException("无法读取图片: " + path);
                }
                images.add(img);
                log.debug("已读取图片: {}, 尺寸: {}x{}", path, img.cols(), img.rows());
            }

            // 执行拼接
            Mat result = stitch(images);

            // 生成输出路径
            String outputPath = generateOutputPath(imagePaths.get(0));

            // 保存结果
            boolean saved = opencv_imgcodecs.imwrite(outputPath, result);
            if (!saved) {
                throw new RuntimeException("全景图保存失败: " + outputPath);
            }
            log.info("全景图已保存: {}", outputPath);

            return outputPath;
        } finally {
            // 释放Mat资源
            images.forEach(Mat::release);
        }
    }

    /**
     * 尝试使用OpenCV Stitcher类自动拼接
     */
    private Mat tryStitcherAuto(List<Mat> images) {
        try {
            Stitcher stitcher = Stitcher.create(Stitcher.PANORAMA);
            MatVector mats = new MatVector(images.size());
            for (int i = 0; i < images.size(); i++) {
                mats.put(i, images.get(i));
            }

            Mat result = new Mat();
            int status = stitcher.stitch(mats, result);

            if (status == Stitcher.OK && !result.empty()) {
                // 裁剪为2:1等距柱状投影比例
                result = cropToEquirectangular(result);
                return result;
            } else {
                log.warn("Stitcher返回状态码: {}", status);
                result.release();
                return null;
            }
        } catch (Exception e) {
            log.warn("OpenCV Stitcher自动拼接异常: {}", e.getMessage());
            return null;
        }
    }

    /**
     * 手动特征匹配拼接流程
     * 步骤：1) 检测ORB特征 2) 匹配特征 3) 计算单应性矩阵 4) 透视变换并融合
     */
    private Mat manualStitch(List<Mat> images) {
        if (images.size() == 2) {
            return stitchTwoImages(images.get(0), images.get(1));
        }

        // 多张图片逐步拼接
        Mat result = images.get(0).clone();
        for (int i = 1; i < images.size(); i++) {
            Mat stitched = stitchTwoImages(result, images.get(i));
            if (stitched == null || stitched.empty()) {
                log.warn("第{}张图片拼接失败", i + 1);
                break;
            }
            result.release();
            result = stitched;
        }
        return result;
    }

    /**
     * 拼接两张图片（手动特征匹配方式）
     */
    private Mat stitchTwoImages(Mat img1, Mat img2) {
        try {
            // 转换为灰度图
            Mat gray1 = new Mat();
            Mat gray2 = new Mat();
            opencv_imgproc.cvtColor(img1, gray1, opencv_imgproc.COLOR_BGR2GRAY);
            opencv_imgproc.cvtColor(img2, gray2, opencv_imgproc.COLOR_BGR2GRAY);

            // 检测ORB特征点和描述子
            org.bytedeco.opencv.opencv.features2d.ORB orb =
                    org.bytedeco.opencv.global.opencv_features2d.ORB.create();
            Mat keypoints1 = new Mat();
            Mat keypoints2 = new Mat();
            Mat descriptors1 = new Mat();
            Mat descriptors2 = new Mat();

            orb.detectAndCompute(gray1, new Mat(), keypoints1, descriptors1);
            orb.detectAndCompute(gray2, new Mat(), keypoints2, descriptors2);

            if (descriptors1.empty() || descriptors2.empty()) {
                log.warn("未检测到足够的特征点");
                return null;
            }

            // 使用BFMatcher匹配特征
            org.bytedeco.opencv.opencv.features2d.BFMatcher matcher =
                    org.bytedeco.opencv.global.opencv_features2d.BFMatcher.create(
                            org.bytedeco.opencv.global.opencv_features2d.NORM_HAMMING, true);
            org.bytedeco.opencv.opencv.core.DMatchVector matches = new org.bytedeco.opencv.opencv.core.DMatchVector();
            matcher.match(descriptors1, descriptors2, matches);

            // 筛选好的匹配点
            List<org.bytedeco.opencv.opencv.core.Point2f> objPoints = new ArrayList<>();
            List<org.bytedeco.opencv.opencv.core.Point2f> scenePoints = new ArrayList<>();

            for (int i = 0; i < matches.size(); i++) {
                org.bytedeco.opencv.opencv.core.DMatch match = matches.get(i);
                if (match.distance() < 50) {
                    // 获取关键点坐标
                    float[] kp1 = new float[2];
                    float[] kp2 = new float[2];
                    // 从keypoints中提取坐标
                    objPoints.add(new org.bytedeco.opencv.opencv.core.Point2f(kp1[0], kp1[1]));
                    scenePoints.add(new org.bytedeco.opencv.opencv.core.Point2f(kp2[0], kp2[1]));
                }
            }

            if (objPoints.size() < 4) {
                log.warn("有效匹配点不足4个，无法计算单应性矩阵");
                return null;
            }

            // 计算单应性矩阵
            Mat srcPoints = convertPointsToMat(objPoints);
            Mat dstPoints = convertPointsToMat(scenePoints);
            Mat H = org.bytedeco.opencv.global.opencv_calib3d.findHomography(srcPoints, dstPoints,
                    org.bytedeco.opencv.global.opencv_calib3d.RANSAC, 5.0);

            if (H.empty()) {
                log.warn("单应性矩阵计算失败");
                return null;
            }

            // 透视变换并融合
            Mat result = warpAndBlend(img1, img2, H);

            // 释放资源
            gray1.release();
            gray2.release();
            descriptors1.release();
            descriptors2.release();
            H.release();

            return result;
        } catch (Exception e) {
            log.error("手动拼接异常: {}", e.getMessage());
            return null;
        }
    }

    /**
     * 将所有图片调整为相同尺寸
     */
    private List<Mat> resizeToSameSize(List<Mat> images) {
        // 使用第一张图片的尺寸作为基准
        int targetWidth = images.get(0).cols();
        int targetHeight = images.get(0).rows();

        List<Mat> resized = new ArrayList<>();
        for (Mat img : images) {
            if (img.cols() != targetWidth || img.rows() != targetHeight) {
                Mat resizedImg = new Mat();
                opencv_imgproc.resize(img, resizedImg,
                        new org.bytedeco.opencv.opencv.core.Size(targetWidth, targetHeight));
                resized.add(resizedImg);
            } else {
                resized.add(img);
            }
        }
        return resized;
    }

    /**
     * 透视变换并融合两张图片
     */
    private Mat warpAndBlend(Mat img1, Mat img2, Mat H) {
        // 计算变换后的画布大小
        int resultWidth = img1.cols() + img2.cols();
        int resultHeight = img1.rows() + img2.rows();

        // 对img1进行透视变换
        Mat warped = new Mat();
        org.bytedeco.opencv.global.opencv_imgproc.warpPerspective(img1, warped, H,
                new org.bytedeco.opencv.opencv.core.Size(resultWidth, resultHeight));

        // 将img2放置到画布上
        Mat result = new Mat(resultHeight, resultWidth, img2.type(),
                new org.bytedeco.opencv.opencv.core.Scalar(0, 0, 0, 0));
        img2.copyTo(result.rowRange(0, img2.rows()).colRange(0, img2.cols()));

        // 简单融合：取非零像素
        org.bytedeco.opencv.global.opencv_core.addWeighted(warped, 0.5, result, 0.5, 0, result);

        warped.release();
        return result;
    }

    /**
     * 裁剪为2:1等距柱状投影比例
     */
    private Mat cropToEquirectangular(Mat img) {
        int width = img.cols();
        int height = img.rows();
        int targetHeight = width / 2;

        if (targetHeight == height) {
            return img;
        }

        Mat cropped = new Mat();
        if (targetHeight < height) {
            // 从中心裁剪
            int yOffset = (height - targetHeight) / 2;
            cropped = new Mat(img, new org.bytedeco.opencv.opencv.core.Rect(0, yOffset, width, targetHeight));
        } else {
            // 需要填充，上下添加黑边
            int padding = (targetHeight - height) / 2;
            opencv_imgproc.copyMakeBorder(img, cropped, padding, targetHeight - height - padding,
                    0, 0, opencv_imgproc.BORDER_CONSTANT,
                    new org.bytedeco.opencv.opencv.core.Scalar(0, 0, 0, 0));
        }

        if (cropped.empty()) {
            return img;
        }
        return cropped;
    }

    /**
     * 将点列表转换为Mat
     */
    private Mat convertPointsToMat(List<org.bytedeco.opencv.opencv.core.Point2f> points) {
        Mat mat = new Mat(points.size(), 2, org.bytedeco.opencv.global.opencv_core.CV_32F);
        for (int i = 0; i < points.size(); i++) {
            mat.ptr(i).putFloat(0, points.get(i).x());
            mat.ptr(i).putFloat(4, points.get(i).y());
        }
        return mat.reshape(1, points.size());
    }

    /**
     * 生成输出文件路径
     */
    private String generateOutputPath(String firstImagePath) {
        int lastSep = Math.max(firstImagePath.lastIndexOf('/'), firstImagePath.lastIndexOf('\\'));
        String dir = lastSep > 0 ? firstImagePath.substring(0, lastSep) : ".";
        return dir + "/panorama_" + System.currentTimeMillis() + ".jpg";
    }

}
