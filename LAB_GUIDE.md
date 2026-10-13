# Guía del laboratorio

**Duración:** 1 h 45 min

**Región:** US East (Ohio), `us-east-2`

**Meta:** llevar una API probada desde Docker hasta Kubernetes y observar cuándo aparece el valor de la orquestación.

> Ejecute los comandos uno por uno y lea qué hace cada uno antes de copiarlo. Observe el resultado indicado y deténgase si obtiene un error. **Cada paso de la práctica debe quedar respaldado por una captura legible del comando y su resultado.** No espere al final para reunir las evidencias.

## Evidencias durante la práctica

En cada sección tome capturas donde se distingan el comando ejecutado y la salida relevante. Acompañe cada captura con una breve explicación de qué hizo, qué resultado obtuvo y qué demuestra. No incluya credenciales, tokens ni información sensible. Puede usar `evidence/evidence-template.md` como lista de control.

## 0–15 min — Preparar el entorno

### 1. Abrir CloudShell en Ohio

En la consola AWS, seleccione **US East (Ohio), `us-east-2`**. Pulse el icono de terminal de la barra superior para abrir CloudShell. Verifique que la pestaña de CloudShell también diga `us-east-2`, como en la captura:

![Ubicación del icono de CloudShell y terminal abierta en la región Ohio](docs/images/01-abrir-cloudshell.png)

### 2. Crear el laboratorio

Primero descargue el script de despliegue desde el repositorio. `curl` guarda el archivo en `/tmp/deploy-lab.sh`; si funciona, no muestra salida.

```bash
curl -fsSL https://raw.githubusercontent.com/jorgealerojas/ucab-lab-3/main/scripts/deploy-lab.sh -o /tmp/deploy-lab.sh
```

Ahora ejecute el script descargado. Este genera un identificador único y pide a CloudFormation que cree la infraestructura y prepare Docker y K3s.

```bash
bash /tmp/deploy-lab.sh
```

Debe aparecer `Identificador generado: ucab-lab-3-...` y luego `Creando el laboratorio`. Anote inmediatamente el identificador en su evidencia; no lo cambie ni invente uno. El comando permanecerá activo mientras CloudFormation trabaja.

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

Si la cuenta es compartida, no abra, modifique ni elimine el stack de otro estudiante. En **EC2 → Instances**, seleccione la instancia cuyo nombre coincide exactamente con su identificador.

Aunque **Instance state** muestre `Running`, espere si **Status check** todavía dice `Initializing`. AWS aún está comprobando la instancia y sus recursos asociados:

![Instancia EC2 en ejecución con sus status checks todavía inicializando](docs/images/04-ec2-status-checks-inicializando.png)

Actualice la lista hasta que **Status check** muestre en verde `3/3 checks passed`. Tome una captura como evidencia y solo entonces abra **Connect → Session Manager**:

![Instancia EC2 con los tres status checks aprobados](docs/images/05-ec2-status-checks-aprobados.png)

Cambie del usuario de Session Manager al usuario preparado para el laboratorio. El prompt debe pasar a mostrar `student`.

```bash
sudo -iu student
```

Entre al repositorio clonado durante el bootstrap. Este comando normalmente no produce salida; solo cambia el directorio actual.

```bash
cd ~/ucab-lab-3
```

Compruebe Docker, K3s, herramientas, región e identificador. Cada comprobación debe indicar `OK` y el resumen debe terminar con `Entorno listo`.

```bash
make doctor
```

La instancia EC2 es solo la plataforma del laboratorio; el trabajo evaluado comienza con Docker.

## 15–30 min — Conocer y probar la aplicación

Muestre el código de la API. Busque las rutas `/` y `/health`, las variables de entorno y la respuesta JSON.

```bash
sed -n '1,220p' app/src/app.js
```

Muestre las pruebas automatizadas. Debe identificar cuatro casos: ruta principal, salud, ruta inexistente y método no permitido.

```bash
sed -n '1,240p' app/test/app.test.js
```

Muestre el Dockerfile. Observe las etapas `test` y `runtime`, el usuario no privilegiado y el `HEALTHCHECK`.

```bash
sed -n '1,220p' app/Dockerfile
```

Ejecute las pruebas dentro de un contenedor temporal de Node.js 22. Esto valida la aplicación sin instalar Node.js directamente en la instancia.

```bash
make test
```

El resumen esperado contiene `tests 4`, `pass 4` y `fail 0`. Si alguna prueba falla, no continúe con la construcción de la imagen.

## 30–45 min — Construir una imagen y ejecutar un contenedor

Construya la versión `v1`. Docker ejecutará también las pruebas de la etapa `test` antes de producir la imagen final.

```bash
make image VERSION=v1
```

Debe terminar sin errores y mostrar una imagen etiquetada como `ucab-api:v1`.

Liste las imágenes de la aplicación para comprobar el repositorio, tag, identificador y tamaño.

```bash
docker image ls ucab-api
```

Inspeccione las capas que componen la imagen. La salida permite relacionar instrucciones del Dockerfile con capas reproducibles.

```bash
docker history ucab-api:v1
```

Inicie un contenedor llamado `ucab-api`, publique el puerto `8080` y configure el mensaje de la aplicación.

```bash
make run VERSION=v1
```

Docker debe devolver un identificador largo: es el ID del contenedor recién creado.

Realice una prueba HTTP contra el contenedor. El comando espera a que `/health` responda y luego muestra el JSON de `/`.

```bash
make smoke
```

La respuesta debe incluir `service`, `"version": "v1"`, `message` y `hostname`.

Inspeccione la configuración y el estado interno del contenedor.

```bash
make inspect
```

Busque el usuario `1000:1000`, las variables `APP_VERSION` y `APP_MESSAGE`, y la definición del healthcheck.

Liste los contenedores en ejecución para confirmar nombre, imagen, puertos y estado.

```bash
docker ps
```

Debe aparecer `ucab-api`, la imagen `ucab-api:v1` y el mapeo `8080->3000`.

Una imagen es la plantilla inmutable. `docker run` crea una instancia ejecutable con su propia identidad y capa escribible.

## 45–57 min — Varias instancias y ausencia de reconciliación

Cree una segunda instancia de la misma imagen. Se llama `ucab-api-2`, escucha en el puerto `8081` y recibe un mensaje diferente.

```bash
docker run -d --name ucab-api-2 -p 8081:3000 -e APP_MESSAGE="Réplica Docker 2" ucab-api:v1
```

Docker debe devolver un nuevo ID de contenedor.

Cree una tercera instancia en el puerto `8082`.

```bash
docker run -d --name ucab-api-3 -p 8082:3000 -e APP_MESSAGE="Réplica Docker 3" ucab-api:v1
```

Docker debe devolver otro ID distinto.

Consulte la segunda instancia y formatee su JSON con `jq`.

```bash
curl -s http://127.0.0.1:8081/ | jq .
```

Debe mostrar el mensaje `Réplica Docker 2`. Anote su `hostname`.

Consulte la tercera instancia.

```bash
curl -s http://127.0.0.1:8082/ | jq .
```

Debe mostrar `Réplica Docker 3` y otro `hostname`. Los hostnames diferentes demuestran que son instancias independientes de la misma imagen.

Elimine deliberadamente la segunda instancia.

```bash
docker rm -f ucab-api-2
```

Docker debe imprimir `ucab-api-2`, confirmando su eliminación.

Liste los contenedores creados desde `ucab-api:v1`.

```bash
docker ps --filter ancestor=ucab-api:v1
```

`ucab-api-2` ya no debe aparecer. Espere unos segundos y ejecute exactamente el mismo comando otra vez: seguirá ausente. Docker ejecutó lo solicitado, pero nadie declaró que debían existir siempre tres réplicas. Esa ausencia prepara el problema que resolverá Kubernetes.

Elimine el contenedor principal mediante el objetivo de limpieza del Makefile.

```bash
make stop
```

Elimine también la tercera réplica para liberar puertos y memoria antes de iniciar K3s.

```bash
docker rm -f ucab-api-3
```

Debe imprimir `ucab-api-3`.

## 57–68 min — Iniciar Kubernetes y transferir la imagen

Inicie K3s y espere que su único nodo alcance la condición `Ready`.

```bash
make k8s-start
```

La salida esperada termina con `condition met`.

Consulte el nodo para ver su estado y versión de Kubernetes.

```bash
sudo k3s kubectl get nodes
```

Debe aparecer un nodo con `STATUS` igual a `Ready`.

Docker y K3s usan almacenes de imágenes distintos. Exporte `ucab-api:v1` desde Docker e impórtela en el `containerd` administrado por K3s.

```bash
make k8s-load VERSION=v1
```

El comando muestra información de importación y debe terminar sin errores.

Confirme que el almacén de K3s contiene la imagen.

```bash
sudo k3s ctr images list | grep ucab-api
```

Debe aparecer una referencia a `ucab-api:v1`.

Revise el Deployment. Busque `replicas: 3`, labels, probes, estrategia de actualización e imagen.

```bash
sed -n '1,240p' k8s/deployment.yaml
```

Revise el Service. Observe el selector y el puerto estable `30080`.

```bash
sed -n '1,160p' k8s/service.yaml
```

Revise el ConfigMap. Observe cómo el mensaje se separa de la imagen.

```bash
sed -n '1,120p' k8s/configmap.yaml
```

Relaciones que debe identificar:

```text
Deployment → desea 3 Pods
Service    → selecciona Pods por label
ConfigMap  → aporta configuración sin reconstruir la imagen
```

## 68–82 min — Declarar y observar el estado deseado

Aplique todos los manifiestos y espere a que el Deployment termine.

```bash
make k8s-deploy
```

Debe ver `created` o `configured` para ConfigMap, Deployment y Service, seguido de `successfully rolled out`.

Muestre el estado del nodo, Deployment, Pods y Service.

```bash
make k8s-status
```

Compruebe que el Deployment indique `3/3` y que existan tres Pods `Running`.

Pruebe el NodePort desde la instancia.

```bash
make k8s-smoke
```

Debe recibir un JSON con `"version": "v1"` y el mensaje configurado por Kubernetes.

Envíe doce solicitudes al mismo endpoint y muestre únicamente el hostname de cada respuesta.

```bash
for i in {1..12}; do curl -s http://127.0.0.1:30080/ | jq -r '.hostname'; done
```

Debe observar más de un hostname. El `Service` conserva un endpoint mientras distribuye solicitudes entre Pods que pueden cambiar.

## 82–92 min — Escalado y autocuración

Cambie el estado deseado de tres a cuatro réplicas.

```bash
sudo k3s kubectl scale deployment/ucab-api --replicas=4
```

La salida debe indicar `deployment.apps/ucab-api scaled`.

Espere a que Kubernetes complete el escalado.

```bash
sudo k3s kubectl rollout status deployment/ucab-api
```

Debe terminar con `successfully rolled out`.

Liste los Pods para comprobar que ahora hay cuatro en estado `Running`.

```bash
sudo k3s kubectl get pods -l app.kubernetes.io/name=ucab-api
```

Seleccione automáticamente el nombre del primer Pod y guárdelo en la variable `POD`. Este comando no muestra salida.

```bash
POD=$(sudo k3s kubectl get pods -l app.kubernetes.io/name=ucab-api -o jsonpath='{.items[0].metadata.name}')
```

Compruebe qué nombre se guardó antes de eliminarlo.

```bash
echo "$POD"
```

Debe imprimir un nombre que comienza por `ucab-api-`.

Elimine ese Pod deliberadamente. El Deployment seguirá declarando cuatro réplicas.

```bash
sudo k3s kubectl delete pod "$POD"
```

Debe aparecer `pod/... deleted`.

Observe los Pods en tiempo real.

```bash
sudo k3s kubectl get pods -l app.kubernetes.io/name=ucab-api -w
```

Detenga la observación con `Ctrl+C` cuando aparezca un reemplazo `Running`. El nombre nuevo debe ser distinto: el controlador reconcilió el estado real con las cuatro réplicas declaradas.

Restaure el estado deseado original de tres réplicas.

```bash
sudo k3s kubectl scale deployment/ucab-api --replicas=3
```

La salida debe indicar nuevamente `scaled`.

## 92–99 min — Rolling update

Construya una nueva imagen etiquetada `v2`. El cambio de versión se inyecta durante el build.

```bash
make image VERSION=v2
```

Las cuatro pruebas deben pasar y Docker debe producir `ucab-api:v2`.

Importe `v2` al almacén de imágenes de K3s.

```bash
make k8s-load VERSION=v2
```

Debe terminar sin errores.

Cambie la imagen deseada del contenedor `api` dentro del Deployment.

```bash
sudo k3s kubectl set image deployment/ucab-api api=ucab-api:v2
```

La salida debe indicar `deployment.apps/ucab-api image updated`.

Observe el avance de la sustitución gradual.

```bash
sudo k3s kubectl rollout status deployment/ucab-api
```

Kubernetes crea Pods `v2` y retira los `v1` sin dejar el servicio sin réplicas disponibles. El comando termina con `successfully rolled out`.

Consulte el historial de revisiones del Deployment.

```bash
sudo k3s kubectl rollout history deployment/ucab-api
```

Debe mostrar al menos dos revisiones.

Compruebe la versión entregada por el Service.

```bash
curl -s http://127.0.0.1:30080/ | jq .
```

La respuesta debe contener `"version": "v2"`. La estrategia permite un Pod adicional y no permite ninguno no disponible (`maxSurge: 1`, `maxUnavailable: 0`).

## 99–102 min — Preguntas para el informe

Responda las siguientes preguntas con sus propias palabras. Apoye cada respuesta con las evidencias que obtuvo durante la práctica e identifique claramente las capturas relacionadas.

1. ¿Cuál es la diferencia entre la imagen `ucab-api:v1` y los contenedores creados a partir de ella? Utilice sus evidencias para explicar qué elementos comparten y cuáles son propios de cada contenedor.
2. ¿Por qué Docker no volvió a crear `ucab-api-2` después de eliminarlo, mientras que Kubernetes sí creó un Pod de reemplazo? Relacione su respuesta con el estado deseado y la reconciliación.
3. ¿Qué función cumplen el Deployment, el Service y el ConfigMap en esta práctica, y cómo se relacionan para ejecutar y exponer la aplicación?
4. ¿Por qué fue necesario importar la imagen desde Docker al almacén de imágenes de K3s (`containerd`) antes de desplegarla en Kubernetes?
5. ¿Qué ocurrió con la aplicación durante el escalado y el rolling update? Explique el efecto de las réplicas, `maxSurge` y `maxUnavailable`, y por qué este clúster de un solo nodo no ofrece alta disponibilidad.

### Verificación final opcional

Opcionalmente ejecute la verificación funcional automatizada. Esta comprueba réplicas, Service y versión desplegada.

```bash
make verify
```

El resultado esperado termina sin errores e informa que la verificación fue satisfactoria.

## 102–105 min — Limpieza obligatoria

Dentro de la instancia, elimine los contenedores Docker y objetos Kubernetes creados por el ejercicio.

```bash
make clean
```

El comando puede mostrar objetos `deleted`; también es correcto que indique que alguno ya no existe.

Salga del usuario `student` y vuelva a la sesión administrada por AWS.

```bash
exit
```

Cierre la sesión de Session Manager.

```bash
exit
```

Regrese a CloudShell. Guarde en una variable el identificador exacto generado al principio. Sustituya únicamente el valor de ejemplo.

```bash
STACK_NAME="ucab-lab-3-a1b2c3d4e5f60708"
```

Compruebe visualmente el valor antes de borrar nada, especialmente si la cuenta es compartida.

```bash
echo "$STACK_NAME"
```

Solicite a CloudFormation la eliminación del stack completo. El comando normalmente no muestra salida.

```bash
aws cloudformation delete-stack --stack-name "$STACK_NAME" --region us-east-2
```

Espere hasta que AWS confirme la eliminación. Mientras espera, el comando no muestra progreso; al terminar correctamente vuelve al prompt sin salida.

```bash
aws cloudformation wait stack-delete-complete --stack-name "$STACK_NAME" --region us-east-2
```

Compruebe en **CloudFormation → Stacks** que el stack desapareció. No basta con detener la instancia: hay que eliminar el stack para retirar también volumen, Security Group, rol e Instance Profile.

## Informe a entregar

El formato del informe es **libre**. Puede organizarlo como documento, presentación o PDF; lo importante es que:

- incluya nombre, cédula, sección, fecha e identificador del laboratorio;
- muestre evidencia detallada de cada paso de la práctica;
- explique brevemente qué demuestra cada captura;
- responda las preguntas originales incluidas en esta guía;
- incluya evidencia de la limpieza final del stack.

`evidence/evidence-template.md` es una ayuda opcional para revisar que no falte información; no es un formato obligatorio.
