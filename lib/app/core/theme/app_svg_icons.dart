import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppSvgIcons {
  // SVG Strings Directos para Renderizado Inmediato y Autónomo
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

  static const String motorcycleCourierSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">
  <circle cx="16" cy="46" r="10" fill="none" stroke="#0F172A" stroke-width="4.5" />
  <circle cx="16" cy="46" r="3.5" fill="#64748B" />
  <circle cx="48" cy="46" r="10" fill="none" stroke="#0F172A" stroke-width="4.5" />
  <circle cx="48" cy="46" r="3.5" fill="#64748B" />
  <path d="M16 46 L26 46 L36 34 L44 34 L48 46" fill="none" stroke="#059669" stroke-width="4" stroke-linecap="round" stroke-linejoin="round" />
  <path d="M43 26 L40 34" stroke="#0F172A" stroke-width="3.5" stroke-linecap="round" />
  <circle cx="47" cy="30" r="2.5" fill="#F59E0B" />
  <circle cx="33" cy="20" r="5" fill="#059669" />
  <path d="M34 23 C31 28, 29 32, 28 36" stroke="#0F172A" stroke-width="3" stroke-linecap="round" />
  <rect x="12" y="24" width="14" height="14" rx="3" fill="#F59E0B" stroke="#D97706" stroke-width="1.5" />
  <path d="M15 31 H23" stroke="#FFFFFF" stroke-width="2" stroke-linecap="round" />
</svg>
''';

  static const String bicycleCourierSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">
  <circle cx="16" cy="46" r="10" fill="none" stroke="#0F172A" stroke-width="3.5" />
  <circle cx="48" cy="46" r="10" fill="none" stroke="#0F172A" stroke-width="3.5" />
  <path d="M16 46 L30 46 L38 32 L22 32 Z" fill="none" stroke="#059669" stroke-width="3.5" stroke-linejoin="round" />
  <path d="M30 46 L24 24" stroke="#059669" stroke-width="3.5" stroke-linecap="round" />
  <path d="M38 32 L44 24 L48 46" fill="none" stroke="#059669" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round" />
  <path d="M21 24 H27" stroke="#0F172A" stroke-width="4" stroke-linecap="round" />
  <path d="M41 22 H47" stroke="#0F172A" stroke-width="3.5" stroke-linecap="round" />
  <circle cx="28" cy="14" r="4.5" fill="#059669" />
  <rect x="18" y="16" width="9" height="11" rx="2.5" fill="#F59E0B" />
</svg>
''';

  static const String carCourierSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">
  <path d="M8 38 L14 22 C15 19, 18 18, 22 18 H40 C43 18, 46 20, 48 24 L56 36 V48 C56 50, 54 52, 52 52 H12 C10 52, 8 50, 8 48 Z" fill="#059669" />
  <path d="M20 22 H32 V34 H14 Z" fill="#E2E8F0" />
  <path d="M36 22 H44 L50 34 H36 Z" fill="#E2E8F0" />
  <circle cx="18" cy="50" r="7" fill="#0F172A" stroke="#FFFFFF" stroke-width="2.5" />
  <circle cx="44" cy="50" r="7" fill="#0F172A" stroke="#FFFFFF" stroke-width="2.5" />
  <rect x="52" y="38" width="4" height="6" rx="2" fill="#F59E0B" />
</svg>
''';

  static const String storePickupMarkerSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">
  <path d="M32 4 C18.7 4, 8 14.7, 8 28 C8 43, 32 60, 32 60 C32 60, 56 43, 56 28 C56 14.7, 45.3 4, 32 4 Z" fill="#F59E0B" stroke="#FFFFFF" stroke-width="2.5" />
  <circle cx="32" cy="26" r="14" fill="#FFFFFF" />
  <path d="M24 23 L25 18 H39 L40 23 Z" fill="#F59E0B" />
  <path d="M23 23 H41 V32 H23 Z" fill="none" stroke="#F59E0B" stroke-width="2" />
  <rect x="29" y="27" width="6" height="5" fill="#F59E0B" />
</svg>
''';

  static const String customerDropoffMarkerSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">
  <path d="M32 4 C18.7 4, 8 14.7, 8 28 C8 43, 32 60, 32 60 C32 60, 56 43, 56 28 C56 14.7, 45.3 4, 32 4 Z" fill="#059669" stroke="#FFFFFF" stroke-width="2.5" />
  <circle cx="32" cy="26" r="14" fill="#FFFFFF" />
  <path d="M32 18 L23 25 V33 H41 V25 Z" fill="#059669" />
  <rect x="30" y="27" width="4" height="6" fill="#FFFFFF" />
</svg>
''';

  static const String driverLiveMarkerSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">
  <circle cx="32" cy="32" r="28" fill="#10B981" fill-opacity="0.25" />
  <circle cx="32" cy="32" r="18" fill="#059669" stroke="#FFFFFF" stroke-width="3" />
  <path d="M32 18 L38 28 L32 25 L26 28 Z" fill="#FFFFFF" />
  <circle cx="28" cy="38" r="3" fill="#FFFFFF" />
  <circle cx="36" cy="38" r="3" fill="#FFFFFF" />
  <path d="M28 38 H36" stroke="#FFFFFF" stroke-width="2" />
</svg>
''';

  static const String proofOfDeliverySvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">
  <rect x="8" y="16" width="48" height="36" rx="8" fill="#059669" />
  <path d="M22 16 L25 10 H39 L42 16 Z" fill="#047857" />
  <circle cx="32" cy="34" r="11" fill="#FFFFFF" />
  <circle cx="32" cy="34" r="6" fill="#059669" />
  <circle cx="48" cy="18" r="9" fill="#F59E0B" stroke="#FFFFFF" stroke-width="2" />
  <path d="M44 18 L47 21 L52 15" fill="none" stroke="#FFFFFF" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
</svg>
''';

  // Métodos Utilitarios para Renderizar Widgets Directos
  static Widget chiringuitoLogo({double size = 48}) {
    return SvgPicture.string(chiringuitoLogoSvg, width: size, height: size);
  }

  static Widget motorcycleCourier({double size = 32, Color? color}) {
    return SvgPicture.string(
      motorcycleCourierSvg,
      width: size,
      height: size,
      colorFilter: color != null ? ColorFilter.mode(color, BlendMode.srcIn) : null,
    );
  }

  static Widget bicycleCourier({double size = 32, Color? color}) {
    return SvgPicture.string(
      bicycleCourierSvg,
      width: size,
      height: size,
      colorFilter: color != null ? ColorFilter.mode(color, BlendMode.srcIn) : null,
    );
  }

  static Widget carCourier({double size = 32, Color? color}) {
    return SvgPicture.string(
      carCourierSvg,
      width: size,
      height: size,
      colorFilter: color != null ? ColorFilter.mode(color, BlendMode.srcIn) : null,
    );
  }

  static Widget storePickupMarker({double size = 48}) {
    return SvgPicture.string(storePickupMarkerSvg, width: size, height: size);
  }

  static Widget customerDropoffMarker({double size = 48}) {
    return SvgPicture.string(customerDropoffMarkerSvg, width: size, height: size);
  }

  static Widget driverLiveMarker({double size = 48}) {
    return SvgPicture.string(driverLiveMarkerSvg, width: size, height: size);
  }

  static Widget proofOfDelivery({double size = 32}) {
    return SvgPicture.string(proofOfDeliverySvg, width: size, height: size);
  }
}
