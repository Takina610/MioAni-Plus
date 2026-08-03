使用 Conventional Commits 的简化格式：

```text
<type>(<scope>): <中文或英文简述>
```

常用 `type`：

| type | 含义 |
| --- | --- |
| `feat` | 新功能 |
| `fix` | 缺陷修复 |
| `docs` | 仅文档修改 |
| `style` | 不影响逻辑的格式修改 |
| `refactor` | 重构 |
| `perf` | 性能优化 |
| `test` | 测试相关 |
| `build` | 构建或依赖变更 |
| `ci` | CI/CD 配置变更 |
| `chore` | 其他维护 |
| `revert` | 回退提交 |

示例：

```text
fix(order): handle empty cart during checkout

- Returns 400 Bad Request instead of throwing NullPointerException
- Adds validation before order items enumeration
- Logs warning with user ID for monitoring
```

重大不兼容变更须在类型后增加 `!`，并在正文中写明影响：

```text
fix(order!): handle empty cart during checkout

- Returns 400 Bad Request instead of throwing NullPointerException
- Adds validation before order items enumeration
- Logs warning with user ID for monitoring
```