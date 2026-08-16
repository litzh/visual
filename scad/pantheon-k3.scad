// ============================================================
//  罗马万神殿 (The Pantheon, Rome) — OpenSCAD 参数化模型
//  单位: 米 (1:1)
//  结构依据实测尺寸:
//   - 圆形正殿内径 43.3 m, 室内高 43.3 m (内部为完美球体)
//   - 穹顶顶部天窗(眼孔)直径 8.8 m
//   - 墙体厚约 6.2 m
//   - 门廊 16 根花岗岩柱, 柱高约 11.8 m (39 罗马尺), 宽 34 m
// ============================================================

/* [开关] */
coffers     = false;   // 穹顶内部藻井(5 圈 × 28 格), 渲染很慢, 默认关闭
show_ground = true;    // 地面广场
// section  = true;    // 取消注释(或 -D section=true)查看纵剖面

/* [主要尺寸] */
R_int    = 21.65;      // 正殿内半径
wall     = 6.2;        // 墙体厚度
R_ext    = R_int + wall;
h_spring = 21.65;      // 穹顶起拱高度 (= 内半径)
oc_r     = 4.4;        // 天窗半径

port_w   = 34.0;       // 门廊宽
port_d   = 15.5;       // 门廊进深
col_h    = 11.8;       // 柱高(含柱头)
col_r    = 0.75;       // 柱底半径

/* [派生定位] */
y0    = -(R_ext + port_d - 1.6);   // 前排柱中心 y
row2  = y0 + 5.2;
row3  = y0 + 10.4;
yback = -R_ext + 3.0;              // 门廊檐部后端(嵌入过渡体)
yf    = y0 - 2.6;                  // 门廊地面前沿
xs1   = [-14, -10, -6.2, -2.2, 2.2, 6.2, 10, 14]; // 前排 8 柱
xs2   = [-14, -4.7, 4.7, 14];                     // 中/后排各 4 柱

$fn = 64;

// 纵剖面模式: 保留后半截, 便于观察内部结构
if (!is_undef(section) && section)
  intersection() {
    pantheon();
    translate([-100, 0, -2]) cube([200, 200, 100]);
  }
else
  pantheon();

// ============================ 总装 ============================
module pantheon() {
  color([0.78, 0.72, 0.60]) rotunda();        // 正殿主体
  color([0.72, 0.66, 0.55]) dome_steps();     // 穹顶外阶梯环
  color([0.78, 0.72, 0.60]) portico_body();   // 门廊檐部/山花/过渡体
  color([0.55, 0.48, 0.44]) columns_all();    // 灰色花岗岩柱
  color([0.35, 0.25, 0.15]) doors();          // 青铜大门
  if (show_ground)
    color([0.83, 0.81, 0.77]) translate([0, 0, -1.7]) cylinder(r = 80, h = 0.2, $fn = 128);
}

// ============================ 正殿 ============================
module rotunda() {
  difference() {
    union() {
      // 鼓座墙
      cylinder(r = R_ext, h = h_spring, $fn = 128);
      // 基座(埋入地面)
      translate([0, 0, -1.6]) cylinder(r = R_ext + 0.3, h = 1.8, $fn = 128);
      // 穹顶外壳(压扁球面, 顶部厚度约 1.4 m)
      dome_outer();
      // 天窗券环
      ring(oc_r + 0.9, oc_r, 42.8, 1.3);
      // 鼓座外壁两道腰线
      ring(R_ext + 0.30, R_ext - 0.1, 12.9, 0.7);
      ring(R_ext + 0.35, R_ext - 0.1, 21.1, 0.8);
    }
    // 室内掏空(圆柱 + 半球 => 内部为完整球体)
    translate([0, 0, -0.1]) cylinder(r = R_int, h = h_spring + 0.2, $fn = 128);
    translate([0, 0, h_spring - 0.1]) sphere(r = R_int, $fn = 128);
    // 天窗
    cylinder(r = oc_r, h = 60);
    // 入口门洞
    entrance_cut();
    // 7 个壁龛(半圆龛与矩形龛交替)
    niches();
    // 穹顶藻井
    if (coffers) coffer_cuts();
  }
  // 室内装饰(必须在差集之外添加, 否则会被掏空)
  interior_decor();
}

module dome_outer() {
  intersection() {
    translate([0, 0, h_spring]) scale([1, 1, 0.82]) sphere(r = R_ext, $fn = 128);
    translate([0, 0, h_spring - 0.2]) cylinder(r = R_ext + 1, h = 30, $fn = 128);
  }
}

function dome_r(dz) = sqrt(R_ext * R_ext - pow(dz / 0.82, 2));

// 穹顶外部 7 道阶梯环(贴合穹顶外表面)
module dome_steps() {
  for (i = [0:6])
    ring(dome_r(i * 1.12) + 0.38, dome_r(i * 1.12) - 1.4, h_spring + i * 1.12, 1.18);
}

// 壁龛: k=6 为入口; k=0,2,4 半圆龛(90°为正对入口的后殿); k=1,3,5,7 矩形龛
module niches() {
  for (k = [0, 2, 4]) rotate([0, 0, k * 45])
    translate([R_int, 0, 0]) cylinder(r = 4.2, h = 12.9);
  for (k = [1, 3, 5, 7]) rotate([0, 0, k * 45])
    translate([R_int - 0.6, -4.2, 0]) cube([4.2, 8.4, 12.9]);
}

module entrance_cut() {
  translate([-3.2, -R_ext - 4.6, -0.1]) cube([6.4, wall + 6.8, 12.7]);
}

// 内壁线脚 + 8 组小神龛(壁柱式祭亭)
module interior_decor() {
  ring(R_int + 0.30, R_int - 0.35, 12.9, 0.6);   // 檐壁线脚
  ring(R_int + 0.25, R_int - 0.40, 21.2, 0.55);  // 起拱线脚
  cylinder(r = R_int + 0.05, h = 0.02, $fn = 128); // 地面
  for (k = [0:7]) rotate([0, 0, k * 45 + 22.5]) {
    for (s = [-1, 1]) translate([R_int - 0.75, s * 1.5, 0]) {
      cylinder(r1 = 0.42, r2 = 0.36, h = 7.6);            // 小柱
      translate([-0.5, -0.5, 7.6]) cube([1, 1, 0.35]);    // 柱顶板
    }
    translate([R_int - 1.05, -2.4, 7.95]) cube([1.15, 4.8, 0.5]); // 小檐部
    translate([R_int - 0.65, 0, 8.45]) rotate([0, 0, 90]) pediment(5.0, 1.1, 1.0); // 小山花
  }
}

// 穹顶藻井: 5 圈 × 28 格
module coffer_cuts() {
  for (ring_i = [0:4], i = [0:27])
    rotate([0, 0, i * 360 / 28])
      rotate([0, -(14 + ring_i * 12), 0])
        translate([R_int + 0.55, 0, 0])
          cube([1.6, 2.7 - 0.3 * ring_i, 2.7 - 0.3 * ring_i], center = true);
}

// ============================ 门廊 ============================
module portico_body() {
  difference() {
    union() {
      // 前部 5 级台阶
      for (k = [0:4])
        translate([-(port_w / 2 - 2), yf - (0.45 * (5 - k) + 0.25), -1.7])
          cube([port_w - 4, 0.45 * (5 - k) + 0.25, 0.5 + 0.3 * k]);
      // 门廊地面
      translate([-port_w / 2, yf, -0.6]) cube([port_w, yback + 1.2 - yf, 0.6]);
      // 天花板
      translate([-16, y0 - 1.5, 11.45]) cube([32, yback - y0 + 1.5, 0.35]);
      // 檐部三段: 额枋 / 檐壁 / 挑檐
      translate([-port_w / 2, y0 - 1.8, 11.8])  cube([port_w, yback - y0 + 1.8, 1.5]);
      translate([-port_w / 2, y0 - 1.8, 13.3])  cube([port_w, yback - y0 + 1.8, 1.25]);
      translate([-port_w / 2 - 0.5, y0 - 2.3, 14.55]) cube([port_w + 1, yback - y0 + 2.6, 0.7]);
      // 三角形山花(前门廊)
      translate([0, y0 - 1.5, 15.25]) pediment(port_w + 1, 3.5, 2.6);
      // 双坡屋顶
      for (s = [-1, 1])
        translate([s * 8.6, (y0 - 1.5 + (-R_ext - 4)) / 2, 17.0])
          rotate([0, s * 11.3, 0])
            cube([17.4, (-R_ext - 4) - (y0 - 1.5), 0.35], center = true);
      // 过渡体(连接门廊与正殿)
      translate([-18, -R_ext - 4, 0]) cube([36, 12.5, 21.65]);
      // 第二道山花轮廓(著名的"双重山花")
      translate([0, -R_ext - 4.45, 15.25]) pediment(36.5, 6.4, 0.9);
    }
    entrance_cut();  // 门洞贯穿过渡体
  }
}

module columns_all() {
  for (x = xs1) translate([x, y0, 0]) column();
  for (x = xs2, y = [row2, row3]) translate([x, y, 0]) column();
}

module column() {
  translate([0, 0, 0.15])  cube([2.0, 2.0, 0.3], center = true);      // 柱础
  translate([0, 0, 0.4])   cylinder(r1 = 0.95, r2 = 0.82, h = 0.2);   // 础座
  translate([0, 0, 0.5])   cylinder(r1 = col_r, r2 = 0.63, h = col_h - 1.3); // 柱身(微收分)
  translate([0, 0, col_h - 0.8]) cylinder(r1 = 0.63, r2 = 0.85, h = 0.5);    // 柱头钟部
  translate([0, 0, col_h - 0.15]) cube([1.8, 1.8, 0.3], center = true);      // 顶板
}

module doors() {
  for (s = [-1, 1])
    translate([s < 0 ? -3.15 : 0.15, -R_int - 0.8, 0])
      cube([3.0, 0.3, 7.4]);
}

// ============================ 工具 ============================
module ring(r_out, r_in, z, h) {
  translate([0, 0, z]) difference() {
    cylinder(r = r_out, h = h);
    translate([0, 0, -0.05]) cylinder(r = r_in, h = h + 0.1);
  }
}

// 三棱柱山花: x 向宽 w, z 向高 h, y 向厚 t
module pediment(w, h, t) {
  rotate([90, 0, 0])
    linear_extrude(height = t, center = true)
      polygon(points = [[-w / 2, 0], [w / 2, 0], [0, h]]);
}
