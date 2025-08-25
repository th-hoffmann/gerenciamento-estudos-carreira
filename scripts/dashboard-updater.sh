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
#    das issues do GitHub, integrando com o weekly-report.sh
#
#   👨‍💻 Desenvolvedor.: Thiago Hoffmann
#   📅 Data..........: 25/08/2025
#   🏷️  Versão.......: 1.0.0
# 
# ═══════════════════════════════════════════════════════════════════════════════

set -e

DASHBOARD_FILE="DASHBOARD_KPIS.md"
BACKUP_FILE="DASHBOARD_KPIS.md.backup"

echo "🔄 Iniciando atualização integrada do dashboard..."

# Backup do arquivo original
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
    local issue_body=$(gh issue view $issue_number --json body | jq -r '.body')
    
    # Extrair progresso (buscar padrões como **Progresso Atual**: ██░░░░░░░░ 17%)
    local progress=$(echo "$issue_body" | grep "Progresso Atual" | grep -o "[0-9]\+%" | head -1 | tr -d '%')
    
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
    local color=$(get_badge_color $progress)
    local status=$(get_status_text $progress)
    
    echo "🔄 Atualizando badge: $area_name ($progress%)"
    
    # Atualizar badge de progresso
    sed -i "s|📚 \*\*$area_name\*\*.*|📚 \*\*$area_name\*\* \| ![Progress](https://img.shields.io/badge/${progress}%25-${color}) \| $status \|" "$DASHBOARD_FILE"
}

# Função para atualizar disciplina específica
update_discipline() {
    local issue_num="$1"
    local discipline_name="$2"
    local hours="$3"
    
    local progress=$(get_issue_progress $issue_num)
    local color=$(get_badge_color $progress)
    
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
sed -i "s/Próxima revisão: .*/Próxima revisão: $(date -d '+7 days' '+%d\/%m\/%Y')/g" "$DASHBOARD_FILE"

echo "✅ Dashboard atualizado com sucesso!"
echo "📁 Backup salvo em: $BACKUP_FILE" 
echo "📊 Resumo das atualizações:"
echo "   - Progresso Acadêmico Médio: $ACADEMIC_AVERAGE%"
echo "   - Status: $ACADEMIC_STATUS"
echo "   - Data de atualização: $CURRENT_DATE"
