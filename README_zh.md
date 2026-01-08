# Pulse Notify

macOS 螢幕邊緣呼吸燈通知效果，專為 Claude Code hooks 設計。

## 特色

- 高斯呼吸曲線，模擬自然的吸氣/吐氣節奏
- 全螢幕四邊同步發光
- 光暈尺寸隨呼吸動態擴張收縮
- 觸發時播放系統音效
- 所有參數皆可透過命令列調整

## 快速安裝

```bash
curl -fsSL https://raw.githubusercontent.com/neokn/claude-notification-hook/main/install.sh | bash
```

> **系統需求：** macOS 11.0+ 搭配 Apple Silicon (M1/M2/M3/M4)

## 使用方式

```bash
./pulse-notify [參數]
```

## 參數說明

### 基本參數

| 參數 | 簡寫 | 預設值 | 說明 |
|------|------|--------|------|
| `--color` | `-c` | `orange` | 光暈顏色（名稱或 hex） |
| `--duration` | `-d` | `8` | 持續時間（秒） |

**支援的顏色名稱：**
`white`, `green`, `blue`, `red`, `orange`, `purple`, `yellow`, `pink`, `cyan`

**Hex 格式：** `#FF5500` 或 `FF5500`

### 呼吸參數

| 參數 | 預設值 | 說明 |
|------|--------|------|
| `--breath-cycle` | `4.0` | 完整呼吸週期（秒） |
| `--min-brightness` | `0.15` | 最低亮度 (0-1) |
| `--max-brightness` | `1.0` | 最高亮度 (0-1) |
| `--inhale-sigma` | `0.8` | 吸氣高斯寬度（越小越快） |
| `--exhale-sigma` | `1.2` | 吐氣高斯寬度（越大越慢） |

### 光暈尺寸參數

| 參數 | 預設值 | 說明 |
|------|--------|------|
| `--min-glow-height` | `80` | 上下光暈最小高度 (px) |
| `--max-glow-height` | `160` | 上下光暈最大高度 (px) |
| `--min-glow-width` | `100` | 左右光暈最小寬度 (px) |
| `--max-glow-width` | `200` | 左右光暈最大寬度 (px) |
| `--min-blur` | `20` | 最小模糊半徑 (px) |
| `--max-blur` | `45` | 最大模糊半徑 (px) |

### 音效參數

| 參數 | 簡寫 | 預設值 | 說明 |
|------|------|--------|------|
| `--sound` | `-s` | `Ping` | 音效名稱 |
| `--no-sound` | - | - | 靜音模式 |

**可用的系統音效：**
```
Basso, Blow, Bottle, Frog, Funk, Glass, Hero,
Morse, Ping, Pop, Purr, Sosumi, Submarine, Tink
```

### 語音參數 (Text-to-Speech)

| 參數 | 預設值 | 說明 |
|------|--------|------|
| `--speak` | - | 要唸出的訊息（stdin 沒有訊息時的備用） |
| `--voice` | `Ralph` | macOS 語音名稱 |

**語音優先順序：** stdin 的 `message` 欄位 → `--speak` 參數 → 不唸

當被 Claude Code hook 觸發時，程式會自動讀取 stdin JSON 的 `message` 欄位並唸出來。`--speak` 是給沒有 message 的 hook（如 `Stop`）使用的備用方案。

**列出可用語音：**
```bash
say -v '?'                    # 所有語音
say -v '?' | grep Taiwan      # 台灣中文語音
say -v '?' | grep en_US       # 美式英文語音
```

## 使用範例

```bash
# 預設效果（橘色呼吸燈 + Ping 音效）
./pulse-notify

# 綠色成功提示
./pulse-notify -c green -d 5 -s Glass

# 紅色錯誤警告（較快呼吸）
./pulse-notify -c red --breath-cycle 2 -s Basso

# 藍色靜音模式（大光暈）
./pulse-notify -c blue --max-glow-height 200 --no-sound

# 自訂 hex 顏色
./pulse-notify -c "#FF6B35" -d 10

# 慢速冥想模式
./pulse-notify -c purple --breath-cycle 8 --exhale-sigma 1.5

# 使用台灣中文語音
./pulse-notify -c green --speak "任務完成" --voice Meijia

# 測試 stdin 訊息（模擬 Claude hook）
echo '{"message": "需要授權"}' | ./pulse-notify -c red
```

## Claude Code Hook 設定

在 `~/.claude/settings.json` 中加入：

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "permission_prompt",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/claude-notification-hook/bin/pulse-notify -c red -s Ping"
          }
        ]
      },
      {
        "matcher": "idle_prompt",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/claude-notification-hook/bin/pulse-notify -c blue -s Blow"
          }
        ]
      },
      {
        "matcher": "elicitation_dialog",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/claude-notification-hook/bin/pulse-notify -c purple -s Pop"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/claude-notification-hook/bin/pulse-notify -c orange -s Glass --speak 'Mission accomplished' --voice Meijia"
          }
        ]
      }
    ]
  }
}
```

### 事件類型說明

| 事件 | 顏色 | 音效 | 語音 | 用途 |
|------|------|------|------|------|
| `permission_prompt` | 紅色 | Ping | 自動 (stdin) | 請求授權，需要注意 |
| `idle_prompt` | 藍色 | Blow | 自動 (stdin) | 等待輸入中 |
| `elicitation_dialog` | 紫色 | Pop | 自動 (stdin) | 互動對話/提問 |
| `Stop` | 橘色 | Glass | "Mission accomplished" | 任務完成 |

> **備註：** Notification hook 會自動唸出 Claude stdin JSON 中的 `message` 欄位。`Stop` hook 因為沒有 message，所以使用 `--speak` 作為備用方案。

## 授權

MIT
