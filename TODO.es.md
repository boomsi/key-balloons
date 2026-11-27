# Key Balloons

[English](TODO.en.md) · [简体中文](TODO.md) · [繁體中文](TODO.zh-TW.md) · [Français](TODO.fr.md) · [日本語](TODO.ja.md) · [한국어](TODO.ko.md) · [Español](TODO.es.md)

## Primera versión

- [x] Usar C++ y Qt Quick para el código compartido. Reservar los eventos del sistema y el comportamiento de las ventanas al código de cada plataforma.
- [x] Añadir pruebas automáticas de pulsaciones repetidas, desaparición independiente y entrada rápida.
- [x] Crear la caja translúcida flotante y las etiquetas que suben y se desvanecen por separado en tres segundos.
- [x] Añadir monitorización global del teclado, pausa y salida en macOS y Windows.
- [x] Compilar en macOS, ejecutar las pruebas de animación y comprobar QML de forma estática.
- [x] En macOS, comprobar que la caja permanece encima, la ventana original conserva el foco y los clics pasan a la ventana inferior.
- [x] En macOS, simular 20 entradas por segundo durante 30 segundos. Se crearon y liberaron las 600 etiquetas. Como máximo se mostraron 59 a la vez. El percentil 95 desde la creación hasta el siguiente fotograma de Qt fue de 12 ms.
- [x] Medir el uso de CPU en reposo en macOS. Las dos muestras dieron 0,0 %.
- [x] Compilar y ejecutar las pruebas automáticas de animación en CI para macOS y Windows. [Ejecución de CI](https://github.com/boomsi/key-balloons/actions/runs/45830723721)
- [ ] Comprobar con teclados físicos la entrada entre aplicaciones en ambas plataformas. En Windows, verificar también la posición siempre visible, el foco y el paso de los clics.
- [ ] Medir la latencia entre una pulsación física y su visualización, así como el intervalo entre fotogramas durante una animación continua en Windows.
- [ ] Confirmar la repetición al mantener una tecla y el comportamiento de la opción que sigue al sistema. La primera versión muestra las pulsaciones reales y coloca la caja en la pantalla principal.
- [x] Confirmar la primera versión en Git y enviarla al nuevo repositorio público.
