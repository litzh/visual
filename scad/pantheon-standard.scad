// ============================================================
//  罗马万神殿 (Pantheon, Rome) — OpenSCAD 参数化模型
// ============================================================
//  所有尺寸以米为建模单位；需渲染时整体缩放。
//  关键几何：内部为直径 43.30 m 的内切球体。
//  坐标系约定：
//    - 原点 (0,0,0) = 室内地面中心点
//    - +Z 向上，+X 指向入口/前廊方向
//    - 前廊朝 +X 方向延伸（南向入口）
// ============================================================

// ------------------------------------------------------------------
// 全局开关 / 显示控制
// ------------------------------------------------------------------
$fn = 96;                         // 圆的分段精度

SHOW_PORTICO       = true;        // 前廊（柱群+山墙+三段式檐部）
SHOW_BLOCK         = true;        // 过渡连接体（含大门）
SHOW_ROTUNDA_WALL  = true;        // 圆舱墙体
SHOW_DOME          = true;        // 穹顶壳与阶梯退台
SHOW_INTERIOR      = false;       // 内部切割：显示藻井/龛/球体（对最终实体无影响）
EXPORT_MODE        = "solid";     // "solid" = 完整实体；"interior" = 内部可视化

// ------------------------------------------------------------------
//  一、全局几何规则（速查表数据）
// ------------------------------------------------------------------
INTERIOR_D      = 43.30;          // 室内内切球体直径 / 室内总高 (m)
INTERIOR_R      = INTERIOR_D / 2; // 内球半径 21.65 m

// ------------------ 前廊 Portico ------------------
PORTICO_W       = 33.10;          // 前廊面宽 (m)
PORTICO_D       = 15.60;          // 前廊深度 (m)
COL_SHAFT_H     = 11.80;          // 柱身高度 (m)
COL_CAPITAL_H   = 1.30;           // 柱头高 (m)
COL_BASE_H      = 0.90;           // 柱础高 (m)
COL_TOTAL_H     = 14.00;          // 柱体总高 (m)
COL_BOTTOM_D    = 1.50;           // 柱底直径 (m)
COL_TOP_D       = 1.30;           // 柱顶直径 (m)
ENTAB_H         = 3.30;           // 三段式檐部总高 (m)
PEDIMENT_ANGLE  = 24;             // 山墙倾角 (deg)

// ------------------ 过渡连接体 Block ------------------
BLOCK_W         = 34.00;          // 连接体宽度 (m)
BLOCK_H         = 30.50;          // 连接体高度（与圆舱外墙等高）(m)
DOOR_W          = 6.00;           // 门洞宽 (m)
DOOR_H          = 12.60;          // 门洞高 (m)

// ------------------ 圆舱与穹顶 Rotunda & Dome ------------------
WALL_THICK      = 6.20;           // 外墙厚度 (m)
WALL_H          = 30.50;          // 外墙高度（至穹顶起拱处）
LOWER_ZONE_H    = 13.00;          // 下层柱廊与龛高度 (m)
ATTIC_ZONE_H    = 8.70;           // 阁楼层高度 (m)
DOME_BOTTOM_T   = 5.90;           // 穹顶底部厚度 (m)
DOME_TOP_T      = 1.50;           // 穹顶顶光口处厚度 (m)
OCULUS_D        = 8.92;           // 顶光口直径 (m)
COFFER_RINGS    = 5;              // 藻井环数
COFFERS_PER     = 28;             // 每环藻井数
STEP_RINGS      = 7;              // 穹顶外侧阶梯状退台环数

// ------------------------------------------------------------------
//  公共工具模块
// ------------------------------------------------------------------

// 球冠截面带：从仰角 a1 到 a2（0=赤道，90=极点）
// 用于阶梯状半球外壳：每环以各自半径 r 形成一阶退台
module sphere_band(r, a1, a2) {
    // 用 rotate_extrude 构建一个角度带
    rotate_extrude(angle = 360, $fn = 240) {
        polygon(points = [
            [r * cos(a1), r * sin(a1)],
            [r * cos(a2), r * sin(a2)],
            [0, r * sin(a2) * 0.999],
            [0, r * sin(a1) * 1.001]
        ]);
    }
}

// 分段带状球（仅为显示内部而用）
module spherical_shell_band(r, a1, a2, t) {
    rotate_extrude(angle = 360, $fn = 240) {
        polygon(points = [
            [r * cos(a1), r * sin(a1)],
            [r * cos(a2), r * sin(a2)],
            [(r + t) * cos(a2), (r + t) * sin(a2)],
            [(r + t) * cos(a1), (r + t) * sin(a1)]
        ]);
    }
}

// ------------------------------------------------------------------
//  二、前廊 Portico：16 根科林斯柱 + 三段式檐部 + 三角山墙
// ------------------------------------------------------------------

// 单根科林斯柱（柱础 + 带收分的柱身 + 柱头）
module column() {
    base_r   = COL_BOTTOM_D / 2;
    top_r    = COL_TOP_D / 2;
    shaft_h  = COL_SHAFT_H;
    cap_h    = COL_CAPITAL_H;
    base_h   = COL_BASE_H;

    // 柱础（略外扩的方形/圆形底座）
    color("gray", 0.85) {
        cylinder(h = base_h, r1 = base_r + 0.25, r2 = base_r + 0.10);
    }
    // 柱身：底径→顶径 线性收分（Entasis 简化）
    translate([0, 0, base_h])
        color("rosybrown", 0.9)
        cylinder(h = shaft_h, r1 = base_r, r2 = top_r);
    // 柱头：科林斯式（用外扩柱头近似）
    translate([0, 0, base_h + shaft_h])
        color("ivory") {
        cylinder(h = cap_h * 0.5, r1 = top_r, r2 = top_r + 0.35);
        cylinder(h = cap_h * 0.5, r1 = top_r + 0.35, r2 = top_r + 0.15);
    }
}

// 前廊整体：三段式檐部 + 山墙 + 柱群
module portico() {
    // 抬升到地面高度：整个前廊立在 0 平面之上
    // 柱群排布：前排 8 根，中排 4 根，后排 4 根
    // 前廊沿 X 轴，面宽沿 Y 轴
    // 前排（最靠外，x = 0 处主立面）
    // 后排（靠近连接体）

    // 山墙顶点高度计算：
    // 檐部顶高 = COL_TOTAL_H + ENTAB_H
    // 山墙高 = tan(24°) * (PORTICO_W / 2)
    entab_top   = COL_TOTAL_H + ENTAB_H;
    ped_h       = tan(PEDIMENT_ANGLE) * (PORTICO_W / 2);

    // --- 三段式檐部 ---
    translate([-PORTICO_D, -PORTICO_W / 2, COL_TOTAL_H])
        color("wheat") {
        // 檐底梁（Architrave/Frieze/Cornice 简化为一整块）
        cube([PORTICO_D, PORTICO_W, ENTAB_H]);
    }
    // 檐部挑出（cornice 外挑）
    translate([-PORTICO_D - 0.4, -PORTICO_W / 2 - 0.4, entab_top])
        color("wheat") {
        cube([PORTICO_D + 0.8, PORTICO_W + 0.8, 0.5]);
    }

    // --- 三角山墙 (Pediment) ---
    // 山墙倾角 24°，位于前立面（x = -PORTICO_D 侧）
    translate([-PORTICO_D, -PORTICO_W / 2, entab_top])
        color("tan") {
        linear_extrude(height = 0.6) {
            polygon(points = [
                [-0.4, 0],
                [PORTICO_W + 0.4, 0],
                [PORTICO_W / 2, ped_h]
            ]);
        }
    }

    // --- 柱群 ---
    // 前排 8 根（沿 Y 均匀分布），位于 x = -(PORTICO_D - off)
    row_x_front = -PORTICO_D + 1.0;
    row_x_mid   = -PORTICO_D * 0.55;
    row_x_back  = -0.5;

    // 前方 8 根均匀分布；中排取奇数位 4 根，后排取偶数位 4 根
    col_ys = [for (i = [0:7]) -PORTICO_W / 2 + (i + 0.5) * (PORTICO_W / 8)];

    // 前排 8 根
    for (y = col_ys) translate([row_x_front, y, 0]) column();
    // 中排 4 根（奇数索引 0,2,4,6）
    for (i = [0, 2, 4, 6]) translate([row_x_mid, col_ys[i], 0]) column();
    // 后排 4 根（偶数索引 1,3,5,7）
    for (i = [1, 3, 5, 7]) translate([row_x_back, col_ys[i], 0]) column();
}

// ------------------------------------------------------------------
//  三、过渡连接体 Intermediate Block（含大门）
// ------------------------------------------------------------------
module intermediate_block() {
    // 连接体：矩形块，位于圆舱与前廊之间
    // 圆舱外墙外半径
    rotunda_outer_r = INTERIOR_R + WALL_THICK;

    // 连接体占 X 范围：[ -door_block_depth, 0 ] 从圆舱前缘向前
    // 宽度 BLOCK_W，高度 BLOCK_H
    block_depth = BLOCK_W * 0.55;   // 深度近似取与宽度相当的一段

    color("slategray", 0.9) {
        translate([-block_depth, -BLOCK_W / 2, 0])
            cube([block_depth, BLOCK_W, BLOCK_H]);
    }

    // 大门门洞（青铜双开门）
    // 门洞位于前立面中心（x = -block_depth 侧外表面）
    color("peru", 0.95) {
        // 门框（稍外凸）
        translate([-block_depth - 0.05, -DOOR_W / 2 - 0.4, 0])
            cube([0.5, DOOR_W + 0.8, DOOR_H + 0.4]);
        // 门扇（双开，左右两扇）
        translate([-block_depth - 0.02, -DOOR_W / 2, 0])
            cube([0.1, DOOR_W / 2 - 0.05, DOOR_H]);
        translate([-block_depth - 0.02, 0.05, 0])
            cube([0.1, DOOR_W / 2 - 0.05, DOOR_H]);
    }
}

// ------------------------------------------------------------------
//  四、圆舱墙体 Rotunda Cylinder Wall
// ------------------------------------------------------------------
module rotunda_wall() {
    rotunda_outer_r = INTERIOR_R + WALL_THICK;

    // 外墙：空心圆筒（外径 = 内半径 + 墙厚）
    difference() {
        color("lightsteelblue", 0.85)
            cylinder(h = WALL_H, r = rotunda_outer_r);
        // 内腔
        translate([0, 0, -0.01])
            cylinder(h = WALL_H + 0.02, r = INTERIOR_R);
    }

    // 墙体外侧的三道环形减重拱（装饰性环形凸出）
    for (z = [WALL_H * 0.25, WALL_H * 0.5, WALL_H * 0.75]) {
        translate([0, 0, z])
            color("lightsteelblue", 0.9)
            difference() {
            cylinder(h = 0.6, r = rotunda_outer_r + 0.8);
            cylinder(h = 0.6, r = rotunda_outer_r - 0.1);
        }
    }

    // 内部 8 大龛（Recesses）：半圆/矩形相间
    if (SHOW_INTERIOR) {
        for (a = [0 : 45 : 315]) {
            rotate([0, 0, a]) {
                // 半圆形龛（朝向内侧）
                translate([INTERIOR_R - 2.5, 0, 2])
                    rotate([0, 0, 90])
                    cylinder(h = LOWER_ZONE_H - 1, r = 3.3, $fn = 64);
            }
        }
    }
}

// ------------------------------------------------------------------
//  五、穹顶 Dome & 藻井 Coffers
// ------------------------------------------------------------------
module dome() {
    rotunda_outer_r = INTERIOR_R + WALL_THICK;

    outer_r_base = INTERIOR_R + DOME_BOTTOM_T;   // 底部外半径
    outer_r_top  = INTERIOR_R + DOME_TOP_T;      // 顶部外半径
    oculus_r     = OCULUS_D / 2;

    // 穹顶起拱基线高度 = 墙高
    dome_z = WALL_H;

    // 外壳：阶梯状半球（内表面光滑，外表面阶梯退台）
    color("wheat", 0.9) {
        difference() {
            union() {
                for (i = [0 : STEP_RINGS - 1]) {
                    a1 = (i / STEP_RINGS) * 90;
                    a2 = ((i + 1) / STEP_RINGS) * 90;
                    mid = (a1 + a2) / 2;
                    r = outer_r_base - (outer_r_base - outer_r_top) * (mid / 90);
                    translate([0, 0, dome_z])
                        sphere_band(r, a1, a2);
                }
            }
            // 内腔（光滑半球）
            translate([0, 0, dome_z])
                sphere(r = INTERIOR_R);
            // 顶光口
            translate([0, 0, dome_z + INTERIOR_R - 0.01])
                cylinder(h = 4, r = oculus_r, center = true);
        }
    }

    // 顶光口青铜卷边（加高 0.5 m 环圈）
    color("darkgoldenrod", 1.0) {
        translate([0, 0, dome_z + INTERIOR_R])
            difference() {
            cylinder(h = 0.5, r = oculus_r + 0.3);
            cylinder(h = 0.5, r = oculus_r);
        }
    }

    // 藻井 Coffers（5 环 × 28 个 = 140 个）
    if (SHOW_INTERIOR) {
        for (ring = [1 : COFFER_RINGS]) {
            // 每环仰角：从穹顶底向上等分
            ang = 20 + (ring - 1) * 13;   // 约 20°~72° 分布
            zc  = dome_z + INTERIOR_R * sin(ang);
            rr  = INTERIOR_R * cos(ang);
            for (i = [0 : COFFERS_PER - 1]) {
                a = i * (360 / COFFERS_PER);
                // 藻井位置（内表面）
                px = rr * cos(a);
                py = rr * sin(a);
                pz = zc;
                // 朝向球心
                color("darkolivegreen", 0.7) {
                    translate([px, py, pz]) {
                        // 简化：绘制向外的小方块凸出（表示凹陷）
                        // 实际藻井为内凹，此处用 6×4 小盒示意
                        rotate([0, 0, a])
                            translate([0, 0, -INTERIOR_R])
                            cube([1.2, 1.2, 0.3], center = true);
                    }
                }
            }
        }
    }
}

// ------------------------------------------------------------------
//  六、主装配
// ------------------------------------------------------------------
module pantheon() {
    if (SHOW_PORTICO) {
        portico();
    }
    if (SHOW_BLOCK) {
        intermediate_block();
    }
    if (SHOW_ROTUNDA_WALL) {
        rotunda_wall();
    }
    if (SHOW_DOME) {
        dome();
    }
}

// 渲染
pantheon();
