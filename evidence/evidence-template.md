# Lista de control opcional — UCAB Lab 3

> El formato del informe es libre. Esta plantilla sirve únicamente para comprobar que no falten datos, evidencias o respuestas. Cada captura debe acompañarse de una breve explicación.

**Nombre:**

**Cédula:**

**Sección:**

**Fecha:**

**Identificador generado por el script:**

## 0. Preparación de AWS

- [ ] Stack en `CREATE_COMPLETE`.
- [ ] Instancia EC2 con `3/3 checks passed`.
- [ ] `make doctor` finalizado con `Entorno listo`.
- [ ] Respuestas sobre estado de la instancia, diagnóstico e identificador único.

## 1. Pruebas e imagen

- Resultado resumido de `make test`:
- ID de `ucab-api:v1`:
- ¿Qué etapa del Dockerfile impide producir la imagen si fallan las pruebas?
- [ ] Captura de las cuatro pruebas aprobadas.
- [ ] Capturas de imagen, smoke test, usuario no privilegiado y contenedor en ejecución.

## 2. Contenedores Docker

| Contenedor | Puerto host | Hostname devuelto |
|---|---:|---|
| ucab-api | 8080 | |
| ucab-api-2 | 8081 | |
| ucab-api-3 | 8082 | |

Explique por qué `ucab-api-2` no reapareció después de eliminarlo:

- [ ] Captura de las tres instancias y sus hostnames.
- [ ] Captura posterior a la eliminación de `ucab-api-2`.

## 3. Kubernetes

- Réplicas iniciales disponibles:
- Réplicas después del escalado:
- Pod eliminado:
- Pod que lo reemplazó:
- Versión devuelta después del rolling update:

¿Qué objeto mantuvo el número de Pods deseado y qué objeto proporcionó un endpoint estable?

- [ ] Nodo K3s `Ready` e imagen importada.
- [ ] Tres Pods y Service funcionando.
- [ ] Escalado a cuatro réplicas.
- [ ] Pod eliminado y Pod sustituto.
- [ ] Historial del rollout y respuesta con `v2`.

## 4. Comparación razonada

Explique brevemente:

1. Imagen vs. contenedor.
2. Contenedor independiente vs. Pod administrado por un Deployment.
3. Ejecución imperativa vs. estado deseado.
4. Qué problema resuelve el ConfigMap.
5. Por qué un clúster K3s de un nodo no ofrece alta disponibilidad.

## 5. Limpieza

- Resultado de `stack-delete-complete`:
- Nombre exacto del stack eliminado:
- Confirmo que eliminé únicamente mi stack: [ ]
- [ ] Captura final de CloudShell y CloudFormation sin el stack.

## 6. Revisión antes de entregar

- [ ] El informe contiene nombre, cédula, sección, fecha e identificador del laboratorio.
- [ ] Cada evidencia explica qué comando se ejecutó, qué resultado importa y qué demuestra.
- [ ] Todas las preguntas de la guía están respondidas con razonamiento propio.
- [ ] Las capturas son legibles y no exponen credenciales ni tokens.
