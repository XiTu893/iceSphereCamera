-- =====================================================
-- 冰球全景看房系统 数据库初始化脚本
-- =====================================================

-- 创建数据库
CREATE DATABASE IF NOT EXISTS `ice_sphere_camera` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `ice_sphere_camera`;

-- =====================================================
-- 系统用户表
-- =====================================================
DROP TABLE IF EXISTS `sys_user`;
CREATE TABLE `sys_user` (
    `user_id`     BIGINT       NOT NULL AUTO_INCREMENT COMMENT '用户ID',
    `username`    VARCHAR(50)  NOT NULL                COMMENT '用户名',
    `password`    VARCHAR(100) NOT NULL                COMMENT '密码（BCrypt加密）',
    `phone`       VARCHAR(20)  DEFAULT NULL            COMMENT '手机号',
    `user_type`   TINYINT      NOT NULL DEFAULT 1      COMMENT '用户类型：1=普通用户 2=经纪人 3=管理员',
    `status`      TINYINT      NOT NULL DEFAULT 1      COMMENT '状态：0=禁用 1=正常',
    `create_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (`user_id`),
    UNIQUE KEY `uk_username` (`username`),
    KEY `idx_phone` (`phone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='系统用户表';

-- =====================================================
-- 房源信息表
-- =====================================================
DROP TABLE IF EXISTS `house_info`;
CREATE TABLE `house_info` (
    `house_id`        BIGINT        NOT NULL AUTO_INCREMENT COMMENT '房源ID',
    `user_id`         BIGINT        NOT NULL                COMMENT '所属用户ID',
    `community_name`  VARCHAR(100)  NOT NULL                COMMENT '小区名称',
    `house_type`      VARCHAR(50)   DEFAULT NULL            COMMENT '户型（如：三室两厅）',
    `area`            DECIMAL(10,2) DEFAULT NULL            COMMENT '面积（平方米）',
    `price`           DECIMAL(12,2) DEFAULT NULL            COMMENT '价格（万元）',
    `status`          TINYINT       NOT NULL DEFAULT 0      COMMENT '状态：0=待审核 1=已上线 2=已下架',
    `create_time`     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (`house_id`),
    KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='房源信息表';

-- =====================================================
-- 全景资源表
-- =====================================================
DROP TABLE IF EXISTS `panorama_resource`;
CREATE TABLE `panorama_resource` (
    `pan_id`      BIGINT       NOT NULL AUTO_INCREMENT COMMENT '全景ID',
    `house_id`    BIGINT       NOT NULL                COMMENT '关联房源ID',
    `scene_name`  VARCHAR(100) DEFAULT NULL            COMMENT '场景名称（如：客厅、卧室）',
    `pan_url`     VARCHAR(500) NOT NULL                COMMENT '全景图URL',
    `hot_data`    TEXT         DEFAULT NULL            COMMENT '热点数据（JSON格式）',
    `create_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (`pan_id`),
    KEY `idx_house_id` (`house_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='全景资源表';

-- =====================================================
-- 插入示例数据
-- =====================================================

-- 管理员账号（密码: admin123）
INSERT INTO `sys_user` (`username`, `password`, `phone`, `user_type`, `status`) VALUES
('admin', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi', '13800000001', 3, 1);

-- 经纪人账号（密码: agent123）
INSERT INTO `sys_user` (`username`, `password`, `phone`, `user_type`, `status`) VALUES
('agent01', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi', '13800000002', 2, 1);

-- 普通用户账号（密码: user123）
INSERT INTO `sys_user` (`username`, `password`, `phone`, `user_type`, `status`) VALUES
('user01', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi', '13800000003', 1, 1);

-- 示例房源
INSERT INTO `house_info` (`user_id`, `community_name`, `house_type`, `area`, `price`, `status`) VALUES
(2, '翡翠湾花园', '三室两厅', 120.50, 350.00, 1),
(2, '阳光海岸', '两室一厅', 89.30, 280.00, 1),
(2, '星河湾', '四室两厅', 156.80, 520.00, 0),
(2, '碧水蓝天', '一室一厅', 45.60, 120.00, 2);

-- 示例全景资源
INSERT INTO `panorama_resource` (`house_id`, `scene_name`, `pan_url`, `hot_data`) VALUES
(1, '客厅', '/uploads/panorama/living_room_001.jpg', '[{"type":"scene","position":{"yaw":0,"pitch":0},"targetSceneId":2,"tooltip":"去卧室"}]'),
(1, '主卧', '/uploads/panorama/bedroom_001.jpg', '[{"type":"scene","position":{"yaw":180,"pitch":0},"targetSceneId":1,"tooltip":"去客厅"}]'),
(2, '客厅', '/uploads/panorama/living_room_002.jpg', NULL),
(2, '阳台', '/uploads/panorama/balcony_002.jpg', NULL);
