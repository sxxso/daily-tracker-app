# 每日打卡 Daily Tracker

个人专用 Android App，用于记录**每日打卡习惯**与**番茄钟专注时间**。所有数据存储在本地 SQLite，不需要联网账号，隐私完全自控。

## 功能概览

- **今日打卡** — 主屏顶部显示当日完成率，点击小圆点可进入某天补打卡；每个习惯卡片直接勾勾选打卡
- **番茄钟** — 25/5/15 分钟专注-短休息-长休息循环；支持自定义时长；自动跳下一阶段；退出后台通知也仍然准时
- **习惯管理** — 新增/编辑/删除习惯；选择颜色、图标、每周目标；拖拽排序
- **习惯详情** — 连续天数、最长连续、近 30 天完成率、月历热力图、补打卡入口
- **数据统计** — 近 7 / 14 / 30 天打卡趋势、番茄钟趋势、习惯完成率排行
- **设置** — 专注/短休息/长休息时长、自动进入下一阶段开关、阶段结束通知开关

## 技术栈

| 层 | 选型 |
|---|---|
| 框架 | Flutter 3.29+（Material 3） |
| 状态管理 | provider |
| 本地数据库 | sqflite |
| 图表 | fl_chart |
| 后台闹钟 | flutter_local_notifications + exact-alarm |
| 时区 | flutter_timezone + timezone |

## 环境要求

- **Dart SDK** ≥ 3.6.0（需 Flutter 3.29+）
- **Android SDK** 最低 `minSdk 21`（Android 5.0）
- 推荐 **Android Studio / VS Code** 的 Flutter 插件

本项目**不需要网络权限上传数据**，只声明了 `POST_NOTIFICATIONS` 等必要权限用于番茄钟提醒。

## 构建与安装

> 本仓库在 `pubspec.yaml` 里锁定了具体依赖版本，`flutter pub get` 后无需改动。

### 1. 配置本地路径

把 `android/local.properties.example` 复制一份成 `local.properties`，填入本机实际路径：

```
sdk.dir=C:/Users/你的用户名/AppData/Local/Android/Sdk
flutter.sdk=D:/flutter-sdk   # 换成你的 Flutter 安装目录
```

### 2. 安装依赖并运行

```bash
cd daily-tracker-app
flutter pub get
flutter run
```

### 3. 构建 APK

```bash
flutter build apk --release
# 产物在 build/app/outputs/flutter-apk/app-release.apk
```

## 本地开发说明

### 目录结构

```
lib/
  models/           # Habit / CheckIn / PomodoroSession
  providers/        # HabitProvider / PomodoroProvider
  screens/          # 今日 / 习惯管理 / 番茄钟 / 设置 / 统计
  services/         # DB / Notification
  utils/            # DateUtilsX / HabitStats / PomodoroRules
  widgets/          # ProgressRing / HeatmapCalendar / HabitCheckTile
  main.dart
```

### 测试

纯函数已分离到 `utils/`，不依赖数据库可独立运行测试：

```bash
flutter test
```

覆盖：
- `test/habit_stats_test.dart` — 连续天数、完成率、本周统计等边界用例
- `test/pomodoro_rules_test.dart` — 分阶段规则、`groupByDay`、序列化往返

### 数据库迁移

当前版本 `dbVersion = 1`。如需后续升级：

1. 在 `constants.dart` 里把 `dbVersion` 加 1
2. 在 `DatabaseService._onUpgrade` 里写 ALTER TABLE 或重建逻辑

## 隐私与安全

- 数据完全存在本地 SQLite，不发往任何服务器
- 通知只是闹钟，不含任何埋点
- `minSdk 21` 以上即可运行，兼容面很广

## License

Personal / Non-commercial — 仅供作者自己使用，未对外开源商业授权。
