# Documento de Requerimientos Funcionales (FRD)
## Proyecto: `dsp_app` — Aplicación Móvil del Repartidor OpenDSP Driver

---

## 1. Información General y Propósito del Sistema

**`dsp_app`** es una aplicación móvil nativa multiplataforma desarrollada en **Flutter 3.29** y **Dart 3.7**, diseñada para repartidores y motorizados de última milla. Proporciona todas las herramientas necesarias para la recepción de pedidos en tiempo real, navegación satelital paso a paso con voz, auditoría de documentación y gestión integral de ganancias en moneda local (**Bolivianos - Bs.**).

### Objetivos Clave:
1. **Rastreo Satelital Continuo**: Transmisión de telemetría de alta precisión por WebSockets hacia la torre de control administrativa.
2. **Alerta Temprana Despertador**: Detección de órdenes entrantes con bucle de audio de alta fidelidad y vibración háptica pulsada para garantizar respuesta inmediata.
3. **Navegación GPS Asistida**: Visualización cartográfica clara, cálculo de rutas óptimas y guiado por voz en español (*TTS*).
4. **Billetera Digital y Retiros Directos**: Control transparente de cobros por carrera, propinas y retiros a cuentas bancarias o transferencias QR en Bolivia.

---

## 2. Perfil de Usuario y Flujo de Ciclo de Vida del Conductor

- **Usuario Principal**: Conductor / Motorizado de Reparto (*Driver*).
- **Estados de la Cuenta del Repartidor**:
  1. `UNREGISTERED`: Usuario nuevo que inicia el proceso de alta.
  2. `PENDING_REVIEW`: Ha completado el formulario y subido sus documentos; está a la espera de auditoría por el administrador o líder de asociación.
  3. `ACTIVE` / `VERIFIED`: Expediente aprobado; puede conectarse a turno (*Online*) y recibir ofertas de viaje.
  4. `REJECTED`: Documentos rechazados con motivo especificado; se le permite subsanar y volver a subir fotos.
  5. `SUSPENDED`: Cuenta inhabilitada temporalmente por infracciones operativas.

---

## 3. Catálogo Detallado de Pantallas y Funcionalidades

---

### Pantalla 3.1: Pantalla de Carga y Enrutamiento Inicial (`SplashScreen`)
- **Archivo fuente**: [`lib/app/ui/views/auth/splash_screen.dart`](file:///c:/Users/marvin/Documents/marvin/dsp/dsp_app/lib/app/ui/views/auth/splash_screen.dart)
- **Propósito**: Comprobar el estado de autenticación y los permisos del sistema antes de cargar la interfaz.
- **Elementos de Interfaz**:
  - Animación de marca OpenDSP / video de presentación con efecto fade-in.
  - Indicador de inicialización de servicios (Audio, Sockets, Base de Datos local).
- **Lógica de Enrutamiento**:
  1. Si no existe sesión válida ➔ Redirige a `WelcomeOnboardingScreen`.
  2. Si existe sesión pero `isPendingVerification == true` ➔ Redirige a `DriverVerificationPendingScreen`.
  3. Si la sesión está activa y verificada:
     - Evalúa `AppPermissionsService.hasAllRequiredPermissions()`.
     - Si faltan permisos críticos (GPS preciso o Notificaciones) ➔ Redirige a `PermissionRequestScreen`.
     - Si todos los permisos están concedidos ➔ Redirige directamente al mapa principal en `AllOrdersFeedScreen`.

---

### Pantalla 3.2: Bienvenida e Inducción (`WelcomeOnboardingScreen`)
- **Archivo fuente**: [`lib/app/ui/views/auth/welcome_onboarding_screen.dart`](file:///c:/Users/marvin/Documents/marvin/dsp/dsp_app/lib/app/ui/views/auth/welcome_onboarding_screen.dart)
- **Propósito**: Presentar las ventajas de la plataforma a nuevos motorizados y canalizar el acceso.
- **Elementos de Interfaz**:
  - Carrusel ilustrativo de beneficios (Pagos puntuales en Bs., rutas optimizadas, soporte 24/7).
  - Botón Principal: *"Iniciar Sesión"* (lleva a `LoginScreen`).
  - Botón Secundario / Outline: *"Quiero ser Conductor"* (lleva a `RegisterDriverScreen`).

---

### Pantalla 3.3: Inicio de Sesión (`LoginScreen`)
- **Archivo fuente**: [`lib/app/ui/views/auth/login_screen.dart`](file:///c:/Users/marvin/Documents/marvin/dsp/dsp_app/lib/app/ui/views/auth/login_screen.dart)
- **Propósito**: Autenticar a conductores registrados mediante credenciales seguras.
- **Elementos de Interfaz**:
  - Campos de entrada: Correo Electrónico o Teléfono, y Contraseña.
  - Botón de alternancia de visibilidad de contraseña (icono de ojo).
  - Tarjetas de Credenciales Rápidas de Prueba (*Quick Demo Fill*):
    - Conductor Moto: `driver@dsp.com`
    - Conductor Auto: `auto@dsp.com`
  - Botón de acción: *"INGRESAR"* con spinner integrado.
  - Enlace: *"¿No tienes cuenta? Regístrate aquí"*.
- **Acciones del Usuario**:
  - Ingresar credenciales y enviar el formulario.
  - Conexión contra `POST /v1/auth/driver-login`. Al tener éxito, inicializa el socket del conductor (`SocketService.joinDriver`) y comprueba los permisos de sistema.

---

### Pantalla 3.4: Registro Guiado del Conductor en 5 Fases (`RegisterDriverScreen`)
- **Archivo fuente**: [`lib/app/ui/views/auth/register_driver_screen.dart`](file:///c:/Users/marvin/Documents/marvin/dsp/dsp_app/lib/app/ui/views/auth/register_driver_screen.dart)
- **Propósito**: Recolección estructurada y validación de datos personales, vehículo, documentación legal y firma de contrato.
- **Componentes de Interfaz**:
  - **Barra de Progreso Superior (*Stepper*)**: 5 indicadores circulares con iconos y checkmarks que se iluminan al avanzar.
  - **Fase 1 - Datos Personales**:
    - Nombre y Apellidos, Cédula de Identidad (CI), Correo, Teléfono de contacto, Dirección de residencia y Contraseña.
  - **Fase 2 - Vehículo**:
    - Selector visual de tipo: Motocicleta, Automóvil o Bicicleta / Torito.
    - Número de Placa, Marca, Modelo y Color.
  - **Fase 3 - Carga de Documentos (Cloudinary)**:
    - 4 tarjetas interactivas de carga: *Cédula de Identidad*, *Licencia de Conducir*, *SOAT Vigente* y *Foto del Vehículo*.
    - Integración con cámara y galería. Subida asíncrona con barra de progreso en vivo, miniatura de confirmación y opción de reintentar.
  - **Fase 4 - Contrato Mercantil de Adhesión**:
    - Contenedor con scroll de los términos y condiciones de prestación de servicios.
    - Casilla de verificación interactiva de aceptación legal y registro de timestamp.
  - **Fase 5 - Resumen y Envío**:
    - Vista preliminar de los datos registrados y botón *"FINALIZAR REGISTRO"*.
- **Acciones del Usuario**:
  - Avanzar paso a paso con validaciones en tiempo real que impiden continuar si faltan campos obligatorios o fotos.

---

### Pantalla 3.5: Cuenta en Revisión (`DriverVerificationPendingScreen`)
- **Archivo fuente**: [`lib/app/ui/views/auth/driver_verification_pending_screen.dart`](file:///c:/Users/marvin/Documents/marvin/dsp/dsp_app/lib/app/ui/views/auth/driver_verification_pending_screen.dart)
- **Propósito**: Notificar al repartidor que su expediente se encuentra bajo revisión legal.
- **Elementos de Interfaz**:
  - Ilustración de auditoría con reloj de arena animado.
  - Tarjetas de estado de los documentos subidos.
  - Botón: *"Verificar Estado Ahora"* (consulta al backend si ya fue activado).
  - Botón: *"Contactar con Soporte por WhatsApp"*.
  - Botón de cierre de sesión.

---

### Pantalla 3.6: Solicitud de Permisos de Sistema (`PermissionRequestScreen`)
- **Archivo fuente**: [`lib/app/ui/views/permissions/permission_request_screen.dart`](file:///c:/Users/marvin/Documents/marvin/dsp/dsp_app/lib/app/ui/views/permissions/permission_request_screen.dart)
- **Propósito**: Explicar al usuario la necesidad técnica de los permisos antes de invocar los diálogos nativos del sistema operativo.
- **Elementos de Interfaz**:
  - Tarjeta 1: **Ubicación Satelital GPS Precisa (Siempre activa)**: Para recibir pedidos cercanos y guiarte en el mapa.
  - Tarjeta 2: **Notificaciones Push y Alertas Sonoras**: Para despertar el teléfono cuando entre una orden urgente.
  - Tarjeta 3: **Cámara y Almacenamiento**: Para fotografiar comprobantes de entrega.
  - Botón Principal: *"ACTIVAR TODOS LOS PERMISOS"*.

---

### Pantalla 3.7: Pantalla Principal de Despacho (`AllOrdersFeedScreen`)
- **Archivo fuente**: [`lib/app/ui/views/feed/all_orders_feed_screen.dart`](file:///c:/Users/marvin/Documents/marvin/dsp/dsp_app/lib/app/ui/views/feed/all_orders_feed_screen.dart)
- **Propósito**: Centro neurálgico del conductor con 4 pestañas de navegación:
  
#### Pestaña 1: Mapa Satelital de Inicio
- **Componentes**:
  - Mapa Mapbox dinámico con estilo claro (*Mapbox Light*).
  - Marcador de navegación del vehículo orientado según el rumbo (`heading`).
  - Capa de halo de radar translúcido verde alrededor del conductor que indica radio de cobertura.
  - **Posicionamiento reactivo**: Suscrito a `LocationBufferService.currentPositionNotifier` (`Geolocator.getPositionStream`).
  - **Botón Flotante de Re-centrado GPS** (`Icons.my_location_rounded`): Centra la cámara instantáneamente en la ubicación física del conductor.
  - **Interruptor de Turno (AppBar)**: Conmutador *Online / Offline*. Al activarse, inicia la telemetría periódica hacia `/tracking` y suscribe al repartidor en su sala de despacho.
  - **Tarjeta Dinámica Inferior**:
    - En modo *Offline*: Sugerencia de conexión para iniciar turno.
    - En modo *Online*: Radar de búsqueda con el botón interactivo **"Probar Alerta"** (dispara una simulación completa con sonido, vibración y modal).
    - Con viaje activo: Tarjeta con detalles del pedido en curso y botón de acceso rápido a navegación.

#### Pestaña 2: Lista de Órdenes Disponibles
- Listado de pedidos listos para entrega con pull-to-refresh, tarifa en Bs., distancias y botón de aceptación rápida.

#### Pestaña 3: Billetera y Ganancias
- Acceso directo al módulo financiero en Bolivianos (`EarningsWalletScreen`).

#### Pestaña 4: Perfil y Documentos
- Visualización de datos personales, vehículo, calificación en estrellas (Rating) y acceso a auditoría de documentos.

---

### Modal Especial 3.8: Alerta Despertador de Orden Entrante (`IncomingOrderModal`)
- **Archivo fuente**: [`lib/app/ui/widgets/incoming_order_modal.dart`](file:///c:/Users/marvin/Documents/marvin/dsp/dsp_app/lib/app/ui/widgets/incoming_order_modal.dart)
- **Propósito**: Notificar de forma invasiva y urgente la asignación de un pedido.
- **Mecanismo de Despertador**:
  - Se ejecuta automáticamente al recibir el evento WebSocket `order:offer` o al presionar *"Probar Alerta"*.
  - **Sonido en bucle**: Ejecuta `universfield-ringtone-091-496417.mp3` en modo continuo (`ReleaseMode.loop`).
  - **Vibración periódica**: Emite pulsos de vibración fuerte (`HapticFeedback.vibrate()`) cada **1.2 segundos** sin detenerse.
- **Elementos de Interfaz**:
  - Temporizador circular animado con cuenta regresiva de **30 segundos**.
  - Tarjeta de Ganancia Destacada: *"Ganarás +Bs. XX.XX"*.
  - Nombre del Comercio y Dirección de Recogida (*Pickup*).
  - Dirección de Entrega al Cliente (*Dropoff*) y distancia en km.
  - Notas de entrega del paquete.
  - Botón: *"ACEPTAR PEDIDO"* (Verde esmeralda prominente).
  - Botón: *"RECHAZAR"* (Secundario gris).
- **Flujo**:
  - Si el conductor presiona *"ACEPTAR"*:
    - Se cancela la alarma y la vibración.
    - Suena el efecto de confirmación `accepted.mp3`.
    - Se envía `POST /v1/orders/:id/accept`.
    - Se redirige inmediatamente a `LiveMapNavigationScreen`.
  - Si el conductor presiona *"RECHAZAR"* o el tiempo llega a 0:
    - Se cancela la alarma sonora y la vibración de inmediato.
    - El modal se cierra y el pedido se devuelve a la bolsa de despacho.

---

### Pantalla 3.9: Navegación GPS Turn-by-Turn en Vivo (`LiveMapNavigationScreen`)
- **Archivo fuente**: [`lib/app/ui/views/navigation/live_map_navigation_screen.dart`](file:///c:/Users/marvin/Documents/marvin/dsp/dsp_app/lib/app/ui/views/navigation/live_map_navigation_screen.dart)
- **Propósito**: Guiar al conductor durante las 3 etapas del trayecto con voz e indicaciones cartográficas.
- **Fases del Viaje**:
  1. `ARRIVED_AT_PICKUP`: Ruta hacia la tienda/restaurante. Botón: *"Llegué al Comercio"*.
  2. `IN_TRANSIT`: Paquete recibido. Ruta hacia el destino del cliente. Botón: *"Iniciar Viaje al Cliente"*.
  3. `DELIVERED`: Confirmación de entrega. Botón: *"Confirmar Entrega Completada"*.
- **Elementos de Interfaz**:
  - Trazado de ruta en tiempo real sobre Mapbox.
  - Indicador de maniobra superior (ej. *"A 200m gire a la derecha en Av. Cristo Redentor"*).
  - Sintetizador de voz en español (*TTS*) para comandos hablados sin apartar la vista del camino.
  - Botón de llamada telefónica directa al cliente o al comercio.
  - Botón de reporte de problema o cancelación de viaje.
  - Celebración de entrega exitosa con animación de saldo acumulado y sonido de caja registradora (`cash.mp3`).

---

### Pantalla 3.10: Billetera Digital y Solicitud de Retiros (`EarningsWalletScreen`)
- **Archivo fuente**: [`lib/app/ui/views/wallet/earnings_wallet_screen.dart`](file:///c:/Users/marvin/Documents/marvin/dsp/dsp_app/lib/app/ui/views/wallet/earnings_wallet_screen.dart)
- **Propósito**: Gestión transparente del dinero ganado por el repartidor en moneda boliviana.
- **Elementos de Interfaz**:
  - **Tarjeta de Saldo Principal**:
    - Gradiente esmeralda oscuro con distintivo de moneda oficial: **`BOB (Bs.)`**.
    - **Contador Dinámico Animado**: Animación suave de aumento de saldo con `TweenAnimationBuilder`.
  - **Acciones en AppBar**: Pull-to-refresh y botón manual de sincronización con spinner para actualizar el balance en vivo contra `GET /v1/drivers/:id/wallet`.
  - **Pastillas de Filtro**: *Todos los movimientos*, *Ganancias (+)* y *Retiros (-)*.
  - **Historial de Transacciones**: Lista detallada con tipo de evento, código de orden o retiro, fecha y variación del saldo.
  - **Botón Destacado**: `+ Solicitar Retiro`.
- **Modal de Retiro de Fondos (`WithdrawFundsDialog`)**:
  - Selector de modalidad: **Transferencia Bancaria** o **QR Simple Bolivia**.
  - Validación de monto mínimo (Bs. 10.00) y verificación contra saldo disponible.
  - Formulario de cuenta: Banco de destino, Número de Cuenta o carga de imagen del código QR personal.
  - Envío asíncrono hacia `POST /v1/settlements/withdrawals/request`.
  - Detección de errores del servidor y despliegue de banner rojo explicativo.
  - En caso de éxito: Modal de celebración con check verde animado y actualización automática del saldo.

---

## 4. Requisitos No Funcionales y Especificaciones Técnicas

- **Plataformas**: Android (API 24+) e iOS (iOS 13+).
- **Gestor de Estado**: `Provider` / `ChangeNotifier` para reactividad fluida de 60fps.
- **Conectividad en Tiempo Real**: `socket_io_client` conectado a `ws://<host>:3000/tracking` con reconexión automática y buffer local de telemetría offline.
- **Sonidos Nativos**: `audioplayers` con assets pre-cacheados en memoria.
- **Permisos Nativos Android**:
  - `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `ACCESS_BACKGROUND_LOCATION`.
  - `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_LOCATION`.
  - `VIBRATE`, `POST_NOTIFICATIONS`, `WAKE_LOCK`.
