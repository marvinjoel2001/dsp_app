import 'package:flutter/material.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/entities/driver_entity.dart';

class ActiveTripCard extends StatelessWidget {
  final OrderEntity? order;
  final DriverEntity? driver;
  final VoidCallback onContinueGps;

  const ActiveTripCard({
    super.key,
    required this.order,
    required this.driver,
    required this.onContinueGps,
  });

  @override
  Widget build(BuildContext context) {
    final storeName = order?.pickupAddress ?? 'Restaurante El Chiringuito Central';
    final payout = order?.driverPayout ?? 23.50;
    final distance = order?.estimatedDistanceKm?.toStringAsFixed(1) ?? '1.2';
    final duration = order?.estimatedTime ?? '5';
    final productsCount = order?.packageNotes ?? '2 productos';

    final driverName = driver?.fullName ?? 'Carlos M.';
    final driverRating = driver?.rating.toStringAsFixed(1) ?? '4.9';
    final vehicleType = driver?.vehicleType == 'MOTORCYCLE'
        ? 'Moto 125cc'
        : (driver?.vehicleType == 'BICYCLE' ? 'Bicicleta' : 'Moto 125cc');
    final vehiclePlate = (driver?.vehiclePlate != null && driver!.vehiclePlate.isNotEmpty)
        ? driver!.vehiclePlate
        : '123-ABC';

    final bool isDelivering = order?.status == OrderDeliveryStatus.inTransit ||
        order?.status == OrderDeliveryStatus.delivered;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.10),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle superior sutil
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Fila 1: Badge "VIAJE EN CURSO" y Tarifa en Verde
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'VIAJE EN CURSO',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF00875A),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Text(
                '+Bs. ${payout.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF00875A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Fila 2: Nombre del Comercio / Restaurante
          Text(
            storeName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 12),

          // Fila 3: Estadísticas del Viaje (Distancia, Tiempo, Productos) con iconos morados
          Row(
            children: [
              _buildStatItem(
                icon: Icons.location_on_outlined,
                text: '$distance km',
              ),
              const SizedBox(width: 14),
              _buildStatItem(
                icon: Icons.access_time_rounded,
                text: '$duration min',
              ),
              const SizedBox(width: 14),
              _buildStatItem(
                icon: Icons.inventory_2_outlined,
                text: productsCount,
                isFlexible: true,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Fila 4: Barra de Progreso de Ruta (Recogida -> Entrega)
          Row(
            children: [
              // Check Recogida
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Color(0xFF00875A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 12,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Recogida',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF00875A),
                ),
              ),

              // Barra conectora
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: isDelivering ? 1.0 : 0.45,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF48D19F),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),

              // Texto Entrega
              Text(
                'Entrega',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isDelivering ? const Color(0xFF00875A) : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isDelivering ? const Color(0xFF00875A) : const Color(0xFF7C3AED),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Fila 5: Tarjeta del Conductor y Vehículo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Info Conductor (Foto, Nombre, Calificación)
                Row(
                  children: [
                    CircleAvatar(
                      radius: 19,
                      backgroundColor: const Color(0xFFE2E8F0),
                      backgroundImage: driver?.avatarUrl != null && driver!.avatarUrl!.isNotEmpty
                          ? NetworkImage(driver!.avatarUrl!)
                          : null,
                      child: (driver?.avatarUrl == null || driver!.avatarUrl!.isEmpty)
                          ? const Icon(Icons.person, size: 20, color: Color(0xFF64748B))
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driverName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Row(
                          children: [
                            Text(
                              driverRating,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.star_rounded,
                              size: 13,
                              color: Color(0xFFF59E0B),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                // Info Vehículo (Icono Morado + Tipo y Placa)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.local_shipping_outlined,
                        size: 20,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          vehicleType,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          vehiclePlate,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Fila 6: Botón de Acción Principal Verde
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onContinueGps,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00875A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Continuar Navegación GPS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String text,
    bool isFlexible = false,
  }) {
    final content = Row(
      mainAxisSize: isFlexible ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF7C3AED),
        ),
        const SizedBox(width: 4),
        isFlexible
            ? Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
      ],
    );

    if (isFlexible) {
      return Expanded(child: content);
    }
    return content;
  }
}
