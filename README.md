# UCAB Lab 3: Docker y Kubernetes

Laboratorio de 1 hora y 45 minutos para la Unidad III de **Computación en la Nube (INFO-02028)**. El recorrido lleva una API desde sus pruebas unitarias hasta Docker y luego a un clúster Kubernetes ligero con K3s.

## Objetivos

Al finalizar, el estudiante podrá:

- diferenciar imagen y contenedor mediante observación directa;
- construir y ejecutar una imagen reproducible con Docker;
- explicar qué problema añade y resuelve un orquestador;
- desplegar `Deployment`, `Service` y `ConfigMap`;
- experimentar con réplicas, autocuración y rolling updates;
- eliminar todos los recursos creados en AWS.

## Requisitos

- Cuenta AWS en el plan gratuito con créditos disponibles.
- Región **US East (Ohio), `us-east-2`**.
- Permisos para CloudFormation, EC2, IAM y Systems Manager.
- Default VPC presente en `us-east-2`.

La plantilla usa `c7i-flex.large` por defecto: 2 vCPU y 4 GiB, elegible para el plan gratuito de cuentas nuevas. Como contingencia admite `t3.small`, aunque sus 2 GiB dejan menos margen.

## Identificador único automático

El estudiante no elige ni escribe un `LabId`. El script genera un nombre como `ucab-lab-3-a1b2c3d4e5f60708`, comprueba que no exista en CloudFormation y lo usa como identificador del stack y de la instancia. La creación del stack es atómica: nunca actualiza un laboratorio existente por accidente.

Anote el valor generado en la evidencia. Es la referencia que debe usar para conectarse, diagnosticar y eliminar exclusivamente su laboratorio.

## Despliegue rápido desde AWS CloudShell

Seleccione **US East (Ohio), `us-east-2`** en la consola. Abra CloudShell con el icono de terminal de la barra superior; aparecerá un panel en la parte inferior. Confirme que la pestaña del panel también muestre `us-east-2`.

![Consola AWS con el icono de CloudShell y la terminal abierta en us-east-2](docs/images/01-abrir-cloudshell.png)

En CloudShell, ejecute:

```bash
curl -fsSL https://raw.githubusercontent.com/jorgealerojas/ucab-lab-3/main/scripts/deploy-lab.sh \
  -o /tmp/deploy-lab.sh
bash /tmp/deploy-lab.sh
```

El script muestra `Identificador generado`; cópielo en la evidencia. Mientras espera, abra **CloudFormation → Stacks** en otra pestaña. Debe aparecer un stack con ese mismo identificador y estado `CREATE_IN_PROGRESS`.

![Lista de stacks de CloudFormation con el laboratorio en CREATE_IN_PROGRESS](docs/images/02-cloudformation-creando-stack.png)

Pulse el nombre del stack para abrir **Stack details → Events**. Use el botón de actualizar para seguir cada recurso. `CREATE_IN_PROGRESS` indica que continúa trabajando y `CREATE_COMPLETE` que el recurso terminó correctamente.

![Detalle de CloudFormation mostrando los eventos y estados de los recursos del stack](docs/images/03-eventos-detalle-stack.png)

Si aparece `CREATE_FAILED`, seleccione el evento fallido o **View root cause** y consulte [TROUBLESHOOTING.md](TROUBLESHOOTING.md). No modifique ni elimine recursos individuales desde esta vista.

La creación puede tardar entre 3 y 8 minutos. No cierre CloudShell. CloudFormation no indicará `CREATE_COMPLETE` hasta que Docker y K3s hayan sido instalados y comprobados. Entonces abra **EC2 → Instances**, seleccione la instancia cuyo nombre coincide con el identificador generado y use **Connect → Session Manager**. En la terminal:

```bash
sudo -iu student
cd ~/ucab-lab-3
make doctor
```

Continúe con [LAB_GUIDE.md](LAB_GUIDE.md).

## Limpieza obligatoria

Al terminar, cierre la sesión y elimine el stack desde CloudShell:

```bash
STACK_NAME="ucab-lab-3-a1b2c3d4e5f60708" # Copie el valor generado; no invente otro
aws cloudformation delete-stack --stack-name "$STACK_NAME" --region us-east-2
aws cloudformation wait stack-delete-complete --stack-name "$STACK_NAME" --region us-east-2
```

El stack elimina la instancia, el volumen EBS, el Security Group y el rol creados para el laboratorio.

## Uso de una cuenta compartida

El laboratorio admite varios stacks simultáneos en una misma cuenta. Cada ejecución genera 64 bits aleatorios, verifica el nombre contra CloudFormation y crea el stack de forma atómica. CloudFormation genera nombres físicos distintos para los demás recursos. Docker y Kubernetes se ejecutan dentro de instancias separadas, por lo que sus contenedores, puertos, imágenes y Pods tampoco colisionan.

Antes de la clase, el docente debe validar la cuota para el número de participantes simultáneos:

```bash
curl -fsSL https://raw.githubusercontent.com/jorgealerojas/ucab-lab-3/main/scripts/check-shared-account.sh \
  -o /tmp/check-shared-account.sh
bash /tmp/check-shared-account.sh 10 # Reemplace 10 por el máximo simultáneo
```

Cada laboratorio consume 2 vCPU. Los créditos y cuotas son compartidos por toda la cuenta. Los nombres únicos evitan colisiones, pero no aumentan esos límites y tampoco aíslan permisos si todos usan las mismas credenciales. Cuando sea posible, use identidades IAM diferentes; si comparten una sola identidad, cada alumno debe operar exclusivamente el identificador que generó su ejecución.

## Desarrollo y validación

```bash
make test
make image VERSION=v1
make run VERSION=v1
make smoke
```

Las pruebas unitarias también se ejecutan durante cada `docker build`; una imagen no se produce si fallan.

## Estructura

```text
app/        API Node.js, pruebas y Dockerfile
docs/       capturas utilizadas en la guía del estudiante
evidence/   plantilla de entrega
infra/      CloudFormation para AWS
k8s/       objetos Kubernetes
scripts/    bootstrap, diagnóstico y verificaciones
```

Consulte [TROUBLESHOOTING.md](TROUBLESHOOTING.md) si el stack, Docker o K3s no quedan listos.
