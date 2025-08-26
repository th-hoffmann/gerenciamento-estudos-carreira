# 📁 Política de Backups

## 📋 Visão Geral

Este diretório contém os backups automáticos do arquivo `DASHBOARD_KPIS.md` criados pelo script `dashboard-updater.sh`.

## 🎯 Convenção de Nomeação

Os arquivos de backup seguem o padrão:

DASHBOARD_KPIS_backup_YYYYMMDD_HHMMSS.md

**Exemplo:** `DASHBOARD_KPIS_backup_20250826_143052.md`

- **YYYY**: Ano (4 dígitos)
- **MM**: Mês (2 dígitos)
- **DD**: Dia (2 dígitos)
- **HH**: Hora (formato 24h, 2 dígitos)
- **MM**: Minuto (2 dígitos)
- **SS**: Segundo (2 dígitos)

## 🔄 Política de Retenção

- **Máximo de arquivos**: 7 backups (equivalente a 1 semana)
- **Rotação automática**: Quando o limite é atingido, os arquivos mais antigos são removidos automaticamente
- **Frequência**: Backups criados a cada execução do script `dashboard-updater.sh`

## 🛡️ Funcionalidades

1. **Criação automática do diretório**: Se o diretório não existir, será criado automaticamente
2. **Gerenciamento inteligente**: O script verifica a quantidade de backups antes de criar um novo
3. **Limpeza automática**: Remove automaticamente os backups mais antigos quando necessário
4. **Logs informativos**: Exibe informações sobre o processo de backup durante a execução

## 📊 Exemplo de Execução

```bash
🗂️  Aplicando política de backups (máximo: 7 arquivos)...
📂 Backups atuais: 3 (dentro do limite de 7)
💾 Backup criado: backups/DASHBOARD_KPIS_backup_20250826_143052.md
```

## 🔧 Manutenção

O gerenciamento de backups é totalmente automático. Não é necessária intervenção manual, mas você pode:

- **Visualizar backups**: `ls -la backups/DASHBOARD_KPIS_backup_*.md`
- **Backup manual**: Copiar manualmente o arquivo se necessário
- **Restauração**: Copiar qualquer backup de volta para o arquivo principal

## ⚙️ Configuração

As configurações da política estão no arquivo `scripts/dashboard-updater.sh`:

```bash
MAX_BACKUPS=7  # Altere este valor para mudar o limite de backups
```
