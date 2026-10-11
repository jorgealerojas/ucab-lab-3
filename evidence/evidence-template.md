# Evidencia — UCAB Lab 3

**Nombre:**

**Cédula:**

**Fecha:**

**Identificador generado por el script:**

## 1. Pruebas e imagen

- Resultado resumido de `make test`:
- ID de `ucab-api:v1`:
- ¿Qué etapa del Dockerfile impide producir la imagen si fallan las pruebas?

## 2. Contenedores Docker

| Contenedor | Puerto host | Hostname devuelto |
|---|---:|---|
| ucab-api | 8080 | |
| ucab-api-2 | 8081 | |
| ucab-api-3 | 8082 | |

Explique por qué `ucab-api-2` no reapareció después de eliminarlo:

## 3. Kubernetes

- Réplicas iniciales disponibles:
- Réplicas después del escalado:
- Pod eliminado:
- Pod que lo reemplazó:
- Versión devuelta después del rolling update:

¿Qué objeto mantuvo el número de Pods deseado y qué objeto proporcionó un endpoint estable?

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
