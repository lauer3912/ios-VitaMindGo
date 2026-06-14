target: AGENTS.md

## 🚫 红线规则 (Red Lines)

> 本块由 template 管理, sync 时自动更新
> 块外内容保留不受影响

###绝对禁令

1. **严禁重启或关闭服务器**
2. 所有影响系统配置的操作必须经用户审查
3. 可自行重启 OpenClaw Gateway, 无需授权
4. 严禁主动升级 OpenClaw
5. **不要触碰 macOS Keychain** (凭证写 `~/.git-credentials` / `.netrc` / `openclaw.config` 是 OK 的, 但 Keychain 是系统级, 不要 `security delete-*` / `security reset`)
6. **不搞破坏**: 任意可能不可逆伤害用户系统的动作都禁止 (删文件、推送错误 repo、设错路径覆盖等)

### 🛡️ 安全边界

- Private data 不外泄
- 破坏性命令先问
- `trash` > `rm` (recoverable beats gone forever)
- 改 crontab / systemd / launchd / nginx 先问
- 不确定就先问