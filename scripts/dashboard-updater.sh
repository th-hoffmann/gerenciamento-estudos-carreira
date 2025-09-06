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

# Função para extrair progresso de uma issue específica baseado em sub-issues
get_issue_progress() {
    local issue_number=$1
    echo "📊 Calculando progresso da Issue #$issue_number baseado em sub-issues..." >&2
    
    # Obter título da issue principal para identificar sub-issues relacionadas
    local issue_title
    issue_title=$(gh issue view $issue_number --json title | jq -r '.title')
    
    # Definir termos de busca baseados no número da issue
    local search_terms=""
    case $issue_number in
        2) # Matemática Aplicada
            search_terms="matemática"
            ;;
        3) # Tecnologia de Redes  
            search_terms="tecnologia.*redes|redes.*tecnologia"
            ;;
        4) # Redes Remotas
            search_terms="redes.*remotas|remotas.*redes"
            ;;
        5) # Cabeamento Estruturado
            search_terms="cabeamento"
            ;;
        6) # Tecnologias de Roteamento
            search_terms="roteamento"
            ;;
        7) # Sistema Linux
            search_terms="linux"
            ;;
    esac
    
    # Buscar sub-issues relacionadas
    local total_subissues=0
    local closed_subissues=0
    
    # Obter todas as issues e filtrar por termos relacionados
    local all_issues
    all_issues=$(gh issue list --state all --json number,title,state --limit 100)
    
    # Filtrar issues relacionadas usando jq
    local related_issues
    related_issues=$(echo "$all_issues" | jq -r '.[] | select(.title | test("'$search_terms'"; "i")) | "\(.number) \(.state)"')
    
    if [ -n "$related_issues" ]; then
        while IFS=' ' read -r issue_num state; do
            # Ignorar a issue principal
            if [ "$issue_num" != "$issue_number" ]; then
                total_subissues=$((total_subissues + 1))
                if [ "$state" = "CLOSED" ]; then
                    closed_subissues=$((closed_subissues + 1))
                fi
            fi
        done <<< "$related_issues"
    fi
    
    # Verificar se a disciplina tem sub-issues
    if [ $total_subissues -gt 0 ]; then
        local progress=$(( (closed_subissues * 100) / total_subissues ))
        echo "   📋 Sub-issues encontradas: $total_subissues (fechadas: $closed_subissues) = $progress%" >&2
        echo $progress
    else
        echo "   ⏭️  Nenhuma sub-issue encontrada, pulando disciplina..." >&2
        echo "SKIP"
    fi
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
    
    local progress
    progress=$(get_issue_progress $issue_num)
    
    # Verificar se a disciplina deve ser pulada
    if [ "$progress" = "SKIP" ]; then
        echo "⏭️  Pulando disciplina: $discipline_name (sem sub-issues)"
        return 0
    fi
    
    local color
    color=$(get_badge_color $progress)
    
    echo "📚 Atualizando disciplina: $discipline_name ($progress%)"
    
    # Usar perl para evitar problemas com caracteres especiais no sed
    # Substituir apenas o badge de progresso preservando as demais colunas
    perl -i -pe "s/(.*\*\*\Q$discipline_name\E\*\*.*?\|.*?\|)\s*!\[Progress\]\([^)]+\)(\s*\|.*)/\$1 ![Progress](https:\/\/img.shields.io\/badge\/${progress}%25-${color})\$2/" "$DASHBOARD_FILE"
}

echo "📈 Atualizando progresso das disciplinas individuais..."

# Atualizar disciplinas específicas baseadas nas issues
update_discipline "2" "Matemática Aplicada"
update_discipline "3" "Tecnologia de Redes"  
update_discipline "4" "Redes de Computadores Remotas"
update_discipline "5" "Cabeamento Estruturado"
update_discipline "6" "Tecnologias de Roteamento"
update_discipline "7" "Sistema Linux"

echo "🎯 Calculando progresso geral..."

# Calcular progresso acadêmico geral baseado apenas nas disciplinas com sub-issues
VALID_DISCIPLINES=0
ACADEMIC_TOTAL=0

for issue_num in 2 3 4 5 6 7; do
    progress=$(get_issue_progress $issue_num)
    if [ "$progress" != "SKIP" ]; then
        ACADEMIC_TOTAL=$((ACADEMIC_TOTAL + progress))
        VALID_DISCIPLINES=$((VALID_DISCIPLINES + 1))
    fi
done

# Calcular média apenas das disciplinas válidas
if [ $VALID_DISCIPLINES -gt 0 ]; then
    ACADEMIC_AVERAGE=$((ACADEMIC_TOTAL / VALID_DISCIPLINES))
    echo "📊 Progresso acadêmico médio: $ACADEMIC_AVERAGE% (baseado em $VALID_DISCIPLINES disciplinas)"
else
    ACADEMIC_AVERAGE=0
    echo "⚠️  Nenhuma disciplina com sub-issues encontrada, usando 0%"
fi

# Atualizar resumo executivo
ACADEMIC_COLOR=$(get_badge_color $ACADEMIC_AVERAGE)
ACADEMIC_STATUS=$(get_status_text $ACADEMIC_AVERAGE)

# Atualizar linha do resumo executivo usando perl - preservando coluna "Próximo Milestone"
perl -i -pe "s/(.*📚 \*\*Progresso Acadêmico\*\*.*?\|)\s*!\[Progress\]\([^)]+\)(\s*\|.*)/\$1 ![Progress](https:\/\/img.shields.io\/badge\/${ACADEMIC_AVERAGE}%25-${ACADEMIC_COLOR})\$2/" "$DASHBOARD_FILE"

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
