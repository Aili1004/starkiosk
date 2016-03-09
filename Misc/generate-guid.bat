for /f %%i in ('hostname') do echo %%i > c:\guid.txt
subst P: /D
subst P: "C:\Users\Edd\Dropbox"
pause