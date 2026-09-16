---
title: Style-Bert-VITS2 训练杂记
published: 2026-09-07
updated: 2026-09-07
description: '使用 Style-Bert-VITS2 进行日语声音模型的训练记录'
image: ''
tags: [笔记]
category: '技术'
draft: false
lang: 'zh_CN'
---

## 前记

开源项目使用：https://github.com/litagin02/Style-Bert-VITS2

训练教程大致参考 https://github.com/litagin02/Style-Bert-VITS2/blob/master/docs/CLI.md ，有轻微变动。

此前参考过其他开发者记录的资料：https://slimeboyowo.github.io/LingBlog/blog/projects/ling-chat/develop/Style-Bert-VITS2%E6%A8%A1%E5%9E%8B%E8%AE%AD%E7%BB%83%E6%95%99%E7%A8%8B ，这个其实很好用，还做了更新和汉化，但是只能在本地训练，对配置要求比较高，我这种笔记本开发的就完全倒闭了。

比较好用的招是去云端租算力进行训练。然后我尝试用了一下 AutoDL（https://www.autodl.com/home ） ，-50 米。

选了一个 RTX 4090D 的卡。镜像配置如下：

| 配置 | 版本 |
|:---:|:---:|
| PyTorch | 2.1.2 |
| Python | 3.10(ubuntu22.04) |
| CUDA | 11.8 |

然后踩了茫茫多的坑，在 AI 的帮助下花了 4h+ 才勉强跑通。下面让 AI 写了一个踩坑说明。

---

Style-Bert-VITS2 AutoDL 训练踩坑记录

---

## 一、环境安装阶段

### 错误 1：PyAV 编译失败（缺少 FFmpeg 开发库）

**症状**：
```
pkg-config could not find libraries ['avformat', 'avcodec', 'avdevice', 'avutil', 'avfilter', 'swscale', 'swresample']
```

**解决**：
```bash
apt-get update && apt-get install -y \
  ffmpeg libavdevice-dev libavfilter-dev libavformat-dev \
  libavcodec-dev libavutil-dev libswscale-dev libswresample-dev \
  pkg-config libsndfile1-dev
```

---

### 错误 2：PyAV Cython 语法编译错误

**症状**：
```
Cannot assign type 'const char *(void *) except? NULL nogil' to 'const char *(*)(void *) noexcept nogil'
```

**原因**：Cython 3.0+ 与旧版 PyAV 语法不兼容。

**解决**：
```bash
pip install "cython<3"
pip install "av" --no-build-isolation
```

---

### 错误 3：faster-whisper 安装失败（缺少 wheel）

**症状**：
```
error: invalid command 'bdist_wheel'
```

**解决**：
```bash
pip install wheel
pip install faster-whisper==0.10.1 --no-build-isolation
```

---

### 错误 4：soundfile 缺失

**症状**：
```
ModuleNotFoundError: No module named 'soundfile'
```

**解决**：
```bash
pip install soundfile
```

---

## 二、运行时库冲突（AutoDL 镜像特有问题）

### 错误 5：libstdc++ 版本冲突（conda 污染）

**症状**：
```
ImportError: .../miniconda3/lib/libstdc++.so.6: version `GLIBCXX_3.4.30' not found
```

**原因**：AutoDL 预装的 miniconda3 自带旧版 `libstdc++`，与系统库冲突。

**解决**：
```bash
# 备份并替换 conda 的 libstdc++ 为系统版本
cp /root/miniconda3/lib/libstdc++.so.6 /root/miniconda3/lib/libstdc++.so.6.bak
cp /usr/lib/x86_64-linux-gnu/libstdc++.so.6 /root/miniconda3/lib/libstdc++.so.6
```

---

### 错误 6：cuDNN 版本冲突（最隐蔽的大坑）

**症状**（预处理 + 训练阶段都会炸）：
- 预处理：`CUDNN_STATUS_MAPPING_ERROR`、`CUFFT_INTERNAL_ERROR`、`CUDA illegal memory access`
- 训练：`CUDA error: an illegal memory access was encountered`
- 诊断：`cuDNN version incompatibility: PyTorch was compiled against (8, 9, 2) but found runtime version (8, 6, 0)`

**原因**：PyTorch 2.1.2+cu118 自带 cuDNN 8.9.x（通过 `nvidia-cudnn-cu11` 包安装在 venv 内），但 `LD_LIBRARY_PATH` 导致系统/conda 的 cuDNN 8.6.0 被优先加载。

**解决**（关键步骤，必须执行）：

```bash
# 1. 查找 PyTorch 自带的 cuDNN 实际路径（cu118 版本）
find /root/autodl-tmp/Style-Bert-VITS2/venv -name "libcudnn.so*" | head -5
# 典型输出示例：
# /root/autodl-tmp/Style-Bert-VITS2/venv/lib/python3.10/site-packages/nvidia/cudnn/lib/libcudnn.so.8

# 2. 清理 venv activate 中旧的 LD_LIBRARY_PATH 设置
sed -i '/LD_LIBRARY_PATH/d' /root/autodl-tmp/Style-Bert-VITS2/venv/bin/activate

# 3. 写入正确顺序（PyTorch 自带 cuDNN > torch/lib > 系统库）
# 注意：根据上面 find 的实际路径调整，以下是常见路径示例
echo 'export LD_LIBRARY_PATH=/root/autodl-tmp/Style-Bert-VITS2/venv/lib/python3.10/site-packages/nvidia/cudnn/lib:/root/autodl-tmp/Style-Bert-VITS2/venv/lib/python3.10/site-packages/torch/lib:/usr/lib/x86_64-linux-gnu:/usr/local/nvidia/lib:/usr/local/nvidia/lib64' >> /root/autodl-tmp/Style-Bert-VITS2/venv/bin/activate

# 4. 重新激活并验证
source /root/autodl-tmp/Style-Bert-VITS2/venv/bin/activate
python -c "import torch; print(f'PyTorch: {torch.__version__}, cuDNN: {torch.backends.cudnn.version()}')"
# 必须输出 cuDNN: 8902（或 89xx），不能是 8600
```

---

## 三、网络问题

### 错误 7：HuggingFace 连接失败

**症状**：
```
ConnectError: [Errno 99] Cannot assign requested address
```

**解决**：
```bash
export HF_ENDPOINT=https://hf-mirror.com
```

---

### 错误 8：Xet 协议 401 错误

**症状**：
```
HTTP status client error (401 Unauthorized), domain: https://cas-server.xethub.hf.co
```

**解决**：
```bash
export HF_HUB_DISABLE_XET=1
export HF_ENDPOINT=https://hf-mirror.com
```

---

## 四、预处理阶段

### 错误 9：transformers 版本太新

**症状**：
```
cannot import name 'AutoModelForMaskedLM' from 'transformers'
```

**原因**：pip 自动解析安装了 transformers 4.57.6（太新），项目需要 4.35.x。

**解决**：
```bash
pip uninstall transformers -y
pip install transformers==4.35.2

# 锁定版本，防止后续被覆盖
sed -i 's/^transformers$/transformers==4.35.2/' /root/autodl-tmp/Style-Bert-VITS2/requirements.txt
```

---

### 错误 10：DebertaV2Model 导入失败（连锁反应）

**症状**：
```
Could not import module 'DebertaV2Model'. Are this object's requirements defined correctly?
```

**原因**：transformers 版本不对，或缺少 `sentencepiece`。

**解决**：
```bash
# 确保 transformers 版本正确
pip install transformers==4.35.2

# 安装 sentencepiece（日语 BERT tokenizer 依赖）
pip install sentencepiece
```

---

### 错误 11：预处理多进程 GPU 冲突

**症状**：预处理时部分文件报 `CUDNN_STATUS_MAPPING_ERROR` / `CUFFT_INTERNAL_ERROR`

**注意**：如果已修复错误 6（cuDNN 版本冲突）仍出现，则是多进程问题。

**解决**：
```bash
python preprocess_all.py -m <model_name> --use_jp_extra ... --num_processes 1
```

---

## 五、训练阶段

### 错误 12：训练 OOM（Out Of Memory）

**症状**：
```
torch.cuda.OutOfMemoryError: CUDA out of memory. Tried to allocate 20.00 MiB
```

**解决**：修改 `config.json` 降低 batch_size（无需重新预处理）：
```bash
# RTX 4090D 24GB 建议值
sed -i 's/"batch_size": 12/"batch_size": 6/' Data/<model_name>/config.json
```

**推荐训练参数**（config.json）：
```json
"train": {
  "batch_size": 6,
  "fp16_run": true
}
```

---

## 六、完整环境初始化速查（修正版，基于 cu118）

```bash
# ========== 1. 系统依赖 ==========
apt-get update && apt-get install -y \
  ffmpeg libavdevice-dev libavfilter-dev libavformat-dev \
  libavcodec-dev libavutil-dev libswscale-dev libswresample-dev \
  pkg-config libsndfile1-dev

# ========== 2. 创建并进入环境 ==========
cd /root/autodl-tmp/Style-Bert-VITS2  # 根据实际路径修改
python -m venv venv
source venv/bin/activate

# ========== 3. 安装 PyTorch（cu118，与镜像一致） ==========
pip install torch==2.1.2 torchaudio==2.1.2 --index-url https://download.pytorch.org/whl/cu118

# ========== 4. 分步安装易冲突依赖 ==========
pip install "cython<3"
pip install wheel
pip install "av" --no-build-isolation
pip install faster-whisper==0.10.1 --no-build-isolation
pip install soundfile sentencepiece

# ========== 5. 锁定 transformers 版本 ==========
pip install transformers==4.35.2
sed -i 's/^transformers$/transformers==4.35.2/' requirements.txt

# ========== 6. 安装其余依赖 ==========
pip install -r requirements.txt

# ========== 7. 修复 conda libstdc++ 冲突 ==========
cp /root/miniconda3/lib/libstdc++.so.6 /root/miniconda3/lib/libstdc++.so.6.bak
cp /usr/lib/x86_64-linux-gnu/libstdc++.so.6 /root/miniconda3/lib/libstdc++.so.6

# ========== 8. 修复 cuDNN 路径（关键！先查找再写入） ==========
find /root/autodl-tmp/Style-Bert-VITS2/venv -name "libcudnn.so*" | head -5
# 根据输出结果，把包含 libcudnn.so.8 的目录放到 LD_LIBRARY_PATH 最前面
sed -i '/LD_LIBRARY_PATH/d' venv/bin/activate
echo 'export LD_LIBRARY_PATH=/root/autodl-tmp/Style-Bert-VITS2/venv/lib/python3.10/site-packages/nvidia/cudnn/lib:/root/autodl-tmp/Style-Bert-VITS2/venv/lib/python3.10/site-packages/torch/lib:/usr/lib/x86_64-linux-gnu:/usr/local/nvidia/lib:/usr/local/nvidia/lib64' >> venv/bin/activate
source venv/bin/activate

# ========== 9. 验证环境 ==========
python -c "import torch; print(f'PyTorch: {torch.__version__}, CUDA: {torch.version.cuda}, cuDNN: {torch.backends.cudnn.version()}, GPU: {torch.cuda.get_device_name(0)}')"
# 期望输出：PyTorch: 2.1.2+cu118, CUDA: 11.8, cuDNN: 8902, GPU: NVIDIA GeForce RTX 4090D

# ========== 10. 设置网络镜像 ==========
export HF_ENDPOINT=https://hf-mirror.com
export HF_HUB_DISABLE_XET=1

# ========== 11. 下载预训练模型 ==========
python initialize.py
```

---

## 七、训练全流程速查

```bash
# 1. 切片
python slice.py --model_name <model_name> -i /path/to/raw_audio -m 2 -M 12

# 2. 转写
python transcribe.py --model_name <model_name> --language jp --model large-v3 --device cuda

# 3. 检查 esd.list（手动修正错误标注）

# 4. 预处理（单进程，避免 GPU 冲突）
python preprocess_all.py -m <model_name> \
  --use_jp_extra \
  --batch_size 6 \
  --epochs 100 \
  --save_every_steps 1000 \
  --normalize --trim \
  --yomi_error raise \
  --num_processes 1

# 5. 修改 batch_size（如果预处理时设的太大）
# sed -i 's/"batch_size": 12/"batch_size": 6/' Data/<model_name>/config.json

# 6. 训练
python train_ms_jp_extra.py

# 7. 监控
tensorboard --logdir Data/<model_name>/models/ --port 6006
```

---

**核心经验**：AutoDL 镜像的 **conda 环境污染**（libstdc++ 和 cuDNN）是所有 CUDA 相关报错的共同根因。PyTorch 2.1.2+cu118 自带 cuDNN 8.9.x，但必须通过 `LD_LIBRARY_PATH` 显式置顶，否则会被系统/conda 的 cuDNN 8.6.0 劫持，导致从预处理到训练全链路崩溃。