# Evidencia — UCAB Lab 3

> Lista de control opcional. El formato del informe es libre; conserve las preguntas originales y acompañe cada paso con una captura explicada.

**Nombre:**

**Cédula:**

**Sección:**

**Fecha:**

**Identificador generado por el script:**

## 1. Pruebas e imagen

- Resultado resumido de `make test`:
- ID de `ucab-api:v1`:

## 2. Contenedores Docker

| Contenedor | Puerto host | Hostname devuelto |
|---|---:|---|
| ucab-api | 8080 | |
| ucab-api-2 | 8081 | |
| ucab-api-3 | 8082 | |

## 3. Kubernetes

- Réplicas iniciales disponibles:
- Réplicas después del escalado:
- Pod eliminado:
- Pod que lo reemplazó:
- Versión devuelta después del rolling update:

## 4. Preguntas para el informe

Responda con sus propias palabras y relacione cada respuesta con las capturas obtenidas durante la práctica.

1. ¿Cuál es la diferencia entre la imagen `ucab-api:v1` y los contenedores creados a partir de ella? Utilice sus evidencias para explicar qué elementos comparten y cuáles son propios de cada contenedor.
2. ¿Por qué Docker no volvió a crear `ucab-api-2` después de eliminarlo, mientras que Kubernetes sí creó un Pod de reemplazo? Relacione su respuesta con el estado deseado y la reconciliación.
3. ¿Qué función cumplen el Deployment, el Service y el ConfigMap en esta práctica, y cómo se relacionan para ejecutar y exponer la aplicación?
4. ¿Por qué fue necesario importar la imagen desde Docker al almacén de imágenes de K3s (`containerd`) antes de desplegarla en Kubernetes?
5. ¿Qué ocurrió con la aplicación durante el escalado y el rolling update? Explique el efecto de las réplicas, `maxSurge` y `maxUnavailable`, y por qué este clúster de un solo nodo no ofrece alta disponibilidad.

## 5. Limpieza

- Resultado de `stack-delete-complete`:
- Nombre exacto del stack eliminado:
- Confirmo que eliminé únicamente mi stack: [ ]
