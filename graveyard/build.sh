# create tex
pandoc --template technical_specification_working_draft.latex -H header.tex --number-sections --table-of-contents concurrency.0.md concurrency.1.md concurrency.2.md -o D3904.tex

# annotate headings with labels

perl '-i.bak' -p00e 's/\\section{(.*)\\#(.*)\\#(.*)}/\\section[\1]{\1\\hfill[\2]\\label{\3}}/s' D3904.tex
perl '-i.bak' -p00e 's/\\subsection{(.*)\\#(.*)\\#(.*)}/\\subsection[\1]{\1\\hfill[\2]\\label{\3}}/s' D3904.tex
perl '-i.bak' -p00e 's/\\subsubsection{(.*)\\#(.*)\\#(.*)}/\\subsubsection[\1]{\1\\hfill[\2]\\label{\3}}/s' D3904.tex
perl '-i.bak' -p00e 's/\\paragraph{(.*)\\#(.*)\\#(.*)}/\\paragraph[\1]{\1\\hfill[\2]\\label{\3}}/s' D3904.tex
perl '-i.bak' -p00e 's/\\subparagraph{(.*)\\#(.*)\\#(.*)}/\\subparagraph[\1]{\1\\hfill[\2]\\label{\3}}/s' D3904.tex

perl '-i.bak' -p00e 's/\\hfill\[\s(.*)\s\]/\\hfill[\1]/s' D3904.tex

# create pdf
pdflatex D3904.tex
