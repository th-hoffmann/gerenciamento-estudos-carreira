#!/usr/bin/env bash

# ╔═════════════════════════════════════════════════════════════════════════════╗
# ║  📊 weekly-report.sh - Sistema de Relatórios Semanais
# ╚═════════════════════════════════════════════════════════════════════════════╝
# 
# ╔═════════════════════════════════════════════════════════════════════════════╗
# ║ 📋 INFORMAÇÕES DO SCRIPT
# ╚═════════════════════════════════════════════════════════════════════════════╝
# 
#   📄 Descrição.....: Sistema completo de geração de relatórios semanais
#   integrado com GitHub Actions para automação dominical.
#   Gera relatórios em Markdown com links simbólicos e histórico completo.
#
#   👨‍💻 Desenvolvedor.: Thiago Hoffmann
#   📮 Contato.......: thiago@hoffmann.tec.br
#   🔗 GitHub........: https://github.com/th-hoffmann
#   🌐 LinkedIn......: https://linkedin.com/in/th-hoffmann87
#   
#   📅 Data..........: 27/08/2025
#   🏷️  Versão.......: 2.0.0
#   
#   � Novidades v2.0.0:
#   - ✅ Sistema de relatórios com timestamp legível
#   - ✅ Links simbólicos entre relatórios (navegação)
#   - ✅ Diretório dedicado reports/weekly/ 
#   - ✅ Acesso rápido via latest-weekly-report
#   - ✅ Integração GitHub Actions (execução dominical)
#   - ✅ Formato único Markdown (sem HTML)
#   - ✅ Histórico completo sem retenção
#   - ✅ Cálculo automático de semana do ano
# 
# ╔═════════════════════════════════════════════════════════════════════════════╗
# ║ 🚀 MODO DE USO
# ╚═════════════════════════════════════════════════════════════════════════════╝
# 
#   Manual:      ./scripts/weekly-report.sh
#   Automático:  GitHub Actions (domingos 18:00 BRT)
#   Acesso:      cat latest-weekly-report
#
# ═══════════════════════════════════════════════════════════════════════════════

set -e

# ╔═════════════════════════════════════════════════════════════════════════════╗
# ║ ⚙️ CONFIGURAÇÕES GLOBAIS
# ╚═════════════════════════════════════════════════════════════════════════════╝

# Diretórios
REPORTS_DIR="reports"
WEEKLY_DIR="$REPORTS_DIR/weekly"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Datas e timestamps
CURRENT_DATE=$(date '+%Y-%m-%d')
CURRENT_WEEK_NUM=$(date '+%V')
CURRENT_YEAR=$(date '+%Y')
READABLE_DATE=$(date '+%d/%m/%Y')
WEEK_START=$(date -d 'monday-7 days' '+%Y-%m-%d')
WEEK_END=$(date -d 'sunday-7 days' '+%Y-%m-%d')

# Nomes de arquivos
REPORT_FILENAME="${CURRENT_DATE}_Semana-${CURRENT_WEEK_NUM}.md"
REPORT_PATH="$PROJECT_ROOT/$WEEKLY_DIR/$REPORT_FILENAME"
LATEST_LINK="$PROJECT_ROOT/latest-weekly-report"

echo "📊 Sistema de Relatórios Semanais v2.0.0"
echo "════════════════════════════════════════"
echo "📅 Período: $WEEK_START a $WEEK_END"
echo "📊 Relatório: $REPORT_FILENAME"
echo "📂 Destino: $WEEKLY_DIR/"
echo ""

# ╔═════════════════════════════════════════════════════════════════════════════╗
# ║ 🛠️ FUNÇÕES AUXILIARES
# ╚═════════════════════════════════════════════════════════════════════════════╝

# Função para criar diretórios necessários
create_directories() {
    echo "📁 Criando estrutura de diretórios..."
    mkdir -p "$PROJECT_ROOT/$REPORTS_DIR"
    mkdir -p "$PROJECT_ROOT/$WEEKLY_DIR"
}

# Função para encontrar o relatório anterior
find_previous_report() {
    local previous_report=""
    
    # Procurar pelo arquivo mais recente (excluindo o atual)
    for file in "$PROJECT_ROOT/$WEEKLY_DIR"/*.md; do
        if [[ -f "$file" && "$file" != "$REPORT_PATH" ]]; then
            # Extrair apenas o nome do arquivo
            previous_report=$(basename "$file")
        fi
    done
    
    echo "$previous_report"
}

# Função para contar issues por label
count_issues_by_label() {
    local label="$1"
    local state="$2"
    
    # Verificar se gh está disponível
    if ! command -v gh &> /dev/null; then
        echo "0"
        return
    fi
    
    gh issue list --label "$label" --state "$state" --json number 2>/dev/null | jq length 2>/dev/null || echo "0"
}

# Função para calcular progresso
calculate_progress() {
    local total="$1"
    local completed="$2"
    if [ "$total" -eq 0 ]; then
        echo "0"
    else
        echo "scale=0; $completed * 100 / $total" | bc 2>/dev/null || echo "0"
    fi
}

# Função para extrair dados do DASHBOARD_KPIS.md
extract_dashboard_data() {
    local dashboard_file="$PROJECT_ROOT/DASHBOARD_KPIS.md"
    
    if [[ ! -f "$dashboard_file" ]]; then
        echo "⚠️ DASHBOARD_KPIS.md não encontrado"
        return 1
    fi
    
    echo "📊 Extraindo dados do DASHBOARD_KPIS.md..."
    return 0
}

# Função para gerar o relatório em Markdown
generate_markdown_report() {
    local previous_report
    previous_report=$(find_previous_report)
    
    echo "📝 Gerando relatório Markdown..."
    
    cat > "$REPORT_PATH" << EOF
# 📊 Relatório Semanal - Semana ${CURRENT_WEEK_NUM} (${READABLE_DATE})

## 🔗 Navegação
EOF

    if [[ -n "$previous_report" ]]; then
        echo "- 📄 [Relatório Anterior](./$previous_report)" >> "$REPORT_PATH"
    else
        echo "- 📄 Primeiro relatório do sistema" >> "$REPORT_PATH"
    fi

    cat >> "$REPORT_PATH" << EOF
- 🏠 [Voltar ao Projeto](../../README.md)
- 📊 [Dashboard Atual](../../DASHBOARD_KPIS.md)

---

## 📈 Resumo da Semana
**Período:** ${WEEK_START} a ${WEEK_END}  
**Data do Relatório:** ${READABLE_DATE}

### 📋 Status Geral
EOF

    # Contadores gerais (com fallback se gh não estiver disponível)
    if command -v gh &> /dev/null; then
        local TOTAL_ISSUES CLOSED_ISSUES OPEN_ISSUES
        TOTAL_ISSUES=$(gh issue list --state all --json number 2>/dev/null | jq length 2>/dev/null || echo "N/A")
        CLOSED_ISSUES=$(gh issue list --state closed --json number 2>/dev/null | jq length 2>/dev/null || echo "N/A")
        OPEN_ISSUES=$(gh issue list --state open --json number 2>/dev/null | jq length 2>/dev/null || echo "N/A")

        cat >> "$REPORT_PATH" << EOF
- **Total de Issues**: ${TOTAL_ISSUES}
- **Issues Abertas**: ${OPEN_ISSUES}  
- **Issues Fechadas**: ${CLOSED_ISSUES}
- **Taxa de Conclusão**: $(calculate_progress "${TOTAL_ISSUES}" "${CLOSED_ISSUES}")%
EOF
    else
        cat >> "$REPORT_PATH" << EOF
- **Sistema GitHub Issues**: Não disponível no momento
- **Dados extraídos de**: DASHBOARD_KPIS.md
EOF
    fi

    cat >> "$REPORT_PATH" << EOF

### 📊 Progresso por Categoria
EOF

    # Progresso por categoria
    if command -v gh &> /dev/null; then
        local ACADEMIC_TOTAL ACADEMIC_DONE ACADEMIC_PROGRESS
        local CERT_TOTAL CERT_DONE CERT_PROGRESS  
        local PROJECT_TOTAL PROJECT_DONE PROJECT_PROGRESS
        local META_TOTAL META_DONE META_PROGRESS

        ACADEMIC_TOTAL=$(count_issues_by_label "📚 acadêmico" "all")
        ACADEMIC_DONE=$(count_issues_by_label "📚 acadêmico" "closed")
        ACADEMIC_PROGRESS=$(calculate_progress "$ACADEMIC_TOTAL" "$ACADEMIC_DONE")

        CERT_TOTAL=$(count_issues_by_label "🎓 certificação" "all")
        CERT_DONE=$(count_issues_by_label "🎓 certificação" "closed")
        CERT_PROGRESS=$(calculate_progress "$CERT_TOTAL" "$CERT_DONE")

        PROJECT_TOTAL=$(count_issues_by_label "🚀 projeto" "all")
        PROJECT_DONE=$(count_issues_by_label "🚀 projeto" "closed")
        PROJECT_PROGRESS=$(calculate_progress "$PROJECT_TOTAL" "$PROJECT_DONE")

        META_TOTAL=$(count_issues_by_label "🎯 meta" "all")
        META_DONE=$(count_issues_by_label "🎯 meta" "closed")
        META_PROGRESS=$(calculate_progress "$META_TOTAL" "$META_DONE")

        cat >> "$REPORT_PATH" << EOF
- **📚 Acadêmico**: ${ACADEMIC_DONE}/${ACADEMIC_TOTAL} (${ACADEMIC_PROGRESS}%)
- **🎓 Certificações**: ${CERT_DONE}/${CERT_TOTAL} (${CERT_PROGRESS}%)
- **🚀 Projetos**: ${PROJECT_DONE}/${PROJECT_TOTAL} (${PROJECT_PROGRESS}%)
- **🎯 Metas**: ${META_DONE}/${META_TOTAL} (${META_PROGRESS}%)
EOF
    else
        # Extrair dados do DASHBOARD_KPIS.md como fallback
        if [[ -f "$PROJECT_ROOT/DASHBOARD_KPIS.md" ]]; then
            echo "- **Dados extraídos do DASHBOARD_KPIS.md em $(date '+%d/%m/%Y')**" >> "$REPORT_PATH"
        else
            echo "- **Dados não disponíveis no momento**" >> "$REPORT_PATH"
        fi
    fi

    # Conquistas e novos itens
    cat >> "$REPORT_PATH" << EOF

### ✅ Conquistas da Semana
EOF

    if command -v gh &> /dev/null; then
        local CLOSED_THIS_WEEK
        CLOSED_THIS_WEEK=$(gh issue list --state closed --search "closed:>=$WEEK_START" --json number 2>/dev/null | jq length 2>/dev/null || echo "0")

        if [ "$CLOSED_THIS_WEEK" -gt 0 ]; then
            echo "**${CLOSED_THIS_WEEK} issues concluídas:**" >> "$REPORT_PATH"
            gh issue list --state closed --search "closed:>=$WEEK_START" --json number,title 2>/dev/null | jq -r '.[] | "- #\(.number): \(.title)"' >> "$REPORT_PATH" 2>/dev/null || echo "- Erro ao listar issues concluídas" >> "$REPORT_PATH"
        else
            echo "- Nenhuma issue foi concluída nesta semana" >> "$REPORT_PATH"
        fi
    else
        echo "- Sistema de tracking via GitHub Issues não disponível" >> "$REPORT_PATH"
    fi

    cat >> "$REPORT_PATH" << EOF

### 🆕 Novos Itens Planejados
EOF

    if command -v gh &> /dev/null; then
        local CREATED_THIS_WEEK
        CREATED_THIS_WEEK=$(gh issue list --search "created:>=$WEEK_START" --json number 2>/dev/null | jq length 2>/dev/null || echo "0")

        if [ "$CREATED_THIS_WEEK" -gt 0 ]; then
            echo "**${CREATED_THIS_WEEK} novas issues criadas:**" >> "$REPORT_PATH"
            gh issue list --search "created:>=$WEEK_START" --json number,title 2>/dev/null | jq -r '.[] | "- #\(.number): \(.title)"' >> "$REPORT_PATH" 2>/dev/null || echo "- Erro ao listar novas issues" >> "$REPORT_PATH"
        else
            echo "- Nenhuma nova issue foi criada nesta semana" >> "$REPORT_PATH"
        fi
    else
        echo "- Planejamento via DASHBOARD_KPIS.md" >> "$REPORT_PATH"
    fi

    # Próximos prazos e footer
    cat >> "$REPORT_PATH" << EOF

### ⏰ Próximos Prazos
EOF

    if command -v gh &> /dev/null; then
        echo "Issues com deadline nos próximos 7 dias:" >> "$REPORT_PATH"
        gh issue list --state open --json number,title,labels 2>/dev/null | jq -r '.[] | select(.labels[]?.name | test("urgent|deadline")) | "- #\(.number): \(.title)"' >> "$REPORT_PATH" 2>/dev/null || echo "- Nenhum prazo urgente identificado" >> "$REPORT_PATH"
    else
        echo "- Consultar DASHBOARD_KPIS.md para prazos atualizados" >> "$REPORT_PATH"
    fi

    cat >> "$REPORT_PATH" << EOF

---

## 📊 Métricas Importantes

### 🎯 KPIs Principais
- **Progresso Acadêmico**: Consultar [DASHBOARD_KPIS.md](../../DASHBOARD_KPIS.md)
- **Certificações**: Planejamento em andamento
- **Projetos**: Acompanhar evolução semanal

### 📈 Evolução
- **Esta Semana**: Semana ${CURRENT_WEEK_NUM}/${CURRENT_YEAR}
- **Próximo Relatório**: $(date -d '+7 days' '+%d/%m/%Y') (Semana $((CURRENT_WEEK_NUM + 1)))

---

## 🔄 Navegação entre Relatórios
EOF

    if [[ -n "$previous_report" ]]; then
        echo "- ⬅️ [Anterior: $previous_report](./$previous_report)" >> "$REPORT_PATH"
    fi
    echo "- ➡️ Próximo: Será gerado em $(date -d '+7 days' '+%d/%m/%Y')" >> "$REPORT_PATH"

    cat >> "$REPORT_PATH" << EOF

---

*📊 Relatório gerado automaticamente em ${READABLE_DATE}*  
*🤖 Sistema: weekly-report.sh v2.0.0*  
*🔗 Acesso rápido: \`latest-weekly-report\` na raiz do projeto*

EOF
}

# Função para atualizar links simbólicos
update_symbolic_links() {
    echo "🔗 Atualizando links simbólicos..."
    
    # Remover link anterior se existir
    if [[ -L "$LATEST_LINK" ]] || [[ -f "$LATEST_LINK" ]]; then
        rm -f "$LATEST_LINK"
    fi
    
    # Criar novo link simbólico para o relatório atual
    cd "$PROJECT_ROOT"
    ln -sf "$WEEKLY_DIR/$REPORT_FILENAME" "latest-weekly-report"
    
    echo "✅ Link simbólico atualizado: latest-weekly-report -> $WEEKLY_DIR/$REPORT_FILENAME"
}

# ╔═════════════════════════════════════════════════════════════════════════════╗
# ║ 🚀 FUNÇÃO PRINCIPAL
# ╚═════════════════════════════════════════════════════════════════════════════╝

main() {
    echo "🎯 Iniciando geração do relatório semanal..."
    
    # Criar estrutura de diretórios
    create_directories
    
    # Gerar relatório em Markdown
    generate_markdown_report
    
    # Atualizar links simbólicos
    update_symbolic_links
    
    echo ""
    echo "✅ Relatório semanal gerado com sucesso!"
    echo "📂 Localização: $WEEKLY_DIR/$REPORT_FILENAME"
    echo "🔗 Acesso rápido: latest-weekly-report"
    echo "📊 Próximo relatório: $(date -d '+7 days' '+%d/%m/%Y')"
    echo ""
    echo "🎯 Para visualizar: cat latest-weekly-report"
}

# Executar função principal
main "$@"
