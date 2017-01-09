@echo off

:: Tell Bundler where the Gemfile and gems are.
set "BUNDLE_GEMFILE=%~dp0\lib\vendor\Gemfile"
set BUNDLE_IGNORE_CONFIG=

:: Run the actual binary using the bundled Ruby.
@"%~dp0\lib\ruby\bin\ruby.bat" -rbundler/setup "%~dp0\lib\vendor\ruby\2.2.0\bin\elm-install" %*
