@setlocal
@echo off
if not exist %~dp0..\nodiffs md %~dp0..\nodiffs
set PYTHON_CMD=C:\Python34\python.exe

FOR /D %%f IN (
    atomic_smart_ptr.html
    future.html
    latch_barrier.html
    main.html
) DO %PYTHON_CMD% %~dp0remove_diff_marks.py %~dp0..\%%f %~dp0..\nodiffs\%%f
windiff %~dp0..\*.html %~dp0..\nodiffs\*.html