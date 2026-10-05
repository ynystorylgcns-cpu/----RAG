# 한글 깨짐 방지==============================================
# UTF-8 설정
chcp 65001

[Console]::InputEncoding  = New-Object System.Text.UTF8Encoding($false)
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
$OutputEncoding = New-Object System.Text.UTF8Encoding($false)

$env:LANG = "ko_KR.UTF-8"
$env:LC_ALL = "ko_KR.UTF-8"

git config --global core.quotepath false
git config --global i18n.commitEncoding utf-8
git config --global i18n.logOutputEncoding utf-8
#==============================================

cd "F:\Source\repos\건설사고-재발방지대책-RAG"

git status
git add -A
git commit -m "로컬 수정사항 업데이트"
git push









