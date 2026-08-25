import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppSvgIcons {
  // 1. Logo Oficial de Chiringuito Driver
  static const String chiringuitoLogoSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="100" height="100">
  <defs>
    <linearGradient id="emeraldGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#10B981" />
      <stop offset="100%" stop-color="#047857" />
    </linearGradient>
    <linearGradient id="amberGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#FBBF24" />
      <stop offset="100%" stop-color="#D97706" />
    </linearGradient>
  </defs>
  <rect x="5" y="5" width="90" height="90" rx="28" fill="url(#emeraldGrad)" />
  <path d="M16 38 H28" stroke="#A7F3D0" stroke-width="3" stroke-linecap="round" />
  <path d="M12 48 H24" stroke="#A7F3D0" stroke-width="3.5" stroke-linecap="round" />
  <path d="M18 58 H26" stroke="#A7F3D0" stroke-width="3" stroke-linecap="round" />
  <circle cx="36" cy="66" r="10" fill="none" stroke="#FFFFFF" stroke-width="4.5" />
  <circle cx="36" cy="66" r="4" fill="#FFFFFF" />
  <circle cx="74" cy="66" r="10" fill="none" stroke="#FFFFFF" stroke-width="4.5" />
  <circle cx="74" cy="66" r="4" fill="#FFFFFF" />
  <path d="M36 66 L46 66 L56 50 L70 50 L74 66" fill="none" stroke="#FFFFFF" stroke-width="4.5" stroke-linecap="round" stroke-linejoin="round" />
  <path d="M68 40 L64 50" stroke="#FFFFFF" stroke-width="4" stroke-linecap="round" />
  <circle cx="72" cy="46" r="3" fill="#FDE68A" />
  <rect x="28" y="38" width="18" height="18" rx="4" fill="url(#amberGrad)" stroke="#FFFFFF" stroke-width="2" />
  <path d="M32 47 H42" stroke="#FFFFFF" stroke-width="2" stroke-linecap="round" />
</svg>
''';

  // 2. Motocicleta / Scooter Vectorial Oficial (Top-Down Navigation)
  static const String motorcycleSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 320" width="100%" height="100%">
  <defs>
    <filter id="shadow" x="-10%" y="-10%" width="120%" height="120%">
      <feDropShadow dx="0" dy="4" stdDeviation="4" flood-opacity="0.15"/>
    </filter>
    <linearGradient id="scooterBody" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#D5D8DC"/>
      <stop offset="50%" stop-color="#FFFFFF"/>
      <stop offset="100%" stop-color="#BDC3C7"/>
    </linearGradient>
  </defs>

  <rect x="20" y="20" width="160" height="280" rx="80" fill="#FFFFFF" stroke="#B0B5BA" stroke-width="6" filter="url(#shadow)"/>

  <g transform="translate(0, 10)">
    <path d="M 45 80 L 75 88 L 125 88 L 155 80" fill="none" stroke="#7F8C8D" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>
    <rect x="42" y="74" width="12" height="12" rx="3" fill="#2C3E50"/>
    <rect x="146" y="74" width="12" height="12" rx="3" fill="#2C3E50"/>
    <circle cx="48" cy="62" r="7" fill="#BDC3C7" stroke="#7F8C8D" stroke-width="2"/>
    <circle cx="152" cy="62" r="7" fill="#BDC3C7" stroke="#7F8C8D" stroke-width="2"/>
    <path d="M 78 70 C 78 55, 122 55, 122 70 C 122 95, 78 95, 78 70 Z" fill="url(#scooterBody)" stroke="#95A5A6" stroke-width="2"/>
    <ellipse cx="100" cy="62" rx="12" ry="6" fill="#F4F6F7" stroke="#BDC3C7" stroke-width="2"/>
    <rect x="94" y="92" width="12" height="25" rx="5" fill="#7F8C8D"/>
    <path d="M 75 110 L 125 110 L 120 160 L 80 160 Z" fill="#7F8C8D"/>
    <path d="M 82 115 L 118 115 L 115 155 L 85 155 Z" fill="#34495E"/>
    <path d="M 78 160 C 78 145, 122 145, 122 160 L 120 215 C 120 225, 80 225, 80 215 Z" fill="#2C3E50"/>
    <rect x="70" y="218" width="60" height="42" rx="8" fill="url(#scooterBody)" stroke="#95A5A6" stroke-width="2"/>
    <rect x="90" y="260" width="20" height="6" rx="3" fill="#E74C3C"/>
  </g>
</svg>
''';

  // 3. Bicicleta / E-Bike Vectorial Oficial (Top-Down Navigation)
  static const String bicycleSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 320" width="100%" height="100%">
  <defs>
    <filter id="shadow" x="-10%" y="-10%" width="120%" height="120%">
      <feDropShadow dx="0" dy="4" stdDeviation="4" flood-opacity="0.15"/>
    </filter>
  </defs>

  <rect x="20" y="20" width="160" height="280" rx="80" fill="#FFFFFF" stroke="#B0B5BA" stroke-width="6" filter="url(#shadow)"/>

  <g transform="translate(0, 10)">
    <rect x="96" y="45" width="8" height="65" rx="4" fill="#2C3E50"/>
    <rect x="98" y="48" width="4" height="59" rx="2" fill="#7F8C8D"/>
    <rect x="96" y="195" width="8" height="65" rx="4" fill="#2C3E50"/>
    <rect x="98" y="198" width="4" height="59" rx="2" fill="#7F8C8D"/>
    <path d="M 45 95 C 65 90, 80 92, 100 92 C 120 92, 135 90, 155 95" fill="none" stroke="#7F8C8D" stroke-width="5" stroke-linecap="round"/>
    <path d="M 45 95 L 45 108" stroke="#34495E" stroke-width="7" stroke-linecap="round"/>
    <path d="M 155 95 L 155 108" stroke="#34495E" stroke-width="7" stroke-linecap="round"/>
    <rect x="97" y="90" width="6" height="95" fill="#95A5A6"/>
    <line x1="65" y1="170" x2="135" y2="170" stroke="#7F8C8D" stroke-width="4" stroke-linecap="round"/>
    <rect x="60" y="163" width="12" height="14" rx="2" fill="#34495E"/>
    <rect x="128" y="163" width="12" height="14" rx="2" fill="#34495E"/>
    <path d="M 100 150 C 92 165, 82 185, 82 195 C 82 205, 92 210, 100 210 C 108 210, 118 205, 118 195 C 118 185, 108 165, 100 150 Z" fill="#2C3E50" stroke="#1A252F" stroke-width="2"/>
  </g>
</svg>
''';

  // 4. Automóvil / Van Vectorial Oficial (Top-Down Navigation)
  static const String carSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 320" width="100%" height="100%">
  <defs>
    <filter id="shadow" x="-10%" y="-10%" width="120%" height="120%">
      <feDropShadow dx="0" dy="4" stdDeviation="4" flood-opacity="0.15"/>
    </filter>
    <linearGradient id="carBody" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#E2E5E9"/>
      <stop offset="20%" stop-color="#F5F6F8"/>
      <stop offset="50%" stop-color="#FFFFFF"/>
      <stop offset="80%" stop-color="#F5F6F8"/>
      <stop offset="100%" stop-color="#D5D8DC"/>
    </linearGradient>
    <linearGradient id="glass" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#2A2E33"/>
      <stop offset="100%" stop-color="#1A1D20"/>
    </linearGradient>
  </defs>

  <rect x="20" y="20" width="160" height="280" rx="80" fill="#FFFFFF" stroke="#B0B5BA" stroke-width="6" filter="url(#shadow)"/>

  <g transform="translate(0, 10)">
    <rect x="36" y="115" width="14" height="24" rx="6" fill="#D5D8DC" stroke="#808B96" stroke-width="1.5"/>
    <rect x="150" y="115" width="14" height="24" rx="6" fill="#D5D8DC" stroke="#808B96" stroke-width="1.5"/>
    <path d="M 55 60 C 55 45, 80 40, 100 40 C 120 40, 145 45, 145 60 L 148 210 C 148 245, 125 255, 100 255 C 75 255, 52 245, 52 210 Z" fill="url(#carBody)" stroke="#99A3A4" stroke-width="2"/>
    <path d="M 68 55 C 85 50, 115 50, 132 55" fill="none" stroke="#BDC3C7" stroke-width="2" stroke-linecap="round"/>
    <path d="M 62 100 C 80 93, 120 93, 138 100 L 132 125 C 115 122, 85 122, 68 125 Z" fill="url(#glass)"/>
    <path d="M 67 128 C 85 125, 115 125, 133 128 L 135 185 C 115 188, 85 188, 65 185 Z" fill="url(#carBody)" stroke="#CBD5E0" stroke-width="1"/>
    <path d="M 66 190 C 85 187, 115 187, 134 190 L 130 208 C 115 212, 85 212, 70 208 Z" fill="url(#glass)"/>
    <path d="M 60 106 L 66 126 L 64 183 L 58 186 Z" fill="#2A2E33"/>
    <path d="M 140 106 L 134 126 L 136 183 L 142 186 Z" fill="#2A2E33"/>
    <path d="M 56 230 C 56 242, 72 248, 78 248 L 78 238 C 70 238, 60 235, 56 230 Z" fill="#E74C3C"/>
    <path d="M 144 230 C 144 242, 128 248, 122 248 L 122 238 C 130 238, 140 235, 144 230 Z" fill="#E74C3C"/>
  </g>
</svg>
''';

  // 5. Pin de Punto de Recogida (Comercio / Restaurante)
  static const String storePickupMarkerSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 120" width="100%" height="100%">
  <defs>
    <filter id="pinShadow" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="6" stdDeviation="5" flood-color="#0F172A" flood-opacity="0.25"/>
    </filter>
  </defs>
  <path d="M 50 10 C 27.9 10, 10 27.9, 10 50 C 10 78, 50 115, 50 115 C 50 115, 90 78, 90 50 C 90 27.9, 72.1 10, 50 10 Z" fill="#F59E0B" stroke="#FFFFFF" stroke-width="4" filter="url(#pinShadow)"/>
  <circle cx="50" cy="48" r="24" fill="#FFFFFF"/>
  <path d="M 36 43 L 38 35 H 62 L 64 43 Z" fill="#F59E0B"/>
  <path d="M 35 43 H 65 V 59 H 35 Z" fill="none" stroke="#F59E0B" stroke-width="3"/>
  <rect x="45" y="49" width="10" height="10" fill="#F59E0B"/>
</svg>
''';

  // 6. Pin de Punto de Entrega (Cliente Final / Casa)
  static const String customerDropoffMarkerSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 120" width="100%" height="100%">
  <defs>
    <filter id="dropShadow" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="6" stdDeviation="5" flood-color="#0F172A" flood-opacity="0.25"/>
    </filter>
  </defs>
  <path d="M 50 10 C 27.9 10, 10 27.9, 10 50 C 10 78, 50 115, 50 115 C 50 115, 90 78, 90 50 C 90 27.9, 72.1 10, 50 10 Z" fill="#059669" stroke="#FFFFFF" stroke-width="4" filter="url(#dropShadow)"/>
  <circle cx="50" cy="48" r="24" fill="#FFFFFF"/>
  <path d="M 50 34 L 35 46 V 62 H 65 V 46 Z" fill="#059669"/>
  <rect x="46" y="50" width="8" height="12" fill="#FFFFFF"/>
</svg>
''';

  // Métodos Utilitarios con compatibilidad total para size, width y height
  static Widget chiringuitoLogo({double size = 48}) {
    return SvgPicture.string(chiringuitoLogoSvg, width: size, height: size);
  }

  static Widget motorcycleCourier({double? size, double? width, double? height}) {
    final w = width ?? (size != null ? size * (200 / 320) : 34.0);
    final h = height ?? size ?? 54.0;
    return SvgPicture.string(motorcycleSvg, width: w, height: h);
  }

  static Widget bicycleCourier({double? size, double? width, double? height}) {
    final w = width ?? (size != null ? size * (200 / 320) : 34.0);
    final h = height ?? size ?? 54.0;
    return SvgPicture.string(bicycleSvg, width: w, height: h);
  }

  static Widget carCourier({double? size, double? width, double? height}) {
    final w = width ?? (size != null ? size * (200 / 320) : 34.0);
    final h = height ?? size ?? 54.0;
    return SvgPicture.string(carSvg, width: w, height: h);
  }

  static Widget vehicleNavMarker({
    String vehicleType = 'MOTORCYCLE',
    double width = 38,
    double height = 60,
  }) {
    switch (vehicleType.toUpperCase()) {
      case 'BICYCLE':
        return SvgPicture.string(bicycleSvg, width: width, height: height);
      case 'CAR':
        return SvgPicture.string(carSvg, width: width, height: height);
      case 'MOTORCYCLE':
      default:
        return SvgPicture.string(motorcycleSvg, width: width, height: height);
    }
  }

  static Widget storePickupMarker({double size = 48}) {
    return SvgPicture.string(storePickupMarkerSvg, width: size, height: size * 1.2);
  }

  static Widget customerDropoffMarker({double size = 48}) {
    return SvgPicture.string(customerDropoffMarkerSvg, width: size, height: size * 1.2);
  }
}
