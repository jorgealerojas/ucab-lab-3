# Guía del laboratorio

**Duración:** 1 h 45 min

**Región:** US East (Ohio), `us-east-2`

**Meta:** llevar una API probada desde Docker hasta Kubernetes y observar cuándo aparece el valor de la orquestación.

> No copie resultados ajenos. Ejecute los comandos, observe el estado y explique con sus propias palabras. Complete `evidence/evidence-template.md` mientras avanza.

## 0–15 min — Preparar el entorno

### 1. Abrir CloudShell en Ohio

En la consola AWS, seleccione **US East (Ohio), `us-east-2`**. Pulse el icono de terminal de la barra superior para abrir CloudShell. Verifique que la pestaña de CloudShell también diga `us-east-2`, como en la captura:

![Ubicación del icono de CloudShell y terminal abierta en la región Ohio](docs/images/01-abrir-cloudshell.png)

### 2. Crear el laboratorio

Pegue estos comandos en CloudShell:

```bash
curl -fsSL https://raw.githubusercontent.com/jorgealerojas/ucab-lab-3/main/scripts/deploy-lab.sh \
  -o /tmp/deploy-lab.sh
bash /tmp/deploy-lab.sh
```

Anote inmediatamente el valor mostrado después de `Identificador generado`. No lo cambie ni invente uno.

### 3. Observar CloudFormation

Sin interrumpir el comando, abra **CloudFormation → Stacks** en otra pestaña. Busque el nombre que coincide con su identificador. Durante la preparación debe mostrar `CREATE_IN_PROGRESS`:

![Stack del laboratorio visible en CloudFormation con estado CREATE_IN_PROGRESS](docs/images/02-cloudformation-creando-stack.png)

Pulse el nombre del stack. En **Stack details → Events** podrá observar cómo CloudFormation crea el rol, Security Group, Instance Profile, instancia y condición de espera. Actualice la lista con el botón circular de la esquina superior derecha:

![Vista detallada de los eventos de CloudFormation durante la creación del laboratorio](docs/images/03-eventos-detalle-stack.png)

Interprete los estados así:

- `CREATE_IN_PROGRESS`: el recurso continúa en preparación.
- `CREATE_COMPLETE`: el recurso terminó correctamente.
- `CREATE_FAILED`: abra el evento o pulse **View root cause** para leer la causa exacta.

No elimine recursos individuales desde **Events**. La creación y la limpieza deben realizarse siempre sobre el stack completo.

Espere a que CloudShell muestre `LABORATORIO LISTO` y a que el stack cambie a `CREATE_COMPLETE`. Puede tardar entre 3 y 8 minutos. No continúe si aparece `CREATE_FAILED` o `ROLLBACK_COMPLETE`; consulte [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

### 4. Entrar a la instancia

Si la cuenta es compartida, no abra, modifique ni elimine el stack de otro estudiante. En **EC2 → Instances**, seleccione la instancia cuyo nombre coincide exactamente con su identificador y abra **Connect → Session Manager**. En la terminal, cambie al usuario del laboratorio:

```bash
sudo -iu student
cd ~/ucab-lab-3
make doctor
```

El diagnóstico debe terminar con `Entorno listo`. La instancia EC2 es solo la plataforma del laboratorio; el trabajo evaluado comienza con Docker.

## 15–30 min — Conocer y probar la aplicación

Revise los archivos principales:

```bash
sed -n '1,220p' app/src/app.js
sed -n '1,240p' app/test/app.test.js
sed -n '1,220p' app/Dockerfile
```

Ejecute las pruebas en un contenedor temporal de Node.js:

```bash
make test
```

Preguntas para la evidencia:

1. ¿Por qué `/health` tiene una respuesta más pequeña que `/`?
2. ¿Qué evita que se construya la imagen si una prueba falla?
3. ¿Cuál es la diferencia entre `APP_VERSION` y `APP_MESSAGE` en este laboratorio?

## 30–45 min — Construir una imagen y ejecutar un contenedor

Construya la versión 1:

```bash
make image VERSION=v1
docker image ls ucab-api
docker history ucab-api:v1
```

Ejecute una instancia y espere su healthcheck:

```bash
make run VERSION=v1
make smoke
make inspect
docker ps
```

Observe especialmente:

- el tag de la imagen;
- el ID del contenedor;
- el UID/GID no privilegiado `1000:1000` del usuario `node`;
- `APP_VERSION` y `APP_MESSAGE`;
- el estado del healthcheck.

Una imagen es la plantilla inmutable. `docker run` crea una instancia ejecutable con su propia identidad y capa escribible.

## 45–57 min — Varias instancias y ausencia de reconciliación

Cree dos contenedores adicionales desde la misma imagen:

```bash
docker run -d --name ucab-api-2 -p 8081:3000 -e APP_MESSAGE="Réplica Docker 2" ucab-api:v1
docker run -d --name ucab-api-3 -p 8082:3000 -e APP_MESSAGE="Réplica Docker 3" ucab-api:v1
curl -s http://127.0.0.1:8081/ | jq .
curl -s http://127.0.0.1:8082/ | jq .
```

Compare los hostnames y luego elimine una instancia:

```bash
docker rm -f ucab-api-2
docker ps --filter ancestor=ucab-api:v1
```

Espere unos segundos y repita `docker ps`. Docker ejecutó exactamente lo solicitado, pero nadie declaró que debían existir siempre tres réplicas. Esa ausencia prepara el problema que resolverá Kubernetes.

Limpie los contenedores antes de iniciar K3s:

```bash
make stop
docker rm -f ucab-api-3
```

## 57–68 min — Iniciar Kubernetes y transferir la imagen

Inicie el clúster de un nodo:

```bash
make k8s-start
sudo k3s kubectl get nodes
```

Docker y K3s usan almacenes de imágenes distintos. Importe la imagen OCI construida con Docker al `containerd` de K3s:

```bash
make k8s-load VERSION=v1
sudo k3s ctr images list | grep ucab-api
```

Revise los manifiestos:

```bash
sed -n '1,240p' k8s/deployment.yaml
sed -n '1,160p' k8s/service.yaml
sed -n '1,120p' k8s/configmap.yaml
```

Ubique estas relaciones:

```text
Deployment → desea 3 Pods
Service    → selecciona Pods por label
ConfigMap  → aporta configuración sin reconstruir la imagen
```

## 68–82 min — Declarar y observar el estado deseado

Aplique los objetos:

```bash
make k8s-deploy
make k8s-status
make k8s-smoke
```

Repita solicitudes y observe los hostnames:

```bash
for i in {1..12}; do
  curl -s http://127.0.0.1:30080/ | jq -r '.hostname'
done
```

El `Service` conserva un endpoint mientras los Pods pueden cambiar.

## 82–92 min — Escalado y autocuración

Escala de tres a cuatro réplicas:

```bash
sudo k3s kubectl scale deployment/ucab-api --replicas=4
sudo k3s kubectl rollout status deployment/ucab-api
sudo k3s kubectl get pods -l app.kubernetes.io/name=ucab-api
```

Elimine un Pod y observe en tiempo real:

```bash
POD=$(sudo k3s kubectl get pods -l app.kubernetes.io/name=ucab-api -o jsonpath='{.items[0].metadata.name}')
sudo k3s kubectl delete pod "$POD"
sudo k3s kubectl get pods -l app.kubernetes.io/name=ucab-api -w
```

Detenga la observación con `Ctrl+C` cuando aparezca el reemplazo. El nombre del nuevo Pod debe ser distinto: el controlador reconcilió el estado real con las cuatro réplicas declaradas.

Restaure tres réplicas:

```bash
sudo k3s kubectl scale deployment/ucab-api --replicas=3
```

## 92–99 min — Rolling update

Construya e importe una imagen con otra versión:

```bash
make image VERSION=v2
make k8s-load VERSION=v2
```

Solicite la actualización y obsérvela:

```bash
sudo k3s kubectl set image deployment/ucab-api api=ucab-api:v2
sudo k3s kubectl rollout status deployment/ucab-api
sudo k3s kubectl rollout history deployment/ucab-api
curl -s http://127.0.0.1:30080/ | jq .
```

La estrategia permite un Pod adicional y no permite ninguno no disponible (`maxSurge: 1`, `maxUnavailable: 0`). Kubernetes incorpora `v2` gradualmente.

## 99–102 min — Síntesis

Complete en la evidencia:

- imagen vs. contenedor;
- contenedor individual vs. Pod administrado;
- ejecución imperativa vs. estado deseado;
- qué aportaron Deployment, Service y ConfigMap;
- por qué este clúster de un nodo no representa alta disponibilidad.

Opcionalmente valide el estado final:

```bash
make verify
```

## 102–105 min — Limpieza obligatoria

Dentro de la instancia:

```bash
make clean
exit
exit
```

Desde CloudShell:

```bash
STACK_NAME="ucab-lab-3-a1b2c3d4e5f60708" # Copie aquí el valor que generó el script
aws cloudformation delete-stack --stack-name "$STACK_NAME" --region us-east-2
aws cloudformation wait stack-delete-complete --stack-name "$STACK_NAME" --region us-east-2
```

Compruebe que el comando termina sin error. No basta con detener la instancia: hay que eliminar el stack.
