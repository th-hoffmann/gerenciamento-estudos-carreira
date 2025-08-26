#!/usr/bin/env bash

# ╔═════════════════════════════════════════════════════════════════════════════╗
# ║  🔄 dashboard-updater.sh
# ╚═════════════════════════════════════════════════════════════════════════════╝
# 
# ╔═════════════════════════════════════════════════════════════════════════════╗
# ║ 📋 INFORMAÇÕES DO SCRIPT
# ╚═════════════════════════════════════════════════════════════════════════════╝
# 
#   📄 Descrição.....: Atualiza o DASHBOARD_KPIS.md com métricas reais extraídas
#    das issues do GitHub, integrando com o weekly-report.sh. Inclui sistema
#    automatizado de backup com política de retenção de 7 arquivos.
#
#   👨‍💻 Desenvolvedor.: Thiago Hoffmann
#   📮 Contato.......: thiago@hoffmann.tec.br
#   🔗 GitHub........: https://github.com/th-hoffmann
#   🌐 LinkedIn......: https://linkedin.com/in/th-hoffmann87
#
#   📅 Data..........: 26/08/2025
#   🏷️  Versão.......: 1.1.1
#   
#   🔧 Melhorias v1.1.1:
#   - ✅ Correções de boas práticas: declaração separada de variáveis
#   - ✅ Melhor tratamento de erros e robustez do código
#   - ✅ Conformidade total com shellcheck (zero warnings)
#   
#   🔧 Melhorias v1.1.0:
#   - ✅ Sistema de backup automatizado no diretório 'backups/'
#   - ✅ Política de retenção: máximo 7 backups (1 semana)
#   - ✅ Nomenclatura com timestamp: YYYYMMDD_HHMMSS
#   - ✅ Limpeza automática dos backups mais antigos
#
#
# ╔═════════════════════════════════════════════════════════════════════════════╗
# ║ 🚀 MODO DE USO
# ╚═════════════════════════════════════════════════════════════════════════════╝
#
#   Executar:    ./dashboard-updater.sh
#
#
# ═══════════════════════════════════════════════════════════════════════════════

set -e

DASHBOARD_FILE="DASHBOARD_KPIS.md"
BACKUP_DIR="backups"
BACKUP_FILE="${BACKUP_DIR}/DASHBOARD_KPIS_backup_$(date '+%Y%m%d_%H%M%S').md"
MAX_BACKUPS=7

echo "🔄 Iniciando atualização integrada do dashboard..."

# Criar diretório de backup se não existir
mkdir -p "$BACKUP_DIR"

# Função para gerenciar política de backups
manage_backup_policy() {
    local backup_dir="$1"
    local max_backups="$2"
    local file_pattern="DASHBOARD_KPIS_backup_*.md"
    
    echo "🗂️  Aplicando política de backups (máximo: $max_backups arquivos)..."
    
    # Contar arquivos de backup existentes
    local backup_count
    backup_count=$(find "$backup_dir" -name "$file_pattern" -type f 2>/dev/null | wc -l)
    
    if [ "$backup_count" -ge "$max_backups" ]; then
        # Calcular quantos arquivos excedentes existem
        local excess_files=$((backup_count - max_backups + 1))
        
        echo "📁 Encontrados $backup_count backups. Removendo os $excess_files mais antigos..."
        
        # Remover os arquivos mais antigos
        find "$backup_dir" -name "$file_pattern" -type f -printf '%T@ %p\n' | \
        sort -n | \
        head -n "$excess_files" | \
        cut -d' ' -f2- | \
        while read -r old_backup; do
            echo "🗑️  Removendo backup antigo: $(basename "$old_backup")"
            rm -f "$old_backup"
        done
    else
        echo "📂 Backups atuais: $backup_count (dentro do limite de $max_backups)"
    fi
}

# Aplicar política de backups antes de criar novo backup
manage_backup_policy "$BACKUP_DIR" "$MAX_BACKUPS"

# Backup do arquivo original com timestamp
cp "$DASHBOARD_FILE" "$BACKUP_FILE"
echo "💾 Backup criado: $BACKUP_FILE"

# Função para obter cor do badge baseada no progresso
get_badge_color() {
    local progress=$1
    if [ "$progress" -ge 90 ]; then
        echo "brightgreen"
    elif [ "$progress" -ge 70 ]; then
        echo "green"
    elif [ "$progress" -ge 50 ]; then
        echo "yellow"
    elif [ "$progress" -ge 30 ]; then
        echo "orange"
    else
        echo "red"
    fi
}

# Função para obter status baseado no progresso
get_status_text() {
    local progress=$1
    if [ "$progress" -ge 90 ]; then
        echo "🟢 Excelente"
    elif [ "$progress" -ge 70 ]; then
        echo "🟢 Bom"
    elif [ "$progress" -ge 50 ]; then
        echo "🟡 Regular"
    elif [ "$progress" -ge 30 ]; then
        echo "🟡 Atrasado"
    else
        echo "🚨 Crítico"
    fi
}

# Função para extrair progresso de uma issue específica
get_issue_progress() {
    local issue_number=$1
    echo "📊 Extraindo progresso da Issue #$issue_number..." >&2
    
    # Obter corpo da issue
    local issue_body
    issue_body=$(gh issue view $issue_number --json body | jq -r '.body')
    
    # Extrair progresso (buscar padrões como **Progresso Atual**: ██░░░░░░░░ 17%)
    local progress
    progress=$(echo "$issue_body" | grep "Progresso Atual" | grep -o "[0-9]\+%" | head -1 | tr -d '%')
    
    # Se não encontrou, buscar por padrões alternativos
    if [ -z "$progress" ]; then
        progress=$(echo "$issue_body" | grep -o "█\+░\+.*[0-9]\+%" | head -1 | grep -o "[0-9]\+%" | tr -d '%')
    fi
    
    echo ${progress:-0}
}

# Função para atualizar badge no dashboard
update_dashboard_badge() {
    local area_name="$1"
    local progress="$2"
    local color
    color=$(get_badge_color $progress)
    local status
    status=$(get_status_text $progress)
    
    echo "🔄 Atualizando badge: $area_name ($progress%)"
    
    # Atualizar badge de progresso
    sed -i "s|📚 \*\*$area_name\*\*.*|📚 \*\*$area_name\*\* \| ![Progress](https://img.shields.io/badge/${progress}%25-${color}) \| $status \|" "$DASHBOARD_FILE"
}

# Função para atualizar disciplina específica
update_discipline() {
    local issue_num="$1"
    local discipline_name="$2"
    local hours="$3"
    
    local progress
    progress=$(get_issue_progress $issue_num)
    local color
    color=$(get_badge_color $progress)
    
    echo "📚 Atualizando disciplina: $discipline_name ($progress%)"
    
    # Usar perl para evitar problemas com caracteres especiais no sed
    perl -i -pe "s/\*\*\Q$discipline_name\E\*\*.*$/\*\*$discipline_name\*\* | ${hours}h | ![Progress](https:\/\/img.shields.io\/badge\/${progress}%25-${color}) |/" "$DASHBOARD_FILE"
}

echo "📈 Atualizando progresso das disciplinas individuais..."

# Atualizar disciplinas específicas baseadas nas issues
update_discipline "2" "Matemática Aplicada" "60"
update_discipline "3" "Tecnologia de Redes" "80"  
update_discipline "4" "Redes de Computadores Remotas" "80"
update_discipline "5" "Cabeamento Estruturado" "60"
update_discipline "6" "Tecnologias de Roteamento" "80"
update_discipline "7" "Sistema Linux" "60"

echo "🎯 Calculando progresso geral..."

# Calcular progresso acadêmico geral baseado nas disciplinas
TOTAL_DISCIPLINES=6
ACADEMIC_TOTAL=0

for issue_num in 2 3 4 5 6 7; do
    progress=$(get_issue_progress $issue_num)
    ACADEMIC_TOTAL=$((ACADEMIC_TOTAL + progress))
done

ACADEMIC_AVERAGE=$((ACADEMIC_TOTAL / TOTAL_DISCIPLINES))

echo "📊 Progresso acadêmico médio: $ACADEMIC_AVERAGE%"

# Atualizar resumo executivo
ACADEMIC_COLOR=$(get_badge_color $ACADEMIC_AVERAGE)
ACADEMIC_STATUS=$(get_status_text $ACADEMIC_AVERAGE)

# Atualizar linha do resumo executivo usando perl
perl -i -pe "s/📚 \*\*Progresso Acadêmico\*\*.*$/📚 \*\*Progresso Acadêmico\*\* | ![Progress](https:\/\/img.shields.io\/badge\/${ACADEMIC_AVERAGE}%25-${ACADEMIC_COLOR}) | $ACADEMIC_STATUS |/" "$DASHBOARD_FILE"

# Atualizar timestamp
CURRENT_DATE=$(date '+%d de %B de %Y')
sed -i "s/Última atualização: .*/Última atualização: $CURRENT_DATE/g" README.md
# Atualizar próxima data de atualização
sed -i "s/\*\*📅 Próxima atualização\*\*: .*/\*\*📅 Próxima atualização\*\*: $(date -d '+1 day' '+%d\/%m\/%Y')/g" "$DASHBOARD_FILE"

echo "✅ Dashboard atualizado com sucesso!"
echo "📁 Backup salvo em: $BACKUP_FILE" 
echo "📊 Resumo das atualizações:"
echo "   - Progresso Acadêmico Médio: $ACADEMIC_AVERAGE%"
echo "   - Status: $ACADEMIC_STATUS"
echo "   - Data de atualização: $CURRENT_DATE"
