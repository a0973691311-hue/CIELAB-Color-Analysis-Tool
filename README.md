# CIELAB Color Analysis Tool

這是一個用 MATLAB 與 Python 製作的色彩分析小專案。主要功能是讓使用者載入圖片後，點選圖片位置取得 RGB、HSV、XYZ、CIELAB 色彩數值，並可以計算兩點之間的色差。

## MATLAB 版本功能

- 載入 JPG、PNG、BMP、TIF 圖片
- 單點取樣並顯示 RGB、HSV、XYZ、CIELAB
- 兩點取樣並計算色差
- 支援 `CIE76`、`CIE94`、`CIEDE2000`
- ROI 矩形區域平均色彩分析
- 顯示取樣結果表格
- 匯出 CSV 結果

## MATLAB 使用方式

在 MATLAB 中開啟此資料夾，執行：

```matlab
ColorLabPicker
```

使用流程：

1. 按 `Load Image` 載入圖片。
2. 選擇 Delta E 公式。
3. 使用：
   - `Single Point`：點一個位置看色彩數值
   - `Two Point Delta E`：點兩個位置計算色差
   - `ROI Mean Color`：框選區域計算平均色彩
4. 按 `Export CSV` 匯出結果。


## 色差公式

本專案支援三種色差公式：

- `CIE76`
- `CIE94`
- `CIEDE2000`

其中 `CIEDE2000` 通常比 `CIE76` 更接近人眼感知。

## 需求

MATLAB 版本：

- MATLAB
- Image Processing Toolbox

