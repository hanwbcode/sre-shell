# SRE Shell 🚀

[![Build and Push Docker Image](https://github.com/hanwbcode/sre-shell/actions/workflows/docker-build.yml/badge.svg)](https://github.com/hanwbcode/sre-shell/actions/workflows/docker-build.yml)
[![GitHub Packages](https://img.shields.io/badge/GHCR-sre--shell-blue?logo=docker)](https://github.com/hanwbcode/sre-shell/pkgs/container/sre-shell)

面向云原生与混合云环境的 SRE / DevOps 开箱即用运维工具容器镜像，基于 Debian Bookworm 构建，集成了主流 Kubernetes、对象存储（AWS S3、阿里云 OSS）及常用诊断运维工具。

---

## 📦 包含工具清单

| 工具 | 说明 | 版本策略 | 验证命令 |
| :--- | :--- | :--- | :--- |
| **kubectl** | Kubernetes 命令行管理客户端 | 官方最新稳定版 | `kubectl version --client` |
| **Helm** | Kubernetes 应用包管理器 | 官方最新稳定版 (Helm 3) | `helm version` |
| **PostgreSQL 备份与管理** | `pg_dump`, `pg_dumpall`, `pg_restore`, `psql`, `pg_basebackup` | PGDG 官方最新稳定版 | `pg_dump --version` |
| **MySQL 备份与管理** | `mysqldump`, `mysql`, `mysqladmin` (MariaDB/MySQL 客户端) | Debian 官方仓库 | `mysqldump --version` |
| **MyDumper / MyLoader** | MySQL 高性能多线程并行备份与恢复工具 | Debian 官方仓库 | `mydumper --version` |
| **AWS CLI v2** | AWS 云平台与 S3 对象存储管理工具 | 官方最新 v2 版本 | `aws --version` |
| **ossutil v2** | 阿里云 OSS 对象存储命令行工具 | 官方最新 2.x 版本 | `ossutil version` |
| **系统基础工具** | `git`, `curl`, `ca-certificates`, `unzip`, `less`, `groff-base`, `pigz`, `zstd` | Debian Bookworm 官方仓库 | - |

- **默认时区**：`Asia/Shanghai` (UTC+8)
- **支持架构**：`linux/amd64` (Dockerfile 内部已支持自适应 `amd64` 与 `arm64`)

---

## 🏷️ 镜像标签规范

镜像发布于 **GitHub Container Registry (GHCR)**：

```
ghcr.io/hanwbcode/sre-shell:<tag>
```

- **`latest`**：始终指向主分支（`main`）最新一次成功构建的镜像。
- **`YYYYMMDD`**：以构建当天的**北京时间（Asia/Shanghai）**作为日期标签（例如 `20261011`）。

---

## 🚀 快速开始

### 1. 交互式运行

直接启动并进入 Shell：

```bash
docker run -it --rm ghcr.io/hanwbcode/sre-shell:latest
```

### 2. 挂载凭证与配置

#### 挂载 Kubernetes 配置 (`~/.kube/config`)
```bash
docker run -it --rm \
  -v ~/.kube:/root/.kube:ro \
  ghcr.io/hanwbcode/sre-shell:latest
```

#### 挂载 AWS 与阿里云凭据
```bash
docker run -it --rm \
  -v ~/.aws:/root/.aws:ro \
  -v ~/.ossutilconfig:/root/.ossutilconfig:ro \
  ghcr.io/hanwbcode/sre-shell:latest
```

### 3. 作为 Kubernetes 集群内临时 Debug Pod 运行

```bash
kubectl run sre-shell-debug --rm -it --image=ghcr.io/hanwbcode/sre-shell:latest --restart=Never -- /bin/bash
```

---

## 💡 典型使用场景

### 1. AWS S3 与兼容存储操作
```bash
# 查看存储桶
aws s3 ls

# 同步本地目录到 S3
aws s3 sync /local/path s3://my-bucket/backup/

# 指定第三方 S3 兼容端点（如 MinIO / Ceph）
aws --endpoint-url=https://minio.example.com s3 ls
```

### 2. 阿里云 OSS 操作 (ossutil v2)
```bash
# 交互式初始化配置
ossutil config

# 列出存储桶
ossutil ls

# 复制文件到 OSS 存储桶
ossutil cp local_file.tar.gz oss://my-bucket/
```

### 3. Kubernetes 与 Helm 部署
```bash
kubectl get nodes -o wide
helm list -A
```

### 4. 数据库备份与恢复

#### PostgreSQL 逻辑备份 (pg_dump)
```bash
# 单库逻辑备份并使用 pigz 多线程压缩保存到本地
pg_dump -h <host> -U <user> -d <dbname> | pigz > backup.sql.gz

# 备份为自定义格式并通过管道流式直传 S3（无需临时占用本地磁盘）
pg_dump -h <host> -U <user> -Fc <dbname> | aws s3 cp - s3://my-bucket/backup/$(date +%Y%m%d)_<dbname>.dump

# 流式直传阿里云 OSS
pg_dump -h <host> -U <user> -Fc <dbname> | ossutil cp - oss://my-bucket/backup/$(date +%Y%m%d)_<dbname>.dump
```

#### MySQL 备份 (mysqldump / mydumper)
```bash
# 单库逻辑备份并通过管道流式直传 S3 (结合 pigz 压缩)
mysqldump -h <host> -u <user> -p<password> --single-transaction --quick <dbname> | pigz | aws s3 cp - s3://my-bucket/mysql/backup.sql.gz

# 使用 mydumper 进行多线程并行备份
mydumper -h <host> -u <user> -p <password> -B <dbname> -o /tmp/backup_dir -t 4 --compress
```

---

## 🛠️ 本地构建与测试

克隆本仓库并在本地构建镜像：

```bash
git clone https://github.com/hanwbcode/sre-shell.git
cd sre-shell

# 本地构建
docker build -t sre-shell:local .

# 测试运行
docker run --rm sre-shell:local bash -c "kubectl version --client && helm version && aws --version && ossutil version && pg_dump --version && mysqldump --version && mydumper --version"
```

---

## 🔄 CI/CD 自动构建

项目集成了 GitHub Actions 自动化流水线（[.github/workflows/docker-build.yml](.github/workflows/docker-build.yml)）：
- **自动触发**：向 `main` 分支推送代码或打 Release Tag 时自动触发。
- **构建缓存**：利用 GitHub Actions Cache 加速构建。
- **自动推送**：自动为镜像打上 `latest` 与当日北京时间日期标签（如 `20261011`）并推送至 GHCR。
