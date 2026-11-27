# <img src="assets/KeyBalloons.svg" alt="Icono de Key Balloons" width="36"> Key Balloons

[English](README.md) · [简体中文](README.zh.md) · [繁體中文](README.zh-TW.md) · [Français](README.fr.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md)

Key Balloons muestra una caja flotante en el escritorio de macOS y Windows. Al escribir en cualquier aplicación, las etiquetas de las teclas suben desde la caja y se desvanecen en unos dos segundos. Cada pulsación tiene su propia animación, incluidas las pulsaciones repetidas.

**[Descargar](https://github.com/boomsi/key-balloons/releases)** · [Instalación](#instalación) · [Uso](#uso) · [Compilar desde el código fuente](#compilar-desde-el-código-fuente) · [Guía de integración](docs/mouse-feedback.es.md)

![Demostración de Key Balloons: las teclas flotan al escribir kissmenow](assets/key-balloons-demo.gif)

> Las pulsaciones se usan en el dispositivo para mostrar la animación. La aplicación no guarda un historial ni envía pulsaciones por la red.

## Instalación

Descarga el instalador de tu sistema desde [GitHub Releases](https://github.com/boomsi/key-balloons/releases).

| Plataforma | Pasos de instalación |
| --- | --- |
| macOS | Abre el `.dmg` universal, arrastra **KeyBalloons.app** a Aplicaciones y ábrela desde esa carpeta. |
| Windows | Ejecuta el instalador x64 `.exe` y abre **Key Balloons** desde el menú Inicio. |

### Permitir la monitorización de entrada en macOS

1. Si se solicita permiso al iniciar, elige **Abrir la monitorización de entrada**. También puedes elegir **Activar la monitorización…** en la barra de menús.
2. En Ajustes del Sistema → Privacidad y seguridad → Monitorización de entrada, arrastra el icono de Key Balloons de la tarjeta de ayuda a la lista.
3. Activa el interruptor. La tarjeta se cierra cuando la aplicación detecta el permiso. Si macOS pide cerrar y volver a abrir la aplicación, sigue sus indicaciones.

Después de actualizar, usa **−** para eliminar la entrada anterior si sigue apareciendo. Añade y autoriza la versión actual.

## Uso

Escribe en tu aplicación habitual. La caja permanece encima y muestra una etiqueta por cada pulsación.

Los clics izquierdo y derecho iluminan su lado. Desplazar o pulsar la rueda ilumina el centro. En **Avanzado** puedes activar la [integración con aplicaciones locales](docs/mouse-feedback.es.md).

### Ajustes

Haz clic derecho en la caja o elige **Settings… (Ajustes…)** en la barra de menús o en el área de notificación. Ambos abren el mismo panel.

- En **Apariencia**, **Tamaño** (50 %–150 %) y **Opacidad** (20 %–100 %) se aplican a la caja y a las etiquetas.
- En **Posición**, activa **Permitir arrastrar** para mover la caja con el botón izquierdo. **Ajustar al borde inferior** la coloca en la parte inferior del área utilizable de la pantalla más cercana al soltarla.
- **Idioma** cambia la interfaz al instante y guarda la selección. El idioma predeterminado es el inglés.
- El menú muestra la memoria que usa la aplicación y el estado de la monitorización. Desde ahí también puedes pausar, reanudar o salir.

En macOS 26, si se compila con Xcode 26 o posterior, se usa un panel nativo Liquid Glass. En macOS, la caja y las animaciones mantienen su posición al cambiar de espacio.

## Compilar desde el código fuente

Necesitas CMake 3.21 o posterior, el SDK de escritorio Qt 6.10 con Qt Quick, Qt Quick Test y las herramientas de Qt Linguist, y Xcode o las herramientas de C++ de Visual Studio 2022. Los ejemplos usan Qt 6.10.3.

### macOS

```sh
cmake -S . -B build \
  -DCMAKE_BUILD_TYPE=Release \
  -DKEY_BALLOONS_DEVELOPMENT_BUILD=ON \
  -DCMAKE_PREFIX_PATH="$HOME/Qt/6.10.3/macos"
cmake --build build --parallel
ctest --test-dir build --output-on-failure
open build/KeyBalloonsDev.app
```

### Windows (PowerShell)

```powershell
$qt = "$env:USERPROFILE/Qt/6.10.3/msvc2022_64"
$env:Path = "$qt/bin;$env:Path"
cmake -S . -B build -A x64 "-DCMAKE_PREFIX_PATH=$qt"
cmake --build build --config Release --parallel
ctest --test-dir build --build-config Release --output-on-failure
& "./build/Release/KeyBalloons.exe"
```

## Instaladores de las versiones

Publicar una versión en GitHub inicia **Release installers**. El flujo compila desde la etiqueta, ejecuta las pruebas y, tras verificar los paquetes, adjunta el `.dmg` universal para macOS y el `.exe` x64 para Windows.

Usa **Actions → Release installers → Run workflow** para probar el empaquetado. Los dos instaladores aparecen en **Artifacts**. El paquete de macOS usa firma ad hoc. La notarización de Apple y la firma de distribución para Windows requieren sus respectivas credenciales.

## Estructura y pruebas

- [`examples/basic-box/`](examples/basic-box/) contiene el ejemplo de la caja integrada, sus animaciones y su suscriptor a eventos del ratón.
- `src/macos/` y `src/windows/` gestionan la entrada de cada plataforma. El módulo de macOS también proporciona los ajustes nativos y la guía de permisos.
- `tests/tst_balloons.qml` cubre la entrada rápida, el desvanecimiento independiente, el arrastre, la respuesta visual del ratón y los ajustes. `tests/tst_overlay_core.cpp` cubre la posición, la integración local, los idiomas y la memoria.
- `tests/tst_stress.qml` simula 20 entradas por segundo durante 30 segundos. Informa del percentil 95 del intervalo entre fotogramas y del tiempo desde la creación de la etiqueta hasta el siguiente fotograma de Qt. La latencia física se mide por separado.

Ejecuta la prueba de animación continua en una sesión de escritorio.

```sh
./build/key_balloons_tests -input tests/tst_stress.qml
```

En Windows, usa `./build/Release/key_balloons_tests.exe`. Para una comprobación rápida, escribe `A A B` en TextEdit o el Bloc de notas. El editor debe mantener el foco mientras las tres etiquetas suben y desaparecen por separado. Consulta la [lista de comprobaciones](TODO.es.md).
