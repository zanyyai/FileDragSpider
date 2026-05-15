# FileDragSpider v4

## ☕ 支持作者
无需安装，直接解压运行。如果这个小工具帮到了你，可以请我喝杯咖啡吗~

<p align="center">
  <img src="docs/wechat_qr.png" alt="微信赞赏码" width="350" style="margin-right:20px;"/>
  <img src="docs/alipay_qr.png" alt="支付宝扫一扫" width="150"/>
</p>

> 如果对您有帮助，可以打赏点零花钱，感谢支持 🙏  
> 你的每一笔赞助都会激励我继续维护更新！


<div align="center">

**文件批量搜索与处理工具**

[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Windows-lightgrey.svg)](https://www.microsoft.com/windows)

</div>

---

## 📖 简介

这是第一个做的小工具发布到github请多多指教。如有类似软件可以推荐给我。
（感谢Gemini，swe-1.5，Cursor，Chatgpt，，Claude code等工具带来的帮助！！！应该早有大神做出了这个小功能，可能他们没空发布这么小的功能，不管怎么说感谢各种借到的力。）
FileDragSpider 是一款Windows文件批量搜索与处理工具，帮助用户快速定位、整理和批量处理分散在不同目录中的文件。

<img width="722" height="792" alt="image" src="https://github.com/user-attachments/assets/7b6dd43c-d982-452b-8b1a-d37929a4e792" />


### ✨ 核心功能

- 🔍 **多目录搜索** - 同时在多个目录中搜索指定文件
- 🎯 **灵活匹配** - 支持精确匹配和模糊匹配
- 🔗 **智能集中** - 一键将文件集中到临时文件夹
- 📁 **同名定位** - 自动搜索并定位同名文件
- 🚀 **批量移动** - 将文件移动到同名文件所在目录
- 💾 **设置保存** - 自动保存搜索配置

---

## 📦 下载安装

### 下载

前往 [Releases](https://github.com/zanyyai/FileDragSpider/releases) 页面下载最新版本的 `.exe` 文件。

### 运行

直接双击下载的 `.exe` 文件即可运行，无需安装。

---

## 🚀 使用方法

1. 在"搜索目录"框中输入要搜索的目录路径（每行一个）
2. 在"文件名列表"框中输入要搜索的文件名（每行一个）
3. 勾选搜索选项（区分大小写、精确匹配）
4. 点击"搜索"按钮开始搜索
5. 勾选需要处理的文件
6. 点击"集中到临时文件夹"按钮
7. 临时文件夹将自动打开，可直接拖入目标软件

### 高级功能

- **搜索同名文件**：在指定目录中搜索同名文件
- **移动到同名文件所在目录**：将文件移动到同名文件所在目录
- **批量操作**：全选、反选、清除勾选
- **右键菜单**：打开文件、复制路径等

---

## 💡 使用场景

### 法律文书整理
- 在多个证据目录中搜索特定录音文件
- 快速定位并集中分散的证据文件
- 按文件名批量整理证据材料

### 医疗档案管理
- 搜索患者相关的所有检查报告
- 集中分散在不同科室的病历文件
- 按时间或类型批量整理档案

### 科研数据处理
- 搜索实验数据文件
- 集中分散在不同项目的数据
- 批量移动到统一目录进行分析

### 软件开发
- 搜索特定版本的配置文件
- 集中分散在不同分支的代码文件
- 按文件名批量整理资源文件

---

## 🔧 技术细节

### 硬链接 vs 复制

- **硬链接**：零磁盘占用，快速创建，但要求在同一分区
- **复制**：跨分区使用，占用磁盘空间，速度较慢

程序会自动尝试硬链接，失败时降级为复制。

### 设置文件

程序会自动在同级目录创建 `FileDragSpider_v1.ini` 配置文件，保存：
- 搜索目录
- 文件名列表
- 同名文件目录
- 搜索选项

下次启动时自动加载。

### 性能优化

- 使用 `Opt("-Redraw")` 禁用重绘，防止大量数据时闪烁
- 批量操作时显示进度提示
- 智能缓存搜索结果

---

## 📄 许可证

本项目采用 **MIT License** 开源许可证。

**允许：**
- ✅ 个人使用


---

## 📮 联系方式

- **项目主页**: [GitHub Repository](https://github.com/yourusername/FileDragSpider)
- **问题反馈**: [GitHub Issues](https://github.com/yourusername/FileDragSpider/issues)

---

<div align="center">

**如果这个项目对您有帮助，请给个 ⭐️ Star 支持一下！**

</div>
