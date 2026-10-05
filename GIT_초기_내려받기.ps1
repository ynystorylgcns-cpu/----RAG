# 한글 깨짐 방지==============================================
chcp 65001

[Console]::InputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

git config --global core.quotepath false
git config --global i18n.commitEncoding utf-8
git config --global i18n.logOutputEncoding utf-8
#==============================================
#git 연결

git init
git remote add origin https://github.com/ynystory-gif/ravionyx.git
git fetch origin
git checkout -b main origin/main

# 상태확인
git status
git remote -v
git branch -vv

#파일 내려받기
git pull