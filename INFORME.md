# Informe — Laboratorio 5.2: CI/CD con Docker y GitHub Actions

## 1. Descripción del pipeline

El pipeline automatiza el ciclo completo desde el commit hasta el despliegue en producción. Está compuesto por tres jobs que se ejecutan en secuencia:

```
Commit → build-and-push → deploy-staging → deploy-production
```

- **build-and-push:** Construye la imagen Docker con multi-stage build, la publica en Docker Hub con tres tags (`latest`, `v1.0.0` y el SHA del commit), y ejecuta un escaneo de vulnerabilidades con Trivy.
- **deploy-staging:** Se conecta al servidor vía SSH, despliega la imagen en el puerto 3001, valida el endpoint `/health` y solo si pasa promueve el contenedor.
- **deploy-production:** Solo se ejecuta si staging fue exitoso. Despliega en el puerto 80 usando la imagen etiquetada con el SHA del commit para mayor precisión.

### Decisiones técnicas tomadas

- **Multi-stage build:** Reduce el tamaño de la imagen final copiando únicamente los artefactos de producción, sin herramientas de build.
- **Etiquetado con SHA + versión semántica:** El SHA permite rollback preciso a cualquier commit; la versión semántica (`v1.0.0`) facilita la identificación humana.
- **Health check antes de swap:** El nuevo contenedor se valida en un puerto alterno antes de reemplazar al activo, evitando interrupciones del servicio.
- **Entornos staging y production:** Staging valida el despliegue antes de llegar a producción, reduciendo el riesgo.
- **Trivy:** Detecta vulnerabilidades en dependencias y sistema base antes del despliegue.

---

## 2. Evidencia del pipeline ejecutándose

### Job: build-and-push
> [Insertar captura de pantalla del job completado con ✅]

### Job: deploy-staging
> [Insertar captura de pantalla del job completado con ✅]

### Job: deploy-production
> [Insertar captura de pantalla del job completado con ✅, mostrando los logs SSH]

---

## 3. Aplicación funcionando en la instancia remota

**URL pública:** `http://<IP_EC2>/health`

> [Insertar captura de pantalla del navegador o terminal mostrando la respuesta]

---

## 4. Evidencia del escaneo de vulnerabilidades

> [Insertar captura de pantalla de la salida de Trivy en el job build-and-push]

---

## 5. Proceso de rollback

Para revertir a una versión anterior se usa la imagen etiquetada con el SHA del commit:

```bash
# 1. Identificar el SHA del commit al que revertir
git log --oneline

# 2. Conectarse al servidor EC2
ssh -i lab5.2.pem ubuntu@<IP_EC2>

# 3. Ejecutar el rollback
./rollback.sh <SHA_ANTERIOR> <DOCKER_USERNAME>

# Ejemplo:
./rollback.sh e4f5g6h gabriel132

# 4. Verificar
curl http://localhost/health
```

El script `rollback.sh` descarga la imagen del SHA indicado, detiene el contenedor activo y levanta el anterior en el puerto 80.

---

## 6. Reflexión

**Ventajas de los contenedores Docker:**
Los contenedores garantizan que la aplicación se comporta igual en desarrollo, staging y producción, eliminando el clásico problema de "en mi máquina funciona". También permiten despliegues más rápidos y rollbacks inmediatos sin necesidad de reconfigurar el servidor.

**Ventajas del despliegue continuo:**
El CD elimina los despliegues manuales propensos a errores humanos. Cada commit que pasa los checks llega automáticamente a producción, lo que acelera la entrega de valor y reduce el tiempo entre desarrollo y uso real.

**Mejoras para producción real:**
En un entorno real agregaría: un balanceador de carga, notificaciones a Slack o email ante fallos del pipeline, tests automatizados como job previo al build, y rotación automática de secretos. También separaría staging y production en instancias EC2 distintas para mayor aislamiento.
