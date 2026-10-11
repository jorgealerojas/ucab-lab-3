# Solución de problemas

Use siempre **US East (Ohio), `us-east-2`**. En una cuenta compartida, confirme el identificador exacto antes de ejecutar cualquier comando que modifique o elimine recursos.

## No anoté el identificador generado

El script guarda un comprobante en CloudShell. Liste únicamente esos comprobantes con:

```bash
ls -1 "$HOME/.ucab-lab-3"
```

También puede buscar las instancias por la etiqueta `Course`:

```bash
aws ec2 describe-instances \
  --filters Name=tag:Course,Values=INFO-02028 Name=instance-state-name,Values=pending,running,stopping,stopped \
  --query 'Reservations[].Instances[].[Tags[?Key==`Name`]|[0].Value,InstanceId,State.Name]' \
  --output table --region us-east-2
```

Si aparecen varios laboratorios, no adivine cuál es suyo: compare la hora de creación en CloudFormation o consulte al docente.

## El script rechaza la región o las credenciales

Confirme la región y la identidad activa:

```bash
export AWS_REGION=us-east-2
aws sts get-caller-identity
```

Errores `AccessDenied` indican que la identidad necesita permisos para CloudFormation, EC2, IAM, Systems Manager y los parámetros públicos de SSM. No intente eludirlos con credenciales de otra persona; solicite al docente la identidad correcta.

## El stack falla inmediatamente

Revise los últimos eventos usando el identificador que imprimió el script:

```bash
STACK_NAME="ucab-lab-3-a1b2c3d4e5f60708" # Copie el valor real
aws cloudformation describe-stack-events \
  --stack-name "$STACK_NAME" --region us-east-2 \
  --query 'StackEvents[0:12].[Timestamp,LogicalResourceId,ResourceStatus,ResourceStatusReason]' \
  --output table
```

Errores frecuentes:

| Mensaje o estado | Causa probable | Acción |
|---|---|---|
| `VcpuLimitExceeded` | La cuenta no tiene 2 vCPU libres por laboratorio | El docente aumenta la cuota o divide el grupo en turnos |
| `InsufficientInstanceCapacity` | AWS no tiene capacidad temporal del tipo elegido | Espere y reintente; como contingencia use `t3.small` |
| `Default VPC` / `No default VPC` | La Default VPC no existe en Ohio | Restaure la Default VPC antes de la clase |
| `AccessDenied` | Faltan permisos en la identidad activa | Corrija IAM; cambiar el nombre no lo resuelve |
| `AlreadyExistsException` | Colisión extremadamente improbable o ejecución duplicada | No actualice ese stack; vuelva a ejecutar el script para generar otro identificador |
| `ROLLBACK_COMPLETE` | Algún recurso falló y CloudFormation revirtió la creación | Revise Events y elimine ese stack antes de reintentar |

Para usar la contingencia de 2 GiB:

```bash
INSTANCE_TYPE=t3.small bash /tmp/deploy-lab.sh
```

Con `t3.small`, detenga todos los contenedores Docker antes de iniciar K3s. El nuevo intento genera otro identificador; elimine también cualquier stack fallido anterior.

## Session Manager no está disponible

La instancia puede tardar unos minutos en arrancar y registrar SSM Agent. Espere dos minutos, actualice **EC2 → Connect** y confirme que seleccionó la instancia cuyo nombre es su identificador.

Si continúa inactiva, revise **EC2 → Status checks**. El Security Group no tiene entrada SSH por diseño; no agregue el puerto 22.

## `make doctor` dice que el bootstrap no terminó

Observe el proceso y los logs:

```bash
sudo cloud-init status --wait
sudo tail -n 100 /var/log/ucab-lab-user-data.log
sudo tail -n 100 /var/log/ucab-lab-bootstrap.log
```

No continúe hasta que exista `/var/lib/ucab-lab/ready`. Si CloudFormation todavía está en `CREATE_IN_PROGRESS`, espere: la plantilla no termina hasta recibir la señal del bootstrap.

## Docker responde `permission denied`

Compruebe que usa el usuario correcto:

```bash
whoami
groups
```

Debe ser `student` y pertenecer a `docker`. Ejecute `exit` si corresponde y vuelva a entrar con `sudo -iu student` para renovar los grupos.

## Un contenedor no inicia o el puerto 8080 está ocupado

Revise los contenedores y limpie únicamente los del ejercicio:

```bash
docker ps -a
make stop
docker rm -f ucab-api-2 ucab-api-3 2>/dev/null || true
```

Después repita `make run VERSION=v1`. No elimine contenedores en una instancia distinta.

## K3s no inicia o el nodo no queda `Ready`

```bash
sudo systemctl status k3s --no-pager
sudo journalctl -u k3s -n 100 --no-pager
sudo k3s kubectl get nodes -o wide
```

En `t3.small`, libere memoria con `make stop` antes de `make k8s-start`. Espere hasta dos minutos; si persiste, conserve los logs y avise al docente.

Si CloudFormation muestra `WaitCondition received failed message`, consulte el evento `CREATE_FAILED` y recupere la salida de consola antes de borrar el stack. El bootstrap espera explícitamente que el objeto `Node` exista antes de consultar su condición `Ready`, evitando el error transitorio `no matching resources found`.

## Un Pod queda en `ImagePullBackOff`

Docker y K3s usan almacenes de imágenes distintos. Confirme la importación y el tag:

```bash
make k8s-load VERSION=v1
sudo k3s ctr images list | grep ucab-api
grep 'image:' k8s/deployment.yaml
sudo k3s kubectl describe pods -l app.kubernetes.io/name=ucab-api
```

## Un Pod queda en `CrashLoopBackOff`

```bash
sudo k3s kubectl logs deployment/ucab-api --all-pods=true
sudo k3s kubectl describe pods -l app.kubernetes.io/name=ucab-api
```

Busque errores de inicio y fallos de probes. No edite el manifiesto a ciegas: compare primero el código y las rutas `/` y `/health`.

## El Service no responde

Revise por capas:

```bash
sudo k3s kubectl get pods -o wide
sudo k3s kubectl describe deployment ucab-api
sudo k3s kubectl get endpoints ucab-api
sudo k3s kubectl logs deployment/ucab-api --all-pods=true
sudo k3s kubectl get service ucab-api
```

Los Pods deben estar `Ready`, `Endpoints` debe contener direcciones y el NodePort debe ser `30080`. Después pruebe desde la propia instancia:

```bash
curl -v http://127.0.0.1:30080/health
```

## El rolling update sigue mostrando `v1`

Construya e importe `v2` antes de cambiar el Deployment:

```bash
make image VERSION=v2
make k8s-load VERSION=v2
sudo k3s kubectl set image deployment/ucab-api api=ucab-api:v2
sudo k3s kubectl rollout status deployment/ucab-api
sudo k3s kubectl get pods -o jsonpath='{range .items[*]}{.spec.containers[0].image}{"\n"}{end}'
```

Si el rollout se bloquea, use `kubectl describe deployment ucab-api` y `kubectl rollout undo deployment/ucab-api`.

## La eliminación del stack falla

Copie el identificador, no escriba uno parecido:

```bash
STACK_NAME="ucab-lab-3-a1b2c3d4e5f60708" # Copie el valor real
aws cloudformation delete-stack --stack-name "$STACK_NAME" --region us-east-2
aws cloudformation wait stack-delete-complete --stack-name "$STACK_NAME" --region us-east-2
```

No elimine manualmente el Security Group, rol o Instance Profile. Si falla, revise **CloudFormation → Events**, corrija el recurso señalado y repita. Que `describe-stacks` devuelva `does not exist` después del borrado es el resultado esperado.

## Hay varios alumnos en la misma cuenta

- Cada ejecución crea su propio identificador; nadie debe reutilizar uno visible en la pantalla de otra persona.
- La instancia y la etiqueta `LabId` deben coincidir exactamente con el nombre del stack.
- Antes de actualizar o borrar, lea el identificador completo y compárelo con su evidencia.
- Los nombres no resuelven límites compartidos: créditos, vCPU y permisos siguen siendo comunes.
- Si todos usan las mismas credenciales, no existe aislamiento de seguridad. Evite operaciones masivas y filtros amplios.

La cuota requerida es **Running On-Demand Standard instances** (`L-1216C47A`) y se mide en vCPU. Cada stack necesita 2 vCPU.
