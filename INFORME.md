# Informe — Laboratorio 5.2: CI/CD con Docker y GitHub Actions

## 1. Descripción del pipeline de CD y decisiones técnicas

El pipeline automatiza el ciclo completo desde el commit hasta el despliegue en producción. Está compuesto por tres jobs que se ejecutan en secuencia:

```
Commit → build-and-push → deploy-staging → deploy-production
```

### Jobs del pipeline

- **build-and-push:** Construye la imagen Docker con multi-stage build, la publica en Docker Hub con tres tags (`latest`, `v3.0.0` y el SHA del commit), y ejecuta un escaneo de vulnerabilidades con Trivy.
- **deploy-staging:** Se conecta por SSH a la instancia de staging (`34.229.141.13`), despliega la imagen en el puerto `3001`, valida el endpoint `/health` y solo si pasa el check promueve el contenedor.
- **deploy-production:** Solo se ejecuta si staging fue exitoso. Se conecta a la instancia de producción (`98.90.202.118`), valida en el puerto `8080` y despliega en el puerto `80`.

### Decisiones técnicas tomadas

- **Multi-stage build:** Se usan dos etapas en el Dockerfile — `builder` instala dependencias y `runtime` copia solo los artefactos necesarios. Esto reduce el tamaño de la imagen final y elimina herramientas innecesarias.
- **Etiquetado con SHA + versión semántica:** El SHA del commit (`v3.0.0`) permite identificar exactamente qué código está corriendo y hacer rollback preciso. La versión semántica facilita la identificación humana.
- **Health check antes de swap:** El nuevo contenedor se levanta en un puerto alterno, se valida con `curl /health`, y solo si responde HTTP 200 se reemplaza el contenedor activo. Si falla, la versión anterior sigue en producción sin interrupción.
- **GitHub Environments (staging y production):** Cada entorno tiene sus propios secrets (`SSH_HOST`, `SSH_USER`, `SSH_PRIVATE_KEY`) apuntando a instancias EC2 distintas. Staging actúa como validación previa antes de llegar a producción.
- **Trivy:** Escanea la imagen construida en busca de vulnerabilidades `CRITICAL` y `HIGH` en dependencias y sistema operativo base, antes de cualquier despliegue.

---

## 2. Capturas de pantalla del workflow en Actions

### Job: build-and-push
> [Insertar captura de pantalla del job completado con ✅]

### Job: deploy-staging
> [Insertar captura de pantalla del job completado con ✅]

### Job: deploy-production
> [Insertar captura de pantalla del job completado con ✅ mostrando los logs SSH]

---

## 3. Aplicación funcionando en las instancias remotas

### Staging
**URL:** `http://34.229.141.13:3001/health`

> [Insertar captura de pantalla mostrando la respuesta JSON]

### Production
**URL:** `http://98.90.202.118/health`

> [Insertar captura de pantalla mostrando la respuesta JSON]

---

## 4. Evidencia del escaneo de vulnerabilidades

El escaneo se ejecuta automáticamente en el job `build-and-push` usando `aquasecurity/trivy-action` con los siguientes parámetros:

- Tipos de vulnerabilidad: `os,library`
- Severidad reportada: `CRITICAL, HIGH`
- Vulnerabilidades sin parche disponible: ignoradas (`ignore-unfixed: true`)
- El pipeline no se detiene ante vulnerabilidades encontradas (`exit-code: '0'`)

> [Insertar captura de pantalla de la salida de Trivy en el step "Escaneo de vulnerabilidades con Trivy"]

---

## 5. Proceso de rollback a una versión anterior

Cada imagen se publica en Docker Hub con el SHA del commit, lo que permite revertir a cualquier versión anterior de forma precisa.

**Pasos para hacer rollback en producción:**

```bash
# 1. Identificar el SHA del commit al que revertir
git log --oneline
# Ejemplo de salida:
# c0987a6 feat: actualiza API a v3.0.0   ← versión actual (con bug)
# 6e7ab59 feat: restaura health check    ← versión estable anterior

# 2. Conectarse al servidor de producción
ssh -i lab5.2.pem ubuntu@98.90.202.118

# 3. Ejecutar el script de rollback
./rollback.sh 6e7ab59 gabriel132

# 4. Verificar que el rollback fue exitoso
curl http://localhost/health
```

El script `rollback.sh` descarga la imagen del SHA indicado desde Docker Hub, detiene el contenedor activo y levanta la versión anterior en el puerto 80.

---

## 6. Reflexión sobre contenedores y despliegue continuo

**Ventajas de los contenedores Docker:**
Los contenedores garantizan que la aplicación se comporta de forma idéntica en desarrollo, staging y producción, eliminando el clásico problema de "en mi máquina funciona". La imagen es inmutable: lo que se prueba en staging es exactamente lo que llega a producción. Además, permiten despliegues y rollbacks en segundos sin necesidad de reconfigurar el servidor.

**Ventajas del despliegue continuo:**
El CD elimina los despliegues manuales, que son lentos y propensos a errores humanos. Cada commit que supera las validaciones llega automáticamente a producción, acelerando la entrega de valor. El pipeline también actúa como red de seguridad: si algo falla en staging, producción no se toca.

**Mejoras para un proyecto real:**
En producción agregaría tests automatizados como job previo al build, notificaciones a Slack ante fallos, un balanceador de carga con múltiples réplicas para cero downtime, y rotación automática de secretos. También implementaría aprobación manual requerida antes del deploy a producción usando GitHub Environment protection rules.
