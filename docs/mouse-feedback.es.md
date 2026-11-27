# Integración de la respuesta visual del ratón

[English](mouse-feedback.md) · [简体中文](mouse-feedback.zh.md) · [繁體中文](mouse-feedback.zh-TW.md) · [Français](mouse-feedback.fr.md) · [日本語](mouse-feedback.ja.md) · [한국어](mouse-feedback.ko.md) · [Español](mouse-feedback.es.md)

Haz clic derecho en la caja o abre **Ajustes…** desde la barra de menús o el área de notificación. En **Avanzado**, activa **Permitir integraciones locales del ratón**. La integración se inicia desactivada. Si la desactivas, se desconectan los clientes externos. La caja integrada sigue suscrita mediante una conexión privada con el mismo protocolo.

## Conexión

Tras activar la integración, lee `mouse-feedback-v1.json` en una de estas rutas. Cada instancia tiene su propio punto de conexión. Vuelve a leer el archivo antes de reconectar. Para cada usuario, solo una instancia puede abrir el acceso para clientes externos a la vez.

| Plataforma | Ruta del descriptor | Transporte |
| --- | --- | --- |
| macOS | `~/Library/Application Support/Key Balloons/mouse-feedback-v1.json` | Socket de dominio Unix |
| Windows | `%LOCALAPPDATA%\Key Balloons\mouse-feedback-v1.json` | Canalización con nombre |

El descriptor contiene un número `version` y una cadena `endpoint`. Usa `endpoint` como ruta del socket local o de la canalización. Pueden conectarse los procesos locales ejecutados por el mismo usuario.

## Enviar y recibir eventos

Cada mensaje es un objeto JSON UTF-8 seguido de un salto de línea (`\n`). El límite es de 512 bytes, incluido el salto de línea. Todos los mensajes incluyen `"version":1`. Si se supera el límite, se cierra la conexión.

| Evento | Entrada nativa | Caja integrada |
| --- | --- | --- |
| `mouse.left` | Pulsación del botón izquierdo | Se ilumina el lado izquierdo |
| `mouse.right` | Pulsación del botón derecho | Se ilumina el lado derecho |
| `mouse.wheel` | Desplazamiento vertical u horizontal o pulsación de la rueda | Se ilumina el centro |

Envía `subscribe` una vez en la conexión. Tras la confirmación, los eventos nuevos llegan como mensajes `event`. Los anteriores no se vuelven a enviar. El mismo cliente puede publicar en esa conexión y también recibe los eventos que publica si está suscrito.

```jsonl
{"version":1,"op":"subscribe"}
{"version":1,"op":"ok","request":"subscribe"}
{"version":1,"op":"event","event":"mouse.left"}
```

Para activar el efecto, envía `publish` con un nombre de evento de la tabla. La caja se ilumina y los suscriptores reciben el evento. La publicación solo produce un efecto visual. Los clientes externos pueden publicar mientras la monitorización nativa está en pausa. En macOS, los eventos nativos requieren permiso de Monitorización de entrada.

```jsonl
{"version":1,"op":"publish","event":"mouse.right"}
{"version":1,"op":"ok","request":"publish"}
```

Las solicitudes inválidas devuelven `{"version":1,"op":"error","code":"…"}`. Los códigos son `invalid_message`, `unsupported_version`, `unsupported_operation` y `unsupported_event`. La confirmación indica que se aceptó la solicitud. Los eventos solo contienen el nombre de la acción. Un cliente que lea demasiado despacio puede desconectarse. Vuelve a conectar y suscribirte para seguir recibiendo eventos.

## Ejecutar el ejemplo

Una vez instalado Node.js y activada la integración, ejecuta estos comandos desde la raíz del repositorio en dos terminales. El comando de escucha muestra la confirmación y los eventos posteriores.

```sh
node examples/mouse-feedback.mjs watch
```

```sh
node examples/mouse-feedback.mjs mouse.left
node examples/mouse-feedback.mjs mouse.right
node examples/mouse-feedback.mjs mouse.wheel
```

Para una interfaz gráfica, consulta [el suscriptor de la caja integrada](../examples/basic-box/overlay_mouse_client.cpp).
