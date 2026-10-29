cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

# Define the application target. To change its name, change BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` will no longer
# work.
#
# Any new source files that you add to the application should be added here.
add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# Add preprocessor definitions for the build version.
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION=\"${FLUTTER_VERSION}\"")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}")

# Disable Windows macros that collide with C++ standard library functions.
target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")

# Add dependency libraries and include directories. Add any application-specific
# dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_link_libraries(${BINARY_NAME} PRIVATE "dwmapi.lib")
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")

# Run the Flutter tool portions of the build. This must not be removed.
add_dependencies(${BINARY_NAME} flutter_assemble)

# Automação de inicialização das pastas mães (server/, backend/, security/) durante 'flutter run'
add_custom_command(
  TARGET ${BINARY_NAME} PRE_BUILD
  COMMAND powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $tcp = New-Object System.Net.Sockets.TcpClient('127.0.0.1', 8080); $tcp.Close(); } catch { $serverDir = Resolve-Path '${CMAKE_SOURCE_DIR}/../../server' -ErrorAction SilentlyContinue; if ($serverDir -and (Test-Path $serverDir)) { $cls = if (Test-Path \"$serverDir/bin/Main.class\") { 'Main' } else { 'main.Main' }; Start-Process -FilePath 'java' -ArgumentList \"-cp bin $cls\" -WorkingDirectory $serverDir -WindowStyle Hidden; Write-Host '[AGMRM] Servidor Java e backend inicializados automaticamente via flutter run.' } }"
  COMMENT "Garantindo inicializacao das pastas maes (server e backend) para flutter run..."
)
