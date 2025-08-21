#!/bin/bash

# 📊 Script de Relatório Semanal de Progresso
# Gera relatório automático baseado nas issues do GitHub

set -e

# Configurações
REPO_OWNER="th-hoffmann"
REPO_NAME="carreira-infra-security"
DATE=$(date '+%d/%m/%Y')
WEEK_START=$(date -d 'monday-7 days' '+%Y-%m-%d')
WEEK_END=$(date -d 'sunday-7 days' '+%Y-%m-%d')

echo "📊 Gerando Relatório Semanal de Progresso"
echo "Período: $WEEK_START a $WEEK_END"
echo "Data do relatório: $DATE"
echo ""

# Função para contar issues por label
count_issues_by_label() {
    local label="$1"
    local state="$2"
    gh issue list --label "$label" --state "$state" --json number | jq length
}

# Função para calcular progresso
calculate_progress() {
    local total="$1"
    local completed="$2"
    if [ "$total" -eq 0 ]; then
        echo "0"
    else
        echo "scale=0; $completed * 100 / $total" | bc
    fi
}

echo "## 📈 Resumo da Semana"
echo ""

# Contadores gerais
TOTAL_ISSUES=$(gh issue list --state all --json number | jq length)
CLOSED_ISSUES=$(gh issue list --state closed --json number | jq length)
OPEN_ISSUES=$(gh issue list --state open --json number | jq length)

echo "### 📋 Status Geral"
echo "- **Total de Issues**: $TOTAL_ISSUES"
echo "- **Issues Abertas**: $OPEN_ISSUES"  
echo "- **Issues Fechadas**: $CLOSED_ISSUES"
echo "- **Taxa de Conclusão**: $(calculate_progress $TOTAL_ISSUES $CLOSED_ISSUES)%"
echo ""

# Progresso por categoria
echo "### 📊 Progresso por Categoria"

# Acadêmico
ACADEMIC_TOTAL=$(count_issues_by_label "📚 acadêmico" "all")
ACADEMIC_DONE=$(count_issues_by_label "📚 acadêmico" "closed")
ACADEMIC_PROGRESS=$(calculate_progress $ACADEMIC_TOTAL $ACADEMIC_DONE)

echo "- **📚 Acadêmico**: $ACADEMIC_DONE/$ACADEMIC_TOTAL ($ACADEMIC_PROGRESS%)"

# Certificações
CERT_TOTAL=$(count_issues_by_label "🎓 certificação" "all")
CERT_DONE=$(count_issues_by_label "🎓 certificação" "closed")
CERT_PROGRESS=$(calculate_progress $CERT_TOTAL $CERT_DONE)

echo "- **🎓 Certificações**: $CERT_DONE/$CERT_TOTAL ($CERT_PROGRESS%)"

# Projetos
PROJECT_TOTAL=$(count_issues_by_label "🚀 projeto" "all")
PROJECT_DONE=$(count_issues_by_label "🚀 projeto" "closed")
PROJECT_PROGRESS=$(calculate_progress $PROJECT_TOTAL $PROJECT_DONE)

echo "- **🚀 Projetos**: $PROJECT_DONE/$PROJECT_TOTAL ($PROJECT_PROGRESS%)"

# Metas
META_TOTAL=$(count_issues_by_label "🎯 meta" "all")  
META_DONE=$(count_issues_by_label "🎯 meta" "closed")
META_PROGRESS=$(calculate_progress $META_TOTAL $META_DONE)

echo "- **🎯 Metas**: $META_DONE/$META_TOTAL ($META_PROGRESS%)"
echo ""

# Issues fechadas na semana
echo "### ✅ Conquistas da Semana"
CLOSED_THIS_WEEK=$(gh issue list --state closed --search "closed:>=$WEEK_START" --json number,title | jq length)

if [ "$CLOSED_THIS_WEEK" -gt 0 ]; then
    echo "**$CLOSED_THIS_WEEK issues concluídas:**"
    gh issue list --state closed --search "closed:>=$WEEK_START" --json number,title | jq -r '.[] | "- #\(.number): \(.title)"'
else
    echo "- Nenhuma issue foi concluída nesta semana"
fi
echo ""

# Issues criadas na semana
echo "### 🆕 Novos Itens Planejados"
CREATED_THIS_WEEK=$(gh issue list --search "created:>=$WEEK_START" --json number | jq length)

if [ "$CREATED_THIS_WEEK" -gt 0 ]; then
    echo "**$CREATED_THIS_WEEK novas issues criadas:**"
    gh issue list --search "created:>=$WEEK_START" --json number,title | jq -r '.[] | "- #\(.number): \(.title)"'
else
    echo "- Nenhuma nova issue foi criada nesta semana"
fi
echo ""

# Próximos deadlines
echo "### ⏰ Próximos Prazos"
echo "Issues com deadline nos próximos 7 dias:"

# Aqui você pode adicionar lógica para verificar issues com datas próximas
# Isso dependeria de como você armazena as datas (custom fields, milestones, etc.)

gh issue list --state open --json number,title,labels | jq -r '.[] | select(.labels[]?.name | test("urgent|deadline")) | "- #\(.number): \(.title)"' || echo "- Nenhum prazo urgente identificado"

echo ""
echo "---"
echo "*Relatório gerado automaticamente em $DATE*"
echo "*Próximo relatório: $(date -d '+7 days' '+%d/%m/%Y')*"
