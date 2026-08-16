// ============================================================
// 罗马万神殿 Pantheon — OpenSCAD 模型
// 几何核心：直径 43.30 m 的内切参考球体
//   球心位于 (0,0,INNER_R)，球底切于室内地面 z=0，
//   球顶切于顶光口 (Oculus)。
// 三大模块：矩形前廊 Portico / 过渡连接体 Block / 圆舱与穹顶 Rotunda & Dome
// ============================================================

/* [精度] */
QUALITY = 2;            // [1:快速预览, 2:标准, 3:精细]
/* [细节] */
SHOW_NICHE_COLUMNS    = true;
SHOW_ATTIC_RELIEF     = true;
SHOW_REFERENCE_SPHERE = false; // 显示直径 43.30 m 的内切参考球体

// ---------- 全局几何参数 ----------
INNER_R    = 43.30 / 2;        // 室内半径 / 内切球半径 = 21.65 m
WALL_T     = 6.2;              // 圆舱外墙厚度
OUTER_R    = INNER_R + WALL_T; // 圆舱外半径 = 27.85 m
DRUM_H     = 30.5;             // 圆舱外墙高度
SPRING_Z   = INNER_R;          // 穹顶起拱高度（球赤道面）

OC_DIA     = 8.92;             // 顶光口直径
OC_R       = OC_DIA / 2;       // 4.46 m
OC_THETA   = acos(OC_R / INNER_R); // 顶光口边缘对应的球面极角(度)

DOME_T_BOT = 5.9;              // 穹顶底部厚度
DOME_T_TOP = 1.5;              // 穹顶顶部（顶光口处）厚度

// ---------- 前廊 Portico ----------
PORT_W     = 33.1;             // 面宽
PORT_D     = 15.6;             // 深度
PORT_FRONT = -(OUTER_R + PORT_D); // 前廊前缘 x
PORT_REAR  = -OUTER_R;            // 前廊后缘 = 过渡块前脸 x
PORT_CX    = (PORT_FRONT + PORT_REAR) / 2;

COL_H      = 14.0;             // 柱总高
SHAFT_H    = 11.8;             // 柱身高
CAP_H      = 1.3;              // 柱头高
BASE_H     = 0.9;              // 柱础高
SHAFT_R_B  = 1.5 / 2;          // 柱底半径
SHAFT_R_T  = 1.3 / 2;          // 柱顶半径（线性收分近似 Entasis）

ENT_H      = 3.3;              // 三段式檐部总高
PED_ANGLE  = 24;               // 山墙倾角
PED_H      = tan(PED_ANGLE) * (PORT_W / 2); // 山墙高度

// 三排柱网（前 8 / 中 4 / 后 4）
COL_FRONT_X = PORT_FRONT + 0.85;
COL_MID_X   = PORT_FRONT + 7.65;
COL_REAR_X  = PORT_REAR - 1.15;
COL_Y_FRONT = [-14.49, -10.35, -6.21, -3.00, 3.00, 6.21, 10.35, 14.49]; // 中央开间加宽至 6.0 m，直通大门
COL_Y_MID   = [-10.35, -4.14, 4.14, 10.35];
COL_Y_REAR  = [-10.35, -6.21, 6.21, 10.35];

// ---------- 过渡连接体 Block ----------
BLOCK_W     = 34.0;            // 宽度
BLOCK_FRONT = PORT_REAR;       // 前脸（装大门，朝前廊）
BLOCK_REAR  = -sqrt(OUTER_R * OUTER_R - (BLOCK_W / 2) * (BLOCK_W / 2)); // 与圆舱外墙相切收尾
BLOCK_D     = BLOCK_REAR - BLOCK_FRONT; // 深度（沿 x，正数）
BLOCK_CX    = (BLOCK_FRONT + BLOCK_REAR) / 2;

DOOR_W      = 6.0;             // 门洞宽
DOOR_H      = 12.6;            // 门洞高
DOOR_INNER  = -21.4;           // 门洞内端（全宽穿入圆舱内壁）
DOOR_LEN    = DOOR_INNER - BLOCK_FRONT; // 门洞进深（正数）
DOOR_CX     = (BLOCK_FRONT + DOOR_INNER) / 2;

// ---------- 室内墙体与龛 ----------
NICHE_H     = 13.0;            // 下层高度
NICHE_R     = 3.0;             // 半圆龛半径（开口弦宽 2*sqrt(r^2-offset^2)）
NICHE_OFF   = 1.0;             // 半圆龛圆心越过内壁的距离（形成开口）
NICHE_D     = 3.8;             // 矩形龛进深
NICHE_W     = 3.4;             // 矩形龛宽
APSE_R      = 3.4;             // 主龛半径
APSE_OFF    = 1.2;             // 主龛圆心越过内壁的距离

// ---------- 藻井 Coffers ----------
N_RINGS    = 5;
N_COLS     = 28;
RING_ANGLES = [10, 23, 36, 49, 62]; // 自穹顶赤道面起算的极角(度)

// ---------- 分段精度 ----------
SEG = QUALITY <= 1 ? 96 : (QUALITY == 2 ? 160 : 256);
DOME_SEG = QUALITY <= 1 ? 144 : (QUALITY == 2 ? 240 : 360);

// ---------- 材质 ----------
C_CONCRETE  = "#C7B396";  // 混凝土/火山灰抹面
C_MARBLE    = "#F0E9D8";  // 白色大理石
C_GRANITE_R = "#9A4A3A";  // 阿斯旺红花岗岩
C_GRANITE_G = "#8D8D8D";  // 灰色花岗岩
C_BRONZE    = "#8A5A2B";  // 青铜
C_DOOR      = "#5C3A1E";  // 深色青铜大门
C_TRAVERTINE= "#D9CBB2";  // 石灰华地面
C_PORPHYRY  = "#8E3B46";  // 斑岩
C_GIALLO    = "#E2BF5F";  // 黄大理石

// ============================================================
// 工具函数
// ============================================================
function dome_th(t) = DOME_T_BOT + (DOME_T_TOP - DOME_T_BOT) * t / OC_THETA;

// ============================================================
// 穹顶外壳（内壳为光滑半球，外壳厚度 5.9 -> 1.5 m 线性递减）
// ============================================================
module dome_shell() {
    N = 120;
    outer = [ for (i = [0 : N])
        let (t = OC_THETA * i / N,
             r = INNER_R + dome_th(t))
        [ r * cos(t), INNER_R + r * sin(t) ] ];
    inner = [ for (i = [N : -1 : 0])
        let (t = OC_THETA * i / N)
        [ INNER_R * cos(t), INNER_R + INNER_R * sin(t) ] ];
    rotate_extrude(angle = 360, $fn = DOME_SEG)
        polygon(points = concat(outer, inner));
}

// ============================================================
// 单个藻井楔块
//   局部坐标系：+x = 向外(径向)，+y = 环向，+z = 子午线向上(朝顶光口)
//   深面中心沿 +z 偏移 bias —— 透视矫正：
//   站在地面中央仰视时，藻井内部阶梯朝向视点倾斜，
//   而非垂直于球面做无脑平移挤出。
// ============================================================
module coffer_wedge(d, w, h, bias, over = 0.35) {
    w2 = w * 0.82;
    h2 = h * 0.86;
    hull() {
        // 开口面（略向室内凸出，保证差集干净）
        translate([-over, 0, 0])
            cube([0.02, w, h], center = true);
        // 凹底面：向顶光口方向偏置（透视矫正）
        translate([d, 0, bias])
            cube([0.02, w2, h2], center = true);
    }
}

// 5 环 × 28 列 = 140 个藻井（极坐标阵列，奇偶环错位半个柱距）
module coffers_cutters() {
    for (ri = [0 : N_RINGS - 1]) {
        theta = RING_ANGLES[ri];
        th    = dome_th(theta);
        cell  = 2 * PI * INNER_R * cos(theta) / N_COLS;
        w     = cell * 0.56;
        h     = 3.0 * (1 - 0.36 * ri / (N_RINGS - 1));
        d     = th * 0.52;
        bias  = h * 0.25;
        off   = (ri % 2 == 0) ? 0 : 180 / N_COLS;
        for (ci = [0 : N_COLS - 1]) {
            phi = 360 * ci / N_COLS + off;
            rotate([0, 0, phi])
                rotate([0, -theta, 0])
                    translate([INNER_R, 0, 0])
                        coffer_wedge(d, w, h, bias);
        }
    }
}

module dome_with_coffers() {
    difference() {
        dome_shell();
        coffers_cutters();
    }
}

// 穹顶外侧三道阶梯状环形退台（位于实体墙筒顶部露出的穹顶外表面上）
module step_rings() {
    // z, 该高度处穹顶外半径, 环厚
    ring(27.0, 26.45, 0.45, 0.55);
    ring(32.5, 23.45, 0.45, 0.55);
    ring(38.0, 19.30, 0.40, 0.50);
}

module ring(z, r, t, h) {
    translate([0, 0, z - h / 2])
        difference() {
            cylinder(r = r + t, h = h, $fn = SEG);
            cylinder(r = r - t, h = h + 0.02, $fn = SEG);
        }
}

// ============================================================
// 下层大龛（主龛 + 6 侧龛；第 8 个为入口，留空）
//   45/135/225/315°：半圆龛；90/270°：矩形龛
// ============================================================
module niche_cyl(angle, r, off) {
    rotate([0, 0, angle])
        translate([INNER_R + off, 0, -0.05])
            cylinder(r = r, h = NICHE_H + 0.1, $fn = SEG);
}

module niche_rect(angle, d, w) {
    rotate([0, 0, angle])
        translate([INNER_R + d / 2, 0, NICHE_H / 2])
            cube([d, w, NICHE_H + 0.1], center = true);
}

module niches() {
    niche_cyl(0, APSE_R, APSE_OFF);        // 正对入口的主龛
    niche_cyl(45, NICHE_R, NICHE_OFF);     // 半圆龛
    niche_rect(90, NICHE_D, NICHE_W);      // 矩形龛
    niche_cyl(135, NICHE_R, NICHE_OFF);    // 半圆龛
    niche_rect(225, NICHE_D, NICHE_W);     // 矩形龛
    niche_cyl(270, NICHE_R, NICHE_OFF);    // 半圆龛
    niche_rect(315, NICHE_D, NICHE_W);     // 矩形龛
}

// 阁楼层浅龛/假窗饰面（上层 8.7 m 高区域内的灰泥假窗）
module attic_recesses() {
    for (i = [0 : 27]) {
        rotate([0, 0, i * 360 / 28 + 360 / 56])
            translate([INNER_R - 0.05, 0, 17.0])
                cube([1.6, 1.7, 4.2], center = true);
    }
}

// 龛前成对科林斯小柱
module small_column() {
    color(C_MARBLE)
        translate([0, 0, 0])
            cylinder(h = 0.5, r1 = 0.55, r2 = 0.42, $fn = 48);
    color(C_GRANITE_R)
        translate([0, 0, 0.5])
            cylinder(h = 11.2, r1 = 0.38, r2 = 0.30, $fn = 48);
    color(C_MARBLE)
        translate([0, 0, 11.7])
            cylinder(h = 1.0, r1 = 0.32, r2 = 0.52, $fn = 48);
    translate([0, 0, 12.7])
        color(C_MARBLE)
            cylinder(h = 0.3, r = 0.55, $fn = 48);
}

module niche_columns() {
    if (SHOW_NICHE_COLUMNS) {
        for (a = [0, 45, 90, 135, 225, 270, 315]) {
            off = (a == 0) ? 3.0 : 2.4;
            for (s = [-1, 1])
                rotate([0, 0, a])
                    translate([INNER_R - 0.45, s * off, 0])
                        small_column();
        }
    }
}

// ============================================================
// 主体：圆舱墙体 + 穹顶 + 过渡块，减去内部球空间、门洞与龛
// ============================================================
module main_mass() {
    difference() {
        union() {
            // 1) 圆舱外墙筒，先挖出内部圆柱空间 + 参考球腔 + 龛
            difference() {
                cylinder(r = OUTER_R, h = DRUM_H, $fn = SEG);
                union() {
                    // 室内圆柱空间（地面 ~ 起拱面）
                    cylinder(r = INNER_R, h = INNER_R, $fn = SEG);
                    // 内切参考球（下半球包在圆柱空间内，上半球为穹顶内壳）
                    translate([0, 0, INNER_R])
                        sphere(r = INNER_R, $fn = SEG);
                    niches();
                    if (SHOW_ATTIC_RELIEF)
                        attic_recesses();
                }
            }
            // 2) 穹顶外壳（已挖藻井）
            dome_with_coffers();
            // 3) 穹顶外阶梯环
            step_rings();
            // 4) 过渡连接体（前脸装大门；侧壁与圆舱外墙相切）
            translate([BLOCK_CX, 0, DRUM_H / 2])
                cube([BLOCK_D, BLOCK_W, DRUM_H], center = true);
        }
        // 门洞：穿过渡块 + 外墙，止于室内空间
        translate([DOOR_CX, 0, DOOR_H / 2])
            cube([DOOR_LEN, DOOR_W, DOOR_H], center = true);
    }
}

// ============================================================
// 顶光口青铜卷边（无玻璃封口）
// ============================================================
module oculus_rim() {
    color(C_BRONZE)
        translate([0, 0, 44.25])
            difference() {
                cylinder(r = 5.0, h = 0.5, $fn = DOME_SEG);
                cylinder(r = 4.35, h = 0.6, $fn = DOME_SEG);
            }
}

// ============================================================
// 前廊构件
// ============================================================
module column(granite = C_GRANITE_R) {
    // 柱础
    color(C_MARBLE) {
        cylinder(h = 0.18, r1 = 1.02, r2 = 0.95, $fn = 64);
        translate([0, 0, 0.18])
            cylinder(h = BASE_H - 0.18, r1 = 0.95, r2 = SHAFT_R_B, $fn = 64);
    }
    // 柱身（线性收分近似 Entasis）
    color(granite)
        translate([0, 0, BASE_H])
            cylinder(h = SHAFT_H, r1 = SHAFT_R_B, r2 = SHAFT_R_T, $fn = 64);
    // 科林斯柱头（简化：两层翻卷 + 顶板）
    color(C_MARBLE) {
        translate([0, 0, BASE_H + SHAFT_H])
            cylinder(h = 0.45, r1 = SHAFT_R_T, r2 = 0.82, $fn = 64);
        translate([0, 0, BASE_H + SHAFT_H + 0.45])
            cylinder(h = 0.55, r1 = 0.82, r2 = 0.62, $fn = 64);
        translate([0, 0, BASE_H + SHAFT_H + 1.0])
            cylinder(h = 0.30, r = 0.88, $fn = 64);
    }
}

module portico_columns() {
    for (y = COL_Y_FRONT)
        translate([COL_FRONT_X, y, 0])
            column(C_GRANITE_R);
    for (y = COL_Y_MID)
        translate([COL_MID_X, y, 0])
            column(C_GRANITE_G);
    for (y = COL_Y_REAR)
        translate([COL_REAR_X, y, 0])
            column(C_GRANITE_R);
}

// 三段式檐部：额枋 / 檐壁 / 檐口
module entablature() {
    color(C_MARBLE) {
        // Architrave
        translate([PORT_CX, 0, COL_H + 1.10 / 2])
            cube([PORT_D, PORT_W, 1.10], center = true);
        // Frieze
        translate([PORT_CX, 0, COL_H + 1.10 + 1.10 / 2])
            cube([PORT_D, PORT_W - 0.4, 1.10], center = true);
        // Cornice（略出挑）
        translate([PORT_CX, 0, COL_H + 2.20 + 0.80 / 2])
            cube([PORT_D + 0.5, PORT_W + 0.3, 0.80], center = true);
    }
}

// 三角山墙（24° 倾角，截面沿进深方向等截面拉伸）
module pediment() {
    color(C_MARBLE)
        translate([PORT_CX, 0, COL_H + ENT_H])
            rotate([0, 90, 0])
                linear_extrude(height = PORT_D, center = true)
                    polygon(points = [
                        [0, -PORT_W / 2],
                        [0,  PORT_W / 2],
                        [-PED_H, 0]
                    ]);
}

// 门前台阶（两级，向广场方向降）
module front_steps() {
    color(C_TRAVERTINE) {
        translate([PORT_FRONT - 0.35, 0, 0.35])
            cube([0.7, PORT_W + 1.2, 0.7], center = true);
        translate([PORT_FRONT - 1.05, 0, 0.175])
            cube([0.7, PORT_W + 2.0, 0.35], center = true);
    }
}

// ============================================================
// 青铜大门与门框
// ============================================================
module bronze_door() {
    color(C_DOOR) {
        // 左右两扇门板（置于门洞外端）
        for (s = [-1, 1])
            translate([BLOCK_FRONT - 0.10, s * DOOR_W / 4, DOOR_H / 2])
                cube([0.2, DOOR_W / 2 - 0.05, DOOR_H], center = true);
        // 门框：两侧立柱 + 上方横楣 + 门槛
        for (s = [-1, 1])
            translate([BLOCK_FRONT - 0.05, s * (DOOR_W / 2 + 0.15), DOOR_H / 2])
                cube([0.35, 0.3, DOOR_H], center = true);
        translate([BLOCK_FRONT - 0.05, 0, DOOR_H + 0.15])
            cube([0.35, DOOR_W + 0.6, 0.3], center = true);
        translate([BLOCK_FRONT - 0.05, 0, 0.1])
            cube([0.5, DOOR_W + 0.6, 0.2], center = true);
    }
}

// ============================================================
// 地面与室内铺装（方格与圆形交错 + 向心排水）
// ============================================================
module ground_and_floor() {
    // 广场地面
    color(C_TRAVERTINE)
        translate([0, 0, -0.16])
            cylinder(r = 58, h = 0.32, $fn = 256);

    // 室内地板基层
    color("#E9E1CE")
        translate([0, 0, -0.001])
            cylinder(r = INNER_R - 0.05, h = 0.04, $fn = SEG);

    // 中央斑岩圆盘 + 黄大理石环
    color(C_PORPHYRY)
        translate([0, 0, 0.02])
            cylinder(r = 4.4, h = 0.04, $fn = SEG);
    color(C_GIALLO)
        translate([0, 0, 0.02])
            difference() {
                cylinder(r = 5.9, h = 0.04, $fn = SEG);
                cylinder(r = 4.8, h = 0.05, $fn = SEG);
            }

    // 外围方格：方格与圆形交错图案
    for (i = [0 : 23]) {
        a = i * 15;
        rotate([0, 0, a])
            translate([INNER_R * 0.62, 0, 0.02])
                color(i % 2 == 0 ? C_PORPHYRY : C_MARBLE)
                    if (i % 3 == 0)
                        cylinder(r = 1.05, h = 0.04, $fn = 48);
                    else
                        cube([2.0, 2.0, 0.04], center = true);
    }

    // 中心向外的 8 条排水凹线（暗色细槽）
    color("#7C6B52")
        for (i = [0 : 45 : 315])
            rotate([0, 0, i])
                translate([INNER_R * 0.42, 0, 0.025])
                    cube([INNER_R * 0.55, 0.14, 0.015], center = true);
}

// ============================================================
// 43.30 m 内切参考球体（可选显示，Ghost 模式）
// ============================================================
module reference_sphere() {
    if (SHOW_REFERENCE_SPHERE)
        %translate([0, 0, INNER_R])
            sphere(r = INNER_R, $fn = SEG);
}

// ============================================================
// 总装配
// ============================================================
module pantheon_assembly() {
    color(C_CONCRETE)
        main_mass();

    oculus_rim();

    // 前廊
    portico_columns();
    entablature();
    pediment();
    front_steps();

    // 大门
    bronze_door();

    // 室内细节
    niche_columns();
    ground_and_floor();

    // 几何基准：直径 43.30 m 的球体，底部切地面、顶部切顶光口
    reference_sphere();
}

pantheon_assembly();
