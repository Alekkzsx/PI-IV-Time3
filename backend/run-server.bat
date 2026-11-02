@echo off
rem Compila e executa o backend (sem Maven). Os jars do driver MongoDB ficam em backend\lib.
rem Configuracao: variavel MONGODB_URI (ou arquivo env na raiz do projeto). Sem ela o servidor usa banco em memoria.
setlocal
cd /d "%~dp0"
if not exist out mkdir out
dir /s /b src\*.java > out\fontes.txt
javac -encoding UTF-8 -cp "lib\*" -d out @out\fontes.txt || exit /b 1
java -cp "out;lib\*" server.ServidorHttpNativo
